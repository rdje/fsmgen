"""Passive native fixture identity, source, progress and settlement controls."""

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

import test_fixture_startup_observer as fixtures

observer = fixtures.observer
ROOT = fixtures.ROOT


class CensusControls(unittest.TestCase):
    def setUp(self):
        workspace = tempfile.TemporaryDirectory(prefix="census-controls-", dir=ROOT / ".artifacts/tmp")
        self.addCleanup(workspace.cleanup)
        self.root = Path(workspace.name)
        self.clock = fixtures.Clock()
        self.native = fixtures.Native(self.root, self.clock)
        self.evidence = observer.Evidence(self.root)
        self.addCleanup(self.evidence.stream.close)
        for name, value in (("monotonic", lambda: self.clock.now), ("sleep", self.clock.sleep)):
            mocked = patch.object(observer.time, name, side_effect=value)
            mocked.start()
            self.addCleanup(mocked.stop)
        for owner, name in ((observer, "CaptureSession"), (observer.sampler, "capture"),
                            (observer.sampler, "sudo_validation"), (observer.os, "kill")):
            mocked = patch.object(owner, name, side_effect=AssertionError("passive census performed an active operation"))
            mocked.start()
            self.addCleanup(mocked.stop)

    def census(self, **kwargs):
        return observer.FixtureCensus(self.native.identity(10), self.native,
                                      self.evidence, self.root, **kwargs)

    def events(self):
        return [json.loads(line) for line in (self.evidence.directory / "observations.jsonl").read_text().splitlines()]

    def test_exact_admission_archives_sources_and_settles_only_observed_births(self):
        census = self.census()
        entries = census.scan()
        self.assertEqual([entry["evidence"]["child"]["pid"] for entry in entries], [30, 20])
        self.assertEqual([entry["leaf"] for entry in entries], [True, False])
        self.assertEqual(entries[0]["evidence"]["ancestor"], self.native.records[10])
        self.assertEqual({path.read_bytes() for path in self.evidence.directory.glob("*.source")},
                         {b"independent wrapper source\n", b"independent producer source\n"})
        for path in self.evidence.directory.glob("*.source"):
            self.assertEqual(path.stem, hashlib.sha256(path.read_bytes()).hexdigest())
        census.require_coverage()
        census.scan()
        self.assertEqual(sum(row["event"] == "candidate" for row in self.events()), 2)
        result = census.settle()
        self.assertEqual(result, {"observed_fixtures_gone": True, "observed_fixture_count": 2,
                                  "unobserved_descendants": "unknown"})
        self.assertEqual(self.native.identity(40)["pid"], 40, "unrelated helper remains untouched")

    def test_source_change_for_one_native_birth_is_failed_without_overwriting_archive(self):
        census = self.census()
        census.scan()
        self.native.producer.write_bytes(b"different producer source\n")
        with self.assertRaisesRegex(RuntimeError, "changed for an observed native birth"):
            census.scan()
        self.assertNotIn(b"different producer source\n",
                         [path.read_bytes() for path in self.evidence.directory.glob("*.source")])
        self.assertEqual(census.settle()["observed_fixture_count"], 2)

    def test_same_source_bytes_under_a_replacement_inode_are_rejected(self):
        census = self.census()
        census.scan()
        original_inode = self.native.producer.stat().st_ino
        replacement = self.root / "replacement-source"
        replacement.write_bytes(self.native.producer.read_bytes())
        replacement.replace(self.native.producer)
        self.assertNotEqual(self.native.producer.stat().st_ino, original_inode)
        with self.assertRaisesRegex(RuntimeError, "changed for an observed native birth"):
            census.scan()
        self.assertEqual(census.settle()["observed_fixture_count"], 2)

    def test_identity_capacity_failure_keeps_its_admitted_prefix_settleable(self):
        census = self.census()
        with patch.object(observer, "MAX_IDENTITIES", 1):
            with self.assertRaisesRegex(RuntimeError, "identity capacity"):
                census.scan()
        self.assertEqual([info["pid"] for info in census.seen.values()], [30])
        self.assertEqual(census.settle()["observed_fixture_count"], 1)

    def test_reused_pid_is_a_distinct_birth_and_never_an_old_survivor(self):
        census = self.census()
        census.scan()
        self.native.records[30]["start_usec"] += 1
        self.assertEqual([info["pid"] for info in census.survivors()], [20])
        census.scan()
        self.assertEqual(len(census.seen), 3)
        self.assertEqual(sum(row["event"] == "candidate" for row in self.events()), 3)

    def test_stale_test_and_wrong_ancestry_cannot_be_admitted(self):
        test = dict(self.native.records[10], start_usec=999)
        with self.assertRaisesRegex(ValueError, "exact normal-user"):
            observer.FixtureCensus(test, self.native, self.evidence, self.root)
        census = self.census()
        self.native.records[20]["ppid"] = 40
        self.assertEqual(census.scan(), [])
        with self.assertRaisesRegex(RuntimeError, "no fixture was observed"):
            census.require_coverage()
        self.assertEqual(census.settle()["observed_fixture_count"], 0)

    def test_legacy_wrapper_progress_names_its_selected_producer(self):
        self.root = self.root / "legacy"
        self.native = fixtures.Native(self.root, self.clock, family="legacy")
        self.evidence = observer.Evidence(self.root)
        self.addCleanup(self.evidence.stream.close)
        census = self.census()
        census.scan()
        marker = Path(str(self.native.producer) + "-progress")
        marker.write_bytes(b"entered\n")
        entries = census.scan()
        self.assertEqual([entry["progress"] for entry in entries], ["entered", "entered"])
        rows = [row for row in self.events() if row["event"] == "main_entry" and row["progress"] == "entered"]
        self.assertEqual([row["progress_scope"] for row in rows], ["target", "selected_producer"])
        marker.write_bytes(b"entered\ndrained\n")
        self.assertEqual([entry["progress"] for entry in census.scan()], ["drained", "drained"])
        marker.write_bytes(b"partial")
        with self.assertRaisesRegex(RuntimeError, "complete native progress"):
            census.scan()
        marker.write_bytes(b"x" * 65)
        with self.assertRaisesRegex(RuntimeError, "fixed byte bound"):
            census.scan()

    def test_permission_failure_and_slow_inspection_checkpoint_remain_failed(self):
        census = self.census()
        with patch.object(self.native, "command", side_effect=PermissionError(errno.EPERM, "denied")):
            with self.assertRaises(PermissionError):
                census.scan()
        calls = []

        def checkpoint():
            calls.append(self.clock.now)
            if self.clock.now >= 0.3:
                raise TimeoutError("independent inspection deadline")

        census = self.census(checkpoint=checkpoint)
        command = self.native.command

        def slow(pid):
            self.clock.now += 0.2
            return command(pid)

        with patch.object(self.native, "command", side_effect=slow):
            with self.assertRaisesRegex(TimeoutError, "inspection deadline"):
                census.scan()
        self.assertLessEqual(self.clock.now, 0.4)
        self.assertGreater(len(calls), 2)

    def test_archive_failure_retains_admitted_identity_for_caller_owned_cleanup(self):
        census = self.census()
        with patch.object(self.evidence, "retain_sources", side_effect=RuntimeError("archive full")):
            with self.assertRaisesRegex(RuntimeError, "archive full"):
                census.scan()
        self.assertEqual([info["pid"] for info in census.seen.values()], [30])
        self.assertEqual(census.settle()["observed_fixture_count"], 1)

    def test_capture_eligibility_clock_starts_after_successful_source_archival(self):
        census = self.census()
        retain = self.evidence.retain_sources

        def slow_archive(records):
            retain(records)
            self.clock.now += 0.25

        with patch.object(self.evidence, "retain_sources", side_effect=slow_archive):
            entries = census.scan()
        self.assertEqual([census.first_seen[observer.identity_key(entry["evidence"]["child"])]
                          for entry in entries], [0.25, 0.5])
        self.assertEqual([entry["observed_at"] for entry in entries], [0.25, 0.5])

    def test_observed_survivor_or_denied_cleanup_is_never_success(self):
        census = self.census()
        census.scan()
        self.native.end = 1000
        with patch.object(observer, "SETTLE_SECONDS", 0.2):
            with self.assertRaisesRegex(RuntimeError, "observed fixture cleanup"):
                census.settle()
        with patch.object(self.native, "identity", side_effect=PermissionError(errno.EPERM, "cleanup denied")):
            with self.assertRaises(PermissionError):
                census.settle()

    def test_independent_survivor_oracle_rejects_false_absence(self):
        with patch.object(observer.FixtureCensus, "survivors", return_value=[]):
            with self.assertRaisesRegex(AssertionError, "RuntimeError not raised"):
                self.test_observed_survivor_or_denied_cleanup_is_never_success()


