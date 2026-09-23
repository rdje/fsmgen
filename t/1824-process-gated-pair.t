#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(getcwd);
use Errno qw(EAGAIN ECHILD EINTR EIO EPERM EPIPE ESRCH);
use Fcntl qw(FD_CLOEXEC F_GETFD);
use IO::Select;
use JSON::PP ();
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGUSR1 WNOHANG _exit);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::GatedPair ();

my $class = 'FSM::Support::ProcessSupervisor::GatedPair';
my $reservation_class = 'FSM::Support::ProcessSupervisor::Reservation';
my $owner = $$;
my @pairs;
sub now { return clock_gettime(CLOCK_MONOTONIC) }
sub error { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@; }
sub snapshot {
    my (@argv) = @_;
    return FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [@argv], cwd => '.', schema => 'private.gated.fixture.v1',
        stage => 'gate-control', containment => 'fixture-group',
        bounds => {timeout_seconds => 10, capture_limit_bytes => 4096},
    }, sprintf('%.0f', now() * 1e9));
}
sub prepare {
    my ($snapshot, @handles) = @_;
    my $p = FSM::Support::ProcessSupervisor::GatedPair::prepare(
        snapshot => $snapshot, deadline => now() + 10, close_handles => [@handles]);
    push @pairs, $p;
    return $p;
}
sub until_pair {
    my ($p, $phase) = @_;
    my $end = now() + 3;
    while (now() < $end) {
        $p->advance;
        my $o = $p->observation;
        return $o if $o->{phase} eq $phase;
        die "pair failed: $o->{failure}\n" if $o->{failure} && $phase ne 'failed';
        sleep(0.001);
    }
    die "pair observer expired waiting for $phase\n";
}
sub reap_command {
    my ($p) = @_;
    my $end = now() + 2;
    while ($p->{command_authority} && now() < $end) { $p->poll_command; sleep(0.001); }
    die 'command reap observer expired' if $p->{command_authority};
    return $p->observation;
}
sub drain {
    my ($fh) = @_;
    my $text = '';
    my $end = now() + 2;
    while (now() < $end) {
        next unless IO::Select->new($fh)->can_read(0.01);
        my $n = sysread($fh, my $chunk, 4096);
        next if !defined($n) && ($! == EAGAIN || $! == EINTR);
        die 'fixture capture read failed' unless defined $n;
        return $text unless $n;
        $text .= $chunk;
        die 'fixture capture overflow' if length($text) > 8192;
    }
    die 'fixture capture EOF deadline';
}
sub close_pair {
    my ($p) = @_;
    my $r = $p->reservation;
    $p->cancel unless $p->{retired};
    $p->signal_command('KILL') if $p->{command_authority};
    reap_command($p);
    my $end = now() + 2.5;
    # This independent test driver owns partial-start cleanup. The following
    # production slice integrates the same operations with capture/deadlines.
    while ($r->{pid} && !$r->{moved} && !$r->{failure} && now() < $end) {
        $p->advance; sleep(0.001);
    }
    if ($r->{moved}) {
        die 'unexpected live command group' unless $r->group_absent;
    }
    # Keep the execution witness before retiring the readers. If no command
    # was forked, the parent still owns the unused writer ends.
    $p->_close(qw(child_stdout child_stderr child_control));
    $p->{test_capture} = {map { $_ => drain($p->streams->{$_}) } keys %{$p->streams}};
    $p->retire(now() + 2.5);
    $end = now() + 3;
    while ($r->observation->{phase} ne 'finished' && now() < $end) { $r->advance; sleep(0.001); }
    die 'reservation closure observer expired' unless $r->observation->{phase} eq 'finished';
    return $r->observation;
}

# Rescue only recorded, unharvested direct children. No negative process IDs
# are used here, and models below never enter this inventory.
END {
    local $?;
    if ($$ == $owner) {
        alarm 0;
        for my $p (@pairs) {
            for my $record ([$p->{command_pid}, $p->{command_authority}],
                [$p->reservation->{pid}, $p->reservation->{positive_authority}]) {
                my ($pid, $owned) = @$record;
                next unless $pid && $owned;
                kill 'KILL', $pid;
                my $end = now() + 2;
                while (now() < $end) {
                    my $w = waitpid($pid, WNOHANG);
                    last if $w == $pid || $w == -1;
                    sleep(0.001);
                }
            }
        }
    }
}
local $SIG{ALRM} = sub { die "gated pair test deadline\n" };
alarm 60;

