package FSM::Support::ProcessSupervisor::Reservation;

use strict;
use warnings;

use Errno qw(EAGAIN EINTR ESRCH EWOULDBLOCK);
use Fcntl qw(FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL O_NONBLOCK);
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGCHLD SA_NOCLDWAIT WNOHANG _exit setpgid);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime gettimeofday);
use FSM::Support::ProcessSupervisor ();
use FSM::Support::ProcessSupervisor::Wire ();

# Private reservation lifetime only: no executable, caller routing or result
# facade. The coordinator retains a prepared object and reserves its job and
# both child slots BEFORE start. It supplies every other run-private handle.
# A live reservation is never harvested until the owner retires group signals.
my $LIMIT = FSM::Support::ProcessSupervisor::Wire::limits();
my ($TERM_GRACE, $KILL_GRACE) = FSM::Support::ProcessSupervisor::_termination_graces();

sub _error { die "private process reservation: $_[0]\n" }
sub _now { return clock_gettime(CLOCK_MONOTONIC) }
sub _minimum { return $_[0] < $_[1] ? $_[0] : $_[1] }
sub _fork { return fork() }
sub _wait { return waitpid($_[0], WNOHANG) }
sub _signal { return kill($_[0], $_[1]) }
sub _group { return getpgrp($_[0]) }
sub _set_group { return setpgid(0, $_[0]) }
sub _mask { return POSIX::sigprocmask(@_) }
sub _pipe { return pipe(${$_[0]}, ${$_[1]}) }
sub _write { return syswrite($_[0], $_[1], 1) }

sub _time {
    my ($value) = @_;
    _error('expected a finite monotonic deadline')
        unless defined($value) && !ref($value)
            && "$value" =~ /\A[0-9]+(?:\.[0-9]+)?\z/
            && $value > 0 && $value < 1e15;
    return 0 + $value;
}

sub _owner {
    my ($self) = @_;
    _error('invalid reservation handle') unless ref($self) eq __PACKAGE__;
    _error('inherited reservation cannot control its creator')
        unless $self->{owner_pid} == $$;
}

sub _failure {
    my ($self, $message) = @_;
    $self->{failure} //= $message;
    $self->{phase} = 'failed' unless $self->{retired};
    return;
}

sub _close {
    my ($self, @names) = @_;
    for my $name (@names) {
        my $fh = delete $self->{$name};
        next unless defined $fh;
        $self->_failure('reservation descriptor close failed') unless close $fh;
    }
}

sub _seal {
    my ($fh, $nonblocking) = @_;
    my $flags = fcntl($fh, F_GETFD, 0);
    _error('cannot seal reservation descriptor') unless defined($flags)
        && fcntl($fh, F_SETFD, $flags | FD_CLOEXEC);
    return unless $nonblocking;
    $flags = fcntl($fh, F_GETFL, 0);
    _error('cannot make reservation descriptor nonblocking') unless defined($flags)
        && fcntl($fh, F_SETFL, $flags | O_NONBLOCK);
}

sub _inventory {
    my ($handles, $cap) = @_;
    _error('expected a bounded descriptor inventory') unless ref($handles) eq 'ARRAY'
        && @$handles <= $cap;
    my %seen;
    for my $fh (@$handles) {
        my $fd = eval { fileno($fh) };
        _error('descriptor inventory contains a closed, standard or duplicate handle')
            unless defined($fd) && $fd >= 3 && !$seen{$fd}++;
    }
    return [@$handles];
}

sub _check_allocation_deadline {
    my ($deadline, $check) = @_;
    _error('execution deadline expired before allocation') if _now() >= $deadline;
    $check->() if defined $check;
}

# Shared preparation transaction only; never wrap a fork in this helper.
# The operation publishes its retained state before restoration can run a
# pending handler. Both operation failure and restoration are consumed.
sub _masked_preparation {
    my ($operation) = @_;
    return _masked_operation(sub { $operation->() }, \&_mask,
        'cannot mask preparation signals', 'fatal preparation signal-mask restoration failure');
}

# Fork transactions receive the caller's original mask explicitly. A command
# child must retain that mask for exec; a preparation mask is never a substitute.
sub _masked_fork {
    my ($operation, $mask, $role, $outcome) = @_;
    return _masked_operation($operation, $mask,
        "cannot mask $role fork signals", "fatal $role signal-mask restoration failure", $outcome);
}
sub _masked_operation {
    my ($operation, $mask, $block_error, $restore_error, $outcome) = @_;
    my $all = POSIX::SigSet->new; $all->fillset;
    my $old = POSIX::SigSet->new;
    defined($mask->(SIG_BLOCK, $all, $old)) or _error($block_error);
    my $ok = eval { $operation->($old); 1 };
    my $error = $@;
    my ($restored, $interrupted);
    { local $@; eval { $restored = defined $mask->(SIG_SETMASK, $old); 1 } or $interrupted = $@; }
    $outcome->{restoration_failed} = !$restored && !$interrupted ? 1 : 0 if $outcome;
    unless ($ok) {
        $error .= $interrupted if $interrupted;
        $error .= "private process reservation: $restore_error\n"
            unless $restored || $interrupted;
        die $error;
    }
    die $interrupted if $interrupted;
    _error($restore_error) unless $restored;
    return;
}

