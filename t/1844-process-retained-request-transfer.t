#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN ECHILD);
use IO::Select;
use Math::BigInt;
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Service ();

my $creator = $$;
my (@services, @clients, %children, %selected_requests);
my ($clock_ns, $signal_at, $publication_wall) = (undef, '', undef);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1_000_000_000) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
my $initial = census();
sub raw { pack('NCC', length($_[1]) + 2, 1, $_[0]) . $_[1] }
sub bytes { pack('N', length($_[0])) . $_[0] }
sub spawn_frame {
    my ($started, $timeout) = @_;
    my ($hi, $lo) = Math::BigInt->new($started)->bdiv(4_294_967_296);
    return raw(3, pack('NN', $hi->numify, $lo->numify)
        . bytes('transfer.schema') . bytes('probe') . bytes('fixture-group') . bytes('.')
        . pack('NNNN', $timeout, 64, 18, 3)
        . bytes('never-executed') . bytes('') . bytes("high\xff\n")
        . pack('N', 2) . bytes('A') . bytes('') . bytes('B') . bytes("space and\nnewline"));
}
sub until_value {
    my ($s, $read) = @_; my $end = now() + 2;
    while (now() < $end) {
        $s->advance; my $value = $read->(); return $value if defined $value;
        sleep(0.001);
    }
    die 'retained request observer expired';
}
sub send_raw {
    my ($c, $raw) = @_; my $end = now() + 2;
    while (length $raw && now() < $end) {
        my $n = syswrite($c->handle, $raw, length $raw);
        if (defined($n) && $n > 0) { substr($raw, 0, $n, ''); next; }
        die 'retained request raw write failed' unless !defined($n) && $! == EAGAIN;
        sleep(0.001);
    }
    die 'retained request raw write observer expired' if length $raw;
}
sub service {
    my ($root_deadline) = @_;
    my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run();
    my $s = FSM::Support::ProcessSupervisor::Service::new_service($run, $root_deadline // ns(now() + 25));
    push @services, $s; return $s;
}
sub request {
    my ($s, $context, $started, $timeout) = @_;
    $context //= $s->context; $started //= $clock_ns // ns(now()); $timeout //= 20;
    my $c = FSM::Support::ProcessSupervisor::Endpoint::connect_context($context);
    push @clients, $c;
    until_value($s, sub { IO::Select->new($c->handle)->can_write(0) && $c->connection_ready ? 1 : undef });
    my @v = split /:/, $context;
    send_raw($c, raw(1, pack('H*', $v[2]) . pack('N', $v[3]) . pack('H*', $v[4])));
    my $ready = '';
    until_value($s, sub {
        my $n = sysread($c->handle, my $part, 26 - length $ready);
        $ready .= $part if defined($n) && $n > 0;
        return length($ready) == 26 ? 1 : undef;
    });
    is($ready, raw(2, pack('H*', $v[2]) . pack('N', $v[3])), 'independent client receives literal authenticated READY');
    send_raw($c, spawn_frame($started, $timeout));
    my $ticket = until_value($s, sub {
        for my $id (@{$s->tickets}) {
            return $id if $s->ticket_observation($id)->{state} eq 'request'
                && !$selected_requests{refaddr($s)}{$id};
        }
        return;
    });
    $selected_requests{refaddr($s)}{$ticket} = 1;
    return ($ticket, $c, $started);
}
sub peer_eof {
    my ($c) = @_;
    ok(IO::Select->new($c->handle)->can_read(1), 'native peer is readable after server retirement');
    is(sysread($c->handle, my $part, 1), 0, 'native peer observes empty EOF');
}
sub finish {
    my ($s) = @_; my $path = repository_root() . '/' . $s->{run}{directory};
    ok($s->close->{ok}, 'original service reports complete closure');
    ok(!-e $path, 'independent exact endpoint is absent');
}
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot read transfer mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        for my $pid (keys %children) {
            next if $children{$pid}; my $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid || ($w == -1 && $! == ECHILD)) { $children{$pid} = 1; next; }
            die 'fixture lost exact inherited child' unless $w == 0;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) {
                if (CORE::waitpid($pid, WNOHANG) == $pid) { $children{$pid} = 1; last; }
                sleep(0.001);
            }
            die 'fixture child rescue expired' unless $children{$pid};
        }
        for my $s (@services) {
            eval { $s->close };
            for my $r (values %{$s->{records}}) {
                CORE::close($r->{handle}) if $r->{handle} && defined(fileno($r->{handle}));
            }
            eval { $s->{run}->close };
        }
        eval { $_->close } for @clients;
    }
}
my $mask = FSM::Support::ProcessSupervisor::Reservation->can('_mask');
my $clock = FSM::Support::ProcessSupervisor::Service->can('_now_ns');
my $string = Math::BigInt->can('bstr');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { $clock_ns // $clock->() };
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($signal_at eq 'before' && $_[0] == SIG_BLOCK) {
        $signal_at = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal before transfer mask';
    }
    my $result = $mask->(@_);
    return $result;
};
local *Math::BigInt::bstr = sub {
    my $result = $string->(@_);
    if ($signal_at eq 'publish' && refaddr($_[0]) == $publication_wall) {
        $signal_at = ''; CORE::kill('USR1', $$) == 1 or die 'cannot queue transfer publication signal';
    }
    return $result;
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "retained request fixture deadline\n" }; alarm 40;

