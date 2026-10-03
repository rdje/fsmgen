"""Finite independent causes, mutations, identities/kinds and counterfactuals.

Wider constructors/child/controller/report internals remain cold observations.
Observed runtime root coordinates use a repository-derived marker.
"""
import copy
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
B = Path(__file__).parent
REV = 'f1b7748253715b1ca3659046baf1f79481fc2753'
def load(name): return json.loads((B / name).read_text())
def same(a, b):
    assert json.dumps(a, sort_keys=True, separators=(',', ':')) == json.dumps(
        b, sort_keys=True, separators=(',', ':')), 'value, kind or field mismatch'
def source(path):
    return subprocess.check_output(['git', 'show', REV + ':' + path]).decode()
test = source('t/1947-isf-formal-reusable-products.t')
mixed = re.search(r"my \$mixed = <<'ISF';\n(.*?)\nISF", test, re.S)[1] + '\n'
atl = source('isf/atl_resolved_child_pipeline.isf')
width_source = mixed.replace('(transaction worker',
    '(storage (var payload (width 8))) (transaction worker')
bindings = load('bindings.json')
assert set(bindings) == {'baseline', 'metadata', 'sources'} and bindings['baseline'] == REV
paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REV, '--',
    'bin', 'perl', 't', 'scripts', 'isf']).decode().splitlines()
assert set(bindings['metadata']) == set(paths)
hashes = subprocess.check_output(['git', 'hash-object', '--stdin-paths'],
    input=('\n'.join(paths) + '\n').encode()).decode().splitlines()
gitrows = subprocess.check_output(['git', 'ls-tree', '-r', REV, '--',
    'bin', 'perl', 't', 'scripts', 'isf']).decode().splitlines()
wanted_hashes = {r.split('\t', 1)[1]: r.split()[2] for r in gitrows}
for path, digest in zip(paths, hashes):
    raw = Path(path).read_bytes()
    same(bindings['metadata'][path], {'bytes': len(raw),
        'sha256': hashlib.sha256(raw).hexdigest()})
    assert digest == wanted_hashes[path]
for path, body in bindings['sources'].items():
    assert body == Path(path).read_text() == source(path)
ids = [
    ('missing library module', 'missing a generated module name', 'mixed',
     "Library use 'rx' is missing a generated module name"),
    ('library versus generated module collision', 'conflicts with another generated child', 'mixed',
     "Library use 'rx' generated module 'worker' conflicts with another generated child"),
    ('missing library actor', 'does not carry a reusable actor shell', 'mixed',
     "Library use 'rx' does not carry a reusable actor shell"),
    ('missing resolved ATL module', 'missing a generated module name', 'atl',
     "ATL static actor instance 'worker' is missing a generated module name"),
    ('unsupported ATL group composition',
     'cannot combine generated child wiring with static group metadata', 'atl',
     "ATL generated top for actor 'atl_resolved_child_pipeline' cannot combine generated child wiring with static group metadata in the current subset"),
]
bands = ('current_fixture', 'earlier_target', 'primary_target_echo')
actor_keys = set('actor_name actor_network clock clock_domains constant_symbols constants crossings drives enum_declarations enum_symbols handshakes imports interface interface_port_metadata library_uses package_imports package_roots params phases priorities procs reset reset_provenance resources rules stages storage transactions type_declarations type_symbols uses verification_bridge verification_observations watchdog'.split())
main_clauses = [['on', 'fire'], ['spawn', 'worker', 'as', 'job'],
    ['await_all', 'done'], ['wait', 'payload'], ['complete', 'done']]
atl_clauses = [['on', 'start'], ['atl_trigger', 'worker_process_start'],
    ['await', 'worker_done'], ['complete', 'done']]
