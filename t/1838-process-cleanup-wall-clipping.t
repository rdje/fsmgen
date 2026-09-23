#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(ECHILD ESRCH);
use POSIX qw(SIG_BLOCK SIG_SETMASK SIG_UNBLOCK SIGUSR1 WNOHANG WUNTRACED WIFSTOPPED WSTOPSIG);
use Time::HiRes qw(sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::ReservedJob ();

my $creator = $$;
my (@jobs, @pipes, %births, %waits, %absence, @kills, $stop_retirement, $inject_signal, $inject_before_mask);
my $reservation = 'FSM::Support::ProcessSupervisor::Reservation';
my $pair = 'FSM::Support::ProcessSupervisor::GatedPair';
sub now { FSM::Support::ProcessSupervisor::Reservation::_now() }
sub live { grep { defined(fileno($_)) } @pipes }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub prepare {
    my $s = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', 'print "FORBIDDEN"'], cwd => '.',
        schema => 'private.clipped.cleanup.v1', stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 15, capture_limit_bytes => 64},
    }, sprintf('%.0f', now() * 1e9));
    my $j = FSM::Support::ProcessSupervisor::ReservedJob::prepare(snapshot => $s,
        deadline => $s->{started_ns} / 1e9 + 15, close_handles => []);
    push @jobs, $j; $j->start; return $j;
}
sub drive {
    my ($j, $predicate) = @_;
    my $end = now() + 5;
    while (now() < $end) {
        return if $predicate->();
        $j->advance; sleep(0.001);
    }
    die 'clipped cleanup fixture observer deadline';
}
sub stopped {
    my ($pid) = @_;
    die 'stop target is not an owned unreaped direct child' unless exists($births{$pid}) && !$births{$pid};
    CORE::kill('STOP', $pid) == 1 or die 'cannot stop exact owned child';
    my $end = now() + 1;
    while (now() < $end) {
        my $w = CORE::waitpid($pid, WNOHANG | WUNTRACED);
        if ($w == $pid) {
            my $raw = ${^CHILD_ERROR_NATIVE};
            die 'owned child did not report the requested stop' unless WIFSTOPPED($raw) && WSTOPSIG($raw) == POSIX::SIGSTOP();
            return;
        }
        die 'lost exact child stop ownership' if $w == -1;
        sleep(0.001);
    }
    die 'native stop observation expired';
}
sub rescue {
    for my $pid (keys %births) {
        next if $births{$pid};
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid || ($w == -1 && $! == ECHILD)) { $births{$pid} = 1; next; }
        die 'lost direct-child rescue ownership' unless $w == 0;
        CORE::kill('KILL', $pid);
        my $end = now() + 2;
        while (now() < $end) {
            $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid) { $births{$pid} = 1; last; }
            die 'lost exact rescue wait' if $w == -1;
            sleep(0.001);
        }
        die 'clipping fixture rescue expired' unless $births{$pid};
    }
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        my $needed = grep { !$_ } values %births;
        rescue(); diag('independent clipping fixture rescued actual direct children') if $needed;
        close $_ for live();
    }
}
my $rfork = $reservation->can('_fork'); my $cfork = $pair->can('_fork');
my $rwait = $reservation->can('_wait'); my $cwait = $pair->can('_wait');
my $rsignal = $reservation->can('_signal'); my $csignal = $pair->can('_signal');
my $retire = $reservation->can('retire'); my $pipe = $reservation->can('_pipe'); my $mask = $reservation->can('_mask');
my $fork = sub { my ($native) = @_; my $pid = $native->(); $births{$pid} = 0 if defined($pid) && $pid > 0; return $pid };
my $wait = sub {
    my ($native, $pid) = @_;
    die 'native engine waited for an unobserved child' unless exists $births{$pid};
    my $w = $native->($pid);
    if ($w == $pid) { $waits{$pid} = $?; $births{$pid} = 1; }
    return $w;
};
my $signal = sub {
    my ($native, $sig, $target) = @_;
    my $at = now(); my $result = $native->($sig, $target);
    push @kills, [$target, $at, $result] if "$sig" eq 'KILL'; return $result;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->($rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->($cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait, @_) };
local *FSM::Support::ProcessSupervisor::Reservation::_signal = sub { $signal->($rsignal, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_signal = sub { $signal->($csignal, @_) };
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    my $ok = $pipe->(@_); push @pipes, ${$_[0]}, ${$_[1]} if $ok; return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::retire = sub {
    my ($r) = @_;
    if ($r->{pid} && $r->{moved} && !$r->{retired}) {
        local $! = 0; my $present = CORE::kill(0, -$r->{pid});
        $absence{$r->{pid}} = [$present, 0 + $!];
        if ($stop_retirement) { $stop_retirement = 0; stopped($r->{pid}); }
    }
    return $retire->(@_);
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($inject_before_mask && $_[0] == SIG_BLOCK) {
        $inject_before_mask = 0; CORE::kill('USR1', $$) == 1 or die 'cannot queue pre-mask clipping interruption';
    }
    if ($inject_signal && $_[0] == SIG_SETMASK) {
        $inject_signal = 0; CORE::kill('USR1', $$) == 1 or die 'cannot queue clipping interruption';
    }
    return $mask->(@_);
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "native clipping test wall\n" };
alarm 35;

for my $cut (qw(command reservation)) {
    subtest "earlier shared wall clips existing $cut cleanup without renewal" => sub {
        die 'previous native ownership remains live' if grep { !$_ } values %births;
        @kills = ();
        local $SIG{TERM} = $cut eq 'command' ? 'IGNORE' : 'DEFAULT';
        my $j = prepare(); drive($j, sub { $j->observation->{phase} eq 'ready' });
        my $c = $j->observation->{command}{command_pid};
        my $r = $j->observation->{reservation}{pid};
        stopped($c) if $cut eq 'command';
        $stop_retirement = 1 if $cut eq 'reservation';
        my $original = now() + 4;
        $j->cancel('original cleanup cause', $original);
        if ($cut eq 'reservation') {
            drive($j, sub { $j->{closure}->observation->{phase} eq 'retiring' });
            ok($j->{pair}->reservation->observation->{retired}, 'reservation signal authority retires before wall clipping');
        }
        else { $j->advance; }
        my $old_kill = $j->{closure}->observation->{kill_at};
        my $first = $j->observation->{first_failure};
        my $earlier = now() + 0.8;
        my ($seen_group, $seen_reservation);
        if ($cut eq 'reservation') {
            local $SIG{USR1} = sub {
                $seen_group = $j->{closure}->observation->{deadline};
                $seen_reservation = $j->{pair}->reservation->{closure_deadline};
                die "interrupted clipped cleanup return\n";
            };
            my $old = POSIX::SigSet->new;
            defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select clipping signal mask';
            $inject_signal = 1;
            like(error_from(sub { $j->cancel('later cancellation', $earlier) }), qr/interrupted clipped cleanup return/,
                'actual pending signal interrupts the clipped return');
            $inject_signal = 0;
            defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore clipping signal mask';
            is($seen_group, $earlier, 'handler sees the clipped group wall');
            is($seen_reservation, $earlier, 'handler sees the same clipped reservation wall');
        }
        else { $j->cancel('later cancellation', $earlier); }
        is($j->{closure}->observation->{deadline}, $earlier, 'repeated cancellation first shortens the original cleanup wall');
        # A real handler can win the race before the outer operation masks.
        # Its smaller wall must never be overwritten by the outer stale value.
        my $old_mask = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old_mask) or die 'cannot select race mask';
        my $nested = $earlier - 0.1;
        {
            local $SIG{USR1} = sub {
                if ($cut eq 'reservation') { $j->{pair}->reservation->retire($nested); }
                else { $j->{closure}->shorten_deadline($nested); }
            };
            $inject_before_mask = 1;
            if ($cut eq 'reservation') { $j->{pair}->reservation->retire($earlier - 0.05); }
            else { $j->{closure}->shorten_deadline($earlier - 0.05); }
            $inject_before_mask = 0;
        }
        defined POSIX::sigprocmask(SIG_SETMASK, $old_mask) or die 'cannot restore race mask';
        is($cut eq 'reservation' ? $j->{pair}->reservation->{closure_deadline}
            : $j->{closure}->observation->{deadline}, $nested,
            'actual pre-mask handler shortening survives the outer stale request');
        $earlier = $nested;
        $j->cancel('shared wall after nested shortening', $earlier);
        is($j->{closure}->observation->{deadline}, $earlier, 'shared cancellation retains the smaller nested wall');
        $j->cancel('attempted renewal', $original);
        is($j->{closure}->observation->{deadline}, $earlier, 'later cancellation cannot renew consumed grace');
        like(error_from(sub { $j->{closure}->shorten_deadline(0) }), qr/finite monotonic deadline/, 'invalid clipping input rejects');
        drive($j, sub { $j->observation->{phase} eq 'finished' });
        my $target = $cut eq 'command' ? -$r : $r;
        my @actual = grep { $_->[0] == $target && $_->[2] } @kills;
        ok(@actual, 'independent native observer sees successful required KILL');
        ok(@actual && $actual[0][1] < $old_kill && $actual[0][1] <= $earlier,
            'actual KILL uses the clipped wall before the original escalation threshold');
        ok($j->finished_job->{resources_closed}, 'shortened cleanup consumes exact native resources');
        ok(!grep(!$_, values %births), 'all independent direct waits are consumed before rescue');
        is($waits{$cut eq 'command' ? $c : $r} & 127, 9, 'exact native wait confirms selected stopped child died by KILL');
        is_deeply($absence{$r}, [0, ESRCH], 'kernel group absence was retained before reservation retirement');
        is_deeply($j->observation->{first_failure}, $first, 'wall shortening preserves the original failure');
        is($j->finished_job->{result}{stdout}, '', 'no gated command executes');
        ok(!live(), 'every independently retained native pipe end closes');
        my $finished = $j->{closure}->observation;
        $j->{closure}->shorten_deadline(now() + 4);
        is_deeply($j->{closure}->observation, $finished, 'finished closure cannot be restarted by a later wall');
    };
}

done_testing;
