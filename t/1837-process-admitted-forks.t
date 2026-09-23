#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(ECHILD);
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Time::HiRes qw(sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::ReservedJob ();

my $creator = $$;
my (@jobs, @foreign, @foreign_all, @pipes, %births, %native_status, $job, $last_role, $signal_role, $fake_now);
my ($sequence, $consumed, $fork_count) = (0, 0, 0);
my $reservation = 'FSM::Support::ProcessSupervisor::Reservation';
my $pair = 'FSM::Support::ProcessSupervisor::GatedPair';
my $native_now = $reservation->can('_now');
sub now { $native_now->() }
sub live { grep { defined(fileno($_)) } @_ }
sub mask_pair {
    my $mask = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $mask) or die 'cannot inspect caller mask';
    return [$mask->ismember(SIGUSR1), $mask->ismember(SIGUSR2)];
}
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub prepare {
    my $s = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', 'syswrite STDOUT,"FORBIDDEN"'], cwd => '.',
        schema => 'private.fork.admission.v1', stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 15, capture_limit_bytes => 64},
    }, sprintf('%.0f', now() * 1e9));
    my $j = FSM::Support::ProcessSupervisor::ReservedJob::prepare_record(
        snapshot => $s, deadline => $s->{started_ns} / 1e9 + 15, close_handles => []);
    push @jobs, $j; $j->allocate; return $j;
}
sub foreign_pipe {
    CORE::pipe(my $r, my $w) or die 'cannot create owned foreign fixture';
    push @foreign, $r, $w; push @foreign_all, $r, $w;
}
sub reset_observers {
    die 'previous direct child remains unconsumed' if grep { !$_ } values %births;
    close $_ or die 'cannot close parent foreign descriptor' for live(@foreign);
    @foreign = (); $last_role = $signal_role = undef; $sequence = $consumed = 0; $fake_now = undef;
}
sub drive {
    my ($j, $phase) = @_;
    my $end = now() + 5;
    while (now() < $end) {
        return if $j->observation->{phase} eq $phase;
        if ($j->observation->{phase} eq 'finished') {
            my $o = $j->observation;
            my $pid = $o->{command}{command_pid} // $o->{reservation}{pid};
            my $raw = defined($pid) && exists($native_status{$pid}) ? $native_status{$pid} : 'unobserved';
            die "native job finished before required handoff; independent wait=$raw\n";
        }
        $j->advance; sleep(0.001);
    }
    die 'native fork fixture observer wall expired';
}
sub close_job {
    my ($j, $complete) = @_;
    my $first = $j->observation->{first_failure};
    $j->cancel('fixture closes unreleased native job', now() + 4);
    drive($j, 'finished');
    my $state = $j->finished_job;
    ok($state->{resources_closed}, 'gated native resources close exactly') if $complete;
    ok(!grep(!$_, values %births), 'engine consumes every independently observed direct wait before rescue');
    ok(!@{$j->handles}, 'retained job inventory is empty after cleanup');
    is_deeply($j->observation->{first_failure}, $first, 'later cancellation preserves the original fork error') if $first;
    is($state->{result}{stdout}, '', 'unreleased command contributes no output');
}
sub rescue {
    for my $pid (keys %births) {
        next if $births{$pid};
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid || ($w == -1 && $! == ECHILD)) { $births{$pid} = 1; next; }
        die 'fixture lost exact child ownership' unless $w == 0;
        CORE::kill('KILL', $pid);
        my $end = now() + 2;
        while (now() < $end) {
            $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid) { $births{$pid} = 1; last; }
            die 'fixture lost exact rescue wait' if $w == -1;
            sleep(0.001);
        }
        die 'fixture rescue wall expired' unless $births{$pid};
    }
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        my $needed = grep { !$_ } values %births;
        rescue(); diag('independent fork fixture rescued direct children') if $needed;
        close $_ for live(@foreign_all, @pipes);
    }
}

