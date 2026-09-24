#!/usr/bin/env perl
use strict;
use warnings;
our $PEEKS = 0;
BEGIN {
    *CORE::GLOBAL::recv = sub { ++$PEEKS; return CORE::recv($_[0], $_[1], $_[2], $_[3]); };
}
use Errno qw(EAGAIN ECHILD EINTR EIO EWOULDBLOCK);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use IO::Select;
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Socket qw(AF_UNIX SOCK_STREAM);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::Connection ();

my (@connections, @handles, %children, @reads, @masks);
my ($clock, $mode, $after_read, $before_mask, $watch);
my $writes = 0; my $creator = $$;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub literal { pack('NCC', length($_[1]) + 2, 1, $_[0]) . $_[1] }
sub bytes { pack('N', length($_[0])) . $_[0] }
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot observe input mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
sub pair {
    socketpair(my $server, my $peer, AF_UNIX, SOCK_STREAM, 0) or die 'inspection socketpair failed';
    fcntl($peer, F_SETFL, fcntl($peer, F_GETFL, 0) | O_NONBLOCK) or die 'inspection peer sealing failed';
    push @handles, $server, $peer;
    my $c = FSM::Support::ProcessSupervisor::Connection::new_connection($server, defined($clock) ? $clock + 20 : now() + 20);
    push @connections, $c; return ($c, $peer);
}
sub send_raw {
    my ($peer, $data, $reader) = @_; my $end = now() + 2;
    while (length($data) && now() < $end) {
        my $n = syswrite($peer, $data);
        if (defined($n) && $n > 0) { substr($data,0,$n,''); next; }
        die 'inspection raw send failed' unless !defined($n) && ($! == EAGAIN || $! == EINTR);
        inspect($reader) if $reader;
        sleep(0.001);
    }
    die 'inspection raw send expired' if length $data;
}
sub empty_peer {
    my ($peer) = @_; my $n = sysread($peer, my $part, 1);
    ok(!defined($n) && $! == EAGAIN, 'literal peer receives no output from inspection');
}
sub finish {
    my ($c, $peer) = @_; $clock = undef; $mode = ''; $after_read = $before_mask = undef;
    ok($c->close, 'original socket closes');
    ok(IO::Select->new($peer)->can_read(1), 'literal peer observes native EOF');
    is(sysread($peer, my $part, 1), 0, 'no queued byte escaped before closure');
    CORE::close($peer) or die 'peer close failed';
}
my $read = FSM::Support::ProcessSupervisor::Connection->can('_read_once');
my $write = FSM::Support::ProcessSupervisor::Connection->can('_write_once');
my $native_clock = FSM::Support::ProcessSupervisor::Connection->can('_now');
my $mask = FSM::Support::ProcessSupervisor::Reservation->can('_mask');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Connection::_read_once = sub {
    push @reads, $_[2]; push @masks, mask_state() if $watch;
    if (($mode // '') =~ /\A(?:EAGAIN|EINTR|EIO)\z/) {
        $! = $mode eq 'EAGAIN' ? EAGAIN : $mode eq 'EINTR' ? EINTR : EIO; return undef;
    }
    my $n = $read->(@_); my $errno = 0 + $!;
    $after_read->($n) if $after_read;
    die "lost original input return\n" if ($mode // '') eq 'lost-return';
    $! = $errno; return $n;
};
local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub { ++$writes; return $write->(@_) };
local *FSM::Support::ProcessSupervisor::Connection::_now = sub { defined($clock) ? $clock : $native_clock->() };
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($before_mask && $_[0] == SIG_BLOCK) { my $f = $before_mask; $before_mask = undef; $f->(); }
    return $mask->(@_);
};
use warnings 'redefine';
sub inspect {
    my ($c) = @_; my ($before, $peeks) = (scalar @reads, $PEEKS);
    $watch = 1; my $v = $c->inspect_input; $watch = 0;
    ok(@reads - $before + $PEEKS - $peeks <= 1, 'inspection performs at most one native read or peek');
    return $v;
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        for my $pid (grep { !$children{$_} } keys %children) {
            my $n = CORE::waitpid($pid, WNOHANG); next if $n == $pid || $n == -1;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) { last if CORE::waitpid($pid, WNOHANG) == $pid; sleep(0.001); }
        }
        eval { $_->close } for @connections; CORE::close($_) for live(@handles);
    }
}
local $SIG{ALRM} = sub { die "input inspection fixture deadline\n" }; alarm 30;
my $old = POSIX::SigSet->new;
defined POSIX::sigprocmask(SIG_SETMASK, POSIX::SigSet->new(SIGUSR2), $old) or die 'cannot set inspection mask';

