package FSM::Support::ProcessSupervisor::ReservedJob;

use strict;
use warnings;

use IO::Select;
use FSM::Support::ProcessSupervisor ();
use FSM::Support::ProcessSupervisor::GroupClosure ();

# Inactive private strategy. The coordinator reserves aggregate capacity and
# retains this prepared job BEFORE start. Only explicit release may follow
# complete ownership publication. Public/sealed callers still use the legacy
# engine; this component owns no connection, subtree or receipt-review policy.
my ($TERM_GRACE, $KILL_GRACE) = FSM::Support::ProcessSupervisor::_termination_graces();

sub _error { die "private reserved process: $_[0]\n" }
sub _now { return FSM::Support::ProcessSupervisor::Reservation::_now() }
sub _minimum { return $_[0] < $_[1] ? $_[0] : $_[1] }
sub _owner {
    my ($self) = @_;
    _error('invalid or inherited job') unless ref($self) eq __PACKAGE__
        && $self->{owner_pid} == $$;
}

sub prepare {
    my (%args) = @_;
    _error('expected snapshot, deadline and close_handles') unless keys(%args) == 3
        && exists($args{snapshot}) && exists($args{deadline}) && exists($args{close_handles});
    my $pair = FSM::Support::ProcessSupervisor::GatedPair::prepare(%args);
    my $snapshot = $pair->{snapshot};
    my $started = $snapshot->{started_ns} / 1_000_000_000;
    my $now = _now();
    if ($started > $now || $args{deadline} > $started + $snapshot->{timeout_seconds}) {
        $pair->retire($now);
        _error('deadline must preserve the original invocation wall');
    }
    my $self = bless {
        owner_pid => $$, pair => $pair, received => {},
        state => {
            map({ $_ => $snapshot->{$_} } qw(schema stage containment)),
            bounds => {map { $_ => $snapshot->{$_} } qw(timeout_seconds capture_limit_bytes)},
            phase => 'prepared', deadline => 0 + $args{deadline}, started => $started,
            stdout => '', stderr => '', exec_error => '',
            exec_handoff => undef, first_output => undef,
            leader_reaped => 0, leader_status => undef,
            timed_out => 0, output_limited => 0, latch_failures => 1,
            cleanup => FSM::Support::ProcessSupervisor::_new_cleanup(0, $snapshot->{containment}),
            select => IO::Select->new, streams => {},
        },
    }, __PACKAGE__;
    $self->_sync_identity;
    return $self;
}

sub _sync_identity {
    my ($self) = @_;
    my $s = $self->{state};
    my $c = $self->{pair}->observation;
    my $r = $self->{pair}->reservation->observation;
    @{$s}{qw(pid birth_sec birth_usec leader_reaped leader_status)} =
        @{$c}{qw(command_pid birth_sec birth_usec command_reaped command_status)};
    $s->{cleanup}{leader_started} = $c->{command_pid} ? 1 : 0;
    $s->{group_identity} = {
        pid => $r->{pid}, start_sec => $r->{birth_sec}, start_usec => $r->{birth_usec},
    };
    $s->{reservation_observation} = $r;
    return ($c, $r);
}

sub start {
    my ($self) = @_; _owner($self);
    _error('start requires a retained prepared job')
        unless @_ == 1 && $self->{state}{phase} eq 'prepared';
    $self->{state}{phase} = 'launch';
    $self->{pair}->start;
    $self->_sync_identity;
}

sub release {
    my ($self) = @_; _owner($self);
    _error('release requires the ready published job')
        unless @_ == 1 && $self->{state}{phase} eq 'ready';
    $self->{pair}->release;
    $self->{state}{phase} = 'releasing';
}

sub _latch {
    my ($self, $status, $diagnostic) = @_;
    FSM::Support::ProcessSupervisor::_latch_supervision_failure(
        $self->{state}, $status, $diagnostic);
}

sub _attach_capture {
    my ($self) = @_;
    my $s = $self->{state};
    # Keep the recipient reachable before transfer. If mask restoration throws,
    # cancellation still sees every transferred handle through this record.
    $self->{pair}->transfer_streams($self->{received});
    for my $name (qw(stdout stderr control)) {
        my $fh = $self->{received}{$name};
        $s->{streams}{fileno($fh)} = [$name, $fh];
        $s->{select}->add($fh);
    }
    $s->{control_fileno} = fileno($self->{received}{control});
    $s->{phase} = 'ready';
}

sub _close_capture {
    my ($self) = @_;
    # streams borrows these handles; the shared reader may already have closed
    # some at EOF. Closing the retained recipient handles also covers an
    # interrupted transfer return or partially constructed selector.
    FSM::Support::ProcessSupervisor::_close_handles(values %{$self->{received}});
    $self->{received} = {};
    $self->{state}{streams} = {};
    $self->{state}{select} = IO::Select->new;
}

