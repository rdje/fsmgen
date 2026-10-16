#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Path qw(remove_tree);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;

use lib 'perl', 't/lib';
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);

my $root = repository_root();
my $parent = ensure_project_artifact_dir(qw(tmp hdl-behavior-policy-tests));
my $work = File::Temp::tempdir('fixture-XXXXXXXX', DIR => $parent, CLEANUP => 0);
my $perl = abs_path($^X) or die 'current Perl is unavailable';
my $retire = 1;
my $control = "$work/control";
my $trace = "$work/launches";
my $body = <<'PROGRAM';
use strict;
use warnings;
use Cwd qw(getcwd);
use JSON::PP ();
$| = 1;
open my $in, '<', $ENV{FSMGEN_HDL_POLICY_CONTROL} or die $!;
chomp(my $mode = <$in>);
close $in or die $!;
open my $trace, '>>', $ENV{FSMGEN_HDL_POLICY_TRACE} or die $!;
print {$trace} "$$\n" or die $!;
close $trace or die $!;
print JSON::PP->new->canonical->encode({argv => \@ARGV, cwd => getcwd(),
    temporary => $ENV{TMPDIR}}), "\n";
if ($mode eq 'nonzero') { print STDERR "HDL_POLICY_NATIVE_NONZERO\n"; exit 7; }
if ($mode eq 'signal') { kill 'KILL', $$; die 'signal did not terminate'; }
if ($mode eq 'overflow') { print 'x' x 1_048_577; sleep 2; exit 0; }
if ($mode eq 'timeout') {
    $SIG{TERM} = 'IGNORE';
    my $child = fork;
    die 'fixture fork failed' unless defined $child;
    if (!$child) { sleep 120; exit 99; }
    print "DESCENDANT_PID=$child\n";
    sleep 1 while 1;
}
exit 0;
PROGRAM
for my $tool (qw(ghdl verilator)) {
    write_file("$work/$tool", "#!$perl\n" . $body);
    chmod 0755, "$work/$tool" or die $!;
}
write_file($control, "success\n");
write_file($trace, '');
write_file("$work/dut.vhd", "-- fake-provider input; no HDL claim\n");
write_file("$work/dut.sv", "// fake-provider input; no HDL claim\n");
write_file("$work/not-hdl.txt", "boundary control\n");
symlink "$work/dut.vhd", "$work/linked.vhd" or die $!;
mkdir "$work/nested-metadata" or die $!;
write_file("$work/nested-metadata/dut.vhd", "-- metadata-admission fixture\n");
# An invalid marker fixture only: no Git repository is created or operated on.
write_file("$work/nested-metadata/.git", "gitdir: not-a-real-repository\n");

local $ENV{PATH} = $work . ':' . ($ENV{PATH} // '');
local $ENV{FSMGEN_RESET_GHDL} = "$work/ghdl";
local $ENV{FSMGEN_HDL_POLICY_CONTROL} = $control;
local $ENV{FSMGEN_HDL_POLICY_TRACE} = $trace;
require FSM::Test::HDLBehaviorRuntime;

sub analysis { return FSM::Test::HDLBehaviorRuntime::run_ghdl_analysis(@_); }
sub behavior { return FSM::Test::HDLBehaviorRuntime::run_ghdl_behavior(@_); }
sub lint { return FSM::Test::HDLBehaviorRuntime::run_storage_identifier_lint(@_); }

sub native {
    my ($result) = @_;
    diag('HDL policy native result: ' . JSON::PP->new->canonical->encode($result));
    is($result->{timeout_seconds}, 60, 'original wall is sealed');
    is($result->{capture_limit_bytes}, 1_048_576, 'original capture is sealed');
    is($result->{cleanup}{containment}, 'test_runtime_process_group', 'original containment retains');
    my $settled = $result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone};
    ok($settled, 'native leader and process group settle');
    $retire = 0 unless $settled;
    return $result;
}

sub observed_arguments {
    my ($result) = @_;
    my ($line) = split /\n/, $result->{stdout};
    return JSON::PP->new->decode($line);
}

