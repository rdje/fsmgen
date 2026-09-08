"""Observe actual T1669 fixture generation without executing its subprocesses."""

import json
import os
from pathlib import Path
import re
import resource
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "t/1669-task-acceptance-fixture-runtime.t"

# Compile the real test, run only its Rust subtest, and intercept that subtest's
# supervisor calls. File allocation, writes and symlinks are the real operations.
# Every other subtest is skipped by this control, not executed or qualified.
OBSERVER = r'''
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use JSON::PP;
use Test::More ();

my $root = abs_path('.');
local $FindBin::Bin = File::Spec->catdir($root, 't');
my $selected = 'Rust parity rejects unresolved and misleading tool identities before building';
my $real_subtest = \&Test::More::subtest;
my (@observed, $selected_calls);

sub source_snapshot {
    my ($path) = @_;
    return undef unless -e $path;
    open my $handle, '<:raw', $path or die "cannot read generated source: $!";
    local $/;
    my $bytes = <$handle>;
    close $handle or die "cannot close generated source: $!";
    return unpack('H*', $bytes);
}

{
    no warnings qw(redefine once);
    *Test::More::subtest = sub {
        my ($name, $body) = @_;
        return 1 unless $name eq $selected;
        ++$selected_calls;
        local *main::supervise_process = sub {
            my %args = @_;
            my $mode = (qw(directory proxy_nonzero proxy_decoy))[scalar @observed];
            die "unexpected extra supervisor call" unless defined $mode;
            my ($wrapper, $bin) = @{$args{argv}}[3, 4];
            my $proxy = File::Spec->catfile($bin, 'rustup');
            my $cargo = File::Spec->catfile($bin, 'cargo');
            push @observed, {
                mode => $mode,
                wrapper => File::Spec->abs2rel($wrapper, $root),
                proxy => File::Spec->abs2rel($proxy, $root),
                wrapper_at_launch => source_snapshot($wrapper),
                proxy_at_launch => source_snapshot($proxy),
                cargo_kind => -l $cargo ? 'symlink' : -d $cargo ? 'directory' : 'other',
                cargo_target => -l $cargo ? File::Spec->abs2rel(abs_path($cargo), $root) : undef,
                argv_prefix => [@{$args{argv}}[0, 1, 2]],
                bounds => $args{bounds},
            };
            # Model only the supervisor's returned status; no fixture executes.
            my $adapter = {
                ok => JSON::PP::false,
                status => $mode eq 'proxy_nonzero' ? 'nonzero_exit' : 'invocation_error',
                failure_stage => $mode eq 'proxy_decoy' ? 'tool_admission' : 'tool_resolution',
                stages => [],
            };
            return { ok => JSON::PP::true, stdout => JSON::PP->new->encode($adapter) };
        };
        return $real_subtest->($name, $body);
    };
}

my $loaded = do $ARGV[0];
die "cannot load actual fixture source: $@ $!" unless $loaded;
die "selected subtest was not called once" unless ($selected_calls // 0) == 1;
for my $row (@observed) {
    $row->{wrapper_after_modes} = source_snapshot(File::Spec->catfile($root, $row->{wrapper}));
    $row->{proxy_after_modes} = source_snapshot(File::Spec->catfile($root, $row->{proxy}));
}
print "FIXTURE_SOURCE_IDENTITIES: ", JSON::PP->new->ascii->canonical->encode(\@observed), "\n";
'''


