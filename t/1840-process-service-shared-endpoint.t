#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EIO ECHILD);
use IO::Select;
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Service ();

my (@runs, @services, @clients, @accepted, %identities, %children);
my ($queue_signal, $before_mask, $throw_close, $deny_close, $close_calls) = (0, 0, 0, 0, 0);
my $creator = $$;
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1e9) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
sub service {
    my ($shared) = @_;
    my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run(); push @runs, $run;
    my $constructor = $shared ? 'new_shared_service' : 'new_service';
    my $s = FSM::Support::ProcessSupervisor::Service->can($constructor)->($run, ns(now() + 20));
    push @services, $s;
    my $path = repository_root() . '/' . $run->{directory};
    $identities{refaddr($s)} = [map { [$_, [lstat($_)]] } ("$path/s", $path)];
    return $s;
}
sub client {
    my ($s) = @_;
    my $c = FSM::Support::ProcessSupervisor::Endpoint::connect_context($s->context); push @clients, $c;
    my $end = now() + 2;
    while (now() < $end) {
        return $c if IO::Select->new($c->handle)->can_write(0) && $c->connection_ready;
        sleep(0.001);
    }
    die 'shared endpoint client observer expired';
}
sub accepted_peer {
    my ($s) = @_;
    my $count = $s->counts->{open}; my $c = client($s); my $end = now() + 2;
    while (now() < $end) {
        $s->advance;
        return $c if $s->counts->{open} == $count + 1;
        sleep(0.001);
    }
    die 'shared endpoint accept observer expired';
}
sub retained_endpoint {
    my ($s) = @_;
    for my $entry (@{$identities{refaddr($s)}}) {
        my @actual = lstat($entry->[0]);
        is_deeply([@actual[0,1,2,4]], [@{$entry->[1]}[0,1,2,4]], 'original endpoint identity remains unchanged');
    }
    is(scalar @{$s->{run}->handles}, 2, 'aggregate owner retains listener and directory handles');
    is_deeply([sort map { refaddr($_) } @{$s->handles}],
        [sort map { refaddr($_) } @{$s->{run}->handles}], 'closed shared service reports only the borrowed run inventory');
}
sub close_shared {
    my ($s) = @_;
    my $result = $s->close;
    ok($result->{ok} && $result->{endpoint_retained}, 'shared admission closure settles accepted peers and retains endpoint');
    ok(!$result->{socket_removed} && !$result->{directory_removed}, 'shared close makes no endpoint-removal claim');
    is($s->counts->{parents}, 0, 'every parent authority is revoked');
    is($s->counts->{open}, 0, 'every accepted peer is closed');
    ok(!live(@accepted), 'independent actual accepted-descriptor inventory is closed');
    like(error_from(sub { $s->context }), qr/no longer live/, 'closed service cannot publish root authority');
    retained_endpoint($s);
    is_deeply($s->close, $result, 'completed service close is idempotent');
    return $result;
}
sub retire_run {
    my ($s) = @_;
    ok($s->{run}->close->{ok}, 'aggregate owner retires the original endpoint separately');
    ok(!grep(lstat($_->[0]), @{$identities{refaddr($s)}}), 'independent original endpoint paths are absent');
    is(scalar @{$s->handles}, 0, 'closed borrowed inventory follows actual endpoint retirement');
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0;
        for my $pid (keys %children) {
            next if $children{$pid};
            my $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid || ($w == -1 && $! == ECHILD)) { $children{$pid} = 1; next; }
            die 'fixture lost exact inherited child ownership' unless $w == 0;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) {
                if (CORE::waitpid($pid, WNOHANG) == $pid) { $children{$pid} = 1; last; }
                sleep(0.001);
            }
            die 'fixture exact child rescue expired' unless $children{$pid};
        }
        # A negative control may deliberately break Service::close. Consume
        # that verdict without making fixture teardown depend on the broken
        # operation; the independent handles and original endpoints still own
        # their exact native cleanup, never a forged service success.
        for my $s (@services) {
            my $ok = eval { $s->close; 1 };
            diag('independent fixture teardown after failed service close') unless $ok;
        }
        close $_ for live(@accepted);
        for my $endpoint (@clients, @runs) {
            die 'independent original endpoint cleanup failed' unless $endpoint->close->{ok};
        }
    }
}

my $accept = FSM::Support::ProcessSupervisor::Service->can('_accept_once');
my $close = FSM::Support::ProcessSupervisor::Connection->can('close');
my $mask = FSM::Support::ProcessSupervisor::Reservation->can('_mask');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Service::_accept_once = sub {
    my $peer = $accept->(@_); push @accepted, ${$_[0]} if defined $peer; return $peer;
};
local *FSM::Support::ProcessSupervisor::Connection::close = sub {
    ++$close_calls;
    my $result = $close->(@_);
    if ($queue_signal) { $queue_signal = 0; CORE::kill('USR1', $$) == 1 or die 'cannot queue actual close interruption'; }
    if ($throw_close) { $throw_close = 0; die "fixture interrupts close after native effect\n"; }
    return $deny_close ? 0 : $result;
};
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($before_mask && $_[0] == SIG_BLOCK) {
        $before_mask = 0; CORE::kill('USR1', $$) == 1 or die 'cannot select pre-mask service close';
    }
    return $mask->(@_);
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "shared service fixture deadline\n" }; alarm 30;

