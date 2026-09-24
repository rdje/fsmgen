package FSM::Support::ProcessSupervisor::GatedPair;

use strict;
use warnings;

use Errno qw(EAGAIN EINTR ESRCH EWOULDBLOCK);
use POSIX qw(SIG_BLOCK SIG_SETMASK WNOHANG _exit setpgid);
use Scalar::Util qw(refaddr);
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
        && $self->{owner_pid} == $$ && ($self->{identity} // 0) == refaddr($self);
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
    delete $self->{fork_check};
    delete $self->{release_check};
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
        cwd => $cwd, deadline => $args{deadline}, original_deadline => $args{deadline},
        close_handles => [@$handles],
        reserved_children => 2, command_reaped => 0, command_authority => 0,
        joined => 0, released => 0, release_attempted => 0, release_uncertain => 0, retired => 0,
        dispositions => {%SIG}}, __PACKAGE__;
    $self->{identity} = refaddr($self);
    $self->{reservation} = FSM::Support::ProcessSupervisor::Reservation::prepare_record(
        deadline => $args{deadline}, close_handles => $handles);
    $self->{reservation_identity} = refaddr($self->{reservation});
    return $self;
}

sub allocate {
    my ($self, $check) = @_; _owner($self);
    _error('allocation requires a retained unallocated pair')
        unless (@_ == 1 || (@_ == 2 && ref($check) eq 'CODE'))
            && $self->{phase} eq 'unallocated' && !$self->{retired};
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $self->{phase} = 'allocating';
            my $allocated = eval {
                FSM::Support::ProcessSupervisor::Reservation::_inventory(
                    $self->{close_handles}, $LIMIT->{descriptors} - resource_cost()->{descriptors});
                for my $pair (@PAIRS) {
                    FSM::Support::ProcessSupervisor::Reservation::_check_allocation_deadline($self->{deadline}, $check);
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
                $self->{reservation}->allocate($self->handles, defined($check) ? ($check) : ());
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
    my ($self, $check) = @_; _owner($self);
    _error('unexpected start state')
        unless (@_ == 1 || (@_ == 2 && ref($check) eq 'CODE')) && $self->{phase} eq 'prepared';
    $self->{fork_check} = $check if defined $check;
    $self->{phase} = 'group_pending';
    my $ok = eval {
        $self->{reservation}->start(defined($check) ? (sub {
            return [@{$self->_fork_inventory('reservation')}, @{$self->handles}];
        }) : ());
        1;
    };
    unless ($ok) {
        my $error = $@; $self->_fail(FSM::Support::ProcessSupervisor::_sanitize_control($error)); die $error;
    }
}

sub _fork_inventory {
    my ($self, $role) = @_;
    my $foreign = $self->{fork_check} ? $self->{fork_check}->($role) : $self->{close_handles};
    $foreign = FSM::Support::ProcessSupervisor::Reservation::_inventory($foreign, $LIMIT->{descriptors});
    # Fresh foreign descriptors may have appeared since preparation. Validate
    # the actual current union, including overlap with this pair's own handles.
    FSM::Support::ProcessSupervisor::Reservation::_inventory(
        [@$foreign, @{$self->handles}, @{$self->{reservation}->handles}], $LIMIT->{descriptors});
    return $foreign;
}

sub _start_command {
    my ($self) = @_;
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_fork(sub {
            my ($old) = @_;
            my $admitted = eval {
                $self->{close_handles} = $self->_fork_inventory('command');
                _error('execution deadline expired before command fork') if _now() >= $self->{deadline};
                1;
            };
            unless ($admitted) {
                my $error = $@; $self->_fail(FSM::Support::ProcessSupervisor::_sanitize_control($error)); die $error;
            }
            $self->{exec_mask} = $old;
            $self->{reservation_handles} = $self->{reservation}->handles;
            @{$self}{qw(birth_sec birth_usec)} = gettimeofday();
            my $pid = _fork();
            if (defined($pid) && !$pid) { eval { _child($self) }; _exit(126); }
            if (defined $pid) {
                $self->{command_pid} = $self->{original_command_pid} = $pid;
                $self->{command_authority} = 1;
                $self->{phase} = 'join_pending';
                $self->{outgoing} = 'J';
                $self->{handshake_deadline} = FSM::Support::ProcessSupervisor::Reservation::_minimum(
                    $self->{deadline}, _now() + $LIMIT->{handshake_seconds});
            }
            else { $self->_fail('cannot fork command child'); }
            $self->_close(qw(stdin child_stdout child_stderr child_ack child_gate child_control));
            delete @{$self}{qw(close_handles dispositions exec_mask reservation_handles fork_check)};
        }, \&_mask, 'command');
        1;
    };
    unless ($ok) {
        my $error = $@; $self->_fail(FSM::Support::ProcessSupervisor::_sanitize_control($error)); die $error;
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
    if (defined($self->{outgoing}) && $self->{outgoing} eq 'E') {
        $self->_advance_release; return;
    }
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
        delete $self->{outgoing};
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

# Only this ready native owner may reach the irreversible execution byte.
# Recheck after callbacks: they may cancel, spend the wall, retire a reservation
# or harvest the command. No launch advancement (and thus no fork) occurs here.
sub _release_live {
    my ($self, $basis, $phase) = @_; _owner($self);
    _error('exec release lost original pair state')
        unless $self->{phase} eq $phase && !$self->{failure} && !$self->{retired}
            && !$self->{released} && !$self->{release_uncertain}
            && ref($self->{release_basis}) eq 'HASH'
            && refaddr($self->{release_basis}) == refaddr($basis);
    $self->_check_custody('exec release');
    for my $name (qw(gate ack)) {
        _error('exec release lost original gate handles')
            unless defined($self->{$name}) && defined(fileno($self->{$name}))
                && refaddr($self->{$name}) == $basis->{$name};
    }
}

# The masked release transaction and original wrapper's custody inspection use
# this same native check. It never advances this Pair or writes its pending E.
sub _check_custody {
    my ($self, $purpose, $allow_completed) = @_; _owner($self);
    _error("$purpose lost original native state")
        unless $self->{phase} =~ /\A(?:ready|release_pending|released)\z/
            && !$self->{failure} && !$self->{retired} && !$self->{release_uncertain};
    _error("$purpose lost original reservation identity")
        unless ref($self->{reservation}) eq 'FSM::Support::ProcessSupervisor::Reservation'
            && refaddr($self->{reservation}) == $self->{reservation_identity};
    my $r = $self->{reservation};
    my $o = $r->observation;
    _error("$purpose requires live reservation identity")
        unless $o->{phase} eq 'moved' && !$o->{failure} && !$o->{retired} && !$o->{reaped};
    $r->advance;
    $o = $r->observation;
    _error("$purpose requires live reservation identity")
        unless $o->{phase} eq 'moved' && !$o->{failure} && !$o->{retired} && !$o->{reaped};
    return 0 if $allow_completed && $self->{released} && $self->{command_reaped}
        && !$self->{command_authority} && defined($self->{command_status});
    _error("$purpose lost original command custody")
        unless $self->{command_authority} && !$self->{command_reaped} && !$self->{failure}
            && $self->{command_pid} == $self->{original_command_pid};
    $self->poll_command;
    # Inspection may observe ordinary completion of an already released
    # command. Preserve its exact status for capture to classify normally.
    return 0 if $allow_completed && $self->{released} && $self->{command_reaped}
        && !$self->{command_authority} && defined($self->{command_status});
    _error("$purpose lost original command custody")
        unless $self->{command_authority} && !$self->{command_reaped} && !$self->{failure};
    _error("$purpose exceeded original invocation wall")
        unless $self->{deadline} == $self->{original_deadline} && _now() < $self->{original_deadline};
    return 1;
}

sub _advance_release {
    my ($self) = @_; _owner($self);
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            my $admitted = eval {
                _error('reentrant execution admission') if $self->{release_check_active};
                local $self->{release_check_active} = 1;
                my $basis = $self->{release_basis};
                $self->_release_live($basis, 'release_pending');
                my $allow = $self->{release_check} ? $self->{release_check}->($self) : 1;
                _error('execution admission must return boolean')
                    unless defined($allow) && !ref($allow) && "$allow" =~ /\A[01]\z/;
                $self->_release_live($basis, 'release_pending');
                return 1 unless $allow;
                local $SIG{PIPE} = 'IGNORE';
                # A thrown/lost native return cannot prove that no byte escaped.
                # Retain that uncertainty and revoke retries on the failure path.
                $self->{release_attempted} = $self->{release_uncertain} = 1;
                my $n = _write($self->{gate}, 'E');
                $self->{release_uncertain} = 0;
                return 1 if !defined($n) && ($! == EAGAIN || $! == EINTR || $! == EWOULDBLOCK);
                unless (defined($n) && $n == 1) {
                    $self->_fail('command gate write failed'); return 1;
                }
                $self->{released} = 1;
                $self->{phase} = 'released';
                delete @{$self}{qw(outgoing release_check)};
                $self->_close(qw(gate ack));
                1;
            };
            unless ($admitted) {
                my $why = $@;
                $self->_fail(FSM::Support::ProcessSupervisor::_sanitize_control($why));
                die $why;
            }
        });
        1;
    };
    unless ($ok) {
        my $why = $@;
        $self->_fail(FSM::Support::ProcessSupervisor::_sanitize_control($why));
        die $why;
    }
}

