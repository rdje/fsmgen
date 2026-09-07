#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(getcwd);
use Errno qw(EAGAIN EINTR EWOULDBLOCK EIO);
use Fcntl qw(F_GETFD F_GETFL FD_CLOEXEC O_NONBLOCK);
use IO::Select;
use Math::BigInt;
use POSIX qw(WNOHANG _exit);
use Socket qw(SHUT_WR);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Endpoint ();
use FSM::Support::ProcessSupervisor::Service ();
use FSM::Support::ProcessSupervisor::Wire ();

my $class = 'FSM::Support::ProcessSupervisor::Service';
my (@services, @clients);
END {
    local $?;
    $_->close for grep { $_->{owner_pid} == $$ && !$_->{closed} } @services;
    $_->close for grep { $_->{owner_pid} == $$ && !$_->{closed} } @clients;
}
sub now { return clock_gettime(CLOCK_MONOTONIC) }
sub ns { return sprintf('%.0f', $_[0] * 1_000_000_000) }
sub service {
    my ($deadline) = @_;
    my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run();
    my $service = FSM::Support::ProcessSupervisor::Service::new_service($run, $deadline // ns(now() + 30));
    push @services, $service;
    return $service;
}
sub client {
    my ($service, $context) = @_;
    my $c = FSM::Support::ProcessSupervisor::Endpoint::connect_context($context // $service->context);
    push @clients, $c;
    my $wall = now() + 2;
    while (now() < $wall) {
        return $c if IO::Select->new($c->handle)->can_write(0) && $c->connection_ready;
        $service->advance;
    }
    die 'client connect observer expired';
}
sub raw { return pack('NCC', length($_[1]) + 2, 1, $_[0]) . $_[1] }
sub b { return pack('N', length($_[0])) . $_[0] }
sub hello {
    my ($encoded, $mutate) = @_;
    my @v = split /:/, $encoded;
    my ($run, $id, $token) = (pack('H*', $v[2]), $v[3], pack('H*', $v[4]));
    $run = 'x' x 16 if ($mutate // '') eq 'run';
    $id = 99 if ($mutate // '') eq 'parent';
    $token = 'z' x 32 if ($mutate // '') eq 'token';
    return raw(1, $run . pack('N', $id) . $token);
}
sub spawn {
    my ($started, $timeout) = @_;
    my ($hi, $lo) = Math::BigInt->new($started)->bdiv(4_294_967_296);
    return raw(3, pack('NN', $hi->numify, $lo->numify)
        . b('fixture.schema') . b('stage') . b('owned') . b('.')
        . pack('NNNN', $timeout // 20, 1024, 18, 3)
        . b('fixture-only-never-exec') . b('') . b("high\xff\n")
        . pack('N', 2) . b('A') . b('') . b('B') . b("space and\nnewline"));
}
sub send_raw {
    my ($service, $client, $bytes) = @_;
    my $wall = now() + 2;
    while (length $bytes) {
        die 'raw write observer expired' if now() >= $wall;
        my $n = syswrite($client->handle, $bytes, length($bytes));
        if (defined($n) && $n > 0) { substr($bytes, 0, $n, ''); next; }
        die 'raw write failed' unless !defined($n) && ($! == EAGAIN || $! == EWOULDBLOCK || $! == EINTR);
        $service->advance;
    }
}
sub until_value {
    my ($service, $read) = @_;
    my $wall = now() + 3;
    while (now() < $wall) {
        $service->advance;
        my $v = $read->();
        return $v if defined $v;
    }
    die 'service observer expired';
}
sub ready {
    my ($service, $c, $context) = @_;
    send_raw($service, $c, hello($context // $service->context));
    my $bytes = '';
    until_value($service, sub {
        my $n = sysread($c->handle, my $part, 26 - length($bytes));
        $bytes .= $part if defined($n) && $n > 0;
        return length($bytes) == 26 ? 1 : undef;
    });
    my @v = split /:/, $context // $service->context;
    ok($bytes eq raw(2, pack('H*', $v[2]) . pack('N', $v[3])), 'READY is exact literal run/parent confirmation only');
}
sub closed { my ($service) = @_; return until_value($service, sub { $service->take_closed }); }
sub finish {
    my ($service) = @_;
    my $relative = $service->{run}{directory};
    my $cleanup = $service->close;
    ok($cleanup->{ok} && $cleanup->{socket_removed} && $cleanup->{directory_removed}, 'service owns complete endpoint cleanup');
    ok(!-e repository_root() . '/' . $relative, 'independent exact endpoint path is absent');
    is($service->counts->{parents}, 0, 'no live authority survives closure');
}

subtest 'literal peers validate authority and preserve a detached request without launch' => sub {
    my $service = service(); my $context = $service->context; my $c = client($service);
    my $started = ns(now()); ready($service, $c);
    send_raw($service, $c, spawn($started));
    my $request = until_value($service, sub { $service->take_request });
    is($request->{parent}, 1, 'request belongs to authenticated root');
    is_deeply($request->{request}{argv}, ['fixture-only-never-exec', '', "high\xff\n"], 'literal argv bytes and empty element survive');
    is_deeply($request->{request}{environment}, [['A', ''], ['B', "space and\nnewline"]], 'ordered environment is detached and exact');
    ok(!defined $service->take_request, 'snapshot can be taken only once');
    my $record = $service->{records}{$request->{ticket}};
    ok(!exists $record->{request}, 'service releases complete snapshot after transfer');
    ok(fcntl($record->{io}->handle, F_GETFD, 0) & FD_CLOEXEC, 'accepted descriptor is close-on-exec');
    ok(fcntl($record->{io}->handle, F_GETFL, 0) & O_NONBLOCK, 'accepted descriptor is nonblocking');
    $service->retire($request->{ticket});
    is($service->take_closed->{status}, 'cancelled', 'owner retirement returns bounded first outcome');
    ok(!defined $service->take_closed, 'outcome consumed exactly once');
    finish($service);
};

subtest 'wrong run, unknown parent, forged and revoked tokens never admit' => sub {
    for my $mutation (qw(run parent token)) {
        my $service = service(); my $c = client($service);
        send_raw($service, $c, hello($service->context, $mutation));
        is(closed($service)->{status}, 'invocation_error', "$mutation authority fails closed");
        ok(!defined $service->take_request, 'invalid authority yields no snapshot');
        finish($service);
    }
    my $service = service(); my $context = $service->register_parent(2, ns(now() + 20));
    my $c = client($service, $context); ready($service, $c, $context);
    my $native = FSM::Support::ProcessSupervisor::Connection->can('close');
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Connection::close = sub {
            ok(!exists $service->{parents}{2}, 'authority is already gone when descriptor cleanup starts');
            return $native->(@_);
        };
        $service->revoke_parent(2);
    }
    is($service->take_closed->{status}, 'authority_revoked', 'authenticated peer closes on revocation');
    $c = client($service, $context);
    send_raw($service, $c, hello($context));
    is(closed($service)->{status}, 'invocation_error', 'later connection cannot replay revoked context');
    ok(!eval { $service->register_parent(2, ns(now() + 10)); 1 }, 'retired parent identity cannot be reused');
    finish($service);
};

subtest 'one submission per socket and exact message order' => sub {
    for my $mode (qw(spawn_before_hello cancel_before_accept repeated_hello repeated_spawn)) {
        my $service = service(); my $c = client($service); my $started = ns(now());
        ready($service, $c) unless $mode eq 'spawn_before_hello';
        my $bytes = $mode eq 'repeated_hello' ? hello($service->context)
            : $mode eq 'cancel_before_accept' ? raw(7, pack('N', 2)) : spawn($started);
        if ($mode eq 'repeated_spawn') {
            send_raw($service, $c, $bytes);
            ok(until_value($service, sub { $service->take_request }), 'first submission reaches private owner');
        }
        send_raw($service, $c, $bytes);
        is(closed($service)->{status}, 'protocol_error', "$mode is rejected");
        finish($service);
    }
    my $service = service();
    my $a = client($service); my $b = client($service);
    ready($service, $a); ready($service, $b);
    is($service->counts->{open}, 2, 'distinct sockets may share one live parent');
    finish($service);
};

subtest 'accepted sockets and retained outcomes stay at the selected cap' => sub {
    my $service = service(); my @c;
    for (1 .. 8) {
        push @c, client($service);
        $service->advance;
        is($service->counts->{connections}, $_, 'one accepted slot per pass');
    }
    my $started = ns(now());
    ready($service, $c[7]);
    send_raw($service, $c[7], spawn($started));
    ok(until_value($service, sub { $service->take_request }), 'healthy peer progresses while other slots await HELLO');
    my $ninth = client($service);
    $service->advance for 1 .. 20;
    is($service->counts->{connections}, 8, 'ninth kernel peer remains outside service ownership');
    shutdown($c[0]->handle, SHUT_WR) or die 'cannot half close peer';
    until_value($service, sub { $service->counts->{open} == 7 ? 1 : undef });
    is($service->counts->{connections}, 8, 'unconsumed closed outcome still occupies its bounded slot');
    my $outcome = $service->take_closed;
    is($outcome->{status}, 'peer_closed', 'EOF is observed at saturated admission');
    $service->advance;
    is($service->counts->{connections}, 8, 'exact freed slot accepts waiting kernel peer');
    finish($service);
};

subtest 'live parent table is bounded and monotonic without retaining revoked tokens' => sub {
    my $service = service();
    $service->register_parent($_, ns(now() + 20)) for 2 .. 8;
    ok(!eval { $service->register_parent(9, ns(now() + 20)); 1 }, 'boundary plus one refuses authority');
    $service->revoke_parent(4);
    ok(!exists $service->{parents}{4}, 'revoked record and token are discarded');
    ok($service->register_parent(9, ns(now() + 20)), 'freed authority slot accepts a fresh higher identity');
    ok(!eval { $service->register_parent(4, ns(now() + 20)); 1 }, 'old id stays invalid after slot reuse');
    $service->revoke_parent(5);
    ok(!eval { $service->register_parent(10, ns(now() + 40)); 1 }, 'parent cannot extend original run lifetime even with a free slot');
    is($service->{high_parent}, 9, 'failed lifetime admission does not consume identity');
    finish($service);
};

subtest 'fixed authentication, admission and timestamp windows' => sub {
    no warnings 'redefine';
    my $base = now(); my $fake = $base;
    local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { ns($fake) };
    local *FSM::Support::ProcessSupervisor::Connection::_now = sub { $fake };
    {
        my $service = service(ns($base + 30)); my $c = client($service);
        $service->advance; $fake = $base + 1.9;
        send_raw($service, $c, substr(hello($service->context), 0, 1));
        $service->advance; $fake = $base + 2.01;
        is(closed($service)->{status}, 'timed_out', 'late first byte does not renew authentication');
        finish($service);
    }
    $fake = $base;
    {
        my $service = service(ns($base + 30)); my $c = client($service);
        ready($service, $c); $fake = $base + 1.99;
        send_raw($service, $c, substr(spawn(ns($base)), 0, 1));
        $service->advance; $fake = $base + 2.01;
        is(closed($service)->{status}, 'timed_out', 'SPAWN progress cannot renew admission');
        finish($service);
    }
    for my $offset (-2, 0, -2.000000001, 0.000000001) {
        $fake = $base;
        my $service = service(ns($base + 30)); my $c = client($service);
        ready($service, $c);
        # Integer nanosecond arithmetic keeps the boundary-plus-one distinct.
        my $started = Math::BigInt->new(ns($base))->badd(sprintf('%.0f', $offset * 1_000_000_000))->bstr;
        send_raw($service, $c, spawn($started));
        if ($offset == -2 || $offset == 0) {
            ok(until_value($service, sub { $service->take_request }), 'inclusive timestamp boundary admitted');
        }
        else { is(closed($service)->{status}, 'invocation_error', 'timestamp one nanosecond outside window rejected'); }
        finish($service);
    }
};

subtest 'original invocation and parent walls clip requests and stale transfer' => sub {
    no warnings 'redefine';
    my $base = now(); my $fake = $base;
    local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { ns($fake) };
    local *FSM::Support::ProcessSupervisor::Connection::_now = sub { $fake };
    my $service = service(ns($base + 30));
    my $context = $service->register_parent(2, ns($base + 1));
    my $c = client($service, $context); ready($service, $c, $context);
    send_raw($service, $c, spawn(ns($base)));
    my $request = until_value($service, sub { $service->take_request });
    is($request->{deadline_ns}, ns($base + 1), 'ancestor deadline clips a longer client wall');
    $fake = $base + 1.01;
    is(closed($service)->{status}, 'timed_out', 'parent expiry closes handed request');
    ok(!exists $service->{parents}{2}, 'expiry revokes authority');
    finish($service);
    $fake = $base;
    $service = service(ns($base + 30)); $c = client($service); ready($service, $c);
    send_raw($service, $c, spawn(ns($base), 1));
    until_value($service, sub { (scalar grep { $_->{state} eq 'request' } values %{$service->{records}}) || undef });
    $fake = $base + 1.01;
    ok(!defined $service->take_request, 'taking a snapshot after its wall cannot leak stale admission');
    my $stale = $service->take_closed;
    is($stale ? $stale->{status} : undef, 'timed_out', 'stale transfer retains timeout truth');
    finish($service);
};

subtest 'fair advancement is bounded and rejects a deliberate blocking model' => sub {
    no warnings qw(redefine once);
    my $service = service(); my @c = map { client($service) } 1 .. 3;
    $service->advance for 1 .. 3;
    my $native = FSM::Support::ProcessSupervisor::Connection->can('advance');
    my $select = IO::Select->can('can_read'); my @seen;
    local *FSM::Support::ProcessSupervisor::Connection::advance = sub {
        push @seen, fileno($_[0]->handle); return $native->(@_);
    };
    local *IO::Select::can_read = sub { die 'blocking readiness' if !defined($_[1]) || $_[1] != 0; return $select->(@_); };
    local *FSM::Support::ProcessSupervisor::Service::sleep = sub { die 'blocking sleep' };
    ok(!eval { IO::Select->new->can_read(1); 1 }, 'negative blocking model is independently rejected');
    $service->advance; my @first = @seen; @seen = ();
    $service->advance;
    is(scalar @first, 3, 'each accepted descriptor advances once per pass');
    is_deeply([@seen], [@first[1, 2, 0]], 'next pass rotates descriptor order');
    ok($service->poll_delay <= 0.05, 'driver idle delay stays bounded');
    finish($service);
};

subtest 'accept host failure and descriptor cleanup truth survive closure' => sub {
    no warnings 'redefine';
    my $service = service(); my $c = client($service);
    {
        local *FSM::Support::ProcessSupervisor::Service::_accept_once = sub { $! = EIO; return; };
        $service->advance;
    }
    is($service->failure->{status}, 'host_error', 'accept error is a terminal host failure');
    ok($service->close->{ok}, 'accept failure leaves no endpoint residue');
    $service = service(); $c = client($service); $service->advance;
    my $native = FSM::Support::ProcessSupervisor::Connection->can('close');
    {
        local *FSM::Support::ProcessSupervisor::Connection::close = sub { $native->(@_); return 0; };
        ok(!$service->close->{ok}, 'reported accepted-descriptor cleanup failure cannot become success');
    }
    my $failure = $service->failure;
    is($failure ? $failure->{status} : undef, 'cleanup_failed', 'cleanup uncertainty is retained');
};

subtest 'real slow authentication expires and exact endpoints close' => sub {
    my $service = service(); my $c = client($service);
    $service->advance;
    my $wall = now() + 4;
    my $outcome;
    while (now() < $wall) {
        $service->advance;
        $outcome = $service->take_closed;
        last if $outcome;
        sleep(0.002);
    }
    ok($outcome && $outcome->{status} eq 'timed_out', 'real unauthenticated socket closes inside independent finite observer');
    finish($service);
};

subtest 'receipt and root revocation recheck lifetime before publishing authority' => sub {
    no warnings 'redefine';
    my $base = now(); my $fake = $base;
    local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { ns($fake) };
    local *FSM::Support::ProcessSupervisor::Connection::_now = sub { $fake };
    my $service = service(ns($base + 30)); my $c = client($service);
    send_raw($service, $c, hello($service->context));
    my $native = FSM::Support::ProcessSupervisor::Connection->can('_read_once');
    {
        local *FSM::Support::ProcessSupervisor::Connection::_read_once = sub {
            my $n = $native->(@_);
            $fake = $base + 3 if defined($n) && $n > 6;
            return $n;
        };
        $service->advance for 1 .. 3;
    }
    my $outcome = $service->take_closed;
    ok($outcome && $outcome->{status} eq 'timed_out', 'time consumed during receipt cannot publish a late READY');
    finish($service);
    $fake = $base;
    $service = service(ns($base + 1)); $c = client($service); $service->advance;
    $fake = $base + 1.01; $service->advance;
    is($service->failure->{status}, 'timed_out', 'original run wall closes the endpoint without renewal');
    ok(!eval { $service->context; 1 }, 'expired root context cannot be published');
    finish($service);
    $fake = $base;
    $service = service(ns($base + 30));
    my $context = $service->register_parent(2, ns($base + 20));
    $c = client($service, $context); ready($service, $c, $context);
    $service->revoke_parent(1);
    is($service->counts->{parents}, 0, 'root revocation removes all descendant authority first');
    is($service->take_closed->{status}, 'authority_revoked', 'root revocation closes descendant connection');
    finish($service);
};

subtest 'forked service copy cannot reuse or retire creator endpoints' => sub {
    my $service = service(); my $context = $service->context;
    my $c = client($service); $service->advance;
    my $listener = $service->{run}->listener;
    my @handles = map { $_->{io}->handle } values %{$service->{records}};
    my $pid = fork(); die 'cannot fork service oracle' unless defined $pid;
    if (!$pid) {
        my $advance = eval { $service->advance; 1 };
        my $close = eval { $service->close; 1 };
        $service->discard_inherited;
        my $open = grep { defined fileno($_) } ($listener, @handles);
        _exit(!$advance && !$close && !$open ? 0 : 1);
    }
    my $wall = now() + 2; my $reaped;
    while (now() < $wall) {
        my $got = waitpid($pid, WNOHANG);
        if ($got == $pid) { $reaped = $?; last; }
        die 'lost exact forked service child' if $got < 0;
        sleep(0.002);
    }
    unless (defined $reaped) {
        kill 'KILL', $pid;
        my $cleanup_wall = now() + 2;
        while (now() < $cleanup_wall) {
            if (waitpid($pid, WNOHANG) == $pid) { $reaped = $?; last; }
            sleep(0.002);
        }
        fail('forked service oracle exceeded original observer');
    }
    is($reaped, 0, 'actual child rejects reuse, discards own handles and exits/reaps');
    ready($service, $c, $context);
    finish($service);
};

done_testing();
