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
IDENTITY_FIELDS = ("pid", "start_sec", "start_usec")
REQUEST_FIELDS = (*IDENTITY_FIELDS, "parent_pid", "parent_start_sec",
                  "parent_start_usec")


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
        result = subprocess.run(
            ["/bin/ps", "-p", str(pid), "-o", "command="],
            stdin=subprocess.DEVNULL, capture_output=True, timeout=2, check=True,
        )
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
    if not isinstance(request, dict) or set(request) != set(REQUEST_FIELDS):
        raise ValueError("request fields do not match the closed schema")
    if any(type(value) is not int or value < 0 for value in request.values()):
        raise ValueError("request identity fields must be nonnegative integers")
    if request["pid"] <= 1 or request["parent_pid"] <= 1:
        raise ValueError("request requires actual child and parent identities")
    if request["pid"] > 2**31 - 1 or request["parent_pid"] > 2**31 - 1:
        raise ValueError("process ID exceeds the native API range")
    return request


def validate_target(request, native, root):
    """Bind a direct orphaning-runtime fixture to the exact live T1668 parent."""
    child = native.identity(request["pid"])
    parent = native.identity(request["parent_pid"])
    for key in IDENTITY_FIELDS:
        if child[key] != request[key] or parent[key] != request["parent_" + key]:
            raise ValueError("stale or reused process identity")
    if child["ppid"] != parent["pid"]:
        raise ValueError("fixture no longer belongs to the requested parent")
    if any(info[key] != os.getuid() for info in (child, parent) for key in ("uid", "ruid")):
        raise ValueError("fixture and test must run as this normal user")
    perl = Path("/usr/bin/perl").resolve()
    if any(native.executable(info["pid"]) != perl for info in (child, parent)):
        raise ValueError("fixture and test must use the selected system Perl")
    if native.command(parent["pid"]) not in (
        "/usr/bin/perl " + TEST_PATH, "/usr/bin/perl " + str(root / TEST_PATH),
    ):
        raise ValueError("parent is not the selected T1668 invocation")
    command = native.command(child["pid"])
    prefix = "/usr/bin/perl " + str(root / ".artifacts/tmp/tests") + "/"
    if not command.startswith(prefix):
        raise ValueError("target is not a repository-local generated fixture")
    suffix = command[len(prefix):].split("/")
    if len(suffix) != 2 or not suffix[0] or suffix[1] != "orphaning-runtime":
        raise ValueError("target is not the selected orphaning-runtime fixture")
    fixture = root / ".artifacts/tmp/tests" / suffix[0] / suffix[1]
    if fixture.resolve() != fixture or fixture.stat().st_dev != root.stat().st_dev:
        raise ValueError("fixture path is indirect or on a different volume")
    with os.fdopen(os.open(fixture, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK), "rb") as stream:
        metadata = os.fstat(stream.fileno())
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_dev != root.stat().st_dev:
            raise ValueError("fixture is not a repository-volume regular file")
        body = stream.read(65537)
    if len(body) > 65536:
        raise ValueError("fixture is not a bounded regular source file")
    if native.identity(child["pid"]) != child or native.identity(parent["pid"]) != parent:
        raise ValueError("identity changed during inspection")
    return {"child": child, "parent": parent,
            "fixture": str(fixture.relative_to(root)),
            "fixture_sha256": hashlib.sha256(body).hexdigest()}


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
            (target_directory / "result.json").write_text(json.dumps(result, indent=2) + "\n")
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
