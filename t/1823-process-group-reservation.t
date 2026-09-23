#!/usr/bin/env perl
use strict;
use warnings;

use Errno qw(EAGAIN ECHILD EINTR EIO EPERM EPIPE ESRCH);
use Fcntl qw(FD_CLOEXEC F_GETFD F_GETFL F_SETFL O_NONBLOCK);
use IO::Select;
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGUSR1 WNOHANG _exit setpgid);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::Reservation ();

my $class = 'FSM::Support::ProcessSupervisor::Reservation';
my $owner = $$;
my (@reservations, @members);
sub now { return clock_gettime(CLOCK_MONOTONIC) }
sub error { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@; }
sub prepare {
    my $r = FSM::Support::ProcessSupervisor::Reservation::prepare(
        deadline => now() + 10, close_handles => [@_]);
    push @reservations, $r;
    return $r;
}
sub until_state {
    my ($r, $state) = @_;
    my $end = now() + 3;
    while (now() < $end) {
        $r->advance;
        return $r->observation if $r->observation->{phase} eq $state;
        die 'unexpected reservation failure: ' . $r->observation->{failure}
            if $state ne 'failed' && $state ne 'finished' && $r->observation->{failure};
        sleep(0.001);
    }
    die "reservation observer expired waiting for $state\n";
}
sub close_reservation {
    my ($r) = @_;
    $r->retire(now() + 2.5);
    return until_state($r, 'finished');
}
sub member {
    my ($r) = @_;
    pipe(my $ready_read, my $ready_write) or die $!;
    pipe(my $release_read, my $release_write) or die $!;
    my @inherited = @{$r->handles};
    my $group = $r->observation->{pid};
    my $pid = fork(); die 'member fork failed' unless defined $pid;
    if (!$pid) {
        $SIG{ALRM} = $SIG{TERM} = 'DEFAULT';
        alarm 6;
        close $_ for (@inherited, $ready_read, $release_write);
        close STDIN; close STDOUT; close STDERR;
        my $ok = setpgid(0, $group);
        _exit(91) unless defined($ok) && $ok == 0 && getpgrp(0) == $group;
        _exit(92) unless syswrite($ready_write, 'J', 1) == 1;
        close $ready_write;
        my $n = sysread($release_read, my $byte, 1);
        _exit(defined($n) && $n == 1 && $byte eq 'X' ? 23 : 93);
    }
    my $m = {pid => $pid, reaped => 0, release => $release_write};
    push @members, $m;
    close $ready_write; close $release_read;
    my $ack;
    die 'member did not join' unless IO::Select->new($ready_read)->can_read(2)
        && sysread($ready_read, $ack, 1) == 1 && $ack eq 'J';
    close $ready_read;
    return $m;
}
sub reap_member {
    my ($m) = @_;
    my $end = now() + 2;
    while (now() < $end) {
        my $w = waitpid($m->{pid}, WNOHANG);
        if ($w == $m->{pid}) {
            $m->{reaped} = 1;
            my $status = $?;
            close delete $m->{release};
            return $status;
        }
        die 'member wait status lost' if $w == -1 && $! != EINTR;
        sleep(0.001);
    }
    die 'member reap observer expired';
}

# Rescue only exact, still-unharvested children of this test. The synthetic
# retirement controls below never enter these lists or use a real signal.
END {
    local $?;
    if ($$ == $owner) {
        alarm 0;
        for my $m (@members) {
            next if $m->{reaped};
            kill 'KILL', $m->{pid};
            eval { reap_member($m) };
        }
        for my $r (@reservations) {
            my $o = $r->observation;
            next unless $o->{pid} && !$o->{reaped} && $r->{positive_authority};
            kill 'KILL', $o->{pid};
            my $end = now() + 2;
            while (now() < $end) {
                my $w = waitpid($o->{pid}, WNOHANG);
                last if $w == $o->{pid} || $w == -1;
                sleep(0.001);
            }
        }
    }
}
local $SIG{ALRM} = sub { die "reservation test deadline\n" };
alarm 60;