subtest 'prepared resources and partial pipe/seal failures start no process' => sub {
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { die 'unadmitted fork' };
    is_deeply($class->resource_cost, {children => 2, descriptors => 16}, 'both child roles have an explicit pre-fork cost');
    my $p = prepare(snapshot($^X, '-e', 'exit 0'));
    is($p->observation->{phase}, 'prepared', 'preparation starts no child');
    my @handles = (@{$p->handles}, @{$p->reservation->handles});
    ok(!grep(!(fcntl($_, F_GETFD, 0) & FD_CLOEXEC), @handles), 'every retained pipe end is close-on-exec');
    like(error(sub { $p->release }), qr/acknowledged join and departure/, 'no exec release in prepared state');
    close_pair($p);
    ok(!grep(defined(fileno($_)), @handles), 'unused preparation really closes its descriptors');
    like(error(sub { FSM::Support::ProcessSupervisor::GatedPair::prepare(
        snapshot => snapshot($^X, '-e', 'exit 0'), deadline => now() + 3,
        close_handles => [(undef) x 113]) }), qr/descriptor inventory exceeds/, 'descriptor boundary plus one rejects before allocation');
    my @other;
    for (1 .. 56) { pipe(my $read, my $write) or die $!; push @other, $read, $write; }
    my $at_limit = prepare(snapshot($^X, '-e', 'exit 0'), @other);
    is(scalar(@other) + $class->resource_cost->{descriptors}, 128, 'inclusive declared descriptor budget is accepted');
    close_pair($at_limit);
    close $_ or die 'boundary fixture close failed' for @other;
    my $native_pipe = $reservation_class->can('_pipe');
    for my $cut (1 .. 8) {
        my ($count, @allocated) = (0);
        local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
            if (++$count == $cut) { $! = EIO; return 0; }
            my $ok = $native_pipe->(@_); push @allocated, ${$_[0]}, ${$_[1]}; return $ok;
        };
        like(error(sub { prepare(snapshot($^X, '-e', 'exit 0')) }), qr/(?:allocate command|create reservation).*pipe/, "pipe $cut fails before fork");
        ok(!grep(defined(fileno($_)), @allocated), "pipe $cut closes prior allocations");
    }
    my $seal = $reservation_class->can('_seal');
    my @allocated;
    local *FSM::Support::ProcessSupervisor::Reservation::_seal = sub {
        push @allocated, $_[0]; die "injected seal failure\n" if @allocated == 3;
        return $seal->(@_);
    };
    like(error(sub { prepare(snapshot($^X, '-e', 'exit 0')) }), qr/injected seal/, 'descriptor sealing fails before fork');
    ok(!grep(defined(fileno($_)), @allocated), 'seal failure closes all observed handles');
};

