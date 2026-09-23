package FSM::Support::ProcessSupervisor::GatedPair;

use strict;
use warnings;

use Errno qw(EAGAIN EINTR ESRCH EWOULDBLOCK);
use POSIX qw(SIG_BLOCK SIG_SETMASK WNOHANG _exit setpgid);
use Time::HiRes qw(gettimeofday);
use FSM::Support::ProcessSupervisor ();
use FSM::Support::ProcessSupervisor::Reservation ();
use FSM::Support::ProcessSupervisor::Wire ();

# Inactive launch strategy. Preparation owns both child slots and all pipe
# ends before start; the future coordinator must charge resource_cost against
# its aggregate ledger and retain this object before allowing either fork.
# prepare_record creates the complete owner graph without descriptors;
# allocate creates pipes only after that graph is retained by its caller.
# Capture, subtree closure and public results remain with the shared engine.
my $LIMIT = FSM::Support::ProcessSupervisor::Wire::limits();
my @PAIRS = ([qw(stdin child_stdin)], [qw(stdout child_stdout)],
    [qw(stderr child_stderr)], [qw(ack child_ack)],
    [qw(child_gate gate)], [qw(control child_control)]);
my @HANDLES = map { @$_ } @PAIRS;

sub _error { die "private gated process: $_[0]\n" }
sub _now { return FSM::Support::ProcessSupervisor::Reservation::_now() }
sub _fork { return fork() }
sub _mask { return POSIX::sigprocmask(@_) }
sub _write { return syswrite($_[0], $_[1], 1) }
sub _wait { return waitpid($_[0], WNOHANG) }
sub _signal { return kill($_[0], $_[1]) }
sub _join { return setpgid(0, $_[0]) }
sub _close_handle { return close $_[0] }

sub _owner {
    my ($self) = @_;
    _error('invalid or inherited pair') unless ref($self) eq __PACKAGE__
        && $self->{owner_pid} == $$;
}

sub resource_cost { return {children => 2, descriptors => 16} }

sub _close {
    my ($self, @names) = @_;
    for my $name (@names) {
        my $fh = delete $self->{$name};
        next unless defined $fh;
        $self->{failure} //= 'command descriptor close failed' unless _close_handle($fh);
    }
}

sub _fail {
    my ($self, $why) = @_;
    $self->{failure} //= $why;
    $self->{phase} = 'failed';
    delete $self->{outgoing};
    # EOF can only abort a child waiting at either gate, never release it.
    $self->_close('gate');
}

sub prepare_record {
    my (%args) = @_;
    _error('expected snapshot, deadline and close_handles') unless keys(%args) == 3
        && exists($args{snapshot}) && exists($args{deadline}) && exists($args{close_handles});
    my $snapshot = FSM::Support::ProcessSupervisor::Wire::decode_frame('client',
        FSM::Support::ProcessSupervisor::Wire::encode_frame('client', $args{snapshot}));
    _error('expected an admitted execution snapshot') unless $snapshot->{type} eq 'SPAWN';
    my ($cwd, $error) = FSM::Support::ProcessSupervisor::repository_contained_path(
        $snapshot->{cwd}, must_exist => 1);
    _error('execution directory is unavailable') if defined($error) || !-d $cwd;
    my $handles = $args{close_handles};
    _error('descriptor inventory exceeds pair admission') unless ref($handles) eq 'ARRAY'
        && @$handles <= $LIMIT->{descriptors} - resource_cost()->{descriptors};
    my %seen;
    for my $fh (@$handles) {
        my $fd = eval { fileno($fh) };
        _error('invalid inherited descriptor inventory') unless defined($fd)
            && $fd >= 3 && !$seen{$fd}++;
    }
    my $self = bless {owner_pid => $$, phase => 'unallocated', snapshot => $snapshot,
        cwd => $cwd, deadline => $args{deadline}, close_handles => [@$handles],
        reserved_children => 2, command_reaped => 0, command_authority => 0,
        joined => 0, released => 0, retired => 0,
        dispositions => {%SIG}}, __PACKAGE__;
    $self->{reservation} = FSM::Support::ProcessSupervisor::Reservation::prepare_record(
        deadline => $args{deadline}, close_handles => $handles);
    return $self;
}

