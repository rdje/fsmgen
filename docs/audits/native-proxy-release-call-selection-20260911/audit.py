"""Independent selector census and interval-based effect oracle.

The effect oracle compares positions with completed subtree intervals; it does
not execute or import the producer's event/state interpreter.
"""
from collections import Counter
import copy
import hashlib
import importlib.util
import itertools
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
BOUNDARY = BASE.parent / 'native-proxy-observation-archive-release-boundaries-20260911'
REVISION = 'e0cfaecedbfb44f757e44660fa940bf15df47e6b'


def load(path): return json.loads(path.read_bytes())
def signature(value): return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path); value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value); return value


PRIOR = module('selection_independent_boundary', BOUNDARY / 'audit.py')


def rejects(action):
    try: action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError): return True
    return False


def expected(calls, sealed):
    assert [c['id'] for c in calls] == list(range(len(calls)))
    depth, end, ordinals, occurrence = {}, {}, Counter(), {}
    for c in calls:
        ident = c['id']; parent = c['parent']
        assert parent is None or 0 <= parent < ident
        depth[ident] = 0 if parent is None else depth[parent] + 1; end[ident] = ident
        occurrence[ident] = ordinals[c['name']]; ordinals[c['name']] += 1
    for c in reversed(calls):
        if c['parent'] is not None: end[c['parent']] = max(end[c['parent']], end[c['id']])
    assert max(depth.values()) < 128
    def position(c, phase): return (c['id'], -129) if phase == 'before' else (end[c['id']], -depth[c['id']])
    unlink = [c for c in calls if c['name'] == PRIOR.FLOW.RELEASE + '::_unlink_exact']; assert len(unlink) == 1
    checks = [c for c in calls if c['name'] == PRIOR.FLOW.RELEASE + '::_assert_absent']
    assert [c['phase'] for c in checks] == ['after_unlink', 'finish']
    result = []
    for c in calls:
        for phase in ('before', 'after'):
            if phase == 'after' and (c['name'] in sealed or c['name'] == PRIOR.FLOW.CUSTODY + '::_source'): continue
            point = position(c, phase)
            unlinked = int(point >= position(unlink[0], 'after'))
            started = [check for check in checks if point > position(check, 'before')]
            last = None
            if started:
                check = started[-1]
                last = dict(phase=check['phase'], state='absent' if point >= position(check, 'after') else 'unknown')
            result.append(dict(address=c['name'] + '#' + str(occurrence[c['id']]) + ':' + phase,
                effects=dict(unlink_attempted=unlinked, unlink_completed=unlinked,
                             reference_absence_verified=int(point >= position(checks[0], 'after')), last_reference_check=last)))
    assert len({r['address'] for r in result}) == len(result)
    return sorted(result, key=lambda r: r['address'])


def alternate_flow(row, spec, order):
    # Independent input-role permutation, without the producer's rename helper.
    context = copy.deepcopy(row['context']); before = copy.deepcopy(row['operation']['before'])
    originals = {p: n for p, n in before['store'].items() if p.startswith('references/')}
    names = sorted(originals); assert set(order) == set(range(len(names))) and len(order) == len(names)
    deltas = {names[index]: 'references/' + ('%064x' % rank) + '.json' for rank, index in enumerate(order)}
    before['store'] = {deltas.get(p, p): node for p, node in before['store'].items()}
    store = context['store']['path']; identity = context['acquired']['observation_reference']['source']['identity']
    identity['path'] = store + '/' + deltas[identity['path'][len(store) + 1:]]
    return PRIOR.FLOW.derive(context, before, spec)


