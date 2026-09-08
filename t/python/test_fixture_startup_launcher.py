"""Actual held-child ordering and cleanup controls; no authenticated sampling."""

import errno
import contextlib
import io
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import run_fixture_startup_observation as launcher


def install_policy_control(case, root):
    """Replace only the OS stream with a real held, unprivileged producer."""
    source = root / "controlled-policy.pl"
    source.write_text('use strict; use warnings; $|=1; $SIG{INT}=sub { exit 0 }; alarm 30;\n'
                      'print "Filtering the log data using controlled fixture predicate\\n";\n'
                      'while (1) { select undef, undef, undef, 0.05; }\n')
    popen, processes = subprocess.Popen, []

    def spawn(argv, **kwargs):
        if argv[:2] == ["/usr/bin/log", "stream"]:
            case.assertEqual(argv, launcher.policy_log.command(root))
            process = popen(["/usr/bin/perl", str(source)], **kwargs)
            processes.append(process)
            return process
        return popen(argv, **kwargs)

    def close():
        for process in processes:
            if process.poll() is None:
                process.kill()
            process.wait(timeout=2)

    replaced = patch.object(launcher.policy_log.subprocess, "Popen", side_effect=spawn)
    replaced.start()
    case.addCleanup(replaced.stop)
    case.addCleanup(close)


class PortableProcesses:
    """Model only birth metadata off Darwin; pipe/exec/wait controls remain real."""

    def __init__(self):
        self.test = None

    def identity(self, pid):
        if self.test is not None and pid == self.test.pid and self.test.poll() is not None:
            raise ProcessLookupError(errno.ESRCH, "owned child reaped")
        return dict(pid=pid, start_sec=100, start_usec=20,
                    ppid=os.getpid() if pid != os.getpid() else os.getppid(),
                    uid=os.getuid(), ruid=os.getuid())

    def executable(self, _pid):
        return Path("/usr/bin/perl").resolve()

    def command(self, _pid):
        return " ".join(launcher.TEST_ARGV)

    def children(self, _pid):
        return []


class Session:
    def __init__(self, native, root):
        self.helper = native.identity(os.getpid())
        self.directory = root / ".artifacts/logs/fixture-kernel-capture/session-control"
        self.submitted = False
        self.ready = True
        self.number, self.cursor = 1, 0
        self.stop_calls = 0

    def state(self):
        return dict(state="ready" if self.ready else "stopped", helper=self.helper,
                    last_request=self.cursor)

    def stop(self):
        self.stop_calls += 1

    def stopped(self):
        return self.stop_calls > 0


