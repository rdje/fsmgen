#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN EINTR EIO);
use IO::Select;
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::GatedPair ();

my $pair_class = 'FSM::Support::ProcessSupervisor::GatedPair';
my $reservation_class = 'FSM::Support::ProcessSupervisor::Reservation';
my $creator = $$;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub snapshot {
    return {type => 'SPAWN', started_ns => sprintf('%.0f', now() * 1e9),
        schema => 'native.exec.admission', stage => 'gate', containment => 'fixture-group',
        cwd => '.', umask => 0027, timeout_seconds => 20, capture_limit_bytes => 4096,
        argv => [$^X, '-MPOSIX', '-e', 'my $s=POSIX::SigSet->new; POSIX::sigprocmask(POSIX::SIG_BLOCK(),POSIX::SigSet->new,$s); syswrite STDOUT, join(":", "EXECUTED", $s->ismember(POSIX::SIGUSR1())?1:0, $s->ismember(POSIX::SIGUSR2())?1:0);'],
        environment => []};
}
subtest 'original pair identity refuses shallow creator copies' => sub {
    my $p = FSM::Support::ProcessSupervisor::GatedPair::prepare_record(
        snapshot => snapshot(), deadline => now() + 20, close_handles => []);
    my $copy = bless {%$p}, ref($p);
    like(error_from(sub { $copy->observation }), qr/invalid or inherited pair/,
        'copied creator pair cannot act as the retained native owner');
    is($p->observation->{phase}, 'unallocated', 'original resource-free owner remains usable');
};


