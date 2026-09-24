#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN);
use IO::Select;
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Service ();

my (@services, @runs, @clients, @accepted);
my ($observing, $ticket, $admitted, $native_calls, $cut) = (undef, undef, 0, 0, '');
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1e9) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
sub service {
    my ($standalone) = @_;
    my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run(); push @runs, $run;
    my $constructor = $standalone ? 'new_service' : 'new_shared_service';
    my $s = FSM::Support::ProcessSupervisor::Service->can($constructor)->($run, ns(now() + 20));
    push @services, $s; return $s;
}
sub client {
    my ($s) = @_;
    my $c = FSM::Support::ProcessSupervisor::Endpoint::connect_context($s->context); push @clients, $c;
    my $end = now() + 2;
    while (now() < $end) {
        return $c if IO::Select->new($c->handle)->can_write(0) && $c->connection_ready;
        sleep(0.001);
    }
    die 'retained accept client observer expired';
}
sub admission {
    my ($s, $id) = @_;
    is(refaddr($s), refaddr($observing), 'admission receives the original service');
    $ticket = $id; $admitted = 1;
    my $observation = $s->ticket_observation($id);
    is($observation->{state}, 'accepting', 'ticket is retained before admission');
    is($observation->{handles}, 0, 'admission precedes native socket allocation');
    return 1;
}
sub advance {
    my ($s) = @_; $observing = $s; $admitted = 0;
    $s->advance(\&admission);
}
sub peer_eof {
    my ($c) = @_;
    ok(IO::Select->new($c->handle)->can_read(1), 'independent client observes peer closure');
    my $n = sysread($c->handle, my $bytes, 1);
    is($n, 0, 'actual accepted socket closes with empty EOF');
}
sub finish {
    my ($s) = @_;
    ok($s->close->{ok}, 'service native ownership closes successfully');
    ok(!live(@accepted), 'independent retained accepted handles are closed');
    ok($s->{run}->close->{ok}, 'original endpoint owner retires its own run');
}
END {
    local $?; alarm 0;
    # Deliberately broken source variants cannot make cleanup depend solely
    # on the service under test. These are original actual handles and runs.
    eval { $_->close } for @services;
    close $_ for live(@accepted);
    for my $endpoint (@clients, @runs) {
        die 'independent retained accept endpoint cleanup failed' unless $endpoint->close->{ok};
    }
}

my $accept = FSM::Support::ProcessSupervisor::Service->can('_accept_once');
my $construct = FSM::Support::ProcessSupervisor::Connection->can('new_connection');
my $seal = FSM::Support::ProcessSupervisor::Endpoint->can('_seal_handle');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Service::_accept_once = sub {
    ++$native_calls;
    ok($admitted, 'native accept has a fresh original-owner admission'); $admitted = 0;
    is($observing->ticket_observation($ticket)->{state}, 'accepting', 'original ticket precedes syscall');
    if ($cut eq 'transient') { $! = EAGAIN; return undef; }
    my $peer = $accept->(@_);
    if (defined $peer) {
        my $handle = ${$_[0]}; push @accepted, $handle;
        ok(grep(refaddr($_) == refaddr($handle), @{$observing->handles}), 'actual socket is reachable immediately after native accept');
        die "selected partial native accept\n" if $cut eq 'accept_throw';
        if ($cut eq 'partial_transient') { $! = EAGAIN; return undef; }
        CORE::kill('USR1', $$) == 1 or die 'cannot queue accept signal' if $cut eq 'accept_signal';
    }
    return $peer;
};
local *FSM::Support::ProcessSupervisor::Connection::new_connection = sub {
    my ($handle) = @_;
    ok(grep(refaddr($_) == refaddr($handle), @{$observing->handles}), 'constructor borrows the already retained native socket');
    die "selected before connection construction\n" if $cut eq 'construct_before';
    my $io = $construct->(@_);
    die "selected after connection construction\n" if $cut eq 'construct_after';
    return $io;
};
local *FSM::Support::ProcessSupervisor::Endpoint::_seal_handle = sub {
    my $result = $seal->(@_);
    # Endpoint/client setup also seals handles; select only the actual native
    # accepted handle independently observed at the syscall boundary.
    if (grep(refaddr($_) == refaddr($_[0]), live(@accepted))) {
        die "selected accepted seal failure\n" if $cut eq 'seal_throw';
        CORE::kill('USR1', $$) == 1 or die 'cannot queue seal signal' if $cut eq 'seal_signal';
    }
    return $result;
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "retained accept fixture deadline\n" }; alarm 30;
my $initial = census();