subtest 'shared service retains exact endpoint custody and standalone still retires it' => sub {
    my $before = census(); my $s = service(1); accepted_peer($s); accepted_peer($s);
    is($s->counts->{connections}, 2, 'actual accepted peers are retained');
    close_shared($s);
    is($s->counts->{connections}, 2, 'closed peer outcomes keep their slots until consumed');
    my $outcome = $s->take_closed;
    is($outcome->{status}, 'cancelled', 'consumed outcome preserves service cancellation');
    is($s->counts->{connections}, 1, 'exactly one consumed outcome releases its slot');
    retire_run($s); is_deeply(census(), $before, 'shared endpoint census returns to predecessor');
    $s = service(0); accepted_peer($s);
    my $result = $s->close;
    ok($result->{ok} && $result->{socket_removed} && $result->{directory_removed}, 'default standalone service still owns complete endpoint retirement');
    is(scalar @{$s->handles}, 0, 'standalone service leaves no native handles');
    is_deeply(census(), $before, 'standalone endpoint census returns to predecessor');
};

subtest 'expiry revocation and fatal accept close authority without retiring a shared run' => sub {
    for my $mode (qw(expire revoke accept)) {
        my $s = service(1); accepted_peer($s);
        if ($mode eq 'expire') {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { $s->{deadline}->bstr };
            $s->advance;
        }
        elsif ($mode eq 'revoke') { $s->revoke_parent(1); }
        else {
            client($s);
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::Service::_accept_once = sub { $! = EIO; return undef; };
            $s->advance;
        }
        is($s->failure->{status}, $mode eq 'expire' ? 'timed_out' : $mode eq 'revoke' ? 'authority_revoked' : 'host_error',
            "$mode retains its first service failure");
        my $first = $s->failure; close_shared($s);
        is_deeply($s->failure, $first, 'resource cleanup does not replace the original failure');
        retire_run($s);
    }
};

subtest 'actual pending close signals see complete ownership publication' => sub {
    for my $shared (0, 1) {
        my $s = service($shared); accepted_peer($s); accepted_peer($s); my $observed;
        local $SIG{USR1} = sub {
            $observed = {counts => $s->counts, accepted => scalar(live(@accepted)),
                cleanup => $s->{cleanup} ? {%{$s->{cleanup}}} : undef,
                endpoint => $s->{run}->observation};
            die "creator interrupted complete service close\n";
        };
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select caller mask';
        $queue_signal = 1; my $before = $close_calls;
        my $error = error_from(sub { $s->close });
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore caller mask';
        $queue_signal = 0;
        like($error, qr/creator interrupted complete service close/, 'real pending handler interrupts only the completed return');
        is_deeply($observed->{counts}, {parents => 0, connections => 2, open => 0}, 'handler sees all authority revoked and closed outcomes retained');
        is($observed->{accepted}, 0, 'handler sees every actual accepted descriptor closed');
        ok($observed->{cleanup} && $observed->{cleanup}{ok}, 'handler sees complete cleanup publication');
        is($observed->{endpoint}{closed}, $shared ? 0 : 1, 'handler sees the selected endpoint lifetime');
        ok($s->close->{ok}, 'original complete close result remains recoverable');
        is($close_calls - $before, 2, 'interrupted return does not repeat actual peer close calls');
        if ($shared) { retained_endpoint($s); retire_run($s); }
    }
};

subtest 'pre-mask close and interrupted native close cannot strand publication' => sub {
    my $s = service(1); accepted_peer($s); my $before = $close_calls;
    my $nested;
    local $SIG{USR1} = sub { $nested = $s->close };
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select reentrant mask';
    $before_mask = 1; my $result = $s->close;
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore reentrant mask';
    ok($nested->{ok} && $result->{ok}, 'actual pre-mask handler can complete the original service');
    is($close_calls - $before, 1, 'masked recheck prevents a stale outer duplicate close');
    retire_run($s);
    $s = service(1); accepted_peer($s); accepted_peer($s);
    $throw_close = 1;
    like(error_from(sub { $s->close }), qr/fixture interrupts close after native effect/, 'synchronous interruption follows an actual retained close');
    ok(!$s->{cleanup}, 'partly closed service publishes no completed cleanup result');
    is($s->counts->{parents}, 0, 'partial cleanup already revoked authority');
    close_shared($s); retire_run($s);
};

subtest 'uncertain accepted closure remains failed while the aggregate endpoint stays retained' => sub {
    my $s = service(1); accepted_peer($s); $deny_close = 1;
    my $result = $s->close; $deny_close = 0;
    ok(!$result->{ok}, 'reported accepted closure uncertainty is preserved');
    is($s->failure->{status}, 'cleanup_failed', 'uncertainty remains the first cleanup failure');
    ok(!live(@accepted), 'actual descriptors closed despite the refused success report');
    retained_endpoint($s);
    ok(!$s->close->{ok}, 'retry cannot forge a completed accepted closure');
    retire_run($s);
};

subtest 'copied and inherited service records cannot retire creator ownership' => sub {
    my $s = service(1); accepted_peer($s);
    my $copy = bless {%$s}, ref($s);
    like(error_from(sub { $copy->close }), qr/copied service/, 'copied service cannot close original native custody');
    is($s->counts->{open}, 1, 'copy refusal leaves the original accepted peer alive');
    my @run_handles = @{$s->{run}->handles};
    my $pid = fork(); die 'cannot fork inherited ownership oracle' unless defined $pid;
    if (!$pid) {
        my $error = error_from(sub { $s->close }); $s->discard_inherited;
        _exit($error =~ /inherited/ && !live(@accepted, @run_handles) ? 0 : 1);
    }
    $children{$pid} = 0; my ($status, $end) = (undef, now() + 2);
    while (now() < $end) {
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid) { $children{$pid} = 1; $status = $?; last; }
        die 'lost exact inherited oracle wait' if $w == -1;
        sleep(0.001);
    }
    is($status, 0, 'actual inherited copy rejects creator cleanup and discards only child descriptors');
    close_shared($s); retire_run($s);
};

done_testing;
