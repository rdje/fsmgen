#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EIO);
use POSIX qw(SIG_UNBLOCK SIG_SETMASK SIGUSR1);
use Scalar::Util qw(refaddr);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $class = 'FSM::Support::ProcessSupervisor::Coordinator';
my $reservation = 'FSM::Support::ProcessSupervisor::Reservation';
my (@owners, @pipes, $owner, $calls, $checks, $fail_at, $cancel_at, $expire_at, $signal_at, $clock_ns);
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined(fileno($_)) } @pipes }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
sub reset_observers {
    die 'previous native preparation is not closed' if live();
    @pipes = (); $calls = $checks = 0;
    $fail_at = $cancel_at = $expire_at = $signal_at = 0; $clock_ns = undef;
}
sub create {
    my $s = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', 'die "preparation cannot execute"'], cwd => '.',
        schema => 'private.coordinator.preparation.v1', stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 15, capture_limit_bytes => 64},
    }, FSM::Support::ProcessSupervisor::Admission::_now_ns());
    my $o = FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot => $s);
    push @owners, $o; $o->open_run; return $o;
}
sub close_owner {
    my ($o) = @_;
    my $first = $o->observation->{failure};
    ok($o->close->{ok}, 'original owner closes native preparation and endpoint');
    is($o->observation->{phase}, 'closed', 'resources close before root retirement');
    is($o->observation->{usage}{charged_descriptors}, 0, 'all descriptor charges settle');
    is($o->observation->{usage}{charged_children}, 0, 'unused child reservations settle');
    is($o->observation->{usage}{jobs}, 0, 'root outcome retires only after closure');
    ok(!live(), 'independent native observer sees every actual pipe end closed');
    is($o->observation->{failure}, $first, 'cleanup preserves the first preparation cause');
}
END {
    local $?;
    for my $o (@owners) {
        next if $o->{phase} eq 'closed';
        die 'preparation fixture endpoint cleanup failed' unless $o->close->{ok};
    }
    my @remaining = live();
    diag('independent preparation observer rescues remaining pipe ends') if @remaining;
    close $_ or die 'independent pipe rescue failed' for @remaining;
}

