"""Audit ordinary original omission verdicts, native aliases and separate recovery."""
from collections import Counter
import copy
import errno
import json
import os
from pathlib import Path
import re
import stat
import sys
from model import CORE, resolve

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
OLD = CORE.OLD
SUPPORT = CORE.SUPPORT
PREPARE = CORE.module('omission_matrix_prepare', BASE / 'prepare.py')
MAIN_NAMES = ['prepare.py', 'source-pins.json', 'plan.json', 'model.py', 'OmissionPlan.pm', 'Omissions.pm',
    'qualify.t', 'audit.py', 'binding-pins.json', 'binding.t', 'preflight.py', 'recover-preflight.py',
    'preflight-recovery-pins.json', 'result/preflight/binding.json', 'result/preflight/binding.tap',
    'result/preflight/binding.stderr', 'result/preflight/binding.exit', 'result/preflight/preflight.json',
    'result/preflight/preflight.stdout', 'result/preflight/preflight.stderr', 'result/preflight/preflight.exit',
    'result/preflight/recovery-plan.json', 'result/preflight/recovery-copies.json',
    'native-trace-source-review.json', 'recover.py', 'recovery-pins.json']


def load(path):
    return json.loads(path.read_bytes())


def original_digest(operation):
    return SUPPORT.signature({k: v for k, v in operation.items() if k not in ('before', 'after')})


def native_trace(row, spec, selected):
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
    assert not active and not stack and operation['all_observed_handles_closed'] == int(selected is None)
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
        omitted = selected is not None and h['label'] == selected['label']
        assert h['actual_close_ok'] == h['closed_after_call'] == h['closed_at_return'] == int(not omitted)
        assert h['actual_errno'] == 0
        if omitted:
            assert h['actual_close_performed'] == 0
            assert type(h['omitted_object_address']) is int and h['omitted_object_address'] > 0
        else:
            assert 'actual_close_performed' not in h and 'omitted_object_address' not in h
        assert h['reported_return'] == (0 if 'modeled_close_errno' in h else 1)
        assert h['reported_errno'] == (errno.EIO if 'modeled_close_errno' in h else 0)
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


def aliases(operation, evidence, selected):
    assert set(evidence) == set('observation_returned omission_hits open_witnesses observer_recovery observer_errors original_sha256_before_recovery original_sha256_after_recovery recovery_complete'.split())
    assert evidence['observation_returned'] == evidence['recovery_complete'] == 1
    assert evidence['observer_errors'] == []
    assert evidence['original_sha256_before_recovery'] == evidence['original_sha256_after_recovery'] == original_digest(operation)
    assert evidence['omission_hits'] == ([] if selected is None else [selected['address']])
    if selected is None:
        assert evidence['open_witnesses'] == evidence['observer_recovery'] == []
        return
    h, = [h for h in operation['handles'] if h['label'] == selected['label']]
    witness, = evidence['open_witnesses']; recovery, = evidence['observer_recovery']
    assert set(witness) == set('label kind path object_address descriptor native device inode open_after_original_return cloexec observer_descriptor observer_closed'.split())
    for key in ('label', 'kind', 'path', 'descriptor', 'device', 'inode'):
        assert witness[key] == h[key]
    assert witness['object_address'] == h['omitted_object_address']
    assert type(witness['object_address']) is int and witness['object_address'] > 0
    native = witness['native']; admitted = h['native_at_admission']
    assert len(native) == len(admitted) == 13
    assert (native[0], native[1], native[4]) == (h['device'], h['inode'], admitted[4])
    assert stat.S_IFMT(native[2]) == stat.S_IFMT(admitted[2])
    assert witness['open_after_original_return'] == 1
    if h['kind'] == 'directory':
        assert stat.S_ISDIR(native[2]) and witness['cloexec'] is None
        assert type(witness['observer_descriptor']) is int and witness['observer_descriptor'] >= 0
        assert witness['observer_descriptor'] != h['descriptor'] and witness['observer_closed'] == 1
    else:
        assert stat.S_ISREG(native[2]) and witness['cloexec'] == 1
        assert witness['observer_descriptor'] is None and witness['observer_closed'] is None
        assert native[7] == admitted[7]
    expected = dict(label=h['label'], object_address=h['omitted_object_address'], descriptor_before=h['descriptor'],
        primitive='CORE::closedir' if h['kind'] == 'directory' else 'CORE::close',
        performed=1, actual_return=1, actual_errno=0, closed_after=1)
    assert recovery == expected
    assert all(type(recovery[k]) is int for k in ('object_address', 'descriptor_before', 'performed', 'actual_return', 'actual_errno', 'closed_after'))


