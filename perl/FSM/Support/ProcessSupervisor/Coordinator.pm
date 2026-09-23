package FSM::Support::ProcessSupervisor::Coordinator;

use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime);
use FSM::Support::ProcessSupervisor::Admission ();
use FSM::Support::ProcessSupervisor::Endpoint ();
use FSM::Support::ProcessSupervisor::Reservation ();
use FSM::Support::ProcessSupervisor::Wire ();

# Inactive native owner. This first composition owns only run construction;
# job allocation/start, accepted peers and fair advancement are later layers.
# Preparing this object allocates no descriptor, token, path or process.
my $COST = FSM::Support::ProcessSupervisor::Endpoint::resource_cost();
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
        jobs => {1 => {grant => $ledger->root, snapshot => $snapshot}}}, __PACKAGE__;
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
            if Math::BigInt->new(_now_ns())->bcmp($self->{cleanup_deadline_ns}) >= 0;
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
    return $self->{run}->context;
}
sub handles {
    my ($self) = @_; _owner($self);
    _error('unexpected inventory arguments') unless @_ == 1;
    return $self->{run} ? $self->{run}->handles : [];
}
sub observation {
    my ($self) = @_; _owner($self);
    _error('unexpected observation arguments') unless @_ == 1;
    return {phase => $self->{phase}, failure => $self->{failure}, usage => $self->{ledger}->usage,
        cleanup_deadline_ns => $self->{cleanup_deadline_ns},
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
            $self->{ledger}->cancel($self->{jobs}{1}{grant});
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
            # No job or accepted peer can allocate through this initial layer.
            # Keep all charges if native cleanup was incomplete; otherwise
            # release even a reservation whose producer return was interrupted.
            $self->{ledger}->release_descriptors($_, 0) for @{$self->{ledger}->descriptor_grants};
            my $root = $self->{jobs}{1}{grant};
            $self->{ledger}->release_resources($root, children => 0, descriptors => 0);
            $self->{ledger}->finish($root);
            $self->{ledger}->retire($root);
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
