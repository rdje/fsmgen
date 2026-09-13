"""Independent Python empty-store peer; execute only under committed admission."""

import errno
import fcntl
import os
from pathlib import Path
import signal
import stat
import sys
import time

from contract import BASE, ROOT, WAIT_NS, cases
from capability import worker_admission
from wire import command, emit


def directory(path):
    relative = path.relative_to(ROOT)
    current = ROOT
    for part in relative.parts:
        current /= part
        metadata = current.lstat()
        if (not stat.S_ISDIR(metadata.st_mode) or metadata.st_uid != os.getuid()
                or metadata.st_dev != ROOT.stat().st_dev):
            raise ValueError('invalid direct owned directory')
    if stat.S_IMODE(metadata.st_mode) != 0o700:
        raise ValueError('invalid private directory mode')
    return (metadata.st_dev, metadata.st_ino, metadata.st_mode, metadata.st_uid)


def lock_identity(descriptor, path):
    opened, named = os.fstat(descriptor), path.lstat()
    fields = ('st_dev', 'st_ino', 'st_mode', 'st_nlink', 'st_uid', 'st_size')
    value = tuple(getattr(opened, field) for field in fields)
    if (not stat.S_ISREG(opened.st_mode) or opened.st_dev != ROOT.stat().st_dev
            or stat.S_IMODE(opened.st_mode) != 0o600 or opened.st_nlink != 1
            or opened.st_uid != os.getuid() or opened.st_size != 0
            or value != tuple(getattr(named, field) for field in fields)):
        raise ValueError('invalid permanent lock identity')
    return value


def inspect_empty(store, initial):
    if directory(store) != initial:
        raise ValueError('store root replaced')
    if sorted(os.listdir(store)) != ['coordination.lock', 'images', 'references']:
        raise ValueError('unexpected store members')
    for name in ('images', 'references'):
        directory(store / name)
        if os.listdir(store / name):
            raise ValueError('peer admits only an empty namespace')


def exec_probe(descriptor, identity, sealed):
    flags = fcntl.fcntl(descriptor, fcntl.F_GETFD)
    if not flags & fcntl.FD_CLOEXEC:
        raise ValueError('original close-on-exec seal missing')
    if not sealed:
        # Deliberate omitted-guard countercontrol, before any lock acquisition.
        fcntl.fcntl(descriptor, fcntl.F_SETFD, flags & ~fcntl.FD_CLOEXEC)
    child = os.fork()
    if child == 0:
        try:
            os.execv(sys.executable, [sys.executable, '-B', '-s', '-E', str(BASE / 'probe.py'),
                                     str(descriptor), str(identity[0]), str(identity[1])])
        except BaseException:
            os._exit(126)
    emit('probe_spawned', child_pid=child, before_acquisition=True, sealed=sealed)
    waited, status = os.waitpid(child, 0)
    if waited != child:
        raise RuntimeError('wrong probe reaped')
    code = os.waitstatus_to_exitcode(status)
    emit('probe_reaped', child_pid=child, exit_code=code)
    if code != (0 if sealed else 23):
        raise ValueError('unexpected exec probe outcome')
    fcntl.fcntl(descriptor, fcntl.F_SETFD, flags)


def run(case, role):
    store = ROOT / case['store']
    initial = directory(store)
    path = store / 'coordination.lock'
    descriptor = os.open(path, os.O_RDWR | os.O_NOFOLLOW | os.O_NONBLOCK)
    error = None
    busy_count = 0
    entered = False
    first_ns = last_ns = None
    try:
        identity = lock_identity(descriptor, path)
        flags = fcntl.fcntl(descriptor, fcntl.F_GETFD)
        fcntl.fcntl(descriptor, fcntl.F_SETFD, flags | fcntl.FD_CLOEXEC)
        emit('opened', descriptor=descriptor, device=identity[0], inode=identity[1],
             close_on_exec=bool(fcntl.fcntl(descriptor, fcntl.F_GETFD) & fcntl.FD_CLOEXEC))
        command('lock')
        if role == 'inheritance':
            exec_probe(descriptor, identity, case['sealed'])
        first_ns = time.monotonic_ns()
        deadline = first_ns + WAIT_NS
        while True:
            last_ns = time.monotonic_ns()
            if last_ns >= deadline:
                raise TimeoutError('permanent lock admission deadline expired')
            try:
                fcntl.flock(descriptor, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except OSError as failure:
                if failure.errno not in (errno.EAGAIN, errno.EWOULDBLOCK):
                    raise
                busy_count += 1
                if busy_count == 1:
                    emit('busy', errno=failure.errno)
                remaining = deadline - time.monotonic_ns()
                if remaining <= 0:
                    last_ns = time.monotonic_ns()
                    raise TimeoutError('permanent lock admission deadline expired')
                time.sleep(min(remaining / 1_000_000_000, 0.005))
                continue
            last_ns = time.monotonic_ns()
            if last_ns >= deadline:
                raise TimeoutError('permanent lock admission deadline expired')
            if lock_identity(descriptor, path) != identity:
                raise ValueError('permanent lock replaced during acquisition')
            entered = True
            emit('entered')
            break
        inspect_empty(store, initial)
        if role == 'holder':
            emit('held')
            command('release')
        inspect_empty(store, initial)
        if lock_identity(descriptor, path) != identity:
            raise ValueError('permanent lock replaced during census')
    except Exception as failure:
        error = str(failure)
    close_error = None
    try:
        os.close(descriptor)
    except OSError as failure:
        close_error = str(failure)
    emit('finished', success=error is None, error=error, entered=entered,
         busy_count=busy_count, first_ns=first_ns, last_ns=last_ns,
         descriptor_closed=close_error is None, close_error=close_error)
    if close_error is not None:
        return 24
    return 0


def main():
    if len(sys.argv) != 3:
        raise ValueError('expected declared case and role')
    name, role = sys.argv[1:]
    selected = next(case for case in cases() if case['name'] == name)
    if role not in ('holder', 'waiter', 'inheritance'):
        raise ValueError('unknown role')
    if selected['kind'] == 'pair':
        if role == 'inheritance' or selected[role] != 'python':
            raise ValueError('wrong declared Python role')
    elif role != 'inheritance' or selected['language'] != 'python':
        raise ValueError('wrong inheritance role')
    if os.getuid() <= 0 or os.getuid() != os.geteuid() or os.getpgrp() != os.getpid():
        raise ValueError('worker lacks normal-user private process group')
    worker_admission()
    signal.alarm(20)
    emit('ready', case=name, role=role, language='python', uid=os.getuid(), euid=os.geteuid(),
         ppid=os.getppid(), pgid=os.getpgrp())
    command('admit')
    return run(selected, role)


if __name__ == '__main__':
    sys.exit(main())