my $pipe = $reservation->can('_pipe');
my $check = $class->can('_before_job_allocation');
my $now = FSM::Support::ProcessSupervisor::Admission->can('_now_ns');
my $native_now = $reservation->can('_now');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_now = sub { defined($clock_ns) ? $clock_ns / 1e9 : $native_now->() };
local *FSM::Support::ProcessSupervisor::Admission::_now_ns = sub { $clock_ns // $now->() };
local *FSM::Support::ProcessSupervisor::Coordinator::_now_ns = sub { $clock_ns // $now->() };
local *FSM::Support::ProcessSupervisor::Coordinator::_before_job_allocation = sub {
    my ($self, $grant) = @_;
    ++$checks;
    $self->{ledger}->cancel($grant) if $cancel_at && $checks == $cancel_at;
    $clock_ns = $self->{ledger}->describe($grant)->{deadline_ns}
        if $expire_at && $checks == $expire_at;
    $check->(@_);
};
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    ++$calls;
    die 'native pipe lacks fresh original admission' unless $checks == $calls;
    my $entry = $owner->{jobs}{1};
    die 'native graph is not retained before allocation' unless $entry->{native}
        && $entry->{native}->observation->{phase} eq 'allocating';
    my $view = $owner->job_observation($entry->{grant})->{admission};
    die 'native pipe lacks original peak credit' unless $view->{phase} eq 'preparing'
        && $view->{reserved_descriptors} == 16 && $view->{reserved_children} == 2;
    die 'aggregate native effect exceeds capacity' if $owner->observation->{usage}{charged_descriptors} > 128;
    if ($fail_at && $calls == $fail_at) { $! = EIO; return 0; }
    my $ok = $pipe->(@_); push @pipes, ${$_[0]}, ${$_[1]} if $ok;
    CORE::kill('USR1', $$) == 1 or die 'cannot queue creator signal'
        if $signal_at && $calls == $signal_at;
    return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { die 'preparation must not fork' };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { die 'preparation must not fork' };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { die 'preparation must not wait' };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { die 'preparation must not wait' };
local *FSM::Support::ProcessSupervisor::Reservation::_signal = sub { die 'preparation must not signal children' };
local *FSM::Support::ProcessSupervisor::GatedPair::_signal = sub { die 'preparation must not signal children' };
use warnings 'redefine';

subtest 'original retained root preparation reconciles actual native handles' => sub {
    reset_observers(); my $before = census(); $owner = create(); my $grant = $owner->root;
    my $run_handles = $owner->handles;
    $owner->prepare_job($grant);
    is($calls, 8, 'every actual command and reservation pipe has admission');
    is(scalar(live()), 15, 'independent observer counts actual prepared ends');
    my $entry = $owner->{jobs}{1};
    ok(!exists($entry->{snapshot}), 'native graph takes snapshot custody without retaining a second copy');
    is_deeply([sort map { refaddr($_) } @{$entry->{native}{pair}{close_handles}}],
        [sort map { refaddr($_) } @$run_handles], 'prepared job borrows the complete current foreign run inventory');
    is_deeply([sort { $a <=> $b } map { fileno($_) } @{$owner->handles}],
        [sort { $a <=> $b } map { fileno($_) } (@$run_handles, live())], 'aggregate inventory contains every native handle exactly once');
    is_deeply($owner->observation->{usage}, {jobs => 1, children => 0, descriptors => 17,
        reserved_children => 2, reserved_descriptors => 2, charged_children => 2, charged_descriptors => 19},
        'actual preparation replaces only job descriptor credit; future children and cleanup remain reserved');
    my $view = $owner->job_observation($grant);
    is($view->{admission}{phase}, 'prepared', 'ledger publication follows actual allocation');
    is($view->{native}{phase}, 'prepared', 'original native job is prepared without starting');
    $view->{admission}{descriptors} = 0;
    is($owner->job_observation($grant)->{admission}{descriptors}, 15, 'copied observation cannot release resources');
    like(error_from(sub { $owner->prepare_job($grant) }), qr/single-use/, 'root allocation cannot replay');
    close_owner($owner); is_deeply(census(), $before, 'exact endpoint census returns to predecessor');
};

subtest 'copied grants, cancellation and inclusive expiry reject before effects' => sub {
    reset_observers(); $owner = create(); my $grant = $owner->root;
    my $copy = bless {}, ref($grant);
    like(error_from(sub { $owner->prepare_job($copy) }), qr/foreign, copied or retired/, 'copied root grant cannot allocate');
    is($calls, 0, 'copied grant reaches no native pipe'); close_owner($owner);
    for my $mode (qw(cancel expire)) {
        for my $cut (1 .. 8) {
            reset_observers(); $owner = create();
            $cancel_at = $mode eq 'cancel' ? $cut : 0; $expire_at = $mode eq 'expire' ? $cut : 0;
            like(error_from(sub { $owner->prepare_job($owner->root) }), qr/admission revoked|deadline expired/,
                "$mode rejects at original pipe boundary $cut");
            is($calls, $cut - 1, 'no native pipe follows the rejected original check');
            is($owner->observation->{usage}{charged_descriptors}, 20, 'interrupted allocation keeps original conservative peak until cleanup');
            is($owner->job_observation($owner->root)->{admission}{phase}, 'closing', 'failure revokes admission before cleanup');
            close_owner($owner);
        }
    }
    reset_observers();
};

subtest 'each native allocation failure preserves original ownership and cause' => sub {
    for my $cut (1 .. 8) {
        reset_observers(); $owner = create(); $fail_at = $cut;
        like(error_from(sub { $owner->prepare_job($owner->root) }), qr/cannot (?:allocate|create)/, "actual pipe failure $cut propagates");
        is($calls, $cut, 'no later pipe follows native failure');
        ok($owner->{jobs}{1}{native}, 'original native graph remains reachable after failure');
        is($owner->observation->{usage}{charged_descriptors}, 20, 'partial failure retains peak charges until consumed');
        close_owner($owner);
    }
};

subtest 'pending creator interruption sees reconciled native ownership before return' => sub {
    for my $cut (1, 6, 8) {
        reset_observers(); $owner = create(); $signal_at = $cut;
        my ($view, $usage, $handles);
        local $SIG{USR1} = sub {
            $view = $owner->job_observation($owner->root); $usage = $owner->observation->{usage};
            $handles = scalar(live()); die "interrupted original preparation return\n";
        };
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select original fixture mask';
        my $error = error_from(sub { $owner->prepare_job($owner->root) });
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore original fixture mask';
        like($error, qr/interrupted original preparation return/, 'actual pending creator signal interrupts return');
        is($view->{admission}{phase}, 'prepared', 'handler sees ledger prepared before restoration');
        is($view->{native}{phase}, 'prepared', 'handler sees original native owner prepared');
        is($handles, 15, 'handler observes actual retained pipe ownership');
        is($usage->{charged_descriptors}, 19, 'handler observes reconciled descriptor credit');
        is($owner->observation->{phase}, 'failed', 'interrupted return cannot publish context');
        is($owner->job_observation($owner->root)->{admission}{phase}, 'closing', 'interrupted return revokes future start');
        close_owner($owner);
    }
};

subtest 'incomplete native closure cannot release a prepared root' => sub {
    reset_observers(); $owner = create(); $owner->prepare_job($owner->root);
    my $finished = FSM::Support::ProcessSupervisor::ReservedJob->can('finished_job');
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::ReservedJob::finished_job = sub {
            my $result = $finished->(@_); return {%$result, resources_closed => 0};
        };
        like(error_from(sub { $owner->close }), qr/native job cleanup incomplete/,
            'a producer reporting incomplete closure prevents retirement');
    }
    ok(!live(), 'actual pipe ends are closed even though completion was refused');
    is($owner->observation->{phase}, 'close_failed', 'owner retains incomplete native closure');
    is($owner->observation->{usage}{charged_descriptors}, 19, 'no credit is released from closed handles alone');
    is($owner->observation->{usage}{jobs}, 1, 'original root slot remains retained');
    is(scalar @{$owner->{run}->handles}, 2, 'endpoint remains owned until native cleanup settles');
    close_owner($owner);
};

subtest 'admitted peak remains usable at exact aggregate capacity' => sub {
    reset_observers(); $owner = create();
    $owner->{ledger}->reserve_descriptors(108); # outstanding valid credit, no fabricated handle
    is($owner->observation->{usage}{charged_descriptors}, 128, 'exact existing aggregate bound is reserved');
    $owner->prepare_job($owner->root);
    is($calls, 8, 'existing job credit permits preparation without reacquisition');
    is($owner->observation->{usage}{charged_descriptors}, 127, 'actual reconciliation releases only the unused pipe-end allowance');
    like(error_from(sub { $owner->{ledger}->reserve_descriptors(2) }), qr/capacity exhausted/, 'excess outstanding credit still rejects');
    close_owner($owner);
};

done_testing;
