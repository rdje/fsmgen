#!/usr/bin/env python3
"""Verify saved MCP census custody and evaluate its emitted schema vocabulary."""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == ROOT
sys.path.insert(0, str(ROOT / 'scripts'))
from generate_pod_reference import local_path


def encoded(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, allow_nan=False, separators=(',', ':'))


def same_value(left, right):
    # JSON numbers compare mathematically; Booleans remain a distinct type.
    if type(left) in (int, float) and type(right) in (int, float):
        return left == right
    if type(left) is not type(right):
        return False
    if isinstance(left, list):
        return len(left) == len(right) and all(same_value(a, b) for a, b in zip(left, right))
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(same_value(left[k], right[k]) for k in left)
    return left == right


SCHEMA_KEYS = {'type', 'properties', 'required', 'additionalProperties', 'items',
               'enum', 'const', 'anyOf', 'description', 'minLength'}


def check_schema(schema):
    assert isinstance(schema, dict) and set(schema) <= SCHEMA_KEYS, schema
    for child in schema.get('properties', {}).values():
        check_schema(child)
    if 'items' in schema:
        check_schema(schema['items'])
    for branch in schema.get('anyOf', []):
        check_schema(branch)


def is_type(value, wanted):
    if wanted == 'integer':
        return type(value) is int or (type(value) is float and value.is_integer())
    if wanted == 'number':
        return type(value) in (int, float)
    return type(value) is {'object': dict, 'array': list, 'string': str,
                           'boolean': bool, 'null': type(None)}[wanted]


def errors(value, schema, path='$'):
    # Deliberately scoped to the complete vocabulary emitted in this capture;
    # unknown keywords fail rather than pretending to be a general validator.
    assert isinstance(schema, dict) and set(schema) <= SCHEMA_KEYS, schema
    result = []
    types = schema.get('type')
    if types and not any(is_type(value, t) for t in ([types] if isinstance(types, str) else types)):
        return [f'{path}: expected {types}, got {type(value).__name__}']
    if 'enum' in schema and not any(same_value(value, v) for v in schema['enum']):
        result.append(path + ': enum mismatch')
    if 'const' in schema and not same_value(value, schema['const']):
        result.append(path + ': const mismatch')
    if 'anyOf' in schema and all(errors(value, branch, path) for branch in schema['anyOf']):
        result.append(path + ': no anyOf branch accepts the value')
    if isinstance(value, dict):
        result += [path + '/' + key + ': required' for key in schema.get('required', []) if key not in value]
        props = schema.get('properties', {})
        if schema.get('additionalProperties') is False:
            result += [path + '/' + key + ': additional property' for key in value if key not in props]
        for key in value.keys() & props.keys():
            result += errors(value[key], props[key], path + '/' + key)
    if isinstance(value, list) and 'items' in schema:
        for index, item in enumerate(value):
            result += errors(item, schema['items'], path + '/' + str(index))
    if isinstance(value, str) and len(value) < schema.get('minLength', 0):
        result.append(path + ': shorter than minLength')
    return result


def field_rows(schema):
    result, pending = [], [('', schema)]
    while pending:
        prefix, parent = pending.pop()
        for name, child in parent.get('properties', {}).items():
            path = prefix + '/' + name
            result.append({'path': path, 'required': name in parent.get('required', []), 'schema': child})
            pending.append((path, child))
    return sorted(result, key=lambda row: row['path'])


def value_kind(value):
    return {type(None): 'null', bool: 'boolean', int: 'integer', float: 'number',
            str: 'string', list: 'array', dict: 'object'}[type(value)]


