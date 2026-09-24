#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN ECHILD);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use IO::Select;
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Socket qw(AF_UNIX SOCK_STREAM);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::Connection ();

my $creator = $$;
my (@connections, @handles, %children);
my ($clock_value, $write_size, $before_mask);
my $writes = 0;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub literal { pack('NCCN', 6, 1, $_[0], $_[1]) }
sub pair {
    socketpair(my $server, my $peer, AF_UNIX, SOCK_STREAM, 0) or die 'admission socketpair failed';
    fcntl($peer, F_SETFL, fcntl($peer, F_GETFL, 0) | O_NONBLOCK) or die 'admission nonblocking failed';
    push @handles, $server, $peer;
    my $c = FSM::Support::ProcessSupervisor::Connection::new_connection($server, now() + 15);
    push @connections, $c;
    return ($c, $peer);
}
sub read_bytes {
    my ($peer, $size) = @_; my ($bytes, $end) = ('', now() + 2);
    while (length($bytes) < $size && now() < $end) {
        my $n = sysread($peer, my $part, $size - length($bytes));
        if (defined($n)) { last unless $n; $bytes .= $part; next; }
        die 'admission peer read failed' unless $! == EAGAIN;
        sleep(0.001);
    }
    return $bytes;
}
sub empty_open {
    my ($peer) = @_;
    my $n = sysread($peer, my $part, 1);
    ok(!defined($n) && $! == EAGAIN, 'independent peer has no unadmitted byte');
}
sub peer_eof {
    my ($peer) = @_;
    ok(IO::Select->new($peer)->can_read(1), 'native peer observes closure');
    is(sysread($peer, my $part, 1), 0, 'native peer reaches empty EOF');
}
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot read admission mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        for my $pid (keys %children) {
            next if $children{$pid}; my $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid || ($w == -1 && $! == ECHILD)) { $children{$pid} = 1; next; }
            die 'admission fixture lost exact child' unless $w == 0;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) {
                if (CORE::waitpid($pid, WNOHANG) == $pid) { $children{$pid} = 1; last; }
                sleep(0.001);
            }
            die 'admission child rescue expired' unless $children{$pid};
        }
        eval { $_->close } for @connections;
        CORE::close($_) for grep { defined($_) && defined(fileno($_)) } @handles;
    }
}
my $native_write = FSM::Support::ProcessSupervisor::Connection->can('_write_once');
my $native_clock = FSM::Support::ProcessSupervisor::Connection->can('_now');
my $native_mask = FSM::Support::ProcessSupervisor::Reservation->can('_mask');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub {
    $writes++;
    return $native_write->($_[0], $_[1], defined($write_size) && $write_size < $_[2] ? $write_size : $_[2]);
};
local *FSM::Support::ProcessSupervisor::Connection::_now = sub { $clock_value // $native_clock->() };
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($before_mask && $_[0] == SIG_BLOCK) {
        $before_mask = 0;
        CORE::kill('USR1', $$) == 1 or die 'cannot signal before write admission';
    }
    return $native_mask->(@_);
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "write admission fixture deadline\n" }; alarm 30;

subtest 'deferred bytes retain their original queue and progress wall' => sub {
    my ($c, $peer) = pair(); my $calls = 0;
    $c->advance(sub { $calls++; 1 }); is($calls, 0, 'idle connection requires no write admission');
    ok($c->queue_accept(2), 'original ACCEPT queues');
    my $deadline = $c->{progress_deadline}; my $before = $writes;
    $c->advance(sub { $calls++; is(refaddr($_[0]), refaddr($c), 'callback receives the original connection'); 0 });
    is($writes, $before, 'false admission performs no native write');
    is($c->queued_bytes->{control}, 10, 'deferral retains every encoded queue byte');
    is($c->{progress_deadline}, $deadline, 'deferral never renews original no-progress wall');
    is($c->accept_publication->{confirmed_bytes}, 0, 'deferral confirms no publication byte');
    empty_open($peer);
    $write_size = 1;
    my $admitted = 0;
    for (1 .. 10) { $c->advance(sub { $admitted++; is_deeply(mask_state(), [1, 1], 'admission executes under preparation mask'); 1 }); }
    $write_size = undef;
    is($admitted, 10, 'every actual partial write obtains a fresh admission');
    is(read_bytes($peer, 10), literal(4, 2), 'independent peer receives exact complete ACCEPT');
    ok($c->accept_publication->{published}, 'only completed writes publish');
    $c->advance(sub { die 'unexpected completed admission' });
    $c->close; peer_eof($peer);
};

subtest 'deferred output preserves bounded client read progress and legacy writes' => sub {
    my ($c, $peer) = pair(); $c->queue_accept(3);
    is(syswrite($peer, literal(7, 3)), 10, 'peer supplies a literal CANCEL');
    $c->advance(sub { 0 }) for 1 .. 3;
    is_deeply($c->take_frame, {type => 'CANCEL', job => 3}, 'read side completes independently of deferred output');
    empty_open($peer);
    $c->advance;
    is(read_bytes($peer, 10), literal(4, 3), 'legacy no-callback advancement retains its exact behavior');
    $c->close; peer_eof($peer);
};

