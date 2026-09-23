#!/usr/bin/env perl
use strict;
use warnings;

use Errno qw(ECHILD);
use POSIX qw(WNOHANG WUNTRACED WIFSTOPPED WSTOPSIG SIGSTOP _exit);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::ReservedJob ();

my $creator = $$;
my (%births, @signals);
my $group_retired = 0;
sub now { clock_gettime(CLOCK_MONOTONIC) }

# This inventory observes native fork returns independently of engine records.
# Rescue first establishes an exact still-unharvested direct child with waitpid;
# ECHILD revokes authority. Never address the caller's group or a made-up PID.
sub rescue {
    for my $pid (sort {$a <=> $b} keys %births) {
        next if $births{$pid}{reaped};
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid || ($w == -1 && $! == ECHILD)) {
            $births{$pid}{reaped} = 1; next;
        }
        die "independent ownership unavailable for rescue\n" unless $w == 0;
        CORE::kill('KILL', $pid);
        my $end = now() + 2;
        while (now() < $end) {
            $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid) { $births{$pid}{reaped} = 1; last; }
            die "independent rescue lost exact child\n" if $w == -1;
            sleep(0.001);
        }
        die "independent rescue deadline expired\n" unless $births{$pid}{reaped};
    }
}
END {
    local $?;
    if ($$ == $creator) { alarm 0; rescue(); }
}
local $SIG{ALRM} = sub { die "unjoined closure observer deadline\n" };
alarm 20;

my $rfork = FSM::Support::ProcessSupervisor::Reservation->can('_fork');
my $cfork = FSM::Support::ProcessSupervisor::GatedPair->can('_fork');
my $rwait = FSM::Support::ProcessSupervisor::Reservation->can('_wait');
my $cwait = FSM::Support::ProcessSupervisor::GatedPair->can('_wait');
my $rsignal = FSM::Support::ProcessSupervisor::Reservation->can('_signal');
my $csignal = FSM::Support::ProcessSupervisor::GatedPair->can('_signal');
my $retire = FSM::Support::ProcessSupervisor::Reservation->can('retire');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub {
    my $pid = $rfork->();
    $births{$pid} = {role => 'reservation', reaped => 0} if defined($pid) && $pid > 0;
    return $pid;
};
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub {
    my $pid = $cfork->();
    if (defined($pid) && !$pid) {
        $SIG{TERM} = 'IGNORE';
        CORE::kill('STOP', $$) or _exit(126);
    }
    $births{$pid} = {role => 'command', reaped => 0} if defined($pid) && $pid > 0;
    return $pid;
};
sub observed_wait {
    my ($native, $pid) = @_;
    die 'wait for an unrecorded child' unless $births{$pid};
    my $w = $native->($pid);
    $births{$pid}{reaped} = 1 if $w == $pid;
    return $w;
}
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { observed_wait($cwait, @_) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub {
    die 'reservation waited before group retirement' unless $group_retired;
    observed_wait($rwait, @_);
};
sub observed_signal {
    my ($native, $signal, $target) = @_;
    my $pid = abs($target);
    die 'signal for an unowned or harvested identity' unless $births{$pid} && !$births{$pid}{reaped};
    die 'group operation after retirement' if $target < 0 && $group_retired;
    push @signals, [$signal, $target];
    return $native->($signal, $target);
}
local *FSM::Support::ProcessSupervisor::GatedPair::_signal = sub { observed_signal($csignal, @_) };
local *FSM::Support::ProcessSupervisor::Reservation::_signal = sub { observed_signal($rsignal, @_) };
local *FSM::Support::ProcessSupervisor::Reservation::retire = sub {
    $group_retired = 1;
    return $retire->(@_);
};

my $caller_group = getpgrp(0);
my $snapshot = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
    argv => [$^X, '-e', 'print "FORBIDDEN"'], cwd => '.', schema => 'private.unjoined.fixture.v1',
    stage => 'probe', containment => 'fixture-group',
    bounds => {timeout_seconds => 10, capture_limit_bytes => 64},
}, sprintf('%.0f', now() * 1e9));
my $job = FSM::Support::ProcessSupervisor::ReservedJob::prepare(
    snapshot => $snapshot, deadline => $snapshot->{started_ns} / 1e9 + 10, close_handles => []);
$job->start;
my $end = now() + 3;
my $command;
while (now() < $end) {
    $job->advance;
    $command = $job->observation->{command}{command_pid};
    last if $command;
    sleep(0.001);
}
die 'command fork was never recorded' unless $command;
my $reservation = $job->observation->{reservation}{pid};
ok($births{$command} && $births{$reservation}, 'independent native fork inventory agrees with both identities');
my ($stopped, $stop_status, $portable_status);
$end = now() + 2;
while (now() < $end) {
    my $w = CORE::waitpid($command, WNOHANG | WUNTRACED);
    if ($w == $command) {
        $stopped = 1;
        $portable_status = $?;
        $stop_status = ${^CHILD_ERROR_NATIVE};
        last;
    }
    die 'native stop observation lost ownership' if $w == -1;
    sleep(0.001);
}
ok($stopped && WIFSTOPPED($stop_status) && WSTOPSIG($stop_status) == SIGSTOP,
    'independent native stop status proves the command has not reached its join gate')
    or diag explain({observed => $stopped, raw_status => $stop_status,
        portable_status => $portable_status, expected_stop => 0 + SIGSTOP, command => $command});
die 'stop control is unavailable' unless $stopped && WIFSTOPPED($stop_status);
is(getpgrp($command), $caller_group, 'stopped command still belongs to the caller group');
is(getpgrp($reservation), $reservation, 'reservation initially owns its separately created group');

my $deadline = now() + 4;
$job->cancel('cancel stopped unjoined command', $deadline);
my $observed_moved = 0;
$end = now() + 5;
while (now() < $end) {
    $job->advance;
    my $o = $job->observation;
    if (!$observed_moved && $o->{reservation}{moved} && !$o->{reservation}{retired}) {
        $observed_moved = 1;
        is(getpgrp($reservation), $caller_group, 'native membership confirms reservation departure');
        is(getpgrp($command), $caller_group, 'the stopped command remains outside the reserved group');
    }
    last if $o->{phase} eq 'finished';
    sleep(0.001);
}
ok($observed_moved, 'the exact moved-reservation/unjoined-command cut was exercised');
my $s = $job->finished_job;
ok($s->{resources_closed}, 'the engine closes every owned resource inside the shared wall')
    or diag explain({result => $s->{result}, closure => $s->{closure_observation}, signals => \@signals});
ok($s->{cleanup}{leader_reaped}, 'the engine consumes the actual command wait');
ok(grep($_->[0] eq 'KILL' && $_->[1] == $command, @signals),
    'positive command KILL remains available after reservation departure');
is($s->{result}{signal}, 9, 'actual command wait records its forced termination');
is($s->{result}{diagnostic}, 'cancel stopped unjoined command', 'cleanup preserves the original cancellation');
ok(!$job->observation->{command}{released}, 'no exec release is delivered');
is(getpgrp(0), $caller_group, 'caller group remains unchanged');
ok(!grep(!$_->{reaped}, values %births),
    'independent native wait observer confirms the engine consumed both children');

rescue();
ok(!grep(!$_->{reaped}, values %births), 'independent owner inventory consumes every native child outcome');
alarm 0;
done_testing();