subtest 'preparation is process-free and bounded' => sub {
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { die 'unexpected fork' };
    my $r = prepare();
    is($r->observation->{phase}, 'prepared', 'no child exists before explicit start');
    my @handles = @{$r->handles};
    is(scalar @handles, 4, 'the two pipes have an explicit descriptor cost');
    ok(!grep(!(fcntl($_, F_GETFD, 0) & FD_CLOEXEC), @handles), 'all private descriptors are close-on-exec');
    is(scalar(grep { fcntl($_, F_GETFL, 0) & O_NONBLOCK } @handles), 2, 'both parent endpoints are nonblocking');
    like(error(sub { $r->depart }), qr/acknowledged group ownership/, 'no departure before ownership');
    like(error(sub { $r->signal_group('KILL') }), qr/live reservation identity/, 'no inferred signal target before fork');
    like(error(sub { $r->retire(now() + 10) }), qr/cleanup envelope/, 'retirement cannot enlarge the cleanup wall');
    close_reservation($r);
    is_deeply($r->handles, [], 'unused prepared reservation closes every descriptor');
    ok(!grep(defined(fileno($_)), @handles), 'independent handles observe actual closure');
    like(error(sub { FSM::Support::ProcessSupervisor::Reservation::prepare(
        deadline => now() + 2, close_handles => [(undef) x 125]) }), qr/bounded descriptor inventory/, 'descriptor boundary plus one is rejected');
    my @limit_handles;
    for (1 .. 62) {
        pipe(my $read, my $write) or die 'descriptor boundary fixture failed';
        push @limit_handles, $read, $write;
    }
    my $at_limit = prepare(@limit_handles);
    is(scalar @{$at_limit->handles} + @limit_handles, 128, 'inclusive descriptor boundary is accepted without forking');
    close_reservation($at_limit);
    close $_ or die 'boundary fixture close failed' for @limit_handles;
};

subtest 'kernel membership, wait truth and caller isolation' => sub {
    my $caller_group = getpgrp(0);
    my $terms = 0;
    local $SIG{TERM} = sub { ++$terms };
    local $ENV{FSMGEN_PROCESS_COORDINATOR_CONTEXT} = 'fixture-only-authority';
    my $native_byte = $class->can('_child_byte');
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::Reservation::_child_byte = sub {
        _exit(94) if keys %ENV;
        return $native_byte->(@_);
    };
    for my $mode ('normal', 'term') {
        pipe(my $sentinel_read, my $sentinel_write) or die $!;
        my $r = prepare($sentinel_read, $sentinel_write);
        my @owned = @{$r->handles};
        $r->start;
        close $sentinel_write;
        my $o = until_state($r, 'group_ready');
        is($ENV{FSMGEN_PROCESS_COORDINATOR_CONTEXT}, 'fixture-only-authority',
            "$mode child acknowledgment requires cleared environment while caller authority is unchanged");
        my $pid = $o->{pid};
        is(getpgrp($pid), $pid, "$mode independent kernel query confirms the reserved group");
        ok(IO::Select->new($sentinel_read)->can_read(1), "$mode unrelated inherited writer really closed");
        is(sysread($sentinel_read, my $unused, 1), 0, "$mode observes EOF rather than a retained sibling descriptor");
        close $sentinel_read;
        like(error(sub { $r->group_absent }), qr/acknowledged departure/, "$mode absence cannot be certified before departure");
        my $m = member($r);
        is(getpgrp($m->{pid}), $pid, "$mode independent command joined the actual group");
        $r->depart;
        until_state($r, 'moved');
        is(getpgrp($pid), $caller_group, "$mode actual reservation membership returned to caller group");
        is($r->group_absent, 0, "$mode live independent member prevents false absence");
        if ($mode eq 'normal') { syswrite($m->{release}, 'X', 1) == 1 or die 'release failed'; }
        else { ok($r->signal_group('TERM'), 'TERM targets the reserved command group'); }
        my $status = reap_member($m);
        is($status, $mode eq 'normal' ? 23 << 8 : 15, "$mode preserves independent command wait truth");
        is($r->group_absent, 1, "$mode actual group absence precedes identity release");
        ok(kill(0, $pid), "$mode reservation remains alive through the last group inspection");
        my $closed = close_reservation($r);
        ok($closed->{reaped}, "$mode exact reservation was reaped");
        is($closed->{wait_status}, 0, "$mode normal reservation release is exit zero");
        is($closed->{failure}, undef, "$mode reservation closure has no failure");
        local $! = 0;
        ok(!kill(0, $pid) && $! == ESRCH, "$mode independent PID probe proves absence after return");
        is(waitpid($pid, WNOHANG), -1, "$mode no unconsumed direct-child wait remains");
        ok(!grep(defined(fileno($_)), @owned), "$mode all captured handles are closed");
        like(error(sub { $r->signal_group('KILL') }), qr/live reservation identity/, "$mode retired group cannot be signalled");
        like(error(sub { $r->group_absent }), qr/live reservation identity/, "$mode retired numeric group cannot be probed");
        is(getpgrp(0), $caller_group, "$mode caller membership is unchanged");
        is($terms, 0, "$mode caller group received no TERM");
    }
};

