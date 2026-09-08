"""Independent observer lifecycle, filesystem and native child-census controls."""

import errno
import hashlib
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
import observe_fixture_startup as observer


class Clock:
    def __init__(self):
        self.now = 0.0

    def sleep(self, duration):
        self.now += duration


class Native:
    def __init__(self, root, clock, family="rust"):
        self.clock, self.end = clock, 1.2
        self.records = {pid: dict(pid=pid, start_sec=100 + pid, start_usec=200,
                                 ppid=parent, uid=os.getuid(), ruid=os.getuid())
                        for pid, parent in ((10, 1), (20, 10), (30, 20), (40, 1))}
        workspace = root / ".artifacts/tmp/process-supervisor-tests/controlled"
        workspace.mkdir(parents=True)
        if family == "rust":
            wrapper = workspace / "rust-tool-resolution"
            producer = workspace / "rust-tools/rustup"
            producer.parent.mkdir()
            wrapper_command = f"/usr/bin/perl -Iperl -It/lib {wrapper} {producer.parent}"
            child_command = f"/usr/bin/perl {producer} which cargo"
        else:
            wrapper = workspace / "legacy-ram-capture"
            producer = workspace / "legacy-ram-streams"
            wrapper_command = f"/usr/bin/perl {wrapper} {workspace} {producer}"
            child_command = (f"/usr/bin/perl {producer} --host-max-pct 88"
                             " --process-max-rss-mb 4096 --poll-seconds 0.02"
                             " --grace-seconds 0 -- unused")
        wrapper.write_bytes(b"independent wrapper source\n")
        producer.write_bytes(b"independent producer source\n")
        self.producer = producer
        self.commands = {10: "/usr/bin/perl t/1669-task-acceptance-fixture-runtime.t",
                         20: wrapper_command, 30: child_command, 40: "authenticated-helper"}

    def identity(self, pid):
        if pid not in self.records or (pid != 40 and self.clock.now >= self.end):
            raise ProcessLookupError(errno.ESRCH, "controlled native birth is gone")
        return dict(self.records[pid])

    def executable(self, _pid):
        return Path("/usr/bin/perl").resolve()

    def command(self, pid):
        return self.commands[pid]

    def children(self, pid):
        return [key for key, item in self.records.items() if item["ppid"] == pid]


class Session:
    def __init__(self, root):
        self.directory = root / ".artifacts/logs/fixture-kernel-capture/session-control"
        self.submitted = False
        self.requests = []
        self.stop_called = False
        self.cleanup_ok = True
        self.capture = {"sampler": {"returncode": 0, "timeout": False}}

    def submit(self, request):
        self.requests.append(request)
        if self.submitted:
            raise AssertionError("second capture attempted")
        self.submitted = True

    def result(self):
        return self.capture

    def stop(self):
        self.stop_called = True

    def stopped(self):
        return self.stop_called and self.cleanup_ok


