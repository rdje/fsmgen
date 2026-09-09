"""Independent TAP oracle for the exact T1669 legacy diagnostic block.

Supervisor results are explicitly modeled here; the extracted block still
writes its real generated sources and reads actual marker files. The native
producer control separately executes those sources without the broken reader.
"""

import copy
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "t/1669-task-acceptance-fixture-runtime.t"


class LegacyFailureRetention(unittest.TestCase):
    def exercise(self, markers, *, suppress=False, execute_producers=False):
        source = SOURCE.read_text()
        start = source.index("subtest 'legacy RAM-guard capture controls")
        end = source.index("\nsubtest ", start + 1)
        block = source[start:end]
        helpers = source[source.index("sub write_executable {"):]
        result = dict(schema="fsmgen.test.legacy_ram_capture_probe.v1", schema_version=1,
                      stage="legacy_capture", ok=0, status="timed_out", exit_code=None,
                      signal=15, timed_out=1, output_limited=0, exec_failed=0, exec_error=None,
                      diagnostic="independent modeled result", timeout_seconds=5,
                      capture_limit_bytes=65536, stdout="\x00\xff", stderr="err",
                      stdout_bytes=2, stderr_bytes=3, started_monotonic_ns=1000,
                      exec_handoff_monotonic_ns=1100, first_output_monotonic_ns=1200,
                      finished_monotonic_ns=2000, spawn_to_exec_ns=100,
                      exec_to_first_output_ns=100, first_output_to_exit_ns=800,
                      execution_ns=900, cleanup=dict(containment="legacy_ram_capture_probe_group",
                      leader_started=1, leader_reaped=1, group_gone=1, surviving_descendants=0,
                      term_sent=1, kill_sent=0))
        signal_result = copy.deepcopy(result)
        signal_stdout = json.dumps(dict(native_wait_status=15, projected_exit=0,
                                       stdout="signal-body-entered\n", stderr=""))
        signal_result.update(ok=1, status="success", timed_out=0, signal=0, exit_code=0,
                             stdout=signal_stdout, stdout_bytes=len(signal_stdout),
                             stderr="", stderr_bytes=0)
        signal_result["cleanup"]["term_sent"] = 0
        models = {"signal": signal_result, "streams": result}
        program = r'''
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP qw(decode_json);
use Test::More;
my $repo_root = abs_path('.');
my $perl = abs_path($^X);
my $workspace = File::Spec->rel2abs(shift @ARGV);
my $models = decode_json(slurp("$workspace/models.json"));
my $markers = decode_json(slurp("$workspace/markers.json"));
sub supervise_process {
    my %args = @_;
    my ($mode) = $args{argv}[-1] =~ /legacy-ram-(signal|streams)$/;
    die 'unexpected modeled fixture' unless defined $mode;
    if (defined $markers->{$mode}) {
        open my $marker, '>:raw', "$args{argv}[-1]-progress" or die $!;
        print {$marker} $markers->{$mode} or die $!;
        close $marker or die $!;
    }
    return $models->{$mode};
}
'''
        if suppress:
            program += "no warnings 'redefine'; *main::diag = sub { 1 };\n"
        program += block + r'''
open my $after, '>:raw', "$workspace/after.json" or die $!;
print {$after} JSON::PP->new->ascii->canonical->encode($models) or die $!;
close $after or die $!;
done_testing();
''' + helpers
        with tempfile.TemporaryDirectory(prefix="legacy-retention-", dir=ROOT / ".artifacts/tmp") as temporary:
            workspace = Path(temporary)
            (workspace / "models.json").write_text(json.dumps(models))
            (workspace / "markers.json").write_text(json.dumps(markers))
            completed = subprocess.run(["/usr/bin/perl", "-e", program,
                                        str(workspace.relative_to(ROOT))], cwd=ROOT,
                                       stdin=subprocess.DEVNULL, capture_output=True, timeout=10)
            self.assertEqual(json.loads((workspace / "after.json").read_text()), models,
                             "diagnostic path must not alter the original results")
            diagnostics = [json.loads(line) for line in re.findall(
                rb"^\s*# Legacy main-entry result: (.+)$", completed.stderr, re.MULTILINE)]
            expected = {}
            for mode in models:
                producer = workspace / ("legacy-ram-" + mode)
                body = producer.read_bytes()
                expected[mode] = dict(mode=mode, fixture=dict(path=str(producer.relative_to(ROOT)),
                    size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest()),
                    marker=dict(path=str(producer.relative_to(ROOT)) + "-progress",
                                regular_file=int(markers[mode] is not None), content=markers[mode]),
                    result=models[mode])
                if execute_producers:
                    marker = Path(str(producer) + "-progress")
                    marker.unlink(missing_ok=True)
                    native = subprocess.run(["/usr/bin/perl", str(producer)], cwd=ROOT,
                                            stdin=subprocess.DEVNULL, capture_output=True,
                                            timeout=10, start_new_session=True)
                    if mode == "signal":
                        self.assertEqual((native.returncode, native.stdout, native.stderr),
                                         (-15, b"signal-body-entered\n", b""))
                        self.assertEqual(marker.read_bytes(), b"entered\n")
                    else:
                        self.assertEqual((native.returncode, native.stdout, native.stderr),
                                         (0, b"stdout-after-stderr\n", b"x" * 262144))
                        self.assertEqual(marker.read_bytes(), b"entered\ndrained\n")
            return completed, diagnostics, expected

    def assert_retained(self, observed, expected, failed_modes):
        self.assertEqual(observed, [expected[mode] for mode in failed_modes])
        for record in observed:
            self.assertFalse(os.path.isabs(record["fixture"]["path"]))
            self.assertFalse(os.path.isabs(record["marker"]["path"]))

    def test_failed_main_entry_retains_exact_result_even_when_timeout_assertion_passes(self):
        for mode in ("signal", "streams"):
            for marker in (None, "", "partial", "entered\ndrained\n"):
                with self.subTest(mode=mode, marker=marker):
                    markers = dict(signal="entered\n", streams="entered\n")
                    markers[mode] = marker
                    completed, observed, expected = self.exercise(markers)
                    self.assertEqual(completed.returncode, 1)
                    self.assert_retained(observed, expected, [mode])
                    self.assertRegex(completed.stdout, rb"\n    ok [0-9]+ - old sequential reader")
                    failures = re.findall(rb"^    not ok [0-9]+ - (.+)$", completed.stdout, re.MULTILINE)
                    message = ("producer independently records main entry" if marker is None
                               else "progress excludes an assumed completed write")
                    self.assertEqual(failures, [(mode + " " + message).encode()])

    def test_expected_entry_keeps_tap_success_and_generated_producer_bytes(self):
        completed, observed, expected = self.exercise(
            dict(signal="entered\n", streams="entered\n"), execute_producers=True)
        self.assertEqual(completed.returncode, 0, completed.stderr.decode())
        self.assert_retained(observed, expected, [])

    def test_retention_oracle_rejects_suppressed_diagnostics(self):
        completed, observed, expected = self.exercise(
            dict(signal="entered\n", streams=None), suppress=True)
        self.assertEqual(completed.returncode, 1)
        with self.assertRaises(AssertionError):
            self.assert_retained(observed, expected, ["streams"])


if __name__ == "__main__":
    unittest.main()