subtest 'original ticket owns actual accept construction and retirement' => sub {
    my $s = service(); my $c = client($s); advance($s);
    is_deeply($s->tickets, [1], 'first original ticket is retained');
    my $observation = $s->ticket_observation(1);
    is($observation->{state}, 'hello', 'accepted connection is sealed and awaiting authentication');
    is($observation->{handles}, 1, 'raw and Connection aliases count once');
    is(scalar @{$s->handles}, 3, 'run and accepted socket form the complete borrowed inventory');
    $observation->{state} = 'closed'; push @{$s->tickets}, 99;
    is($s->ticket_observation(1)->{state}, 'hello', 'copied observations cannot mutate the original ticket');
    is_deeply($s->tickets, [1], 'copied ticket list cannot add authority');
    $s->retire(1); peer_eof($c);
    my $outcome = $s->take_closed;
    ok($outcome->{resources_closed}, 'consumed outcome proves native socket closure');
    is($outcome->{status}, 'cancelled', 'original retirement cause survives');
    is_deeply($s->tickets, [], 'explicit outcome consumption releases the ticket slot');
    finish($s);
};

subtest 'refused and transient attempts spend identities without native ownership' => sub {
    my $s = service(); my $c = client($s); $observing = $s;
    my $before = $native_calls;
    $s->advance(sub { admission(@_); return 0 });
    is($native_calls, $before, 'refused admission performs no accept');
    is_deeply($s->tickets, [], 'resource-free refused ticket is forgotten');
    $cut = 'transient'; advance($s); $cut = '';
    is_deeply($s->tickets, [], 'no-handle EAGAIN leaves no occupied slot');
    advance($s); is_deeply($s->tickets, [3], 'deferred and transient ticket identities never repeat');
    $s->retire(3); peer_eof($c); finish($s);
};

subtest 'admission failures recheck original authority and wall before native accept' => sub {
    for my $mode (qw(invalid throw expired revoked)) {
        my $s = service(); client($s); $observing = $s; my $before = $native_calls;
        my $time = FSM::Support::ProcessSupervisor::Service->can('_now_ns'); my $expired = 0;
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub {
            return $expired ? $s->ticket_observation(1)->{wall_ns} : $time->();
        };
        my $error = error_from(sub { $s->advance(sub {
            admission(@_);
            return [] if $mode eq 'invalid';
            die "selected admission refusal\n" if $mode eq 'throw';
            $expired = 1 if $mode eq 'expired';
            $s->revoke_parent(1) if $mode eq 'revoked';
            return 1;
        }) });
        like($error, qr/boolean|selected admission refusal|wall expired|no longer live/, "$mode rejects the original attempt");
        is($native_calls, $before, "$mode performs no native accept");
        is_deeply($s->tickets, [1], 'failed original ticket remains recoverable');
        ok($s->take_closed->{resources_closed}, 'resource-free failure consumes only its own closed outcome');
        finish($s);
    }
};

