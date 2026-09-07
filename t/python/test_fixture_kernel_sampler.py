"""Focused controls for the manual native-sampling boundary; no sudo is run."""

import copy
import errno
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import select
import signal
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "fixture_kernel_sampler", ROOT / "scripts/fixture_kernel_sampler.py")
SAMPLER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SAMPLER)


class NativeOracle:
    """Deterministic process observations; file identity remains a real OS input."""
    def __init__(self, root, fixture):
        self.processes = {
            100: {"pid": 100, "start_sec": 200, "start_usec": 300,
                  "ppid": 90, "uid": os.getuid(), "ruid": os.getuid()},
            90: {"pid": 90, "start_sec": 190, "start_usec": 290,
                 "ppid": 80, "uid": os.getuid(), "ruid": os.getuid()},
        }
        self.commands = {100: "/usr/bin/perl " + str(fixture),
                         90: "/usr/bin/perl " + SAMPLER.TEST_PATH}
        self.executables = {pid: Path("/usr/bin/perl").resolve() for pid in self.processes}

    def identity(self, pid):
        return dict(self.processes[pid])

    def executable(self, pid):
        return self.executables[pid]

    def command(self, pid):
        return self.commands[pid]


class CaptureBoundary(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory(
            prefix="capture-controls-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(self.workspace.cleanup)
        self.root = Path(self.workspace.name)
        self.fixture = self.root / ".artifacts/tmp/tests/controlled/orphaning-runtime"
        self.fixture.parent.mkdir(parents=True)
        self.fixture.write_text("#!/usr/bin/perl\nprint qq(controlled);\n")
        self.native = NativeOracle(self.root, self.fixture)
        self.request = {"pid": 100, "start_sec": 200, "start_usec": 300,
                        "parent_pid": 90, "parent_start_sec": 190, "parent_start_usec": 290}

    def test_command_query_distinguishes_native_absence_from_inspection_failure(self):
        native = object.__new__(SAMPLER.NativeProcesses)
        query_error = subprocess.CalledProcessError(1, ["/bin/ps", "-p", "100"])
        for number in (errno.ESRCH, errno.ENOENT, errno.EPERM):
            identity_error = OSError(number, "controlled native identity outcome")
            with self.subTest(errno=number):
                with patch.object(native, "identity", side_effect=identity_error) as identity, \
                        patch.object(SAMPLER.subprocess, "run", side_effect=query_error), \
                        self.assertRaises(OSError) as caught:
                    native.command(100)
                self.assertIs(caught.exception, identity_error)
                identity.assert_called_once_with(100)
        for birth in (200, 201):
            # A live birth, including one that replaced the caller's old birth,
            # cannot turn a command-query error into process disappearance.
            with self.subTest(birth=birth):
                with patch.object(native, "identity", return_value=dict(pid=100, start_sec=birth)) as identity, \
                        patch.object(SAMPLER.subprocess, "run", side_effect=query_error), \
                        self.assertRaises(subprocess.CalledProcessError) as caught:
                    native.command(100)
                self.assertIs(caught.exception, query_error)
                identity.assert_called_once_with(100)
        timeout = subprocess.TimeoutExpired(["/bin/ps"], 2)
        with patch.object(native, "identity") as identity, \
                patch.object(SAMPLER.subprocess, "run", side_effect=timeout), \
                self.assertRaises(subprocess.TimeoutExpired) as caught:
            native.command(100)
        self.assertIs(caught.exception, timeout)
        identity.assert_not_called()
        for status in (2, -signal.SIGTERM):
            failure = subprocess.CalledProcessError(status, ["/bin/ps"])
            with self.subTest(query_status=status):
                with patch.object(native, "identity", side_effect=ProcessLookupError(errno.ESRCH, "gone")) as identity, \
                        patch.object(SAMPLER.subprocess, "run", side_effect=failure), \
                        self.assertRaises(subprocess.CalledProcessError) as caught:
                    native.command(100)
                self.assertIs(caught.exception, failure)
                identity.assert_not_called()

    @unittest.skipUnless(sys.platform == "darwin", "Darwin native identity contract")
    def test_real_child_exit_between_identity_and_command_is_native_disappearance(self):
        child = subprocess.Popen(
            ["/usr/bin/perl", "-e", '$|=1; alarm 5; print "ready\\n"; scalar <STDIN>;'],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            self.assertTrue(select.select([child.stdout], [], [], 3)[0])
            self.assertEqual(os.read(child.stdout.fileno(), 64), b"ready\n")
            native = SAMPLER.NativeProcesses()
            admitted = native.identity(child.pid)
            self.assertEqual(admitted["ppid"], os.getpid())
            _, stderr = child.communicate(b"exit\n", timeout=3)
            self.assertEqual(child.returncode, 0, stderr.decode(errors="replace"))
            with self.assertRaises(ProcessLookupError) as caught:
                native.command(admitted["pid"])
            self.assertEqual(caught.exception.errno, errno.ESRCH)
        finally:
            if child.poll() is None:
                child.kill()
            child.communicate(timeout=3)

    def test_direct_fixture_retains_real_source_identity(self):
        first = SAMPLER.validate_target(self.request, self.native, self.root)
        self.fixture.write_text("#!/usr/bin/perl\nprint qq(changed);\n")
        changed = SAMPLER.validate_target(self.request, self.native, self.root)
        self.assertNotEqual(first["fixture_sha256"], changed["fixture_sha256"])
        self.assertEqual(first["fixture"], ".artifacts/tmp/tests/controlled/orphaning-runtime")

    def allocated_supervisor_workspace(self):
        """Exercise the unchanged allocator and original T1669 allocation call.

        Copy the module into this isolated repository-shaped root; neither the
        sampler's prefix nor this test's synthetic fixtures determine the path.
        Hold the allocating Perl process until controls finish so File::Temp
        keeps ownership of its directory and performs its ordinary cleanup.
        """
        module = self.root / "perl/FSM/ProjectDataLocality.pm"
        module.parent.mkdir(parents=True, exist_ok=True)
        module.write_bytes((ROOT / "perl/FSM/ProjectDataLocality.pm").read_bytes())
        (self.root / "README.md").touch()
        (self.root / "bin").mkdir(exist_ok=True)
        (self.root / "bin/fsmgen").touch()
        source = (ROOT / "t/1669-task-acceptance-fixture-runtime.t").read_text()
        calls = re.findall(r"my \$workspace = create_project_tempdir\([\s\S]*?\);", source)
        self.assertEqual(len(calls), 1, "original allocation must be unambiguous")
        program = "$|=1; alarm 15;\n" + calls[0] + '''
print "$workspace\\n";
read(STDIN, my $release, 1) == 1 or die "allocator release missing";
'''
        allocator = subprocess.Popen(
            ["/usr/bin/perl", "-Iperl", "-MFSM::ProjectDataLocality=create_project_tempdir",
             "-e", program], cwd=self.root, stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        workspace = None

        def finish():
            try:
                _, stderr = allocator.communicate(b"R", timeout=3)
                self.assertEqual(allocator.returncode, 0, stderr.decode(errors="replace"))
                if workspace is not None:
                    self.assertFalse(workspace.exists(), "real allocator cleanup was incomplete")
            finally:
                if allocator.poll() is None:
                    allocator.kill()
                    allocator.communicate(timeout=3)

        self.addCleanup(finish)
        output = b""
        deadline = time.monotonic() + 3
        while time.monotonic() < deadline and not output.endswith(b"\n"):
            if select.select([allocator.stdout], [], [], 0.1)[0]:
                data = os.read(allocator.stdout.fileno(), 4096)
                if not data:
                    break
                output += data
                self.assertLessEqual(len(output), 4096)
        self.assertTrue(output.endswith(b"\n"), "actual allocator did not report its directory")
        workspace = Path(os.fsdecode(output).strip())
        self.assertEqual(workspace.resolve(), workspace)
        self.assertIn(self.root, workspace.parents)
        self.assertEqual(workspace.stat().st_dev, self.root.stat().st_dev)
        return workspace

    def supervisor_chain(self, family, nested, workspace=None):
        if workspace is None:
            workspace = self.root / ".artifacts/tmp/process-supervisor-tests/controlled"
            workspace.mkdir(parents=True, exist_ok=True)
        if family == "rust":
            wrapper = workspace / "rust-tool-resolution"
            producer = workspace / "rust-tools/rustup"
            producer.parent.mkdir(exist_ok=True)
            wrapper_command = f"/usr/bin/perl -Iperl -It/lib {wrapper} {producer.parent}"
            producer_command = f"/usr/bin/perl {producer} which cargo"
        else:
            wrapper = workspace / "legacy-ram-capture"
            producer = workspace / ("legacy-ram-" + family)
            wrapper_command = f"/usr/bin/perl {wrapper} {workspace} {producer}"
            producer_command = (f"/usr/bin/perl {producer} --host-max-pct 88"
                                " --process-max-rss-mb 4096 --poll-seconds 0.02"
                                " --grace-seconds 0 -- unused")
        wrapper.write_text("wrapper source\n")
        producer.write_text("producer source\n")
        self.native.commands[100] = producer_command if nested else wrapper_command
        self.native.commands[90] = wrapper_command if nested else (
            "/usr/bin/perl " + SAMPLER.SUPERVISOR_TEST_PATH)
        if nested:
            self.native.processes[80] = {
                "pid": 80, "start_sec": 180, "start_usec": 280,
                "ppid": 70, "uid": os.getuid(), "ruid": os.getuid()}
            self.native.executables[80] = Path("/usr/bin/perl").resolve()
            self.native.commands[80] = "/usr/bin/perl " + SAMPLER.SUPERVISOR_TEST_PATH
            self.request.update(ancestor_pid=80, ancestor_start_sec=180, ancestor_start_usec=280)
        return wrapper, producer

    def test_t1669_commands_follow_the_actual_allocator(self):
        workspace = self.allocated_supervisor_workspace()
        for family in ("rust", "signal", "streams"):
            for nested in (False, True):
                with self.subTest(family=family, nested=nested):
                    self.native = NativeOracle(self.root, self.fixture)
                    self.request = {key: value for key, value in self.request.items()
                                    if key in SAMPLER.REQUEST_FIELDS}
                    wrapper, producer = self.supervisor_chain(family, nested, workspace)
                    evidence = SAMPLER.validate_target(self.request, self.native, self.root)
                    self.assertEqual(evidence["fixture"], str(
                        (producer if nested else wrapper).relative_to(self.root)))

    def test_t1669_rejects_the_former_wrong_root_and_unrelated_purposes(self):
        for family in ("rust", "signal", "streams"):
            self.supervisor_chain(family, False)
            command = self.native.commands[100]
            for purpose in ("tests", "runtime", "process-supervisor-tests-other",
                            "process-supervisor-tests/../tests"):
                wrong = command.replace("/process-supervisor-tests/", "/" + purpose + "/")
                with self.subTest(family=family, purpose=purpose), self.assertRaises(ValueError):
                    SAMPLER._supervisor_wrapper(wrong, self.root)

    def test_supervisor_wrappers_and_exact_producers_retain_each_source(self):
        for family in ("rust", "signal", "streams"):
            for nested in (False, True):
                with self.subTest(family=family, nested=nested):
                    self.native = NativeOracle(self.root, self.fixture)
                    self.request = {key: value for key, value in self.request.items()
                                    if key in SAMPLER.REQUEST_FIELDS}
                    wrapper, producer = self.supervisor_chain(family, nested)
                    result = SAMPLER.validate_target(self.request, self.native, self.root)
                    target = producer if nested else wrapper
                    self.assertEqual(result["fixture"], str(target.relative_to(self.root)))
                    expected_sources = {str(wrapper.relative_to(self.root))}
                    if nested or family != "rust":
                        expected_sources.add(str(producer.relative_to(self.root)))
                    self.assertEqual({item["path"] for item in result["sources"]}, expected_sources)
                    self.assertEqual("ancestor" in result, nested)
                    for record in result["sources"]:
                        self.assertEqual(record["sha256"], hashlib.sha256(
                            (self.root / record["path"]).read_bytes()).hexdigest())

    def test_nested_requests_require_the_complete_exact_ancestor_identity(self):
        self.supervisor_chain("rust", True)
        path = self.root / "request.json"
        path.write_text(json.dumps(self.request))
        self.assertEqual(SAMPLER.read_request(path), self.request)
        for field in SAMPLER.ANCESTOR_FIELDS:
            bad = dict(self.request)
            del bad[field]
            path.write_text(json.dumps(bad))
            with self.subTest(missing=field), self.assertRaises(ValueError):
                SAMPLER.read_request(path)
            bad = dict(self.request)
            bad[field] += 1
            if field == "ancestor_pid":
                self.native.processes[81] = {**self.native.processes[80], "pid": 81}
                self.native.executables[81] = Path("/usr/bin/perl").resolve()
                self.native.commands[81] = self.native.commands[80]
            with patch.object(SAMPLER.subprocess, "Popen") as launch:
                self.assertTrue(SAMPLER.capture(bad, self.native, self.root, self.root)["rejected"])
                launch.assert_not_called()

    def test_nested_wrong_command_workspace_user_executable_and_chain_reject(self):
        self.supervisor_chain("streams", True)
        for change in ("producer", "workspace", "wrapper", "test", "uid", "executable", "ancestry"):
            native = copy.deepcopy(self.native)
            if change == "producer":
                native.commands[100] += " --unexpected"
            elif change == "workspace":
                native.commands[100] = native.commands[100].replace("/controlled/", "/different/")
            elif change == "wrapper":
                native.commands[90] = native.commands[90].replace("legacy-ram-streams", "legacy-ram-signal")
            elif change == "test":
                native.commands[80] = "/usr/bin/perl " + SAMPLER.TEST_PATH
            elif change == "uid":
                native.processes[80]["uid"] += 1
            elif change == "executable":
                native.executables[90] = Path("/bin/sh")
            else:
                native.processes[90]["ppid"] = 1
            with self.subTest(change=change), patch.object(SAMPLER.subprocess, "Popen") as launch:
                self.assertTrue(SAMPLER.capture(self.request, native, self.root, self.root)["rejected"])
                launch.assert_not_called()

    def test_same_birth_exec_change_and_changed_intermediate_source_reject(self):
        wrapper, _ = self.supervisor_chain("rust", True)
        original = self.native.command
        calls = {}

        def replaced_command(pid):
            calls[pid] = calls.get(pid, 0) + 1
            return "/usr/bin/perl unrelated.pl" if calls[pid] > 1 else original(pid)

        self.native.command = replaced_command
        with self.assertRaisesRegex(ValueError, "identity changed"):
            SAMPLER.validate_target(self.request, self.native, self.root)
        self.native.command = original
        wrapper.unlink()
        wrapper.symlink_to(self.fixture)
        with self.assertRaisesRegex(ValueError, "indirect"):
            SAMPLER.validate_target(self.request, self.native, self.root)

    def test_reused_pid_foreign_parent_or_identity_never_launches_a_sampler(self):
        for field in SAMPLER.REQUEST_FIELDS:
            bad = dict(self.request)
            bad[field] += 1
            with self.subTest(field=field), patch.object(SAMPLER.subprocess, "Popen") as launch:
                if field in ("pid", "parent_pid"):
                    with self.assertRaises(KeyError):
                        SAMPLER.capture(bad, self.native, self.root, self.root)
                else:
                    self.assertTrue(SAMPLER.capture(bad, self.native, self.root, self.root)["rejected"])
                launch.assert_not_called()

    def test_identity_race_rejects_before_launch(self):
        original = self.native.identity
        calls = {}

        def reused_after_command(pid):
            calls[pid] = calls.get(pid, 0) + 1
            identity = original(pid)
            if calls[pid] > 1:
                identity["start_usec"] += 1
            return identity

        self.native.identity = reused_after_command
        with patch.object(SAMPLER.subprocess, "Popen") as launch:
            result = SAMPLER.capture(self.request, self.native, self.root, self.root)
            self.assertTrue(result["rejected"])
            self.assertIn("changed during inspection", result["error"])
            launch.assert_not_called()

    def test_real_filesystem_redirect_and_fifo_reject_without_blocking(self):
        other = self.root / "other.pl"
        other.write_text("foreign source")
        self.fixture.unlink()
        self.fixture.symlink_to(other)
        with self.assertRaisesRegex(ValueError, "indirect"):
            SAMPLER.validate_target(self.request, self.native, self.root)
        self.fixture.unlink()
        os.mkfifo(self.fixture)
        with self.assertRaisesRegex(ValueError, "regular file"):
            SAMPLER.validate_target(self.request, self.native, self.root)

    def test_unrelated_command_uid_executable_and_reparenting_reject(self):
        for change in ("command", "test", "uid", "executable", "parent"):
            native = copy.deepcopy(self.native)
            if change == "command":
                native.commands[100] += " --unexpected"
            elif change == "test":
                native.commands[90] = "/usr/bin/perl unrelated.t"
            elif change == "uid":
                native.processes[100]["ruid"] += 1
            elif change == "executable":
                native.executables[100] = Path("/bin/sh")
            else:
                native.processes[100]["ppid"] = 1
            with self.subTest(change=change), self.assertRaises(ValueError):
                SAMPLER.validate_target(self.request, native, self.root)

    def test_closed_request_refuses_duplicates_overflow_symlink_and_fifo(self):
        request = self.root / "request.json"
        request.write_text(json.dumps(self.request))
        self.assertEqual(SAMPLER.read_request(request), self.request)
        for text in ('{"pid":100,"pid":101}', "x" * (SAMPLER.REQUEST_BYTES + 1),
                     json.dumps({**self.request, "command": "/bin/sh"}),
                     json.dumps({**self.request, "pid": True}),
                     json.dumps({**self.request, "pid": 2**32 + 100})):
            request.write_text(text)
            with self.subTest(text=text[:50]), self.assertRaises(ValueError):
                SAMPLER.read_request(request)
        request.unlink()
        request.symlink_to(self.fixture)
        with self.assertRaises(OSError):
            SAMPLER.read_request(request)
        request.unlink()
        os.mkfifo(request)
        with self.assertRaisesRegex(ValueError, "regular file"):
            SAMPLER.read_request(request)

    def test_output_path_rejects_symlink_before_creating_descendants(self):
        (self.root / "redirect").symlink_to(self.fixture.parent, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "symbolic link"):
            SAMPLER.local_directory(self.root / "redirect/should-not-exist", self.root)
        self.assertFalse((self.fixture.parent / "should-not-exist").exists())

    def session_patches(self, directory, validations):
        from contextlib import ExitStack
        stack = ExitStack()
        self.addCleanup(stack.close)
        stack.enter_context(patch.object(SAMPLER, "ROOT", self.root))
        stack.enter_context(patch.object(SAMPLER.sys, "argv", ["fixture_kernel_sampler.py"]))
        stack.enter_context(patch.object(SAMPLER.sys, "platform", "darwin"))
        stack.enter_context(patch.object(SAMPLER.uuid, "uuid4", return_value=SimpleNamespace(hex="control")))
        stack.enter_context(patch.object(SAMPLER, "NativeProcesses", return_value=SimpleNamespace(
            identity=lambda pid: {"pid": pid, "start_sec": 1, "start_usec": 2})))
        stack.enter_context(patch.object(SAMPLER, "sudo_validation", side_effect=validations.append))
        stack.enter_context(patch.object(SAMPLER.subprocess, "run"))
        stack.enter_context(patch.dict(os.environ, {
            "FSMGEN_RAM_GUARD_ACTIVE": "1", **{key: str(self.root / ".artifacts/tmp")
            for key in ("TMPDIR", "TMP", "TEMP")}}))
        directory.parent.mkdir(parents=True, exist_ok=True)
        return stack

    def test_sequential_requests_authenticate_interactively_only_once(self):
        directory = self.root / ".artifacts/logs/fixture-kernel-capture/session-control"
        validations = []
        stack = self.session_patches(directory, validations)
        stack.enter_context(patch.object(SAMPLER, "MAX_REQUESTS", 2))

        def authenticate(interactive):
            validations.append(interactive)
            for number in (1, 2):
                (directory / ("request-%04d.json" % number)).write_text(json.dumps(self.request))

        stack.enter_context(patch.object(SAMPLER, "sudo_validation", side_effect=authenticate))
        launched = stack.enter_context(patch.object(SAMPLER, "capture", return_value={
            "sampler": {"returncode": 0, "timeout": False}}))
        self.assertEqual(SAMPLER.main(), 0)
        self.assertEqual(validations, [True])
        self.assertEqual(launched.call_count, 2)
        for number in (1, 2):
            self.assertTrue((directory / ("capture-%04d" % number) / "result.json").is_file())
        self.assertEqual(json.loads((directory / "session.json").read_text())["state"],
                         "request_limit_reached")

    def test_capture_result_never_exposes_a_partial_json_record(self):
        directory = self.root / ".artifacts/logs/fixture-kernel-capture/session-control"
        stack = self.session_patches(directory, [])
        stack.enter_context(patch.object(SAMPLER, "MAX_REQUESTS", 1))
        stack.enter_context(patch.object(SAMPLER, "sudo_validation", side_effect=lambda _: (
            directory / "request-0001.json").write_text(json.dumps(self.request))))
        stack.enter_context(patch.object(SAMPLER, "capture", return_value={
            "sampler": {"returncode": 0, "timeout": False}}))
        write = Path.write_text
        observed = []

        def interrupted_write(path, text, *args, **kwargs):
            if path.name not in ("result.json", "result.next"):
                return write(path, text, *args, **kwargs)
            with path.open("w") as stream:
                middle = len(text) // 2
                stream.write(text[:middle])
                stream.flush()
                public = path.parent / "result.json"
                observed.append(public.exists())
                self.assertFalse(public.exists(), "reader can see a partial published capture result")
                stream.write(text[middle:])
            return len(text)

        stack.enter_context(patch.object(Path, "write_text", interrupted_write))
        self.assertEqual(SAMPLER.main(), 0)
        self.assertEqual(observed, [False])
        self.assertEqual(json.loads((directory / "capture-0001/result.json").read_text())["sampler"]["returncode"], 0)

    def test_refresh_is_noninteractive_and_stop_ends_the_session(self):
        directory = self.root / ".artifacts/logs/fixture-kernel-capture/session-control"
        validations = []
        stack = self.session_patches(directory, validations)
        clock = iter(range(0, 1000, 31))
        stack.enter_context(patch.object(SAMPLER.time, "monotonic", side_effect=lambda: next(clock)))
        stack.enter_context(patch.object(SAMPLER.time, "sleep", side_effect=lambda _: (directory / "STOP").touch()))
        self.assertEqual(SAMPLER.main(), 0)
        self.assertEqual(validations, [True, False])
        state = json.loads((directory / "session.json").read_text())
        self.assertEqual(state["state"], "stopped")
        self.assertTrue(state["authentication_invalidated"])

    def test_expiry_stops_without_waiting_for_a_request(self):
        directory = self.root / ".artifacts/logs/fixture-kernel-capture/session-control"
        validations = []
        stack = self.session_patches(directory, validations)
        stack.enter_context(patch.object(SAMPLER, "SESSION_SECONDS", 1))
        clock = iter(range(10))
        stack.enter_context(patch.object(SAMPLER.time, "monotonic", side_effect=lambda: next(clock)))
        launched = stack.enter_context(patch.object(SAMPLER, "capture"))
        self.assertEqual(SAMPLER.main(), 0)
        launched.assert_not_called()
        self.assertEqual(validations, [True])

    def test_timeout_reaps_a_real_term_resistant_owned_child(self):
        read_end, write_end = os.pipe()
        child = subprocess.Popen(
            [sys.executable, "-B", "-c",
             "import os,signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); "
             "os.write(int(os.environ['CAPTURE_READY_FD']),b'r'); time.sleep(30)"],
            env={**os.environ, "CAPTURE_READY_FD": str(write_end)}, pass_fds=(write_end,))
        os.close(write_end)
        try:
            import select
            self.assertTrue(select.select([read_end], [], [], 3)[0], "child readiness absent")
            self.assertEqual(os.read(read_end, 1), b"r")
            result = SAMPLER.bounded_wait(child, 0.05)
            self.assertTrue(result["timeout"])
            self.assertEqual(result["returncode"], -signal.SIGKILL)
            with self.assertRaises(ChildProcessError):
                os.waitpid(child.pid, os.WNOHANG)
        finally:
            os.close(read_end)
            if child.poll() is None:
                child.kill()
                child.wait(timeout=3)

    @unittest.skipUnless(sys.platform == "darwin", "Darwin native identity contract")
    def test_real_t1669_wrappers_and_nested_producers_are_admitted(self):
        workspace = self.allocated_supervisor_workspace()
        for family in ("rust", "signal", "streams"):
            with self.subTest(family=family):
                self.assert_native_supervisor_chain(workspace, family)

    def assert_native_supervisor_chain(self, workspace, family):
        if family == "rust":
            producer = workspace / "rust-tools/rustup"
            producer.parent.mkdir()
            wrapper = workspace / "rust-tool-resolution"
            wrapper_body = '''
my $tool = shift(@ARGV) . '/rustup';
my $pid = fork(); defined $pid or die $!;
if (!$pid) { exec '/usr/bin/perl', $tool, 'which', 'cargo'; die $!; }
waitpid($pid, 0);
'''
            launch = "'/usr/bin/perl', '-Iperl', '-It/lib', " + \
                '"$workspace/rust-tool-resolution", "$workspace/rust-tools"'
            roles = ("rust-wrapper", "rust-proxy")
        else:
            producer = workspace / ("legacy-ram-" + family)
            wrapper = workspace / "legacy-ram-capture"
            wrapper_body = '''
my ($workspace, $tool) = @ARGV;
my $pid = fork(); defined $pid or die $!;
if (!$pid) { exec '/usr/bin/perl', $tool, '--host-max-pct', '88',
    '--process-max-rss-mb', '4096', '--poll-seconds', '0.02',
    '--grace-seconds', '0', '--', 'unused'; die $!; }
waitpid($pid, 0);
'''
            launch = "'/usr/bin/perl', " + \
                f'"$workspace/legacy-ram-capture", $workspace, "$workspace/legacy-ram-{family}"'
            roles = ("legacy-wrapper", "legacy-producer")
        producer.write_text('$|=1; alarm 10; print "producer=$$\\n"; sleep 8;\n')
        wrapper.write_text('$|=1; alarm 12; print "wrapper=$$\\n";\n' + wrapper_body)
        parent_path = self.root / SAMPLER.SUPERVISOR_TEST_PATH
        parent_path.parent.mkdir(exist_ok=True)
        parent_path.write_text('''alarm 14;
my $workspace = pack('H*', '%s');
my $pid = fork(); defined $pid or die $!;
if (!$pid) { exec %s; die $!; }
waitpid($pid, 0);
''' % (os.fsencode(workspace).hex(), launch))
        parent = subprocess.Popen(["/usr/bin/perl", str(parent_path)], stdout=subprocess.PIPE,
                                  start_new_session=True)
        native = SAMPLER.NativeProcesses()
        identities = {}
        try:
            output = b""
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline and len(identities) < 2:
                if select.select([parent.stdout], [], [], 0.1)[0]:
                    data = os.read(parent.stdout.fileno(), 128)
                    if not data:
                        break
                    output += data
                    self.assertLess(len(output), 512)
                    for line in output.splitlines():
                        if line.startswith((b"wrapper=", b"producer=")):
                            name, pid = line.decode().split("=")
                            identities[name] = native.identity(int(pid))
            self.assertEqual(set(identities), {"wrapper", "producer"},
                             "both controlled programs must independently enter main")
            test = native.identity(parent.pid)
            request = {key: identities["wrapper"][key] for key in SAMPLER.IDENTITY_FIELDS}
            request.update({"parent_" + key: test[key] for key in SAMPLER.IDENTITY_FIELDS})
            self.assertEqual(SAMPLER.validate_target(request, native, self.root)["target_role"],
                             roles[0])
            request = {key: identities["producer"][key] for key in SAMPLER.IDENTITY_FIELDS}
            request.update({"parent_" + key: identities["wrapper"][key]
                            for key in SAMPLER.IDENTITY_FIELDS})
            request.update({"ancestor_" + key: test[key] for key in SAMPLER.IDENTITY_FIELDS})
            evidence = SAMPLER.validate_target(request, native, self.root)
            self.assertEqual(evidence["target_role"], roles[1])
            self.assertEqual(evidence["ancestor"], test)
        finally:
            # Own one real process group for this control, including on missing readiness.
            try:
                os.killpg(parent.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            self.assertIsNotNone(SAMPLER.bounded_wait(parent, 3)["returncode"])
            parent.stdout.close()
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline:
                try:
                    os.killpg(parent.pid, 0)
                except ProcessLookupError:
                    break
                time.sleep(0.01)
            else:
                self.fail("native control process group cleanup incomplete")

    @unittest.skipUnless(sys.platform == "darwin", "Darwin native identity contract")
    def test_real_perl_fixture_and_parent_are_admitted(self):
        import select
        self.fixture.write_text("$|=1; alarm 8; print qq(child-ready\\n); sleep 6;\n")
        parent_path = self.root / SAMPLER.TEST_PATH
        parent_path.parent.mkdir()
        parent_path.write_text("""use strict; use warnings; use Cwd qw(abs_path); use FindBin;
my $fixture = abs_path("$FindBin::Bin/../.artifacts/tmp/tests/controlled/orphaning-runtime");
my $child = fork(); defined $child or die "fork: $!";
if (!$child) { exec '/usr/bin/perl', $fixture; die "exec: $!"; }
$|=1; alarm 8; print "$child\\n"; waitpid($child, 0);
""")
        parent = subprocess.Popen(["/usr/bin/perl", str(parent_path)], stdout=subprocess.PIPE)
        pid = None
        native = SAMPLER.NativeProcesses()
        try:
            output = b""
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline and (b"child-ready\n" not in output or pid is None):
                if select.select([parent.stdout], [], [], 0.1)[0]:
                    data = os.read(parent.stdout.fileno(), 128)
                    if not data:
                        break
                    output += data
                    self.assertLess(len(output), 512)
                    for line in output.splitlines():
                        if line.isdigit():
                            pid = int(line)
            self.assertIn(b"child-ready\n", output, "fixture main did not acknowledge readiness")
            self.assertIsNotNone(pid)
            child_identity = native.identity(pid)
            parent_identity = native.identity(parent.pid)
            request = {key: child_identity[key] for key in SAMPLER.IDENTITY_FIELDS}
            request.update({"parent_" + key: parent_identity[key] for key in SAMPLER.IDENTITY_FIELDS})
            evidence = SAMPLER.validate_target(request, native, self.root)
            self.assertEqual(evidence["child"]["pid"], pid)
            self.assertEqual(evidence["parent"]["pid"], parent.pid)
        finally:
            if pid is not None and parent.poll() is None:
                try:
                    os.kill(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            result = SAMPLER.bounded_wait(parent, 3)
            parent.stdout.close()
            self.assertIsNotNone(result["returncode"], "control parent cleanup incomplete")

    @unittest.skipUnless(sys.platform == "darwin", "Darwin native identity contract")
    def test_native_identity_matches_an_independently_forked_child(self):
        pid = os.fork()
        if pid == 0:
            signal.alarm(5)
            time.sleep(4)
            os._exit(0)
        try:
            native = SAMPLER.NativeProcesses()
            identity = native.identity(pid)
            self.assertEqual(identity["pid"], pid)
            self.assertEqual(identity["ppid"], os.getpid())
            self.assertEqual(identity["uid"], os.getuid())
        finally:
            os.kill(pid, signal.SIGKILL)
            deadline = time.monotonic() + 3
            found = 0
            while time.monotonic() < deadline:
                found, _ = os.waitpid(pid, os.WNOHANG)
                if found:
                    break
                time.sleep(0.01)
            self.assertEqual(found, pid, "owned child was not reaped within cleanup bound")
        with self.assertRaises(OSError):
            native.identity(pid)


if __name__ == "__main__":
    unittest.main()