subtest 'fresh quiet input never writes a queued publication or renews its wall' => sub {
    my ($c, $peer) = pair(); $c->queue_accept(7);
    my $wall = $c->{progress_deadline}; my $before = $writes;
    my $v = inspect($c);
    is_deeply($v, {state=>'quiet', buffered_bytes=>0, frame_ready=>0, failure=>undef}, 'actual empty nonblocking read reports quiet');
    is($writes, $before, 'read-only inspection invokes no native output write');
    is($c->queued_bytes->{control}, 10, 'all original encoded ACCEPT bytes remain queued');
    is($c->accept_publication->{confirmed_bytes}, 0, 'inspection publishes no ACCEPT bytes');
    is($c->{progress_deadline}, $wall, 'inspection preserves original delivery wall');
    empty_peer($peer); $v->{state} = 'closed'; $v->{buffered_bytes} = 900;
    is(inspect($c)->{state}, 'quiet', 'copied inspection cannot replace original state');
    finish($c,$peer);
};

subtest 'every literal fragment and retained decoded frame stays pending' => sub {
    my ($c,$peer) = pair(); my $frame = literal(7, pack('N',7));
    for my $i (0 .. length($frame)-1) {
        send_raw($peer,substr($frame,$i,1));
        is(inspect($c)->{state}, 'pending', 'received fragment never reports quiet');
        my $v = inspect($c);
        is($v->{state}, 'pending', 'empty kernel read cannot erase buffered control');
        is($v->{frame_ready}, $i==length($frame)-1 ? 1:0, 'frame readiness matches exact literal completion');
    }
    is_deeply($c->take_frame, {type=>'CANCEL',job=>7}, 'original retained frame preserves literal control');
    is(inspect($c)->{state}, 'quiet', 'only consumed frame plus a fresh empty read becomes quiet');
    send_raw($peer,literal(9,pack('N',7)).literal(7,pack('N',8)));
    is(inspect($c)->{state},'pending','pipelined header remains pending');
    is(inspect($c)->{state},'pending','pipelined prefix remains pending');
    is(inspect($c)->{frame_ready},1,'first pipelined frame is retained');
    is_deeply($c->take_frame,{type=>'ACK',job=>7},'first frame stays separate');
    is(inspect($c)->{state},'pending','unread following frame prevents quiet');
    inspect($c); inspect($c);
    is_deeply($c->take_frame,{type=>'CANCEL',job=>8},'second frame remains exact');
    finish($c,$peer);
};

