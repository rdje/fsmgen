"""Observe actual T1669 fixture generation without executing its subprocesses."""

import json
import os
from pathlib import Path
import resource
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "t/1669-task-acceptance-fixture-runtime.t"

# Compile the real test, run only its Rust subtest, and intercept that subtest's
# supervisor calls. Allocation, portable preparation and retirement are real.
# Every other subtest is skipped by this control, not executed or qualified.
OBSERVER = r'''
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path ();
use File::Spec;
use FindBin;
use JSON::PP;
use Test::More ();

my $root = abs_path('.');
local $FindBin::Bin = File::Spec->catdir($root, 't');
my $selected = 'Rust parity rejects unresolved and misleading tool identities before building';
my $real_subtest = \&Test::More::subtest;
my (@observed, @allocated, @preparations, $selected_calls);
my $compiler_attempts = 0;
die "expected source and fixed observation mode" unless @ARGV == 2
    && ($ARGV[1] eq 'clean' || $ARGV[1] eq 'mutate_proxy' || $ARGV[1] eq 'empty_stages');

END {
    # All fixture runtime calls are inert and compilation is trapped. Retire
    # only this control's exact allocator identities if an assertion aborts it.
    for my $owned (@allocated) {
        my ($path, $device, $inode) = @$owned;
        next unless -e $path || -l $path;
        my @current = lstat($path);
        die "controlled allocator identity changed" unless @current && -d _ && !-l _
            && $current[0] == $device && $current[1] == $inode && $current[4] == $<;
        my $errors;
        File::Path::remove_tree($path, {error => \$errors});
        die "controlled workspace cleanup failed" if @$errors || -e $path || -l $path;
    }
}

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
        my $allocate = \&File::Temp::newdir;
        local *File::Temp::newdir = sub {
            my $directory = $allocate->(@_);
            my $path = "$directory";
            die "unexpected allocator parent" unless dirname($path)
                eq File::Spec->catdir($root, qw(.artifacts tmp process-supervisor-tests));
            my @metadata = stat($path);
            push @allocated, [$path, @metadata[0, 1]];
            return $directory;
        };
        # Source lifetime does not require native execution. Exercise the real
        # portable builder and fail before any accidental compiler invocation.
        local *FSM::Test::RustProxyFixture::_selection = sub {
            return {implementation => 'perl', reason => 'controlled_source_observation'};
        };
        local *FSM::Test::RustProxyFixture::supervise_process = sub {
            ++$compiler_attempts;
            die "compiler invocation forbidden in source control";
        };
        my $prepare = \&main::prepare_rust_proxy;
        local *main::prepare_rust_proxy = sub {
            my $result = $prepare->(@_);
            push @preparations, {mode => $_[1], result => $result};
            return $result;
        };
        my $retire = \&main::retire_rust_proxy_workspace;
        local *main::retire_rust_proxy_workspace = sub {
            my ($directory) = @_;
            my $row = $observed[-1];
            die "retirement does not match observed mode" unless $row
                && dirname(File::Spec->catfile($root, $row->{wrapper})) eq "$directory";
            my $wrapper = File::Spec->catfile($root, $row->{wrapper});
            my $proxy = File::Spec->catfile($root, $row->{proxy});
            if ($ARGV[1] eq 'mutate_proxy' && $row->{mode} eq 'proxy_nonzero') {
                chmod 0600, $proxy or die "cannot open controlled mutation: $!";
                open my $changed, '>>:raw', $proxy or die "cannot mutate controlled source: $!";
                print {$changed} "\n# controlled after-launch change\n" or die $!;
                close $changed or die $!;
                chmod 0500, $proxy or die $!;
            }
            $row->{wrapper_before_retirement} = source_snapshot($wrapper);
            $row->{proxy_before_retirement} = source_snapshot($proxy);
            ++$row->{retirements};
            my $result = $retire->(@_);
            $row->{absent_after_retirement} = !-e $directory && !-l $directory
                ? JSON::PP::true : JSON::PP::false;
            return $result;
        };
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
                stages => [{stage => 'tool_resolution', cleanup => {
                    leader_started => 0, leader_reaped => 0, group_gone => 1,
                }}],
            };
            $adapter->{stages} = [] if $ARGV[1] eq 'empty_stages';
            return {ok => JSON::PP::true, stdout => JSON::PP->new->encode($adapter),
                    cleanup => {leader_started => 0, leader_reaped => 0, group_gone => 1}};
        };
        return $real_subtest->($name, $body);
    };
}

my $loaded = do $ARGV[0];
die "cannot load actual fixture source: $@ $!" unless $loaded;
die "selected subtest was not called once" unless ($selected_calls // 0) == 1;
print "FIXTURE_SOURCE_IDENTITIES: ", JSON::PP->new->ascii->canonical->encode({
    modes => \@observed, preparations => \@preparations, compiler_attempts => $compiler_attempts,
}), "\n";
'''


