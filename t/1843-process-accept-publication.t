#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN ECHILD);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use IO::Select;
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 SIGPIPE WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Socket qw(AF_UNIX SOCK_STREAM);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::Connection ();

my $creator = $$;
my (@connections, @servers, @peers, %children);
my ($write_size, $write_mode, $signal_at, $before_mask) = (undef, '', '', '');
my ($current, $clock_value); my $writes = 0;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub pair {
    my ($deadline) = @_;
    socketpair(my $server, my $peer, AF_UNIX, SOCK_STREAM, 0) or die 'publication socketpair failed';
    fcntl($peer, F_SETFL, fcntl($peer, F_GETFL, 0) | O_NONBLOCK) or die 'publication peer nonblocking failed';
    push @servers, $server; push @peers, $peer;
    my $c = FSM::Support::ProcessSupervisor::Connection::new_connection($server, $deadline // now() + 15);
    push @connections, $c; $current = $c; return ($c, $peer);
}
sub raw_frame { pack('NCC', length($_[1]) + 2, 1, $_[0]) . $_[1] }
sub accept_frame { raw_frame(4, pack('N', $_[0])) }
sub read_bytes {
    my ($peer, $size) = @_;
    my ($bytes, $end) = ('', now() + 2);
    while (length($bytes) < $size && now() < $end) {
        my $n = sysread($peer, my $part, $size - length($bytes));
        if (defined($n)) { last unless $n; $bytes .= $part; next; }
        die 'independent publication read failed' unless $! == EAGAIN;
        sleep(0.001);
    }
    return $bytes;
}
sub peer_eof {
    my ($peer) = @_;
    ok(IO::Select->new($peer)->can_read(1), 'independent peer observes native closure');
    is(sysread($peer, my $part, 1), 0, 'native socket reaches empty EOF');
}
sub signal_mask {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot inspect caller mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
sub pipe_handler {
    my $action = POSIX::SigAction->new;
    defined POSIX::sigaction(SIGPIPE, undef, $action) or die 'cannot inspect caller pipe action';
    return [ref($action->handler) ? refaddr($action->handler) : $action->handler, $action->flags];
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        for my $pid (keys %children) {
            next if $children{$pid};
            my $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid || ($w == -1 && $! == ECHILD)) { $children{$pid} = 1; next; }
            die 'publication fixture lost exact inherited child' unless $w == 0;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) {
                if (CORE::waitpid($pid, WNOHANG) == $pid) { $children{$pid} = 1; last; }
                sleep(0.001);
            }
            die 'publication fixture child rescue expired' unless $children{$pid};
        }
        eval { $_->close } for @connections;
        close $_ for live(@servers, @peers);
    }
}

