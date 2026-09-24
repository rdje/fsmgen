#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN ECHILD);
use IO::Select;
use Math::BigInt;
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG _exit);
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;

our ($WATCH, $READS) = (0, 0);
BEGIN {
    no warnings qw(once redefine);
    *CORE::GLOBAL::sysread = sub {
        $READS++ if $WATCH && -c $_[0];
        return @_ == 4 ? CORE::sysread($_[0], $_[1], $_[2], $_[3]) : CORE::sysread($_[0], $_[1], $_[2]);
    };
}
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $creator = $$;
my (@owners, @clients, @pipes, @entropy, @witnesses, @checks, %births, %selected);
my ($o, $selected_ticket, $fault, $cut, $interrupt, $throw_at, $clock_ns, $service_ns, $opens, $pipes, $before_mask);
my $key = 'FSMGEN_PROCESS_COORDINATOR_CONTEXT';
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1_000_000_000) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
my $initial = census();
sub snapshot {
    return {type => 'SPAWN', started_ns => ns(now()), schema => 'association.fixture',
        stage => 'probe', containment => 'fixture-group', cwd => '.', umask => 0027,
        timeout_seconds => $_[0] // 40, capture_limit_bytes => 64,
        argv => [$^X, '-e', 'syswrite STDOUT,"FORBIDDEN"', '', "high\xff\n"],
        environment => [['A', ''], ['B', "space\nand newline"]]};
}
sub bytes { pack('N', length($_[0])) . $_[0] }
sub raw { pack('NCC', length($_[1]) + 2, 1, $_[0]) . $_[1] }
sub literal {
    my ($s) = @_;
    my ($hi, $lo) = Math::BigInt->new($s->{started_ns})->bdiv(4_294_967_296);
    return raw(3, pack('NN', $hi->numify, $lo->numify)
        . join('', map { bytes($s->{$_}) } qw(schema stage containment cwd))
        . pack('NNNN', $s->{timeout_seconds}, $s->{capture_limit_bytes}, $s->{umask}, scalar @{$s->{argv}})
        . join('', map { bytes($_) } @{$s->{argv}}) . pack('N', scalar @{$s->{environment}})
        . join('', map { bytes($_->[0]) . bytes($_->[1]) } @{$s->{environment}}));
}
sub until_value {
    my ($read) = @_; my $end = now() + 2;
    while (now() < $end) { $o->advance_service; my $v = $read->(); return $v if defined $v; sleep(0.001); }
    die 'association native observer expired';
}
sub send_raw {
    my ($c, $raw) = @_; my $end = now() + 2;
    while (length($raw) && now() < $end) {
        my $n = syswrite($c->handle, $raw);
        if (defined($n) && $n > 0) { substr($raw, 0, $n, ''); next; }
        die 'association raw write refused' unless !defined($n) && $! == EAGAIN;
        sleep(0.001);
    }
    die 'association raw write expired' if length $raw;
}
sub ready {
    my ($g) = @_; $o->prepare_job($g); $o->start_job($g); my $end = now() + 3;
    while (now() < $end) {
        my $v = $o->advance_job($g); return if $v->{native}{phase} eq 'ready';
        die 'association original gated handoff refused' if $v->{admission}{phase} eq 'closing';
        sleep(0.001);
    }
    die 'association original gated handoff expired';
}
sub owner {
    $o = FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot => snapshot());
    push @owners, $o; $o->open_run; ready($o->root);
    open my $fh, '<&', $o->{jobs}{1}{native}{received}{stdout} or die 'cannot retain original output witness';
    push @witnesses, $fh;
    return $o->root;
}
sub request {
    my ($parent, $s) = @_; $parent //= 1; $s //= snapshot(20);
    my $context = $o->{service}->parent_context($parent);
    my $c = FSM::Support::ProcessSupervisor::Endpoint::connect_context($context); push @clients, $c;
    until_value(sub { IO::Select->new($c->handle)->can_write(0) && $c->connection_ready ? 1 : undef });
    my @v = split /:/, $context;
    send_raw($c, raw(1, pack('H*', $v[2]) . pack('N', $v[3]) . pack('H*', $v[4])));
    my $ready = '';
    until_value(sub {
        my $n = sysread($c->handle, my $part, 26 - length $ready); $ready .= $part if defined($n) && $n > 0;
        return length($ready) == 26 ? 1 : undef;
    });
    ok($ready eq raw(2, pack('H*', $v[2]) . pack('N', $v[3])), 'literal socket handshake authenticates the original parent');
    send_raw($c, literal($s));
    my $ticket = until_value(sub {
        for my $id (@{$o->peer_tickets}) {
            return $id if $o->peer_observation($id)->{transport}{state} eq 'request' && !$selected{refaddr($o)}{$id};
        }
        return;
    });
    $selected{refaddr($o)}{$ticket} = 1;
    return ($ticket, $c, $s);
}
sub peer_eof {
    my ($c) = @_;
    ok(IO::Select->new($c->handle)->can_read(1), 'original socket observes closure');
    is(sysread($c->handle, my $part, 1), 0, 'no ACCEPT or other unexpected bytes precede EOF');
}
sub finish {
    my ($owner) = @_; $fault = $cut = $interrupt = $throw_at = $before_mask = ''; $clock_ns = $service_ns = undef; $WATCH = 0;
    my ($result, $end) = (undef, now() + 5);
    while (now() < $end) { $result = $owner->close; last unless $result->{pending}; sleep(0.001); }
    ok($result && $result->{ok}, 'original aggregate cleanup completes');
    is($owner->observation->{usage}{charged_descriptors}, 0, 'all descriptor credit retires after closure');
    is($owner->observation->{usage}{charged_children}, 0, 'all child credit retires after exact waits');
    ok(!live(@pipes, @entropy), 'independent native pipe and weak entropy inventories are closed');
    ok(!grep(!$_, values %births), 'every actual direct child has its exact consumed wait');
    for my $fh (live(@witnesses)) {
        is(sysread($fh, my $part, 32), 0, 'independent original stdout has EOF without command output'); CORE::close($fh);
    }
    $_->close for @clients; @clients = ();
}
sub reset_observers {
    die 'previous association fixture still owns resources' if live(@pipes, @entropy, @witnesses) || grep { !$_ } values %births;
    @pipes = (); @entropy = (); @witnesses = (); @checks = ();
    $fault = $cut = $interrupt = $throw_at = $before_mask = ''; $clock_ns = $service_ns = undef;
    $READS = $opens = $pipes = 0;
}
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot read association mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0; $WATCH = 0; $fault = $interrupt = $throw_at = $before_mask = ''; $clock_ns = $service_ns = undef;
        eval { $_->close } for @owners;
        for my $pid (keys %births) {
            next if $births{$pid}; my $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid || ($w == -1 && $! == ECHILD)) { $births{$pid} = 1; next; }
            die 'association fixture lost exact child' unless $w == 0;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) {
                if (CORE::waitpid($pid, WNOHANG) == $pid) { $births{$pid} = 1; last; } sleep(0.001);
            }
            die 'association child rescue expired' unless $births{$pid};
        }
        CORE::close($_) for live(@pipes, @witnesses);
        eval { $_->close } for @clients;
        eval { $_->{run}->close } for @owners;
    }
}