subtest 'callback errors and malformed returns close before any write' => sub {
    for my $mode (qw(throw undef reference nonboolean)) {
        my ($c, $peer) = pair(); $c->queue_accept(4); my $before = $writes;
        my $error = error_from(sub { $c->advance(sub {
            die "selected admission failure\n" if $mode eq 'throw';
            return undef if $mode eq 'undef'; return [] if $mode eq 'reference'; return 2;
        }) });
        like($error, $mode eq 'throw' ? qr/selected admission failure/ : qr/must return a boolean/, "$mode has its original refusal");
        ok($c->is_closed, 'failed admission closes the original connection');
        is($c->failure->{status}, 'host_error', 'failed guard retains a host failure');
        is($writes, $before, 'failed guard cannot reach native write');
        is($c->accept_publication->{confirmed_bytes}, 0, 'failed guard confirms no bytes');
        $c->advance;
        is($writes, $before, 'unguarded retry cannot bypass failed admission');
        peer_eof($peer);
    }
};

subtest 'callback closure and original failure win over a successful return' => sub {
    for my $throws (0, 1) {
        my ($c, $peer) = pair(); $c->queue_accept(5); my $before = $writes;
        my $error = error_from(sub { $c->advance(sub {
            $_[0]->_fail('cancelled', 'original owner cancelled');
            die "after original cancellation\n" if $throws;
            return 1;
        }) });
        is($writes, $before, 'closed callback owner cannot write after returning');
        is($c->failure->{status}, 'cancelled', 'first cancellation survives any later callback failure');
        if ($throws) { like($error, qr/after original cancellation/, 'callback exception remains observable'); }
        else { is($error, '', 'clean callback closure returns normally'); }
        peer_eof($peer);
    }
};

subtest 'successful callback cannot carry stale invocation or no-progress time' => sub {
    for my $kind (qw(invocation progress)) {
        my ($c, $peer) = pair(); $c->queue_accept(6); my $before = $writes;
        $clock_value = now();
        my $wall = $kind eq 'invocation' ? $c->{deadline} : $c->{progress_deadline};
        $c->advance(sub { $clock_value = $wall; return 1 });
        $clock_value = undef;
        is($writes, $before, "$kind boundary expires before native write");
        is($c->failure->{status}, $kind eq 'invocation' ? 'timed_out' : 'write_timeout', 'inclusive original wall keeps its exact cause');
        peer_eof($peer);
    }
};

subtest 'real pending creator signal observes complete guarded publication' => sub {
    my ($c, $peer) = pair(); $c->queue_accept(7); my $observed;
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select caller signal';
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select caller mask';
    local $SIG{USR1} = sub { $observed = $c->accept_publication; die "guarded return interruption\n" };
    my $error = error_from(sub { $c->advance(sub { CORE::kill('USR1', $$) == 1 or die 'cannot queue guard signal'; 1 }) });
    like($error, qr/guarded return interruption/, 'creator signal interrupts after the write transaction');
    is_deeply(mask_state(), [0, 1], 'original signal mask is restored');
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore fixture mask';
    ok($observed && $observed->{published} && $observed->{confirmed_bytes} == 10, 'handler observes confirmed publication rather than an in-flight guard');
    is(read_bytes($peer, 10), literal(4, 7), 'literal native bytes independently establish the complete write');
    $c->close; peer_eof($peer);
};

subtest 'pre-mask closure prevents callback and copied or inherited owners refuse' => sub {
    my ($c, $peer) = pair(); $c->queue_accept(8); my $calls = 0;
    my $copy = bless {%$c}, ref($c);
    like(error_from(sub { $copy->advance(sub { $calls++; 1 }) }), qr/copied connection/, 'copied owner cannot invoke admission');
    for my $bad (undef, 1, {}) {
        like(error_from(sub { $c->advance($bad) }), qr/optional socket write admission/, 'invalid admission argument refuses');
    }
    my $pid = fork(); die 'admission inheritance fork failed' unless defined $pid;
    if (!$pid) {
        my $error = error_from(sub { $c->advance(sub { 1 }) });
        $_->discard_inherited for @connections;
        CORE::close($_) for grep { defined($_) && defined(fileno($_)) } @handles;
        _exit($error =~ /inherited connection/ ? 0 : 91);
    }
    $children{$pid} = 0; my $end = now() + 2; my $status;
    while (now() < $end) {
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid) { $status = ${^CHILD_ERROR_NATIVE}; $children{$pid} = 1; last; }
        die 'exact admission child wait failed' if $w < 0;
        sleep(0.001);
    }
    ok(defined($status) && POSIX::WIFEXITED($status) && POSIX::WEXITSTATUS($status) == 0, 'exact inherited child refuses and closes only its copied descriptors');
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select pre-mask signal';
    local $SIG{USR1} = sub { $c->close };
    $before_mask = 1; $c->advance(sub { $calls++; 1 }); $before_mask = 0;
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore pre-mask fixture signal';
    is($calls, 0, 'pre-mask closure and invalid owners invoke no callback');
    peer_eof($peer);
};

done_testing;
