#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(getcwd);
use POSIX qw(SIG_BLOCK SIG_SETMASK SIG_UNBLOCK SIGUSR1);
use Scalar::Util qw(weaken);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Endpoint ();

my $class = 'FSM::Support::ProcessSupervisor::Endpoint';
my (@runs, @observed, @live_counts);
my $root = repository_root();
sub run {
    my $run = FSM::Support::ProcessSupervisor::Endpoint::prepare_run();
    push @runs, $run;
    return $run;
}
sub native_live { return grep { defined($_) && defined(fileno($_)) } @observed }
sub observe {
    # Weak observers do not prolong local entropy/cwd/iterator handles when
    # an exception unwinds their owning scope. Census happens while native
    # owners are still alive, before any convenience-constructor return.
    push @observed, $_[0]; weaken($observed[-1]);
    my %fds = map { fileno($_) => 1 } native_live();
    push @live_counts, scalar keys %fds;
}
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub census { return [sort glob "$root/.artifacts/tmp/process-coordinator/*"] }
sub close_run {
    my ($run) = @_;
    my $closed = $run->close;
    ok($closed->{ok}, 'retained owner closes its exact endpoint');
    ok(!defined($run->{directory}) || !-e "$root/$run->{directory}", 'owned path is independently absent');
    is(scalar(@{$run->handles}), 0, 'retained inventory is empty after closure');
}
END {
    local $?;
    for my $run (@runs) {
        next if $run->{closed};
        my $closed = $run->close;
        die 'retained endpoint rescue failed' unless $closed->{ok};
    }
}
my $seal = $class->can('_seal_handle');
my $entries = $class->can('_open_entries');
my ($fail_at, $signal_at, $seals, $pending, $retained);
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Endpoint::_seal_handle = sub {
    ++$seals;
    observe($_[0]);
    die "injected sealing failure\n" if $fail_at && $seals == $fail_at;
    my $result = $seal->(@_);
    if ($signal_at && $seals == $signal_at) {
        die 'native owner was not retained before allocation' unless $retained
            && $retained->observation->{phase} eq 'starting';
        $pending = 1;
        CORE::kill('USR1', $$) == 1 or die 'cannot queue actual creator signal';
    }
    return $result;
};
local *FSM::Support::ProcessSupervisor::Endpoint::_open_entries = sub {
    my $result = $entries->(@_);
    observe(${$_[0]}) if $result;
    return $result;
};
use warnings 'redefine';
sub reset_observers { @observed = (); @live_counts = (); $seals = 0; $fail_at = 0; $signal_at = 0; }

subtest 'preparation is resource-free and construction has an independently observed peak' => sub {
    reset_observers(); my $before = census(); my $r = run();
    is_deeply(census(), $before, 'preparation creates no path');
    is($seals, 0, 'preparation allocates no entropy, anchor or socket handle');
    is_deeply($r->handles, [], 'resource-free owner has no descriptors');
    like(error_from(sub { $r->context }), qr/not ready/, 'prepared owner cannot publish authority');
    like(error_from(sub { $r->listener }), qr/not ready/, 'prepared owner cannot publish listener');
    $r->start_run;
    is($r->observation->{phase}, 'ready', 'one start reaches ready');
    is(scalar(@{$r->handles}), 2, 'steady owner retains socket and directory anchor');
    my $peak = (sort { $b <=> $a } @live_counts)[0];
    is($peak, 4, 'native census observes two steady and two transient descriptors together');
    is_deeply($class->resource_cost, {descriptors => $peak, steady_descriptors => 2, transient_descriptors => 2},
        'declared cost covers the independent observed peak and cleanup scratch');
    like(error_from(sub { $r->start_run }), qr/single-use/, 'a started owner cannot allocate another run');
    @live_counts = ();
    close_run($r);
    is((sort { $b <=> $a } @live_counts)[0], 3,
        'cleanup uses two transient descriptors beside the remaining directory anchor');
    is(scalar(native_live()), 0, 'every observed handle is closed or its owning scope has released it');
    is_deeply(census(), $before, 'full endpoint census returns to its predecessor');
};

