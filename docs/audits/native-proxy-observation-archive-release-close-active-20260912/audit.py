"""Verify active-runtime close reports with unchanged qualified row and runtime-state oracles."""
from collections import Counter
import copy
import errno
import importlib.util
import json
import os
from pathlib import Path
import re
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name


def load(path):
    return json.loads(path.read_bytes())


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec); spec.loader.exec_module(value)
    return value


PREPARE = module('active_close_matrix_prepare', BASE / 'prepare.py')
CORE = module('active_close_qualified_row_audit', PREPARE.ORDINARY / 'audit.py')
ACTIVE = module('active_close_original_runtime_state_audit', PREPARE.ACTIVE / 'audit.py')
ORACLE = module('active_close_baseline_preflight', BASE / 'oracle-preflight.py')
SUPPORT = CORE.SUPPORT
OLD, FLOW, SELECT = CORE.OLD, CORE.FLOW, CORE.SELECT
TRACE, PREFIX, SIGNATURE = CORE.TRACE, CORE.PREFIX, CORE.SIGNATURE
rejects = CORE.rejects
PIN_NAMES = ['plan.json', 'prepare.py', 'prepare-pin.json', 'qualify.t', 'audit.py',
    'oracle-preflight.py', 'oracle-pins.json', 'result/preflight/oracle.json',
    'result/preflight/oracle.stdout', 'result/preflight/oracle.stderr',
    'result/preflight/oracle.exit', 'result/preflight/recovery.json']


def domain(plan):
    original = load(PREPARE.SELECTION / 'plan.json'); selected = original['profiles'][2]
    assert plan['schema'] == 'fsmgen.release_active_close_plan.v1'
    assert plan['source_revision'] == PREPARE.REVISION and plan['component'] == BASE.name
    assert plan['owner'] == selected['owner'] and plan['profile_id'] == selected['id']
    assert plan['selection'] == selected['selection'] and plan['cases'] == selected['cases']
    assert len(plan['cases']) == 1 + len(selected['selectors'])
    assert plan['report_contract'] == original['report_contract']
    assert plan['source_boundaries'] == load(PREPARE.BOUNDARY / 'plan.json')['source_boundaries']
    assert plan['sealed_symbols'] == list(load(PREPARE.BOUNDARY / 'plan.json')['sealed_continuations'])


def authenticate(plan):
    assert PREPARE.build() == plan
    CORE.authenticate(load(PREPARE.ORDINARY / 'plan.json'))
    pins = load(BASE / 'preflight-pins.json')
    assert pins == [PREPARE.pin(BASE / n) for n in PIN_NAMES]
    previous = [r['path'] for p in plan['previous_root_reports'] for r in load(ROOT / p)['allocated']]
    assert len(previous) == len(set(previous))
    for path in previous:
        relative = Path(path); assert not relative.is_absolute() and '..' not in relative.parts
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    return pins


def prerequisites(plan):
    inherited = CORE.prerequisites(load(PREPARE.ORDINARY / 'plan.json'))
    directory = BASE / 'result/preflight'
    names = ['oracle.json', 'oracle.stdout', 'oracle.stderr', 'oracle.exit']
    copies = load(directory / 'recovery.json')
    assert [r['destination'] for r in copies] == [str((directory / n).relative_to(ROOT)) for n in names]
    assert [r['source'] for r in copies] == [str((LOG / n).relative_to(ROOT)) for n in names]
    for record in copies:
        assert {k: record[k] for k in ('size_bytes', 'sha256')} == {
            k: PREPARE.pin(ROOT / record['destination'])[k] for k in ('size_bytes', 'sha256')}
    assert (directory / 'oracle.exit').read_bytes() == b'0\n'
    predicted = ORACLE.evaluate(plan)
    assert load(directory / 'oracle.json') == predicted
    assert load(directory / 'oracle.stdout') == ORACLE.summary(predicted)
    assert (directory / 'oracle.stderr').read_bytes() == b''
    return dict(inherited=inherited, baseline_predictions=len(predicted['predictions']),
        baseline_falsifiers=len(predicted['falsifiers']), copies=len(copies))


