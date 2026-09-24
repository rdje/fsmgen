package FSM::Support::ProcessSupervisor::Service;

use strict;
use warnings;

use Errno qw(EAGAIN EINTR EWOULDBLOCK);
use IO::Select;
use Math::BigInt;
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime);
use FSM::Support::ProcessSupervisor::Connection ();
use FSM::Support::ProcessSupervisor::Endpoint ();
use FSM::Support::ProcessSupervisor::Reservation ();
use FSM::Support::ProcessSupervisor::Wire ();

# Inactive transport admission only. A standalone service owns its endpoint;
# a shared service borrows it until the aggregate native owner retires the run.
# The trusted caller owns ledger admission, native readiness and exec release.
# Service binds a handed request to its ready job context and tracked ACCEPT;
# local publication remains subject to the original admission wall. This module
# provides no command launch or post-exec result lifecycle API.
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
    _error('invalid or copied service handle') unless ref($self) eq __PACKAGE__
        && defined($self->{owner_identity}) && $self->{owner_identity} == refaddr($self);
    _error('inherited service cannot be reused') unless $self->{owner_pid} == $$;
}

sub new_service {
    _error('expected endpoint run and original deadline') unless @_ == 2;
    return _new_service(@_, 0);
}

sub new_shared_service {
    _error('expected shared endpoint run and original deadline') unless @_ == 2;
    return _new_service(@_, 1);
}

sub _new_service {
    my ($run, $deadline_ns, $shared) = @_;
    _error('expected an owned endpoint run')
        unless ref($run) eq 'FSM::Support::ProcessSupervisor::Endpoint';
    my $encoded = $run->context;
    my $context = FSM::Support::ProcessSupervisor::Wire::decode_context($encoded);
    my $deadline = _time($deadline_ns);
    _error('original deadline already expired') if $deadline->bcmp(_time(_now_ns())) <= 0;
    my $self = bless {
        owner_pid => $$, run => $run, identity => $context->{run}, deadline => $deadline,
        shared_run => $shared,
        parents => {1 => {state => 'ready', token => $context->{token},
            context => $encoded, deadline => $deadline->copy}},
        high_parent => 1, next_ticket => 1, records => {}, order => [], closed => 0,
    }, __PACKAGE__;
    $self->{owner_identity} = refaddr($self);
    return $self;
}

sub context {
    _error('unexpected context arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    _error('root authority is no longer live') unless !$self->{closed} && $self->{parents}{1}
        && $self->{deadline}->bcmp(_time(_now_ns())) > 0;
    return $self->parent_context(1);
}

sub _check_parent_live {
    my ($self, $id, $record) = @_;
    _error('parent authority is no longer retained') unless !$self->{closed}
        && $self->{parents}{1} && $self->{parents}{$id}
        && refaddr($self->{parents}{$id}) == refaddr($record);
    my $now = _time(_now_ns());
    if ($now->bcmp($self->{deadline}) >= 0 || $now->bcmp($record->{deadline}) >= 0) {
        $record->{failure} //= {status => 'timed_out', diagnostic => 'original parent lifetime expired'}
            if $record->{state} eq 'preparing';
        _error('original parent lifetime expired');
    }
    my $run = $self->{run}->observation;
    _error('parent endpoint is no longer ready') unless $run->{phase} eq 'ready' && !$run->{closed};
    return;
}

sub parent_context {
    _error('expected one original parent identity') unless @_ == 2;
    my ($self, $id) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_uint($id, '4294967295', 1);
    my $record = $self->{parents}{$id} or _error('unknown or revoked parent authority');
    _error('parent authority preparation is not complete') unless $record->{state} eq 'ready';
    $self->_check_parent_live($id, $record);
    return $record->{context};
}

sub parent_observation {
    _error('expected one retained parent identity') unless @_ == 2;
    my ($self, $id) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_uint($id, '4294967295', 1);
    my $record = $self->{parents}{$id} or _error('unknown or revoked parent authority');
    # Preparation state is a historical fact, not current submission authority.
    # Inspecting it never exposes a token or replaces parent_context's checks.
    return {parent => 0 + $id, state => $record->{state},
        deadline_ns => $record->{deadline}->bstr,
        failure => $record->{failure} ? {%{$record->{failure}}} : undef};
}

sub register_parent {
    _error('expected job identity, original deadline and optional token admission')
        unless @_ == 3 || (@_ == 4 && ref($_[3]) eq 'CODE');
    my ($self, $id, $deadline_ns, $check) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_uint($id, '4294967295', 1);
    my $deadline = _time($deadline_ns);
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        # Validate before spending an identity, then retain the original record
        # before entropy effects. Failed preparation consumes its bounded slot
        # until explicit revocation, and the identity can never be reused.
        _error('service is closed') if $self->{closed};
        _error('parent identity is reused or out of order') if $id <= $self->{high_parent};
        _error('live authority capacity exhausted') if keys(%{$self->{parents}}) >= $LIMIT->{jobs};
        _error('invalid parent lifetime') if $deadline->bcmp(_time(_now_ns())) <= 0
            || $deadline->bcmp($self->{deadline}) > 0 || !$self->{parents}{1};
        my $record = $self->{parents}{$id} = {state => 'preparing', deadline => $deadline};
        $self->{high_parent} = 0 + $id;
        my $ok = eval {
            $self->_check_parent_live($id, $record);
            $record->{token} = FSM::Support::ProcessSupervisor::Endpoint::new_job_token(sub {
                # Each native open/read needs current original authority. A
                # caller check can revoke it or consume time before returning.
                $self->_check_parent_live($id, $record);
                $check->($self, $id, @_) if $check;
                $self->_check_parent_live($id, $record);
            });
            $self->_check_parent_live($id, $record);
            $record->{context} = $self->{run}->context_for($id, $record->{token});
            $self->_check_parent_live($id, $record);
            $record->{state} = 'ready';
            1;
        };
        unless ($ok) {
            my $error = $@;
            $record->{state} = 'failed';
            $record->{failure} //= {status => 'host_error', diagnostic => 'parent authority preparation failed'};
            die $error;
        }
    });
    # Fresh lookup also refuses closure/expiry from a pre-return handler.
    return $self->parent_context($id);
}

