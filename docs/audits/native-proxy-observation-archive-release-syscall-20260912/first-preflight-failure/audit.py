"""Reconstruct syscall/report outcomes from retained physical and call evidence."""
import copy
from collections import Counter
import errno
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import stat
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
ORIGINAL = BASE.with_name('native-proxy-release-readback-selection-20260911')
PREVIOUS = BASE.with_name('native-proxy-observation-archive-release-readback-last-20260912')
PIN_NAMES = ('prepare.py', 'prepare-pins.json', 'plan.json', 'qualify.t', 'SyscallTrace.pm', 'expected_trace.py', 'audit.py', 'oracle-preflight.py')


def load(path):
    return json.loads(path.read_bytes())


def signature(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


def rejects(action):
    try:
        action()
    except (AssertionError, KeyError, TypeError, ValueError, IndexError):
        return True
    return False


def expected_cases():
    # Independent reconstruction of the original finite syscall domain.
    original = load(ORIGINAL / 'plan.json')
    profiles = original['profiles']
    assert [p['id'] for p in profiles] == original['syscall_healthy_profiles']
    cases = []
    for profile in profiles:
        expected_reports = []
        for control, phase in [('unlink-eacces', None), ('absence-eio', 'after_unlink'),
                               ('absence-present', 'after_unlink'), ('absence-eio', 'finish'),
                               ('absence-present', 'finish')]:
            expected_reports.append(dict(profile=profile['id'], control=control, phase=phase, attempted=1,
                completed=int(control != 'unlink-eacces'), historical=int(phase == 'finish'),
                latest=None if phase is None else dict(phase=phase, state='unknown' if control == 'absence-eio' else 'present'),
                actual_hold='present' if control == 'unlink-eacces' else 'absent'))
        assert [r for r in original['syscall_reports'] if r['profile'] == profile['id']] == expected_reports
        for report in [None, *expected_reports]:
            effects = dict(unlink_attempted=1, unlink_completed=1, reference_absence_verified=1,
                           last_reference_check=dict(phase='finish', state='absent'))
            if report:
                effects.update(unlink_completed=report['completed'], reference_absence_verified=report['historical'],
                               last_reference_check=report['latest'])
            cases.append(dict(index=len(cases), name=profile['id'] + ':' +
                ('healthy' if report is None else report['control'] + ':' + str(report['phase'])),
                profile_id=profile['id'], selection=profile['selection'], selector=report,
                expected_success=int(report is None), expected_effects=effects))
    return cases


def domain(plan):
    assert plan['cases'] == expected_cases()
    assert plan['owner'] == load(ORIGINAL / 'plan.json')['syscall_owner']
    assert plan['source_revision'] == 'b6d957ca33c99956ccc7559764fa863e9f89567a'
    assert plan['component'] == BASE.name and plan['schema'] == 'fsmgen.release_syscall_plan.v1'


def authenticate(plan):
    prepare = module('syscall_plan_builder', BASE / 'prepare.py')
    assert plan == prepare.build()
    pins = load(BASE / 'preflight-pins.json')
    assert pins == [prepare.pin(BASE / name) for name in PIN_NAMES]
    return pins


def diagnostic(selector):
    if selector is None:
        return ''
    return {'unlink-eacces': 'cannot unlink exact observation hold: Permission denied\n',
            'absence-eio': 'cannot establish exact path absence: Input/output error\n',
            'absence-present': 'released observation hold remains present\n'}[selector['control']]


def native_present(observation, node):
    assert set(observation) == {'metadata', 'errno'} and observation['errno'] == 0
    m = observation['metadata']
    assert len(m) == 13 and stat.S_ISREG(m[2])
    assert (m[0], m[1], stat.S_IMODE(m[2]), m[3], m[4], m[7]) == (
        node['device'], node['inode'], node['mode'], node['links'], node['uid'], node['size_bytes'])


def syscall(row, selected):
    op = row['operation']; trace = op['syscall_trace']; hold = op['expected_hold']
    assert set(trace) == {'hits', 'unlink', 'absence'} and trace['hits'] == int(selected is not None)
    unlink = trace['unlink']
    assert set(unlink) == {'path', 'before', 'after', 'modeled', 'actual', 'reported'}
    assert unlink['path'] == hold
    key = hold[len(row['context']['store']['path']) + 1:]
    node = op['before']['store'][key]
    native_present(unlink['before'], node)
    denied = selected is not None and selected['control'] == 'unlink-eacces'
    assert unlink['modeled'] == int(denied)
    if denied:
        assert unlink['actual'] == dict(executed=0, count=None, errno=None)
        assert unlink['reported'] == dict(count=0, errno=errno.EACCES)
        assert unlink['after'] == unlink['before'] and op['after']['store'][key] == node
        assert op['unlinks'] == [] and trace['absence'] == []
    else:
        assert unlink['actual'] == dict(executed=1, count=1, errno=0)
        assert unlink['reported'] == dict(count=1, errno=0)
        assert unlink['after'] == dict(metadata=[], errno=errno.ENOENT)
        assert key not in op['after']['store']
        assert op['unlinks'] == [dict(paths=[hold], actual_count=1, actual_errno=0)]
        phases = ['after_unlink', 'finish'] if selected is None or selected['phase'] == 'finish' else ['after_unlink']
        assert len(trace['absence']) == len(phases)
        absent_calls = [c for c in op['boundary_calls'] if c['name'] == 'NativeProxyPrivateWorkspace::_absent']
        assert len(absent_calls) == len(phases)
        for check, phase, call in zip(trace['absence'], phases, absent_calls, strict=True):
            modeled = selected is not None and selected['phase'] == phase
            reported = dict(metadata=[], errno=errno.ENOENT)
            if modeled:
                reported = dict(metadata=[], errno=errno.EIO) if selected['control'] == 'absence-eio' else dict(
                    metadata=unlink['before']['metadata'], errno=0)
            assert check == dict(path=hold, call_id=call['id'], phase=phase, modeled=int(modeled),
                                 actual=dict(metadata=[], errno=errno.ENOENT), reported=reported)
    return dict(unlink_syscalls=int(not denied), suppressed_unlinks=int(denied),
                absence_syscalls=len(trace['absence']), modeled_reports=int(selected is not None))


def verify_row(plan, case, row, support, oracle):
    keys = set('matrix_case profile_id name selection context setup_before work_selection work_settlement before_archive archive_receipt before_mutation mutation arguments operation prospective input_fingerprint_before input_fingerprint_after inputs_unchanged roots_absent'.split())
    if case['selection']['runtime'] == 'retired': keys.add('retirement')
    if case['selection']['last_observation']: keys.add('controlled_setup_removed_hold')
    assert set(row) == keys and row['matrix_case'] == case
    assert row['profile_id'] == case['profile_id'] and row['selection'] == case['selection']
    assert row['name'] == case['selection']['name']
    assert row['roots_absent'] is True and row['inputs_unchanged'] == 1
    assert re.fullmatch('[0-9a-f]{64}', row['input_fingerprint_before'])
    assert row['input_fingerprint_before'] == row['input_fingerprint_after']
    old = support.OLD
    old.work_records(row); spec, _ = old.setup(row); assert old.mutation(row) == 0
    op = row['operation']; selected = case['selector']
    calls = support.PRIOR.FLOW.derive(row['context'], op['before'], spec)
    expected = oracle.derive(calls, row['context'], plan['sealed_symbols'], selected)
    assert row['prospective'] == dict(error='', resolved=selected, expected_error=diagnostic(selected),
        flow_calls=len(calls), flow_sha256=signature(calls))
    assert op['events'] == expected['events']
    assert len(op['boundary_calls']) == len(expected['calls'])
    for actual, required in zip(op['boundary_calls'], expected['calls'], strict=True):
        assert {k: v for k, v in actual.items() if k != 'depth'} == required
        assert type(actual['depth']) is int and 0 < actual['depth'] <= 128
        if actual['parent'] is not None:
            assert actual['depth'] > op['boundary_calls'][actual['parent']]['depth']
    assert op['interrupted_boundary_ids'] == expected['interrupted_boundary_ids']
    assert op['injected_hits'] == expected['injected_hits'] == 0
    assert op['syscall_trace']['hits'] == expected['report_hits']
    assert op['returned'] == 1 and op['error'] == '' and op['modeled_close_hits'] == 0
    assert all('modeled_close_errno' not in h for h in op['handles'])
    counts = Counter(old.trace(row, spec))
    assert len(op['handles']) == len(expected['handles'])
    for actual, required in zip(op['handles'], expected['handles'], strict=True):
        assert {k: actual[k] for k in required if k != 'source_call'} == {k: v for k, v in required.items() if k != 'source_call'}
    sources = [c for c in expected['calls'] if c['name'] == 'NativeProxyImageCustody::_source']
    assert op['source_requests'] == [{k: c[k] for k in ('path', 'mode', 'limit')} for c in sources]
    assert op['reads'] == [c['path'] for c in sources] and len(sources) == counts['sources']
    assert op['expected_hold'] == row['context']['acquired']['observation_reference']['source']['identity']['path']
    counts.update(syscall(row, selected))
    after = copy.deepcopy(op['before'])
    if expected['unlinked']:
        del after['store'][op['expected_hold'][len(row['context']['store']['path']) + 1:]]
    assert op['after'] == after
    effects = case['expected_effects']
    assert effects['unlink_completed'] == int(expected['unlinked'])
    if selected is None:
        old.attempt(row, spec)
    else:
        assert op['result'] == dict(schema='fsmgen.inactive_observation_release_attempt.v1', runtime_authorized=0,
            executable=None, success=0, error=diagnostic(selected), release=None, **effects)
    assert {k: op['result'][k] for k in effects} == effects
    for field in ('runtime_authorized', 'success', 'unlink_attempted', 'unlink_completed', 'reference_absence_verified'):
        assert type(op['result'][field]) is int
    counts.update(cases=1, successes=int(selected is None), rejections=int(selected is not None), calls=len(op['boundary_calls']))
    return counts, [dict(kind=k, **row['context'][k]) for k in ('store', 'workspace', 'other_workspace', 'evidence')]


def header(plan, report, pins, support):
    assert set(report) == set('schema success prospective_pins cases case_files allocated caller_controls current_case forbidden_attempts'.split())
    assert report['schema'] == 'fsmgen.release_syscall_qualification.v1'
    assert report['success'] is True and report['forbidden_attempts'] == 0
    assert report['prospective_pins'] == pins and report['cases'] == [] and report['current_case'] is None
    assert len(report['case_files']) == len(plan['cases'])
    support.caller_controls(plan, report['caller_controls'])
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        assert set(receipt) == {'index', 'name', 'path', 'size_bytes', 'sha256'}
        assert receipt['index'] == case['index'] and receipt['name'] == case['name']
        assert receipt['path'] == str(LOG.relative_to(ROOT)) + '/cases/case-%04d.json' % case['index']


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    plan = load(BASE / 'plan.json'); domain(plan); pins = authenticate(plan)
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, prospective_pins=len(pins), inputs=len(plan['inputs']), allocated_fixtures=0)))
        return
    storage = BASE / 'result' if sys.argv[1:] == ['--verify-saved'] else LOG
    prepare = module('syscall_result_pin_reader', BASE / 'prepare.py')
    result_pins = load(BASE / 'oracle-preflight-result-pins.json')
    assert result_pins == [prepare.pin(BASE / 'result/oracle-preflight' / ('oracle-preflight.' + ext))
                           for ext in ('json', 'stdout', 'stderr', 'exit')]
    preflight = load(BASE / 'result/oracle-preflight/oracle-preflight.json')
    assert preflight['success'] is True and preflight['allocated_fixtures'] == 0
    assert preflight['prospective_pins'] == pins
    assert [c['case'] for c in preflight['comparisons']] == [c['name'] for c in plan['cases']]
    support = module('syscall_saved_source_support', BASE.with_name('native-proxy-observation-archive-release-ordinary-before-20260911') / 'audit.py')
    oracle = module('syscall_scope_oracle', BASE / 'expected_trace.py')
    report = load(storage / 'qualification.json'); header(plan, report, pins, support)
    totals, roots, examples = Counter(), [], []
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        row = support.read_case(storage, receipt)
        counts, allocated = verify_row(plan, case, row, support, oracle)
        totals.update(counts); roots.extend(allocated); examples.append(row)
    assert (totals['cases'], totals['successes'], totals['rejections']) == (24, 4, 20)
    assert report['allocated'] == roots and len({r['path'] for r in roots}) == len(roots) == 96
    assert [json.loads(line) for line in (storage / 'admission.jsonl').read_text().splitlines()] == roots
    prior = [r['path'] for p in plan['previous_root_reports'] for r in load(ROOT / p)['allocated']]
    assert len(prior) == len(set(prior)) == 24584 and not set(prior) & {r['path'] for r in roots}
    for relative in prior + [r['path'] for r in roots]:
        assert relative.startswith('.artifacts/') and '..' not in Path(relative).parts
        assert not (ROOT / relative).exists() and not (ROOT / relative).is_symlink()
    assert {p.name for p in (storage / 'cases').iterdir()} == {'case-%04d.json' % c['index'] for c in plan['cases']}
    support.tap(storage / 'qualify.tap', 289)
    assert (storage / 'qualify.exit').read_bytes() == b'0\n' and (storage / 'qualify.stderr').read_bytes() == b''
    falsifiers = []
    mutations = [
        ('invented-unlink', 1, lambda r: r['operation']['syscall_trace']['unlink']['actual'].update(executed=1)),
        ('wrong-unlink-errno', 1, lambda r: r['operation']['syscall_trace']['unlink']['reported'].update(errno=errno.EIO)),
        ('invented-actual-absence-error', 2, lambda r: r['operation']['syscall_trace']['absence'][0]['actual'].update(errno=errno.EIO)),
        ('concealed-modeled-presence', 3, lambda r: r['operation']['syscall_trace']['absence'][0]['reported'].update(metadata=[])),
        ('lost-historical-absence', 4, lambda r: r['operation']['result'].update(reference_absence_verified=0)),
        ('stale-latest-absence', 5, lambda r: r['operation']['result']['last_reference_check'].update(state='absent')),
        ('wrong-error-precedence', 4, lambda r: r['operation']['result'].update(error='cannot close retained release descriptor: Input/output error\n')),
        ('unclosed-source', 2, lambda r: r['operation']['handles'][0].update(actual_close_ok=0)),
        ('lost-archive', 0, lambda r: r['operation']['after'].update(evidence={})),
        ('lost-other-owner', 2, lambda r: r['operation']['after'].update(other_workspace={})),
        ('invented-runtime-retirement', 12, lambda r: r.update(retirement={})),
        ('missing-final-hold-setup', 18, lambda r: r.pop('controlled_setup_removed_hold')),
        ('lost-final-image', 20, lambda r: r['operation']['after']['store'].pop('images/' + r['context']['runtime']['image']['key'] + '/rustup')),
        ('wrong-call-prefix', 2, lambda r: r['operation']['events'].pop(1)),
        ('wrong-absence-phase', 4, lambda r: r['operation']['syscall_trace']['absence'][-1].update(phase='after_unlink')),
        ('wrong-native-identity', 1, lambda r: r['operation']['syscall_trace']['unlink']['before']['metadata'].__setitem__(1, -1)),
    ]
    for name, index, mutate in mutations:
        bad = copy.deepcopy(examples[index]); mutate(bad)
        assert rejects(lambda: verify_row(plan, plan['cases'][index], bad, support, oracle)), name
        falsifiers.append(name)
    for name, mutate in [('missing-case', lambda p: p['cases'].pop()),
                         ('duplicate-case', lambda p: p['cases'].__setitem__(1, p['cases'][0])),
                         ('wrong-selected-phase', lambda p: p['cases'][2]['selector'].update(phase='finish'))]:
        bad = copy.deepcopy(plan); mutate(bad); assert rejects(lambda: domain(bad)), name; falsifiers.append(name)
    for name, mutate in [('incomplete-report', lambda r: r.update(success=False)),
                         ('lost-receipt', lambda r: r['case_files'].pop()),
                         ('unconsumed-case', lambda r: r.update(current_case={})),
                         ('altered-pin', lambda r: r['prospective_pins'][0].update(sha256='0' * 64))]:
        bad = copy.deepcopy(report); mutate(bad); assert rejects(lambda: header(plan, bad, pins, support)), name; falsifiers.append(name)
    for field, value in [('size_bytes', 0), ('sha256', '0' * 64)]:
        bad = copy.deepcopy(report['case_files'][0]); bad[field] = value
        assert rejects(lambda: support.read_case(storage, bad)); falsifiers.append('corrupt-case-' + field)
    result = dict(success=True, totals=dict(totals), assertions=289, roots_absent=len(roots),
        prior_roots_absent=len(prior), prospective_pins=len(pins), unchanged_inputs=len(plan['inputs']),
        falsifiers=falsifiers, scope=plan['scope'])
    if storage == LOG:
        with (LOG / 'audit.json').open('x') as output: output.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
