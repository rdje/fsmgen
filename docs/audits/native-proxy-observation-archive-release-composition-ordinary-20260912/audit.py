"""Verify ordinary composition traces, native custody and first-error precedence."""
from collections import Counter
import copy
import errno
import hashlib
import importlib.util
import inspect
import json
import os
from pathlib import Path
import re
import stat
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


PREPARE = module('ordinary_composition_audit_prepare', BASE / 'prepare.py')
PREFLIGHT = module('ordinary_composition_audit_preflight', BASE / 'preflight.py')
SUPPORT = module('ordinary_composition_original_support', PREPARE.CALLS / 'audit.py')
OLD = SUPPORT.OLD
FLOW = SUPPORT.PRIOR.FLOW
TRACE = PREFLIGHT.TRACE
SIGNATURE = SUPPORT.signature
ERROR_TEXT = {k: os.strerror(getattr(errno, k)) for k in ('EIO', 'ENOSPC')}
PURE_NAMES = ('CompositionPlan.pm', 'DirectoryRead.pm', 'CompositionReports.pm', 'expected_trace.py',
              'prepare.py', 'prepare-pin.json', 'plan.json', 'flow-vectors.json', 'flow-qualify.t', 'preflight.py')
COPY_NAMES = ('flow-qualification.json', 'flow-qualify.tap', 'flow-qualify.stderr', 'flow-qualify.exit',
              'preflight.json', 'preflight.stdout', 'preflight.stderr', 'preflight.exit')
MAIN_NAMES = ('plan.json', 'prepare.py', 'prepare-pin.json', 'qualify.t', 'qualifier-pin.json',
              'audit.py', 'trace-adaptation.json', 'flow-preflight-pins.json',
              *('result/preflight/' + n for n in COPY_NAMES), 'result/preflight/recovery.json')


def rejects(action):
    try:
        action()
    except (AssertionError, KeyError, ValueError, TypeError, IndexError, StopIteration):
        return True
    return False


def domain(plan):
    original = load(PREPARE.SELECTION / 'plan.json'); profile = original['profiles'][0]
    assert plan['schema'] == 'fsmgen.release_ordinary_composition_plan.v1'
    assert plan['source_revision'] == PREPARE.REVISION and plan['component'] == BASE.name
    assert plan['owner'] == profile['owner'] and plan['profile_id'] == profile['id']
    assert plan['selection'] == profile['selection']
    assert plan['cases'] == [dict(index=c['index'], name=':'.join(str(c['recipe'][k]) for k in ('kind', 'scope', 'order')),
                                  recipe=c['recipe']) for c in profile['cases']]
    for field in ('report_contract', 'directory_contract', 'source_boundaries', 'sealed_symbols', 'previous_root_reports'):
        assert plan[field] == original[field]


def trace_adaptation():
    original = inspect.getsource(OLD.trace).strip()
    old_check = "assert h['reported_errno'] == (errno.EIO if 'modeled_close_errno' in h else 0)"
    new_check = "assert h['reported_errno'] == (h['modeled_close_errno'] if 'modeled_close_errno' in h else 0)"
    assert original.count(old_check) == 1
    expected = original.replace('def trace(row, spec):', 'def native_trace(row, spec):', 1)
    expected = expected.replace('before = flattened(', 'before = OLD.flattened(', 1).replace(old_check, new_check)
    assert inspect.getsource(native_trace).strip() == expected
    return dict(original_path=str(Path(OLD.__file__).relative_to(ROOT)),
        original_body_sha256=hashlib.sha256(original.encode()).hexdigest(),
        adapted_body_sha256=hashlib.sha256(expected.encode()).hexdigest(),
        contract='Only function naming, explicit original footprint qualification and the per-handle reported '
                 'errno expression differ. The row oracle separately binds each modeled errno to its exact '
                 'selected EIO/ENOSPC report; native closure, identity, source and lock checks remain complete.')


def authenticate(plan):
    built, vectors = PREPARE.build()
    assert built == plan and vectors == load(BASE / 'flow-vectors.json')
    assert load(BASE / 'flow-preflight-pins.json') == [PREPARE.pin(BASE / n) for n in PURE_NAMES]
    assert load(BASE / 'qualifier-pin.json') == PREPARE.pin(BASE / 'qualify.t')
    assert load(BASE / 'trace-adaptation.json') == trace_adaptation()
    pins = load(BASE / 'preflight-pins.json'); assert pins == [PREPARE.pin(BASE / n) for n in MAIN_NAMES]
    return pins, vectors