class RustFixtureSources(unittest.TestCase):
    def observe(self, source):
        with tempfile.TemporaryDirectory(prefix="fixture-source-controls-",
                                         dir=ROOT / ".artifacts/tmp") as directory:
            path = Path(directory) / "source.t"
            path.write_text(source)
            environment = os.environ.copy()
            environment.update({key: directory for key in ("TMPDIR", "TMP", "TEMP")})
            stdout_path, stderr_path = Path(directory) / "stdout", Path(directory) / "stderr"

            def limit_output():
                resource.setrlimit(resource.RLIMIT_FSIZE, (1048576, 1048576))

            with stdout_path.open("xb") as stdout, stderr_path.open("xb") as stderr:
                result = subprocess.run(
                    ["/usr/bin/perl", "-Iperl", "-It/lib", "-e", OBSERVER, str(path)],
                    cwd=ROOT, env=environment, stdin=subprocess.DEVNULL,
                    stdout=stdout, stderr=stderr, timeout=10, preexec_fn=limit_output)
            self.assertLess(stdout_path.stat().st_size, 1048576)
            self.assertLess(stderr_path.stat().st_size, 1048576)
            output, error = stdout_path.read_bytes(), stderr_path.read_bytes()
        self.assertEqual(result.returncode, 0, error.decode(errors="replace"))
        self.assertIn(b"ok 1 - Rust parity rejects unresolved", output)
        records = [line.removeprefix(b"FIXTURE_SOURCE_IDENTITIES: ")
                   for line in output.splitlines()
                   if line.startswith(b"FIXTURE_SOURCE_IDENTITIES: ")]
        self.assertEqual(len(records), 1)
        rows = json.loads(records[0])
        self.assertEqual([row["mode"] for row in rows],
                         ["directory", "proxy_nonzero", "proxy_decoy"])
        for row in rows:
            # The real allocator must remove its exact owned files on Perl exit.
            self.assertFalse((ROOT / row["wrapper"]).exists())
            self.assertFalse((ROOT / row["proxy"]).exists())
            self.assertFalse((ROOT / row["wrapper"]).parent.exists(),
                             "recorded fixture workspace must be removed, even if empty")
        return rows

    def assert_distinct_sources(self, rows):
        self.assertEqual(len({row["wrapper"] for row in rows}), len(rows))
        self.assertEqual(len({row["proxy"] for row in rows}), len(rows))
        wrappers = {row["wrapper_at_launch"] for row in rows}
        self.assertEqual(len(wrappers), 1, "wrapper bytes must remain identical")
        for row in rows:
            self.assertEqual(row["wrapper_at_launch"], row["wrapper_after_modes"])
            self.assertEqual(row["proxy_at_launch"], row["proxy_after_modes"])
            self.assertEqual(row["argv_prefix"], [str(Path("/usr/bin/perl").resolve()), "-Iperl", "-It/lib"])
            self.assertEqual(row["bounds"], {"timeout_seconds": 20, "capture_limit_bytes": 65536})
            self.assertTrue(row["wrapper"].startswith(".artifacts/tmp/process-supervisor-tests/"))
            self.assertEqual(Path(row["proxy"]).name, "rustup")
        self.assertEqual(rows[0]["cargo_kind"], "directory")
        self.assertIsNone(rows[0]["proxy_at_launch"])
        for row in rows[1:]:
            self.assertEqual(row["cargo_kind"], "symlink")
            self.assertEqual(row["cargo_target"], row["proxy"])
        self.assertNotEqual(rows[1]["proxy_at_launch"], rows[2]["proxy_at_launch"])

    def test_each_actual_rust_mode_keeps_its_own_source_identity(self):
        self.assert_distinct_sources(self.observe(SOURCE.read_text()))

    def test_reusing_the_outer_workspace_is_rejected(self):
        source, replacements = re.subn(
            r"my \$mode_workspace = create_project_tempdir\(\s*"
            r"purpose => 'process-supervisor-tests',\s*\);",
            "my $mode_workspace = $workspace;", SOURCE.read_text())
        self.assertEqual(replacements, 1, "the allocation control must alter one actual call")
        # The predecessor initialized Cargo once outside its loop. Let the
        # shared-workspace control reach source rewriting on later iterations.
        setup = "make_path(File::Spec->catdir($bin, 'cargo'));"
        self.assertEqual(source.count(setup), 1)
        source = source.replace(setup, "make_path(File::Spec->catdir($bin, 'cargo')) "
                                "unless -e File::Spec->catfile($bin, 'cargo');")
        rows = self.observe(source)
        self.assertNotEqual(rows[1]["proxy_at_launch"], rows[1]["proxy_after_modes"])
        with self.assertRaises(AssertionError):
            self.assert_distinct_sources(rows)


if __name__ == "__main__":
    unittest.main()