subtest 'fork publication precedes exact signal-mask restoration' => sub {
    my $old = POSIX::SigSet->new;
    POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'mask setup failed';
    my $r = prepare();
    my $native = $class->can('_mask');
    my $published = 0;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
            $published = defined($r->{pid}) && $r->{positive_authority}
                if $$ == $owner && $_[0] == SIG_SETMASK;
            return $native->(@_);
        };
        $r->start;
    }
    my $current = POSIX::SigSet->new;
    POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $current) or die 'mask read failed';
    POSIX::sigprocmask(SIG_SETMASK, $old) or die 'test mask restoration failed';
    ok($published, 'owner record contains the exact fork before signals can run');
    ok($current->ismember(SIGUSR1), 'the original blocked signal remains blocked');
    until_state($r, 'group_ready'); $r->depart; until_state($r, 'moved');
    close_reservation($r);
};

subtest 'real missing acknowledgment and stuck release consume finite walls' => sub {
    my $native = $class->can('_child_byte');
    for my $mode ('silent', 'stuck') {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Reservation::_child_byte = sub {
            return if $mode eq 'silent';
            $native->(@_);
            if ($_[1] eq 'M') {
                # A real, bounded counterexample to assuming that release
                # delivery means child termination. The parent must harvest.
                $SIG{ALRM} = 'DEFAULT'; alarm 6;
                while (1) { sleep(0.05); }
            }
        };
        my $r = prepare(); $r->start;
        if ($mode eq 'silent') {
            my $o = until_state($r, 'failed');
            like($o->{failure}, qr/handshake deadline/, 'real silent handoff expires');
            ok(now() >= $r->{handshake_deadline}, 'deadline is observed against the independent caller clock');
        }
        else { until_state($r, 'group_ready'); $r->depart; until_state($r, 'moved'); }
        my $o = close_reservation($r);
        ok($o->{reaped}, "$mode exact child is harvested within cleanup");
        is($o->{wait_status}, $mode eq 'silent' ? 0 : 9, "$mode actual wait distinguishes normal release and KILL");
        like($o->{failure}, $mode eq 'silent' ? qr/handshake deadline/ : qr/forced termination/, "$mode original failure survives cleanup");
    }
};

subtest 'unexpected death retains identity and first failure until retirement' => sub {
    my $r = prepare(); $r->start; until_state($r, 'group_ready');
    my $pid = $r->observation->{pid};
    kill 'KILL', $pid;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { die 'premature reservation reap' };
        my $o = until_state($r, 'failed');
        like($o->{failure}, qr/exited before retirement/, 'EOF is a live ownership failure');
        ok(!$o->{reaped} && !$o->{retired}, 'dead reservation remains unharvested');
        ok(kill(0, $pid), 'independent kernel probe observes the unreaped identity');
    }
    my $o = close_reservation($r);
    ok($o->{reaped}, 'explicit retirement permits exact reaping');
    is($o->{wait_status} & 127, 9, 'actual KILL status is retained');
    like($o->{failure}, qr/exited before retirement/, 'later incomplete-departure facts preserve the first failure');
};

for my $fault ('create', 'depart', 'ack') {
    subtest "real child rejects $fault handoff failure" => sub {
        my $set = $class->can('_set_group'); my $byte = $class->can('_child_byte');
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Reservation::_set_group = sub {
            if (($fault eq 'create' && !$_[0]) || ($fault eq 'depart' && $_[0])) { $! = EPERM; return undef; }
            return $set->(@_);
        };
        local *FSM::Support::ProcessSupervisor::Reservation::_child_byte = sub {
            return $byte->($_[0], $fault eq 'ack' ? '?' : $_[1]);
        };
        my $r = prepare(); $r->start;
        if ($fault eq 'depart') { until_state($r, 'group_ready'); $r->depart; }
        my $failed = until_state($r, 'failed');
        ok(!$failed->{moved}, 'no false departure acknowledgment');
        my $closed = close_reservation($r);
        ok($closed->{reaped}, 'failed partial start has an exact consumed wait');
        is($closed->{failure}, $failed->{failure}, 'cleanup preserves the original failure');
        is($closed->{wait_status}, $fault eq 'ack' ? 0 : 126 << 8, 'child-side failure truth is not synthesized');
    };
}

