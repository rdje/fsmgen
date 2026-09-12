"""Corrected audit: successful open errno is captured, never a failure signal.

No qualifier or earlier main is invoked. --verify-saved consumes the tracked
recovery bodies. The strong-reference counterexample is never a primary case.
"""
from collections import Counter
import copy
import errno
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
REVISION = 'efadb9148c14391fde011851e766a72b84bcfda8'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.3.10.2.2'
BINDING = BASE.with_name('native-proxy-release-readback-ordinary-20260911')
BEFORE = BASE.with_name('native-proxy-observation-archive-release-ordinary-before-20260911')
ORIGINAL = BASE.with_name('native-proxy-release-readback-selection-20260911')
CORRECTION = BASE.with_name('native-proxy-release-readback-applicability-20260911')
SOURCE = 'NativeProxyImageCustody::_source'
MODES = ('first-eio', 'partial-eio', 'early-eof', 'body-xor')
NATIVE_FIELDS = (0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12)
PIN_PATHS = [BASE / n for n in ('plan.json', 'prepare.py', 'prepare-pins.json', 'ReadbackCore.pm',
    'ReadbackTrace.pm', 'ReadbackPlan.pm', 'qualify.t', 'audit.py', 'expected_trace.py',
    'oracle-preflight.py', 'oracle-preflight-plan.json', 'oracle-preflight-pins.json',
    'result/oracle-preflight/oracle-preflight.json', 'result/oracle-preflight/oracle-preflight.stdout',
    'result/oracle-preflight/oracle-preflight.stderr', 'result/oracle-preflight/oracle-preflight.exit')]
PIN_PATHS += [BINDING / n for n in ('binding-probe.t', 'binding-probe-plan.json', 'binding-probe-pins.json',
    'binding-review.json', 'result/binding-probe.tap', 'result/binding-probe.stderr', 'result/binding-probe.exit')]
PIN_PATHS += [BASE / 'first-syntax-failure' / n for n in ('qualify.t', 'preflight-pins.json', 'ReadbackCore.pm',
    'ReadbackTrace.pm', 'ReadbackPlan.pm', 'audit.py', 'raw.json', 'review.json')]


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


def domain(plan):
    original = load(ORIGINAL / 'plan.json')['profiles'][0]
    corrected = load(CORRECTION / 'applicability.json')['profiles'][0]
    old = load(BEFORE / 'plan.json')
    assert plan['schema'] == 'fsmgen.release_readback_ordinary_plan.v1'
    assert plan['source_revision'] == REVISION and plan['owner'] == corrected['execution_owner'] == OWNER
    assert plan['component'] == BASE.name and plan['profile_id'] == original['id'] == corrected['id']
    assert plan['selection'] == original['selection'] == old['selection']
    assert plan['source_boundaries'] == old['source_boundaries'] and plan['sealed_symbols'] == old['sealed_symbols']
    assert plan['publication'] == old['publication']
    assert (plan['primary_cases'], plan['primary_successes'], plan['primary_rejections'], plan['seam_counterexamples']) == (482, 10, 472, 1)
    assert len(plan['cases']) == 483 and len(original['sources']) == len(corrected['body_xor']) == 120
    final = dict(unlink_attempted=1, unlink_completed=1, reference_absence_verified=1,
                 last_reference_check=dict(phase='finish', state='absent'))
    for index, case in enumerate(plan['cases']):
        assert set(case) == {'index', 'name', 'role', 'selector', 'expected_success', 'expected_effects'}
        assert type(case['index']) is int and case['index'] == index and type(case['expected_success']) is int
        assert case['role'] == ('primary' if index < 482 else 'seam_counterexample')
        if index == 0:
            name, selector, success, effects = 'healthy:ordinary', None, 1, final
        elif index == 1:
            name = 'first-source-one-byte-then-normal'
            selector, success, effects = dict(control='one-byte', occurrence=0, strong_alias=0), 1, final
        else:
            ordinal, mode = divmod(index - 2, 4) if index < 482 else (0, 0)
            control = MODES[mode]
            selector = dict(control=control, occurrence=ordinal, strong_alias=int(index == 482))
            name = 'source#' + str(ordinal) + ':' + control if index < 482 else 'strong-alias:first-source-eio'
            assert original['sources'][ordinal]['occurrence'] == corrected['body_xor'][ordinal]['occurrence'] == ordinal
            success = int(control == 'body-xor' and corrected['body_xor'][ordinal]['expected_success'])
            effects = final if success else original['sources'][ordinal]['effects_before_source']
        assert (case['name'], case['selector'], case['expected_success'], case['expected_effects']) == (name, selector, success, effects)
        if selector is not None:
            assert type(case['selector']['occurrence']) is type(case['selector']['strong_alias']) is int
    old_reports = ['docs/audits/native-proxy-observation-archive-release-boundaries-20260911/result/qualification.json']
    old_reports += ['docs/audits/native-proxy-observation-archive-release-' + p + '-20260911/result/qualification.json'
                    for p in ('ordinary-before', 'ordinary-after', 'equal-before', 'equal-after',
                              'active-before', 'active-after', 'last-before', 'last-after')]
    assert plan['previous_root_reports'] == old_reports
    inputs = {p['path'] for p in load(BASE / 'oracle-preflight-plan.json')['inputs']} | set(old_reports)
    inputs.update(str((BEFORE / n).relative_to(ROOT)) for n in ('plan.json', 'qualify.t', 'CallPlan.pm', 'CallFaultTrace.pm'))
    assert [p['path'] for p in plan['inputs']] == sorted(inputs)