def verify_rows(data):
    assert set(data) == {'rows'} and len(data['rows']) == 33
    roster = [(ident, wanted, kind, cause, band, method)
        for ident, wanted, kind, cause in ids for band in bands
        for method in ('prepare_formal_source', 'build_module')]
    roster += [('raw parent width conflict', 'width/payload regex', 'mixed',
        "signal width for 'payload' conflicts across transactions while merging 'main'",
        band, 'build_module') for band in bands]
    anchors = {}
    for row, (ident, wanted, kind, cause, band, method) in zip(data['rows'], roster):
        assert set(row) == set('id wanted kind source band method actor_before actor_after error pattern matched primary_matched'.split())
        raw_width = ident == 'raw parent width conflict'
        same([row[k] for k in ('id', 'wanted', 'kind', 'source', 'band', 'method')],
            [ident, wanted, kind, width_source if raw_width else mixed if kind == 'mixed' else atl,
             band, method])
        actor = row['actor_before']
        assert set(actor) == actor_keys | ({'_atl_actor_type_resolutions'} if kind == 'atl' else set())
        same(actor['actor_name'], 'mixed_children' if kind == 'mixed' else 'atl_resolved_child_pipeline')
        tx = actor['transactions'][-1]
        same(tx['name'], 'main' if kind == 'mixed' else 'run')
        clauses = copy.deepcopy(main_clauses if kind == 'mixed' else atl_clauses)
        target = 'width payload' if raw_width else wanted
        if band != 'current_fixture':
            clauses.insert(0, ['spawn', target if band == 'primary_target_echo' else 'missing_child',
                               'as', 'wrong_job'])
        same(tx['clauses'], clauses)
        same(tx['ports'], {'inputs': [{'name': 'payload', 'width': 4}], 'outputs': []}
             if kind == 'mixed' else {'inputs': [], 'outputs': []})
        if kind == 'mixed' and not raw_width:
            use = actor['library_uses'][0]
            same(use['instance'], 'rx')
            if ident == 'missing library module': assert 'module' not in use
            elif ident == 'library versus generated module collision': same(use['module'], 'worker')
            elif ident == 'missing library actor': assert 'actor' not in use
        if kind == 'atl':
            assert set(actor['_atl_actor_type_resolutions']) == {'worker'}
            if ident == 'missing resolved ATL module':
                assert 'module' not in actor['_atl_actor_type_resolutions']['worker']
            same(actor['actor_network']['groups'],
                 [{'name': 'grouped'}] if ident == 'unsupported ATL group composition' else [])
        # Complete cross-band mutation closure. Original constructor internals
        # remain observations, not a second parser implementation.
        if band == 'current_fixture':
            if ident in anchors: same(actor, anchors[ident])
            else: anchors[ident] = copy.deepcopy(actor)
        else:
            expected = copy.deepcopy(anchors[ident])
            expected['transactions'][-1]['clauses'].insert(0, clauses[0])
            same(actor, expected)
        same(row['actor_after'], actor)
        primary = cause if band == 'current_fixture' else (
            f"Transaction '{tx['name']}': spawn target '{target if band == 'primary_target_echo' else 'missing_child'}' is not a declared transaction")
        assert row['error'].splitlines()[0] == primary and "\teval '" not in row['error']
        same(row['matched'], int(not raw_width or band != 'earlier_target'))
        same(row['primary_matched'], int(band != 'earlier_target'))
        pattern = '(?^s:(?:width|Width).*payload|payload.*(?:width|Width))' if raw_width else '(?^:' + wanted + ')'
        same(row['pattern'], pattern)
data = load('causes.json'); verify_rows(data)
same(json.loads(subprocess.check_output(['perl', str(B / 'replay.pl')])),
     [{k: r[k] for k in ('matched', 'primary_matched', 'pattern')} for r in data['rows']])
if '--trust-helper' in sys.argv:
    assert all(r['matched'] == int(r['band'] == 'current_fixture') for r in data['rows'][:30]), 'twenty actual helper false matches'
if '--trust-primary' in sys.argv:
    assert all(r['primary_matched'] == int(r['band'] == 'current_fixture') for r in data['rows'][:30]), 'ten actual primary fragment echoes'
if '--trust-direct' in sys.argv:
    assert all(r['matched'] == int(r['band'] == 'current_fixture') for r in data['rows'][30:]), 'one actual direct primary echo'
prepkeys = set('actor actor_context deferred_formal_collisions domain_partition domain_source_products generated_child_products generated_children parent_activation_products parent_completion_products parent_named_completion_products parent_payload_snapshot_products parent_point_products parent_storage_read_products parent_storage_write_products parent_wiring_products pruned_transactions resource_signal_products reusable_child_products transaction_binding_report_products transaction_products transactions'.split())
modulekeys = set('actor_name actor_network actor_phases actor_stages assignment_provenance atl_top_instances bank_accesses children clock compatible_fanin_groups conflict_issues constants counters declared_storage dt_blocks enum_declarations explicit_interface_ports explicit_internal_signals immediate_assertions interface_port_metadata library_uses logical_controllers output_defaults package_imports package_roots params ports priority_resolution reset reset_provenance reset_values resource_activation resource_arbitration signal_type_refs signal_widths spawn_instances states storage_roles temporal_contracts transaction_port_bindings type_declarations verification_bridge verification_observations watchdog'.split())
ordinary_ids = ['fifo_library_use', 'atl_resolved_child_pipeline',
    'atl_resolved_child_pin_ingress_vector_multi_pipeline',
    'atl_resolved_child_pin_egress_vector_multi_pipeline',
    'atl_two_child_vector_data_pipeline', 'atl_two_child_trigger_batch_pipeline',
    'mixed', 'external', 'raw_width']
