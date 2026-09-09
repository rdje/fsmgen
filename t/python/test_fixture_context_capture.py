"""Fixed combined-caller controls: real held children, no original or sudo."""

import contextlib
import io
import json
import os
from pathlib import Path
import runpy
import sys
import unittest
from unittest.mock import patch

import test_fixture_startup_launcher as fixtures

launcher = fixtures.launcher
ROOT = Path(__file__).resolve().parents[2]
ENTRYPOINT = ROOT / "scripts/run_fixture_startup_context_capture.py"


class ContextCaptureControls(unittest.TestCase):
    policy_scope = "execution_context"
    setUp = fixtures.LauncherControls.setUp
    program = fixtures.LauncherControls.program
    events = fixtures.LauncherControls.events
    policy_body = fixtures.LauncherControls.policy_body

    def run_capture(self):
        return launcher.run(self.session, self.native, self.evidence, self.root,
                            target_family="rust", policy_scope=self.policy_scope)

    def test_context_is_prepared_before_entry_and_verified_at_settlement(self):
        self.program(body=self.policy_body())
        with patch.object(launcher.observer, "observe", return_value=None) as observe:
            result = self.run_capture()
        self.assertEqual(result["returncode"], 0)
        self.assertTrue(result["leader_reaped"])
        self.assertEqual(observe.call_args.kwargs["target_family"], "rust")
        self.assertEqual(launcher.TEST_ARGV,
                         ("/usr/bin/perl", "t/1669-task-acceptance-fixture-runtime.t"))
        retained = launcher.retained_policy_result(self.evidence, scope="execution_context")
        self.assertEqual(retained["scope"], "execution_context")
        rows = self.events()
        ready = next(row for row in rows if row["event"] == "observer_ready")
        settled = next(row for row in rows if row["event"] == "policy_settled")
        self.assertEqual(ready["policy_readiness"]["scope"], "execution_context")
        self.assertEqual(settled["scope"], "execution_context")
        self.assertEqual(rows[-1]["scope"], "execution_context")
        self.assertEqual((self.root / "body-entered").read_text(), "ready\n")
        self.assertTrue((self.root / "policy-body-proof").exists())
        self.assertGreater(self.session.stop_calls, 0)

    def test_successful_observation_preserves_original_failure_and_split_streams(self):
        self.program(exit_code=23)
        with patch.object(launcher.observer, "observe", return_value=None), \
                self.assertRaisesRegex(RuntimeError, "original test failed"):
            self.run_capture()
        result = json.loads((self.evidence.directory / "test-result.json").read_text())
        self.assertEqual(result["returncode"], 23)
        self.assertTrue(result["leader_reaped"])
        self.assertEqual((self.evidence.directory / "test.stderr").read_bytes(), b"separate stderr\n")
        self.assertIn(b"ok 1 - controlled body", (self.evidence.directory / "test.tap").read_bytes())
        self.assertEqual((self.root / "body-entered").read_text(), "ready\n")
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.assertEqual(launcher.retained_policy_result(
            self.evidence, scope="execution_context")["failures"], {})
        self.assertGreater(self.session.stop_calls, 0)

    def test_agreeing_wrong_scope_result_and_manifest_cannot_promote_success(self):
        finish = launcher.policy_log.PolicyLog.finish

        def wrong_scope(collector):
            result = finish(collector)
            result["scope"] = "fixture_path"
            result["command"] = [arg.replace(str(self.root), "<repo>")
                              for arg in launcher.policy_log.command(self.root)]
            (self.evidence.directory / "policy-result.json").write_text(json.dumps(result))
            return result

        with patch.object(launcher.observer, "observe", return_value=None), \
                patch.object(launcher.policy_log.PolicyLog, "finish", wrong_scope), \
                self.assertRaisesRegex(RuntimeError, "unexpected collection scope"):
            self.run_capture()
        self.assertEqual(json.loads((self.evidence.directory / "test-result.json").read_text())["returncode"], 0)
        self.assertFalse(any(row["event"] == "caller_complete" for row in self.events()))
        self.assertGreater(self.session.stop_calls, 0)

    def test_unknown_scope_stops_helper_without_collector_or_original(self):
        with patch.object(launcher.policy_log, "PolicyLog") as collector, \
                patch.object(launcher, "GatedTest") as child, \
                self.assertRaisesRegex(ValueError, "unknown policy collection scope"):
            launcher.run(self.session, self.native, self.evidence, self.root,
                         policy_scope="unrecognized")
        collector.assert_not_called()
        child.assert_not_called()
        self.assertGreater(self.session.stop_calls, 0)

    def test_fixed_entrypoint_passes_context_through_main_and_rejects_override(self):
        output = io.StringIO()
        with patch.object(sys, "argv", [str(ENTRYPOINT), "--session", "controlled", "--target-family", "rust"]), \
                patch.object(launcher.sys, "platform", "darwin"), \
                patch.object(launcher.os, "getuid", return_value=501), \
                patch.object(launcher.os, "geteuid", return_value=501), \
                patch.object(launcher.os, "umask"), \
                patch.dict(os.environ, {"FSMGEN_RAM_GUARD_ACTIVE": "1"}), \
                patch.object(launcher, "OwnedProcesses", return_value=self.native), \
                patch.object(launcher.observer, "CaptureSession", return_value=self.session), \
                patch.object(launcher.observer, "Evidence", return_value=self.evidence), \
                patch.object(launcher, "run", return_value={}) as run, \
                contextlib.redirect_stdout(output), self.assertRaises(SystemExit) as stopped:
            runpy.run_path(str(ENTRYPOINT), run_name="__main__")
        self.assertEqual(stopped.exception.code, 0)
        self.assertEqual(run.call_args.kwargs["policy_scope"], "execution_context")
        self.assertEqual(run.call_args.kwargs["target_family"], "rust")
        with patch.object(sys, "argv", [str(ENTRYPOINT), "--session", "controlled", "--policy-scope", "fixture_path"]), \
                patch.object(launcher, "OwnedProcesses") as native, \
                contextlib.redirect_stderr(output), self.assertRaises(SystemExit) as rejected:
            runpy.run_path(str(ENTRYPOINT), run_name="__main__")
        self.assertEqual(rejected.exception.code, 2)
        native.assert_not_called()


if __name__ == "__main__":
    unittest.main()
