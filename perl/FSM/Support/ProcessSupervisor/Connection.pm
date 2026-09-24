package FSM::Support::ProcessSupervisor::Connection;

use strict;
use warnings;

use Errno qw(EAGAIN EINTR EPIPE EWOULDBLOCK);
use IO::Select;
use POSIX qw(SIGPIPE);
use Scalar::Util qw(openhandle refaddr);
use Socket qw(AF_UNIX MSG_PEEK SOCK_STREAM SOL_SOCKET SO_TYPE sockaddr_family);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime);
use FSM::Support::ProcessSupervisor::Endpoint ();
use FSM::Support::ProcessSupervisor::Reservation ();
use FSM::Support::ProcessSupervisor::Wire ();

# Inactive, server-side mechanics only. The owner must consume each received
# frame before advancing again and supply the original invocation deadline.
# This object neither authenticates a parent nor admits or launches a command.
# Outgoing client SPAWN serialization belongs to the later client-routing leaf,
# not to these finite coordinator control/stream queues.
my $LIMIT = FSM::Support::ProcessSupervisor::Wire::limits();

sub _now { return clock_gettime(CLOCK_MONOTONIC) }
sub _error { die "private process connection: $_[0]\n" }

sub new_connection {
    _error('expected descriptor and invocation deadline') unless @_ == 2;
    my ($handle, $deadline) = @_;
    _error('expected an open Unix stream descriptor') unless ref($handle) && openhandle($handle);
    my $type = getsockopt($handle, SOL_SOCKET, SO_TYPE);
    my $address = getsockname($handle);
    _error('expected an open Unix stream descriptor') unless defined($type)
        && unpack('i', $type) == SOCK_STREAM && defined($address)
        && sockaddr_family($address) == AF_UNIX;
    _error('invalid invocation deadline') unless defined($deadline) && !ref($deadline)
        && $deadline =~ /\A[0-9]+(?:\.[0-9]+)?\z/ && $deadline > 0;
    my $state = bless {
        owner_pid => $$, handle => $handle, deadline => 0 + $deadline,
        input => '', target => 4, frame_started => undef,
        queues => {control => [], stream => []},
        queued_bytes => {control => 0, stream => 0},
        active => undef, progress_deadline => undef, closed => 0,
    }, __PACKAGE__;
    $state->{owner_identity} = refaddr($state);
    my $sealed = eval { FSM::Support::ProcessSupervisor::Endpoint::_seal_handle($handle, 1); 1 };
    $state->_fail('host_error', 'cannot seal accepted descriptor') unless $sealed;
    return $state;
}

sub _owner {
    my ($self) = @_;
    _error('invalid or copied connection handle') unless ref($self) eq __PACKAGE__
        && defined($self->{owner_identity}) && $self->{owner_identity} == refaddr($self);
    _error('inherited connection cannot be reused') unless $self->{owner_pid} == $$;
}

sub _fail {
    my ($self, $status, $diagnostic) = @_;
    $self->{failure} //= {status => $status, diagnostic => $diagnostic};
    $self->close;
    return;
}

sub failure {
    my ($self) = @_;
    _owner($self);
    return $self->{failure} ? {%{$self->{failure}}} : undef;
}

sub is_closed { _owner($_[0]); return $_[0]{closed} ? 1 : 0 }
sub handle { _owner($_[0]); return $_[0]{handle} }

sub queue {
    my ($self, $message) = @_;
    _error('expected one outgoing message') unless @_ == 2;
    _owner($self);
    return 0 if $self->{closed};
    my $frame = eval { FSM::Support::ProcessSupervisor::Wire::encode_frame('coordinator', $message) };
    if ($@) { $self->_fail('protocol_error', 'invalid outgoing coordinator frame'); return 0; }
    my $kind = $message->{type} eq 'STDOUT' || $message->{type} eq 'STDERR' ? 'stream' : 'control';
    return $self->_queue_encoded($kind, $frame);
}

# One tracked ACCEPT per original connection. This records successful local
# socket writes, not remote acknowledgement or permission to release a job.
sub queue_accept {
    my ($self, $job) = @_;
    _error('expected one ACCEPT job identity') unless @_ == 2;
    _owner($self);
    my $queued = 0;
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        _error('ACCEPT publication is single-use') if $self->{accept_publication};
        return if $self->{closed};
        my $frame = eval { FSM::Support::ProcessSupervisor::Wire::encode_frame(
            'coordinator', {type => 'ACCEPT', job => $job}) };
        if ($@) { $self->_fail('protocol_error', 'invalid ACCEPT job identity'); return; }
        my $publication = $self->{accept_publication} = {
            job => $job, state => 'queued', frame_bytes => length($frame), confirmed_bytes => 0,
        };
        $queued = $self->_queue_encoded('control', $frame, $publication);
    });
    return $queued;
}

sub accept_publication {
    my ($self) = @_;
    _error('unexpected ACCEPT publication arguments') unless @_ == 1;
    _owner($self);
    my $publication = $self->{accept_publication} or return;
    return {%$publication, published => $publication->{state} eq 'written' ? 1 : 0,
        failure => $publication->{failure} ? {%{$publication->{failure}}} : undef};
}

