#!/usr/bin/env python3
"""Recheck the saved source-selector repair, including complete report equality."""
import copy
import gzip
import hashlib
import json
from functools import lru_cache
from pathlib import Path
import re
import subprocess
import sys

from verify_inventory import check_schema, encoded, errors

ROOT = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == ROOT
TOOLS = {'fsmgen_check', 'fsmgen_semantic_introspect', 'fsmgen_schedule_preview'}


@lru_cache(maxsize=None)
def original_source(path, digest, head):
    current = ROOT / path
    if current.is_file() and hashlib.sha256(current.read_bytes()).hexdigest() == digest:
        return current.read_bytes()
    revisions = [head] + subprocess.check_output(
        ['git', 'log', '--format=%H', '--', path]).decode().splitlines()
    # A repaired source is captured before its commit, while HEAD still names
    # the predecessor. Recover that exact producer from the later slice commit
    # after current code moves on; never pretend predecessor bytes are repaired.
    for revision in dict.fromkeys(revisions):
        candidate = subprocess.run(['git', 'show', revision + ':' + path],
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if candidate.returncode == 0 and hashlib.sha256(candidate.stdout).hexdigest() == digest:
            return candidate.stdout
    raise AssertionError('Exact original source unavailable: ' + path)


def source_bytes(record, path):
    return original_source(path, record['source_sha256'][path], record['head'])


def query_runtime(source):
    source = source.decode().split('\n__END__', 1)[0]
    for start, end in [('\nsub list_tools {', '\nsub call_tool {'),
                       ('\nsub _source_query_tool_descriptor {', '\nsub _source_tool_properties {'),
                       ('\nsub _source_tool_properties {', '\nsub _capability_query_output_schema {')]:
        if start in source:
            left, right = source.split(start, 1)
            _, tail = right.split(end, 1)
            source = left + end + tail
    return source


def verify(record_before, record_after):
    for record in (record_before, record_after):
        assert record['orderly_eof'] is True and type(record['exit_status']) is int
        assert record['exit_status'] == 0
        for path in record['source_sha256']:
            source_bytes(record, path)
        sent = [json.loads(line) for line in record['sent_utf8'].splitlines()]
        received = [json.loads(line) for line in record['received_utf8'].splitlines()]
        result = record['result']
        assert encoded(received) == encoded([result['discovery']] + [c['response'] for c in result['calls']]), 'wire/result mismatch'
        assert len(sent) == len(received) == len(result['calls']) + 1
        assert sent[0]['method'] == 'tools/list'
        for request, response in zip(sent, received):
            assert type(request['id']) is int and type(response['id']) is int
            assert request['id'] == response['id'] and response['jsonrpc'] == '2.0'
        for request, call in zip(sent[1:], result['calls']):
            assert request['method'] == 'tools/call'
            assert encoded(request['params']) == encoded({'name': call['name'], 'arguments': call['arguments']})

    module = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'
    assert query_runtime(source_bytes(record_before, module)) == query_runtime(source_bytes(record_after, module))
    before, after = (r['result'] for r in (record_before, record_after))
    assert record_before['sent_utf8'] == record_after['sent_utf8'], 'request population changed'
    expected = copy.deepcopy(before['discovery'])
    for tool in expected['result']['tools']:
        if tool['name'] in TOOLS:
            schema = tool['inputSchema']
            schema['anyOf'] = [{'required': ['source_path']}, {'required': ['source_id']}]
            for key in ('source_path', 'source_id'):
                schema['properties'][key]['minLength'] = 1
    assert encoded(expected) == encoded(after['discovery']), 'unexpected discovery change'
    schemas = {t['name']: t['inputSchema'] for t in after['discovery']['result']['tools']}
    for schema in schemas.values():
        check_schema(schema)
    positives, refusals = 0, 0
    for old, new in zip(before['calls'], after['calls']):
        assert old['name'] == new['name'] and old['name'] in TOOLS
        assert encoded(old['arguments']) == encoded(new['arguments'])
        assert type(new['expected_valid']) is bool and old['expected_valid'] is new['expected_valid']
        assert bool(errors(new['arguments'], schemas[new['name']])) is not new['expected_valid']
        if new['expected_valid']:
            positives += 1
            assert encoded(old['response']) == encoded(new['response']), 'complete valid result changed'
            payload = new['response']['result']
            assert payload['isError'] is False
            assert encoded(json.loads(payload['content'][0]['text'])) == encoded(payload['structuredContent'])
        else:
            refusals += 1
            reason = ('source identity must be a nonempty string' if new['arguments']
                      else 'source_path or source_id is required')
            for call in (old, new):
                error = call['response']['error']
                assert set(error) == {'code', 'message'} and error['code'] == -32602
                # The independently owned automatic-location leak is still
                # present. Compare the exact public reason and recognize only
                # this adapter's known suffix; never discard arbitrary text.
                pattern = ('Invalid params: ' + re.escape(reason)
                           + r' at perl/FSM/Support/SemanticIntrospectionMCPAdapter\.pm line \d+, <STDIN> line \d+\.')
                assert re.fullmatch(pattern, error['message']), error
    assert {c['name'] for c in after['calls']} == TOOLS
    assert positives and refusals
    return {'valid_results_conserved': positives, 'refusals_preserved': refusals,
            'automatic_location_repair_pending': True}


def main():
    paths = [Path(argument) for argument in sys.argv[1:]]
    assert len(paths) == 2
    records = [json.loads(gzip.decompress(p.read_bytes())) for p in paths]
    result = verify(*records)
    controls = []
    for name in ('missing_call', 'changed_valid_report', 'missing_selector_requirement', 'lost_wire_reply'):
        corrupted = copy.deepcopy(records[1])
        if name == 'missing_call':
            corrupted['result']['calls'].pop()
            for key in ('sent_utf8', 'received_utf8'):
                corrupted[key] = corrupted[key].rsplit('\n', 2)[0] + '\n'
        elif name == 'changed_valid_report':
            call = next(c for c in corrupted['result']['calls'] if c['expected_valid'])
            call['response']['result']['structuredContent']['report'] = True
            call['response']['result']['content'][0]['text'] = json.dumps(call['response']['result']['structuredContent'])
        elif name == 'missing_selector_requirement':
            tool = next(t for t in corrupted['result']['discovery']['result']['tools'] if t['name'] in TOOLS)
            del tool['inputSchema']['anyOf']
        else:
            corrupted['received_utf8'] = corrupted['received_utf8'].rsplit('\n', 2)[0] + '\n'
        if name in ('changed_valid_report', 'missing_selector_requirement'):
            corrupted['received_utf8'] = ''.join(json.dumps(r) + '\n' for r in
                [corrupted['result']['discovery']] + [c['response'] for c in corrupted['result']['calls']])
        expected_refusal = {'missing_call': 'request population changed',
                            'changed_valid_report': 'complete valid result changed',
                            'missing_selector_requirement': 'unexpected discovery change',
                            'lost_wire_reply': 'wire/result mismatch'}[name]
        try:
            verify(records[0], corrupted)
        except AssertionError as error:
            assert str(error) == expected_refusal, (name, str(error))
            controls.append(name)
        else:
            raise AssertionError('Control was accepted: ' + name)
    result['controls_rejected'] = controls
    result['capture_sha256'] = {p.as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
