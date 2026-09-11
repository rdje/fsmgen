"""Compare equal-reference after-call scope predictions with a saved healthy event projection.

Only descriptors already open at the selected return enter the cleanup suffix.
Their close order comes from the real healthy trace, independently of the new
source-scope interpreter. No fixture, producer or native executable is invoked.
"""
import hashlib
import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
EQUAL_BEFORE = BASE.with_name('native-proxy-observation-archive-release-equal-before-20260911')


def load(path): return json.loads(path.read_bytes())
def signature(value): return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


def main():
    plan = load(BASE / 'plan.json'); pins = load(BASE / 'trace-preflight-pins.json')
    for pin in pins + plan['inputs']:
        path = ROOT / pin['path']; raw = path.read_bytes()
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        assert pin == dict(path=pin['path'], size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    equal_before_audit = module('equal_after_reference_audit', EQUAL_BEFORE / 'audit.py')
    oracle = equal_before_audit.PREVIOUS.TRACE
    old_plan = load(EQUAL_BEFORE / 'plan.json'); saved = load(EQUAL_BEFORE / 'result/qualification.json')
    equal_before_audit.header(old_plan, saved)
    healthy = equal_before_audit.read_case(EQUAL_BEFORE / 'result', saved['case_files'][0])
    equal_before_audit.verify_row(old_plan, old_plan['cases'][0], healthy)
    assert healthy['profile_id'] == plan['profile_id'] and healthy['selection'] == plan['selection']
    spec, _ = equal_before_audit.OLD.setup(healthy)
    calls = equal_before_audit.PRIOR.FLOW.derive(healthy['context'], healthy['operation']['before'], spec)
    operation = healthy['operation']; events = operation['events']; results = []
    report = dict(schema='fsmgen.release_equal_after_trace_preflight.v1', success=False, prospective_pins=pins,
                  allocated=[], cases=results, first_unexpected=None)
    output = LOG / 'trace-preflight.json'
    assert not output.exists() and not output.is_symlink()
    def save(): output.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n')
    save()
    for selected in plan['cases'][1:]:
        fault = selected['selector']; ident = [c['id'] for c in calls if c['name'] == fault['symbol']][fault['occurrence']]
        resolved = dict(address=fault['address'], call_id=ident, symbol=fault['symbol'], occurrence=fault['occurrence'], phase='after')
        report['first_unexpected'] = dict(selection=selected, resolved=resolved); save()
        prediction = oracle.derive(calls, healthy['context'], plan['sealed_symbols'], resolved)
        endpoint = events.index('call:%d:after' % ident) + 1
        prefix = events[:endpoint]; active = set(); opened = set()
        for event in prefix:
            if event.startswith('opened:'):
                label = event[len('opened:'):]; assert label not in active; active.add(label); opened.add(label)
            elif event.startswith('close:') and event.endswith(':after'):
                active.remove(event[len('close:'):-len(':after')])
        suffix = []
        for event in events[endpoint:]:
            if event.startswith('close:') and event.endswith(':before'):
                label = event[len('close:'):-len(':before')]
                if label in active:
                    suffix.extend(['close:' + label + ':before', 'close:' + label + ':after']); active.remove(label)
        assert not active
        projected = prefix + suffix + ['operation:end']
        assert prediction['events'] == projected
        actual_handles = [h for h in operation['handles'] if h['label'] in opened]
        fields = ('label', 'kind', 'path', 'close_caller')
        assert [{k: h[k] for k in fields} for h in prediction['handles']] == [{k: h[k] for k in fields} for h in actual_handles]
        ancestry = []; parent = calls[ident]['parent']
        while parent is not None: ancestry.append(parent); parent = calls[parent]['parent']
        assert prediction['interrupted_boundary_ids'] == list(reversed(ancestry))
        assert next(c for c in prediction['calls'] if c['id'] == ident)['completion'] == 'direct_return'
        assert prediction['unlinked'] == ('unlink:0:after' in prefix) and prediction['injected_hits'] == 1
        results.append(dict(address=fault['address'], resolved=resolved, events=len(projected), handles=len(actual_handles),
                            calls=len(prediction['calls']), unlinked=prediction['unlinked'], event_sha256=signature(projected)))
        report['first_unexpected'] = None; save()
    assert len(results) == 466
    report['success'] = True; save()
    print(json.dumps(dict(success=True, cases=len(results), allocated=0), sort_keys=True))


if __name__ == '__main__': main()
