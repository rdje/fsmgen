"""Independent event/ownership oracle; accepts retained data and spawns nothing."""

import hashlib
import json
import re


def exactly(rows, predicate):
    selected = [row for row in rows if predicate(row)]
    assert len(selected) == 1
    return selected[0]


def event(rows, worker, name):
    return exactly(rows, lambda row: row['event'] == 'worker_event' and row['worker'] == worker
                   and row['value']['event'] == name)


def worker_rows(rows, worker, name):
    return [row for row in rows if row['event'] == name and row.get('worker') == worker]


def native_birth(value):
    assert all(type(value.get(key)) is int for key in ('pid', 'start_sec', 'start_usec', 'ppid', 'uid', 'ruid'))
    assert value['pid'] > 1 and value['start_sec'] > 0 and 0 <= value['start_usec'] < 1_000_000
    return value['pid'], value['start_sec'], value['start_usec']


def verify_worker(case, rows, role, language, uid):
    key = case['name'] + '.' + role
    started = exactly(rows, lambda row: row['event'] == 'run_started')
    initial = exactly(rows, lambda row: row['event'] == 'snapshot'
                      and row['case'] == case['name'] and row['phase'] == 'initial')['objects']
    launch = exactly(rows, lambda row: row['event'] == 'launch_intent' and row['worker'] == key)
    assert launch['language'] == language
    assert launch['arguments'] == [case['name'], role]
    assert launch['start_new_session'] is launch['close_fds'] is True
    spawned = exactly(rows, lambda row: row['event'] == 'native_spawned' and row['worker'] == key)
    admitted = exactly(rows, lambda row: row['event'] == 'native_admitted' and row['worker'] == key)
    identity = admitted['identity']
    assert native_birth(identity) == native_birth(spawned['identity'])
    assert identity['uid'] == identity['ruid'] == uid and uid > 0
    assert identity['ppid'] == started['controller']['pid']
    assert spawned['pgid'] == admitted['pgid'] == identity['pid']
    assert spawned['session_id'] == admitted['session_id'] == identity['pid']
    values = worker_rows(rows, key, 'worker_event')
    assert 1 <= len(values) <= 32
    ready = event(rows, key, 'ready')
    assert ready == values[0]
    rv = ready['value']
    assert rv['pid'] == identity['pid'] and rv['case'] == case['name'] and rv['role'] == role
    assert rv['language'] == language and rv['uid'] == rv['euid'] == uid
    assert rv['ppid'] == identity['ppid'] and rv['pgid'] == identity['pid']
    opened = event(rows, key, 'opened')
    ov = opened['value']
    lock = initial[case['store'] + '/coordination.lock']
    assert ov['device'] == lock['device'] and ov['inode'] == lock['inode']
    assert type(ov['descriptor']) is int and ov['descriptor'] > 2 and ov['close_on_exec'] is True
    commands = worker_rows(rows, key, 'command')
    expected_commands = ['admit', 'lock'] + (['release'] if role == 'holder' else ['scan'] if role == 'inheritance' else [])
    assert [row['command'] for row in commands] == expected_commands
    assert ready['sequence'] < commands[0]['sequence'] < opened['sequence'] < commands[1]['sequence']
    reaped = exactly(rows, lambda row: row['event'] == 'reaped' and row['worker'] == key)
    assert reaped['pid'] == identity['pid'] and reaped['leader_reaped'] is reaped['group_gone'] is True
    assert reaped['separate_recovery'] is False and reaped['first_capture_error'] is None
    assert reaped['discarded'] == dict(stdout=0, stderr=0)
    assert set(reaped['streams']) == {'stdout', 'stderr'}
    assert reaped['streams']['stderr']['size_bytes'] == 0
    assert 0 < reaped['streams']['stdout']['size_bytes'] <= 32768
    for channel, source in reaped['streams'].items():
        assert source['path'].endswith('/' + key + '.' + channel)
        assert re.fullmatch('[0-9a-f]{64}', source['sha256'])
        raw = (b''.join((json.dumps(row['value'], sort_keys=True, separators=(',', ':')) + '\n').encode()
                       for row in values) if channel == 'stdout' else b'')
        assert source['size_bytes'] == len(raw) and source['sha256'] == hashlib.sha256(raw).hexdigest()
    cancelled = case.get('outcome') == 'cancel' and role == 'waiter'
    expected_events = ['ready', 'opened']
    if role == 'holder':
        expected_events += ['entered', 'held', 'finished']
    elif role == 'inheritance':
        expected_events += ['probe_spawned', 'probe_ready', 'probe_result', 'probe_reaped', 'entered', 'finished']
    else:
        expected_events += ['busy']
        if not cancelled:
            if case['outcome'] == 'handoff':
                expected_events += ['entered']
            expected_events += ['finished']
    assert sorted(row['value']['event'] for row in values) == sorted(expected_events)
    if cancelled:
        assert reaped['exit_code'] == -15
        assert not any(row['value']['event'] in ('entered', 'held', 'finished') for row in values)
    else:
        assert reaped['exit_code'] == 0
        finished = event(rows, key, 'finished')
        fv = finished['value']
        assert finished == values[-1] and finished['sequence'] < reaped['sequence']
        assert fv['descriptor_closed'] is True and fv['close_error'] is None
        assert fv.get('forbidden_process_attempts', 0) == 0
        assert type(fv['entered']) is type(fv['success']) is bool
        assert type(fv['busy_count']) is int and fv['busy_count'] >= 0
        assert type(fv['first_ns']) is type(fv['last_ns']) is int
        assert 0 <= fv['first_ns'] <= fv['last_ns']
    for row in values:
        if row['value']['event'] not in ('probe_ready', 'probe_result'):
            assert row['value']['pid'] == identity['pid']
    return key, reaped


