#!/usr/bin/env python3
"""Independently verify root topology, native bindings, exact sources and omissions."""
import ast
import base64
import copy
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

from verify_diagnostic_limits import verify_metadata_packet
from verify_error_context import source

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'scripts'))
from generate_pod_reference import local_path

COLLECTOR = 'docs/audits/mcp-api-reference-20261023/capture_model_roots.py'
ADAPTER = 'perl/FSM/Support/SemanticIntrospectionMCPAdapter.pm'
ALIASES = {'all', 'contracts', 'examples', 'vial_tooling_v1', 'vial_tooling_v2', 'vial_inspection'}


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True, separators=(',', ':'))


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def read(path):
    return json.loads(gzip.decompress(path.read_bytes()))


def capture_check(record):
    assert re.fullmatch('[0-9a-f]{40}', record['head'])
    verify_metadata_packet(record)
    paths = {p for p in subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', record['head'],
             'perl']).decode().splitlines() if p.endswith('.pm')} | {
        'README.md', 'bin/fsmgen', 'bin/fsmgen-mcp', COLLECTOR, 'scripts/generate_pod_reference.py',
        't/python/test_fixture_mcp_stdio.py', 't/python/test_fixture_mcp_metadata_schemas.py'}
    assert set(record['source_sha256']) == paths, 'selected source population mismatch'
    for path in paths:
        source(record, path)
    identity = record['capture_identity']
    assert identity['owner'] == 'PERL-POD-API-REFERENCE.6.1.2.3.1'
    raw_path, native_path = [local_path(ROOT, identity[k]) for k in ('raw_capture', 'native_capture')]
    assert sha(raw_path.read_bytes()) == identity['raw_sha256'], 'raw capture identity mismatch'
    assert sha(native_path.read_bytes()) == identity['native_sha256'], 'native capture identity mismatch'
    raw, native = read(raw_path), read(native_path)
    assert canonical({k: v for k, v in record.items() if k not in ('capture_identity', 'native_api')}) == canonical(raw), 'raw capture join failed'
    assert native['head'] == record['head'] and native['source_sha256'] == record['source_sha256']
    assert native['mcp_raw_capture'] == identity['raw_capture'] and native['mcp_raw_sha256'] == identity['raw_sha256']
    assert type(native['exit_status']) is int and native['exit_status'] == 0
    assert base64.b64decode(native['stderr_base64'], validate=True) == b''
    assert canonical(json.loads(base64.b64decode(native['stdout_base64'], validate=True))) == canonical(record['native_api'])
    program = [ast.literal_eval(n.value) for n in ast.parse(source(record, COLLECTOR).decode()).body
               if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'NATIVE_PROGRAM' for t in n.targets)]
    assert program == [native['program']], 'native program custody mismatch'
    assert identity['python']['implementation'] and len(identity['python']['version']) == 5
    assert identity['perl_runtime']['perl'].startswith('v') and identity['perl_runtime']['json_pp']
    ex = record['exchanges']
    assert [e['request']['method'] for e in ex[:4]] == ['initialize', 'tools/list', 'resources/list', 'resources/templates/list']
    resources, tool_list, templates = (ex[i]['response']['result'][k] for i, k in
                                      ((2, 'resources'), (1, 'tools'), (3, 'resourceTemplates')))
    uris = [r['uri'] for r in resources]
    assert len(uris) == len(set(uris))
    results = {}
    for e in ex[4:4 + len(uris) + 2]:
        request, contents = e['request'], e['response']['result']['contents']
        assert request['method'] == 'resources/read' and len(contents) == 1
        uri = request['params']['uri']
        assert contents[0]['uri'] == uri and contents[0]['mimeType'] == 'application/json'
        assert uri not in results
        results[uri] = json.loads(contents[0]['text'])
    assert list(results) == uris + ['fsmgen://vial/1/capabilities', 'fsmgen://vial/2/capabilities']
    m = record['native_api']['manifest']
    assert canonical(results['fsmgen://capabilities']) == canonical(m), 'native/manifest mismatch'
    contract = m['semantic_introspection']
    assert canonical(record['native_api']['source_query_kinds']) == canonical(contract['source_query_kinds'])
    assert set(m['manifest_contract']['public_top_level_presence_keys']) <= set(m)
    assert set(m['manifest_contract']['top_level_contract_source_map']) == set(m) - {'manifest_contract', 'manifest_schema_version'}
    assert {t['name'] for t in tool_list} == set(contract['mcp_tool_names']) == {t['name'] for t in contract['mcp_tools']}
    assert len(tool_list) == len({t['name'] for t in tool_list})
    assert {r['uriTemplate'] for r in templates} == set(contract['mcp_resource_uri_templates'])
    assert len(templates) == len({r['uriTemplate'] for r in templates})
    assert set(uris) == {d['uri_template'] for d in contract['mcp_resources'] if not d['source_bound'] and '{' not in d['uri_template']}
    for version in (1, 2):
        assert canonical(results['fsmgen://vial/%d/capabilities' % version]) == canonical(record['native_api']['vial_tooling_v%d' % version])
    calls = ex[4 + len(uris) + 2:]
    assert [c['request']['params']['arguments']['section'] for c in calls] == sorted(set(m) | ALIASES)
    for e in calls:
        request, result = e['request'], e['response']['result']
        section = request['params']['arguments']['section']
        assert request['method'] == 'tools/call' and request['params']['name'] == 'fsmgen_capability_query'
        assert result['isError'] is False and len(result['content']) == 1 and result['content'][0]['type'] == 'text'
        value = result['structuredContent']
        assert canonical(json.loads(result['content'][0]['text'])) == canonical(value)
        if section == 'all':
            expected = m
        elif section == 'contracts':
            expected = {'manifest_contract': m['manifest_contract'], 'semantic_introspection': contract}
        elif section == 'examples':
            expected = results['fsmgen://examples']
        else:
            payload = record['native_api'].get(section, m.get(section))
            expected = {'section': section, 'payload': payload}
        assert canonical(value) == canonical(expected), 'native/selector mismatch'
    assert canonical(results['fsmgen://contracts']) == canonical({'manifest_contract': m['manifest_contract'], 'semantic_introspection': contract})
    assert canonical(results['fsmgen://diagnostics']) == canonical(m['diagnostics'])
    assert canonical(results['fsmgen://support-accounting']) == canonical(m['support_accounting'])
    assert contract['read_only_default'] is True and contract['write_generation_tools_enabled'] is False
    return m, tool_list


