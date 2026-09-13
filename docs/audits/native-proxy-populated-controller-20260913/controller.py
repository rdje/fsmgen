"""Single-child supervision for the prospective inert populated-store worker.

This module has no execution entrypoint. A future committed admission must bind
its Spawn, limits, source closure and native image before any real worker runs.
Only the main thread owns/waits for each Popen child; SIGCHLD stays default.
The fixed worker must not fork. A surviving group is unresolved custody, never
permission to signal a PID/group inferred from a previously reaped leader.
"""
from dataclasses import dataclass
import hashlib
import json
import math
import os
from pathlib import Path
import signal
import stat
import subprocess
import threading
import time


@dataclass(frozen=True)
class Limits:
    output_bytes: int
    event_bytes: int
    events: int
    command_bytes: int
    term_seconds: float
    kill_seconds: float

    def __post_init__(self):
        for value in (self.output_bytes, self.event_bytes, self.events, self.command_bytes):
            if type(value) is not int or value < 1:
                raise ValueError('limits require positive integers')
        if self.event_bytes > self.output_bytes:
            raise ValueError('event bound exceeds aggregate output bound')
        for value in (self.term_seconds, self.kill_seconds):
            if type(value) not in (int, float) or not math.isfinite(value) or value <= 0:
                raise ValueError('termination grace must be finite and positive')


@dataclass(frozen=True)
class Spawn:
    root: Path
    script: str
    arguments: tuple
    invocation: Path
    native_image: Path
    invocation_pin: dict
    native_pin: dict
    sources: dict
    captures: dict
    events: frozenset
    commands: frozenset

    def __post_init__(self):
        if not self.root.is_absolute() or not self.invocation.is_absolute() or not self.native_image.is_absolute():
            raise ValueError('runtime-derived root and installed paths must be absolute')
        if self.script not in self.sources or not {'ready', 'finished'} <= self.events:
            raise ValueError('script source and lifecycle events must be declared')
        if len(self.captures) != 2 or set(self.captures) != {'stdout', 'stderr'} or len(set(self.captures.values())) != 2:
            raise ValueError('distinct stdout/stderr capture paths required')
        for path in [self.script, *self.sources, *self.captures.values()]:
            pure = Path(path)
            if pure.is_absolute() or pure.as_posix() != path or '..' in pure.parts:
                raise ValueError('project paths must be canonical and root-relative')
        if any(not path.startswith('.artifacts/logs/') for path in self.captures.values()):
            raise ValueError('captures must be in admitted repository logs')
        if not all(isinstance(value, str) and '\0' not in value for value in self.arguments):
            raise ValueError('arguments must be literal strings')


def pin(path, limit):
    """Stable no-follow regular file bytes; selected inputs, not a dylib closure."""
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC)
    try:
        before = os.fstat(fd)
        if not stat.S_ISREG(before.st_mode) or before.st_size > limit:
            raise ValueError('input type or byte bound differs')
        body = bytearray()
        while len(body) <= limit:
            part = os.read(fd, min(65536, limit + 1 - len(body)))
            if not part:
                break
            body.extend(part)
        after = os.fstat(fd)
        identity = lambda item: (item.st_dev, item.st_ino, item.st_size, item.st_mtime_ns, item.st_ctime_ns)
        if len(body) > limit or len(body) != before.st_size or identity(before) != identity(after):
            raise ValueError('input changed during bounded read')
        return dict(size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())
    finally:
        os.close(fd)


