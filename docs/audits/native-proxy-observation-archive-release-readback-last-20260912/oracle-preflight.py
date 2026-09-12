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
REVISION = '70c1fe9e82267dc52df7be14177f91114d980f60'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.5'
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


ORDINARY = BASE.with_name('native-proxy-observation-archive-release-readback-ordinary-20260911')


def main():
    audit = module('last_readback_domain_audit', BASE / 'audit.py')
    plan = load(BASE / 'plan.json')
    audit.domain(plan)
    pins = audit.authenticate(plan)
    assert not (LOG / 'oracle-preflight.json').exists(), 'preserve the first preflight output'
    oracle = module('last_shared_readback_source_scope', ORDINARY / 'expected_trace.py')
    projection = module('last_saved_event_projection', ORDINARY / 'oracle-preflight.py')
    support = module('last_before_support', BASE.parent / 'native-proxy-observation-archive-release-ordinary-before-20260911/audit.py')
    order_model = module('last_order_support', BASE.parent / 'native-proxy-release-call-selection-20260911/model.py')
    original = load(BASE.parent / 'native-proxy-release-readback-selection-20260911/plan.json')
    corrected = load(BASE.parent / 'native-proxy-release-readback-applicability-20260911/applicability.json')
    saved = load(ROOT / original['healthy_input'])
    sealed = plan['sealed_symbols']
    projections, orders = [], []
    for row, correction in zip(saved['cases'][3:4], corrected['profiles'][3:4], strict=True):
        spec, _ = support.OLD.setup(row)
        calls = support.PRIOR.FLOW.derive(row['context'], row['operation']['before'], spec)
        sources = [c for c in calls if c['name'] == SOURCE]
        selections = [None, dict(control='one-byte', occurrence=0, call_id=sources[0]['id'], path=sources[0]['path'])]
        selections.extend(dict(control=mode, occurrence=i, call_id=c['id'], path=c['path'])
            for i, c in enumerate(sources) for mode in ('first-eio', 'partial-eio', 'early-eof', 'body-xor'))
        for selected in selections:
            expected = projection.project(row, selected, sealed)
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
    assert len(projections) == 406 and len(orders) == 2
    assert sum(p['expected_success'] for p in projections) == 7
    report = dict(schema='fsmgen.release_readback_last_preflight.v1', success=True,
        prospective_pins=pins, inputs=len(plan['inputs']), allocated=[], projections=projections,
        order_only_skeletons=orders, scope='Historical event-prefix and future-open-handle close projection; ordering models are not codec-valid file fixtures. No injected-reader, real descriptor or integrated observer qualification.')
    with (LOG / 'oracle-preflight.json').open('x') as output:
        output.write(json.dumps(report, sort_keys=True, indent=2) + '\n')
    print(json.dumps(dict(success=True, projections=len(projections), order_only_skeletons=len(orders),
                         allocated_fixtures=0), sort_keys=True))


if __name__ == '__main__':
    main()