sub _fail_record {
    my ($self, $record, $status, $diagnostic) = @_;
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        $record->{failure} //= ($record->{io} ? $record->{io}->failure : undef)
            // {status => $status, diagnostic => $diagnostic};
        delete $record->{request};
        $record->{state} = 'closing';
        my $error;
        if ($record->{io}) {
            my $ok = eval {
                $record->{close_failed} = 1 unless $record->{io}->close;
                delete $record->{close_interrupted};
                1;
            };
            unless ($ok) { $error = $@; $record->{close_interrupted} = 1; }
        }
        # Retain the original accept handle even when Connection has removed
        # its own field before close. Never substitute a remembered FD number.
        for my $handle (@{_record_handles($record)}) {
            my $ok = eval { $record->{close_failed} = 1 unless _close_once($handle); 1 };
            unless ($ok) { $error //= $@; $record->{close_failed} = 1; }
        }
        $self->{descriptor_cleanup_failed} = 1 if $record->{close_failed};
        $record->{state} = 'closed'
            unless $record->{close_interrupted} || @{_record_handles($record)};
        die $error if defined $error;
    });
    return;
}

sub _record_handles {
    my ($record) = @_;
    my %seen;
    return [grep { defined($_) && defined(fileno($_)) && !$seen{refaddr($_)}++ }
        $record->{handle}, $record->{io} ? $record->{io}->handle : ()];
}
sub _close_once { return CORE::close($_[0]) }

sub _revoke {
    my ($self, $id, $status, $diagnostic) = @_;
    # Authority is removed before any descriptor cleanup can run.
    delete $self->{parents}{$id};
    for my $record (values %{$self->{records}}) {
        next unless (defined($record->{parent}) && $record->{parent} == $id)
            || (defined($record->{job}) && $record->{job} == $id);
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
    my ($self, $now, $check) = @_;
    my $record;
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            # Recheck after any pre-mask handler. Closed outcomes still occupy
            # slots; a saturated backlog receives no ticket or native effect.
            return if $self->{closed} || @{$self->{order}} >= $LIMIT->{connections};
            return unless IO::Select->new($self->{run}->listener)->can_read(0);
            if ($self->{next_ticket} > 4_294_967_295) {
                $self->{failure} //= {status => 'host_error', diagnostic => 'connection identity exhausted'};
                $self->close;
                return;
            }
            my $ticket = $self->{next_ticket}++;
            $record = {ticket => $ticket, state => 'accepting',
                wall => _minimum(_window($now), $self->{deadline})};
            $self->{records}{$ticket} = $record;
            push @{$self->{order}}, $ticket;
            if ($check) {
                my $admitted = $check->($self, $ticket);
                _error('accept admission must return a boolean') unless defined($admitted)
                    && !ref($admitted) && "$admitted" =~ /\A[01]\z/;
                unless ($admitted) { $self->_forget_empty($record); return; }
            }
            _error('accept admission is no longer live') if $self->{closed}
                || $record->{state} ne 'accepting' || !$self->{parents}{1};
            _error('original accept admission wall expired')
                if _time(_now_ns())->bcmp($record->{wall}) >= 0;
            # Publish directly into the retained record. Construction borrows
            # this handle; the record keeps custody through every close path.
            my $peer = _accept_once(\$record->{handle}, $self->{run}->listener);
            unless (defined $peer) {
                my $transient = $! == EAGAIN || $! == EWOULDBLOCK || $! == EINTR;
                if ($transient && !@{_record_handles($record)}) {
                    $self->_forget_empty($record);
                    return;
                }
                $self->{failure} //= {status => 'host_error', diagnostic => 'socket accept failed'};
                $self->close;
                return;
            }
            $record->{io} = FSM::Support::ProcessSupervisor::Connection::new_connection(
                $record->{handle}, $self->{deadline}->numify / $SECOND);
            $record->{state} = 'hello';
            $self->_fail_record($record, 'host_error', 'accepted descriptor sealing failed')
                if $record->{io}->failure;
        });
        1;
    };
    unless ($ok) {
        my $error = $@;
        $self->{failure} //= {status => 'host_error', diagnostic => 'accepted descriptor admission interrupted'};
        # Preserve the original exception if cleanup also throws. The original
        # service and raw handles remain inspectable and retryable by the owner.
        my $closed = eval { $self->close; 1 };
        $self->{cleanup_interruption} //= 'accepted descriptor cleanup interrupted' unless $closed;
        die $error;
    }
    return;
}