def verify_outcomes(case, rows, uid):
    start = exactly(rows, lambda row: row['event'] == 'run_started')
    if case['kind'] == 'pair':
        holder, _ = verify_worker(case, rows, 'holder', case['holder'], uid)
        waiter, waiter_reaped = verify_worker(case, rows, 'waiter', case['waiter'], uid)
        held = event(rows, holder, 'held')
        busy = event(rows, waiter, 'busy')
        assert busy['value']['errno'] in start['busy_errno']
        release = exactly(worker_rows(rows, holder, 'command'), lambda row: row['command'] == 'release')
        assert event(rows, holder, 'entered')['sequence'] < held['sequence'] < busy['sequence'] < release['sequence']
        holder_result = event(rows, holder, 'finished')['value']
        assert holder_result['entered'] is True and holder_result['busy_count'] == 0
        assert not any(row['event'] in ('probe_native_admitted', 'capture_failed')
                       and row.get('worker') in (holder, waiter) for row in rows)
        if case['outcome'] == 'cancel':
            sent = exactly(worker_rows(rows, waiter, 'signal'), lambda row: True)
            assert sent['signal'] == 15
            assert busy['sequence'] < sent['sequence'] < waiter_reaped['sequence'] < release['sequence']
            assert holder_result['success'] is True and holder_result['error'] is None
        else:
            assert not worker_rows(rows, waiter, 'signal')
            finished = event(rows, waiter, 'finished')
            result = finished['value']
            assert result['busy_count'] > 0
            if case['outcome'] == 'handoff':
                assert result['success'] is result['entered'] is holder_result['success'] is True
                assert result['error'] is holder_result['error'] is None
                assert release['sequence'] < event(rows, waiter, 'entered')['sequence'] < finished['sequence']
            elif case['outcome'] == 'deadline':
                assert result['success'] is result['entered'] is False
                assert result['error'].strip() == 'permanent lock admission deadline expired'
                # The Perl source clock is a floating-point monotonic value.
                assert result['last_ns'] - result['first_ns'] >= 2_000_000_000 - 1000
                assert finished['sequence'] < waiter_reaped['sequence'] < release['sequence']
                assert holder_result['success'] is True and holder_result['error'] is None
            else:
                assert case['outcome'] == 'replace'
                replacement = exactly(rows, lambda row: row['event'] == 'replaced' and row['case'] == case['name'])
                assert busy['sequence'] < replacement['sequence'] < release['sequence']
                assert result['success'] is result['entered'] is holder_result['success'] is False
                assert result['error'].strip() == holder_result['error'].strip() == 'invalid permanent lock identity'
    else:
        key, _ = verify_worker(case, rows, 'inheritance', case['language'], uid)
        admitted = exactly(worker_rows(rows, key, 'native_admitted'), lambda row: True)
        probe = exactly(worker_rows(rows, key, 'probe_native_admitted'), lambda row: True)
        native_birth(probe['identity'])
        assert probe['identity']['ppid'] == admitted['identity']['pid']
        assert probe['identity']['pid'] != admitted['identity']['pid']
        assert probe['identity']['uid'] == probe['identity']['ruid'] == uid
        assert probe['pgid'] == probe['session_id'] == admitted['identity']['pid']
        spawned = event(rows, key, 'probe_spawned')['value']
        ready = event(rows, key, 'probe_ready')['value']
        assert spawned['child_pid'] == ready['pid'] == probe['identity']['pid']
        assert ready['ppid'] == admitted['identity']['pid'] and ready['pgid'] == probe['pgid']
        assert ready['uid'] == ready['euid'] == uid and spawned['before_acquisition'] is True
        assert spawned['sealed'] is case['sealed']
        result_row = event(rows, key, 'probe_result')
        result = result_row['value']
        opened = event(rows, key, 'opened')['value']
        assert result['pid'] == ready['pid'] and result['descriptor'] == opened['descriptor']
        assert result['closed'] is case['sealed'] and result['inherited'] is not case['sealed']
        if not case['sealed']:
            assert result['device'] == opened['device'] and result['inode'] == opened['inode']
        reaped = event(rows, key, 'probe_reaped')
        assert reaped['value']['child_pid'] == ready['pid']
        assert reaped['value']['exit_code'] == (0 if case['sealed'] else 23)
        assert result_row['sequence'] < reaped['sequence'] < event(rows, key, 'entered')['sequence']
        finished = event(rows, key, 'finished')['value']
        assert finished['success'] is finished['entered'] is True
        assert finished['busy_count'] == 0 and finished['error'] is None
        assert not worker_rows(rows, key, 'signal')


