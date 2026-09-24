#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN ECHILD);
use IO::Select;
use Math::BigInt;
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Service ();

my $creator = $$;
my (@services, @clients, @entropy_handles, @preparation, %children);
our $active;
my ($mode, $clock_ns, $before_mask, $captured_context) = ('', undef, '', undef);
my $entropy_calls = 0;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1_000_000_000) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
my $initial = census();
sub service {
    my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run();
    my $s = FSM::Support::ProcessSupervisor::Service::new_service($run, ns(now() + 25));
    push @services, $s; return $s;
}
sub register {
    my ($s, $id, $wall) = @_;
    local $active = $s;
    return $s->register_parent($id, $wall // ns(now() + 15));
}
sub exchange {
    my ($s, $context) = @_;
    my $c = FSM::Support::ProcessSupervisor::Endpoint::connect_context($context);
    push @clients, $c;
    my $end = now() + 2;
    while (!(IO::Select->new($c->handle)->can_write(0) && $c->connection_ready)) {
        die 'parent client connect observer expired' if now() >= $end;
        $s->advance; sleep(0.001);
    }
    my @v = split /:/, $context;
    my $hello = pack('NCC', 54, 1, 1) . pack('H*', $v[2]) . pack('N', $v[3]) . pack('H*', $v[4]);
    my $ready = pack('NCC', 22, 1, 2) . pack('H*', $v[2]) . pack('N', $v[3]);
    my ($bytes, $eof) = ('', 0);
    while (length $hello) {
        die 'parent raw send observer expired' if now() >= $end;
        my $n = syswrite($c->handle, $hello, length $hello);
        if (defined($n) && $n > 0) { substr($hello, 0, $n, ''); next; }
        die 'parent raw send failed' unless !defined($n) && $! == EAGAIN;
        $s->advance;
    }
    while (now() < $end) {
        $s->advance;
        my $n = sysread($c->handle, my $part, 26 - length $bytes);
        if (defined $n) { if (!$n) { $eof = 1; last; } $bytes .= $part; last if length($bytes) == 26; }
        else { die 'parent raw receive failed' unless $! == EAGAIN; }
        sleep(0.001);
    }
    die 'parent authentication observer expired' unless $eof || length($bytes) == 26;
    # Never emit contexts, random tokens or raw frames, even on a control failure.
    return {accepted => $bytes eq $ready ? 1 : 0, empty_eof => $eof && !length($bytes) ? 1 : 0};
}
sub finish {
    my ($s) = @_; my $path = repository_root() . '/' . $s->{run}{directory};
    ok($s->close->{ok}, 'original service closes completely');
    ok(!-e $path, 'independent exact endpoint is absent');
}
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot inspect parent mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0; $active = undef; $mode = ''; $before_mask = ''; $clock_ns = undef;
        for my $pid (keys %children) {
            next if $children{$pid}; my $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid || ($w == -1 && $! == ECHILD)) { $children{$pid} = 1; next; }
            die 'parent fixture lost exact child' unless $w == 0;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) {
                if (CORE::waitpid($pid, WNOHANG) == $pid) { $children{$pid} = 1; last; }
                sleep(0.001);
            }
            die 'parent fixture child rescue expired' unless $children{$pid};
        }
        for my $s (@services) {
            eval { $s->close };
            for my $r (values %{$s->{records}}) { CORE::close($r->{handle}) if $r->{handle} && defined fileno($r->{handle}); }
            eval { $s->{run}->close };
        }
        eval { $_->close } for @clients;
        CORE::close($_) for grep { defined fileno($_) } @entropy_handles;
    }
}