class RustFixtureSources(unittest.TestCase):
    def observe(self, source, *, mutate_proxy=False, fail_stage_history=False):
        self.assertFalse(mutate_proxy and fail_stage_history)
        mode = "empty_stages" if fail_stage_history else "mutate_proxy" if mutate_proxy else "clean"
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
                    ["/usr/bin/perl", "-Iperl", "-It/lib", "-e", OBSERVER, str(path),
                     mode],
                    cwd=ROOT, env=environment, stdin=subprocess.DEVNULL,
                    stdout=stdout, stderr=stderr, timeout=10, preexec_fn=limit_output)
            self.assertLess(stdout_path.stat().st_size, 1048576)
            self.assertLess(stderr_path.stat().st_size, 1048576)
            output, error = stdout_path.read_bytes(), stderr_path.read_bytes()
        self.assertEqual(result.returncode, 1 if fail_stage_history else 0, error.decode(errors="replace"))
        self.assertIn((b"not ok" if fail_stage_history else b"ok") +
                      b" 1 - Rust parity rejects unresolved", output)
        if fail_stage_history:
            self.assertIn(b"directory returns a structured adapter result", error)
            self.assertIn(b"Retained proxy workspace:", error)
        records = [line.removeprefix(b"FIXTURE_SOURCE_IDENTITIES: ")
                   for line in output.splitlines()
                   if line.startswith(b"FIXTURE_SOURCE_IDENTITIES: ")]
        self.assertEqual(len(records), 1)
        observation = json.loads(records[0])
        self.assertEqual(observation["compiler_attempts"], 0)
        preparations = observation["preparations"]
        self.assertEqual([p["mode"] for p in preparations],
                         [] if fail_stage_history else ["proxy_nonzero", "proxy_decoy"])
        for prepared in preparations:
            self.assertEqual(prepared["result"]["implementation"], "perl")
            self.assertTrue(prepared["result"]["ok"])
            self.assertIsNone(prepared["result"]["compilation"])
        rows = observation["modes"]
        self.assertEqual([row["mode"] for row in rows],
                         ["directory"] if fail_stage_history else ["directory", "proxy_nonzero", "proxy_decoy"])
        for row in rows:
            if fail_stage_history:
                self.assertNotIn("retirements", row)
                self.assertNotIn("absent_after_retirement", row)
            else:
                self.assertEqual(row["retirements"], 1)
                self.assertTrue(row["absent_after_retirement"])
            # Real retirement, or the control's own failure cleanup, removes it.
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
            self.assertEqual(row["wrapper_at_launch"], row["wrapper_before_retirement"],
                             "wrapper bytes must stay unchanged until retirement")
            self.assertEqual(row["proxy_at_launch"], row["proxy_before_retirement"],
                             "proxy bytes must stay unchanged until retirement")
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

    def test_proxy_source_change_before_retirement_is_rejected(self):
        rows = self.observe(SOURCE.read_text(), mutate_proxy=True)
        self.assertNotEqual(rows[1]["proxy_at_launch"], rows[1]["proxy_before_retirement"])
        with self.assertRaisesRegex(AssertionError, "proxy bytes must stay unchanged until retirement"):
            self.assert_distinct_sources(rows)

    def test_failed_stage_history_cleans_the_exact_control_workspace(self):
        rows = self.observe(SOURCE.read_text(), fail_stage_history=True)
        self.assertNotIn("wrapper_before_retirement", rows[0])
        self.assertIsNone(rows[0]["proxy_at_launch"])


if __name__ == "__main__":
    unittest.main()
