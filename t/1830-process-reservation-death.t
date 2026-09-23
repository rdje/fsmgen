#!/usr/bin/env perl
use strict;
use warnings;

use Errno qw(EAGAIN ECHILD EINTR ESRCH);
use IO::Select;
use POSIX qw(WNOHANG WUNTRACED WIFSTOPPED WSTOPSIG SIGSTOP);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::ReservedJob ();
use FSM::Support::ProcessSupervisor::ReservedReceipt ();

my $creator = $$;
my %births;
sub now { clock_gettime(CLOCK_MONOTONIC) }

# The inventory comes from native fork/wait returns, not terminal engine flags.
# Rescue uses only recorded direct children and rechecks exact wait ownership
# before a positive signal. No retired numeric group is ever revisited.
sub rescue {
    for my $pid (sort { $a <=> $b } keys %births) {
        next if $births{$pid}{reaped};
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid || ($w == -1 && $! == ECHILD)) {
            $births{$pid}{reaped} = 1; next;
        }
        die "rescue lacks exact direct-child ownership\n" unless $w == 0;
        CORE::kill('KILL', $pid);
        my $end = now() + 2;
        while (now() < $end) {
            $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid) { $births{$pid}{reaped} = 1; last; }
            die "rescue lost its exact child\n" if $w == -1;
            sleep(0.001);
        }
        die "rescue wait deadline expired\n" unless $births{$pid}{reaped};
    }
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        my $needed = grep { !$_->{reaped} } values %births;
        rescue();
        diag('independent END rescue consumed every retained direct child') if $needed;
    }
}

sub until_observed {
    my ($job, $predicate, $seconds) = @_;
    my $end = now() + $seconds;
    while (now() < $end) {
        my $o = $job->observation;
        return $o if $predicate->($o);
        die "unexpected terminal job\n" if $o->{phase} eq 'finished';
        $job->advance;
        sleep(0.001);
    }
    die "native lifecycle observer deadline expired\n";
}

sub observe_stop {
    my ($pid) = @_;
    die 'stop requires an owned unharvested command' unless $births{$pid}
        && $births{$pid}{role} eq 'command' && !$births{$pid}{reaped};
    CORE::kill('STOP', $pid) == 1 or die 'native command stop failed';
    my $end = now() + 2;
    while (now() < $end) {
        my $w = CORE::waitpid($pid, WNOHANG | WUNTRACED);
        if ($w == $pid) {
            my $raw = ${^CHILD_ERROR_NATIVE};
            die 'expected an actual stopped child' unless WIFSTOPPED($raw)
                && WSTOPSIG($raw) == SIGSTOP;
            return;
        }
        die 'native stop lost exact ownership' if $w == -1;
        sleep(0.001);
    }
    die 'native stop deadline expired';
}

sub read_to_eof {
    my ($fh, $seconds) = @_;
    my $bytes = '';
    my $end = now() + $seconds;
    while (now() < $end) {
        next unless IO::Select->new($fh)->can_read(0.01);
        my $n = sysread($fh, my $chunk, 128);
        next if !defined($n) && ($! == EAGAIN || $! == EINTR);
        die 'native EOF read failed' unless defined $n;
        return $bytes unless $n;
        $bytes .= $chunk;
        die 'unexpected unbounded witness bytes' if length($bytes) > 128;
    }
    die 'native EOF observer deadline expired';
}

my $rfork = FSM::Support::ProcessSupervisor::Reservation->can('_fork');
my $cfork = FSM::Support::ProcessSupervisor::GatedPair->can('_fork');
my $rwait = FSM::Support::ProcessSupervisor::Reservation->can('_wait');
my $cwait = FSM::Support::ProcessSupervisor::GatedPair->can('_wait');
my $rsignal = FSM::Support::ProcessSupervisor::Reservation->can('_signal');
my $csignal = FSM::Support::ProcessSupervisor::GatedPair->can('_signal');
my $retire = FSM::Support::ProcessSupervisor::Reservation->can('retire');
my $pipe = FSM::Support::ProcessSupervisor::Reservation->can('_pipe');

