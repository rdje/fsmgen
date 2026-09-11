"""Independent healthy call forest, actual custody and fault-domain verifier."""
from __future__ import annotations

from collections import Counter, defaultdict
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
REVISION = '49c15609fb5b4645c51d63babe1370b4aceeb44c'
RELEASE = BASE.parent / 'native-proxy-observation-archive-release-20260911'
CONTRACT = BASE.parent / 'native-proxy-release-interruption-contract-20260911'


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


OLD = module('boundary_release_oracle', RELEASE / 'audit.py')
FLOW = module('boundary_flow_oracle', BASE / 'flow_model.py')


def load(path): return json.loads(path.read_bytes())
def digest(raw): return dict(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def rejects(action):
    try: action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError): return True
    return False


def domain(plan):
    assert plan['source_revision'] == REVISION and plan['component'] == BASE.name
    contract = load(CONTRACT / 'contract.json')
    assert plan['source_boundaries'] == contract['source_boundaries']
    assert [p['id'] for p in plan['profiles']] == contract['profiles']
    prior = load(RELEASE / 'plan.json')
    names = ['healthy:ordinary', 'healthy:equal_reference', 'healthy:runtime-still-active', 'healthy:last-observation']
    for profile, name, sizes in zip(plan['profiles'], names, [(4, 3, 2), (3, 3, 2), (4, 4, 2), (4, 2, 1)], strict=True):
        assert profile['original_case'] == name
        assert profile['selection'] == next(c for c in prior['cases'] if c['name'] == name)
        assert (profile['archive_files'], profile['before_references'], profile['after_referenced_images']) == sizes
        assert len(profile['expected_calls']) == 31 and all(type(v) is int and v > 0 for v in profile['expected_calls'].values())
    expected = {
        FLOW.RELEASE + '::_coordinator_request': [FLOW.CUSTODY + '::_directory'],
        FLOW.CENSUS + '::_inspect_locked': [FLOW.RELEASE + '::' + n for n in ('_admit_locked', '_release_locked', '_finish_locked')],
        FLOW.RELEASE + '::_admit_locked': [FLOW.COORD + '::_census'],
        FLOW.RELEASE + '::_release_locked': [FLOW.COORD + '::_census'],
        FLOW.RELEASE + '::_finish_locked': [FLOW.COORD + '::_structure'],
        FLOW.RELEASE + '::_unlink_exact': [FLOW.RELEASE + '::_assert_absent'],
    }
    assert plan['sealed_continuations'] == expected
    return expected


def authenticate(plan):
    pins = load(BASE / 'preflight-pins.json')
    names = ['plan.json', 'prepare.py', 'flow_model.py', 'BoundaryTrace.pm', 'qualify.t', 'audit.py']
    assert [p['path'] for p in pins] == [str((BASE / n).relative_to(ROOT)) for n in names]
    contract = load(CONTRACT / 'contract.json')
    expected = {p['path'] for p in contract['inputs']}
    expected.update(str((CONTRACT / n).relative_to(ROOT)) for n in ['contract.json', 'prepare.py', 'model.py', 'qualify.py',
        'audit.py', 'preflight-pins.json', 'corrected-auditor-pin.json', 'result/qualification.json', 'result/audit.json'])
    assert [p['path'] for p in plan['inputs']] == sorted(expected)
    for pin in plan['inputs'] + pins:
        path = ROOT / pin['path']; raw = path.read_bytes()
        assert path.stat().st_dev == ROOT.stat().st_dev
        for ancestor in [path, *path.parents]:
            if ancestor == ROOT: break
            assert not ancestor.is_symlink()
        assert pin == dict(path=pin['path'], **digest(raw))
        if pin in plan['inputs']: assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
    for boundary in plan['source_boundaries']:
        lines = (ROOT / boundary['path']).read_bytes().splitlines(keepends=True)
        raw = b''.join(lines[boundary['start_line'] - 1:boundary['start_line'] - 1 + boundary['lines']])
        assert digest(raw) == {key: boundary[key] for key in ('size_bytes', 'sha256')}
        assert raw.startswith(('sub ' + boundary['symbol'] + ' {').encode())
    return pins


