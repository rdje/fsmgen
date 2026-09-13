"""Inject pipe/parser/termination states without allocating a fixture or process."""

import argparse
import json
import signal
from types import SimpleNamespace
from unittest.mock import patch

from contract import BASE, BOUNDS
import runtime


class Stream:
    def __init__(self, descriptor):
        self.descriptor = descriptor
        self.closed = False

    def fileno(self):
        return self.descriptor

    def close(self):
        assert not self.closed
        self.closed = True


class Selector:
    def __init__(self, chunks):
        self.chunks = list(chunks)
        self.streams = {3: Stream(3), 4: Stream(4)}
        self.active = set(self.streams)

    def select(self, timeout):
        if not self.chunks:
            return []
        descriptor, _ = self.chunks[0]
        assert descriptor in self.active
        return [(SimpleNamespace(fileobj=self.streams[descriptor],
                                 data='stdout' if descriptor == 3 else 'stderr'), 1)]

    def read(self, descriptor, limit):
        expected, body = self.chunks.pop(0)
        assert descriptor == expected and len(body) <= limit
        return body

    def unregister(self, stream):
        self.active.remove(stream.fileno())

    def get_map(self):
        return self.active

    def close(self):
        assert not self.active


def make_worker(chunks):
    worker = runtime.Worker.__new__(runtime.Worker)
    worker.buffers = dict(stdout=bytearray(), stderr=bytearray())
    worker.pending = bytearray()
    worker.events = []
    worker.captures = dict(stdout=11, stderr=12)
    worker.capture_paths = dict(stdout='synthetic.stdout', stderr='synthetic.stderr')
    worker.selector = Selector(chunks)
    worker.first_capture_error = None
    worker.discarded = dict(stdout=0, stderr=0)
    worker.key = 'synthetic'
    worker.reaped = worker.closed = False
    worker.signal_sent = None
    worker.process = SimpleNamespace(pid=123, poll=lambda: 0, wait=lambda timeout: 0, stdin=Stream(0))
    worker.journal_rows = []
    worker.journal = lambda event, **fields: worker.journal_rows.append(dict(event=event, **fields))
    worker.observe = worker.events.append
    return worker


def drain(worker):
    writes, closes = [], []

    def write(descriptor, body):
        assert descriptor in (11, 12)
        writes.append((descriptor, bytes(body)))
        return len(body)

    with patch.object(runtime.os, 'read', worker.selector.read), patch.object(runtime.os, 'write', write):
        first = None
        while worker.selector.chunks:
            try:
                worker.pump(recovery=first is not None)
            except ValueError as failure:
                assert first is None
                first = str(failure)
        assert not worker.selector.get_map()
    fake_pin = lambda path, limit: dict(path=path, size_bytes=0, sha256='0' * 64)
    with patch.object(runtime.os, 'close', closes.append), patch.object(runtime, 'group_gone', lambda pid: True), patch.object(runtime, 'pin', fake_pin):
        worker.reap(separate_recovery=first is not None or bool(worker.pending))
    assert closes == [11, 12] and worker.process.stdin.closed and worker.reaped
    assert all(stream.closed for stream in worker.selector.streams.values())
    return first, writes


