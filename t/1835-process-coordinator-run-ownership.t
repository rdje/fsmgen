#!/usr/bin/env perl
use strict;
use warnings;
use POSIX qw(SIG_UNBLOCK SIG_SETMASK SIGUSR1);
use Scalar::Util qw(refaddr weaken);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $coordinator = 'FSM::Support::ProcessSupervisor::Coordinator';
my $endpoint = 'FSM::Support::ProcessSupervisor::Endpoint';
my $root = repository_root();
my (@owners, @observed, @counts, $owner, $last, $sequence, $used, $expire_operation, $clock_ns, $queue_signal);
my %fixture_cleanup;
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub census { [sort glob "$root/.artifacts/tmp/process-coordinator/*"] }
sub live { grep { defined($_) && defined(fileno($_)) } @observed }
sub prepare {
    my $snapshot = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', 'die "run ownership must not execute"'], cwd => '.',
        schema => 'private.run.fixture.v1', stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 15, capture_limit_bytes => 64},
    }, FSM::Support::ProcessSupervisor::Admission::_now_ns());
    my $o = FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot => $snapshot);
    $snapshot->{argv}[0] = 'changed caller';
    is($o->{jobs}{1}{snapshot}{argv}[0], $^X, 'retained root snapshot is detached from caller mutation');
    push @owners, $o; return $o;
}
sub reset_observers {
    @observed = (); @counts = (); $last = undef; $sequence = 0; $used = 0;
    $expire_operation = undef; $clock_ns = undef; $queue_signal = 0;
}
sub observed {
    my ($handle, $operation) = @_;
    die "native $operation lacks a fresh admitted check" unless $last
        && $last->{operation} eq $operation && $last->{sequence} > $used;
    $used = $last->{sequence};
    die 'native run has no retained owner' unless $owner->{run};
    my $usage = $owner->observation->{usage};
    die 'native effect lacks the original peak reservation' unless $usage->{charged_descriptors} == 20;
    push @observed, $handle; weaken($observed[-1]);
    my %fds = map { fileno($_) => 1 } live();
    push @counts, scalar keys %fds;
}
sub close_owner {
    my ($o) = @_;
    my $result = $o->close;
    ok($result->{ok}, 'retained coordinator closes its endpoint exactly');
    is($o->observation->{phase}, 'closed', 'native cleanup precedes owner retirement');
    is_deeply($o->observation->{usage}, {map { $_ => 0 }
        qw(jobs children descriptors reserved_children reserved_descriptors charged_children charged_descriptors)},
        'native closure settles all original reservations and root result slot');
    is(scalar(live()), 0, 'no observed live native handle remains');
}
END {
    local $?;
    for my $o (@owners) {
        next if $o->{phase} eq 'closed';
        next if $fixture_cleanup{refaddr($o)};
        $owner = $o;
        my $result = $o->close;
        die 'native run fixture cleanup incomplete' unless $result->{ok};
    }
}

