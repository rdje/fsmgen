#!/usr/bin/env python3
"""Qualify capability payload typing without changing any public result value."""
import copy
import gzip
import json
from pathlib import Path
import subprocess
import sys

from verify_diagnostic_limits import verify_metadata_packet
from verify_inventory import check_schema, encoded, errors
from verify_source_identity import source_bytes

MODULE = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'
ALIASES = {'all', 'contracts', 'examples', 'vial_tooling_v1', 'vial_tooling_v2', 'vial_inspection'}


def population(record):
    verify_metadata_packet(record)
    manifest = json.loads(record['exchanges'][2]['response']['result']['contents'][0]['text'])
    calls = [e for e in record['exchanges'] if e['request']['method'] == 'tools/call']
    sections = [e['request']['params']['arguments']['section'] for e in calls]
    assert len(sections) == len(set(sections)) and set(sections) == set(manifest) | ALIASES, 'section population changed'
    return manifest, calls


def runtime(record):
    source = source_bytes(record, MODULE).decode().split('\n__END__', 1)[0]
    left, body = source.split('\nsub _capability_query_output_schema {', 1)
    _, right = body.split('\nsub _source_query_output_schema {', 1)
    return left + '\nsub _source_query_output_schema {' + right


def verify(before, after):
    for record in (before, after):
        names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', record['head'], 'perl/FSM']).decode().splitlines()
        expected = {p for p in names if p.endswith('.pm')} | {
            'bin/fsmgen-mcp', 't/python/test_fixture_mcp_stdio.py', 't/python/test_fixture_mcp_metadata_schemas.py'}
        assert set(record['source_sha256']) == expected
        for path in record['source_sha256']:
            source_bytes(record, path)
    _, old_calls = population(before)
    manifest, new_calls = population(after)
    assert before['sent_utf8'] == after['sent_utf8'], 'request population changed'
    old_tools = before['exchanges'][1]['response']['result']
    new_tools = after['exchanges'][1]['response']['result']
    expected = copy.deepcopy(old_tools)
    tool = next(t for t in expected['tools'] if t['name'] == 'fsmgen_capability_query')
    original_payload = tool['outputSchema']['properties']['payload']
    tool['outputSchema']['properties']['payload'] = {'anyOf': [original_payload, {'type': 'integer'}]}
    assert encoded(expected) == encoded(new_tools), 'unexpected schema change'
    schema = next(t['outputSchema'] for t in new_tools['tools'] if t['name'] == 'fsmgen_capability_query')
    check_schema(schema)
    resources = {e['request']['params']['uri']: json.loads(e['response']['result']['contents'][0]['text'])
                 for e in after['exchanges'] if e['request']['method'] == 'resources/read'}
    for exchange in new_calls:
        params, result = exchange['request']['params'], exchange['response']['result']
        assert params['name'] == 'fsmgen_capability_query'
        assert result['isError'] is False
        value = result['structuredContent']
        assert not errors(value, schema), 'output schema violation'
        assert encoded(json.loads(result['content'][0]['text'])) == encoded(value)
        section = params['arguments']['section']
        if section == 'all':
            wanted = manifest
        elif section == 'contracts':
            wanted = {key: manifest[key] for key in ('manifest_contract', 'semantic_introspection')}
        elif section == 'examples':
            wanted = resources['fsmgen://examples']
        elif section.startswith('vial_tooling_v'):
            wanted = {'section': section, 'payload': resources['fsmgen://vial/' + section[-1] + '/capabilities']}
        elif section == 'vial_inspection':
            assert set(value) == {'section', 'payload'} and value['section'] == section
            assert type(value['payload']) is dict
            continue  # Its complete value is conserved below; T1882 joins the backing public API.
        else:
            wanted = {'section': section, 'payload': manifest[section]}
        assert encoded(value) == encoded(wanted), 'section value mismatch'
    assert len(old_calls) == len(new_calls)
    for old, new in zip(before['exchanges'], after['exchanges']):
        if new['request']['method'] != 'tools/list':
            assert encoded(old) == encoded(new), 'complete result changed'
    assert runtime(before) == runtime(after), 'query runtime changed'
    assert not errors({'section': 'manifest_schema_version', 'payload': 1.0}, schema)
    for wrong in (True, '1', [], None):
        assert errors({'section': 'manifest_schema_version', 'payload': wrong}, schema)
    return {'capability_sections_conserved': len(new_calls),
            'public_manifest_sections': len(manifest), 'selected_source_files': len(after['source_sha256']),
            'integer_payload_preserved': manifest['manifest_schema_version']}


def rewire(record, requests=False):
    record['received_utf8'] = ''.join(json.dumps(e['response']) + '\n' for e in record['exchanges'])
    if requests:
        frames = [e['request'] for e in record['exchanges']]
        frames.insert(1, {'jsonrpc': '2.0', 'method': 'notifications/initialized'})
        record['sent_utf8'] = ''.join(json.dumps(r) + '\n' for r in frames)


def main():
    assert len(sys.argv) == 3
    records = [json.loads(gzip.decompress(Path(p).read_bytes())) for p in sys.argv[1:]]
    result = verify(*records)
    controls = []
    for name, reason in [('missing_section', 'section population changed'),
                         ('extra_section', 'section population changed'),
                         ('boolean_payload', 'output schema violation'),
                         ('borrowed_integer', 'section value mismatch'),
                         ('missing_integer_schema', 'unexpected schema change')]:
        bad = copy.deepcopy(records[1])
        if name == 'missing_section':
            bad['exchanges'].pop()
            rewire(bad, requests=True)
        elif name == 'extra_section':
            extra = copy.deepcopy(bad['exchanges'][-1])
            extra['request']['id'] = extra['response']['id'] = len(bad['exchanges'])
            extra['request']['params']['arguments']['section'] = 'unpublished_section_control'
            bad['exchanges'].append(extra)
            rewire(bad, requests=True)
        elif name in ('boolean_payload', 'borrowed_integer'):
            section = 'manifest_schema_version' if name == 'boolean_payload' else 'semantic_introspection'
            item = next(e for e in bad['exchanges'] if e['request'].get('params', {}).get('arguments', {}).get('section') == section)
            value = item['response']['result']
            value['structuredContent']['payload'] = True if name == 'boolean_payload' else 1
            value['content'][0]['text'] = json.dumps(value['structuredContent'])
            rewire(bad)
        else:
            tool = next(t for t in bad['exchanges'][1]['response']['result']['tools'] if t['name'] == 'fsmgen_capability_query')
            tool['outputSchema']['properties']['payload'] = {'type': 'object', 'additionalProperties': True}
            rewire(bad)
        try:
            verify(records[0], bad)
        except AssertionError as error:
            assert str(error) == reason, (name, str(error))
            controls.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    result['controls_rejected'] = controls
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