my $guard = FSM::Support::ProcessSupervisor::Coordinator->can('_before_context_allocation');
my $transfer = FSM::Support::ProcessSupervisor::Service->can('transfer_request');
my $seal = FSM::Support::ProcessSupervisor::Endpoint->can('_seal_handle');
my $pipe = FSM::Support::ProcessSupervisor::Reservation->can('_pipe');
my $r_fork = FSM::Support::ProcessSupervisor::Reservation->can('_fork');
my $c_fork = FSM::Support::ProcessSupervisor::GatedPair->can('_fork');
my $r_wait = FSM::Support::ProcessSupervisor::Reservation->can('_wait');
my $c_wait = FSM::Support::ProcessSupervisor::GatedPair->can('_wait');
my $clock = FSM::Support::ProcessSupervisor::Coordinator->can('_now_ns');
my $s_clock = FSM::Support::ProcessSupervisor::Service->can('_now_ns');
my $bind = FSM::Support::ProcessSupervisor::Coordinator->can('_bind_context');
my $mask = FSM::Support::ProcessSupervisor::Reservation->can('_mask');
my $fork = sub { my ($f) = @_; my $pid = $f->(); $births{$pid} = 0 if defined($pid) && $pid > 0; return $pid };
my $wait = sub {
    my ($f, $pid) = @_; die 'unobserved association child wait' unless exists $births{$pid};
    my $w = $f->($pid); $births{$pid} = 1 if $w == $pid; return $w;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Coordinator::_now_ns = sub { $clock_ns // $clock->() };
local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { $service_ns // $s_clock->() };
local *FSM::Support::ProcessSupervisor::Reservation::_mask = sub {
    if ($before_mask && $_[0] == SIG_BLOCK) {
        $before_mask = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal before association mask';
    }
    return $mask->(@_);
};
local *FSM::Support::ProcessSupervisor::Service::transfer_request = sub {
    my $result = $transfer->(@_);
    if ($WATCH) {
        die "selected original transfer return interruption\n" if $throw_at eq 'transfer';
        if ($interrupt eq 'transfer') { $interrupt = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal request transfer'; }
    }
    return $result;
};
local *FSM::Support::ProcessSupervisor::Coordinator::_before_context_allocation = sub {
    my ($owner, $grant, $service, $id, $kind, $operation) = @_;
    if ($WATCH) {
        my $job = $owner->{jobs}{$id}; my $peer = $owner->{peers}{$selected_ticket};
        push @checks, [$operation, $peer->{request_state}, $peer->{job_id},
            $peer->{job_grant} && refaddr($peer->{job_grant}) == refaddr($grant) ? 1 : 0,
            $job->{peer} && refaddr($job->{peer}) == refaddr($peer) ? 1 : 0,
            $peer->{request} && refaddr($peer->{request}{request}) == refaddr($job->{snapshot}) ? 1 : 0,
            $service->ticket_observation($selected_ticket)->{state}, mask_state()];
        if ($fault && $cut eq $operation) {
            if ($fault eq 'wall') { $clock_ns = $peer->{request}{admission_deadline_ns}; }
            elsif ($fault eq 'peer') {
                local $job->{peer} = {%$peer}; return $guard->(@_);
            }
            elsif ($fault eq 'packet') {
                local $peer->{request} = {%{$peer->{request}}}; return $guard->(@_);
            }
            elsif ($fault eq 'grant') {
                local $peer->{job_grant} = bless {}, ref($grant); return $guard->(@_);
            }
            elsif ($fault eq 'retire') { $service->retire($selected_ticket); }
            elsif ($fault eq 'parent') { $service->revoke_parent($peer->{request}{parent}); }
        }
    }
    return $guard->(@_);
};
local *FSM::Support::ProcessSupervisor::Coordinator::_bind_context = sub {
    my $result = $bind->(@_);
    die "selected original context return interruption\n" if $WATCH && $throw_at eq 'context';
    if ($WATCH && $interrupt eq 'context') { $interrupt = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal context return'; }
    return $result;
};
local *FSM::Support::ProcessSupervisor::Endpoint::_seal_handle = sub {
    if ($WATCH && -c $_[0]) { $opens++; push @entropy, $_[0]; weaken($entropy[-1]); }
    return $seal->(@_);
};
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    $pipes++; my $ok = $pipe->(@_); push @pipes, ${$_[0]}, ${$_[1]} if $ok; return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->($r_fork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->($c_fork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($r_wait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($c_wait, @_) };
use warnings 'redefine';
local $SIG{ALRM} = sub { die "request association fixture deadline\n" }; alarm 60;

subtest 'selected original request owns one child grant before actual token effects' => sub {
    reset_observers(); owner(); my ($first, $a) = request(); my ($second, $b, $s) = request(); $selected_ticket = $second;
    my $source = $o->{service}{records}{$second}{request}; my $before_pipes = $pipes; my $before_children = scalar keys %births;
    my $grant; { local $WATCH = 1; $grant = $o->admit_request($second); }
    is_deeply(\@checks, [map { [$_, 'preparing', 2, 1, 1, 1, 'handed', [1, 1]] } qw(entropy_open entropy_read)], 'original peer packet and grant precede every actual token boundary');
    is($opens, 1, 'one actual token source opened'); is($READS, 1, 'one actual token read completed');
    is($pipes, $before_pipes, 'association creates no native job pipe');
    is(scalar keys %births, $before_children, 'association creates no native child');
    is($o->peer_observation($first)->{transport}{state}, 'request', 'unselected original request retains Service custody');
    is($o->peer_observation($second)->{request}{state}, 'ready', 'matching original peer publishes completed association');
    is($o->job_observation($grant)->{admission}{parent}, 1, 'original active parent owns the child grant');
    my $context = $o->{service}->parent_context(2);
    my $expected = {%$s, environment => [@{$s->{environment}}, [$key, $context]]};
    ok(literal($o->{jobs}{2}{snapshot}) eq literal($expected), 'independent literal snapshot changes only the admitted private context');
    ok(literal($source) eq literal($s), 'transferred original snapshot bytes stay unchanged');
    ok(!exists $o->{peers}{$second}{request}{request}, 'completed binding releases the redundant source snapshot slot');
    my $view = $o->peer_observation($second); $view->{request}{job} = 99; $view->{request}{state} = 'failed';
    is($o->peer_observation($second)->{request}{job}, 2, 'copied request observation cannot rewrite original association');
    like(error_from(sub { $o->admit_request($second) }), qr/single-use/, 'repeated original ticket refuses without consuming another grant');
    is($o->peer_observation($second)->{request}{state}, 'ready', 'repeated caller cannot revoke the admitted association');
    like(error_from(sub { $o->admit_request(999) }), qr/unknown retained peer/, 'foreign ticket refuses before admission');
    ready($grant); my ($third, $c) = request(2); $selected_ticket = $third;
    my $nested = $o->admit_request($third);
    is($o->job_observation($nested)->{admission}{parent}, 2, 'literal nested socket joins its actual submitting grant');
    is($o->job_observation($nested)->{admission}{deadline_ns}, $o->{peers}{$third}{request}{deadline_ns}, 'original clipped nested execution wall is unchanged');
    finish($o);
};

subtest 'creator interruption observes complete original request association before return' => sub {
    for my $point (qw(transfer context)) {
        reset_observers(); owner(); my ($ticket, $c) = request(); $selected_ticket = $ticket; my $view;
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select signal';
        defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select mask';
        local $SIG{USR1} = sub { $view = $o->peer_observation($ticket); die "selected association signal interruption\n" };
        $interrupt = $point; my $error;
        { local $WATCH = 1; $error = error_from(sub { $o->admit_request($ticket) }); }
        like($error, qr/selected association signal interruption/, 'actual signal interrupts the original return');
        is_deeply(mask_state(), [0, 1], 'original creator mask restores');
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore signal mask';
        ok($view && $view->{request}{state} eq 'ready' && $view->{request}{job} == 2, 'handler sees completed peer and original grant association');
        is($o->job_observation($o->{peers}{$ticket}{job_grant})->{admission}{phase}, 'closing', 'interrupted return leaves the original grant revoked and recoverable');
        like($o->peer_observation($ticket)->{request}{failure}, qr/selected association signal interruption/, 'first interruption survives subsequent peer retirement');
        peer_eof($c); finish($o);
    }
};

subtest 'thrown transfer and context returns retain original custody and first failure' => sub {
    for my $point (qw(transfer context)) {
        reset_observers(); owner(); my ($ticket, $c) = request(); $selected_ticket = $ticket; $throw_at = $point;
        my $error; { local $WATCH = 1; $error = error_from(sub { $o->admit_request($ticket) }); } $throw_at = '';
        like($error, qr/selected original $point return interruption/, 'original thrown return survives');
        my $peer = $o->{peers}{$ticket}; ok($peer->{request}, 'original transferred packet remains in retained peer');
        is($peer->{request_state}, 'failed', 'thrown return cannot report ready association');
        is(!!$peer->{job_grant}, $point eq 'context' ? 1 : '', 'only a created original grant remains associated');
        is(scalar(@{$o->grants}), $point eq 'context' ? 2 : 1, 'exact original ledger inventory matches interrupted stage');
        peer_eof($c); finish($o);
    }
};

subtest 'pre-mask re-entry and retirement preserve the original peer state' => sub {
    for my $mode (qw(reenter retire)) {
        reset_observers(); owner(); my ($ticket, $c) = request(); $selected_ticket = $ticket; my $grant;
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select pre-mask signal';
        local $SIG{USR1} = sub {
            if ($mode eq 'reenter') { $grant = $o->admit_request($ticket); }
            else { $o->retire_peer($ticket); }
        };
        $before_mask = 1;
        my $error = error_from(sub { $o->admit_request($ticket) });
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore pre-mask signal';
        like($error, $mode eq 'reenter' ? qr/single-use/ : qr/private owner retired the connection/, 'fresh peer state refuses the interrupted original caller');
        if ($mode eq 'reenter') {
            is($o->peer_observation($ticket)->{request}{state}, 'ready', 're-entry association survives stale caller refusal');
            is($o->job_observation($grant)->{admission}{phase}, 'reserved', 'stale caller cannot cancel the original re-entry grant');
            is(scalar @{$o->grants}, 2, 'only the original re-entry grant exists');
        }
        else {
            ok(!$o->peer_observation($ticket)->{request}, 'retired peer acquires no request association');
            is(scalar @{$o->grants}, 1, 'retired peer creates no child grant');
            peer_eof($c);
        }
        finish($o);
    }
};

subtest 'original identity and inclusive admission cuts refuse before selected entropy' => sub {
    for my $mode (qw(peer packet grant wall retire parent)) {
        for my $operation (qw(entropy_open entropy_read)) {
            reset_observers(); owner(); my ($ticket, $c) = request(); $selected_ticket = $ticket; $fault = $mode; $cut = $operation;
            my $error; { local $WATCH = 1; $error = error_from(sub { $o->admit_request($ticket) }); }
            $fault = ''; $clock_ns = undef;
            like($error, qr/original retained peer|original transferred packet|foreign, copied|admission deadline expired|private owner retired|authority|no longer handed|closes/, "$mode refuses the original request effect boundary");
            is($opens, $operation eq 'entropy_open' ? 0 : 1, 'no unadmitted entropy source opens');
            is($READS, 0, 'no unadmitted actual entropy read occurs');
            my $peer = $o->{peers}{$ticket};
            is($peer->{job_id}, 2, 'spent original identity remains associated despite refused effect');
            is($peer->{request_state}, 'failed', 'failed original request remains inspectable');
            ok(!$o->{jobs}{2}{native}, 'refusal creates no child native graph');
            peer_eof($c); finish($o);
        }
    }
};

subtest 'capacity and pre-transfer expiry refuse with exact retained ownership' => sub {
    for my $mode (qw(capacity expiry)) {
        reset_observers(); my $root = owner(); my ($ticket, $c) = request(); $selected_ticket = $ticket;
        if ($mode eq 'capacity') { $o->reserve_job(parent => $root, snapshot => snapshot(15)) for 1 .. 7; }
        else { $service_ns = $o->{service}{records}{$ticket}{wall}->bstr; }
        my $before = scalar @{$o->grants}; my $error;
        { local $WATCH = 1; $error = error_from(sub { $o->admit_request($ticket) }); } $service_ns = undef;
        like($error, qr/job capacity exhausted|original request admission deadline expired/, 'original limiting cause survives refusal');
        is(scalar(@{$o->grants}), $before, 'refusal adds no unowned original ledger grant');
        is($READS, 0, 'refusal performs no token read');
        ok(!$o->{peers}{$ticket}{job_grant}, 'no nonexistent grant is associated');
        peer_eof($c); finish($o);
    }
};

subtest 'peer EOF or repeated request revokes its associated grant before preparation' => sub {
    for my $mode (qw(eof repeated retire)) {
        reset_observers(); owner(); my ($ticket, $c, $s) = request(); my $grant = $o->admit_request($ticket);
        if ($mode eq 'eof') { $c->close; }
        elsif ($mode eq 'repeated') { send_raw($c, literal($s)); }
        else { $o->retire_peer($ticket); }
        until_value(sub { $o->peer_observation($ticket)->{transport}{state} eq 'closed' ? 1 : undef });
        is($o->peer_observation($ticket)->{request}{state}, 'failed', 'observed peer closure marks the original request failed');
        is($o->job_observation($grant)->{admission}{phase}, 'closing', 'original peer failure revokes its original child');
        my $count = $pipes;
        like(error_from(sub { $o->prepare_job($grant) }), qr/single-use/, 'closed original peer cannot start native preparation');
        is($pipes, $count, 'no pipe follows recorded peer closure');
        peer_eof($c) unless $mode eq 'eof'; finish($o);
    }
};

subtest 'copied and inherited aggregate owners cannot consume a request' => sub {
    reset_observers(); owner(); my ($ticket, $c) = request();
    my $copy = bless {%$o}, ref($o);
    like(error_from(sub { $copy->admit_request($ticket) }), qr/invalid or copied coordinator/, 'copied aggregate refuses original ticket');
    like(error_from(sub { $copy->_reserve_job($o->root, snapshot(10)) }), qr/invalid or copied coordinator/, 'copied internal owner refuses before shared reservation');
    is(scalar @{$o->grants}, 1, 'copied helper cannot spend original ledger grant');
    my $pid = CORE::fork(); die 'cannot fork inherited association control' unless defined $pid;
    if (!$pid) { my $e = error_from(sub { $o->admit_request($ticket) }); _exit($e =~ /inherited coordinator/ ? 0 : 91); }
    $births{$pid} = 0; my $end = now() + 2;
    while (now() < $end) {
        if (CORE::waitpid($pid, WNOHANG) == $pid) { $births{$pid} = 1; is($?, 0, 'exact inherited child confirms refusal'); last; }
        sleep(0.001);
    }
    ok($births{$pid}, 'exact inherited child wait is consumed');
    is($o->peer_observation($ticket)->{transport}{state}, 'request', 'original request remains unconsumed after foreign owners');
    ok($o->admit_request($ticket), 'original creator still admits its own request'); finish($o);
};

is_deeply(census(), $initial, 'independent endpoint census returns to original membership');
done_testing;