class System:
    """OS operations separated so qualification never launches or signals a child."""
    now = staticmethod(time.monotonic)
    pause = staticmethod(time.sleep)
    pin = staticmethod(pin)
    read = staticmethod(os.read)
    write = staticmethod(os.write)
    close = staticmethod(os.close)

    def check_owner(self):
        if os.name != 'posix' or threading.current_thread() is not threading.main_thread():
            raise ValueError('POSIX main-thread child ownership required')
        if signal.getsignal(signal.SIGCHLD) != signal.SIG_DFL:
            raise ValueError('exclusive default SIGCHLD ownership required')

    def open_capture(self, root, relative):
        path = root / relative
        # Admission creates the parent; no implicit directories or aliases.
        current = root
        device = root.stat().st_dev
        for part in Path(relative).parts[:-1]:
            current = current / part
            info = current.lstat()
            if not stat.S_ISDIR(info.st_mode) or info.st_dev != device or info.st_uid != os.getuid():
                raise ValueError('capture parent ownership/type/volume differs')
        return os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC, 0o600)

    def spawn(self, spec):
        environment = dict(PATH=os.defpath, LC_ALL='C', LANG='C',
                           TMPDIR=str(spec.root / '.artifacts/tmp'))
        return subprocess.Popen([str(spec.invocation), str(spec.root / spec.script), *spec.arguments],
                                cwd=spec.root, env=environment, stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                start_new_session=True, close_fds=True, bufsize=0)

    def nonblocking(self, stream):
        os.set_blocking(stream.fileno(), False)

    def ownership(self, reader, process):
        value = reader.identity(process.pid)
        if (value['pid'] != process.pid or value['uid'] != os.getuid() or value['ruid'] != os.getuid()
                or value['ppid'] != os.getpid() or os.getpgid(process.pid) != process.pid
                or os.getsid(process.pid) != process.pid):
            raise ValueError('native child ownership differs')
        return value

    def group_gone(self, pid):
        try:
            os.killpg(pid, 0)
        except ProcessLookupError:
            return True
        return False


def birth(value):
    return tuple(value[key] for key in ('pid', 'start_sec', 'start_usec'))


class RecoveryIncomplete(RuntimeError):
    def __init__(self, outcome):
        super().__init__('child recovery is incomplete; preserved outcome requires action')
        self.outcome = outcome