def expected_values(record):
    result = {}
    for e in record['exchanges']:
        q, value = e['request'], e['response']['result']
        if q['method'] == 'resources/read':
            result['resource:' + q['params']['uri']] = (q['id'], 'decoded resource content', json.loads(value['contents'][0]['text']))
        elif q['method'] == 'tools/call':
            section, value = q['params']['arguments']['section'], value['structuredContent']
            result['selector:' + section] = (q['id'], 'structuredContent', value)
            if section not in ('all', 'contracts', 'examples'):
                result['selector:' + section + '/payload'] = (q['id'], 'wrapped payload', value['payload'])
        else:
            result['method:' + q['method']] = (q['id'], 'JSON-RPC result', value)
    return result


def verify(record, graph):
    m, tools = capture_check(record)
    assert graph['owner'] == 'PERL-POD-API-REFERENCE.6.1.2.3.1' and graph['head'] == record['head']
    assert graph['scope'] == 'root topology and declarations, not semantic documentation completion'
    assert sha(graph['projector_source'].encode()) == graph['projector_source_sha256']
    assert graph['projector_path_guard_sha256'] == record['source_sha256']['scripts/generate_pod_reference.py']
    values = expected_values(record)
    observed = {r['id']: r for r in graph['observed_roots']}
    assert len(observed) == len(graph['observed_roots']) and set(observed) == set(values), 'observed root population mismatch'
    for identity, (exchange, layer, value) in values.items():
        row = observed[identity]
        assert row['exchange_id'] == exchange and row['layer'] == layer
        assert row['value_sha256'] == sha(canonical(value).encode()), 'observed root binding mismatch'
        kind = {dict: 'object', list: 'array', str: 'string', bool: 'boolean', int: 'integer', float: 'number', type(None): 'null'}[type(value)]
        assert row['value_kind'] == kind and row['top_level_keys'] == (sorted(value) if isinstance(value, dict) else [])
        expected_availability = 'observed discovery/lifecycle' if identity.startswith('method:') else 'observed metadata'
        assert row['availability'] == expected_availability, 'root availability classification changed'
        assert row['field_semantics'] == 'pending dedicated model/documentation census', 'premature field completion'
    contract = m['semantic_introspection']
    declared = {d['id']: d for d in graph['declared_result_roots']}
    wanted = {'tool:' + t['name'] for t in tools} | {'template:' + r['uri_template'] for r in contract['mcp_resources']}
    assert set(declared) == wanted and len(declared) == len(graph['declared_result_roots']), 'declared root population mismatch'
    domains = {d['name']: d for d in contract['query_domains']}
    families = {f['name']: f for f in contract['query_families']}
    for tool in tools:
        row = declared['tool:' + tool['name']]
        native = next(d for d in contract['mcp_tools'] if d['name'] == tool['name'])
        family = families[native['query_family']]
        surfaces = []
        for name in family['query_domains']:
            for surface in domains[name]['contract_surfaces']:
                if surface not in surfaces:
                    surfaces.append(surface)
        owners = list(dict.fromkeys(contract['contract_surface_map'][s]['contract_source'] for s in surfaces))
        assert row['query_family'] == family['name'] and row['query_domains'] == family['query_domains']
        assert row['contract_surfaces'] == surfaces and row['contract_sources_from_domains'] == owners, 'tool domain/owner join mismatch'
        assert row['tool_declaration'] == native and canonical(row['output_schema']) == canonical(tool['outputSchema'])
        assert row['source_bound'] is any(domains[n]['requires_source_identity'] for n in family['query_domains'])
        assert row['binding'] == 'tools/call structuredContent'
        assert row['availability'] == 'published declaration; this audit executes capability queries only'
        assert row['field_semantics'] == 'pending dedicated census'
    for template in contract['mcp_resources']:
        row = declared['template:' + template['uri_template']]
        assert row['output_contract_source'] == template['output_contract_source'] and row['contract_surfaces'] == template['contract_surfaces']
        assert row['source_bound'] is template['source_bound']
        assert row['binding'] == 'decoded resource content'
        assert row['availability'] == 'published declaration; source-bound instances not executed here'
        assert row['field_semantics'] == 'pending dedicated census'
    assert canonical(graph['contract_surface_map']) == canonical(contract['contract_surface_map']), 'contract surface graph mismatch'
    assert canonical(graph['manifest_root_owner_map']) == canonical(m['manifest_contract']['top_level_contract_source_map'])
    assert graph['raw_private_surfaces_excluded'] == contract['raw_private_surfaces_excluded']
    assert graph['read_only_default'] is True and graph['write_generation_tools_enabled'] is False

    # Independently traverse by work stack, retaining every occurrence and
    # JSON-pointer location rather than comparing just aggregate totals.
    owners, slots, labels = [], [], []
    stack = [(root, value, '', '', False) for root, (_, _, value) in values.items()]
    while stack:
        root, value, path, field, owner_map = stack.pop()
        if isinstance(value, str) and re.fullmatch(r'FSM(?:::[A-Za-z_][A-Za-z0-9_]*)+', value):
            module = 'perl/' + value.replace('::', '/') + '.pm'
            role = 'contract_owner' if field.endswith('contract_source') or owner_map else 'producer' if field == 'report_source' else 'namespace_reference'
            owners.append({'root': root, 'pointer': path, 'identifier': value, 'role': role,
                           'selected_source': module if module in record['source_sha256'] else None})
        if isinstance(value, str) and value.startswith('fsmgen.'):
            labels.append({'root': root, 'pointer': path, 'label': value, 'status': 'schema-namespace occurrence; meaning not inferred'})
        children = value.items() if isinstance(value, dict) else enumerate(value) if isinstance(value, list) else []
        for key, item in children:
            p = path + '/' + str(key).replace('~', '~0').replace('/', '~1')
            if isinstance(value, dict) and 'schema' in key.lower():
                kind = {dict:'object', list:'array', str:'string', bool:'boolean', int:'integer', float:'number', type(None):'null'}[type(item)]
                slots.append({'root':root, 'pointer':p, 'field':key, 'value_kind':kind, 'value':item, 'status':'declared slot; interpretation pending'})
            stack.append((root, item, p, key if isinstance(value, dict) else field,
                          owner_map or (isinstance(value, dict) and key.endswith('contract_source_map'))))
    for actual, expected, message in ((graph['owner_references'], owners, 'owner reference graph mismatch'),
                                      (graph['schema_slots'], slots, 'schema slot graph mismatch'),
                                      (graph['schema_label_occurrences'], labels, 'schema namespace graph mismatch')):
        assert sorted(map(canonical, actual)) == sorted(map(canonical, expected)), message
    assert graph['unresolved_declared_owners'] == []
    assert all(o['selected_source'] is not None for o in owners if o['role'] != 'namespace_reference')
    groups = {}
    for identity, (_, _, value) in values.items():
        groups.setdefault(sha(canonical(value).encode()), []).append(identity)
    expected_groups = sorted(sorted(g) for g in groups.values() if len(g) > 1)
    assert sorted(sorted(g) for g in graph['observed_value_equivalence_groups']) == expected_groups, 'value-equivalence graph mismatch'
    return {'exchanges':len(record['exchanges']), 'selected_sources':len(record['source_sha256']),
            'observed_roots':len(values), 'declared_roots':len(wanted), 'owner_occurrences':len(owners),
            'schema_namespace_occurrences':len(labels), 'schema_slots':len(slots),
            'unresolved_declared_owners':0, 'semantics_completion':'not claimed'}


