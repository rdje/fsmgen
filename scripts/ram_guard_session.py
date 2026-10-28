#!/usr/bin/env python3
"""Private session handoff and census for run_with_ram_guard.sh.

The retained session leader prevents identity reuse and survives command exit.
getsid, rather than ps's Darwin sess field (which can be zero), also recognizes
orphaned members of nested process groups. No command runs before admission.
"""

import os
from pathlib import Path
import signal
import subprocess
import sys
import time


def members(session):
    rows = subprocess.check_output(["ps", "-axo", "pid=,stat="], text=True)
    result = {}
    for line in rows.splitlines():
        pid_text, state = line.split(None, 1)
        pid = int(pid_text)
        try:
            if os.getsid(pid) == session and not state.startswith("Z"):
                result[pid] = state.strip()
        except ProcessLookupError:
            pass
    return result


def send_owned(pid, session, sig):
    try:
        if os.getsid(pid) == session:
            os.kill(pid, sig)
    except ProcessLookupError:
        pass


def terminate(session, grace):
    # Keep the identity anchor until other members cannot fork any more.
    for pid in members(session):
        if pid != session:
            send_owned(pid, session, signal.SIGTERM)
    time.sleep(grace)
    deadline = time.monotonic() + 2
    while True:
        for pid in members(session):
            if pid != session:
                send_owned(pid, session, signal.SIGSTOP)
        stopped = members(session)
        if all(pid == session or state.startswith("T") for pid, state in stopped.items()):
            break
        if time.monotonic() >= deadline:
            raise RuntimeError("owned session members did not stop before cleanup deadline")
        time.sleep(0.01)
    for pid in stopped:
        if pid != session:
            send_owned(pid, session, signal.SIGKILL)
    deadline = time.monotonic() + 2
    while any(pid != session for pid in members(session)):
        if time.monotonic() >= deadline:
            raise RuntimeError("owned session members remain after KILL")
        time.sleep(0.01)
    send_owned(session, session, signal.SIGKILL)


def publish(directory, name, value):
    temporary = directory / (name + ".tmp")
    temporary.write_text(str(value) + "\n")
    temporary.replace(directory / name)


def launch(directory, owner, command):
    os.setsid()
    session = os.getpid()
    for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(sig, signal.SIG_IGN)

    def check_owner():
        if os.getppid() != owner:
            terminate(session, 0)
            os._exit(137)

    publish(directory, "ready", session)
    while not (directory / "go").is_file():
        check_owner()
        time.sleep(0.01)
    check_owner()
    child = os.fork()
    if child == 0:
        for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP, signal.SIGQUIT, signal.SIGPIPE):
            signal.signal(sig, signal.SIG_DFL)
        try:
            os.execvp(command[0], command)
        except OSError as error:
            print(f"ram-guard: cannot execute {command[0]}: {error}", file=sys.stderr)
            os._exit(127 if isinstance(error, FileNotFoundError) else 126)
    status = None
    while True:
        check_owner()
        if status is None:
            waited, raw = os.waitpid(child, os.WNOHANG)
            if waited:
                status = 128 + os.WTERMSIG(raw) if os.WIFSIGNALED(raw) else os.WEXITSTATUS(raw)
                publish(directory, "status", status)
        if status is not None and (directory / "finish").is_file():
            return status
        time.sleep(0.02)


def main():
    mode, *args = sys.argv[1:]
    if mode == "launch":
        directory, owner, *command = args
        if not command:
            raise ValueError("missing private command")
        return launch(Path(directory), int(owner), command)
    if mode == "members":
        session, = args
        for pid in members(int(session)):
            print(pid)
        return 0
    if mode == "terminate":
        session, grace = args
        terminate(int(session), float(grace))
        return 0
    raise ValueError("unknown private session operation")


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"ram-guard: session supervision failed: {error}", file=sys.stderr)
        sys.exit(2)