my $token = FSM::Support::ProcessSupervisor::Endpoint->can('new_job_token');
my $context_for = FSM::Support::ProcessSupervisor::Endpoint->can('context_for');
my $seal = FSM::Support::ProcessSupervisor::Endpoint->can('_seal_handle');
my $mask = FSM::Support::ProcessSupervisor::Reservation->can('_mask');
my $clock = FSM::Support::ProcessSupervisor::Service->can('_now_ns');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { $clock_ns // $clock->() };
local *FSM::Support::ProcessSupervisor::Endpoint::_seal_handle = sub {
    push @entropy_handles, $_[0] if $active;
    return $seal->(@_);
};
local *FSM::Support::ProcessSupervisor::Endpoint::new_job_token = sub {
    ++$entropy_calls;
    if ($active) {
        my $id = $active->{high_parent}; my $r = $active->{parents}{$id};
        push @preparation, [$id, $r ? $r->{state} : undef,
            scalar grep { defined fileno($_) } @entropy_handles];
    }
    die "selected token effect refused\n" if $mode eq 'token_before';
    my $value = $token->(@_);
    die "selected token return lost\n" if $mode eq 'token_after';
    if ($mode eq 'expire_token') { $clock_ns = $active->{parents}{$active->{high_parent}}{deadline}->bstr; }
    if ($mode eq 'signal') { CORE::kill('USR1', $$) == 1 or die 'cannot queue parent signal'; }
    return $value;
};
local *FSM::Support::ProcessSupervisor::Endpoint::context_for = sub {
    my $value = $context_for->(@_);
    if ($active && $_[1] != 1) {
        $captured_context = $value;
        die "selected context return lost\n" if $mode eq 'context_after';
        if ($mode eq 'expire_context') { $clock_ns = $active->{parents}{$_[1]}{deadline}->bstr; }
    }
    return $value;
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($before_mask && $_[0] == SIG_BLOCK) {
        $before_mask = ''; CORE::kill('USR1', $$) == 1 or die 'cannot queue parent pre-mask signal';
    }
    return $mask->(@_);
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "parent context fixture deadline\n" }; alarm 40;

subtest 'original parent preparation precedes entropy and context remains recoverable' => sub {
    my $s = service(); my $root = $s->context; my $deadline = ns(now() + 15); @preparation = ();
    my $encoded = register($s, 2, $deadline);
    is_deeply(\@preparation, [[2, 'preparing', 0]], 'original parent identity and preparing state precede the entropy effect');
    is_deeply($s->parent_observation(2), {parent => 2, state => 'ready', deadline_ns => $deadline, failure => undef}, 'copied observation contains preparation metadata only');
    my $copy = $s->parent_observation(2); $copy->{state} = 'failed';
    is($s->parent_observation(2)->{state}, 'ready', 'copied state cannot alter original publication');
    my $calls = $entropy_calls;
    ok($encoded eq $s->parent_context(2), 'recovery returns the same original opaque authority');
    ok($s->context eq $root && $s->parent_context(1) eq $root, 'original root context is unchanged');
    is($entropy_calls, $calls, 'recovery creates no replacement token');
    is_deeply(exchange($s, $encoded), {accepted => 1, empty_eof => 0}, 'literal native HELLO authenticates the original prepared parent');
    like(error_from(sub { register($s, 2) }), qr/reused/, 'successful identity cannot be registered twice');
    $s->revoke_parent(2);
    like(error_from(sub { $s->parent_context(2) }), qr/revoked/, 'revoked original context is no longer recoverable');
    is_deeply(exchange($s, $encoded), {accepted => 0, empty_eof => 1}, 'actual replay after revocation gets empty EOF');
    finish($s);
};

subtest 'actual creator signal observes complete context before interrupted return' => sub {
    my $s = service(); my ($observed, $recovered);
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select parent caller mask';
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select blocked parent signal';
    local $SIG{USR1} = sub {
        $observed = $s->parent_observation(2);
        $recovered = $s->parent_context(2);
        die "selected parent publication interruption\n";
    };
    $mode = 'signal'; my $error = error_from(sub { register($s, 2) }); $mode = '';
    like($error, qr/selected parent publication interruption/, 'real creator handler interrupts the published return');
    is_deeply(mask_state(), [0, 1], 'original caller signal mask survives interruption');
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore parent fixture mask';
    is($observed->{state}, 'ready', 'handler sees complete original preparation');
    my $again = eval { $s->parent_context(2) };
    ok(defined($recovered) && defined($again) && $recovered eq $again, 'original ready context survives the lost return without re-registration');
    ok(!(grep { defined fileno($_) } @entropy_handles), 'all actual entropy handles closed before publication');
    is_deeply(exchange($s, $again), {accepted => 1, empty_eof => 0}, 'actual peer authenticates recovered original context');
    finish($s);
};

subtest 'failed token or context preparation retains bounded unusable identity' => sub {
    for my $cut (qw(token_before token_after context_after expire_token expire_context)) {
        my $s = service(); my $deadline = ns(now() + 15); $captured_context = undef;
        $mode = $cut; my $error = error_from(sub { register($s, 2, $deadline) }); $mode = ''; $clock_ns = undef;
        ok(length($error), "$cut refuses parent publication");
        my $seen = $s->parent_observation(2);
        is($seen->{state}, 'failed', 'original partial preparation remains failed');
        is($seen->{deadline_ns}, $deadline, 'failure cannot renew the original wall');
        is($seen->{failure}{status}, $cut =~ /expire/ ? 'timed_out' : 'host_error', 'first preparation cause retains its correct class');
        my $failure = $seen->{failure}; $failure->{status} = 'forged';
        isnt($s->parent_observation(2)->{failure}{status}, 'forged', 'copied failure cannot rewrite the original');
        like(error_from(sub { $s->parent_context(2) }), qr/not complete/, 'failed preparation publishes no context');
        like(error_from(sub { register($s, 2) }), qr/reused/, 'partial identity remains spent');
        is($s->counts->{parents}, 2, 'failed parent consumes its bounded logical slot');
        if (defined $captured_context) {
            is_deeply(exchange($s, $captured_context), {accepted => 0, empty_eof => 1}, 'actual partially constructed context cannot authenticate a failed parent');
        }
        ok(!(grep { defined fileno($_) } @entropy_handles), 'failed native preparation leaves no entropy descriptor');
        $s->revoke_parent(2); is($s->counts->{parents}, 1, 'explicit revocation releases the failed logical slot');
        finish($s);
    }
};

subtest 'pre-mask changes and invalid lifetime refuse before another entropy effect' => sub {
    for my $cut (qw(reenter revoke expire)) {
        my $s = service(); my ($inside, $error); my $deadline = ns(now() + 15); my $calls = $entropy_calls;
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select parent pre-mask signal';
        local $SIG{USR1} = sub {
            if ($cut eq 'reenter') { $inside = register($s, 2, $deadline); }
            elsif ($cut eq 'revoke') { $s->revoke_parent(1); }
            else { $clock_ns = $deadline; }
        };
        $before_mask = 1; $error = error_from(sub { register($s, 2, $deadline) }); $before_mask = '';
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore parent pre-mask signal';
        $clock_ns = undef;
        ok(length($error), "$cut refuses stale outer registration");
        is($entropy_calls - $calls, $cut eq 'reenter' ? 1 : 0, 'only the independently completed inner admission may generate authority');
        if ($cut eq 'reenter') { ok($inside eq $s->parent_context(2), 'outer stale call cannot overwrite the inner original context'); }
        elsif ($cut eq 'expire') { is($s->{high_parent}, 1, 'invalid lifetime consumes no identity before effects'); }
        finish($s);
    }
    my $s = service(); my $calls = $entropy_calls;
    like(error_from(sub { register($s, 2, ns(now() + 60)) }), qr/invalid parent lifetime/, 'parent cannot extend the original run');
    is($entropy_calls, $calls, 'invalid future lifetime reaches no entropy effect');
    is($s->{high_parent}, 1, 'pre-effect rejection preserves original identity frontier');
    finish($s);
};

subtest 'failed slots preserve inclusive capacity and spent identity monotonicity' => sub {
    my $s = service(); $mode = 'token_after';
    for my $id (2 .. 8) { ok(length(error_from(sub { register($s, $id) })), 'selected partial token return retains its failed slot'); }
    $mode = ''; is($s->counts->{parents}, 8, 'original root plus failed preparations fill the inclusive bound');
    my $calls = $entropy_calls;
    like(error_from(sub { register($s, 9) }), qr/capacity/, 'first excess refuses before token generation');
    is($entropy_calls, $calls, 'full logical capacity has no entropy effect');
    $s->revoke_parent(2);
    ok(defined register($s, 9), 'freed logical slot admits a fresh higher identity');
    like(error_from(sub { register($s, 2) }), qr/reused/, 'revoked identity cannot re-enter a freed slot');
    finish($s);
};

subtest 'expired or closed endpoint cannot recover ready authority' => sub {
    my $s = service(); my $deadline = ns(now() + 15); register($s, 2, $deadline);
    $clock_ns = $deadline;
    like(error_from(sub { $s->parent_context(2) }), qr/lifetime expired/, 'exact original boundary refuses ready-context recovery');
    is($s->parent_observation(2)->{state}, 'ready', 'preparation observation remains a historical fact');
    $clock_ns = undef;
    ok($s->{run}->close->{ok}, 'fixture retires the actual endpoint independently');
    like(error_from(sub { $s->parent_context(2) }), qr/endpoint.*not.*ready|endpoint.*no longer ready/, 'closed actual endpoint refuses retained context');
    finish($s);
};

subtest 'copied and inherited services cannot publish or recover creator contexts' => sub {
    my $s = service(); register($s, 2); my $copy = bless {%$s}, ref($s);
    for my $method (qw(parent_context parent_observation)) {
        like(error_from(sub { $copy->$method(2) }), qr/copied service/, 'copied owner cannot inspect original parent authority');
    }
    like(error_from(sub { register($copy, 3) }), qr/copied service/, 'copied owner cannot register another parent');
    my $pid = fork(); die 'cannot fork inherited parent oracle' unless defined $pid;
    if (!$pid) {
        my $error = error_from(sub { $s->parent_context(2) });
        my $prepare = error_from(sub { register($s, 3) });
        $s->discard_inherited;
        _exit($error =~ /inherited/ && $prepare =~ /inherited/ ? 0 : 1);
    }
    $children{$pid} = 0; my ($status, $end) = (undef, now() + 2);
    while (now() < $end) {
        if (CORE::waitpid($pid, WNOHANG) == $pid) { $status = $?; $children{$pid} = 1; last; }
        sleep(0.001);
    }
    is($status, 0, 'exact native child wait confirms inherited authority refusal');
    is_deeply(exchange($s, $s->parent_context(2)), {accepted => 1, empty_eof => 0}, 'original creator authority survives inherited discard');
    finish($s);
};

is_deeply(census(), $initial, 'independent final endpoint census matches its predecessor');
done_testing;
