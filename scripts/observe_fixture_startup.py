"""Bounded, read-only T1669 observer for an explicitly identified live test.

This program neither launches nor signals tests. The caller owns the guarded
test invocation and its original TAP/exit result. Only the separately started
authenticated helper can perform the fixed native capture. libproc is a
read-only OS dependency; all diagnostic output is repository-local.
"""

import argparse
import ctypes
import errno
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import stat
import sys
import time
import uuid

import fixture_kernel_sampler as sampler


ROOT = Path(__file__).resolve().parent.parent
OBSERVATION_SECONDS = 180
SETTLE_SECONDS = 12
CANDIDATE_SECONDS = 0.5
POLL_SECONDS = 0.1
MAX_CHILDREN = 64
MAX_IDENTITIES = 512
MAX_EVENTS = 4096
MAX_EVENT_BYTES = 16384
MAX_LOG_BYTES = 16 * 1024 * 1024
MAX_SOURCE_FILES = 64
MAX_SOURCE_BYTES = 4 * 1024 * 1024


class Processes(sampler.NativeProcesses):
    def __init__(self):
        super().__init__()
        self.library.proc_listchildpids.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_int]
        self.library.proc_listchildpids.restype = ctypes.c_int

    def children(self, pid):
        # The installed libproc.h declares this bounded buffer API. Its PID-count
        # return unit is independently tested with actual parent-owned children.
        buffer = (ctypes.c_int * MAX_CHILDREN)()
        ctypes.set_errno(0)
        count = self.library.proc_listchildpids(pid, buffer, ctypes.sizeof(buffer))
        if count < 0:
            raise OSError(ctypes.get_errno(), "native child census failed")
        if count >= MAX_CHILDREN:
            raise ValueError("native child census reached its completeness bound")
        pids = list(buffer[:count])
        if len(set(pids)) != count or any(pid <= 1 for pid in pids):
            raise ValueError("native child census has invalid identities or return units")
        return pids


def identity_key(info):
    return tuple(info[key] for key in sampler.IDENTITY_FIELDS)


def still_live(native, info):
    try:
        return identity_key(native.identity(info["pid"])) == identity_key(info)
    except OSError as error:
        if error.errno in (errno.ESRCH, errno.ENOENT):
            return False
        raise


def read_local_file(path, root, limit):
    if path.resolve() != path or root not in path.parents:
        raise ValueError("diagnostic file must be a direct repository-local path")
    with os.fdopen(os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK), "rb") as stream:
        metadata = os.fstat(stream.fileno())
        if (not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid()
                or metadata.st_dev != root.stat().st_dev):
            raise ValueError("diagnostic input is not an owned repository-volume regular file")
        body = stream.read(limit + 1)
    if len(body) > limit:
        raise ValueError("diagnostic input exceeds its fixed byte bound")
    return body


