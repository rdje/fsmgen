"""Fixed policy-only caller controls with real children and no authentication."""

import contextlib
import errno
import hashlib
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


class PortableFixtureProcesses(fixtures.PortableProcesses):
    """Model native inspections off Darwin using a real reported process tree."""

    def __init__(self, root):
        super().__init__()
        self.root = root
        self.workspace = root / ".artifacts/tmp/process-supervisor-tests/caller-control"

    def records(self):
        result = {}
        for role in ("wrapper", "producer"):
            path = self.workspace / (role + ".json")
            if path.exists():
                result[role] = json.loads(path.read_text())
        return result

    @staticmethod
    def live(pid):
        try:
            os.kill(pid, 0)
            return True
        except ProcessLookupError:
            return False

    def identity(self, pid):
        for record in self.records().values():
            if record["pid"] == pid:
                if not self.live(pid):
                    raise ProcessLookupError(errno.ESRCH, "reported control child is gone")
                return dict(super().identity(pid), ppid=record["ppid"])
        return super().identity(pid)

    def children(self, pid):
        return [record["pid"] for record in self.records().values()
                if record["ppid"] == pid and self.live(record["pid"])]

    def command(self, pid):
        for role, record in self.records().items():
            if record["pid"] == pid:
                if role == "wrapper":
                    return f"/usr/bin/perl -Iperl -It/lib {self.workspace}/rust-tool-resolution {self.workspace}/rust-tools"
                return f"/usr/bin/perl {self.workspace}/rust-tools/rustup which cargo"
        return super().command(pid)