subtest 'explicit original ticket transfers literal request into retained custody' => sub {
    my $s = service(); my ($first, $a) = request($s); my ($second, $b) = request($s);
    my $source = $s->{records}{$second}{request}; my $before = $s->ticket_observation($second);
    my %owner;
    ok($s->transfer_request($second, \$owner{request}), 'selected original request transfers to the preexisting owner slot');
    my $packet = $owner{request};
    is($packet->{ticket}, $second, 'explicit second ticket cannot consume another pending request');
    is($s->ticket_observation($first)->{state}, 'request', 'earlier request remains with its own original peer');
    is(refaddr($packet->{request}), refaddr($source), 'original detached snapshot moves without a second snapshot');
    is_deeply($packet->{request}{argv}, ['never-executed', '', "high\xff\n"], 'literal empty and high-byte argv preserved');
    is_deeply($packet->{request}{environment}, [['A', ''], ['B', "space and\nnewline"]], 'literal ordered environment preserved');
    is_deeply([@{$packet->{request}}{qw(cwd umask schema stage containment)}], ['.', 18, 'transfer.schema', 'probe', 'fixture-group'], 'remaining execution bytes and umask preserved');
    is($packet->{admission_deadline_ns}, $before->{wall_ns}, 'original admission wall travels with the packet');
    is($packet->{deadline_ns}, $s->{records}{$second}{deadline}->bstr, 'original clipped execution wall travels separately');
    ok(!exists $s->{records}{$second}{request}, 'source releases custody only after destination publication');
    is($s->ticket_observation($second)->{state}, 'handed', 'source retains handed metadata');
    my $unused;
    like(error_from(sub { $s->transfer_request($second, \$unused) }), qr/no pending original request/, 'repeated ticket cannot mint another transfer');
    ok(!defined $unused, 'repeat leaves the new destination empty');
    my $legacy = $s->take_request;
    is($legacy->{ticket}, $first, 'legacy API still consumes the other original request once');
    ok(!defined $s->take_request, 'legacy empty behavior stays compatible');
    finish($s); peer_eof($a); peer_eof($b);
};

