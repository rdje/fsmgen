#!/usr/bin/env perl
use strict;
use warnings;

use Errno qw(ECHILD);
use Fcntl qw(F_GETFD FD_CLOEXEC);
use IO::Select;
use POSIX qw(WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Service ();
use FSM::Support::ProcessSupervisor::ReservedJob ();

my $creator = $$;
my (%births, @sealed, @pipes, @clients, @services, @runs);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1e9) }
sub live { grep { defined(fileno($_)) } @_ }
sub descriptors { [sort { $a <=> $b } map { fileno($_) } live(@_)] }
sub references { [sort { $a <=> $b } map { refaddr($_) } live(@_)] }

sub rescue {
    for my $pid (sort { $a <=> $b } keys %births) {
        next if $births{$pid};
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid || ($w == -1 && $! == ECHILD)) { $births{$pid} = 1; next; }
        die 'descriptor fixture lost direct-child ownership' unless $w == 0;
        CORE::kill('KILL', $pid);
        my $end = now() + 2;
        while (now() < $end) {
            $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid) { $births{$pid} = 1; last; }
            die 'descriptor fixture lost exact rescue wait' if $w == -1;
            sleep(0.001);
        }
        die 'descriptor fixture rescue deadline expired' unless $births{$pid};
    }
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        my $needed = grep { !$_ } values %births;
        rescue();
        diag('independent descriptor-fixture rescue consumed every direct child') if $needed;
        for my $object (grep { !$_->{closed} } (@clients, @services, @runs)) {
            my $closed = $object->close;
            die 'independent descriptor-fixture endpoint cleanup failed' unless $closed->{ok};
        }
        die 'independent descriptor-fixture endpoint residue'
            if grep { -e repository_root() . '/' . $_->{directory} } @runs;
        close $_ for live(@pipes, @sealed);
    }
}

# Retain actual allocation handles, including temporary ones, independently of
# each component's inventory. Closed references remain here to detect omissions
# and duplication without a process-wide or off-volume descriptor census.
my $seal = FSM::Support::ProcessSupervisor::Endpoint->can('_seal_handle');
my $pipe = FSM::Support::ProcessSupervisor::Reservation->can('_pipe');
my $rfork = FSM::Support::ProcessSupervisor::Reservation->can('_fork');
my $cfork = FSM::Support::ProcessSupervisor::GatedPair->can('_fork');
my $rwait = FSM::Support::ProcessSupervisor::Reservation->can('_wait');
my $cwait = FSM::Support::ProcessSupervisor::GatedPair->can('_wait');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Endpoint::_seal_handle = sub {
    push @sealed, $_[0]; return $seal->(@_);
};
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    my $ok = $pipe->(@_);
    push @pipes, ${$_[0]}, ${$_[1]} if $ok;
    return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub {
    my $pid = $rfork->(); $births{$pid} = 0 if defined($pid) && $pid > 0; return $pid;
};
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub {
    my $pid = $cfork->(); $births{$pid} = 0 if defined($pid) && $pid > 0; return $pid;
};
my $wait = sub {
    my ($native, $pid) = @_;
    die 'engine waited for an unrecorded child' unless exists $births{$pid};
    my $w = $native->($pid); $births{$pid} = 1 if $w == $pid; return $w;
};
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait, @_) };
use warnings 'redefine';

sub prepare_job {
    my ($foreign) = @_;
    my $snapshot = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', 'print "inventory-proof"'], cwd => '.',
        schema => 'private.descriptor.fixture.v1', stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 15, capture_limit_bytes => 64},
    }, ns(now()));
    return FSM::Support::ProcessSupervisor::ReservedJob::prepare(
        snapshot => $snapshot, deadline => $snapshot->{started_ns} / 1e9 + 15,
        close_handles => $foreign);
}
sub drive {
    my ($job, $phase) = @_;
    my $end = now() + 5;
    while (now() < $end) {
        return if $job->observation->{phase} eq $phase;
        die 'job finished before the required inventory cut' if $job->observation->{phase} eq 'finished';
        $job->advance;
        sleep(0.001);
    }
    die 'descriptor lifecycle observer deadline expired';
}
sub check_inventory {
    my ($object, $expected, $label) = @_;
    my $handles = $object->handles;
    is_deeply(descriptors(@$handles), descriptors(@$expected), "$label contains every actual owned live descriptor once");
    is_deeply(references(@$handles), references(@$expected), "$label borrows original handles without duplication");
    my $count = @pipes + @sealed;
    $object->handles;
    is(@pipes + @sealed, $count, "$label inspection allocates no private pipe or sealed descriptor");
    ok(!grep(!(fcntl($_, F_GETFD, 0) & FD_CLOEXEC), @$handles), "$label retains native close-on-exec sealing");
}