class Evidence:
    def __init__(self, root):
        base = sampler.local_directory(root / ".artifacts/logs/t1669-startup-observation", root)
        self.root = root
        self.directory = base / ("run-" + uuid.uuid4().hex)
        self.directory.mkdir(mode=0o700)
        self.stream = (self.directory / "observations.jsonl").open("x", buffering=1)
        self.count = self.bytes = 0
        self.sources = set()
        self.source_bytes = 0
        self.failures = {}

    def problem(self, stage, error):
        """Keep terminal failure evidence even after ordinary event capacity is full."""
        if stage not in ("observation", "cleanup", "final"):
            raise ValueError("unknown observer failure stage")
        reason = str(error).replace(str(self.root), ".")
        if len(reason.encode()) > 1024:
            reason = reason.encode()[:1000].decode(errors="replace") + " [truncated]"
        self.failures.setdefault(stage, reason)
        pending = self.directory / "failure.next"
        pending.write_text(json.dumps({"failures": self.failures}, sort_keys=True) + "\n")
        pending.replace(self.directory / "failure.json")

    def record(self, event, **fields):
        record = {"event": event, "monotonic_ns": time.monotonic_ns(), **fields}
        raw = json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n"
        size = len(raw.encode())
        if (self.count >= MAX_EVENTS or size > MAX_EVENT_BYTES
                or self.bytes + size > MAX_LOG_BYTES):
            raise ValueError("observer evidence reached its fixed storage bound")
        self.stream.write(raw)
        self.count += 1
        self.bytes += size

    def retain_sources(self, records):
        for record in records:
            digest = record["sha256"]
            if digest in self.sources:
                continue
            body = read_local_file(self.root / record["path"], self.root, 65536)
            if len(body) != record["size_bytes"] or hashlib.sha256(body).hexdigest() != digest:
                raise ValueError("inspected fixture bytes changed before retention")
            if len(self.sources) >= MAX_SOURCE_FILES or self.source_bytes + len(body) > MAX_SOURCE_BYTES:
                raise RuntimeError("observer source archive reached its fixed storage bound")
            with (self.directory / (digest + ".source")).open("xb") as stream:
                stream.write(body)
            self.sources.add(digest)
            self.source_bytes += len(body)


class CaptureSession:
    def __init__(self, relative, native, root):
        if not re.fullmatch(r"\.artifacts/logs/fixture-kernel-capture/session-[0-9a-f]{32}", relative):
            raise ValueError("select one exact repository-local authenticated session")
        self.root, self.native = root, native
        self.directory = root / relative
        if self.directory.resolve() != self.directory:
            raise ValueError("authenticated session path is indirect")
        metadata = self.directory.stat()
        if (not stat.S_ISDIR(metadata.st_mode) or metadata.st_uid != os.getuid()
                or metadata.st_dev != root.stat().st_dev or stat.S_IMODE(metadata.st_mode) != 0o700):
            raise ValueError("authenticated session must be an owned private local directory")
        self.directory_identity = (metadata.st_dev, metadata.st_ino)
        state = self.state()
        if state.get("state") != "ready":
            raise ValueError("authenticated session is not ready")
        if state.get("producer_sha256") != hashlib.sha256(
                (root / "scripts/fixture_kernel_sampler.py").read_bytes()).hexdigest():
            raise ValueError("authenticated helper does not match the qualified producer")
        self.helper = state["helper"]
        if (not still_live(native, self.helper)
                or any(native.identity(self.helper["pid"])[key] != os.getuid() for key in ("uid", "ruid"))):
            raise ValueError("authenticated helper identity is unavailable or foreign")
        previous = state.get("last_request", 0)
        if type(previous) is not int or not 0 <= previous < sampler.MAX_REQUESTS:
            raise ValueError("authenticated session request capacity is exhausted")
        self.number = previous + 1
        self.submitted = False

    def state(self):
        metadata = self.directory.lstat()
        if (not stat.S_ISDIR(metadata.st_mode)
                or (metadata.st_dev, metadata.st_ino) != self.directory_identity):
            raise ValueError("authenticated session directory was replaced")
        return json.loads(read_local_file(self.directory / "session.json", self.root, 8192))

    def submit(self, request):
        state = self.state()
        if (self.submitted or state.get("state") != "ready"
                or identity_key(state["helper"]) != identity_key(self.helper)
                or state.get("last_request", 0) != self.number - 1
                or not still_live(self.native, self.helper)):
            raise ValueError("authenticated session changed or was already used")
        raw = (json.dumps(request, sort_keys=True) + "\n").encode()
        if len(raw) > sampler.REQUEST_BYTES:
            raise ValueError("capture request exceeds the helper's fixed bound")
        path = self.directory / ("request-%04d.json" % self.number)
        # Publish complete bytes atomically; never let the helper read a partial request.
        pending = self.directory / ("observer-" + uuid.uuid4().hex + ".pending")
        try:
            with pending.open("xb") as stream:
                stream.write(raw)
            os.link(pending, path)
            self.submitted = True
        finally:
            pending.unlink(missing_ok=True)

    def result(self):
        path = self.directory / ("capture-%04d" % self.number) / "result.json"
        try:
            return json.loads(read_local_file(path, self.root, 65536))
        except FileNotFoundError:
            return None

    def stop(self):
        state = self.state()
        if identity_key(state["helper"]) != identity_key(self.helper):
            raise ValueError("refusing to stop a replacement authenticated helper")
        path = self.directory / "STOP"
        try:
            with path.open("xb"):
                pass
        except FileExistsError:
            read_local_file(path, self.root, 1)

    def stopped(self):
        state = self.state()
        return (identity_key(state["helper"]) == identity_key(self.helper)
                and state.get("authentication_invalidated") is True
                and state.get("state") in ("stopped", "failed", "request_limit_reached")
                and not still_live(self.native, self.helper))


