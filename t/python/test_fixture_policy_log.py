"""Real bounded producer and independent retained-record controls; no OS writes."""

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
import fixture_policy_log as policy
import fixture_kernel_sampler as sampler
import observe_fixture_startup as observer
import run_fixture_startup_observation as launcher


class PortableIdentity:
    def identity(self, pid):
        return dict(pid=pid, ppid=os.getpid(), uid=os.getuid(), ruid=os.getuid(),
                    start_sec=100, start_usec=200)


class PolicyControls(unittest.TestCase):
    scope = "fixture_path"

    def setUp(self):
        workspace = tempfile.TemporaryDirectory(prefix="policy-controls-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(workspace.cleanup)
        self.root = Path(workspace.name)
        self.evidence = observer.Evidence(self.root)
        self.addCleanup(self.evidence.stream.close)
        native = sampler.NativeProcesses() if sys.platform == "darwin" else PortableIdentity()
        self.collector = policy.PolicyLog(self.root, self.evidence.directory, native, scope=self.scope)
        self.addCleanup(self.close_collector)

    def close_collector(self):
        # A failed assertion must still consume the real held child.
        process = self.collector.process
        if process is not None and process.poll() is None:
            process.kill()
            process.wait(timeout=2)
        for stream in self.collector.streams.values():
            if not stream.closed:
                stream.close()

    def controlled(self, body="", *, header=True):
        popen = subprocess.Popen
        source = 'use strict; use warnings; $|=1; $SIG{INT}=sub { exit 0 }; alarm 10;\n'
        if header:
            source += 'print "Filtering the log data using controlled predicate\\n";\n'
        source += body + '\nwhile (1) { select undef, undef, undef, 0.05; }\n'
        path = self.root / "controlled-policy.pl"
        path.write_text(source)

        def spawn(argv, **kwargs):
            self.assertEqual(argv, policy.command(self.root, scope=self.scope))
            self.assertEqual(kwargs["cwd"], self.root)
            for key in ("TMPDIR", "TMP", "TEMP"):
                self.assertEqual(kwargs["env"][key], str(self.root / ".artifacts/tmp"))
            return popen(["/usr/bin/perl", str(path)], **kwargs)

        return patch.object(policy.subprocess, "Popen", side_effect=spawn)

    def result(self):
        return json.loads((self.evidence.directory / "policy-result.json").read_text())

    def test_retained_record_survives_source_loss_and_missing_later_query(self):
        source = self.root / "volatile-source"
        source.write_text('{"eventMessage":"literal fixture record","timestamp":"controlled"}\n')
        body = ('open my $input, "<", "volatile-source" or die $!; '
                'print while <$input>; close $input or die $!; '
                'unlink "volatile-source" or die $!;')
        with self.controlled(body):
            witness = self.collector.prepare()
            deadline = time.monotonic() + 2
            while source.exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertFalse(source.exists())
            self.collector.check()
            result = self.collector.finish()
        raw = (self.evidence.directory / "policy.stdout").read_bytes()
        rows = [json.loads(row) for row in raw.splitlines()[1:]]
        self.assertEqual(rows, [{"eventMessage": "literal fixture record", "timestamp": "controlled"}])
        self.assertEqual(list(self.root.glob("volatile-source")), [], "later source retrieval is empty")
        self.assertEqual(result["failures"], {})
        self.assertEqual(result["scope"], self.scope)
        self.assertEqual(witness["scope"], self.scope)
        self.assertEqual(launcher.retained_policy_result(self.evidence, scope=self.scope), result)
        self.assertTrue(result["leader_reaped"])
        self.assertEqual(result["returncode"], 0)
        self.assertEqual(witness["subscription_readiness"], "unproved")
        self.assertEqual(result["complete_coverage"], "unproved")
        self.assertEqual(self.result(), result)
        self.assertNotIn(str(self.root), json.dumps(result))
        self.assertFalse((self.evidence.directory / "policy-result.next").exists())
        with self.assertRaises(ChildProcessError):
            os.waitpid(self.collector.process.pid, os.WNOHANG)
        self.assertEqual(self.collector.finish(), result)

    def test_empty_stream_is_not_complete_coverage(self):
        with self.controlled():
            self.collector.prepare()
            result = self.collector.finish()
        self.assertEqual(result["failures"], {})
        self.assertEqual(result["missing_records"], "unknown")
        self.assertEqual(len((self.evidence.directory / "policy.stdout").read_bytes().splitlines()), 1)

    def test_independent_source_loss_oracle_rejects_discarded_live_records(self):
        finish = policy.PolicyLog.finish

        def discard(collector):
            if not collector.finished:
                os.ftruncate(collector.streams["stdout"].fileno(), 0)
            return finish(collector)

        control = type(self)("test_retained_record_survives_source_loss_and_missing_later_query")
        result = unittest.TestResult()
        with patch.object(policy.PolicyLog, "finish", discard):
            control.run(result)
        self.assertEqual(result.errors, [])
        self.assertEqual(len(result.failures), 1)
        self.assertIn("Lists differ", result.failures[0][1])

    def test_observed_lifetime_overrun_stays_failed_after_normal_shutdown(self):
        with self.controlled():
            self.collector.prepare()
        with patch.object(policy, "LIFETIME_SECONDS", 0), \
                self.assertRaisesRegex(TimeoutError, "fixed lifetime"):
            self.collector.check()
        result = self.collector.finish()
        self.assertIn("collection", result["failures"])
        self.assertTrue(result["leader_reaped"])
        self.assertEqual(result["command"][7], "240")

    def test_bad_header_prevents_preparation_and_still_reaps(self):
        with self.controlled('print "unexpected header\\n";', header=False), \
                self.assertRaisesRegex(ValueError, "native filter header"):
            self.collector.prepare()
        result = self.collector.finish()
        self.assertIn("prepare", result["failures"])
        self.assertIsNone(result["prepared_ns"])
        self.assertTrue(result["leader_reaped"])

    def test_missing_header_is_bounded_and_consumes_child(self):
        with self.controlled(header=False), patch.object(policy, "START_SECONDS", 0.1), \
                self.assertRaisesRegex(TimeoutError, "startup header"):
            self.collector.prepare()
        self.assertTrue(self.collector.finish()["leader_reaped"])

    def test_premature_zero_exit_remains_a_collection_failure(self):
        with self.controlled('exit 0;'):
            try:
                self.collector.prepare()
            except RuntimeError as error:
                self.assertIn("exited before", str(error))
            self.collector.process.wait(timeout=2)
        result = self.collector.finish()
        self.assertEqual(result["returncode"], 0)
        self.assertIn("collection", result["failures"])
        self.assertTrue(result["leader_reaped"])

    def test_native_file_limit_bounds_output_and_preserves_overflow_failure(self):
        with self.controlled('print "X" x 100000;'), patch.object(policy, "OUTPUT_BYTES", 1024):
            try:
                self.collector.prepare()
            except RuntimeError:
                pass
            self.collector.process.wait(timeout=2)
            result = self.collector.finish()
        self.assertLessEqual((self.evidence.directory / "policy.stdout").stat().st_size, 1024)
        self.assertTrue(result["failures"])
        self.assertTrue(result["leader_reaped"])

    def test_child_independently_reads_the_default_file_limit(self):
        popen = subprocess.Popen
        source = ('import json,resource,signal,time; '
                  'signal.signal(signal.SIGINT,lambda *_:exit(0)); signal.alarm(10); '
                  'print("Filtering the log data using controlled predicate",flush=True); '
                  'print(json.dumps(resource.getrlimit(resource.RLIMIT_FSIZE)),flush=True); '
                  'time.sleep(5)')
        with patch.object(policy.subprocess, "Popen", side_effect=lambda _argv, **kwargs:
                          popen([sys.executable, "-B", "-c", source], **kwargs)):
            self.collector.prepare()
        deadline = time.monotonic() + 2
        path = self.evidence.directory / "policy.stdout"
        while len(path.read_bytes().splitlines()) < 2 and time.monotonic() < deadline:
            time.sleep(0.01)
        result = self.collector.finish()
        limits = json.loads(path.read_bytes().splitlines()[1])
        self.assertEqual(limits, [16777216, 16777216])
        self.assertEqual(result["failures"], {})
        self.assertTrue(result["leader_reaped"])

    def test_independent_native_limit_oracle_rejects_changed_default(self):
        control = type(self)("test_child_independently_reads_the_default_file_limit")
        result = unittest.TestResult()
        with patch.object(policy, "OUTPUT_BYTES", 1024):
            control.run(result)
        self.assertEqual(result.errors, [])
        self.assertEqual(len(result.failures), 1)
        self.assertIn("[1024, 1024] != [16777216, 16777216]", result.failures[0][1])

    def test_int_resistance_requires_bounded_kill_and_stays_failed(self):
        with self.controlled('$SIG{INT}="IGNORE";'), patch.object(policy, "REAP_SECONDS", 0.1):
            self.collector.prepare()
            result = self.collector.finish()
        self.assertTrue(result["forced_kill"])
        self.assertEqual(result["returncode"], -signal.SIGKILL)
        self.assertTrue(result["leader_reaped"])
        self.assertIn("collection", result["failures"])

    def test_interrupted_wait_still_reaps_and_retains_cleanup_failure(self):
        with self.controlled():
            self.collector.prepare()
        wait = self.collector.process.wait
        calls = []

        def interrupted(*args, **kwargs):
            calls.append(1)
            if len(calls) == 1:
                raise KeyboardInterrupt("controlled cleanup interruption")
            return wait(*args, **kwargs)

        with patch.object(self.collector.process, "wait", side_effect=interrupted):
            result = self.collector.finish()
        self.assertTrue(result["leader_reaped"])
        self.assertIn("cleanup", result["failures"])

    def test_output_replacement_is_detected_and_owner_still_closed(self):
        with self.controlled():
            self.collector.prepare()
        output = self.evidence.directory / "policy.stdout"
        output.rename(output.with_suffix(".original"))
        output.write_text("replacement\n")
        with self.assertRaisesRegex(ValueError, "output file was replaced"):
            self.collector.check()
        result = self.collector.finish()
        self.assertTrue(result["leader_reaped"])
        self.assertIn("cleanup", result["failures"])
        self.assertFalse(result["outputs"]["stdout"]["path_identity_matches"])

    def test_existing_output_is_never_overwritten(self):
        output = self.evidence.directory / "policy.stdout"
        output.write_text("existing\n")
        with patch.object(policy.subprocess, "Popen") as spawn, self.assertRaises(FileExistsError):
            self.collector.prepare()
        spawn.assert_not_called()
        self.assertEqual(output.read_text(), "existing\n")
        self.assertIn("prepare", self.collector.finish()["failures"])

    def test_result_collision_cannot_overwrite_evidence_or_strand_collector(self):
        with self.controlled():
            self.collector.prepare()
        original = self.evidence.directory / "policy-result.json"
        original.write_bytes(b"existing evidence\n")
        with self.assertRaises(FileExistsError):
            self.collector.finish()
        self.assertEqual(original.read_bytes(), b"existing evidence\n")
        self.assertTrue(self.collector.result["leader_reaped"])
        self.assertIn("publication", self.collector.finish()["failures"]["cleanup"])
        self.assertFalse((self.evidence.directory / "policy-result.next").exists())

    def test_foreign_pending_result_is_not_removed_on_collision(self):
        with self.controlled():
            self.collector.prepare()
        pending = self.evidence.directory / "policy-result.next"
        pending.write_bytes(b"foreign pending evidence\n")
        with self.assertRaises(FileExistsError):
            self.collector.finish()
        self.assertEqual(pending.read_bytes(), b"foreign pending evidence\n")
        self.assertTrue(self.collector.result["leader_reaped"])

    def test_fixed_command_quotes_current_root_and_cannot_change_host_configuration(self):
        root = self.root / 'space and "quote"'
        argv = policy.command(root)
        self.assertEqual(argv[:7], ["/usr/bin/log", "stream", "--style", "ndjson", "--level", "debug", "--timeout"])
        self.assertEqual(argv[7:9], ["240", "--predicate"])
        self.assertEqual(json.loads(argv[9].split(" CONTAINS ", 1)[1]),
                         str(root / ".artifacts/tmp/process-supervisor-tests") + "/")
        self.assertNotIn("config", argv)

    def test_retained_scope_and_command_cannot_be_relabelled(self):
        with self.controlled():
            self.collector.prepare()
            original = self.collector.finish()
        path = self.evidence.directory / "policy-result.json"
        for change in ({"scope": "arbitrary"}, {"scope": None}, {"command": ["/usr/bin/log", "config"]}):
            with self.subTest(change=change):
                path.write_text(json.dumps(dict(original, **change)) + "\n")
                with self.assertRaisesRegex(RuntimeError, "scope or command"):
                    launcher.retained_policy_result(self.evidence, scope=self.scope)
        path.write_text(json.dumps(original) + "\n")
        self.assertEqual(launcher.retained_policy_result(self.evidence, scope=self.scope), original)
        other = "execution_context" if self.scope == "fixture_path" else "fixture_path"
        with self.assertRaisesRegex(RuntimeError, "scope or command"):
            launcher.retained_policy_result(self.evidence, scope=other)

    def test_scope_is_closed_before_any_collector_spawn(self):
        for scope in (None, "", "syspolicyd", 'TRUEPREDICATE', [], {}):
            with self.subTest(scope=scope), patch.object(policy.subprocess, "Popen") as spawn:
                with self.assertRaisesRegex(ValueError, "unknown policy collection scope"):
                    policy.command(self.root, scope=scope)
                with self.assertRaisesRegex(ValueError, "unknown policy collection scope"):
                    policy.PolicyLog(self.root, self.evidence.directory, self.collector.native, scope=scope)
                spawn.assert_not_called()


class ExecutionPolicyControls(PolicyControls):
    """Apply the same real-producer failure/retention oracles to the new scope."""

    scope = "execution_context"


@unittest.skipUnless(sys.platform == "darwin", "native Foundation predicate and OS log controls")
class NativeExecutionContext(unittest.TestCase):
    def setUp(self):
        workspace = tempfile.TemporaryDirectory(prefix="policy-context-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(workspace.cleanup)
        self.root = Path(workspace.name)

    def evaluate(self, predicate, records):
        # The OS's predicate engine, not a Python reconstruction of our filter,
        # interprets actual emitted argv against independently selected records.
        # osascript/Foundation are read-only installed OS dependencies; this JXA
        # calls no application and writes no files. Temporary data stays local.
        source = '''function run(argv) {
            ObjC.import("Foundation");
            var predicate = $.NSPredicate.predicateWithFormat(argv[0]);
            return JSON.stringify(JSON.parse(argv[1]).map(function(record) {
                return Boolean(predicate.evaluateWithObject($(record)));
            }));
        }'''
        environment = dict(os.environ, TMPDIR=str(self.root), TMP=str(self.root), TEMP=str(self.root))
        result = subprocess.run(
            ["/usr/bin/osascript", "-l", "JavaScript", "-e", source,
             predicate, json.dumps(records)],
            cwd=self.root, env=environment, stdin=subprocess.DEVNULL,
            capture_output=True, timeout=5, check=True)
        self.assertEqual(result.stderr, b"")
        return json.loads(result.stdout)

    def test_context_keeps_real_token_only_records_and_excludes_unrelated_sources(self):
        # Exact message text from the dated .3.2 record, independently emitted by
        # syspolicyd. These messages have no repository path to match.
        messages = [
            "queueing up scan for code: PST: (path: e0b722d88ddbf34e), (team: (null)), (id: (null)), (bundle_id: (null))",
            "scan finished, waking up any waiters: PST: (path: e0b722d88ddbf34e), (team: (null)), (id: (null)), (bundle_id: NOT_A_BUNDLE)",
        ]
        root = self.root / 'space and "quote" \\ literal'
        prefix = str(root / ".artifacts/tmp/process-supervisor-tests") + "/"
        records = [dict(process="syspolicyd", subsystem="com.apple.syspolicy.exec", eventMessage=m)
                   for m in messages]
        records += [
            dict(process="syspolicyd", subsystem="com.apple.securityd", eventMessage=prefix + "fixture"),
            dict(process="another_process", subsystem="com.apple.syspolicy.exec", eventMessage=messages[0]),
            dict(process="syspolicyd", subsystem="unrelated.subsystem", eventMessage=messages[0]),
            dict(process="another_process", subsystem="com.apple.securityd", eventMessage=prefix + "fixture"),
            dict(process="syspolicyd", subsystem="com.apple.securityd", eventMessage=prefix[:-1] + "-other/fixture"),
        ]
        original = policy.command(root)
        self.assertEqual(original[-1], 'process == "syspolicyd" AND eventMessage CONTAINS '
                         + json.dumps(prefix, ensure_ascii=False))
        self.assertEqual(self.evaluate(original[-1], records), [False, False, True, False, False, False, False])
        context = policy.command(root, scope="execution_context")
        self.assertEqual(context[:-1], original[:-1])
        self.assertEqual(self.evaluate(context[-1], records), [True, True, True, False, False, False, False])

    def test_native_record_oracle_rejects_restored_path_only_predicate(self):
        original = policy.command
        control = type(self)("test_context_keeps_real_token_only_records_and_excludes_unrelated_sources")
        result = unittest.TestResult()
        with patch.object(policy, "command", side_effect=lambda root, **_kwargs: original(root)):
            control.run(result)
        self.assertEqual(result.errors, [])
        self.assertEqual(len(result.failures), 1)
        self.assertIn("[False, False, True", result.failures[0][1])

    @unittest.skipUnless(os.environ.get("FSMGEN_LIVE_POLICY_COLLECTOR_ORACLE") == "1",
                         "separately selected live policy collector qualification")
    def test_real_context_collector_settles_with_exact_scope_and_owned_cleanup(self):
        # Recheck at execution: import-time selection must not survive revocation.
        # This must precede evidence allocation and every native admission.
        if os.environ.get("FSMGEN_LIVE_POLICY_COLLECTOR_ORACLE") != "1":
            self.skipTest("live policy collector qualification is not selected")
        evidence = observer.Evidence(self.root)
        self.addCleanup(evidence.stream.close)
        native = sampler.NativeProcesses()
        collector = policy.PolicyLog(self.root, evidence.directory, native, scope="execution_context")
        try:
            witness = collector.prepare()
            collector.check()
        finally:
            result = collector.finish()
        self.assertEqual(witness["scope"], "execution_context")
        self.assertEqual(result["scope"], "execution_context")
        self.assertEqual(result["failures"], {})
        self.assertTrue(result["leader_reaped"])
        self.assertFalse(result["forced_kill"])
        self.assertEqual(launcher.retained_policy_result(evidence, scope="execution_context"), result)
        with self.assertRaisesRegex(RuntimeError, "scope or command"):
            launcher.retained_policy_result(evidence)
        with self.assertRaises(ChildProcessError):
            os.waitpid(collector.process.pid, os.WNOHANG)
        self.assertFalse(observer.still_live(native, witness["identity"]))
        self.assertIn(b"com.apple.syspolicy.exec", (evidence.directory / "policy.stdout").read_bytes())


class LiveCollectorAdmission(unittest.TestCase):
    def invoke_body(self):
        method = NativeExecutionContext.test_real_context_collector_settles_with_exact_scope_and_owned_cleanup
        # Exercise the execution-time gate even when unittest skips the method
        # at discovery. Neither control is allowed to start a system-log stream.
        return getattr(method, "__wrapped__", method)(self)

    def test_unselected_or_revoked_live_collection_fails_before_native_admission(self):
        self.root = ROOT  # The rejected path must never allocate this evidence.
        for value in ("", "0", "true", "yes"):
            with self.subTest(selection=value), \
                    patch.dict(os.environ, {"FSMGEN_LIVE_POLICY_COLLECTOR_ORACLE": value}), \
                    patch.object(observer, "Evidence", side_effect=AssertionError("unselected evidence boundary")) as evidence, \
                    patch.object(sampler, "NativeProcesses") as native, \
                    patch.object(policy, "PolicyLog") as collector:
                with self.assertRaisesRegex(unittest.SkipTest, "not selected"):
                    self.invoke_body()
                evidence.assert_not_called()
                native.assert_not_called()
                collector.assert_not_called()

    def test_exact_selection_reaches_evidence_boundary_without_collection(self):
        self.root = ROOT  # No fixture is allocated: the boundary raises first.
        with patch.dict(os.environ, {"FSMGEN_LIVE_POLICY_COLLECTOR_ORACLE": "1"}), \
                patch.object(observer, "Evidence", side_effect=RuntimeError("selected boundary")) as evidence, \
                patch.object(sampler, "NativeProcesses") as native, \
                patch.object(policy, "PolicyLog") as collector:
            with self.assertRaisesRegex(RuntimeError, "selected boundary"):
                self.invoke_body()
            evidence.assert_called_once_with(ROOT)
            native.assert_not_called()
            collector.assert_not_called()


if __name__ == "__main__":
    unittest.main()