my $guard = $coordinator->can('_before_run_allocation');
my $seal = $endpoint->can('_seal_handle');
my $entries = $endpoint->can('_open_entries');
my $bind = $endpoint->can('_bind_socket');
my $now = FSM::Support::ProcessSupervisor::Admission->can('_now_ns');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Admission::_now_ns = sub { $clock_ns // $now->() };
local *FSM::Support::ProcessSupervisor::Coordinator::_now_ns = sub { $clock_ns // $now->() };
local *FSM::Support::ProcessSupervisor::Coordinator::_before_run_allocation = sub {
    my ($self, $kind, $operation) = @_;
    $clock_ns = $self->{ledger}->describe($self->{jobs}{1}{grant})->{deadline_ns}
        if $kind eq 'create' && defined($expire_operation) && $operation eq $expire_operation;
    $guard->(@_);
    $last = {operation => $operation, sequence => ++$sequence};
    return;
};
local *FSM::Support::ProcessSupervisor::Endpoint::_seal_handle = sub {
    my $operation = -c $_[0] ? 'entropy_open' : -S $_[0] ? 'socket_create'
        : $owner->{run}{directory_handle} ? 'cwd_open' : 'directory_open';
    observed($_[0], $operation);
    my $result = $seal->(@_);
    if ($queue_signal) {
        $queue_signal = 0;
        CORE::kill('USR1', $$) == 1 or die 'cannot queue owned creator signal';
    }
    return $result;
};
local *FSM::Support::ProcessSupervisor::Endpoint::_open_entries = sub {
    my $ok = $entries->(@_); observed(${$_[0]}, 'entries_open') if $ok; return $ok;
};
local *FSM::Support::ProcessSupervisor::Endpoint::_bind_socket = sub {
    die 'native bind lacks a fresh original grant check' unless $last
        && $last->{operation} eq 'socket_bind' && $last->{sequence} > $used;
    $used = $last->{sequence}; return $bind->(@_);
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { die 'run ownership must not fork' };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { die 'run ownership must not fork' };
use warnings 'redefine';

subtest 'native run consumes original steady and transient grants before effects' => sub {
    reset_observers(); my $before = census(); $owner = prepare();
    is_deeply($owner->handles, [], 'coordinator preparation creates no descriptor');
    is($owner->observation->{usage}{charged_descriptors}, 16, 'only root job peak is reserved initially');
    is_deeply(census(), $before, 'resource-free coordinator creates no path');
    $owner->open_run;
    is_deeply($owner->observation->{usage}, {jobs => 1, children => 0, descriptors => 2,
        reserved_children => 2, reserved_descriptors => 18, charged_children => 2, charged_descriptors => 20},
        'steady handles are actual while root and cleanup scratch remain reserved');
    is((sort { $b <=> $a } @counts)[0], 4, 'independent native observers see the reserved run peak');
    my $context = FSM::Support::ProcessSupervisor::Wire::decode_context($owner->context);
    ok($context->{parent} == 1, 'live original root can publish its private context');
    my $view = $owner->{ledger}->describe_descriptors($owner->{scratch_grant});
    $view->{count} = 0;
    is($owner->{ledger}->describe_descriptors($owner->{scratch_grant})->{count}, 2, 'copied projection cannot release cleanup credit');
    like(error_from(sub { $owner->open_run }), qr/single-use/, 'run resources cannot be allocated twice');
    $owner->{ledger}->cancel($owner->{jobs}{1}{grant});
    like(error_from(sub { $owner->context }), qr/revoked/, 'revoked root cannot publish authority');
    close_owner($owner);
    is_deeply(census(), $before, 'exact endpoint path census returns to predecessor');
};

subtest 'insufficient, copied, inherited and cancelled grants reject before native effects' => sub {
    reset_observers(); my $before = census(); $owner = prepare();
    $owner->{ledger}->reserve_descriptors(109); # valid outstanding credit, no fabricated native handle
    like(error_from(sub { $owner->open_run }), qr/descriptor capacity exhausted/, 'partial run reservation fails before native construction');
    is($owner->observation->{usage}{charged_descriptors}, 127, 'first retained run credit survives later capacity refusal');
    is($sequence, 0, 'capacity refusal reaches no native allocation check'); close_owner($owner);
    reset_observers(); $owner = prepare();
    my $copy = bless {%$owner}, ref($owner);
    like(error_from(sub { $copy->open_run }), qr/copied coordinator/, 'copied owner cannot use original ledger');
    { local $owner->{owner_pid} = $$ + 1;
      like(error_from(sub { $owner->open_run }), qr/inherited coordinator/, 'inherited-owner model rejects before native effects'); }
    $owner->{ledger}->cancel($owner->{jobs}{1}{grant});
    like(error_from(sub { $owner->open_run }), qr/revoked/, 'cancel-before-open cannot allocate');
    is($sequence, 0, 'invalid creators and cancelled root perform no native effect'); close_owner($owner);
    reset_observers(); $owner = prepare();
    my $prepare = $endpoint->can('prepare_run');
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::prepare_run = sub {
            my $r = $prepare->();
            $owner->{run_grant} = bless {}, ref($owner->{run_grant});
            return $r;
        };
        like(error_from(sub { $owner->open_run }), qr/foreign, copied or retired descriptor grant/,
            'copied run grant cannot reach entropy allocation');
    }
    is(scalar(@observed), 0, 'copied grant rejects before the first actual descriptor'); close_owner($owner);
    reset_observers(); $owner = prepare();
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::prepare_run = sub {
            my $r = $prepare->(); $owner->{scratch_grant} = $owner->{run_grant}; return $r;
        };
        like(error_from(sub { $owner->open_run }), qr/require distinct grants/, 'one original grant cannot pay for both resource roles');
    }
    is(scalar(@observed), 0, 'aliased credits reject before the first actual descriptor'); close_owner($owner);
    reset_observers(); $owner = prepare();
    $clock_ns = $owner->{ledger}->describe($owner->{jobs}{1}{grant})->{deadline_ns};
    like(error_from(sub { $owner->open_run }), qr/original invocation deadline expired/, 'root expiry before opening rejects');
    is($owner->observation->{usage}{charged_descriptors}, 16, 'expired opening cannot acquire new run credit');
    is(scalar(@observed), 0, 'expired opening creates no descriptor'); close_owner($owner);
    reset_observers();
    is_deeply(census(), $before, 'all refused runs leave original endpoint census unchanged');
};

subtest 'original expiry at creation boundaries preserves bounded partial cleanup' => sub {
    for my $operation (qw(entropy_open entropy_read run_mkdir directory_open socket_create cwd_open entries_open socket_bind)) {
        reset_observers(); my $before = census(); $owner = prepare(); $expire_operation = $operation;
        my $deadline = $owner->{ledger}->describe($owner->{jobs}{1}{grant})->{deadline_ns};
        like(error_from(sub { $owner->open_run }), qr/original invocation deadline expired/, "$operation checks the original inclusive wall");
        my $first = $owner->observation->{failure};
        is($owner->observation->{usage}{charged_descriptors}, 20, 'failed opening retains all peak credit until cleanup is consumed');
        close_owner($owner);
        is($owner->observation->{failure}, $first, 'cleanup does not replace original expiry');
        is($owner->observation->{cleanup_deadline_ns}, Math::BigInt->new($deadline)->badd(4_000_000_000)->bstr,
            'cleanup keeps the original fixed envelope despite revoked creation');
        is_deeply(census(), $before, 'expired partial construction leaves no endpoint path');
    }
    reset_observers();
};

subtest 'pending creator signal sees native effects and reconciled grants before return' => sub {
    reset_observers(); my $before = census(); $owner = prepare(); $queue_signal = 1;
    my ($phase, $usage, $handles);
    local $SIG{USR1} = sub {
        $phase = $owner->observation->{phase}; $usage = $owner->observation->{usage};
        $handles = scalar @{$owner->handles}; die "injected coordinator return signal\n";
    };
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select fixture mask';
    my $error = error_from(sub { $owner->open_run });
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore fixture mask';
    like($error, qr/injected coordinator return signal/, 'real pending signal interrupts coordinator return');
    is($phase, 'open', 'handler sees complete native publication');
    is($usage->{descriptors}, 2, 'handler sees reconciled actual run handles');
    is($usage->{reserved_descriptors}, 18, 'handler sees original root and scratch reservations');
    is($handles, 2, 'original endpoint remains reachable from its coordinator');
    like(error_from(sub { $owner->context }), qr/not open/, 'interrupted coordinator cannot publish context');
    close_owner($owner); is_deeply(census(), $before, 'interrupted native run is removed exactly');
};

subtest 'unproved filesystem cleanup retains charges despite closed descriptors' => sub {
    reset_observers(); my $before = census(); $owner = prepare(); $owner->open_run;
    my $context = FSM::Support::ProcessSupervisor::Wire::decode_context($owner->context);
    my $path = "$root/$context->{directory}";
    my @directory = lstat($path); my @socket = lstat("$path/s");
    open my $extra, '>:raw', "$path/fixture" or die 'cannot create exact hostile fixture';
    print {$extra} 'fixture-owned' or die 'cannot write exact hostile fixture';
    close $extra or die 'cannot close exact hostile fixture';
    my @file = lstat("$path/fixture");
    my $result = $owner->close;
    ok(!$result->{ok}, 'unexpected entry prevents successful native closure');
    is($owner->observation->{phase}, 'close_failed', 'incomplete endpoint remains an owned failed outcome');
    is($owner->observation->{usage}{charged_descriptors}, 20, 'uncertain cleanup cannot release descriptor credits');
    is($owner->observation->{usage}{jobs}, 1, 'uncertain cleanup cannot retire the root slot');
    is(scalar(live()), 0, 'closed native descriptors alone do not prove filesystem closure');
    like(error_from(sub { $owner->context }), qr/not open/, 'failed cleanup cannot publish authority');
    ok(! $owner->close->{ok}, 'retry cannot rewrite the original failed cleanup');
    # The fixture owns this disturbance. Verify each independently captured
    # native identity before exact nonrecursive removal; preserve owner failure.
    for my $entry (["$path/fixture", \@file], ["$path/s", \@socket], [$path, \@directory]) {
        my @actual = lstat($entry->[0]);
        die 'hostile cleanup fixture identity changed' unless @actual
            && $actual[0] == $entry->[1][0] && $actual[1] == $entry->[1][1];
    }
    unlink("$path/fixture") == 1 or die 'cannot remove exact hostile fixture';
    unlink("$path/s") == 1 or die 'cannot remove exact owned socket fixture';
    rmdir($path) or die 'cannot remove exact empty run fixture';
    die 'independent fixture cleanup left residue' if -e $path || @{$owner->handles};
    $fixture_cleanup{refaddr($owner)} = 1;
    is_deeply(census(), $before, 'independent exact fixture cleanup leaves no native residue');
    is($owner->observation->{phase}, 'close_failed', 'fixture teardown never forges coordinator completion');
};

done_testing;