def caller_controls(plan, controls):
    assert {c['name'] for c in controls} == set(plan['sealed_continuations']) and len(controls) == 6
    diagnostics = {
        FLOW.RELEASE + '::_coordinator_request': 'release admission requires the fixed coordinator',
        FLOW.RELEASE + '::_admit_locked': 'release ownership admission requires the fixed coordinator',
        FLOW.RELEASE + '::_release_locked': 'exact release requires the fixed coordinator',
        FLOW.RELEASE + '::_finish_locked': 'release closure requires the fixed coordinator',
        FLOW.RELEASE + '::_unlink_exact': 'exact unlink requires the release owner',
        FLOW.CENSUS + '::_inspect_locked': 'reference inspection requires the sealed coordinator',
    }
    for control in controls:
        assert control['baseline_returned'] == control['instrumented_returned'] == 0
        assert control['baseline_error'] == control['instrumented_error'] == diagnostics[control['name']] + '\n'
        assert control['events'] == ['call:0:before', 'call:0:error'] and len(control['calls']) == 1
        call = control['calls'][0]
        assert call['name'] == control['name'] and call['caller'] == 'NativeProxyReleaseBoundaryTrace'
        assert call['tail'] == 1 and call['completion'] == 'external_rejection' and call['continuation'] is None
        assert call['error'] == control['instrumented_error'] and call['id'] == call['occurrence'] == 0 and call['parent'] is None


def boundaries(plan, profile, row, spec):
    op = row['operation']; calls = op['boundary_calls']; events = op['events']
    expected = FLOW.derive(row['context'], op['before'], spec)
    assert row['planned_calls'] == profile['expected_calls'] == dict(Counter(c['name'] for c in expected))
    assert len(spec['files']) == profile['archive_files']
    assert op['boundary_stack_complete'] == 1 and op['pending_boundary_ids'] == []
    assert len(calls) == len(expected)
    source_calls = []; ordinals = Counter(); continuations = defaultdict(list)
    for observed, required in zip(calls, expected, strict=True):
        fields = {k: v for k, v in required.items() if k != 'opens'}
        assert {k: observed[k] for k in fields} == fields, ('call forest mismatch', required['id'], fields, observed)
        assert observed['occurrence'] == ordinals[observed['name']]; ordinals[observed['name']] += 1
        assert observed['error'] == '' and observed['relative_depth'] == observed['depth'] - calls[0]['depth']
        if observed['parent'] is not None: assert observed['depth'] > calls[observed['parent']]['depth']
        tail = observed['name'] in plan['sealed_continuations']; assert observed['tail'] == int(tail)
        is_source = observed['name'] == FLOW.CUSTODY + '::_source'
        assert observed['category'] == ('before_only_returned_handle' if is_source else 'safe_before_after')
        assert observed['completion'] == ('caller_continuation' if tail else 'direct_return')
        if tail: continuations[observed['name']].append(observed['continuation'])
        else: assert observed['continuation'] is None
        if is_source: source_calls.append(required)
    assert dict(continuations) == plan['sealed_continuations']
    assert len(source_calls) == len(op['source_requests']) == len(op['reads']) == profile['original_sources']
    handles = {h['label']: h for h in op['handles']}
    assert {h['kind'] for h in handles.values()} == {'source', 'directory', 'lock'}
    for required, request, path in zip(source_calls, op['source_requests'], op['reads'], strict=True):
        assert request == {key: required[key] for key in ('path', 'mode', 'limit')} and path == required['path']
        assert handles[required['opens']]['path'] == path
    active, stack, cuts, opened_by = set(), [], [], {}
    before_seen, after_seen = [], set()
    for position, event in enumerate(events):
        match = re.fullmatch(r'call:([0-9]+):(before|after)', event)
        if match:
            ident, phase = int(match[1]), match[2]; call = calls[ident]
            if phase == 'before':
                assert call['parent'] == (stack[-1] if stack else None)
                before_seen.append(ident); stack.append(ident)
                if 'source_handle' in call: assert call['source_handle'] in active
            else:
                assert stack.pop() == ident and ident not in after_seen; after_seen.add(ident)
                if call['tail']:
                    following = re.fullmatch(r'call:([0-9]+):before', events[position + 1])
                    assert following and calls[int(following[1])]['name'] == call['continuation']
            source_after = call['name'] == FLOW.CUSTODY + '::_source' and phase == 'after'
            alias = events[position + 1] if call['tail'] and phase == 'after' else None
            cuts.append(dict(event=event, index=position, call_id=ident, phase=phase,
                             eligible=not source_after and alias is None, alias=alias,
                             owned_handles=sorted(active), unlink_completed=int('unlink:0:after' in events[:position]),
                             meaning='returned_source_ownership_only' if source_after else 'caller_continuation_alias' if alias else 'selected_call_boundary'))
        elif event.startswith('opened:'):
            label = event[7:]; handle = handles[label]; assert label not in active
            active.add(label); opened_by[label] = stack[-1] if stack else None
            if handle['kind'] == 'source':
                assert stack and calls[stack[-1]]['name'] == FLOW.CUSTODY + '::_source'
                assert expected[stack[-1]]['opens'] == label
            elif handle['kind'] == 'directory':
                assert stack and calls[stack[-1]]['name'] in (FLOW.COORD + '::_names', FLOW.CUSTODY + '::_members')
                assert calls[stack[-1]]['path'] == handle['path']
            else: assert not stack
        elif event.startswith('close:'):
            label, side = event[6:].rsplit(':', 1); assert label in active
            if side == 'after': active.remove(label)
            else: assert side == 'before'
        elif event.startswith('source_request:') or event.startswith('read:'):
            index = int(event.split(':')[1]); assert stack and expected[stack[-1]].get('opens') == 'source:' + str(index)
        elif event.startswith('unlink:'):
            assert stack and calls[stack[-1]]['name'] == FLOW.RELEASE + '::_unlink_exact'
            assert any(handles[label]['kind'] == 'lock' for label in active)
        else: assert event in ('operation:begin', 'operation:end')
    assert before_seen == list(range(len(calls))) and after_seen == set(before_seen) and not stack and not active
    for call in calls:
        if call['name'] in (FLOW.COORD + '::_names', FLOW.CUSTODY + '::_members'):
            labels = [label for label, owner in opened_by.items() if owner == call['id']]
            assert len(labels) == 1
            assert events.index('close:' + labels[0] + ':after') < events.index('call:' + str(call['id']) + ':after')
    return cuts


