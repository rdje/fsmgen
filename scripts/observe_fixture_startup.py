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
RUST_CANDIDATE_SECONDS = 3.0
POLL_SECONDS = 0.1
MAX_CHILDREN = 64
MAX_IDENTITIES = 512
MAX_EVENTS = 4096
MAX_EVENT_BYTES = 16384
MAX_LOG_BYTES = 16 * 1024 * 1024
MAX_SOURCE_FILES = 64
MAX_SOURCE_BYTES = 4 * 1024 * 1024
TARGET_FAMILIES = ("all", "legacy", "rust")


def require_target_family(target_family):
    if target_family not in TARGET_FAMILIES:
        raise ValueError("target family must be all, legacy or rust")


def selected_target(admitted, target_family):
    if target_family == "all":
        return True
    roles = (("rust-wrapper", "rust-proxy") if target_family == "rust" else
             ("legacy-wrapper", "legacy-producer"))
    return admitted["target_role"] in roles


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


def main_entry(evidence, root, *, include_wrapper=False):
    role = evidence["target_role"]
    if role == "legacy-wrapper" and include_wrapper:
        # Admission retains the exact wrapper and its selected producer in
        # this order. This marker describes that producer, not wrapper entry.
        fixture = evidence["sources"][1]["path"]
    elif role == "legacy-producer":
        fixture = evidence["fixture"]
    else:
        return "unknown"
    marker = root / (fixture + "-progress")
    try:
        body = read_local_file(marker, root, 64)
    except FileNotFoundError:
        return "not_observed"
    if body not in (b"entered\n", b"entered\ndrained\n"):
        raise ValueError("legacy main-entry marker is not a complete native progress record")
    return "drained" if body.endswith(b"drained\n") else "entered"


class CheckpointProcesses:
    """Check caller policy between native inspections, including command queries."""

    def __init__(self, native, checkpoint):
        self.native, self.checkpoint = native, checkpoint

    def inspect(self, method, pid):
        if self.checkpoint is not None:
            self.checkpoint()
        result = method(pid)
        if self.checkpoint is not None:
            self.checkpoint()
        return result

    def identity(self, pid):
        return self.inspect(self.native.identity, pid)

    def executable(self, pid):
        return self.inspect(self.native.executable, pid)

    def command(self, pid):
        return self.inspect(self.native.command, pid)

    def children(self, pid):
        return self.inspect(self.native.children, pid)


class FixtureCensus:
    """Passive exact-fixture admission; callers own execution and capture policy.

    Scanning and read-only settlement are separate so a scan failure cannot
    prevent the enclosing caller from finishing its original test first.
    Authenticated observation retains its existing permissive rejection policy;
    the normal-user census additionally requires immutable admitted sources.
    """

    def __init__(self, test, native, evidence, root, *, checkpoint=None,
                 include_wrapper_progress=True, strict=True):
        self.test, self.raw_native, self.evidence, self.root = test, native, evidence, root
        self.native = CheckpointProcesses(native, checkpoint)
        self.include_wrapper_progress, self.strict = include_wrapper_progress, strict
        self.seen, self.admitted, self.first_seen, self.progress_seen = {}, {}, {}, {}
        if (not still_live(self.native, test)
                or any(self.native.identity(test["pid"])[key] != os.getuid() for key in ("uid", "ruid"))
                or self.native.executable(test["pid"]) != Path("/usr/bin/perl").resolve()
                or not sampler._test_command(self.native.command(test["pid"]), sampler.SUPERVISOR_TEST_PATH, root)):
            raise ValueError("observer requires the exact normal-user T1669 invocation")

    def scan(self):
        entries = []
        for pid in self.native.children(self.test["pid"]):
            try:
                parent = self.native.identity(pid)
                if parent["ppid"] != self.test["pid"]:
                    continue
                sampler._supervisor_wrapper(self.native.command(pid), self.root)
                chains = [[parent, self.test]]
                for child_pid in self.native.children(pid):
                    child = self.native.identity(child_pid)
                    chains.insert(0, [child, parent, self.test])
                for chain in chains:
                    request = request_for(chain)
                    admitted = sampler.validate_target(request, self.native, self.root)
                    key = identity_key(admitted["child"])
                    if key not in self.seen:
                        if len(self.seen) >= MAX_IDENTITIES:
                            raise RuntimeError("observer identity capacity reached")
                        # Remember admission before any archival/journal failure:
                        # the caller still needs to settle this observed birth.
                        self.seen[key] = admitted["child"]
                        self.admitted[key] = admitted
                        self.evidence.retain_sources(admitted["sources"])
                        # Preserve authenticated capture eligibility: archival
                        # time is not part of its post-retention observation.
                        self.first_seen[key] = time.monotonic()
                        self.evidence.record("candidate", evidence=admitted)
                    elif self.strict and admitted != self.admitted[key]:
                        raise RuntimeError("fixture identity or source changed for an observed native birth")
                    progress = main_entry(admitted, self.root, include_wrapper=self.include_wrapper_progress)
                    if self.progress_seen.get(key) != progress:
                        self.evidence.record("main_entry", identity=admitted["child"], progress=progress,
                                             progress_scope="selected_producer" if (
                                                 self.include_wrapper_progress and admitted["target_role"] == "legacy-wrapper"
                                             ) else "target")
                        self.progress_seen[key] = progress
                    entries.append({"request": request, "evidence": admitted, "progress": progress,
                                    "leaf": len(chain) == 3 or len(chains) == 1,
                                    "observed_at": time.monotonic()})
            except (FileNotFoundError, ProcessLookupError):
                continue
            except ValueError as error:
                # Unrelated T1669 controls are outside this exact target policy.
                known = any(info["pid"] == pid or info["ppid"] == pid for info in self.seen.values())
                if known:
                    self.evidence.record("candidate_rejected", pid=pid,
                                         reason=str(error).replace(str(self.root), "."))
                    if self.strict:
                        raise RuntimeError("observed fixture rejected: " + str(error)) from error
                continue
        return entries

    def require_coverage(self):
        if not self.seen:
            raise RuntimeError("no fixture was observed; coverage is unestablished")

    def survivors(self):
        # The original and collector may already be settled; inspection here
        # must not depend on their earlier scan-time checkpoints.
        return [info for info in self.seen.values() if still_live(self.raw_native, info)]

    def settle(self):
        deadline = time.monotonic() + SETTLE_SECONDS
        while self.survivors():
            if time.monotonic() >= deadline:
                raise RuntimeError("observer could not verify observed fixture cleanup")
            time.sleep(POLL_SECONDS)
        return {"observed_fixtures_gone": True, "observed_fixture_count": len(self.seen),
                "unobserved_descendants": "unknown"}


