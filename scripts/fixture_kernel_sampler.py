"""User-authenticated, fixed-command Darwin fixture sampling session.

This helper never launches tests. The diagnostic owner supplies a fresh request
only after identifying its own live fixture. No command or output path comes
from that request. Installed libproc, ps, sudo and spindump are OS dependencies.
"""

import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import signal
import stat
import subprocess
import sys
import time
import uuid


ROOT = Path(__file__).resolve().parent.parent
SESSION_SECONDS = 3600
MAX_REQUESTS = 16
REQUEST_BYTES = 2048
OUTPUT_BYTES = 16 * 1024 * 1024
TEST_PATH = "t/1668-darwin-inline-verilator-test-runtime.t"
SUPERVISOR_TEST_PATH = "t/1669-task-acceptance-fixture-runtime.t"
IDENTITY_FIELDS = ("pid", "start_sec", "start_usec")
REQUEST_FIELDS = (*IDENTITY_FIELDS, "parent_pid", "parent_start_sec",
                  "parent_start_usec")
ANCESTOR_FIELDS = tuple("ancestor_" + key for key in IDENTITY_FIELDS)


class BSDInfo(ctypes.Structure):
    _fields_ = [(name, ctypes.c_uint32) for name in (
        "flags", "status", "xstatus", "pid", "ppid", "uid", "gid",
        "ruid", "rgid", "svuid", "svgid", "reserved",
    )] + [("comm", ctypes.c_char * 16), ("name", ctypes.c_char * 32)] + [
        (name, ctypes.c_uint32) for name in ("nfiles", "pgid", "jobc", "tdev", "tpgid")
    ] + [("nice", ctypes.c_int32), ("start_sec", ctypes.c_uint64),
         ("start_usec", ctypes.c_uint64)]


class NativeProcesses:
    def __init__(self):
        self.library = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
        self.library.proc_pidinfo.argtypes = [ctypes.c_int, ctypes.c_int,
                                             ctypes.c_uint64, ctypes.c_void_p, ctypes.c_int]
        self.library.proc_pidinfo.restype = ctypes.c_int
        self.library.proc_pidpath.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32]
        self.library.proc_pidpath.restype = ctypes.c_int

    def identity(self, pid):
        info = BSDInfo()
        ctypes.set_errno(0)
        result = self.library.proc_pidinfo(pid, 3, 0, ctypes.byref(info), ctypes.sizeof(info))
        if result <= 0:
            raise OSError(ctypes.get_errno(), "native process identity unavailable")
        if result != ctypes.sizeof(info) or info.pid != pid:
            raise RuntimeError("native process identity ABI mismatch")
        return {key: getattr(info, key) for key in (*IDENTITY_FIELDS, "ppid", "uid", "ruid")}

    def executable(self, pid):
        buffer = ctypes.create_string_buffer(4096)
        ctypes.set_errno(0)
        if self.library.proc_pidpath(pid, buffer, len(buffer)) <= 0:
            raise OSError(ctypes.get_errno(), "native executable identity unavailable")
        return Path(os.fsdecode(buffer.value)).resolve()

    def command(self, pid):
        try:
            result = subprocess.run(
                ["/bin/ps", "-p", str(pid), "-o", "command="],
                stdin=subprocess.DEVNULL, capture_output=True, timeout=2, check=True,
            )
        except subprocess.CalledProcessError as error:
            if error.returncode != 1:
                raise
            # Even ps's observed no-match status needs native confirmation.
            # Only native absence supplies the gone-process exception callers
            # may skip. Live/reused PIDs, other exit statuses and query timeouts
            # remain errors; unavailable native identity also stays failed.
            self.identity(pid)
            raise
        return os.fsdecode(result.stdout).strip()


def local_directory(path, root):
    """Validate each existing component before creating any descendant."""
    relative = path.relative_to(root)
    current = root
    for component in relative.parts:
        current = current / component
        if current.is_symlink():
            raise ValueError("symbolic link in diagnostic output path")
        current.mkdir(exist_ok=True)
        if not current.is_dir() or current.stat().st_dev != root.stat().st_dev:
            raise ValueError("diagnostic output leaves the repository volume")
    return current