local $SIG{ALRM} = sub { die "private descriptor test deadline\n" };
alarm 30;
my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run();
push @runs, $run;
my @run_handles = live(@sealed);
check_inventory($run, \@run_handles, 'run');
ok(grep(-d $_, @{$run->handles}), 'run inventory includes the actual directory anchor');
my $directory = $run->{directory};
my $service = FSM::Support::ProcessSupervisor::Service::new_service($run, ns(now() + 20));
push @services, $service;
my $client = FSM::Support::ProcessSupervisor::Endpoint::connect_context($service->context);
push @clients, $client;
check_inventory($client, [$client->handle], 'client');
my $end = now() + 2;
while (now() < $end && !$service->counts->{open}) { $service->advance; sleep(0.001); }
is($service->counts->{open}, 1, 'one native connection is accepted');
my @server_handles = grep { refaddr($_) != refaddr($client->handle) } live(@sealed);
check_inventory($service, \@server_handles, 'service with an accepted peer');

my $idle = prepare_job([]);
my @idle_handles = live(@pipes);
check_inventory($idle, \@idle_handles, 'prepared idle job');
my @foreign = (@server_handles, $client->handle, @idle_handles);
my @passed = (@{$service->handles}, @{$client->handles}, @{$idle->handles});
my $before = scalar @pipes;
my $job = prepare_job(\@passed);
my @job_handles = @pipes[$before .. $#pipes];
check_inventory($job, \@job_handles, 'prepared command job excludes its borrowed close list');

{
    # Both real child roles check independently retained foreign references
    # after closing them and before acknowledging any group handoff. Missing
    # inventory entries cannot hide behind CLOEXEC later closing the leak.
    my $byte = FSM::Support::ProcessSupervisor::Reservation->can('_child_byte');
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::Reservation::_child_byte = sub {
        _exit(91) if live(@foreign);
        for my $inherited ($run, $client, $service, $idle, $job) {
            my $ok = eval { $inherited->handles; 1 };
            _exit(92) if $ok;
        }
        return $byte->(@_);
    };
    $job->start;
    drive($job, 'ready');
}
pass('both native children close the full independent foreign inventory before acknowledging');
check_inventory($job, \@job_handles, 'ready job includes transferred capture');
check_inventory($service, \@server_handles, 'child closure preserves parent service ownership');
check_inventory($idle, \@idle_handles, 'child closure preserves parent idle job ownership');
ok(exists($job->{received}{stdout}) && !exists($job->{pair}{stdout}), 'actual capture transfer changes the owner');

$job->release;
drive($job, 'finished');
is($job->finished_job->{result}{stdout}, 'inventory-proof', 'real command executes after inventory qualification');
ok($job->finished_job->{resources_closed}, 'real command and reservation close exactly');
ok(!grep(!$_, values %births), 'independent native waits are all consumed before rescue');
check_inventory($job, [], 'finished job');
ok(!live(@job_handles), 'independent command handles are all actually closed');
$idle->cancel('unused inventory fixture', now() + 4);
drive($idle, 'finished');
check_inventory($idle, [], 'cancelled prepared job');
ok(!live(@idle_handles), 'unused job closes every independently retained allocation');

$client->close;
check_inventory($client, [], 'closed client');
$end = now() + 2;
while (now() < $end && $service->counts->{open}) { $service->advance; sleep(0.001); }
is($service->counts->{connections}, 1, 'unconsumed closed peer outcome retains its connection slot');
is($service->counts->{open}, 0, 'peer EOF closes the actual accepted socket');
check_inventory($service, \@run_handles, 'closed peer outcome owns no socket');
my $closed = $service->take_closed;
is($closed->{status}, 'peer_closed', 'exact peer outcome is consumed');
my $cleanup = $service->close;
ok($cleanup->{ok}, 'service closes its endpoint after all child outcomes');
ok(!-e repository_root() . '/' . $directory, 'independent exact endpoint path is absent');
check_inventory($service, [], 'closed service');
check_inventory($run, [], 'closed run');
ok(!live(@sealed, @pipes), 'no observed fixture descriptor survives normal closure');
alarm 0;
done_testing();