class PolicyOnlyControls(unittest.TestCase):
    policy_body = fixtures.LauncherControls.policy_body
    events = fixtures.LauncherControls.events

    def setUp(self):
        workspace = tempfile.TemporaryDirectory(prefix="policy-caller-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(workspace.cleanup)
        self.root = Path(workspace.name)
        (self.root / "t").mkdir()
        self.native = launcher.OwnedProcesses() if sys.platform == "darwin" else PortableFixtureProcesses(self.root)
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

    def program(self, exit_code=0, body="", pause="0.3", *, with_fixture=True):
        if with_fixture:
            workspace = self.root / ".artifacts/tmp/process-supervisor-tests/caller-control"
            (workspace / "rust-tools").mkdir(parents=True, exist_ok=True)
            prefix = r'''
use strict;
use warnings;
use Cwd qw(getcwd);
use JSON::PP qw(encode_json decode_json);
$SIG{TERM} = 'DEFAULT';
alarm 12;
my $workspace = getcwd() . '/.artifacts/tmp/process-supervisor-tests/caller-control';
sub report_identity {
    my ($name) = @_;
    open my $out, '>', "$workspace/$name.next" or die $!;
    print {$out} encode_json({pid => $$, ppid => getppid()}) or die $!;
    close $out or die $!;
    rename "$workspace/$name.next", "$workspace/$name.json" or die $!;
}
'''
            wrapper = prefix + r'''
report_identity('wrapper');
system '/usr/bin/perl', "$workspace/rust-tools/rustup", 'which', 'cargo';
die 'controlled producer failed' if $? != 0;
'''
            journal = (self.evidence.directory / "observations.jsonl").relative_to(self.root)
            failure = (self.evidence.directory / "failure.json").relative_to(self.root)
            producer = prefix + "my $journal_path = '" + str(journal) + "';\n"
            producer += "my $failure_path = '" + str(failure) + "';\n" + r'''
report_identity('producer');
while (1) {
    last if -f $failure_path;
    open my $journal, '<', $journal_path or die $!;
    my $admitted = 0;
    while (my $line = <$journal>) {
        my $row = eval { decode_json($line) };
        next unless $row && $row->{event} eq 'candidate';
        $admitted++ if $row->{evidence}{child}{pid} == $$
            && $row->{evidence}{parent}{pid} == getppid()
            && $row->{evidence}{target_role} eq 'rust-proxy';
    }
    close $journal or die $!;
    if ($admitted) {
        open my $marker, '>', "$workspace/admission-read" or die $!;
        print {$marker} "admitted\n" or die $!;
        close $marker or die $!;
        last;
    }
    select undef, undef, undef, 0.01;
}
'''
            (workspace / "rust-tool-resolution").write_text(wrapper)
            (workspace / "rust-tools/rustup").write_text(producer)
            self.fixture_sources = {wrapper.encode(), producer.encode()}
            body += r'''
do {
    require Cwd;
    my $workspace = Cwd::getcwd() . '/.artifacts/tmp/process-supervisor-tests/caller-control';
    system '/usr/bin/perl', '-Iperl', '-It/lib', "$workspace/rust-tool-resolution", "$workspace/rust-tools";
    die 'controlled wrapper failed' if $? != 0;
};
'''
        fixtures.LauncherControls.program(self, exit_code=exit_code, body=body, pause=pause)

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
        workspace = self.root / ".artifacts/tmp/process-supervisor-tests/caller-control"
        for role in ("wrapper", "producer"):
            path = workspace / (role + ".json")
            if path.exists():
                with self.assertRaises(ProcessLookupError):
                    self.native.identity(json.loads(path.read_text())["pid"])

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
        self.assertEqual(completed["fixture_native_identity"], "observed_subset")
        self.assertGreater(completed["fixtures"]["observed_fixture_count"], 0)
        workspace = self.root / ".artifacts/tmp/process-supervisor-tests/caller-control"
        reported = json.loads((workspace / "producer.json").read_text())
        admitted = next(row["evidence"] for row in rows if row["event"] == "candidate"
                        and row["evidence"]["child"]["pid"] == reported["pid"])
        self.assertEqual(admitted["parent"]["pid"], reported["ppid"])
        self.assertEqual(admitted["ancestor"]["pid"], self.children[0].pid)
        self.assertEqual((workspace / "admission-read").read_text(), "admitted\n")
        self.assertEqual({path.read_bytes() for path in self.evidence.directory.glob("*.source")}, self.fixture_sources)
        for path in self.evidence.directory.glob("*.source"):
            self.assertEqual(path.stem, hashlib.sha256(path.read_bytes()).hexdigest())
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
        self.assertTrue(json.loads((self.evidence.directory / "fixture-result.json").read_text())["observed_fixtures_gone"])
        self.assertTrue(any(row["event"] == "fixtures_settled" for row in self.events()))
        self.check_closed()

    def test_original_deadline_preserves_timeout_and_reaps_term_resistant_child(self):
        self.program(body=self.context_body(), pause="5")
        with patch.object(launcher, "TEST_SECONDS", 0.15), patch.object(launcher, "REAP_SECONDS", 0.1), \
                self.assertRaisesRegex((RuntimeError, TimeoutError),
                                       "original test failed|fixture census reached the original test deadline"):
            self.run_caller()
        self.assertTrue(self.original()["timeout"])
        self.assertEqual(self.original()["returncode"], -signal.SIGKILL)
        self.check_closed()

    def test_census_failure_preserves_original_before_each_owner_settles(self):
        order = []
        original_finish = self.gated_class.finish
        policy_finish = launcher.policy_log.PolicyLog.finish
        census_settle = launcher.observer.FixtureCensus.settle

        def finish_original(test, *args, **kwargs):
            result = original_finish(test, *args, **kwargs)
            order.append("original")
            return result

        def finish_policy(collector):
            self.assertEqual(self.original()["returncode"], 0)
            result = policy_finish(collector)
            order.append("policy")
            return result

        def finish_census(census):
            self.assertTrue((self.evidence.directory / "policy-result.json").exists())
            result = census_settle(census)
            order.append("fixtures")
            return result

        with patch.object(launcher.observer.FixtureCensus, "scan", side_effect=PermissionError("census denied")), \
                patch.object(self.gated_class, "finish", finish_original), \
                patch.object(launcher.policy_log.PolicyLog, "finish", finish_policy), \
                patch.object(launcher.observer.FixtureCensus, "settle", finish_census), \
                self.assertRaisesRegex(PermissionError, "census denied"):
            self.run_caller()
        self.assertEqual(order, ["original", "policy", "fixtures"])
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.check_closed()

    def test_empty_fixture_coverage_remains_failed_after_all_physical_cleanup(self):
        self.program(body=self.context_body(), with_fixture=False)
        with self.assertRaisesRegex(RuntimeError, "no fixture was observed"):
            self.run_caller()
        self.assertEqual(self.original()["returncode"], 0)
        self.assertEqual(json.loads((self.evidence.directory / "fixture-result.json").read_text()),
                         {"observed_fixtures_gone": True, "observed_fixture_count": 0,
                          "unobserved_descendants": "unknown"})
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.check_closed()

    def false_settlement_control(self, *, disable_recheck=False):
        settle = launcher.observer.FixtureCensus.settle

        def wrong_claim(census):
            result = settle(census)
            # Corrupt the callee's claimed set with the still-live controller
            # birth. The caller must independently reject this false closure.
            controller = self.native.identity(os.getpid())
            census.seen[launcher.observer.identity_key(controller)] = controller
            if disable_recheck:
                bypass = patch.object(launcher.observer, "still_live", return_value=False)
                bypass.start()
                self.addCleanup(bypass.stop)
            return dict(result, observed_fixture_count=len(census.seen))

        with patch.object(launcher.observer.FixtureCensus, "settle", wrong_claim), \
                self.assertRaisesRegex(RuntimeError, "settlement disagrees with observed identities"):
            self.run_caller()
        self.assertEqual(self.original()["returncode"], 0)
        self.check_closed()

    def test_caller_independently_rechecks_claimed_settled_births(self):
        self.false_settlement_control()

    def test_false_settlement_oracle_rejects_disabled_native_recheck(self):
        with self.assertRaisesRegex(AssertionError, "RuntimeError not raised"):
            self.false_settlement_control(disable_recheck=True)
        self.assertEqual(self.original()["returncode"], 0)
        self.check_closed()

    def test_failed_census_settlement_cannot_skip_collector_or_original_cleanup(self):
        with patch.object(launcher.observer.FixtureCensus, "settle", side_effect=PermissionError("settlement denied")), \
                self.assertRaisesRegex(RuntimeError, "observed fixtures: settlement denied"):
            self.run_caller()
        self.assertEqual(self.original()["returncode"], 0)
        self.assertEqual(launcher.retained_policy_result(self.evidence, scope="execution_context")["failures"], {})
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.check_closed()

    def test_reported_tree_model_exercises_off_darwin_inspection_contract(self):
        self.native = PortableFixtureProcesses(self.root)
        self.test_actual_body_verifies_context_preparation_before_its_single_release()

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

    def test_fixture_journal_failure_keeps_independently_verified_saved_settlement(self):
        record = self.evidence.record

        def full(event, **fields):
            if event == "fixtures_settled":
                raise RuntimeError("fixture journal full")
            return record(event, **fields)

        with patch.object(self.evidence, "record", side_effect=full), \
                self.assertRaisesRegex(RuntimeError, "fixture journal full"):
            self.run_caller()
        retained = json.loads((self.evidence.directory / "fixture-result.json").read_text())
        self.assertTrue(retained["observed_fixtures_gone"])
        self.assertGreater(retained["observed_fixture_count"], 0)
        self.assertEqual(self.original()["returncode"], 0)
        self.check_closed()

    def test_original_result_delivery_failure_still_settles_other_owners(self):
        finish = self.gated_class.finish

        def failed_delivery(test, *args, **kwargs):
            finish(test, *args, **kwargs)
            raise RuntimeError("original result delivery failed")

        with patch.object(self.gated_class, "finish", failed_delivery), \
                self.assertRaisesRegex(RuntimeError, "test cleanup: original result delivery failed"):
            self.run_caller()
        self.assertEqual(self.children[0].status, 0)
        with self.assertRaises(ChildProcessError):
            os.waitpid(self.children[0].pid, os.WNOHANG)
        self.assertTrue((self.evidence.directory / "test.tap").exists())
        self.assertFalse((self.evidence.directory / "test-result.json").exists())
        self.assertTrue(json.loads((self.evidence.directory / "policy-result.json").read_text())["leader_reaped"])
        self.assertTrue(json.loads((self.evidence.directory / "fixture-result.json").read_text())["observed_fixtures_gone"])
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))

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