subtest 'kernel join, departure and explicit exec release preserve caller state' => sub {
    my $caller_group = getpgrp(0);
    my $cwd = getcwd();
    my $terms = 0;
    local $SIG{TERM} = sub { ++$terms };
    local $ENV{FSMGEN_GATED_FIXTURE} = "value\n\xff";
    pipe(my $sentinel_read, my $sentinel_write) or die $!;
    my $program = 'use JSON::PP; my $n=sysread(STDIN,my $b,1); print JSON::PP->new->ascii->encode({pid=>$$,ppid=>getppid(),group=>getpgrp(0),arg=>$ARGV[0],env=>$ENV{FSMGEN_GATED_FIXTURE},stdin=>$n,mask=>umask()}); print STDERR "stderr-proof"; exit 23';
    my $original_mask = umask();
    my $p = prepare(snapshot($^X, '-e', $program, "arg\n\xfe"), $sentinel_read, $sentinel_write);
    $p->start;
    until_pair($p, 'join_pending');
    my $pid = $p->observation->{command_pid};
    my $reserved = $p->reservation->observation->{pid};
    ok($pid && $pid != $reserved, 'both direct child identities are recorded separately');
    like(error(sub { $p->release }), qr/acknowledged join/, 'recorded fork alone does not release exec');
    close $sentinel_write;
    my $ready = until_pair($p, 'ready');
    is(getpgrp($pid), $reserved, 'independent kernel query proves command membership');
    is(getpgrp($reserved), $caller_group, 'independent kernel query proves reservation departure');
    ok(IO::Select->new($sentinel_read)->can_read(1), 'both children close unrelated inherited writer');
    is(sysread($sentinel_read, my $unused, 1), 0, 'actual sentinel EOF proves descriptor isolation');
    close $sentinel_read;
    ok(!IO::Select->new($p->streams->{stdout})->can_read(0.05), 'ready child has emitted no execution witness');
    for (1 .. 3) { $p->advance; }
    is($p->observation->{released}, 0, 'automatic advancement cannot release exec');
    $p->release;
    is($p->observation->{released}, 0, 'release request remains revocable before byte delivery');
    until_pair($p, 'released');
    my $out = JSON::PP::decode_json(drain($p->streams->{stdout}));
    is_deeply($out, {pid => $pid, ppid => $$, group => $reserved,
        arg => "arg\n\xfe", env => "value\n\xff", stdin => 0, mask => $original_mask},
        'executed child independently reports its identity, bytes, EOF and umask');
    is(drain($p->streams->{stderr}), 'stderr-proof', 'stderr has a separate pipe');
    is(drain($p->streams->{control}), '', 'successful exec closes its control descriptor');
    my $done = reap_command($p);
    is($done->{command_status}, 23 << 8, 'actual command wait preserves nonzero exit');
    like(error(sub { $p->signal_command('KILL') }), qr/unharvested/, 'harvested command cannot be signalled');
    is($p->reservation->group_absent, 1, 'actual command group disappears while reservation is still held');
    ok(kill(0, $reserved), 'independent observation sees reserved identity still alive');
    my $closed = close_pair($p);
    ok($closed->{reaped} && $closed->{wait_status} == 0, 'exact reservation retirement completes');
    is(waitpid($pid, WNOHANG), -1, 'no command wait remains');
    is(waitpid($reserved, WNOHANG), -1, 'no reservation wait remains');
    is(getpgrp(0), $caller_group, 'caller group is unchanged');
    is(getcwd(), $cwd, 'caller cwd is unchanged');
    is($ENV{FSMGEN_GATED_FIXTURE}, "value\n\xff", 'caller environment is unchanged');
    is($terms, 0, 'caller group received no TERM');
};

for my $cut ('prepared', 'group_pending', 'join_pending', 'move_pending', 'ready', 'release_pending') {
    subtest "cancel at $cut cannot execute" => sub {
        my $p = prepare(snapshot($^X, '-e', 'print "EXECUTED"'));
        if ($cut ne 'prepared') {
            $p->start;
            until_pair($p, $cut eq 'release_pending' ? 'ready' : $cut) unless $cut eq 'group_pending';
        }
        $p->release if $cut eq 'release_pending';
        $p->cancel;
        like(error(sub { $p->release }), qr/acknowledged join/, 'cancelled pair cannot be reopened');
        my $closed = close_pair($p);
        ok(!$p->observation->{released}, 'no exec release was delivered');
        is($p->{test_capture}{stdout}, '', 'complete pipe through actual child exit has no execution witness');
        ok(!$p->{command_pid} || $p->observation->{command_reaped}, 'every created command was reaped');
        ok(!$closed->{pid} || $closed->{reaped}, 'every created reservation was reaped');
        like($p->observation->{failure}, qr/cancelled/, 'cancellation stays the first failure');
    };
}

