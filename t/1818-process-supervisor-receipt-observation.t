#!/usr/bin/env perl
use strict;
use warnings;

my $FORKS = 0;
my $SIGNALS = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { $FORKS++; CORE::fork(); };
    *CORE::GLOBAL::system = sub { die 'receipt observation must not spawn'; };
    *CORE::GLOBAL::kill = sub {
        my ($signal, $pid) = @_;
        $SIGNALS++ if $signal;
        return CORE::kill($signal, $pid);
    };
}

use FindBin;
use File::Spec;
use Scalar::Util qw(refaddr);
use Test::More;
use lib 'perl', 't/lib', File::Spec->catdir(
    $FindBin::Bin, '..', 'docs', 'audits',
    'native-proxy-receipt-adapter-20260922',
);
use FSM::Test::ProcessSupervisor ();
use ReceiptAdapter;

my $observe = \&FSM::Support::ProcessSupervisor::receipt_observation;
my $build = \&FSM::Support::ProcessSupervisor::_receipt_observation;
my $bound = \&NativeProxyReceiptAdapter::receipts_bound;

sub finished_job {
    my ($stage, $pid) = @_;
    my $cleanup = {
        containment => 'receipt_observation',
        leader_started => 1, term_sent => 0, kill_sent => 0,
        leader_reaped => 1, group_gone => 1, surviving_descendants => 0,
    };
    return {
        phase => 'finished', stage => $stage, pid => $pid,
        birth_sec => 1_700_000_000 + $pid, birth_usec => $pid,
        leader_reaped => 1, cleanup => $cleanup,
    };
}

my @jobs = (
    finished_job('compile_proxy', 11),
    finished_job('probe', 12),
    finished_job('tool_resolution', 13),
);
my @states;
for my $index (0 .. $#jobs) {
    my $job = $jobs[$index];
    my $observation = $observe->('FSM::Test::ProcessSupervisor', $job);
    is($observation->{stage}, $job->{stage}, "stage $index is preserved");
    is($observation->{phase}, 'finished', "stage $index is finished");
    is($observation->{birth}{pid}, $job->{pid}, "stage $index returns its pid");
    is($observation->{birth}{start_sec}, $job->{birth_sec},
        "stage $index returns its birth second");
    is($observation->{birth}{start_usec}, $job->{birth_usec},
        "stage $index returns its birth microsecond");
    is_deeply($observation->{group}, $observation->{birth},
        "stage $index group equals its leader birth");
    is(refaddr($observation->{cleanup}), $observation->{cleanup_identity},
        "stage $index keeps the original cleanup identity");
    is(refaddr($observation->{cleanup}), refaddr($job->{cleanup}),
        "stage $index does not copy the cleanup hash");
    push @states, {
        role => (qw(compiler outer inner))[$index],
        birth => $observation->{birth},
        group => $observation->{group},
        stage => $observation->{stage},
        phase => $observation->{phase},
        leader_reaped => $observation->{leader_reaped},
        cleanup => $observation->{cleanup},
        cleanup_identity => $observation->{cleanup_identity},
    };
}
ok($bound->(\@states, {closed => 1}),
    'sealed observations satisfy the aligned receipt review');

my $copied = $build->($jobs[0]);
$copied->{cleanup} = {%{$copied->{cleanup}}};
ok(!$bound->([{
    role => 'compiler', birth => $copied->{birth}, group => $copied->{group},
    stage => $copied->{stage}, phase => $copied->{phase},
    leader_reaped => $copied->{leader_reaped}, cleanup => $copied->{cleanup},
    cleanup_identity => $copied->{cleanup_identity},
}, @states[1, 2]], {closed => 1}), 'a copied cleanup hash still rejects');

my $open = eval { $observe->('FSM::Other', $jobs[0]); 1 };
ok(!$open, 'an unsealed caller cannot observe a receipt');
like("$@", qr/caller-sealed/, 'the rejection names the caller seal');

my $missing = eval { $observe->('FSM::Test::ProcessSupervisor', {phase => 'capture'}); 1 };
ok(!$missing, 'an unfinished job has no receipt observation');
like("$@", qr/finished job/, 'the rejection names the finished job');

my $public = FSM::Support::ProcessSupervisor::_finish_result({
    schema => 'fsmgen.process_supervisor.receipt_observation.v1',
    stage => 'probe', status => 'success', diagnostic => 'probe',
    stdout => '', stderr => '', exec_error => undef, leader_status => 0,
    timed_out => 0, output_limited => 0, exec_failed => 0,
    bounds => {timeout_seconds => 1, capture_limit_bytes => 64},
    started => undef, exec_handoff => undef, first_output => undef,
    finished => undef, cleanup => $jobs[0]{cleanup},
});
ok(!exists $public->{pid}, 'the public result still omits pid');
ok(!exists $public->{cleanup_identity},
    'the public result still omits cleanup identity');
is($public->{schema_version}, 1, 'the public result keeps schema version 1');
is_deeply($public->{cleanup}, $jobs[0]{cleanup},
    'the public result returns the same cleanup flags');
ok(refaddr($public->{cleanup}) != refaddr($jobs[0]{cleanup}),
    'the public result does not share the private cleanup hash');
$public->{cleanup}{leader_reaped} = 0;
is($jobs[0]{cleanup}{leader_reaped}, 1,
    'mutating the public cleanup copy leaves the private hash unchanged');

my $private = FSM::Test::ProcessSupervisor::sealed_finished_job({
    phase => 'finished', stage => 'compile_proxy', pid => 21,
    birth_sec => 1_700_000_021, birth_usec => 21, leader_reaped => 1,
    cleanup => $jobs[0]{cleanup}, result => $public,
});
is(refaddr($private->{cleanup}), refaddr($jobs[0]{cleanup}),
    'the sealed return keeps the original cleanup hash');