sub allocate {
    my ($self) = @_; _owner($self);
    _error('allocation requires a retained unallocated pair')
        unless @_ == 1 && $self->{phase} eq 'unallocated' && !$self->{retired};
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $self->{phase} = 'allocating';
            my $allocated = eval {
                FSM::Support::ProcessSupervisor::Reservation::_inventory(
                    $self->{close_handles}, $LIMIT->{descriptors} - resource_cost()->{descriptors});
                for my $pair (@PAIRS) {
                    FSM::Support::ProcessSupervisor::Reservation::_check_allocation_deadline($self->{deadline});
                    FSM::Support::ProcessSupervisor::Reservation::_pipe(
                        \$self->{$pair->[0]}, \$self->{$pair->[1]}) or _error('cannot allocate command pipe');
                    for my $name (@$pair) {
                        FSM::Support::ProcessSupervisor::Reservation::_seal(
                            $self->{$name}, $name =~ /\A(?:stdout|stderr|ack|gate|control)\z/ ? 1 : 0);
                    }
                }
                # stdin is the read end; no child may inherit its writer.
                $self->_close('child_stdin');
                _error($self->{failure}) if $self->{failure};
                $self->{reservation}->allocate($self->handles);
                $self->{phase} = 'prepared';
                1;
            };
            unless ($allocated) {
                my $why = $@; $self->_fail($why);
                $self->_close(@HANDLES);
                $self->{reservation}->retire(
                    FSM::Support::ProcessSupervisor::Reservation::_minimum($self->{deadline}, _now()));
                die $why;
            }
        });
        1;
    };
    unless ($ok) {
        my $error = $@; $self->_fail($error); die $error;
    }
    return;
}

sub prepare {
    my $self = prepare_record(@_);
    my $ok = eval { $self->allocate; 1 };
    unless ($ok) {
        my $error = $@;
        $self->retire(FSM::Support::ProcessSupervisor::Reservation::_minimum($self->{deadline}, _now()));
        die $error;
    }
    return $self;
}

sub start {
    my ($self) = @_; _owner($self);
    _error('unexpected start state') unless @_ == 1 && $self->{phase} eq 'prepared';
    $self->{phase} = 'group_pending';
    $self->{reservation}->start;
}

sub _start_command {
    my ($self) = @_;
    my $all = POSIX::SigSet->new; $all->fillset;
    my $old = POSIX::SigSet->new;
    unless (defined _mask(SIG_BLOCK, $all, $old)) {
        $self->_fail('cannot mask command fork signals'); return;
    }
    $self->{exec_mask} = $old;
    $self->{reservation_handles} = $self->{reservation}->handles;
    @{$self}{qw(birth_sec birth_usec)} = gettimeofday();
    my $pid = _fork();
    if (defined($pid) && !$pid) { eval { _child($self) }; _exit(126); }
    if (defined $pid) {
        $self->{command_pid} = $pid;
        $self->{command_authority} = 1;
        $self->{phase} = 'join_pending';
        $self->{outgoing} = 'J';
        $self->{handshake_deadline} = FSM::Support::ProcessSupervisor::Reservation::_minimum(
            $self->{deadline}, _now() + $LIMIT->{handshake_seconds});
    }
    else { $self->_fail('cannot fork command child'); }
    $self->_close(qw(stdin child_stdout child_stderr child_ack child_gate child_control));
    delete $self->{close_handles};
    delete $self->{dispositions};
    delete $self->{exec_mask};
    delete $self->{reservation_handles};
    unless (defined _mask(SIG_SETMASK, $old)) {
        $self->_fail('fatal command signal-mask restoration failure');
        _error($self->{failure});
    }
    $self->_fail($self->{failure}) if $self->{failure};
}

sub _child_expect {
    my ($fh, $expected) = @_;
    while (1) {
        my $n = sysread($fh, my $byte, 1);
        next if !defined($n) && $! == EINTR;
        _exit(125) unless defined($n) && $n == 1 && $byte eq $expected;
        return;
    }
}

