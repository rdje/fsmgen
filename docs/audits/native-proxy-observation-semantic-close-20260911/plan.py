"""Prospective census close batches and competing-error precedence."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.3.2.2.2.2.2.2.2.2.2'
REVISION = '829df81b7df7cc2a8f61e740b67655db8093ea40'
spec = importlib.util.spec_from_file_location('prior_semantic_plan', BASE.parent/'native-proxy-observation-semantic-cuts-20260911/plan.py')
SEMANTIC = importlib.util.module_from_spec(spec)
spec.loader.exec_module(SEMANTIC)


def source_label(event):
    if not event.endswith(':read'): return None
    parts = event.split(':')
    if parts[0] == 'reference':
        return ('original:' if parts[1] == 'initial' else 'fresh:')+parts[2]
    assert parts[0] == 'image'
    return ':'.join(parts[:3]+[parts[4]])


def execution(flow, case):
    """Walk declared calls, with explicit close batches at ownership boundaries.

    A batch attempts every close. A failed inner batch unwinds retained originals;
    a primary call error outranks all reports produced during its cleanup.
    """
    trace, completed, closes, live = [], [], [], []
    primary = case.get('cut'); reports = case['reports']; error = None

    def close_batch(labels):
        nonlocal error
        for label in labels:
            assert label in live
            live.remove(label); closes.append(label)
            if label in reports and error is None:
                error = dict(kind='close', label=label, errno=reports[label])

    def unwind():
        # At most one image-input pair or one fresh reference is nested inside
        # the outer original-reference list. Preserve each owner's open order.
        close_batch([label for label in live if not label.startswith('original:')])
        close_batch(list(live))

    for item in flow:
        event = item['event']; trace.append(event)
        if event == primary:
            error = dict(kind='primary', event=event)
            unwind(); break
        completed.append(event)
        label = source_label(event)
        if label: live.append(label)
        if event.startswith('image:') and event.endswith(':directory:final'):
            prefix = ':'.join(event.split(':')[:3])+':'
            close_batch([prefix+'c', prefix+'image'])
        elif event.startswith('reference:closure:') and event.endswith(':fresh'):
            close_batch(['fresh:'+event.split(':')[2]])
        elif event == 'closure:return': close_batch(list(live))
        if error is not None:
            unwind(); break
    assert not live
    assert primary is None or any(event == primary for event in trace)
    assert set(reports) <= set(closes)
    return dict(trace=trace, completed_calls=completed, closes=closes, error=error)


def build():
    prior = SEMANTIC.build(); cases = []; mutants = []
    for route in ('fresh', 'reuse'):
        for phase in ('pre', 'post'):
            n = 3 if route == 'fresh' and phase == 'pre' else 4
            originals = ['original:'+str(i) for i in range(n)]
            original_reports = {name: ('EIO' if i == 0 else 'ENOSPC') for i, name in enumerate(originals)}

            def add(name, reports=None, cut=None, guard=None):
                row = dict(id=route+':'+phase+':'+name, route=route, phase=phase,
                           reports=reports or {}, cut=cut,
                           hold='complete' if guard or not (reports or cut) or route == 'reuse' or phase == 'post' else 'absent')
                if guard: row['guard'] = guard
                row['expectations'] = {binding: execution(flow, row)
                    for binding, flow in prior['flows'][route][phase].items()}
                (mutants if guard else cases).append(row)

            add('complete')
            for name in originals: add(name, {name:'EIO'})
            add('all_originals', original_reports)
            for i in range(n): add('fresh:'+str(i), {'fresh:'+str(i):'EIO'})
            for i in (0, n-1):
                add('fresh_and_originals:'+str(i), dict({key:'ENOSPC' for key in originals}, **{'fresh:'+str(i):'EIO'}))
            for part in ('initial', 'closure'):
                for role in ('primary', 'other'):
                    prefix = 'image:'+part+':'+role+':'
                    pair = {prefix+'c':'EIO', prefix+'image':'ENOSPC'}
                    for member in ('c', 'image'): add(prefix+member, {prefix+member:'EIO'})
                    add(prefix+'both', pair)
                    # An initial image failure may precede later original reads.
                    # Only the first original is guaranteed to be owned for both
                    # image roles; original:0 suffices for competing outer error.
                    add(prefix+'both_and_original', dict(pair, **{'original:0':'ENOSPC'}))
                    add(prefix+'primary_and_closes', dict(pair, **{'original:0':'ENOSPC'}),
                        cut='image:'+part+':'+role+':input:c:check')
            for i in (0, n-1):
                reached = {key:value for key,value in original_reports.items() if int(key.split(':')[1]) <= i}
                add('original_primary:'+str(i), reached, cut='reference:initial:'+str(i)+':decode')
            for i in range(n):
                add('fresh_primary:'+str(i), dict({key:'ENOSPC' for key in originals}, **{'fresh:'+str(i):'EIO'}),
                    cut='reference:closure:'+str(i)+':fresh')
            for guard in ('omit_original_reference_close', 'omit_image_input_close', 'omit_fresh_reference_close'):
                add(guard, guard=guard)
    assert len({row['id'] for row in cases+mutants}) == len(cases)+len(mutants)
    return dict(schema='fsmgen.inactive_observation_semantic_close_plan.v1', owner=OWNER,
        source_revision=REVISION, flows=prior['flows'], cases=cases, mutants=mutants,
        fixture=prior['fixture'], ordering=prior['ordering'],
        checkpoints='Existing semantic call trace plus independently predeclared census close batches. Reports occur after actual CORE::close and actual closure inspection, using EIO/ENOSPC. Original-reference and image-input batches must attempt every owned close; fresh-reference cleanup is immediate. Primary call errors outrank cleanup reports; the first inner close report outranks outer cleanup reports.',
        custody='Retain every returned source/writer/lock/directory handle from the full operation. Bind each census close to the exact GLOB address in the recorder and independently to its per-path read occurrence in the oracle. Check actual close result and closure before modeled error return. Model resource effects only for completed declared calls. Preserve exact conservative holds and all other owners.',
        mutants_contract=prior['mutants_contract'],
        limits='Finite synchronous modeled census close reports and competing primary errors. This does not prove operating-system close ambiguity, every syscall or aggregate-reader internal failure, asynchronous crashes, target/permanent-lock close reports, native ownership, archive/release, activation or historical startup repair. Each selector runs once with its actual independently bound order; no full selector-by-order product.')


if __name__ == '__main__':
    (BASE/'plan.json').write_text(json.dumps(build(), sort_keys=True, indent=2)+'\n')
