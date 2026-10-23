#!/usr/bin/env python3
"""Capture the complete published MCP metadata surface through a live pipe."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == ROOT
sys.path.insert(0, str(ROOT / 't/python'))
from test_fixture_mcp_stdio import Session
sys.path.insert(0, str(ROOT / 'scripts'))
from generate_pod_reference import local_path


def fingerprint():
    paths = subprocess.check_output(['git', 'ls-files', '-z', '--', 'perl/FSM']).decode().split('\0')
    paths = [p for p in paths if p.endswith('.pm')]
    paths += ['bin/fsmgen', 'bin/fsmgen-mcp', 't/python/test_fixture_mcp_stdio.py',
              't/fixtures/semantic_introspection_mcp/read_only_schema_snapshot.json',
              'docs/book/src/11-extensions-and-embedding.md', 'docs/book/src/11a-perl-api-reference.md',
              'docs/VIAL_SOURCE_INSPECTION_CONTRACT.md']
    result = {}
    for name in sorted(paths):
        raw = local_path(ROOT, name).read_bytes()
        committed = subprocess.check_output(['git', 'show', 'HEAD:' + name])
        assert raw == committed, 'Capture boundary source differs from HEAD: ' + name
        result[name] = hashlib.sha256(raw).hexdigest()
    return result


def properties(schema, prefix=''):
    result = []
    for name, child in sorted(schema.get('properties', {}).items()):
        path = prefix + '/' + name
        result.append({'path': path, 'required': name in schema.get('required', []), 'schema': child})
        result.extend(properties(child, path))
    return result


def kind(value):
    if value is None:
        return 'null'
    if type(value) is bool:
        return 'boolean'
    if type(value) is int:
        return 'integer'
    if type(value) is float:
        return 'number'
    return {str: 'string', list: 'array', dict: 'object'}[type(value)]


before = fingerprint()
exchanges = []
with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
    def request(method, params=None, label=None):
        value = {'jsonrpc': '2.0', 'id': len(exchanges) + 1, 'method': method}
        if params is not None:
            value['params'] = params
        server.send(value)
        response = server.receive(timeout=30)
        assert type(response['id']) is int and response['id'] == value['id']
        exchanges.append({'label': label or method, 'request': value, 'response': response})
        return response

    def result(method, params=None, label=None):
        value = request(method, params, label)
        assert 'result' in value, value
        return value['result']

    def tool(name, arguments, label=None):
        return request('tools/call', {'name': name, 'arguments': arguments}, label)

    initialized = result('initialize', {'protocolVersion': '2025-06-18', 'capabilities': {},
                         'clientInfo': {'name': 'fsmgen-reference-census', 'version': '1'}})
    server.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
    result('ping')
    tools = result('tools/list')['tools']
    resources = result('resources/list')['resources']
    templates = result('resources/templates/list')['resourceTemplates']
    static_payloads = {}
    for row in resources:
        contents = result('resources/read', {'uri': row['uri']}, 'static:' + row['uri'])['contents']
        assert len(contents) == 1 and contents[0]['uri'] == row['uri']
        static_payloads[row['uri']] = json.loads(contents[0]['text'])
    manifest = static_payloads['fsmgen://capabilities']
    contract = manifest['semantic_introspection']
    sections = {}
    section_names = set(manifest) | {'all', 'contracts', 'examples', 'vial_tooling_v1',
                                    'vial_tooling_v2', 'vial_inspection'}
    for name in sorted(section_names):
        response = tool('fsmgen_capability_query', {'section': name}, 'section:' + name)
        assert 'result' in response, response
        payload = response['result']['structuredContent']
        assert json.loads(response['result']['content'][0]['text']) == payload
        sections[name] = {'result_kind': kind(payload),
                          'payload_kind': kind(payload['payload']) if 'payload' in payload else None,
                          'exchange_id': response['id']}

    bases = {
        'fsmgen_capability_query': {'section': 'semantic_introspection'},
        'fsmgen_discover_sources': {'limit': 2}, 'fsmgen_find_examples': {'limit': 2},
        'fsmgen_explain_diagnostic': {'code': 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE'},
        'fsmgen_support_summary': {'limit_examples': 2},
        'fsmgen_check': {}, 'fsmgen_semantic_introspect': {},
        'fsmgen_schedule_preview': {}, 'fsmgen_vial_inspect': {},
    }
    assert set(bases) == {r['name'] for r in tools}, 'Every published tool needs explicit census cases'
    for name, base in sorted(bases.items()):
        tool(name, base, 'base:' + name)
        tool(name, dict(base, unpublished_argument=True), 'extra-argument:' + name)
    invalid_fields = {'fsmgen_capability_query': 'section', 'fsmgen_discover_sources': 'query',
                      'fsmgen_find_examples': 'query', 'fsmgen_explain_diagnostic': 'code',
                      'fsmgen_support_summary': 'limit_examples'}
    for name, field in invalid_fields.items():
        tool(name, dict(bases[name], **{field: []}), 'wrong-type:' + name)
    for name, field in [('fsmgen_discover_sources', 'limit'), ('fsmgen_find_examples', 'limit'),
                        ('fsmgen_support_summary', 'limit_examples'), ('fsmgen_explain_diagnostic', 'limit_examples')]:
        for limit in (0, 1, 101, -1):
            tool(name, dict(bases[name], **{field: limit}), f'limit:{name}:{limit}')
    for method in ('tools/list', 'resources/list', 'resources/templates/list'):
        request(method, {'cursor': None}, 'cursor:' + method)
    request('resources/read', {'uri': 'fsmgen://unsupported'}, 'unknown-resource')
    request('tools/call', {'name': 'fsmgen_not_a_tool', 'arguments': {}}, 'unknown-tool')
    request('not/a/method', {}, 'unknown-method')
    sent, received = bytes(server.sent), bytes(server.received)

assert server.process.returncode == 0
assert fingerprint() == before, 'Census inputs changed during collection'
assert {r['name'] for r in tools} == set(contract['mcp_tool_names'])
assert {r['uriTemplate'] for r in templates} == set(contract['mcp_resource_uri_templates'])
assert {r['uri'] for r in resources} == {uri for uri in contract['mcp_resource_uri_templates'] if '{' not in uri}
source = (ROOT / 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm').read_text()
dispatch = source.split('sub handle_jsonrpc_request {', 1)[1].split('sub _reject_unsupported_list_cursor', 1)[0]
methods = sorted(set(re.findall(r"\$method eq '([^']+)'", dispatch)))
assert set(methods) <= {r['request']['method'] for r in exchanges}
field_rows = {r['name']: {'inputs': properties(r['inputSchema']), 'outputs': properties(r['outputSchema'])}
              for r in tools}
print(json.dumps({'head': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
                  'producer_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  'selected_source_sha256': before, 'source_scope': 'All tracked repository-owned FSM .pm files, launchers, client and selected schema/docs; external toolchain binaries/modules are not fully fingerprinted.',
                  'python_version': list(sys.version_info), 'initialized': initialized,
                  'tools': tools, 'resources': resources, 'templates': templates, 'methods': methods,
                  'contract_surface_map': contract['contract_surface_map'],
                  'source_query_kinds': contract['source_query_kinds'], 'field_rows': field_rows,
                  'capability_sections': sections, 'exchanges': exchanges,
                  'sent_utf8': sent.decode(), 'received_utf8': received.decode(),
                  'transport_exit_status': server.process.returncode, 'orderly_eof': True,
                  'limit': 'Metadata/source-applicability census only; no hardware/source compiler epoch or temporal execution was run.'},
                 indent=2, sort_keys=True))