my (@pairs, @pipes, %births);
my ($p, $mode, $write_calls, $writes, $clock, $signal_cut, $mask_cut);
my @write_masks;
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot read native mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
my $pipe = $reservation_class->can('_pipe');
my $cfork = $pair_class->can('_fork'); my $rfork = $reservation_class->can('_fork');
my $cwait = $pair_class->can('_wait'); my $rwait = $reservation_class->can('_wait');
my $write = $pair_class->can('_write'); my $close = $pair_class->can('_close_handle');
my $native_now = $pair_class->can('_now'); my $mask = $reservation_class->can('_mask');
my $fork = sub { my ($f) = @_; my $pid = $f->(); $births{$pid} = 0 if defined($pid) && $pid > 0; return $pid; };
my $wait = sub {
    my ($f, $pid) = @_; die 'unexpected non-positive wait' unless $pid > 0;
    my $n = $f->($pid); my $status = $?; $births{$pid} = 1 if $n == $pid;
    $? = $status; return $n;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    my $ok = $pipe->(@_);
    if ($ok) { push @pipes, ${$_[0]}, ${$_[1]}; weaken($pipes[-1]); weaken($pipes[-2]); }
    return $ok;
};
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->($cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->($rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait, @_) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_now = sub { defined($clock) ? $clock : $native_now->() };
local *FSM::Support::ProcessSupervisor::GatedPair::_write = sub {
    return $write->(@_) unless $$ == $creator && $_[1] eq 'E';
    ++$write_calls; push @write_masks, mask_state();
    if ($mode eq 'EAGAIN' || $mode eq 'EINTR' || $mode eq 'EIO') {
        $! = $mode eq 'EAGAIN' ? EAGAIN : $mode eq 'EINTR' ? EINTR : EIO; return undef;
    }
    my $n = $write->(@_); ++$writes if defined($n) && $n == 1;
    die "lost native E return\n" if $mode eq 'lost-return';
    kill('USR2', $$) == 1 or die 'cannot queue release signal' if $signal_cut eq 'write';
    return $n;
};
local *FSM::Support::ProcessSupervisor::GatedPair::_close_handle = sub {
    my $is_ack = $$ == $creator && $p && $signal_cut eq 'close'
        && $p->{released} && defined($p->{test_ack}) && refaddr($_[0]) == $p->{test_ack};
    my $n = $close->(@_);
    die "lost gate close return\n" if $$ == $creator && $mode eq 'close-throw'
        && defined($p->{test_ack}) && refaddr($_[0]) == $p->{test_ack};
    kill('USR2', $$) == 1 or die 'cannot queue close signal' if $is_ack;
    return $n;
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    my $n = $mask->(@_);
    if ($$ == $creator && $mask_cut && $_[0] == SIG_BLOCK) {
        $mask_cut = 0; kill('USR2', $$) == 1 or die 'cannot queue publication signal';
    }
    return $n;
};
sub until_phase {
    my ($wanted) = @_; my $end = now() + 3;
    while (now() < $end) {
        $p->advance; my $o = $p->observation; return $o if $o->{phase} eq $wanted;
        die "native pair failed: $o->{failure}" if $o->{failure}; sleep(0.001);
    }
    die "native gate observer expired: $wanted";
}
sub prepare_ready {
    die 'prior native fixture resources survive' if live(@pipes) || grep { !$_ } values %births;
    ($mode, $signal_cut, $mask_cut, $write_calls, $writes, $clock) = ('', '', 0, 0, 0, undef);
    @write_masks = (); @pipes = ();
    $p = FSM::Support::ProcessSupervisor::GatedPair::prepare(
        snapshot => snapshot(), deadline => now() + 20, close_handles => []);
    push @pairs, $p; $p->start; until_phase('ready');
    $p->{test_ack} = refaddr($p->{ack});
    return $p;
}
sub drain {
    my ($fh) = @_; my ($text, $end) = ('', now() + 2);
    while (now() < $end) {
        next unless IO::Select->new($fh)->can_read(0.01);
        my $n = sysread($fh, my $chunk, 4096);
        next if !defined($n) && ($! == EAGAIN || $! == EINTR);
        die 'native output read failed' unless defined $n;
        return $text unless $n; $text .= $chunk; die 'native output exceeds bound' if length($text) > 4096;
    }
    die 'native output EOF observer expired';
}
sub finish {
    my ($expect) = @_;
    $mode = $signal_cut = ''; $mask_cut = 0; $clock = undef;
    if (!$expect) { $p->cancel unless $p->{retired}; }
    my $end = now() + 2;
    while ($p->{command_authority} && now() < $end) { $p->poll_command; sleep(0.001); }
    die 'exact command wait expired' if $p->{command_authority};
    is($p->observation->{command_reaped}, 1, 'exact original command wait was consumed');
    is(drain($p->streams->{stdout}), $expect // '', 'native output through EOF independently witnesses execution');
    is(drain($p->streams->{stderr}), '', 'native stderr reaches empty EOF');
    is(drain($p->streams->{control}), '', 'native control reaches empty EOF');
    my $r = $p->reservation;
    if (!$r->{retired}) {
        is($r->group_absent, 1, 'original moved command group is absent before retirement');
    }
    $p->retire(now() + 2);
    $end = now() + 3;
    while ($r->observation->{phase} ne 'finished' && now() < $end) { $r->advance; sleep(0.001); }
    ok($r->observation->{reaped}, 'original reservation has its exact consumed wait');
    ok(!grep(!$_, values %births), 'independent fork/wait census has no live direct child');
    ok(!live(@pipes), 'independent weak pipe inventory is fully closed');
    ok(!exists $p->{release_check}, 'retirement retains no callback or owner cycle');
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        for my $pid (grep { !$births{$_} } keys %births) {
            my $n = CORE::waitpid($pid, WNOHANG); next if $n == $pid || $n == -1;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) { last if CORE::waitpid($pid, WNOHANG) == $pid; sleep(0.001); }
        }
        CORE::close($_) for live(@pipes);
    }
}
local $SIG{ALRM} = sub { die "native execution admission test deadline\n" };
alarm 90;
my $caller_mask = POSIX::SigSet->new;
defined POSIX::sigprocmask(SIG_SETMASK, POSIX::SigSet->new(SIGUSR1), $caller_mask) or die 'mask setup failed';
local $SIG{USR2} = sub { die "unexpected creator signal\n" };

subtest 'each native attempt requires fresh admission and keeps the original exec mask' => sub {
    prepare_ready(); my ($calls, $allow) = (0, 0); my $wall = $p->{deadline};
    $p->release(sub {
        is(refaddr($_[0]), refaddr($p), 'admission receives the original native owner');
        is_deeply(mask_state(), [1,1], 'admission runs under creator masking');
        ++$calls; return $allow;
    });
    is($calls, 0, 'queuing release performs no early admission');
    $p->advance; is($write_calls, 0, 'boolean deferral performs no native E write');
    is($p->observation->{phase}, 'release_pending', 'deferral remains revocable');
    $allow = 1;
    for my $retry ('EAGAIN', 'EINTR') {
        $mode = $retry; $p->advance;
        is($p->observation->{released}, 0, "$retry confirms no execution byte");
        is($p->observation->{release_uncertain}, 0, "$retry is a known retryable return");
    }
    my $copy = bless {%$p}, ref($p);
    like(error_from(sub { $copy->advance }), qr/invalid or inherited pair/, 'copied pending pair cannot write E');
    $mode = ''; $p->advance;
    is($calls, 4, 'deferral and every syscall retry each obtain fresh admission');
    is($write_calls, 3, 'only admitted attempts reach the native boundary');
    is($writes, 1, 'one literal E byte crosses the original gate');
    is_deeply(\@write_masks, [[1,1],[1,1],[1,1]], 'every E attempt is masked');
    is($p->{deadline}, $wall, 'no deferral or retry renews the original wall');
    ok($p->observation->{released} && !live($p->{gate}, $p->{ack}), 'release truth and both closes are retained together');
    ok(!exists $p->{release_check}, 'successful release removes its retained callback');
    like(error_from(sub { $p->release }), qr/acknowledged join/, 'released pair cannot reopen the gate');
    is_deeply(mask_state(), [1,0], 'creator mask is restored after E');
    finish('EXECUTED:1:0');
};

