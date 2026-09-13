"""Exercise the event reader with explicitly synthetic carriers, without workers."""

import argparse
import copy
import hashlib
import json
from pathlib import Path

from contract import BASE, ROOT, cases
from oracle import verify_journal


def carrier():
    rows = []
    plan = dict(cases=cases(), native_constants=dict(busy_errno=[35]))
    uid = 501
    next_pid = 200

    def add(event, **fields):
        rows.append(dict(sequence=len(rows), controller_ns=1_000_000 + len(rows) * 1000,
                         event=event, **copy.deepcopy(fields)))

    def native(pid, parent):
        return dict(pid=pid, ppid=parent, start_sec=123456, start_usec=pid,
                    uid=uid, ruid=uid)

    def value(key, pid, event, **fields):
        add('worker_event', worker=key, value=dict(event=event, pid=pid, **fields))

    add('run_started', schema='fsmgen.language_coordination_actual.v1',
        admission_commit='a' * 40, controller=native(100, 99), root_device=9,
        plan_sha256='b' * 64, preflight_sha256='c' * 64, busy_errno=[35],
        native_proxy_execution=False, live_store_authorized=False)
    for index, case in enumerate(plan['cases']):
        add('case_started', case=case['name'])
        initial = {}
        for offset, (suffix, kind) in enumerate((('', 'directory'), ('/images', 'directory'),
                                                ('/references', 'directory'), ('/coordination.lock', 'file'))):
            path = case['store'] + suffix
            obj = dict(path=path, device=9, inode=1000 + 10 * index + offset,
                       uid=uid, kind=kind, mode=0o600 if kind == 'file' else 0o700)
            add('allocation_intent', case=case['name'], path=path, kind=kind)
            add('allocated', case=case['name'], object=obj)
            initial[path] = obj
        add('snapshot', case=case['name'], phase='initial', objects=initial)
        lock = initial[case['store'] + '/coordination.lock']
        worker_ids = {}

        def launch(role, language):
            nonlocal next_pid
            pid = next_pid
            next_pid += 1
            key = case['name'] + '.' + role
            worker_ids[key] = pid
            add('launch_intent', worker=key, language=language, arguments=[case['name'], role],
                script=BASE.relative_to(ROOT).as_posix() + ('/worker.pl' if language == 'perl' else '/peer.py'),
                start_new_session=True, close_fds=True)
            add('launched', worker=key, pid=pid)
            for event in ('native_spawned', 'native_admitted'):
                add(event, worker=key, identity=native(pid, 100), pgid=pid, session_id=pid)
            value(key, pid, 'ready', case=case['name'], role=role, language=language,
                  uid=uid, euid=uid, ppid=100, pgid=pid)
            add('command', worker=key, command='admit')
            value(key, pid, 'opened', descriptor=3, device=9, inode=lock['inode'], close_on_exec=True)
            add('command', worker=key, command='lock')
            return key, pid

        def finish(key, pid, success, entered, busy_count, error=None):
            first_ns = 1000 * pid
            last_ns = first_ns + (2_000_000_000 if error == 'permanent lock admission deadline expired' else 1_000_000)
            value(key, pid, 'finished', success=success, entered=entered, busy_count=busy_count,
                  error=error, descriptor_closed=True, close_error=None,
                  first_ns=first_ns, last_ns=last_ns)

        def reap(key, pid, code=0):
            body = b''.join((json.dumps(row['value'], sort_keys=True, separators=(',', ':')) + '\n').encode()
                            for row in rows if row['event'] == 'worker_event' and row['worker'] == key)
            streams = {channel: dict(path='.artifacts/logs/native-proxy-language-coordination-20260913/' + key + '.' + channel,
                                     size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
                       for channel, raw in (('stdout', body), ('stderr', b''))}
            add('reaped', worker=key, pid=pid, exit_code=code, leader_reaped=True, group_gone=True,
                separate_recovery=False, first_capture_error=None, discarded=dict(stdout=0, stderr=0), streams=streams)

        final = copy.deepcopy(initial)
        if case['kind'] == 'pair':
            holder, hp = launch('holder', case['holder'])
            value(holder, hp, 'entered')
            value(holder, hp, 'held')
            waiter, wp = launch('waiter', case['waiter'])
            value(waiter, wp, 'busy', errno=35)
            add('snapshot', case=case['name'], phase='busy', objects=initial)
            if case['outcome'] == 'replace':
                old = dict(lock, path=case['retired_lock'])
                final[case['retired_lock']] = old
                final[lock['path']]['inode'] += 1
                add('replacement_intent', case=case['name'], original=lock, destination=case['retired_lock'])
                add('replaced', case=case['name'], original=old, replacement=final[lock['path']])
                add('snapshot', case=case['name'], phase='replacement', objects=final)
            if case['outcome'] == 'cancel':
                add('signal', worker=waiter, signal=15, identity=native(wp, 100))
                reap(waiter, wp, -15)
            elif case['outcome'] == 'deadline':
                finish(waiter, wp, False, False, 100, 'permanent lock admission deadline expired')
                reap(waiter, wp)
            add('command', worker=holder, command='release')
            if case['outcome'] == 'replace':
                finish(holder, hp, False, True, 0, 'invalid permanent lock identity')
                finish(waiter, wp, False, False, 1, 'invalid permanent lock identity')
            else:
                finish(holder, hp, True, True, 0)
                if case['outcome'] == 'handoff':
                    value(waiter, wp, 'entered')
                    finish(waiter, wp, True, True, 1)
            reap(holder, hp)
            if case['outcome'] not in ('cancel', 'deadline'):
                reap(waiter, wp)
        else:
            worker, pid = launch('inheritance', case['language'])
            probe_pid = next_pid
            next_pid += 1
            value(worker, pid, 'probe_spawned', child_pid=probe_pid, before_acquisition=True, sealed=case['sealed'])
            add('probe_native_admitted', worker=worker, identity=native(probe_pid, pid), pgid=pid, session_id=pid)
            value(worker, probe_pid, 'probe_ready', ppid=pid, pgid=pid, uid=uid, euid=uid)
            add('command', worker=worker, command='scan')
            fields = dict(descriptor=3, closed=case['sealed'], inherited=not case['sealed'])
            if not case['sealed']:
                fields.update(device=9, inode=lock['inode'])
            value(worker, probe_pid, 'probe_result', **fields)
            value(worker, pid, 'probe_reaped', child_pid=probe_pid, exit_code=0 if case['sealed'] else 23)
            value(worker, pid, 'entered')
            finish(worker, pid, True, True, 0)
            reap(worker, pid)
        add('snapshot', case=case['name'], phase='final', objects=final)
        removed = sorted(final, key=lambda item: (item.count('/'), item), reverse=True)
        for relative in removed:
            add('removed', case=case['name'], object=final[relative])
        add('case_finished', case=case['name'], success=True, removed=removed, workers=list(worker_ids))
    return dict(schema='fsmgen.synthetic_language_coordination_carrier.v1', synthetic=True,
                uid=uid, plan=plan, rows=rows, actual_worker_execution=False)


def select(rows, predicate):
    return next(row for row in rows if predicate(row))


def reseal_streams(rows):
    """Keep altered-event carriers coherent with their reported raw stream hashes."""
    for row in rows:
        if row['event'] != 'reaped':
            continue
        raw = b''.join((json.dumps(event['value'], sort_keys=True, separators=(',', ':')) + '\n').encode()
                       for event in rows if event['event'] == 'worker_event' and event['worker'] == row['worker'])
        row['streams']['stdout'].update(size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def qualify(value):
    assert value['synthetic'] is True and value['actual_worker_execution'] is False
    plan, rows, uid = value['plan'], value['rows'], value['uid']
    expected = verify_journal(rows, plan, uid)
    controls = []
    mutations = (
        ('native_authority', lambda r: r[0].update(native_proxy_execution=True)),
        ('missing_case', lambda r: r.pop(next(i for i, row in enumerate(r) if row['event'] == 'case_finished'))),
        ('lost_busy', lambda r: r.pop(next(i for i, row in enumerate(r) if row['event'] == 'worker_event' and row['value']['event'] == 'busy'))),
        ('inherited_open_admission', lambda r: select(r, lambda row: row['event'] == 'worker_event' and row['value']['event'] == 'opened')['value'].update(close_on_exec=False)),
        ('lost_close', lambda r: select(r, lambda row: row['event'] == 'worker_event' and row['value']['event'] == 'finished')['value'].update(descriptor_closed=False)),
        ('hidden_recovery', lambda r: select(r, lambda row: row['event'] == 'reaped').update(separate_recovery=True)),
        ('unsettled_group', lambda r: select(r, lambda row: row['event'] == 'reaped').update(group_gone=False)),
        ('wrong_native_parent', lambda r: select(r, lambda row: row['event'] == 'native_admitted')['identity'].update(ppid=99)),
        ('changed_worker_birth', lambda r: select(r, lambda row: row['event'] == 'native_admitted')['identity'].update(start_usec=1)),
        ('foreign_uid', lambda r: select(r, lambda row: row['event'] == 'native_admitted')['identity'].update(uid=0)),
        ('wrong_cancel_result', lambda r: select(r, lambda row: row['event'] == 'reaped' and row['exit_code'] == -15).update(exit_code=0)),
        ('short_deadline', lambda r: select(r, lambda row: row['event'] == 'worker_event' and row['value'].get('error') == 'permanent lock admission deadline expired')['value'].update(last_ns=999999999)),
        ('wrong_busy_errno', lambda r: select(r, lambda row: row['event'] == 'worker_event' and row['value']['event'] == 'busy')['value'].update(errno=0)),
        ('missing_probe', lambda r: r.pop(next(i for i, row in enumerate(r) if row['event'] == 'probe_native_admitted'))),
        ('inherited_descriptor_accepted', lambda r: select(r, lambda row: row['event'] == 'worker_event' and row['value']['event'] == 'probe_result' and row['value']['inherited'])['value'].update(closed=True, inherited=False)),
        ('probe_after_acquisition', lambda r: select(r, lambda row: row['event'] == 'worker_event' and row['value']['event'] == 'probe_spawned')['value'].update(before_acquisition=False)),
        ('lost_cleanup', lambda r: r.pop(next(i for i, row in enumerate(r) if row['event'] == 'removed'))),
        ('changed_lock_identity', lambda r: select(r, lambda row: row['event'] == 'worker_event' and row['value']['event'] == 'opened')['value'].update(inode=5)),
        ('foreign_volume', lambda r: r[0].update(root_device=8)),
        ('unknown_event', lambda r: r.append(dict(sequence=len(r), controller_ns=r[-1]['controller_ns'] + 1, event='unexpected_worker'))),
    )
    for name, mutate in mutations:
        changed = copy.deepcopy(rows)
        mutate(changed)
        # Keep transport framing coherent, so omissions must fail semantic checks.
        for index, row in enumerate(changed):
            row['sequence'] = index
            row['controller_ns'] = 1_000_000 + index * 1000
        reseal_streams(changed)
        try:
            verify_journal(changed, plan, uid)
        except (AssertionError, KeyError, ValueError):
            controls.append(name)
        else:
            raise AssertionError('countercontrol accepted: ' + name)
    shifted = copy.deepcopy(rows)
    for row in shifted:
        if row['event'] == 'worker_event' and row['value']['event'] == 'finished':
            for field in ('first_ns', 'last_ns'):
                row['value'][field] += 10_000_000_000_000 * row['value']['pid']
    reseal_streams(shifted)
    assert verify_journal(shifted, plan, uid) == expected
    child_first = copy.deepcopy(rows)
    for case in plan['cases']:
        if case['kind'] != 'inheritance':
            continue
        key = case['name'] + '.inheritance'
        spawned = select(child_first, lambda row: row['event'] == 'worker_event'
                         and row['worker'] == key and row['value']['event'] == 'probe_spawned')
        child_first.remove(spawned)
        scan = select(child_first, lambda row: row['event'] == 'command'
                      and row['worker'] == key and row['command'] == 'scan')
        child_first.insert(child_first.index(scan) + 1, spawned)
    for index, row in enumerate(child_first):
        row['sequence'] = index
        row['controller_ns'] = 1_000_000 + index * 1000
    reseal_streams(child_first)
    assert verify_journal(child_first, plan, uid) == expected
    return dict(schema='fsmgen.language_coordination_data_review.v1', synthetic=True,
                carrier_cases=len(plan['cases']), carrier_records=len(rows), rejected_controls=controls,
                independent_clock_offsets_accepted=True, child_ready_before_parent_notice_accepted=True,
                raw_streams_joined=True, expected=expected,
                actual_worker_execution=False, native_process_qualification=False)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    group.add_argument('--retain-final', action='store_true')
    group.add_argument('--verify-final', action='store_true')
    args = parser.parse_args()
    if args.retain:
        value = carrier()
        with (BASE / 'synthetic-carrier.json').open('x') as stream:
            json.dump(value, stream, sort_keys=True, indent=2)
            stream.write('\n')
        result = qualify(value)
        with (BASE / 'data-review.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    elif args.retain_final or args.verify_final:
        value = json.loads((BASE / 'synthetic-carrier.json').read_bytes())
        assert value == carrier()
        result = qualify(value)
        if args.retain_final:
            with (BASE / 'data-review-final.json').open('x') as stream:
                json.dump(result, stream, sort_keys=True, indent=2)
                stream.write('\n')
        else:
            assert result == json.loads((BASE / 'data-review-final.json').read_bytes())
    else:
        value = json.loads((BASE / 'synthetic-carrier.json').read_bytes())
        assert value == carrier()
        result = qualify(value)
        assert result == json.loads((BASE / 'data-review.json').read_bytes())
    print(json.dumps(dict(cases=result['carrier_cases'], controls=len(result['rejected_controls']),
                          actual_worker_execution=False), sort_keys=True))


if __name__ == '__main__':
    main()