sub prepare_record {
    my (%args) = @_;
    _error('expected deadline and close_handles') unless keys(%args) == 2
        && exists $args{deadline} && exists $args{close_handles};
    my $deadline = _time($args{deadline});
    my $now = _now();
    _error('execution deadline is expired or exceeds the private wall domain')
        unless $deadline > $now && $deadline <= $now + 4_294_967_295;
    my $handles = _inventory($args{close_handles}, $LIMIT->{descriptors} - 4);
    return bless {
        owner_pid => $$, phase => 'unallocated', deadline => $deadline,
        close_handles => [@$handles], reaped => 0, retired => 0,
        group_ready => 0, moved => 0, positive_authority => 0,
    }, __PACKAGE__;
}

sub allocate {
    my ($self, $additional, $check) = @_; _owner($self);
    _error('allocation requires an unallocated retained reservation and close inventory')
        unless (@_ == 2 || (@_ == 3 && ref($check) eq 'CODE'))
            && $self->{phase} eq 'unallocated' && !$self->{retired};
    my $ok = eval {
        _masked_preparation(sub {
            $self->{phase} = 'allocating';
            my $allocated = eval {
                $additional = _inventory($additional, $LIMIT->{descriptors} - 4);
                $self->{close_handles} = _inventory(
                    [@{$self->{close_handles}}, @$additional], $LIMIT->{descriptors} - 4);
                _check_allocation_deadline($self->{deadline}, $check);
                _pipe(\$self->{child_read}, \$self->{write})
                    or _error('cannot create reservation instruction pipe');
                _check_allocation_deadline($self->{deadline}, $check);
                _pipe(\$self->{read}, \$self->{child_write})
                    or _error('cannot create reservation acknowledgment pipe');
                _seal($self->{$_}, 0) for qw(child_read child_write);
                _seal($self->{$_}, 1) for qw(read write);
                $self->{phase} = 'prepared';
                1;
            };
            unless ($allocated) {
                my $error = $@; $self->_failure($error);
                $self->_close(qw(child_read child_write read write));
                die $error;
            }
        });
        1;
    };
    unless ($ok) {
        my $error = $@;
        $self->_failure($error);
        die $error;
    }
    return;
}

sub prepare {
    my $self = prepare_record(@_);
    my $ok = eval { $self->allocate([]); 1 };
    unless ($ok) {
        my $error = $@;
        $self->retire(_minimum($self->{deadline}, _now()));
        die $error;
    }
    return $self;
}

sub start {
    my ($self, $check) = @_; _owner($self);
    _error('unexpected start arguments or state')
        unless (@_ == 1 || (@_ == 2 && ref($check) eq 'CODE'))
        && $self->{phase} eq 'prepared' && !$self->{retired};
    if (_now() >= $self->{deadline}) {
        $self->_failure('execution deadline expired before reservation fork');
        return;
    }
    my $action = POSIX::SigAction->new;
    _error('default child-reaping disposition is required')
        unless defined(POSIX::sigaction(SIGCHLD, undef, $action))
            && defined($action->handler) && !ref($action->handler)
            && $action->handler eq 'DEFAULT' && !($action->flags & SA_NOCLDWAIT);
    $self->{caller_group} = _group(0);
    _error('cannot establish caller process group')
        unless defined($self->{caller_group}) && $self->{caller_group} > 0;
    my $outcome = {};
    my $ok = eval {
        _masked_fork(sub {
            my $admitted = eval {
                $self->{close_handles} = _inventory($check->('reservation'), $LIMIT->{descriptors} - 4)
                    if defined $check;
                _inventory([@{$self->handles}, @{$self->{close_handles}}], $LIMIT->{descriptors});
                _error('execution deadline expired before reservation fork') if _now() >= $self->{deadline};
                1;
            };
            unless ($admitted) {
                my $error = $@; $self->_failure(FSM::Support::ProcessSupervisor::_sanitize_control($error)); die $error;
            }
            # No callback or I/O separates fork from retained PID publication.
            @{$self}{qw(birth_sec birth_usec)} = gettimeofday();
            my $pid = _fork();
            if (defined($pid) && $pid == 0) { _child($self); _exit(126); }
            if (defined $pid) {
                $self->{pid} = $pid;
                $self->{positive_authority} = 1;
                $self->{phase} = 'group_pending';
                $self->{handshake_deadline} = _minimum($self->{deadline}, _now() + $LIMIT->{handshake_seconds});
            }
            else { $self->_failure('cannot fork reservation child'); }
            $self->_close(qw(child_read child_write));
            delete $self->{close_handles};
        }, \&_mask, 'reservation', $outcome);
        1;
    };
    unless ($ok) {
        my $error = $@;
        # An interrupted successful return retains a usable reservation
        # handshake for cleanup. The composing job keeps the interruption as
        # its first cause; marking this native protocol failed would prevent
        # it from acknowledging group creation/departure during cancellation.
        $self->_failure(FSM::Support::ProcessSupervisor::_sanitize_control($error))
            unless $self->{pid} && !$outcome->{restoration_failed};
        die $error;
    }
    return;
}