subtest 'inherited ready pair cannot release for its original creator' => sub {
    prepare_ready();
    my $pid = CORE::fork(); die 'cannot fork ownership observer' unless defined $pid;
    if (!$pid) {
        my $why = error_from(sub { $p->release(sub { 1 }) });
        _exit($why =~ /invalid or inherited pair/ ? 0 : 93);
    }
    $births{$pid} = 0;
    my ($status, $end) = (undef, now() + 2);
    while (now() < $end) {
        my $n = CORE::waitpid($pid, WNOHANG);
        if ($n == $pid) { $status = $?; $births{$pid} = 1; last; }
        die 'inherited observer wait failed' if $n < 0; sleep(0.001);
    }
    is($status, 0, 'real inherited process refuses the creator execution gate');
    is($p->observation->{phase}, 'ready', 'creator keeps its original gate state');
    is($write_calls, 0, 'creator has issued no E byte'); finish();
};

subtest 'legacy release remains callable and hard write failure cannot retry' => sub {
    prepare_ready(); $p->release; $p->advance; finish('EXECUTED:1:0');
    prepare_ready(); $p->release; $mode = 'EIO'; $p->advance;
    like($p->observation->{failure}, qr/command gate write failed/, 'legacy write failure retains its existing diagnostic');
    is($p->observation->{release_uncertain}, 0, 'reported syscall failure is known');
    $mode = ''; $p->advance; is($write_calls, 1, 'failed native write cannot later execute'); finish();
};

subtest 'live checks before and after callbacks revoke stale authority even on deferral' => sub {
    for my $cut ('copy', 'owner', 'reservation', 'command', 'wall', 'renewed-wall', 'gate', 'cancel', 'retire', 'bad-return', 'throw', 'reentrant') {
        for my $allow (0,1) {
            prepare_ready(); my %saved = map { $_ => $p->{$_} } qw(identity reservation command_pid deadline);
            my $called = 0;
            if ($cut eq 'copy') {
                my $copy = bless {%$p}, ref($p);
                like(error_from(sub { $copy->release(sub { ++$called; 1 }) }), qr/invalid or inherited pair/, 'copied ready owner cannot queue E');
            }
            else {
                $p->release(sub {
                    ++$called;
                    if ($cut eq 'owner') { $p->{identity} = 0; }
                    elsif ($cut eq 'reservation') { $p->{reservation} = bless {%{$p->{reservation}}}, ref($p->{reservation}); }
                    elsif ($cut eq 'command') { $p->{command_pid} = $creator; }
                    elsif ($cut eq 'wall') { $clock = $p->{deadline}; }
                    elsif ($cut eq 'renewed-wall') { $p->{deadline} += 10; }
                    elsif ($cut eq 'gate') { CORE::close($p->{gate}); }
                    elsif ($cut eq 'cancel') { $p->cancel; }
                    elsif ($cut eq 'retire') { $p->reservation->retire(now() + 2); }
                    elsif ($cut eq 'bad-return') { return []; }
                    elsif ($cut eq 'throw') { die "original execution refusal\n"; }
                    elsif ($cut eq 'reentrant') { eval { $p->advance }; }
                    return $allow;
                });
                my $why = error_from(sub { $p->advance });
                like($why, $cut eq 'throw' ? qr/original execution refusal/ : qr/private gated process:/, "$cut/$allow reports original refusal");
            }
            @{$p}{keys %saved} = values %saved; $clock = undef;
            is($called, $cut eq 'copy' ? 0 : 1, "$cut/$allow callback has bounded invocation");
            is($write_calls, 0, "$cut/$allow reaches no E syscall");
            ok(!exists $p->{release_check}, "$cut/$allow clears the refused callback");
            $p->advance;
            is($writes, 0, "$cut/$allow later advancement cannot bypass refusal");
            finish();
        }
    }
};

