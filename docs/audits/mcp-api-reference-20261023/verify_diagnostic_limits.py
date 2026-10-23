#!/usr/bin/env python3
"""Recheck diagnostic descriptor admission and complete live/controlled results."""
import copy
import gzip
import json
from pathlib import Path
import sys

from verify_inventory import encoded, errors
from verify_source_identity import source_bytes

MODULE = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'
NAME = 'fsmgen_explain_diagnostic'


def runtime(record):
    source = source_bytes(record, MODULE).decode().split('\n__END__', 1)[0]
    left, body = source.split('\nsub list_tools {', 1)
    _, right = body.split('\nsub call_tool {', 1)
    return left + '\nsub call_tool {' + right


def metadata(before, after):
    expected = copy.deepcopy(before)
    tool = next(t for t in after['tools'] if t['name'] == NAME)
    properties = tool['inputSchema']['properties']
    assert 'limit_examples' in properties, 'missing limit descriptor'
    field = properties['limit_examples']
    assert set(field) == {'type', 'description'} and field['type'] == 'integer', 'wrong limit type'
    assert isinstance(field['description'], str) and field['description']
    original = next(t for t in expected['tools'] if t['name'] == NAME)
    assert 'limit_examples' not in original['inputSchema']['properties']
    original['inputSchema']['properties']['limit_examples'] = field
    assert encoded(expected) == encoded(after), 'unrelated metadata changed'
    return tool['inputSchema']


def verify_metadata_packet(record):
    assert record['orderly_eof'] is True and type(record['exit_status']) is int and record['exit_status'] == 0
    requests = [json.loads(line) for line in record['sent_utf8'].splitlines()]
    assert [r for r in requests if 'id' not in r] == [{'jsonrpc': '2.0', 'method': 'notifications/initialized'}]
    requests = [r for r in requests if 'id' in r]
    replies = [json.loads(line) for line in record['received_utf8'].splitlines()]
    assert [r['id'] for r in requests] == list(range(len(requests)))
    assert encoded(requests) == encoded([e['request'] for e in record['exchanges']]), 'request join failed'
    assert encoded(replies) == encoded([e['response'] for e in record['exchanges']]), 'reply join failed'
    for request, reply in zip(requests, replies):
        assert type(request['id']) is int and type(reply['id']) is int and request['id'] == reply['id']
        assert reply['jsonrpc'] == '2.0' and 'error' not in reply