def verify(plan, report):
    domain(plan)
    assert report['schema'] == 'fsmgen.inactive_release_boundary_qualification.v1'
    assert report['success'] is True and report['forbidden_process_attempts'] == 0
    assert report['prospective_pins'] == load(BASE / 'preflight-pins.json')
    caller_controls(plan, report['caller_controls'])
    assert [r['profile_id'] for r in report['cases']] == [p['id'] for p in plan['profiles']]
    totals = Counter(); roots, domains = [], []
    for profile, row in zip(plan['profiles'], report['cases'], strict=True):
        assert row['name'] == profile['original_case'] and row['selection'] == profile['selection'] and row['inputs_unchanged'] == 1
        OLD.work_records(row); spec, _ = OLD.setup(row); assert OLD.mutation(row) == 0
        totals.update(OLD.trace(row, spec)); OLD.attempt(row, spec)
        cuts = boundaries(plan, profile, row, spec)
        domains.append(dict(profile_id=profile['id'], boundaries=cuts))
        totals.update(cases=1, calls=len(row['operation']['boundary_calls']), eligible=sum(c['eligible'] for c in cuts),
                      continuation_aliases=sum(c['alias'] is not None for c in cuts), ownership_only=sum(c['meaning'] == 'returned_source_ownership_only' for c in cuts))
        roots.extend(dict(kind=k, **row['context'][k]) for k in ('store', 'workspace', 'other_workspace', 'evidence'))
    assert report['allocated'] == roots and len({r['path'] for r in roots}) == len(roots)
    return dict(totals, roots=len(roots), caller_controls=len(report['caller_controls'])), domains


