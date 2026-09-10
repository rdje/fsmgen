"""Prospective coordinator call boundaries; resource effects complete after calls."""
from __future__ import annotations

import json
from pathlib import Path

OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.3.2.2.2.2.2.2.2.1'
REVISION = 'f7fb1d0272266e5d6117023c1e9e8496622bedd0'


def flow(route: str) -> list[dict]:
    assert route in ('fresh', 'reuse')
    rows = []

    def add(event: str, effect=None):
        rows.append(dict(event=event, effect=effect))

    def structure(phase: str):
        prefix = 'structure:'+phase
        add(prefix+':enter')
        add(prefix+':names:entry', dict(directory='store'))
        for name in ('images', 'references'): add(prefix+':directory:'+name)
        add(prefix+':names:complete', dict(directory='store'))
        add(prefix+':return')

    def census(phase: str, references: int):
        prefix = 'census:'+phase
        add(prefix+':enter')
        for name in ('images', 'references'): add(prefix+':names:'+name, dict(directory=name))
        for index in range(2): add(prefix+':directory:'+str(index))
        for index in range(references):
            add(prefix+':source:'+str(index), dict(reference=phase, index=index))
            add(prefix+':check:'+str(index))
        add(prefix+':return')

    add('coordinator:root:initial')
    add('coordinator:lock:open', dict(lock=True))
    add('coordinator:lock:identity:initial')
    add('coordinator:lock:flags:get')
    add('coordinator:lock:flags:set')
    add('coordinator:lock:acquire')
    add('coordinator:lock:identity:acquired')
    add('coordinator:root:acquired')
    structure('pre')
    for name in ('images', 'references'): add('coordinator:namespace:initial:'+name)
    census('pre', 3 if route == 'fresh' else 4)
    add('semantic:pre:enter', dict(semantic='pre'))
    add('operation:admit:enter', dict(target_reads=2))
    add('operation:acquire:enter', dict(target_reads=1, publication=route == 'fresh'))
    census('post', 4)
    add('semantic:post:enter', dict(semantic='post'))
    add('operation:finish:enter', dict(target_reads=1, hold_read=True))
    structure('final')
    for name in ('images', 'references'): add('coordinator:namespace:final:'+name)
    add('coordinator:root:final')
    add('coordinator:lock:identity:final')
    assert len({row['event'] for row in rows}) == len(rows)
    return rows


def build() -> dict:
    flows = {route: flow(route) for route in ('fresh', 'reuse')}
    cases = []
    for route, rows in flows.items():
        cases.append(dict(id=route+':complete', route=route, cut=None, hold='complete'))
        published = route == 'reuse'
        for row in rows:
            cases.append(dict(id=route+':'+row['event'], route=route, cut=row['event'],
                              hold='complete' if published else 'absent'))
            if row['event'] == 'operation:acquire:enter': published = True
    return dict(schema='fsmgen.inactive_observation_coordinator_cut_plan.v1', owner=OWNER,
        source_revision=REVISION, flows=flows, cases=cases,
        mutants=[dict(id=route+':'+guard, route=route, guard=guard, hold='complete')
                 for route in ('fresh', 'reuse')
                 for guard in ('omit_lock_close', 'omit_reference_close', 'omit_directory_close')],
        fixture='Reuse the qualified four-root inert context: two runtime images, independent other observation hold, and exact primary prior hold for reuse. Declare the plan before allocations; journal each root and completed case immediately. No process, compiler, native query/helper, archive/release or retry.',
        checkpoints='Synchronous called-function entry cuts, plus structure/census returns that transfer no open handle. Never interrupt after a source or lock opens but before its caller owns it. Sealed census/observation wrappers tail-goto originals. Lock flags are cut before their fixed builtin calls; actual busy/error timing remains in the earlier modeled coordinator qualification. Semantic internals and target/lock close reports remain separately owned.',
        ordering='Structural references use their actual sorted filenames; source/check indexes are ordinal, independently mapped from exact before/after fixtures. Image directories use sorted content keys. Every reached call prefix must equal the independently generated route flow. Count only effects of calls completed before the cut.',
        custody='Retain every returned source/writer/lock and actual directory handle. Observe directory identity through an immediately closed descriptor duplicate. Independently reconstruct per-path source and directory counts: one source per completed structural reference read; each complete semantic pass adds two reads per reference, four C/four executable/two manifest reads per image, one reference-directory enumeration and four enumerations per image directory. Complete admission reads each target twice, acquisition once, finish once plus a temporary hold read. Fresh publication adds its readback and writer. Verify explicit closes before observer recovery and preserve every other owner.',
        mutants_contract='Skip one actual lock, first structural reference, or first structure-directory close while reporting success. Exact per-path counts and independent retained-handle custody must expose precisely that open handle, then observer recovery closes it before fixture removal. Do not omit another guard or rewrite a prototype.',
        limits='Finite inert coordinator call-boundary cuts only. No complete semantic-census internal matrix, every syscall failure, asynchronous crash, ordinary lexical-cleanup leak, native process ownership, archive/capture settlement, exact release, product activation or historical startup repair is established.')


if __name__ == '__main__':
    Path(__file__).with_name('plan.json').write_text(json.dumps(build(), sort_keys=True, indent=2)+'\n')