def verify(live_before, live_after, controlled_before, controlled_after):
    for live, controlled in ((live_before, controlled_before), (live_after, controlled_after)):
        # The Perl probe fingerprints actual files but has no Git subprocess.
        # Join its adapter hash to the paired live boundary before using that
        # HEAD only as an exact-source history locator.
        assert controlled['source_sha256'][MODULE] == live['source_sha256'][MODULE]
        controlled = dict(controlled, head=live['head'])
        for record in (live, controlled):
            for path in record['source_sha256']:
                source_bytes(record, path)
    assert runtime(live_before) == runtime(live_after), 'query runtime changed'
    for record in (live_before, live_after):
        verify_metadata_packet(record)
    assert live_before['sent_utf8'] == live_after['sent_utf8']
    schema = metadata(live_before['exchanges'][1]['response']['result'], live_after['exchanges'][1]['response']['result'])
    calls = 0
    for old, new in zip(live_before['exchanges'], live_after['exchanges']):
        if new['request']['method'] == 'tools/list':
            continue
        assert encoded(old) == encoded(new), 'live result changed'
        if new['request']['method'] == 'tools/call':
            result = new['response']['result']
            assert result['isError'] is False
            assert encoded(json.loads(result['content'][0]['text'])) == encoded(result['structuredContent'])
            if new['request']['params']['name'] == NAME:
                assert not errors(new['request']['params']['arguments'], schema)
                calls += 1
    for wrong in (True, '1', [], {}, None):
        assert errors({'code': 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE', 'limit_examples': wrong}, schema)
    metadata(controlled_before['tools'], controlled_after['tools'])
    assert controlled_before['fixture_kind'] == controlled_after['fixture_kind'] == 'counterfactual_catalog'
    assert encoded(controlled_before['catalog_entries']) == encoded(controlled_after['catalog_entries'])
    manifest = json.loads(live_after['exchanges'][2]['response']['result']['contents'][0]['text'])
    code = 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE'
    diagnostic = next(d for d in manifest['diagnostics']['stable_codes'] if d['code'] == code)
    fields = ('id', 'relpath', 'family', 'classification', 'coverage', 'source_kind',
              'strict_supported', 'diagnostic_code')
    expected = {'null': 10, '0': 10, '1': 1, '10': 10, '100': 100, '101': 100, '-1': 10, '1e30': 10}
    assert [c['input_literal'] for c in controlled_after['cases']] == list(expected)
    for old, new in zip(controlled_before['cases'], controlled_after['cases']):
        assert encoded(old) == encoded(new), 'controlled result changed'
        literal = new['input_literal']
        arguments = {'code': code}
        if literal != 'null':
            arguments['limit_examples'] = json.loads(literal)
        assert new['request']['method'] == 'tools/call'
        assert encoded(new['request']['params']) == encoded({'name': NAME, 'arguments': arguments})
        result = new['response']['result']
        assert result['isError'] is False
        assert encoded(json.loads(result['content'][0]['text'])) == encoded(result['structuredContent'])
        wanted = {'code': code, 'diagnostic': diagnostic,
                  'registry_contract': manifest['diagnostics']['stable_code_registry'],
                  'support_examples': [{key: e[key] for key in fields}
                      for e in controlled_after['catalog_entries'][:expected[literal]]]}
        assert encoded(result['structuredContent']) == encoded(wanted)
    return {'live_diagnostic_queries_conserved': calls, 'controlled_queries_conserved': len(expected),
            'large_integer_limit_defect': '1e30 selects default 10; owned by .6.1.2.2.4'}


def rewire(record):
    record['received_utf8'] = ''.join(json.dumps(e['response']) + '\n' for e in record['exchanges'])


def main():
    assert len(sys.argv) == 5
    records = [json.loads(gzip.decompress(Path(p).read_bytes())) for p in sys.argv[1:]]
    result = verify(*records)
    controls = []
    for name, reason in [('missing_limit', 'missing limit descriptor'), ('wrong_type', 'wrong limit type'),
                         ('changed_live_result', 'live result changed'), ('lost_reply', 'reply join failed'),
                         ('changed_controlled_result', 'controlled result changed')]:
        variant = copy.deepcopy(records)
        if name in ('missing_limit', 'wrong_type'):
            tool = next(t for t in variant[1]['exchanges'][1]['response']['result']['tools'] if t['name'] == NAME)
            if name == 'missing_limit':
                del tool['inputSchema']['properties']['limit_examples']
            else:
                tool['inputSchema']['properties']['limit_examples']['type'] = 'boolean'
            rewire(variant[1])
        elif name == 'changed_live_result':
            result_value = variant[1]['exchanges'][3]['response']['result']
            result_value['structuredContent']['support_examples'][0]['strict_supported'] = 1
            result_value['content'][0]['text'] = json.dumps(result_value['structuredContent'])
            rewire(variant[1])
        elif name == 'lost_reply':
            variant[1]['received_utf8'] = variant[1]['received_utf8'].rsplit('\n', 2)[0] + '\n'
        else:
            value = variant[3]['cases'][5]['response']['result']
            value['structuredContent']['support_examples'] = value['structuredContent']['support_examples'][:10]
            value['content'][0]['text'] = json.dumps(value['structuredContent'])
        try:
            verify(*variant)
        except AssertionError as error:
            assert str(error) == reason, (name, str(error))
            controls.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    result['controls_rejected'] = controls
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
