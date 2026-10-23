#!/usr/bin/env python3
"""Qualify examples documentation typing and complete unchanged public results."""
import copy
import gzip
import json
from pathlib import Path
import subprocess
import sys

from verify_diagnostic_limits import verify_metadata_packet
from verify_error_context import source
from verify_inventory import check_schema, encoded, errors

ADAPTER = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'
ARGUMENTS = [{}, {'limit': 2}, {'query': 'CoMpOsItIoN', 'limit': 3},
             {'query': '__no_matching_catalog_entry__', 'limit': 1}, {'query': 'i2c', 'limit': 1e30}]


def population(record, repaired):
    verify_metadata_packet(record)
    paths = {p for p in subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', record['head'],
             'perl']).decode().splitlines() if p.endswith('.pm')} | {
             'README.md', 'bin/fsmgen', 'bin/fsmgen-mcp', 't/python/test_fixture_mcp_stdio.py',
             't/python/test_fixture_mcp_metadata_schemas.py'}
    assert set(record['source_sha256']) == paths, 'source population mismatch'
    for path in paths:
        source(record, path)
    ex = record['exchanges']
    assert len(ex) == 12 and ex[0]['request']['method'] == 'initialize'
    expected = [('tools/list', None), ('resources/read', {'uri': 'fsmgen://capabilities'}),
                ('resources/read', {'uri': 'fsmgen://examples'}),
                ('tools/call', {'name': 'fsmgen_capability_query', 'arguments': {'section': 'examples'}}),
                ('tools/call', {'name': 'fsmgen_capability_query', 'arguments': {'section': 'documentation'}}),
                ('tools/call', {'name': 'fsmgen_support_summary', 'arguments': {'limit_examples': 0}})]
    expected += [('tools/call', {'name': 'fsmgen_find_examples', 'arguments': a}) for a in ARGUMENTS]
    for row, (method, params) in zip(ex[1:], expected):
        request = {'jsonrpc': '2.0', 'id': row['request']['id'], 'method': method}
        if params is not None:
            request['params'] = params
        assert encoded(row['request']) == encoded(request), 'request population mismatch'
    tools = ex[1]['response']['result']['tools']
    schema = next(t['outputSchema'] for t in tools if t['name'] == 'fsmgen_find_examples')
    check_schema(schema)
    manifest = json.loads(ex[2]['response']['result']['contents'][0]['text'])
    documentation = manifest['documentation']
    assert type(documentation) is dict and set(documentation) == {'human_contract', 'downstream_alignment', 'section_contract'}
    contract = documentation['section_contract']
    assert contract['contract_source'] == 'FSM::Support::DocumentationContract'
    assert contract['schema_version'] == 1 and type(contract['schema_version']) is int
    assert contract['path_contract'] == {'repo_relative_paths': True, 'tracked_markdown_files': True, 'exact_path_lists_frozen': False}
    support = manifest['support_accounting']
    summary = {'query_kind': 'support_summary', 'source': support['source'],
        **{k: support[k] for k in ('entry_count', 'classifications', 'coverage_buckets', 'families', 'source_kinds')},
        'id_counts': {k: len(support[k]) for k in ('supported_smoke_ids', 'strict_supported_ids', 'expected_failure_ids')},
        'sample_catalog_entries': []}
    assert encoded(ex[6]['response']['result']['structuredContent']) == encoded(summary), 'support summary mismatch'
    resource = json.loads(ex[3]['response']['result']['contents'][0]['text'])
    assert encoded(ex[4]['response']['result']['structuredContent']) == encoded(resource), 'examples alias mismatch'
    assert encoded(ex[5]['response']['result']['structuredContent']) == encoded({'section': 'documentation', 'payload': documentation})
    violations = []
    for row, arguments in zip(ex[7:], ARGUMENTS):
        result = row['response']['result']
        assert result['isError'] is False
        payload = result['structuredContent']
        query, limit = arguments.get('query', ''), arguments.get('limit', 25)
        matches = [entry for entry in support['catalog_entries'] if any(
            query.lower() in entry[key].lower() for key in ('id', 'relpath'))]
        selected = matches[:min(len(matches), int(limit))]
        wanted = {'documentation': documentation, 'query': query, 'limit': limit,
                  'support_summary': summary, 'returned_count': len(selected), 'catalog_entries': selected}
        assert encoded(payload) == encoded(wanted), 'complete example value mismatch'
        assert encoded(json.loads(result['content'][0]['text'])) == encoded(wanted), 'text/structured mismatch'
        if not arguments:
            assert encoded(resource) == encoded(wanted), 'default resource mismatch'
        found = errors(payload, schema)
        if repaired:
            assert not found, 'example schema violation remains'
            for wrong in ([], True, 1, 'documentation', None):
                assert errors(dict(payload, documentation=wrong), schema), 'wrong documentation type admitted'
        else:
            assert found and all('$/documentation:' in e for e in found), 'original discrepancy changed'
            violations.append(found)
    return {'source_files': len(paths), 'original_schema_violations': violations}