width_cases = {'atl_resolved_child_pin_egress_vector_multi_pipeline': [('worker', 0, 8), ('worker', 1, 4)],
               'atl_two_child_vector_data_pipeline': [('reader', 0, 8)]}
def caller_after(original, ident):
    expected = copy.deepcopy(original)
    for instance, index, width in width_cases.get(ident, []):
        port = expected['_atl_actor_type_resolutions'][instance]['actor']['interface']['outputs'][index]
        same(port['width'], str(width)); port['width'] = width
    return expected
def products_of(module, generated):
    return {'children': {k: v for k, v in module['children'].items() if k not in generated},
            'library_uses': module['library_uses'], 'atl_top_instances': module['atl_top_instances']}
def verify_products(products, pure=False):
    assert set(products) == {'rows'} and len(products['rows']) == 9
    for row, ident in zip(products['rows'], ordinary_ids):
        assert set(row) == set('id source actor original input_equal prepared_actor_equal prepared physical module physical_module reprepared physical_equal repreprepared_equal'.replace('repreprepared_equal', 'reprepared_equal').split())
        same(row['id'], ident)
        expected_source = mixed if ident == 'mixed' else width_source if ident == 'raw_width' else (
            '(actor external (instance reader of packet_reader) (transaction main (wait 1)))'
            if ident == 'external' else source('isf/' + ident + '.isf'))
        same(row['source'], expected_source); same(row['actor'], caller_after(row['original'], ident))
        p = row['prepared']; q = row['reprepared']; generated = {'worker': 1} if ident in ('mixed', 'raw_width') else {}
        assert set(p) == set(q) == prepkeys
        same(p['actor'], row['original']); same(p['generated_children'], generated)
        same(sorted(p['generated_child_products']), sorted(generated))
        same(row['prepared_actor_equal'], 1); same(row['input_equal'], int(ident not in width_cases))
        r = p['reusable_child_products']; assert set(r) == {'children', 'library_uses', 'atl_top_instances'}
        parent = 'mixed_children' if ident in ('mixed', 'raw_width') else ident
        instances = ['u_fifo'] if ident == 'fifo_library_use' else ['rx'] if ident in ('mixed', 'raw_width') else [] if ident == 'external' else ['reader', 'writer'] if ident.startswith('atl_two_child_') else ['worker']
        same(sorted(r['children']), sorted(parent + '__' + i for i in instances))
        same(len(r['library_uses']), int(ident in ('fifo_library_use', 'mixed', 'raw_width')))
        same(len(r['atl_top_instances']), int(ident.startswith('atl_')))
        for name, child in r['children'].items():
            same(child['actor_name'], name)
            instance = name[len(parent) + 2:]
            expected_origin = {'parent_actor': parent, 'instance': instance,
                'library': 'common.fifo' if ident == 'fifo_library_use' else 'common.pulse' if ident in ('mixed', 'raw_width') else 'common.packet',
                'export': 'fifo' if ident == 'fifo_library_use' else 'pulse_actor' if ident in ('mixed', 'raw_width') else 'packet_' + instance if ident.startswith('atl_two_child_') else 'packet_worker',
                'library_source': '${REPO_ROOT}/isf/common/fifo.isf' if ident == 'fifo_library_use' else 'reusable_products.isf' if ident in ('mixed', 'raw_width') else 'isf/' + ident + '.isf'}
            if ident.startswith('atl_'): expected_origin['usage'] = 'atl_static_instance'
            same(child['library_origin'], expected_origin)
        assert set(row['physical_module']) == modulekeys
        if ident == 'raw_width': same(row['module'], None)
        else:
            assert set(row['module']) == modulekeys; same(products_of(row['module'], generated), r)
        physical_equal = int(not (ident == 'fifo_library_use' and not pure))
        reprepared_equal = int(ident not in width_cases and not (ident == 'fifo_library_use' and not pure))
        same(row['physical_equal'], physical_equal); same(row['reprepared_equal'], reprepared_equal)
        same(int(json.dumps(products_of(row['physical_module'], generated), sort_keys=True) == json.dumps(r, sort_keys=True)), physical_equal)
        same(int(json.dumps(q['reusable_child_products'], sort_keys=True) == json.dumps(r, sort_keys=True)), reprepared_equal)