def prerequisites(vectors):
    directory = BASE / 'result/preflight'; copies = load(directory / 'recovery.json')
    assert [r['destination'] for r in copies] == [str((directory / n).relative_to(ROOT)) for n in COPY_NAMES]
    for r in copies:
        assert {k: r[k] for k in ('size_bytes', 'sha256')} == {
            k: PREPARE.pin(ROOT / r['destination'])[k] for k in ('size_bytes', 'sha256')}
    pins = load(BASE / 'flow-preflight-pins.json')
    qualified = load(directory / 'flow-qualification.json'); preflight = load(directory / 'preflight.json')
    assert qualified['success'] is True and qualified['prospective_pins'] == pins
    assert qualified['allocated'] == [] and qualified['forbidden_process_attempts'] == 0
    assert preflight['success'] is True and preflight['prospective_pins'] == pins
    assert preflight['errno_constants'] == {k: getattr(errno, k) for k in ERROR_TEXT}
    assert preflight['errno_text'] == ERROR_TEXT
    observed = [dict(profile=p['profile'], name=v['name'], resolved=len(v['expected']),
        resolution_sha256=PREFLIGHT.signature(v['expected']), inputs_unchanged=1)
        for p in vectors['profiles'] for v in p['variants']]
    assert qualified['variants'] == observed
    assert [(r['profile'], r['variant'], r['predictions']) for r in preflight['variants']] == [
        (r['profile'], r['name'], r['resolved']) for r in observed]
    assert len(qualified['controls']) == len({r['name'] for r in qualified['controls']}) == 10
    assert all(r['returned'] == 0 and r['error'].endswith('\n') for r in qualified['controls'])
    assert len(preflight['falsifiers']) == len(set(preflight['falsifiers'])) == 11
    assertions = 2 * len(observed) + 21
    assert preflight['pure_assertions'] == assertions
    assert preflight['predictions'] == sum(r['resolved'] for r in observed)
    SUPPORT.tap(directory / 'flow-qualify.tap', assertions)
    assert (directory / 'flow-qualify.exit').read_bytes() == (directory / 'preflight.exit').read_bytes() == b'0\n'
    return dict(variants=len(observed), predictions=preflight['predictions'], assertions=assertions, copies=len(copies))


def header(plan, report, pins):
    assert set(report) == {'schema', 'success', 'prospective_pins', 'cases', 'case_files', 'allocated',
        'caller_controls', 'current_case', 'forbidden_process_attempts', 'errno_constants', 'errno_text'}
    assert report['schema'] == 'fsmgen.release_ordinary_composition_qualification.v1' and report['success'] is True
    assert report['prospective_pins'] == pins and report['forbidden_process_attempts'] == 0
    assert report['cases'] == [] and report['current_case'] is None
    assert report['errno_constants'] == {k: getattr(errno, k) for k in ERROR_TEXT} and report['errno_text'] == ERROR_TEXT
    SUPPORT.caller_controls(plan, report['caller_controls'])
    assert len(report['case_files']) == len(plan['cases'])
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        assert set(receipt) == {'index', 'name', 'path', 'size_bytes', 'sha256'}
        assert receipt['index'] == case['index'] and receipt['name'] == case['name']
        assert receipt['path'] == '.artifacts/logs/' + BASE.name + '/cases/case-%04d.json' % case['index']
        assert type(receipt['size_bytes']) is int and receipt['size_bytes'] > 0
        assert re.fullmatch('[0-9a-f]{64}', receipt['sha256'])


