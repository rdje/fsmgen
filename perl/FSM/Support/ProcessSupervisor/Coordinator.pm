package FSM::Support::ProcessSupervisor::Coordinator;

use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime);
use FSM::Support::ProcessSupervisor::Admission ();
use FSM::Support::ProcessSupervisor::Endpoint ();
use FSM::Support::ProcessSupervisor::Reservation ();
use FSM::Support::ProcessSupervisor::ReservedJob ();
use FSM::Support::ProcessSupervisor::Service ();
use FSM::Support::ProcessSupervisor::Wire ();

# Inactive native owner. Original grants retain root/nested gated jobs through
# bounded cleanup, alongside original accepted-peer descriptor grants.
# Root execution release is explicit; nested release, outcome delivery and
# fair scheduling follow.
# Preparing this object allocates no descriptor, token, path or process.
my $COST = FSM::Support::ProcessSupervisor::Endpoint::resource_cost();
my $JOB_COST = FSM::Support::ProcessSupervisor::GatedPair::resource_cost();
my $LIMIT = FSM::Support::ProcessSupervisor::Wire::limits();
my ($TERM, $KILL) = FSM::Support::ProcessSupervisor::_termination_graces();
sub _error { die "private process coordinator: $_[0]\n" }
sub _now_ns { return sprintf('%.0f', clock_gettime(CLOCK_MONOTONIC) * 1_000_000_000) }
sub _owner {
    my ($self) = @_;
    _error('invalid or copied coordinator') unless ref($self) eq __PACKAGE__
        && defined($self->{identity}) && $self->{identity} == refaddr($self);
    _error('inherited coordinator cannot be reused') unless $self->{owner_pid} == $$;
    for my $field (qw(run service)) {
        my $identity = $self->{$field . '_identity'};
        _error('lost or substituted original ' . ($field eq 'run' ? 'endpoint' : 'Service'))
            unless defined($identity)
                ? ref($self->{$field}) && refaddr($self->{$field}) == $identity
                : !defined($self->{$field});
    }
    # Keep the original key set separately: an omitted job must not silently
    # disappear from descriptor inventories or bounded cleanup.
    _error('lost original job inventory') unless keys(%{$self->{jobs}}) == keys(%{$self->{job_identities}});
    $self->_job_owner($_) for keys %{$self->{job_identities}};
}
sub _job_owner {
    my ($self, $id) = @_;
    my $entry = $self->{jobs}{$id};
    _error('lost or substituted original job entry') unless ref($entry) eq 'HASH'
        && refaddr($entry) == ($self->{job_identities}{$id} // 0);
    _error('lost or substituted original native job') unless defined($entry->{native_identity})
        ? ref($entry->{native}) && refaddr($entry->{native}) == $entry->{native_identity}
        : !defined($entry->{native});
    return $entry;
}
sub _failure {
    my ($self, $error) = @_;
    $self->{failure} //= FSM::Support::ProcessSupervisor::_sanitize_control($error);
}
sub prepare {
    my %args = @_;
    FSM::Support::ProcessSupervisor::Wire::_keys(\%args, 'snapshot');
    my $snapshot = FSM::Support::ProcessSupervisor::Wire::decode_frame('client',
        FSM::Support::ProcessSupervisor::Wire::encode_frame('client', $args{snapshot}));
    _error('expected original root execution snapshot') unless $snapshot->{type} eq 'SPAWN';
    my $ledger = FSM::Support::ProcessSupervisor::Admission::prepare(
        map { $_ => $snapshot->{$_} } qw(started_ns timeout_seconds));
    my $self = bless {owner_pid => $$, phase => 'prepared', ledger => $ledger,
        jobs => {1 => {grant => $ledger->root, snapshot => $snapshot}}, peers => {}}, __PACKAGE__;
    $self->{identity} = refaddr($self);
    $self->{job_identities} = {1 => refaddr($self->{jobs}{1})};
    return $self;
}
sub _begin_cleanup {
    my ($self) = @_;
    return if defined $self->{cleanup_deadline_ns};
    my $original = Math::BigInt->new($self->{ledger}->describe($self->{jobs}{1}{grant})->{deadline_ns});
    my $now = Math::BigInt->new(_now_ns());
    my $start = $original->bcmp($now) < 0 ? $original : $now;
    $self->{cleanup_deadline_ns} = $start->copy->badd(($TERM + $KILL) * 1_000_000_000)->bstr;
}
sub _before_run_allocation {
    my ($self, $kind, $operation) = @_; _owner($self);
    _error('unknown endpoint allocation operation') unless defined($operation)
        && !ref($operation) && $operation =~ /\A(?:entropy_open|entropy_read|ancestry_mkdir|run_mkdir|directory_open|socket_create|socket_bind|cwd_open|entries_open)\z/;
    if ($kind eq 'create') {
        _error('run creation is no longer admitted') unless $self->{phase} eq 'opening';
        $self->{ledger}->check_live($self->{jobs}{1}{grant});
    }
    elsif ($kind eq 'cleanup') {
        _error('creation operation cannot borrow cleanup credit')
            unless $operation eq 'cwd_open' || $operation eq 'entries_open';
        # Partial startup also uses this branch before open_run has returned.
        $self->_begin_cleanup;
        _error('original cleanup envelope expired')
            if Math::BigInt->new(_now_ns())->bcmp($self->{cleanup_deadline_ns}) >= 0
                || (defined($self->{native_cleanup_deadline})
                    && _now_ns() / 1_000_000_000 >= $self->{native_cleanup_deadline});
    }
    else { _error('unknown run allocation role'); }
    for my $entry (['run_grant', 'steady_descriptors'], ['scratch_grant', 'transient_descriptors']) {
        my ($field, $cost) = @$entry;
        my $held = $self->{ledger}->describe_descriptors($self->{$field});
        _error('run descriptor grant is insufficient') if $held->{count} < $COST->{$cost};
    }
    _error('run and cleanup scratch require distinct grants')
        if refaddr($self->{run_grant}) == refaddr($self->{scratch_grant});
    _error('aggregate descriptor capacity exceeded')
        if $self->{ledger}->usage->{charged_descriptors} > $LIMIT->{descriptors};
    return;
}
sub open_run {
    my ($self) = @_; _owner($self);
    _error('run opening is single-use') unless @_ == 1 && $self->{phase} eq 'prepared';
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $self->{phase} = 'opening';
            my $opened = eval {
                $self->{ledger}->check_live($self->{jobs}{1}{grant});
                # Publish both credits before the resource-free endpoint,
                # then retain that endpoint before its first native effect.
                $self->{run_grant} = $self->{ledger}->reserve_descriptors($COST->{steady_descriptors});
                $self->{scratch_grant} = $self->{ledger}->reserve_descriptors($COST->{transient_descriptors});
                $self->{run} = FSM::Support::ProcessSupervisor::Endpoint::prepare_run();
                $self->{run_identity} = refaddr($self->{run});
                $self->{run}->start_run(sub { $self->_before_run_allocation(@_) });
                my $handles = $self->{run}->handles;
                _error('native run inventory disagrees with reserved cost')
                    unless @$handles == $COST->{steady_descriptors};
                $self->{ledger}->descriptors_prepared($self->{run_grant}, scalar @$handles);
                $self->{service} = FSM::Support::ProcessSupervisor::Service::new_shared_service(
                    $self->{run}, $self->{ledger}->describe($self->{jobs}{1}{grant})->{deadline_ns});
                $self->{service_identity} = refaddr($self->{service});
                $self->_bind_context($self->{jobs}{1}{grant});
                $self->{phase} = 'open';
                1;
            };
            unless ($opened) {
                my $error = $@; $self->_failure($error); $self->{phase} = 'failed'; die $error;
            }
        });
        1;
    };
    unless ($ok) {
        my $error = $@; $self->_failure($error); $self->{phase} = 'failed'; die $error;
    }
    return;
}
sub context {
    my ($self) = @_; _owner($self);
    _error('root run is not open') unless @_ == 1 && $self->{phase} eq 'open';
    return $self->_context_live($self->{jobs}{1}{grant});
}
sub _before_peer_accept {
    my ($self, $service, $ticket) = @_; _owner($self);
    _error('accept requires the original shared service') unless $self->{service}
        && refaddr($service) == refaddr($self->{service});
    my $observed = $service->ticket_observation($ticket);
    _error('accept ticket is not resource-free original admission')
        unless $observed->{state} eq 'accepting' && !$observed->{handles}
            && !exists $self->{peers}{$ticket};
    # Service already owns this ticket. Retain it before even a liveness
    # refusal, then before the resource-free ledger reservation. A thrown
    # reservation return leaves any original credit in the ledger as well.
    my $entry = $self->{peers}{$ticket} = {ticket => $ticket, transport => $observed};
    _error('run is no longer open for accept') unless $self->{phase} eq 'open';
    $self->{ledger}->check_live($self->{jobs}{1}{grant});
    return 0 if $self->{ledger}->usage->{charged_descriptors} >= $LIMIT->{descriptors};
    $entry->{grant} = $self->{ledger}->reserve_descriptors(1);
    my $held = $self->{ledger}->describe_descriptors($entry->{grant});
    _error('accept lacks its original reserved descriptor')
        unless $held->{reserved} && $held->{count} == 1;
    return 1;
}
sub _reconcile_peers {
    my ($self) = @_;
    return unless $self->{service};
    my %retained = map { $_ => 1 } @{$self->{service}->tickets};
    _error('native peer lacks its original aggregate owner')
        if grep { !exists $self->{peers}{$_} } keys %retained;
    for my $ticket (sort { $a <=> $b } keys %{$self->{peers}}) {
        my $entry = $self->{peers}{$ticket};
        unless ($retained{$ticket}) {
            next if $entry->{outcome};
            _error('accepted ticket disappeared before retained outcome consumption')
                unless $entry->{transport}{state} eq 'accepting' && !$entry->{transport}{handles};
            # Only an empty refused/transient attempt may disappear here.
            $self->{ledger}->release_descriptors($entry->{grant}, 0) if $entry->{grant};
            delete $self->{peers}{$ticket};
            next;
        }
        my $observed = $self->{service}->ticket_observation($ticket);
        $entry->{transport} = $observed;
        $entry->{publication} = scalar $self->{service}->accept_publication($ticket);
        _error('accepted socket exceeds its original grant') if $observed->{handles} > 1;
        if ($observed->{handles}) {
            my $held = $self->{ledger}->describe_descriptors($entry->{grant});
            _error('accepted socket lost its original descriptor credit') unless $held->{count} == 1;
            $self->{ledger}->descriptors_prepared($entry->{grant}, 1) if $held->{reserved};
        }
        # Closed outcomes keep conservative credit until whole-run close.
        $self->_request_failed($entry, $observed->{failure}{diagnostic} // 'original request peer closed')
            if $observed->{state} =~ /\A(?:closing|closed)\z/
                && defined($entry->{request_state}) && $entry->{request_state} ne 'failed';
    }
    return;
}
sub advance_service {
    my ($self) = @_; _owner($self);
    _error('service advancement requires an open run') unless @_ == 1 && $self->{phase} eq 'open';
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            my $error;
            eval {
                $self->_reconcile_execution;
                $self->{ledger}->check_live($self->{jobs}{1}{grant});
                $self->{service}->advance(sub { $self->_before_peer_accept(@_) },
                    sub { $self->_before_accept_write(@_) });
                1;
            } or $error = $@;
            eval { $self->_reconcile_peers; 1 } or $error //= $@;
            die $error if defined $error;
            my $failure = $self->{service}->failure;
            _error($failure->{diagnostic}) if $failure;
        });
        1;
    };
    unless ($ok) {
        my $error = $@; $self->_job_failed($self->{jobs}{1}{grant}, $error); die $error;
    }
    return;
}
sub peer_tickets {
    my ($self) = @_; _owner($self);
    _error('unexpected peer inventory arguments') unless @_ == 1;
    return [sort { $a <=> $b } keys %{$self->{peers}}];
}
sub peer_observation {
    my ($self, $ticket) = @_; _owner($self);
    _error('peer observation requires one original ticket') unless @_ == 2;
    FSM::Support::ProcessSupervisor::Wire::_uint($ticket, '4294967295', 1);
    my $entry = $self->{peers}{$ticket} or _error('unknown retained peer ticket');
    my $transport = $entry->{transport};
    return {ticket => $ticket,
        transport => {%$transport, failure => $transport->{failure} ? {%{$transport->{failure}}} : undef},
        request => defined($entry->{request_state}) ? {
            state => $entry->{request_state}, failure => $entry->{request_failure},
            cleanup_error => $entry->{cleanup_error},
            parent => $entry->{request} ? $entry->{request}{parent} : undef,
            job => $entry->{job_id},
            deadline_ns => $entry->{request} ? $entry->{request}{deadline_ns} : undef,
            admission_deadline_ns => $entry->{request} ? $entry->{request}{admission_deadline_ns} : undef,
        } : undef,
        publication => _copy_publication($entry->{publication}),
        execution => _copy_execution($entry->{execution}),
        admission => $entry->{grant} && !$entry->{retired}
            ? $self->{ledger}->describe_descriptors($entry->{grant}) : undef,
        outcome => $entry->{outcome} ? {%{$entry->{outcome}}} : undef};
}
sub _copy_publication {
    my ($view) = @_; return undef unless $view;
    return {%$view, failure => $view->{failure} ? {%{$view->{failure}}} : undef,
        write => $view->{write} ? {%{$view->{write}},
            failure => $view->{write}{failure} ? {%{$view->{write}{failure}}} : undef} : undef};
}
sub _copy_execution {
    my ($view) = @_; return undef unless $view;
    return {native => {%{$view->{native}}},
        report => $view->{report} ? {%{$view->{report}}} : undef};
}
sub admit_request {
    my ($self, $ticket) = @_; _owner($self);
    _error('request admission requires one original peer ticket') unless @_ == 2;
    $self->peer_observation($ticket);
    my $peer = $self->{peers}{$ticket};
    my $started = 0;
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            _error('request admission requires the original open peer')
                unless $self->{phase} eq 'open' && $self->{peers}{$ticket}
                    && refaddr($self->{peers}{$ticket}) == refaddr($peer);
            _error('request admission is single-use') if defined($peer->{request_state});
            my $transport = $self->{service}->ticket_observation($ticket);
            $peer->{transport} = $transport;
            _error($transport->{failure}{diagnostic} // 'original peer has no pending request')
                unless $transport->{state} eq 'request';
            $peer->{request_state} = 'preparing'; $started = 1;
            unless ($self->{service}->transfer_request($ticket, \$peer->{request})) {
                my $view = $self->{service}->ticket_observation($ticket);
                _error($view->{failure}{diagnostic} // 'original request transfer refused');
            }
            $peer->{request_identity} = refaddr($peer->{request});
            my $parent = $self->{jobs}{$peer->{request}{parent}};
            _error('request has no original retained parent job') unless $parent;
            $peer->{parent_grant} = $parent->{grant};
            $self->_request_live($peer);
            # Transfer supplied a validated detached snapshot. The retained
            # peer and job share custody until binding publishes its replacement.
            $self->_reserve_job($peer->{parent_grant}, $peer->{request}{request}, $peer);
            $self->_request_live($peer);
            delete $peer->{request}{request};
            $peer->{request_state} = 'ready';
        });
        1;
    };
    unless ($ok) {
        my $error = $@; $self->_request_failed($peer, $error) if $started; die $error;
    }
    return $peer->{job_grant};
}
sub _request_live {
    my ($self, $peer) = @_; _owner($self);
    _error('request lacks its original retained peer') unless $peer
        && $self->{peers}{$peer->{ticket}}
        && refaddr($self->{peers}{$peer->{ticket}}) == refaddr($peer);
    my $packet = $peer->{request};
    _error('request lacks its original transferred packet') unless $packet
        && refaddr($packet) == ($peer->{request_identity} // 0)
        && $packet->{ticket} == $peer->{ticket};
    my $executing = $peer->{job_grant} && !$peer->{outcome}
        ? $self->_record_request_execution($peer) : 0;
    _error('request admission is no longer live') unless $self->{phase} eq 'open'
        && ($peer->{request_state} // '') =~ /\A(?:preparing|ready)\z/;
    my $transport = $self->{service}->ticket_observation($peer->{ticket});
    $peer->{transport} = $transport;
    my $matching = $transport->{state} eq 'handed'
        || ($transport->{state} eq 'bound' && defined($peer->{accept_state})
            && defined($peer->{job_id}) && $transport->{job} == $peer->{job_id});
    _error($transport->{failure}{diagnostic} // 'original request peer is no longer handed or bound')
        unless $matching && $transport->{handles} == 1
            && $transport->{parent} == $packet->{parent}
            && $transport->{wall_ns} eq $packet->{admission_deadline_ns};
    my $wall = $executing ? $packet->{deadline_ns} : $packet->{admission_deadline_ns};
    _error('request lifetime disagrees with original native execution truth')
        unless $transport->{active_deadline_ns} eq $wall;
    my (undef, $parent) = $self->_job($peer->{parent_grant});
    _error('request parent is not its original active job')
        unless $parent->{id} == $packet->{parent} && $parent->{phase} eq 'active';
    $self->_context_live($peer->{parent_grant});
    my $now = Math::BigInt->new(_now_ns());
    _error($executing ? 'original request execution deadline expired'
        : 'original request admission deadline expired') if grep {
        $now->bcmp($_) >= 0
    } $packet->{deadline_ns}, $wall;
    if ($peer->{job_grant}) {
        my ($job, $record) = $self->_job($peer->{job_grant});
        _error('request lacks its original child grant association') unless $job->{peer}
            && refaddr($job->{peer}) == refaddr($peer) && $record->{id} == $peer->{job_id}
            && $record->{parent} == $packet->{parent}
            && $record->{deadline_ns} eq $packet->{deadline_ns};
        $self->{ledger}->check_live($peer->{job_grant});
    }
    return;
}
sub _request_failed {
    my ($self, $peer, $error) = @_;
    # Mark failure before cancellation can reconcile the same peer again.
    $peer->{request_failure} //= FSM::Support::ProcessSupervisor::_sanitize_control($error);
    $peer->{request_state} = 'failed';
    $self->_job_failed($peer->{job_grant}, $peer->{request_failure}) if $peer->{job_grant};
    eval {
        $self->{service}->retire($peer->{ticket});
        $peer->{transport} = $self->{service}->ticket_observation($peer->{ticket});
        $peer->{publication} = scalar $self->{service}->accept_publication($peer->{ticket});
        1;
    }
        or $peer->{cleanup_error} //= FSM::Support::ProcessSupervisor::_sanitize_control($@);
    return;
}
sub _request_peer {
    my ($self, $ticket) = @_;
    $self->peer_observation($ticket);
    my $peer = $self->{peers}{$ticket};
    _error('request has no completed original grant association')
        unless ($peer->{request_state} // '') eq 'ready' && $peer->{job_grant};
    return $peer;
}
sub start_request {
    my ($self, $ticket) = @_; _owner($self);
    _error('request start requires one original ticket') unless @_ == 2;
    my $peer = $self->_request_peer($ticket);
    _error('request start is single-use') if $peer->{start_requested};
    my $started = 0;
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $self->_request_live($peer);
            _error('request start is single-use') if $peer->{start_requested};
            $peer->{start_requested} = 1; $started = 1;
        });
        # No outer mask: start and later launch advancement must retain the
        # caller's actual mask at both native fork boundaries.
        $self->prepare_job($peer->{job_grant});
        $self->start_job($peer->{job_grant});
        1;
    };
    unless ($ok) { my $error = $@; $self->_request_failed($peer, $error) if $started; die $error; }
    return;
}
sub _ready_request {
    my ($self, $peer) = @_;
    $self->_request_live($peer);
    my $before = $self->job_observation($peer->{job_grant});
    # This helper also runs under the socket-write mask. Never advance a
    # launching pair here: that path can still create the command process.
    _error('ACCEPT requires the original active ready gated job')
        unless $before->{admission}{phase} eq 'active' && $before->{native}
            && $before->{native}{phase} eq 'ready';
    my $view = $self->advance_job($peer->{job_grant});
    _error('original gated job lost readiness before ACCEPT')
        unless $view->{admission}{phase} eq 'active' && $view->{native}{phase} eq 'ready'
            && !$view->{native}{first_failure} && !$view->{native}{command}{released}
            && $view->{native}{command}{command_pid} && !$view->{native}{command}{command_reaped}
            && $view->{native}{reservation}{pid} && !$view->{native}{reservation}{reaped};
    return;
}
sub advance_request {
    my ($self, $ticket) = @_; _owner($self);
    _error('request advancement requires one original ticket') unless @_ == 2;
    my $peer = $self->_request_peer($ticket);
    _error('request has not started its original gated job') unless $peer->{start_requested};
    my $ok = eval {
        $self->_request_live($peer);
        # Launch advancement may fork; only the subsequent ready publication
        # is a preparation transaction. Nothing in this method releases exec.
        my $view = $self->advance_job($peer->{job_grant});
        if ($view->{admission}{phase} eq 'active' && $view->{native}{phase} eq 'ready') {
            FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
                $self->_ready_request($peer);
                unless (defined($peer->{accept_state})) {
                    $peer->{accept_state} = 'preparing';
                    unless ($self->{service}->queue_accept($ticket, $peer->{job_id})) {
                        my $transport = $self->{service}->ticket_observation($ticket);
                        _error($transport->{failure}{diagnostic} // 'original ACCEPT queue refused');
                    }
                    $peer->{accept_state} = 'queued';
                }
                $self->_reconcile_peers;
            });
        }
        elsif ($view->{admission}{phase} eq 'closing') {
            _error($view->{failure} // 'original gated request failed');
        }
        $self->_reconcile_peers;
        1;
    };
    unless ($ok) { my $error = $@; $self->_request_failed($peer, $error); die $error; }
    return $self->peer_observation($ticket);
}
sub _before_accept_write {
    my ($self, $service, $ticket, $job) = @_; _owner($self);
    _error('ACCEPT write requires the original shared Service')
        unless $self->{service} && refaddr($service) == refaddr($self->{service});
    my $peer = $self->{peers}{$ticket};
    _error('ACCEPT write lacks its original request/job association')
        unless $peer && defined($peer->{accept_state}) && $peer->{job_grant}
            && defined($peer->{job_id}) && $peer->{job_id} == $job;
    my $ok = eval { $self->_ready_request($peer); 1 };
    unless ($ok) { my $error = $@; $self->_request_failed($peer, $error); return 0; }
    return 1;
}

# Called only from the original child's masked E transaction. This parent
# inspection must never advance its queued execution or native launch.
sub _request_execution_live {
    my ($self, $peer, $native, $deadline, $pair) = @_;
    $self->_request_live($peer);
    my ($entry, $record) = $self->_job($peer->{job_grant});
    _error('nested execution requires its original active native job')
        unless $record->{id} > 1 && $record->{phase} eq 'active'
            && $entry->{native} && refaddr($entry->{native}) == refaddr($native);
    _error('nested execution admission is no longer open')
        unless $self->{phase} eq 'open' && !$self->{failure} && !$entry->{failure}
            && !$peer->{request_failure} && $peer->{start_requested}
            && $peer->{release_requested} && ($peer->{accept_state} // '') eq 'queued';
    $self->_context_live($peer->{job_grant});
    $native->_release_live($pair);
    _error('nested execution changed its original invocation wall')
        unless $record->{deadline_ns} eq $deadline
            && $pair->{original_deadline} == $deadline / 1_000_000_000;
    my ($parent, $parent_record) = $self->_job($peer->{parent_grant});
    my $parent_wall = $self->{service}->parent_observation($parent_record->{id})->{deadline_ns};
    _error('nested execution lost original parent native custody')
        unless $parent_record->{phase} eq 'active' && !$parent->{failure} && $parent->{native}
            && $parent_record->{deadline_ns} eq $parent_wall
            && $parent->{native}->check_custody;
    # Context lookup and native inspection carry no lasting ledger permission.
    $self->{ledger}->check_live($_) for $peer->{parent_grant}, $peer->{job_grant};
    ($entry, $record) = $self->_job($peer->{job_grant});
    ($parent, $parent_record) = $self->_job($peer->{parent_grant});
    _error('nested execution authority changed during its final check')
        unless $self->{phase} eq 'open' && !$self->{failure} && !$entry->{failure}
            && !$parent->{failure} && !$peer->{request_failure}
            && ($peer->{request_state} // '') eq 'ready'
            && $record->{phase} eq 'active' && $record->{deadline_ns} eq $deadline
            && $parent_record->{phase} eq 'active' && $parent_record->{deadline_ns} eq $parent_wall;
    return;
}

sub _request_execution_grant {
    my ($self, $peer) = @_; _owner($self);
    my $grant = $peer->{execution_grant};
    _error('nested execution lost its retained original Service grant')
        unless ref($grant) && refaddr($grant) == ($peer->{execution_grant_identity} // 0);
    my $record = $self->{service}->_execution_grant_record($grant);
    _error('nested execution grant names a different original request')
        unless $grant->{ticket} == $peer->{ticket} && $grant->{job} == $peer->{job_id}
            && $record->{ticket} == $peer->{ticket} && $record->{parent} == $peer->{request}{parent};
    return $grant;
}

sub _before_request_execution {
    my ($self, $peer, $native, $deadline, $pair) = @_; _owner($self);
    _error('nested execution requires its original retained callback owners')
        unless @_ == 5 && ref($peer) eq 'HASH' && $self->{peers}{$peer->{ticket}}
            && refaddr($self->{peers}{$peer->{ticket}}) == refaddr($peer);
    my ($entry) = $self->_job($peer->{job_grant});
    _error('nested execution requires its original retained callback owners')
        unless $entry->{peer} && refaddr($entry->{peer}) == refaddr($peer)
            && $entry->{native} && refaddr($entry->{native}) == refaddr($native)
            && ref($pair) && refaddr($pair) == $native->{pair_identity};
    my $admitted = 0;
    my $ok = eval {
        $self->_request_execution_live($peer, $native, $deadline, $pair);
        if (defined($peer->{execution_grant_identity})) {
            $self->_request_execution_grant($peer);
            $admitted = $self->{service}->execution_admission($peer->{ticket}, $peer->{job_id});
        }
        else {
            _error('nested execution grant slot was populated outside original admission')
                if defined($peer->{execution_grant});
            # Service publishes into this retained peer before returning. If
            # that return throws there is no E; original grant custody survives.
            $admitted = $self->{service}->execution_admission(
                $peer->{ticket}, $peer->{job_id}, \$peer->{execution_grant});
            $peer->{execution_grant_identity} = refaddr($peer->{execution_grant})
                if defined($peer->{execution_grant});
        }
        $self->_request_execution_grant($peer) if $admitted || defined($peer->{execution_grant_identity});
        $self->_request_execution_live($peer, $native, $deadline, $pair);
        if ($admitted || defined($peer->{execution_grant_identity})) {
            # Native parent inspection is another return boundary. A grant
            # authenticated before that call cannot authorize this E afterward.
            my $grant = $self->_request_execution_grant($peer);
            my $record = $self->{service}->_execution_grant_record($grant);
            _error('nested execution grant was already reported') if $record->{execution_report};
            _error($record->{failure}{diagnostic} // 'nested execution lost final Service authority')
                unless $self->{service}->_bound_live($record);
        }
        1;
    };
    unless ($ok) {
        my $error = $@;
        # The original request cause precedes cleanup and signal restoration.
        eval { $self->_request_failed($peer, $error); 1 };
        die $error;
    }
    return $admitted;
}

# Historical effect ownership deliberately does not require live contexts or
# an unexpired admission wall: a confirmed E may need reporting after closure.
sub _request_effect_owner {
    my ($self, $peer) = @_; _owner($self);
    _error('native effect requires its original retained request')
        unless ref($peer) eq 'HASH' && $self->{peers}{$peer->{ticket}}
            && refaddr($self->{peers}{$peer->{ticket}}) == refaddr($peer)
            && $peer->{request} && refaddr($peer->{request}) == ($peer->{request_identity} // 0)
            && $peer->{request}{ticket} == $peer->{ticket};
    my ($entry, $record) = $self->_job($peer->{job_grant});
    my (undef, $parent) = $self->_job($peer->{parent_grant});
    _error('native effect lost its original job/parent association')
        unless $entry->{peer} && refaddr($entry->{peer}) == refaddr($peer)
            && $record->{id} == $peer->{job_id} && $record->{id} > 1
            && $record->{parent} == $parent->{id} && $parent->{id} == $peer->{request}{parent}
            && $record->{deadline_ns} eq $peer->{request}{deadline_ns};
    return ($entry, $record);
}

sub _retain_execution_report {
    my ($peer, $service, $grant) = @_;
    my $record = $service->_execution_grant_record($grant);
    my $report = $record->{execution_report} or return 0;
    _error('native effect report lost its original association')
        unless $record->{ticket} == $peer->{ticket} && $record->{job} == $peer->{job_id}
            && $record->{parent} == $peer->{request}{parent}
            && $report->{admission_issued_ns} eq $grant->{issued_ns}
            && $report->{deadline_ns} eq $peer->{execution}{native}{deadline_ns};
    if (my $held = $peer->{execution}{report}) {
        _error('original execution report changed after publication') if grep {
            !defined($held->{$_}) || $held->{$_} ne $report->{$_}
        } qw(reported_ns admission_issued_ns deadline_ns);
    }
    else { $peer->{execution}{report} = {%$report}; }
    return 1;
}

sub _record_request_execution {
    my ($self, $peer) = @_;
    _error('native effect reporting requires one original peer') unless @_ == 2;
    my ($entry) = $self->_request_effect_owner($peer);
    return 0 unless $entry->{native};
    my $native = $entry->{native};
    my ($started, $reported, $service, $grant) = (0, 0);
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            my (undef, $record) = $self->_request_effect_owner($peer);
            my $observed = $native->observation;
            if (my $failure = $observed->{first_failure}) {
                # Liveness may discover a retained native failure before the
                # next advance_job call. A later report error must not win.
                my $cause = FSM::Support::ProcessSupervisor::_sanitize_control($failure->{diagnostic});
                $entry->{failure} //= $cause;
                $peer->{request_failure} //= $cause;
            }
            my $command = $observed->{command};
            return unless $command->{released} || $command->{release_uncertain};
            _error('native effect lacks its original execution attempt')
                unless $peer->{release_requested} && $command->{release_attempted}
                    && !($command->{released} && $command->{release_uncertain});
            $grant = $self->_request_execution_grant($peer);
            $service = $self->{service}; $started = 1;
            my $captured = eval {
                my $state = $command->{released} ? 'confirmed' : 'uncertain';
                if (my $held = $peer->{execution}) {
                    _error('original native effect changed after observation')
                        unless $held->{native}{state} eq $state
                            && $held->{native}{job} == $record->{id}
                            && $held->{native}{parent} == $record->{parent}
                            && $held->{native}{deadline_ns} eq $record->{deadline_ns};
                }
                else {
                    # This is the observation time, never a native exec time.
                    # Retain confirmed/uncertain truth before any report call.
                    $peer->{execution} = {native => {state => $state, observed_ns => _now_ns(),
                        job => $record->{id}, parent => $record->{parent}, deadline_ns => $record->{deadline_ns}}};
                }
                if ($state eq 'confirmed') {
                    unless (_retain_execution_report($peer, $service, $grant)) {
                        $service->record_execution($grant);
                        _error('original Service returned without retaining its execution report')
                            unless _retain_execution_report($peer, $service, $grant);
                    }
                    $reported = 1;
                }
                $self->_request_effect_owner($peer);
                $self->_request_execution_grant($peer);
                1;
            };
            unless ($captured) {
                my $error = $@;
                # A lost report return may already have published its marker.
                # Read that original owner without needing another mask.
                eval { _retain_execution_report($peer, $service, $grant); 1 };
                eval { $self->_request_failed($peer, $error); 1 };
                die $error;
            }
        });
        $self->_request_effect_owner($peer);
        $self->_request_execution_grant($peer) if $started;
        1;
    };
    unless ($ok) {
        my $error = $@;
        if ($started) {
            eval { _retain_execution_report($peer, $service, $grant); 1 }
                if $peer->{execution} && $peer->{execution}{native}{state} eq 'confirmed';
            eval { $self->_request_failed($peer, $error); 1 };
        }
        die $error;
    }
    return $reported;
}

sub _reconcile_execution {
    my ($self) = @_; _owner($self);
    for my $ticket (sort { $a <=> $b } keys %{$self->{peers}}) {
        my $peer = $self->{peers}{$ticket};
        # Consumed peers retain their effect history but their Service grant is
        # spent. Every still-retained native effect must precede consumption.
        next if !$peer->{job_grant} || $peer->{outcome};
        $self->_record_request_execution($peer);
    }
    return;
}
sub retire_peer {
    my ($self, $ticket) = @_; _owner($self);
    _error('peer retirement requires one original ticket') unless @_ == 2;
    $self->peer_observation($ticket);
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        my $error;
        eval { $self->{service}->retire($ticket); 1 } or $error = $@;
        eval { $self->_reconcile_peers; 1 } or $error //= $@;
        die $error if defined $error;
    });
    return;
}
sub _consume_closed_peers {
    my ($self) = @_;
    return unless $self->{service};
    $self->_reconcile_execution;
    $self->_reconcile_peers;
    for my $entry (values %{$self->{peers}}) {
        my $observed = $entry->{transport};
        _error('accepted peer cleanup incomplete') unless $observed->{resources_closed}
            && $observed->{state} eq 'closed' && !$observed->{handles};
        # Retain the complete original outcome before Service consumes it.
        # A thrown consumption return cannot strand even this pure metadata.
        $entry->{outcome} //= {ticket => $entry->{ticket}, parent => $observed->{parent},
            %{$observed->{failure}}, resources_closed => $observed->{resources_closed}};
    }
    for (1 .. $LIMIT->{connections}) {
        last unless @{$self->{service}->tickets};
        my $outcome = $self->{service}->take_closed;
        _error('service has no consumable closed outcome') unless $outcome;
        my $entry = $self->{peers}{$outcome->{ticket}};
        _error('closed outcome lacks its original retained peer') unless $entry && $entry->{outcome};
        for my $field (qw(ticket parent status diagnostic resources_closed)) {
            my ($expected, $actual) = ($entry->{outcome}{$field}, $outcome->{$field});
            _error('closed outcome disagrees with its original retained observation')
                if defined($expected) != defined($actual)
                    || (defined($expected) && "$expected" ne "$actual");
        }
    }
    _error('service retains unconsumed outcomes') if @{$self->{service}->tickets};
    return;
}
sub root {
    my ($self) = @_; _owner($self);
    _error('unexpected root arguments') unless @_ == 1;
    return $self->{ledger}->root;
}
sub _job {
    my ($self, $grant) = @_; _owner($self);
    my $record = $self->{ledger}->describe($grant);
    my $entry = $self->_job_owner($record->{id});
    _error('job grant has no original retained owner') unless $entry
        && refaddr($entry->{grant}) == refaddr($grant);
    return ($entry, $record);
}
sub grants {
    my ($self) = @_; _owner($self);
    _error('unexpected grant inventory arguments') unless @_ == 1;
    return $self->{ledger}->grants;
}
sub reserve_job {
    my ($self, %args) = @_; _owner($self);
    FSM::Support::ProcessSupervisor::Wire::_keys(\%args, qw(parent snapshot));
    _error('nested admission requires an open run') unless $self->{phase} eq 'open';
    $self->_job($args{parent});
    my $snapshot = FSM::Support::ProcessSupervisor::Wire::decode_frame('client',
        FSM::Support::ProcessSupervisor::Wire::encode_frame('client', $args{snapshot}));
    _error('expected nested execution snapshot') unless $snapshot->{type} eq 'SPAWN';
    return $self->_reserve_job($args{parent}, $snapshot);
}
sub _reserve_job {
    my ($self, $parent, $snapshot, $peer) = @_; _owner($self);
    my $grant;
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $self->_request_live($peer) if $peer;
            $grant = $self->{ledger}->reserve_job(parent => $parent,
                map { $_ => $snapshot->{$_} } qw(started_ns timeout_seconds));
            my $id = $self->{ledger}->describe($grant)->{id};
            $self->{jobs}{$id} = {grant => $grant, snapshot => $snapshot};
            $self->{job_identities}{$id} = refaddr($self->{jobs}{$id});
            if ($peer) {
                # Both original owners precede token generation and any return.
                $peer->{job_grant} = $grant; $peer->{job_id} = $id;
                $self->{jobs}{$id}{peer} = $peer;
            }
            # Register in original admission order, not later native-start
            # order. A failed preparation still spends this job identity.
            $self->_bind_context($grant);
        });
        1;
    };
    unless ($ok) {
        my $error = $@;
        $self->_job_failed($grant, $error) if $grant;
        die $error;
    }
    # If a pending handler interrupts this return, grants still exposes the
    # original record and snapshot. Token effects have their retained owner;
    # native process preparation and fork have not started.
    return $grant;
}
sub _bind_context {
    my ($self, $grant) = @_; _owner($self);
    my ($entry, $record) = $self->_job($grant);
    _error('context binding requires original reserved snapshot custody')
        unless $record->{phase} eq 'reserved' && $entry->{snapshot} && !$entry->{native};
    _error('context binding is single-use') if defined($entry->{context_state});
    $entry->{context_state} = 'preparing';
    my $ok = eval {
        $self->{ledger}->check_live($grant);
        my $context = $record->{id} == 1 ? $self->{service}->parent_context(1)
            : $self->{service}->register_parent($record->{id}, $record->{deadline_ns},
                sub { $self->_before_context_allocation($grant, @_) });
        $self->{ledger}->check_live($grant);
        my $snapshot = FSM::Support::ProcessSupervisor::Wire::snapshot_with_context($entry->{snapshot}, $context);
        $self->{ledger}->check_live($grant);
        _error('original context changed during snapshot preparation')
            unless $self->{service}->parent_context($record->{id}) eq $context;
        $self->_job($grant);
        $entry->{snapshot} = $snapshot;
        # Later Service liveness cannot authorize a different context value.
        $entry->{bound_context} = $context;
        $entry->{context_state} = 'ready';
        1;
    };
    unless ($ok) { my $error = $@; $entry->{context_state} = 'failed'; die $error; }
    return;
}
sub _before_context_allocation {
    my ($self, $grant, $service, $id, $kind, $operation) = @_; _owner($self);
    _error('context entropy requires the original open Service')
        unless $self->{phase} eq 'open' && $self->{service}
            && refaddr($service) == refaddr($self->{service});
    _error('unknown context allocation operation') unless $kind eq 'create'
        && ($operation eq 'entropy_open' || $operation eq 'entropy_read');
    my ($entry, $record) = $self->_job($grant);
    $self->{ledger}->check_live($grant);
    $self->_request_live($entry->{peer}) if $entry->{peer};
    _error('context entropy lacks original reserved job custody')
        unless $id == $record->{id} && $record->{phase} eq 'reserved'
            && $entry->{context_state} eq 'preparing' && $entry->{snapshot} && !$entry->{native}
            && $record->{reserved_descriptors} == $JOB_COST->{descriptors}
            && $record->{reserved_children} == $JOB_COST->{children};
    my $run = $self->{ledger}->describe_descriptors($self->{run_grant});
    my $scratch = $self->{ledger}->describe_descriptors($self->{scratch_grant});
    _error('context entropy lacks separate retained scratch credit')
        unless refaddr($self->{run_grant}) != refaddr($self->{scratch_grant})
            && !$run->{reserved} && $run->{count} >= $COST->{steady_descriptors}
            && $scratch->{reserved} && $scratch->{count} >= $COST->{transient_descriptors};
    my $usage = $self->{ledger}->usage;
    _error('aggregate context capacity exceeded')
        if $usage->{charged_descriptors} > $LIMIT->{descriptors}
            || $usage->{charged_children} > $LIMIT->{children};
    return;
}
sub _context_live {
    my ($self, $grant) = @_; _owner($self);
    my ($entry, $record) = $self->_job($grant);
    _error('original job context is not prepared') unless ($entry->{context_state} // '') eq 'ready';
    $self->{ledger}->check_live($grant);
    $self->_request_live($entry->{peer}) if $entry->{peer};
    my $context = $self->{service}->parent_context($record->{id});
    $self->_job($grant);
    _error('original bound context changed or disappeared')
        unless defined($context) && defined($entry->{bound_context}) && $context eq $entry->{bound_context};
    return $context;
}
sub _job_failed {
    my ($self, $grant, $error) = @_;
    my ($entry, $record) = $self->_job($grant);
    # Keep the original error if cleanup itself is interrupted. Revocation and
    # all native owners remain retained for the next bounded cleanup call.
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $entry->{failure} //= FSM::Support::ProcessSupervisor::_sanitize_control($error);
            if ($record->{id} == 1) {
                $self->_failure($error);
                $self->{phase} = 'failed' unless $self->{phase} eq 'closing' || $self->{phase} eq 'closed';
            }
            $self->cancel_job($grant, $entry->{failure});
        });
        1;
    };
    unless ($ok) {
        my $cleanup_error = $@;
        $entry->{failure} //= FSM::Support::ProcessSupervisor::_sanitize_control($error);
        $entry->{cleanup_error} //= FSM::Support::ProcessSupervisor::_sanitize_control($cleanup_error);
    }
    return;
}
sub _before_job_allocation {
    my ($self, $grant) = @_; _owner($self);
    _error('run is no longer open for job preparation') unless $self->{phase} eq 'open';
    my ($entry, $record) = $self->_job($grant);
    $self->_context_live($grant);
    _error('native job must be retained under preparing admission')
        unless $entry->{native} && $record->{phase} eq 'preparing';
    _error('job peak credit is no longer retained')
        unless $record->{reserved_descriptors} == $JOB_COST->{descriptors}
            && $record->{reserved_children} == $JOB_COST->{children};
    my $usage = $self->{ledger}->usage;
    _error('aggregate job capacity exceeded')
        if $usage->{charged_descriptors} > $LIMIT->{descriptors}
            || $usage->{charged_children} > $LIMIT->{children};
    return;
}
sub prepare_job {
    my ($self, $grant) = @_; _owner($self);
    _error('job preparation requires an open run and original grant')
        unless @_ == 2 && $self->{phase} eq 'open';
    my ($entry, $record) = $self->_job($grant);
    _error('job preparation is single-use') unless $record->{phase} eq 'reserved';
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $self->_context_live($grant);
            $self->{ledger}->begin_prepare($grant);
            # The constructor is resource-free. Publish its entire graph before
            # allocate; the caller's original snapshot is then owned by the pair.
            $entry->{native} = FSM::Support::ProcessSupervisor::ReservedJob::prepare_record(
                snapshot => $entry->{snapshot}, deadline => $record->{deadline_ns} / 1_000_000_000,
                close_handles => $self->handles);
            $entry->{native_identity} = refaddr($entry->{native});
            delete $entry->{snapshot};
            $entry->{native}->allocate(sub { $self->_before_job_allocation($grant) });
            $self->{ledger}->prepared($grant, scalar @{$entry->{native}->handles});
        });
        1;
    };
    unless ($ok) {
        my $error = $@;
        $self->_job_failed($grant, $error);
        die $error;
    }
    return;
}
sub _before_job_fork {
    my ($self, $grant, $role) = @_; _owner($self);
    _error('unknown native fork role') unless defined($role) && !ref($role)
        && ($role eq 'reservation' || $role eq 'command');
    _error('run is no longer open for job start') unless $self->{phase} eq 'open';
    my ($entry, $record) = $self->_job($grant);
    $self->_context_live($grant);
    _error('native fork requires original starting credit')
        unless $entry->{native} && $record->{phase} eq 'starting'
            && $record->{reserved_children} == $JOB_COST->{children}
            && $record->{descriptors} >= scalar @{$entry->{native}->handles};
    my $usage = $self->{ledger}->usage;
    _error('aggregate fork capacity exceeded')
        if $usage->{charged_children} > $LIMIT->{children}
            || $usage->{charged_descriptors} > $LIMIT->{descriptors};
    my %own = map { refaddr($_) => 1 } @{$entry->{native}->handles};
    return [grep { !$own{refaddr($_)} } @{$self->handles}];
}
sub start_job {
    my ($self, $grant) = @_; _owner($self);
    _error('job start requires an open run and original grant')
        unless @_ == 2 && $self->{phase} eq 'open';
    my ($entry, $record) = $self->_job($grant);
    _error('job start is single-use') unless $record->{phase} eq 'prepared';
    my $ok = eval {
        $self->{ledger}->begin_start($grant);
        # The native fork mask captures the original exec signal state. Do not
        # surround this or advance with the broader preparation mask.
        $entry->{native}->start(sub { $self->_before_job_fork($grant, @_) });
        1;
    };
    unless ($ok) { my $error = $@; $self->_job_failed($grant, $error); die $error; }
    return;
}
sub _root_release_live {
    my ($self, $grant, $native, $deadline, $phase) = @_;
    my ($entry, $record) = $self->_job($grant);
    _error('execution release requires the original active root')
        unless $record->{id} == 1 && !$record->{parent} && $record->{phase} eq 'active'
            && $entry->{native} && refaddr($entry->{native}) == refaddr($native);
    _error('root execution admission is no longer open')
        unless $self->{phase} eq 'open' && !$self->{failure} && !$entry->{failure};
    $self->_context_live($grant);
    my $view = $native->observation;
    _error('root execution requires original native readiness and custody')
        unless $view->{phase} eq $phase && !$view->{first_failure}
            && !$view->{command}{released} && !$view->{command}{release_uncertain}
            && $view->{command}{command_pid} && $view->{command}{command_authority}
            && !$view->{command}{command_reaped} && !$view->{command}{retired}
            && !$view->{command}{failure} && $view->{reservation}{phase} eq 'moved'
            && !$view->{reservation}{reaped} && !$view->{reservation}{retired}
            && !$view->{reservation}{failure};
    _error('root execution changed its original invocation wall')
        unless $record->{deadline_ns} eq $deadline
            && $view->{command}{original_deadline} == $deadline / 1_000_000_000;
    # Context lookup and native observation convey no lasting authority.
    # Recheck original admission and failure state at the end of this attempt.
    $self->{ledger}->check_live($grant);
    ($entry, $record) = $self->_job($grant);
    _error('root execution admission changed during its final check')
        unless $self->{phase} eq 'open' && !$self->{failure} && !$entry->{failure}
            && $record->{phase} eq 'active' && $record->{deadline_ns} eq $deadline;
    return;
}
sub _before_root_execution {
    my ($self, $grant, $native, $deadline, $pair) = @_;
    # ReservedJob also checks this around its caller; require the same original
    # Pair here so direct invocation cannot authenticate a substituted callback.
    $native->_release_live($pair);
    $self->_root_release_live($grant, $native, $deadline, 'releasing');
    my ($entry) = $self->_job($grant);
    _error('root execution was not requested') unless $entry->{release_requested};
    return 1;
}
sub _root_release_failed {
    my ($self, $entry, $grant, $error) = @_;
    # A failed mask restoration must not prevent refusal publication. These
    # original records block the retained E callback even if cleanup is delayed.
    $entry->{failure} //= FSM::Support::ProcessSupervisor::_sanitize_control($error);
    $self->_failure($error);
    $self->{phase} = 'failed' unless $self->{phase} eq 'closing' || $self->{phase} eq 'closed';
    eval { $self->_job_failed($grant, $entry->{failure}); 1 }
        or $entry->{cleanup_error} //= FSM::Support::ProcessSupervisor::_sanitize_control($@);
    return;
}
sub release_root {
    my ($self, $grant) = @_; _owner($self);
    _error('root release requires one original grant') unless @_ == 2;
    my ($entry, $record) = $self->_job($grant);
    _error('root execution release is single-use') if $entry->{release_requested};
    my ($native, $deadline) = ($entry->{native}, $record->{deadline_ns});
    $self->_root_release_live($grant, $native, $deadline, 'ready');
    my $started = 0;
    my $ok = eval {
        # This ready-only transaction queues E. Launch and advancement stay
        # outside the preparation mask so they retain the original exec mask.
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            _error('root execution release is single-use') if $entry->{release_requested};
            $self->_root_release_live($grant, $native, $deadline, 'ready');
            $entry->{release_requested} = 1; $started = 1;
            my $queued = eval {
                $native->release(sub { $self->_before_root_execution($grant, $native, $deadline, @_) });
                1;
            };
            unless ($queued) {
                my $error = $@; $self->_root_release_failed($entry, $grant, $error); die $error;
            }
        });
        1;
    };
    unless ($ok) {
        my $error = $@;
        $self->_root_release_failed($entry, $grant, $error) if $started;
        die $error;
    }
    return;
}
sub cancel_job {
    my ($self, $grant, $diagnostic) = @_; _owner($self);
    _error('cancellation requires an original grant and diagnostic')
        unless @_ == 3 && defined($diagnostic) && !ref($diagnostic) && length($diagnostic);
    my (undef, $record) = $self->_job($grant);
    FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
        $self->{ledger}->cancel($grant);
        my %affected;
        my @entries;
        my $wall = _now_ns() / 1_000_000_000 + $TERM + $KILL;
        for my $g (@{$self->{ledger}->grants}) {
            my ($entry, $r) = $self->_job($g);
            next unless $r->{id} == $record->{id} || $affected{$r->{parent}};
            $affected{$r->{id}} = 1;
            push @entries, $entry;
            # A settled descendant retains a result slot, not a live cleanup
            # clock. Its spent wall cannot expire later cleanup of a sibling.
            next unless $entry->{native};
            my $observed = $entry->{native}->observation;
            next if $observed->{phase} eq 'finished'
                && $entry->{native}->finished_job->{resources_closed} && !@{$entry->{native}->handles};
            my $original = $r->{deadline_ns} / 1_000_000_000 + $TERM + $KILL;
            $wall = $original if $original < $wall;
            $wall = $entry->{cleanup_deadline}
                if defined($entry->{cleanup_deadline}) && $entry->{cleanup_deadline} < $wall;
            my $held = $observed->{cleanup_deadline};
            $wall = $held if defined($held) && $held < $wall;
        }
        if (defined $self->{cleanup_deadline_ns}) {
            my $run_wall = $self->{cleanup_deadline_ns} / 1_000_000_000;
            $wall = $run_wall if $run_wall < $wall;
        }
        if ($record->{id} == 1) {
            $wall = $self->{native_cleanup_deadline}
                if defined($self->{native_cleanup_deadline}) && $self->{native_cleanup_deadline} < $wall;
            $self->{native_cleanup_deadline} = $wall;
        }
        # Publish the common remaining wall everywhere before native cleanup.
        for my $entry (@entries) {
            $entry->{cleanup_deadline} = $wall
                unless defined($entry->{cleanup_deadline}) && $entry->{cleanup_deadline} < $wall;
        }
        my $cleanup_error;
        if ($self->{service}) {
            for my $id (sort { $a <=> $b } keys %affected) {
                eval { $self->{service}->revoke_parent($id); 1 } or $cleanup_error //= $@;
            }
            eval { $self->_reconcile_peers; 1 } or $cleanup_error //= $@;
        }
        for my $entry (@entries) {
            $entry->{failure} //= FSM::Support::ProcessSupervisor::_sanitize_control($diagnostic);
            next unless $entry->{native};
            eval { $entry->{native}->cancel($entry->{failure}, $wall); 1 } or $cleanup_error //= $@;
        }
        die $cleanup_error if defined $cleanup_error;
    });
    return;
}
sub advance_job {
    my ($self, $grant) = @_; _owner($self);
    _error('job advancement requires an original grant') unless @_ == 2;
    my ($entry, $record) = $self->_job($grant);
    _error('job is not starting, active or closing')
        unless $record->{phase} =~ /\A(?:starting|active|closing)\z/;
    my $ok = eval {
        $self->_context_live($grant) unless $record->{phase} eq 'closing';
        $self->cancel_job($grant, $entry->{failure} // 'job admission revoked')
            if $record->{phase} eq 'closing';
        if ($entry->{native}) {
            my ($native_error, $report_error);
            eval { $entry->{native}->advance; 1 } or $native_error = $@;
            if (defined($native_error) && $entry->{peer}) {
                # Report recovery can itself fail and cancel this subtree.
                # Publish the earlier native cause before that cleanup path.
                my $cause = FSM::Support::ProcessSupervisor::_sanitize_control($native_error);
                $entry->{failure} //= $cause;
                $entry->{peer}{request_failure} //= $cause;
            }
            # E may be confirmed or uncertain even when native advancement
            # loses its return. Reconcile that truth before failure cleanup.
            eval {
                $self->_record_request_execution($entry->{peer})
                    if $entry->{peer} && !$entry->{peer}{outcome};
                1;
            } or $report_error = $@;
            die $native_error if defined $native_error;
            die $report_error if defined $report_error;
            my $observed = $entry->{native}->observation;
            if ($observed->{first_failure} && $record->{phase} ne 'closing') {
                my $error = $observed->{first_failure}{diagnostic};
                $entry->{peer} ? $self->_request_failed($entry->{peer}, $error)
                    : $self->_job_failed($grant, $error);
            }
            elsif ($observed->{phase} eq 'ready' && $record->{phase} eq 'starting') {
                FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
                    _error('ready native pair lacks retained direct children')
                        unless $observed->{command}{command_pid} && !$observed->{command}{command_reaped}
                            && $observed->{reservation}{pid} && !$observed->{reservation}{reaped};
                    $self->{ledger}->activate($grant, scalar @{$entry->{native}->handles});
                });
            }
        }
        1;
    };
    unless ($ok) {
        my $error = $@;
        eval {
            $entry->{peer} ? $self->_request_failed($entry->{peer}, $error)
                : $self->_job_failed($grant, $error);
            1;
        } or $entry->{cleanup_error} //= FSM::Support::ProcessSupervisor::_sanitize_control($@);
        die $error;
    }
    return $self->job_observation($grant);
}
sub job_observation {
    my ($self, $grant) = @_; _owner($self);
    _error('job observation requires an original grant') unless @_ == 2;
    my ($entry, $record) = $self->_job($grant);
    return {admission => $record, failure => $entry->{failure}, cleanup_error => $entry->{cleanup_error},
        context_state => $entry->{context_state},
        release_requested => $entry->{release_requested} ? 1 : 0,
        cleanup_deadline => $entry->{cleanup_deadline},
        native => $entry->{native} ? $entry->{native}->observation : undef};
}
sub handles {
    my ($self) = @_; _owner($self);
    _error('unexpected inventory arguments') unless @_ == 1;
    my %seen;
    return [grep { !$seen{refaddr($_)}++ }
        $self->{service} ? @{$self->{service}->handles} : $self->{run} ? @{$self->{run}->handles} : (),
        map { $_->{native} ? @{$_->{native}->handles} : () } values %{$self->{jobs}}];
}
sub observation {
    my ($self) = @_; _owner($self);
    _error('unexpected observation arguments') unless @_ == 1;
    return {phase => $self->{phase}, failure => $self->{failure}, usage => $self->{ledger}->usage,
        cleanup_deadline_ns => $self->{cleanup_deadline_ns},
        native_cleanup_deadline => $self->{native_cleanup_deadline},
        endpoint => $self->{run} ? $self->{run}->observation : undef,
        cleanup => $self->{cleanup} ? {%{$self->{cleanup}}} : undef};
}
sub close {
    my ($self) = @_; _owner($self);
    _error('unexpected close arguments') unless @_ == 1;
    return {%{$self->{cleanup}}} if $self->{phase} eq 'closed';
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $self->{phase} = 'closing';
            $self->_begin_cleanup;
            my $cancel_error;
            eval { $self->cancel_job($self->{jobs}{1}{grant}, 'coordinator closes unreleased jobs'); 1 }
                or $cancel_error = $@;
            $self->_failure($cancel_error) if defined $cancel_error;
            my $pending = 0;
            for my $entry (values %{$self->{jobs}}) {
                my $native = $entry->{native} or next;
                my $observed = $native->observation;
                unless ($observed->{phase} eq 'finished') {
                    $native->advance;
                }
                if ($native->observation->{phase} ne 'finished') { $pending = 1; next; }
                _error('native job cleanup incomplete')
                    unless $native->finished_job->{resources_closed} && !@{$native->handles};
            }
            if ($pending) {
                $self->{cleanup} = {ok => 0, pending => 1, diagnostic => 'native cleanup remains pending'};
                return;
            }
            die $cancel_error if defined $cancel_error;
            if ($self->{service}) {
                my $closed = $self->{service}->close;
                if ($closed->{pending}) {
                    $self->{cleanup} = {ok => 0, pending => 1, diagnostic => 'accepted peer cleanup remains pending'};
                    return;
                }
                _error('accepted peer cleanup incomplete') unless $closed->{ok};
                $self->_consume_closed_peers;
            }
            my $cleanup = $self->{run} ? $self->{run}->close
                : {ok => 1, socket_removed => 0, directory_removed => 0, diagnostic => 'unopened run closed'};
            $cleanup = {%$cleanup, ok => 0, diagnostic => 'run descriptor cleanup incomplete'}
                if @{$self->handles};
            $self->{cleanup} = $cleanup;
            unless ($cleanup->{ok}) {
                $self->_failure($cleanup->{diagnostic});
                $self->{phase} = 'close_failed';
                return;
            }
            # Every job and the endpoint are now actually closed.
            # Keep all charges if native cleanup was incomplete; otherwise
            # release even a reservation whose producer return was interrupted.
            $self->{ledger}->release_descriptors($_, 0) for @{$self->{ledger}->descriptor_grants};
            $_->{retired} = 1 for values %{$self->{peers}};
            for my $grant (reverse @{$self->{ledger}->grants}) {
                $self->{ledger}->release_resources($grant, children => 0, descriptors => 0);
                $self->{ledger}->finish($grant);
                $self->{ledger}->retire($grant);
            }
            $self->{phase} = 'closed';
        });
        1;
    };
    unless ($ok) {
        my $error = $@; $self->_failure($error);
        $self->{phase} = 'close_failed' unless $self->{phase} eq 'closed';
        die $error;
    }
    return {%{$self->{cleanup}}};
}

1;
