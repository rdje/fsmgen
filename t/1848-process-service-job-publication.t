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
my ($clock_ns, $signal_at) = (undef, '');
my ($write_size, $write_mode, $queue_mode, $expire_at_write) = (undef, '', '', undef);
my $writes = 0;
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
        . bytes('publication.schema') . bytes('probe') . bytes('fixture-group') . bytes('.')
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
    die 'Service publication observer expired';
}
sub send_raw {
    my ($c, $raw) = @_; my $end = now() + 2;
    while (length $raw && now() < $end) {
        my $n = syswrite($c->handle, $raw, length $raw);
        if (defined($n) && $n > 0) { substr($raw, 0, $n, ''); next; }
        die 'Service publication raw write failed' unless !defined($n) && $! == EAGAIN;
        sleep(0.001);
    }
    die 'Service publication raw write observer expired' if length $raw;
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
    ok($c->close->{ok}, 'original client closes its retained descriptor');
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
my $queue = FSM::Support::ProcessSupervisor::Connection->can('queue_accept');
my $write = FSM::Support::ProcessSupervisor::Connection->can('_write_once');
my $ready_write = FSM::Support::ProcessSupervisor::Connection->can('_write_ready');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { $clock_ns // $clock->() };
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($signal_at eq 'before' && $_[0] == SIG_BLOCK) {
        $signal_at = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal before binding';
    }
    return $mask->(@_);
};
local *FSM::Support::ProcessSupervisor::Connection::queue_accept = sub {
    if ($signal_at eq 'queue') { $signal_at = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal queue publication'; }
    die "before native queue publication\n" if $queue_mode eq 'before';
    return 0 if $queue_mode eq 'false';
    my $result = $queue->(@_);
    die "after native queue publication\n" if $queue_mode eq 'after';
    return $result;
};
local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub {
    $writes++;
    if ($write_mode eq 'blocked') { $! = EAGAIN; return; }
    my $result = $write->($_[0], $_[1], defined($write_size) && $write_size < $_[2] ? $write_size : $_[2]);
    if ($signal_at eq 'write') { $signal_at = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal written publication'; }
    return $result;
};
local *FSM::Support::ProcessSupervisor::Connection::_write_ready = sub {
    if (defined $expire_at_write) { $clock_ns = $expire_at_write; $expire_at_write = undef; }
    return $ready_write->(@_);
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "Service publication fixture deadline\n" }; alarm 50;

sub handed {
    my ($s, $context, $started, $timeout) = @_;
    my ($ticket, $c) = request($s, $context, $started, $timeout); my $packet;
    ok($s->transfer_request($ticket, \$packet), 'original request transfers before job binding');
    return ($ticket, $c, $packet);
}
sub read_bytes {
    my ($c, $size) = @_; my ($bytes, $end) = ('', now() + 2);
    while (length($bytes) < $size && now() < $end) {
        my $n = sysread($c->handle, my $part, $size - length($bytes));
        if (defined($n)) { last unless $n; $bytes .= $part; next; }
        die 'publication peer read failed' unless $! == EAGAIN;
        sleep(0.001);
    }
    return $bytes;
}
sub accept_bytes { raw(4, pack('N', $_[0])) }
sub ready_job {
    my ($s, $packet, $job, $deadline) = @_;
    $s->register_parent($job, $deadline // $packet->{deadline_ns});
}

subtest 'original association precedes tracked bytes and survives copied observations and closure' => sub {
    my $s = service(); my ($first, $a, $one) = handed($s); my ($second, $b, $two) = handed($s);
    ok(!defined $s->accept_publication($second), 'unbound original ticket has no publication');
    ready_job($s, $two, 2); ok($s->queue_accept($second, 2), 'selected second request queues its admitted identity');
    my $view = $s->accept_publication($second);
    is_deeply([@{$view}{qw(ticket parent job state deadline_ns admission_deadline_ns)}],
        [$second, 1, 2, 'bound', $two->{deadline_ns}, $two->{admission_deadline_ns}], 'copied association preserves original ticket and both walls');
    is($view->{write}{confirmed_bytes}, 0, 'queue admission alone confirms no byte');
    $view->{job} = 99; $view->{write}{job} = 99; $view->{write}{confirmed_bytes} = 10;
    is($s->accept_publication($second)->{write}{confirmed_bytes}, 0, 'nested publication copy cannot mutate original confirmation');
    like(error_from(sub { $s->queue_accept($second, 2) }), qr/unbound handed request/, 'same request cannot bind twice');
    like(error_from(sub { $s->queue_accept($first, 2) }), qr/already belongs/, 'another original request cannot reuse the bound job context');
    is($s->ticket_observation($first)->{state}, 'handed', 'foreign association refusal leaves other request intact');
    $write_size = 1;
    for my $n (1 .. 10) {
        $s->advance;
        is($s->accept_publication($second)->{write}{confirmed_bytes}, $n, 'Service exposes exact confirmed partial progress');
    }
    $write_size = undef;
    is(read_bytes($b, 10), accept_bytes(2), 'independent peer receives literal matching ACCEPT');
    $s->retire($second);
    $view = $s->accept_publication($second);
    ok($view->{write}{published} && $view->{state} eq 'closed', 'local write fact survives later closure without claiming live authority');
    is($view->{failure}{status}, 'cancelled', 'closure records its own original cause');
    my $closed = $s->take_closed;
    is_deeply([@{$closed}{qw(ticket parent job resources_closed)}], [$second, 1, 2, 1], 'closed outcome retains exact job association');
    like(error_from(sub { $s->queue_accept($first, 2) }), qr/already belongs/, 'consuming the outcome cannot reuse the spent context association');
    ready_job($s, $one, 3); ok($s->queue_accept($first, 3), 'fresh higher job context binds the other original request');
    $s->advance; is(read_bytes($a, 10), accept_bytes(3), 'other request receives only its own literal identity');
    finish($s); peer_eof($a); peer_eof($b);
};

subtest 'pending creator signals retain queue association and completed write before return' => sub {
    for my $point (qw(queue write)) {
        my $s = service(); my ($ticket, $c, $packet) = handed($s); ready_job($s, $packet, 2);
        $s->queue_accept($ticket, 2) if $point eq 'write';
        my ($observed, $old) = (undef, POSIX::SigSet->new);
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select publication signal';
        defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select publication mask';
        local $SIG{USR1} = sub { $observed = $s->accept_publication($ticket); die "selected Service publication interruption\n" };
        $signal_at = $point;
        my $error = error_from(sub { $point eq 'queue' ? $s->queue_accept($ticket, 2) : $s->advance }); $signal_at = '';
        like($error, qr/selected Service publication interruption/, "$point interruption reaches the creator after publication");
        is_deeply(mask_state(), [0, 1], 'original caller mask is restored');
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore publication fixture mask';
        ok($observed && $observed->{job} == 2 && $observed->{state} eq 'bound', 'handler sees original retained request/job binding');
        is($observed->{write}{state}, $point eq 'queue' ? 'queued' : 'written', 'handler sees completed original Connection publication');
        like(error_from(sub { $s->queue_accept($ticket, 2) }), qr/unbound handed request/, 'interrupted return cannot be retried into another association');
        $s->advance if $point eq 'queue';
        is(read_bytes($c, 10), accept_bytes(2), 'exact peer bytes survive the interrupted return');
        finish($s); peer_eof($c);
    }
};

subtest 'pre-mask reentry cannot overwrite a newer binding or retirement' => sub {
    for my $mode (qw(bind retire expire)) {
        my $s = service(); my ($ticket, $c, $packet) = handed($s); ready_job($s, $packet, 2); ready_job($s, $packet, 3);
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select reentry signal';
        local $SIG{USR1} = sub {
            if ($mode eq 'bind') { $s->queue_accept($ticket, 3); }
            elsif ($mode eq 'retire') { $s->retire($ticket); }
            else { $clock_ns = $packet->{admission_deadline_ns}; }
        };
        $signal_at = 'before'; my $queued;
        my $error = error_from(sub { $queued = $s->queue_accept($ticket, 2) }); $signal_at = '';
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore reentry signal';
        if ($mode eq 'bind') {
            like($error, qr/unbound handed request/, 'stale outer binding refuses after handler association');
            is($s->accept_publication($ticket)->{job}, 3, 'newer original association remains intact');
            $s->advance; is(read_bytes($c, 10), accept_bytes(3), 'only the handler-selected original identity publishes');
        }
        else {
            ok(!$queued, "$mode cannot queue the stale request");
            is($s->ticket_observation($ticket)->{failure}{status}, $mode eq 'retire' ? 'cancelled' : 'timed_out', 'original refusal remains authoritative');
        }
        $clock_ns = undef; finish($s); peer_eof($c);
    }
};

subtest 'all original lifetimes remain inclusive at queue and native write boundaries' => sub {
    for my $kind (qw(admission invocation parent root job)) {
        for my $cut (qw(before exact write)) {
            my $base = ns(now()); $clock_ns = $base;
            my $root_end = Math::BigInt->new($base)->badd($kind eq 'root' ? 250_000_000 : 25_000_000_000)->bstr;
            my $s = service($root_end); my $context;
            $context = $s->register_parent(2, Math::BigInt->new($base)->badd(500_000_000)->bstr) if $kind eq 'parent';
            my ($ticket, $c, $packet) = handed($s, $context, $base, $kind eq 'invocation' ? 1 : 20);
            my $job = $kind eq 'parent' ? 3 : 2;
            my $job_end = $kind eq 'job' ? Math::BigInt->new($base)->badd(750_000_000)->bstr : $packet->{deadline_ns};
            ready_job($s, $packet, $job, $job_end);
            my $wall = $kind eq 'job' ? $job_end : $packet->{admission_deadline_ns};
            $clock_ns = $cut eq 'write' ? $base : Math::BigInt->new($wall)->bsub($cut eq 'before' ? 1 : 0)->bstr;
            my $queued = $s->queue_accept($ticket, $job);
            is($queued, $cut eq 'exact' ? 0 : 1, "$kind $cut queue obeys the original inclusive wall");
            if ($cut eq 'write') {
                my $before = $writes; $expire_at_write = $wall; $s->advance;
                is($writes, $before, "$kind expiry after Service preflight cannot reach a native write");
            }
            if ($cut ne 'before') {
                is($s->accept_publication($ticket)->{failure}{status}, 'timed_out', 'original expiry closes the retained association');
                my $write = $s->accept_publication($ticket)->{write};
                ok(!$write || !$write->{published}, 'expired association claims no completed write');
            }
            $clock_ns = undef; finish($s); peer_eof($c);
        }
    }
};

subtest 'decoded cancellation or foreign messages and EOF close before more publication' => sub {
    for my $mode (qw(cancel foreign ack repeated eof parent job)) {
        my $s = service(); my ($ticket, $c, $packet) = handed($s); ready_job($s, $packet, 2); $s->queue_accept($ticket, 2);
        my $expected = 'protocol_error';
        if ($mode eq 'eof') { $c->close; $expected = 'peer_closed'; }
        elsif ($mode eq 'parent' || $mode eq 'job') { $s->revoke_parent($mode eq 'parent' ? 1 : 2); $expected = 'authority_revoked'; }
        else {
            my $message = $mode eq 'repeated' ? spawn_frame($packet->{request}{started_ns}, 20)
                : raw($mode eq 'ack' ? 9 : 7, pack('N', $mode eq 'foreign' ? 3 : 2));
            send_raw($c, $message); $expected = 'cancelled' if $mode eq 'cancel';
        }
        $write_mode = 'blocked'; $s->advance for 1 .. 2;
        my $before = $writes; $write_mode = ''; $s->advance;
        is($writes, $before, "$mode cannot write after the decoded refusal");
        my $view = $s->accept_publication($ticket);
        is($view->{state}, 'closed', 'original bound peer closes');
        is($view->{failure}{status}, $expected, 'closure keeps the exact protocol or authority cause');
        ok(!$view->{write}{published}, 'refused peer never claims complete ACCEPT');
        finish($s); peer_eof($c) unless $mode eq 'eof';
    }
};

subtest 'partial publication preserves its original prefix and endpoint loss refuses binding' => sub {
    my $s = service(); my ($ticket, $c, $packet) = handed($s); ready_job($s, $packet, 2);
    $s->queue_accept($ticket, 2); $write_size = 1; $s->advance; $write_size = undef;
    is(read_bytes($c, 1), substr(accept_bytes(2), 0, 1), 'independent peer receives only the first literal byte');
    $clock_ns = $packet->{admission_deadline_ns}; $s->advance; $clock_ns = undef;
    my $view = $s->accept_publication($ticket);
    is_deeply([@{$view->{write}}{qw(state confirmed_bytes published)}], ['failed', 1, 0], 'expiry retains the confirmed prefix without forging completion');
    is($view->{failure}{status}, 'timed_out', 'Service preserves the original admission failure');
    $view->{failure}{status} = 'altered'; $view->{write}{failure}{status} = 'altered';
    is($s->accept_publication($ticket)->{failure}{status}, 'timed_out', 'copied Service failure cannot alter the original');
    isnt($s->accept_publication($ticket)->{write}{failure}{status}, 'altered', 'copied nested write failure cannot alter the original');
    finish($s); peer_eof($c);
    $s = service(); ($ticket, $c, $packet) = handed($s); ready_job($s, $packet, 2);
    ok($s->{run}->close->{ok}, 'actual original endpoint closes before binding');
    is($s->queue_accept($ticket, 2), 0, 'closed endpoint cannot queue ACCEPT');
    is($s->accept_publication($ticket)->{failure}{status}, 'host_error', 'endpoint loss remains a retained host failure');
    finish($s); peer_eof($c);
};

subtest 'queue failures retain spent association and exact cleanup' => sub {
    for my $mode (qw(before after false)) {
        my $s = service(); my ($ticket, $c, $packet) = handed($s); ready_job($s, $packet, 2);
        $queue_mode = $mode; my $queued;
        my $error = error_from(sub { $queued = $s->queue_accept($ticket, 2) }); $queue_mode = '';
        if ($mode eq 'false') { is($queued, 0, 'false native queue return refuses'); }
        else { like($error, qr/$mode native queue publication/, 'original queue exception survives cleanup'); }
        my $view = $s->accept_publication($ticket);
        is_deeply([@{$view}{qw(job state)}], [2, 'closed'], 'failed queue keeps its original job association');
        is($view->{failure}{status}, 'host_error', 'queue failure retains its original cause');
        ok(!$view->{write} || !$view->{write}{published}, 'uncertain queue return cannot claim publication');
        is($s->take_closed->{job}, 2, 'closed outcome retains the spent identity');
        finish($s); peer_eof($c);
    }
};

subtest 'shared Service closes its bound peer while retaining aggregate endpoint custody' => sub {
    my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run();
    my $s = FSM::Support::ProcessSupervisor::Service::new_shared_service($run, ns(now() + 25));
    push @services, $s;
    my ($ticket, $c, $packet) = handed($s); ready_job($s, $packet, 2); $s->queue_accept($ticket, 2);
    $s->advance; is(read_bytes($c, 10), accept_bytes(2), 'shared endpoint peer receives its original literal ACCEPT');
    my $closed = $s->close;
    ok($closed->{ok} && $closed->{endpoint_retained}, 'shared Service retains original aggregate endpoint custody');
    ok(!$run->observation->{closed} && @{$run->handles}, 'original endpoint remains actually open after peer closure');
    ok($s->accept_publication($ticket)->{write}{published}, 'copied historical publication survives shared Service closure');
    peer_eof($c);
    ok($run->close->{ok}, 'aggregate owner explicitly closes its original endpoint');
    finish($s);
};

subtest 'invalid contexts and copied or inherited Service owners refuse association' => sub {
    my $s = service(); my ($ticket, $c, $packet) = handed($s);
    for my $job (1, 99, 0, '02') {
        ok(length(error_from(sub { $s->queue_accept($ticket, $job) })), 'unknown root or invalid job identity refuses');
    }
    $s->register_parent(2, $s->{deadline}->bstr);
    like(error_from(sub { $s->queue_accept($ticket, 2) }), qr/exceeds original request lifetime/, 'longer child context cannot extend the original invocation');
    ready_job($s, $packet, 3);
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::new_job_token = sub { die "selected unavailable context\n" };
        like(error_from(sub { ready_job($s, $packet, 4) }), qr/selected unavailable context/, 'original failed parent preparation is retained');
    }
    like(error_from(sub { $s->queue_accept($ticket, 4) }), qr/ready original child context/, 'failed original context cannot bind the handed request');
    ok(!defined $s->accept_publication($ticket), 'invalid contexts leave the original request unbound');
    my $copy = bless {%$s}, ref($s);
    like(error_from(sub { $copy->queue_accept($ticket, 3) }), qr/copied service/, 'copied Service cannot bind original jobs');
    like(error_from(sub { $copy->accept_publication($ticket) }), qr/copied service/, 'copied Service cannot inspect original publication');
    my $pid = fork(); die 'Service publication inheritance fork failed' unless defined $pid;
    if (!$pid) {
        my $first = error_from(sub { $s->queue_accept($ticket, 3) });
        my $second = error_from(sub { $s->accept_publication($ticket) });
        $_->discard_inherited for @services;
        $_->discard_inherited for @clients;
        _exit($first =~ /inherited service/ && $second =~ /inherited service/ ? 0 : 91);
    }
    $children{$pid} = 0; my ($status, $end) = (undef, now() + 2);
    while (now() < $end) {
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid) { $status = ${^CHILD_ERROR_NATIVE}; $children{$pid} = 1; last; }
        die 'exact Service publication child wait failed' if $w < 0;
        sleep(0.001);
    }
    ok(defined($status) && POSIX::WIFEXITED($status) && POSIX::WEXITSTATUS($status) == 0, 'exact inherited child refuses both APIs and closes copied descriptors');
    ok($s->queue_accept($ticket, 3), 'creator retains original request after all invalid owners');
    $s->advance; is(read_bytes($c, 10), accept_bytes(3), 'creator still publishes its exact original job');
    finish($s); peer_eof($c);
};

is_deeply(census(), $initial, 'independent endpoint census returns to its original membership');
done_testing;