@unittest.skipUnless(sys.platform == "darwin", "native libproc fixture admission is Darwin-only")
class NativeCensusControls(unittest.TestCase):
    def test_actual_held_perl_chains_supply_independent_identity_source_and_progress(self):
        for family in ("rust", "legacy"):
            with self.subTest(family=family), tempfile.TemporaryDirectory(
                    prefix="native-census-", dir=ROOT / ".artifacts/tmp") as temporary:
                self.check_native_chain(Path(temporary), family)

    def test_exit_during_final_command_query_is_native_disappearance(self):
        with tempfile.TemporaryDirectory(prefix="native-census-exit-", dir=ROOT / ".artifacts/tmp") as temporary:
            self.check_native_chain(Path(temporary), "legacy", exit_during_command=True)

    def test_native_exit_oracle_rejects_missing_successful_query_presence_check(self):
        def unchecked_command(native, pid):
            result = subprocess.run(["/bin/ps", "-p", str(pid), "-o", "command="],
                                    stdin=subprocess.DEVNULL, capture_output=True,
                                    timeout=2, check=True)
            return os.fsdecode(result.stdout).strip()

        with tempfile.TemporaryDirectory(prefix="native-census-exit-mutant-", dir=ROOT / ".artifacts/tmp") as temporary, \
                patch.object(observer.sampler.NativeProcesses, "command", unchecked_command), \
                self.assertRaisesRegex(RuntimeError, "observed fixture rejected: identity changed during inspection"):
            self.check_native_chain(Path(temporary), "legacy", exit_during_command=True)

    def check_native_chain(self, root, family, *, exit_during_command=False):
        workspace = root / ".artifacts/tmp/process-supervisor-tests/native-held"
        workspace.mkdir(parents=True)
        (root / "t").mkdir()
        prefix = r'''
use strict;
use warnings;
use Cwd qw(getcwd);
use JSON::PP qw(encode_json);
alarm 12;
my $workspace = getcwd() . '/.artifacts/tmp/process-supervisor-tests/native-held';
sub identity {
    my ($name) = @_;
    open my $out, '>', "$workspace/$name.next" or die $!;
    print {$out} encode_json({pid => $$, ppid => getppid()}) or die $!;
    close $out or die $!;
    rename "$workspace/$name.next", "$workspace/$name.json" or die $!;
}
'''
        if family == "rust":
            wrapper, producer = workspace / "rust-tool-resolution", workspace / "rust-tools/rustup"
            producer.parent.mkdir()
            wrapper_argv = "'/usr/bin/perl', '-Iperl', '-It/lib', \"$workspace/rust-tool-resolution\", \"$workspace/rust-tools\""
            producer_argv = "'/usr/bin/perl', \"$workspace/rust-tools/rustup\", 'which', 'cargo'"
        else:
            wrapper, producer = workspace / "legacy-ram-capture", workspace / "legacy-ram-streams"
            wrapper_argv = "'/usr/bin/perl', \"$workspace/legacy-ram-capture\", $workspace, \"$workspace/legacy-ram-streams\""
            producer_argv = ("'/usr/bin/perl', \"$workspace/legacy-ram-streams\", '--host-max-pct', '88', "
                             "'--process-max-rss-mb', '4096', '--poll-seconds', '0.02', "
                             "'--grace-seconds', '0', '--', 'unused'")

        def parent_body(name, argv):
            hold_reap = (r'''
while (!-f "$workspace/reap") { select undef, undef, undef, 0.01; }
''' if name == "wrapper" and exit_during_command else "")
            return prefix + "identity('" + name + "');\n" + r'''
my $child = fork();
die 'fork failed' unless defined $child;
if (!$child) {
''' + "    exec " + argv + ";\n    die 'exec failed';\n}\n" + hold_reap + r'''
waitpid($child, 0) == $child or die 'wait failed';
exit($? == 0 ? 0 : 1);
'''

        original_source = parent_body("original", wrapper_argv)
        wrapper_source = parent_body("wrapper", producer_argv)
        producer_source = prefix
        if family == "legacy":
            producer_source += r'''
open my $marker, '>', "$workspace/legacy-ram-streams-progress" or die $!;
print {$marker} "entered\n" or die $!;
close $marker or die $!;
'''
        producer_source += "identity('producer');\nwhile (!-f \"$workspace/release\") { select undef, undef, undef, 0.01; }\n"
        (root / "t/1669-task-acceptance-fixture-runtime.t").write_text(original_source)
        wrapper.write_text(wrapper_source)
        producer.write_text(producer_source)
        native = observer.Processes()
        evidence = observer.Evidence(root)
        process = None
        census = None
        try:
            process = subprocess.Popen(["/usr/bin/perl", "t/1669-task-acceptance-fixture-runtime.t"],
                                       cwd=root, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                       stderr=subprocess.PIPE, start_new_session=True)
            original_identity = native.identity(process.pid)
            deadline = time.monotonic() + 5
            while not (workspace / "producer.json").exists():
                if time.monotonic() >= deadline:
                    self.fail("actual held producer did not publish its independent identity")
                time.sleep(0.01)
            reported = {name: json.loads((workspace / (name + ".json")).read_text())
                        for name in ("original", "wrapper", "producer")}
            self.assertEqual(reported["original"]["pid"], process.pid)
            self.assertEqual(reported["wrapper"]["ppid"], process.pid)
            self.assertEqual(reported["producer"]["ppid"], reported["wrapper"]["pid"])
            with patch.object(observer, "CaptureSession", side_effect=AssertionError("helper requested")), \
                    patch.object(observer.sampler, "capture", side_effect=AssertionError("capture requested")), \
                    patch.object(observer.os, "kill", side_effect=AssertionError("fixture signalled")):
                census = observer.FixtureCensus(original_identity, native, evidence, root)
                entries = census.scan()
                census.require_coverage()
                self.assertEqual({entry["evidence"]["child"]["pid"] for entry in entries},
                                 {reported["wrapper"]["pid"], reported["producer"]["pid"]})
                target = next(entry for entry in entries if entry["evidence"]["child"]["pid"] == reported["producer"]["pid"])
                self.assertEqual(target["evidence"]["parent"]["pid"], reported["wrapper"]["pid"])
                self.assertEqual(target["evidence"]["ancestor"], original_identity)
                self.assertEqual(target["evidence"]["fixture_sha256"], hashlib.sha256(producer_source.encode()).hexdigest())
                self.assertEqual(target["progress"], "entered" if family == "legacy" else "unknown")
                self.assertEqual({path.read_bytes() for path in evidence.directory.glob("*.source")},
                                 {wrapper_source.encode(), producer_source.encode()})
                if exit_during_command:
                    command = native.command
                    producer_pid = reported["producer"]["pid"]
                    queries = []

                    def exit_before_final_command(pid):
                        if pid == producer_pid:
                            queries.append(pid)
                            if len(queries) == 2:
                                # All initial identity/executable/command reads
                                # and the final executable read saw the held
                                # producer. Exit only before the final ps query.
                                (workspace / "release").write_text("exit\n")
                                deadline = time.monotonic() + 2
                                while True:
                                    try:
                                        native.identity(pid)
                                    except ProcessLookupError:
                                        break
                                    if time.monotonic() >= deadline:
                                        self.fail("released producer did not exit within the control bound")
                                    time.sleep(0.01)
                                snapshot = subprocess.check_output(
                                    ["/bin/ps", "-p", str(pid), "-o", "stat=,command="], timeout=2)
                                self.assertRegex(snapshot, rb"^Z\S*\s+<defunct>\s*$")
                        return command(pid)

                    with patch.object(native, "command", side_effect=exit_before_final_command):
                        self.assertEqual(census.scan(), [], "native disappearance cannot become identity corruption")
                    self.assertEqual(queries, [producer_pid, producer_pid])
                    self.assertEqual(len(census.seen), 2, "prior admitted cleanup ownership remains intact")
                    (workspace / "reap").write_text("reap\n")
                else:
                    producer.write_text(producer_source + "# changed after native admission\n")
                    with self.assertRaisesRegex(RuntimeError, "changed for an observed native birth"):
                        census.scan()
                self.assertEqual({path.read_bytes() for path in evidence.directory.glob("*.source")},
                                 {wrapper_source.encode(), producer_source.encode()})
                if not exit_during_command:
                    with patch.object(observer, "SETTLE_SECONDS", 0.02):
                        with self.assertRaisesRegex(RuntimeError, "observed fixture cleanup"):
                            census.settle()
                    self.assertEqual(len(census.survivors()), 2, "passive settlement must not signal live fixtures")
                (workspace / "release").write_text("release\n")
                stderr = process.communicate(timeout=5)[1]
                self.assertEqual((process.returncode, stderr), (0, b""))
                self.assertTrue(census.settle()["observed_fixtures_gone"])
            for name in ("original", "wrapper", "producer"):
                with self.assertRaises(ProcessLookupError):
                    native.identity(reported[name]["pid"])
        finally:
            (workspace / "release").write_text("release\n")
            (workspace / "reap").write_text("reap\n")
            if process is not None and process.returncode is None:
                # The control alone creates and owns this session/group. Keep
                # its leader unreaped until any necessary group signal. This
                # reserves the PID even if native identity admission failed.
                try:
                    if os.getpgid(process.pid) != process.pid:
                        raise RuntimeError("native control group identity changed before cleanup")
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait(timeout=2)
            if process is not None and process.stderr is not None:
                process.stderr.close()
            if census is not None:
                census.settle()
            evidence.stream.close()


if __name__ == "__main__":
    unittest.main()