products = load('products.json'); pure = load('pure-products.json')
verify_products(products); verify_products(pure, True)
if '--trust-projection-kinds' in sys.argv:
    assert all(r['physical_equal'] and r['reprepared_equal'] for r in products['rows']), 'actual test projection/source kind gaps'
guards = load('guard-observations.json')
assert set(guards) == {'rows'} and len(guards['rows']) == 4
for row, (ident, mode) in zip(guards['rows'], [(i, m) for i in width_cases for m in ('original', 'detached')]):
    assert set(row) == set('fixture mode source before after_prepare after_build prepared module guards'.split())
    same([row['fixture'], row['mode'], row['source']], [ident, mode, source('isf/' + ident + '.isf')])
    same(row['after_prepare'], row['before'])
    same(row['after_build'], caller_after(row['before'], ident) if mode == 'original' else row['before'])
    for observation in row['guards']:
        assert set(observation) == {'phase', 'context', 'instance', 'before', 'after'}
        expected = copy.deepcopy(observation['before'])
        if mode == 'original':
            for instance, index, width in width_cases[ident]:
                if instance == observation['instance']:
                    same(expected['interface']['outputs'][index]['width'], str(width))
                    expected['interface']['outputs'][index]['width'] = width
        same(observation['after'], expected)
for prior, detached in zip(guards['rows'][::2], guards['rows'][1::2]):
    same(prior['prepared'], detached['prepared']); same(prior['module'], detached['module'])
if '--trust-caller-kinds' in sys.argv:
    assert all(r['before'] == r['after_build'] for r in guards['rows'] if r['mode'] == 'original'), 'actual aliased width mutation'
steps = load('input-steps.json')['steps']
same([s['stage'] for s in steps], ['parsed', 'storable_clone', 'prepared', 'built'])
parsed = steps[0]['actor']; expected_clone = copy.deepcopy(parsed)
for index in range(4):
    signal = expected_clone['library_uses'][0]['actor']['storage'][3]['signals'][index]
    same(signal['index'], index); signal['index'] = str(index)
for index in (3, 7):
    binding = expected_clone['library_uses'][0]['bindings'][index]
    same(binding['width'], 8); binding['width'] = '8'
same(steps[1]['clone'], expected_clone)
for step in steps:
    same(step['actor'], parsed)
    if 'prepared_actor' in step: same(step['prepared_actor'], parsed)
for label in ('cause', 'source', 'kind', 'actor', 'field', 'member'):
    bad = copy.deepcopy(data)
    if label == 'cause': bad['rows'][0]['error'] = 'wrong cause\n'
    elif label == 'source': bad['rows'][0]['source'] = '(not_actor)'
    elif label == 'kind': bad['rows'][0]['matched'] = True
    elif label == 'actor': bad['rows'][0]['actor_before']['transactions'][-1]['ports']['inputs'][0]['width'] = 4.0
    elif label == 'field': bad['rows'][0]['unknown'] = 1
    else: bad['rows'].pop()
    try: verify_rows(bad)
    except AssertionError: print('cause corruption rejects:', label)
    else: raise AssertionError('accepted ' + label)
for label in ('origin', 'kind', 'field'):
    bad = copy.deepcopy(products)
    if label == 'origin': bad['rows'][0]['prepared']['reusable_child_products']['children']['fifo_library_use__u_fifo']['library_origin']['instance'] = 'wrong'
    elif label == 'kind': bad['rows'][0]['input_equal'] = True
    else: bad['rows'][0]['module']['unknown'] = 1
    try: verify_products(bad)
    except AssertionError: print('whole corruption rejects:', label)
    else: raise AssertionError('accepted ' + label)
assert (B / 'default.status').read_text() == '0\n' and 'Files=1, Tests=3' in (B / 'default.txt').read_text()
assert (B / 'probe-red.status').read_text() == '22\n' and 'failed 22 tests of 132' in (B / 'probe-red.txt').read_text()
assert (B / 'ordinary.status').read_text() == (B / 'pure_projection.status').read_text() == '0\n'
if (B / 'manifest.json').exists():
    members = load('manifest.json')['members']
    assert set(members) == {str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for name, row in members.items():
        raw = (B / name).read_bytes()
        same(row, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
print('PASS finite actual causes/mutations/identities/kinds, source closure, real clone/width roots and complete observations; wider constructor/child semantics remain cold-owned.')