def request_for(chain):
    return {prefix + key: info[key] for prefix, info in zip(("", "parent_", "ancestor_"), chain)
            for key in sampler.IDENTITY_FIELDS}


def main_entry(evidence, root):
    if evidence["target_role"] != "legacy-producer":
        return "unknown"
    marker = root / (evidence["fixture"] + "-progress")
    try:
        body = read_local_file(marker, root, 64)
    except FileNotFoundError:
        return "not_observed"
    if body not in (b"entered\n", b"entered\ndrained\n"):
        raise ValueError("legacy main-entry marker is not a complete native progress record")
    return "drained" if body.endswith(b"drained\n") else "entered"


def observe(test, native, session, evidence, root):
    deadline = time.monotonic() + OBSERVATION_SECONDS
    seen, candidates, progress_seen = {}, {}, {}
    capture = None
    try:
        if (not still_live(native, test)
                or any(native.identity(test["pid"])[key] != os.getuid() for key in ("uid", "ruid"))
                or native.executable(test["pid"]) != Path("/usr/bin/perl").resolve()
                or not sampler._test_command(native.command(test["pid"]), sampler.SUPERVISOR_TEST_PATH, root)):
            raise ValueError("observer requires the exact normal-user T1669 invocation")
        evidence.record("attached", test=test, test_source=sampler.SUPERVISOR_TEST_PATH,
                        sampler_session=str(session.directory.relative_to(root)),
                        observer_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                        sampler_sha256=hashlib.sha256((root / "scripts/fixture_kernel_sampler.py").read_bytes()).hexdigest())
        while still_live(native, test):
            if time.monotonic() >= deadline:
                raise TimeoutError("observer wall expired; caller still owns the test")
            choices = []
            for pid in native.children(test["pid"]):
                try:
                    parent = native.identity(pid)
                    if parent["ppid"] != test["pid"]:
                        continue
                    sampler._supervisor_wrapper(native.command(pid), root)
                    chains = [[parent, test]]
                    for child_pid in native.children(pid):
                        child = native.identity(child_pid)
                        chains.insert(0, [child, parent, test])
                    for chain in chains:
                        request = request_for(chain)
                        admitted = sampler.validate_target(request, native, root)
                        key = identity_key(admitted["child"])
                        if key not in seen:
                            if len(seen) >= MAX_IDENTITIES:
                                raise RuntimeError("observer identity capacity reached")
                            evidence.retain_sources(admitted["sources"])
                            seen[key] = admitted["child"]
                            candidates[key] = time.monotonic()
                            evidence.record("candidate", evidence=admitted)
                        progress = main_entry(admitted, root)
                        if progress_seen.get(key) != progress:
                            evidence.record("main_entry", identity=admitted["child"], progress=progress)
                            progress_seen[key] = progress
                        if (not session.submitted and progress not in ("entered", "drained")
                                and time.monotonic() - candidates[key] >= CANDIDATE_SECONDS
                                and (len(chain) == 3 or len(chains) == 1)):
                            choices.append((request, admitted, progress))
                except (FileNotFoundError, ProcessLookupError):
                    continue
                except ValueError as error:
                    # Ordinary unrelated T1669 controls are outside this target policy.
                    # Record target races only after that native birth was admitted.
                    if any(info["pid"] == pid or info["ppid"] == pid for info in seen.values()):
                        evidence.record("candidate_rejected", pid=pid, reason=str(error).replace(str(root), "."))
                    continue
            if choices and not session.submitted:
                request, admitted, progress = choices[0]
                admitted = sampler.validate_target(request, native, root)
                evidence.retain_sources(admitted["sources"])
                progress = main_entry(admitted, root)
                if progress not in ("entered", "drained"):
                    session.submit(request)
                    evidence.record("capture_requested", request=request, evidence=admitted, main_entry=progress)
            if session.submitted and capture is None:
                capture = session.result()
                if capture is not None:
                    evidence.record("capture_result", result=capture)
            time.sleep(POLL_SECONDS)
        evidence.record("test_gone", test=test)
    except BaseException as error:
        evidence.problem("observation", error)
        raise
    finally:
        try:
            session.stop()
            settle_deadline = time.monotonic() + SETTLE_SECONDS
            while time.monotonic() < settle_deadline:
                if session.submitted and capture is None:
                    capture = session.result()
                    if capture is not None:
                        evidence.record("capture_result", result=capture)
                survivors = [info for info in seen.values() if still_live(native, info)]
                if not survivors and session.stopped():
                    break
                time.sleep(POLL_SECONDS)
            else:
                raise RuntimeError("observer could not verify selected fixture/helper shutdown")
            evidence.record("settled", observed_fixtures_gone=True, helper_stopped=True,
                            capture_received=capture is not None,
                            original_test_result="caller_owned", unobserved_descendants="unknown")
        except BaseException as error:
            evidence.problem("cleanup", error)
            raise
    if session.submitted and (capture is None or capture.get("rejected")
            or capture.get("sampler", {}).get("returncode") != 0
            or capture.get("sampler", {}).get("timeout")):
        raise RuntimeError("capture was rejected, failed or unavailable; inspect original evidence")
    return capture


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for key in sampler.IDENTITY_FIELDS:
        parser.add_argument("--test-" + key.replace("_", "-"), type=int, required=True)
    parser.add_argument("--session", required=True)
    args = parser.parse_args()
    if sys.platform != "darwin" or os.getuid() == 0 or os.geteuid() == 0:
        raise ValueError("the observer runs only as the normal user on Darwin")
    if os.environ.get("FSMGEN_RAM_GUARD_ACTIVE") != "1":
        raise ValueError("run this observer through scripts/run_with_ram_guard.sh")
    test = {key: getattr(args, "test_" + key) for key in sampler.IDENTITY_FIELDS}
    if not 1 < test["pid"] <= 2**31 - 1 or test["start_sec"] < 0 or not 0 <= test["start_usec"] < 1000000:
        raise ValueError("invalid native test identity")
    native = Processes()
    session = CaptureSession(args.session, native, ROOT)
    os.umask(0o077)
    evidence = Evidence(ROOT)
    print(str(evidence.directory.relative_to(ROOT)), flush=True)
    def interrupted(_signum, _frame):
        raise KeyboardInterrupt
    previous_term = signal.signal(signal.SIGTERM, interrupted)
    try:
        capture = observe(test, native, session, evidence, ROOT)
        evidence.record("complete", captured=capture is not None, qualification="not_claimed")
        return 0
    except (Exception, KeyboardInterrupt) as error:
        evidence.problem("final", error)
        print(str(error), file=sys.stderr)
        return 130 if isinstance(error, KeyboardInterrupt) else 1
    finally:
        signal.signal(signal.SIGTERM, previous_term)
        evidence.stream.close()


if __name__ == "__main__":
    raise SystemExit(main())