sub _queue_encoded {
    my ($self, $kind, $frame, $publication) = @_;
    my $cap = $LIMIT->{$kind . '_queue'};
    if (length($frame) > $cap - $self->{queued_bytes}{$kind}) {
        # Stream pressure means the caller must retain its unaccepted chunk
        # and stop reading that producer. Control exhaustion is a failed link.
        $self->_fail('control_queue_full', 'control queue exhausted') if $kind eq 'control';
        return 0;
    }
    push @{$self->{queues}{$kind}}, $publication
        ? {kind => $kind, bytes => $frame, publication => $publication} : $frame;
    $self->{queued_bytes}{$kind} += length($frame);
    $self->{progress_deadline} //= _now() + $LIMIT->{delivery_seconds};
    return 1;
}

sub queued_bytes {
    my ($self) = @_;
    _owner($self);
    return {%{$self->{queued_bytes}}};
}

sub take_frame {
    my ($self) = @_;
    _owner($self);
    return delete $self->{received};
}

sub poll_delay {
    my ($self) = @_;
    _owner($self);
    return 0 if $self->{closed};
    my $deadline = $self->{deadline};
    for my $candidate (
        defined($self->{frame_started}) ? $self->{frame_started} + $LIMIT->{handshake_seconds} : (),
        defined($self->{progress_deadline}) ? $self->{progress_deadline} : (),
    ) {
        $deadline = $candidate if $candidate < $deadline;
    }
    my $remaining = $deadline - _now();
    return 0 if $remaining <= 0;
    return $remaining < $LIMIT->{idle_seconds} ? $remaining : $LIMIT->{idle_seconds};
}

sub _read_once { return sysread($_[0], ${$_[1]}, $_[2]) }
sub _write_once { return syswrite($_[0], ${$_[1]}, $_[2]) }

sub _read_ready {
    my ($self, $now) = @_;
    if ($self->{received}) {
        # Even while a completed frame is waiting for its owner, peer EOF must
        # remain observable. Peeking stores at most one byte and consumes none.
        my $peer = recv($self->{handle}, my $peek, 1, MSG_PEEK);
        if (defined($peer)) {
            $self->_fail('peer_closed', 'peer closed the connection') unless length($peek);
        }
        elsif ($! != EAGAIN && $! != EWOULDBLOCK && $! != EINTR) {
            $self->_fail('host_error', 'cannot inspect peer closure');
        }
        return;
    }
    my $needed = $self->{target} - length($self->{input});
    $needed = $LIMIT->{chunk} if $needed > $LIMIT->{chunk};
    my $read = _read_once($self->{handle}, \my $part, $needed);
    if (!defined($read)) {
        return if $! == EAGAIN || $! == EWOULDBLOCK || $! == EINTR;
        $self->_fail('host_error', 'socket read failed');
        return;
    }
    if (!$read) { $self->_fail('peer_closed', 'peer closed the connection'); return; }
    $self->{frame_started} //= $now;
    $self->{input} .= $part;
    if (length($self->{input}) == 4 && $self->{target} == 4) {
        my $admitted = eval { FSM::Support::ProcessSupervisor::Wire::payload_size($self->{input}) };
        unless (defined($admitted)) { $self->_fail('protocol_error', 'invalid frame length header'); return; }
        $self->{target} = 6;
    }
    if (length($self->{input}) == 6 && $self->{target} == 6) {
        my $size = eval { FSM::Support::ProcessSupervisor::Wire::frame_size('client', $self->{input}) };
        unless (defined($size)) { $self->_fail('protocol_error', 'invalid client frame prefix'); return; }
        $self->{target} = $size;
    }
    if (length($self->{input}) == $self->{target} && $self->{target} >= 6) {
        my $decoded = eval { FSM::Support::ProcessSupervisor::Wire::decode_frame('client', $self->{input}) };
        unless ($decoded) { $self->_fail('protocol_error', 'invalid client frame body'); return; }
        $self->{received} = $decoded;
        $self->{input} = '';
        $self->{target} = 4;
        $self->{frame_started} = undef;
    }
}

sub _write_ready {
    my ($self, $observed_now, $check) = @_;
    _owner($self);
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        # A pre-mask handler may have closed or advanced this original owner.
        return if $self->{closed};
        if ($check) {
            my ($admitted, $error);
            {
                local $@;
                eval {
                    $admitted = $check->($self);
                    _error('write admission must return a boolean') unless defined($admitted)
                        && !ref($admitted) && "$admitted" =~ /\A[01]\z/;
                    1;
                } or $error = $@;
            }
            if (defined $error) {
                # A failed callback cannot leave queued bytes eligible for an
                # unguarded retry. Preserve its exception if cleanup also fails.
                eval { $self->_fail('host_error', 'socket write admission failed'); 1 };
                die $error;
            }
            return unless $admitted;
            return if $self->{closed};
        }
        # The caller's authority check can consume time or close the owner.
        # Neither callback success nor a stale readiness sample renews a wall.
        my $now = _now();
        if ($now >= $self->{deadline}) {
            $self->_fail('timed_out', 'original invocation deadline expired'); return;
        }
        if (defined($self->{progress_deadline}) && $now >= $self->{progress_deadline}) {
            $self->_fail('write_timeout', 'queued bytes made no delivery progress'); return;
        }
        $self->_write_ready_effect($now);
    });
    return;
}