def verify(before, after):
    old, new = population(before, False), population(after, True)
    assert before['head'] == after['head']
    assert set(before['native_source_overrides']) == set() and set(after['native_source_overrides']) == {ADAPTER}
    assert set(before['source_sha256']) == set(after['source_sha256'])
    for path, digest in before['source_sha256'].items():
        if path != ADAPTER:
            assert after['source_sha256'][path] == digest, 'unrelated selected source changed'
    old_runtime, new_runtime = [source(r, ADAPTER).decode().split('\n__END__', 1)[0] for r in (before, after)]
    line = "            documentation => { type => 'array', items => _open_object_schema() },"
    assert old_runtime.count(line) == 1
    assert new_runtime == old_runtime.replace(line, '            documentation => _open_object_schema(),'), 'query runtime changed'
    expected = copy.deepcopy(before['exchanges'])
    field = next(t for t in expected[1]['response']['result']['tools'] if t['name'] == 'fsmgen_find_examples')['outputSchema']['properties']
    field['documentation'] = field['documentation']['items']
    assert encoded(expected) == encoded(after['exchanges']), 'unrelated metadata or complete result changed'
    assert before['sent_utf8'] == after['sent_utf8']
    return {'selected_source_files': new['source_files'], 'complete_unchanged_exchanges': len(expected) - 1,
            'example_queries': len(ARGUMENTS), 'original_schema_violations': old['original_schema_violations']}


def controls(before, after):
    rejected = []
    for name in ('restored_array', 'changed_documentation', 'borrowed_catalog', 'text_mismatch', 'borrowed_source'):
        bad = copy.deepcopy(after)
        if name == 'restored_array':
            bad['exchanges'][1]['response'] = copy.deepcopy(before['exchanges'][1]['response'])
        elif name == 'borrowed_source':
            bad['source_sha256'][ADAPTER] = before['source_sha256'][ADAPTER]
            bad['native_source_overrides'][ADAPTER] = source(before, ADAPTER).decode()
        else:
            result = bad['exchanges'][8]['response']['result']
            if name == 'text_mismatch':
                result['content'][0]['text'] = '{}'
            else:
                field = 'documentation' if name == 'changed_documentation' else 'catalog_entries'
                result['structuredContent'][field] = {} if field == 'documentation' else []
                result['content'][0]['text'] = json.dumps(result['structuredContent'])
        bad['received_utf8'] = ''.join(json.dumps(e['response']) + '\n' for e in bad['exchanges'])
        try:
            verify(before, bad)
        except AssertionError as error:
            wanted = {'restored_array': 'example schema violation remains',
                      'borrowed_source': 'query runtime changed', 'text_mismatch': 'text/structured mismatch'}
            assert str(error) == wanted.get(name, 'complete example value mismatch'), (name, str(error))
            rejected.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    return rejected


if __name__ == '__main__':
    assert len(sys.argv) == 3
    before, after = [json.loads(gzip.decompress(Path(p).read_bytes())) for p in sys.argv[1:]]
    result = verify(before, after)
    result['controls'] = controls(before, after)
    print(json.dumps(result, indent=2))
