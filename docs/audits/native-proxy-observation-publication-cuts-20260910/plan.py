"""Prospective publication failure/cleanup transitions independent of Perl hooks."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('publication_snapshot_plan',
    BASE.parent/'native-proxy-observation-snapshot-cuts-20260910/plan.py')
SNAPSHOT = importlib.util.module_from_spec(spec)
spec.loader.exec_module(SNAPSHOT)
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.3.2.2.2.2.1'
REVISION = '5bb1b2366cc652416283d8959d12a9d44616498c'
PREFIX = ['publication:enter','publication:byte_mode','publication:get_flags','publication:set_flags',
    'publication:write:1','publication:readback','publication:readcheck','publication:before_seal',
    'publication:after_seal']
CLOSE = ['publication:reader_close','publication:writer_close']


def publication_events(fault: str) -> list[str]:
    if fault == 'before_open': return PREFIX[:1]
    if fault in ('byte_mode','get_flags','set_flags'):
        return PREFIX[:PREFIX.index('publication:'+fault)+1]+CLOSE[1:]
    if fault in ('zero_write','write_and_close_error'):
        return PREFIX[:5]+CLOSE[1:]
    if fault == 'partial_write':
        return PREFIX[:5]+['publication:write:2']+CLOSE[1:]
    if fault == 'readback': return PREFIX[:6]+CLOSE[1:]
    if fault in ('readcheck','readcheck_and_close_error'):
        return PREFIX[:7]+CLOSE
    if fault == 'before_seal': return PREFIX[:8]+CLOSE
    if fault in ('after_seal','reader_close_error','writer_close_error','both_close_error'):
        return PREFIX+CLOSE
    return PREFIX+CLOSE+['publication:return']


def build() -> dict:
    fault_rows = [
        ('complete','complete',''),
        ('before_open','absent','injected observation publication before_open'),
        ('byte_mode','empty','cannot select canonical byte mode'),
        ('get_flags','empty','cannot read canonical writer flags'),
        ('set_flags','empty','cannot seal canonical writer inheritance'),
        ('zero_write','empty','cannot write complete canonical bytes'),
        ('partial_write','partial','cannot write complete canonical bytes'),
        ('readback','complete','injected observation publication readback'),
        ('readcheck','complete','injected observation publication readcheck'),
        ('before_seal','complete','injected observation publication before_seal'),
        ('after_seal','complete','injected observation publication after_seal'),
        ('after_return','complete','injected observation publication after_return'),
        ('reader_close_error','complete','cannot close canonical reader'),
        ('writer_close_error','complete','cannot close canonical writer'),
        ('both_close_error','complete','cannot close canonical reader'),
        ('write_and_close_error','empty','cannot write complete canonical bytes'),
        ('readcheck_and_close_error','complete','injected observation publication readcheck'),
    ]
    snapshot = SNAPSHOT.trace('fresh')
    position = snapshot.index('finish:enter')
    prefix, suffix = snapshot[:position],snapshot[position:]
    cases = []
    for fault,state,diagnostic in fault_rows:
        returns = fault == 'complete'
        events = prefix+publication_events(fault)+(suffix if returns else [])
        cases.append(dict(id='fresh:'+fault,route='fresh',fault=fault,hold=state,
            returns=returns,diagnostic=diagnostic,trace=events))
    cases.append(dict(id='reuse:complete',route='reuse',fault='complete',hold='complete',
        returns=True,diagnostic='',trace=SNAPSHOT.trace('reuse')))
    mutants = [dict(id='fresh:'+fault,route='fresh',fault=fault,hold='complete',returns=True,
        diagnostic='',trace=prefix+publication_events(fault)+suffix)
        for fault in ('omit_reader_close','omit_writer_close')]
    return dict(schema='fsmgen.inactive_observation_publication_cut_plan.v1',owner=OWNER,
        source_revision=REVISION,partial_write_bytes=8,cases=cases,mutants=mutants,
        fixture='Reuse the qualified inert snapshot fixture: four immediately recorded private same-volume roots, two runtime owners on distinct original inert images, and an independently seeded other-image observation owner. Reuse starts with exact original primary acquisition. No compiler/process/native query/helper/archive/release/retry or product activation.',
        trace='Independently enumerate normal source/directory admission, publication calls and actual cleanup-call sequence. Failures before publication return never run postpublication census or finish. A publication:return exception follows explicit reader/writer closure and carries no unowned handle. Caller-sealed observation wrappers tail-goto originals. Readback faults occur before invoking the reader; recheck/seal faults occur only after source ownership transfers into publication cleanup.',
        descriptors='Retain independent aliases to all successfully returned source handles, the writer at byte-mode entry and the permanent existing lock. Before publication the pre-census and completed observation reads contribute exactly 44 sources; add one successful writer readback when reached. Healthy full fresh/reuse routes retain the predecessor 83/89-source multiset. Every correct route closes all observed handles; omitted reader/writer close mutants expose precisely the actual unclosed publication descriptor, which the observer explicitly recovers.',
        cleanup='Reported close failures perform the real close first and return failure with EIO. They qualify diagnostic precedence and actual closure, not a claim about every operating-system close ambiguity. Ordinary error controls preserve their first cause when writer or both publication closes also report failure. Omitted-close mutants deliberately return success without closing so the observer can detect reliance on lexical destruction.',
        bytes='Only the fresh primary hold may be added: no file before exclusive open, zero bytes on prewrite failure, exactly the first eight canonical bytes after a real short write followed by EIO, or the complete canonical record after a full write. All admitted observation payloads remain mode 0400, even when sealing is interrupted; another owner is never rewritten or dropped. Reuse makes no publication call.',
        limits='Finite synchronous publication and close-report controls only. Coordinator/census and retained-target/lock close-report cuts and final matrix join remain separately owned. Lower-reader prehandoff failure, asynchronous crash durability, actual process ownership, archive/capture settlement, exact release, contention and native activation are not established.')


if __name__ == '__main__':
    Path(__file__).with_name('plan.json').write_text(json.dumps(build(),sort_keys=True,indent=2)+'\n')