def native_trace(row, spec):
    context = row['context']; operation = row['operation']; planned = row['selection']
    before = OLD.flattened(context, operation['before']); events = operation['events']; handles = operation['handles']
    assert events[0] == 'operation:begin' and len(events) == len(set(events))
    assert events.count('operation:end') == operation['returned']
    if operation['returned']: assert events[-1] == 'operation:end'
    by_label = {h['label']: h for h in handles}; assert len(by_label) == len(handles)
    assert [event[7:] for event in events if event.startswith('opened:')] == list(by_label)
    active = set(); stack = []
    for event in events:
        if event.startswith('opened:'):
            label = event[7:]; assert label not in active; active.add(label)
        elif event.startswith('close:'):
            label, side = event[6:].rsplit(':', 1)
            if side == 'before': assert label in active; stack.append(label)
            else: assert side == 'after' and stack.pop() == label; active.remove(label)
    assert not active and not stack and operation['all_observed_handles_closed'] == 1
    for key, prefix in [('reads', 'read:'), ('source_requests', 'source_request:')]:
        assert [event for event in events if event.startswith(prefix)] == [prefix + str(i) for i in range(len(operation[key]))]
    archive_paths = {f['path'] for f in spec['files']}
    store = context['store']['path']; archive = context['evidence']['path'] + '/retained-sources'
    allowed = archive_paths | {p for p, n in before.items() if n['kind'] == 'file' and (
        re.fullmatch(re.escape(store) + r'/references/[0-9a-f]{64}\.json', p)
        or re.fullmatch(re.escape(store) + r'/images/[0-9a-f]{64}/(?:rustup\.c|rustup|image\.json)', p))}
    assert set(operation['reads']) <= allowed
    for request in operation['source_requests']:
        assert request['path'] in allowed
        image_file = request['path'].endswith('/rustup')
        small_record = '/references/' in request['path'] or request['path'].endswith('/image.json')
        assert request['mode'] == (0o500 if image_file else 0o400)
        assert request['limit'] == (4096 if small_record else 65536)
    sources = [h for h in handles if h['kind'] == 'source']
    assert len(sources) <= len(operation['source_requests']) == len(operation['reads'])
    for h in handles:
        node = before[h['path']]; native = h['native_at_admission']
        assert len(native) == 13 and h['descriptor'] >= 0
        assert (h['device'], h['inode']) == (node['device'], node['inode']) == (native[0], native[1])
        assert stat.S_IMODE(native[2]) == node['mode'] and native[4] == node['uid']
        assert h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == 1 and h['actual_errno'] == 0
        assert h['reported_return'] == (0 if 'modeled_close_errno' in h else 1)
        assert h['reported_errno'] == (h['modeled_close_errno'] if 'modeled_close_errno' in h else 0)
        if h['kind'] == 'directory':
            assert stat.S_ISDIR(native[2]) and node['kind'] == 'directory'
            assert h['observer_closed'] == 1 and h['observer_descriptor'] >= 0 and h['observer_descriptor'] != h['descriptor']
            assert h['path'] in (store, store + '/images', store + '/references', archive) or re.fullmatch(re.escape(store) + '/images/[0-9a-f]{64}', h['path'])
        else:
            assert stat.S_ISREG(native[2]) and h['cloexec_before_close'] == 1
            assert native[3] == node['links'] == 1 and native[7] == node['size_bytes']
            if h['kind'] == 'source':
                assert h['path'] in allowed and h['cloexec_at_handoff'] == 1
                assert (h['sha256'], h['size_bytes']) == (node['sha256'], node['size_bytes'])
            else: assert h['kind'] == 'lock' and h['path'] == context['acquired']['lock']['path']
    locks = [h for h in handles if h['kind'] == 'lock']
    assert len(locks) == sum(o['returned'] for o in operation['lock_opens']) <= 1
    for attempt in operation['lock_opens']:
        assert attempt['path'] == context['acquired']['lock']['path']
        assert not attempt['flags'] & (os.O_CREAT | os.O_EXCL | os.O_TRUNC)
    if locks:
        opened = events.index('opened:' + locks[0]['label'])
        for i, path in enumerate(operation['reads']):
            if path not in archive_paths: assert opened < events.index('read:' + str(i))
        if planned['expected_unlinked']:
            assert (locks[0]['device'], locks[0]['inode']) == (context['acquired']['lock']['device'], context['acquired']['lock']['inode'])
            assert {h['path'] for h in sources if events.index('opened:' + h['label']) < opened} == archive_paths
    assert operation['forbidden_mutation_attempts'] == operation['forbidden_source_attempts'] == 0
    return dict(handles=len(handles), sources=len(sources), directories=sum(h['kind'] == 'directory' for h in handles),
                locks=len(locks), events=len(events), reads=len(operation['reads']))


