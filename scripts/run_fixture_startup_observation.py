"""Run one fixed T1669 diagnostic with observation prepared before exec release.

The test and this caller remain normal-user processes. Only the separately
authenticated helper samples a closed fixture target. All output stays in the
observer's private repository-local evidence directory.
"""

import argparse
import errno
import hashlib
import json
import os
from pathlib import Path
import resource
import select
import signal
import struct
import subprocess
import sys
import time

import observe_fixture_startup as observer
import fixture_policy_log as policy_log


ROOT = Path(__file__).resolve().parent.parent
READY_SECONDS = 10
EXEC_SECONDS = 5
TEST_SECONDS = 200
REAP_SECONDS = 2
ACK_BYTES = 16
OUTPUT_BYTES = 16 * 1024 * 1024
POLICY_STATUS_BYTES = 65536
TEST_ARGV = ("/usr/bin/perl", observer.sampler.SUPERVISOR_TEST_PATH)


class GatedTest:
    """Own one unreaped child; the pipe is its sole permission to attempt exec."""

    def __init__(self, native, root, directory):
        self.native, self.root = native, root
        self.pid = self.identity = self.status = None
        self.gate = self.ack = None
        self.released = self.timed_out = False
        self.deadline = time.monotonic() + TEST_SECONDS
        gate_read, gate_write = os.pipe()
        try:
            ack_read, ack_write = os.pipe()
        except BaseException:
            os.close(gate_read)
            os.close(gate_write)
            raise
        try:
            with (directory / "test.tap").open("xb") as stdout, \
                    (directory / "test.stderr").open("xb") as stderr:
                pid = os.fork()
                if pid == 0:
                    try:
                        os.close(gate_write)
                        os.close(ack_read)
                        # Match normal subprocess exec: Python ignores these
                        # signals in its own runtime, but the test must not.
                        for name in ("SIGTERM", "SIGINT", "SIGPIPE", "SIGXFZ", "SIGXFSZ"):
                            signum = getattr(signal, name, None)
                            if signum is not None:
                                signal.signal(signum, signal.SIG_DFL)
                        os.dup2(stdout.fileno(), 1)
                        os.dup2(stderr.fileno(), 2)
                        with open(os.devnull, "rb") as stdin:
                            os.dup2(stdin.fileno(), 0)
                        os.chdir(root)
                        resource.setrlimit(resource.RLIMIT_FSIZE, (OUTPUT_BYTES, OUTPUT_BYTES))
                        readable, _, _ = select.select([gate_read], [], [], READY_SECONDS)
                        if not readable or os.read(gate_read, 2) != b"R":
                            os._exit(125)
                        os.close(gate_read)
                        # This witness is produced by the held child, before exec.
                        os.write(ack_write, struct.pack("!QQ", os.getpid(), time.monotonic_ns()))
                        os.close(ack_write)
                        os.execv(TEST_ARGV[0], TEST_ARGV)
                    except BaseException:
                        os.write(2, b"diagnostic child failed before exec\n")
                        os._exit(125)
                self.pid = pid
        finally:
            os.close(gate_read)
            os.close(ack_write)
            if self.pid is None:
                os.close(gate_write)
                os.close(ack_read)
        self.gate, self.ack = gate_write, ack_read
        try:
            self.identity = native.identity(self.pid)
            if (self.identity["ppid"] != os.getpid()
                    or any(self.identity[key] != os.getuid() for key in ("uid", "ruid"))):
                raise ValueError("reserved test is not this caller's normal-user child")
        except BaseException:
            self.close_gate()
            self.finish(cancel=True)
            raise

    def poll(self):
        if self.status is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                if pid != self.pid:
                    raise RuntimeError("waitpid returned an unrelated child")
                self.status = status
        return self.status

    def close_gate(self):
        if self.gate is not None:
            os.close(self.gate)
            self.gate = None

    def release(self, prepare):
        if self.released or self.gate is None or self.poll() is not None:
            raise ValueError("reserved test was already released or is unavailable")
        ready_ns = prepare()
        if self.native.identity(self.pid) != self.identity:
            raise ValueError("reserved test identity changed before release")
        os.write(self.gate, b"R")
        self.released = True
        self.close_gate()
        deadline = time.monotonic() + READY_SECONDS
        body = b""
        while len(body) < ACK_BYTES:
            remaining = deadline - time.monotonic()
            if remaining <= 0 or not select.select([self.ack], [], [], remaining)[0]:
                raise TimeoutError("test release acknowledgement expired")
            data = os.read(self.ack, ACK_BYTES - len(body))
            if not data:
                raise RuntimeError("test disappeared before release acknowledgement")
            body += data
        pid, released_ns = struct.unpack("!QQ", body)
        if pid != self.pid or released_ns < ready_ns:
            raise ValueError("child release witness precedes readiness or names another PID")
        return {"ready_ns": ready_ns, "child_release_ns": released_ns, "pid": pid,
                "exec_success": "not_established"}

    def _signal(self, signum):
        if self.poll() is not None:
            return
        try:
            if self.identity is not None and self.native.identity(self.pid) != self.identity:
                raise RuntimeError("refusing to signal a changed reserved test identity")
        except ProcessLookupError:
            # Native exit can precede waitpid availability. Do not signal a
            # missing identity; the bounded reap loop still has to consume it.
            return
        try:
            os.kill(self.pid, signum)
        except ProcessLookupError:
            pass

    def _wait_until(self, deadline):
        while self.poll() is None and time.monotonic() < deadline:
            time.sleep(0.01)
        return self.poll() is not None

    def finish(self, cancel=False):
        self.close_gate()
        try:
            if not cancel and self._wait_until(self.deadline):
                return self.result()
            if self.poll() is None:
                self.timed_out = not cancel
                self._signal(signal.SIGTERM)
                if not self._wait_until(time.monotonic() + REAP_SECONDS):
                    self._signal(signal.SIGKILL)
                    if not self._wait_until(time.monotonic() + REAP_SECONDS):
                        raise RuntimeError(f"owned test {self.pid} did not reap within final cleanup bound")
            return self.result()
        finally:
            if self.ack is not None:
                os.close(self.ack)
                self.ack = None

    def result(self):
        return {"pid": self.pid, "native_wait_status": self.status,
                "returncode": os.waitstatus_to_exitcode(self.status),
                "timeout": self.timed_out, "released": self.released,
                "leader_reaped": True, "unobserved_descendants": "unknown"}