class Worker:
    def __init__(self, spec, limits, reader, journal, deadline, system=None):
        self.spec, self.limits, self.reader, self.journal = spec, limits, reader, journal
        self.system = system if system is not None else System()
        if not math.isfinite(deadline):
            raise ValueError('finite absolute deadline required')
        self.deadline = deadline
        self.started = False
        self.process = self.native = self.outcome = self.first_failure = None
        self.native_admitted = False
        self.events, self.cleanup_errors, self.signals = [], [], []
        self.buffers = {channel: bytearray() for channel in ('stdout', 'stderr')}
        self.discarded = dict(stdout=0, stderr=0)
        self.captures, self.streams = {}, {}
        self.nonblocking, self.eof, self.abandoned, self.bad_captures = set(), set(), set(), set()
        self.pending = bytearray()
        self.journal_failed = False
        self.waited = False

    def fail(self, phase, error):
        if self.first_failure is None:
            self.first_failure = dict(phase=phase, type=type(error).__name__, message=str(error))

    def emit(self, event, recovery=False, **fields):
        if self.journal_failed:
            return
        try:
            self.journal(event, **fields)
        except Exception as error:
            self.journal_failed = True
            self.fail('journal', error)
            if not recovery:
                raise

    def launch(self):
        if self.started:
            raise ValueError('worker launch cannot be repeated')
        self.started = True
        try:
            self.system.check_owner()
            if self.system.now() >= self.deadline:
                raise TimeoutError('worker deadline expired before launch')
            for relative, expected in self.spec.sources.items():
                if self.system.pin(self.spec.root / relative, expected['size_bytes']) != expected:
                    raise ValueError('worker source differs from admission')
            if self.system.pin(self.spec.invocation, self.spec.invocation_pin['size_bytes']) != self.spec.invocation_pin:
                raise ValueError('interpreter invocation differs before launch')
            if self.system.pin(self.spec.native_image, self.spec.native_pin['size_bytes']) != self.spec.native_pin:
                raise ValueError('selected native image differs before launch')
            for channel, relative in self.spec.captures.items():
                self.captures[channel] = self.system.open_capture(self.spec.root, relative)
            self.emit('launch_intent', script=self.spec.script, arguments=list(self.spec.arguments))
            self.process = self.system.spawn(self.spec)
            # Take custody of every returned pipe before any fallible setup.
            self.streams = {channel: getattr(self.process, channel) for channel in self.buffers}
            self.emit('launched', pid=self.process.pid)
            for channel, stream in self.streams.items():
                self.system.nonblocking(stream)
                self.nonblocking.add(channel)
            self.system.nonblocking(self.process.stdin)
            self.native = self.system.ownership(self.reader, self.process)
            self.emit('native_owned', identity=self.native)
        except Exception as error:
            self.fail('launch', error)
            raise

    def observe(self, value):
        if not isinstance(value, dict) or type(value.get('pid')) is not int or value['pid'] != self.process.pid:
            raise ValueError('foreign or invalid event envelope')
        name = value.get('event')
        if name not in self.spec.events or len(self.events) >= self.limits.events:
            raise ValueError('undeclared event or event count exceeded')
        if self.events and self.events[-1]['event'] == 'finished':
            raise ValueError('event follows terminal worker outcome')
        if name == 'ready':
            if self.events or self.native is None:
                raise ValueError('ready precedes native ownership or is duplicated')
            current = self.system.ownership(self.reader, self.process)
            if birth(current) != birth(self.native):
                raise ValueError('native birth changed before ready')
            if self.reader.executable(self.process.pid) != self.spec.native_image:
                raise ValueError('native executable path differs')
            if self.system.pin(self.spec.native_image, self.spec.native_pin['size_bytes']) != self.spec.native_pin:
                raise ValueError('native executable bytes differ')
            self.native_admitted = True
            self.emit('native_admitted', identity=current, image=self.spec.native_pin)
        elif not self.native_admitted:
            raise ValueError('event precedes native admission')
        self.events.append(value)
        self.emit('worker_event', value=value)

    def _capture(self, channel, data):
        remaining = self.limits.output_bytes + 1 - sum(map(len, self.buffers.values()))
        retained = data[:max(0, remaining)]
        self.buffers[channel].extend(retained)
        self.discarded[channel] += len(data) - len(retained)
        if channel not in self.bad_captures:
            try:
                view = memoryview(retained)
                while view:
                    count = self.system.write(self.captures[channel], view)
                    if count <= 0 or count > len(view):
                        raise OSError('invalid capture write length')
                    view = view[count:]
            except Exception:
                self.bad_captures.add(channel)
                raise
        if sum(map(len, self.buffers.values())) > self.limits.output_bytes:
            raise ValueError('aggregate worker output exceeded')

    def _parse(self, data):
        self.pending.extend(data)
        while b'\n' in self.pending:
            line, _, tail = self.pending.partition(b'\n')
            self.pending[:] = tail
            if len(line) + 1 > self.limits.event_bytes:
                raise ValueError('worker event byte bound exceeded')
            value = json.loads(line)
            if json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False).encode() != line:
                raise ValueError('worker event is not canonical JSON')
            self.observe(value)
        if len(self.pending) >= self.limits.event_bytes:
            raise ValueError('unterminated event byte bound exceeded')

    def _close_stream(self, channel):
        stream = self.streams.pop(channel)
        try:
            stream.close()
        except Exception as error:
            self.cleanup_errors.append(dict(phase='close_pipe', channel=channel, error=str(error)))
            self.fail('close_pipe', error)

    def pump(self, recovery=False):
        if not recovery:
            if self.first_failure is not None:
                raise ValueError('failed worker requires separate recovery')
            if self.system.now() >= self.deadline:
                error = TimeoutError('worker deadline expired')
                self.fail('deadline', error)
                raise error
        progress = False
        for channel, stream in list(self.streams.items()):
            try:
                if channel not in self.nonblocking:
                    self.system.nonblocking(stream)
                    self.nonblocking.add(channel)
                data = self.system.read(stream.fileno(), 4096)
            except BlockingIOError:
                continue
            except Exception as error:
                self.fail('pipe_read', error)
                if not recovery:
                    raise
                self.abandoned.add(channel)
                self._close_stream(channel)
                continue
            progress = True
            if not data:
                self.eof.add(channel)
                self._close_stream(channel)
                if self.first_failure is not None and not recovery:
                    raise OSError('pipe close failed')
                continue
            try:
                self._capture(channel, data)
                if channel == 'stdout' and not recovery:
                    self._parse(data)
            except Exception as error:
                self.fail('capture_or_event', error)
                if not recovery:
                    raise
        if not progress:
            self.system.pause(0.005)

    def send(self, name, payload=None):
        try:
            if self.system.now() >= self.deadline:
                raise TimeoutError('command deadline expired')
            if self.events and self.events[-1]['event'] == 'finished':
                raise ValueError('command follows terminal worker event')
            if self.first_failure is not None or not self.native_admitted or self.process.poll() is not None:
                raise ValueError('command requires a live admitted healthy worker')
            if name not in self.spec.commands:
                raise ValueError('undeclared command')
            body = (json.dumps(dict(command=name, payload=payload), sort_keys=True,
                               separators=(',', ':'), allow_nan=False) + '\n').encode()
            if len(body) > self.limits.command_bytes:
                raise ValueError('command byte bound exceeded')
            self.emit('command', command=name)
            if self.system.write(self.process.stdin.fileno(), body) != len(body):
                raise OSError('command write incomplete; never retry a command')
        except Exception as error:
            self.fail('command', error)
            raise

    def finished(self):
        return self.process is not None and self.process.poll() is not None and not self.streams

    def _close_resources(self):
        for channel in list(self.streams):
            self.abandoned.add(channel)
            self._close_stream(channel)
        if self.process is not None and not self.process.stdin.closed:
            try:
                self.process.stdin.close()
            except Exception as error:
                self.cleanup_errors.append(dict(phase='close_stdin', error=str(error)))
                self.fail('close_stdin', error)
        for channel, descriptor in list(self.captures.items()):
            del self.captures[channel]
            try:
                self.system.close(descriptor)
            except Exception as error:
                self.cleanup_errors.append(dict(phase='close_capture', channel=channel,
                                                descriptor=descriptor, error=str(error)))
                self.fail('close_capture', error)

    def _consume(self, recovery):
        if self.outcome is not None:
            raise ValueError('worker outcome consumed twice')
        terminal = self.process is None or self.process.poll() is not None
        code, gone = None, self.process is None
        if self.process is not None and terminal:
            try:
                code = self.process.wait(timeout=0)
                self.waited = True
                gone = self.system.group_gone(self.process.pid)
            except Exception as error:
                self.fail('terminal_receipt', error)
                self.cleanup_errors.append(dict(phase='terminal_receipt', error=str(error)))
        self._close_resources()
        if not terminal or not gone:
            self.fail('settlement', RuntimeError('child or group remains unresolved'))
        complete = terminal and gone and not self.cleanup_errors
        self.emit('consumed', recovery=True, separate_recovery=recovery, exit_code=code,
                  leader_reaped=self.waited, group_gone=gone, cleanup_complete=complete)
        self.outcome = dict(exit_code=code, launched=self.process is not None,
                            leader_reaped=self.waited, group_gone=gone,
                            separate_recovery=recovery, native_admitted=self.native_admitted,
                            first_failure=self.first_failure, cleanup_errors=list(self.cleanup_errors),
                            cleanup_complete=complete, journal_complete=not self.journal_failed,
                            output_complete=self.eof == {'stdout', 'stderr'} and not self.abandoned and not self.bad_captures,
                            discarded=dict(self.discarded), signals=list(self.signals),
                            eof=sorted(self.eof), abandoned=sorted(self.abandoned),
                            failed_captures=sorted(self.bad_captures),
                            failed_capture_prefixes={name: self.buffers[name].hex() for name in sorted(self.bad_captures)},
                            healthy=not recovery and self.first_failure is None,
                            retained_prefixes={name: dict(size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest())
                                     for name, body in self.buffers.items()})
        if not complete:
            raise RecoveryIncomplete(self.outcome)
        return self.outcome

    def finish(self):
        if not self.finished():
            raise ValueError('terminal child and drained pipes required')
        if (self.first_failure is not None or self.pending or not self.native_admitted
                or not self.events or self.events[-1]['event'] != 'finished' or self.process.poll() != 0):
            error = ValueError('worker did not complete a healthy admitted protocol')
            self.fail('finish', error)
            raise error
        return self._consume(recovery=False)

    def recover(self, cause=None):
        """Bound direct-child termination and draining; preserve the first failure."""
        if self.outcome is not None:
            if not self.outcome['cleanup_complete']:
                raise RecoveryIncomplete(self.outcome)
            return self.outcome
        self.fail('recovery', cause if cause is not None else RuntimeError('separate recovery requested'))
        if self.process is not None:
            for number, grace in ((signal.SIGTERM, self.limits.term_seconds),
                                  (signal.SIGKILL, self.limits.kill_seconds)):
                if self.finished():
                    break
                # Pipe EOF is not child liveness. The Popen owner may signal its
                # still-unreaped direct child even if native admission failed.
                # send_signal polls again and never signals a known terminal PID.
                if self.process.poll() is None:
                    try:
                        self.process.send_signal(number)
                        self.signals.append(number)
                        self.emit('child_signal', recovery=True, signal=number)
                    except Exception as error:
                        self.cleanup_errors.append(dict(phase='signal', error=str(error)))
                deadline = self.system.now() + grace
                while not self.finished() and self.system.now() < deadline:
                    self.pump(recovery=True)
        return self._consume(recovery=True)