sub _child_byte {
    my ($fh, $byte) = @_;
    while (1) {
        my $n = syswrite($fh, $byte, 1);
        next if !defined($n) && $! == EINTR;
        _exit(126) unless defined($n) && $n == 1;
        return;
    }
}

sub _child {
    my ($self) = @_;
    # A reservation executes no caller program and retains no client context.
    # It must not run inherited Perl callbacks, END blocks or alarm handlers.
    $SIG{$_} = 'DEFAULT' for grep { !/^__/ } keys %SIG;
    alarm 0;
    %ENV = ();
    for my $fh ($self->{read}, $self->{write}, @{$self->{close_handles}}) {
        _exit(126) unless close $fh;
    }
    close STDIN; close STDOUT; close STDERR;
    _exit(126) unless defined _mask(SIG_SETMASK, POSIX::SigSet->new);
    my $set = _set_group(0);
    _exit(126) unless defined($set) && $set == 0 && _group(0) == $$;
    _child_byte($self->{child_write}, 'G');
    my $moved = 0;
    while (1) {
        my $n = sysread($self->{child_read}, my $byte, 1);
        next if !defined($n) && $! == EINTR;
        _exit(125) unless defined($n) && $n == 1;
        _exit(0) if $byte eq 'X';
        _exit(126) unless $byte eq 'M' && !$moved;
        $set = _set_group($self->{caller_group});
        _exit(126) unless defined($set) && $set == 0
            && _group(0) == $self->{caller_group};
        $moved = 1;
        _child_byte($self->{child_write}, 'M');
    }
}

sub depart {
    my ($self) = @_; _owner($self);
    _error('departure requires acknowledged group ownership') unless @_ == 1
        && $self->{phase} eq 'group_ready' && !$self->{retired};
    $self->{phase} = 'move_pending';
    $self->{outgoing} = 'M';
    $self->{handshake_deadline} = _minimum($self->{deadline}, _now() + $LIMIT->{handshake_seconds});
    return;
}

sub _write_pending {
    my ($self) = @_;
    return unless defined $self->{outgoing};
    local $SIG{PIPE} = 'IGNORE';
    my $n = _write($self->{write}, $self->{outgoing});
    return if !defined($n) && ($! == EAGAIN || $! == EWOULDBLOCK || $! == EINTR);
    if (!defined($n) || $n != 1) { $self->_failure('reservation instruction write failed'); }
    delete $self->{outgoing};
}

sub advance {
    my ($self) = @_; _owner($self);
    _error('unexpected advance arguments') unless @_ == 1;
    return if $self->{phase} eq 'unallocated' || $self->{phase} eq 'finished' || $self->{phase} eq 'prepared';
    if ($self->{retired}) { $self->_advance_retirement; return; }
    return if $self->{failure};
    my $pending = $self->{phase} eq 'group_pending' || $self->{phase} eq 'move_pending';
    if (_now() >= ($pending ? $self->{handshake_deadline} : $self->{deadline})) {
        $self->_failure($pending ? 'reservation handshake deadline expired' : 'reservation execution deadline expired');
        return;
    }
    $self->_write_pending;
    return if $self->{failure};
    # One bounded read, even while ready: premature EOF is a failure, never
    # permission to harvest the reservation and reuse its numeric identity.
    my $n = sysread($self->{read}, my $bytes, 2);
    return if !defined($n) && ($! == EAGAIN || $! == EWOULDBLOCK || $! == EINTR);
    if (!defined($n) || $n != 1) {
        $self->_failure(defined($n) && !$n ? 'reservation exited before retirement' : 'invalid reservation acknowledgment');
        return;
    }
    if ($self->{phase} eq 'group_pending' && $bytes eq 'G') {
        $self->{group_ready} = 1;
        $self->{phase} = 'group_ready';
    }
    elsif ($self->{phase} eq 'move_pending' && !defined($self->{outgoing}) && $bytes eq 'M') {
        $self->{moved} = 1;
        $self->{phase} = 'moved';
    }
    else { $self->_failure('out-of-order reservation acknowledgment'); }
    return;
}