def domain(plan):
    assert plan['schema'] == 'fsmgen.release_call_selection_plan.v1' and plan['source_revision'] == REVISION
    original = load(BOUNDARY / 'plan.json'); saved = load(BOUNDARY / 'result/qualification.json')
    projection = load(BOUNDARY / 'result/fault-domain.json')
    assert plan['owner'] == original['owner'].rsplit('.', 1)[0] + '.3.1'
    assert plan['sealed_symbols'] == list(original['sealed_continuations'])
    assert plan['failure_contract'] == dict(returned=1, success=0, release=None, runtime_authorized=0, executable=None,
                                           error='injected release call: <address>\n')
    assert plan['binding'] == 'Resolve exact symbol, zero-based occurrence and admitted phase against the source-derived current physical-input flow before release. Numeric source_call_id and source_event identify preserved evidence only, never a portable injection target.'
    partitions = []; expected_baseline = []
    for profile, row, prior in zip(original['profiles'], saved['cases'], projection['profiles'], strict=True):
        spec, _ = PRIOR.OLD.setup(row); calls = PRIOR.FLOW.derive(row['context'], row['operation']['before'], spec)
        vector = expected(calls, plan['sealed_symbols']); by_address = {v['address']: v['effects'] for v in vector}
        expected_baseline.append(dict(profile_id=row['profile_id'], calls=len(calls), selectors=len(vector), vector_sha256=signature(vector)))
        for phase in ('before', 'after'):
            cases = []
            for cut in prior['boundaries']:
                if cut['phase'] != phase or not cut['eligible']: continue
                call = row['operation']['boundary_calls'][cut['call_id']]
                address = call['name'] + '#' + str(call['occurrence']) + ':' + phase
                effects = by_address[address]
                assert effects['unlink_completed'] == cut['unlink_completed']
                assert cut['alias'] is None and cut['meaning'] == 'selected_call_boundary'
                cases.append(dict(address=address, symbol=call['name'], occurrence=call['occurrence'], phase=phase,
                                  source_call_id=call['id'], source_event=cut['event'], baseline_effects=effects))
            partitions.append(dict(id=profile['id'] + ':' + phase, owner=plan['owner'].rsplit('.', 1)[0] + '.' + str(len(partitions) + 2),
                                   profile_id=profile['id'], phase=phase, selection=profile['selection'], cases=cases))
        assert {c['address'] for p in partitions[-2:] for c in p['cases']} == set(by_address)
    assert plan['partitions'] == partitions and len(partitions) == 8
    return expected_baseline


