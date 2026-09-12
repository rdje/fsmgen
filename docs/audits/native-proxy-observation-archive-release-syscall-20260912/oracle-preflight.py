"""Qualify the prospective syscall oracle against retained call-cut oracles."""
import json
from pathlib import Path
import importlib.util

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def main():
    audit = module('syscall_preflight_audit', BASE / 'audit.py')
    plan = audit.load(BASE / 'plan.json'); audit.domain(plan); pins = audit.authenticate(plan)
    before = module('syscall_before_oracle', BASE.with_name('native-proxy-observation-archive-release-ordinary-before-20260911') / 'audit.py')
    after = module('syscall_after_oracle', BASE.with_name('native-proxy-observation-archive-release-ordinary-after-20260911') / 'expected_trace.py')
    oracle = module('syscall_new_oracle', BASE / 'expected_trace.py')
    projection = module('syscall_saved_event_projection', BASE.with_name('native-proxy-observation-archive-release-readback-ordinary-20260911') / 'oracle-preflight.py')
    original = audit.load(audit.ORIGINAL / 'plan.json')
    saved = audit.load(ROOT / original['healthy_input'])
    rows = {row['profile_id']: row for row in saved['cases']}
    checks = []
    for case in plan['cases']:
        row = rows[case['profile_id']]
        spec, _ = before.OLD.setup(row)
        calls = before.PRIOR.FLOW.derive(row['context'], row['operation']['before'], spec)
        selected = case['selector']; cut = None
        if selected:
            symbol = 'NativeProxyObservationRelease::_unlink_exact' if selected['control'] == 'unlink-eacces' else 'NativeProxyPrivateWorkspace::_absent'
            matches = [c for c in calls if c['name'] == symbol]
            call = matches[int(selected['phase'] == 'finish')]
            cut = dict(call_id=call['id'], symbol=symbol, occurrence=matches.index(call),
                       phase='after' if selected['control'] == 'absence-present' else 'before')
        reference = (after if cut and cut['phase'] == 'after' else before.TRACE).derive(
            calls, row['context'], plan['sealed_symbols'], cut)
        if selected and selected['control'] == 'unlink-eacces':
            index = reference['events'].index('call:' + str(cut['call_id']) + ':before') + 1
            reference['events'][index:index] = ['unlink:0:before', 'unlink:0:after']
        reference['report_hits'] = reference.pop('injected_hits'); reference['injected_hits'] = 0
        actual = oracle.derive(calls, row['context'], plan['sealed_symbols'], selected)
        assert actual == reference, case['name']
        if selected is None:
            projected = projection.project(row, None, plan['sealed_symbols'])
            assert actual['events'] == projected['events']
            assert actual['interrupted_boundary_ids'] == projected['interrupted_boundary_ids']
            fields = ('id', 'name', 'parent', 'caller', 'occurrence')
            assert [[c[k] for k in fields] for c in actual['calls']] == [[c[k] for k in fields] for c in row['operation']['boundary_calls']]
        checks.append(dict(case=case['name'], calls=len(actual['calls']), events=len(actual['events']),
                           event_sha256=audit.signature(actual['events'])))
    result = dict(success=True, allocated_fixtures=0, prospective_pins=pins, comparisons=checks,
                  scope='Pure retained healthy traces and independently qualified before/after call cuts; no fixture execution.')
    with (audit.LOG / 'oracle-preflight.json').open('x') as output:
        output.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(dict(success=True, comparisons=len(checks), allocated_fixtures=0)))


if __name__ == '__main__':
    main()
