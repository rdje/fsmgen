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

use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $creator = $$;
my (@owners, @clients, @pipes, @witnesses, @checks, %births, %selected);
my ($o, $selected_ticket, $clock_ns, $service_ns, $pipes, $watch, $write_mode, $write_limit,
    $write_calls, $queue_signal, $queue_throw, $check_exec_mask, $write_signal);
my @write_masks;
my %witnessed;
my $key = 'FSMGEN_PROCESS_COORDINATOR_CONTEXT';
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1_000_000_000) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
my $initial = census();
sub snapshot {
    return {type => 'SPAWN', started_ns => ns(now()), schema => 'gated.accept.fixture',
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
    is(sysread($c->handle, my $part, 1), 0, 'no further ACCEPT bytes precede EOF');
}
sub finish {
    my ($owner) = @_; $write_mode = $queue_signal = $queue_throw = $write_signal = ''; $clock_ns = $service_ns = undef; $watch = $check_exec_mask = 0;
    my ($result, $end) = (undef, now() + 5);
    while (now() < $end) { $result = $owner->close; last unless $result->{pending}; sleep(0.001); }
    ok($result && $result->{ok}, 'original aggregate cleanup completes');
    is($owner->observation->{usage}{charged_descriptors}, 0, 'all descriptor credit retires after closure');
    is($owner->observation->{usage}{charged_children}, 0, 'all child credit retires after exact waits');
    ok(!live(@pipes), 'independent original native pipe inventory is closed');
    ok(!grep(!$_, values %births), 'every actual direct child has its exact consumed wait');
    for my $fh (live(@witnesses)) {
        is(sysread($fh, my $part, 32), 0, 'independent original stdout has EOF without command output'); CORE::close($fh);
    }
    $_->close for @clients; @clients = ();
}
sub reset_observers {
    die 'previous association fixture still owns resources' if live(@pipes, @witnesses) || grep { !$_ } values %births;
    @pipes = (); @witnesses = (); @checks = (); @write_masks = ();
    $write_mode = $queue_signal = $queue_throw = $write_signal = ''; $clock_ns = $service_ns = undef;
    $pipes = $write_calls = $watch = $check_exec_mask = 0; $write_limit = 10;
}
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot read association mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0; $watch = $check_exec_mask = 0; $write_mode = $queue_signal = $queue_throw = $write_signal = ''; $clock_ns = $service_ns = undef;
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

my $guard = FSM::Support::ProcessSupervisor::Coordinator->can('_before_accept_write');
my $queue = FSM::Support::ProcessSupervisor::Service->can('queue_accept');
my $write = FSM::Support::ProcessSupervisor::Connection->can('_write_once');
my $pipe = FSM::Support::ProcessSupervisor::Reservation->can('_pipe');
my $r_fork = FSM::Support::ProcessSupervisor::Reservation->can('_fork');
my $c_fork = FSM::Support::ProcessSupervisor::GatedPair->can('_fork');
my $r_wait = FSM::Support::ProcessSupervisor::Reservation->can('_wait');
my $c_wait = FSM::Support::ProcessSupervisor::GatedPair->can('_wait');
my $child = FSM::Support::ProcessSupervisor::GatedPair->can('_child');
my $clock = FSM::Support::ProcessSupervisor::Coordinator->can('_now_ns');
my $s_clock = FSM::Support::ProcessSupervisor::Service->can('_now_ns');
my $fork = sub {
    my ($f) = @_;
    my @fixture_handles = map { @{$_->handles} } @clients;
    my $pid = $f->();
    if (defined($pid) && !$pid) {
        # These sockets model external callers, but this fixture creates them
        # in the coordinator process. Close only their inherited test copies;
        # production remains responsible for every original server/job handle.
        _exit(93) unless live(@fixture_handles) == @fixture_handles;
        $_->discard_inherited for @clients;
        _exit(94) if live(@fixture_handles);
    }
    $births{$pid} = 0 if defined($pid) && $pid > 0;
    return $pid;
};
my $wait = sub {
    my ($f, $pid) = @_; die 'unobserved gated ACCEPT child wait' unless exists $births{$pid};
    my $w = $f->($pid); $births{$pid} = 1 if $w == $pid; return $w;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Coordinator::_now_ns = sub { $clock_ns // $clock->() };
local *FSM::Support::ProcessSupervisor::Service::_now_ns = sub { $service_ns // $s_clock->() };
local *FSM::Support::ProcessSupervisor::Service::queue_accept = sub {
    my $id = $_[2];
    my $stdout = $o->{jobs}{$id}{native}{received}{stdout};
    if (defined($stdout) && defined(fileno($stdout)) && !$witnessed{refaddr($o)}{$id}++) {
        open my $fh, '<&', $stdout
            or die 'cannot retain original gated command output witness';
        push @witnesses, $fh;
    }
    $service_ns = $_[0]{records}{$_[1]}{wall}->bstr if $watch && $queue_throw eq 'expire';
    my $result = $queue->(@_);
    if ($watch) {
        die "selected original ACCEPT queue return interruption\n" if $queue_throw && $queue_throw ne 'expire';
        if ($queue_signal) { $queue_signal = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal original queue'; }
    }
    return $result;
};
local *FSM::Support::ProcessSupervisor::Coordinator::_before_accept_write = sub {
    my ($owner, $service, $ticket, $job) = @_;
    return $guard->(@_) unless $watch;
    my $peer = $owner->{peers}{$ticket};
    my $view = $owner->job_observation($peer->{job_grant});
    push @checks, [$ticket, $job, refaddr($owner->{service}) == refaddr($service) ? 1 : 0,
        $view->{admission}{phase}, $view->{native}{phase}, mask_state()];
    return 0 if $write_mode eq 'defer';
    return undef if $write_mode eq 'malformed';
    die "selected original write admission interruption\n" if $write_mode eq 'throw';
    return $guard->($owner, bless({%$service}, ref($service)), $ticket, $job) if $write_mode eq 'service';
    return $guard->($owner, $service, $ticket, $job + 1) if $write_mode eq 'job';
    my $result = $guard->(@_);
    $service_ns = $service->{records}{$ticket}{wall}->bstr if $write_mode eq 'wall';
    $service->retire($ticket) if $write_mode eq 'retire';
    return $result;
};
local *FSM::Support::ProcessSupervisor::Connection::_write_once = sub {
    my @args = @_;
    if ($watch) {
        $write_calls++; push @write_masks, mask_state();
        $args[2] = $write_limit if $args[2] > $write_limit;
    }
    my $n = $write->(@args);
    if ($watch && $write_signal && defined($n) && $n > 0) {
        $write_signal = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal actual ACCEPT write';
    }
    return $n;
};
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    $pipes++; my $ok = $pipe->(@_); push @pipes, ${$_[0]}, ${$_[1]} if $ok; return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->($r_fork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->($c_fork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($r_wait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($c_wait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_child = sub {
    if ($check_exec_mask) {
        _exit(92) unless $_[0]{exec_mask}->ismember(SIGUSR1)
            && !$_[0]{exec_mask}->ismember(SIGUSR2) && $_[0]{dispositions}{USR2} eq 'IGNORE';
    }
    return $child->(@_);
};
use warnings 'redefine';
local $SIG{ALRM} = sub { die "gated ACCEPT fixture deadline\n" }; alarm 60;

sub queued {
    my ($ticket) = @_; my $end = now() + 2;
    while (now() < $end) {
        my $view = $o->advance_request($ticket);
        return $view if $view->{publication};
        sleep(0.001);
    }
    die 'original gated ACCEPT readiness expired';
}
sub launched {
    my ($parent) = @_; my ($ticket, $c, $s) = request($parent);
    my $g = $o->admit_request($ticket); $o->start_request($ticket); queued($ticket);
    return ($ticket, $c, $g, $s);
}
sub read_bytes {
    my ($c, $count) = @_; my $bytes = ''; my $end = now() + 1;
    while (length($bytes) < $count && now() < $end) {
        my $n = sysread($c->handle, my $part, $count - length($bytes));
        if (defined($n) && $n > 0) { $bytes .= $part; next; }
        last if defined($n) && $n == 0;
        die 'unexpected native read failure' if !defined($n) && $! != EAGAIN;
        sleep(0.001);
    }
    return $bytes;
}
sub publish {
    my ($ticket, $c, $id) = @_; my $end = now() + 2;
    while (now() < $end) {
        $o->advance_service;
        my $view = $o->peer_observation($ticket);
        last if $view->{publication}{write}{published};
        sleep(0.001);
    }
    is(read_bytes($c, 10), raw(4, pack('N', $id)), 'independent native client receives the exact matching ACCEPT frame');
    ok($o->peer_observation($ticket)->{publication}{write}{published}, 'original copied publication records complete native write');
}

subtest 'matching ready root and nested requests publish literal ACCEPT without exec' => sub {
    reset_observers(); owner(); my ($ticket, $c) = request(); my $g = $o->admit_request($ticket);
    my $copy = bless {%$o}, ref($o);
    like(error_from(sub { $copy->start_request($ticket) }), qr/invalid or copied/, 'copied request starter refuses before native effects');
    like(error_from(sub { $copy->advance_request($ticket) }), qr/invalid or copied/, 'copied request advancement refuses original ownership');
    like(error_from(sub { $o->advance_request($ticket) }), qr/has not started/, 'advancement before start refuses without changing original association');
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select saved mask';
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select unblocked signal';
    {
        local $SIG{USR2} = 'IGNORE'; $check_exec_mask = 1;
        my $view;
        my $error = error_from(sub { $o->start_request($ticket); $view = queued($ticket) });
        $check_exec_mask = 0;
        is($error, '', 'actual gated command validates the original caller exec mask');
        die $error if $error;
        is($o->job_observation($g)->{native}{phase}, 'ready', 'only a ready native pair can publish its original ACCEPT');
        is($view->{publication}{job}, 2, 'ready native job binds its own Service publication');
        is($view->{publication}{write}{confirmed_bytes}, 0, 'queue publication confirms no native socket byte');
    }
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore saved mask';
    like(error_from(sub { $o->start_request($ticket) }), qr/single-use/, 'repeated start preserves the original native job');
    $watch = 1; $write_limit = 1; publish($ticket, $c, 2); $watch = 0;
    is($write_calls, 10, 'actual single-byte writes account for the complete fixed frame');
    is_deeply(\@checks, [map { [$ticket, 2, 1, 'active', 'ready', [1, 1]] } 1 .. 10], 'every actual write checks original Service grant and native readiness under the mask');
    is_deeply(\@write_masks, [map { [1, 1] } 1 .. 10], 'actual socket writes keep publication masking');
    my $view = $o->peer_observation($ticket); $view->{publication}{write}{confirmed_bytes} = 0;
    is($o->peer_observation($ticket)->{publication}{write}{confirmed_bytes}, 10, 'nested publication copies cannot rewrite confirmed bytes');
    is($o->job_observation($g)->{native}{phase}, 'ready', 'complete ACCEPT leaves the actual command gated');
    ok(!$o->job_observation($g)->{native}{command}{released}, 'complete ACCEPT alone releases no exec authority');
    my ($nested, $child_client, $child_grant) = launched(2);
    $watch = 1; $write_limit = 10; publish($nested, $child_client, 3); $watch = 0;
    is($o->job_observation($child_grant)->{admission}{parent}, 2, 'nested publication remains joined to its original bound parent');
    finish($o);
    ok($o->peer_observation($ticket)->{publication}{write}{published}, 'historical completed publication survives exact whole-run cleanup');
};

subtest 'guard deferral and original post-check walls admit no stale native byte' => sub {
    for my $mode (qw(defer wall retire malformed throw service job)) {
        reset_observers(); owner(); my ($ticket, $c) = launched();
        my $wall = $o->peer_observation($ticket)->{publication}{admission_deadline_ns};
        $watch = 1; $write_mode = $mode;
        my $error = error_from(sub { $o->advance_service }); $service_ns = undef; $write_mode = ''; $watch = 0;
        is($write_calls, 0, "$mode prevents the next actual native socket write");
        if ($mode eq 'defer') {
            is($error, '', 'boolean deferral is not a host failure');
            is($o->peer_observation($ticket)->{publication}{admission_deadline_ns}, $wall, 'deferral cannot renew the original admission wall');
            $watch = 1; publish($ticket, $c, 2); $watch = 0;
        }
        else {
            my %expected = (malformed => qr/bound-write admission must return a boolean/,
                throw => qr/selected original write admission interruption/,
                service => qr/original shared Service/, job => qr/original request\/job association/);
            like($error, $expected{$mode}, 'original callback contract error survives') if $expected{$mode};
            ok(!$o->peer_observation($ticket)->{publication}{write}{published}, 'failed original guard cannot publish complete ACCEPT');
            peer_eof($c);
        }
        finish($o);
    }
};

subtest 'partial publication refuses peer loss messages expiry and actual native death' => sub {
    for my $mode (qw(eof cancel foreign repeated wall native)) {
        reset_observers(); owner(); my ($ticket, $c, $g, $s) = launched();
        $watch = 1; $write_limit = 5; $o->advance_service;
        is(read_bytes($c, 5), substr(raw(4, pack('N', 2)), 0, 5), 'independent client retains only the actual original prefix');
        is($write_calls, 1, 'one actual prefix write occurred');
        if ($mode eq 'eof') { $c->close; }
        elsif ($mode eq 'cancel') { send_raw($c, raw(7, pack('N', 2))); }
        elsif ($mode eq 'foreign') { send_raw($c, raw(9, pack('N', 99))); }
        elsif ($mode eq 'repeated') { send_raw($c, literal($s)); }
        elsif ($mode eq 'wall') { $service_ns = $o->peer_observation($ticket)->{publication}{admission_deadline_ns}; }
        else {
            my $pair = $o->{jobs}{2}{native}{pair};
            is(CORE::kill('KILL', $pair->observation->{command_pid}), 1, 'selected actual gated command receives the exact signal');
            ok(IO::Select->new($pair->{ack})->can_read(1), 'original command acknowledgment pipe independently witnesses native loss');
        }
        if ($mode eq 'cancel' || $mode eq 'foreign' || $mode eq 'repeated') {
            # Preserve bounded header/prefix/body advancement. While the first
            # two native reads decode the prefix, owner deferral writes nothing;
            # the final pass must consume the decoded message before any write.
            $write_mode = 'defer'; $o->advance_service for 1 .. 2; $write_mode = '';
        }
        my $error = error_from(sub { $o->advance_service }); $service_ns = undef; $watch = 0;
        is($write_calls, 1, "$mode permits no byte after the original prefix");
        my $view = $o->peer_observation($ticket);
        is($view->{publication}{write}{confirmed_bytes}, 5, 'failed partial publication preserves actual confirmed byte count');
        ok(!$view->{publication}{write}{published}, 'partial ACCEPT never reports complete publication');
        is($o->job_observation($g)->{admission}{phase}, 'closing', 'original failure revokes the matching gated job');
        peer_eof($c) unless $mode eq 'eof'; finish($o);
    }
};

subtest 'pending creator signals observe queued or written original publication before return' => sub {
    for my $point (qw(queue partial complete)) {
        reset_observers(); owner(); my ($ticket, $c) = request(); $o->admit_request($ticket); $o->start_request($ticket);
        queued($ticket) unless $point eq 'queue';
        my $seen; my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select publication signal';
        defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select publication mask';
        local $SIG{USR1} = sub { $seen = $o->peer_observation($ticket); die "selected gated publication interruption\n" };
        $watch = 1; $write_limit = $point eq 'partial' ? 5 : 10;
        if ($point eq 'queue') { $queue_signal = 1; }
        else { $write_signal = 1; }
        my $error = error_from(sub { $point eq 'queue' ? queued($ticket) : $o->advance_service }); $watch = 0;
        like($error, qr/selected gated publication interruption/, 'actual creator handler interrupts the original publication return');
        is_deeply(mask_state(), [0, 1], 'original creator mask is restored');
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore publication mask';
        my $count = $point eq 'queue' ? 0 : $point eq 'partial' ? 5 : 10;
        ok($seen && $seen->{publication} && $seen->{publication}{job} == 2, 'handler sees matching retained publication rather than an unjoined numeric job');
        is($seen->{publication}{write}{confirmed_bytes}, $count, 'handler sees the exact completed native write effect');
        if ($count) { is(read_bytes($c, $count), substr(raw(4, pack('N', 2)), 0, $count), 'literal client bytes agree with interrupted publication'); }
        peer_eof($c); finish($o);
    }
};

subtest 'thrown or expired queue return retains publication and the original cause' => sub {
    for my $mode (qw(throw expire)) {
        reset_observers(); owner(); my ($ticket, $c) = request(); my $g = $o->admit_request($ticket); $o->start_request($ticket);
        $watch = 1; $queue_throw = $mode;
        my $expected = $mode eq 'throw' ? qr/selected original ACCEPT queue return interruption/ : qr/original ACCEPT admission deadline expired/;
        like(error_from(sub { queued($ticket) }), $expected, 'original queue return failure survives');
        $watch = $queue_throw = 0; $service_ns = undef;
        my $view = $o->peer_observation($ticket);
        is($view->{publication}{job}, 2, 'failed original queue still retains its matching job identity');
        if ($mode eq 'throw') { is($view->{publication}{write}{confirmed_bytes}, 0, 'failed queue return invents no confirmed socket byte'); }
        else { ok(!$view->{publication}{write}, 'expired queue leaves no fabricated Connection publication'); }
        like($view->{request}{failure}, $expected, 'retained request preserves the original queue cause');
        is($o->job_observation($g)->{admission}{phase}, 'closing', 'original queue failure revokes matching native admission');
        peer_eof($c); finish($o);
    }
};

is_deeply(census(), $initial, 'independent endpoint census returns to original membership');
done_testing;