class OwnedProcesses(observer.Processes):
    """Reap only our child so the attach-only observer cannot wait on its zombie."""

    def __init__(self):
        super().__init__()
        self.test = None

    def identity(self, pid):
        if self.test is not None and pid == self.test.pid and self.test.poll() is not None:
            raise ProcessLookupError(errno.ESRCH, "owned test birth was reaped")
        return super().identity(pid)


def wait_for_exec(test, native, root):
    deadline = time.monotonic() + EXEC_SECONDS
    while time.monotonic() < deadline:
        if test.poll() is not None:
            raise RuntimeError("test exited before its exec identity was observed")
        if native.identity(test.pid) != test.identity:
            raise ValueError("reserved test birth changed during exec observation")
        try:
            if (native.executable(test.pid) == Path(TEST_ARGV[0]).resolve()
                    and observer.sampler._test_command(
                        native.command(test.pid), TEST_ARGV[1], root)):
                return
        except (ProcessLookupError, subprocess.CalledProcessError):
            pass
        time.sleep(0.01)
    raise TimeoutError("fixed test exec identity was not observed within its bound")


def stop_helper(session):
    session.stop()
    deadline = time.monotonic() + observer.SETTLE_SECONDS
    while not session.stopped():
        if time.monotonic() >= deadline:
            raise RuntimeError("authenticated helper shutdown was not verified")
        time.sleep(observer.POLL_SECONDS)


def require_ready(session, native):
    state = session.state()
    cursor = state.get("last_request", 0)
    if (session.submitted or state.get("state") != "ready"
            or observer.identity_key(state["helper"]) != observer.identity_key(session.helper)
            or not observer.still_live(native, session.helper)
            or type(cursor) is not int or cursor != session.number - 1
            or (session.directory / "STOP").exists()):
        raise ValueError("authenticated helper changed before test release")


def retained_policy_result(evidence, *, scope="fixture_path"):
    """Reload retained status and independently verify its exact output files."""
    policy_log.require_scope(scope)
    result = json.loads(observer.read_local_file(
        evidence.directory / "policy-result.json", evidence.root, POLICY_STATUS_BYTES))
    # Build the canonical contract without repeating producer normalization.
    expected_command = policy_log.command(Path("<repo>"), scope=scope)
    if (not isinstance(result, dict) or result.get("scope") != scope
            or result.get("command") != expected_command):
        raise RuntimeError("policy retention has unexpected collection scope or command")
    if (not isinstance(result, dict) or result.get("schema") != "fsmgen.fixture_policy_log.v1"
            or result.get("failures") != {} or result.get("leader_reaped") is not True
            or result.get("forced_kill") is not False
            or type(result.get("returncode")) is not int
            or result["returncode"] not in (0, -signal.SIGINT)
            or any(type(result.get(key)) is not int for key in ("started_ns", "prepared_ns", "finished_ns"))
            or not 0 < result["started_ns"] <= result["prepared_ns"] <= result["finished_ns"]
            or not isinstance(result.get("outputs"), dict)
            or set(result["outputs"]) != {"stdout", "stderr"}):
        raise RuntimeError("policy retention lacks prepared, successful owned cleanup")
    for name, metadata in result["outputs"].items():
        path = evidence.directory / ("policy." + name)
        if (not isinstance(metadata, dict) or metadata.get("path") != str(path.relative_to(evidence.root))
                or metadata.get("hash_complete") is not True or metadata.get("path_identity_matches") is not True
                or type(metadata.get("bytes")) is not int
                or not 0 <= metadata["bytes"] < policy_log.OUTPUT_BYTES):
            raise RuntimeError("policy retention has invalid output identity or bounds")
        raw = observer.read_local_file(path, evidence.root, policy_log.OUTPUT_BYTES)
        if len(raw) != metadata["bytes"] or hashlib.sha256(raw).hexdigest() != metadata.get("sha256"):
            raise RuntimeError("policy retained output changed after collector shutdown")
    return result


