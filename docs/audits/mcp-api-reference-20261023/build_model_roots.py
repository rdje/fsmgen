#!/usr/bin/env python3
"""Project public metadata root topology; field semantics remain a separate census."""
import gzip
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == ROOT
sys.path.insert(0, str(ROOT / 'scripts'))
from generate_pod_reference import local_path

OWNER = 'PERL-POD-API-REFERENCE.6.1.2.3.1'
MODULE_NAME = re.compile(r'FSM(?:::[A-Za-z_][A-Za-z0-9_]*)+\Z')


def encoded(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':'))


def digest(value):
    return hashlib.sha256(encoded(value).encode()).hexdigest()


def pointer(path, key):
    return path + '/' + str(key).replace('~', '~0').replace('/', '~1')


def json_kind(value):
    if value is None:
        return 'null'
    if type(value) is bool:
        return 'boolean'
    if type(value) is int:
        return 'integer'
    if type(value) is float:
        return 'number'
    if isinstance(value, str):
        return 'string'
    return 'object' if isinstance(value, dict) else 'array'


def build(record):
    exchanges = record['exchanges']
    observed, owners, schema_slots, schema_labels = [], [], [], []

    def inspect(root_id, value, path='', field='', in_owner_map=False):
        if isinstance(value, str) and MODULE_NAME.fullmatch(value):
            module = 'perl/' + value.replace('::', '/') + '.pm'
            role = ('contract_owner' if field.endswith('contract_source') or in_owner_map
                    else 'producer' if field == 'report_source' else 'namespace_reference')
            owners.append({'root': root_id, 'pointer': path, 'identifier': value, 'role': role,
                           'selected_source': module if module in record['source_sha256'] else None})
        if isinstance(value, str) and value.startswith('fsmgen.'):
            schema_labels.append({'root': root_id, 'pointer': path, 'label': value,
                                  'status': 'schema-namespace occurrence; meaning not inferred'})
        if isinstance(value, dict):
            for key in sorted(value):
                item, item_path = value[key], pointer(path, key)
                if 'schema' in key.lower():
                    schema_slots.append({'root': root_id, 'pointer': item_path, 'field': key,
                        'value_kind': json_kind(item), 'value': item,
                        'status': 'declared slot; interpretation pending'})
                inspect(root_id, item, item_path, key,
                        in_owner_map or key.endswith('contract_source_map'))
        elif isinstance(value, list):
            for i, item in enumerate(value):
                inspect(root_id, item, pointer(path, i), field, in_owner_map)

    def root(root_id, value, exchange, layer, availability):
        observed.append({'id': root_id, 'exchange_id': exchange, 'layer': layer,
            'availability': availability, 'value_kind': json_kind(value), 'value_sha256': digest(value),
            'top_level_keys': sorted(value) if isinstance(value, dict) else [],
            'field_semantics': 'pending dedicated model/documentation census'})
        inspect(root_id, value)

    for exchange in exchanges:
        request, response = exchange['request'], exchange['response']
        method, index = request['method'], request['id']
        result = response['result']
        if method == 'resources/read':
            uri = request['params']['uri']
            value = json.loads(result['contents'][0]['text'])
            root('resource:' + uri, value, index, 'decoded resource content', 'observed metadata')
        elif method == 'tools/call':
            section = request['params']['arguments']['section']
            value = result['structuredContent']
            root('selector:' + section, value, index, 'structuredContent', 'observed metadata')
            if isinstance(value, dict) and set(value) == {'section', 'payload'} and value['section'] == section:
                root('selector:' + section + '/payload', value['payload'], index,
                     'wrapped payload', 'observed metadata')
        else:
            root('method:' + method, result, index, 'JSON-RPC result', 'observed discovery/lifecycle')

    manifest = record['native_api']['manifest']
    contract = manifest['semantic_introspection']
    tools = exchanges[1]['response']['result']['tools']
    declared = []
    for tool in tools:
        declaration = next(d for d in contract['mcp_tools'] if d['name'] == tool['name'])
        family = next(f for f in contract['query_families'] if f['name'] == declaration['query_family'])
        domains = [next(d for d in contract['query_domains'] if d['name'] == name)
                   for name in family['query_domains']]
        surfaces = list(dict.fromkeys(s for d in domains for s in d['contract_surfaces']))
        sources = list(dict.fromkeys(contract['contract_surface_map'][s]['contract_source'] for s in surfaces))
        declared.append({'id': 'tool:' + tool['name'], 'binding': 'tools/call structuredContent',
            'contract_sources_from_domains': sources, 'contract_surfaces': surfaces,
            'query_family': family['name'], 'query_domains': family['query_domains'],
            'tool_declaration': declaration,
            'output_schema': tool.get('outputSchema'),
            'source_bound': any(d['requires_source_identity'] for d in domains),
            'availability': 'published declaration; this audit executes capability queries only',
            'field_semantics': 'pending dedicated census'})
    for item in contract['mcp_resources']:
        declared.append({'id': 'template:' + item['uri_template'], 'binding': 'decoded resource content',
            'output_contract_source': item['output_contract_source'],
            'contract_surfaces': item['contract_surfaces'], 'source_bound': item['source_bound'],
            'availability': 'published declaration; source-bound instances not executed here',
            'field_semantics': 'pending dedicated census'})

    by_value = {}
    for item in observed:
        by_value.setdefault(item['value_sha256'], []).append(item['id'])
    unresolved = [o for o in owners if o['role'] != 'namespace_reference' and o['selected_source'] is None]
    return {'owner': OWNER, 'scope': 'root topology and declarations, not semantic documentation completion',
        'head': record['head'], 'observed_roots': observed, 'declared_result_roots': declared,
        'owner_references': owners, 'schema_label_occurrences': schema_labels, 'schema_slots': schema_slots,
        'observed_value_equivalence_groups': [v for _, v in sorted(by_value.items()) if len(v) > 1],
        'unresolved_declared_owners': unresolved,
        'manifest_root_owner_map': manifest['manifest_contract']['top_level_contract_source_map'],
        'contract_surface_map': contract['contract_surface_map'],
        'raw_private_surfaces_excluded': contract['raw_private_surfaces_excluded'],
        'read_only_default': contract['read_only_default'],
        'write_generation_tools_enabled': contract['write_generation_tools_enabled'],
        'interpretation': [
            'A metadata reference to a separate CLI/library API is not an enabled MCP operation.',
            'Source/report templates are declared here; their deeper fields and evidence are successor censuses.',
            'Presence-key families are bounded required surfaces, not automatically closed exhaustive object schemas.',
            'Schema-labelled slots and namespace strings need dedicated interpretation, not automatic API promotion.',
            'Value-equal roots are an observation, not a promise that different operations have identical contracts.',
        ]}


if __name__ == '__main__':
    assert len(sys.argv) == 3, 'Usage: build_model_roots.py INPUT.json.gz OUTPUT.json.gz'
    input_path, output = [local_path(ROOT, name) for name in sys.argv[1:]]
    assert not output.exists()
    raw = input_path.read_bytes()
    graph = build(json.loads(gzip.decompress(raw)))
    graph['capture_path'] = input_path.relative_to(ROOT).as_posix()
    graph['capture_sha256'] = hashlib.sha256(raw).hexdigest()
    graph['projector_source_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    graph['projector_source'] = Path(__file__).read_text()
    graph['projector_path_guard_sha256'] = hashlib.sha256((ROOT / 'scripts/generate_pod_reference.py').read_bytes()).hexdigest()
    output.write_bytes(gzip.compress((json.dumps(graph, indent=2, ensure_ascii=False) + '\n').encode(), mtime=0))
    print('Root topology retained: ' + output.relative_to(ROOT).as_posix())
