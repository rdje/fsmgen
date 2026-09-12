"""Compare the new scope oracle with independent saved-event projections.

Only retained JSON and pure original helper functions are consumed. No prior
main, fixture allocator, compiler or native executable is invoked.
"""
import hashlib
import importlib.util
import itertools
import json
from pathlib import Path
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
REVISION = 'efadb9148c14391fde011851e766a72b84bcfda8'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.2.2'
SOURCE = 'NativeProxyImageCustody::_source'


def load(path):
    return json.loads(path.read_bytes())


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def signature(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def project(row, selected, sealed):
    """Cut the retained event stream and filter its future real closes."""
    op = row['operation']
    calls = op['boundary_calls']
    events = [e for e in op['events'] if not (e.startswith('call:') and e.endswith(':after')
        and calls[int(e.split(':')[1])]['name'] in sealed)]
    sources = [c for c in calls if c['name'] == SOURCE]
    terminal = None
    pending_start = None
    if selected is not None:
        source = sources[selected['occurrence']]
        parent = calls[source['parent']]
        if selected['control'] in ('first-eio', 'partial-eio', 'early-eof'):
            terminal = 'read:' + str(selected['occurrence'])
            pending_start = source['id']
        elif selected['control'] == 'body-xor' and parent['name'] != 'NativeProxyImageCoordination::_census':
            if parent['name'] == 'NativeProxyReferenceCensus::_image':
                target, = [c for c in calls if c['parent'] == parent['id']
                           and c['name'] == 'NativeProxyImageCustody::read_entry']
                terminal = 'call:' + str(target['id']) + ':before'
                pending_start = target['id']
            elif parent['name'] == 'NativeProxyReferenceCensus::_inspect_locked':
                target = calls[source['id'] + 1]
                assert target['name'] == 'NativeProxyReferenceCensus::_decode_record'
                terminal = 'call:' + str(target['id']) + ':before'
                pending_start = target['id']
            else:
                if parent['name'] == 'NativeProxyImageCustody::read_entry':
                    siblings = [c for c in sources if c['parent'] == parent['id']]
                    assert len(siblings) == 3
                    last = siblings[-1]
                else:
                    assert parent['name'] in {'NativeProxyObservationRelease::_prepare',
                        'NativeProxyObservationRelease::_retain_live_sources',
                        'NativeProxyObservationArchive::_source_closure', 'NativeProxyReferenceCensus::_closure'}
                    last = source
                terminal = 'call:' + str(last['id']) + ':after'
                pending_start = parent['id']
    if terminal is None:
        projected = events
    else:
        assert events.count(terminal) == 1
        end = events.index(terminal) + 1
        projected = events[:end]
        opened = {e.split(':', 1)[1] for e in projected if e.startswith('opened:')}
        closed = {e[len('close:'):-len(':after')] for e in projected if e.startswith('close:') and e.endswith(':after')}
        waiting = opened - closed
        closes = [e for e in events[end:] if e.startswith('close:')
                  and e[len('close:'):].rsplit(':', 1)[0] in waiting]
        assert len(closes) == len(waiting) * 2
        projected = projected + closes + ['operation:end']
    labels = [e[len('opened:'):] for e in projected if e.startswith('opened:')]
    handles = [{k: h[k] for k in ('label', 'kind', 'path', 'close_caller')}
               for h in op['handles'] if h['label'] in labels]
    assert [h['label'] for h in handles] == labels
    pending = []
    while pending_start is not None:
        pending.append(pending_start)
        pending_start = calls[pending_start]['parent']
    pending.reverse()
    return dict(events=projected, handles=handles, interrupted_boundary_ids=pending)


def main():
    pins = load(BASE / 'oracle-preflight-pins.json')
    plan = load(BASE / 'oracle-preflight-plan.json')
    assert plan['schema'] == 'fsmgen.release_readback_scope_preflight_plan.v1'
    assert plan['owner'] == OWNER and plan['source_revision'] == REVISION
    assert [p['path'] for p in pins] == [str((BASE / n).relative_to(ROOT))
        for n in ('oracle-preflight.py', 'expected_trace.py', 'oracle-preflight-plan.json')]
    for pin in pins + plan['inputs']:
        path = ROOT / pin['path']
        raw = path.read_bytes()
        assert path.stat().st_dev == ROOT.stat().st_dev
        for ancestor in [path, *path.parents]:
            if ancestor == ROOT:
                break
            assert not ancestor.is_symlink()
        assert pin == dict(path=pin['path'], size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        if pin in plan['inputs']:
            assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
    assert not (LOG / 'oracle-preflight.json').exists(), 'preserve the first preflight output'
    oracle = module('new_readback_source_scope', BASE / 'expected_trace.py')
    support = module('retained_readback_before_support', BASE.parent / 'native-proxy-observation-archive-release-ordinary-before-20260911/audit.py')
    order_model = module('retained_readback_order_support', BASE.parent / 'native-proxy-release-call-selection-20260911/model.py')
    original = load(BASE.parent / 'native-proxy-release-readback-selection-20260911/plan.json')
    corrected = load(BASE.parent / 'native-proxy-release-readback-applicability-20260911/applicability.json')
    saved = load(ROOT / original['healthy_input'])
    sealed = load(BASE.parent / 'native-proxy-release-call-selection-20260911/plan.json')['sealed_symbols']
    projections, orders = [], []
    for row, correction in zip(saved['cases'], corrected['profiles'], strict=True):
        spec, _ = support.OLD.setup(row)
        calls = support.PRIOR.FLOW.derive(row['context'], row['operation']['before'], spec)
        sources = [c for c in calls if c['name'] == SOURCE]
        selections = [None, dict(control='one-byte', occurrence=0, call_id=sources[0]['id'], path=sources[0]['path'])]
        selections.extend(dict(control=mode, occurrence=i, call_id=c['id'], path=c['path'])
            for i, c in enumerate(sources) for mode in ('first-eio', 'partial-eio', 'early-eof', 'body-xor'))
        for selected in selections:
            expected = project(row, selected, sealed)
            actual = oracle.derive(calls, row['context'], sealed, selected)
            actual_view = {k: actual[k] for k in ('events', 'interrupted_boundary_ids')}
            actual_view['handles'] = [{k: h[k] for k in ('label', 'kind', 'path', 'close_caller')} for h in actual['handles']]
            assert actual_view == expected, (row['profile_id'], selected)
            observed = [int(e.split(':')[1]) for e in expected['events'] if e.startswith('call:') and e.endswith(':before')]
            assert [c['id'] for c in actual['calls']] == observed
            projections.append(dict(profile=row['profile_id'], selection=selected,
                event_sha256=signature(actual['events']), events=len(actual['events']),
                handles=len(actual['handles']), calls=len(actual['calls']), expected_success=actual['expected_success']))
        names = sorted(k for k in row['operation']['before']['store'] if k.startswith('references/'))
        for order in itertools.permutations(range(len(names))):
            context, before = order_model.order_skeleton(row['context'], row['operation']['before'], order)
            flow = support.PRIOR.FLOW.derive(context, before, spec)
            source_calls = [c for c in flow if c['name'] == SOURCE]
            outcomes = [oracle.outcome(flow, dict(control='body-xor', occurrence=i, call_id=c['id'], path=c['path']))
                        for i, c in enumerate(source_calls)]
            assert [v['expected_success'] for v in outcomes] == [b['expected_success'] for b in correction['body_xor']]
            orders.append(dict(profile=row['profile_id'], order=list(order), source_occurrences=len(source_calls),
                expected_body_successes=sum(o['expected_success'] for o in outcomes),
                outcome_sha256=signature(outcomes)))
    assert len(projections) == 1868 and len(orders) == 38
    assert sum(p['expected_success'] for p in projections) == 40
    report = dict(schema='fsmgen.release_readback_scope_preflight.v1', success=True,
        prospective_pins=pins, inputs=len(plan['inputs']), allocated=[], projections=projections,
        order_only_skeletons=orders, scope='Historical event-prefix and future-open-handle close projection; ordering models are not codec-valid file fixtures. No injected-reader, real descriptor or integrated observer qualification.')
    with (LOG / 'oracle-preflight.json').open('x') as output:
        output.write(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, projections=len(projections), order_only_skeletons=len(orders),
                         allocated_fixtures=0), sort_keys=True))


if __name__ == '__main__':
    main()
