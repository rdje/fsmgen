"""Check the recovery diagnosis against adjacent states, using only test doubles."""
import hashlib
import json
from contextlib import ExitStack
from pathlib import Path
from unittest.mock import patch

import reproduce_recovery as first


def control(drained, admitted):
    payload = b'failed before ready\n'
    worker = first.model.make_worker([] if drained else [(3, payload), (3, b''), (4, b'')])
    worker.native = {} if admitted else None
    if drained:
        worker.selector.active.clear()
    writes, closed, signals = [], [], []

    def no_signal(*args):
        signals.append(args)
        raise AssertionError('a terminal model child must not receive a signal')

    def saved_pin(path, limit):
        descriptor = 11 if path.endswith('.stdout') else 12
        raw = b''.join(body for fd, body in writes if fd == descriptor)
        assert len(raw) <= limit
        return dict(path=path, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())

    with ExitStack() as stack:
        replacements = [(first.model.runtime, 'group_gone', lambda group: group == 123),
                        (first.model.runtime, 'write_all', lambda fd, raw: writes.append((fd, raw))),
                        (first.model.runtime, 'pin', saved_pin),
                        (first.model.runtime.os, 'read', worker.selector.read),
                        (first.model.runtime.os, 'close', closed.append),
                        (first.model.runtime.os, 'killpg', no_signal),
                        (first.model.runtime.os, 'kill', no_signal),
                        (first.model.runtime.subprocess, 'Popen', no_signal)]
        for target, name, replacement in replacements:
            stack.enter_context(patch.object(target, name, replacement))
        worker.recover()
    assert worker.closed and worker.reaped and worker.process.stdin.closed
    assert not worker.selector.active and not worker.selector.chunks
    assert sorted(closed) == [11, 12] and not signals
    assert worker.journal_rows[-1]['event'] == 'reaped'
    assert worker.journal_rows[-1]['separate_recovery'] is True
    assert b''.join(raw for fd, raw in writes if fd == 11) == (b'' if drained else payload)
    return dict(initial_streams_drained=drained, native_admission_modeled=admitted,
                recovered=True, terminal_result_consumed=True, signal_operations=0,
                group_absence='test-double assumption, not a kernel observation')


if __name__ == '__main__':
    saved = json.loads((Path(__file__).parent / 'recovery-first.json').read_bytes())
    assert saved['result']['defect_reproduced'] and not saved['result']['recovery_complete']
    results = [control(drained=True, admitted=False), control(drained=False, admitted=True)]
    print(json.dumps(dict(controls=results, original_defect_retained=True,
                         worker_invocations=0, fixture_allocations=0), sort_keys=True))