sub _forget_empty {
    my ($self, $record) = @_;
    _error('cannot forget a native accepted handle') if @{_record_handles($record)};
    delete $self->{records}{$record->{ticket}};
    @{$self->{order}} = grep { $_ != $record->{ticket} } @{$self->{order}};
    return;
}

sub _message {
    my ($self, $record, $message, $now) = @_;
    if ($record->{state} eq 'hello' && $message->{type} eq 'HELLO') {
        my $parent = $self->{parents}{$message->{parent}};
        unless ($message->{run} eq $self->{identity} && $parent && $parent->{state} eq 'ready'
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
    if ($record->{state} eq 'bound' && $message->{type} eq 'CANCEL'
        && $message->{job} == $record->{job}) {
        $self->_fail_record($record, 'cancelled', 'client cancelled its admitted job');
        return;
    }
    $self->_fail_record($record, 'protocol_error', 'unexpected or repeated client message');
}

sub advance {
    _error('expected optional native accept admission')
        unless @_ == 1 || (@_ == 2 && ref($_[1]) eq 'CODE');
    my ($self, $check) = @_; _owner($self);
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
    $self->_accept($now, $check);
    return if $self->{closed};
    # Rotate before every pass; each descriptor gets at most one bounded
    # advancement and one decoded message. There is no private waiting loop.
    push @{$self->{order}}, shift @{$self->{order}} if @{$self->{order}} > 1;
    for my $ticket (@{$self->{order}}) {
        my $record = $self->{records}{$ticket};
        next if $record->{state} eq 'closed';
        if ($record->{state} eq 'closing') {
            $self->_fail_record($record, 'host_error', 'accepted descriptor cleanup incomplete');
            next;
        }
        if ($now->bcmp($record->{wall}) >= 0) {
            $self->_fail_record($record, 'timed_out', 'fixed authentication or admission deadline expired');
            next;
        }
        if ($record->{state} eq 'bound') {
            $record->{io}->advance(sub { $self->_write_admission($record, @_) });
        }
        else { $record->{io}->advance; }
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

# The aggregate supplies a slot in its original retained peer entry BEFORE
# calling. Publish into that slot before releasing Service custody; a creator
# signal may interrupt the return but cannot strand the original snapshot.
# This transfers data only, never job admission or permission to execute.
sub transfer_request {
    _error('expected original ticket and empty retained request slot') unless @_ == 3;
    my ($self, $ticket, $target) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_uint($ticket, '4294967295', 1);
    _request_target($target);
    my $transferred = 0;
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        # A pre-mask handler may have filled the destination, closed this
        # peer or consumed its request. Never overwrite that newer state.
        _request_target($target);
        my $record = $self->{records}{$ticket} or _error('unknown connection ticket');
        _error('ticket has no pending original request')
            unless $record->{state} eq 'request' && $record->{request};
        my $parent = $self->{parents}{$record->{parent}};
        if ($self->{closed} || !$parent) {
            $self->_fail_record($record, 'authority_revoked', 'parent authority is no longer live');
            return;
        }
        my $now = _time(_now_ns());
        if (grep { $now->bcmp($_) >= 0 }
            $record->{wall}, $record->{deadline}, $parent->{deadline}, $self->{deadline}) {
            $self->_fail_record($record, 'timed_out', 'original request admission deadline expired');
            return;
        }
        $$target = {ticket => $ticket, parent => $record->{parent},
            deadline_ns => $record->{deadline}->bstr,
            admission_deadline_ns => $record->{wall}->bstr, request => $record->{request}};
        delete $record->{request};
        $record->{state} = 'handed';
        $transferred = 1;
    });
    return $transferred;
}

sub _request_target {
    my ($target) = @_;
    # Native scalar custody only: a tied STORE is an arbitrary callback and
    # cannot provide the same assignment-before-release guarantee.
    _error('request target must be an empty untied scalar slot')
        unless ref($target) eq 'SCALAR' && !defined(tied($$target)) && !defined($$target);
    return;
}

# Retain only a transport/context association here. The caller must already
# own the actual ledger grant and ready gated job; no numeric id proves those.
sub queue_accept {
    _error('expected original ticket and ready job identity') unless @_ == 3;
    my ($self, $ticket, $job) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_uint($_, '4294967295', 1) for $ticket, $job;
    my $queued = 0;
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        my $record = $self->{records}{$ticket} or _error('unknown connection ticket');
        _error('ACCEPT requires one unbound handed request')
            unless $record->{state} eq 'handed' && !defined($record->{job});
        my $context = $self->{parents}{$job};
        _error('ACCEPT requires a ready original child context') unless $context
            && $context->{state} eq 'ready' && $job > $record->{parent};
        _error('job context already belongs to a request') if defined($context->{request_ticket});
        _error('job context exceeds original request lifetime')
            if $context->{deadline}->bcmp($record->{deadline}) > 0;
        # Spend the association before queue effects or a thrown return. The
        # ready context retains this ticket even after its outcome is consumed.
        $record->{job} = 0 + $job;
        $record->{state} = 'bound';
        $context->{request_ticket} = 0 + $ticket;
        my $ok = eval {
            if ($self->_bound_live($record)) {
                $queued = $record->{io}->queue_accept($job);
                $self->_fail_record($record, 'host_error', 'ACCEPT queue admission failed') unless $queued;
            }
            1;
        };
        unless ($ok) {
            my $error = $@;
            eval { $self->_fail_record($record, 'host_error', 'ACCEPT queue publication interrupted'); 1 };
            die $error;
        }
    });
    return $queued;
}