def qualify():
    forbidden = lambda *args, **kwargs: (_ for _ in ()).throw(AssertionError('source/data qualification attempted a process or signal'))
    checks = []
    with patch.object(runtime.subprocess, 'Popen', forbidden), patch.object(runtime.os, 'fork', forbidden), patch.object(runtime.os, 'killpg', forbidden):
        event = dict(event='ready', pid=123)
        raw = (json.dumps(event, sort_keys=True, separators=(',', ':')) + '\n').encode()
        worker = make_worker([(3, raw[:7]), (3, raw[7:]), (3, b''), (4, b'')])
        error, writes = drain(worker)
        assert error is None and worker.events == [event]
        assert b''.join(body for descriptor, body in writes if descriptor == 11) == raw
        assert worker.journal_rows[-1]['separate_recovery'] is False
        checks.append('fragmented_valid_event_and_explicit_pipe_closure')

        worker = make_worker([(3, b'{invalid}\n'), (3, b'undecodable recovery tail'), (3, b''), (4, b'')])
        error, writes = drain(worker)
        assert error and error == worker.first_capture_error
        assert worker.events == [] and len([row for row in worker.journal_rows if row['event'] == 'capture_failed']) == 1
        assert b''.join(body for descriptor, body in writes if descriptor == 11) == b'{invalid}\nundecodable recovery tail'
        assert worker.journal_rows[-1]['separate_recovery'] is True
        checks.append('first_parser_error_preserved_while_recovery_drains')

        worker = make_worker([(3, b'{"event":'), (3, b''), (4, b'')])
        error, _ = drain(worker)
        assert error is None and worker.pending == b'{"event":'
        assert worker.journal_rows[-1]['separate_recovery'] is True
        checks.append('partial_terminal_event_requires_separate_recovery')

        payload = b'x' * (BOUNDS['worker_output_bytes'] + 4096)
        chunks = [(4, payload[offset:offset + 4096]) for offset in range(0, len(payload), 4096)] + [(4, b''), (3, b'')]
        worker = make_worker(chunks)
        error, writes = drain(worker)
        retained = b''.join(body for descriptor, body in writes if descriptor == 12)
        assert error == 'worker output exceeds admitted aggregate bound'
        assert len(retained) == BOUNDS['worker_output_bytes'] + 1
        assert retained == payload[:len(retained)]
        assert worker.discarded == dict(stdout=0, stderr=len(payload) - len(retained))
        checks.append('overflow_prefix_bounded_and_discard_count_explicit')

        worker = make_worker([(3, b' ' * BOUNDS['event_bytes']), (3, b''), (4, b'')])
        error, _ = drain(worker)
        assert error == 'unterminated event exceeds admitted byte bound'
        checks.append('unterminated_event_bound_fails_closed')

        worker = SimpleNamespace(reaped=False, signal_sent=None, step=0)
        worker.pump = lambda: setattr(worker, 'step', worker.step + 1)
        worker.finished = lambda: worker.step >= 3
        worker.seen = lambda name: worker.step >= 2
        # A leader may have exited while complete stdout is still buffered.
        worker.process = SimpleNamespace(poll=lambda: 0)
        with patch.object(runtime.time, 'monotonic', lambda: 0):
            runtime.until([worker], lambda: worker.step >= 3, 10)
        assert worker.step == 3
        checks.append('exit_does_not_skip_remaining_stdout')

        worker = runtime.Worker.__new__(runtime.Worker)
        worker.process = object()
        worker.reaped = False
        worker.terminated = False
        sent, reaped, clock = [], [], [0.0]
        worker.finished = lambda: worker.terminated
        worker.signal = lambda number: (sent.append(number), setattr(worker, 'terminated', number == signal.SIGKILL))
        worker.pump = lambda recovery: None
        worker.reap = lambda separate_recovery: reaped.append(separate_recovery)

        def now():
            clock[0] += 0.75
            return clock[0]

        with patch.object(runtime.time, 'monotonic', now):
            worker.recover()
        assert sent == [signal.SIGTERM, signal.SIGKILL] and reaped == [True]
        checks.append('bounded_term_then_kill_consumes_one_recovery_outcome')
    return dict(schema='fsmgen.language_coordination_runtime_data_review.v1', checks=checks,
                mocked_pipe_and_process_states=True, actual_worker_execution=False,
                actual_fixture_allocation=False, actual_signal_calls=False)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain', action='store_true')
    group.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    result = qualify()
    if args.retain:
        with (BASE / 'runtime-data-review.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2)
            stream.write('\n')
    else:
        assert result == json.loads((BASE / 'runtime-data-review.json').read_bytes())
    print(json.dumps(dict(checks=len(result['checks']), actual_worker_execution=False), sort_keys=True))


if __name__ == '__main__':
    main()