def run(session, native, evidence, root, *, stop_session=True, target_family="all",
        policy_scope="fixture_path"):
    test, result = None, None
    collection = None
    observation_error = None
    cancelled = False
    try:
        observer.require_target_family(target_family)
        policy_log.require_scope(policy_scope)
        collection = policy_log.PolicyLog(root, evidence.directory, native, scope=policy_scope)
        policy_ready = collection.prepare()
        evidence.record("policy_prepared", **policy_ready)
        test = GatedTest(native, root, evidence.directory)
        native.test = test

        def prepare():
            require_ready(session, native)
            collection.check()
            ready_ns = time.monotonic_ns()
            evidence.record("observer_ready", ready_ns=ready_ns, test=test.identity,
                            target_family=target_family,
                            policy_readiness=policy_ready,
                            argv=list(TEST_ARGV), test_sha256=hashlib.sha256(
                                (root / TEST_ARGV[1]).read_bytes()).hexdigest(),
                            launcher_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
            return ready_ns

        witness = test.release(prepare)
        evidence.record("test_release", witness=witness, test=test.identity)
        wait_for_exec(test, native, root)
        observer.observe(test.identity, native, session, evidence, root,
                         stop_session=stop_session, target_family=target_family,
                         check_collection=collection.check)
    except (Exception, KeyboardInterrupt) as error:
        observation_error = error
        cancelled = isinstance(error, KeyboardInterrupt)
        evidence.problem("observation", error)
    finally:
        cleanup_errors = []
        try:
            if test is not None:
                result = test.finish(cancel=cancelled or not test.released)
                pending = evidence.directory / "test-result.next"
                pending.write_text(json.dumps(result, indent=2) + "\n")
                pending.replace(evidence.directory / "test-result.json")
        except (Exception, KeyboardInterrupt) as error:
            cleanup_errors.append("test cleanup: " + str(error))
        if collection is not None:
            try:
                collected = collection.finish()
                if retained_policy_result(evidence, scope=policy_scope) != collected:
                    raise RuntimeError("policy status changed after collector publication")
            except (Exception, KeyboardInterrupt) as error:
                cleanup_errors.append("policy collection: " + str(error))
            else:
                try:
                    evidence.record("policy_settled", scope=policy_scope, leader_reaped=True, failures={},
                                    result_path=str((evidence.directory / "policy-result.json").relative_to(root)))
                except (Exception, KeyboardInterrupt) as error:
                    # A full journal must not relabel physically verified
                    # collection cleanup, or replace an earlier observation error.
                    if observation_error is None:
                        observation_error = error
        if stop_session:
            try:
                stop_helper(session)
            except (Exception, KeyboardInterrupt) as error:
                cleanup_errors.append("helper cleanup: " + str(error))
        if cleanup_errors:
            failure = RuntimeError("; ".join(cleanup_errors))
            evidence.problem("cleanup", failure)
            raise failure
    if observation_error is not None:
        evidence.problem("observation", observation_error)
        raise observation_error
    if result is None or result["timeout"] or result["returncode"] != 0:
        raise RuntimeError("original test failed; retained TAP/wait status remains authoritative")
    evidence.record("caller_complete", result=result, scope=policy_scope, qualification="not_claimed")
    return result


def main(*, policy_scope="fixture_path"):
    policy_log.require_scope(policy_scope)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", required=True)
    parser.add_argument("--target-family", choices=observer.TARGET_FAMILIES, default="all")
    args = parser.parse_args()
    if sys.platform != "darwin" or os.getuid() == 0 or os.geteuid() == 0:
        raise ValueError("run the diagnostic caller as the normal user on Darwin")
    if os.environ.get("FSMGEN_RAM_GUARD_ACTIVE") != "1":
        raise ValueError("run this caller through scripts/run_with_ram_guard.sh")
    native = OwnedProcesses()
    session = observer.CaptureSession(args.session, native, ROOT)
    evidence = None

    def interrupted(_signum, _frame):
        raise KeyboardInterrupt

    previous = signal.signal(signal.SIGTERM, interrupted)
    try:
        os.umask(0o077)
        evidence = observer.Evidence(ROOT)
        print(str(evidence.directory.relative_to(ROOT)), flush=True)
        run(session, native, evidence, ROOT, target_family=args.target_family,
            policy_scope=policy_scope)
        return 0
    except (Exception, KeyboardInterrupt) as error:
        if evidence is not None:
            evidence.problem("final", error)
        print(str(error), file=sys.stderr)
        return 130 if isinstance(error, KeyboardInterrupt) else 1
    finally:
        signal.signal(signal.SIGTERM, previous)
        if evidence is not None:
            evidence.stream.close()
        else:
            stop_helper(session)


if __name__ == "__main__":
    raise SystemExit(main())
