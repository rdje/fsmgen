"""Prospective full-operation flow for the remaining acquisition close sites."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.3.2.2.2.2.3.1.2'
REVISION = 'b2e382b393784ea6b0bf48c3345fa05a919dff97'


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


COORD = module('remaining_coordinator_plan', BASE.parent/'native-proxy-observation-coordinator-cuts-20260911/plan.py')
SNAPSHOT = module('remaining_snapshot_plan', BASE.parent/'native-proxy-snapshot-occurrence-20260911/plan.py')


def targets(route):
    return SNAPSHOT.TARGET_ROLES+(['hold'] if route == 'reuse' else [])


def flow(route):
    rows = []
    for item in COORD.flow(route):
        event = item['event']
        if not event.startswith('operation:'):
            rows.append(item); continue
        phase = event.split(':')[1]
        rows.append(dict(event=event, effect=None))
        for call in SNAPSHOT.trace(route):
            if not call.startswith(phase+':') or call == phase+':enter': continue
            effect = None
            if call.startswith('admit:read:') or ':sources:read:' in call:
                effect = dict(target=call.split(':')[-1])
            elif call == 'finish:hold:read': effect = dict(target='hold')
            rows.append(dict(event=call, effect=effect))
        if phase == 'acquire' and route == 'fresh':
            rows.append(dict(event='publication:enter', effect=dict(publication=True)))
    assert len(rows) == len({row['event'] for row in rows})
    return rows


def source_label(event):
    if event == 'coordinator:lock:open': return 'lock'
    if event.startswith('census:') and ':source:' in event:
        parts = event.split(':'); return ':'.join(parts[:2]+[parts[3]])
    if event.startswith('admit:read:'): return 'target:'+event.split(':')[-1]
    if ':sources:read:' in event:
        parts = event.split(':'); return 'fresh:'+parts[0]+':'+parts[-1]
    if event == 'finish:hold:read': return 'hold'
    return None


def execution(route, case):
    trace, completed, closes, live = [], [], [], []
    error = None

    def close_batch(labels):
        nonlocal error
        for label in labels:
            assert label in live
            live.remove(label); closes.append(label)
            if label in case['reports'] and error is None:
                error = dict(kind='close', label=label, errno=case['reports'][label])

    def unwind():
        close_batch([label for label in live if label != 'lock' and not label.startswith('target:')])
        close_batch([label for label in live if label.startswith('target:')])
        close_batch(list(live))

    for item in flow(route):
        event = item['event']; trace.append(event)
        if event == case.get('cut'):
            error = dict(kind='primary', event=event); unwind(); break
        completed.append(event)
        label = source_label(event)
        if label: live.append(label)
        if event.startswith('census:') and ':check:' in event:
            parts = event.split(':'); close_batch([':'.join(parts[:2]+[parts[3]])])
        elif ':sources:fresh:' in event:
            parts = event.split(':'); close_batch(['fresh:'+parts[0]+':'+parts[-1]])
        elif event == 'finish:hold:check': close_batch(['hold'])
        elif event == 'finish:directory:image':
            close_batch([label for label in live if label.startswith('target:')])
        elif event == 'coordinator:lock:identity:final': close_batch(['lock'])
        if error is not None:
            unwind(); break
    assert not live
    assert case.get('cut') is None or case['cut'] in trace
    assert set(case['reports']) <= set(closes)
    if case.get('omit'): assert case['omit'] in closes
    published = route == 'reuse' or 'publication:enter' in completed
    return dict(trace=trace, completed_calls=completed, closes=closes, error=error,
                hold='complete' if published else 'absent')


def build():
    cases, mutants = [], []
    for route in ('fresh', 'reuse'):
        roles = targets(route)
        target_reports = {'target:'+role: ('EIO' if i == 0 else 'ENOSPC') for i, role in enumerate(roles)}
        outer = dict({name:'ENOSPC' for name in target_reports}, lock='ENOSPC')

        def add(name, reports=None, cut=None, omit=None):
            case = dict(id=route+':'+name, route=route, cut=cut, reports=reports or {}, omit=omit)
            case['expectation'] = execution(route, case)
            (mutants if omit else cases).append(case)

        add('complete'); add('lock', {'lock':'EIO'})
        for role in roles: add('target:'+role, {'target:'+role:'EIO'})
        add('all_targets', target_reports)
        add('targets_and_lock', dict(target_reports, lock='ENOSPC'))
        for phase in ('admit', 'acquire', 'finish'):
            for role in roles:
                label = 'fresh:'+phase+':'+role
                add(label, {label:'EIO'})
                add(label+':primary', dict(outer, **{label:'EIO'}), cut=phase+':sources:fresh:'+role)
            for role in (roles[0], roles[-1]):
                label = 'fresh:'+phase+':'+role
                add(label+':outer', dict(outer, **{label:'EIO'}))
        add('hold', {'hold':'EIO'})
        add('hold_and_outer', dict(outer, hold='EIO'))
        add('hold_primary', dict(outer, hold='EIO'), cut='finish:hold:check')
        for phase in ('pre', 'post'):
            count = 3 if phase == 'pre' and route == 'fresh' else 4
            for index in range(count):
                label = 'census:'+phase+':'+str(index)
                add(label, {label:'EIO'})
                # The pre-admission census owns only its temporary reader and
                # lock; the post-publication census also unwinds all targets.
                cleanup = outer if phase == 'post' else {'lock':'ENOSPC'}
                add(label+':primary', dict(cleanup, **{label:'EIO'}),
                    cut='census:'+phase+':check:'+str(index))
            label = 'census:'+phase+':0'
            add(label+':outer', dict(outer if phase == 'post' else {'lock':'ENOSPC'}, **{label:'EIO'}))
        add('admit_primary', dict(target_reports, lock='ENOSPC'), cut='admit:sources:original:wrapper')
        add('early_lock_primary', {'lock':'EIO'}, cut='coordinator:root:acquired')
        add('late_lock_primary', {'lock':'EIO'}, cut='coordinator:root:final')
        for label in ['lock', 'target:wrapper', 'hold', 'census:pre:0', 'census:post:0']:
            add('omit:'+label, omit=label)
        for phase in ('admit', 'acquire', 'finish'):
            add('omit:fresh:'+phase, omit='fresh:'+phase+':wrapper')
    assert len({row['id'] for row in cases+mutants}) == len(cases)+len(mutants)
    return dict(schema='fsmgen.inactive_observation_remaining_close_plan.v1', owner=OWNER,
        source_revision=REVISION, flows={route:flow(route) for route in ('fresh','reuse')},
        cases=cases, mutants=mutants, fixture=COORD.build()['fixture'],
        checkpoints='Compose the previously qualified coordinator and target-source call flows. Semantic passes and publication remain complete aggregates with their earlier internal qualifications. Declare each structural reference, original target, temporary target reread, temporary hold and permanent-lock close. The actual close and closure observation precede modeled EIO/ENOSPC; all owners attempt cleanup and preserve the primary or first inner error.',
        custody='Count only completed source/aggregate/directory effects. Retain every actual source/writer/lock/directory handle. Bind observed close calls by actual GLOB identity; the independent oracle derives exact per-path source-read occurrence. A failed report returns no acquisition result and never removes or repairs a hold. Preserve every other owner and recover deliberately omitted closes before fixture removal.',
        limits='Finite synchronous selected close reports, not operating-system close ambiguity, every syscall or aggregate-reader internal failure, asynchronous crashes, archive/capture settlement, exact release, native ownership, activation or historical startup repair. One actual independently bound reference order per selector, not a full order Cartesian product. Final all-matrix applicability and closure join remains a separate leaf.')


if __name__ == '__main__':
    (BASE/'plan.json').write_text(json.dumps(build(), sort_keys=True, indent=2)+'\n')