my $rfork = $reservation->can('_fork'); my $cfork = $pair->can('_fork');
my $rwait = $reservation->can('_wait'); my $cwait = $pair->can('_wait');
my $pipe = $reservation->can('_pipe'); my $byte = $reservation->can('_child_byte');
my $command_child = $pair->can('_child');
my $check_exec_mask = 0;
my $fork = sub {
    my ($role, $native) = @_;
    die 'native fork lacks fresh admitted inventory' unless defined($last_role)
        && $last_role eq $role && $sequence > $consumed;
    $consumed = $sequence;
    my $pid = $native->();
    if (defined($pid) && $pid > 0) {
        $births{$pid} = 0; ++$fork_count;
        CORE::kill('USR1', $$) == 1 or die 'cannot queue retained fork interruption'
            if defined($signal_role) && $signal_role eq $role;
    }
    return $pid;
};
my $wait = sub {
    my ($native, $pid) = @_;
    die 'engine waited for a foreign child' unless exists $births{$pid};
    my $w = $native->($pid);
    if ($w == $pid) { $native_status{$pid} = $?; $births{$pid} = 1; }
    return $w;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_now = sub { $fake_now // $native_now->() };
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    my $ok = $pipe->(@_); push @pipes, ${$_[0]}, ${$_[1]} if $ok; return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->('reservation', $rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->('command', $cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait, @_) };
local *FSM::Support::ProcessSupervisor::Reservation::_child_byte = sub {
    _exit(91) if live(@foreign);
    return $byte->(@_);
};
local *FSM::Support::ProcessSupervisor::GatedPair::_child = sub {
    if ($check_exec_mask) {
        _exit(92) unless $_[0]{exec_mask}->ismember(SIGUSR1)
            && !$_[0]{exec_mask}->ismember(SIGUSR2) && $_[0]{dispositions}{USR2} eq 'IGNORE';
    }
    return $command_child->(@_);
};
use warnings 'redefine';
sub admission {
    my ($effect) = @_;
    return sub {
        my ($role) = @_;
        my $mask = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $mask) or die 'cannot observe fork mask';
        die 'admission is outside the native fork mask' unless $mask->ismember(SIGUSR1) && $mask->ismember(SIGUSR2);
        $last_role = $role; ++$sequence;
        return $effect->($role) if $effect;
        return [@foreign];
    };
}
local $SIG{ALRM} = sub { die "admitted native fork fixture deadline\n" };
alarm 45;

subtest 'fresh native inventories and original exec state survive both gated forks' => sub {
    reset_observers(); local $SIG{USR2} = 'IGNORE';
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR2), $old) or die 'cannot select caller mask';
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR1)) or die 'cannot block original signal';
    $job = prepare(); foreign_pipe(); $check_exec_mask = 1;
    $job->start(admission());
    foreign_pipe(); # created after reservation fork, before command fork
    drive($job, 'ready');
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore caller mask';
    $check_exec_mask = 0;
    is($sequence, 2, 'each original native fork obtains a distinct current admission');
    ok(live(@foreign) == 4, 'child closure preserves parent ownership of all later foreign descriptors');
    ok(!exists($job->{pair}{fork_check}), 'completed forks release retained admission callback');
    open my $witness, '<&', $job->{received}{stdout} or die 'cannot retain independent output witness';
    close_job($job, 1);
    my $n = sysread($witness, my $bytes, 32);
    is($n, 0, 'independent actual EOF proves no unreleased command output'); close $witness;
};

subtest 'denial, expiry and invalid inventories refuse the selected actual fork' => sub {
    for my $role (qw(reservation command)) {
        for my $mode (qw(deny expire duplicate overlap closed)) {
            reset_observers(); $job = prepare(); foreign_pipe(); my $before = $fork_count;
            my $check = admission(sub {
                return [@foreign] unless $_[0] eq $role;
                die "original admission revoked\n" if $mode eq 'deny';
                $fake_now = $job->{state}{deadline} if $mode eq 'expire';
                return [$foreign[0], $foreign[0]] if $mode eq 'duplicate';
                return [@foreign, $job->{pair}{stdout}] if $mode eq 'overlap';
                close $foreign[0] or die 'cannot select closed inventory' if $mode eq 'closed';
                return [@foreign];
            });
            my $original_mask = mask_pair();
            my $error = error_from(sub { $job->start($check); drive($job, 'ready'); });
            is_deeply(mask_pair(), $original_mask, 'actual caller signal mask is restored after fork refusal');
            $fake_now = undef;
            like($error, qr/admission revoked|deadline expired|closed, standard or duplicate/, "$mode rejects $role before native fork");
            is($fork_count - $before, $role eq 'reservation' ? 0 : 1, 'independent fork observer sees no refused child');
            close_job($job, 1);
        }
    }
};

subtest 'refreshed native inventories respect the inclusive actual descriptor union' => sub {
    reset_observers(); $job = prepare(); foreign_pipe() for 1 .. 56;
    open my $extra, '<&', $foreign[0] or die 'cannot duplicate exact owned foreign handle';
    push @foreign, $extra; push @foreign_all, $extra;
    is(scalar(live(@foreign, @pipes)), 128, 'independent native census reaches the exact private descriptor boundary');
    $job->start(admission()); drive($job, 'ready');
    close_job($job, 1);
    is(scalar(live(@foreign)), 113, 'native child closure never closes parent foreign ownership');
    reset_observers(); $job = prepare(); foreign_pipe() for 1 .. 57;
    my $before = $fork_count;
    is(scalar(live(@foreign, @pipes)), 129, 'independent excess control adds one descriptor beyond the union');
    like(error_from(sub { $job->start(admission()) }), qr/bounded descriptor inventory/,
        'actual union excess rejects inside admission before native fork');
    is($fork_count, $before, 'excess union performs no native fork');
    close_job($job, 1);
};

subtest 'actual pending signals retain fork identities and usable cleanup handshakes' => sub {
    for my $role (qw(reservation command)) {
        reset_observers(); $job = prepare(); foreign_pipe(); $signal_role = $role;
        my $published;
        local $SIG{USR1} = sub {
            my $o = $job->observation;
            $published = $role eq 'reservation' ? $o->{reservation}{pid} : $o->{command}{command_pid};
            die "creator interrupted retained $role return\n";
        };
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select signal mask';
        my $error = error_from(sub { $job->start(admission()); drive($job, 'ready'); });
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore signal mask';
        $signal_role = undef;
        like($error, qr/creator interrupted retained/, 'real pending callback interrupts the selected return');
        ok($published && exists($births{$published}), 'handler sees the exact independently observed child in original owner');
        like($job->observation->{first_failure}{diagnostic}, qr/creator interrupted retained/, 'job retains original interruption before cancellation');
        close_job($job, 1);
    }
};

done_testing;
