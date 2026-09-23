#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::fork = sub { die 'receipt observation must not fork'; };
    *CORE::GLOBAL::system = sub { die 'receipt observation must not spawn'; };
    *CORE::GLOBAL::kill = sub { die 'receipt observation must not signal'; };
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

done_testing;