subtest 'real pending signal observes publication before interrupted return' => sub {
    my $s = service(); my ($ticket, $c) = request($s); my (%owner, $observed);
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select transfer caller mask';
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select blocked transfer signal';
    local $SIG{USR1} = sub {
        $observed = [$owner{request}, $s->ticket_observation($ticket)->{state}, exists($s->{records}{$ticket}{request}) ? 1 : 0];
        die "selected retained transfer interruption\n";
    };
    $publication_wall = refaddr($s->{records}{$ticket}{wall});
    $signal_at = 'publish'; my $error = error_from(sub { $s->transfer_request($ticket, \$owner{request}) }); $signal_at = '';
    like($error, qr/selected retained transfer interruption/, 'actual creator handler interrupts the completed return');
    is_deeply(mask_state(), [0, 1], 'original caller mask is restored after handler failure');
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore transfer fixture mask';
    ok($owner{request}, 'original caller slot retains its complete packet after interruption');
    is_deeply($observed, [$owner{request}, 'handed', 0], 'handler observes both published destination and released source custody');
    is_deeply($owner{request}{request}{argv}, ['never-executed', '', "high\xff\n"], 'retained packet still carries original literal bytes');
    finish($s); peer_eof($c);
};

subtest 'pre-mask creator changes cannot be overwritten by stale transfer' => sub {
    for my $mode (qw(destination retire expire)) {
        my $s = service(); my ($ticket, $c) = request($s); my %owner;
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select pre-mask signal';
        local $SIG{USR1} = sub {
            if ($mode eq 'destination') { $owner{request} = 'original occupied slot'; }
            elsif ($mode eq 'retire') { $s->retire($ticket); }
            else { $clock_ns = $s->ticket_observation($ticket)->{wall_ns}; }
        };
        $signal_at = 'before'; my $error = error_from(sub { $s->transfer_request($ticket, \$owner{request}) }); $signal_at = '';
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore pre-mask fixture signal';
        if ($mode eq 'destination') {
            like($error, qr/empty untied scalar/, 'new destination occupancy refuses stale publication');
            is($owner{request}, 'original occupied slot', 'newer original destination remains intact');
            is($s->ticket_observation($ticket)->{state}, 'request', 'unmoved source remains recoverable');
        }
        else {
            ok(!defined $owner{request}, "$mode cannot transfer the stale source");
            is($s->ticket_observation($ticket)->{failure}{status}, $mode eq 'retire' ? 'cancelled' : 'timed_out', 'original cause remains authoritative');
        }
        $clock_ns = undef; finish($s); peer_eof($c);
    }
};

subtest 'inclusive admission execution parent and root walls remain original' => sub {
    for my $kind (qw(admission invocation parent root)) {
        for my $expired (0, 1) {
            my $base = ns(now()); $clock_ns = $base;
            my $root_end = Math::BigInt->new($base)->badd($kind eq 'root' ? 250_000_000 : 25_000_000_000)->bstr;
            my $s = service($root_end); my $context;
            $context = $s->register_parent(2, Math::BigInt->new($base)->badd(500_000_000)->bstr) if $kind eq 'parent';
            my ($ticket, $c) = request($s, $context, $base, $kind eq 'invocation' ? 1 : 20);
            my $wall = $s->ticket_observation($ticket)->{wall_ns};
            $clock_ns = Math::BigInt->new($wall)->bsub($expired ? 0 : 1)->bstr;
            my $slot;
            is($s->transfer_request($ticket, \$slot), $expired ? 0 : 1, "$kind wall admits only strictly before its original boundary");
            if ($expired) {
                ok(!defined $slot, 'expired wall leaves destination empty');
                is($s->ticket_observation($ticket)->{failure}{status}, 'timed_out', 'expiry retains timeout truth');
            }
            else { is($slot->{admission_deadline_ns}, $wall, 'successful transfer cannot renew the original wall'); }
            $clock_ns = undef; finish($s); peer_eof($c);
        }
    }
};