local $SIG{ALRM} = sub { die "reservation-death test deadline\n" };
alarm 30;
for my $moved (0, 1) {
    subtest $moved ? 'reservation death after acknowledged departure'
                  : 'reservation death before departure delivery' => sub {
        rescue(); %births = ();
        my (@signals, @handles);
        my ($retired, $group_permitted) = (0, 0);
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub {
            my $pid = $rfork->();
            $births{$pid} = {role => 'reservation', reaped => 0} if defined($pid) && $pid > 0;
            return $pid;
        };
        local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub {
            my $pid = $cfork->();
            $births{$pid} = {role => 'command', reaped => 0} if defined($pid) && $pid > 0;
            return $pid;
        };
        local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
            my $ok = $pipe->(@_);
            push @handles, ${$_[0]}, ${$_[1]} if $ok;
            return $ok;
        };
        my $wait = sub {
            my ($native, $pid) = @_;
            die 'wait for an unrecorded child' unless $births{$pid};
            die 'reservation wait before signal retirement'
                if $births{$pid}{role} eq 'reservation' && !$retired;
            my $w = $native->($pid);
            if ($w == $pid) {
                $births{$pid}{status} = $?;
                $births{$pid}{reaped} = 1;
            }
            return $w;
        };
        local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait, @_) };
        local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait, @_) };
        my $signal = sub {
            my ($native, $sig, $target) = @_;
            my $record = $births{abs($target)};
            die 'signal targets an unowned or harvested identity' unless $record && !$record->{reaped};
            die 'group operation lacks acknowledged live authority'
                if $target < 0 && (!$group_permitted || $retired || $record->{role} ne 'reservation');
            my $sent = $native->($sig, $target);
            my $error = 0 + $!;
            push @signals, [$sig, $target, $sent, $error];
            $! = $error;
            return $sent;
        };
        local *FSM::Support::ProcessSupervisor::Reservation::_signal = sub { $signal->($rsignal, @_) };
        local *FSM::Support::ProcessSupervisor::GatedPair::_signal = sub { $signal->($csignal, @_) };
        local *FSM::Support::ProcessSupervisor::Reservation::retire = sub {
            $retired = 1;
            return $retire->(@_);
        };

        my $caller_group = getpgrp(0);
        my $snapshot = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
            argv => [$^X, '-e', 'print "FORBIDDEN"'], cwd => '.',
            schema => 'private.reservation.death.v1', stage => 'probe', containment => 'fixture-group',
            bounds => {timeout_seconds => 10, capture_limit_bytes => 64},
        }, sprintf('%.0f', now() * 1e9));
        my $job;
        {
            # The command must need KILL even if the platform delivers TERM
            # while stopped. The caller's disposition is restored immediately.
            local $SIG{TERM} = 'IGNORE';
            $job = FSM::Support::ProcessSupervisor::ReservedJob::prepare(
                snapshot => $snapshot, deadline => $snapshot->{started_ns} / 1e9 + 10,
                close_handles => []);
        }
        my $stdout = $job->{pair}->streams->{stdout};
        $job->start;
        my $o = until_observed($job, sub {
            $moved ? $_[0]{phase} eq 'ready' : $_[0]{command}{phase} eq 'move_pending';
        }, 3);
        my ($command, $reservation) = ($o->{command}{command_pid}, $o->{reservation}{pid});
        is_deeply([sort { $a <=> $b } keys %births], [sort { $a <=> $b } ($command, $reservation)],
            'native fork inventory exactly matches both distinct engine identities');
        isnt($command, $reservation, 'command and reservation are separate direct children');
        is(getpgrp($command), $reservation, 'native command membership confirms completed join');
        is(getpgrp($reservation), $moved ? $caller_group : $reservation,
            'native reservation membership confirms the selected departure cut');
        if (!$moved) {
            is($job->{pair}->reservation->{outgoing}, 'M', 'departure is queued but not delivered');
        }
        $group_permitted = $moved;
        observe_stop($command);
        pass('native wait proves the joined command is stopped before exec');
        open my $witness, '<&', $stdout or die 'cannot retain independent execution witness';
        CORE::kill('KILL', $reservation) == 1 or die 'cannot terminate owned reservation';
        is(read_to_eof($job->{pair}->reservation->{read}, 2), '',
            'native pipe EOF establishes reservation death without harvesting its identity');
        ok(!$births{$reservation}{reaped}, 'reservation remains independently unharvested');

        $job->advance;
        my $first = $job->observation->{first_failure};
        is($first->{status}, 'host_error', 'premature reservation death is an infrastructure failure');
        like($first->{diagnostic}, qr/reservation (?:instruction write failed|exited before retirement)/,
            'the original handoff failure is explicit');
        my $deadline = $job->{closure}->observation->{deadline};
        until_observed($job, sub { $_[0]{phase} eq 'finished' }, 5);
        my $state = $job->finished_job;
        is($state->{closure_observation}{deadline}, $deadline, 'cleanup never renews its original envelope');
        is_deeply($job->observation->{first_failure}, $first, 'cleanup preserves the first failure');
        is($state->{result}{diagnostic}, $first->{diagnostic}, 'terminal result keeps the original cause');
        is($state->{result}{status}, 'host_error', 'settled waits cannot promote the failed job');
        ok(!grep(!$_->{reaped}, values %births), 'engine consumes every native child outcome before rescue');
        is($births{$command}{status}, 9, 'native command wait records required KILL');
        is($state->{leader_status}, $births{$command}{status}, 'engine command wait equals native observation');
        is($births{$reservation}{status}, 9, 'native reservation wait records injected KILL');
        is($state->{reservation_observation}{wait_status}, $births{$reservation}{status},
            'engine preserves the independent reservation wait');
        is($state->{resources_closed}, $moved, 'closure requires departure and proved group disappearance');
        is($state->{cleanup}{group_gone}, $moved, 'unacknowledged departure never fabricates group absence');
        ok(grep($_->[0] eq 'KILL' && $_->[1] == ($moved ? -$reservation : $command), @signals),
            'escalation uses only the authority available at this cut');
        if ($moved) {
            ok(grep($_->[0] eq '0' && $_->[1] == -$reservation && !$_->[2] && $_->[3] == ESRCH, @signals),
                'native ESRCH is observed while the dead reservation still holds its identity');
        }
        else { ok(!grep($_->[1] < 0, @signals), 'no group operation precedes acknowledged departure'); }
        is(read_to_eof($witness, 1), '', 'independent output reaches EOF without command execution');
        close $witness or die 'execution witness close failed';
        ok(!grep(defined(fileno($_)), @handles), 'every independently retained engine descriptor is closed');
        ok(!$job->observation->{command}{released}, 'exec gate remains unreleased');
        is(getpgrp(0), $caller_group, 'caller group remains unchanged');
        is(FSM::Support::ProcessSupervisor::ReservedReceipt::receipt_bound(
            $job, $state->{receipt_observation}, 'outer', {closed => 1}) ? 1 : 0, $moved,
            'receipt review distinguishes exact resource closure from infrastructure failure');
        rescue();
        ok(!grep(!$_->{reaped}, values %births), 'independent owner inventory has no unconsumed child');
    };
}
alarm 0;
done_testing();
