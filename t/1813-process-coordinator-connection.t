#!/usr/bin/env perl
use strict;
use warnings;
use Config;
use Errno qw(EAGAIN EWOULDBLOCK);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use IO::Select;
use POSIX qw(SIGPIPE SA_RESTART WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Socket qw(AF_UNIX SOCK_STREAM SOL_SOCKET SO_SNDBUF);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::Connection ();
use FSM::Support::ProcessSupervisor::Wire ();

my $class = 'FSM::Support::ProcessSupervisor::Connection';
my @connections;
my @peers;
END {
    local $?;
    $_->close for grep { $_->{owner_pid} == $$ && !$_->is_closed } @connections;
    close $_ for grep { defined fileno($_) } @peers;
}

sub now { return clock_gettime(CLOCK_MONOTONIC) }

sub pair {
    my ($deadline) = @_;
    socketpair(my $server, my $peer, AF_UNIX, SOCK_STREAM, 0) or die 'socketpair failed';
    fcntl($peer, F_SETFL, fcntl($peer, F_GETFL, 0) | O_NONBLOCK) or die 'peer nonblocking failed';
    my $connection = FSM::Support::ProcessSupervisor::Connection::new_connection(
        $server, defined($deadline) ? $deadline : now() + 10);
    push @connections, $connection;
    push @peers, $peer;
    return ($connection, $peer);
}

sub frame { return pack('NCC', length($_[1]) + 2, 1, $_[0]) . $_[1] }
sub b { return pack('N', length($_[0])) . $_[0] }
sub hello { return frame(1, ('r' x 16) . pack('N', 1) . ('t' x 32)) }

sub send_raw {
    my ($peer, $bytes, $connection) = @_;
    my $deadline = now() + 2;
    while (length $bytes) {
        die 'raw write deadline expired' if now() >= $deadline;
        my $n = syswrite($peer, $bytes, length($bytes) > 16384 ? 16384 : length($bytes));
        if (defined($n) && $n > 0) { substr($bytes, 0, $n, ''); next; }
        die 'raw write failed' unless !defined($n) && ($! == EAGAIN || $! == EWOULDBLOCK);
        $connection->advance;
    }
}

sub receive_frame {
    my ($connection) = @_;
    my $deadline = now() + 2;
    while (now() < $deadline) {
        $connection->advance;
        my $message = $connection->take_frame;
        return $message if $message;
        die 'connection failed before frame' if $connection->failure;
    }
    die 'frame reception deadline expired';
}

sub drain_output {
    my ($connection, $peer) = @_;
    my $bytes = '';
    my $deadline = now() + 2;
    while (now() < $deadline) {
        $connection->advance;
        die 'connection failed during output' if $connection->failure;
        my $n = sysread($peer, my $part, 65536);
        $bytes .= $part if defined($n) && $n > 0;
        my $queued = $connection->queued_bytes;
        return $bytes unless $queued->{control} || $queued->{stream};
    }
    die 'raw output deadline expired';
}

sub pipe_action {
    my $action = POSIX::SigAction->new;
    POSIX::sigaction(SIGPIPE, undef, $action) or die 'cannot inspect SIGPIPE';
    return $action;
}

sub action_identity {
    my ($action) = @_;
    return [ref($action->handler) ? refaddr($action->handler) : $action->handler,
        $action->flags,
        join(',', map { $action->mask->ismember($_) ? $_ : () }
            grep { $_ > 0 } split /\s+/, $Config{sig_num})];
}

subtest 'raw fragmented and pipelined frames are received one at a time' => sub {
    my ($connection, $peer) = pair();
    my $literal = hello();
    for my $octet (split //, $literal) {
        send_raw($peer, $octet, $connection);
        $connection->advance;
    }
    my $message = $connection->take_frame;
    ok($message && $message->{type} eq 'HELLO' && $message->{parent} == 1,
        'literal byte-at-a-time HELLO is decoded');
    ok($message->{run} eq 'r' x 16 && $message->{token} eq 't' x 32,
        'raw authority bytes are preserved without diagnostics');
    send_raw($peer, frame(7, pack('N', 9)) . frame(9, pack('N', 9)), $connection);
    is_deeply(receive_frame($connection), {type => 'CANCEL', job => 9}, 'first frame is isolated');
    is_deeply(receive_frame($connection), {type => 'ACK', job => 9}, 'next frame remains available');
    is(length($connection->{input}), 0, 'wire storage is discarded after decoding');
    ok($connection->close, 'framing fixture closes');
};

subtest 'literal large SPAWN uses bounded reads after prefix admission' => sub {
    my ($connection, $peer) = pair();
    my @argv = ('tool', ('x' x 60000), ('y' x 60000), ('z' x 60000));
    my $body = pack('NN', 0, 1) . b('schema') . b('stage') . b('group') . b('.')
        . pack('NNN', 10, 100, 18) . pack('N', scalar @argv)
        . join('', map { b($_) } @argv) . pack('N', 0);
    my @reads;
    my $native = $class->can('_read_once');
    my $message;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Connection::_read_once = sub {
            push @reads, $_[2];
            return $native->(@_);
        };
        send_raw($peer, frame(3, $body), $connection);
        $message = receive_frame($connection);
    }
    is_deeply([@reads[0, 1]], [4, 2], 'length and type are read separately before body data');
    ok(!grep({ $_ > 16384 } @reads), 'every body syscall stays within one read chunk');
    ok($message->{type} eq 'SPAWN' && @{$message->{argv}} == 4
        && $message->{argv}[1] eq $argv[1] && $message->{argv}[3] eq $argv[3],
        'large admitted request survives native peer buffering exactly');
    ok($connection->close, 'large request fixture closes');
};

