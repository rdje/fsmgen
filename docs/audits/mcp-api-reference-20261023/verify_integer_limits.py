#!/usr/bin/env python3
"""Independently check every controlled limit result, not only sample counts."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
from pathlib import PurePosixPath
import subprocess
import sys

from verify_arguments import native_digest
from verify_diagnostic_limits import verify_metadata_packet
from verify_source_identity import source_bytes
from verify_inventory import same_value

ADAPTER = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'
CONTRACT = 'perl/FSM/Support/SemanticIntrospectionContract.pm'
PRODUCER = 't/2103-mcp-metadata-integer-limits.t'
TOOLS = [('fsmgen_explain_diagnostic', 'limit_examples'),
         ('fsmgen_support_summary', 'limit_examples'),
         ('fsmgen_discover_sources', 'limit'), ('fsmgen_find_examples', 'limit')]
LITERALS = ['omitted', '-1', '0', '0.0', '1', '1.0', '1e0', '10', '25',
            '100', '101', '121', '122', '1e30', '1e300',
            '1.5', 'true', 'false', 'null', '"1"', '[]', '{}']
CODE = 'FSMGEN_COUNTERFACTUAL_LIMIT_FIXTURE'


def entries():
    return [dict(id='counterfactual_%03d' % i, relpath='counterfactual/catalog_%03d.fsm' % i,
                 family='counterfactual_fixture', classification='counterfactual_fixture',
                 coverage='counterfactual_fixture', source_kind='fsm', strict_supported=bool(i % 2),
                 diagnostic_code=CODE,
                 **({'expected_module_name': 'counterfactual_module_' + str(i)} if i % 3 == 0 else {}))
            for i in range(1, 122)]


def expected_fixture():
    return {'documentation': {'fixture': 'counterfactual_catalog'},
            'diagnostics': {'stable_codes': [{'code': CODE, 'meaning': 'counterfactual limit fixture'}],
                            'stable_code_registry': {'fixture': 'counterfactual_registry'}},
            'support_accounting': {
                'source': 'counterfactual_catalog', 'entry_count': 121,
                **{key: {'counterfactual_fixture': 121} for key in ('classifications', 'coverage_buckets', 'families')},
                'source_kinds': {'fsm': 121}, 'supported_smoke_ids': [], 'strict_supported_ids': [],
                'expected_failure_ids': [], 'catalog_entries': entries()}}


def policy(tool, literal, repaired):
    if literal in LITERALS[15:]:
        return None
    default = 10 if tool in (TOOLS[0][0], TOOLS[1][0]) else 25
    if literal in ('omitted', '-1'):
        return default
    if literal in ('0', '0.0'):
        return default if tool in (TOOLS[0][0], TOOLS[3][0]) else 0
    if literal in ('1e30', '1e300') and not repaired:
        return default
    value = json.loads(literal)
    return value if tool == TOOLS[3][0] else min(value, 100)


def expected_result(tool, limit):
    fixture = expected_fixture()
    catalog = fixture['support_accounting']['catalog_entries']
    count = min(int(limit), len(catalog))
    compact_fields = ('id', 'relpath', 'family', 'classification', 'coverage', 'source_kind',
                      'strict_supported', 'diagnostic_code')
    compact = [{key: entry[key] for key in compact_fields} for entry in catalog[:count]]
    summary = {'query_kind': 'support_summary', 'source': 'counterfactual_catalog', 'entry_count': 121,
               **{key: fixture['support_accounting'][key]
                  for key in ('classifications', 'coverage_buckets', 'families', 'source_kinds')},
               'id_counts': {'supported_smoke_ids': 0, 'strict_supported_ids': 0, 'expected_failure_ids': 0},
               'sample_catalog_entries': []}
    if tool == TOOLS[0][0]:
        return {'code': CODE, 'diagnostic': fixture['diagnostics']['stable_codes'][0],
                'registry_contract': fixture['diagnostics']['stable_code_registry'], 'support_examples': compact}
    if tool == TOOLS[1][0]:
        return dict(summary, sample_catalog_entries=compact)
    if tool == TOOLS[2][0]:
        support_fields = ('id', 'family', 'classification', 'coverage', 'strict_supported',
                          'diagnostic_code', 'expected_module_name')
        sources = [{'source_id': e['relpath'], 'source_path': e['relpath'], 'relpath': e['relpath'],
                    'file_kind': 'fsm', 'source_kind': 'fsm', 'available_query_kinds': ['check', 'semantic'],
                    'support': {key: e[key] for key in support_fields if key in e}}
                   for e in catalog[:count]]
        return {'query_kind': 'source_discovery', 'source': 'counterfactual_catalog', 'query': '', 'limit': limit,
                'filters': {'file_kind': '', 'source_kind': '', 'classification': ''},
                'path_policy': {'discovery_authority': 'manifest_support_catalog_only',
                                'recursive_workspace_traversal': False, 'hidden_paths': 'excluded',
                                'source_identity': 'repo_or_workspace_relative', 'machine_local_absolute_paths': 'not_returned'},
                'total_catalog_count': 121, 'matched_count': 121, 'returned_count': count, 'sources': sources}
    return {'documentation': fixture['documentation'], 'query': '', 'limit': limit,
            'support_summary': summary, 'returned_count': count, 'catalog_entries': catalog[:count]}


def verify(record, repaired):
    assert record['fixture_kind'] == 'counterfactual_catalog'
    assert same_value(record['fixture'], expected_fixture()), 'counterfactual input changed'
    assert set(record['source_sha256']) == set(record['source_capsules']) == {ADAPTER, CONTRACT, PRODUCER}
    for path, text in record['source_capsules'].items():
        assert hashlib.sha256(text.encode()).hexdigest() == record['source_sha256'][path], 'source capsule hash mismatch'
    assert native_digest(record['source_head'], CONTRACT) == record['source_sha256'][CONTRACT]
    if not repaired:
        assert native_digest(record['source_head'], ADAPTER) == record['source_sha256'][ADAPTER]
    sent = record['sent_utf8'].splitlines()
    received = record['received_utf8'].splitlines()
    cases = record['cases']
    assert len(cases) == len(sent) == len(received) == len(TOOLS) * len(LITERALS), 'controlled case population mismatch'
    labels = []
    for index, ((tool, field), literal) in enumerate((t, value) for t in TOOLS for value in LITERALS):
        case = cases[index]
        raw = case['request_utf8']
        assert raw == sent[index] and case['input_literal'] == literal, 'controlled request mislabeled'
        args = {'code': CODE} if tool == TOOLS[0][0] else {}
        if literal != 'omitted':
            args[field] = json.loads(literal)
            assert '"' + field + '":' + literal in raw, 'numeric spelling changed'
        request = {'jsonrpc': '2.0', 'id': index, 'method': 'tools/call', 'params': {'name': tool, 'arguments': args}}
        assert same_value(json.loads(raw), request), 'controlled request changed'
        api, wire = case['response'], json.loads(received[index])
        for response in (api, wire):
            assert type(response['id']) is int and response['id'] == index and response['jsonrpc'] == '2.0'
        limit = policy(tool, literal, repaired)
        if limit is None:
            for response in (api, wire):
                assert set(response) == {'jsonrpc', 'id', 'error'}
                assert set(response['error']) == {'code', 'message'} and response['error']['code'] == -32602
            labels.append(tool + ':' + literal)
            continue
        assert same_value(api, wire), 'API/newline complete result mismatch'
        assert set(api) == {'jsonrpc', 'id', 'result'}
        result = api['result']
        assert set(result) == {'content', 'structuredContent', 'isError'} and result['isError'] is False
        assert len(result['content']) == 1 and set(result['content'][0]) == {'type', 'text'}
        assert result['content'][0]['type'] == 'text'
        wanted = expected_result(tool, limit)
        assert same_value(result['structuredContent'], wanted), 'unexpected integer-limit result'
        assert same_value(json.loads(result['content'][0]['text']), wanted), 'unexpected integer-limit text'
        labels.append(tool + ':' + literal)
    return labels


def compare(before, after):
    assert verify(before, False) == verify(after, True)
    for path in (CONTRACT, PRODUCER):
        assert before['source_sha256'][path] == after['source_sha256'][path]
    changed = []
    for index, (old, new) in enumerate(zip(before['cases'], after['cases'])):
        if 'result' in old['response'] and not same_value(old['response'], new['response']):
            changed.append(TOOLS[index // len(LITERALS)][0] + ':' + old['input_literal'])
    assert set(changed) == {tool + ':' + literal for tool, _ in TOOLS for literal in ('1e30', '1e300')}
    return {'controlled_cases_per_entrypoint': len(before['cases']), 'changed_cases': changed,
            'exact_nonlarge_successes_and_wrong_kind_codes_conserve': True,
            'selected_source_paths': sorted(after['source_sha256'])}


def controls(before, after):
    rejected = []
    for name, message in (
        ('restored_large_fallback', 'unexpected integer-limit result'),
        ('universal_example_cap', 'unexpected integer-limit result'),
        ('boolean_numeric_limit', 'unexpected integer-limit result'),
        ('reordered_complete_records', 'unexpected integer-limit result'),
        ('lost_newline_reply', 'controlled case population mismatch'),
        ('tampered_producer_source', 'source capsule hash mismatch'),
    ):
        bad = copy.deepcopy(after)
        if name == 'tampered_producer_source':
            bad['source_capsules'][PRODUCER] += '\n'
        elif name == 'lost_newline_reply':
            bad['received_utf8'] = '\n'.join(bad['received_utf8'].splitlines()[:-1]) + '\n'
        else:
            target = {'restored_large_fallback': (0, '1e30'), 'universal_example_cap': (3, '1e30'),
                      'boolean_numeric_limit': (2, '1'), 'reordered_complete_records': (3, '121')}[name]
            index = target[0] * len(LITERALS) + LITERALS.index(target[1])
            case = bad['cases'][index]
            if name == 'restored_large_fallback':
                case['response'] = copy.deepcopy(before['cases'][index]['response'])
            else:
                result = case['response']['result']
                if name == 'universal_example_cap':
                    result['structuredContent'] = expected_result(TOOLS[3][0], 100)
                elif name == 'boolean_numeric_limit':
                    result['structuredContent']['limit'] = True
                else:
                    rows = result['structuredContent']['catalog_entries']
                    rows[0], rows[1] = rows[1], rows[0]
                result['content'][0]['text'] = json.dumps(result['structuredContent'])
            lines = bad['received_utf8'].splitlines()
            lines[index] = json.dumps(case['response'])
            bad['received_utf8'] = '\n'.join(lines) + '\n'
        try:
            compare(before, bad)
        except AssertionError as error:
            assert str(error) == message, (name, str(error))
            rejected.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    return rejected


def verify_live(record):
    verify_metadata_packet(record)
    native = {p for p in subprocess.check_output(['git', 'ls-tree', '-r', '--name-only',
              record['head'], 'perl/FSM']).decode().splitlines() if p.endswith('.pm')}
    assert set(record['source_sha256']) == native | {
        'bin/fsmgen-mcp', 't/python/test_fixture_mcp_stdio.py', 't/python/test_fixture_mcp_metadata_schemas.py'}
    for path in record['source_sha256']:
        source_bytes(record, path)
    exchanges = record['exchanges']
    values = ['omitted', 0, -1, 1, 100, 101, 1e30, 1e300]
    assert len(exchanges) == 3 + len(TOOLS) * len(values), 'unexpected live population'
    assert exchanges[0]['request']['method'] == 'initialize'
    assert exchanges[1]['request']['method'] == 'tools/list'
    assert exchanges[2]['request']['params'] == {'uri': 'fsmgen://capabilities'}
    manifest = json.loads(exchanges[2]['response']['result']['contents'][0]['text'])
    support = manifest['support_accounting']
    catalog = support['catalog_entries']
    summary = {'query_kind': 'support_summary', 'source': support['source'], 'entry_count': support['entry_count'],
               **{k: support[k] for k in ('classifications', 'coverage_buckets', 'families', 'source_kinds')},
               'id_counts': {k: len(support[k]) for k in ('supported_smoke_ids', 'strict_supported_ids', 'expected_failure_ids')},
               'sample_catalog_entries': []}
    compact_fields = ('id', 'relpath', 'family', 'classification', 'coverage', 'source_kind', 'strict_supported', 'diagnostic_code')

    def compact(rows):
        return [{k: e[k] for k in compact_fields if k in e} for e in rows]

    sources = []
    kinds = manifest['semantic_introspection']['source_query_kinds']
    for entry in catalog:
        path = entry['relpath']
        assert isinstance(path, str) and type(entry['strict_supported']) is bool
        kind = PurePosixPath(path).suffix[1:].lower()
        if not path or path.startswith('/') or '\\' in path or any(p.startswith('.') for p in path.split('/')) or kind not in kinds:
            continue
        sources.append({'source_id': path, 'source_path': path, 'relpath': path, 'file_kind': kind,
                        'source_kind': entry['source_kind'], 'available_query_kinds': kinds[kind],
                        'support': {k: entry[k] for k in ('id', 'family', 'classification', 'coverage', 'strict_supported',
                                    'diagnostic_code', 'expected_module_name', 'expected_top_name', 'expected_lane',
                                    'has_expected_error_pattern', 'has_expected_hint_pattern') if k in entry}})
    code = 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE'
    diagnostic = next(d for d in manifest['diagnostics']['stable_codes'] if d['code'] == code)
    for offset, (tool, field) in enumerate(TOOLS):
        for step, value in enumerate(values):
            exchange = exchanges[3 + offset * len(values) + step]
            args = {'code': code} if tool == TOOLS[0][0] else {}
            if value != 'omitted':
                args[field] = value
            assert same_value(exchange['request']['params'], {'name': tool, 'arguments': args}), 'unexpected live argument'
            literal = 'omitted' if value == 'omitted' else ('1e30' if value == 1e30 else '1e300' if value == 1e300 else str(value))
            limit = policy(tool, literal, True)
            if tool == TOOLS[0][0]:
                matches = [e for e in catalog if e.get('diagnostic_code') == code]
                wanted = {'code': code, 'diagnostic': diagnostic, 'registry_contract': manifest['diagnostics']['stable_code_registry'],
                          'support_examples': compact(matches[:int(limit)])}
            elif tool == TOOLS[1][0]:
                wanted = dict(summary, sample_catalog_entries=compact(catalog[:int(limit)]))
            elif tool == TOOLS[2][0]:
                selected = sources[:int(limit)]
                wanted = {'query_kind': 'source_discovery', 'source': support['source'], 'query': '', 'limit': limit,
                          'filters': {'file_kind': '', 'source_kind': '', 'classification': ''},
                          'path_policy': expected_result(tool, 1)['path_policy'],
                          'total_catalog_count': len(catalog), 'matched_count': len(sources),
                          'returned_count': len(selected), 'sources': selected}
            else:
                selected = catalog[:int(limit)]
                wanted = {'documentation': manifest['documentation'], 'query': '', 'limit': limit, 'support_summary': summary,
                          'returned_count': len(selected), 'catalog_entries': selected}
            result = exchange['response']['result']
            assert result['isError'] is False
            assert same_value(result['structuredContent'], wanted), 'unexpected full live limit result'
            assert same_value(json.loads(result['content'][0]['text']), wanted), 'unexpected full live limit text'
    return {'complete_live_calls': len(TOOLS) * len(values), 'selected_source_paths': len(record['source_sha256'])}


def join_live(controlled, record):
    assert controlled['source_sha256'][ADAPTER] == record['source_sha256'][ADAPTER], 'controlled/live adapter boundary mismatch'
    assert controlled['source_head'] == record['head'], 'controlled/live base boundary mismatch'
    return verify_live(record)


def live_controls(before, after, record):
    rejected = []
    for name, message in (('borrowed_live_identity', 'unexpected full live limit result'),
                          ('boolean_live_limit', 'unexpected full live limit result'),
                          ('lost_live_reply', 'reply join failed'),
                          ('borrowed_native_boundary', 'controlled/live adapter boundary mismatch')):
        bad = copy.deepcopy(record)
        if name == 'borrowed_native_boundary':
            bad['source_sha256'][ADAPTER] = before['source_sha256'][ADAPTER]
        elif name == 'lost_live_reply':
            bad['received_utf8'] = '\n'.join(bad['received_utf8'].splitlines()[:-1]) + '\n'
        else:
            index = 3 + (1 if name == 'borrowed_live_identity' else 2) * 8 + 3
            result = bad['exchanges'][index]['response']['result']
            if name == 'borrowed_live_identity':
                result['structuredContent']['sample_catalog_entries'][0]['id'] = 'counterfactual_borrowed_identity'
            else:
                result['structuredContent']['limit'] = True
            result['content'][0]['text'] = json.dumps(result['structuredContent'])
            bad['received_utf8'] = ''.join(json.dumps(e['response']) + '\n' for e in bad['exchanges'])
        try:
            join_live(after, bad)
        except AssertionError as error:
            assert str(error) == message, (name, str(error))
            rejected.append(name)
        else:
            raise AssertionError('Live control accepted: ' + name)
    return rejected


def main():
    assert len(sys.argv) in (3, 4)
    before, after = (json.loads(gzip.decompress(Path(p).read_bytes())) for p in sys.argv[1:3])
    result = compare(before, after)
    result['controls_rejected'] = controls(before, after)
    if len(sys.argv) == 4:
        live = json.loads(gzip.decompress(Path(sys.argv[3]).read_bytes()))
        result['live'] = join_live(after, live)
        result['live_controls_rejected'] = live_controls(before, after, live)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