def verify_row(plan, case, row):
    assert set(row) == set('matrix_case profile_id name selection context setup_before work_selection work_settlement retirement before_archive archive_receipt before_mutation mutation arguments operation prospective input_fingerprint_before input_fingerprint_after inputs_unchanged roots_absent omission'.split())
    assert row['matrix_case'] == case and row['profile_id'] == plan['profile_id']
    assert row['selection'] == plan['selection'] and row['name'] == plan['selection']['name']
    assert row['roots_absent'] is True and row['inputs_unchanged'] == 1
    assert re.fullmatch('[0-9a-f]{64}', row['input_fingerprint_before'])
    assert row['input_fingerprint_before'] == row['input_fingerprint_after']
    OLD.work_records(row); spec, _ = OLD.setup(row); assert OLD.mutation(row) == 0
    op = row['operation']; calls = CORE.FLOW.derive(row['context'], op['before'], spec)
    resolved = resolve(calls, row['context'], plan['sealed_symbols'], case['recipe'])
    selected = resolved[0] if resolved else None
    assert row['prospective'] == dict(error='', resolved=resolved, flow_calls=len(calls), flow_sha256=SUPPORT.signature(calls))
    expected = SUPPORT.TRACE.derive(calls, row['context'], plan['sealed_symbols'], None)
    assert op['events'] == expected['events']
    assert len(op['boundary_calls']) == len(expected['calls'])
    for actual, required in zip(op['boundary_calls'], expected['calls'], strict=True):
        assert {k:v for k,v in actual.items() if k != 'depth'} == required
        assert type(actual['depth']) is int and 0 < actual['depth'] <= 128
        if actual['parent'] is not None:
            assert actual['depth'] > op['boundary_calls'][actual['parent']]['depth']
    assert op['interrupted_boundary_ids'] == [] and op['injected_hits'] == op['modeled_close_hits'] == 0
    assert len(op['handles']) == len(expected['handles'])
    for actual, required in zip(op['handles'], expected['handles'], strict=True):
        assert all(actual[k] == v for k,v in required.items() if k not in ('source_call', 'close_scope'))
        assert 'modeled_close_errno' not in actual
    source_calls = [calls[h['source_call']] for h in expected['handles'] if h['kind'] == 'source']
    assert op['source_requests'] == [{k:c[k] for k in ('path', 'mode', 'limit')} for c in source_calls]
    assert op['reads'] == [c['path'] for c in source_calls]
    counts = native_trace(row, spec, selected)
    aliases(op, row['omission'], selected)
    # Apply the unchanged original closure oracle to the untouched original
    # snapshot. Recovery has not rewritten it into a passing implementation.
    if selected is None:
        assert OLD.trace(row, spec) == counts
    else:
        assert CORE.rejects(lambda: OLD.trace(row, spec))
    OLD.attempt(row, spec)
    roots = [dict(kind=k, **row['context'][k]) for k in ('store', 'workspace', 'other_workspace', 'evidence')]
    return dict(counts, cases=1, healthy=int(selected is None), original_open_verdicts=int(selected is not None),
        original_auditor_rejections=int(selected is not None), separately_recovered=int(selected is not None),
        calls=len(op['boundary_calls']), unlinks=sum(r['actual_count'] for r in op['unlinks'])), roots