subtest 'oversized, wrong-direction and malformed prefixes fail before body reads' => sub {
    for my $case (
        [pack('N', 1048577), [4]],
        [pack('NCC', 8193, 1, 1), [4, 2]],
        [pack('NCC', 22, 1, 2), [4, 2]],
        [pack('NCC', 2, 2, 1), [4, 2]],
        [pack('NCC', 2, 1, 255), [4, 2]],
        [pack('NCC', 2, 1, 1), [4, 2]],
    ) {
        my ($connection, $peer) = pair();
        my @reads;
        my $native = $class->can('_read_once');
        {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::Connection::_read_once = sub {
                push @reads, $_[2]; return $native->(@_);
            };
            send_raw($peer, $case->[0] . ('q' x 100), $connection);
            $connection->advance for 1 .. 3;
        }
        is($connection->failure->{status}, 'protocol_error', 'hostile prefix is a protocol failure');
        is_deeply(\@reads, $case->[1], 'promised body is never read or allocated');
        ok($connection->is_closed && !defined($connection->handle), 'failed descriptor is closed');
    }
};

subtest 'stream and control queues enforce independent encoded-byte ceilings' => sub {
    my ($connection, $peer) = pair();
    my $message = {type => 'STDOUT', job => 2, offset => 0, chunk => 'x' x 16362};
    ok($connection->queue($message), 'stream boundary frame admitted') for 1 .. 4;
    is($connection->queued_bytes->{stream}, 65536, 'headers and payload fill the stream ceiling exactly');
    ok(!$connection->queue({%$message, chunk => ''}), 'next frame refuses before exceeding stream ceiling');
    ok(!$connection->failure, 'stream refusal is backpressure, not accepted or lost output');
    is($connection->queued_bytes->{stream}, 65536, 'refused bytes do not enter storage');
    ok($connection->queue({type => 'READY', run => 'r' x 16, parent => 1}),
        'control has reserved room under saturated stream output');
    my $bytes = drain_output($connection, $peer);
    my $ready = frame(2, ('r' x 16) . pack('N', 1));
    my $stream = frame(5, pack('NNN', 2, 0, 0) . b('x' x 16362));
    ok($bytes eq $ready . ($stream x 4), 'raw peer receives exact priority and all admitted stream bytes');
    ok($connection->close, 'stream fixture closes');

    ($connection, $peer) = pair();
    my $control = {type => 'REJECT', class => 1, diagnostic => 'd' x 2037};
    ok($connection->queue($control), 'control boundary frame admitted') for 1 .. 8;
    is($connection->queued_bytes->{control}, 16384, 'encoded control queue reaches exact ceiling');
    ok(!$connection->queue({%$control, diagnostic => ''}), 'next control frame refuses');
    is($connection->failure->{status}, 'control_queue_full', 'control exhaustion is terminal');
};