sub _begin_cleanup {
    my ($self, $cancel, $deadline) = @_;
    my $s = $self->{state};
    return if $s->{phase} eq 'cleanup' || $s->{phase} eq 'finished';
    $deadline //= _minimum($s->{deadline}, _now()) + $TERM_GRACE + $KILL_GRACE;
    $self->{closure} = FSM::Support::ProcessSupervisor::GroupClosure::prepare(
        pair => $self->{pair}, cancel => $cancel, deadline => $deadline);
    $self->_close_capture;
    $s->{phase} = 'cleanup';
}

sub cancel {
    my ($self, $diagnostic, $deadline) = @_; _owner($self);
    _error('cancel requires a diagnostic and shared closure deadline')
        unless @_ == 3 && defined($diagnostic) && !ref($diagnostic)
            && length($diagnostic) && defined($deadline);
    return if $self->{state}{phase} eq 'finished';
    $self->_latch('host_error', FSM::Support::ProcessSupervisor::_sanitize_control($diagnostic));
    $self->_begin_cleanup(1, $deadline);
}

sub _capture {
    my ($self) = @_;
    my $s = $self->{state};
    FSM::Support::ProcessSupervisor::_read_supervision_streams($s);
    $self->{pair}->poll_command;
    my ($c, $r) = $self->_sync_identity;
    if (defined($c->{failure})) { $self->_latch('host_error', $c->{failure}); }
    if (defined($s->{host_error}) || $s->{output_limited} || length($s->{exec_error})
            || defined($c->{failure})) {
        $self->_begin_cleanup(1);
        return;
    }
    return unless $c->{command_reaped};
    my $raw = $c->{command_status};
    if ($raw & 127) { $self->_latch('signaled', 'supervised process exited after a signal'); }
    elsif ($raw >> 8) { $self->_latch('nonzero_exit', 'supervised process exited nonzero'); }
    my $absent = $self->{pair}->reservation->group_absent;
    if (!defined($absent)) {
        $self->_latch('host_error', 'reserved command group absence is uncertain');
        $self->_begin_cleanup(1);
    }
    elsif (!$absent) {
        $s->{surviving_descendants} = $s->{cleanup}{surviving_descendants} = 1;
        $self->_latch('surviving_descendants', 'supervised process left descendants after leader exit');
        $self->_begin_cleanup(0);
    }
    elsif (!$s->{select}->count) { $self->_begin_cleanup(0); }
}

sub _finish {
    my ($self) = @_;
    my $s = $self->{state};
    my (undef, $r) = $self->_sync_identity;
    my $closed = $self->{closure}->observation;
    @{$s->{cleanup}}{qw(leader_reaped group_gone term_sent kill_sent)} =
        @{$closed}{qw(leader_reaped group_gone term_sent kill_sent)};
    $s->{surviving_descendants} ||= $closed->{surviving_descendants};
    $s->{cleanup}{surviving_descendants} = $s->{surviving_descendants} ? 1 : 0;
    $s->{reservation_reaped} = $closed->{reservation_reaped};
    $s->{resources_closed} = $closed->{complete};
    $s->{closure_observation} = $closed;
    $self->_latch('cleanup_failed', $closed->{failure}) unless $closed->{complete};
    $self->_latch('host_error', $r->{failure}) if defined($r->{failure});
    FSM::Support::ProcessSupervisor::_publish_supervision_result($s);
}

sub advance {
    my ($self) = @_; _owner($self);
    _error('unexpected advance arguments') unless @_ == 1;
    my $s = $self->{state};
    return if $s->{phase} eq 'prepared' || $s->{phase} eq 'finished';
    if ($s->{phase} eq 'cleanup') {
        $self->{closure}->advance;
        $self->_finish if $self->{closure}->observation->{phase} eq 'finished';
        return;
    }
    if (_now() >= $s->{deadline}) {
        $s->{timed_out} = 1;
        $self->_latch('timed_out', 'supervised process exceeded its fixed deadline');
        $self->_begin_cleanup(1);
        return;
    }
    $self->{pair}->advance;
    my ($c) = $self->_sync_identity;
    if (defined($c->{failure})) {
        $self->_latch('host_error', $c->{failure});
        $self->_begin_cleanup(1);
        return;
    }
    if ($s->{phase} eq 'launch' && $c->{phase} eq 'ready') { $self->_attach_capture; }
    if ($s->{phase} eq 'releasing' && $c->{released}) { $s->{phase} = 'capture'; }
    $self->_capture if $s->{phase} eq 'capture';
}

sub observation {
    my ($self) = @_; _owner($self);
    _error('unexpected observation arguments') unless @_ == 1;
    my ($c, $r) = $self->_sync_identity;
    return {phase => $self->{state}{phase}, command => $c, reservation => $r,
        first_failure => $self->{state}{first_failure}
            ? {%{$self->{state}{first_failure}}} : undef};
}

sub finished_job {
    my ($self) = @_; _owner($self);
    _error('result requires a finished job')
        unless @_ == 1 && $self->{state}{phase} eq 'finished';
    return $self->{state};
}

1;