def verify(record, check_git=True):
    assert re.fullmatch('[0-9a-f]{40}', record['head'])
    sent = [json.loads(line) for line in record['sent_utf8'].splitlines()]
    replies = [json.loads(line) for line in record['received_utf8'].splitlines()]
    requests = [r for r in sent if 'id' in r]
    assert [r for r in sent if 'id' not in r] == [
        {'jsonrpc': '2.0', 'method': 'notifications/initialized'}]
    assert len(requests) == len(replies) == len(record['exchanges'])
    by_label = {}
    for req, reply, exchange in zip(requests, replies, record['exchanges']):
        assert encoded(req) == encoded(exchange['request'])
        assert encoded(reply) == encoded(exchange['response'])
        assert type(req['id']) is int and type(reply['id']) is int and req['id'] == reply['id']
        assert reply['jsonrpc'] == '2.0' and (('result' in reply) != ('error' in reply))
        assert exchange['label'] not in by_label
        by_label[exchange['label']] = exchange
        if req['method'] == 'tools/call' and 'result' in reply:
            value = reply['result']
            assert type(value['isError']) is bool and isinstance(value['structuredContent'], dict)
            assert len(value['content']) == 1 and value['content'][0]['type'] == 'text'
            assert encoded(json.loads(value['content'][0]['text'])) == encoded(value['structuredContent'])
    assert type(record['transport_exit_status']) is int and record['transport_exit_status'] == 0
    assert record['orderly_eof'] is True
    for key, label, member in [('tools', 'tools/list', 'tools'), ('resources', 'resources/list', 'resources'),
                               ('templates', 'resources/templates/list', 'resourceTemplates')]:
        assert encoded(record[key]) == encoded(by_label[label]['response']['result'][member])
    assert encoded(record['initialized']) == encoded(by_label['initialize']['response']['result'])
    contents = by_label['static:fsmgen://capabilities']['response']['result']['contents']
    manifest = json.loads(contents[0]['text'])
    contract = manifest['semantic_introspection']
    tools = {row['name']: row for row in record['tools']}
    assert len(tools) == len(record['tools']) and set(tools) == set(contract['mcp_tool_names'])
    assert {r['uriTemplate'] for r in record['templates']} == set(contract['mcp_resource_uri_templates'])
    assert {r['uri'] for r in record['resources']} == {u for u in contract['mcp_resource_uri_templates'] if '{' not in u}
    assert len(record['resources']) == len({r['uri'] for r in record['resources']})
    assert len(record['templates']) == len({r['uriTemplate'] for r in record['templates']})
    assert encoded(record['source_query_kinds']) == encoded(contract['source_query_kinds'])
    assert encoded(record['contract_surface_map']) == encoded(contract['contract_surface_map'])
    assert set(record['field_rows']) == set(tools)
    for name, descriptor in tools.items():
        rows = record['field_rows'][name]
        for key, schema_key in [('inputs', 'inputSchema'), ('outputs', 'outputSchema')]:
            check_schema(descriptor[schema_key])
            assert encoded(sorted(rows[key], key=lambda r: r['path'])) == encoded(field_rows(descriptor[schema_key]))
    expected_sections = set(manifest) | {'all', 'contracts', 'examples', 'vial_tooling_v1',
                                        'vial_tooling_v2', 'vial_inspection'}
    assert set(record['capability_sections']) == expected_sections
    assert {label[8:] for label in by_label if label.startswith('section:')} == expected_sections
    for section in record['capability_sections']:
        response = by_label['section:' + section]['response']
        value = response['result']['structuredContent']
        info = record['capability_sections'][section]
        assert type(info['exchange_id']) is int and info['exchange_id'] == response['id']
        assert info['result_kind'] == value_kind(value)
        assert info['payload_kind'] == (value_kind(value['payload']) if 'payload' in value else None)
        if section in manifest:
            assert encoded(value['payload']) == encoded(manifest[section])
    if check_git:
        names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', '-z', record['head'],
                                          '--', 'perl/FSM']).decode().split('\0')
        expected = {p for p in names if p.endswith('.pm')} | {
            'bin/fsmgen', 'bin/fsmgen-mcp', 't/python/test_fixture_mcp_stdio.py',
            't/fixtures/semantic_introspection_mcp/read_only_schema_snapshot.json',
            'docs/book/src/11-extensions-and-embedding.md', 'docs/book/src/11a-perl-api-reference.md',
            'docs/VIAL_SOURCE_INSPECTION_CONTRACT.md'}
        assert set(record['selected_source_sha256']) == expected
        for name, identity in record['selected_source_sha256'].items():
            assert not Path(name).is_absolute() and '..' not in Path(name).parts
            raw = subprocess.check_output(['git', 'show', record['head'] + ':' + name])
            assert hashlib.sha256(raw).hexdigest() == identity
        source = subprocess.check_output(['git', 'show', record['head'] +
            ':perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm']).decode()
        dispatch = source.split('sub handle_jsonrpc_request {', 1)[1].split('sub _reject_unsupported_list_cursor', 1)[0]
        assert record['methods'] == sorted(set(re.findall(r"\$method eq '([^']+)'", dispatch)))
        version = re.search(r"MCP_PROTOCOL_VERSION => '([^']+)'", source).group(1)
        assert record['initialized']['protocolVersion'] == version
        producer_path = 'docs/audits/mcp-api-reference-20261023/inventory_mcp.py'
        identities = {hashlib.sha256(local_path(ROOT, producer_path).read_bytes()).hexdigest()}
        if record['producer_sha256'] not in identities:
            revisions = subprocess.check_output(['git', 'log', '--format=%H', '--', producer_path]).decode().splitlines()
            for revision in revisions:
                raw = subprocess.check_output(['git', 'show', revision + ':' + producer_path])
                identities.add(hashlib.sha256(raw).hexdigest())
        assert record['producer_sha256'] in identities, 'Exact original producer version is unavailable'
    assert set(record['methods']) <= {r['method'] for r in requests}
    findings = []
    for exchange in record['exchanges']:
        req, response, label = exchange['request'], exchange['response'], exchange['label']
        if 'error' in response:
            message = response['error']['message']
            for category, pattern in [('private_reference', r'\b(?:ARRAY|HASH|SCALAR|CODE|GLOB)\(0x[0-9a-f]+\)'),
                                      ('private_location', r'SemanticIntrospectionMCPAdapter\.pm line \d+')]:
                if re.search(pattern, message):
                    findings.append({'kind': category, 'label': label, 'exchange_id': response['id']})
        if req['method'] != 'tools/call':
            continue
        name = req['params']['name']
        if name not in tools:
            continue
        arguments = req['params']['arguments']
        input_errors = errors(arguments, tools[name]['inputSchema'])
        if 'result' in response:
            if input_errors:
                findings.append({'kind': 'invalid_arguments_accepted', 'label': label,
                                 'exchange_id': response['id'], 'errors': input_errors})
            output_errors = errors(response['result']['structuredContent'], tools[name]['outputSchema'])
            if output_errors:
                findings.append({'kind': 'output_schema_mismatch', 'label': label,
                                 'exchange_id': response['id'], 'errors': output_errors})
        elif label.startswith('base:') and not input_errors:
            findings.append({'kind': 'schema_admitted_base_refused', 'label': label,
                             'exchange_id': response['id'], 'error': response['error']})
    return {'tools': len(tools), 'resources': len(record['resources']), 'templates': len(record['templates']),
            'methods': len(record['methods']), 'exchanges': len(record['exchanges']),
            'selected_source_files': len(record['selected_source_sha256']), 'findings': findings}


