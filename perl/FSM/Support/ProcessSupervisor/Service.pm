package FSM::Support::ProcessSupervisor::Service;

use strict;
use warnings;

use Errno qw(EAGAIN EINTR EWOULDBLOCK);
use IO::Select;
use Math::BigInt;
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime);
use FSM::Support::ProcessSupervisor::Connection ();
use FSM::Support::ProcessSupervisor::Endpoint ();
use FSM::Support::ProcessSupervisor::Wire ();

# Inactive transport admission only. The service takes ownership of its run;
# the trusted caller owns job admission, child slots and any later ACCEPT/exec.
# A taken request remains subject to its original admission wall. This module
# deliberately provides no command launch or post-ACCEPT lifecycle API.
my $LIMIT = FSM::Support::ProcessSupervisor::Wire::limits();
my $SECOND = 1_000_000_000;

sub _error { die "private process service: $_[0]\n" }
sub _now_ns { return sprintf('%.0f', clock_gettime(CLOCK_MONOTONIC) * $SECOND) }
sub _time {
    return Math::BigInt->new(FSM::Support::ProcessSupervisor::Wire::_uint(
        $_[0], '18446744073709551615', 1));
}
sub _minimum {
    my $value = shift;
    for (@_) { $value = $_ if $_->bcmp($value) < 0; }
    return $value->copy;
}
sub _window { return $_[0]->copy->badd($LIMIT->{handshake_seconds} * $SECOND) }
sub _owner {
    my ($self) = @_;
    _error('invalid service handle') unless ref($self) eq __PACKAGE__;
    _error('inherited service cannot be reused') unless $self->{owner_pid} == $$;
}

sub new_service {
    _error('expected endpoint run and original deadline') unless @_ == 2;
    my ($run, $deadline_ns) = @_;
    _error('expected an owned endpoint run')
        unless ref($run) eq 'FSM::Support::ProcessSupervisor::Endpoint';
    my $context = FSM::Support::ProcessSupervisor::Wire::decode_context($run->context);
    my $deadline = _time($deadline_ns);
    _error('original deadline already expired') if $deadline->bcmp(_time(_now_ns())) <= 0;
    return bless {
        owner_pid => $$, run => $run, identity => $context->{run}, deadline => $deadline,
        parents => {1 => {token => $context->{token}, deadline => $deadline->copy}},
        high_parent => 1, next_ticket => 1, records => {}, order => [], closed => 0,
    }, __PACKAGE__;
}