def read_request(path):
    with os.fdopen(os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK), "rb") as stream:
        metadata = os.fstat(stream.fileno())
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid():
            raise ValueError("request must be a regular file owned by this user")
        raw = stream.read(REQUEST_BYTES + 1)
    if len(raw) > REQUEST_BYTES:
        raise ValueError("request exceeds the fixed size limit")
    def unique_object(pairs):
        value = {}
        for key, item in pairs:
            if key in value:
                raise ValueError("duplicate request field")
            value[key] = item
        return value

    request = json.loads(raw, object_pairs_hook=unique_object)
    if not isinstance(request, dict) or set(request) not in (
            set(REQUEST_FIELDS), set((*REQUEST_FIELDS, *ANCESTOR_FIELDS))):
        raise ValueError("request fields do not match the closed schema")
    if any(type(value) is not int or value < 0 for value in request.values()):
        raise ValueError("request identity fields must be nonnegative integers")
    for field in ("pid", "parent_pid", "ancestor_pid"):
        if field in request and not 1 < request[field] <= 2**31 - 1:
            raise ValueError("process ID exceeds the native API range")
    return request


def source_identity(fixture, root):
    """Inspect a bounded direct source, retaining its filesystem and byte identity."""
    if fixture.resolve() != fixture or fixture.stat().st_dev != root.stat().st_dev:
        raise ValueError("fixture path is indirect or on a different volume")
    with os.fdopen(os.open(fixture, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK), "rb") as stream:
        metadata = os.fstat(stream.fileno())
        if (not stat.S_ISREG(metadata.st_mode) or metadata.st_dev != root.stat().st_dev
                or metadata.st_uid != os.getuid()):
            raise ValueError("fixture is not an owned repository-volume regular file")
        body = stream.read(65537)
        after = os.fstat(stream.fileno())
    if len(body) > 65536:
        raise ValueError("fixture is not a bounded regular source file")
    fields = ("st_dev", "st_ino", "st_mode", "st_uid", "st_size", "st_mtime_ns", "st_ctime_ns")
    before_identity = tuple(getattr(metadata, field) for field in fields)
    if any(tuple(getattr(info, field) for field in fields) != before_identity
           for info in (after, fixture.lstat())) or len(body) != metadata.st_size:
        raise ValueError("fixture changed during inspection")
    return {"path": str(fixture.relative_to(root)), "sha256": hashlib.sha256(body).hexdigest(),
            "device": metadata.st_dev, "inode": metadata.st_ino, "size_bytes": len(body)}


def _test_command(command, path, root):
    return command in ("/usr/bin/perl " + path, "/usr/bin/perl " + str(root / path))


def _workspace(command, root, includes=False, *, purpose="tests"):
    directory = root / ".artifacts/tmp" / purpose
    prefix = "/usr/bin/perl " + ("-Iperl -It/lib " if includes else "")
    prefix += str(directory) + "/"
    match = re.match(re.escape(prefix) + r"([A-Za-z0-9_-]+)/", command)
    if not match:
        raise ValueError("target is not a selected repository-local generated fixture")
    return directory / match[1]


def _supervisor_wrapper(command, root):
    """Literal argv shapes from T1669; no shell tokenization or free-form arguments."""
    includes = command.startswith("/usr/bin/perl -Iperl -It/lib ")
    # T1669 uses create_project_tempdir with this explicit purpose; T1668's
    # direct File::Temp fixture retains the separate default tests directory.
    workspace = _workspace(command, root, includes, purpose="process-supervisor-tests")
    if command == f"/usr/bin/perl -Iperl -It/lib {workspace}/rust-tool-resolution {workspace}/rust-tools":
        return "rust-wrapper", workspace, workspace / "rust-tool-resolution", None
    for mode in ("signal", "streams"):
        producer = workspace / ("legacy-ram-" + mode)
        if command == f"/usr/bin/perl {workspace}/legacy-ram-capture {workspace} {producer}":
            return "legacy-wrapper", workspace, workspace / "legacy-ram-capture", producer
    raise ValueError("parent is not a selected T1669 wrapper command")