def header(plan, report, pins):
    assert set(report) == {'schema', 'success', 'prospective_pins', 'cases', 'case_files', 'allocated',
        'caller_controls', 'current_case', 'forbidden_process_attempts', 'errno_constants', 'errno_text'}
    assert report['schema'] == 'fsmgen.release_active_close_qualification.v1' and report['success'] is True
    assert report['prospective_pins'] == pins and report['forbidden_process_attempts'] == 0
    assert report['cases'] == [] and report['current_case'] is None
    assert report['errno_constants'] == dict(EIO=errno.EIO) and report['errno_text'] == dict(EIO=os.strerror(errno.EIO))
    SUPPORT.caller_controls(plan, report['caller_controls'])
    assert len(report['case_files']) == len(plan['cases'])
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        assert set(receipt) == {'index', 'name', 'path', 'size_bytes', 'sha256'}
        assert receipt['index'] == case['index'] and receipt['name'] == case['name']
        assert receipt['path'] == '.artifacts/logs/' + BASE.name + '/cases/case-%04d.json' % case['index']
        assert type(receipt['size_bytes']) is int and receipt['size_bytes'] > 0
        assert re.fullmatch('[0-9a-f]{64}', receipt['sha256'])


def _verify_close(plan, case, row):
    assert set(row) == set('matrix_case profile_id name selection context setup_before work_selection work_settlement before_archive archive_receipt before_mutation mutation arguments operation prospective input_fingerprint_before input_fingerprint_after inputs_unchanged roots_absent'.split())
    assert row['matrix_case'] == case and row['profile_id'] == plan['profile_id']
    assert row['selection'] == plan['selection'] and row['name'] == plan['selection']['name']
    assert row['roots_absent'] is True and row['inputs_unchanged'] == 1
    assert re.fullmatch('[0-9a-f]{64}', row['input_fingerprint_before'])
    assert row['input_fingerprint_before'] == row['input_fingerprint_after']
    OLD.work_records(row); spec, _ = OLD.setup(row); assert OLD.mutation(row) == 0
    op = row['operation']; calls = FLOW.derive(row['context'], op['before'], spec)
    bindings = SELECT.ownership(calls, row['context']); by_address = {b['address']: b for b in bindings}
    resolved = [by_address[r['address']] for r in case['reports']]
    assert row['prospective'] == dict(error='', resolved=resolved, flow_calls=len(calls), flow_sha256=SIGNATURE(calls))
    expected = TRACE.derive(calls, row['context'], plan['sealed_symbols'], resolved, os.strerror(errno.EIO))
    healthy = SUPPORT.TRACE.derive(calls, row['context'], plan['sealed_symbols'], None)
    assert expected == PREFIX.reference(calls, plan['sealed_symbols'], healthy, bindings, resolved[0] if resolved else None)
    assert op['events'] == expected['events']
    assert len(op['boundary_calls']) == len(expected['calls'])
    for actual, required in zip(op['boundary_calls'], expected['calls'], strict=True):
        assert {k: v for k, v in actual.items() if k != 'depth'} == required
        assert type(actual['depth']) is int and 0 < actual['depth'] <= 128
        if actual['parent'] is not None: assert actual['depth'] > op['boundary_calls'][actual['parent']]['depth']
    assert op['interrupted_boundary_ids'] == expected['interrupted_boundary_ids'] and op['injected_hits'] == 0
    assert op['reported_error_hits'] == [r['address'] for r in resolved]
    assert op['modeled_close_hits'] == expected['reported_error_hits'] == len(resolved)
    counts = OLD.trace(row, spec)
    assert len(op['handles']) == len(expected['handles'])
    for actual, required in zip(op['handles'], expected['handles'], strict=True):
        assert all(actual[k] == v for k, v in required.items() if k not in ('source_call', 'close_scope'))
    source_calls = [calls[h['source_call']] for h in expected['handles'] if h['kind'] == 'source']
    assert op['source_requests'] == [{k: c[k] for k in ('path', 'mode', 'limit')} for c in source_calls]
    assert op['reads'] == [c['path'] for c in source_calls]
    assert op['returned'] == 1 and op['error'] == ''
    handles = {h['label']: h for h in op['handles']}
    assert len(op['close_reports']) == len(handles) == len(expected['reports'])
    targets = {r['label']: r['address'] for r in resolved}
    for actual, required in zip(op['close_reports'], expected['reports'], strict=True):
        h = handles[required['label']]; applied = required['applied']
        wanted = {k: h[k] for k in ('label', 'kind', 'path', 'descriptor', 'device', 'inode')}
        wanted.update(actual_return=1, actual_errno=0, closed_after_call=1,
            report_applied=int(applied), reported_return=int(not applied),
            reported_errno=errno.EIO if applied else 0, selected_address=targets.get(h['label']))
        assert actual == wanted
        assert ('modeled_close_errno' in h) == applied
        if applied: assert h['modeled_close_errno'] == errno.EIO
        for field in ('actual_return', 'actual_errno', 'closed_after_call', 'report_applied', 'reported_return', 'reported_errno'):
            assert type(actual[field]) is int
    unlinked = expected['effects']['unlink_completed']
    assert op['unlinks'] == ([dict(paths=[op['expected_hold']], actual_count=1, actual_errno=0)] if unlinked else [])
    physical = copy.deepcopy(op['before'])
    if unlinked: del physical['store'][op['expected_hold'][len(row['context']['store']['path']) + 1:]]
    assert op['after'] == physical
    if not resolved:
        OLD.attempt(row, spec)
    else:
        assert op['result'] == dict(schema='fsmgen.inactive_observation_release_attempt.v1', runtime_authorized=0,
            executable=None, success=0, error=expected['error'], release=None, **expected['effects'])
    for field in ('runtime_authorized', 'success', 'unlink_attempted', 'unlink_completed', 'reference_absence_verified'):
        assert type(op['result'][field]) is int
    roots = [dict(kind=k, **row['context'][k]) for k in ('store', 'workspace', 'other_workspace', 'evidence')]
    return dict(counts, cases=1, calls=len(op['boundary_calls']), unlinks=unlinked,
        modeled_reports=len(resolved), close_reports=len(op['close_reports']), healthy=int(not resolved),
        failures=int(bool(resolved)), post_unlink_failures=unlinked * int(bool(resolved))), roots


