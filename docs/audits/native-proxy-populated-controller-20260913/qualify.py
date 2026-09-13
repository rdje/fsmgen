"""No-process lifecycle qualification with rejecting state/source controls."""
import argparse
from dataclasses import replace
import hashlib
import json
from pathlib import Path
import signal
from types import SimpleNamespace
from unittest.mock import patch

import controller as c

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LIMITS = c.Limits(256, 128, 8, 128, 0.2, 0.2)
PIN = dict(size_bytes=1, sha256='a' * 64)
SPEC = c.Spawn(ROOT, 'docs/qualification-model.pl', ('case', 'role'),
               ROOT / 'model-invocation', ROOT / 'model-native', PIN, PIN,
               {'docs/qualification-model.pl': PIN},
               dict(stdout='.artifacts/logs/model.stdout', stderr='.artifacts/logs/model.stderr'),
               frozenset(('ready', 'step', 'finished')), frozenset(('admit', 'release')))
IDENTITY = dict(pid=123, start_sec=1, start_usec=2, uid=501, ruid=501, ppid=1)


def event(name, **fields):
    return (json.dumps(dict(event=name, pid=123, **fields), sort_keys=True, separators=(',', ':')) + '\n').encode()


class Stream:
    def __init__(self, fd):
        self.fd, self.closed, self.closes = fd, False, 0
        self.close_error = False

    def fileno(self):
        assert not self.closed
        return self.fd

    def close(self):
        self.closes += 1
        assert self.closes == 1
        if self.close_error:
            raise OSError('model stream close failed')
        self.closed = True


class Process:
    def __init__(self):
        self.pid = 123
        self.stdin, self.stdout, self.stderr = Stream(0), Stream(3), Stream(4)
        self.code, self.waits, self.signals = None, 0, []
        self.term_works, self.kill_works = True, True
        self.signal_error, self.wait_error = False, False

    def poll(self):
        return self.code

    def send_signal(self, number):
        assert self.code is None, 'terminal child must not be signaled'
        self.signals.append(number)
        if self.signal_error:
            raise OSError('model signaling failed')
        if (number == signal.SIGTERM and self.term_works) or (number == signal.SIGKILL and self.kill_works):
            self.code = -number

    def wait(self, timeout):
        assert timeout == 0 and self.code is not None
        self.waits += 1
        assert self.waits == 1
        if self.wait_error:
            raise OSError('model wait failed')
        return self.code