def domain(plan):
    selection = load(PREPARE.SELECTION / 'plan.json'); profile = selection['profiles'][0]
    assert plan['schema'] == 'fsmgen.release_ordinary_omission_plan.v1'
    assert plan['owner'] == PREPARE.OWNER == profile['owner']
    assert plan['component'] == BASE.name and plan['source_revision'] == PREPARE.REVISION
    assert plan['profile_id'] == profile['id'] and plan['selection'] == profile['selection']
    assert plan['cases'] == profile['cases'] and plan['binding_profiles'] == selection['profiles']
    for field in ('source_boundaries', 'sealed_symbols', 'omission_contract', 'observation_contract', 'recovery_contract', 'previous_root_reports'):
        assert plan[field] == selection[field]


def prerequisites(plan):
    preflight = CORE.module('ordinary_omission_retained_preflight', BASE / 'preflight.py')
    recovery = CORE.module('ordinary_omission_preflight_recovery', BASE / 'recover-preflight.py')
    directory = BASE / 'result/preflight'; records = load(directory / 'recovery-copies.json')
    assert records == load(directory / 'recovery-plan.json'); recovery.verify(records)
    pins = load(BASE / 'binding-pins.json'); assert pins == [PREPARE.pin(BASE / n) for n in preflight.NAMES]
    assert (directory / 'binding.exit').read_bytes() == (directory / 'preflight.exit').read_bytes() == b'0\n'
    counts = preflight.verify(plan, pins, load(directory / 'binding.json'), directory / 'binding.tap')
    result = load(directory / 'preflight.json')
    assert result['success'] is True and result['counts'] == counts and result['prospective_pins'] == pins
    assert len(result['falsifiers']) == len(set(result['falsifiers'])) == 8
    return dict(counts, copies=len(records))


