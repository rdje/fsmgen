#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(ECHILD);
use Fcntl qw(F_GETFD FD_CLOEXEC);
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;

our ($SELECTED, $READ_CHUNK, $NATIVE_READS) = (0, undef, 0);
our @EVENTS;
BEGIN {
    no warnings qw(once redefine);
    # Compile the actual Endpoint reads through this alias-preserving observer.
    # Observe byte counts only; authority bytes never enter TAP or diagnostics.
    *CORE::GLOBAL::sysread = sub {
        my $selected = $SELECTED && -c $_[0];
        my $count = $_[2];
        if ($selected) {
            $NATIVE_READS++;
            die 'token source lacks close-on-exec' unless fcntl($_[0], F_GETFD, 0) & FD_CLOEXEC;
            $count = $READ_CHUNK if defined($READ_CHUNK) && $READ_CHUNK < $count;
        }
        my $n = @_ == 4 ? CORE::sysread($_[0], $_[1], $count, $_[3])
            : CORE::sysread($_[0], $_[1], $count);
        push @EVENTS, 'read:' . (defined($n) ? $n : 'error') if $selected;
        return $n;
    };
}
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Service ();

my $creator = $$;
my (@services, @entropy, %children);
my ($opens, $clock_ns, $expire_after_open, $selected_wall) = (0, undef, 0, undef);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1_000_000_000) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
my $initial = census();
sub native_live { grep { defined($_) && defined(fileno($_)) } @entropy }
sub reset_observers {
    die 'token observer reset would forget a live handle' if native_live();
    @entropy = (); @EVENTS = (); $opens = 0; $NATIVE_READS = 0;
    $READ_CHUNK = undef; $clock_ns = undef; $expire_after_open = 0;
}
sub service {
    local $SELECTED = 0;
    my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run();
    my $s = FSM::Support::ProcessSupervisor::Service::new_service($run, ns(now() + 25));
    push @services, $s; return $s;
}
sub finish {
    my ($s) = @_; my $path = repository_root() . '/' . $s->{run}{directory};
    local $SELECTED = 0;
    ok($s->close->{ok}, 'original Service closes completely');
    ok(!-e $path, 'independent exact endpoint is absent');
    is(scalar(native_live()), 0, 'weak observers find no live scoped entropy handle');
}
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot read token mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0; $SELECTED = 0; $clock_ns = undef;
        for my $pid (keys %children) {
            next if $children{$pid}; my $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid || ($w == -1 && $! == ECHILD)) { $children{$pid} = 1; next; }
            die 'token fixture lost exact child' unless $w == 0;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) {
                if (CORE::waitpid($pid, WNOHANG) == $pid) { $children{$pid} = 1; last; }
                sleep(0.001);
            }
            die 'token child rescue expired' unless $children{$pid};
        }
        eval { $_->close } for @services;
    }
}
my $seal = FSM::Support::ProcessSupervisor::Endpoint->can('_seal_handle');
my $clock = FSM::Support::ProcessSupervisor::Service->can('_now_ns');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { $clock_ns // $clock->() };
local *FSM::Support::ProcessSupervisor::Endpoint::_seal_handle = sub {
    if ($SELECTED && -c $_[0]) {
        $opens++; push @EVENTS, 'open';
        # An observer must not keep a scoped source alive during unwinding.
        push @entropy, $_[0]; weaken($entropy[-1]);
        $clock_ns = $selected_wall if $expire_after_open;
    }
    return $seal->(@_);
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "parent token admission fixture deadline\n" }; alarm 35;

subtest 'Endpoint token checks precede actual entropy effects and preserve the no-callback API' => sub {
    reset_observers(); local $SELECTED = 1;
    my $token = FSM::Support::ProcessSupervisor::Endpoint::new_job_token(sub {
        is($_[0], 'create', 'token callback keeps the original allocation role');
        push @EVENTS, 'check:' . $_[1];
        return; # Allocation checks refuse by throwing, not by boolean return.
    });
    ok(length($token) == 32 && !utf8::is_utf8($token), 'actual token has the admitted octet width without exposing authority');
    is_deeply(\@EVENTS, ['check:entropy_open', 'open', 'check:entropy_read', 'read:32'], 'independent native observer orders each guard before its effect');
    is(scalar(native_live()), 0, 'successful token scope closes its native source');
    reset_observers();
    $token = FSM::Support::ProcessSupervisor::Endpoint::new_job_token();
    ok(length($token) == 32, 'legacy token call still obtains the admitted width');
    is_deeply(\@EVENTS, ['open', 'read:32'], 'legacy native byte acquisition remains unchanged');
};

subtest 'original preparing Service parent reaches every short-read admission under its mask' => sub {
    reset_observers(); my $s = service(); local $SELECTED = 1; $READ_CHUNK = 4;
    my @calls; my $context = $s->register_parent(2, ns(now() + 15), sub {
        my ($owner, $id, $kind, $operation) = @_;
        push @calls, [refaddr($owner), $id, $kind, $operation, $s->parent_observation($id)->{state}, mask_state()];
        push @EVENTS, 'check:' . $operation;
        return 0; # Existing allocation callbacks have a void success contract.
    });
    is(scalar @calls, 9, 'one open and every bounded short read obtain original admission');
    is_deeply(\@calls, [map { [refaddr($s), 2, 'create', $_, 'preparing', [1, 1]] }
        'entropy_open', ('entropy_read') x 8], 'all calls name the original preparing parent and native operation');
    is_deeply(\@EVENTS, ['check:entropy_open', 'open', map { ('check:entropy_read', 'read:4') } 1 .. 8], 'actual short reads follow their matching guards');
    is($s->parent_observation(2)->{state}, 'ready', 'complete admitted entropy publishes ready authority');
    ok($context eq $s->parent_context(2), 'original ready context is recoverable without printing its bytes');
    finish($s);
};

subtest 'caller refusal before open or read retains failure and spends the original identity' => sub {
    for my $operation (qw(entropy_open entropy_read)) {
        reset_observers(); my $s = service(); local $SELECTED = 1;
        my $error = error_from(sub { $s->register_parent(2, ns(now() + 15), sub {
            push @EVENTS, 'check:' . $_[3]; die "selected token admission refusal\n" if $_[3] eq $operation;
        }) });
        like($error, qr/selected token admission refusal/, 'original allocation refusal survives unwinding');
        is($opens, $operation eq 'entropy_open' ? 0 : 1, 'open refusal prevents acquisition while read refusal releases its acquired source');
        is($NATIVE_READS, 0, 'refused admission performs no native entropy read');
        is_deeply([@{$s->parent_observation(2)}{qw(state)}], ['failed'], 'original parent preparation remains failed');
        is($s->parent_observation(2)->{failure}{status}, 'host_error', 'caller refusal retains its first preparation cause');
        like(error_from(sub { $s->parent_context(2) }), qr/not complete/, 'failed token admission never exposes a context');
        like(error_from(sub { $s->register_parent(2, ns(now() + 15)) }), qr/reused or out of order/, 'failed identity cannot be retried into new token authority');
        finish($s);
    }
};

subtest 'callback expiry or revocation cannot authorize the following native effect' => sub {
    for my $operation (qw(entropy_open entropy_read)) {
        for my $mode (qw(expire revoke)) {
            reset_observers(); my $s = service(); local $SELECTED = 1;
            my $wall = ns(now() + 15);
            my $error = error_from(sub { $s->register_parent(2, $wall, sub {
                return unless $_[3] eq $operation;
                if ($mode eq 'expire') { $clock_ns = $wall; }
                else { $_[0]->revoke_parent($_[1]); }
                return;
            }) });
            like($error, $mode eq 'expire' ? qr/lifetime expired/ : qr/no longer retained/, "$mode after caller check refuses original authority");
            is($opens, $operation eq 'entropy_open' ? 0 : 1, 'changed authority cannot advance a new open');
            is($NATIVE_READS, 0, 'changed authority cannot advance a new entropy read');
            if ($mode eq 'expire') { is($s->parent_observation(2)->{failure}{status}, 'timed_out', 'inclusive clock cut preserves timeout truth'); }
            else { like(error_from(sub { $s->parent_context(2) }), qr/unknown or revoked/, 'explicit revocation stays removed'); }
            $clock_ns = undef; finish($s);
        }
    }
};

subtest 'internal lifetime checks still guard each effect without an external callback' => sub {
    reset_observers(); my $s = service(); local $SELECTED = 1;
    $selected_wall = ns(now() + 15); $expire_after_open = 1;
    like(error_from(sub { $s->register_parent(2, $selected_wall) }), qr/lifetime expired/, 'expiry after actual open refuses before the next native read');
    is($opens, 1, 'actual original source was acquired before the selected clock cut');
    is($NATIVE_READS, 0, 'no-callback registration still refuses an expired read');
    is($s->parent_observation(2)->{failure}{status}, 'timed_out', 'internal admission preserves original timeout');
    $clock_ns = undef; $expire_after_open = 0; finish($s);
};

subtest 'real pending creator signal observes ready authority and closed entropy scope' => sub {
    reset_observers(); my $s = service(); local $SELECTED = 1; my ($observed, $recovered);
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select token signal';
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select token mask';
    local $SIG{USR1} = sub {
        $observed = [$s->parent_observation(2)->{state}, scalar(native_live())];
        $recovered = $s->parent_context(2);
        die "selected token publication interruption\n";
    };
    my $error = error_from(sub { $s->register_parent(2, ns(now() + 15), sub {
        CORE::kill('USR1', $$) == 1 or die 'cannot queue token creator signal' if $_[3] eq 'entropy_read';
    }) });
    like($error, qr/selected token publication interruption/, 'creator signal interrupts the completed publication return');
    is_deeply(mask_state(), [0, 1], 'original caller mask is restored');
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore token fixture mask';
    is_deeply($observed, ['ready', 0], 'actual handler observes ready authority and no live entropy source');
    ok(defined($recovered) && $recovered eq $s->parent_context(2), 'interrupted return retains the same original private context');
    finish($s);
};

subtest 'bad callback arguments and copied or inherited Service owners admit no token effects' => sub {
    reset_observers(); my $s = service(); local $SELECTED = 1;
    for my $bad (undef, 1, {}) {
        like(error_from(sub { FSM::Support::ProcessSupervisor::Endpoint::new_job_token($bad) }), qr/optional token allocation admission/, 'invalid token callback refuses');
        like(error_from(sub { $s->register_parent(2, ns(now() + 15), $bad) }), qr/optional token admission/, 'invalid Service callback refuses');
    }
    my $copy = bless {%$s}, ref($s);
    like(error_from(sub { $copy->register_parent(2, ns(now() + 15), sub { die 'copied callback ran' }) }), qr/copied service/, 'copied owner cannot invoke original token admission');
    is($opens, 0, 'argument and owner refusals allocate no entropy source');
    my $pid = fork(); die 'token inheritance fork failed' unless defined $pid;
    if (!$pid) {
        my $error = error_from(sub { $s->register_parent(2, ns(now() + 15), sub { _exit(93) }) });
        $_->discard_inherited for @services;
        _exit($error =~ /inherited service/ ? 0 : 91);
    }
    $children{$pid} = 0; my ($status, $end) = (undef, now() + 2);
    while (now() < $end) {
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid) { $status = ${^CHILD_ERROR_NATIVE}; $children{$pid} = 1; last; }
        die 'exact token child wait failed' if $w < 0;
        sleep(0.001);
    }
    ok(defined($status) && POSIX::WIFEXITED($status) && POSIX::WEXITSTATUS($status) == 0, 'exact inherited child refuses before the allocation callback');
    ok(length($s->register_parent(2, ns(now() + 15))), 'creator can still spend the original unconsumed identity');
    finish($s);
};

is_deeply(census(), $initial, 'independent endpoint census returns to original membership');
done_testing;
