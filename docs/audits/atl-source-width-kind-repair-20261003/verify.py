"""Independent finite source-width repair models; wider child semantics stay open."""
import copy
import hashlib
import json
import subprocess
import sys
from pathlib import Path
B = Path(__file__).parent
OLD = Path('docs/audits/reusable-product-helper-causes-20261003')
REV = 'b30ed324e63549180f50c3d624d386258fba7405'
PROVIDER = 'perl/FSM/Scheduler/ISF/LoweringIR.pm'
TEST = 't/2059-isf-atl-source-width-kind-preservation.t'
def load(path): return json.loads(path.read_text())
def same(a, b):
    assert json.dumps(a, sort_keys=True, separators=(',', ':')) == json.dumps(
        b, sort_keys=True, separators=(',', ':')), 'value/kind/field mismatch'
def git_source(path):
    return subprocess.check_output(['git', 'show', REV + ':' + path])
before_binding = load(B / 'before-bindings.json')
after_binding = load(B / 'after-bindings.json')
paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', REV, '--',
    'bin', 'perl', 't', 'scripts', 'isf']).decode().splitlines()
assert set(before_binding) == set(after_binding) == {'baseline', 'metadata', 'sources'}
assert before_binding['baseline'] == after_binding['baseline'] == REV
assert set(before_binding['metadata']) == set(after_binding['metadata']) == set(paths) | {TEST}
for path in paths:
    raw = git_source(path)
    same(before_binding['metadata'][path], {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
for path, row in after_binding['metadata'].items():
    raw = Path(path).read_bytes()
    same(row, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
    if path != PROVIDER: same(row, before_binding['metadata'][path])
for binding in (before_binding, after_binding):
    for path, body in binding['sources'].items():
        raw = body.encode()
        same(binding['metadata'][path], {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
for path, body in after_binding['sources'].items(): assert body == Path(path).read_text()
prior_source = git_source(PROVIDER).decode()
assert before_binding['sources'][PROVIDER] == prior_source
old_block = """        confess "$context data movement '$movement->{drive}' requires a $port_label '$port_name' on $instance_role '$instance'\\n"
            unless ref($declared) eq 'HASH'
                && ($declared->{width} || 1) == $width
                && $width > 0;"""
new_block = """        # Numeric inspection must not change the caller's scalar flags.
        my $declared_width = ref($declared) eq 'HASH'
            ? $declared->{width}
            : undef;
        confess "$context data movement '$movement->{drive}' requires a $port_label '$port_name' on $instance_role '$instance'\\n"
            unless ref($declared) eq 'HASH'
                && ($declared_width || 1) == $width
                && $width > 0;"""
assert prior_source.count(old_block) == 1
assert prior_source.replace(old_block, new_block) == after_binding['sources'][PROVIDER]
assert before_binding['sources'][TEST] == after_binding['sources'][TEST]

fixtures = [
    ('atl_resolved_child_pin_egress_vector_multi_pipeline', 'worker', 'publish_result', [('worker', 0, 8), ('worker', 1, 4)]),
    ('atl_two_child_vector_data_pipeline', 'reader', 'forward_payload', [('reader', 0, 8)]),
]
prepkeys = set('actor actor_context deferred_formal_collisions domain_partition domain_source_products generated_child_products generated_children parent_activation_products parent_completion_products parent_named_completion_products parent_payload_snapshot_products parent_point_products parent_storage_read_products parent_storage_write_products parent_wiring_products pruned_transactions resource_signal_products reusable_child_products transaction_binding_report_products transaction_products transactions'.split())
modulekeys = set('actor_name actor_network actor_phases actor_stages assignment_provenance atl_top_instances bank_accesses children clock compatible_fanin_groups conflict_issues constants counters declared_storage dt_blocks enum_declarations explicit_interface_ports explicit_internal_signals immediate_assertions interface_port_metadata library_uses logical_controllers output_defaults package_imports package_roots params ports priority_resolution reset reset_provenance reset_values resource_activation resource_arbitration signal_type_refs signal_widths spawn_instances states storage_roles temporal_contracts transaction_port_bindings type_declarations verification_bridge verification_observations watchdog'.split())
def ports(actor, instance):
    return actor['_atl_actor_type_resolutions'][instance]['actor']['interface']['outputs']
def verify_rows(data, prior=False):
    assert set(data) == {'rows'} and len(data['rows']) == 12
    roster = [(fixture, instance, drive, widths, band, method)
        for fixture, instance, drive, widths in fixtures
        for band in ('ordinary', 'wrong_width', 'missing_output')
        for method in ('prepare_formal_source', 'build_module')]
    anchors = {}
    for row, (fixture, instance, drive, widths, band, method) in zip(data['rows'], roster):
        assert set(row) == set('fixture instance drive band method source original actor accepted error result'.split())
        same([row[k] for k in ('fixture', 'instance', 'drive', 'band', 'method', 'source')],
             [fixture, instance, drive, band, method, git_source('isf/' + fixture + '.isf').decode()])
        original = row['original']
        same(original['actor_name'], fixture)
        if fixture not in anchors:
            anchors[fixture] = copy.deepcopy(original)
            for child, index, width in widths:
                same(ports(original, child)[index]['width'], str(width))
        expected_original = copy.deepcopy(anchors[fixture])
        if band == 'wrong_width': ports(expected_original, instance)[0]['width'] = '7'
        elif band == 'missing_output': ports(expected_original, instance).pop(0)
        same(original, expected_original)
        expected_actor = copy.deepcopy(original)
        if prior and method == 'build_module':
            if band == 'ordinary':
                for child, index, width in widths: ports(expected_actor, child)[index]['width'] = width
            elif band == 'wrong_width': ports(expected_actor, instance)[0]['width'] = 7
        same(row['actor'], expected_actor)
        same(row['accepted'], int(band == 'ordinary'))
        if band == 'ordinary':
            same(row['error'], '')
            result = row['result']
            assert set(result) == (prepkeys if method == 'prepare_formal_source' else modulekeys)
            parent_actor = result['actor'] if method == 'prepare_formal_source' else None
            if parent_actor is not None: same(parent_actor, original)
            else: same(result['actor_name'], fixture)
            children = result['reusable_child_products']['children'] if parent_actor is not None else result['children']
            instances = ['worker'] if instance == 'worker' else ['reader', 'writer']
            same(sorted(children), sorted(fixture + '__' + child for child in instances))
            for child in instances:
                module = fixture + '__' + child
                same(children[module]['actor_name'], module)
                same(children[module]['library_origin'], {
                    'parent_actor': fixture, 'instance': child, 'library': 'common.packet',
                    'export': 'packet_' + child, 'library_source': 'isf/' + fixture + '.isf',
                    'usage': 'atl_static_instance'})
        else:
            same(row['result'], None)
            expected = f"ATL generated top for actor '{fixture}' data movement '{drive}' requires a child output port 'payload' on "
            expected += 'source instance' if instance == 'reader' else 'instance'
            expected += f" '{instance}'"
            assert row['error'].splitlines()[0] == expected

before = load(B / 'before-causes.json')
current = load(B / 'current-causes.json')
prior = load(B / 'prior-causes.json')
verify_rows(before, True); verify_rows(current); verify_rows(prior, True)
for a, b, c in zip(before['rows'], current['rows'], prior['rows']):
    same(a['original'], b['original']); same(a['original'], c['original'])
    same(a['accepted'], b['accepted']); same(a['accepted'], c['accepted'])
    same(a['result'], b['result']); same(a['result'], c['result'])
    assert a['error'].splitlines()[:1] == b['error'].splitlines()[:1] == c['error'].splitlines()[:1]
old_guards = load(OLD / 'guard-observations.json')['rows']
for row in current['rows']:
    if row['band'] != 'ordinary': continue
    old = next(r for r in old_guards if r['fixture'] == row['fixture'] and r['mode'] == 'original')
    same(row['original'], old['before'])
    same(row['result'], old['prepared'] if row['method'] == 'prepare_formal_source' else old['module'])
if '--trust-prior-kinds' in sys.argv:
    assert all(r['actor'] == r['original'] for r in prior['rows']), 'exact prior guard changes four actual caller-kind observations'
for label in ('cause', 'source', 'kind', 'actor', 'field', 'member'):
    bad = copy.deepcopy(current)
    if label == 'cause': bad['rows'][2]['error'] = 'wrong cause\n'
    elif label == 'source': bad['rows'][0]['source'] = '(not_actor)'
    elif label == 'kind': bad['rows'][0]['accepted'] = True
    elif label == 'actor': ports(bad['rows'][0]['actor'], 'worker')[0]['width'] = 8
    elif label == 'field': bad['rows'][0]['unknown'] = 1
    else: bad['rows'].pop()
    try: verify_rows(bad)
    except AssertionError: print('input corruption rejects:', label)
    else: raise AssertionError('accepted ' + label)
for label in ('origin', 'schema', 'kind'):
    bad = copy.deepcopy(current)
    result = bad['rows'][0]['result']
    child = result['reusable_child_products']['children']['atl_resolved_child_pin_egress_vector_multi_pipeline__worker']
    if label == 'origin': child['library_origin']['instance'] = 'wrong'
    elif label == 'schema': result['unknown'] = 1
    else: result['actor']['_atl_actor_type_resolutions']['worker']['actor']['interface']['outputs'][0]['width'] = 8
    try: verify_rows(bad)
    except AssertionError: print('output corruption rejects:', label)
    else: raise AssertionError('accepted ' + label)
assert (B / 'current.status').read_text() == '0\n' and 'Files=1, Tests=48' in (B / 'current.txt').read_text()
assert (B / 'before-red.status').read_text() == '1\n' and 'Failed 4/48 subtests' in (B / 'before-red.txt').read_text()
assert (B / 'prior-red.status').read_text() == '4\n' and 'failed 4 tests of 48' in (B / 'prior-red.txt').read_text()
assert '461a70406e8e18c739497c03718166cd950e7038' in (B / 'history.txt').read_text()
introduction = subprocess.check_output(['git', 'show', '461a70406e8e18c739497c03718166cd950e7038:' + PROVIDER])
assert (B / 'introduction-LoweringIR.pm').read_bytes() == introduction
assert b'($declared->{width} || 1) == $width' in introduction
if (B / 'manifest.json').exists():
    members = load(B / 'manifest.json')['members']
    assert set(members) == {str(p.relative_to(B)) for p in B.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    for name, row in members.items():
        raw = (B / name).read_bytes()
        same(row, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
print('PASS exact source delta/closure, complete caller-kind preservation, prior real failures, admission causes and whole output conservation; wider child semantics remain cold-owned.')
