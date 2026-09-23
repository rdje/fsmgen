package FSM::Support::ProcessSupervisor::GroupClosure;

use strict;
use warnings;

use FSM::Support::ProcessSupervisor::GatedPair ();

# Private, nonblocking closure of one already-retained pair. The coordinator
# supplies the SAME remaining deadline to every affected job; no advance
# sleeps, extends it, or grants reservation retirement another grace period.
# Transferred capture handles and logical descendants remain caller-owned.
my ($TERM_GRACE, $KILL_GRACE) = FSM::Support::ProcessSupervisor::_termination_graces();

sub _error { die "private process group closure: $_[0]\n" }
sub _now { return FSM::Support::ProcessSupervisor::Reservation::_now() }
sub _minimum { return $_[0] < $_[1] ? $_[0] : $_[1] }

sub _owner {
    my ($self) = @_;
    _error('invalid or inherited closure') unless ref($self) eq __PACKAGE__
        && $self->{owner_pid} == $$;
}

sub prepare {
    my (%args) = @_;
    _error('expected pair, cancel and deadline') unless keys(%args) == 3
        && exists($args{pair}) && exists($args{cancel}) && exists($args{deadline});
    my $pair = $args{pair};
    _error('expected a retained gated pair')
        unless ref($pair) eq 'FSM::Support::ProcessSupervisor::GatedPair';
    my $command = $pair->observation;
    _error('pair identity is already retired') if $command->{retired};
    _error('cancel must be an integer boolean') unless defined($args{cancel})
        && !ref($args{cancel}) && "$args{cancel}" =~ /\A[01]\z/;
    _error('normal closure requires the exact released command wait')
        unless $args{cancel} || ($command->{released} && $command->{command_reaped});
    my $deadline = FSM::Support::ProcessSupervisor::Reservation::_time($args{deadline});
    my $now = _now();
    _error('closure cannot extend the original cleanup envelope')
        if $deadline > _minimum($pair->{deadline}, $now) + $TERM_GRACE + $KILL_GRACE;
    return bless {
        owner_pid => $$, pair => $pair, cancel => 0 + $args{cancel},
        phase => 'stopping', deadline => $deadline,
        kill_at => _minimum($now + $TERM_GRACE, $deadline - $KILL_GRACE),
        term_sent => 0, kill_sent => 0, group_gone => 0,
        surviving_descendants => 0, complete => 0,
    }, __PACKAGE__;
}

sub _failure { $_[0]->{failure} //= $_[1]; return; }

sub _signal_remaining {
    my ($self, $command, $reservation, $signal) = @_;
    my $pair = $self->{pair};
    my $phase = lc $signal;
    # Until departure is acknowledged, even an acknowledged join grants no
    # group-signal permission. Stop only the known unharvested direct child.
    if ($reservation->{moved} && !$self->{group_gone}) {
        unless ($self->{attempted}{$phase}{group}++) {
            my $sent = $pair->reservation->signal_group($signal);
            $self->{"${phase}_sent"} = 1 if $sent;
        }
    }
    elsif (!$reservation->{moved} && $command->{command_authority}) {
        unless ($self->{attempted}{$phase}{command}++) {
            my $sent = $pair->signal_command($signal);
            $self->{"${phase}_sent"} = 1 if $sent;
        }
    }
}

sub _retire {
    my ($self) = @_;
    # GatedPair retires every command/group signal target before the
    # reservation can be released or reaped. No stored PID is used afterwards.
    $self->{pair}->retire($self->{deadline});
    $self->{phase} = 'retiring';
    $self->_advance_retirement;
}

sub _advance_retirement {
    my ($self) = @_;
    my $reservation = $self->{pair}->reservation;
    $reservation->advance;
    my $r = $reservation->observation;
    return unless $r->{phase} eq 'finished';
    my $c = $self->{pair}->observation;
    $self->_failure('command wait status is unknown')
        if $c->{command_pid} && !$c->{command_reaped};
    $self->_failure('reserved command group disappearance is unproved')
        unless $self->{group_gone};
    $self->_failure('reservation closure lacks an exact wait')
        if $r->{pid} && (!$r->{reaped} || !defined($r->{wait_status}));
    $self->{complete} = !defined($self->{failure}) ? 1 : 0;
    $self->{phase} = 'finished';
}

sub advance {
    my ($self) = @_; _owner($self);
    _error('unexpected advance arguments') unless @_ == 1;
    return if $self->{phase} eq 'finished';
    if ($self->{phase} eq 'retiring') { $self->_advance_retirement; return; }
    my $pair = $self->{pair};
    if ($self->{cancel} && !$self->{gate_cancelled}) {
        $pair->cancel;
        $self->{gate_cancelled} = 1;
    }
    $pair->poll_command;
    my $c = $pair->observation;
    my $r = $pair->reservation->observation;
    # Stop a gated command before advancing the reservation's departure.
    # Once moved, the group operation also reaches descendants of a released
    # command. Separate attempt flags permit that newly available authority.
    my $signal = _now() >= $self->{kill_at} ? 'KILL' : 'TERM';
    $self->{phase} = 'killing' if $signal eq 'KILL';
    $self->_signal_remaining($c, $r, $signal)
        if $self->{cancel} && !$r->{moved};
    $pair->advance;
    $r = $pair->reservation->observation;
    if ($r->{moved} && (!$c->{command_pid} || !$c->{command_authority})) {
        # Harvest the known direct command before querying group absence.
        # A dying unharvested command can leave a transient unprobeable group;
        # it already prevents closure without needing to infer any OS state.
        my $absent = $pair->reservation->group_absent;
        $self->{group_gone} = $absent ? 1 : 0;
        $self->_failure('reserved command group absence is uncertain') unless defined $absent;
        $self->{surviving_descendants} = 1
            if !$self->{cancel} && defined($absent) && !$absent;
    }
    else { $self->{group_gone} = $r->{pid} ? 0 : 1; }
    if ((!$c->{command_pid} || $c->{command_reaped}) && $self->{group_gone}) {
        $self->_retire;
        return;
    }
    $self->_signal_remaining($c, $r, $signal);
    if (_now() >= $self->{deadline}) {
        $self->_failure('shared cleanup deadline expired before command-group closure');
        $self->_retire;
    }
}

sub observation {
    my ($self) = @_; _owner($self);
    _error('unexpected observation arguments') unless @_ == 1;
    my $c = $self->{pair}->observation;
    my $r = $self->{pair}->reservation->observation;
    return {
        map({ $_ => $self->{$_} } qw(phase deadline kill_at term_sent kill_sent
            group_gone surviving_descendants complete failure)),
        leader_started => $c->{command_pid} ? 1 : 0,
        leader_reaped => $c->{command_reaped} ? 1 : 0,
        reservation_started => $r->{pid} ? 1 : 0,
        reservation_reaped => $r->{reaped} ? 1 : 0,
        reservation_wait_status => $r->{wait_status},
        reservation_failure => $r->{failure},
    };
}

1;