subtest 'real join, departure, gate and descriptor faults retain no execution' => sub {
    for my $fault ('fork', 'join', 'ack', 'depart', 'join-write', 'exec-write', 'child-close', 'parent-close') {
        no warnings 'redefine';
        my $fork = $class->can('_fork'); my $join = $class->can('_join');
        my $write = $class->can('_write'); my $close = $class->can('_close_handle');
        my $set = $reservation_class->can('_set_group');
        my $byte = $reservation_class->can('_child_byte');
        local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub {
            if ($fault eq 'fork') { $! = EAGAIN; return undef; } return $fork->();
        };
        local *FSM::Support::ProcessSupervisor::GatedPair::_join = sub {
            if ($fault eq 'join') { $! = EPERM; return undef; } return $join->(@_);
        };
        local *FSM::Support::ProcessSupervisor::GatedPair::_write = sub {
            if (($fault eq 'join-write' && $_[1] eq 'J') || ($fault eq 'exec-write' && $_[1] eq 'E')) {
                $! = EPIPE; return undef;
            } return $write->(@_);
        };
        local *FSM::Support::ProcessSupervisor::GatedPair::_close_handle = sub {
            my $ok = $close->(@_);
            return $$ != $owner && $fault eq 'child-close' ? 0 : $ok;
        };
        local *FSM::Support::ProcessSupervisor::Reservation::_set_group = sub {
            if ($fault eq 'depart' && $_[0]) { $! = EPERM; return undef; } return $set->(@_);
        };
        local *FSM::Support::ProcessSupervisor::Reservation::_child_byte = sub {
            return $byte->($_[0], $fault eq 'ack' && $_[1] eq 'J' ? '?' : $_[1]);
        };
        my $p = prepare(snapshot($^X, '-e', 'print "EXECUTED"'));
        $p->start;
        my $failed_parent_close = 0;
        local *FSM::Support::ProcessSupervisor::GatedPair::_close_handle = sub {
            my $ok = $close->(@_);
            return 0 if $$ != $owner && $fault eq 'child-close';
            return 0 if $$ == $owner && $fault eq 'parent-close'
                && $p->{command_pid} && !$failed_parent_close++;
            return $ok;
        };
        if ($fault eq 'exec-write') { until_pair($p, 'ready'); $p->release; }
        my $failed = until_pair($p, 'failed');
        my $closed = close_pair($p);
        ok(!$p->observation->{released}, "$fault cannot release exec");
        is($p->{test_capture}{stdout}, '', "$fault actual EOF carries no execution witness");
        is($p->observation->{failure}, $failed->{failure}, "$fault preserves the first failure");
        ok(!$p->{command_pid} || $p->observation->{command_reaped}, "$fault command wait consumed");
        ok($closed->{reaped}, "$fault reservation wait consumed");
    }
};

subtest 'recorded command precedes restored signals; failure is recoverable' => sub {
    for my $fail (0, 1) {
        my $p = prepare(snapshot($^X, '-e', 'exit 0'));
        $p->start;
        my $mask = $class->can('_mask');
        my $published = 0;
        {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::GatedPair::_mask = sub {
                my $value = $mask->(@_);
                if ($$ == $owner && $_[0] == SIG_SETMASK) {
                    $published = $p->{command_pid} && $p->{command_authority};
                    return undef if $fail;
                }
                return $value;
            };
            if ($fail) {
                like(error(sub { until_pair($p, 'join_pending') }), qr/fatal command signal-mask/, 'restore failure is reported with child retained');
            }
            else { until_pair($p, 'join_pending'); }
        }
        ok($published, 'exact child is recorded before signal delivery resumes');
        my $closed = close_pair($p);
        ok($closed->{reaped} && $p->observation->{command_reaped}, 'both recorded children close after interrupted launch');
    }
};

subtest 'execution witness rejects a deliberately bypassed gate' => sub {
    my $expect = $class->can('_child_expect');
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::GatedPair::_child_expect = sub {
        return if $_[1] eq 'E'; # Known-bad child executes without release.
        return $expect->(@_);
    };
    my $p = prepare(snapshot($^X, '-e', 'syswrite STDOUT,"EXECUTED"; exit 0'));
    $p->start;
    until_pair($p, 'join_pending');
    my $end = now() + 2;
    while (now() < $end && !IO::Select->new($p->streams->{stdout})->can_read(0.01)) { $p->advance; }
    ok(IO::Select->new($p->streams->{stdout})->can_read(0), 'independent witness is readable before any release');
    reap_command($p);
    close_pair($p);
    is($p->{test_capture}{stdout}, 'EXECUTED', 'known-bad gate fails the empty-output oracle');
    ok(!$p->observation->{released}, 'internal release flag alone would miss this counterexample');
};