def authenticate(plan):
    pins = load(BASE / 'preflight-pins.json')
    names = ['plan.json', 'prepare.py', 'model.py', 'qualify.py', 'audit.py', 'reference-order-review.json', 'compaction-census.json']
    assert [p['path'] for p in pins] == [str((BASE / n).relative_to(ROOT)) for n in names]
    original = load(BOUNDARY / 'plan.json')
    paths = {p['path'] for p in original['inputs']} | {str(p.relative_to(ROOT)) for p in BOUNDARY.rglob('*') if p.is_file()}
    assert [p['path'] for p in plan['inputs']] == sorted(paths)
    for pin in pins + plan['inputs']:
        path = ROOT / pin['path']; raw = path.read_bytes()
        assert path.stat().st_dev == ROOT.stat().st_dev
        for ancestor in [path, *path.parents]:
            if ancestor == ROOT: break
            assert not ancestor.is_symlink()
        assert pin == dict(path=pin['path'], size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        if pin in plan['inputs']: assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
    PRIOR.authenticate(original)
    counts, projection = PRIOR.verify(original, load(BOUNDARY / 'result/qualification.json'))
    assert projection == load(BOUNDARY / 'result/fault-domain.json')['profiles']
    assert counts == {key: load(BOUNDARY / 'result/audit.json')[key] for key in counts}
    for root in load(BOUNDARY / 'result/qualification.json')['allocated']:
        path = ROOT / root['path']; assert not path.exists() and not path.is_symlink()
    census = load(BASE / 'compaction-census.json'); assert census['source_revision'] == REVISION and census['live_owner_matches'] == []
    for pin in census['registry_files']:
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
        assert len(raw) == pin['size_bytes'] and hashlib.sha256(raw).hexdigest() == pin['sha256']
    return pins


def verify(plan, report):
    baseline = domain(plan)
    assert report['schema'] == 'fsmgen.release_call_selection_qualification.v1'
    assert report['success'] is True and report['inputs_unchanged'] is True
    assert report['prospective_pins'] == load(BASE / 'preflight-pins.json')
    assert report['allocated'] == [] and report['forbidden_process_attempts'] == 0
    assert report['baseline'] == baseline
    original = load(BOUNDARY / 'result/qualification.json'); expected_rows = []; topology_counts = []
    for row, initial in zip(original['cases'], baseline, strict=True):
        spec, _ = PRIOR.OLD.setup(row)
        count = sum(p.startswith('references/') for p in row['operation']['before']['store'])
        topologies = set()
        for order in itertools.permutations(range(count)):
            calls = alternate_flow(row, spec, order); vector = expected(calls, plan['sealed_symbols'])
            topology = signature([c['name'] for c in calls]); topologies.add(topology)
            assert signature(vector) == initial['vector_sha256']
            expected_rows.append(dict(profile_id=row['profile_id'], order=list(order), calls=len(calls), selectors=len(vector),
                                      vector_sha256=signature(vector), numeric_symbol_order_sha256=topology))
        topology_counts.append(dict(profile_id=row['profile_id'], distinct_numeric_symbol_orders=len(topologies)))
    assert report['order_skeletons'] == expected_rows
    return dict(partitions=len(plan['partitions']), selected_cases=sum(len(p['cases']) for p in plan['partitions']),
                cases_by_partition=[len(p['cases']) for p in plan['partitions']], baseline_profiles=len(baseline),
                pure_order_skeletons=len(expected_rows), numeric_symbol_orders=topology_counts)


def main():
    plan = load(BASE / 'plan.json'); pins = authenticate(plan); report = load(LOG / 'qualification.json')
    counts = verify(plan, report)
    assert (LOG / 'qualify.exit').read_bytes() == b'0\n'
    report_changes = [
        ('missing baseline', lambda r: r['baseline'].pop()),
        ('duplicate baseline', lambda r: r['baseline'].append(copy.deepcopy(r['baseline'][0]))),
        ('changed selector count', lambda r: r['baseline'][0].update(selectors=1)),
        ('changed effect vector', lambda r: r['baseline'][0].update(vector_sha256='0' * 64)),
        ('missing order', lambda r: r['order_skeletons'].pop()),
        ('duplicated order', lambda r: r['order_skeletons'].append(copy.deepcopy(r['order_skeletons'][0]))),
        ('reordered traversal', lambda r: r['order_skeletons'].reverse()),
        ('changed topology', lambda r: r['order_skeletons'][0].update(numeric_symbol_order_sha256='0' * 64)),
        ('changed effect on reordered input', lambda r: r['order_skeletons'][0].update(vector_sha256='0' * 64)),
        ('unexpected fixture', lambda r: r['allocated'].append('unexpected')),
        ('hidden process', lambda r: r.update(forbidden_process_attempts=1)),
        ('changed input', lambda r: r.update(inputs_unchanged=False)),
    ]
    for name, change in report_changes:
        altered = copy.deepcopy(report); change(altered); assert rejects(lambda: verify(plan, altered)), name
    def case(p): return p['partitions'][0]['cases'][0]
    domain_changes = [
        ('missing partition', lambda p: p['partitions'].pop()),
        ('missing selector', lambda p: p['partitions'][0]['cases'].pop()),
        ('duplicate selector', lambda p: p['partitions'][0]['cases'].append(copy.deepcopy(case(p)))),
        ('stale numeric injection binding', lambda p: case(p).update(runtime_call_id=case(p)['source_call_id'])),
        ('wrong occurrence', lambda p: case(p).update(occurrence=999)),
        ('wrong effect', lambda p: case(p)['baseline_effects'].update(unlink_completed=1)),
        ('unsafe source after', lambda p: next(c for c in p['partitions'][0]['cases'] if c['symbol'].endswith('::_source')).update(phase='after')),
        ('independent sealed after', lambda p: next(c for c in p['partitions'][0]['cases'] if c['symbol'].endswith('::_unlink_exact')).update(phase='after')),
        ('invented runtime authority', lambda p: p['failure_contract'].update(runtime_authorized=1)),
    ]
    for name, change in domain_changes:
        altered = copy.deepcopy(plan); change(altered); assert rejects(lambda: verify(altered, report)), name
    result = dict(schema='fsmgen.release_call_selection_audit.v1', success=True, **counts,
                  prospective_pins=len(pins), unchanged_inputs=len(plan['inputs']),
                  report_falsifiers=[n for n, _ in report_changes], domain_falsifiers=[n for n, _ in domain_changes],
                  scope=plan['scope'], new_fixture_allocations=0, preserved_healthy_roots_absent=16)
    (LOG / 'audit.json').write_text(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__': main()
