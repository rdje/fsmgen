"""Bounded read-only policy retention for one prospective fixture invocation.

The OS log service and /usr/bin/log are required read-only host dependencies.
The startup header proves only that the command emitted its filter: neither
subscription readiness nor complete delivery is acknowledged by this interface.
"""

import hashlib
import json
import os
from pathlib import Path
import resource
import signal
import stat
import subprocess
import time

import fixture_kernel_sampler as sampler


START_SECONDS = 10
LIFETIME_SECONDS = 240
REAP_SECONDS = 2
OUTPUT_BYTES = 16 * 1024 * 1024
HEADER_BYTES = 8192
POLL_SECONDS = 0.05


def command(root):
    # JSON string quoting supplies an NSPredicate string literal, not shell text.
    prefix = str(root / ".artifacts/tmp/process-supervisor-tests") + "/"
    predicate = 'process == "syspolicyd" AND eventMessage CONTAINS ' + json.dumps(prefix, ensure_ascii=False)
    return ["/usr/bin/log", "stream", "--style", "ndjson", "--level", "debug",
            "--timeout", str(LIFETIME_SECONDS), "--predicate", predicate]


def limit_child_output():
    resource.setrlimit(resource.RLIMIT_FSIZE, (OUTPUT_BYTES, OUTPUT_BYTES))