sub _child {
    my ($self) = @_;
    # Caught callbacks would be reset by exec; do so before private handshakes
    # as well. Preserve the root's ignored dispositions and exec signal mask.
    for my $signal (grep { !/^__/ } keys %SIG) {
        my $saved = $self->{dispositions}{$signal};
        $SIG{$signal} = defined($saved) && !ref($saved) && $saved eq 'IGNORE'
            ? 'IGNORE' : 'DEFAULT';
    }
    alarm 0;
    for my $fh (@{$self}{qw(stdout stderr ack gate control)},
        @{$self->{reservation_handles}}, @{$self->{close_handles}}) {
        _exit(126) unless _close_handle($fh);
    }
    _exit(126) unless defined _mask(SIG_SETMASK, POSIX::SigSet->new);
    _child_expect($self->{child_gate}, 'J');
    my $group = $self->{reservation}->{pid};
    my $joined = _join($group);
    _exit(126) unless defined($joined) && $joined == 0 && getpgrp(0) == $group;
    FSM::Support::ProcessSupervisor::Reservation::_child_byte($self->{child_ack}, 'J');
    _child_expect($self->{child_gate}, 'E');
    for my $fh (@{$self}{qw(child_gate child_ack)}) { _exit(126) unless _close_handle($fh); }
    my $control = $self->{child_control};
    unless (chdir($self->{cwd}) && open(STDIN, '<&', $self->{stdin})
        && open(STDOUT, '>&', $self->{child_stdout})
        && open(STDERR, '>&', $self->{child_stderr})) {
        FSM::Support::ProcessSupervisor::_write_child_control($control, 'command descriptor or cwd handoff failed');
        _exit(126);
    }
    for my $fh (@{$self}{qw(stdin child_stdout child_stderr)}) { _exit(126) unless _close_handle($fh); }
    my $snapshot = $self->{snapshot};
    %ENV = map { @$_ } @{$snapshot->{environment}};
    umask $snapshot->{umask};
    _exit(126) unless defined _mask(SIG_SETMASK, $self->{exec_mask});
    {
        no warnings 'exec';
        exec {$snapshot->{argv}[0]} @{$snapshot->{argv}};
    }
    FSM::Support::ProcessSupervisor::_write_child_control($control, "exec failed: $!");
    _exit(127);
}

sub advance {
    my ($self) = @_; _owner($self);
    _error('unexpected advance arguments') unless @_ == 1;
    return if $self->{phase} eq 'unallocated' || $self->{phase} eq 'prepared' || $self->{retired};
    my $r = $self->{reservation};
    $r->advance;
    my $o = $r->observation;
    $self->_fail($o->{failure}) if $o->{failure} && !$self->{failure};
    if ($o->{retired}) { $self->_fail('reservation identity already retired'); return; }
    # Cancellation may still need the live reservation to leave its group.
    if ($self->{failure}) {
        $r->depart if $o->{phase} eq 'group_ready';
        return;
    }
    if (_now() >= $self->{deadline}) { $self->_fail('command execution deadline expired'); return; }
    if ($self->{phase} eq 'group_pending' && $o->{phase} eq 'group_ready') {
        $self->_start_command; return;
    }
    if ($self->{phase} eq 'move_pending' && $o->{phase} eq 'moved') {
        $self->{phase} = 'ready';
    }
    return if $self->{phase} eq 'released';
    if ($self->{phase} eq 'join_pending' && _now() >= $self->{handshake_deadline}) {
        $self->_fail('command join deadline expired'); return;
    }
    if (defined $self->{outgoing}) {
        local $SIG{PIPE} = 'IGNORE';
        my $n = _write($self->{gate}, $self->{outgoing});
        return if !defined($n) && ($! == EAGAIN || $! == EINTR || $! == EWOULDBLOCK);
        if (!defined($n) || $n != 1) { $self->_fail('command gate write failed'); return; }
        my $byte = delete $self->{outgoing};
        if ($byte eq 'E') {
            $self->{released} = 1;
            $self->{phase} = 'released';
            $self->_close(qw(gate ack));
            return;
        }
    }
    return unless $self->{ack};
    my $n = sysread($self->{ack}, my $bytes, 2);
    return if !defined($n) && ($! == EAGAIN || $! == EINTR || $! == EWOULDBLOCK);
    if (defined($n) && $n == 1 && $bytes eq 'J'
        && $self->{phase} eq 'join_pending' && !defined($self->{outgoing})) {
        $self->{joined} = 1;
        $self->{phase} = 'move_pending';
        $r->depart;
    }
    else { $self->_fail('command join acknowledgment lost or invalid'); }
}

sub release {
    my ($self) = @_; _owner($self);
    _error('exec release requires acknowledged join and departure') unless @_ == 1
        && $self->{phase} eq 'ready' && !$self->{failure} && !$self->{retired};
    my $reservation = $self->{reservation}->observation;
    _error('exec release requires live reservation identity')
        if $reservation->{retired} || $reservation->{failure}
            || $reservation->{phase} ne 'moved';
    # The coordinator calls only after complete ownership publication. This
    # explicit edge is intentionally absent from automatic advancement.
    $self->{phase} = 'release_pending';
    $self->{outgoing} = 'E';
}