sub context {
    _error('unexpected context arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    _error('root authority is no longer live') unless !$self->{closed} && $self->{parents}{1}
        && $self->{deadline}->bcmp(_time(_now_ns())) > 0;
    return $self->{run}->context;
}

sub register_parent {
    _error('expected job identity and original ancestor-clipped deadline') unless @_ == 3;
    my ($self, $id, $deadline_ns) = @_; _owner($self);
    _error('service is closed') if $self->{closed};
    FSM::Support::ProcessSupervisor::Wire::_uint($id, '4294967295', 1);
    _error('parent identity is reused or out of order') if $id <= $self->{high_parent};
    _error('live authority capacity exhausted') if keys(%{$self->{parents}}) >= $LIMIT->{jobs};
    my $deadline = _time($deadline_ns);
    _error('invalid parent lifetime') if $deadline->bcmp(_time(_now_ns())) <= 0
        || $deadline->bcmp($self->{deadline}) > 0 || !$self->{parents}{1};
    my $token = FSM::Support::ProcessSupervisor::Endpoint::new_job_token();
    my $context = $self->{run}->context_for($id, $token);
    $self->{parents}{$id} = {token => $token, deadline => $deadline};
    $self->{high_parent} = 0 + $id;
    return $context;
}

sub _fail_record {
    my ($self, $record, $status, $diagnostic) = @_;
    $record->{failure} //= $record->{io}->failure // {status => $status, diagnostic => $diagnostic};
    delete $record->{request};
    $record->{state} = 'closed';
    $self->{descriptor_cleanup_failed} = 1 unless $record->{io}->close;
}

sub _revoke {
    my ($self, $id, $status, $diagnostic) = @_;
    # Authority is removed before any descriptor cleanup can run.
    delete $self->{parents}{$id};
    for my $record (values %{$self->{records}}) {
        next unless defined($record->{parent}) && $record->{parent} == $id;
        $self->_fail_record($record, $status, $diagnostic);
    }
}

sub revoke_parent {
    _error('expected one parent identity') unless @_ == 2;
    my ($self, $id) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_uint($id, '4294967295', 1);
    if ($id == 1) {
        $self->{failure} //= {status => 'authority_revoked', diagnostic => 'root authority is no longer live'};
        $self->close;
        return;
    }
    $self->_revoke($id, 'authority_revoked', 'parent authority is no longer live');
    return;
}

sub _accept_once { return accept(${$_[0]}, $_[1]) }

sub _accept {
    my ($self, $now) = @_;
    # Closed outcomes still occupy their slots until the owner consumes them.
    # At capacity, the kernel backlog remains unaccepted, never a job record.
    return if @{$self->{order}} >= $LIMIT->{connections};
    return unless IO::Select->new($self->{run}->listener)->can_read(0);
    if ($self->{next_ticket} > 4_294_967_295) {
        $self->{failure} //= {status => 'host_error', diagnostic => 'connection identity exhausted'};
        $self->close;
        return;
    }
    my $peer = _accept_once(\my $handle, $self->{run}->listener);
    unless (defined $peer) {
        return if $! == EAGAIN || $! == EWOULDBLOCK || $! == EINTR;
        $self->{failure} //= {status => 'host_error', diagnostic => 'socket accept failed'};
        $self->close;
        return;
    }
    my $io = eval { FSM::Support::ProcessSupervisor::Connection::new_connection(
        $handle, $self->{deadline}->numify / $SECOND) };
    unless ($io) {
        CORE::close($handle);
        $self->{failure} //= {status => 'host_error', diagnostic => 'accepted descriptor admission failed'};
        $self->close;
        return;
    }
    my $ticket = $self->{next_ticket}++;
    my $record = {ticket => $ticket, io => $io, state => 'hello',
        wall => _minimum(_window($now), $self->{deadline})};
    $self->{records}{$ticket} = $record;
    push @{$self->{order}}, $ticket;
    $self->_fail_record($record, 'host_error', 'accepted descriptor sealing failed') if $io->failure;
}

sub _message {
    my ($self, $record, $message, $now) = @_;
    if ($record->{state} eq 'hello' && $message->{type} eq 'HELLO') {
        my $parent = $self->{parents}{$message->{parent}};
        unless ($message->{run} eq $self->{identity} && $parent
            && $message->{token} eq $parent->{token} && $parent->{deadline}->bcmp($now) > 0) {
            $self->_fail_record($record, 'invocation_error', 'invalid or expired parent authority');
            return;
        }
        $record->{parent} = $message->{parent};
        $record->{hello_ns} = $now->copy;
        $record->{wall} = _minimum(_window($now), $parent->{deadline}, $self->{deadline});
        $record->{state} = 'spawn';
        $record->{io}->queue({type => 'READY', run => $self->{identity}, parent => $record->{parent}});
        return;
    }
    if ($record->{state} eq 'spawn' && $message->{type} eq 'SPAWN') {
        my $start = Math::BigInt->new($message->{started_ns});
        my $earliest = $record->{hello_ns}->copy->bsub($LIMIT->{handshake_seconds} * $SECOND);
        unless ($start->bcmp($earliest) >= 0 && $start->bcmp($record->{hello_ns}) <= 0
            && $start->bcmp($now) <= 0) {
            $self->_fail_record($record, 'invocation_error', 'invocation timestamp outside HELLO window');
            return;
        }
        my $parent = $self->{parents}{$record->{parent}};
        unless ($parent) {
            $self->_fail_record($record, 'authority_revoked', 'parent authority is no longer live');
            return;
        }
        my $execution = $start->copy->badd(Math::BigInt->new($message->{timeout_seconds})->bmul($SECOND));
        $record->{deadline} = _minimum($execution, $parent->{deadline}, $self->{deadline});
        $record->{wall} = _minimum($record->{wall}, $record->{deadline});
        if ($record->{wall}->bcmp($now) <= 0) {
            $self->_fail_record($record, 'timed_out', 'original invocation deadline expired');
            return;
        }
        $record->{request} = $message;
        $record->{state} = 'request';
        return;
    }
    $self->_fail_record($record, 'protocol_error', 'unexpected or repeated client message');
}

sub advance {
    _error('unexpected advancement arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    return if $self->{closed};
    my $now = _time(_now_ns());
    if ($now->bcmp($self->{deadline}) >= 0) {
        $self->{failure} //= {status => 'timed_out', diagnostic => 'original run deadline expired'};
        $self->close;
        return;
    }
    for my $id (keys %{$self->{parents}}) {
        $self->_revoke($id, 'timed_out', 'parent invocation deadline expired')
            if $self->{parents}{$id}{deadline}->bcmp($now) <= 0;
    }
    $self->_accept($now);
    return if $self->{closed};
    # Rotate before every pass; each descriptor gets at most one bounded
    # advancement and one decoded message. There is no private waiting loop.
    push @{$self->{order}}, shift @{$self->{order}} if @{$self->{order}} > 1;
    for my $ticket (@{$self->{order}}) {
        my $record = $self->{records}{$ticket};
        next if $record->{state} eq 'closed';
        if ($now->bcmp($record->{wall}) >= 0) {
            $self->_fail_record($record, 'timed_out', 'fixed authentication or admission deadline expired');
            next;
        }
        $record->{io}->advance;
        if (my $failure = $record->{io}->failure) {
            $self->_fail_record($record, $failure->{status}, $failure->{diagnostic});
            next;
        }
        my $message = $record->{io}->take_frame;
        if ($message) {
            my $received = _time(_now_ns());
            if ($received->bcmp($record->{wall}) >= 0) {
                $self->_fail_record($record, 'timed_out', 'fixed authentication or admission deadline expired');
                next;
            }
            $self->_message($record, $message, $received);
        }
    }
    return;
}

sub take_request {
    _error('unexpected request arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    for my $ticket (@{$self->{order}}) {
        my $record = $self->{records}{$ticket};
        next unless $record->{state} eq 'request';
        my $now = _time(_now_ns());
        unless ($self->{parents}{$record->{parent}} && $now->bcmp($record->{wall}) < 0) {
            $self->_fail_record($record, 'timed_out', 'original request admission deadline expired');
            next;
        }
        # Taking a snapshot grants no command authority and does not renew
        # admission. Later owner integration must recheck before publication.
        $record->{state} = 'handed';
        return {ticket => $ticket, parent => $record->{parent},
            deadline_ns => $record->{deadline}->bstr, request => delete $record->{request}};
    }
    return;
}

sub retire {
    _error('expected one connection ticket') unless @_ == 2;
    my ($self, $ticket) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_uint($ticket, '4294967295', 1);
    my $record = $self->{records}{$ticket} or _error('unknown connection ticket');
    $self->_fail_record($record, 'cancelled', 'private owner retired the connection');
    return;
}

sub take_closed {
    _error('unexpected outcome arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    for my $ticket (@{$self->{order}}) {
        my $record = $self->{records}{$ticket};
        next unless $record->{state} eq 'closed';
        delete $self->{records}{$ticket};
        @{$self->{order}} = grep { $_ != $ticket } @{$self->{order}};
        return {ticket => $ticket, parent => $record->{parent}, %{$record->{failure}}};
    }
    return;
}

sub poll_delay {
    _error('unexpected poll arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    return 0 if $self->{closed};
    my $now = _time(_now_ns());
    my $wall = $self->{deadline}->copy;
    for my $parent (values %{$self->{parents}}) { $wall = _minimum($wall, $parent->{deadline}); }
    my $delay = $LIMIT->{idle_seconds};
    for my $record (values %{$self->{records}}) {
        next if $record->{state} eq 'closed';
        $wall = _minimum($wall, $record->{wall});
        my $io_delay = $record->{io}->poll_delay;
        $delay = $io_delay if $io_delay < $delay;
    }
    my $remaining = $wall->bsub($now)->numify / $SECOND;
    return 0 if $remaining <= 0;
    return $remaining < $delay ? $remaining : $delay;
}

sub counts {
    _error('unexpected count arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    return {parents => scalar keys %{$self->{parents}}, connections => scalar @{$self->{order}},
        open => scalar grep { $_->{state} ne 'closed' } values %{$self->{records}}};
}
sub failure {
    _error('unexpected failure arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    return $self->{failure} ? {%{$self->{failure}}} : undef;
}
sub close {
    _error('unexpected close arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    return {%{$self->{cleanup}}} if $self->{closed};
    $self->{closed} = 1;
    $self->{parents} = {};
    my $failure = $self->{failure} // {status => 'cancelled', diagnostic => 'private service closed'};
    $self->_fail_record($_, $failure->{status}, $failure->{diagnostic}) for values %{$self->{records}};
    $self->{cleanup} = $self->{run}->close;
    if ($self->{descriptor_cleanup_failed}) {
        $self->{cleanup}{ok} = 0;
        $self->{cleanup}{diagnostic} = 'accepted descriptor cleanup incomplete; ' . $self->{cleanup}{diagnostic};
    }
    $self->{failure} //= {status => 'cleanup_failed', diagnostic => 'private endpoint cleanup failed'}
        unless $self->{cleanup}{ok};
    return {%{$self->{cleanup}}};
}
sub discard_inherited {
    _error('expected inherited service') unless @_ == 1
        && ref($_[0]) eq __PACKAGE__ && $_[0]{owner_pid} != $$;
    my ($self) = @_;
    $_->{io}->discard_inherited for values %{$self->{records}};
    $self->{run}->discard_inherited;
    $self->{parents} = {};
    $self->{records} = {};
    $self->{order} = [];
    $self->{closed} = 1;
    return;
}

1;