subtest 'partial syscall construction and sealing preserve original native custody' => sub {
    for my $mode (qw(accept_throw partial_transient construct_before construct_after seal_throw)) {
        my $s = service(); my $c = client($s); $cut = $mode;
        my $error = error_from(sub { advance($s) }); $cut = '';
        if ($mode =~ /accept_throw|construct/) { like($error, qr/selected/, 'original partial-effect exception survives cleanup'); }
        else { is($error, '', 'native or sealing failure is a retained result'); }
        ok(!live(@accepted), "$mode closes independently observed actual accepted sockets"); peer_eof($c);
        is_deeply($s->tickets, [1], 'failed native ticket remains retained until consumed');
        my $outcome = $s->take_closed;
        is($outcome->{status}, 'host_error', 'native failure remains the first peer cause');
        ok($outcome->{resources_closed}, 'native resource closure remains independently consumable');
        if ($mode eq 'seal_throw') { ok(!$s->failure, 'sealed peer failure does not poison the whole service'); }
        else { is($s->failure->{status}, 'host_error', 'interrupted accept closes service authority'); }
        finish($s);
    }
};

subtest 'real pending creator signals observe complete accept publication' => sub {
    for my $mode (qw(accept_signal seal_signal)) {
        my $s = service(); my $c = client($s); my $observed;
        local $SIG{USR1} = sub {
            $observed = {tickets => $s->tickets, ticket => $s->ticket_observation(1),
                actual => scalar(live(@accepted)), inventory => scalar @{$s->handles}};
            die "selected creator interrupted published accept\n";
        };
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select signal mask';
        $cut = $mode; my $error = error_from(sub { advance($s) }); $cut = '';
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore signal mask';
        like($error, qr/selected creator interrupted published accept/, 'actual pending handler interrupts published return');
        is_deeply($observed->{tickets}, [1], 'handler sees original ticket');
        is($observed->{ticket}{state}, 'hello', 'handler sees complete construction and sealing');
        is($observed->{ticket}{handles}, 1, 'handler sees retained actual socket');
        is($observed->{actual}, 1, 'independent native observer agrees');
        is($observed->{inventory}, 3, 'handler sees complete run and peer inventory');
        ok(!live(@accepted), 'interrupted return cleanup closes the actual socket'); peer_eof($c);
        ok($s->take_closed->{resources_closed}, 'original closed outcome survives interrupted return'); finish($s);
    }
};

subtest 'raw custody survives Connection field removal and uncertain close' => sub {
    my $s = service(); my $c = client($s); advance($s);
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Connection::close = sub {
            $_[0]{closed} = 1; delete $_[0]{handle};
            die "selected field removal before native close\n";
        };
        like(error_from(sub { $s->retire(1) }), qr/selected field removal/, 'close interruption follows original handle field removal');
    }
    ok(!live(@accepted), 'raw retained alias closes the actual socket after field removal'); peer_eof($c);
    is($s->ticket_observation(1)->{state}, 'closing', 'interrupted close outcome remains incomplete');
    ok(!defined $s->take_closed, 'partial closure cannot consume its original ticket');
    ok(!$s->close->{ok}, 'missing original Connection close verdict remains failed');
    my $outcome = $s->take_closed;
    ok(!$outcome->{resources_closed}, 'fallback close cannot invent the missing verdict');
    is($outcome->{status}, 'cancelled', 'cleanup uncertainty preserves first retirement cause');
    ok($s->{run}->close->{ok}, 'original endpoint is independently retired');
};