subtest 'invalid API and foreign paths never reach the supervisor' => sub {
    no warnings qw(redefine once);
    my $launched = 0;
    local *FSM::Test::HDLBehaviorRuntime::supervise_process = sub {
        ++$launched;
        die 'invalid input reached process creation';
    };
    for my $result (
        analysis('unknown', $work, ["$work/dut.vhd"]),
        analysis({}, $work, ["$work/dut.vhd"]),
        analysis('reset_behavior', $root, ["$work/dut.vhd"]),
        analysis('reset_behavior', "$root/.artifacts/cache", ["$work/dut.vhd"]),
        analysis('reset_behavior', "$work/nested-metadata", ["$work/nested-metadata/dut.vhd"]),
        analysis('reset_behavior', $work, ["$work/nested-metadata/dut.vhd"]),
        analysis('reset_behavior', $work, ["$work/linked.vhd"]),
        analysis('reset_behavior', $work, ["$work/../dut.vhd"]),
        analysis('reset_behavior', $work, ["$work/not-hdl.txt"]),
        analysis('reset_behavior', $work, ['README.md']),
        analysis('reset_behavior', $work, []),
        analysis('reset_behavior', $work, [map { "$work/dut.vhd" } 1 .. 129]),
        analysis('reset_behavior', $work, ["$work/dut.vhd"], {timeout_seconds => 999}),
        behavior('storage_identifier', $work),
        behavior('reset_behavior', $work, '--stop-time=999s'),
        lint($work, "$work/dut.sv", "$root/obj"),
        lint($work, "$work/dut.sv", "$work/not-hdl.txt"),
        lint($work, "$work/dut.sv", "$work/nested-metadata/obj"),
        lint($work, "$work/dut.sv", "$work/obj", ['sh', '-c', 'true']),
    ) {
        is($result->{status}, 'invocation_error', 'invalid request is refused');
        ok(!$result->{ok}, 'refusal is not success');
        ok(!defined($result->{exec_handoff_monotonic_ns}), 'refusal observes no exec handoff');
    }
    is($launched, 0, 'no rejected request starts a child');
};

subtest 'native argv preserves every committed GHDL caller contract' => sub {
    # These values come from the original caller sources, not the adapter table.
    # The fake provider observes commands; it does not validate or simulate HDL.
    my %expected = (
        reset_behavior => ['reset_tb', '100ns'],
        reset_only => ['reset_only_tb', '100ns'],
        internal_role => ['internal_role_tb', '100ns'],
        storage_ownership => ['storage_tb', '300ns'],
        child_storage_reads => ['read_tb', '1000ns'],
        dynamic_count => ['count_tb', '10000ns'],
        unsigned_comparison => ['comparison_tb', '100ns'],
        extract_runtime => ['extract_tb', '100000ns'],
        storage_identifier => [],
    );
    for my $profile (sort keys %expected) {
        my $result = native(analysis($profile, $work, ["$work/dut.vhd"]));
        ok($result->{ok}, "$profile analysis succeeds once") or diag($result->{diagnostic});
        is($result->{schema}, "fsmgen.test.$profile.v1", 'original schema retains');
        is($result->{stage}, 'ghdl', 'original stage retains');
        my @expected = ('-a', '--std=08');
        push @expected, '--workdir=' . $work unless $profile eq 'storage_identifier';
        push @expected, "$work/dut.vhd";
        my $child = observed_arguments($result);
        is_deeply($child->{argv}, \@expected, "$profile native analysis arguments retain");
        is($child->{cwd}, $work, 'GHDL uses the fixture cwd');
        is($child->{temporary}, $work, 'child scratch remains in the fixture');
        next unless @{$expected{$profile}};
        my ($top, $stop) = @{$expected{$profile}};
        $result = native(behavior($profile, $work));
        ok($result->{ok}, "$profile runtime succeeds once");
        is_deeply(observed_arguments($result)->{argv}, [
            '--elab-run', '--std=08', '--workdir=' . $work,
            $top, '--assert-level=error', '--stop-time=' . $stop,
        ], "$profile native runtime arguments retain");
    }
};

