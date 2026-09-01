#!/usr/bin/env perl

use strict;
use warnings;

use Errno qw(EINTR);
use File::Spec;
use FindBin;
use POSIX qw(WNOHANG _exit setpgid);
use Scalar::Util qw(blessed);
use Test::More;
use Time::HiRes qw(clock_gettime sleep CLOCK_MONOTONIC);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::ProcessSupervisor;

my $capture = \&FSM::VIAL::Backend::ProcessSupervisor::_capture;
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $WATCHDOG_SECONDS = 5;
my @active_groups;

END {
    terminate_group($_) for @active_groups;
}

my @cases = (
    {
        name => 'live-stream observation expiry keeps timeout primary',
        command => [$^X, '-e', 'sleep 30'],
        trigger_call => 1,
        expire => 1,
        expected => 'T',
    },
    {
        name => 'post-EOF observation expiry keeps timeout primary',
        command => [
            $^X, '-e', 'close STDOUT; close STDERR; sleep 30',
        ],
        trigger_call => 2,
        expire => 1,
        expected => 'T',
    },
    {
        name => 'early observation failure remains a host error',
        command => [$^X, '-e', 'sleep 30'],
        trigger_call => 1,
        expire => 0,
        expected => 'H',
    },
);

for my $case (@cases) {
    run_case($case);
}

done_testing();

sub run_case {
    my ($case) = @_;
    subtest $case->{name} => sub {
        my ($reader, $writer);
        pipe($reader, $writer)
            or die "cannot create observation-timeout result pipe: $!\n";
        my $probe_pid = fork();
        die "cannot fork observation-timeout probe: $!\n"
            unless defined $probe_pid;
        if ($probe_pid == 0) {
            close $reader;
            setpgid(0, 0) or _exit(91);
            my $observation_calls = 0;
            my ($result, $error);
            {
                no warnings 'redefine';
                local *FSM::VIAL::Backend::ProcessSupervisor::_observe_selected_tool_descendants = sub {
                        my $deadline = $_[2];
                        $observation_calls++;
                        return if $observation_calls < $case->{trigger_call};
                        if ($case->{expire}) {
                            my $remaining = $deadline
                                - clock_gettime(CLOCK_MONOTONIC) + 0.05;
                            sleep($remaining) if $remaining > 0;
                        }
                        die "injected selected-tool observation failure\n";
                    };
                eval {
                    $result = $capture->(
                        $repo_root,
                        $case->{command},
                        {
                            schema =>
                                'fsmgen.vial_process_supervisor_policy.v1',
                            schema_version => 1,
                            containment => 'outer_worker_process_group',
                            timeout_seconds => 1,
                            capture_limit_bytes => 65_536,
                        },
                    );
                    1;
                } or $error = $@;
            }
            my $record = ref($result) eq 'HASH' && $result->{timed_out}
                ? 'T'
                : blessed($error)
                    && $error->isa(
                        'FSM::VIAL::Backend::ProcessSupervisor::Failure',
                    )
                    && ($error->{code} // '') eq 'VIAL_PROCESS_HOST_ERROR'
                ? 'H'
                : 'F';
            $record = 'F'
                unless $observation_calls == $case->{trigger_call};
            syswrite($writer, $record, 1);
            close $writer;
            _exit($record eq 'F' ? 92 : 0);
        }
        close $writer;
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
        my $record = '';
        sysread($reader, $record, 1);
        close $reader;
        is($record, $case->{expected},
            "$case->{name} has the exact result precedence");
        ok(!$finished || (($status & 127) == 0 && ($status >> 8) == 0),
            "$case->{name} probe exits cleanly");
        ok(!kill(0, -$probe_pid),
            "$case->{name} leaves no process-group residue");

        terminate_group($probe_pid);
        pop @active_groups;
    };
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
