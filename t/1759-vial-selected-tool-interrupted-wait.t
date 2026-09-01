#!/usr/bin/env perl

use strict;
use warnings;

use Errno qw(EINTR);
use File::Spec;
use FindBin;
use POSIX qw(WNOHANG _exit setpgid);
use Test::More;
use Time::HiRes qw(clock_gettime sleep CLOCK_MONOTONIC);

our $INTERRUPT_MODE;
our $INTERRUPT_PID;
our $INTERRUPT_CALLS = 0;
our $KILL_SENT = 0;

BEGIN {
    no warnings qw(once redefine);
    *CORE::GLOBAL::waitpid = sub {
        my ($pid, $flags) = @_;
        my @caller = caller(1);
        my @parent = caller(2);
        my $capture_poll = ($caller[3] // '') eq
                'FSM::VIAL::Backend::ProcessSupervisor::_capture'
            || (($caller[3] // '') eq
                    'FSM::VIAL::Backend::ProcessSupervisor::_poll_owned_child'
                && ($parent[3] // '') eq
                    'FSM::VIAL::Backend::ProcessSupervisor::_capture');
        my $selected = defined($INTERRUPT_MODE)
            && $flags == WNOHANG
            && (!defined($INTERRUPT_PID) || $pid == $INTERRUPT_PID)
            && $INTERRUPT_CALLS == 0
            && ($INTERRUPT_MODE ne 'selected_exit' || $capture_poll)
            && ($INTERRUPT_MODE ne 'selected_kill' || $KILL_SENT);
        if ($selected) {
            $INTERRUPT_CALLS++;
            $! = EINTR;
            return -1;
        }
        return CORE::waitpid($pid, $flags);
    };
    *CORE::GLOBAL::kill = sub {
        my ($signal, @pids) = @_;
        if (defined($INTERRUPT_MODE)
                && $INTERRUPT_MODE eq 'selected_kill'
                && defined($INTERRUPT_PID)
                && $signal eq 'KILL'
                && grep { abs($_) == $INTERRUPT_PID } @pids) {
            $KILL_SENT = 1;
        }
        return CORE::kill($signal, @pids);
    };
}

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::ProcessSupervisor;

my $capture = \&FSM::VIAL::Backend::ProcessSupervisor::_capture;
my $terminate =
    \&FSM::VIAL::Backend::ProcessSupervisor::_terminate_process;
my $terminate_observer =
    \&FSM::VIAL::Backend::ProcessSupervisor::_terminate_host_observer;
my $bounded_command =
    \&FSM::VIAL::Backend::ProcessSupervisor::_bounded_host_command;
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $WATCHDOG_SECONDS = 7;
my @active_groups;

END {
    terminate_group($_) for @active_groups;
}

run_probe(
    'selected-tool exit poll retries EINTR',
    sub {
        arm_interrupt('selected_exit', undef);
        my ($result, $error);
        eval {
            $result = $capture->(
                $repo_root,
                [$^X, '-e', 'exit 42'],
                {
                    schema => 'fsmgen.vial_process_supervisor_policy.v1',
                    schema_version => 1,
                    containment => 'outer_worker_process_group',
                    timeout_seconds => 3,
                    capture_limit_bytes => 65_536,
                },
            );
            1;
        } or $error = $@;
        my $calls = disarm_interrupt();
        my $passed = !defined($error) && $calls == 1
            && ref($result) eq 'HASH'
            && $result->{ok} && $result->{exit_code} == 42
            && $result->{signal} == 0;
        warn 'selected-tool exit-poll diagnostic: calls=', $calls,
            '; error=', defined($error) ? "$error" : '<none>',
            '; ok=', ref($result) eq 'HASH' ? $result->{ok} : '<absent>',
            '; exit_code=', ref($result) eq 'HASH'
                ? $result->{exit_code} : '<absent>',
            '; signal=', ref($result) eq 'HASH'
                ? $result->{signal} : '<absent>', "\n"
            unless $passed;
        return $passed;
    },
);

run_probe(
    'selected-tool TERM poll retries EINTR',
    sub {
        my $tool_pid = spawn_ignoring_child();
        arm_interrupt('selected_term', $tool_pid);
        my $started = clock_gettime(CLOCK_MONOTONIC);
        my ($status, $error);
        eval {
            $status = $terminate->($tool_pid, 0);
            1;
        } or $error = $@;
        my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $started;
        my $calls = disarm_interrupt();
        my $alive = kill(0, $tool_pid) ? 1 : 0;
        reap_exactly($tool_pid) if $alive;
        return !defined($error)
            && defined($status) && ($status & 127) == 9
            && $calls == 1 && $elapsed >= 1.5 && !$alive;
    },
);

run_probe(
    'selected-tool post-KILL poll retries EINTR',
    sub {
        my $tool_pid = spawn_ignoring_child();
        arm_interrupt('selected_kill', $tool_pid);
        my ($status, $error);
        eval {
            $status = $terminate->($tool_pid, 0);
            1;
        } or $error = $@;
        my $calls = disarm_interrupt();
        my $alive = kill(0, $tool_pid) ? 1 : 0;
        reap_exactly($tool_pid) if $alive;
        return !defined($error)
            && defined($status) && ($status & 127) == 9
            && $calls == 1 && !$alive;
    },
);

run_probe(
    'host-observer cleanup poll retries EINTR',
    sub {
        my $observer_pid = spawn_ignoring_child();
        arm_interrupt('host_cleanup', $observer_pid);
        my $started = clock_gettime(CLOCK_MONOTONIC);
        my $error;
        eval {
            $terminate_observer->($observer_pid);
            1;
        } or $error = $@;
        my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $started;
        my $calls = disarm_interrupt();
        my $alive = kill(0, $observer_pid) ? 1 : 0;
        reap_exactly($observer_pid) if $alive;
        return !defined($error) && $calls == 1
            && $elapsed >= 0.15 && !$alive;
    },
);

run_probe(
    'bounded host-command poll retries EINTR',
    sub {
        arm_interrupt('host_command', undef);
        my $error;
        eval {
            $bounded_command->(
                clock_gettime(CLOCK_MONOTONIC) + 3,
                $^X, '-e', 'exit 42',
            );
            1;
        } or $error = $@;
        my $calls = disarm_interrupt();
        return $calls == 1 && defined($error)
            && $error eq "selected-tool host observation did not complete\n";
    },
);

done_testing();

sub run_probe {
    my ($name, $probe) = @_;
    subtest $name => sub {
        my ($reader, $writer);
        pipe($reader, $writer)
            or die "cannot create interrupted-wait result pipe: $!\n";
        my $probe_pid = fork();
        die "cannot fork interrupted-wait probe: $!\n"
            unless defined $probe_pid;
        if ($probe_pid == 0) {
            close $reader;
            setpgid(0, 0) or _exit(91);
            my $passed = eval { $probe->() } ? 1 : 0;
            disarm_interrupt();
            syswrite($writer, $passed ? 'S' : 'F', 1);
            close $writer;
            _exit($passed ? 0 : 92);
        }
        close $writer;
        eval { setpgid($probe_pid, $probe_pid); 1 };
        push @active_groups, $probe_pid;

        my ($finished, $status) = wait_until_exit(
            $probe_pid, $WATCHDOG_SECONDS,
        );
        ok($finished, "$name returns inside the outer watchdog");
        if (!$finished) {
            terminate_group($probe_pid);
            while (1) {
                my $waited = waitpid($probe_pid, 0);
                next if $waited == -1 && $! == EINTR;
                last if $waited == $probe_pid || $waited == -1;
            }
        }
        my $record = '';
        sysread($reader, $record, 1);
        close $reader;
        is($record, 'S', "$name preserves exact completion evidence");
        ok(!$finished || (($status & 127) == 0 && ($status >> 8) == 0),
            "$name probe exits cleanly");
        ok(!kill(0, -$probe_pid),
            "$name leaves no process-group residue");

        terminate_group($probe_pid);
        pop @active_groups;
    };
}

sub arm_interrupt {
    ($INTERRUPT_MODE, $INTERRUPT_PID) = @_;
    $INTERRUPT_CALLS = 0;
    $KILL_SENT = 0;
}

sub disarm_interrupt {
    my $calls = $INTERRUPT_CALLS;
    $INTERRUPT_MODE = undef;
    $INTERRUPT_PID = undef;
    $KILL_SENT = 0;
    return $calls;
}

sub spawn_ignoring_child {
    my ($ready_reader, $ready_writer);
    pipe($ready_reader, $ready_writer)
        or die "cannot create child readiness pipe: $!\n";
    my $pid = fork();
    die "cannot fork interruptible child: $!\n" unless defined $pid;
    if ($pid == 0) {
        close $ready_reader;
        $SIG{TERM} = 'IGNORE';
        syswrite($ready_writer, 'R', 1);
        close $ready_writer;
        sleep 30;
        _exit(0);
    }
    close $ready_writer;
    my $ready = '';
    sysread($ready_reader, $ready, 1);
    close $ready_reader;
    die "interruptible child did not become ready\n" unless $ready eq 'R';
    return $pid;
}

sub reap_exactly {
    my ($pid) = @_;
    kill 'KILL', $pid;
    while (1) {
        my $waited = waitpid($pid, 0);
        next if $waited == -1 && $! == EINTR;
        last if $waited == $pid || $waited == -1;
    }
}

sub wait_until_exit {
    my ($pid, $seconds) = @_;
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + $seconds;
    while (clock_gettime(CLOCK_MONOTONIC) < $deadline) {
        my $waited = waitpid($pid, WNOHANG);
        next if $waited == -1 && $! == EINTR;
        return (1, $?) if $waited == $pid || $waited == -1;
        sleep 0.02;
    }
    return (0, undef);
}

sub terminate_group {
    my ($pid) = @_;
    return unless defined($pid) && $pid > 1;
    kill 'TERM', -$pid;
    sleep 0.05;
    kill 'KILL', -$pid if kill(0, -$pid);
    return;
}