my $write = FSM::Support::ProcessSupervisor::Connection->can('_write_once');
my $enqueue = FSM::Support::ProcessSupervisor::Connection->can('_queue_encoded');
my $mask = FSM::Support::ProcessSupervisor::Reservation->can('_mask');
my $clock = FSM::Support::ProcessSupervisor::Connection->can('_now');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Connection::_now = sub { $clock_value // $clock->() };
local *FSM::Support::ProcessSupervisor::Connection::_queue_encoded = sub {
    my $result = $enqueue->(@_);
    CORE::kill('USR1', $$) == 1 or die 'cannot queue admission publication signal'
        if $signal_at eq 'queue';
    return $result;
};
local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub {
    ++$writes;
    if ($write_mode eq 'again') { $! = EAGAIN; return undef; }
    my $n = $write->($_[0], $_[1], defined($write_size) && $write_size < $_[2] ? $write_size : $_[2]);
    die "selected native write return interrupted\n" if $write_mode eq 'throw_after';
    CORE::kill('USR1', $$) == 1 or die 'cannot queue write publication signal'
        if $signal_at eq 'write' && defined($n) && $n > 0;
    return $n;
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($before_mask && $_[0] == SIG_BLOCK) {
        my $selected = $before_mask; $before_mask = '';
        if ($selected eq 'close') { CORE::kill('USR1', $$) == 1 or die 'cannot queue pre-mask close'; }
        else { $clock_value = $current->{deadline}; }
    }
    return $mask->(@_);
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "ACCEPT publication fixture deadline\n" }; alarm 40;

subtest 'original ACCEPT completion is distinct from aggregate queue emptiness' => sub {
    my ($c, $peer) = pair();
    ok(!defined $c->accept_publication, 'no publication exists before original admission');
    $c->queue({type => 'READY', run => 'r' x 16, parent => 1});
    ok($c->queue_accept(9), 'original job receives one tracked ACCEPT frame');
    my $expected = {job => 9, state => 'queued', frame_bytes => 10, confirmed_bytes => 0, published => 0, failure => undef};
    is_deeply($c->accept_publication, $expected, 'retained record describes only its original frame');
    my $copy = $c->accept_publication; $copy->{job} = 100; $copy->{published} = 1;
    is_deeply($c->accept_publication, $expected, 'copied publication cannot change original completion');
    like(error_from(sub { $c->queue_accept(10) }), qr/single-use/, 'repeat tracked ACCEPT cannot replace original identity');
    $c->queue({type => 'STDERR', job => 9, offset => 0, chunk => 'later'});
    $c->advance;
    is(read_bytes($peer, 26), raw_frame(2, ('r' x 16) . pack('N', 1)), 'independent peer receives the earlier READY exactly');
    ok(!$c->accept_publication->{published}, 'another frame completing cannot confirm ACCEPT');
    $c->advance;
    is(read_bytes($peer, 10), accept_frame(9), 'independent peer receives the complete literal original ACCEPT');
    ok($c->accept_publication->{published}, 'complete original frame has a retained publication result');
    ok($c->queued_bytes->{stream} > 0, 'ACCEPT completion does not require unrelated queues to empty');
    $c->advance;
    is(read_bytes($peer, 27), raw_frame(6, pack('NNNN', 9, 0, 0, 5) . 'later'), 'later stream remains separately framed');
    ok($c->close, 'connection closes after confirmed publication');
    ok($c->accept_publication->{published}, 'later closure does not erase the completed local-write fact');
    peer_eof($peer);
};

subtest 'byte writes preserve partial-stream ordering and exact ACCEPT credit' => sub {
    my ($c, $peer) = pair(); $write_size = 1;
    my $stream = raw_frame(6, pack('NNNN', 2, 0, 0, 3) . 'old');
    $c->queue({type => 'STDERR', job => 2, offset => 0, chunk => 'old'});
    $c->advance; my $bytes = read_bytes($peer, 1);
    ok($c->queue_accept(2), 'tracked control queues behind the already active partial stream');
    for my $count (2 .. length($stream)) {
        $c->advance; $bytes .= read_bytes($peer, 1);
        is($c->accept_publication->{confirmed_bytes}, 0, 'stream writes never count toward ACCEPT');
    }
    is($bytes, $stream, 'raw peer confirms the partial stream stayed contiguous');
    my $accept = '';
    for my $count (1 .. 9) {
        $c->advance; $accept .= read_bytes($peer, 1);
        is($c->accept_publication->{confirmed_bytes}, $count, 'only actual ACCEPT bytes release its confirmed credit');
        ok(!$c->accept_publication->{published}, 'a prefix cannot publish a complete ACCEPT');
    }
    $write_mode = 'again'; $c->advance; $write_mode = '';
    is($c->accept_publication->{confirmed_bytes}, 9, 'EAGAIN confirms no additional byte');
    is($c->queued_bytes->{control}, 1, 'last unconfirmed byte retains queue credit');
    $c->advance; $accept .= read_bytes($peer, 1); $write_size = undef;
    is($accept, accept_frame(2), 'byte-at-a-time writes produce the exact literal ACCEPT');
    ok($c->accept_publication->{published}, 'only the last confirmed byte completes publication');
    $c->close; peer_eof($peer);
};

subtest 'actual pending signals observe queued partial and complete publication' => sub {
    for my $mode (qw(queue partial complete)) {
        my ($c, $peer) = pair(); my $observed;
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select publication mask';
        defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select blocked caller signal';
        my $original_action = pipe_handler();
        local $SIG{USR1} = sub {
            $observed = [$c->accept_publication, $c->queued_bytes, pipe_handler()];
            die "selected creator publication interruption\n";
        };
        my $error;
        if ($mode eq 'queue') {
            $signal_at = 'queue'; $error = error_from(sub { $c->queue_accept(7) });
        }
        else {
            $c->queue_accept(7); $write_size = 1 if $mode eq 'partial';
            $signal_at = 'write'; $error = error_from(sub { $c->advance });
        }
        $signal_at = ''; $write_size = undef;
        like($error, qr/selected creator publication interruption/, 'real handler interrupts the published return');
        is_deeply(signal_mask(), [0, 1], 'original caller blocked/unblocked signal state is restored');
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore fixture mask';
        is_deeply($observed->[2], $original_action, 'handler observes original SIGPIPE action restored');
        my $count = $mode eq 'queue' ? 0 : $mode eq 'partial' ? 1 : 10;
        is($observed->[0]{confirmed_bytes}, $count, 'handler sees all and only original confirmed writes');
        is($observed->[0]{published}, $mode eq 'complete' ? 1 : 0, 'handler sees exact original completion');
        is($observed->[1]{control}, 10 - $count, 'handler sees reconciled remaining queue credit');
        if ($mode eq 'queue') { $c->advance; $count = 10; }
        is(read_bytes($peer, $count), substr(accept_frame(7), 0, $count), 'independent peer bytes match the retained publication prefix');
        $c->close;
        if ($mode eq 'partial') { is($c->accept_publication->{state}, 'failed', 'closing an interrupted prefix refuses completion'); }
        peer_eof($peer);
    }
};

subtest 'uncertain native return and closed peer cannot forge completion' => sub {
    my ($c, $peer) = pair(); $c->queue_accept(2); $write_mode = 'throw_after';
    $c->advance; $write_mode = '';
    is(read_bytes($peer, 10), accept_frame(2), 'independent peer saw actual bytes before the selected lost return');
    is($c->accept_publication->{confirmed_bytes}, 0, 'lost native return confers no confirmed publication credit');
    ok(!$c->accept_publication->{published}, 'unknown native return cannot authorize complete publication');
    is($c->accept_publication->{failure}{status}, 'host_error', 'original write failure remains retained');
    my $failure = $c->accept_publication->{failure}; $failure->{status} = 'forged';
    is($c->accept_publication->{failure}{status}, 'host_error', 'copied failure cannot rewrite the original outcome');
    peer_eof($peer);
    ($c, $peer) = pair(); $c->queue_accept(4);
    my $before_restore = pipe_handler();
    {
        my $sigaction = \&POSIX::sigaction;
        no warnings 'redefine';
        local *POSIX::sigaction = sub {
            my $result = $sigaction->(@_);
            # The actual original action is restored, but its return is lost.
            return undef if @_ == 2 && $_[0] == SIGPIPE;
            return $result;
        };
        $c->advance;
    }
    is(read_bytes($peer, 10), accept_frame(4), 'actual bytes precede the selected SIGPIPE restoration failure');
    is($c->accept_publication->{confirmed_bytes}, 0, 'uncertain write-scope restoration confers no confirmed credit');
    ok(!$c->accept_publication->{published}, 'restoration failure cannot confirm complete publication');
    like($c->accept_publication->{failure}{diagnostic}, qr/restoration failure/, 'scope restoration retains its original failure');
    is_deeply(pipe_handler(), $before_restore, 'independent action read confirms fixture restored the actual disposition');
    peer_eof($peer);
    ($c, $peer) = pair(); $c->queue_accept(3); close $peer;
    my $original = pipe_handler(); $c->_write_ready;
    ok(!$c->accept_publication->{published}, 'actual EPIPE cannot confirm ACCEPT');
    is($c->accept_publication->{failure}{status}, 'peer_closed', 'actual peer failure remains the first cause');
    is_deeply(pipe_handler(), $original, 'EPIPE restores the original SIGPIPE action');
};

subtest 'original invocation and no-progress walls never renew with queue activity' => sub {
    $clock_value = 10; my ($c, $peer) = pair(20); $c->queue_accept(2);
    $clock_value = 11.9; $write_mode = 'again'; $c->advance; $write_mode = '';
    $c->queue({type => 'READY', run => 'r' x 16, parent => 1});
    $clock_value = 12; $c->advance;
    is($c->accept_publication->{failure}{status}, 'write_timeout', 'new queued work and EAGAIN cannot renew the original no-progress wall');
    ok(!$c->accept_publication->{published}, 'expired queue never confirms publication'); peer_eof($peer);
    $clock_value = 10; ($c, $peer) = pair(12.5); $c->queue_accept(2);
    $clock_value = 11.5; $write_size = 1; $c->advance; $write_size = undef;
    is(read_bytes($peer, 1), substr(accept_frame(2), 0, 1), 'actual prefix progresses before the original invocation wall');
    $clock_value = 12.5; $c->advance;
    is($c->accept_publication->{failure}{status}, 'timed_out', 'partial progress cannot extend the original invocation');
    is($c->accept_publication->{confirmed_bytes}, 1, 'expiry retains exact prior confirmed progress');
    peer_eof($peer); $clock_value = undef;
};

subtest 'pre-mask close and expiry prevent stale native writes' => sub {
    for my $mode (qw(close expire)) {
        $clock_value = 10; my ($c, $peer) = pair(20); $c->queue_accept(2);
        my $before = $writes; my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select pre-mask close';
        local $SIG{USR1} = sub { $c->close };
        $before_mask = $mode; $c->advance; $before_mask = '';
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore pre-mask close';
        is($writes, $before, "$mode refuses the stale readiness observation before write");
        ok(!$c->accept_publication->{published}, 'pre-mask invalidation cannot publish ACCEPT');
        is($c->accept_publication->{state}, 'failed', 'original record retains the failed publication');
        peer_eof($peer); $clock_value = undef;
    }
};

subtest 'tracked ACCEPT shares exact encoded control capacity without a receipt registry' => sub {
    for my $extra (0, 1) {
        my ($c, $peer) = pair();
        $c->queue({type => 'REJECT', class => 1, diagnostic => 'd' x 2037}) for 1 .. 7;
        $c->queue({type => 'REJECT', class => 1, diagnostic => 'd' x (2027 + $extra)});
        is($c->queued_bytes->{control}, 16374 + $extra, 'encoded existing controls leave the selected exact remaining capacity');
        my $before = $writes;
        is($c->queue_accept(9), $extra ? 0 : 1, 'tracked frame obeys the same inclusive control ceiling');
        is($writes, $before, 'pure queue admission performs no socket write');
        if ($extra) { is($c->accept_publication->{failure}{status}, 'control_queue_full', 'first excess retains its original queue failure'); }
        else { is($c->queued_bytes->{control}, 16384, 'one tracked ACCEPT fills the inclusive encoded-byte ceiling'); }
        ok(!$c->accept_publication->{published}, 'admission alone never confirms publication');
        $c->close; peer_eof($peer);
    }
};

subtest 'copied and inherited connections cannot inspect or mutate original publication' => sub {
    my ($c, $peer) = pair(); $c->queue_accept(2); my $copy = bless {%$c}, ref($c);
    like(error_from(sub { $copy->accept_publication }), qr/copied connection/, 'copied connection has no original publication observation');
    like(error_from(sub { $copy->close }), qr/copied connection/, 'copied connection cannot close original socket');
    my $handle = $c->handle; my $pid = fork(); die 'cannot fork publication inheritance oracle' unless defined $pid;
    if (!$pid) {
        my $error = error_from(sub { $c->accept_publication });
        $c->discard_inherited;
        _exit($error =~ /inherited/ && !defined(fileno($handle)) ? 0 : 1);
    }
    $children{$pid} = 0; my ($status, $end) = (undef, now() + 2);
    while (now() < $end) {
        if (CORE::waitpid($pid, WNOHANG) == $pid) { $status = $?; $children{$pid} = 1; last; }
        sleep(0.001);
    }
    is($status, 0, 'exact inherited child wait confirms only child descriptors were discarded');
    $c->advance; is(read_bytes($peer, 10), accept_frame(2), 'original creator retains the sole publication after child discard');
    ok($c->accept_publication->{published}, 'original complete publication remains inspectable');
    $c->close; peer_eof($peer);
};

ok(!live(@servers), 'independent native server-handle inventory is closed before teardown');
done_testing;