def controls(record):
    assert not is_type(True, 'integer') and not is_type(False, 'number')
    assert is_type(1.0, 'integer') and not is_type('1', 'integer')
    assert not errors(1.0, {'type': 'integer', 'enum': [1]})
    assert errors(True, {'type': 'integer', 'enum': [1]})
    assert errors(False, {'enum': [0]}) and not errors({'n': [1.0]}, {'const': {'n': [1]}})
    mutations = {}
    mutations['missing_tool'] = dict(record, tools=record['tools'][:-1])
    extra = dict(record['tools'][0], name='fsmgen_unpublished_extra')
    mutations['extra_tool'] = dict(record, tools=record['tools'] + [extra])
    sections = dict(record['capability_sections']); sections.pop('manifest_schema_version')
    mutations['missing_section'] = dict(record, capability_sections=sections)
    fields = copy.deepcopy(record['field_rows'])
    fields['fsmgen_check']['inputs'].pop()
    mutations['missing_field'] = dict(record, field_rows=fields)
    fields = copy.deepcopy(record['field_rows'])
    fields['fsmgen_check']['inputs'][0]['schema'] = {'type': 'array'}
    mutations['borrowed_field_type'] = dict(record, field_rows=fields)
    identities = dict(record['selected_source_sha256']); identities['bin/fsmgen'] = '0' * 64
    mutations['stale_source_hash'] = dict(record, selected_source_sha256=identities)
    mutations['lost_wire_reply'] = dict(record, received_utf8='\n'.join(record['received_utf8'].splitlines()[:-1]) + '\n')
    exchanges = copy.deepcopy(record['exchanges'][:1]) + record['exchanges'][1:]
    exchanges[0]['response']['id'] = True
    replies = record['received_utf8'].splitlines()
    first = json.loads(replies[0]); first['id'] = True; replies[0] = json.dumps(first)
    mutations['boolean_request_identity'] = dict(record, exchanges=exchanges, received_utf8='\n'.join(replies) + '\n')
    outcomes = {}
    for name, candidate in mutations.items():
        try:
            verify(candidate, check_git=name == 'stale_source_hash')
        except AssertionError:
            outcomes[name] = 'rejected'
        else:
            raise AssertionError('Adverse census candidate accepted: ' + name)
    return outcomes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', help='repository-relative saved JSON or JSON.gz')
    parser.add_argument('--controls', action='store_true')
    args = parser.parse_args()
    path = local_path(ROOT, args.capture)
    raw = path.read_bytes()

    def reject_constant(value):
        raise ValueError('Invalid JSON constant: ' + value)

    record = json.loads(gzip.decompress(raw) if path.suffix == '.gz' else raw, parse_constant=reject_constant)
    result = verify(record)
    if args.controls:
        result['adverse_controls'] = controls(record)
    result['capture_sha256'] = hashlib.sha256(raw).hexdigest()
    result['reader_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    result['scope'] = ('Exact saved source/wire/field custody and the emitted schema keyword subset; '
                       'findings are retained, not treated as successful conformance.')
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == '__main__':
    main()