subtest 'partial allocation, fork and instruction failures close honestly' => sub {
    my $native_pipe = $class->can('_pipe'); my $calls = 0; my @first;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
            if (++$calls == 2) { $! = EIO; return 0; }
            my $ok = $native_pipe->(@_); @first = (${$_[0]}, ${$_[1]}); return $ok;
        };
        like(error(sub { prepare() }), qr/acknowledgment pipe/, 'second-pipe allocation failure rejects before fork');
    }
    ok(!grep(defined(fileno($_)), @first), 'actual first-pipe handles close after partial preparation');
    {
        my $r = prepare();
        local $SIG{CHLD} = 'IGNORE';
        like(error(sub { $r->start }), qr/default child-reaping disposition/, 'auto-reaping caller is rejected before fork');
        is($r->observation->{pid}, undef, 'unqualified child-reaping policy starts no child');
        close_reservation($r);
    }
    {
        my $r = prepare(); my $mask = $class->can('_mask');
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
            my $result = $mask->(@_);
            return undef if $$ == $owner && $_[0] == SIG_SETMASK;
            return $result;
        };
        like(error(sub { $r->start }), qr/fatal.*mask restoration/, 'mask restoration failure is fatal with the child still recorded');
        my $o = close_reservation($r);
        ok($o->{reaped}, 'recorded child can close after the failed return');
        like($o->{failure}, qr/fatal.*mask restoration/, 'cleanup cannot replace the original fatal restoration failure');
    }
    {
        my $r = prepare();
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $! = EAGAIN; return undef; };
        $r->start;
        is($r->observation->{pid}, undef, 'failed fork invents no child identity');
        my $o = close_reservation($r);
        like($o->{failure}, qr/cannot fork/, 'failed fork remains failed');
        is_deeply($r->handles, [], 'fork failure closes all pipes');
    }
    {
        my $r = prepare(); $r->start; until_state($r, 'group_ready'); $r->depart;
        {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::Reservation::_write = sub { $! = EPIPE; return undef; };
            $r->advance;
        }
        my $o = close_reservation($r);
        like($o->{failure}, qr/instruction write failed/, 'lost instruction retains original failure');
        ok($o->{reaped}, 'lost move instruction still closes its exact child');
    }
};

subtest 'deadline, retirement and unknown status controls use no real targets' => sub {
    no warnings 'redefine';
    my @signals;
    local *FSM::Support::ProcessSupervisor::Reservation::_signal = sub { push @signals, [@_]; return 1; };
    local *FSM::Support::ProcessSupervisor::Reservation::_now = sub { 10 };
    my $r = bless {owner_pid => $$, phase => 'group_pending', pid => 321,
        deadline => 20, handshake_deadline => 9, retired => 0, reaped => 0}, $class;
    $r->advance;
    like($r->observation->{failure}, qr/handshake deadline/, 'missed handshake cannot renew its deadline');
    is_deeply(\@signals, [], 'unacknowledged group infers no signal authority');
    like(error(sub { $r->signal_group('KILL') }), qr/acknowledged departure/, 'unacknowledged group signal rejects');
    for my $kind ('unknown', 'unreapable') {
        my $model = bless {owner_pid => $$, phase => 'retiring', pid => 654,
            deadline => 8, closure_deadline => 10, kill_at => 8, retired => 1,
            reaped => 0, positive_authority => 1}, $class;
        local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub {
            if ($kind eq 'unknown') { $! = ECHILD; return -1; }
            return 0;
        };
        @signals = ();
        $model->advance;
        my $o = $model->observation;
        ok(!$o->{reaped} && !defined($o->{wait_status}), "$kind never invents wait truth");
        like($o->{failure}, $kind eq 'unknown' ? qr/wait status is unknown/ : qr/forced termination/, "$kind remains explicitly failed");
        is_deeply(\@signals, $kind eq 'unknown' ? [] : [['KILL', 654]], "$kind signals only a still-owned positive child");
        $model->advance;
        is(scalar @signals, $kind eq 'unknown' ? 0 : 1, "$kind terminal state cannot signal again");
        like(error(sub { $model->group_absent }), qr/live reservation identity/, "$kind retired group is never probed");
    }
    for my $errno (ESRCH, EPERM, EIO, 0) {
        my $model = bless {owner_pid => $$, phase => 'moved', pid => 987,
            group_ready => 1, moved => 1, retired => 0}, $class;
        local *FSM::Support::ProcessSupervisor::Reservation::_signal = sub { $! = $errno; return 0; };
        my $absent = $model->group_absent;
        if ($errno == ESRCH) { is($absent, 1, 'only ESRCH proves absence'); }
        else { ok(!defined($absent) && $model->observation->{failure}, "errno $errno preserves uncertainty"); }
    }
    my $foreign = bless {owner_pid => $$ + 1}, $class;
    like(error(sub { $foreign->advance }), qr/inherited reservation/, 'forked handle cannot act for its parent');
};

alarm 0;
done_testing();
