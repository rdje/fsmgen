#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(EAGAIN ECHILD);
use IO::Select;
use POSIX qw(SIG_UNBLOCK SIG_SETMASK SIGUSR1 WNOHANG _exit);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(sleep);
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $creator = $$;
my (@owners, @clients, @accepted, @pipes, @witnesses, @foreign, %births, %waits, %endpoints);
my ($owner, $ticket, $cut, $signal_at, $fail_fork, $consume_throw) = (undef, undef, '', '', '', 0);
my ($accepts, $admissions, $expire_accept) = (0, 0, 0);
my $class = 'FSM::Support::ProcessSupervisor::Coordinator';
my $reservation = 'FSM::Support::ProcessSupervisor::Reservation';
my $pair = 'FSM::Support::ProcessSupervisor::GatedPair';
my $now_ns = FSM::Support::ProcessSupervisor::Admission->can('_now_ns');
sub now { $now_ns->() / 1e9 }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
sub snapshot {
    return FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => [$^X, '-e', 'syswrite STDOUT,"FORBIDDEN"'], cwd => '.',
        schema => 'private.coordinator.peers.v1', stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 25, capture_limit_bytes => 64},
    }, $now_ns->());
}
sub create {
    $owner = FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot => snapshot());
    push @owners, $owner; $owner->open_run;
    my $path = repository_root() . '/' . $owner->{run}{directory};
    $endpoints{refaddr($owner)} = [map { [$_, [lstat($_)]] } ("$path/s", $path)];
    return $owner;
}
sub client {
    my ($context) = @_;
    my $c = FSM::Support::ProcessSupervisor::Endpoint::connect_context($context // $owner->context);
    push @clients, $c;
    my $end = now() + 2;
    while (now() < $end) {
        return $c if IO::Select->new($c->handle)->can_write(0) && $c->connection_ready;
        sleep(0.001);
    }
    die 'aggregate peer connect observer expired';
}
sub peer_eof {
    my ($c) = @_;
    ok(IO::Select->new($c->handle)->can_read(1), 'independent client sees native peer closure');
    is(sysread($c->handle, my $part, 1), 0, 'client observes empty EOF without command output');
}
sub ready {
    my ($grant, $started) = @_;
    unless ($started) { $owner->prepare_job($grant); $owner->start_job($grant); }
    my $end = now() + 4;
    while (now() < $end) {
        my $observed = $owner->advance_job($grant);
        return if $observed->{native}{phase} eq 'ready';
        die 'native peer handoff failed: ' . ($observed->{failure} // 'original admission revoked')
            if $observed->{admission}{phase} eq 'closing';
        die 'native peer fixture finished before ready: ' . ($observed->{failure} // '')
            if $observed->{native}{phase} eq 'finished';
        sleep(0.001);
    }
    die 'aggregate native handoff observer expired';
}
sub close_owner {
    my ($o) = @_;
    my ($result, $end) = (undef, now() + 5);
    while (now() < $end) {
        $result = $o->close;
        last unless $result->{pending};
        sleep(0.001);
    }
    ok($result->{ok}, 'whole-run close proves native and transport closure');
    is_deeply($o->observation->{usage}, {map { $_ => 0 }
        qw(jobs children descriptors reserved_children reserved_descriptors charged_children charged_descriptors)},
        'only complete closure retires every original charge');
    is(scalar @{$o->handles}, 0, 'original aggregate inventory is empty');
    ok(!live(@accepted, @pipes), 'independent actual descriptor inventory is closed before rescue');
    ok(!grep(!$_, values %births), 'all independently observed native children have exact consumed waits');
    is_deeply($o->close, $result, 'completed aggregate close is idempotent');
}
sub rescue {
    for my $pid (keys %births) {
        next if $births{$pid};
        my $w = CORE::waitpid($pid, WNOHANG);
        if ($w == $pid) {
            $waits{$pid} = $?; $births{$pid} = 1;
            diag('independent fixture consumed raw child wait ' . $waits{$pid});
            next;
        }
        if ($w == -1 && $! == ECHILD) { $births{$pid} = 1; next; }
        die 'fixture lost exact child ownership' unless $w == 0;
        CORE::kill('KILL', $pid); my $end = now() + 2;
        while (now() < $end) {
            $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid) { $births{$pid} = 1; last; }
            die 'fixture lost exact rescue wait' if $w == -1;
            sleep(0.001);
        }
        die 'aggregate peer fixture rescue expired' unless $births{$pid};
    }
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0; rescue();
        close $_ for live(@accepted, @pipes, @witnesses);
        $_->close for @clients;
        for my $o (@owners) {
            next if !$o->{run} || $o->{run}->observation->{closed};
            my $ok = eval { $o->{run}->close->{ok} };
            next if $ok;
            # Independent exact cleanup must survive deliberately broken owner
            # methods without promoting their failed admission/closure verdicts.
            for my $entry (@{$endpoints{refaddr($o)}}) {
                my ($path, $original) = @$entry; my @actual = lstat($path); next unless @actual;
                die 'fixture endpoint identity changed' unless @$original
                    && $actual[0] == $original->[0] && $actual[1] == $original->[1]
                    && $actual[2] == $original->[2] && $actual[4] == $original->[4];
                if (-d _) { rmdir($path) or die 'cannot remove exact empty peer fixture directory'; }
                else { unlink($path) == 1 or die 'cannot remove exact peer fixture socket'; }
            }
            die 'independent endpoint handles remain' if @{$o->{run}->handles};
        }
    }
}

my $before_accept = $class->can('_before_peer_accept');
my $accept = FSM::Support::ProcessSupervisor::Service->can('_accept_once');
my $construct = FSM::Support::ProcessSupervisor::Connection->can('new_connection');
my $reserve = FSM::Support::ProcessSupervisor::Admission->can('reserve_descriptors');
my $take_closed = FSM::Support::ProcessSupervisor::Service->can('take_closed');
my $fork_check = $class->can('_before_job_fork');
my $rfork = $reservation->can('_fork'); my $cfork = $pair->can('_fork');
my $rwait = $reservation->can('_wait'); my $cwait = $pair->can('_wait');
my $byte = $reservation->can('_child_byte'); my $pipe = $reservation->can('_pipe');
my $native_cancel = FSM::Support::ProcessSupervisor::ReservedJob->can('cancel');
my $fork = sub {
    my ($which, $native) = @_;
    if ($fail_fork eq $which) { $! = EAGAIN; return undef; }
    my $pid = $native->(); $births{$pid} = 0 if defined($pid) && $pid > 0; return $pid;
};
my $wait = sub {
    my ($native, $pid) = @_;
    die 'native owner waits for an unobserved child' unless exists $births{$pid};
    my $w = $native->($pid);
    if ($w == $pid) { $waits{$pid} = $?; $births{$pid} = 1; }
    return $w;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Coordinator::_before_peer_accept = sub {
    my ($self, $s, $id) = @_; ++$admissions; $ticket = $id;
    if ($expire_accept) {
        my $deadline = $self->job_observation($self->root)->{admission}{deadline_ns};
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Admission::_now_ns = sub { $deadline };
        return $before_accept->(@_);
    }
    return $before_accept->(@_);
};
local *FSM::Support::ProcessSupervisor::Admission::reserve_descriptors = sub {
    my $grant = $reserve->(@_);
    die "selected aggregate grant return\n" if $_[1] == 1 && $cut eq 'grant_throw';
    CORE::kill('USR1', $$) == 1 or die 'cannot queue grant signal'
        if $_[1] == 1 && $signal_at eq 'grant';
    return $grant;
};
local *FSM::Support::ProcessSupervisor::Service::_accept_once = sub {
    ++$accepts;
    my $observed = $owner->peer_observation($ticket);
    is_deeply($observed->{admission}, {count => 1, reserved => 1}, 'native accept has its original reserved descriptor grant');
    is($observed->{transport}{state}, 'accepting', 'aggregate retains the original pre-effect ticket');
    if ($cut eq 'transient') { $! = EAGAIN; return undef; }
    my $peer = $accept->(@_);
    if (defined $peer) {
        push @accepted, ${$_[0]};
        die "selected aggregate partial accept\n" if $cut eq 'accept_throw';
        CORE::kill('USR1', $$) == 1 or die 'cannot queue accepted signal' if $signal_at eq 'accept';
    }
    return $peer;
};
local *FSM::Support::ProcessSupervisor::Connection::new_connection = sub {
    my $io = $construct->(@_);
    die "selected aggregate constructor return\n" if $cut eq 'construct_throw';
    return $io;
};
local *FSM::Support::ProcessSupervisor::Service::take_closed = sub {
    my $outcome = $take_closed->(@_);
    if ($outcome) {
        die "selected consumed outcome return\n" if $consume_throw;
        CORE::kill('USR1', $$) == 1 or die 'cannot queue outcome signal' if $signal_at eq 'consume';
    }
    return $outcome;
};
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    my $ok = $pipe->(@_); push @pipes, ${$_[0]}, ${$_[1]} if $ok; return $ok;
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->('reservation', $rfork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->('command', $cfork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($rwait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($cwait, @_) };
local *FSM::Support::ProcessSupervisor::Reservation::_child_byte = sub {
    _exit(91) if live(@foreign); return $byte->(@_);
};
local *FSM::Support::ProcessSupervisor::Coordinator::_before_job_fork = sub {
    my ($self, $grant) = @_;
    my $inventory = $fork_check->(@_); my $id = $self->job_observation($grant)->{admission}{id};
    @foreign = (@{$self->{run}->handles}, live(@accepted), map {
        $_ == $id || !$self->{jobs}{$_}{native} ? () : @{$self->{jobs}{$_}{native}->handles}
    } keys %{$self->{jobs}});
    is_deeply([sort map { refaddr($_) } @$inventory], [sort map { refaddr($_) } @foreign],
        'each native fork sees current independent endpoint, peer and other-job handles');
    return $inventory;
};
local *FSM::Support::ProcessSupervisor::ReservedJob::cancel = sub {
    for my $g (@{$owner->grants}) {
        my $v = $owner->job_observation($g); my $entry = $owner->{jobs}{$v->{admission}{id}};
        next unless $entry->{native} && refaddr($entry->{native}) == refaddr($_[0]);
        ok(!$v->{admission}{accepting}, 'ledger authority is revoked before native cancellation');
        ok(!exists $owner->{service}{parents}{$v->{admission}{id}}, 'transport authority is revoked before native cancellation');
    }
    return $native_cancel->(@_);
};
local *FSM::Support::ProcessSupervisor::ReservedJob::release = sub { die 'peer integration must never release exec' };
use warnings 'redefine';
local $SIG{ALRM} = sub { die "aggregate accepted-peer fixture deadline\n" }; alarm 60;
my $initial = census();

subtest 'native socket charges and closed outcomes remain original and bounded' => sub {
    create(); my $c = client(); $owner->advance_service;
    is($owner->observation->{usage}{charged_descriptors}, 21, 'original run, scratch, root and peer credit are retained');
    is_deeply($owner->peer_observation(1)->{admission}, {count => 1, reserved => 0}, 'actual socket reconciles reserved into held credit');
    is(scalar @{$owner->handles}, 3, 'aggregate reports endpoint once and the actual peer');
    my $copy = $owner->peer_observation(1); $copy->{transport}{state} = 'closed'; $copy->{admission}{count} = 0;
    is($owner->peer_observation(1)->{transport}{state}, 'hello', 'copied peer metadata cannot change original ownership');
    $owner->retire_peer(1); peer_eof($c);
    is($owner->observation->{usage}{charged_descriptors}, 21, 'closed outcome conservatively retains its descriptor grant');
    close_owner($owner);
    my $outcome = $owner->peer_observation(1)->{outcome};
    ok($outcome->{resources_closed}, 'whole-run closure retains the original consumed outcome');
    $outcome->{status} = 'forged';
    is($owner->peer_observation(1)->{outcome}{status}, 'cancelled', 'consumed outcome inspection is a detached copy');
};

subtest 'descriptor capacity and empty transients defer before native effects' => sub {
    create(); my $c = client(); my $before = $accepts;
    my $held = $owner->{ledger}->reserve_descriptors(108);
    $owner->advance_service;
    is($accepts, $before, 'full aggregate descriptor capacity performs no accept');
    is_deeply($owner->peer_tickets, [], 'capacity refusal retains no resource-free peer');
    $owner->{ledger}->release_descriptors($held, 107);
    $cut = 'transient'; $owner->advance_service; $cut = '';
    is($owner->observation->{usage}{charged_descriptors}, 127, 'no-handle transient releases its exact descriptor reservation');
    is_deeply($owner->peer_tickets, [], 'transient leaves no retained peer slot');
    $owner->advance_service;
    is_deeply($owner->peer_tickets, [3], 'deferred and transient identities never repeat');
    is($owner->observation->{usage}{charged_descriptors}, 128, 'one remaining descriptor admits exactly one actual socket');
    close_owner($owner); peer_eof($c);
};

subtest 'partial accept and construction returns keep conservative original grants' => sub {
    for my $mode (qw(accept_throw construct_throw)) {
        create(); my $c = client(); $cut = $mode;
        like(error_from(sub { $owner->advance_service }), qr/selected aggregate/, 'original native interruption is preserved'); $cut = '';
        my $view = $owner->peer_observation(1);
        is($view->{transport}{state}, 'closed', 'original socket closes through retained Service custody');
        ok($view->{admission}{count} == 1, 'interrupted return keeps the original descriptor credit');
        peer_eof($c); close_owner($owner);
        is($owner->peer_observation(1)->{outcome}{status}, 'host_error', 'retained peer outcome preserves its first cause');
    }
    create(); client(); my $before = $accepts; $cut = 'grant_throw';
    like(error_from(sub { $owner->advance_service }), qr/selected aggregate grant return/,
        'interrupted pure grant return keeps its first cause'); $cut = '';
    is($accepts, $before, 'interrupted grant reservation reaches no native accept');
    is($owner->observation->{usage}{charged_descriptors}, 21, 'original ledger retains the interrupted grant');
    is_deeply($owner->peer_tickets, [1], 'resource-free failed ticket retains its aggregate record');
    close_owner($owner);
};

subtest 'real grant and accept signals see reconciled original ownership' => sub {
    for my $where (qw(grant accept)) {
        create(); my $c = client(); my $observed;
        local $SIG{USR1} = sub { $observed = $owner->peer_observation(1); die "selected aggregate signal return\n" };
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select signal mask';
        $signal_at = $where; my $error = error_from(sub { $owner->advance_service }); $signal_at = '';
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore signal mask';
        like($error, qr/selected aggregate signal return/, 'actual pending handler interrupts only the reconciled return');
        is_deeply($observed->{admission}, {count => 1, reserved => 0}, 'handler sees actual held descriptor credit');
        is($observed->{transport}{handles}, 1, 'handler sees the actual retained socket');
        is($observed->{transport}{state}, 'hello', 'handler sees complete construction');
        peer_eof($c); close_owner($owner);
    }
};

subtest 'consumed outcome returns cannot strand their original metadata or grants' => sub {
    create(); client(); $owner->advance_service; $consume_throw = 1;
    like(error_from(sub { $owner->close }), qr/selected consumed outcome return/, 'selected interruption follows actual Service outcome consumption');
    $consume_throw = 0;
    is_deeply($owner->{service}->tickets, [], 'Service actually consumed its closed ticket');
    ok($owner->peer_observation(1)->{outcome}{resources_closed}, 'aggregate published the original outcome before consumption');
    is(scalar @{$owner->{run}->handles}, 2, 'interrupted consume retains original endpoint');
    is($owner->observation->{usage}{charged_descriptors}, 21, 'interrupted consume retains conservative original grants');
    close_owner($owner);
    create(); client(); $owner->advance_service; my $observed;
    local $SIG{USR1} = sub { $observed = [$owner->observation, $owner->peer_observation(1)]; die "selected complete aggregate close\n" };
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select close mask';
    $signal_at = 'consume'; my $error = error_from(sub { $owner->close }); $signal_at = '';
    defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore close mask';
    like($error, qr/selected complete aggregate close/, 'actual pending signal interrupts complete aggregate close');
    is($observed->[0]{phase}, 'closed', 'handler sees complete original owner retirement');
    ok($observed->[1]{outcome}{resources_closed}, 'handler recovers the consumed original peer outcome');
    close_owner($owner);
};

subtest 'new accepted sockets join both native fork inventories and exact cleanup' => sub {
    create(); my $root = $owner->root; my $first = client(); $owner->advance_service;
    $owner->prepare_job($root); $owner->start_job($root);
    my $second = client(); $owner->advance_service; ready($root, 1);
    my $child = $owner->reserve_job(parent => $root, snapshot => snapshot()); ready($child);
    is($owner->observation->{usage}{children}, 4, 'actual root and nested pairs retain four direct children');
    for my $g ($root, $child) {
        my $id = $owner->job_observation($g)->{admission}{id};
        open my $fh, '<&', $owner->{jobs}{$id}{native}{received}{stdout}
            or die 'cannot retain independent native execution witness';
        push @witnesses, $fh;
    }
    my $child_view = $owner->job_observation($child)->{admission};
    # Admission now registers the context before native preparation. Recover
    # that original authority without attempting a second token publication.
    my $context = $owner->{service}->parent_context($child_view->{id});
    my $nested_peer = client($context); my @parts = split /:/, $context;
    my $hello = pack('NCC', 54, 1, 1) . pack('H*', $parts[2]) . pack('N', $parts[3]) . pack('H*', $parts[4]);
    is(syswrite($nested_peer->handle, $hello), length($hello), 'literal nested HELLO reaches the actual socket');
    my $end = now() + 2;
    while (now() < $end) {
        $owner->advance_service;
        last if defined $owner->peer_observation(3)->{transport}{parent};
        sleep(0.001);
    }
    is($owner->peer_observation(3)->{transport}{parent}, $child_view->{id}, 'actual nested peer authenticates its original parent');
    $owner->cancel_job($child, 'selected nested cancellation');
    peer_eof($nested_peer);
    is($owner->peer_observation(1)->{transport}{handles}, 1, 'nested revocation leaves unrelated root transport live');
    ok(!$owner->peer_observation(1)->{outcome}, 'unassociated root transport remains retained after nested cancellation');
    close_owner($owner); peer_eof($first); peer_eof($second);
    for my $fh (live(@witnesses)) {
        is(sysread($fh, my $bytes, 32), 0, 'independent native pipe EOF proves no command output');
        close $fh;
    }
};

subtest 'closed peer slots remain bounded until whole-run outcome consumption' => sub {
    create();
    for (1 .. 8) { client(); $owner->advance_service; }
    client(); my $before = [$accepts, $admissions];
    $owner->advance_service;
    is_deeply([$accepts, $admissions], $before, 'inclusive peer capacity refuses before ticket admission or native accept');
    $owner->retire_peer($_) for @{$owner->peer_tickets};
    $owner->advance_service;
    is_deeply([$accepts, $admissions], $before, 'closed unconsumed outcomes still prevent further admission');
    is($owner->observation->{usage}{charged_descriptors}, 28, 'closed peer slots keep all original conservative charges');
    close_owner($owner);
    ok(!grep(!defined($owner->peer_observation($_)->{outcome}), @{$owner->peer_tickets}),
        'whole-run close retains every original consumed outcome');
};

subtest 'uncertain peer closure cannot release endpoint or native resource charges' => sub {
    create(); my $c = client(); $owner->advance_service; ready($owner->root);
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Connection::close = sub { return 0 };
        local *FSM::Support::ProcessSupervisor::Service::_close_once = sub { return 0 };
        ok($owner->close->{pending}, 'live peer closure remains pending while native cleanup starts');
    }
    my ($error, $end) = ('', now() + 5);
    while (now() < $end) {
        $error = error_from(sub { $owner->close });
        last if $error;
        sleep(0.001);
    }
    like($error, qr/accepted peer cleanup incomplete/, 'uncertain original peer verdict remains a closure failure');
    peer_eof($c);
    ok(!live(@accepted, @pipes), 'native sockets and pipes actually close despite the failed verdict');
    ok(!grep(!$_, values %births), 'transport uncertainty cannot prevent exact native child cleanup');
    is(scalar @{$owner->{run}->handles}, 2, 'uncertain peer closure retains the original endpoint');
    ok($owner->observation->{usage}{charged_descriptors} > 0, 'uncertain closure retains original aggregate charges');
    ok($owner->{run}->close->{ok}, 'fixture independently retires its exact endpoint without promoting owner success');
};

subtest 'interrupted transport cleanup still cancels native owners before retry' => sub {
    create(); my $c = client(); $owner->advance_service; ready($owner->root);
    my $close = FSM::Support::ProcessSupervisor::Connection->can('close'); my $once = 1;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Connection::close = sub {
            my $result = $close->(@_);
            if ($once) { $once = 0; die "selected transport close interruption\n"; }
            return $result;
        };
        # Depending on exact child wait readiness this first call either
        # publishes pending native closure or rethrows the retained exception.
        my $error = error_from(sub { $owner->close });
        like($error, qr/\A\z|selected transport close interruption/, 'first close retains the selected interruption');
    }
    like($owner->observation->{failure}, qr/selected transport close interruption/, 'original transport exception is durably retained by the owner');
    my $phase = $owner->job_observation($owner->root)->{native}{phase};
    like($phase, qr/\A(?:cleanup|finished)\z/, 'transport exception cannot prevent native cancellation');
    peer_eof($c); close_owner($owner);
    like($owner->observation->{failure}, qr/selected transport close interruption/, 'successful resource cleanup cannot erase the first exception');
};

subtest 'expiry inside native admission retains even a resource-free failed ticket' => sub {
    create(); client(); my $before = $accepts; $expire_accept = 1;
    like(error_from(sub { $owner->advance_service }), qr/original invocation deadline expired/,
        'original expiry refuses admission after Service ticket publication');
    $expire_accept = 0;
    is($accepts, $before, 'expired original admission performs no native accept');
    is_deeply($owner->peer_tickets, [1], 'aggregate retains the failed original ticket without a descriptor');
    close_owner($owner);
    ok($owner->peer_observation(1)->{outcome}{resources_closed}, 'resource-free refused outcome survives whole-run cleanup');
};

subtest 'partial native start closes already admitted transport without losing waits' => sub {
    create(); my $c = client(); $owner->advance_service; my $root = $owner->root;
    $owner->prepare_job($root); $owner->start_job($root); $fail_fork = 'command';
    my $end = now() + 4;
    while (now() < $end) {
        my $v = $owner->advance_job($root);
        last if $v->{admission}{phase} eq 'closing';
        sleep(0.001);
    }
    $fail_fork = '';
    is($owner->job_observation($root)->{admission}{phase}, 'closing', 'actual command fork refusal revokes original root admission');
    peer_eof($c); close_owner($owner);
};

is_deeply(census(), $initial, 'joined native and peer endpoint census returns to its predecessor');
done_testing;
