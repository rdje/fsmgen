"""Fixed sequence CLI over held serial fixtures; no real authentication/logs."""

import contextlib
import copy
import io
import json
import os
import unittest
from unittest.mock import patch

import test_fixture_daemon_sequence as controls
import run_fixture_startup_daemon_sequence as entry

daemon = entry.caller
sequence = controls.sequence
launcher = sequence.launcher


class DaemonSequenceCLI(unittest.TestCase):
    policy_scope = controls.DaemonSequenceControls.policy_scope
    program = controls.DaemonSequenceControls.program
    policy_body = controls.DaemonSequenceControls.policy_body
    body = controls.DaemonSequenceControls.body
    events = controls.DaemonSequenceControls.events
    original = controls.DaemonSequenceControls.original
    check_closed = controls.DaemonSequenceControls.check_closed
    iteration_evidence = controls.DaemonSequenceControls.iteration_evidence
    journal_events = controls.DaemonSequenceControls.journal_events
    bodies = controls.DaemonSequenceControls.bodies
    check_helper = controls.DaemonSequenceControls.check_helper
    tearDown = controls.DaemonSequenceControls.tearDown
    run_sequence = controls.DaemonSequenceControls.run_sequence

    def setUp(self):
        controls.DaemonSequenceControls.setUp(self)

    def cli(self, args=None, *, evidence_failure=False):
        calls = []
        def evidence(root):
            calls.append(root)
            if len(calls) == 1:
                if evidence_failure:
                    raise OSError("/private/journal")
                return self.journal
            return self.iteration_evidence(root)
        stdout, stderr = io.StringIO(), io.StringIO()
        with patch.object(daemon, "ROOT", self.root), patch.object(daemon.sys, "platform", "darwin"), \
                patch.dict(os.environ, {"FSMGEN_RAM_GUARD_ACTIVE": "1"}), \
                patch.object(launcher, "OwnedProcesses", return_value=self.native), \
                patch.object(launcher.observer, "CaptureSession", return_value=self.session), \
                patch.object(launcher.observer, "Evidence", side_effect=evidence), \
                patch.object(sequence, "MAX_INVOCATIONS", 2), \
                contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            status = entry.main(args if args is not None else ["--session", "controlled", "--target-family", "rust",
                                                              "--calibration", self.calibration])
        return status, stdout.getvalue(), stderr.getvalue()

    def output(self, stdout):
        lines = stdout.splitlines()
        self.assertEqual(lines[0], str(self.journal.directory.relative_to(self.root)))
        self.assertNotIn(str(self.root), stdout)
        return [json.loads(line) for line in lines[1:]]

    def test_actual_cli_runs_serial_daemon_bodies_and_reports_no_capture_without_failure_text(self):
        status, stdout, stderr = self.cli()
        self.assertEqual(status, 2)
        self.assertEqual(stderr, "")
        rows = self.output(stdout)
        self.assertEqual(len(rows), 3)
        self.assertEqual(rows[-1], dict(reason="invocation_limit", completed_invocations=2,
                                      capture_received=False, qualification="not_claimed", unobserved_descendants="unknown"))
        self.assertEqual(len(set(self.bodies())), 2)
        for row, evidence in zip(rows[:-1], self.iterations, strict=True):
            raw = (evidence.directory / daemon.archive.INDEX_FILE).read_bytes()
            checked = daemon.archive.consume(raw, row["sha256"], self.root)
            self.assertEqual(checked["index"], row["index"])
        self.check_helper()

    def test_original_failure_stays_failed_but_emits_its_valid_portable_index(self):
        self.first_exit = 23
        status, stdout, stderr = self.cli()
        self.assertEqual(status, 1)
        self.assertEqual(stderr, daemon.PUBLIC_SEQUENCE_FAILURE + "\n")
        rows = self.output(stdout)
        self.assertEqual(len(rows), 1)
        checked = daemon.archive.consume(daemon.archive.associations.canonical(rows[0]["index"]),
                                             rows[0]["sha256"], self.root)
        self.assertEqual(checked["index"]["context"]["original"]["returncode"], 23)
        self.assertEqual(len(self.bodies()), 1)
        self.check_helper()

    def test_received_capture_exits_success_through_the_actual_entrypoint(self):
        observe = launcher.observer.observe
        def capture(test, native, session, evidence, root, **kwargs):
            record = evidence.record
            def received(event, **fields):
                if event == "candidate":
                    session.submitted = True
                return record(event, **fields)
            session.result = lambda: {"sampler": {"returncode": 0, "timeout": False}}
            with patch.object(evidence, "record", side_effect=received):
                return observe(test, native, session, evidence, root, **kwargs)
        with patch.object(launcher.observer, "observe", side_effect=capture):
            status, stdout, stderr = self.cli()
        self.assertEqual(status, 0)
        self.assertEqual(stderr, "")
        rows = self.output(stdout)
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[-1]["reason"], "capture_received")
        self.assertIs(rows[-1]["capture_received"], True)
        self.assertEqual(len(self.bodies()), 1)
        self.check_helper()

    def test_interruption_survives_later_helper_cleanup_error(self):
        stop = launcher.stop_helper
        def failed_cleanup(session):
            stop(session)
            raise OSError("/private/cleanup")
        with patch.object(launcher, "wait_for_exec", side_effect=KeyboardInterrupt), \
                patch.object(launcher, "stop_helper", side_effect=failed_cleanup):
            status, stdout, stderr = self.cli()
        self.assertEqual(status, 130)
        self.assertEqual(stderr, daemon.PUBLIC_SEQUENCE_FAILURE + "\n")
        self.assertNotIn("/private/cleanup", stdout + stderr)
        failures = json.loads((self.journal.directory / "failure.json").read_text())["failures"]
        self.assertIn("/private/cleanup", failures["cleanup"])
        self.check_helper()

    def test_setup_failure_stops_admitted_helper_without_sequence_or_private_output(self):
        with patch.object(sequence, "run_sequence") as run:
            status, stdout, stderr = self.cli(evidence_failure=True)
        run.assert_not_called()
        self.assertEqual(status, 1)
        self.assertEqual(stdout, "")
        self.assertEqual(stderr, daemon.PUBLIC_SEQUENCE_FAILURE + "\n")
        self.check_helper()

    def test_private_and_override_arguments_reject_before_native_setup(self):
        for args in (["--session", "/private/session"],
                     ["--sess", "x", "--cal", "/private/calibration"],
                     *[["--session", "x", "--calibration", "x", option, "/private/value"]
                       for option in ("--predicate", "--policy-scope", "--count", "--deadline")]):
            stdout, stderr = io.StringIO(), io.StringIO()
            with self.subTest(args=args), patch.object(launcher, "OwnedProcesses") as native, \
                    contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                status = entry.main(args)
            native.assert_not_called()
            self.assertEqual(status, 1)
            self.assertEqual(stdout.getvalue(), "")
            self.assertEqual(stderr.getvalue(), daemon.PUBLIC_SEQUENCE_FAILURE + "\n")

    def test_public_outcome_rejects_forged_private_fields_counts_and_indexes_before_output(self):
        outcome = self.run_sequence()
        variants = []
        for key, value in (("reason", "/private/reason"), ("capture_received", 1),
                           ("completed_invocations", True), ("completed_invocations", 21),
                           ("completed_invocations", 1), ("qualification", "passed"),
                           ("unobserved_descendants", "/private/identity"), ("private", "/private/value")):
            changed = copy.deepcopy(outcome)
            changed[key] = value
            variants.append(changed)
        changed = copy.deepcopy(outcome)
        changed["publications"][1] = changed["publications"][0]
        variants.append(changed)
        changed = copy.deepcopy(outcome)
        changed["publications"][1]["sha256"] = "0" * 64
        variants.append(changed)
        for changed in variants:
            output = io.StringIO()
            with self.subTest(changed=changed), patch.object(daemon, "ROOT", self.root), \
                    contextlib.redirect_stdout(output), self.assertRaises(ValueError):
                daemon._emit_sequence(changed, 2)
            self.assertEqual(output.getvalue(), "")
        self.check_helper()

    def test_failed_original_index_cannot_appear_as_a_completed_sequence_iteration(self):
        self.first_exit = 23
        with self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_sequence()
        forged = dict(reason="insufficient_time_for_complete_invocation", completed_invocations=1,
                      capture_received=False, qualification="not_claimed", unobserved_descendants="unknown",
                      publications=[failed.exception.published])
        output = io.StringIO()
        with patch.object(daemon, "ROOT", self.root), contextlib.redirect_stdout(output), \
                self.assertRaisesRegex(ValueError, "unsuccessful original or collector"):
            daemon._emit_sequence(forged, 20)
        self.assertEqual(output.getvalue(), "")
        self.check_helper()

    def test_empty_no_capture_outcome_has_no_indexes_and_is_not_an_execution_failure(self):
        with patch.object(sequence, "RUST_SEQUENCE_SECONDS", 1):
            status, stdout, stderr = self.cli()
        self.assertEqual(status, 2)
        self.assertEqual(stderr, "")
        rows = self.output(stdout)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["reason"], "insufficient_time_for_complete_invocation")
        self.assertEqual(rows[0]["completed_invocations"], 0)
        self.assertEqual(self.bodies(), [])
        self.check_helper()


if __name__ == "__main__":
    unittest.main()
