#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use POSIX qw(WNOHANG _exit setpgid);
use Test::More;
use Time::HiRes qw(clock_gettime sleep CLOCK_MONOTONIC);

our $BLOCKING_WAIT_PID;
our $BLOCKING_WAIT_CALLS = 0;

BEGIN {
    no warnings qw(once redefine);
    *CORE::GLOBAL::waitpid = sub {
        my ($pid, $flags) = @_;
        if (defined($BLOCKING_WAIT_PID)
                && $pid == $BLOCKING_WAIT_PID && $flags == 0) {
            $BLOCKING_WAIT_CALLS++;
            sleep 30;
            return 0;
        }
        return CORE::waitpid($pid, $flags);
    };
}

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::ProcessSupervisor;

my $terminate = \&FSM::VIAL::Backend::ProcessSupervisor::_terminate_process;
my $WATCHDOG_SECONDS = 7;
my @active_groups;

END {
    terminate_group($_) for @active_groups;
}

subtest 'selected-tool leader reap remains bounded after SIGKILL' => sub {
    my ($reader, $writer);
    pipe($reader, $writer)
        or die "cannot create bounded-reap result pipe: $!\n";
    my $probe_pid = fork();
    die "cannot fork bounded-reap probe: $!\n" unless defined $probe_pid;
    if ($probe_pid == 0) {
        close $reader;
        setpgid(0, 0) or _exit(91);

        my ($ready_reader, $ready_writer);
        pipe($ready_reader, $ready_writer) or _exit(92);
        my $tool_pid = fork();
        _exit(93) unless defined $tool_pid;
        if ($tool_pid == 0) {
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
        _exit(94) unless $ready eq 'R';

        $BLOCKING_WAIT_PID = $tool_pid;
        $BLOCKING_WAIT_CALLS = 0;
        my $started = clock_gettime(CLOCK_MONOTONIC);
        my ($status, $error);
        eval {
            $status = $terminate->($tool_pid, 0);
            1;
        } or $error = $@;
        my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $started;
        my $passed = !defined($error)
            && defined($status)
            && ($status & 127) == 9
            && $BLOCKING_WAIT_CALLS == 0
            && $elapsed >= 1.5
            && $elapsed < 5;
        syswrite($writer, $passed ? 'S' : 'F', 1);
        close $writer;
        _exit($passed ? 0 : 95);
    }
    close $writer;
    eval { setpgid($probe_pid, $probe_pid); 1 };
    push @active_groups, $probe_pid;

    my ($finished, $status) = wait_until_exit(
        $probe_pid, $WATCHDOG_SECONDS,
    );
    ok($finished, 'post-SIGKILL reap returns inside the outer watchdog');
    if (!$finished) {
        terminate_group($probe_pid);
        waitpid($probe_pid, 0);
    }
    my $record = '';
    sysread($reader, $record, 1);
    close $reader;
    is($record, 'S',
        'leader reap uses bounded polling and preserves exact wait status');
    ok(!$finished || (($status & 127) == 0 && ($status >> 8) == 0),
        'bounded-reap probe exits cleanly after containment');
    ok(!kill(0, -$probe_pid),
        'bounded-reap probe leaves no process-group residue');

    terminate_group($probe_pid);
    pop @active_groups;
};

done_testing();

sub wait_until_exit {
    my ($pid, $seconds) = @_;
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + $seconds;
    while (clock_gettime(CLOCK_MONOTONIC) < $deadline) {
        my $waited = waitpid($pid, WNOHANG);
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