subtest 'storage-name lint preserves its fixed public command and root cwd' => sub {
    my $result = native(lint($work, "$work/dut.sv", "$work/obj"));
    ok($result->{ok}, 'native lint fixture succeeds');
    is($result->{schema}, 'fsmgen.test.storage_identifier.v1', 'original lint schema retains');
    is($result->{stage}, 'verilator_lint', 'original lint stage retains');
    my $child = observed_arguments($result);
    is_deeply($child->{argv}, ['--lint-only', '-Wno-fatal', '--top-module',
        'storage_identifier', '--Mdir', "$work/obj", "$work/dut.sv"], 'native lint arguments retain');
    is($child->{cwd}, $root, 'lint retains the repository cwd');
    is($child->{temporary}, $work, 'lint scratch is fixture-local');
};

subtest 'selected tools and child environment resist caller redirects' => sub {
    write_file("$work/startup", "exit 93\n");
    local $ENV{FSMGEN_RESET_GHDL} = "$work/not-a-tool";
    local $ENV{PATH} = "$work/not-tools";
    local $ENV{BASH_ENV} = "$work/startup";
    local $ENV{PERL5OPT} = '-MThisModuleMustNotLoad';
    my %before = %ENV;
    is(FSM::Test::HDLBehaviorRuntime::ghdl_behavior_provider('reset_behavior'),
        "$work/ghdl", 'GHDL selection is frozen');
    my $ghdl = native(analysis('reset_behavior', $work, ["$work/dut.vhd"]));
    ok($ghdl->{ok}, 'canonical GHDL fixture ignores later tool/startup redirects');
    my $verilator = native(lint($work, "$work/dut.sv", "$work/obj"));
    ok($verilator->{ok}, 'canonical lint fixture ignores later tool/startup redirects');
    is_deeply(\%ENV, \%before, 'caller environment remains exact');
};

subtest 'native nonzero exit is preserved without retry' => sub {
    write_file($control, "nonzero\n");
    my $before = launches();
    my $result = native(analysis('reset_behavior', $work, ["$work/dut.vhd"]));
    is($result->{status}, 'nonzero_exit', 'native exit is classified accurately');
    is($result->{exit_code}, 7, 'native exit value retains');
    ok(!$result->{ok}, 'completion does not promote failure');
    like($result->{stderr}, qr/HDL_POLICY_NATIVE_NONZERO/, 'native stderr retains');
    is(launches(), $before + 1, 'exactly one native attempt');
};

subtest 'native signal is preserved without retry' => sub {
    write_file($control, "signal\n");
    my $before = launches();
    my $result = native(analysis('reset_behavior', $work, ["$work/dut.vhd"]));
    is($result->{status}, 'signaled', 'signal remains a native failure');
    is($result->{signal}, 9, 'actual signal retains');
    ok(!$result->{ok}, 'signal cannot become success');
    is(launches(), $before + 1, 'signal is not retried');
};

subtest 'real aggregate overflow fails at the sealed capture ceiling' => sub {
    write_file($control, "overflow\n");
    my $before = launches();
    my $result = native(analysis('reset_behavior', $work, ["$work/dut.vhd"]));
    is($result->{status}, 'output_limited', 'native overflow remains failed');
    ok($result->{output_limited} && !$result->{ok}, 'overflow evidence is explicit');
    cmp_ok(length($result->{stdout}) + length($result->{stderr}), '<=', 1_048_576,
        'aggregate stored capture stays bounded');
    is(launches(), $before + 1, 'overflow is not retried');
};

subtest 'real deadline kills a TERM-resistant leader and descendant' => sub {
    write_file($control, "timeout\n");
    my $before = launches();
    my $result = native(behavior('reset_behavior', $work));
    is($result->{status}, 'timed_out', 'sealed deadline remains failed');
    ok($result->{timed_out} && !$result->{ok}, 'timeout cannot become success');
    like($result->{stdout}, qr/DESCENDANT_PID=\d+/, 'actual resistant descendant entered');
    is(launches(), $before + 1, 'deadline is not retried');
};

done_testing();
if ($retire) {
    remove_tree($work);
    die 'settled fixture was not retired' if -e $work;
} else {
    diag('Unsettled native fixture retained at ' . File::Spec->abs2rel($work, $root));
}

sub write_file {
    my ($path, $text) = @_;
    open my $stream, '>:raw', $path or die $!;
    print {$stream} $text or die $!;
    close $stream or die $!;
}

sub launches {
    open my $stream, '<', $trace or die $!;
    my @lines = <$stream>;
    close $stream or die $!;
    return scalar @lines;
}