subtest 'short native writes cannot interleave frames or release unsent credit early' => sub {
    my ($connection, $peer) = pair();
    my $stream = {type => 'STDERR', job => 2, offset => 0, chunk => 'payload'};
    $connection->queue($stream) or die 'cannot queue short-write fixture';
    my $native = $class->can('_write_once');
    my $bytes;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub {
            return $native->($_[0], $_[1], 1);
        };
        $connection->advance;
        is($connection->queued_bytes->{stream}, 28, 'only the actual delivered byte releases credit');
        $connection->queue({type => 'ACCEPT', job => 2}) or die 'cannot queue priority control';
        $bytes = drain_output($connection, $peer);
    }
    my $expected = frame(6, pack('NNN', 2, 0, 0) . b('payload')) . frame(4, pack('N', 2));
    ok($bytes eq $expected, 'new control waits until the partially written stream frame finishes');
    ok($connection->close, 'partial-write fixture closes');

    ($connection, $peer) = pair();
    $connection->queue($stream);
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub {
            return $native->($_[0], $_[1], 1);
        };
        $connection->advance;
    }
    # Deliberately unsafe model: preempt an already-started stream frame with
    # control. The independent raw-byte oracle must reject this corruption.
    push @{$connection->{queues}{stream}}, $connection->{active}{bytes};
    $connection->{active} = undef;
    $connection->queue({type => 'ACCEPT', job => 2});
    my $corrupted = drain_output($connection, $peer);
    ok($corrupted ne $expected, 'raw oracle rejects deliberately interleaved framing');
    ok($connection->close, 'deliberate corruption fixture closes');
};

subtest 'partial-frame and original-invocation deadlines never renew with progress' => sub {
    my $time = 10;
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::Connection::_now = sub { $time };
    my ($connection, $peer) = pair(30);
    send_raw($peer, substr(hello(), 0, 1), $connection);
    $connection->advance;
    $time = 11.9;
    send_raw($peer, substr(hello(), 1, 1), $connection);
    $connection->advance;
    $time = 12;
    $connection->advance;
    is($connection->failure->{status}, 'framing_timeout', 'fixed first-byte wall expires despite a later byte');
    $time = 20;
    ($connection, $peer) = pair(21);
    send_raw($peer, hello(), $connection);
    ok(receive_frame($connection), 'valid frame completes inside original wall');
    $time = 21;
    $connection->advance;
    is($connection->failure->{status}, 'timed_out', 'complete traffic does not extend original invocation wall');
};

subtest 'only successful byte delivery resets write-progress deadline' => sub {
    my $time = 10;
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::Connection::_now = sub { $time };
    my ($connection, $peer) = pair(30);
    $connection->queue({type => 'ACCEPT', job => 2});
    {
        local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub { $! = EAGAIN; return; };
        $connection->advance;
        $time = 11.9;
        $connection->queue({type => 'ACCEPT', job => 3});
        $connection->advance;
    }
    $time = 12;
    $connection->advance;
    is($connection->failure->{status}, 'write_timeout', 'EAGAIN and newly queued bytes cannot renew delivery wall');
};

subtest 'a real non-reading peer expires and EOF remains visible under backpressure' => sub {
    my ($connection, $peer) = pair();
    setsockopt($connection->handle, SOL_SOCKET, SO_SNDBUF, pack('i', 1024))
        or die 'cannot constrain kernel sender buffer';
    my $message = {type => 'STDOUT', job => 2, offset => 0, chunk => 'x' x 16362};
    $connection->queue($message) for 1 .. 4;
    my $deadline = now() + 4;
    while (!$connection->is_closed && now() < $deadline) {
        $connection->advance;
        sleep(0.005);
    }
    ok($connection->is_closed, 'real blocked writer closes within the independent observer wall');
    is($connection->failure->{status}, 'write_timeout', 'actual kernel backpressure retains timeout truth');
    ($connection, $peer) = pair();
    $connection->queue($message) for 1 .. 4;
    shutdown($peer, 1) or die 'cannot half-close raw peer';
    $connection->advance;
    is($connection->failure->{status}, 'peer_closed', 'saturated output cannot hide peer EOF');
};