subtest 'cancellation before effects and changed creator state reject before allocation' => sub {
    reset_observers(); my $r = run(); close_run($r);
    like(error_from(sub { $r->start_run }), qr/closed/, 'closed prepared run cannot start');
    is($seals, 0, 'pre-start cancellation consumes no descriptors');
    $r = run();
    { local $r->{owner_pid} = $$ + 1;
      like(error_from(sub { $r->start_run }), qr/inherited/, 'inherited-owner model rejects before native work'); }
    { local $SIG{CHLD} = 'IGNORE';
      like(error_from(sub { $r->start_run }), qr/default child-reaping/, 'start rechecks reaper disposition after preparation'); }
    is($seals, 0, 'invalid owner and reaper allocate nothing'); close_run($r);
};

subtest 'each descriptor sealing failure retains first failure and complete cleanup' => sub {
    for my $cut (1 .. 6) {
        reset_observers(); $fail_at = $cut;
        my $before = census(); my $cwd = getcwd(); my $r = run();
        like(error_from(sub { $r->start_run }), qr/injected sealing failure/, "sealing cut $cut fails");
        like($r->observation->{failure}, qr/injected sealing failure/, 'original failure remains on retained owner');
        ok($r->observation->{cleanup}{ok}, 'partial construction records successful cleanup');
        is_deeply(census(), $before, 'failed construction leaves no new endpoint path');
        is(getcwd(), $cwd, 'failed construction preserves caller directory');
        is(scalar(native_live()), 0, 'no observed live handle survives failed construction');
        $r->observation->{cleanup}{ok} = 0;
        ok($r->observation->{cleanup}{ok}, 'observation copies cannot alter cleanup evidence');
    }
    reset_observers();
};

subtest 'actual pending signals cannot strand successful construction at return' => sub {
    for my $cut (1, 5, 6) {
        reset_observers(); $signal_at = $cut; $pending = 0;
        my $before = census(); $retained = run();
        my ($handler_phase, $handler_handles);
        local $SIG{USR1} = sub {
            die 'unexpected fixture signal' unless $pending;
            $handler_phase = $retained->observation->{phase};
            $handler_handles = scalar @{$retained->handles};
            die "injected pending creator signal\n";
        };
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old)
            or die 'cannot select fixture signal mask';
        my $error = error_from(sub { $retained->start_run });
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore fixture signal mask';
        like($error, qr/injected pending creator signal/, "real queued signal interrupts cut $cut return");
        is($handler_phase, 'ready', 'handler runs only after construction effects are published');
        is($handler_handles, 2, 'handler sees both original retained live descriptors');
        is($retained->observation->{phase}, 'failed', 'interrupted start cannot publish an apparently ready context');
        close_run($retained);
        is_deeply(census(), $before, 'retained cleanup removes interrupted endpoint exactly');
        is(scalar(native_live()), 0, 'interrupted return retains no live handle after cleanup');
    }
    reset_observers();
};

subtest 'convenience construction still cleans up an interrupted return' => sub {
    reset_observers(); my $before = census();
    my $mask = $class->can('_mask'); my $restores = 0;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::_mask = sub {
            my $result = $mask->(@_);
            die "injected restored constructor return\n" if $_[0] == SIG_SETMASK && ++$restores == 1;
            return $result;
        };
        like(error_from(sub { FSM::Support::ProcessSupervisor::Endpoint::create_run() }),
            qr/injected restored constructor return/, 'constructor propagates interruption after actual mask restoration');
    }
    is_deeply(census(), $before, 'constructor unwinds endpoint before losing its local owner');
    is(scalar(native_live()), 0, 'constructor unwinds its live descriptors');
};

done_testing;