is($private->{receipt_observation}{birth}{pid}, 21,
    'the sealed return carries the private pid');
is($private->{receipt_observation}{birth}{start_sec}, 1_700_000_021,
    'the sealed return carries the birth second');
is($private->{receipt_observation}{birth}{start_usec}, 21,
    'the sealed return carries the birth microsecond');
is_deeply($private->{receipt_observation}{group},
    $private->{receipt_observation}{birth},
    'the sealed return group equals its leader birth');
is($private->{result}, $public, 'the sealed return keeps the public result');
ok(!exists $private->{result}{pid},
    'the sealed public result still omits pid');

my $unsealed_return = eval {
    FSM::Support::ProcessSupervisor::sealed_finished_job('FSM::Other', $private);
    1;
};
ok(!$unsealed_return, 'an unsealed caller cannot receive the private job');
like("$@", qr/caller-sealed/, 'the private-return rejection names the caller seal');

my $unfinished_return = eval {
    FSM::Test::ProcessSupervisor::sealed_finished_job({phase => 'capture'});
    1;
};
ok(!$unfinished_return, 'an unfinished job has no private return');
like("$@", qr/finished job/, 'the private-return rejection names the finished job');

my $launch = do {
    package FSM::Test::ProcessSupervisor;
    sealed_supervise_process(
    schema => 'fsmgen.process_supervisor.receipt_observation.v1',
    stage => 'compile_proxy',
    bounds => {timeout_seconds => 1, capture_limit_bytes => 64},
    containment => 'receipt_observation',
    cwd => '.',
    argv => [],
    );
};
is($launch->{phase}, 'finished', 'the sealed launch returns a finished job');
is($launch->{stage}, 'compile_proxy', 'the sealed launch keeps its stage');
is($launch->{result}{status}, 'invocation_error',
    'an empty argument vector fails before a process');
ok(!exists $launch->{result}{pid},
    'the launch public result still omits pid');
is(refaddr($launch->{receipt_observation}{cleanup}),
    refaddr($launch->{cleanup}),
    'the sealed launch keeps the original cleanup hash');
is($launch->{receipt_observation}{birth}{pid}, $launch->{pid},
    'the sealed launch carries the private pid');
is_deeply($launch->{receipt_observation}{group},
    $launch->{receipt_observation}{birth},
    'the sealed launch group equals its leader birth');
ok(!defined $launch->{pid},
    'the pre-fork failure has no process id');

my $public_launch = do {
    package FSM::Test::ProcessSupervisor;
    __PACKAGE__->can('supervise_process')->(
        schema => 'fsmgen.process_supervisor.receipt_observation.v1',
        stage => 'compile_proxy',
        bounds => {timeout_seconds => 1, capture_limit_bytes => 64},
        containment => 'receipt_observation',
        cwd => '.',
        argv => [],
    );
};
ok(!exists $public_launch->{phase},
    'the public launch still returns only the public result');
is($public_launch->{status}, 'invocation_error',
    'the public launch keeps the invocation failure');
ok(!exists $public_launch->{pid},
    'the public launch still omits pid');

my $ready = do {
    package FSM::Test::ProcessSupervisor;
    sealed_supervise_process(
        schema => 'fsmgen.process_supervisor.receipt_observation.v1',
        stage => 'probe',
        bounds => {timeout_seconds => 1, capture_limit_bytes => 64},
        containment => 'receipt_observation',
        cwd => '.',
        argv => ['receipt-observation-missing'],
    );
};
is($ready->{phase}, 'finished',
    'a named missing program returns a finished private job');
is($ready->{stage}, 'probe', 'the ready launch keeps its stage');
is($ready->{result}{status}, 'invocation_error',
    'a missing program fails before a process');
ok(!defined $ready->{pid}, 'the missing program starts no process');
is(refaddr($ready->{receipt_observation}{cleanup}),
    refaddr($ready->{cleanup}),
    'the ready launch keeps the original cleanup hash');
like($ready->{result}{diagnostic}, qr/not executable/,
    'the rejection names the missing program');

is($FORKS, 0, 'the pre-fork cases start no process');
my $held = do {
    package FSM::Test::ProcessSupervisor;
    sealed_supervise_process(
        schema => 'fsmgen.process_supervisor.receipt_observation.v1',
        stage => 'proof_exit',
        bounds => {timeout_seconds => 1, capture_limit_bytes => 64},
        containment => 'receipt_observation',
        cwd => '.',
        argv => [$^X, '-e', 'exit 0'],
    );
};
is($FORKS, 1, 'the proof launch forks once');
is($held->{phase}, 'finished',
    'an executable proof returns a finished private job');
is($held->{stage}, 'proof_exit', 'the proof launch is not a capture stage');
ok($held->{result}{ok}, 'the proof process exits successfully');
ok(!exists $held->{result}{pid}, 'the proof public result still omits pid');
ok(defined($held->{pid}) && $held->{pid} > 0, 'the proof launch records its pid');
is($held->{receipt_observation}{birth}{pid}, $held->{pid},
    'the proof launch carries its private pid');
is_deeply($held->{receipt_observation}{group},
    $held->{receipt_observation}{birth},
    'the proof launch group equals its leader birth');
is(refaddr($held->{receipt_observation}{cleanup}),
    refaddr($held->{cleanup}),
    'the proof launch keeps the original cleanup hash');
is($held->{cleanup}{leader_reaped}, 1, 'the proof leader is reaped');
is($held->{cleanup}{group_gone}, 1, 'the proof group is gone');
is($SIGNALS, 0, 'the proof launch sends no terminating signal');

done_testing;
