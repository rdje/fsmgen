"""Real serial child/helper lifetime and independent sequence-stop controls."""

import contextlib
import io
import json
import os
from pathlib import Path
import select
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import run_fixture_startup_sequence as sequence
import test_fixture_startup_launcher as launcher_controls

launcher = sequence.launcher


class HeldSession:
    """A real unprivileged held child; authentication state is modeled only."""

    def __init__(self, native, root):
        self.process = subprocess.Popen(
            ["/usr/bin/perl", "-e", '$|=1; alarm 30; print "ready\\n"; scalar <STDIN>;'],
            cwd=root, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            if not select.select([self.process.stdout], [], [], 3)[0]:
                raise RuntimeError("controlled helper did not enter main")
            if self.process.stdout.readline() != b"ready\n":
                raise RuntimeError("controlled helper readiness is invalid")
            self.helper = native.identity(self.process.pid)
        except BaseException:
            self.close()
            raise
        self.directory = root / ".artifacts/logs/fixture-kernel-capture/session-control"
        self.number, self.cursor = 1, 0
        self.submitted = False
        self.stop_calls = 0
        self.revoked = False

    def state(self):
        return {"helper": self.helper, "last_request": self.cursor,
                "state": "ready" if self.process.poll() is None and not self.revoked else "stopped"}

    def stop(self):
        self.stop_calls += 1
        if not self.process.stdin.closed:
            self.process.stdin.close()

    def stopped(self):
        return self.process.poll() is not None

    def close(self):
        if self.process.poll() is None:
            self.process.kill()
        self.process.wait(timeout=3)
        for stream in (self.process.stdin, self.process.stdout, self.process.stderr):
            stream.close()


class SequenceControls(unittest.TestCase):
    def setUp(self):
        workspace = tempfile.TemporaryDirectory(prefix="sequence-controls-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(workspace.cleanup)
        self.root = Path(workspace.name)
        (self.root / "t").mkdir()
        (self.root / "scripts").mkdir()
        (self.root / "scripts/fixture_kernel_sampler.py").write_bytes(
            (ROOT / "scripts/fixture_kernel_sampler.py").read_bytes())
        self.native = launcher.OwnedProcesses() if sys.platform == "darwin" else launcher_controls.PortableProcesses()
        self.session = HeldSession(self.native, self.root)
        self.addCleanup(self.session.close)
        self.journal = launcher.observer.Evidence(self.root)
        self.addCleanup(self.journal.stream.close)
        launcher_controls.install_policy_control(self, self.root)
        workspace = self.root / ".artifacts/tmp/process-supervisor-tests/sequence-control"
        (workspace / "rust-tools").mkdir(parents=True)
        (workspace / "rust-tool-resolution").write_text(
            "use Time::HiRes qw(sleep); sleep 0.4; exit 0;\n")
        self.program()

    def program(self, first_exit=0, family="all"):
        # The test body independently finds its own readiness event, reports
        # actual PIDs and writes an invocation census outside controller output.
        body = r'''
use strict;
use warnings;
use JSON::PP qw(decode_json);
use Cwd qw(abs_path);
my $ready = 0;
for my $path (glob '.artifacts/logs/t1669-startup-observation/run-*/observations.jsonl') {
    open my $events, '<', $path or die $!;
    while (my $line = <$events>) {
        my $event = decode_json($line);
        $ready = 1 if $event->{event} eq 'observer_ready' && $event->{test}{pid} == $$
            && $event->{target_family} eq 'all';
    }
    close $events or die $!;
}
open my $counter, '>>', 'invocations' or die $!;
print {$counter} "$$ $ready\n" or die $!;
close $counter or die $!;
my $base = abs_path('.artifacts/tmp/process-supervisor-tests/sequence-control');
my $pid = fork();
die $! unless defined $pid;
if (!$pid) {
    exec '/usr/bin/perl', '-Iperl', '-It/lib', "$base/rust-tool-resolution", "$base/rust-tools";
    die $!;
}
waitpid($pid, 0) == $pid or die $!;
die 'controlled wrapper failed' if $?;
print "ok 1 - controlled sequence body\n1..1\n";
'''
        body = body.replace("eq 'all'", "eq '" + family + "'")
        if family == "legacy":
            workspace = self.root / ".artifacts/tmp/process-supervisor-tests/sequence-control"
            (workspace / "legacy-ram-capture").write_text("use Time::HiRes qw(sleep); sleep 0.4; exit 0;\n")
            (workspace / "legacy-ram-streams").write_text("exit 0;\n")
            body = body.replace(
                "exec '/usr/bin/perl', '-Iperl', '-It/lib', \"$base/rust-tool-resolution\", \"$base/rust-tools\";",
                "exec '/usr/bin/perl', \"$base/legacy-ram-capture\", $base, \"$base/legacy-ram-streams\";")
        (self.root / launcher.TEST_ARGV[1]).write_text(body + "exit " + str(first_exit) + ";\n")

    def run_sequence(self, **kwargs):
        # This test calibrates real serial lifetime/cleanup, not startup capture
        # eligibility. Native admission and real observation remain enabled.
        with patch.object(sequence, "MAX_INVOCATIONS", 2), \
                patch.object(launcher.observer, "CANDIDATE_SECONDS", 60), \
                patch.object(launcher.observer, "RUST_CANDIDATE_SECONDS", 60):
            return sequence.run_sequence(self.session, self.native, self.journal, self.root, **kwargs)

    def events(self):
        return [json.loads(row) for row in (self.journal.directory / "observations.jsonl").read_text().splitlines()]

    def census(self):
        path = self.root / "invocations"
        return [tuple(map(int, row.split())) for row in path.read_text().splitlines()] if path.exists() else []

    @unittest.skipUnless(sys.platform == "darwin", "real native fixture ancestry admission")
    def test_real_iterations_keep_helper_live_and_close_it_once_after_both(self):
        outcome = self.run_sequence()
        self.assertEqual(outcome["reason"], "invocation_limit")
        self.assertFalse(outcome["capture_received"])
        self.assertEqual(outcome["qualification"], "not_claimed")
        identities = self.census()
        self.assertEqual(len(identities), 2)
        self.assertTrue(all(ready == 1 for _, ready in identities))
        self.assertEqual(len({pid for pid, _ in identities}), 2)
        for pid, _ in identities:
            with self.assertRaises(ChildProcessError):
                os.waitpid(pid, os.WNOHANG)
        self.assertEqual(self.session.stop_calls, 1)
        self.assertTrue(self.session.stopped())
        events = self.events()
        self.assertEqual([e["event"] for e in events], ["sequence_started", "iteration_started",
                         "iteration_completed", "iteration_started", "iteration_completed",
                         "sequence_outcome", "sequence_settled"])
        for event in events:
            if event["event"] == "iteration_started":
                path = self.root / event["evidence"]
                rows = [json.loads(row) for row in (path / "observations.jsonl").read_text().splitlines()]
                self.assertTrue(any(row["event"] == "candidate" for row in rows))
                self.assertEqual(json.loads((path / "test-result.json").read_text())["native_wait_status"], 0)

    @unittest.skipUnless(sys.platform == "darwin", "real native fixture ancestry admission")
    def test_original_nonzero_stops_before_any_second_invocation(self):
        self.program(first_exit=23)
        with self.assertRaisesRegex(RuntimeError, "original test failed"):
            self.run_sequence()
        self.assertEqual(len(self.census()), 1)
        started = next(e for e in self.events() if e["event"] == "iteration_started")
        result = json.loads((self.root / started["evidence"] / "test-result.json").read_text())
        self.assertEqual(result["returncode"], 23)
        self.assertEqual(self.session.stop_calls, 1)
        self.assertTrue(self.session.stopped())

    def check_real_selected_bodies(self, family):
        self.program(family=family)
        outcome = self.run_sequence(target_family=family)
        self.assertEqual(outcome["reason"], "invocation_limit")
        self.assertEqual(len(self.census()), 2)
        self.assertTrue(all(ready == 1 for _, ready in self.census()))
        for event in self.events():
            if event["event"] == "iteration_started":
                rows = [json.loads(row) for row in
                        (self.root / event["evidence"] / "observations.jsonl").read_text().splitlines()]
                settled = next(row for row in rows if row["event"] == "settled")
                self.assertEqual(settled["selected_fixture_count"], 1)
                self.assertEqual(settled["target_family"], family)
        self.assertEqual(self.session.stop_calls, 1)
        self.assertTrue(self.session.stopped())

    @unittest.skipUnless(sys.platform == "darwin", "real native fixture ancestry admission")
    def test_real_legacy_bodies_independently_verify_selected_family_before_entry(self):
        self.check_real_selected_bodies("legacy")

    @unittest.skipUnless(sys.platform == "darwin", "real native fixture ancestry admission")
    def test_real_rust_bodies_independently_verify_selected_family_before_entry(self):
        self.check_real_selected_bodies("rust")

    @unittest.skipUnless(sys.platform == "darwin", "real native fixture ancestry admission")
    def test_independent_lifetime_control_rejects_premature_helper_shutdown(self):
        run = launcher.run

        def premature(session, native, evidence, root, **_kwargs):
            return run(session, native, evidence, root, stop_session=True)

        with patch.object(launcher, "run", side_effect=premature), \
                self.assertRaisesRegex(RuntimeError, "lacks successful original status or observed cleanup"):
            self.run_sequence()
        self.assertEqual(len(self.census()), 1)
        self.assertTrue(self.session.stopped())

    def modeled_iteration(self, session, _native, evidence, _root, *, stop_session, target_family):
        self.assertFalse(stop_session)
        result = {"pid": 99, "returncode": 0, "native_wait_status": 0, "leader_reaped": True,
                  "released": True, "timeout": False, "unobserved_descendants": "unknown"}
        evidence.record("settled", observed_fixture_count=1, observed_fixtures_gone=True,
                        selected_fixture_count=1, target_family=target_family,
                        helper_stopped=False, helper_shutdown_owner="caller",
                        capture_received=session.submitted)
        collector = launcher.policy_log.PolicyLog(_root, evidence.directory, _native)
        try:
            collector.prepare()
        finally:
            retained = collector.finish()
        self.assertEqual(retained["failures"], {})
        evidence.record("policy_settled", leader_reaped=True, failures={},
                        result_path=str((evidence.directory / "policy-result.json").relative_to(_root)))
        return result

    def check_iteration_family(self, family):
        with patch.object(launcher, "run", side_effect=self.modeled_iteration) as run:
            self.run_sequence(target_family=family)
        self.assertEqual(run.call_count, 2)
        self.assertTrue(all(call.kwargs["target_family"] == family for call in run.call_args_list))
        self.assertEqual(self.events()[0]["target_family"], family)
        self.assertEqual(self.session.stop_calls, 1)

    def test_legacy_selection_reaches_every_iteration_and_sequence_journal(self):
        self.check_iteration_family("legacy")

    def test_rust_selection_reaches_every_iteration_and_sequence_journal(self):
        self.check_iteration_family("rust")

    def test_invalid_family_stops_helper_without_starting_an_iteration(self):
        with patch.object(launcher, "run") as run, \
                self.assertRaisesRegex(ValueError, "target family must be"):
            self.run_sequence(target_family="unrecognized")
        run.assert_not_called()
        self.assertEqual(self.census(), [])
        self.assertTrue(self.session.stopped())

    def test_unrelated_coverage_cannot_start_another_legacy_iteration(self):
        def unrelated(session, native, evidence, root, **kwargs):
            kwargs["target_family"] = "all"
            return self.modeled_iteration(session, native, evidence, root, **kwargs)

        with patch.object(launcher, "run", side_effect=unrelated) as run, \
                self.assertRaisesRegex(RuntimeError, "lacks successful original status or observed cleanup"):
            self.run_sequence(target_family="legacy")
        self.assertEqual(run.call_count, 1)
        self.assertTrue(self.session.stopped())

    def test_one_capture_ends_sequence_even_when_original_test_succeeds(self):
        def capture(*args, **kwargs):
            self.session.submitted = True
            return self.modeled_iteration(*args, **kwargs)

        with patch.object(launcher, "run", side_effect=capture) as run:
            outcome = self.run_sequence()
        self.assertTrue(outcome["capture_received"])
        self.assertEqual(outcome["reason"], "capture_received")
        self.assertEqual(run.call_count, 1)
        self.assertEqual(self.session.stop_calls, 1)

    def test_observer_failure_cannot_start_a_later_iteration(self):
        with patch.object(launcher, "run", side_effect=RuntimeError("capture rejected")) as run, \
                self.assertRaisesRegex(RuntimeError, "capture rejected"):
            self.run_sequence()
        self.assertEqual(run.call_count, 1)
        self.assertEqual(self.session.stop_calls, 1)
        self.assertIn("capture rejected", (self.journal.directory / "failure.json").read_text())

    def test_interruption_still_consumes_helper_shutdown_without_next_iteration(self):
        with patch.object(launcher, "run", side_effect=KeyboardInterrupt) as run, \
                self.assertRaises(KeyboardInterrupt):
            self.run_sequence()
        self.assertEqual(run.call_count, 1)
        self.assertEqual(self.session.stop_calls, 1)
        self.assertTrue(self.session.stopped())

    def test_capture_request_flag_cannot_replace_a_received_capture(self):
        def missing_capture(*args, **kwargs):
            result = self.modeled_iteration(*args, **kwargs)
            self.session.submitted = True
            return result

        with patch.object(launcher, "run", side_effect=missing_capture) as run, \
                self.assertRaisesRegex(RuntimeError, "lacks successful"):
            self.run_sequence()
        self.assertEqual(run.call_count, 1)
        self.assertTrue(self.session.stopped())

    def test_exhausted_journal_still_stops_helper_before_reporting_failure(self):
        with patch.object(launcher.observer, "MAX_EVENTS", 0), \
                patch.object(launcher, "run") as run, \
                self.assertRaisesRegex(ValueError, "storage bound"):
            self.run_sequence()
        run.assert_not_called()
        self.assertEqual(self.session.stop_calls, 1)
        self.assertTrue(self.session.stopped())
        self.assertTrue((self.journal.directory / "failure.json").exists())

    def test_revocation_between_iterations_prevents_next_release(self):
        def revoked(*args, **kwargs):
            result = self.modeled_iteration(*args, **kwargs)
            self.session.revoked = True
            return result

        with patch.object(launcher, "run", side_effect=revoked) as run, \
                self.assertRaisesRegex(ValueError, "helper changed"):
            self.run_sequence()
        self.assertEqual(run.call_count, 1)
        self.assertEqual(self.session.stop_calls, 1)

    def test_full_invocation_budget_is_reserved_before_any_launch(self):
        with patch.object(sequence, "SEQUENCE_SECONDS", 12.1), \
                patch.object(launcher, "run") as run:
            outcome = self.run_sequence()
        run.assert_not_called()
        self.assertEqual(outcome["completed_invocations"], 0)
        self.assertEqual(outcome["reason"], "insufficient_time_for_complete_invocation")

    def test_policy_allowances_are_reserved_in_addition_to_the_original_invocation(self):
        # The old 221 + 12 reservation fits 240; collection's extra startup
        # and cleanup do not. No original deadline is shortened to make it fit.
        with patch.object(sequence, "SEQUENCE_SECONDS", 240), patch.object(launcher, "run") as run:
            outcome = self.run_sequence()
        run.assert_not_called()
        self.assertEqual(outcome["reason"], "insufficient_time_for_complete_invocation")

    def test_policy_output_drift_stops_before_another_iteration(self):
        def changed(session, native, evidence, root, **kwargs):
            result = self.modeled_iteration(session, native, evidence, root, **kwargs)
            with (evidence.directory / "policy.stdout").open("ab") as stream:
                stream.write(b"changed after original status\n")
            return result

        with patch.object(launcher, "run", side_effect=changed) as run, \
                self.assertRaisesRegex(RuntimeError, "retained output changed"):
            self.run_sequence()
        self.assertEqual(run.call_count, 1)
        self.assertTrue(self.session.stopped())

    def test_missing_policy_settlement_stops_before_another_iteration(self):
        def missing(session, native, evidence, root, **kwargs):
            result = self.modeled_iteration(session, native, evidence, root, **kwargs)
            path = evidence.directory / "observations.jsonl"
            rows = [row for row in path.read_text().splitlines()
                    if json.loads(row)["event"] != "policy_settled"]
            path.write_text("\n".join(rows) + "\n")
            return result

        with patch.object(launcher, "run", side_effect=missing) as run, \
                self.assertRaisesRegex(RuntimeError, "lacks settled policy retention"):
            self.run_sequence()
        self.assertEqual(run.call_count, 1)
        self.assertTrue(self.session.stopped())

    def test_elapsed_time_is_checked_after_invocation_and_before_another(self):
        now = [0]

        def elapsed(*args, **kwargs):
            result = self.modeled_iteration(*args, **kwargs)
            now[0] = 70
            return result

        with patch.object(sequence.time, "monotonic", side_effect=lambda: now[0]), \
                patch.object(launcher, "run", side_effect=elapsed) as run:
            outcome = self.run_sequence()
        self.assertEqual(run.call_count, 1)
        self.assertEqual(outcome["reason"], "insufficient_time_for_complete_invocation")

    def test_actual_budget_overrun_remains_a_failed_diagnostic(self):
        now = [0]

        def elapsed(*args, **kwargs):
            result = self.modeled_iteration(*args, **kwargs)
            now[0] = 301
            return result

        with patch.object(sequence.time, "monotonic", side_effect=lambda: now[0]), \
                patch.object(launcher, "run", side_effect=elapsed) as run, \
                self.assertRaisesRegex(TimeoutError, "reserved diagnostic budget"):
            self.run_sequence()
        self.assertEqual(run.call_count, 1)
        self.assertTrue(self.session.stopped())

    def test_missing_settlement_cannot_be_promoted_by_a_successful_result(self):
        with patch.object(launcher, "run", return_value={"returncode": 0}), \
                self.assertRaisesRegex(RuntimeError, "lacks successful"):
            self.run_sequence()
        self.assertTrue(self.session.stopped())

    def test_failed_journal_creation_stops_helper_without_launch(self):
        with patch.object(sequence.sys, "argv", ["sequence", "--session", "controlled"]), \
                patch.object(sequence.sys, "platform", "darwin"), \
                patch.object(sequence.os, "getuid", return_value=501), \
                patch.object(sequence.os, "geteuid", return_value=501), \
                patch.object(sequence.os, "umask"), \
                patch.dict(os.environ, {"FSMGEN_RAM_GUARD_ACTIVE": "1"}), \
                patch.object(launcher, "OwnedProcesses", return_value=self.native), \
                patch.object(launcher.observer, "CaptureSession", return_value=self.session), \
                patch.object(launcher.observer, "Evidence", side_effect=OSError("unavailable journal")), \
                patch.object(sequence, "run_sequence") as run, contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(sequence.main(), 1)
        run.assert_not_called()
        self.assertEqual(self.session.stop_calls, 1)
        self.assertTrue(self.session.stopped())


if __name__ == "__main__":
    unittest.main()