class System:
    def __init__(self, chunks=None):
        self.process = Process()
        self.chunks = {3: list((chunks or {}).get(3, [b''])), 4: list((chunks or {}).get(4, [b'']))}
        self.opened, self.closed, self.writes = [], [], {0: bytearray(), 11: bytearray(), 12: bytearray()}
        self.clock, self.spawn_calls, self.group_checks = 0.0, 0, 0
        self.fail_owner = self.fail_open = self.fail_spawn = self.fail_identity = False
        self.fail_nonblocking, self.fail_write, self.fail_read, self.fail_close = set(), set(), set(), set()
        self.short_write, self.stale, self.identity_changed = False, set(), False
        self.gone, self.group_error, self.signal_on_read = True, False, False

    def now(self):
        self.clock += 0.01
        return self.clock

    def pause(self, seconds):
        self.clock += seconds

    def check_owner(self):
        if self.fail_owner:
            raise ValueError('model owner rejected')

    def pin(self, path, limit):
        return dict(PIN, sha256='b' * 64) if path in self.stale else dict(PIN)

    def open_capture(self, root, relative):
        if self.fail_open and self.opened:
            raise OSError('second capture open failed')
        descriptor = 11 + len(self.opened)
        self.opened.append(descriptor)
        return descriptor

    def spawn(self, spec):
        self.spawn_calls += 1
        if self.fail_spawn:
            raise OSError('model Popen failed')
        return self.process

    def nonblocking(self, stream):
        if stream.fd in self.fail_nonblocking:
            raise OSError('model nonblocking setup failed')

    def ownership(self, reader, process):
        if self.fail_identity:
            raise ValueError('model native identity admission failed')
        return dict(IDENTITY, start_usec=3 if self.identity_changed else 2)

    def read(self, descriptor, limit):
        assert limit == 4096
        if descriptor in self.fail_read:
            raise OSError('model pipe read failed')
        if not self.chunks[descriptor]:
            raise BlockingIOError()
        return self.chunks[descriptor].pop(0)

    def write(self, descriptor, body):
        if descriptor in self.fail_write:
            raise OSError('model capture write failed')
        count = max(1, len(body) // 2) if self.short_write else len(body)
        self.writes[descriptor].extend(body[:count])
        return count

    def close(self, descriptor):
        assert descriptor not in self.closed
        self.closed.append(descriptor)
        if descriptor in self.fail_close:
            raise OSError('model descriptor close failed')

    def group_gone(self, pid):
        assert pid == 123
        self.group_checks += 1
        if self.group_error:
            raise PermissionError('model group absence unavailable')
        return self.gone


def model(chunks=None, **settings):
    system = System(chunks)
    for key, value in settings.items():
        setattr(system, key, value)
    rows = []
    reader = SimpleNamespace(executable=lambda pid: SPEC.native_image)
    worker = c.Worker(SPEC, LIMITS, reader, lambda name, **fields: rows.append(dict(event=name, **fields)), 20, system)
    return worker, system, rows


def failure(call, kind=Exception, contains=None):
    try:
        call()
    except kind as error:
        if contains:
            assert contains in str(error), str(error)
        return error
    raise AssertionError('expected rejection did not occur')


def consumed(worker, system, result, healthy=False, complete=True):
    assert result['healthy'] is healthy and result['cleanup_complete'] is complete
    assert not worker.streams and not worker.captures
    if result['launched'] and result['leader_reaped']:
        assert system.process.waits == 1
    if complete:
        assert set(system.closed) == set(system.opened)
        assert system.process.stdin.closed or not result['launched']
    assert result['first_failure'] is None if healthy else result['first_failure'] is not None


def terminal_regression():
    worker, system, rows = model({3: [b'failed before ready\n', b''], 4: [b'']}, fail_identity=True)
    system.process.code = 0
    error = failure(worker.launch, ValueError, 'native identity')
    first = dict(worker.first_failure)
    result = worker.recover(error)
    consumed(worker, system, result)
    assert result['first_failure'] == first and not result['native_admitted']
    assert result['output_complete'] and system.writes[11] == b'failed before ready\n'
    assert system.process.signals == result['signals'] == [] and worker.eof == {'stdout', 'stderr'}
    assert not worker.events and result['separate_recovery']
    assert all(stream.closed for stream in (system.process.stdin, system.process.stdout, system.process.stderr))
    assert worker.recover() is result and system.process.waits == 1
    return result


def qualify():
    checks = []
    regression = terminal_regression()
    checks.append('terminal_unadmitted_undrained_consumes_original_failure_without_signal')

    worker, system, _ = model({3: [event('ready')[:9], event('ready')[9:], event('finished'), b''], 4: [b'']})
    worker.launch()
    for _ in range(4):
        worker.pump()
    system.process.code = 0
    result = worker.finish()
    consumed(worker, system, result, healthy=True)
    assert result['output_complete'] and result['native_admitted'] and not result['separate_recovery']
    failure(worker.finish, ValueError, 'twice')
    checks.append('fragmented_ready_native_image_and_normal_terminal_outcome')

    for field in ('fail_owner', 'fail_open', 'fail_spawn'):
        worker, system, _ = model(**{field: True})
        failure(worker.launch)
        first = dict(worker.first_failure)
        result = worker.recover()
        consumed(worker, system, result)
        assert result['first_failure'] == first and not result['launched']
        assert system.spawn_calls == (1 if field == 'fail_spawn' else 0)
        failure(worker.launch, ValueError, 'repeated')
        checks.append(field + '_closes_partial_resources_without_launch_retry')

    for path in (SPEC.root / SPEC.script, SPEC.invocation, SPEC.native_image):
        worker, system, _ = model(stale={path})
        failure(worker.launch, ValueError, 'differs')
        consumed(worker, system, worker.recover())
        assert not system.opened and system.spawn_calls == 0
        checks.append('stale_' + path.name + '_blocks_before_resources')

    for stop, term_works in (('term', True), ('kill', False)):
        worker, system, _ = model(fail_identity=True)
        system.process.term_works = term_works
        failure(worker.launch, ValueError)
        result = worker.recover()
        consumed(worker, system, result)
        assert system.process.signals == ([signal.SIGTERM] if term_works else [signal.SIGTERM, signal.SIGKILL])
        assert result['output_complete'] and not result['native_admitted'] and result['separate_recovery']
        checks.append('live_unadmitted_direct_child_' + stop + '_recovery')

    worker, system, _ = model(fail_nonblocking={3})
    failure(worker.launch, OSError)
    system.fail_nonblocking.clear()
    result = worker.recover()
    consumed(worker, system, result)
    assert result['output_complete'] and result['first_failure']['phase'] == 'launch'
    checks.append('partial_pipe_setup_recovers_owned_pipes_and_original_failure')

    for setting in ('fail_nonblocking', 'fail_read'):
        worker, system, _ = model(**{setting: {3}})
        if setting == 'fail_nonblocking':
            failure(worker.launch)
        else:
            worker.launch()
            failure(worker.pump)
        result = worker.recover()
        consumed(worker, system, result)
        assert not result['output_complete'] and result['abandoned'] == ['stdout']
        checks.append(setting + '_persistent_output_loss_explicit_and_child_settled')

    for label, body, expected in (
        ('invalid_json', b'{invalid}\n', 'capture_or_event'),
        ('noncanonical', b'{"pid":123, "event":"ready"}\n', 'capture_or_event'),
        ('partial', b'{"event":', 'finish'),
        ('overlong', b'x' * LIMITS.event_bytes, 'capture_or_event'),
        ('foreign', event('ready', marker='x').replace(b'123', b'124'), 'capture_or_event'),
        ('before_ready', event('step'), 'capture_or_event'),
    ):
        worker, system, _ = model({3: [body, b'raw recovery tail', b''], 4: [b'']})
        worker.launch()
        if label == 'partial':
            worker.pump()
            # Finish is separately checked once terminal EOF arrives.
            system.chunks[3] = [b'']
            worker.pump()
            system.process.code = 0
            failure(worker.finish)
        else:
            failure(worker.pump)
        first = dict(worker.first_failure)
        result = worker.recover()
        consumed(worker, system, result)
        assert result['first_failure'] == first and first['phase'] == expected
        assert bytes(system.writes[11]).startswith(body) and result['separate_recovery']
        checks.append(label + '_preserved_without_reentering_parser')

    worker, system, _ = model({3: [b''], 4: [b'x' * 300, b'y' * 20, b'']})
    worker.launch()
    failure(worker.pump, ValueError, 'aggregate')
    result = worker.recover()
    consumed(worker, system, result)
    assert len(system.writes[12]) == 257 and result['discarded'] == dict(stdout=0, stderr=63)
    assert result['retained_prefixes']['stderr']['size_bytes'] == 257
    checks.append('aggregate_overflow_keeps_prefix_first_overflow_byte_and_discard_count')

    worker, system, _ = model({3: [event('ready'), event('step'), b''], 4: [b'']}, fail_write={11})
    worker.launch()
    failure(worker.pump, OSError)
    result = worker.recover()
    consumed(worker, system, result)
    assert result['failed_captures'] == ['stdout'] and not result['output_complete']
    assert bytes.fromhex(result['failed_capture_prefixes']['stdout']) == event('ready') + event('step')
    checks.append('capture_write_failure_retains_bounded_memory_prefix_and_drains')

    worker, system, _ = model({3: [event('ready'), b''], 4: [b'']}, short_write=True)
    worker.launch(); worker.pump()
    assert bytes(system.writes[11]) == event('ready')
    failure(lambda: worker.send('admit'), OSError, 'never retry')
    before = bytes(system.writes[0])
    failure(lambda: worker.send('admit'), ValueError, 'healthy')
    assert bytes(system.writes[0]) == before
    consumed(worker, system, worker.recover())
    checks.append('capture_partial_writes_complete_but_partial_command_is_never_retried')

    for label in ('duplicate_ready', 'birth_changed', 'path_changed', 'image_changed', 'post_finished', 'event_count'):
        worker, system, _ = model()
        worker.launch()
        if label == 'birth_changed':
            system.identity_changed = True
        elif label == 'path_changed':
            worker.reader.executable = lambda pid: SPEC.invocation
        elif label == 'image_changed':
            system.stale.add(SPEC.native_image)
        else:
            worker.observe(dict(event='ready', pid=123))
        if label == 'post_finished':
            worker.observe(dict(event='finished', pid=123))
        elif label == 'event_count':
            for _ in range(LIMITS.events - 1):
                worker.observe(dict(event='step', pid=123))
        failure(lambda: worker.observe(dict(event='ready' if label != 'event_count' else 'step', pid=123)))
        consumed(worker, system, worker.recover(ValueError(label)))
        checks.append(label + '_rejects')

    for label in ('before_admission', 'unknown', 'oversize', 'deadline', 'after_finished'):
        worker, system, _ = model()
        worker.launch()
        if label != 'before_admission':
            worker.observe(dict(event='ready', pid=123))
        if label == 'deadline':
            system.clock = 21
        elif label == 'after_finished':
            worker.observe(dict(event='finished', pid=123))
        failure(lambda: worker.send('unknown' if label == 'unknown' else 'admit', 'x' * 256 if label == 'oversize' else None))
        assert not system.writes[0]
        consumed(worker, system, worker.recover())
        checks.append('command_' + label + '_rejects_without_write')

    worker, system, _ = model()
    worker.launch(); system.clock = 21
    failure(worker.pump, TimeoutError)
    consumed(worker, system, worker.recover())
    checks.append('deadline_requires_bounded_separate_recovery')

    for label in ('stdin', 'stdout', 'capture'):
        worker, system, _ = model()
        worker.launch()
        if label == 'capture':
            system.fail_close.add(11)
        else:
            getattr(system.process, label).close_error = True
        error = failure(worker.recover, c.RecoveryIncomplete)
        consumed(worker, system, error.outcome, complete=False)
        assert error.outcome['cleanup_errors'] and set(system.closed) == {11, 12}
        assert system.process.stderr.closed and system.process.waits == 1
        failure(worker.recover, c.RecoveryIncomplete)
        checks.append(label + '_close_failure_attempts_other_resources_and_stays_unresolved')

    for label in ('group_live', 'group_query', 'wait', 'signal', 'unkillable'):
        worker, system, _ = model()
        worker.launch()
        if label == 'group_live': system.gone = False
        elif label == 'group_query': system.group_error = True
        elif label == 'wait': system.process.wait_error = True
        elif label == 'signal': system.process.signal_error = True
        else: system.process.term_works = system.process.kill_works = False
        error = failure(worker.recover, c.RecoveryIncomplete)
        consumed(worker, system, error.outcome, complete=False)
        assert not error.outcome['healthy'] and system.clock < 2
        if label in ('signal', 'unkillable'):
            assert not error.outcome['leader_reaped'] and system.process.waits == 0
        checks.append(label + '_cannot_be_promoted_to_settled')

    for phase in ('launch', 'capture', 'consumption'):
        worker, system, _ = model({3: [event('ready'), b''], 4: [b'']})
        def bad_journal(*args, **kwargs): raise OSError('model journal failure')
        if phase == 'launch':
            worker.journal = bad_journal
            failure(worker.launch)
        else:
            worker.launch()
            worker.journal = bad_journal
            if phase == 'capture': failure(worker.pump)
        result = worker.recover()
        consumed(worker, system, result)
        assert not result['journal_complete'] and result['first_failure'] is not None
        checks.append('journal_' + phase + '_failure_does_not_interrupt_cleanup')

    worker, system, _ = model()
    worker.launch()
    worker.observe(dict(event='ready', pid=123))
    result = worker.recover(RuntimeError('planned cancellation'))
    consumed(worker, system, result)
    assert result['native_admitted'] and result['separate_recovery']
    assert result['first_failure']['message'] == 'planned cancellation'
    checks.append('admitted_cancellation_remains_separate_recovery')

    worker, system, _ = model(fail_identity=True)
    system.process.code = 7
    failure(worker.launch)
    worker.pump(recovery=True)
    assert not worker.streams
    result = worker.recover()
    consumed(worker, system, result)
    assert result['exit_code'] == 7 and not system.process.signals
    checks.append('already_drained_unadmitted_terminal_child_needs_no_signal')

    system = c.System()
    expected_environment = dict(PATH=c.os.defpath, LC_ALL='C', LANG='C', TMPDIR=str(ROOT / '.artifacts/tmp'))
    with patch.object(c.subprocess, 'Popen', return_value='model-child') as spawn:
        assert system.spawn(SPEC) == 'model-child'
        spawn.assert_called_once_with(
            [str(SPEC.invocation), str(ROOT / SPEC.script), 'case', 'role'],
            cwd=ROOT, env=expected_environment, stdin=c.subprocess.PIPE,
            stdout=c.subprocess.PIPE, stderr=c.subprocess.PIPE,
            start_new_session=True, close_fds=True, bufsize=0)
    checks.append('production_spawn_has_exact_literal_argv_closed_environment_and_pipe_ownership')

    with patch.object(c.signal, 'getsignal', return_value=signal.SIG_IGN):
        failure(system.check_owner, ValueError, 'SIGCHLD')
    with patch.object(c.threading, 'current_thread', return_value=object()):
        failure(system.check_owner, ValueError, 'main-thread')
    checks.append('production_ownership_rejects_ignored_sigchld_and_other_threads')

    with patch.object(c.os, 'getuid', return_value=501), patch.object(c.os, 'getpid', return_value=1), \
         patch.object(c.os, 'getpgid', return_value=123), patch.object(c.os, 'getsid', return_value=123):
        reader = SimpleNamespace(identity=lambda pid: dict(IDENTITY))
        assert system.ownership(reader, SimpleNamespace(pid=123)) == IDENTITY
        for key in ('pid', 'uid', 'ruid', 'ppid'):
            reader.identity = lambda pid, key=key: dict(IDENTITY, **{key: 999})
            failure(lambda: system.ownership(reader, SimpleNamespace(pid=123)), ValueError, 'ownership')
        reader.identity = lambda pid: dict(IDENTITY)
        for method in ('getpgid', 'getsid'):
            with patch.object(c.os, method, return_value=999):
                failure(lambda: system.ownership(reader, SimpleNamespace(pid=123)), ValueError, 'ownership')
    checks.append('production_native_identity_rejects_foreign_child_uid_parent_group_and_session')

    for value in (0, -1, True, 1.5):
        failure(lambda value=value: replace(LIMITS, output_bytes=value), ValueError)
    for value in (0, -1, float('nan'), float('inf')):
        failure(lambda value=value: replace(LIMITS, term_seconds=value), ValueError)
    failure(lambda: replace(LIMITS, event_bytes=257), ValueError)
    for path in ('/tmp/model', '../model', 'a/../model', './model'):
        failure(lambda path=path: replace(SPEC, script=path, sources={path: PIN}), ValueError)
    failure(lambda: replace(SPEC, captures=dict(stdout='.artifacts/logs/x', stderr='.artifacts/logs/x')), ValueError)
    checks.append('configuration_rejects_invalid_bounds_aliases_escapes_and_shared_capture')

    original = c.Worker.recover
    def broken(self, cause=None):
        if self.process is not None and not self.finished() and self.native is None:
            raise ValueError('restored inherited terminal/native coupling')
        return original(self, cause)
    with patch.object(c.Worker, 'recover', broken):
        failure(terminal_regression, ValueError, 'restored inherited')
    checks.append('restored_inherited_recovery_coupling_is_falsified_by_regression')
    assert len(checks) == len(set(checks))
    return dict(checks=checks, terminal_regression=regression,
                actual_worker_execution=False, actual_fixture_allocation=False,
                actual_signals=False, group_absence_in_models_is_assumed=True,
                no_process_models_do_not_grant_execution_admission=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-saved', action='store_true')
    args = parser.parse_args()
    def forbidden(*args, **kwargs): raise AssertionError('qualification attempted a real process or signal')
    with patch.object(c.subprocess, 'Popen', forbidden), patch.object(c.os, 'fork', forbidden), \
         patch.object(c.os, 'kill', forbidden), patch.object(c.os, 'killpg', forbidden):
        result = qualify()
    if args.verify_saved:
        assert result == json.loads((BASE / 'qualification.json').read_bytes())
    else:
        with (BASE / 'qualification.json').open('x') as stream:
            json.dump(result, stream, sort_keys=True, indent=2); stream.write('\n')
    print(json.dumps(dict(checks=len(result['checks']), actual_worker_execution=False,
                          terminal_regression_recovered=True), sort_keys=True))


if __name__ == '__main__':
    main()