def verify_row(plan, case, row):
    assert set(row) == set('matrix_case profile_id name selection context setup_before work_selection work_settlement retirement before_archive archive_receipt before_mutation mutation arguments operation prospective input_fingerprint_before input_fingerprint_after inputs_unchanged roots_absent'.split())
    assert row['matrix_case'] == case and row['profile_id'] == plan['profile_id']
    assert row['selection'] == plan['selection'] and row['name'] == plan['selection']['name']
    assert row['roots_absent'] is True and row['inputs_unchanged'] == 1
    assert re.fullmatch('[0-9a-f]{64}', row['input_fingerprint_before'])
    assert row['input_fingerprint_before'] == row['input_fingerprint_after']
    OLD.work_records(row); spec, _ = OLD.setup(row); assert OLD.mutation(row) == 0
    op = row['operation']; calls = FLOW.derive(row['context'], op['before'], spec)
    resolved = PREPARE.resolve(calls, row['context'], plan['sealed_symbols'], case['recipe'])
    assert row['prospective'] == dict(error='', resolved=resolved, flow_calls=len(calls), flow_sha256=SIGNATURE(calls))
    expected = TRACE.derive(calls, row['context'], plan['sealed_symbols'], resolved, ERROR_TEXT)
    assert expected == PREFLIGHT.reference(calls, row['context'], plan['sealed_symbols'], resolved)
    assert op['events'] == expected['events']
    assert len(op['boundary_calls']) == len(expected['calls'])
    for actual, required in zip(op['boundary_calls'], expected['calls'], strict=True):
        assert {k: v for k, v in actual.items() if k != 'depth'} == required
        assert type(actual['depth']) is int and 0 < actual['depth'] <= 128
        if actual['parent'] is not None: assert actual['depth'] > op['boundary_calls'][actual['parent']]['depth']
    for field in ('interrupted_boundary_ids', 'injected_hits', 'directory_primary_hits'):
        assert op[field] == expected[field]
    assert op['reported_error_hits'] == expected['reported_error_addresses']
    assert op['modeled_close_hits'] == expected['reported_error_hits'] == len(resolved['resolved_reports'])
    counts = native_trace(row, spec)
    assert len(op['handles']) == len(expected['handles'])
    for actual, required in zip(op['handles'], expected['handles'], strict=True):
        assert all(actual[k] == v for k, v in required.items() if k not in ('source_call', 'close_scope'))
    source_calls = [calls[h['source_call']] for h in expected['handles'] if h['kind'] == 'source']
    assert op['source_requests'] == [{k: c[k] for k in ('path', 'mode', 'limit')} for c in source_calls]
    assert op['reads'] == [c['path'] for c in source_calls]
    assert op['returned'] == 1 and op['error'] == ''
    handles = {h['label']: h for h in op['handles']}
    targets = {r['label']: r for r in resolved['resolved_reports']}
    assert len(op['close_reports']) == len(handles) == len(expected['reports'])
    for actual, required in zip(op['close_reports'], expected['reports'], strict=True):
        h = handles[required['label']]; applied = required['applied']; target = targets.get(h['label'])
        error = getattr(errno, target['errno']) if target else 0
        wanted = {k: h[k] for k in ('label', 'kind', 'path', 'descriptor', 'device', 'inode')}
        wanted.update(actual_return=1, actual_errno=0, closed_after_call=1, report_applied=int(applied),
            reported_return=int(not applied), reported_errno=error, selected_address=target['address'] if target else None)
        assert actual == wanted and ('modeled_close_errno' in h) == applied
        if applied: assert type(h['modeled_close_errno']) is int and h['modeled_close_errno'] == error
        for field in ('actual_return', 'actual_errno', 'closed_after_call', 'report_applied', 'reported_return', 'reported_errno'):
            assert type(actual[field]) is int
    primary = resolved['resolved_primary']; reads = op['directory_read_reports']
    if primary is not None and primary['kind'] == 'directory-read':
        actual, = reads; h = handles[primary['binding']['label']]
        before = OLD.flattened(row['context'], op['before']); name = actual['actual_name']
        assert isinstance(name, str) and '/' not in name and name != ''
        assert name in ('.', '..') or h['path'] + '/' + name in before
        wanted = {k: h[k] for k in ('label', 'path', 'descriptor', 'device', 'inode')}
        wanted.update(address=primary['address'], actual_name=name, actual_errno=0,
            report_applied=1, reported_name=None, reported_errno=errno.EIO)
        assert actual == wanted
        for field in ('descriptor', 'device', 'inode', 'actual_errno', 'report_applied', 'reported_errno'):
            assert type(actual[field]) is int
    else: assert reads == []
    unlinked = expected['effects']['unlink_completed']
    assert op['unlinks'] == ([dict(paths=[op['expected_hold']], actual_count=1, actual_errno=0)] if unlinked else [])
    physical = copy.deepcopy(op['before'])
    if unlinked: del physical['store'][op['expected_hold'][len(row['context']['store']['path']) + 1:]]
    assert op['after'] == physical
    if expected['success']: OLD.attempt(row, spec)
    else:
        assert op['result'] == dict(schema='fsmgen.inactive_observation_release_attempt.v1', runtime_authorized=0,
            executable=None, success=0, error=expected['error'], release=None, **expected['effects'])
    for field in ('runtime_authorized', 'success', 'unlink_attempted', 'unlink_completed', 'reference_absence_verified'):
        assert type(op['result'][field]) is int
    roots = [dict(kind=k, **row['context'][k]) for k in ('store', 'workspace', 'other_workspace', 'evidence')]
    return dict(counts, cases=1, calls=len(op['boundary_calls']), unlinks=unlinked,
        modeled_reports=len(targets), close_reports=len(op['close_reports']), healthy=expected['success'],
        failures=1 - expected['success'], post_unlink_failures=unlinked * (1 - expected['success']),
        call_primaries=expected['injected_hits'], directory_primaries=expected['directory_primary_hits']), roots


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    plan = load(BASE / 'plan.json'); domain(plan); pins, vectors = authenticate(plan)
    prerequisite = prerequisites(vectors)
    previous = [r['path'] for p in plan['previous_root_reports'] for r in load(ROOT / p)['allocated']]
    assert len(previous) == len(set(previous))
    for path in previous:
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, pins=len(pins), inputs=len(plan['inputs']),
            prerequisites=prerequisite, previous_roots_absent=len(previous), new_fixture_roots=0), sort_keys=True)); return
    saved = bool(sys.argv[1:]); storage = BASE / 'result' if saved else LOG
    report = load(storage / 'qualification.json'); header(plan, report, pins)
    totals = Counter(); roots = []; witnesses = {}
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        row = SUPPORT.read_case(storage, receipt); counts, allocated = verify_row(plan, case, row)
        totals.update(counts); roots.extend(allocated)
        witnesses.setdefault(case['recipe']['kind'], (case, row))
        if case['recipe']['kind'] == 'group':
            for kind in ('source', 'directory', 'lock'):
                if any(h['kind'] == kind and 'modeled_close_errno' in h for h in row['operation']['handles']):
                    witnesses.setdefault(kind, (case, row))
        if counts['post_unlink_failures']: witnesses['late'] = (case, row)
    assert report['allocated'] == roots
    assert [json.loads(r) for r in (storage / 'admission.jsonl').read_text().splitlines()] == roots
    paths = [r['path'] for r in roots]; assert len(paths) == len(set(paths)) and not set(paths) & set(previous)
    for path in paths:
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    assert {p.name for p in (storage / 'cases').iterdir()} == {'case-%04d.json' % c['index'] for c in plan['cases']}
    assertions = 25 + 13 * len(plan['cases']); SUPPORT.tap(storage / 'qualify.tap', assertions)
    assert (storage / 'qualify.exit').read_bytes() == b'0\n'
    def op(r): return r['operation']
    def modeled(r): return next(h for h in op(r)['handles'] if 'modeled_close_errno' in h)
    def read(r): return op(r)['directory_read_reports'][0]
    changes = [
        ('lost-actual-close', 'group', lambda r: modeled(r).update(actual_close_ok=0)),
        ('open-at-return', 'group', lambda r: modeled(r).update(closed_at_return=0)),
        ('open-lock', 'lock', lambda r: next(h for h in op(r)['handles'] if h['kind'] == 'lock').update(closed_after_call=0)),
        ('lost-directory-observer', 'directory', lambda r: next(h for h in op(r)['handles'] if h['kind'] == 'directory').update(observer_closed=0)),
        ('changed-inode', 'healthy', lambda r: op(r)['handles'][0].update(inode=7)),
        ('lost-modeled-hit', 'group', lambda r: op(r).update(modeled_close_hits=0)),
        ('lost-report-hit', 'group', lambda r: op(r)['reported_error_hits'].pop()),
        ('reversed-hit-order', 'group', lambda r: op(r)['reported_error_hits'].reverse()),
        ('missing-report', 'healthy', lambda r: op(r)['close_reports'].pop()),
        ('false-actual-return', 'group', lambda r: next(x for x in op(r)['close_reports'] if x['report_applied']).update(actual_return=0)),
        ('hidden-reported-error', 'group', lambda r: next(x for x in op(r)['close_reports'] if x['report_applied']).update(reported_return=1)),
        ('wrong-errno', 'group', lambda r: next(x for x in op(r)['close_reports'] if x['report_applied']).update(reported_errno=0)),
        ('invented-call-primary', 'group', lambda r: op(r).update(injected_hits=1)),
        ('lost-call-primary', 'source-primary', lambda r: op(r).update(injected_hits=0)),
        ('lost-close-event', 'healthy', lambda r: op(r)['events'].remove(next(e for e in op(r)['events'] if e.startswith('close:')))),
        ('wrong-caller', 'healthy', lambda r: op(r)['boundary_calls'][0].update(caller='Foreign')),
        ('lost-pending-scope', 'directory-primary', lambda r: op(r)['interrupted_boundary_ids'].clear()),
        ('wrong-current-owner', 'group', lambda r: r['prospective']['resolved']['resolved_reports'][0].update(close_scope='Foreign')),
        ('changed-input', 'healthy', lambda r: r.update(inputs_unchanged=0)),
        ('lost-other-owner', 'healthy', lambda r: op(r)['after']['store'].pop('coordination.lock')),
        ('lost-unlink', 'late', lambda r: op(r)['result'].update(unlink_completed=0)),
        ('lost-absence', 'late', lambda r: op(r)['result'].update(reference_absence_verified=0)),
        ('masked-primary', 'source-primary', lambda r: op(r)['result'].update(error='cleanup replaced primary\n')),
        ('false-success', 'group', lambda r: op(r)['result'].update(success=1)),
        ('native-authority', 'group', lambda r: op(r)['result'].update(runtime_authorized=1)),
        ('missing-directory-read', 'directory-primary', lambda r: op(r)['directory_read_reports'].clear()),
        ('missing-directory-hit', 'directory-primary', lambda r: op(r).update(directory_primary_hits=0)),
        ('foreign-directory-name', 'directory-primary', lambda r: read(r).update(actual_name='foreign/member')),
        ('wrong-directory-inode', 'directory-primary', lambda r: read(r).update(inode=7)),
        ('false-actual-read', 'directory-primary', lambda r: read(r).update(actual_name=None)),
        ('actual-read-error', 'directory-primary', lambda r: read(r).update(actual_errno=errno.EIO)),
        ('successful-reported-read', 'directory-primary', lambda r: read(r).update(reported_name='entry')),
        ('wrong-directory-errno', 'directory-primary', lambda r: read(r).update(reported_errno=errno.ENOSPC)),
        ('masked-directory-primary', 'directory-primary', lambda r: op(r)['result'].update(error='cleanup replaced directory primary\n')),
        ('private-read', 'healthy', lambda r: op(r)['reads'].append(r['context']['workspace']['path'] + '/rust-tool-resolution')),
        ('publication-attempt', 'healthy', lambda r: op(r).update(forbidden_mutation_attempts=1)),
    ]
    for name, kind, mutate in changes:
        case, row = witnesses[kind]; changed = copy.deepcopy(row); mutate(changed)
        assert rejects(lambda: verify_row(plan, case, changed)), name
    domain_controls = []
    for name, mutate in [('missing-case', lambda p: p['cases'].pop()),
                         ('duplicate-case', lambda p: p['cases'].append(copy.deepcopy(p['cases'][1]))),
                         ('wrong-recipe', lambda p: p['cases'][1]['recipe'].update(order='foreign'))]:
        changed = copy.deepcopy(plan); mutate(changed); assert rejects(lambda: domain(changed)); domain_controls.append(name)
    header_controls = []
    for name, mutate in [('missing-pin', lambda r: r['prospective_pins'].pop()),
                         ('missing-receipt', lambda r: r['case_files'].pop()),
                         ('invented-process', lambda r: r.update(forbidden_process_attempts=1)),
                         ('wrong-errno', lambda r: r['errno_constants'].update(ENOSPC=0))]:
        changed = copy.deepcopy(report); mutate(changed); assert rejects(lambda: header(plan, changed, pins)); header_controls.append(name)
    result = dict(schema='fsmgen.release_ordinary_composition_audit.v1', success=True, totals=dict(totals),
        assertions=assertions, source_revision=plan['source_revision'], prospective_pins=pins, input_files=len(plan['inputs']),
        prerequisites=prerequisite, roots_absent=len(paths), prior_roots_absent=len(previous),
        case_bytes=sum(r['size_bytes'] for r in report['case_files']), row_falsifiers=[n for n, _, _ in changes],
        domain_falsifiers=domain_controls, header_falsifiers=header_controls, scope=plan['scope'])
    if saved: assert load(storage / 'audit.json') == result
    else:
        with (storage / 'audit.json').open('x') as stream: stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