sub _bound_live {
    my ($self, $record) = @_;
    return 0 if $record->{state} ne 'bound';
    my $parent = $self->{parents}{$record->{parent}};
    my $job = $self->{parents}{$record->{job}};
    if ($self->{closed} || !$self->{parents}{1} || !$parent || $parent->{state} ne 'ready'
        || !$job || $job->{state} ne 'ready' || !defined($job->{request_ticket})
        || $job->{request_ticket} != $record->{ticket}) {
        $self->_fail_record($record, 'authority_revoked', 'original request or job authority is no longer live');
        return 0;
    }
    my $now = _time(_now_ns());
    if (grep { $now->bcmp($_) >= 0 }
        $record->{wall}, $record->{deadline}, $parent->{deadline}, $job->{deadline}, $self->{deadline}) {
        $self->_fail_record($record, 'timed_out', 'original ACCEPT admission deadline expired');
        return 0;
    }
    my $run = $self->{run}->observation;
    unless ($run->{phase} eq 'ready' && !$run->{closed}) {
        $self->_fail_record($record, 'host_error', 'original ACCEPT endpoint is no longer ready');
        return 0;
    }
    return 1;
}

sub _write_admission {
    my ($self, $record, $io) = @_; _owner($self);
    _error('write admission requires the original retained peer')
        unless $self->{records}{$record->{ticket}}
            && refaddr($self->{records}{$record->{ticket}}) == refaddr($record)
            && refaddr($record->{io}) == refaddr($io);
    return 0 unless $self->_bound_live($record);
    # Connection has just advanced its bounded read. A complete cancellation
    # or foreign/repeated message must close this peer before another write.
    if (my $message = $io->take_frame) {
        $self->_message($record, $message, _time(_now_ns()));
        return 0;
    }
    return 1;
}