subtest 'fresh wall and exact dead-command observations precede admission' => sub {
    for my $cut ('wall-before', 'dead-before', 'dead-after') {
        prepare_ready(); my $calls = 0;
        my $kill_command = sub {
            kill('KILL', $p->{command_pid}) == 1 or die 'cannot stop owned command';
            die 'actual command death not observed' unless IO::Select->new($p->{ack})->can_read(1);
        };
        $p->release(sub { ++$calls; $kill_command->() if $cut eq 'dead-after'; return 1 });
        $clock = $p->{deadline} if $cut eq 'wall-before';
        $kill_command->() if $cut eq 'dead-before';
        like(error_from(sub { $p->advance }), qr/(?:invocation wall|command custody)/, "$cut refuses the original effect");
        is($calls, $cut eq 'dead-after' ? 1 : 0, "$cut checks fresh native state at the correct side");
        is($write_calls, 0, "$cut prevents the syscall"); finish();
    }
};

subtest 'actual creator interruptions see committed native effect and closed gates' => sub {
    for my $cut ('write', 'close', 'queue') {
        prepare_ready(); my $seen;
        local $SIG{USR2} = sub {
            $seen = [$p->observation, scalar live($p->{gate}, $p->{ack})];
            die "original release interruption\n";
        };
        if ($cut eq 'queue') {
            $mask_cut = 1;
            like(error_from(sub { $p->release(sub { 1 }) }), qr/original release interruption/, 'queued release return is interrupted');
            is($seen->[0]{phase}, 'release_pending', 'queued byte is retained before unmask');
            is($seen->[0]{released}, 0, 'queue publication fabricates no native effect');
            is($write_calls, 0, 'queue interruption reaches no E'); finish();
        }
        else {
            $p->release(sub { 1 }); $signal_cut = $cut;
            like(error_from(sub { $p->advance }), qr/original release interruption/, "$cut return is interrupted by a real signal");
            ok($seen->[0]{released} && !$seen->[0]{release_uncertain}, "$cut handler sees confirmed original native effect");
            is($seen->[1], 0, "$cut handler sees gate and ack closed");
            ok($p->observation->{released}, "$cut failure preserves historical release truth");
            is($writes, 1, "$cut writes exactly once"); finish('EXECUTED:1:0');
        }
        is_deeply(mask_state(), [1,0], "$cut restores original creator mask");
    }
};

subtest 'refused queue publishes failure before pending creator delivery' => sub {
    prepare_ready(); my $seen;
    local $SIG{USR2} = sub {
        $seen = [$p->observation, scalar live($p->{gate})];
        die "queue refusal interruption\n";
    };
    $clock = $p->{deadline}; $mask_cut = 1;
    like(error_from(sub { $p->release(sub { 1 }) }), qr/invocation wall.*queue refusal interruption/s,
        'queue error and pending interruption both survive');
    is($seen->[0]{phase}, 'failed', 'refused queue is revoked before creator delivery');
    is($seen->[1], 0, 'refused original gate is closed before creator delivery');
    like($p->observation->{failure}, qr/invocation wall/, 'original queue refusal remains first cause');
    is($write_calls, 0, 'refused queue reaches no E write'); finish();
};

subtest 'failure after actual gate closure preserves the confirmed byte' => sub {
    prepare_ready(); $p->release(sub { 1 }); $mode = 'close-throw';
    like(error_from(sub { $p->advance }), qr/lost gate close return/, 'original close return error survives');
    ok($p->observation->{released} && !$p->observation->{release_uncertain}, 'confirmed E remains true when its close return is lost');
    ok(!live($p->{gate}, $p->{ack}), 'actual gate handles are closed despite lost close return');
    $mode = ''; $p->advance; is($write_calls, 1, 'failed close cannot repeat E');
    finish('EXECUTED:1:0');
};

subtest 'lost native return retains uncertainty without repeating irreversible effect' => sub {
    prepare_ready(); $p->release(sub { 1 }); $mode = 'lost-return';
    like(error_from(sub { $p->advance }), qr/lost native E return/, 'original native return error is preserved');
    my $v = $p->observation;
    ok($v->{release_attempted} && $v->{release_uncertain} && !$v->{released}, 'lost return is explicit uncertainty, never a no-exec claim');
    $mode = ''; $p->advance;
    is($write_calls, 1, 'uncertain original effect is never retried');
    finish('EXECUTED:1:0');
};

defined POSIX::sigprocmask(SIG_SETMASK, $caller_mask) or die 'caller mask restore failed';
alarm 0;
done_testing();