sub _write_ready_effect {
    my ($self, $now) = @_;
    unless ($self->{active}) {
        for my $kind (qw(control stream)) {
            next unless @{$self->{queues}{$kind}};
            my $frame = shift @{$self->{queues}{$kind}};
            $self->{active} = ref($frame) ? $frame : {kind => $kind, bytes => $frame};
            last;
        }
    }
    return unless $self->{active};
    my $active = $self->{active};
    my $count = length($active->{bytes});
    $count = $LIMIT->{chunk} if $count > $LIMIT->{chunk};
    my $previous = POSIX::SigAction->new;
    my $ignore = POSIX::SigAction->new('IGNORE', POSIX::SigSet->new, 0);
    unless (defined POSIX::sigaction(SIGPIPE, $ignore, $previous)) {
        $self->_fail('host_error', 'cannot scope socket SIGPIPE disposition');
        return;
    }
    my ($written, $errno, $exception);
    {
        local $@;
        eval {
            $written = _write_once($self->{handle}, \$active->{bytes}, $count);
            $errno = 0 + $!;
            1;
        } or $exception = 1;
    }
    unless (defined POSIX::sigaction(SIGPIPE, $previous)) {
        $self->_fail('host_error', 'fatal socket SIGPIPE restoration failure');
        return;
    }
    if ($exception) { $self->_fail('host_error', 'socket write raised an exception'); return; }
    unless (defined $written) {
        return if $errno == EAGAIN || $errno == EWOULDBLOCK || $errno == EINTR;
        $self->_fail($errno == EPIPE ? 'peer_closed' : 'host_error', 'socket write failed');
        return;
    }
    unless ($written > 0) { $self->_fail('host_error', 'socket write made no progress'); return; }
    # A partially written frame must finish before any other frame, including
    # newly queued control. Otherwise control priority would corrupt framing.
    substr($active->{bytes}, 0, $written, '');
    $self->{queued_bytes}{$active->{kind}} -= $written;
    if (my $publication = $active->{publication}) {
        $publication->{confirmed_bytes} += $written;
        $publication->{state} = length($active->{bytes}) ? 'writing' : 'written';
    }
    $self->{active} = undef unless length($active->{bytes});
    my $pending = $self->{queued_bytes}{control} + $self->{queued_bytes}{stream};
    $self->{progress_deadline} = $pending ? $now + $LIMIT->{delivery_seconds} : undef;
}

sub advance {
    my ($self, $check) = @_;
    _error('expected optional socket write admission')
        unless @_ == 1 || (@_ == 2 && ref($check) eq 'CODE');
    _owner($self);
    return if $self->{closed};
    my $now = _now();
    if ($now >= $self->{deadline}) {
        $self->_fail('timed_out', 'original invocation deadline expired');
        return;
    }
    if (defined($self->{frame_started}) && $now >= $self->{frame_started} + $LIMIT->{handshake_seconds}) {
        $self->_fail('framing_timeout', 'fixed partial-frame deadline expired');
        return;
    }
    if (defined($self->{progress_deadline}) && $now >= $self->{progress_deadline}) {
        $self->_fail('write_timeout', 'queued bytes made no delivery progress');
        return;
    }
    my $select = IO::Select->new($self->{handle});
    $self->_read_ready($now) if $select->can_read(0);
    return if $self->{closed};
    $self->_write_ready($now, $check) if $self->{progress_deadline} && $select->can_write(0);
    return;
}

sub close {
    my ($self) = @_;
    _error('unexpected close arguments') unless @_ == 1;
    _owner($self);
    return $self->{close_ok} if $self->{closed};
    $self->{closed} = 1;
    if (my $publication = $self->{accept_publication}) {
        unless ($publication->{state} eq 'written') {
            $publication->{state} = 'failed';
            $publication->{failure} //= $self->{failure} ? {%{$self->{failure}}}
                : {status => 'cancelled', diagnostic => 'connection closed before complete ACCEPT write'};
        }
    }
    $self->{close_ok} = CORE::close(delete $self->{handle}) ? 1 : 0;
    $self->{failure} //= {status => 'host_error', diagnostic => 'socket close failed'}
        unless $self->{close_ok};
    $self->{input} = '';
    delete $self->{received};
    $self->{active} = undef;
    $self->{queues} = {control => [], stream => []};
    $self->{queued_bytes} = {control => 0, stream => 0};
    return $self->{close_ok};
}

sub discard_inherited {
    my ($self) = @_;
    _error('expected inherited connection') unless @_ == 1
        && ref($self) eq __PACKAGE__ && $self->{owner_pid} != $$
        && defined($self->{owner_identity}) && $self->{owner_identity} == refaddr($self);
    CORE::close(delete $self->{handle}) if $self->{handle};
    $self->{closed} = 1;
    return;
}

1;