sub accept_publication {
    _error('expected one retained connection ticket') unless @_ == 2;
    my ($self, $ticket) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_uint($ticket, '4294967295', 1);
    my $record = $self->{records}{$ticket} or _error('unknown connection ticket');
    return unless defined($record->{job});
    # Both layers are copied historical observations, never live exec authority.
    return {ticket => $record->{ticket}, parent => $record->{parent}, job => $record->{job},
        state => $record->{state}, deadline_ns => $record->{deadline}->bstr,
        admission_deadline_ns => $record->{wall}->bstr,
        write => scalar($record->{io}->accept_publication),
        failure => $record->{failure} ? {%{$record->{failure}}} : undef};
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
    my $outcome;
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        for my $ticket (@{$self->{order}}) {
            my $record = $self->{records}{$ticket};
            next unless $record->{state} eq 'closed';
            _error('closed outcome still owns native handles') if @{_record_handles($record)};
            $outcome = {ticket => $ticket, parent => $record->{parent}, %{$record->{failure}},
                defined($record->{job}) ? (job => $record->{job}) : (),
                resources_closed => $record->{close_failed} ? 0 : 1};
            $self->_forget_empty($record);
            last;
        }
    });
    return $outcome;
}

sub tickets {
    _error('unexpected ticket inventory arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    return [sort { $a <=> $b } keys %{$self->{records}}];
}
sub ticket_observation {
    _error('expected one retained connection ticket') unless @_ == 2;
    my ($self, $ticket) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_uint($ticket, '4294967295', 1);
    my $record = $self->{records}{$ticket} or _error('unknown connection ticket');
    return {ticket => $record->{ticket}, state => $record->{state}, parent => $record->{parent},
        defined($record->{job}) ? (job => $record->{job}) : (),
        wall_ns => $record->{wall}->bstr, handles => scalar @{_record_handles($record)},
        resources_closed => $record->{state} eq 'closed' && !$record->{close_failed}
            && !@{_record_handles($record)} ? 1 : 0,
        failure => $record->{failure} ? {%{$record->{failure}}} : undef};
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

# Include the owned or borrowed run and all accepted sockets, including handed
# requests. Closed peer outcomes retain slots but no handle. A closed shared
# service can still report its aggregate owner's live endpoint handles.
sub handles {
    _error('unexpected handles arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    return [@{$self->{run}->handles}, map { @{_record_handles($self->{records}{$_})} } @{$self->{order}}];
}

sub failure {
    _error('unexpected failure arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    return $self->{failure} ? {%{$self->{failure}}} : undef;
}
sub close {
    _error('unexpected close arguments') unless @_ == 1;
    my ($self) = @_; _owner($self);
    return {%{$self->{cleanup}}} if $self->{cleanup};
    my $pending;
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        # A handler may have completed close before this mask took effect.
        return if $self->{cleanup};
        $self->{closed} = 1;
        $self->{parents} = {};
        my $failure = $self->{failure} // {status => 'cancelled', diagnostic => 'private service closed'};
        $self->_fail_record($_, $failure->{status}, $failure->{diagnostic}) for values %{$self->{records}};
        if (grep { $_->{state} ne 'closed' } values %{$self->{records}}) {
            # A failed close can leave an actual handle alive. Keep the run
            # and original records retryable; cache only completed cleanup.
            $self->{failure} //= {status => 'cleanup_failed', diagnostic => 'accepted descriptor cleanup incomplete'};
            $pending = {ok => 0, pending => 1, endpoint_retained => 1,
                socket_removed => 0, directory_removed => 0,
                diagnostic => 'accepted descriptor cleanup incomplete'};
            return;
        }
        $self->{cleanup} = $self->{shared_run}
            ? {ok => 1, endpoint_retained => 1, socket_removed => 0, directory_removed => 0,
                diagnostic => 'shared endpoint retained by aggregate owner'}
            : $self->{run}->close;
        if ($self->{descriptor_cleanup_failed}) {
            $self->{cleanup}{ok} = 0;
            $self->{cleanup}{diagnostic} = 'accepted descriptor cleanup incomplete; ' . $self->{cleanup}{diagnostic};
        }
        $self->{failure} //= {status => 'cleanup_failed', diagnostic => 'private endpoint cleanup failed'}
            unless $self->{cleanup}{ok};
    });
    return $pending // {%{$self->{cleanup}}};
}
sub discard_inherited {
    _error('expected inherited service') unless @_ == 1
        && ref($_[0]) eq __PACKAGE__ && $_[0]{owner_pid} != $$
        && defined($_[0]{owner_identity}) && $_[0]{owner_identity} == refaddr($_[0]);
    my ($self) = @_;
    for my $record (values %{$self->{records}}) {
        $record->{io}->discard_inherited if $record->{io};
        CORE::close($record->{handle})
            if $record->{handle} && defined(fileno($record->{handle}));
    }
    $self->{run}->discard_inherited;
    $self->{parents} = {};
    $self->{records} = {};
    $self->{order} = [];
    $self->{closed} = 1;
    return;
}

1;