def validate_target(request, native, root):
    """Admit a closed direct fixture or one exact T1669 wrapper/producer chain."""
    prefixes = ("", "parent_") + (("ancestor_",) if "ancestor_pid" in request else ())
    observations = []
    perl = Path("/usr/bin/perl").resolve()
    for prefix in prefixes:
        info = native.identity(request[prefix + "pid"])
        if any(info[key] != request[prefix + key] for key in IDENTITY_FIELDS):
            raise ValueError("stale or reused process identity")
        if any(info[key] != os.getuid() for key in ("uid", "ruid")):
            raise ValueError("fixture and test must run as this normal user")
        if native.executable(info["pid"]) != perl:
            raise ValueError("fixture and test must use the selected system Perl")
        observations.append((info, native.command(info["pid"])))
    for (child, _), (parent, _) in zip(observations, observations[1:]):
        if child["ppid"] != parent["pid"]:
            raise ValueError("fixture no longer belongs to the requested parent")

    target_command = observations[0][1]
    test_command = observations[-1][1]
    if len(observations) == 2 and _test_command(test_command, TEST_PATH, root):
        workspace = _workspace(target_command, root)
        fixture = workspace / "orphaning-runtime"
        if target_command != f"/usr/bin/perl {fixture}":
            raise ValueError("target is not the selected orphaning-runtime fixture")
        role, sources = "verilator-fixture", [fixture]
    elif _test_command(test_command, SUPERVISOR_TEST_PATH, root):
        wrapper_command = observations[-2][1]
        role, workspace, wrapper, producer = _supervisor_wrapper(wrapper_command, root)
        fixture, sources = wrapper, [wrapper]
        if producer is not None:
            sources.append(producer)
        if len(observations) == 3:
            if role == "rust-wrapper":
                fixture = workspace / "rust-tools/rustup"
                expected = f"/usr/bin/perl {fixture} which cargo"
                sources.append(fixture)
                role = "rust-proxy"
            else:
                fixture = producer
                expected = (f"/usr/bin/perl {fixture} --host-max-pct 88"
                            " --process-max-rss-mb 4096 --poll-seconds 0.02"
                            " --grace-seconds 0 -- unused")
                role = "legacy-producer"
            if target_command != expected:
                raise ValueError("target does not match its exact T1669 producer and workspace")
    else:
        raise ValueError("ancestor is not the selected T1668 or T1669 invocation")

    source_records = [source_identity(path, root) for path in sources]
    for info, command in observations:
        if (native.identity(info["pid"]) != info or native.executable(info["pid"]) != perl
                or native.command(info["pid"]) != command):
            raise ValueError("identity changed during inspection")
    fixture_record = next(record for record in source_records
                          if record["path"] == str(fixture.relative_to(root)))
    evidence = {"child": observations[0][0], "parent": observations[1][0],
                "fixture": fixture_record["path"], "fixture_sha256": fixture_record["sha256"],
                "target_role": role, "sources": source_records}
    if len(observations) == 3:
        evidence["ancestor"] = observations[2][0]
    return evidence


def bounded_wait(process, seconds):
    """Do not turn timeout cleanup into an unbounded wait."""
    try:
        return {"returncode": process.wait(timeout=seconds), "timeout": False}
    except (subprocess.TimeoutExpired, KeyboardInterrupt) as failure:
        try:
            process.terminate()
        except ProcessLookupError:
            pass
        try:
            code = process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            try:
                process.kill()
            except ProcessLookupError:
                pass
            try:
                code = process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                return {"returncode": None, "timeout": True, "unreaped_pid": process.pid}
        return {"returncode": code, "timeout": isinstance(failure, subprocess.TimeoutExpired),
                "interrupted": isinstance(failure, KeyboardInterrupt)}


def sudo_validation(interactive):
    argv = ["/usr/bin/sudo", "-v"] if interactive else ["/usr/bin/sudo", "-n", "-v"]
    # The RAM guard backgrounds its child. Use the controlling terminal explicitly
    # so authentication stays local even when inherited stdin is /dev/null.
    with open("/dev/tty", "r+b", buffering=0) as terminal:
        child = subprocess.Popen(argv, stdin=terminal, stdout=terminal, stderr=terminal)
        result = bounded_wait(child, 120 if interactive else 5)
    if result.get("interrupted"):
        raise KeyboardInterrupt
    if result["returncode"] != 0 or result["timeout"]:
        raise RuntimeError("administrator authentication unavailable or expired")


def capture(request, native, root, directory):
    try:
        evidence = validate_target(request, native, root)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        return {"rejected": True, "error": str(error)}
    argv = ["/usr/bin/sudo", "-n", "--preserve-env=TMPDIR,TMP,TEMP",
            "/usr/sbin/spindump", str(request["pid"]), "1", "10",
            "-onlyTarget", "-noFile", "-noBinary", "-noSymbolicate", "-timelimit", "3"]

    def output_limit():
        resource.setrlimit(resource.RLIMIT_FSIZE, (OUTPUT_BYTES, OUTPUT_BYTES))

    with (directory / "sample.txt").open("xb") as output, \
            (directory / "sampler.stderr").open("xb") as errors:
        child = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=output,
                                 stderr=errors, preexec_fn=output_limit)
        result = bounded_wait(child, 8)
    # A native sample is evidence to inspect, never an automatic diagnosis.
    return {**evidence, "sampler": result, "sudo_pid": child.pid,
            "sample_bytes": (directory / "sample.txt").stat().st_size}


