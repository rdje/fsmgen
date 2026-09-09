"""Fixed combined daemon caller: held originals/fixtures, modeled calibration."""

import contextlib
import io
import json
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch

import test_fixture_startup_launcher as fixtures
import test_fixture_startup_policy_observation as passive
import test_fixture_policy_analysis as calibration

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
try:
    import run_fixture_startup_daemon_capture as daemon
finally:
    sys.path.pop(0)
launcher = daemon.launcher
associations = daemon.archive.associations


def controlled_policy(root, rows):
    header = 'Filtering the log data using "process == "syspolicyd""\n'
    output = header + "".join(json.dumps(row) + "\n" for row in rows)
    (root / "controlled-policy.pl").write_text(
        'use strict; use warnings; $|=1; $SIG{INT}=sub {exit 0}; alarm 30;\nprint '
        + json.dumps(output) + ';\nwhile (1) { select undef, undef, undef, 0.05; }\n')


class DaemonCaptureControls(unittest.TestCase):
    policy_scope = "daemon_context"
    program = passive.PolicyOnlyControls.program
    events = fixtures.LauncherControls.events
    policy_body = fixtures.LauncherControls.policy_body
    original = passive.PolicyOnlyControls.original
    check_closed = passive.PolicyOnlyControls.check_closed

    def setUp(self):
        fixtures.LauncherControls.setUp(self)
        if sys.platform != "darwin":
            self.native = passive.PortableFixtureProcesses(self.root)
            self.session = fixtures.Session(self.native, self.root)
        self.session.submit = Mock(side_effect=AssertionError("authenticated capture requested"))
        self.children = []
        gated = launcher.GatedTest
        def track(*args, **kwargs):
            child = gated(*args, **kwargs)
            self.children.append(child)
            return child
        tracked = patch.object(launcher, "GatedTest", side_effect=track)
        tracked.start()
        self.addCleanup(tracked.stop)
        self.addCleanup(lambda: [child.finish(cancel=True) for child in self.children])
        self.calibration = ".artifacts/logs/control-calibration"
        self.capture_root = str(self.root)
        paths = [associations.analysis.FIXTURE_PREFIX + "calibration/one",
                 associations.analysis.FIXTURE_PREFIX + "calibration/two"]
        tokens = ["1" * 16, "2" * 16]
        records = [calibration.OfflineAttribution.event("PST: (path: " + token + ") file://" + self.capture_root + "/" + path)
                   for path, token in zip(paths, tokens)]
        calibration.OfflineAttribution.make_run(self, self.calibration, paths, records)
        self.mapping = {self.capture_root + "/" + path: token for path, token in zip(paths, tokens)}
        prefix = self.capture_root + "/.artifacts/tmp/process-supervisor-tests/caller-control/"
        self.mapping[prefix + "rust-tool-resolution"] = "3" * 16
        self.mapping[prefix + "rust-tools/rustup"] = "4" * 16
        native_hash = patch.object(associations.analysis, "NativePathHash", return_value=self.mapping.__getitem__)
        native_hash.start()
        self.addCleanup(native_hash.stop)
        controlled_policy(self.root, [calibration.OfflineAttribution.event("controlled daemon row")])
        self.program(body=self.body())

    def body(self):
        journal = str((self.evidence.directory / "observations.jsonl").relative_to(self.root))
        return self.policy_body() + "\nopen my $admission, '<', '" + journal + "' or die $!;\n" + r'''
my ($preflight, $prepared_scope) = (0, 0);
while (my $line = <$admission>) {
    my $row = JSON::PP::decode_json($line);
    if ($row->{event} eq 'daemon_calibration_preflight') {
        die 'wrong admitted scope' unless $row->{scope} eq 'daemon_context';
        $preflight++;
    }
    if ($row->{event} eq 'observer_ready' && $row->{test}{pid} == $$) {
        die 'preflight did not precede release' unless $preflight == 1;
        die 'wrong prepared scope' unless $row->{policy_readiness}{scope} eq 'daemon_context';
        $prepared_scope++;
    }
}
close $admission or die $!;
die 'missing unique prepared scope' unless $prepared_scope == 1;
'''

    def run_capture(self, *, stop_session=True):
        return daemon.run(self.session, self.native, self.evidence, self.root, [self.calibration],
                          stop_session=stop_session, target_family="rust")

    def consume(self, published):
        raw = associations.canonical(published["index"])
        return daemon.archive.consume(raw, published["sha256"], self.root)

    def test_held_body_observes_preflight_and_scope_before_native_settlement_and_publication(self):
        outcome = self.run_capture()
        loaded = self.consume(outcome["publication"])
        self.assertEqual(outcome["original"], self.original())
        self.assertEqual(outcome["original"]["returncode"], 0)
        self.assertEqual(loaded["index"]["context"]["scope"], "daemon_context")
        self.assertEqual(loaded["index"]["limits"]["original_qualification"], "not_claimed")
        self.assertEqual({row["token"] for row in loaded["index"]["context"]["sources"]}, {"3" * 16, "4" * 16})
        self.assertTrue((self.root / "policy-body-proof").exists())
        settled = next(row for row in self.events() if row["event"] == "settled")
        self.assertTrue(settled["observed_fixtures_gone"])
        self.assertGreater(settled["selected_fixture_count"], 0)
        self.assertGreater(self.session.stop_calls, 0)
        self.session.submit.assert_not_called()
        self.check_closed()

    def test_original_failure_stays_failed_after_successful_portable_publication(self):
        self.program(exit_code=23, body=self.body())
        with self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_capture()
        self.assertFalse(failed.exception.interrupted)
        self.assertIsNotNone(failed.exception.published)
        loaded = self.consume(failed.exception.published)
        self.assertEqual(self.original()["returncode"], 23)
        self.assertEqual(loaded["index"]["context"]["original"]["returncode"], 23)
        self.assertIn("original test failed", str(failed.exception.__cause__))
        self.check_closed()

    def test_large_collected_stream_preserves_metadata_and_late_progress(self):
        rows = [{"controlled_metadata": number} for number in range(4096)]
        rows += [calibration.OfflineAttribution.event("starting work for scan: PST: (path: " + "4" * 16 + ")")]
        controlled_policy(self.root, rows)
        outcome = self.run_capture()
        checked = self.consume(outcome["publication"])
        entries = [entry for page in checked["pages"] for entry in page["records"]]
        self.assertEqual(len(entries), 4097)
        self.assertEqual(checked["index"]["metadata_count"], 4096)
        self.assertEqual([entry["sha256"] for entry in entries],
                         [associations.digest(associations.canonical(row)) for row in rows])
        self.assertEqual(entries[-1]["phase"], "started")
        self.assertEqual(entries[-1]["tokens"], ["4" * 16])
        self.assertEqual(outcome["original"]["returncode"], 0)
        self.check_closed()

    def test_header_only_collector_rejects_nonempty_archive_without_promoting_original(self):
        controlled_policy(self.root, [])
        with self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_capture()
        self.assertIsNone(failed.exception.published)
        self.assertIn("no retained rows", str(failed.exception.__cause__))
        self.assertEqual(self.original()["returncode"], 0)
        self.assertFalse((self.evidence.directory / daemon.archive.INDEX_FILE).exists())
        self.check_closed()

    def test_invalid_preflight_stops_standalone_helper_without_any_launch(self):
        with patch.object(associations, "calibration_snapshot", side_effect=ValueError("private calibration failure")), \
                patch.object(launcher.policy_log, "PolicyLog") as collector, self.assertRaises(daemon.CaptureFailure):
            self.run_capture()
        collector.assert_not_called()
        self.assertEqual(self.children, [])
        self.assertGreater(self.session.stop_calls, 0)
        self.assertFalse((self.root / "body-entered").exists())

    def test_sequence_invocation_leaves_helper_ownership_with_its_controller(self):
        result = self.run_capture(stop_session=False)
        self.consume(result["publication"])
        self.assertEqual(self.session.stop_calls, 0)
        self.assertTrue(self.session.ready)
        self.check_closed()

    def test_interrupted_preflight_survives_failed_helper_shutdown(self):
        with patch.object(associations, "calibration_snapshot", side_effect=KeyboardInterrupt), \
                patch.object(launcher, "stop_helper", side_effect=OSError("private cleanup failure")), \
                self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_capture()
        self.assertTrue(failed.exception.interrupted)
        self.assertIsInstance(failed.exception.__cause__.__cause__, KeyboardInterrupt)
        failures = json.loads((self.evidence.directory / "failure.json").read_text())["failures"]
        self.assertIn("private cleanup failure", failures["cleanup"])
        self.assertEqual(self.children, [])

    def test_changed_calibration_after_entry_cannot_receive_a_publication_index(self):
        original_run = launcher.run
        def change(*args, **kwargs):
            result = original_run(*args, **kwargs)
            path = self.root / self.calibration / "test-result.json"
            path.write_text(json.dumps(dict(returncode=0, timeout=False)))
            return result
        with patch.object(launcher, "run", side_effect=change), self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_capture()
        self.assertIsNone(failed.exception.published)
        self.assertEqual(self.original()["returncode"], 0)
        self.assertIn("changed after prospective admission", str(failed.exception.__cause__))
        self.assertFalse((self.evidence.directory / daemon.archive.INDEX_FILE).exists())
        self.check_closed()

    def test_publication_failure_cannot_replace_original_failure_or_skip_cleanup(self):
        self.program(exit_code=23, body=self.body())
        with patch.object(daemon.archive, "publish", side_effect=OSError("private publication failure")), \
                self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_capture()
        self.assertIn("original test failed", str(failed.exception.__cause__))
        failures = json.loads((self.evidence.directory / "failure.json").read_text())["failures"]
        self.assertIn("private publication failure", failures["final"])
        self.assertEqual(self.original()["returncode"], 23)
        self.check_closed()

    def test_cancel_after_release_remains_interrupted_after_owned_cleanup(self):
        self.program(body=self.body(), with_fixture=False)
        with patch.object(launcher, "wait_for_exec", side_effect=KeyboardInterrupt), \
                self.assertRaises(daemon.CaptureFailure) as failed:
            self.run_capture()
        self.assertTrue(failed.exception.interrupted)
        self.assertIsNone(failed.exception.published)
        self.check_closed()

    def cli(self, args):
        stdout, stderr = io.StringIO(), io.StringIO()
        with patch.object(daemon, "ROOT", self.root), patch.object(daemon.sys, "platform", "darwin"), \
                patch.dict(os.environ, {"FSMGEN_RAM_GUARD_ACTIVE": "1"}), \
                patch.object(launcher, "OwnedProcesses", return_value=self.native), \
                patch.object(launcher.observer, "CaptureSession", return_value=self.session), \
                patch.object(launcher.observer, "Evidence", return_value=self.evidence), \
                contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            status = daemon.main(args)
        return status, stdout.getvalue(), stderr.getvalue()

    def test_cli_emits_only_validated_index_even_when_original_fails(self):
        self.program(exit_code=23, body=self.body())
        status, stdout, stderr = self.cli(["--session", "controlled", "--calibration", self.calibration,
                                          "--target-family", "rust"])
        self.assertEqual(status, 1)
        self.assertEqual(stderr, daemon.PUBLIC_FAILURE + "\n")
        lines = stdout.splitlines()
        self.assertEqual(lines[0], str(self.evidence.directory.relative_to(self.root)))
        self.assertEqual(self.consume(json.loads(lines[1]))["index"]["context"]["original"]["returncode"], 23)
        self.assertNotIn(str(self.root), stdout + stderr)
        self.check_closed()

    def test_cli_rejects_overrides_and_private_errors_before_native_admission(self):
        for option in ("--policy-scope", "--predicate", "--count", "--deadline"):
            stdout, stderr = io.StringIO(), io.StringIO()
            with self.subTest(option=option), patch.object(launcher, "OwnedProcesses") as native, \
                    contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                status = daemon.main(["--session", "/private/session", "--calibration", "/private/calibration",
                                      option, "/private/argument"])
            self.assertEqual(status, 1)
            native.assert_not_called()
            self.assertEqual(stdout.getvalue(), "")
            self.assertEqual(stderr.getvalue(), daemon.PUBLIC_FAILURE + "\n")

    def test_cli_rejects_abbreviated_arguments_before_native_admission(self):
        stderr = io.StringIO()
        with patch.object(launcher, "OwnedProcesses") as native, contextlib.redirect_stderr(stderr):
            status = daemon.main(["--sess", "controlled", "--cal", self.calibration])
        self.assertEqual(status, 1)
        native.assert_not_called()
        self.assertEqual(stderr.getvalue(), daemon.PUBLIC_FAILURE + "\n")

    def test_failed_evidence_setup_closes_admitted_helper_without_launch(self):
        stdout, stderr = io.StringIO(), io.StringIO()
        with patch.object(daemon.sys, "platform", "darwin"), \
                patch.dict(os.environ, {"FSMGEN_RAM_GUARD_ACTIVE": "1"}), \
                patch.object(launcher, "OwnedProcesses", return_value=self.native), \
                patch.object(launcher.observer, "CaptureSession", return_value=self.session), \
                patch.object(launcher.observer, "Evidence", side_effect=OSError("/private/evidence")), \
                patch.object(daemon, "run") as run, contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            status = daemon.main(["--session", "controlled", "--calibration", self.calibration])
        self.assertEqual(status, 1)
        run.assert_not_called()
        self.assertGreater(self.session.stop_calls, 0)
        self.assertEqual(stderr.getvalue(), daemon.PUBLIC_FAILURE + "\n")

    def test_cli_interruption_survives_broken_evidence_close(self):
        real_stream = self.evidence.stream
        with patch.object(daemon, "run", side_effect=daemon.CaptureFailure(interrupted=True)), \
                patch.object(self.evidence, "stream", Mock(close=Mock(side_effect=OSError("/private/close")))):
            status, stdout, stderr = self.cli(["--session", "controlled", "--calibration", self.calibration])
        self.assertEqual(status, 130)
        self.assertEqual(stderr, daemon.PUBLIC_FAILURE + "\n")
        self.assertNotIn("/private/close", stdout + stderr)
        real_stream.close()


if __name__ == "__main__":
    unittest.main()