def authenticate(plan):
    pins = load(BASE / 'preflight-pins.json')
    assert [p['path'] for p in pins] == [str(p.relative_to(ROOT)) for p in PIN_PATHS]
    for pin in pins + plan['inputs']:
        path = ROOT / pin['path']
        for ancestor in [path, *path.parents]:
            if ancestor == ROOT:
                break
            assert not ancestor.is_symlink() and ancestor.stat().st_dev == ROOT.stat().st_dev
        raw = path.read_bytes()
        assert pin == dict(path=pin['path'], size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        if pin in plan['inputs']:
            assert raw == subprocess.check_output(['git', 'show', REVISION + ':' + pin['path']], cwd=ROOT)
    return pins


def prerequisites(support):
    prior = load(BASE / 'result/oracle-preflight/oracle-preflight.json')
    assert prior['success'] is True and prior['allocated'] == [] and prior['inputs'] == 220
    assert prior['prospective_pins'] == load(BASE / 'oracle-preflight-pins.json')
    assert len(prior['projections']) == 1868 and len(prior['order_only_skeletons']) == 38
    assert sum(p['expected_success'] for p in prior['projections']) == 40
    assert (BASE / 'result/oracle-preflight/oracle-preflight.exit').read_bytes() == b'0\n'
    support.tap(BINDING / 'result/binding-probe.tap', 12)
    assert (BINDING / 'result/binding-probe.exit').read_bytes() == b'0\n'
    review = load(BINDING / 'binding-review.json')
    assert review['owner'] == OWNER and review['assertions'] == 12 and review['first_run'] is True
    for receipt in review['raw_recovery']:
        raw = (ROOT / receipt['destination']).read_bytes()
        assert len(raw) == receipt['size_bytes'] and hashlib.sha256(raw).hexdigest() == receipt['sha256']
    return dict(binding_assertions=12, saved_event_projections=1868, order_only_skeletons=38)


def header(plan, report, support):
    assert report['schema'] == 'fsmgen.release_readback_ordinary_qualification.v1' and report['success'] is True
    assert report['prospective_pins'] == load(BASE / 'preflight-pins.json')
    assert report['cases'] == [] and report['current_case'] is None and report['forbidden_process_attempts'] == 0
    support.caller_controls(plan, report['caller_controls'])
    assert len(report['case_files']) == len(plan['cases'])
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        assert set(receipt) == {'index', 'name', 'path', 'size_bytes', 'sha256'}
        assert type(receipt['index']) is int and receipt['index'] == case['index'] and receipt['name'] == case['name']
        assert receipt['path'] == '.artifacts/logs/' + BASE.name + '/cases/case-%04d.json' % case['index']
        assert type(receipt['size_bytes']) is int and receipt['size_bytes'] > 0 and re.fullmatch('[0-9a-f]{64}', receipt['sha256'])


def probe(value, descriptor, opened, metadata):
    assert set(value) == {'descriptor', 'duplicate', 'errno', 'metadata', 'duplicate_close', 'duplicate_closed_probe'}
    assert type(value['descriptor']) is int and value['descriptor'] == descriptor
    assert type(value['errno']) is int
    if not opened:
        assert value == dict(descriptor=descriptor, duplicate=None, errno=errno.EBADF,
                             metadata=None, duplicate_close=None, duplicate_closed_probe=None)
        return 0
    assert type(value['duplicate']) is int and value['duplicate'] >= 0 and value['duplicate'] != descriptor
    assert value['errno'] == 0 and len(value['metadata']) == 13
    assert all(type(v) is int for v in value['metadata'])
    assert all(value['metadata'][i] == metadata[i] for i in NATIVE_FIELDS)
    assert value['duplicate_close'] == dict(returned=1, errno=0, attached_closed=1)
    assert value['duplicate_closed_probe'] == dict(duplicate=None, errno=errno.EBADF)
    return 1


def ordinary_weak_contract(reader, failed):
    assert reader['weak_alive_at_return'] == reader['weak_open_at_return'] == int(not failed)
    assert reader['weak_open_at_release_return'] == 0 and reader['recovery'] == [] and reader['after_recovery'] is None


def reader_trace(row, resolved, physical):
    value = row['operation']['readback']
    if resolved is None:
        assert value is None
        return Counter(), None
    assert set(value) == set('events reads recovery reader_returned reader_error observation_error result open opened alias_is_weak weak_alive_at_return weak_open_at_return cloexec_at_reader_return at_reader_return observation_completed weak_open_at_release_return at_release_return after_recovery post_observation_error'.split())
    mode, strong = resolved['control'], resolved['strong_alias']
    failed = mode in MODES[:3]
    assert value['alias_is_weak'] == value['observation_completed'] == 1
    assert value['observation_error'] == value['post_observation_error'] == ''
    assert value['reader_returned'] == int(not failed)
    error = 'fixture changed during its bounded read\n' if mode == 'early-eof' else 'cannot read fixture bytes: ' + os.strerror(errno.EIO) + '\n'
    assert value['reader_error'] == (error if failed else '')
    opened_errno = value['open']['errno']
    assert type(opened_errno) is int and opened_errno >= 0
    # Successful Perl I/O may set errno; its value is not a failure signal.
    assert value['open'] == dict(arity=3, flags=os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, returned=1, errno=opened_errno)
    opened = value['opened']
    assert set(opened) == {'descriptor', 'metadata', 'cloexec'}
    fd, native = opened['descriptor'], opened['metadata']
    assert type(fd) is int and fd >= 0 and len(native) == 13 and all(type(v) is int for v in native)
    node = physical[resolved['path']]
    assert (native[0], native[1], native[2], native[3], native[4], native[7]) == (
        node['device'], node['inode'], 0o100000 | node['mode'], node['links'], node['uid'], node['size_bytes'])
    assert type(opened['cloexec']) is int and opened['cloexec'] in (0, 1)
    raw = bytes.fromhex(node['bytes_hex'])
    assert 0 < len(raw) <= 65536
    counts = Counter(selected_reader_calls=1, failed_reader_calls=int(failed), returned_reader_calls=int(not failed))
    actual_offset = 0
    reported_body = b''
    events = ['open:before', 'open:after']
    reads = value['reads']
    assert reads
    for index, read in enumerate(reads):
        assert set(read) == {'index', 'action', 'requested', 'delegated_requested', 'actual', 'reported'}
        assert type(read['index']) is int and read['index'] == index
        assert type(read['requested']) is int and read['requested'] == 65537 - len(reported_body)
        action = ('report-eio' if (mode == 'first-eio' and index == 0) or (mode == 'partial-eio' and index == 1)
                  else 'report-eof' if mode == 'early-eof' and index == 0
                  else 'delegate-one-byte' if mode in ('partial-eio', 'one-byte') and index == 0
                  else 'delegate-then-xor' if mode == 'body-xor' and index == 0 else 'delegate')
        assert read['action'] == action
        events += ['read:' + str(index) + ':before', 'read:' + str(index) + ':after']
        counts['observed_read_calls'] += 1
        if action in ('report-eio', 'report-eof'):
            assert read['actual'] is None and read['delegated_requested'] is None
            eof = action == 'report-eof'
            required = dict(count=0 if eof else None, errno=0 if eof else errno.EIO,
                buffer=dict(defined=int(eof), bytes_hex='' if eof else None, utf8=0))
            counts['controlled_read_reports'] += 1
        else:
            requested = 1 if action == 'delegate-one-byte' else read['requested']
            assert type(read['delegated_requested']) is int and read['delegated_requested'] == requested
            actual = read['actual']
            assert set(actual) == {'count', 'errno', 'buffer'}
            count = actual['count']
            assert type(count) is int and 0 <= count <= min(requested, len(raw) - actual_offset)
            assert count > 0 if actual_offset < len(raw) else count == 0
            assert count == 1 if action == 'delegate-one-byte' else True
            chunk = raw[actual_offset:actual_offset + count]
            assert actual == dict(count=count, errno=0, buffer=dict(defined=1, bytes_hex=chunk.hex(), utf8=0))
            actual_offset += count
            required = copy.deepcopy(actual)
            if action == 'delegate-then-xor':
                assert count > 0
                required['buffer']['bytes_hex'] = (bytes([chunk[0] ^ 0x80]) + chunk[1:]).hex()
            counts['actual_read_syscalls'] += 1
            counts['actual_read_bytes'] += count
        assert read['reported'] == required
        assert type(read['reported']['errno']) is int
        count = required['count']
        if count is None or count == 0:
            assert index == len(reads) - 1
        else:
            assert index < len(reads) - 1
            reported_body += bytes.fromhex(required['buffer']['bytes_hex'])
    assert len(reads) == 1 if mode in ('first-eio', 'early-eof') else len(reads) == 2 if mode == 'partial-eio' else len(reads) >= 2
    assert value['events'] == events + ['reader:return']
    if failed:
        assert value['result'] is None and actual_offset == (1 if mode == 'partial-eio' else 0)
    else:
        expected_body = bytes([raw[0] ^ 0x80]) + raw[1:] if mode == 'body-xor' else raw
        assert actual_offset == len(raw) and reported_body == expected_body
        assert value['result'] == dict(bytes_hex=expected_body.hex(), bytes_utf8=0, metadata=native, descriptor=fd)
    assert value['weak_alive_at_return'] == value['weak_open_at_return'] == int(not failed or strong)
    assert value['cloexec_at_reader_return'] == (opened['cloexec'] if not failed or strong else None)
    counts['observer_duplicates_closed'] += probe(value['at_reader_return'], fd, not failed or strong, native)
    assert value['weak_open_at_release_return'] == strong
    counts['observer_duplicates_closed'] += probe(value['at_release_return'], fd, strong, native)
    if strong:
        assert failed and mode == 'first-eio' and resolved['occurrence'] == 0
        assert value['recovery'] == [dict(role='observer_strong_counterexample', returned=1, errno=0, closed_after_call=1)]
        assert probe(value['after_recovery'], fd, False, native) == 0
        assert rejects(lambda: ordinary_weak_contract(value, failed))
        counts['strong_counterexample_recoveries'] += 1
        counts['strong_bias_detected'] += 1
    else:
        ordinary_weak_contract(value, failed)
        counts['unreturned_reader_lexical_closes'] += int(failed)
    return counts, reported_body if not failed else None


def verify_row(plan, case, row, support, oracle):
    assert set(row) == set('matrix_case profile_id name selection context setup_before work_selection work_settlement retirement before_archive archive_receipt before_mutation mutation arguments operation prospective input_fingerprint_before input_fingerprint_after inputs_unchanged roots_absent'.split())
    assert row['matrix_case'] == case and row['profile_id'] == plan['profile_id']
    assert row['name'] == plan['selection']['name'] and row['selection'] == plan['selection']
    assert row['roots_absent'] is True and row['inputs_unchanged'] == 1
    assert re.fullmatch('[0-9a-f]{64}', row['input_fingerprint_before'])
    assert row['input_fingerprint_before'] == row['input_fingerprint_after']
    old = support.OLD
    old.work_records(row)
    spec, _ = old.setup(row)
    assert old.mutation(row) == 0
    op = row['operation']
    calls = support.PRIOR.FLOW.derive(row['context'], op['before'], spec)
    sources = [c for c in calls if c['name'] == SOURCE]
    selector = case['selector']
    resolved = None
    if selector is not None:
        source = sources[selector['occurrence']]
        resolved = dict(selector, call_id=source['id'], path=source['path'])
    expected = oracle.derive(calls, row['context'], plan['sealed_symbols'], resolved)
    assert row['prospective'] == dict(error='', resolved=resolved, expected_error=expected['expected_error'],
        flow_calls=len(calls), flow_sha256=signature(calls))
    assert op['events'] == expected['events']
    assert len(op['boundary_calls']) == len(expected['calls'])
    for actual, required in zip(op['boundary_calls'], expected['calls'], strict=True):
        assert {k: v for k, v in actual.items() if k != 'depth'} == required
        assert type(actual['depth']) is int and 0 < actual['depth'] <= 128
        if actual['parent'] is not None:
            assert actual['depth'] > op['boundary_calls'][actual['parent']]['depth']
    assert op['interrupted_boundary_ids'] == expected['interrupted_boundary_ids']
    assert op['injected_hits'] == 0 and op['readback_hits'] == expected['readback_hits']
    assert op['returned'] == 1 and op['error'] == '' and op['modeled_close_hits'] == 0
    assert all('modeled_close_errno' not in h for h in op['handles'])
    physical = old.flattened(row['context'], op['before'])
    read_counts, returned_body = reader_trace(row, resolved, physical)
    assert len(op['handles']) == len(expected['handles'])
    for actual, required in zip(op['handles'], expected['handles'], strict=True):
        assert {k: actual[k] for k in required if k != 'source_call'} == {k: v for k, v in required.items() if k != 'source_call'}
    # The common metadata/closure oracle expects physical-file digests. First
    # prove the deliberately changed returned digest against captured read bytes,
    # then normalize only that one field in an ephemeral verification view.
    # The original row, file footprint and every other observed digest stay exact.
    trace_view = row
    if resolved is not None and resolved['control'] == 'body-xor':
        h_index, = [i for i, h in enumerate(expected['handles']) if h['source_call'] == resolved['call_id']]
        assert op['handles'][h_index]['sha256'] == hashlib.sha256(returned_body).hexdigest()
        trace_view = copy.deepcopy(row)
        trace_view['operation']['handles'][h_index]['sha256'] = physical[resolved['path']]['sha256']
    counts = Counter(old.trace(trace_view, spec))
    counts.update(read_counts)
    entered_sources = [c for c in expected['calls'] if c['name'] == SOURCE]
    assert op['source_requests'] == [{k: c[k] for k in ('path', 'mode', 'limit')} for c in entered_sources]
    assert op['reads'] == [c['path'] for c in entered_sources]
    assert len(entered_sources) - counts['sources'] == int(resolved is not None and resolved['control'] in MODES[:3])
    assert op['expected_hold'] == row['context']['acquired']['observation_reference']['source']['identity']['path']
    assert op['unlinks'] == ([dict(paths=[op['expected_hold']], actual_count=1, actual_errno=0)] if expected['unlinked'] else [])
    after = copy.deepcopy(op['before'])
    if expected['unlinked']:
        del after['store'][op['expected_hold'][len(row['context']['store']['path']) + 1:]]
    assert op['after'] == after
    assert case['expected_success'] == int(expected['expected_success'])
    if expected['expected_success']:
        effects = dict(unlink_attempted=1, unlink_completed=1, reference_absence_verified=1,
                       last_reference_check=dict(phase='finish', state='absent'))
        old.attempt(row, spec)
    else:
        address = SOURCE + '#' + str(resolved['occurrence']) + ':before'
        effects, = [v['effects'] for v in support.SELECT.expected(calls, plan['sealed_symbols']) if v['address'] == address]
        assert op['result'] == dict(schema='fsmgen.inactive_observation_release_attempt.v1', runtime_authorized=0,
            executable=None, success=0, error=expected['expected_error'], release=None, **effects)
    assert effects == case['expected_effects'] and effects['unlink_completed'] == int(expected['unlinked'])
    for field in ('runtime_authorized', 'success', 'unlink_attempted', 'unlink_completed', 'reference_absence_verified'):
        assert type(op['result'][field]) is int
    primary = case['role'] == 'primary'
    counts.update(calls=len(op['boundary_calls']), unlinks=int(expected['unlinked']),
        primary_cases=int(primary), primary_successes=int(primary and expected['expected_success']),
        primary_rejections=int(primary and not expected['expected_success']), seam_counterexamples=int(not primary))
    roots = [dict(kind=k, **row['context'][k]) for k in ('store', 'workspace', 'other_workspace', 'evidence')]
    return counts, roots



def authenticate_correction():
    paths = [BASE / 'audit-corrected.py'] + [BASE / 'first-audit-failure' / n
        for n in ('audit.py', 'preflight-pins.json', 'raw.json', 'review.json', 'open-census.json')]
    pins = load(BASE / 'audit-correction-pins.json')
    assert [p['path'] for p in pins] == [str(p.relative_to(ROOT)) for p in paths]
    for pin in pins:
        path = ROOT / pin['path']
        for ancestor in [path, *path.parents]:
            if ancestor == ROOT:
                break
            assert not ancestor.is_symlink() and ancestor.stat().st_dev == ROOT.stat().st_dev
        raw = path.read_bytes()
        assert pin == dict(path=pin['path'], size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    assert (BASE / 'first-audit-failure/audit.py').read_bytes() == (BASE / 'audit.py').read_bytes()
    assert (BASE / 'first-audit-failure/preflight-pins.json').read_bytes() == (BASE / 'preflight-pins.json').read_bytes()
    return pins


def main():
    assert sys.argv[1:] in ([], ['--verify-saved'], ['--admit-only'])
    saved = sys.argv[1:] == ['--verify-saved']
    storage = BASE / 'result' if saved else LOG
    plan = load(BASE / 'plan.json')
    domain(plan)
    pins = authenticate(plan)
    correction_pins = authenticate_correction()
    support = module('readback_retained_audit_support', BEFORE / 'audit.py')
    oracle = module('readback_independent_source_scope', BASE / 'expected_trace.py')
    preflight = prerequisites(support)
    if sys.argv[1:] == ['--admit-only']:
        print(json.dumps(dict(admitted=True, allocated_fixtures=0, prospective_pins=len(pins),
            unchanged_inputs=len(plan['inputs']), preflight=preflight), sort_keys=True))
        return
    report = load(storage / 'qualification.json')
    header(plan, report, support)
    totals, roots, examples = Counter(), [], {}
    for case, receipt in zip(plan['cases'], report['case_files'], strict=True):
        row = support.read_case(storage, receipt)
        counts, allocated = verify_row(plan, case, row, support, oracle)
        totals.update(counts)
        roots.extend(allocated)
        index = case['index']
        if index in (0, 1, 2, 3, 4, 5, 37, 478, 482):
            examples[index] = (case, row)
    assert (totals['primary_cases'], totals['primary_successes'], totals['primary_rejections'], totals['seam_counterexamples']) == (482, 10, 472, 1)
    original_oracle = module('preserved_first_readback_audit', BASE / 'audit.py')
    short_case, short_row = examples[1]
    assert rejects(lambda: original_oracle.verify_row(plan, short_case, short_row, support, oracle))
    verify_row(plan, short_case, short_row, support, oracle)
    assert totals['strong_bias_detected'] == totals['strong_counterexample_recoveries'] == 1
    assert totals['unreturned_reader_lexical_closes'] == 360
    assert report['allocated'] == roots and len({r['path'] for r in roots}) == len(roots) == 1932
    assert [json.loads(line) for line in (storage / 'admission.jsonl').read_text().splitlines()] == roots
    prior_roots = [r for p in plan['previous_root_reports'] for r in load(ROOT / p)['allocated']]
    prior_paths = {r['path'] for r in prior_roots}
    assert len(prior_paths) == len(prior_roots) == 17108
    assert not prior_paths & {r['path'] for r in roots}
    for relative in prior_paths | {r['path'] for r in roots}:
        path = Path(relative)
        assert not path.is_absolute() and '..' not in path.parts and relative.startswith('.artifacts/')
        assert not (ROOT / path).exists() and not (ROOT / path).is_symlink()
    assert {p.name for p in (storage / 'cases').iterdir()} == {'case-%04d.json' % c['index'] for c in plan['cases']}
    assertions = 24 + len(plan['cases']) * 11 + 1
    support.tap(storage / 'qualify.tap', assertions)
    assert (storage / 'qualify.exit').read_bytes() == b'0\n'

    def op(r):
        return r['operation']

    def reader(r):
        return op(r)['readback']

    def handle(r, kind):
        return next(h for h in op(r)['handles'] if h['kind'] == kind)

    changes = [
        ('lost successful open', 1, lambda r: reader(r)['open'].update(returned=0)),
        ('foreign open flags', 1, lambda r: reader(r)['open'].update(flags=0)),
        ('malformed successful errno', 1, lambda r: reader(r)['open'].update(errno='25')),
        ('negative successful errno', 1, lambda r: reader(r)['open'].update(errno=-1)),
        ('lost actual late unlink', 478, lambda r: op(r)['result'].update(unlink_completed=0)),
        ('invented early unlink', 2, lambda r: op(r)['result'].update(unlink_completed=1)),
        ('lost original read diagnostic', 2, lambda r: op(r)['result'].update(error='')),
        ('lost consumer diagnostic', 5, lambda r: op(r)['result'].update(error='')),
        ('false early success', 2, lambda r: op(r)['result'].update(success=1)),
        ('false structural rejection', 37, lambda r: op(r)['result'].update(success=0)),
        ('false native authority', 0, lambda r: op(r)['result'].update(runtime_authorized=1)),
        ('lost historical absence', 478, lambda r: op(r)['result'].update(reference_absence_verified=0)),
        ('stale current helper ID', 2, lambda r: r['prospective']['resolved'].update(call_id=0)),
        ('missing helper call', 0, lambda r: op(r)['boundary_calls'].pop()),
        ('foreign helper caller', 0, lambda r: op(r)['boundary_calls'][0].update(caller='Foreign')),
        ('lost sealed continuation', 0, lambda r: next(c for c in op(r)['boundary_calls'] if c.get('completion') == 'caller_continuation').update(continuation='Foreign')),
        ('wrong source alias', 0, lambda r: next(c for c in op(r)['boundary_calls'] if 'source_handle' in c).update(source_handle='source:1')),
        ('lost prefix event', 478, lambda r: op(r)['events'].pop(1)),
        ('extra post-failure call', 478, lambda r: op(r)['events'].insert(-1, 'call:999:before')),
        ('lost pending reader frame', 2, lambda r: op(r)['interrupted_boundary_ids'].clear()),
        ('missing selected hit', 2, lambda r: op(r).update(readback_hits=0)),
        ('invented helper injection', 2, lambda r: op(r).update(injected_hits=1)),
        ('unclosed source', 0, lambda r: handle(r, 'source').update(closed_at_return=0)),
        ('unclosed directory', 0, lambda r: handle(r, 'directory').update(closed_at_return=0)),
        ('unclosed lock', 0, lambda r: handle(r, 'lock').update(closed_at_return=0)),
        ('foreign cleanup owner', 0, lambda r: handle(r, 'source').update(close_caller='Foreign')),
        ('wrong source bound', 0, lambda r: op(r)['source_requests'][0].update(limit=4096)),
        ('lost unreturned read request', 2, lambda r: op(r)['source_requests'].pop()),
        ('lost other-owner state', 478, lambda r: op(r)['after']['store'].pop('coordination.lock')),
        ('changed archive receipt', 0, lambda r: op(r)['result']['release']['archive']['source_bindings'][0]['archive'].update(inode=7)),
        ('changed input flags', 0, lambda r: r.update(inputs_unchanged=0)),
        ('changed input fingerprint', 0, lambda r: r.update(input_fingerprint_after='0' * 64)),
        ('unproved fixture cleanup', 0, lambda r: r.update(roots_absent=False)),
        ('missing selected reader', 2, lambda r: op(r).update(readback=None)),
        ('invented actual EIO syscall', 2, lambda r: reader(r)['reads'][0].update(actual=copy.deepcopy(reader(r)['reads'][0]['reported']))),
        ('wrong controlled errno', 2, lambda r: reader(r)['reads'][0]['reported'].update(errno=0)),
        ('invented EOF body', 4, lambda r: reader(r)['reads'][0]['reported']['buffer'].update(bytes_hex='ff')),
        ('lost positive short read', 1, lambda r: reader(r)['reads'][0].update(delegated_requested=65537)),
        ('wrong partial continuation bound', 3, lambda r: reader(r)['reads'][1].update(requested=65537)),
        ('altered actual physical byte', 5, lambda r: reader(r)['reads'][0]['actual']['buffer'].update(bytes_hex='ff')),
        ('lost reported byte alteration', 5, lambda r: reader(r)['reads'][0].update(reported=copy.deepcopy(reader(r)['reads'][0]['actual']))),
        ('lost returned source digest', 5, lambda r: handle(r, 'source').update(sha256='0' * 64)),
        ('unflagged-byte claim lost', 5, lambda r: reader(r)['result'].update(bytes_utf8=1)),
        ('wrong opened native identity', 1, lambda r: reader(r)['opened']['metadata'].__setitem__(1, 7)),
        ('strong observer disguised as weak', 2, lambda r: reader(r).update(alias_is_weak=0)),
        ('failed reader retained at return', 2, lambda r: reader(r).update(weak_open_at_return=1)),
        ('closed reader probe forged', 2, lambda r: reader(r)['at_reader_return'].update(errno=0)),
        ('open source probe erased', 1, lambda r: reader(r)['at_reader_return'].update(duplicate=None)),
        ('observer duplicate close lost', 1, lambda r: reader(r)['at_reader_return']['duplicate_close'].update(returned=0)),
        ('primary observer cleanup inserted', 2, lambda r: reader(r)['recovery'].append(dict(role='observer'))),
        ('strong bias concealed', 482, lambda r: reader(r).update(weak_open_at_release_return=0)),
        ('strong recovery erased', 482, lambda r: reader(r)['recovery'].clear()),
        ('strong recovery misowned', 482, lambda r: reader(r)['recovery'][0].update(role='implementation')),
        ('strong recovered descriptor still open', 482, lambda r: reader(r)['after_recovery'].update(duplicate=999)),
    ]
    for name, index, change in changes:
        case, original = examples[index]
        altered = copy.deepcopy(original)
        change(altered)
        assert rejects(lambda: verify_row(plan, case, altered, support, oracle)), name
    manifests = [
        ('missing case receipt', lambda r: r['case_files'].pop()),
        ('reordered case receipts', lambda r: r['case_files'].reverse()),
        ('unfinished current case', lambda r: r.update(current_case=plan['cases'][0])),
        ('hidden process attempt', lambda r: r.update(forbidden_process_attempts=1)),
        ('caller guard bypass', lambda r: r['caller_controls'][0].update(instrumented_returned=1)),
        ('foreign case path', lambda r: r['case_files'][0].update(path='foreign')),
    ]
    for name, change in manifests:
        altered = copy.deepcopy(report)
        change(altered)
        assert rejects(lambda: header(plan, altered, support)), name
    byte_controls = []
    for name in ('wrong case size', 'wrong case digest'):
        altered = copy.deepcopy(report['case_files'][0])
        if name == 'wrong case size':
            altered['size_bytes'] += 1
        else:
            altered['sha256'] = '0' * 64
        assert rejects(lambda: support.read_case(storage, altered)), name
        byte_controls.append(name)
    domain_controls = [
        ('missing primary case', lambda p: p['cases'].pop(2)),
        ('stale numeric selection', lambda p: p['cases'][2]['selector'].update(call_id=6)),
        ('unsafe after-return selection', lambda p: p['cases'][2]['selector'].update(phase='after')),
        ('restored blanket XOR rejection', lambda p: p['cases'][37].update(expected_success=0)),
        ('counterexample counted as primary', lambda p: p['cases'][482].update(role='primary')),
        ('strong alias in primary domain', lambda p: p['cases'][2]['selector'].update(strong_alias=1)),
        ('omitted predecessor root census', lambda p: p['previous_root_reports'].pop()),
    ]
    for name, change in domain_controls:
        altered = copy.deepcopy(plan)
        change(altered)
        assert rejects(lambda: domain(altered)), name
    result = dict(schema='fsmgen.release_readback_ordinary_audit.v1', success=True, **dict(totals),
        oracle_correction='first-audit-failure/review.json', correction_pins=len(correction_pins),
        original_oracle_rejected_valid_short_read=True,
        cases=len(plan['cases']), roots=len(roots), prior_disjoint_absent_roots=len(prior_paths),
        assertions=assertions, preflight=preflight, caller_controls=6, prospective_pins=len(pins),
        unchanged_inputs=len(plan['inputs']), row_falsifiers=[n for n, _, _ in changes],
        manifest_falsifiers=[n for n, _ in manifests], byte_falsifiers=byte_controls,
        domain_falsifiers=[n for n, _ in domain_controls],
        case_bytes=sum(r['size_bytes'] for r in report['case_files']), scope=plan['scope'])
    if not saved:
        with (LOG / 'audit.json').open('x') as output:
            output.write(json.dumps(result, indent=2, sort_keys=True) + '\n')
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