def main():
    plan = load(BASE / 'plan.json'); pins = authenticate(plan); report = load(LOG / 'qualification.json')
    counts, domains = verify(plan, report)
    admissions = [json.loads(line) for line in (LOG / 'admission.jsonl').read_text().splitlines()]
    assert admissions == report['allocated']
    original = load(RELEASE / 'result/qualification.json')
    old_paths = {r['path'] for r in original['allocated']}
    assert not old_paths & {r['path'] for r in admissions}
    for path in old_paths | {r['path'] for r in admissions}: assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    tap = (LOG / 'qualify.tap').read_text(); assertions = 6 * 4 + 4 * 10 + 1
    assert re.findall(r'^ok ([0-9]+) - ', tap, re.M) == [str(i) for i in range(1, assertions + 1)]
    assert re.findall(r'^1\.\.([0-9]+)$', tap, re.M) == [str(assertions)]
    assert not re.search(r'^(not ok|Bail out!)|#\s*(skip|todo)\b', tap, re.M | re.I)
    assert (LOG / 'qualify.exit').read_bytes() == b'0\n'
    def op(r): return r['cases'][0]['operation']
    def call(r, symbol): return next(c for c in op(r)['boundary_calls'] if c['name'].endswith('::' + symbol))
    def handle(r, kind): return next(h for h in op(r)['handles'] if h['kind'] == kind)
    changes = [
        ('missing profile', lambda r: r['cases'].pop()),
        ('duplicate profile', lambda r: r['cases'].append(copy.deepcopy(r['cases'][0]))),
        ('missing call', lambda r: op(r)['boundary_calls'].pop()),
        ('reordered calls', lambda r: op(r)['boundary_calls'].reverse()),
        ('wrong call parent', lambda r: call(r, '_limits').update(parent=None)),
        ('caller impersonation', lambda r: call(r, '_inspect_locked').update(caller='NativeProxyReleaseBoundaryTrace')),
        ('lost tail continuation', lambda r: call(r, '_unlink_exact').update(continuation=None)),
        ('tail reported as direct return', lambda r: call(r, '_unlink_exact').update(completion='direct_return')),
        ('wrong retained descriptor', lambda r: call(r, '_recheck_source').update(source_handle='source:1')),
        ('wrong source path', lambda r: call(r, '_source').update(path='foreign')),
        ('wrong manifest limit', lambda r: next(c for c in op(r)['boundary_calls'] if c.get('path', '').endswith('/image.json') and 'limit' in c).update(limit=65536)),
        ('missing boundary event', lambda r: op(r)['events'].remove('call:0:before')),
        ('extra unknown event', lambda r: op(r)['events'].insert(1, 'unobserved:gap')),
        ('pending call', lambda r: op(r).update(pending_boundary_ids=[0])),
        ('lost absence phase', lambda r: call(r, '_assert_absent').update(phase='finish')),
        ('unclosed source', lambda r: handle(r, 'source').update(closed_at_return=0)),
        ('unclosed directory', lambda r: handle(r, 'directory').update(closed_at_return=0)),
        ('unclosed lock', lambda r: handle(r, 'lock').update(closed_at_return=0)),
        ('lost actual unlink', lambda r: op(r)['result'].update(unlink_completed=0)),
        ('foreign original archive', lambda r: op(r)['result']['release']['archive']['source_bindings'][0]['source'].update(inode=7)),
        ('false success', lambda r: op(r)['result'].update(success=0)),
        ('native authority', lambda r: op(r)['result'].update(runtime_authorized=1)),
        ('changed input', lambda r: r['cases'][0].update(inputs_unchanged=0)),
        ('lost allocation', lambda r: r['allocated'].pop()),
        ('hidden process', lambda r: r.update(forbidden_process_attempts=1)),
        ('caller guard bypass', lambda r: r['caller_controls'][0].update(instrumented_returned=1)),
        ('changed caller diagnostic', lambda r: r['caller_controls'][0].update(instrumented_error='other')),
    ]
    for name, change in changes:
        altered = copy.deepcopy(report); change(altered); assert rejects(lambda: verify(plan, altered)), name
    domain_changes = [
        ('missing profile', lambda p: p['profiles'].pop()),
        ('wrong occurrence count', lambda p: p['profiles'][0]['expected_calls'].update({FLOW.CUSTODY + '::_source': 1})),
        ('unsafe source return category', lambda p: next(b for b in p['source_boundaries'] if b['symbol'] == '_source').update(category='safe_before_after')),
        ('wrong caller continuation', lambda p: p['sealed_continuations'][FLOW.RELEASE + '::_unlink_exact'].append('foreign')),
    ]
    for name, change in domain_changes:
        altered = copy.deepcopy(plan); change(altered); assert rejects(lambda: verify(altered, report)), name
    projection = dict(schema='fsmgen.inactive_release_fault_domain.v1', owner=plan['owner'], profiles=domains,
                      source_pins=pins, qualification=digest((LOG / 'qualification.json').read_bytes()),
                      scope='Healthy observed call boundaries only. Tail completions alias the next before-call; source returns are ownership observations only. No interruption, close-error, omission or native execution qualification.')
    (LOG / 'fault-domain.json').write_text(json.dumps(projection, indent=2, sort_keys=True) + '\n')
    result = dict(schema='fsmgen.inactive_release_boundary_audit.v1', success=True, **counts, assertions=assertions,
                  unchanged_inputs=len(plan['inputs']), prospective_pins=len(pins), original_preserved_absent_roots=len(old_paths),
                  report_falsifiers=[name for name, _ in changes], domain_falsifiers=[name for name, _ in domain_changes],
                  fault_domain=digest((LOG / 'fault-domain.json').read_bytes()), scope=projection['scope'])
    (LOG / 'audit.json').write_text(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__': main()
