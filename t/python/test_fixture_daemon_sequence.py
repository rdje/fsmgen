"""Fixed daemon sequence: real held bodies/helper, modeled calibration/clock."""

from contextlib import nullcontext
import json
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

import test_fixture_daemon_capture as caller_controls
import test_fixture_startup_sequence as lifetime_controls

sequence = lifetime_controls.sequence
daemon = sequence.daemon
launcher = sequence.launcher
associations = daemon.archive.associations


class DaemonSequenceControls(unittest.TestCase):
    policy_scope = "daemon_context"
    program = caller_controls.DaemonCaptureControls.program
    policy_body = caller_controls.DaemonCaptureControls.policy_body
    body = caller_controls.DaemonCaptureControls.body
    events = caller_controls.DaemonCaptureControls.events
    original = caller_controls.DaemonCaptureControls.original
    check_closed = caller_controls.DaemonCaptureControls.check_closed

    def setUp(self):
        caller_controls.DaemonCaptureControls.setUp(self)
        self.journal = self.evidence
        self.session = lifetime_controls.HeldSession(self.native, self.root)
        self.addCleanup(self.session.close)
        self.session.submit = Mock(side_effect=AssertionError("authenticated capture requested"))
        self.iterations = []
        self.completed_children = []
        self.first_exit = 0
        self.before_body = ""
        self.evidence_class = launcher.observer.Evidence

    def iteration_evidence(self, root):
        if self.iterations and self.children:
            self.check_closed()
            self.completed_children.extend(self.children)
            self.children.clear()
        self.evidence = self.evidence_class(root)
        self.iterations.append(self.evidence)
        body = self.body() + self.before_body + r'''
open my $count, '>>', 'sequence-bodies' or die $!;
print {$count} "$$\n" or die $!;
close $count or die $!;
'''
        self.program(exit_code=self.first_exit if len(self.iterations) == 1 else 0, body=body)
        return self.evidence

    def tearDown(self):
        # Preserve native cleanup failures even if an earlier assertion or a
        # controlled observer error prevents the normal result checks.
        if self.children:
            self.check_closed()

    def run_sequence(self, *, count=2):
        count_control = patch.object(sequence, "MAX_INVOCATIONS", count) if count is not None else nullcontext()
        with count_control, \
                patch.object(launcher.observer, "Evidence", side_effect=self.iteration_evidence):
            return sequence.run_sequence(self.session, self.native, self.journal, self.root,
                                         target_family="rust", calibrations=[self.calibration])

    def journal_events(self):
        return [json.loads(row) for row in (self.journal.directory / "observations.jsonl").read_text().splitlines()]

    def bodies(self):
        path = self.root / "sequence-bodies"
        return path.read_text().splitlines() if path.exists() else []

    def check_helper(self):
        self.assertEqual(self.session.stop_calls, 1)
        self.assertTrue(self.session.stopped())
        self.session.submit.assert_not_called()
        if sys.platform == "darwin":
            self.assertFalse(launcher.observer.still_live(self.native, self.session.helper))

    def checked_publications(self, outcome):
        for evidence, published in zip(self.iterations, outcome["publications"], strict=True):
            raw = (evidence.directory / daemon.archive.INDEX_FILE).read_bytes()
            checked = daemon.archive.consume(raw, published["sha256"], self.root)
            self.assertEqual(checked["index"], published["index"])
            self.assertEqual(checked["index"]["context"]["run"], str(evidence.directory.relative_to(self.root)))
            self.assertEqual(checked["index"]["context"]["original"]["returncode"], 0)
            self.assertEqual(checked["index"]["context"]["scope"], "daemon_context")
            result = json.loads((evidence.directory / "test-result.json").read_text())
            self.assertEqual(result["native_wait_status"], 0)
            if sys.platform == "darwin":
                with self.assertRaises(ProcessLookupError):
                    self.native.identity(result["pid"])
        self.check_closed()

    def test_real_serial_bodies_keep_one_helper_and_pin_each_settled_publication(self):
        outcome = self.run_sequence()
        self.assertEqual(outcome["reason"], "invocation_limit")
        self.assertEqual(outcome["completed_invocations"], 2)
        self.assertEqual(len(set(self.bodies())), 2)
        self.assertEqual(outcome["qualification"], "not_claimed")
        self.checked_publications(outcome)
        admitted = next(row for row in self.journal_events() if row["event"] == "sequence_calibration_admitted")
        self.assertEqual(admitted["scope"], "daemon_context")
        self.assertTrue(all(associations.digest(associations.canonical(p["index"]["context"]["calibrations"])) == admitted["sha256"] for p in outcome["publications"]))
        self.check_helper()

    def test_original_failure_keeps_its_publication_and_stops_before_second_body(self):
        self.first_exit = 23
        with self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_sequence()
        self.assertEqual(len(self.bodies()), 1)
        self.assertIsNotNone(failed.exception.published)
        raw = associations.canonical(failed.exception.published["index"])
        checked = daemon.archive.consume(raw, failed.exception.published["sha256"], self.root)
        self.assertEqual(checked["index"]["context"]["original"]["returncode"], 23)
        self.check_closed()
        self.check_helper()

    def test_invalid_initial_calibration_launches_nothing_and_closes_helper(self):
        with patch.object(associations, "calibration_snapshot", side_effect=ValueError("private calibration")), \
                patch.object(launcher.policy_log, "PolicyLog") as collector, self.assertRaises(ValueError):
            self.run_sequence()
        collector.assert_not_called()
        self.assertEqual(self.bodies(), [])
        self.assertEqual(self.iterations, [])
        self.check_helper()

    def test_calibration_drift_between_iterations_rejects_before_next_collector(self):
        original = daemon.run
        def change(*args, **kwargs):
            result = original(*args, **kwargs)
            path = self.root / self.calibration / "test-result.json"
            path.write_text(json.dumps(dict(returncode=0, timeout=False)))
            return result
        with patch.object(daemon, "run", side_effect=change), self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_sequence()
        self.assertIn("changed after sequence admission", str(failed.exception.__cause__))
        self.assertEqual(len(self.bodies()), 1)
        self.assertFalse((self.iterations[-1].directory / "policy-result.json").exists())
        self.check_helper()

    def test_post_preflight_reserve_prevents_all_child_launches(self):
        now = [0.0]
        snapshot = associations.calibration_snapshot
        calls = []
        def elapsed(*args, **kwargs):
            result = snapshot(*args, **kwargs)
            calls.append(result)
            if len(calls) == 2:
                now[0] = 654.0
            return result
        with patch.object(sequence, "time", SimpleNamespace(monotonic=lambda: now[0])), \
                patch.object(associations, "calibration_snapshot", side_effect=elapsed), \
                patch.object(launcher.policy_log, "PolicyLog", wraps=launcher.policy_log.PolicyLog) as collector:
            outcome = self.run_sequence()
        collector.assert_not_called()
        self.assertEqual(outcome["completed_invocations"], 0)
        self.assertEqual(outcome["publications"], [])
        self.assertEqual(outcome["reason"], "insufficient_time_for_complete_invocation")
        self.assertEqual(self.bodies(), [])
        self.assertEqual(len(calls), 2)
        self.assertTrue(any(r["event"] == "iteration_deferred" for r in self.journal_events()))
        self.check_helper()

    def test_held_helper_revocation_after_preflight_prevents_launch(self):
        snapshot = associations.calibration_snapshot
        calls = []
        def revoke(*args, **kwargs):
            result = snapshot(*args, **kwargs)
            calls.append(result)
            if len(calls) == 2:
                self.session.revoked = True
            return result
        with patch.object(associations, "calibration_snapshot", side_effect=revoke), \
                patch.object(launcher.policy_log, "PolicyLog") as collector, self.assertRaises(daemon.CaptureFailure):
            self.run_sequence()
        collector.assert_not_called()
        self.assertEqual(self.bodies(), [])
        self.check_helper()

    def timed_bodies(self, duration):
        now = [0.0]
        original = daemon.run
        def elapsed(*args, **kwargs):
            result = original(*args, **kwargs)
            now[0] += duration
            return result
        with patch.object(sequence, "time", SimpleNamespace(monotonic=lambda: now[0])), \
                patch.object(daemon, "run", side_effect=elapsed):
            return self.run_sequence(count=None)

    def test_fixed_count_and_budget_keep_indexes_in_separate_bounded_events(self):
        outcome = self.timed_bodies(15)
        self.assertEqual(outcome["completed_invocations"], 20)
        self.assertEqual(len(set(self.bodies())), 20)
        self.assertEqual(outcome["reason"], "invocation_limit")
        events = self.journal_events()
        self.assertEqual(events[0]["max_invocations"], 20)
        self.assertEqual(events[0]["budget_seconds"], 900)
        self.assertEqual(events[0]["invocation_reserve_seconds"], 235)
        self.assertEqual(events[0]["helper_cleanup_seconds"], 12)
        self.assertEqual(sum(e["event"] == "iteration_publication" for e in events), 20)
        self.assertNotIn("publications", next(e for e in events if e["event"] == "sequence_outcome"))
        self.checked_publications(outcome)
        self.check_helper()

    def test_full_reserve_stops_before_a_fourth_body(self):
        outcome = self.timed_bodies(218)
        self.assertEqual(outcome["completed_invocations"], 3)
        self.assertEqual(len(self.bodies()), 3)
        self.assertEqual(outcome["reason"], "insufficient_time_for_complete_invocation")
        self.checked_publications(outcome)
        self.check_helper()

    def test_publication_time_cannot_turn_budget_overrun_into_success(self):
        with self.assertRaisesRegex(TimeoutError, "reserved diagnostic budget"):
            self.timed_bodies(889)
        self.assertEqual(len(self.bodies()), 1)
        self.check_closed()
        self.check_helper()

    def test_index_corruption_after_publication_stops_before_next_body(self):
        original = daemon.run
        def corrupt(*args, **kwargs):
            result = original(*args, **kwargs)
            (self.evidence.directory / daemon.archive.INDEX_FILE).write_bytes(b"{}\n")
            return result
        with patch.object(daemon, "run", side_effect=corrupt), self.assertRaisesRegex(ValueError, "archive index disagrees"):
            self.run_sequence()
        self.assertEqual(len(self.bodies()), 1)
        self.check_closed()
        self.check_helper()

    def test_prior_valid_index_cannot_replace_current_iteration_publication(self):
        original = daemon.run
        prior = []
        def substitute(*args, **kwargs):
            result = original(*args, **kwargs)
            if not prior:
                prior.append(result["publication"])
            else:
                result["publication"] = prior[0]
                (self.evidence.directory / daemon.archive.INDEX_FILE).write_bytes(
                    associations.canonical(prior[0]["index"]))
            return result
        with patch.object(daemon, "run", side_effect=substitute), \
                self.assertRaisesRegex(ValueError, "admitted sequence iteration"):
            self.run_sequence(count=3)
        self.assertEqual(len(self.bodies()), 2)
        self.check_closed()
        self.check_helper()

    def test_retained_scope_drift_stops_before_next_body(self):
        original = daemon.run
        def corrupt(*args, **kwargs):
            result = original(*args, **kwargs)
            path = self.evidence.directory / "policy-result.json"
            data = json.loads(path.read_text())
            data["scope"] = "execution_context"
            path.write_text(json.dumps(data))
            return result
        with patch.object(daemon, "run", side_effect=corrupt), self.assertRaisesRegex(RuntimeError, "scope or command"):
            self.run_sequence()
        self.assertEqual(len(self.bodies()), 1)
        self.check_closed()
        self.check_helper()

    def test_publication_failure_stops_before_any_next_body(self):
        with patch.object(daemon.archive, "publish", side_effect=OSError("private publication")), \
                self.assertRaises(daemon.CaptureFailure):
            self.run_sequence()
        self.assertEqual(len(self.bodies()), 1)
        self.check_closed()
        self.check_helper()

    def test_capture_received_stops_after_first_settled_body(self):
        observe = launcher.observer.observe
        def capture(test, native, session, evidence, root, **kwargs):
            # Capture delivery alone is modeled; the original and observed
            # fixture cleanup, collector, publication and helper are real controls.
            record = evidence.record
            def received(event, **fields):
                if event == "candidate":
                    session.submitted = True
                return record(event, **fields)
            session.result = Mock(return_value={"sampler": {"returncode": 0, "timeout": False}})
            with patch.object(evidence, "record", side_effect=received):
                return observe(test, native, session, evidence, root, **kwargs)
        with patch.object(launcher.observer, "observe", side_effect=capture):
            outcome = self.run_sequence()
        self.assertTrue(outcome["capture_received"])
        self.assertEqual(outcome["reason"], "capture_received")
        self.assertEqual(len(self.bodies()), 1)
        self.checked_publications(outcome)
        self.check_helper()

    def test_interruption_before_original_release_keeps_helper_with_controller(self):
        with patch.object(launcher, "wait_for_exec", side_effect=KeyboardInterrupt), \
                self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_sequence()
        self.assertTrue(failed.exception.interrupted)
        self.check_closed()
        self.check_helper()


if __name__ == "__main__":
    unittest.main()