def observe(test, native, session, evidence, root, *, stop_session=True, target_family="all",
            check_collection=None):
    """Settle observed fixtures; an enclosing sequence may own helper shutdown."""
    deadline = time.monotonic() + OBSERVATION_SECONDS
    census, seen = None, {}
    selected_seen = set()
    capture = None
    try:
        require_target_family(target_family)
        # Rust-only observation reserves the sole request for a longer-lived
        # candidate. This observed interval establishes neither main entry nor
        # an eventual timeout, and never changes the original test's deadlines.
        candidate_seconds = RUST_CANDIDATE_SECONDS if target_family == "rust" else CANDIDATE_SECONDS
        census = FixtureCensus(test, native, evidence, root,
                               include_wrapper_progress=target_family == "legacy", strict=False)
        seen = census.seen
        evidence.record("attached", test=test, test_source=sampler.SUPERVISOR_TEST_PATH,
                        target_family=target_family, candidate_seconds=candidate_seconds,
                        sampler_session=str(session.directory.relative_to(root)),
                        observer_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                        sampler_sha256=hashlib.sha256((root / "scripts/fixture_kernel_sampler.py").read_bytes()).hexdigest())
        while still_live(native, test):
            if check_collection is not None:
                check_collection()
            if time.monotonic() >= deadline:
                raise TimeoutError("observer wall expired; caller still owns the test")
            choices = []
            for entry in census.scan():
                admitted, progress = entry["evidence"], entry["progress"]
                key = identity_key(admitted["child"])
                if (selected_target(admitted, target_family) and not session.submitted
                        and progress not in ("entered", "drained")
                        and entry["observed_at"] - census.first_seen[key] >= candidate_seconds
                        and entry["leaf"]):
                    choices.append((entry["request"], admitted, progress))
            selected_seen.update(key for key, admitted in census.admitted.items()
                                 if selected_target(admitted, target_family))
            if choices and not session.submitted:
                for request, admitted, progress in choices:
                    try:
                        admitted = sampler.validate_target(request, native, root)
                        evidence.retain_sources(admitted["sources"])
                        progress = main_entry(admitted, root, include_wrapper=target_family == "legacy")
                    except (FileNotFoundError, ProcessLookupError):
                        # A selected fixture can finish before final validation,
                        # just as during census. No request has been published.
                        continue
                    if selected_target(admitted, target_family) and progress not in ("entered", "drained"):
                        session.submit(request)
                        evidence.record("capture_requested", request=request, evidence=admitted,
                                        main_entry=progress, target_family=target_family,
                                        progress_scope="selected_producer" if (
                                            target_family == "legacy" and admitted["target_role"] == "legacy-wrapper"
                                        ) else "target")
                        break
            if session.submitted and capture is None:
                capture = session.result()
                if capture is not None:
                    evidence.record("capture_result", result=capture)
            time.sleep(POLL_SECONDS)
        if check_collection is not None:
            check_collection()
        evidence.record("test_gone", test=test)
        if not selected_seen:
            raise RuntimeError("no selected fixture was observed; coverage is unestablished")
    except BaseException as error:
        evidence.problem("observation", error)
        raise
    finally:
        try:
            if stop_session:
                session.stop()
            settle_deadline = time.monotonic() + SETTLE_SECONDS
            while time.monotonic() < settle_deadline:
                if session.submitted and capture is None:
                    capture = session.result()
                    if capture is not None:
                        evidence.record("capture_result", result=capture)
                survivors = census.survivors() if census is not None else []
                helper_settled = session.stopped() if stop_session else (
                    not session.submitted or capture is not None)
                if not survivors and helper_settled:
                    break
                time.sleep(POLL_SECONDS)
            else:
                boundary = "selected fixture/helper shutdown" if stop_session else (
                    "selected fixture cleanup and capture settlement")
                raise RuntimeError("observer could not verify " + boundary)
            evidence.record("settled", observed_fixtures_gone=True,
                            helper_stopped=stop_session,
                            helper_shutdown_owner="observer" if stop_session else "caller",
                            observed_fixture_count=len(seen),
                            selected_fixture_count=len(selected_seen), target_family=target_family,
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
    parser.add_argument("--target-family", choices=TARGET_FAMILIES, default="all")
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
        capture = observe(test, native, session, evidence, ROOT, target_family=args.target_family)
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