subtest 'EPIPE and write exceptions restore the exact native SIGPIPE action' => sub {
    my $old = pipe_action();
    my $caught = 0;
    my $selected = POSIX::SigAction->new(sub { $caught++ },
        POSIX::SigSet->new(POSIX::SIGUSR1()), SA_RESTART);
    POSIX::sigaction(SIGPIPE, $selected) or die 'cannot install test SIGPIPE disposition';
    my $identity = action_identity(pipe_action());
    for my $fault (qw(epipe exception)) {
        my ($connection, $peer) = pair();
        $connection->queue({type => 'ACCEPT', job => 2});
        if ($fault eq 'epipe') {
            close $peer;
            $connection->_write_ready(now());
        }
        else {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub { die 'fixed write fault'; };
            $connection->_write_ready(now());
        }
        my $first = $connection->failure;
        ok($first && $connection->is_closed, 'write failure closes the descriptor');
        is_deeply(action_identity(pipe_action()), $identity, 'native handler, flags and mask are restored');
        $connection->advance;
        ok(!$connection->queue({type => 'ACCEPT', job => 3}), 'closed connection rejects later output');
        is_deeply($connection->failure, $first, 'later operations cannot overwrite first failure');
    }
    POSIX::sigaction(SIGPIPE, $old) or die 'cannot restore original test signal action';
    is($caught, 0, 'socket EPIPE never invokes the caller handler');
};

subtest 'advancement never sleeps or performs a blocking readiness wait' => sub {
    no warnings 'once';
    my ($connection, $peer) = pair();
    my $read = IO::Select->can('can_read');
    my $write = IO::Select->can('can_write');
    my $guard = sub {
        my ($native, $select, $delay) = @_;
        die 'blocking readiness wait' unless defined($delay) && $delay == 0;
        return $native->($select, $delay);
    };
    {
        no warnings 'redefine';
        local *IO::Select::can_read = sub { $guard->($read, @_) };
        local *IO::Select::can_write = sub { $guard->($write, @_) };
        local *Time::HiRes::sleep = sub { die 'blocking sleep' };
        local *FSM::Support::ProcessSupervisor::Connection::sleep = sub { die 'blocking sleep' };
        my $error = eval { IO::Select->new($peer)->can_read(1); 1 };
        ok(!$error && $@ =~ /blocking readiness/, 'readiness trap rejects a deliberate blocking control');
        $error = eval { Time::HiRes::sleep(0.01); 1 };
        ok(!$error && $@ =~ /blocking sleep/, 'sleep trap rejects a deliberate blocking control');
        $connection->queue({type => 'ACCEPT', job => 2});
        $connection->advance;
        send_raw($peer, hello(), $connection);
        ok(receive_frame($connection), 'advancement remains nonblocking through actual input and output');
    }
    ok($connection->poll_delay <= 0.05, 'external driver receives only a bounded idle interval');
    ok($connection->close, 'readiness fixture closes');
};

subtest 'forked connection copies cannot reuse or close creator authority' => sub {
    my ($connection, $peer) = pair();
    my $handle = $connection->handle;
    my $pid = fork();
    die 'cannot fork connection oracle' unless defined $pid;
    if (!$pid) {
        my $reuse = eval { $connection->advance; 1 };
        my $retire = eval { $connection->close; 1 };
        $connection->discard_inherited;
        _exit(!$reuse && !$retire && !defined(fileno($handle)) ? 0 : 1);
    }
    my $deadline = now() + 2;
    my $waited;
    while (($waited = waitpid($pid, WNOHANG)) == 0 && now() < $deadline) { sleep(0.005); }
    if ($waited == 0) {
        kill('KILL', $pid);
        $deadline = now() + 2;
        while (($waited = waitpid($pid, WNOHANG)) == 0 && now() < $deadline) { sleep(0.005); }
    }
    my $status = $?;
    is($waited, $pid, 'exact child is reaped under the independent observer wall');
    is($status, 0, 'child independently verifies inherited-handle rejection');
    send_raw($peer, hello(), $connection);
    ok(receive_frame($connection), 'creator socket still exchanges bytes after inherited descriptor closure');
    ok($connection->close, 'creator retains final closure authority');
};

done_testing();