def controls(record, graph):
    rejected = []
    cases = [('missing_observed_root','observed root population mismatch'),
             ('extra_declared_root','declared root population mismatch'),
             ('borrowed_root_value','observed root binding mismatch'),
             ('wrong_tool_owner','tool domain/owner join mismatch'),
             ('wrong_owner_pointer','owner reference graph mismatch'),
             ('missing_schema_slot','schema slot graph mismatch'),
             ('promoted_field_completion','premature field completion'),
             ('promoted_execution','root availability classification changed')]
    for name, expected in cases:
        bad = copy.deepcopy(graph)
        if name == 'missing_observed_root':
            bad['observed_roots'].pop()
        elif name == 'extra_declared_root':
            row = copy.deepcopy(bad['declared_result_roots'][0]); row['id'] = 'tool:unpublished'; bad['declared_result_roots'].append(row)
        elif name == 'borrowed_root_value':
            bad['observed_roots'][0]['value_sha256'] = bad['observed_roots'][1]['value_sha256']
        elif name == 'wrong_tool_owner':
            bad['declared_result_roots'][0]['contract_sources_from_domains'] = ['FSM::Support::DocumentationContract']
        elif name == 'wrong_owner_pointer':
            bad['owner_references'][0]['pointer'] += '/different'
        elif name == 'missing_schema_slot':
            bad['schema_slots'].pop()
        elif name == 'promoted_field_completion':
            bad['observed_roots'][0]['field_semantics'] = 'complete'
        else:
            bad['observed_roots'][0]['availability'] = 'backend execution observed'
        try:
            verify(record, bad)
        except AssertionError as error:
            assert str(error) == expected, (name, str(error))
            rejected.append(name)
        else:
            raise AssertionError('Control accepted: ' + name)
    bad_record, bad_graph = copy.deepcopy(record), copy.deepcopy(graph)
    bad_record['exchanges'][0]['response']['result']['capabilities']['resources']['listChanged'] = 0
    bad_record['received_utf8'] = bad_record['received_utf8'].replace('"listChanged":false', '"listChanged":0', 1)
    row = next(r for r in bad_graph['observed_roots'] if r['id'] == 'method:initialize')
    row['value_sha256'] = sha(canonical(bad_record['exchanges'][0]['response']['result']).encode())
    try:
        verify(bad_record, bad_graph)
    except AssertionError as error:
        assert str(error) == 'raw capture join failed'
        rejected.append('coherent_boolean_to_zero')
    else:
        raise AssertionError('Boolean-to-zero counterfeit accepted')
    return rejected


if __name__ == '__main__':
    assert len(sys.argv) == 3
    capture_path, graph_path = [local_path(ROOT, arg) for arg in sys.argv[1:]]
    record, graph = read(capture_path), read(graph_path)
    assert graph['capture_path'] == capture_path.relative_to(ROOT).as_posix()
    assert graph['capture_sha256'] == sha(capture_path.read_bytes())
    result = verify(record, graph)
    result['controls'] = controls(record, graph)
    print(json.dumps(result, indent=2))
