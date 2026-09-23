#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EIO);
use POSIX qw(SIG_BLOCK SIG_SETMASK SIG_UNBLOCK SIGUSR1);
use Scalar::Util qw(refaddr);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::ReservedJob ();

my (@jobs, @handles, $retained, $calls, $fail_at, $signal_at);
my $reservation = 'FSM::Support::ProcessSupervisor::Reservation';
my $pair = 'FSM::Support::ProcessSupervisor::GatedPair';
my $job = 'FSM::Support::ProcessSupervisor::ReservedJob';
sub now { FSM::Support::ProcessSupervisor::Reservation::_now() }
sub snapshot {
    return FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', 'die "preparation must never execute"'], cwd => '.',
        schema => 'private.preparation.fixture.v1', stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 15, capture_limit_bytes => 64},
    }, sprintf('%.0f', now() * 1e9));
}
sub record {
    my ($foreign) = @_;
    my $s = snapshot();
    my $j = FSM::Support::ProcessSupervisor::ReservedJob::prepare_record(
        snapshot => $s, deadline => $s->{started_ns} / 1e9 + 15, close_handles => $foreign // []);
    push @jobs, $j; return $j;
}
sub rescue_handles {
    my @open = grep { defined(fileno($_)) } @handles;
    diag('independent preparation observer closes remaining native handles') if @open;
    close $_ or die 'preparation observer handle rescue failed' for @open;
}
sub reset_observers {
    rescue_handles();
    @handles = (); $calls = 0; $fail_at = 0; $signal_at = 0; $retained = undef;
}
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub closed {
    my ($j) = @_;
    $j->cancel('fixture closes retained preparation', now() + 0.5);
    my $wall = now() + 0.5;
    $j->advance while $j->observation->{phase} ne 'finished' && now() < $wall;
    is($j->observation->{phase}, 'finished', 'unstarted retained job completes bounded cleanup');
    ok($j->finished_job->{resources_closed}, 'no child or group exists to leave unproved');
    ok(!grep(defined(fileno($_)), @handles), 'every independently retained actual pipe handle is closed');
}
END {
    local $?;
    for my $j (@jobs) {
        next if $j->{pair}->observation->{retired};
        $j->{pair}->retire(now());
    }
    rescue_handles();
}

my $pipe = $reservation->can('_pipe');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    ++$calls;
    if ($retained) {
        die 'retained job missing before allocation' unless $retained->{state}{phase} eq 'allocating';
        die 'retained pair missing before allocation' unless ref($retained->{pair}) eq $pair;
        die 'retained reservation missing before allocation'
            unless ref($retained->{pair}->reservation) eq $reservation;
    }
    if ($fail_at && $calls == $fail_at) { $! = EIO; return 0; }
    my $ok = $pipe->(@_);
    push @handles, ${$_[0]}, ${$_[1]} if $ok;
    CORE::kill('USR1', $$) == 1 or die 'cannot queue fixture signal'
        if $signal_at && $calls == $signal_at;
    return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { die 'native fork forbidden in preparation test' };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { die 'native fork forbidden in preparation test' };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { die 'native wait forbidden in preparation test' };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { die 'native wait forbidden in preparation test' };
local *FSM::Support::ProcessSupervisor::Reservation::_signal = sub { die 'native child signal forbidden in preparation test' };
local *FSM::Support::ProcessSupervisor::GatedPair::_signal = sub { die 'native child signal forbidden in preparation test' };
use warnings 'redefine';

subtest 'complete ownership graph precedes native effects and preparation is single-use' => sub {
    reset_observers(); $retained = record();
    my ($p, $r) = ($retained->{pair}, $retained->{pair}->reservation);
    is_deeply([map { $_->observation->{phase} } ($retained, $p, $r)],
        [('unallocated') x 3], 'all original records are observable before descriptors exist');
    $retained->advance; $p->advance; $r->advance;
    is($calls, 0, 'advancement cannot allocate a resource-free record');
    is_deeply($retained->handles, [], 'initial owned inventory is empty');
    like(error_from(sub { $retained->start }), qr/retained prepared job/, 'unallocated job cannot start');
    $retained->allocate;
    is($calls, 8, 'independent native observer sees exactly the selected pipe pairs');
    is(refaddr($retained->{pair}), refaddr($p), 'allocation retains the original pair');
    is(refaddr($retained->{pair}->reservation), refaddr($r), 'allocation retains the original reservation');
    is(scalar @{$retained->handles}, 15, 'prepared owner holds actual open ends after stdin-writer closure');
    like(error_from(sub { $retained->allocate }), qr/unallocated job/, 'job allocation cannot replay');
    like(error_from(sub { $p->allocate }), qr/unallocated pair/, 'pair allocation cannot replay');
    like(error_from(sub { $r->allocate([]) }), qr/unallocated retained reservation/, 'reservation allocation cannot replay');
    closed($retained);
    reset_observers(); $retained = record(); closed($retained);
    is($calls, 0, 'cancellation before allocation consumes no descriptors or forks');
};

subtest 'failed allocations preserve first cause and remain reachable for cleanup' => sub {
    for my $cut (1 .. 8) {
        reset_observers(); $retained = record(); $fail_at = $cut;
        like(error_from(sub { $retained->allocate }), qr/(?:allocate command|create reservation).*pipe/,
            "native pipe cut $cut fails");
        is($calls, $cut, 'no later pipe is allocated after failure');
        my $first = $retained->observation->{first_failure};
        is($first->{status}, 'host_error', 'retained job records preparation failure before cleanup');
        closed($retained);
        is_deeply($retained->observation->{first_failure}, $first, 'cancellation cannot replace the original allocation failure');
    }
};

subtest 'original deadline is checked before every pipe and borrowed inventories revalidate' => sub {
    my $clock = $reservation->can('_now');
    for my $cut (0 .. 7) {
        reset_observers(); $retained = record();
        my $deadline = $retained->{state}{deadline};
        {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::Reservation::_now = sub {
                return $calls >= $cut ? $deadline : $clock->();
            };
            like(error_from(sub { $retained->allocate }), qr/deadline expired before allocation/,
                "original wall expires after $cut native pipe allocations");
        }
        is($calls, $cut, 'expiry prevents the next actual allocation');
        closed($retained);
    }
    reset_observers();
    CORE::pipe(my $foreign_read, my $foreign_write) or die 'cannot make borrowed fixture';
    $retained = record([$foreign_read]);
    close $foreign_read or die 'cannot close borrowed fixture';
    like(error_from(sub { $retained->allocate }), qr/closed, standard or duplicate/, 'closed borrowed inventory is revalidated');
    is($calls, 0, 'invalid borrowed handle rejects before any owned allocation');
    ok(defined(fileno($foreign_write)), 'owner failure cannot close a borrowed sibling');
    close $foreign_write or die 'cannot close borrowed sibling'; closed($retained);
};

subtest 'actual pending signals observe the fully retained graph before interrupted return' => sub {
    for my $cut (1, 6, 8) {
        reset_observers(); $retained = record(); $signal_at = $cut;
        my ($phases, $count);
        local $SIG{USR1} = sub {
            $phases = [map { $_->observation->{phase} }
                ($retained, $retained->{pair}, $retained->{pair}->reservation)];
            $count = scalar @{$retained->handles};
            die "injected pending preparation signal\n";
        };
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old)
            or die 'cannot select fixture mask';
        my $error = error_from(sub { $retained->allocate });
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore fixture mask';
        like($error, qr/injected pending preparation signal/, "pending signal interrupts pipe cut $cut return");
        is_deeply($phases, [('prepared') x 3], 'handler sees every level published before restoration');
        is($count, 15, 'handler observes all original prepared native handles');
        is($retained->observation->{phase}, 'preparation_failed', 'interrupted job cannot start');
        like(error_from(sub { $retained->start }), qr/retained prepared job/, 'interrupted preparation rejects launch');
        closed($retained);
    }
};

subtest 'convenience constructors close resources if preparation return is interrupted' => sub {
    my $mask = $reservation->can('_mask');
    for my $kind (qw(reservation pair job)) {
        reset_observers(); my $s = snapshot(); my $depth = 0;
        my $error;
        {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
                my $result = $mask->(@_);
                ++$depth if $_[0] == SIG_BLOCK;
                if ($_[0] == SIG_SETMASK && --$depth == 0) { die "injected outer preparation return\n"; }
                return $result;
            };
            $error = error_from(sub {
                return FSM::Support::ProcessSupervisor::Reservation::prepare(deadline => now() + 10, close_handles => [])
                    if $kind eq 'reservation';
                my %args = (snapshot => $s, deadline => $s->{started_ns} / 1e9 + 15, close_handles => []);
                return FSM::Support::ProcessSupervisor::GatedPair::prepare(%args) if $kind eq 'pair';
                return FSM::Support::ProcessSupervisor::ReservedJob::prepare(%args);
            });
        }
        like($error, qr/injected outer preparation return/, "$kind constructor propagates restored-mask interruption");
        ok(@handles && !grep(defined(fileno($_)), @handles), "$kind constructor closes every observed native handle");
    }
};

done_testing;