sub cancel {
    my ($self) = @_; _owner($self);
    _error('unexpected cancel arguments') unless @_ == 1 && !$self->{retired};
    $self->_fail('command cancelled');
}

sub poll_command {
    my ($self) = @_; _owner($self);
    _error('unexpected command poll arguments') unless @_ == 1;
    return unless $self->{command_authority};
    my $waited = _wait($self->{command_pid});
    if ($waited == $self->{command_pid}) {
        $self->{command_status} = $?;
        $self->{command_reaped} = 1;
        $self->{command_authority} = 0;
        $self->_fail('command exited before exec release') unless $self->{released};
    }
    elsif ($waited == -1 && $! != EINTR) {
        $self->{command_authority} = 0;
        $self->_fail('command wait status is unknown');
    }
}

sub signal_command {
    my ($self, $signal) = @_; _owner($self);
    _error('signal requires an unharvested direct command') unless @_ == 2
        && defined($signal) && ($signal eq 'TERM' || $signal eq 'KILL')
        && $self->{command_authority} && !$self->{retired};
    local $! = 0;
    my $sent = _signal($signal, $self->{command_pid});
    $self->_fail('command signal failed') unless $sent || $! == ESRCH;
    return $sent ? 1 : 0;
}

sub retire {
    my ($self, $deadline) = @_; _owner($self);
    _error('retirement requires a remaining closure deadline') unless @_ == 2;
    return if $self->{retired};
    # The capture owner must finish every group operation first. Reservation
    # retirement enforces the shared wall and irreversibly revokes PGID use.
    $self->{reservation}->retire($deadline);
    $self->{retired} = 1;
    $self->_fail('command identity retired before exact reaping')
        if $self->{command_pid} && !$self->{command_reaped};
    $self->{command_authority} = 0;
    $self->_close(@HANDLES);
    delete $self->{close_handles};
    $self->{phase} = 'retired';
}

sub observation {
    my ($self) = @_; _owner($self);
    _error('unexpected observation arguments') unless @_ == 1;
    return {map { $_ => $self->{$_} } qw(phase command_pid birth_sec birth_usec
        command_reaped command_status command_authority joined released retired failure)};
}

sub reservation { my ($self) = @_; _owner($self); return $self->{reservation}; }

sub transfer_streams {
    my ($self, $recipient) = @_; _owner($self);
    _error('stream transfer requires one retained empty plain record')
        unless @_ == 2 && ref($recipient) eq 'HASH' && !tied(%$recipient)
            && !keys(%$recipient);
    _error('stream transfer requires the acknowledged unreleased command')
        unless $self->{phase} eq 'ready' && !$self->{failure}
            && !$self->{retired} && !$self->{streams_transferred};
    my $reservation = $self->{reservation}->observation;
    _error('stream transfer requires live reservation identity')
        if $reservation->{retired} || $reservation->{failure}
            || $reservation->{phase} ne 'moved';
    my @names = qw(stdout stderr control);
    _error('stream transfer requires open capture descriptors')
        if grep { !defined($self->{$_}) || !defined(fileno($self->{$_})) } @names;
    my $all = POSIX::SigSet->new; $all->fillset;
    my $old = POSIX::SigSet->new;
    _error('cannot mask stream transfer signals') unless defined _mask(SIG_BLOCK, $all, $old);
    # The caller retains recipient BEFORE this call. No callbacks or I/O
    # separate publication from removal of the old ownership. A restored
    # signal or failed return cannot strand handles in a temporary return value.
    @{$recipient}{@names} = @{$self}{@names};
    delete @{$self}{@names};
    $self->{streams_transferred} = 1;
    unless (defined _mask(SIG_SETMASK, $old)) {
        $self->_fail('fatal stream transfer signal-mask restoration failure');
        _error($self->{failure});
    }
    return;
}

sub handles {
    my ($self) = @_; _owner($self);
    return [map { $self->{$_} } grep { defined $self->{$_} } @HANDLES];
}
sub streams {
    my ($self) = @_; _owner($self);
    return {map { $_ => $self->{$_} } grep { defined $self->{$_} } qw(stdout stderr control)};
}

1;