subtest 'large literal requests advance one bounded chunk without sending queued output' => sub {
    my ($c,$peer)=pair(); $c->queue_accept(3); my $before=$writes;
    my $arg='x' x 20000;
    my $body=pack('NN',0,1).bytes('schema').bytes('stage').bytes('group').bytes('.')
        .pack('NNNN',10,100,18,2).bytes('tool').bytes($arg).pack('N',0);
    my $start=@reads; send_raw($peer,literal(3,$body),$c); my $v;
    for (1..8) { $v=inspect($c); last if $v->{frame_ready}; }
    ok($v->{frame_ready},'literal bounded request reaches retained frame');
    is_deeply([@reads[$start,$start+1]],[4,2],'length and prefix precede body reads');
    ok(!grep($_>16384,@reads[$start..$#reads]),'each actual body read remains within the published chunk bound');
    is_deeply($c->take_frame->{argv},['tool',$arg],'independent literal body survives bounded reading');
    is($writes,$before,'large incoming request sends no queued output'); empty_peer($peer); finish($c,$peer);
};

subtest 'interruption and faults cannot manufacture an empty read result' => sub {
    for my $selected ('EINTR','EAGAIN','EIO','lost-return') {
        my ($c,$peer)=pair(); $mode=$selected;
        send_raw($peer,substr(literal(7,pack('N',1)),0,1)) if $selected eq 'lost-return';
        if ($selected eq 'lost-return') {
            like(error_from(sub { inspect($c) }),qr/lost original input return/,'lost native read return preserves its error');
            ok($c->is_closed,'lost input custody closes before any later permission');
            is($c->failure->{diagnostic},'input inspection interrupted','lost return keeps explicit inspection failure');
        }
        else {
            my $v=inspect($c);
            is($v->{state},$selected eq 'EINTR'?'pending':$selected eq 'EAGAIN'?'quiet':'closed',"$selected has its distinct read outcome");
            if ($selected eq 'EIO') {
                is($v->{failure}{status},'host_error','read error retains native failure class');
                $v->{failure}{diagnostic}='changed';
                is($c->failure->{diagnostic},'socket read failed','copied failure does not alias original');
            }
        }
        $mode='';
        is(inspect($c)->{state},'quiet','interrupted empty read can be rechecked freshly') if $selected eq 'EINTR';
        finish($c,$peer);
    }
};

subtest 'EOF and invalid input remain visible with queued and completed frames' => sub {
    for my $retained (0,1) {
        my ($c,$peer)=pair(); $c->queue_accept(2);
        if ($retained) {
            send_raw($peer,literal(7,pack('N',2))); inspect($c) for 1..3;
            ok($c->{received},'complete original control is retained before half-close');
        }
        shutdown($peer,1) or die 'cannot half-close inspection peer';
        is(inspect($c)->{state},'closed','actual EOF closes even with backpressure or retained frame');
        is($c->failure->{status},'peer_closed','EOF remains the first cause'); finish($c,$peer);
    }
    my ($c,$peer)=pair(); send_raw($peer,pack('N',1048577));
    is(inspect($c)->{state},'closed','oversized prefix fails during read-only inspection');
    is($c->failure->{status},'protocol_error','invalid framing is preserved'); finish($c,$peer);
};

subtest 'original invocation framing and delivery walls hold before and after reads' => sub {
    for my $kind ('invocation','frame','delivery') {
        for my $cut ('before','after') {
            $clock=10; my ($c,$peer)=pair(); my $wall;
            if ($kind eq 'invocation') { $wall=$c->{deadline}; }
            elsif ($kind eq 'delivery') { $c->queue_accept(4); $wall=$c->{progress_deadline}; }
            else {
                send_raw($peer,substr(literal(7,pack('N',4)),0,6)); inspect($c); inspect($c);
                $wall=$c->{frame_started}+2; $clock=$wall-0.1;
                send_raw($peer,substr(literal(7,pack('N',4)),6));
            }
            if ($cut eq 'before') { $clock=$wall; }
            else { $after_read=sub { $clock=$wall }; }
            my $before=@reads; my $v=inspect($c); $after_read=undef;
            is($v->{state},'closed',"$kind/$cut original inclusive wall closes");
            is($c->failure->{status},$kind eq 'invocation'?'timed_out':$kind eq 'frame'?'framing_timeout':'write_timeout',"$kind/$cut retains exact wall cause");
            is(scalar(@reads)-$before,$cut eq 'before'?0:1,"$kind/$cut bounds the native read");
            finish($c,$peer);
        }
    }
};

subtest 'real creator signal observes retained input before an interrupted return' => sub {
    my ($c,$peer)=pair(); send_raw($peer,literal(7,pack('N',5))); inspect($c); inspect($c);
    my $seen;
    local $SIG{USR1}=sub { $seen=$c->take_frame; die "original input interruption\n" };
    $after_read=sub { kill('USR1',$$)==1 or die 'cannot queue input signal' };
    like(error_from(sub { inspect($c) }),qr/original input interruption/,'pending creator signal interrupts return after read transaction');
    $after_read=undef;
    is_deeply($seen,{type=>'CANCEL',job=>5},'handler sees complete original frame retained before unmask');
    ok($c->is_closed,'interrupted inspection cannot leave later execution permission');
    is_deeply(mask_state(),[0,1],'creator signal mask is restored'); finish($c,$peer);
    ok(@masks && !grep($_->[0]!=1 || $_->[1]!=1,@masks),'every inspected native read ran under the full creator mask');
};

subtest 'copied inherited and pre-mask closed owners cannot inspect original sockets' => sub {
    my ($c,$peer)=pair(); my $copy=bless {%$c},ref($c); my $before=@reads;
    like(error_from(sub { $copy->inspect_input }),qr/copied connection/,'copied owner cannot inspect native input');
    like(error_from(sub { $c->inspect_input(1) }),qr/inspection arguments/,'extra argument is refused');
    is(scalar(@reads),$before,'invalid ownership or arity performs no read');
    my $pid=fork(); die 'cannot fork inspection observer' unless defined $pid;
    if (!$pid) {
        my $error=error_from(sub { $c->inspect_input });
        $_->discard_inherited for @connections;
        CORE::close($_) for live(@handles);
        _exit($error =~ /inherited connection/ ? 0:93);
    }
    $children{$pid}=0; my ($status,$end)=(undef,now()+2);
    while (now()<$end) {
        my $n=CORE::waitpid($pid,WNOHANG);
        if ($n==$pid) { $status=$?; $children{$pid}=1; last; }
        die 'inspection exact wait failed' if $n<0; sleep(0.001);
    }
    is($status,0,'exact inherited child refuses creator input authority');
    local $SIG{USR1}=sub { $c->close };
    $before_mask=sub { kill('USR1',$$)==1 or die 'cannot signal before input mask' };
    is(inspect($c)->{state},'closed','pre-mask creator closure is rechecked');
    is(scalar(@reads),$before,'pre-mask closure performs no native read'); finish($c,$peer);
    ok(!live(@handles),'all original fixture handles are closed');
    ok(!grep(!$_,values %children),'all original observer waits are consumed');
};

defined POSIX::sigprocmask(SIG_SETMASK,$old) or die 'cannot restore inspection mask';
alarm 0;
done_testing();
