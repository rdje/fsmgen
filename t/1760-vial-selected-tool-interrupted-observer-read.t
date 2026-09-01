#!/usr/bin/env perl

use strict;
use warnings;

use Errno qw(EINTR);
use File::Spec;
use FindBin;
use POSIX qw(WNOHANG _exit setpgid);
use Test::More;
use Time::HiRes qw(clock_gettime sleep CLOCK_MONOTONIC);

our $INTERRUPT_READS = 0;
our $INTERRUPTED_READ_CALLS = 0;

BEGIN {
    no warnings qw(once redefine);
    *CORE::GLOBAL::sysread = sub {
        if ($INTERRUPT_READS) {
            $INTERRUPTED_READ_CALLS++;
            Time::HiRes::sleep(0.01);
            $! = EINTR;
            return undef;
        }
        return @_ == 4
            ? CORE::sysread($_[0], $_[1], $_[2], $_[3])
            : CORE::sysread($_[0], $_[1], $_[2]);
    };
}

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::ProcessSupervisor;

my $bounded_command =
    \&FSM::VIAL::Backend::ProcessSupervisor::_bounded_host_command;
my $WATCHDOG_SECONDS = 5;
my @active_groups;

END {
    terminate_group($_) for @active_groups;
}

subtest 'interrupted host-observer reads cannot suspend their deadline' => sub {
    my ($reader, $writer);
    pipe($reader, $writer)
        or die "cannot create interrupted-read result pipe: $!\n";
    my $probe_pid = fork();
    die "cannot fork interrupted-read probe: $!\n"
        unless defined $probe_pid;
    if ($probe_pid == 0) {
        close $reader;
        setpgid(0, 0) or _exit(91);
        $INTERRUPT_READS = 1;
        $INTERRUPTED_READ_CALLS = 0;
        my $started = clock_gettime(CLOCK_MONOTONIC);
        my $error;
        eval {
            $bounded_command->(
                $started + 1,
                $^X, '-e', 'sleep 30',
            );
            1;
        } or $error = $@;
        my $elapsed = clock_gettime(CLOCK_MONOTONIC) - $started;
        $INTERRUPT_READS = 0;
        my $passed = defined($error)
            && $error eq
                "selected-tool host observation exceeded its deadline\n"
            && $INTERRUPTED_READ_CALLS > 1
            && $elapsed >= 0.8 && $elapsed < 3;
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
    ok($finished, 'interrupted reads return inside the outer watchdog');
    if (!$finished) {
        terminate_group($probe_pid);
        reap_exactly($probe_pid);
    }
    my $record = '';
    sysread($reader, $record, 1);
    close $reader;
    is($record, 'S',
        'sustained EINTR yields to the exact monotonic observer deadline');
    ok(!$finished || (($status & 127) == 0 && ($status >> 8) == 0),
        'interrupted-read probe exits cleanly after helper containment');
    ok(!kill(0, -$probe_pid),
        'interrupted-read probe leaves no process-group residue');

    terminate_group($probe_pid);
    pop @active_groups;
};

done_testing();

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

sub reap_exactly {
    my ($pid) = @_;
    while (1) {
        my $waited = waitpid($pid, 0);
        next if $waited == -1 && $! == EINTR;
        last if $waited == $pid || $waited == -1;
    }
}

sub terminate_group {
    my ($pid) = @_;
    return unless defined($pid) && $pid > 1;
    kill 'TERM', -$pid;
    sleep 0.05;
    kill 'KILL', -$pid if kill(0, -$pid);
    return;
}