def header(plan, report, pins):
    assert set(report) == {'schema', 'success', 'prospective_pins', 'cases', 'case_files', 'allocated',
        'caller_controls', 'current_case', 'forbidden_process_attempts', 'errno_constants', 'errno_text'}
    assert report['schema'] == 'fsmgen.release_ordinary_omission_qualification.v1' and report['success'] is True
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


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    plan = load(BASE / 'plan.json'); domain(plan); assert plan == PREPARE.build()
    pins = load(BASE / 'preflight-pins.json'); assert pins == [PREPARE.pin(BASE / n) for n in MAIN_NAMES]
    prerequisite = prerequisites(plan)
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, pins=len(pins), inputs=len(plan['inputs']), prerequisites=prerequisite, new_fixture_roots=0), sort_keys=True)); return
    storage = BASE / 'result' if sys.argv[1:] else LOG
    report = load(storage / 'qualification.json'); header(plan, report, pins)
    totals = Counter(); roots = []; witnesses = {}
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        row = SUPPORT.read_case(storage, receipt); counts, allocated = verify_row(plan, case, row)
        totals.update(counts); roots.extend(allocated)
        kind = case['recipe']['handle_kind'] if case['recipe']['kind'] == 'omit' else 'healthy'
        witnesses.setdefault(kind, (case, row))
    assert report['allocated'] == roots
    assert [json.loads(r) for r in (storage / 'admission.jsonl').read_text().splitlines()] == roots
    paths = [r['path'] for r in roots]; assert len(paths) == len(set(paths))
    previous = [r['path'] for path in plan['previous_root_reports'] for r in load(ROOT / path)['allocated']]
    assert len(previous) == len(set(previous)) and not set(paths) & set(previous)
    for path in paths + previous:
        relative = Path(path); assert not relative.is_absolute() and '..' not in relative.parts and path.startswith('.artifacts/')
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    assert {p.name for p in (storage / 'cases').iterdir()} == {'case-%04d.json' % c['index'] for c in plan['cases']}
    assertions = 25 + 14 * len(plan['cases']); SUPPORT.tap(storage / 'qualify.tap', assertions)
    assert (storage / 'qualify.exit').read_bytes() == b'0\n'
    controls = []
    def omitted(row):
        return next(h for h in row['operation']['handles'] if 'actual_close_performed' in h)
    changes = [
        ('source-closure-rewritten', 'source', lambda r: omitted(r).update(closed_at_return=1)),
        ('lock-closure-rewritten', 'lock', lambda r: omitted(r).update(actual_close_ok=1)),
        ('directory-closure-rewritten', 'directory', lambda r: omitted(r).update(actual_close_performed=1)),
        ('missing-native-witness', 'source', lambda r: r['omission']['open_witnesses'].clear()),
        ('wrong-native-inode', 'source', lambda r: r['omission']['open_witnesses'][0].update(inode=7)),
        ('wrong-retained-object', 'lock', lambda r: r['omission']['open_witnesses'][0].update(object_address=7)),
        ('unclosed-observer-duplicate', 'directory', lambda r: r['omission']['open_witnesses'][0].update(observer_closed=0)),
        ('duplicate-recovery', 'source', lambda r: r['omission']['observer_recovery'].append(copy.deepcopy(r['omission']['observer_recovery'][0]))),
        ('wrong-recovery-object', 'source', lambda r: r['omission']['observer_recovery'][0].update(object_address=7)),
        ('wrong-recovery-primitive', 'directory', lambda r: r['omission']['observer_recovery'][0].update(primitive='CORE::close')),
        ('failed-recovery-return', 'lock', lambda r: r['omission']['observer_recovery'][0].update(actual_return=0)),
        ('recovery-still-open', 'source', lambda r: r['omission']['observer_recovery'][0].update(closed_after=0)),
        ('lost-original-snapshot', 'source', lambda r: r['omission'].update(original_sha256_after_recovery='0'*64)),
        ('hidden-observer-error', 'source', lambda r: r['omission']['observer_errors'].append('failed witness')),
        ('wrong-current-binding', 'source', lambda r: r['prospective']['resolved'][0].update(label='source:99999')),
        ('missing-call', 'healthy', lambda r: r['operation']['boundary_calls'].pop()),
        ('lost-original-unlink', 'source', lambda r: r['operation']['result'].update(unlink_completed=0)),
        ('changed-other-owner', 'healthy', lambda r: r['operation']['after']['store'].pop('coordination.lock')),
        ('native-authority', 'source', lambda r: r['operation']['result'].update(runtime_authorized=1)),
    ]
    for name, kind, change in changes:
        case, original = witnesses[kind]; changed = copy.deepcopy(original); change(changed)
        # Structural native-closure controls remain bad even with coherent
        # snapshot digests; their rejection cannot rely on a stale checksum.
        if name.endswith('closure-rewritten'):
            digest = original_digest(changed['operation'])
            changed['omission'].update(original_sha256_before_recovery=digest, original_sha256_after_recovery=digest)
        assert CORE.rejects(lambda: verify_row(plan, case, changed)), name
        controls.append(name)
    domain_controls = []
    for name, mutate in [('missing-case', lambda p: p['cases'].pop()),
                         ('repeated-case', lambda p: p['cases'].append(copy.deepcopy(p['cases'][1]))),
                         ('foreign-scope', lambda p: p['cases'][1]['recipe'].update(scope='foreign'))]:
        changed = copy.deepcopy(plan); mutate(changed); assert CORE.rejects(lambda: domain(changed)); domain_controls.append(name)
    header_controls = []
    for name, mutate in [('missing-pin', lambda r: r['prospective_pins'].pop()),
                         ('missing-case-receipt', lambda r: r['case_files'].pop()),
                         ('invented-process', lambda r: r.update(forbidden_process_attempts=1))]:
        changed = copy.deepcopy(report); mutate(changed); assert CORE.rejects(lambda: header(plan, changed, pins)); header_controls.append(name)
    result = dict(schema='fsmgen.release_ordinary_omission_audit.v1', success=True, totals=dict(totals), assertions=assertions,
        source_revision=plan['source_revision'], prospective_pins=pins, prerequisites=prerequisite,
        row_falsifiers=controls, domain_falsifiers=domain_controls, header_falsifiers=header_controls,
        new_roots_absent=len(paths), prior_roots_absent=len(previous), scope=plan['scope'])
    if sys.argv[1:]:
        assert result == load(storage / 'audit.json')
    else:
        with (LOG / 'audit.json').open('x') as stream:
            stream.write(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(json.dumps({k:v for k,v in result.items() if k != 'prospective_pins'}, sort_keys=True))


if __name__ == '__main__':
    main()