subtest 'invalid destinations and owners preserve original pending custody' => sub {
    my $s = service(); my ($ticket, $c) = request($s);
    my $original = $s->{records}{$ticket}{request};
    my $occupied = 'already owned'; my $refvalue = {}; my $blessed = bless \(my $empty), 'FixtureSlot';
    { package FixtureTiedSlot; use overload bool => sub { 0 }, fallback => 1; sub TIESCALAR { bless {}, shift } sub FETCH { undef } sub STORE { die 'tied destination must not execute' } }
    tie my $tied, 'FixtureTiedSlot';
    for my $target (undef, {}, \$occupied, \$refvalue, $blessed, \$tied) {
        like(error_from(sub { $s->transfer_request($ticket, $target) }), qr/empty untied scalar/, 'invalid destination refuses before custody changes');
        is($s->ticket_observation($ticket)->{state}, 'request', 'original source stays pending');
    }
    like(error_from(sub { $s->transfer_request($ticket, \undef) }), qr/read-only/, 'failed native scalar assignment cannot consume source');
    is($s->ticket_observation($ticket)->{state}, 'request', 'assignment failure leaves original source pending');
    is(refaddr($s->{records}{$ticket}{request}), refaddr($original), 'failed assignment cannot delete the original snapshot');
    my $slot; my $copy = bless {%$s}, ref($s);
    like(error_from(sub { $copy->transfer_request($ticket, \$slot) }), qr/copied service/, 'copied Service cannot transfer original custody');
    like(error_from(sub { $s->transfer_request(4294967295, \$slot) }), qr/unknown connection ticket/, 'unknown ticket cannot publish a packet');
    ok(!defined $slot, 'all refused operations preserve the destination');
    ok($s->transfer_request($ticket, \$slot), 'original source remains transferable after refused operations');
    finish($s); peer_eof($c);
};

subtest 'EOF and repeated SPAWN preserve transferred bytes and first transport failure' => sub {
    for my $handed (0, 1) {
        for my $mode (qw(eof repeated)) {
            my $s = service(); my ($ticket, $c, $started) = request($s); my $slot;
            $s->transfer_request($ticket, \$slot) if $handed;
            if ($mode eq 'eof') { $c->close; }
            else { send_raw($c, spawn_frame($started, 20)); }
            until_value($s, sub { $s->ticket_observation($ticket)->{state} eq 'closed' ? 1 : undef });
            is($s->ticket_observation($ticket)->{failure}{status}, $mode eq 'eof' ? 'peer_closed' : 'protocol_error', 'actual transport event retains its first cause');
            my $unused;
            like(error_from(sub { $s->transfer_request($ticket, \$unused) }), qr/no pending original request/, 'closed peer cannot transfer a fresh packet');
            ok(!defined $unused, 'refusal leaves no new custody');
            if ($handed) { is_deeply($slot->{request}{argv}, ['never-executed', '', "high\xff\n"], 'original transferred snapshot remains with its owner after peer failure'); }
            else { ok(!defined $slot, 'failed untaken request cannot escape source closure'); }
            finish($s); peer_eof($c) if $mode ne 'eof';
        }
    }
};

subtest 'actual inherited child cannot transfer creator request' => sub {
    my $s = service(); my ($ticket, $c) = request($s); my $pid = fork(); die 'cannot fork inherited transfer oracle' unless defined $pid;
    if (!$pid) {
        my $slot; my $error = error_from(sub { $s->transfer_request($ticket, \$slot) });
        $s->discard_inherited;
        _exit($error =~ /inherited/ && !defined $slot ? 0 : 1);
    }
    $children{$pid} = 0; my ($status, $end) = (undef, now() + 2);
    while (now() < $end) {
        if (CORE::waitpid($pid, WNOHANG) == $pid) { $status = $?; $children{$pid} = 1; last; }
        sleep(0.001);
    }
    is($status, 0, 'exact child wait confirms inherited transfer refusal');
    my $slot; ok($s->transfer_request($ticket, \$slot), 'creator retains original source after inherited cleanup');
    finish($s); peer_eof($c);
};

is_deeply(census(), $initial, 'independent endpoint census returns to its predecessor');
done_testing;