class PolicyLog:
    """Own one native collector; finish returns retained status including failures."""

    def __init__(self, root, directory, native):
        self.root, self.directory, self.native = root, directory, native
        if root.resolve() != root or directory.resolve() != directory or root not in directory.parents:
            raise ValueError("policy evidence must be directly repository-local")
        metadata = directory.stat()
        if (not stat.S_ISDIR(metadata.st_mode) or metadata.st_dev != root.stat().st_dev
                or metadata.st_uid != os.getuid() or stat.S_IMODE(metadata.st_mode) != 0o700):
            raise ValueError("policy evidence requires an owned private repository-volume directory")
        self.directory_identity = (metadata.st_dev, metadata.st_ino)
        self.process, self.identity = None, None
        self.streams = {}
        self.started_ns = self.prepared_ns = None
        self.failures = {}
        self.finished = False
        self.result = None
        self.argv = command(root)

    def _directory_unchanged(self):
        metadata = self.directory.lstat()
        if (not stat.S_ISDIR(metadata.st_mode)
                or (metadata.st_dev, metadata.st_ino) != self.directory_identity):
            raise ValueError("policy evidence directory was replaced")

    def _problem(self, stage, error):
        reason = str(error).replace(str(self.root), "<repo>")
        self.failures.setdefault(stage, reason[:1024])

    def _inspect_streams(self):
        self._directory_unchanged()
        for name, stream in self.streams.items():
            metadata = os.fstat(stream.fileno())
            linked = (self.directory / ("policy." + name)).lstat()
            if (metadata.st_dev, metadata.st_ino) != (linked.st_dev, linked.st_ino):
                raise ValueError("policy output file was replaced")
            if metadata.st_size >= OUTPUT_BYTES:
                raise RuntimeError("policy output reached its fixed byte bound")

    def prepare(self):
        if self.started_ns is not None or self.finished:
            raise ValueError("policy collector cannot be started twice")
        self.started_ns = time.monotonic_ns()
        deadline = time.monotonic() + START_SECONDS
        try:
            self._directory_unchanged()
            for name in ("stdout", "stderr"):
                self.streams[name] = (self.directory / ("policy." + name)).open("x+b")
            temporary = sampler.local_directory(self.root / ".artifacts/tmp", self.root)
            environment = dict(os.environ, TMPDIR=str(temporary), TMP=str(temporary), TEMP=str(temporary))
            self.process = subprocess.Popen(
                self.argv, cwd=self.root, env=environment, stdin=subprocess.DEVNULL,
                stdout=self.streams["stdout"], stderr=self.streams["stderr"],
                preexec_fn=limit_child_output)
            self.identity = self.native.identity(self.process.pid)
            if (self.identity["ppid"] != os.getpid()
                    or any(self.identity[key] != os.getuid() for key in ("uid", "ruid"))):
                raise ValueError("policy collector is not this caller's normal-user child")
            while time.monotonic() < deadline:
                self.check()
                prefix = os.pread(self.streams["stdout"].fileno(), HEADER_BYTES, 0)
                if b"\n" in prefix:
                    if not prefix.split(b"\n", 1)[0].startswith(b"Filtering the log data using "):
                        raise ValueError("policy collector did not emit its native filter header")
                    self.prepared_ns = time.monotonic_ns()
                    return {"prepared_ns": self.prepared_ns, "identity": self.identity,
                            "subscription_readiness": "unproved", "complete_coverage": "unproved"}
                if len(prefix) == HEADER_BYTES:
                    raise ValueError("policy startup header exceeds its fixed bound")
                time.sleep(POLL_SECONDS)
            raise TimeoutError("policy startup header was not observed within its bound")
        except BaseException as error:
            self._problem("prepare", error)
            raise

    def check(self):
        try:
            if self.finished or self.process is None:
                raise ValueError("policy collector is not running")
            self._inspect_streams()
            if self.process.poll() is not None:
                raise RuntimeError("policy collector exited before requested shutdown")
            if time.monotonic_ns() - self.started_ns >= LIFETIME_SECONDS * 1_000_000_000:
                raise TimeoutError("policy collector exceeded its fixed lifetime")
        except BaseException as error:
            self._problem("collection", error)
            raise

    def finish(self):
        if self.finished:
            return self.result
        forced = False
        if self.started_ns is None:
            self._problem("prepare", "policy collector was never prepared")
        if self.process is not None:
            try:
                self.check()
            except BaseException:
                # Retain collection failure, then independently close its owner.
                pass
        try:
            if self.process is not None:
                if self.process.poll() is not None:
                    self._problem("collection", "policy collector exited before requested shutdown")
                else:
                    # Popen owns this unreaped child: its PID cannot be reused
                    # before poll/wait consumes it. Never signal a foreign PID.
                    self.process.send_signal(signal.SIGINT)
                    try:
                        self.process.wait(timeout=REAP_SECONDS)
                    except subprocess.TimeoutExpired:
                        pass  # The independent final owner below performs KILL/reap.
            self._inspect_streams()
        except BaseException as error:
            self._problem("cleanup", error)
        finally:
            if self.process is not None and self.process.poll() is None:
                try:
                    forced = True
                    self.process.kill()
                    self.process.wait(timeout=REAP_SECONDS)
                except BaseException as error:
                    self._problem("cleanup", error)
            if self.process is not None and (forced or self.process.returncode not in (0, -signal.SIGINT)):
                self._problem("collection", "policy collector did not stop normally")
            outputs = {}
            for name, stream in self.streams.items():
                try:
                    metadata = os.fstat(stream.fileno())
                    size, position, digest = metadata.st_size, 0, hashlib.sha256()
                    while position < min(size, OUTPUT_BYTES):
                        raw = os.pread(stream.fileno(), min(65536, size - position, OUTPUT_BYTES - position), position)
                        if not raw:
                            break
                        digest.update(raw)
                        position += len(raw)
                    linked = (self.directory / ("policy." + name)).lstat()
                    matches = (linked.st_dev, linked.st_ino) == (metadata.st_dev, metadata.st_ino)
                    complete = position == size and os.fstat(stream.fileno()).st_size == size
                    if not complete or not matches:
                        self._problem("cleanup", "policy output identity or final hash is incomplete")
                    outputs[name] = {"path": str((self.directory / ("policy." + name)).relative_to(self.root)),
                                     "bytes": size, "sha256": digest.hexdigest(),
                                     "hash_complete": complete, "path_identity_matches": matches}
                except BaseException as error:
                    self._problem("cleanup", error)
                finally:
                    stream.close()
            self.finished = True
            self.result = {"schema": "fsmgen.fixture_policy_log.v1", "identity": self.identity,
                           "command": [arg.replace(str(self.root), "<repo>") for arg in self.argv],
                           "producer_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                           "started_ns": self.started_ns, "prepared_ns": self.prepared_ns,
                           "finished_ns": time.monotonic_ns(), "outputs": outputs,
                           "returncode": self.process.returncode if self.process is not None else None,
                           "leader_reaped": self.process is None or self.process.returncode is not None,
                           "forced_kill": forced, "failures": dict(self.failures),
                           "subscription_readiness": "unproved", "complete_coverage": "unproved",
                           "missing_records": "unknown", "unobserved_descendants": "unknown"}
            self._directory_unchanged()
            pending = self.directory / "policy-result.next"
            owned_pending = False
            try:
                with pending.open("x") as stream:
                    owned_pending = True
                    stream.write(json.dumps(self.result, sort_keys=True, indent=2) + "\n")
                os.link(pending, self.directory / "policy-result.json")
            except BaseException as error:
                self._problem("cleanup", "policy result publication: " + str(error))
                self.result["failures"] = dict(self.failures)
                raise
            finally:
                if owned_pending:
                    pending.unlink()
        return self.result
