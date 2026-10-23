#!/usr/bin/env python3
"""Qualify strict source kinds, unchanged valid results and URI version routes."""
import copy
import gzip
import json
from pathlib import Path
import sys
from urllib.parse import quote

from verify_arguments import ENVELOPE, controls, rewire, verify
from verify_diagnostic_limits import verify_metadata_packet
from verify_inventory import encoded, errors, same_value
from verify_source_identity import source_bytes

ADAPTER = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'


def read(path):
    return json.loads(gzip.decompress(Path(path).read_bytes()))


def verify_resources(before, after, matrix_before, matrix_after):
    for record, matrix in ((before, matrix_before), (after, matrix_after)):
        verify_metadata_packet(record)
        native = {p for p in matrix['source_sha256'] if p.startswith('perl/FSM/')}
        assert set(record['source_sha256']) == native | {
            'bin/fsmgen-mcp', 't/python/test_fixture_mcp_stdio.py',
            't/python/test_fixture_mcp_metadata_schemas.py', 't/python/test_fixture_mcp_source_identity.py'}
        assert record['source_sha256'][ADAPTER] == matrix['source_sha256'][ADAPTER], 'resource/matrix source boundary mismatch'
        for path in record['source_sha256']:
            source_bytes(record, path)
        exchanges = record['exchanges']
        assert len(exchanges) == 18, 'resource population changed'
        assert exchanges[0]['request']['method'] == 'initialize' and exchanges[1]['request']['method'] == 'tools/list'
        assert encoded(exchanges[1]['response']['result']['tools']) == encoded(matrix['tools'])
        index = 2
        for version, source in ((1, 'vial/ahb_subordinate_base_output_arbitration.vial'),
                                (2, 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial')):
            expected = 'fsmgen://vial/%s/capabilities' % version
            exchange = exchanges[index]
            assert exchange['request']['method'] == 'resources/read' and exchange['request']['params'] == {'uri': expected}
            content = exchange['response']['result']['contents']
            assert len(content) == 1 and content[0]['uri'] == expected and content[0]['mimeType'] == 'application/json'
            assert isinstance(json.loads(content[0]['text']), dict)
            index += 1
            for kind, tool in (('check', 'fsmgen_check'), ('semantic', 'fsmgen_semantic_introspect'),
                               ('inspection', 'fsmgen_vial_inspect')):
                exchange = exchanges[index]
                assert exchange['request']['method'] == 'tools/call'
                assert exchange['request']['params'] == {'name': tool, 'arguments': {'source_id': source, 'language_version': version}}
                result = exchange['response']['result']
                assert result['isError'] is False
                payload = result['structuredContent']
                assert payload['source_id'] == payload['source_path'] == source
                assert payload['query_kind'] == kind
                assert type(payload['adapter_provenance']['language_version']) is int
                assert payload['adapter_provenance']['language_version'] == version
                assert same_value(json.loads(result['content'][0]['text']), payload)
                index += 1
                uris = ['fsmgen://vial/%s/source/%s/%s' % (version, quote(source, safe=''), kind)]
                if version == 1 and kind != 'inspection':
                    uris.append('fsmgen://source/%s/%s' % (quote(source, safe=''), kind))
                for uri in uris:
                    exchange = exchanges[index]
                    assert exchange['request']['method'] == 'resources/read' and exchange['request']['params'] == {'uri': uri}
                    content = exchange['response']['result']['contents']
                    assert len(content) == 1 and set(content[0]) == {'uri', 'mimeType', 'text'}
                    assert content[0]['uri'] == uri and content[0]['mimeType'] == 'application/json'
                    assert same_value(json.loads(content[0]['text']), payload), 'complete tool/resource payload mismatch'
                    index += 1
        assert index == len(exchanges)
    assert encoded(before['exchanges']) == encoded(after['exchanges']), 'complete resource exchanges changed'
    assert before['sent_utf8'] == after['sent_utf8'] and before['received_utf8'] == after['received_utf8']
    return {'complete_resource_controls': 10, 'paired_tool_controls': 6}


def compare(before, after, resources_before, resources_after):
    old, new = verify(before), verify(after)
    assert before['cases'] == after['cases'] and encoded(before['tools']) == encoded(after['tools'])
    assert set(after['native_source_overrides']) == {ADAPTER}
    assert set(before['source_sha256']) == set(after['source_sha256'])
    for path in before['source_sha256']:
        if path != ADAPTER:
            assert before['source_sha256'][path] == after['source_sha256'][path], 'unrelated selected source changed'
    assert all(not rows for rows in new['findings'].values()), 'source admission/copy findings remain'
    tools = {tool['name']: tool for tool in after['tools']}
    conserved, refused = [], []
    for case, original, repaired in zip(before['cases'], before['api']['rows'], after['api']['rows']):
        request = json.loads(case['request_utf8'])
        params = request.get('params')
        invalid = errors(params, ENVELOPE)
        if not invalid and params['name'] in tools:
            invalid = errors(params.get('arguments', {}), tools[params['name']]['inputSchema'])
        response = repaired['response']
        if invalid:
            assert response.get('error', {}).get('code') == -32602, 'invalid source input not refused'
            refused.append(case['label'])
        elif 'result' in original['response']:
            assert encoded(response) == encoded(original['response']), 'complete schema-admitted result changed'
            conserved.append(case['label'])
        else:
            assert response['error']['code'] == original['response']['error']['code'], 'unowned error class changed'
        for key in ('request_after_json', 'request_after_clone_json'):
            assert same_value(json.loads(repaired[key]), request), 'repaired caller changed'
    resources = verify_resources(resources_before, resources_after, before, after)
    return {'original_findings': {k: len(v) for k, v in old['findings'].items()},
            'remaining_findings': {k: len(v) for k, v in new['findings'].items()},
            'complete_schema_admitted_results_conserved': conserved, 'refused_schema_cases': refused,
            'resources': resources}


def repair_controls(before, after, rb, ra):
    rejected = []
    for name, message in (
        ('restored_quoted_version', 'source admission/copy findings remain'),
        ('restored_caller_copy_mutation', 'source admission/copy findings remain'),
        ('borrowed_valid_query_result', 'complete schema-admitted result changed'),
        ('wrong_resource_payload', 'complete tool/resource payload mismatch'),
        ('borrowed_resource_source', 'resource/matrix source boundary mismatch'),
    ):
        bad, resource = copy.deepcopy(after), copy.deepcopy(ra)
        if name == 'borrowed_resource_source':
            resource['source_sha256'][ADAPTER] = rb['source_sha256'][ADAPTER]
        elif name == 'wrong_resource_payload':
            resource['exchanges'][4]['response']['result']['contents'][0]['text'] = '{}'
            resource['received_utf8'] = ''.join(json.dumps(e['response']) + '\n' for e in resource['exchanges'])
        else:
            label = {'restored_quoted_version': 'fsmgen_vial_inspect:language_version:version_string',
                     'restored_caller_copy_mutation': 'fsmgen_check:source_id:zero',
                     'borrowed_valid_query_result': 'fsmgen_vial_inspect:valid_base'}[name]
            index = next(i for i, c in enumerate(bad['cases']) if c['label'] == label)
            row = bad['api']['rows'][index]
            if name == 'restored_quoted_version':
                row['response'] = copy.deepcopy(before['api']['rows'][index]['response'])
            elif name == 'restored_caller_copy_mutation':
                row['request_after_clone_json'] = before['api']['rows'][index]['request_after_clone_json']
            else:
                donor = next(i for i, c in enumerate(before['cases']) if c['label'] == 'fsmgen_check:valid_base')
                row['response']['result'] = copy.deepcopy(before['api']['rows'][donor]['response']['result'])
            bad['wire_replies'][index] = copy.deepcopy(row['response'])
            rewire(bad)
        try:
            compare(before, bad, rb, resource)
        except AssertionError as error:
            assert str(error) == message, (name, str(error))
            rejected.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    return rejected


if __name__ == '__main__':
    assert len(sys.argv) == 5
    before, after, rb, ra = map(read, sys.argv[1:])
    result = compare(before, after, rb, ra)
    result['original_reader_controls'] = controls(before)
    result['repaired_reader_controls'] = controls(after)
    result['repair_controls'] = repair_controls(before, after, rb, ra)
    print(json.dumps(result, indent=2))