def main():
    if sys.argv[1:]:
        raise ValueError("this helper accepts no command, PID or policy overrides")
    if sys.platform != "darwin" or os.getuid() == 0 or os.geteuid() == 0:
        raise ValueError("start this helper as your normal user on macOS")
    if os.environ.get("FSMGEN_RAM_GUARD_ACTIVE") != "1":
        raise ValueError("use bash scripts/await_fixture_kernel_samples.sh")
    for key in ("TMPDIR", "TMP", "TEMP"):
        if Path(os.environ.get(key, "")).resolve() != ROOT / ".artifacts/tmp":
            raise ValueError("project-local temporary environment is required")
    native = NativeProcesses()
    os.umask(0o077)
    base = local_directory(ROOT / ".artifacts/logs/fixture-kernel-capture", ROOT)
    directory = base / ("session-" + uuid.uuid4().hex)
    directory.mkdir()
    session = {"helper": native.identity(os.getpid()), "state": "authenticating",
               "producer_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    status_path = directory / "session.json"

    def publish():
        pending = directory / "session.next"
        pending.write_text(json.dumps(session, indent=2) + "\n")
        pending.replace(status_path)

    publish()
    def stop_on_termination(_signum, _frame):
        raise KeyboardInterrupt

    previous_term_handler = signal.signal(signal.SIGTERM, stop_on_termination)
    try:
        sudo_validation(True)
        deadline = time.monotonic() + SESSION_SECONDS
        refresh = time.monotonic() + 60
        session.update(state="ready", expires_epoch=time.time() + SESSION_SECONDS)
        publish()
        print("READY — diagnostic session: " + str(directory.relative_to(ROOT)), flush=True)
        print("Tell the engineer 'ready'. Leave this window open; Ctrl+C stops the session.", flush=True)
        for number in range(1, MAX_REQUESTS + 1):
            request_path = directory / ("request-%04d.json" % number)
            while not request_path.exists():
                if (directory / "STOP").exists() or time.monotonic() >= deadline:
                    session["state"] = "stopped"
                    return 0
                if time.monotonic() >= refresh:
                    sudo_validation(False)
                    refresh = time.monotonic() + 60
                time.sleep(0.2)
            if (directory / "STOP").exists() or time.monotonic() >= deadline:
                session["state"] = "stopped"
                return 0
            target_directory = directory / ("capture-%04d" % number)
            target_directory.mkdir()
            try:
                request = read_request(request_path)
            except (ValueError, OSError) as error:
                # A vanished/reused target is not permission to sample another PID.
                # Keep the rejection and require a new numbered request.
                result = {"rejected": True, "error": str(error)}
            else:
                # Errors after launch stop the session; they are not pre-launch rejections.
                result = capture(request, native, ROOT, target_directory)
            result_pending = target_directory / "result.next"
            result_pending.write_text(json.dumps(result, indent=2) + "\n")
            result_pending.replace(target_directory / "result.json")
            session["last_request"] = number
            publish()
            if result.get("rejected"):
                continue
            if result["sampler"].get("interrupted"):
                session["state"] = "stopped"
                return 130
            if result["sampler"]["returncode"] != 0 or result["sampler"]["timeout"]:
                raise RuntimeError("native capture failed; inspect retained output before another session")
        session["state"] = "request_limit_reached"
        return 0
    except KeyboardInterrupt:
        session["state"] = "stopped"
        return 130
    except Exception as error:
        session.update(state="failed", error=str(error))
        print("Diagnostic session stopped: " + str(error), file=sys.stderr)
        return 1
    finally:
        # Invalidate this session's sudo timestamp instead of leaving a renewal running.
        try:
            subprocess.run(["/usr/bin/sudo", "-k"], stdin=subprocess.DEVNULL, timeout=5, check=True)
            session["authentication_invalidated"] = True
        except (OSError, subprocess.SubprocessError) as error:
            session["authentication_cleanup_error"] = str(error)
        publish()
        signal.signal(signal.SIGTERM, previous_term_handler)


if __name__ == "__main__":
    raise SystemExit(main())
