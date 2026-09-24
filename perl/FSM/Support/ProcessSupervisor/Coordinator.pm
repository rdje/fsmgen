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
# Execution release, outcome delivery and fair scheduling follow.
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
                $self->{run}->start_run(sub { $self->_before_run_allocation(@_) });
                my $handles = $self->{run}->handles;
                _error('native run inventory disagrees with reserved cost')
                    unless @$handles == $COST->{steady_descriptors};
                $self->{ledger}->descriptors_prepared($self->{run_grant}, scalar @$handles);
                $self->{service} = FSM::Support::ProcessSupervisor::Service::new_shared_service(
                    $self->{run}, $self->{ledger}->describe($self->{jobs}{1}{grant})->{deadline_ns});
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
    $self->{ledger}->check_live($self->{jobs}{1}{grant});
    return $self->{service}->context;
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
        _error('accepted socket exceeds its original grant') if $observed->{handles} > 1;
        if ($observed->{handles}) {
            my $held = $self->{ledger}->describe_descriptors($entry->{grant});
            _error('accepted socket lost its original descriptor credit') unless $held->{count} == 1;
            $self->{ledger}->descriptors_prepared($entry->{grant}, 1) if $held->{reserved};
        }
        # Closed outcomes keep conservative credit until whole-run close.
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
                $self->{ledger}->check_live($self->{jobs}{1}{grant});
                $self->{service}->advance(sub { $self->_before_peer_accept(@_) });
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
        admission => $entry->{grant} && !$entry->{retired}
            ? $self->{ledger}->describe_descriptors($entry->{grant}) : undef,
        outcome => $entry->{outcome} ? {%{$entry->{outcome}}} : undef};
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
    my ($self, $grant) = @_;
    my $record = $self->{ledger}->describe($grant);
    my $entry = $self->{jobs}{$record->{id}};
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
    my $grant;
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $grant = $self->{ledger}->reserve_job(parent => $args{parent},
                map { $_ => $snapshot->{$_} } qw(started_ns timeout_seconds));
            my $id = $self->{ledger}->describe($grant)->{id};
            $self->{jobs}{$id} = {grant => $grant, snapshot => $snapshot};
        });
        1;
    };
    unless ($ok) {
        my $error = $@;
        $self->_job_failed($grant, $error) if $grant;
        die $error;
    }
    # If a pending handler interrupts this return, grants still exposes the
    # original record and its detached snapshot. No native effect has occurred.
    return $grant;
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
    $self->{ledger}->check_live($grant);
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
            $self->{ledger}->begin_prepare($grant);
            # The constructor is resource-free. Publish its entire graph before
            # allocate; the caller's original snapshot is then owned by the pair.
            $entry->{native} = FSM::Support::ProcessSupervisor::ReservedJob::prepare_record(
                snapshot => $entry->{snapshot}, deadline => $record->{deadline_ns} / 1_000_000_000,
                close_handles => $self->handles);
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
    $self->{ledger}->check_live($grant);
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
        $self->{ledger}->check_live($grant) unless $record->{phase} eq 'closing';
        $self->cancel_job($grant, $entry->{failure} // 'job admission revoked')
            if $record->{phase} eq 'closing';
        if ($entry->{native}) {
            $entry->{native}->advance;
            my $observed = $entry->{native}->observation;
            if ($observed->{first_failure} && $record->{phase} ne 'closing') {
                $self->_job_failed($grant, $observed->{first_failure}{diagnostic});
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
    unless ($ok) { my $error = $@; $self->_job_failed($grant, $error); die $error; }
    return $self->job_observation($grant);
}
sub job_observation {
    my ($self, $grant) = @_; _owner($self);
    _error('job observation requires an original grant') unless @_ == 2;
    my ($entry, $record) = $self->_job($grant);
    return {admission => $record, failure => $entry->{failure}, cleanup_error => $entry->{cleanup_error},
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