class LauncherControls(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory(prefix="launcher-controls-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(self.workspace.cleanup)
        self.root = Path(self.workspace.name)
        (self.root / "t").mkdir()
        (self.root / "scripts").mkdir()
        (self.root / "scripts/fixture_kernel_sampler.py").write_bytes(
            (ROOT / "scripts/fixture_kernel_sampler.py").read_bytes())
        self.native = launcher.OwnedProcesses() if sys.platform == "darwin" else PortableProcesses()
        self.session = Session(self.native, self.root)
        self.evidence = launcher.observer.Evidence(self.root)
        self.addCleanup(self.evidence.stream.close)
        install_policy_control(self, self.root)
        self.program()

    def program(self, exit_code=0, body="", pause="0.3"):
        journal = (self.evidence.directory / "observations.jsonl").relative_to(self.root)
        (self.root / launcher.TEST_ARGV[1]).write_text("""
use strict;
use warnings;
use Time::HiRes qw(sleep);
$SIG{TERM} = 'IGNORE';
""" + "open my $journal, '<', '" + str(journal) + "' or die $!;\n" + """
my $ready = grep { /"event":"observer_ready"/ } <$journal>;
close $journal or die $!;
open my $marker, '>>', 'body-entered' or die $!;
print {$marker} $ready ? "ready\\n" : "unprepared\\n";
close $marker or die $!;
$| = 1;
print STDOUT "ok 1 - controlled body\\n1..1\\n";
print STDERR "separate stderr\\n";
""" + body + "\nsleep " + pause + ";\nexit " + str(exit_code) + ";\n")

    def held_test(self):
        test = launcher.GatedTest(self.native, self.root, self.evidence.directory)
        self.native.test = test
        self.addCleanup(lambda: test.finish(cancel=True))
        return test

    def wait_for_body(self):
        deadline = time.monotonic() + 2
        marker = self.root / "body-entered"
        while not marker.exists() and time.monotonic() < deadline:
            time.sleep(0.01)
        self.assertTrue(marker.exists(), "independent test body did not enter")
        return marker

    def run_launcher(self):
        return launcher.run(self.session, self.native, self.evidence, self.root)

    def events(self):
        return [json.loads(row) for row in (self.evidence.directory / "observations.jsonl").read_text().splitlines()]

    def test_delayed_readiness_cannot_release_the_independent_test_body(self):
        self.program(exit_code=23)
        test = self.held_test()

        def prepare():
            time.sleep(0.15)
            self.assertFalse((self.root / "body-entered").exists())
            self.assertIsNone(test.poll())
            self.evidence.record("observer_ready")
            return time.monotonic_ns()

        witness = test.release(prepare)
        launcher.wait_for_exec(test, self.native, self.root)
        self.assertEqual(self.wait_for_body().read_text(), "ready\n")
        self.assertGreaterEqual(witness["child_release_ns"], witness["ready_ns"])
        self.assertEqual(witness["exec_success"], "not_established")
        with self.assertRaisesRegex(ValueError, "already released"):
            test.release(prepare)
        result = test.finish()
        self.assertEqual(result["returncode"], 23)
        self.assertFalse(result["timeout"])
        self.assertEqual((self.evidence.directory / "test.stderr").read_bytes(), b"separate stderr\n")
        with self.assertRaises(ChildProcessError):
            os.waitpid(test.pid, os.WNOHANG)

    def test_failed_readiness_never_executes_the_test(self):
        test = self.held_test()
        with self.assertRaisesRegex(RuntimeError, "preparation failed"):
            test.release(lambda: (_ for _ in ()).throw(RuntimeError("preparation failed")))
        test.close_gate()
        result = test.finish()
        self.assertEqual(result["returncode"], 125)
        self.assertFalse(result["released"])
        self.assertFalse((self.root / "body-entered").exists())

    def test_independent_readiness_oracle_rejects_a_premature_release(self):
        def premature(test, prepare):
            os.write(test.gate, b"R")
            test.released = True
            test.close_gate()
            deadline = time.monotonic() + 2
            while not (test.root / "body-entered").exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            return prepare()

        control = type(self)("test_delayed_readiness_cannot_release_the_independent_test_body")
        result = unittest.TestResult()
        with patch.object(launcher.GatedTest, "release", premature):
            control.run(result)
        self.assertEqual(result.errors, [])
        self.assertEqual(len(result.failures), 1)
        self.assertIn("True is not false", result.failures[0][1])

    def test_changed_birth_is_rejected_before_exec_release(self):
        test = self.held_test()
        identity = self.native.identity

        def changed(pid):
            info = identity(pid)
            if pid == test.pid:
                info["start_usec"] += 1
            return info

        with patch.object(self.native, "identity", side_effect=changed), \
                self.assertRaisesRegex(ValueError, "identity changed"):
            test.release(time.monotonic_ns)
        self.assertFalse(test.released)
        self.assertFalse((self.root / "body-entered").exists())

    def test_original_success_and_ordering_are_retained_with_owned_reaping(self):
        # This minimal ordering body creates no selected fixtures. Isolate a
        # successful observer result here; real missing coverage is tested below.
        with patch.object(launcher.observer, "observe", return_value=None) as observed:
            result = self.run_launcher()
        observed.assert_called_once()
        self.assertEqual(result["returncode"], 0)
        self.assertTrue(result["leader_reaped"])
        rows = self.events()
        ready = next(row for row in rows if row["event"] == "observer_ready")
        released = next(row for row in rows if row["event"] == "test_release")
        self.assertGreaterEqual(released["witness"]["child_release_ns"], ready["monotonic_ns"])
        self.assertEqual(rows[-1]["event"], "caller_complete")
        self.assertEqual(rows[-1]["qualification"], "not_claimed")
        self.assertGreater(self.session.stop_calls, 0)
        self.assertEqual(json.loads((self.evidence.directory / "test-result.json").read_text()), result)
        self.assertFalse((self.evidence.directory / "test-result.next").exists())
        self.assertEqual(len((self.root / "body-entered").read_text().splitlines()), 1)
        self.assertEqual((self.root / "body-entered").read_text(), "ready\n")

    def test_selected_family_is_retained_before_release_and_reaches_observer(self):
        with patch.object(launcher.observer, "observe", return_value=None) as observed:
            result = launcher.run(self.session, self.native, self.evidence, self.root,
                                  target_family="legacy")
        self.assertEqual(result["returncode"], 0)
        self.assertEqual(observed.call_args.kwargs["target_family"], "legacy")
        ready = next(row for row in self.events() if row["event"] == "observer_ready")
        self.assertEqual(ready["target_family"], "legacy")
        self.assertEqual((self.root / "body-entered").read_text(), "ready\n")

    def test_invalid_family_prevents_fork_and_release_but_stops_helper(self):
        with patch.object(launcher, "GatedTest") as child, \
                self.assertRaisesRegex(ValueError, "target family must be"):
            launcher.run(self.session, self.native, self.evidence, self.root, target_family="rust")
        child.assert_not_called()
        self.assertFalse((self.root / "body-entered").exists())
        self.assertGreater(self.session.stop_calls, 0)

    def test_original_failure_is_not_promoted_by_successful_observation(self):
        self.program(exit_code=23)
        with patch.object(launcher.observer, "observe", return_value=None), \
                self.assertRaisesRegex(RuntimeError, "original test failed"):
            self.run_launcher()
        result = json.loads((self.evidence.directory / "test-result.json").read_text())
        self.assertEqual(result["returncode"], 23)
        self.assertTrue(result["leader_reaped"])
        self.assertEqual(launcher.retained_policy_result(self.evidence)["failures"], {})
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))

    def policy_body(self, action=""):
        journal = str((self.evidence.directory / "observations.jsonl").relative_to(self.root))
        return "use JSON::PP qw(decode_json);\nopen my $events, '<', '" + journal + "' or die $!;\n" + r'''
my ($collector, $prepared, $ready);
while (my $line = <$events>) {
    my $row = decode_json($line);
    next unless $row->{event} eq 'observer_ready' && $row->{test}{pid} == $$;
    $collector = $row->{policy_readiness}{identity}{pid};
    $prepared = $row->{policy_readiness}{prepared_ns};
    $ready = $row->{ready_ns};
}
close $events or die $!;
die 'policy was not prepared before release' unless $collector && $prepared <= $ready;
die 'collector is not alive at test entry' unless kill 0, $collector;
open my $proof, '>', 'policy-body-proof' or die $!;
print {$proof} "$collector $prepared $ready\n" or die $!;
close $proof or die $!;
''' + action

    def test_actual_body_verifies_policy_preparation_and_live_collector_before_entry(self):
        self.program(body=self.policy_body())
        with patch.object(launcher.observer, "observe", return_value=None):
            result = self.run_launcher()
        collector_pid, prepared, ready = map(int, (self.root / "policy-body-proof").read_text().split())
        retained = launcher.retained_policy_result(self.evidence)
        self.assertEqual(retained["identity"]["pid"], collector_pid)
        self.assertLessEqual(prepared, ready)
        self.assertEqual(result["returncode"], 0)
        with self.assertRaises(ChildProcessError):
            os.waitpid(collector_pid, os.WNOHANG)
        self.assertGreater(self.session.stop_calls, 0)

    def test_failed_policy_preparation_prevents_test_fork_and_closes_both_owners(self):
        (self.root / "controlled-policy.pl").write_text(
            '$|=1; $SIG{INT}=sub { exit 0 }; alarm 10; print "wrong header\\n"; sleep 5;\n')
        with patch.object(launcher, "GatedTest") as child, self.assertRaisesRegex(RuntimeError, "policy collection"):
            self.run_launcher()
        child.assert_not_called()
        self.assertFalse((self.root / "body-entered").exists())
        retained = json.loads((self.evidence.directory / "policy-result.json").read_text())
        self.assertTrue(retained["leader_reaped"])
        self.assertIn("native filter header", retained["failures"]["prepare"])
        self.assertGreater(self.session.stop_calls, 0)

    def test_early_collector_zero_exit_preserves_successful_original_tap_as_separate_evidence(self):
        self.program(body=self.policy_body("kill 'INT', $collector or die $!;"), pause="1")
        with self.assertRaisesRegex(RuntimeError, "policy collection"):
            self.run_launcher()
        original = json.loads((self.evidence.directory / "test-result.json").read_text())
        retained = json.loads((self.evidence.directory / "policy-result.json").read_text())
        self.assertEqual(original["returncode"], 0)
        self.assertTrue(original["leader_reaped"])
        self.assertEqual(retained["returncode"], 0)
        self.assertTrue(retained["leader_reaped"])
        self.assertIn("exited before requested shutdown", retained["failures"]["collection"])
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.assertGreater(self.session.stop_calls, 0)

    def test_forced_collector_cleanup_cannot_promote_original_success(self):
        path = self.root / "controlled-policy.pl"
        path.write_text(path.read_text().replace('$SIG{INT}=sub { exit 0 }', '$SIG{INT}="IGNORE"'))
        with patch.object(launcher.observer, "observe", return_value=None), \
                patch.object(launcher.policy_log, "REAP_SECONDS", 0.1), \
                self.assertRaisesRegex(RuntimeError, "policy collection"):
            self.run_launcher()
        retained = json.loads((self.evidence.directory / "policy-result.json").read_text())
        self.assertTrue(retained["leader_reaped"])
        self.assertTrue(retained["forced_kill"])
        self.assertEqual(json.loads((self.evidence.directory / "test-result.json").read_text())["returncode"], 0)
        self.assertGreater(self.session.stop_calls, 0)

    def test_changed_retained_output_is_rejected_before_caller_success(self):
        finish = launcher.policy_log.PolicyLog.finish

        def changed(collector):
            result = finish(collector)
            with (collector.directory / "policy.stdout").open("ab") as stream:
                stream.write(b"unreported bytes\n")
            return result

        with patch.object(launcher.observer, "observe", return_value=None), \
                patch.object(launcher.policy_log.PolicyLog, "finish", changed), \
                self.assertRaisesRegex(RuntimeError, "retained output changed"):
            self.run_launcher()
        self.assertEqual(json.loads((self.evidence.directory / "test-result.json").read_text())["returncode"], 0)
        self.assertGreater(self.session.stop_calls, 0)

    def test_passing_test_cannot_promote_missing_fixture_coverage(self):
        with self.assertRaisesRegex(RuntimeError, "no selected fixture was observed"):
            self.run_launcher()
        result = json.loads((self.evidence.directory / "test-result.json").read_text())
        self.assertEqual(result["returncode"], 0, "original passing TAP remains separate")
        self.assertTrue(result["leader_reaped"])
        self.assertGreater(self.session.stop_calls, 0)
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.assertIn("no selected fixture", json.loads(
            (self.evidence.directory / "failure.json").read_text())["failures"]["observation"])

    def test_expired_helper_prevents_release_and_is_stopped(self):
        self.session.ready = False
        with self.assertRaisesRegex(ValueError, "helper changed"):
            self.run_launcher()
        self.assertGreater(self.session.stop_calls, 0)
        self.assertFalse((self.root / "body-entered").exists())
        result = json.loads((self.evidence.directory / "test-result.json").read_text())
        self.assertFalse(result["released"])
        self.assertTrue(result["leader_reaped"])

    def test_unwritable_readiness_evidence_prevents_release(self):
        with patch.object(launcher.observer, "MAX_EVENTS", 0), \
                self.assertRaisesRegex(ValueError, "storage bound"):
            self.run_launcher()
        self.assertFalse((self.root / "body-entered").exists())
        self.assertGreater(self.session.stop_calls, 0)
        self.assertTrue((self.evidence.directory / "failure.json").exists())

    def test_changed_request_cursor_prevents_test_release(self):
        self.session.cursor = 1
        with self.assertRaisesRegex(ValueError, "helper changed"):
            self.run_launcher()
        self.assertFalse((self.root / "body-entered").exists())
        self.assertGreater(self.session.stop_calls, 0)

    def test_observer_failure_preserves_the_original_result_without_retry(self):
        with patch.object(launcher.observer, "observe", side_effect=RuntimeError("observer unavailable")), \
                self.assertRaisesRegex(RuntimeError, "observer unavailable"):
            self.run_launcher()
        self.assertEqual(json.loads((self.evidence.directory / "test-result.json").read_text())["returncode"], 0)
        self.assertEqual(len((self.root / "body-entered").read_text().splitlines()), 1)
        self.assertGreater(self.session.stop_calls, 0)

    def test_reported_test_cleanup_failure_still_stops_the_helper(self):
        finish = launcher.GatedTest.finish

        def failed_report(test, *args, **kwargs):
            finish(test, *args, **kwargs)
            raise RuntimeError("injected cleanup report failure")

        with patch.object(launcher.GatedTest, "finish", failed_report), \
                self.assertRaisesRegex(RuntimeError, "test cleanup"):
            self.run_launcher()
        self.assertGreater(self.session.stop_calls, 0)
        self.assertEqual(self.native.test.poll(), 0)
        self.assertIn("test cleanup", json.loads((self.evidence.directory / "failure.json").read_text())["failures"]["cleanup"])

    def test_term_resistant_owned_child_is_killed_and_reaped_within_cleanup(self):
        self.program(pause="10")
        test = self.held_test()
        test.release(time.monotonic_ns)
        self.wait_for_body()
        test.deadline = time.monotonic() + 0.05
        with patch.object(launcher, "REAP_SECONDS", 0.05):
            result = test.finish()
        self.assertEqual(result["returncode"], -signal.SIGKILL)
        self.assertTrue(result["timeout"])
        with self.assertRaises(ChildProcessError):
            os.waitpid(test.pid, os.WNOHANG)

    def test_native_file_cap_keeps_runaway_test_output_bounded(self):
        self.program(body="print STDOUT 'x' x 4096;", pause="0")
        with patch.object(launcher, "OUTPUT_BYTES", 128):
            test = self.held_test()
        test.release(time.monotonic_ns)
        result = test.finish()
        self.assertNotEqual(result["returncode"], 0)
        self.assertLessEqual((self.evidence.directory / "test.tap").stat().st_size, 128)

    def test_missing_exit_identity_is_not_signalled_before_the_bounded_reap(self):
        test = self.held_test()
        with patch.object(self.native, "identity", side_effect=ProcessLookupError(errno.ESRCH, "exiting")), \
                patch.object(launcher.os, "kill") as kill:
            test._signal(signal.SIGTERM)
        kill.assert_not_called()
        test.close_gate()
        self.assertEqual(test.finish()["returncode"], 125)

    def test_python_ignored_sigpipe_does_not_leak_into_the_test(self):
        self.program(body="kill 'PIPE', $$; die 'ignored SIGPIPE leaked';", pause="0")
        test = self.held_test()
        test.release(time.monotonic_ns)
        self.assertEqual(test.finish()["returncode"], -signal.SIGPIPE)

    def test_failed_evidence_preparation_stops_helper_without_forking(self):
        output = io.StringIO()
        with patch.object(launcher.sys, "argv", ["launcher", "--session", "controlled"]), \
                patch.object(launcher.sys, "platform", "darwin"), \
                patch.object(launcher.os, "getuid", return_value=501), \
                patch.object(launcher.os, "geteuid", return_value=501), \
                patch.object(launcher.os, "umask"), \
                patch.dict(os.environ, {"FSMGEN_RAM_GUARD_ACTIVE": "1"}), \
                patch.object(launcher, "OwnedProcesses", return_value=self.native), \
                patch.object(launcher.observer, "CaptureSession", return_value=self.session), \
                patch.object(launcher.observer, "Evidence", side_effect=OSError("unavailable evidence")), \
                patch.object(launcher, "GatedTest") as child, contextlib.redirect_stderr(output):
            self.assertEqual(launcher.main(), 1)
        child.assert_not_called()
        self.assertEqual(self.session.stop_calls, 1)
        self.assertIn("unavailable evidence", output.getvalue())

    def test_partial_pipe_creation_closes_exact_fds_and_stops_helper(self):
        pipe = os.pipe
        gated_test = launcher.GatedTest
        descriptors = []

        def fail_second_pipe():
            if descriptors:
                raise OSError(errno.EMFILE, "injected descriptor exhaustion")
            pair = pipe()
            descriptors.extend(pair)
            return pair

        def reserve(*args, **kwargs):
            with patch.object(launcher.os, "pipe", side_effect=fail_second_pipe):
                return gated_test(*args, **kwargs)

        try:
            with patch.object(launcher, "GatedTest", side_effect=reserve), \
                    self.assertRaisesRegex(OSError, "descriptor exhaustion"):
                self.run_launcher()
            self.assertEqual(self.session.stop_calls, 1)
            for descriptor in descriptors:
                with self.assertRaises(OSError) as error:
                    os.fstat(descriptor)
                self.assertEqual(error.exception.errno, errno.EBADF)
        finally:
            for descriptor in descriptors:
                try:
                    os.close(descriptor)
                except OSError as error:
                    if error.errno != errno.EBADF:
                        raise


if __name__ == "__main__":
    unittest.main()
