"""Fixed policy-only caller controls with real children and no authentication."""

import contextlib
import io
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import run_fixture_startup_policy_observation as policy_caller
import test_fixture_startup_launcher as fixtures

launcher = policy_caller.launcher


class PolicyOnlyControls(unittest.TestCase):
    program = fixtures.LauncherControls.program
    policy_body = fixtures.LauncherControls.policy_body
    events = fixtures.LauncherControls.events

    def setUp(self):
        workspace = tempfile.TemporaryDirectory(prefix="policy-caller-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(workspace.cleanup)
        self.root = Path(workspace.name)
        (self.root / "t").mkdir()
        self.native = launcher.OwnedProcesses() if sys.platform == "darwin" else fixtures.PortableProcesses()
        self.evidence = launcher.observer.Evidence(self.root)
        self.addCleanup(self.evidence.stream.close)
        self.real_popen = subprocess.Popen
        fixtures.install_policy_control(self, self.root, scope="execution_context")
        controlled_popen = subprocess.Popen
        blocked = patch.object(subprocess, "Popen", side_effect=lambda argv, **kwargs:
                               self.allowed_spawn(controlled_popen, argv, **kwargs))
        blocked.start()
        self.addCleanup(blocked.stop)
        # These traps also protect a future refactor from quietly requiring the
        # authenticated path. No test helper/session is constructed here.
        for owner, name in ((launcher.observer, "CaptureSession"), (launcher, "stop_helper"),
                            (launcher.observer.sampler, "capture"),
                            (launcher.observer.sampler, "sudo_validation")):
            trap = patch.object(owner, name, side_effect=AssertionError("policy-only caller requested authentication"))
            trap.start()
            self.addCleanup(trap.stop)
        self.children = []
        gated = launcher.GatedTest
        self.gated_class = gated

        def start(*args, **kwargs):
            child = gated(*args, **kwargs)
            self.children.append(child)
            return child

        tracked = patch.object(launcher, "GatedTest", side_effect=start)
        tracked.start()
        self.addCleanup(tracked.stop)
        self.addCleanup(self.close_children)
        self.program()

    def allowed_spawn(self, popen, argv, **kwargs):
        self.assertTrue(argv[:2] == ["/usr/bin/log", "stream"] or argv[:1] == ["/bin/ps"], argv)
        return popen(argv, **kwargs)

    def close_children(self):
        for child in self.children:
            child.finish(cancel=True)

    def run_caller(self):
        return policy_caller.run(self.native, self.evidence, self.root)

    def original(self):
        return json.loads((self.evidence.directory / "test-result.json").read_text())

    def check_closed(self):
        self.assertEqual(len(self.children), 1, "exactly one original invocation is permitted")
        child = self.children[0]
        self.assertTrue(self.original()["leader_reaped"])
        with self.assertRaises(ChildProcessError):
            os.waitpid(child.pid, os.WNOHANG)
        retained = json.loads((self.evidence.directory / "policy-result.json").read_text())
        self.assertTrue(retained["leader_reaped"])
        with self.assertRaises(ChildProcessError):
            os.waitpid(retained["identity"]["pid"], os.WNOHANG)
        self.assertFalse(launcher.observer.still_live(self.native, child.identity))

    def context_body(self):
        journal = (self.evidence.directory / "observations.jsonl").relative_to(self.root)
        return self.policy_body() + "\nopen my $context, '<', '" + str(journal) + "' or die $!;\n" + r'''
my $matched = 0;
while (my $line = <$context>) {
    my $row = decode_json($line);
    next unless $row->{event} eq 'observer_ready' && $row->{test}{pid} == $$;
    die 'not policy-only context' unless $row->{mode} eq 'policy_only'
        && $row->{scope} eq 'execution_context'
        && $row->{policy_readiness}{scope} eq 'execution_context';
    $matched++;
}
close $context or die $!;
die 'missing or repeated readiness' unless $matched == 1;
'''

    def test_actual_body_verifies_context_preparation_before_its_single_release(self):
        self.program(body=self.context_body())
        result = self.run_caller()
        self.assertEqual(result["returncode"], 0)
        self.assertEqual((self.root / "body-entered").read_text(), "ready\n")
        self.assertEqual((self.evidence.directory / "test.tap").read_text(), "ok 1 - controlled body\n1..1\n")
        self.assertEqual((self.evidence.directory / "test.stderr").read_text(), "separate stderr\n")
        rows = self.events()
        self.assertEqual(sum(row["event"] == "policy_observation_started" for row in rows), 1)
        self.assertEqual(sum(row["event"] == "test_release" for row in rows), 1)
        completed = next(row for row in rows if row["event"] == "caller_complete")
        self.assertEqual(completed["qualification"], "not_claimed")
        self.assertEqual(completed["kernel_sample"], "not_collected")
        self.assertEqual(completed["fixture_native_identity"], "not_observed")
        self.check_closed()

    def test_original_nonzero_stays_failed_without_another_invocation(self):
        self.program(exit_code=23, body=self.context_body())
        with self.assertRaisesRegex(RuntimeError, "original test failed"):
            self.run_caller()
        self.assertEqual(self.original()["returncode"], 23)
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.assertEqual(launcher.retained_policy_result(self.evidence, scope="execution_context")["failures"], {})
        self.check_closed()

    def test_original_failure_oracle_rejects_laundered_success(self):
        original_finish = self.gated_class.finish

        def launder(test, *args, **kwargs):
            return dict(original_finish(test, *args, **kwargs), returncode=0)

        with patch.object(self.gated_class, "finish", launder), \
                self.assertRaisesRegex(AssertionError, "RuntimeError not raised"):
            self.test_original_nonzero_stays_failed_without_another_invocation()
        self.assertEqual(self.original()["native_wait_status"], 23 << 8)
        self.check_closed()

    def test_preparation_failure_prevents_test_fork_and_preserves_collector_failure(self):
        (self.root / "controlled-policy.pl").write_text(
            '$|=1; $SIG{INT}=sub {exit 0}; alarm 10; print "wrong header\\n"; sleep 5;\n')
        with self.assertRaisesRegex(RuntimeError, "policy collection"):
            self.run_caller()
        self.assertEqual(self.children, [])
        self.assertFalse((self.root / "body-entered").exists())
        retained = json.loads((self.evidence.directory / "policy-result.json").read_text())
        self.assertTrue(retained["leader_reaped"])
        self.assertIn("native filter header", retained["failures"]["prepare"])

    def test_collector_zero_exit_cannot_promote_original_success(self):
        self.program(body=self.policy_body("kill 'INT', $collector or die $!;"), pause="0.4")
        with self.assertRaisesRegex(RuntimeError, "policy collection"):
            self.run_caller()
        self.assertEqual(self.original()["returncode"], 0)
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.check_closed()

    def test_forced_collector_cleanup_cannot_promote_original_success(self):
        path = self.root / "controlled-policy.pl"
        path.write_text(path.read_text().replace('$SIG{INT}=sub { exit 0 }', '$SIG{INT}="IGNORE"'))
        with patch.object(launcher.policy_log, "REAP_SECONDS", 0.1), \
                self.assertRaisesRegex(RuntimeError, "policy collection"):
            self.run_caller()
        self.assertEqual(self.original()["returncode"], 0)
        self.assertTrue(json.loads((self.evidence.directory / "policy-result.json").read_text())["forced_kill"])
        self.check_closed()

    def test_original_deadline_preserves_timeout_and_reaps_term_resistant_child(self):
        self.program(body=self.context_body(), pause="5")
        with patch.object(launcher, "TEST_SECONDS", 0.15), patch.object(launcher, "REAP_SECONDS", 0.1), \
                self.assertRaisesRegex(RuntimeError, "original test failed"):
            self.run_caller()
        self.assertTrue(self.original()["timeout"])
        self.assertEqual(self.original()["returncode"], -signal.SIGKILL)
        self.check_closed()

    def test_interrupt_after_release_closes_both_owners_without_success(self):
        with patch.object(launcher, "wait_for_exec", side_effect=KeyboardInterrupt), self.assertRaises(KeyboardInterrupt):
            self.run_caller()
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.check_closed()

    def test_changed_retained_output_is_failed_after_original_result_is_saved(self):
        finish = launcher.policy_log.PolicyLog.finish

        def changed(collector):
            result = finish(collector)
            with (collector.directory / "policy.stdout").open("ab") as stream:
                stream.write(b"unreported\n")
            return result

        with patch.object(launcher.policy_log.PolicyLog, "finish", changed), \
                self.assertRaisesRegex(RuntimeError, "retained output changed"):
            self.run_caller()
        self.assertEqual(self.original()["returncode"], 0)
        self.check_closed()

    def test_journal_failure_after_settlement_keeps_physical_cleanup_proof(self):
        record = self.evidence.record

        def full(event, **fields):
            if event == "policy_settled":
                raise RuntimeError("controlled full journal")
            return record(event, **fields)

        with patch.object(self.evidence, "record", side_effect=full), \
                self.assertRaisesRegex(RuntimeError, "controlled full journal"):
            self.run_caller()
        self.assertEqual(launcher.retained_policy_result(self.evidence, scope="execution_context")["failures"], {})
        self.check_closed()

    @unittest.skipUnless(sys.platform == "darwin", "actual normal-user OS log lifecycle")
    def test_native_collector_and_actual_body_agree_on_prepared_context(self):
        self.program(body=self.context_body())
        with patch.object(subprocess, "Popen", side_effect=lambda argv, **kwargs:
                          self.allowed_spawn(self.real_popen, argv, **kwargs)):
            self.assertEqual(self.run_caller()["returncode"], 0)
        self.check_closed()

    def test_cli_has_no_session_or_command_override_and_requires_guarded_normal_user(self):
        for arguments in (["--session", "unused"], ["--command", "unused"]):
            with self.subTest(arguments=arguments), patch.object(sys, "argv", ["policy-observation", *arguments]), \
                    contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as error:
                policy_caller.main()
            self.assertEqual(error.exception.code, 2)
        with patch.object(sys, "argv", ["policy-observation"]), patch.object(sys, "platform", "darwin"):
            with patch.object(os, "getuid", return_value=0), self.assertRaisesRegex(ValueError, "normal user"):
                policy_caller.main()
            with patch.object(os, "getuid", return_value=501), patch.object(os, "geteuid", return_value=501), \
                    patch.dict(os.environ, {"FSMGEN_RAM_GUARD_ACTIVE": "0"}), \
                    self.assertRaisesRegex(ValueError, "run this caller through"):
                policy_caller.main()
        self.assertEqual(self.children, [])

    def check_main(self, original_exit, expected_exit):
        self.program(exit_code=original_exit, body=self.context_body())
        previous_handler = signal.getsignal(signal.SIGTERM)
        previous_umask = os.umask(0o077)
        os.umask(previous_umask)
        output, errors = io.StringIO(), io.StringIO()
        with patch.object(policy_caller, "ROOT", self.root), \
                patch.object(launcher, "OwnedProcesses", return_value=self.native), \
                patch.object(launcher.observer, "Evidence", return_value=self.evidence), \
                patch.object(sys, "argv", ["policy-observation"]), \
                patch.dict(os.environ, {"FSMGEN_RAM_GUARD_ACTIVE": "1"}), \
                contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
            self.assertEqual(policy_caller.main(), expected_exit)
        self.assertEqual(signal.getsignal(signal.SIGTERM), previous_handler)
        actual_umask = os.umask(previous_umask)
        self.assertEqual(actual_umask, previous_umask)
        self.assertTrue(self.evidence.stream.closed)
        self.assertEqual(output.getvalue().strip(), str(self.evidence.directory.relative_to(self.root)))
        self.assertEqual(self.original()["returncode"], original_exit)
        if expected_exit:
            self.assertIn("original test failed", errors.getvalue())
            self.assertIn("final", json.loads((self.evidence.directory / "failure.json").read_text())["failures"])
        else:
            self.assertEqual(errors.getvalue(), "")
        self.check_closed()

    @unittest.skipUnless(sys.platform == "darwin", "actual normal-user Darwin entrypoint")
    def test_main_success_closes_journal_and_restores_caller_state(self):
        self.check_main(0, 0)

    @unittest.skipUnless(sys.platform == "darwin", "actual normal-user Darwin entrypoint")
    def test_main_reports_failure_after_preserving_original_and_cleanup(self):
        self.check_main(23, 1)


if __name__ == "__main__":
    unittest.main()
