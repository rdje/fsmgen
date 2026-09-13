"""Inspect one declared descriptor after exec; never acquire or alter a lock."""

import errno
import os
import signal
import sys

from wire import command, emit


def main():
    if len(sys.argv) != 4:
        raise ValueError('expected descriptor, device and inode')
    descriptor, device, inode = map(int, sys.argv[1:])
    if descriptor <= 2 or device < 0 or inode <= 0:
        raise ValueError('invalid descriptor identity')
    signal.alarm(15)
    emit('probe_ready', ppid=os.getppid(), pgid=os.getpgrp(), uid=os.getuid(), euid=os.geteuid())
    command('scan')
    try:
        observed = os.fstat(descriptor)
    except OSError as error:
        if error.errno != errno.EBADF:
            raise
        emit('probe_result', descriptor=descriptor, closed=True, inherited=False)
        return 0
    inherited = (observed.st_dev, observed.st_ino) == (device, inode)
    emit('probe_result', descriptor=descriptor, closed=False, inherited=inherited,
         device=observed.st_dev, inode=observed.st_ino)
    # Any still-open descriptor is rejected; even reuse cannot masquerade as closure.
    return 23


if __name__ == '__main__':
    sys.exit(main())