def verify_journal(rows, plan, uid):
    assert rows and [row['sequence'] for row in rows] == list(range(len(rows)))
    assert all(type(row['controller_ns']) is int for row in rows)
    assert [row['controller_ns'] for row in rows] == sorted(row['controller_ns'] for row in rows)
    started = exactly(rows, lambda row: row['event'] == 'run_started')
    allowed_events = {'run_started', 'case_started', 'allocation_intent', 'allocated', 'snapshot',
                      'launch_intent', 'launched', 'native_spawned', 'native_admitted',
                      'probe_native_admitted', 'worker_event', 'command', 'signal', 'reaped',
                      'replacement_intent', 'replaced', 'removed', 'case_finished', 'run_finished'}
    assert all(row['event'] in allowed_events for row in rows)
    assert rows[0] == started and started['native_proxy_execution'] is started['live_store_authorized'] is False
    assert started['busy_errno'] == plan['native_constants']['busy_errno']
    assert started['controller']['uid'] == started['controller']['ruid'] == uid
    native_birth(started['controller'])
    expected = {(holder, waiter, outcome) for holder, waiter in (('perl', 'python'), ('python', 'perl'))
                for outcome in ('handoff', 'deadline', 'cancel', 'replace')}
    pairs = [case for case in plan['cases'] if case['kind'] == 'pair']
    inheritance = [case for case in plan['cases'] if case['kind'] == 'inheritance']
    assert len(pairs) == 8 and {(case['holder'], case['waiter'], case['outcome']) for case in pairs} == expected
    assert len(inheritance) == 4 and {(case['language'], case['sealed']) for case in inheritance} == {
        ('perl', True), ('perl', False), ('python', True), ('python', False)}
    names = [case['name'] for case in plan['cases']]
    assert len(set(names)) == 12
    assert [row['case'] for row in rows if row['event'] == 'case_started'] == names
    assert [row['case'] for row in rows if row['event'] == 'case_finished'] == names
    workers, removed = set(), set()
    for case in plan['cases']:
        verify_outcomes(case, rows, uid)
        snapshots = [row for row in rows if row['event'] == 'snapshot' and row['case'] == case['name']]
        assert [row['phase'] for row in snapshots] == (
            ['initial', 'busy', 'replacement', 'final'] if case.get('outcome') == 'replace'
            else ['initial', 'busy', 'final'] if case['kind'] == 'pair' else ['initial', 'final'])
        initial, final = snapshots[0]['objects'], snapshots[-1]['objects']
        store = case['store']
        assert re.fullmatch(r'\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-Language20260913_[a-z_]+', store)
        assert set(initial) == {store, store + '/images', store + '/references', store + '/coordination.lock'}
        for relative, value in initial.items():
            assert value['path'] == relative and value['uid'] == uid and value['inode'] > 0
            assert value['device'] == started['root_device']
            assert value['kind'] == ('file' if relative.endswith('.lock') else 'directory')
            assert value['mode'] == (0o600 if value['kind'] == 'file' else 0o700)
        if case.get('outcome') == 'replace':
            lock = store + '/coordination.lock'
            old = dict(initial[lock], path=case['retired_lock'])
            assert set(final) == set(initial) | {case['retired_lock']}
            assert final[case['retired_lock']] == old
            assert final[lock] == dict(initial[lock], inode=final[lock]['inode'])
            assert final[lock]['inode'] != initial[lock]['inode']
            assert {key: value for key, value in final.items() if key in initial and key != lock} == {
                key: value for key, value in initial.items() if key != lock}
            assert snapshots[1]['objects'] == initial and snapshots[2]['objects'] == final
        else:
            assert final == initial and all(row['objects'] == initial for row in snapshots)
        finished = exactly(rows, lambda row: row['event'] == 'case_finished' and row['case'] == case['name'])
        assert finished['success'] is True and set(finished['removed']) == set(final)
        actual_removals = [row['object'] for row in rows if row['event'] == 'removed' and row['case'] == case['name']]
        assert len(actual_removals) == len(final)
        assert {value['path']: value for value in actual_removals} == final
        assert not removed.intersection(final)
        removed.update(final)
        workers.update(finished['workers'])
    reap_rows = [row for row in rows if row['event'] == 'reaped']
    assert len(reap_rows) == len(workers) == 20 and {row['worker'] for row in reap_rows} == workers
    spawned = [row for row in rows if row['event'] == 'native_spawned']
    assert len(spawned) == len({native_birth(row['identity']) for row in spawned}) == 20
    assert len([row for row in rows if row['event'] == 'launched']) == 20
    assert len([row for row in rows if row['event'] == 'launch_intent']) == 20
    probes = [row for row in rows if row['event'] == 'probe_native_admitted']
    assert len(probes) == 4 and len({native_birth(row['identity']) for row in probes}) == 4
    assert len({native_birth(row['identity']) for row in spawned + probes}) == 24
    assert len(removed) == 50
    assert not any(row['event'] in ('first_failure', 'capture_failed') for row in rows)
    return dict(cases=12, worker_leaders=20, exec_probes=4, removed_objects=50,
                native_proxy_execution=False, clock_domains_kept_separate=True)
