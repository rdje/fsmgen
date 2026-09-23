#!/usr/bin/env perl
use strict;
use warnings;

use Errno qw(EAGAIN ECHILD EINTR EPERM ESRCH);
use IO::Select;
use POSIX qw(WNOHANG);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::GroupClosure ();

my @pairs;
my $owner = $$;
sub now { return clock_gettime(CLOCK_MONOTONIC) }
sub error { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@; }
sub prepare {
    my ($program) = @_;
    my $snapshot = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', $program], cwd => '.', schema => 'private.closure.fixture.v1',
        stage => 'closure-control', containment => 'fixture-group',
        bounds => {timeout_seconds => 10, capture_limit_bytes => 4096},
    }, sprintf('%.0f', now() * 1e9));
    my $pair = FSM::Support::ProcessSupervisor::GatedPair::prepare(
        snapshot => $snapshot, deadline => now() + 10, close_handles => []);
    push @pairs, $pair;
    return $pair;
}
sub until_phase {
    my ($pair, $phase) = @_;
    my $end = now() + 3;
    while (now() < $end) {
        return if $pair->observation->{phase} eq $phase;
        $pair->advance;
        die $pair->observation->{failure} if $pair->observation->{failure};
        sleep(0.001);
    }
    die "fixture never reached $phase\n";
}
sub reap {
    my ($pair) = @_;
    my $end = now() + 2;
    while (now() < $end) {
        $pair->poll_command;
        return if $pair->observation->{command_reaped};
        sleep(0.001);
    }
    die "fixture command wait expired\n";
}
sub closure {
    my ($pair, $cancel, $deadline) = @_;
    return FSM::Support::ProcessSupervisor::GroupClosure::prepare(
        pair => $pair, cancel => $cancel, deadline => $deadline // now() + 4);
}
sub finish {
    my ($closure) = @_;
    my $end = now() + 4.5;
    while (now() < $end) {
        $closure->advance;
        return $closure->observation if $closure->observation->{phase} eq 'finished';
        sleep(0.001);
    }
    die "fixture closure observer expired\n";
}
sub read_bytes {
    my ($fh) = @_;
    my $end = now() + 2;
    while (now() < $end) {
        next unless IO::Select->new($fh)->can_read(0.01);
        my $n = sysread($fh, my $b, 4096);
        next if !defined($n) && ($! == EAGAIN || $! == EINTR);
        die 'fixture read failed' unless defined $n;
        return $b;
    }
    die "fixture read observer expired\n";
}
sub exact_closed {
    my ($pair, $o, $label) = @_;
    ok($o->{complete}, "$label closure is complete") or diag explain $o;
    my $c = $pair->observation;
    my $r = $pair->reservation->observation;
    for my $pid ($c->{command_pid}, $r->{pid}) {
        next unless $pid;
        is(waitpid($pid, WNOHANG), -1, "$label has no remaining exact wait");
        is(0 + $!, ECHILD, "$label exact wait was consumed");
    }
    if ($r->{pid}) {
        local $! = 0;
        is(kill(0, -$r->{pid}), 0, "$label kernel group is absent");
        is(0 + $!, ESRCH, "$label group absence is actual ESRCH");
    }
    ok(!@{$pair->handles} && !@{$pair->reservation->handles}, "$label pair descriptors are closed");
}

# Rescue only recorded, unharvested children from real controls. Models below
# never enter this list and never invoke a native signal or wait operation.
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
local $SIG{ALRM} = sub { die "group closure test deadline\n" };
alarm 60;

subtest 'successful command and reservation have independent exact closure' => sub {
    my $p = prepare('print "executed"; exit 23');
    $p->start; until_phase($p, 'ready');
    my %received;
    $p->transfer_streams(\%received);
    $p->release; until_phase($p, 'released');
    is(read_bytes($received{stdout}), 'executed', 'actual program witnesses execution');
    reap($p);
    is($p->observation->{command_status}, 23 << 8, 'original command wait is nonzero');
    my $rpid = $p->reservation->observation->{pid};
    ok(kill(0, $rpid), 'reservation is retained after command reaping');
    my $c = closure($p, 0);
    is($p->observation->{retired}, 0, 'preparing closure has no lifecycle side effect');
    my $o = finish($c);
    exact_closed($p, $o, 'ordinary completion');
    is($p->reservation->observation->{wait_status}, 0, 'reservation wait is separate and successful');
    is($p->observation->{command_status}, 23 << 8, 'cleanup preserves original command wait');
    ok(!$o->{term_sent} && !$o->{kill_sent}, 'ordinary completion needs no termination signals');
    ok(!defined($p->observation->{failure}), 'normal closure manufactures no cancellation failure');
    for my $name (sort keys %received) {
        ok(defined(fileno($received{$name})), "$name remains capture-owned");
        is(read_bytes($received{$name}), '', "$name reaches actual EOF");
        close $received{$name} or die $!;
    }
    like(error(sub { $p->reservation->group_absent }), qr/live reservation identity/, 'retirement closes future group inspection');
};

subtest 'cancellation at each pre-exec boundary never executes the command' => sub {
    my $caller_group = getpgrp(0);
    my $native_probe = FSM::Support::ProcessSupervisor::Reservation->can('group_absent');
    no warnings 'redefine';
    for my $phase (qw(prepared group_pending join_pending move_pending ready release_pending)) {
        my $p = prepare('print "UNADMITTED EXECUTION"');
        if ($phase ne 'prepared') {
            $p->start;
            until_phase($p, $phase eq 'release_pending' ? 'ready' : $phase);
            $p->release if $phase eq 'release_pending';
        }
        my $witness = $p->streams->{stdout};
        # Duplicate only the test reader to observe actual EOF after the owner
        # closes its endpoint. The children inherit neither duplicate.
        open my $observer, '<&', $witness or die $!;
        my $c = closure($p, 1);
        local *FSM::Support::ProcessSupervisor::Reservation::group_absent = sub {
            ok(!$p->observation->{command_authority}, 'exact command wait precedes absence probing');
            return $native_probe->(@_);
        };
        my $o = finish($c);
        exact_closed($p, $o, $phase);
        is(read_bytes($observer), '', "$phase produced no execution witness");
        close $observer or die $!;
        is(getpgrp(0), $caller_group, "$phase leaves caller group untouched");
        ok(!$p->observation->{released}, "$phase never delivers exec release");
    }
};

subtest 'a TERM-ignoring command escalates within the same envelope' => sub {
    my $p = prepare('$SIG{TERM}="IGNORE"; $|=1; print "ready"; sleep 10');
    $p->start; until_phase($p, 'ready'); $p->release; until_phase($p, 'released');
    is(read_bytes($p->streams->{stdout}), 'ready', 'actual child installed TERM ignore before cancellation');
    my $end = now() + 4;
    my $c = closure($p, 1, $end);
    my $o = finish($c);
    exact_closed($p, $o, 'escalation');
    ok($o->{term_sent} && $o->{kill_sent}, 'both real group signals were needed');
    is($p->observation->{command_status} & 127, 9, 'exact command wait reports KILL');
    is($o->{reservation_wait_status}, $p->reservation->observation->{wait_status},
        'reservation wait truth is retained independently of resource closure');
    is($o->{deadline}, $end, 'reservation closure never renews the shared deadline');
    cmp_ok(now(), '<', $end, 'actual closure finishes inside that deadline');
};

subtest 'preparation rejects invalid ownership and extended envelopes' => sub {
    my $p = prepare('exit 0');
    like(error(sub { closure($p, 0) }), qr/exact released command wait/, 'normal closure requires completion');
    like(error(sub { closure($p, 2) }), qr/integer boolean/, 'cancel grammar is closed');
    like(error(sub { closure($p, 1, now() + 5) }), qr/extend/, 'another cleanup grace is refused');
    finish(closure($p, 1));
    like(error(sub { closure($p, 1) }), qr/already retired/, 'retired identities cannot reopen');
};

subtest 'normal command exit still fails its surviving descendants' => sub {
    my $p = prepare('pipe(my $r,my $w) or die $!; my $pid=fork(); die $! unless defined $pid; if (!$pid) { close $r; syswrite($w,"R"); close $w; sleep 3; exit 0 } close $w; sysread($r,my $b,1); close $r; print $pid; exit 0');
    $p->start; until_phase($p, 'ready'); $p->release; until_phase($p, 'released');
    my $descendant = read_bytes($p->streams->{stdout});
    like($descendant, qr/\A[0-9]+\z/, 'actual parent reports its direct descendant');
    reap($p);
    is(getpgrp($descendant), $p->reservation->observation->{pid}, 'kernel observes the surviving group member');
    my $o = finish(closure($p, 0));
    exact_closed($p, $o, 'surviving descendant');
    ok($o->{surviving_descendants}, 'successful cleanup retains the descendant failure fact');
    ok($o->{term_sent}, 'actual group termination reaches the descendant');
    is($p->observation->{command_status}, 0, 'original successful command wait is not overwritten');
};

# Deterministic hostile lifecycle models use fake identities solely behind
# replaced methods. No native syscall is given a model PID.
sub model {
    my (%args) = @_;
    my $clock = $args{start} // 100;
    my @events;
    my $r = bless {owner_pid => $$, phase => 'moved', pid => 80002,
        moved => 1, group_ready => 1, retired => 0, reaped => 0},
        'FSM::Support::ProcessSupervisor::Reservation';
    $r->{moved} = 0 if $args{no_move} || $args{move_on_advance};
    my $p = bless {owner_pid => $$, deadline => 101, phase => 'released',
        command_pid => 80001, command_authority => 1, command_reaped => 0,
        released => 1, joined => $args{unjoined} ? 0 : 1, reservation => $r},
        'FSM::Support::ProcessSupervisor::GatedPair';
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::Reservation::_now = sub { $clock };
    local *FSM::Support::ProcessSupervisor::GatedPair::cancel = sub { push @events, 'cancel'; $_[0]{failure} //= 'command cancelled' };
    local *FSM::Support::ProcessSupervisor::GatedPair::advance = sub {
        push @events, 'advance'; $r->{moved} = 1 if $args{move_on_advance};
    };
    local *FSM::Support::ProcessSupervisor::GatedPair::poll_command = sub {
        push @events, 'command_wait';
        if ($args{unknown}) { $p->{command_authority} = 0; }
        elsif ($args{reaped}) { $p->{command_reaped} = 1; $p->{command_authority} = 0; }
    };
    local *FSM::Support::ProcessSupervisor::Reservation::group_absent = sub {
        die 'unowned group probe' if $r->{retired} || !$r->{moved}; push @events, 'group_probe';
        return $args{uncertain} ? undef : $args{absent} ? 1 : 0;
    };
    local *FSM::Support::ProcessSupervisor::Reservation::signal_group = sub {
        die 'unowned group signal' if $r->{retired} || !$r->{moved}; push @events, "group_$_[1]"; return 1;
    };
    local *FSM::Support::ProcessSupervisor::GatedPair::signal_command = sub {
        die 'unowned command signal' if ($r->{moved} && $p->{joined}) || !$p->{command_authority};
        push @events, "command_$_[1]"; return 1;
    };
    local *FSM::Support::ProcessSupervisor::GatedPair::retire = sub {
        push @events, 'retire'; $p->{retired} = $r->{retired} = 1;
        $p->{command_authority} = 0;
        is($_[1], 104, 'retirement receives original shared deadline');
    };
    local *FSM::Support::ProcessSupervisor::Reservation::advance = sub {
        die 'reservation reaped before retirement' unless $r->{retired};
        push @events, 'reservation_wait'; $r->{phase} = 'finished';
        $r->{reaped} = $args{reservation_unknown} ? 0 : 1;
        $r->{wait_status} = $args{reservation_unknown} ? undef : $args{reservation_status} // 0;
    };
    my $c = closure($p, 1, 104);
    $c->advance;
    $clock = 102 if $clock < 102; $c->advance;
    $clock = 104 if $clock < 104; $c->advance;
    my $o = $c->observation;
    my @terminal = @events;
    $c->advance;
    is_deeply(\@events, \@terminal, 'finished advancement performs no identity operations');
    return ($o, \@events);
}

subtest 'modeled incomplete cleanup preserves actual facts and signal retirement' => sub {
    for my $case (
        [{unknown => 1, absent => 1}, qr/command-group closure|command wait/],
        [{reaped => 1, uncertain => 1}, qr/absence is uncertain/],
        [{reaped => 1}, qr/command-group closure/],
        [{reaped => 1, absent => 1, reservation_unknown => 1}, qr/reservation closure/],
    ) {
        my ($o, $events) = model(%{$case->[0]});
        is($o->{phase}, 'finished', 'model terminates at the original deadline');
        ok(!$o->{complete}, 'unknown cleanup never becomes success');
        like($o->{failure}, $case->[1], 'first cleanup failure remains visible');
        is($events->[0], 'cancel', 'exec permission is revoked before waits or signals');
        my ($retire) = grep { $events->[$_] eq 'retire' } 0 .. $#$events;
        is($events->[$retire + 1], 'reservation_wait', 'reservation is waited only after final identity retirement');
        ok(!grep(/^group_/, @$events[$retire + 1 .. $#$events]), 'no group operation follows retirement');
    }
    my ($o, $events) = model();
    is_deeply([grep { /^group_(?:TERM|KILL)$/ } @$events], ['group_TERM', 'group_KILL'],
        'stuck group receives each escalation once under one wall');
    my ($forced) = model(reaped => 1, absent => 1, reservation_status => 9);
    ok($forced->{complete}, 'exact forced reservation reaping can close owned resources');
    is($forced->{reservation_wait_status}, 9, 'forced status is never promoted to successful exit');
    my ($unmoved, $positive) = model(no_move => 1);
    ok(!$unmoved->{group_gone} && !$unmoved->{complete}, 'unacknowledged departure stays incomplete');
    is_deeply([grep { /_(?:TERM|KILL)$/ } @$positive], ['command_TERM', 'command_KILL'],
        'before departure only the owned positive command is signalled');
    my (undef, $handoff) = model(move_on_advance => 1);
    is_deeply([grep { /_(?:TERM|KILL)$/ } @$handoff], ['command_TERM', 'group_TERM', 'group_KILL'],
        'a prior positive TERM does not suppress newly available group authority');
    my (undef, $unjoined) = model(move_on_advance => 1, unjoined => 1);
    is_deeply([grep { /_(?:TERM|KILL)$/ } @$unjoined],
        ['command_TERM', 'group_TERM', 'group_KILL', 'command_KILL'],
        'reservation departure cannot suppress positive KILL of an unjoined command');
    my ($expired, $last) = model(start => 105);
    ok(!$expired->{complete}, 'expired shared wall cannot grant another grace');
    is_deeply([grep { /_(?:TERM|KILL)$/ } @$last], ['group_KILL'],
        'expired closure makes its final bounded attempt without another TERM phase');
};

alarm 0;
done_testing();