subtest 'failed native close is retryable without replacing its failed verdict' => sub {
    for my $standalone (0, 1) {
        my $s = service($standalone); my $c = client($s); advance($s);
        {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::Connection::close = sub { return 0 };
            local *FSM::Support::ProcessSupervisor::Service::_close_once = sub { return 0 };
            my $result = $s->close;
            ok(!$result->{ok} && $result->{pending}, 'failed live native closure remains pending');
        }
        is(scalar @{$s->{run}->handles}, 2, 'pending native socket closure retains the endpoint in either mode');
        is(scalar(live(@accepted)), 1, 'independent original socket is still open after failed close');
        is($s->ticket_observation(1)->{state}, 'closing', 'original ticket retains unresolved closure');
        ok(!defined $s->take_closed, 'unresolved native ownership cannot be consumed');
        ok(!$s->close->{ok}, 'retry preserves original closure failure');
        ok(!live(@accepted), 'retry closes the still-owned native socket'); peer_eof($c);
        my $outcome = $s->take_closed;
        ok($outcome && !$outcome->{resources_closed}, 'retained failed verdict is consumable only after actual closure');
        is($s->{run}->observation->{closed}, $standalone ? 1 : 0, 'completed peer closure restores the selected endpoint lifetime');
        ok($s->{run}->close->{ok}, 'original endpoint is independently retired');
    }
};

subtest 'closed outcome cannot consume a remaining actual handle' => sub {
    my $s = service(); my $c = client($s); advance($s);
    # Select inconsistent metadata while retaining the original actual socket;
    # this is a consumption guard probe, never fabricated native ownership.
    $s->{records}{1}{state} = 'closed';
    $s->{records}{1}{failure} = {status => 'cancelled', diagnostic => 'selected metadata inconsistency'};
    ok(!$s->ticket_observation(1)->{resources_closed}, 'copied observation cannot mistake closed metadata for native closure');
    like(error_from(sub { $s->take_closed }), qr/still owns native handles/, 'closed metadata cannot erase actual custody');
    is_deeply($s->tickets, [1], 'refused consumption retains the original ticket');
    $s->retire(1); peer_eof($c); finish($s);
};

subtest 'retained closed outcomes bound admission and release slots explicitly' => sub {
    my $s = service(); my @peers;
    for (1 .. 8) { push @peers, client($s); advance($s); }
    my $last = client($s); my $before = $native_calls; my $checks = 0;
    $s->advance(sub { ++$checks; return 1 });
    is($checks, 0, 'saturated service admits no new ticket');
    is($native_calls, $before, 'saturated service performs no ninth native accept');
    $s->retire(1); peer_eof($peers[0]);
    $s->advance(sub { ++$checks; return 1 });
    is($checks, 0, 'unconsumed closed outcome still occupies its bounded slot');
    ok($s->take_closed->{resources_closed}, 'original closed outcome is explicitly consumed');
    advance($s);
    is($native_calls, $before + 1, 'one consumed slot admits exactly one waiting socket');
    is_deeply($s->tickets, [2 .. 9], 'monotonic tickets preserve the remaining exact ownership');
    finish($s); peer_eof($last);
};

subtest 'pre-mask revocation and exhausted identities cannot reach native accept' => sub {
    my $s = service(); client($s); my $before = $native_calls;
    my $mask = FSM::Support::ProcessSupervisor::Reservation->can('_mask'); my $trigger = 1;
    local $SIG{USR1} = sub { $s->revoke_parent(1) };
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select pre-mask signal';
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
            if ($trigger && $_[0] == SIG_BLOCK) {
                $trigger = 0; CORE::kill('USR1', $$) == 1 or die 'cannot queue pre-mask signal';
            }
            return $mask->(@_);
        };
        advance($s);
    }
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore pre-mask signal';
    is($native_calls, $before, 'actual pre-mask revocation prevents stale native admission');
    is_deeply($s->tickets, [], 'pre-mask close creates no unadmitted ticket'); finish($s);
    $s = service(); my $c = client($s);
    $s->{next_ticket} = 4_294_967_295;
    advance($s);
    is_deeply($s->tickets, [4_294_967_295], 'last valid identity retains an actual socket');
    client($s); $before = $native_calls; advance($s);
    is($native_calls, $before, 'identity exhaustion performs no extra accept');
    is($s->failure->{diagnostic}, 'connection identity exhausted', 'exhaustion preserves its original cause');
    peer_eof($c); finish($s);
};

is_deeply(census(), $initial, 'independent endpoint census returns to original state');
done_testing;