def verify_row(plan, case, row):
    counts, roots = _verify_close(plan, case, row)
    ACTIVE.active_state(row)
    counts['active_state_cases'] = 1
    return counts, roots


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    plan = load(BASE / 'plan.json'); domain(plan); pins = authenticate(plan); prerequisite = prerequisites(plan)
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, pins=len(pins), inputs=len(plan['inputs']), prerequisites=prerequisite,
            new_fixture_roots=0), sort_keys=True)); return
    saved = bool(sys.argv[1:]); storage = BASE / 'result' if saved else LOG
    report = load(storage / 'qualification.json'); header(plan, report, pins)
    totals = Counter(); roots = []; witnesses = {}
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        row = SUPPORT.read_case(storage, receipt); counts, allocated = verify_row(plan, case, row)
        totals.update(counts); roots.extend(allocated)
        if not case['reports']: witnesses['healthy'] = (case, row)
        else:
            kind = case['reports'][0]['kind']
            if kind not in witnesses: witnesses[kind] = (case, row)
            if counts['unlinks']: witnesses['late'] = (case, row)
    assert report['allocated'] == roots
    assert [json.loads(r) for r in (storage / 'admission.jsonl').read_text().splitlines()] == roots
    paths = [r['path'] for r in roots]; assert len(paths) == len(set(paths))
    previous = []
    for path in plan['previous_root_reports']: previous.extend(r['path'] for r in load(ROOT / path)['allocated'])
    assert len(previous) == len(set(previous)) and not set(paths) & set(previous)
    for path in paths + previous:
        relative = Path(path); assert not relative.is_absolute() and '..' not in relative.parts
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    assert {p.name for p in (storage / 'cases').iterdir()} == {'case-%04d.json' % c['index'] for c in plan['cases']}
    assertions = 25 + 12 * len(plan['cases']); SUPPORT.tap(storage / 'qualify.tap', assertions)
    assert (storage / 'qualify.exit').read_bytes() == b'0\n'
    def op(row): return row['operation']
    def modeled(row): return next(h for h in op(row)['handles'] if 'modeled_close_errno' in h)
    def handle(row, kind): return next(h for h in op(row)['handles'] if h['kind'] == kind)
    changes = [
        ('lost-actual-close', 'source', lambda r: modeled(r).update(actual_close_ok=0)),
        ('open-at-return', 'source', lambda r: modeled(r).update(closed_at_return=0)),
        ('open-lock', 'lock', lambda r: handle(r, 'lock').update(closed_after_call=0)),
        ('open-directory-observer', 'healthy', lambda r: handle(r, 'directory').update(observer_closed=0)),
        ('changed-inode', 'healthy', lambda r: handle(r, 'source').update(inode=7)),
        ('unsealed-source', 'healthy', lambda r: handle(r, 'source').update(cloexec_at_handoff=0)),
        ('lost-modeled-report', 'source', lambda r: op(r).update(modeled_close_hits=0)),
        ('lost-selected-hit', 'source', lambda r: op(r)['reported_error_hits'].clear()),
        ('missing-close-report', 'healthy', lambda r: op(r)['close_reports'].pop()),
        ('false-actual-return', 'source', lambda r: next(x for x in op(r)['close_reports'] if x['report_applied']).update(actual_return=0)),
        ('hidden-reported-error', 'source', lambda r: next(x for x in op(r)['close_reports'] if x['report_applied']).update(reported_return=1)),
        ('wrong-reported-errno', 'source', lambda r: next(x for x in op(r)['close_reports'] if x['report_applied']).update(reported_errno=errno.ENOSPC)),
        ('invented-call-injection', 'source', lambda r: op(r).update(injected_hits=1)),
        ('lost-close-event', 'healthy', lambda r: op(r)['events'].remove(next(e for e in op(r)['events'] if e.startswith('close:')))),
        ('missing-call', 'healthy', lambda r: op(r)['boundary_calls'].pop()),
        ('wrong-caller', 'healthy', lambda r: op(r)['boundary_calls'][0].update(caller='Foreign')),
        ('lost-pending-scope', 'directory', lambda r: op(r)['interrupted_boundary_ids'].clear()),
        ('wrong-current-owner', 'source', lambda r: r['prospective']['resolved'][0].update(close_scope='Foreign')),
        ('wrong-current-label', 'source', lambda r: r['prospective']['resolved'][0].update(label='source:99999')),
        ('changed-input', 'healthy', lambda r: r.update(inputs_unchanged=0)),
        ('lost-other-owner', 'healthy', lambda r: op(r)['after']['store'].pop('coordination.lock')),
        ('lost-unlink', 'late', lambda r: op(r)['result'].update(unlink_completed=0)),
        ('lost-absence', 'late', lambda r: op(r)['result'].update(reference_absence_verified=0)),
        ('replaced-error', 'source', lambda r: op(r)['result'].update(error='different\n')),
        ('false-success', 'source', lambda r: op(r)['result'].update(success=1)),
        ('native-authority', 'source', lambda r: op(r)['result'].update(runtime_authorized=1)),
        ('private-read', 'healthy', lambda r: op(r)['reads'].append(r['context']['workspace']['path'] + '/rust-tool-resolution')),
        ('publication-attempt', 'healthy', lambda r: op(r).update(forbidden_mutation_attempts=1)),
        ('invented-retirement', 'healthy', lambda r: r.update(retirement={})),
        ('lost-active-runtime-reference', 'healthy', lambda r: op(r)['after']['store'].pop(
            r['context']['runtime']['reference']['global']['identity']['path'][len(r['context']['store']['path']) + 1:])),
        ('lost-active-workspace', 'healthy', lambda r: op(r)['after']['workspace'].clear()),
        ('retired-setup-substituted', 'healthy', lambda r: r['before_archive']['workspace'].clear()),
    ]
    for name, kind, change in changes:
        case, original = witnesses[kind]; changed = copy.deepcopy(original); change(changed)
        assert rejects(lambda: verify_row(plan, case, changed)), name
    domain_controls = []
    for name, change in [('missing-case', lambda p: p['cases'].pop()),
                         ('duplicated-case', lambda p: p['cases'].append(copy.deepcopy(p['cases'][1]))),
                         ('wrong-report', lambda p: p['cases'][1]['reports'][0].update(errno='ENOSPC'))]:
        changed = copy.deepcopy(plan); change(changed); assert rejects(lambda: domain(changed)); domain_controls.append(name)
    header_controls = []
    for name, change in [('missing-pin', lambda r: r['prospective_pins'].pop()),
                         ('missing-case-receipt', lambda r: r['case_files'].pop()),
                         ('invented-process', lambda r: r.update(forbidden_process_attempts=1)),
                         ('wrong-errno', lambda r: r['errno_constants'].update(EIO=0))]:
        changed = copy.deepcopy(report); change(changed); assert rejects(lambda: header(plan, changed, pins)); header_controls.append(name)
    result = dict(schema='fsmgen.release_active_close_audit.v1', success=True, totals=dict(totals),
        assertions=assertions, source_revision=plan['source_revision'], prospective_pins=pins,
        input_files=len(plan['inputs']), prerequisites=prerequisite, roots_absent=len(paths),
        prior_roots_absent=len(previous), case_bytes=sum(r['size_bytes'] for r in report['case_files']),
        row_falsifiers=[n for n, _, _ in changes], domain_falsifiers=domain_controls, header_falsifiers=header_controls,
        scope=plan['scope'])
    if saved: assert load(storage / 'audit.json') == result
    else:
        with (storage / 'audit.json').open('x') as output: output.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