sub release {
    my ($self, $check) = @_; _owner($self);
    my $valid = sub {
        _error('exec release requires acknowledged join and departure')
            unless $self->{phase} eq 'ready' && !$self->{failure} && !$self->{retired};
    };
    _error('exec release requires acknowledged join and departure')
        unless @_ == 1 || (@_ == 2 && ref($check) eq 'CODE');
    $valid->();
    my $started = 0;
    my $ok = eval {
        FSM::Support::ProcessSupervisor::Reservation::_masked_preparation(sub {
            $valid->();
            $started = 1;
            my $queued = eval {
                $self->{release_basis} = {map { $_ => refaddr($self->{$_}) } qw(gate ack)};
                $self->_release_live($self->{release_basis}, 'ready');
                $self->{release_check} = $check if defined $check;
                $self->{phase} = 'release_pending';
                $self->{outgoing} = 'E';
                1;
            };
            unless ($queued) {
                my $why = $@;
                $self->_fail(FSM::Support::ProcessSupervisor::_sanitize_control($why));
                die $why;
            }
        });
        1;
    };
    unless ($ok) {
        my $why = $@;
        $self->_fail(FSM::Support::ProcessSupervisor::_sanitize_control($why)) if $started;
        die $why;
    }
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
    delete @{$self}{qw(close_handles release_check)};
    $self->{phase} = 'retired';
}

sub observation {
    my ($self) = @_; _owner($self);
    _error('unexpected observation arguments') unless @_ == 1;
    return {map { $_ => $self->{$_} } qw(phase original_deadline command_pid birth_sec birth_usec
        command_reaped command_status command_authority joined released release_attempted release_uncertain retired failure)};
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