class ObserverControls(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory(prefix="observer-controls-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(self.workspace.cleanup)
        self.root = Path(self.workspace.name)
        (self.root / "scripts").mkdir()
        (self.root / "scripts/fixture_kernel_sampler.py").write_bytes(
            (ROOT / "scripts/fixture_kernel_sampler.py").read_bytes())
        self.clock = Clock()
        self.session = Session(self.root)
        self.evidence = observer.Evidence(self.root)
        self.addCleanup(self.evidence.stream.close)
        self.native = Native(self.root, self.clock)
        self.test = self.native.identity(10)

    def run_observer(self, **kwargs):
        with patch.object(observer.time, "monotonic", side_effect=lambda: self.clock.now), \
                patch.object(observer.time, "sleep", side_effect=self.clock.sleep):
            return observer.observe(self.test, self.native, self.session, self.evidence, self.root, **kwargs)

    def test_sequence_owner_keeps_helper_live_until_capture_result_is_consumed(self):
        def delayed_result():
            return self.session.capture if self.clock.now >= 1.5 else None

        with patch.object(self.session, "result", side_effect=delayed_result):
            self.assertEqual(self.run_observer(stop_session=False), self.session.capture)
        self.assertFalse(self.session.stop_called)
        self.assertGreaterEqual(self.clock.now, 1.5)
        self.assertFalse(self.events()[-1]["helper_stopped"])
        self.assertEqual(self.events()[-1]["helper_shutdown_owner"], "caller")

    def test_sequence_owner_cannot_hide_missing_capture_or_fixture_cleanup(self):
        self.session.capture = None
        with patch.object(observer, "SETTLE_SECONDS", 0.2), \
                self.assertRaisesRegex(RuntimeError, "could not verify"):
            self.run_observer(stop_session=False)
        self.assertFalse(self.session.stop_called)
        self.assertEqual(len(self.session.requests), 1)
        self.assertIn("cleanup", json.loads((self.evidence.directory / "failure.json").read_text())["failures"])

    def events(self):
        return [json.loads(line) for line in (self.evidence.directory / "observations.jsonl").read_text().splitlines()]

    def add_later_legacy(self, *, entered=False, child=True):
        workspace = self.native.producer.parent.parent
        wrapper, producer = workspace / "legacy-ram-capture", workspace / "legacy-ram-streams"
        wrapper.write_bytes(b"independent later legacy wrapper\n")
        producer.write_bytes(b"independent later legacy producer\n")
        if entered:
            Path(str(producer) + "-progress").write_bytes(b"entered\n")
        self.native.records[50] = dict(self.native.records[20], pid=50, start_sec=150)
        self.native.commands[50] = f"/usr/bin/perl {wrapper} {workspace} {producer}"
        if child:
            self.native.records[60] = dict(self.native.records[30], pid=60, ppid=50, start_sec=160)
            self.native.commands[60] = (f"/usr/bin/perl {producer} --host-max-pct 88"
                                       " --process-max-rss-mb 4096 --poll-seconds 0.02"
                                       " --grace-seconds 0 -- unused")
        children = self.native.children
        self.native.children = lambda pid: [candidate for candidate in children(pid)
                                           if candidate not in (50, 60) or self.clock.now >= 0.8]
        self.native.end = 2.0

    def test_legacy_selection_reaches_later_producer_without_spending_capture_on_rust(self):
        self.add_later_legacy()
        self.assertEqual(self.run_observer(target_family="legacy"), self.session.capture)
        self.assertEqual([request["pid"] for request in self.session.requests], [60])
        rows = self.events()
        self.assertEqual({row["evidence"]["child"]["pid"] for row in rows
                          if row["event"] == "candidate"}, {20, 30, 50, 60})
        self.assertEqual(rows[-1]["observed_fixture_count"], 4)
        self.assertEqual(rows[-1]["selected_fixture_count"], 2)
        self.assertEqual(rows[-1]["target_family"], "legacy")
        self.assertTrue(self.session.stop_called)

    def test_independent_mixed_family_oracle_rejects_unfiltered_capture(self):
        control = type(self)("test_legacy_selection_reaches_later_producer_without_spending_capture_on_rust")
        result = unittest.TestResult()
        with patch.object(observer, "selected_target", return_value=True):
            control.run(result)
        self.assertEqual(result.errors, [])
        self.assertEqual(len(result.failures), 1)
        self.assertIn("[30] != [60]", result.failures[0][1])

    def test_rust_only_cannot_establish_legacy_coverage(self):
        with self.assertRaisesRegex(RuntimeError, "no selected fixture was observed"):
            self.run_observer(target_family="legacy")
        self.assertEqual(self.session.requests, [])
        self.assertEqual(self.events()[-1]["observed_fixture_count"], 2)
        self.assertEqual(self.events()[-1]["selected_fixture_count"], 0)
        self.assertTrue(self.session.stop_called)

    def test_legacy_wrapper_without_child_remains_eligible(self):
        self.add_later_legacy(child=False)
        self.assertEqual(self.run_observer(target_family="legacy"), self.session.capture)
        self.assertEqual([request["pid"] for request in self.session.requests], [50])

    def test_entered_legacy_producer_excludes_its_remaining_wrapper(self):
        self.add_later_legacy(entered=True, child=False)
        self.assertIsNone(self.run_observer(target_family="legacy"))
        self.assertEqual(self.session.requests, [])
        self.assertTrue(any(row.get("progress") == "entered" and
                            row.get("progress_scope") == "selected_producer" for row in self.events()))
        self.assertEqual(self.events()[-1]["selected_fixture_count"], 1)

    def test_invalid_family_stops_helper_without_observing_or_sampling(self):
        with self.assertRaisesRegex(ValueError, "target family must be"):
            self.run_observer(target_family="rust")
        self.assertEqual(self.session.requests, [])
        self.assertTrue(self.session.stop_called)
        self.assertFalse(any(row["event"] == "attached" for row in self.events()))

    def test_one_capture_prefers_the_nested_target_and_retains_exact_sources(self):
        result = self.run_observer()
        self.assertEqual(result, self.session.capture)
        self.assertEqual(len(self.session.requests), 1)
        self.assertEqual(self.session.requests[0]["pid"], 30)
        self.assertEqual(self.session.requests[0]["parent_pid"], 20)
        self.assertEqual(self.session.requests[0]["ancestor_pid"], 10)
        self.assertTrue(self.session.stop_called)
        records = self.events()
        self.assertEqual(sum(row["event"] == "capture_requested" for row in records), 1)
        self.assertEqual(records[-1]["original_test_result"], "caller_owned")
        self.assertEqual(records[-1]["unobserved_descendants"], "unknown")
        sources = list(self.evidence.directory.glob("*.source"))
        self.assertEqual({path.read_bytes() for path in sources},
                         {b"independent wrapper source\n", b"independent producer source\n"})
        for path in sources:
            self.assertEqual(path.stem, hashlib.sha256(path.read_bytes()).hexdigest())

    def command_query_control(self, disappears):
        # The real command-query method sees a closed ps error. Independently
        # change native census state only in the disappearing-process control.
        self.native.records[50] = dict(self.native.records[20], pid=50)
        self.native.commands[50] = self.native.commands[20]
        children = self.native.children

        def query(argv, **_kwargs):
            pid = int(argv[2])
            self.assertEqual(argv, ["/bin/ps", "-p", str(pid), "-o", "command="])
            if pid == 50:
                if disappears:
                    del self.native.records[50]
                raise subprocess.CalledProcessError(1, argv)
            return subprocess.CompletedProcess(argv, 0,
                                               (self.native.commands[pid] + "\n").encode(), b"")

        with patch.object(self.native, "children", side_effect=lambda pid: sorted(children(pid), reverse=True)), \
                patch.object(self.native, "command", side_effect=lambda pid:
                             observer.sampler.NativeProcesses.command(self.native, pid)), \
                patch.object(observer.sampler.subprocess, "run", side_effect=query):
            return self.run_observer()

    def test_disappeared_command_query_does_not_hide_a_later_eligible_fixture(self):
        self.assertEqual(self.command_query_control(True), self.session.capture)
        self.assertEqual([request["pid"] for request in self.session.requests], [30])
        self.assertTrue(self.session.stop_called)
        self.assertFalse((self.evidence.directory / "failure.json").exists())

    def test_live_process_command_query_failure_still_aborts_observation(self):
        with self.assertRaises(subprocess.CalledProcessError):
            self.command_query_control(False)
        self.assertTrue(self.session.stop_called)
        self.assertEqual(self.session.requests, [])
        self.assertIn("non-zero exit status", json.loads(
            (self.evidence.directory / "failure.json").read_text())["failures"]["observation"])

    def test_native_exit_during_final_revalidation_keeps_observation_running(self):
        validate = observer.sampler.validate_target
        validations = {}

        def exit_before_publication(request, processes, root):
            if request["pid"] == 30 and self.clock.now >= observer.CANDIDATE_SECONDS:
                validations[self.clock.now] = validations.get(self.clock.now, 0) + 1
                if validations[self.clock.now] == 2:
                    del self.native.records[30]
            return validate(request, processes, root)

        with patch.object(observer.sampler, "validate_target", side_effect=exit_before_publication):
            self.assertEqual(self.run_observer(), self.session.capture)
        self.assertNotIn(30, self.native.records, "control did not remove the selected birth")
        self.assertEqual([request["pid"] for request in self.session.requests], [20])
        self.assertTrue(self.session.stop_called)
        self.assertFalse((self.evidence.directory / "failure.json").exists())

    def test_native_main_entry_excludes_the_expected_legacy_pipe_wait(self):
        # Distinct workspace for literal legacy commands, independently written marker.
        other = self.root / "legacy-control"
        other.mkdir()
        (other / "scripts").mkdir()
        (other / "scripts/fixture_kernel_sampler.py").write_bytes(
            (ROOT / "scripts/fixture_kernel_sampler.py").read_bytes())
        native = Native(other, self.clock, "legacy")
        Path(str(native.producer) + "-progress").write_bytes(b"entered\n")
        with patch.object(observer.time, "monotonic", side_effect=lambda: self.clock.now), \
                patch.object(observer.time, "sleep", side_effect=self.clock.sleep):
            evidence = observer.Evidence(other)
            try:
                session = Session(other)
                self.assertIsNone(observer.observe(native.identity(10), native, session, evidence, other))
                self.assertEqual(session.requests, [])
                records = [json.loads(line) for line in (evidence.directory / "observations.jsonl").read_text().splitlines()]
                self.assertTrue(any(row.get("progress") == "entered" for row in records))
            finally:
                evidence.stream.close()

    def test_stale_test_identity_stops_helper_without_sampling(self):
        self.test["start_usec"] += 1
        with self.assertRaisesRegex(ValueError, "exact normal-user"):
            self.run_observer()
        self.assertTrue(self.session.stop_called)
        self.assertEqual(self.session.requests, [])
        self.assertIn("exact normal-user", json.loads(
            (self.evidence.directory / "failure.json").read_text())["failures"]["observation"])

    def test_no_admitted_fixture_is_failed_coverage_after_helper_cleanup(self):
        self.native.commands[20] = "/usr/bin/perl unrelated-control"
        with self.assertRaisesRegex(RuntimeError, "no selected fixture was observed"):
            self.run_observer()
        self.assertTrue(self.session.stop_called)
        self.assertEqual(self.session.requests, [])
        self.assertEqual(self.events()[-1]["observed_fixture_count"], 0)
        self.assertIn("no selected fixture", json.loads(
            (self.evidence.directory / "failure.json").read_text())["failures"]["observation"])

    def test_main_entry_is_rechecked_before_request_publication(self):
        other = self.root / "late-entry"
        other.mkdir()
        (other / "scripts").mkdir()
        (other / "scripts/fixture_kernel_sampler.py").write_bytes(
            (ROOT / "scripts/fixture_kernel_sampler.py").read_bytes())
        native = Native(other, self.clock, "legacy")
        validate = observer.sampler.validate_target
        ready_validations = {}

        def enter_before_publication(request, processes, root):
            result = validate(request, processes, root)
            if request["pid"] == 30 and self.clock.now >= observer.CANDIDATE_SECONDS:
                ready_validations[self.clock.now] = ready_validations.get(self.clock.now, 0) + 1
                if ready_validations[self.clock.now] == 2:
                    Path(str(native.producer) + "-progress").write_bytes(b"entered\n")
            return result

        evidence = observer.Evidence(other)
        self.addCleanup(evidence.stream.close)
        session = Session(other)
        with patch.object(observer.time, "monotonic", side_effect=lambda: self.clock.now), \
                patch.object(observer.time, "sleep", side_effect=self.clock.sleep), \
                patch.object(observer.sampler, "validate_target", side_effect=enter_before_publication):
            self.assertIsNone(observer.observe(native.identity(10), native, session, evidence, other))
        self.assertEqual(session.requests, [])
        self.assertTrue(Path(str(native.producer) + "-progress").exists())

    def test_failure_result_stays_failed_and_is_not_retried(self):
        self.session.capture = {"sampler": {"returncode": 77, "timeout": False}}
        with self.assertRaisesRegex(RuntimeError, "capture was rejected, failed"):
            self.run_observer()
        self.assertEqual(len(self.session.requests), 1)
        self.assertTrue(self.session.stop_called)
        self.assertTrue(any(row.get("result") == self.session.capture for row in self.events()))

    def test_observer_wall_preserves_first_failure_when_cleanup_also_fails(self):
        self.native.end = 1000
        self.session.cleanup_ok = False
        with patch.object(observer, "OBSERVATION_SECONDS", 0.2), \
                patch.object(observer, "SETTLE_SECONDS", 0.2), \
                self.assertRaisesRegex(RuntimeError, "could not verify"):
            self.run_observer()
        failures = json.loads((self.evidence.directory / "failure.json").read_text())["failures"]
        self.assertIn("wall expired", failures["observation"])
        self.assertIn("could not verify", failures["cleanup"])
        self.assertTrue(self.session.stop_called)

    def test_exhausted_event_storage_retains_failure_and_stops_helper(self):
        with patch.object(observer, "MAX_EVENTS", 1), self.assertRaisesRegex(ValueError, "storage bound"):
            self.run_observer()
        self.assertTrue(self.session.stop_called)
        self.assertEqual(self.session.requests, [])
        failures = json.loads((self.evidence.directory / "failure.json").read_text())["failures"]
        self.assertIn("storage bound", failures["observation"])
        self.assertIn("storage bound", failures["cleanup"])

    def test_raw_sources_and_event_storage_have_independent_bounds(self):
        body = b"source"
        source = self.root / "source"
        source.write_bytes(body)
        record = {"path": "source", "sha256": hashlib.sha256(body).hexdigest(), "size_bytes": len(body)}
        with patch.object(observer, "MAX_SOURCE_BYTES", len(body) - 1), self.assertRaises(RuntimeError):
            self.evidence.retain_sources([record])
        self.assertEqual(list(self.evidence.directory.glob("*.source")), [])
        self.evidence.retain_sources([record])
        self.evidence.retain_sources([record])
        self.assertEqual(len(list(self.evidence.directory.glob("*.source"))), 1)
        with patch.object(observer, "MAX_EVENT_BYTES", 8), self.assertRaises(ValueError):
            self.evidence.record("oversized", data="x" * 10)
        with patch.object(observer, "MAX_EVENTS", 1):
            self.evidence.record("one")
            with self.assertRaises(ValueError):
                self.evidence.record("two")

    def test_source_digest_and_redirects_are_rejected_before_archival(self):
        source = self.root / "source"
        source.write_bytes(b"old")
        record = {"path": "source", "sha256": hashlib.sha256(b"old").hexdigest(), "size_bytes": 3}
        source.write_bytes(b"new")
        with self.assertRaisesRegex(ValueError, "changed"):
            self.evidence.retain_sources([record])
        source.unlink()
        os.mkfifo(source)
        with self.assertRaisesRegex(ValueError, "regular file"):
            observer.read_local_file(source, self.root, 64)
        source.unlink()
        source.symlink_to(self.native.producer)
        with self.assertRaisesRegex(ValueError, "direct"):
            observer.read_local_file(source, self.root, 64)

    def authenticated_session(self):
        relative = ".artifacts/logs/fixture-kernel-capture/session-" + "a" * 32
        directory = self.root / relative
        directory.mkdir(parents=True, mode=0o700)
        state = {"state": "ready", "helper": self.native.identity(40),
                 "producer_sha256": hashlib.sha256((self.root / "scripts/fixture_kernel_sampler.py").read_bytes()).hexdigest()}
        (directory / "session.json").write_text(json.dumps(state))
        return relative, directory, state

    def test_session_publishes_complete_request_exclusively_and_refuses_replacement(self):
        relative, directory, state = self.authenticated_session()
        session = observer.CaptureSession(relative, self.native, self.root)
        request = observer.request_for([self.native.identity(30), self.native.identity(20), self.test])
        link = os.link
        observed = []

        def reader_at_publication(source, target):
            self.assertFalse(target.exists())
            observed.append(json.loads(source.read_text()))
            link(source, target)

        with patch.object(observer.os, "link", side_effect=reader_at_publication):
            session.submit(request)
        self.assertEqual(observed, [request])
        self.assertEqual(json.loads((directory / "request-0001.json").read_text()), request)
        self.assertEqual(list(directory.glob("*.pending")), [])
        with self.assertRaises(ValueError):
            session.submit(request)
        state["helper"]["start_usec"] += 1
        (directory / "session.json").write_text(json.dumps(state))
        with self.assertRaisesRegex(ValueError, "replacement"):
            session.stop()
        self.assertFalse((directory / "STOP").exists())

    def test_existing_request_and_bad_session_never_get_overwritten(self):
        relative, directory, state = self.authenticated_session()
        session = observer.CaptureSession(relative, self.native, self.root)
        path = directory / "request-0001.json"
        path.write_bytes(b"existing request")
        with self.assertRaises(FileExistsError):
            session.submit(observer.request_for([self.native.identity(20), self.test]))
        self.assertEqual(path.read_bytes(), b"existing request")
        self.assertEqual(list(directory.glob("*.pending")), [])
        state["last_request"] = True
        (directory / "session.json").write_text(json.dumps(state))
        with self.assertRaisesRegex(ValueError, "capacity"):
            observer.CaptureSession(relative, self.native, self.root)
        with self.assertRaises(ValueError):
            observer.CaptureSession("../session", self.native, self.root)

    @unittest.skipUnless(sys.platform == "darwin", "native Darwin PID-count ABI")
    def test_native_child_census_matches_exact_independently_forked_children(self):
        native = observer.Processes()
        before = set(native.children(os.getpid()))
        children = []
        try:
            for _ in range(2):
                pid = os.fork()
                if pid == 0:
                    signal.alarm(5)
                    time.sleep(4)
                    os._exit(0)
                children.append(pid)
            self.assertEqual(set(native.children(os.getpid())) - before, set(children))
            for pid in children:
                self.assertEqual(native.identity(pid)["ppid"], os.getpid())
            with patch.object(observer, "MAX_CHILDREN", 1), self.assertRaisesRegex(ValueError, "completeness"):
                native.children(os.getpid())
        finally:
            for pid in children:
                try:
                    os.kill(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            for pid in children:
                deadline = time.monotonic() + 3
                while time.monotonic() < deadline:
                    reaped, _ = os.waitpid(pid, os.WNOHANG)
                    if reaped:
                        self.assertEqual(reaped, pid)
                        break
                    time.sleep(0.01)
                else:
                    self.fail("native census control child was not reaped within its bound")
        self.assertEqual(set(native.children(os.getpid())), before)


if __name__ == "__main__":
    unittest.main()