subtest 'exec failure and missing join acknowledgment have actual wait truth' => sub {
    my $p = prepare(snapshot('./.artifacts/no-such-gated-program'));
    $p->start; until_pair($p, 'ready'); $p->release; until_pair($p, 'released');
    my $o = reap_command($p);
    is($o->{command_status}, 127 << 8, 'missing executable retains actual exec failure exit');
    close_pair($p);
    like($p->{test_capture}{control}, qr/exec failed/, 'bounded private control retains exec failure');
    my $byte = $reservation_class->can('_child_byte');
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::Reservation::_child_byte = sub {
        return if $_[1] eq 'J'; return $byte->(@_);
    };
    $p = prepare(snapshot($^X, '-e', 'print "EXECUTED"'));
    $p->start;
    $o = until_pair($p, 'failed');
    like($o->{failure}, qr/join deadline/, 'real child with silent join cannot renew handshake wall');
    close_pair($p);
    is($p->{test_capture}{stdout}, '', 'silent join never executes');
    ok($p->observation->{command_reaped}, 'silent join child has an exact wait');
};

subtest 'blocked release is revocable and signal mask survives exec' => sub {
    my $p = prepare(snapshot($^X, '-e', 'print "EXECUTED"'));
    $p->start; until_pair($p, 'ready'); $p->release;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::GatedPair::_write = sub { $! = EAGAIN; return undef; };
        $p->advance;
    }
    is($p->observation->{phase}, 'release_pending', 'blocked byte delivery remains pending');
    $p->cancel; close_pair($p);
    is($p->{test_capture}{stdout}, '', 'cancel removes queued exec byte');
    my $old = POSIX::SigSet->new;
    POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'mask setup failed';
    $p = prepare(snapshot($^X, '-MPOSIX', '-e',
        'my $s=POSIX::SigSet->new; POSIX::sigprocmask(POSIX::SIG_BLOCK(),POSIX::SigSet->new,$s); print $s->ismember(POSIX::SIGUSR1()) ? "blocked" : "unblocked"'));
    $p->start; until_pair($p, 'ready'); $p->release; until_pair($p, 'released');
    POSIX::sigprocmask(SIG_SETMASK, $old) or die 'caller mask restore failed';
    reap_command($p); close_pair($p);
    is($p->{test_capture}{stdout}, 'blocked', 'exec restores original caller signal mask');
};

subtest 'unknown wait and retired identities never authorize a signal' => sub {
    no warnings 'redefine';
    my @signals;
    local *FSM::Support::ProcessSupervisor::GatedPair::_signal = sub { push @signals, [@_]; return 1; };
    local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $! = ECHILD; return -1; };
    my $p = bless {owner_pid => $$, phase => 'ready', command_pid => 123,
        command_authority => 1, retired => 0}, $class;
    $p->poll_command;
    like($p->observation->{failure}, qr/wait status is unknown/, 'unknown status is explicit failure');
    ok(!$p->observation->{command_reaped}, 'no invented reaping');
    like(error(sub { $p->signal_command('KILL') }), qr/unharvested/, 'unknown child cannot be signalled');
    is_deeply(\@signals, [], 'model uses no real target');
    my $foreign = bless {owner_pid => $$ + 1}, $class;
    like(error(sub { $foreign->release }), qr/inherited pair/, 'forked pair cannot act for creator');
    my $retired = bless {owner_pid => $$, phase => 'finished', retired => 1,
        group_ready => 1, moved => 1, reaped => 1}, $reservation_class;
    my $stale = bless {owner_pid => $$, phase => 'ready', retired => 0,
        deadline => now() + 10, reservation => $retired}, $class;
    like(error(sub { $stale->release }), qr/live reservation/, 'cached ready phase cannot release a retired reservation');
    $stale = bless {owner_pid => $$, phase => 'ready', retired => 0,
        deadline => now() + 10, reservation => $retired}, $class;
    $stale->advance;
    like($stale->observation->{failure}, qr/reservation.*retired/, 'advancement independently rejects retired reservation authority');
};

alarm 0;
done_testing();