sub group_absent {
    my ($self) = @_; _owner($self);
    _error('group inspection requires acknowledged departure and live reservation identity')
        unless @_ == 1 && $self->{group_ready} && $self->{moved} && !$self->{retired};
    local $! = 0;
    return 0 if _signal(0, -$self->{pid});
    return 1 if $! == ESRCH;
    $self->_failure('reserved group absence is uncertain');
    return undef;
}

sub signal_group {
    my ($self, $signal) = @_; _owner($self);
    _error('group signal requires acknowledged departure and live reservation identity')
        unless @_ == 2 && defined($signal) && ($signal eq 'TERM' || $signal eq 'KILL')
            && $self->{group_ready} && $self->{moved} && !$self->{retired};
    local $! = 0;
    my $sent = _signal($signal, -$self->{pid});
    $self->_failure('reserved group signal failed') unless $sent || $! == ESRCH;
    return $sent ? 1 : 0;
}

sub retire {
    my ($self, $deadline) = @_; _owner($self);
    _error('retirement requires one remaining closure deadline') unless @_ == 2;
    $deadline = _time($deadline);
    _error('retirement cannot extend the existing cleanup envelope')
        if $deadline > _minimum($self->{deadline}, _now()) + $TERM_GRACE + $KILL_GRACE;
    if ($self->{retired}) {
        if ($self->{phase} ne 'finished' && $deadline < $self->{closure_deadline}) {
            _masked_preparation(sub {
                return if $self->{phase} eq 'finished' || $deadline >= $self->{closure_deadline};
                $self->{closure_deadline} = $deadline;
                $self->{kill_at} = _minimum($self->{kill_at}, $deadline - $KILL_GRACE);
            });
        }
        return;
    }
    # This transition revokes all group operations before any release, kill or
    # wait. The coordinator must finish its last owned group signal first.
    $self->{retired} = 1;
    $self->{phase} = 'retiring';
    $self->{closure_deadline} = $deadline;
    $self->{kill_at} = _minimum(_now() + $TERM_GRACE, $deadline - $KILL_GRACE);
    $self->_close(qw(child_read child_write));
    if (!$self->{pid}) { $self->_finish; return; }
    $self->_failure('reservation retired before acknowledged departure') unless $self->{moved};
    $self->{outgoing} = 'X';
    return;
}

sub _advance_retirement {
    my ($self) = @_;
    my $pid = $self->{pid};
    my $waited = _wait($pid);
    if ($waited == $pid) {
        $self->{wait_status} = $?;
        $self->{reaped} = 1;
        $self->{positive_authority} = 0;
        $self->_failure('reservation child exited unsuccessfully') if $? != 0;
        $self->_finish;
        return;
    }
    if ($waited == -1 && $! != EINTR) {
        $self->{positive_authority} = 0;
        $self->_failure('reservation wait status is unknown');
        $self->_finish;
        return;
    }
    $self->_write_pending;
    my $now = _now();
    if ($self->{positive_authority} && !$self->{kill_attempted} && $now >= $self->{kill_at}) {
        local $! = 0;
        $self->{kill_attempted} = 1;
        $self->{kill_sent} = _signal('KILL', $pid) ? 1 : 0;
        $self->_failure('reservation required forced termination');
        # Even ESRCH does not substitute for the exact wait status.
    }
    if ($now >= $self->{closure_deadline}) {
        $self->{positive_authority} = 0;
        $self->_failure('reservation cleanup deadline expired before reaping');
        $self->_finish;
    }
    return;
}

sub _finish {
    my ($self) = @_;
    $self->_close(qw(read write child_read child_write));
    delete $self->{outgoing};
    delete $self->{close_handles};
    $self->{phase} = 'finished';
}

sub observation {
    my ($self) = @_; _owner($self);
    _error('unexpected observation arguments') unless @_ == 1;
    return {map { $_ => $self->{$_} } qw(phase pid birth_sec birth_usec
        caller_group group_ready moved retired reaped wait_status failure kill_sent)};
}

sub handles {
    my ($self) = @_; _owner($self);
    _error('unexpected handles arguments') unless @_ == 1;
    return [map { $self->{$_} } grep { defined $self->{$_} } qw(read write child_read child_write)];
}

1;
