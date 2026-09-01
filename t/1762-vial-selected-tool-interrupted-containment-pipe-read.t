#!/usr/bin/env perl

use strict;
use warnings;

use Errno qw(EINTR);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use File::Spec;
use FindBin;
use POSIX qw(WNOHANG _exit setpgid);
use Test::More;
use Time::HiRes qw(clock_gettime sleep CLOCK_MONOTONIC);

our $TARGET_READ_FD;
our $INTERRUPT_FROM_CALL;
our $TARGET_READ_CALLS = 0;

BEGIN {
    no warnings qw(once redefine);
    *CORE::GLOBAL::sysread = sub {
        my $fd = fileno($_[0]);
        if (defined($TARGET_READ_FD) && defined($fd)
                && $fd == $TARGET_READ_FD) {
            $TARGET_READ_CALLS++;
            if ($TARGET_READ_CALLS >= $INTERRUPT_FROM_CALL) {
                Time::HiRes::sleep(0.01);
                $! = EINTR;
                return undef;
            }
        }
        return @_ == 4
            ? CORE::sysread($_[0], $_[1], $_[2], $_[3])
            : CORE::sysread($_[0], $_[1], $_[2]);
    };
}

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::ProcessSupervisor;

my $terminate_holders =
    \&FSM::VIAL::Backend::ProcessSupervisor::_terminate_containment_pipe_holders;
my $WATCHDOG_SECONDS = 5;
my @active_groups;

END {
    terminate_group($_) for @active_groups;
}

my @cases = (
    {
        name => 'pre-attribution interrupted reads retain cleanup deadline',
        interrupt_from_call => 1,
        cleanup_seconds => 1,
        minimum_elapsed => 0.8,
        maximum_elapsed => 3,
        expected_holder_calls => 0,
        use_holder => 0,
    },
    {
        name => 'post-kill interrupted reads retain absence deadline',
        interrupt_from_call => 2,
        cleanup_seconds => 4,
        minimum_elapsed => 1.8,
        maximum_elapsed => 4,
        expected_holder_calls => 1,
        use_holder => 1,
    },
);

run_case($_) for @cases;

done_testing();

sub run_case {
    my ($case) = @_;
    subtest $case->{name} => sub {
        my ($result_reader, $result_writer);
        pipe($result_reader, $result_writer)
            or die "cannot create interrupted-pipe result channel: $!\n";
        my $probe_pid = fork();
        die "cannot fork interrupted-pipe probe: $!\n"
            unless defined $probe_pid;
        if ($probe_pid == 0) {
            close $result_reader;
            setpgid(0, 0) or _exit(91);
            run_probe($case, $result_writer);
        }
        close $result_writer;
        eval { setpgid($probe_pid, $probe_pid); 1 };
        push @active_groups, $probe_pid;

        my ($finished, $status) = wait_until_exit(
            $probe_pid, $WATCHDOG_SECONDS,
        );
        ok($finished, "$case->{name} returns inside the outer watchdog");
        if (!$finished) {
            terminate_group($probe_pid);
            reap_exactly($probe_pid);
        }
        my $record = read_record($result_reader);
        close $result_reader;
        is($record, 'S', "$case->{name} keeps exact deadline authority");
        ok(!$finished || (($status & 127) == 0 && ($status >> 8) == 0),
            "$case->{name} probe exits cleanly");
        ok(!kill(0, -$probe_pid),
            "$case->{name} leaves no process-group residue");

        terminate_group($probe_pid);
        pop @active_groups;
    };
}

sub run_probe {
    my ($case, $result_writer) = @_;
    my ($containment_reader, $containment_writer);
    pipe($containment_reader, $containment_writer)
        or _exit(92);
    my $flags = fcntl($containment_reader, F_GETFL, 0);
    _exit(93) unless defined($flags)
        && fcntl($containment_reader, F_SETFL, $flags | O_NONBLOCK);

    my $holder_pid;
    if ($case->{use_holder}) {
        $holder_pid = fork();
        _exit(94) unless defined $holder_pid;
        if ($holder_pid == 0) {
            close $result_writer;
            close $containment_reader;
            sleep 30;
            close $containment_writer;
            _exit(0);
        }
        close $containment_writer;
    }

    my $holder_calls = 0;
    my ($error, $elapsed);
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::ProcessSupervisor::_containment_pipe_holders = sub {
                $holder_calls++;
                return defined($holder_pid) ? [$holder_pid] : [];
            };
        $TARGET_READ_FD = fileno($containment_reader);
        $INTERRUPT_FROM_CALL = $case->{interrupt_from_call};
        $TARGET_READ_CALLS = 0;
        my $started = clock_gettime(CLOCK_MONOTONIC);
        eval {
            $terminate_holders->(
                $containment_reader,
                'injected-containment-identity',
                $started + $case->{cleanup_seconds},
            );
            1;
        } or $error = $@;
        $elapsed = clock_gettime(CLOCK_MONOTONIC) - $started;
        $TARGET_READ_FD = undef;
        $INTERRUPT_FROM_CALL = undef;
    }

    close $containment_reader;
    close $containment_writer unless $case->{use_holder};
    my $holder_ok = 1;
    if (defined $holder_pid) {
        my ($reaped, $status) = wait_until_exit($holder_pid, 1);
        if (!$reaped) {
            kill 'KILL', $holder_pid;
            reap_exactly($holder_pid);
        }
        $holder_ok = $reaped && (($status & 127) == 9);
    }

    my $passed = defined($error)
        && $error eq
            "selected-tool containment pipe observation exceeded its deadline\n"
        && $TARGET_READ_CALLS > $case->{interrupt_from_call}
        && $holder_calls == $case->{expected_holder_calls}
        && $elapsed >= $case->{minimum_elapsed}
        && $elapsed < $case->{maximum_elapsed}
        && $holder_ok;
    syswrite($result_writer, $passed ? 'S' : 'F', 1);
    close $result_writer;
    _exit($passed ? 0 : 95);
}

sub read_record {
    my ($reader) = @_;
    my $record = '';
    while (1) {
        my $read = sysread($reader, $record, 1);
        next if !defined($read) && $! == EINTR;
        last;
    }
    return $record;
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
