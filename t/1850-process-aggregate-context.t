#!/usr/bin/env perl
use strict;
use warnings;
use Errno qw(ECHILD);
use Math::BigInt;
use POSIX qw(SIG_BLOCK SIG_UNBLOCK SIG_SETMASK SIGUSR1 SIGUSR2 WNOHANG);
use Scalar::Util qw(refaddr weaken);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;

our ($WATCH_ENTROPY, $NATIVE_READS) = (0, 0);
our @EFFECTS;
BEGIN {
    no warnings qw(once redefine);
    *CORE::GLOBAL::sysread = sub {
        if ($WATCH_ENTROPY && -c $_[0]) { $NATIVE_READS++; push @EFFECTS, 'read'; }
        return @_ == 4 ? CORE::sysread($_[0], $_[1], $_[2], $_[3])
            : CORE::sysread($_[0], $_[1], $_[2]);
    };
}
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Support::ProcessSupervisor::Coordinator ();

my $creator = $$;
my $key = 'FSMGEN_PROCESS_COORDINATOR_CONTEXT';
my (@owners, @pipes, @entropy, @witnesses, @checks, %births);
my ($owner, $clock_ns, $fault, $cut, $copy_fault, $signal_copy, $revoke_pipe, $pipe_calls, $opens);
sub now { clock_gettime(CLOCK_MONOTONIC) }
sub ns { sprintf('%.0f', $_[0] * 1_000_000_000) }
sub error_from { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@ }
sub live { grep { defined($_) && defined(fileno($_)) } @_ }
sub census { [sort glob(repository_root() . '/.artifacts/tmp/process-coordinator/*')] }
my $initial = census();
sub snapshot {
    return {type => 'SPAWN', started_ns => ns(now()), schema => 'aggregate.context.fixture',
        stage => 'probe', containment => 'fixture-group', cwd => '.', umask => 0027,
        timeout_seconds => $_[0] // 30, capture_limit_bytes => 64,
        argv => [$^X, '-e', 'syswrite STDOUT,"FORBIDDEN"', '', "high\xff\n"],
        environment => [['A', ''], [$key, 'obsolete private value'], [$key . '_OTHER', 'keep'], ['Z', "space\nand newline"]]};
}
sub bytes { pack('N', length $_[0]) . $_[0] }
sub literal {
    my ($s) = @_;
    my ($hi, $lo) = Math::BigInt->new($s->{started_ns})->bdiv(4_294_967_296);
    my $body = pack('CCNN', 1, 3, $hi->numify, $lo->numify)
        . join('', map { bytes($s->{$_}) } qw(schema stage containment cwd))
        . pack('NNNN', $s->{timeout_seconds}, $s->{capture_limit_bytes}, $s->{umask}, scalar @{$s->{argv}})
        . join('', map { bytes($_) } @{$s->{argv}})
        . pack('N', scalar @{$s->{environment}})
        . join('', map { bytes($_->[0]) . bytes($_->[1]) } @{$s->{environment}});
    return pack('N', length $body) . $body;
}
sub expected {
    my ($s, $context) = @_;
    my @env = grep { $_->[0] ne $key } @{$s->{environment}};
    push @env, [$key, $context];
    return {%$s, environment => [sort { $a->[0] cmp $b->[0] } @env]};
}
sub prepare {
    my ($snapshot) = @_;
    $owner = FSM::Support::ProcessSupervisor::Coordinator::prepare(snapshot => $snapshot // snapshot());
    push @owners, $owner; return $owner;
}
sub ready {
    my ($grant) = @_;
    $owner->prepare_job($grant); $owner->start_job($grant);
    my $end = now() + 3;
    while (now() < $end) {
        my $view = $owner->advance_job($grant);
        if ($view->{native}{phase} eq 'ready') { return; }
        die 'aggregate context native handoff refused' if $view->{admission}{phase} eq 'closing';
        sleep(0.001);
    }
    die 'aggregate context native handoff expired';
}
sub root_ready { prepare(); $owner->open_run; ready($owner->root); return $owner->root }
sub finish {
    my ($o) = @_; $fault = $copy_fault = $signal_copy = ''; $clock_ns = undef; $revoke_pipe = 0;
    my ($result, $end) = (undef, now() + 5);
    while (now() < $end) { $result = $o->close; last unless $result->{pending}; sleep(0.001); }
    ok($result && $result->{ok}, 'original aggregate closes all owned native resources');
    is($o->observation->{usage}{charged_descriptors}, 0, 'original descriptor credit retires only after closure');
    is($o->observation->{usage}{charged_children}, 0, 'all original child credit retires');
    ok(!live(@pipes, @entropy), 'independent pipe and weak entropy inventories are closed');
    ok(!grep(!$_, values %births), 'every actual direct child has its exact consumed wait');
    for my $fh (live(@witnesses)) {
        is(sysread($fh, my $part, 32), 0, 'independent stdout EOF contains no released command output');
        CORE::close($fh);
    }
}
sub reset_observers {
    die 'previous context fixture still owns resources' if live(@pipes, @entropy, @witnesses) || grep { !$_ } values %births;
    @pipes = (); @entropy = (); @witnesses = (); @checks = (); @EFFECTS = ();
    $fault = $cut = $copy_fault = $signal_copy = ''; $clock_ns = undef;
    $NATIVE_READS = $opens = $pipe_calls = $revoke_pipe = 0;
}
sub mask_state {
    my $old = POSIX::SigSet->new;
    defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $old) or die 'cannot read context mask';
    return [$old->ismember(SIGUSR1) ? 1 : 0, $old->ismember(SIGUSR2) ? 1 : 0];
}
END {
    local $?;
    if ($$ == $creator) {
        alarm 0; $WATCH_ENTROPY = 0; $fault = $copy_fault = $signal_copy = ''; $clock_ns = undef; $revoke_pipe = 0;
        eval { $_->close } for @owners;
        for my $pid (keys %births) {
            next if $births{$pid}; my $w = CORE::waitpid($pid, WNOHANG);
            if ($w == $pid || ($w == -1 && $! == ECHILD)) { $births{$pid} = 1; next; }
            die 'context fixture lost exact child' unless $w == 0;
            CORE::kill('KILL', $pid); my $end = now() + 2;
            while (now() < $end) {
                if (CORE::waitpid($pid, WNOHANG) == $pid) { $births{$pid} = 1; last; }
                sleep(0.001);
            }
            die 'context child rescue expired' unless $births{$pid};
        }
        CORE::close($_) for live(@pipes, @witnesses);
        eval { $_->{run}->close } for grep { $_->{run} } @owners;
    }
}

my $class = 'FSM::Support::ProcessSupervisor::Coordinator';
my $guard = $class->can('_before_context_allocation');
my $transform = FSM::Support::ProcessSupervisor::Wire->can('snapshot_with_context');
my $seal = FSM::Support::ProcessSupervisor::Endpoint->can('_seal_handle');
my $pipe = FSM::Support::ProcessSupervisor::Reservation->can('_pipe');
my $pipe_guard = $class->can('_before_job_allocation');
my $r_fork = FSM::Support::ProcessSupervisor::Reservation->can('_fork');
my $c_fork = FSM::Support::ProcessSupervisor::GatedPair->can('_fork');
my $r_wait = FSM::Support::ProcessSupervisor::Reservation->can('_wait');
my $c_wait = FSM::Support::ProcessSupervisor::GatedPair->can('_wait');
my $clock = FSM::Support::ProcessSupervisor::Admission->can('_now_ns');
my $fork = sub {
    my ($native) = @_; my $pid = $native->();
    $births{$pid} = 0 if defined($pid) && $pid > 0; return $pid;
};
my $wait = sub {
    my ($native, $pid) = @_;
    die 'unobserved context child wait' unless exists $births{$pid};
    my $w = $native->($pid); $births{$pid} = 1 if $w == $pid; return $w;
};
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Admission::_now_ns = sub { $clock_ns // $clock->() };
local *FSM::Support::ProcessSupervisor::Coordinator::_before_context_allocation = sub {
    my ($o, $g, $s, $id, $kind, $operation) = @_;
    my $entry = $o->{jobs}{$id}; my $description = $o->{ledger}->describe($g);
    push @checks, [$id, $entry->{context_state}, $description->{phase}, $kind, $operation, mask_state()];
    if ($fault && $operation eq $cut) {
        if ($fault eq 'grant') { $g = bless {}, ref($g); }
        elsif ($fault eq 'service') { $s = bless {%$s}, ref($s); }
        elsif ($fault eq 'id') { $id++; }
        elsif ($fault eq 'expire') { $clock_ns = $description->{deadline_ns}; }
        elsif ($fault eq 'cancel') { $o->{ledger}->cancel($g); }
        elsif ($fault eq 'scratch') {
            my $insufficient = $o->{ledger}->reserve_descriptors(1);
            local $o->{scratch_grant} = $insufficient;
            return $guard->($o, $g, $s, $id, $kind, $operation);
        }
    }
    $guard->($o, $g, $s, $id, $kind, $operation);
    push @EFFECTS, 'check:' . $operation if $WATCH_ENTROPY;
    return;
};
local *FSM::Support::ProcessSupervisor::Endpoint::_seal_handle = sub {
    if ($WATCH_ENTROPY && -c $_[0]) { $opens++; push @EFFECTS, 'open'; push @entropy, $_[0]; weaken($entropy[-1]); }
    return $seal->(@_);
};
local *FSM::Support::ProcessSupervisor::Wire::snapshot_with_context = sub {
    die "selected context snapshot refusal\n" if $copy_fault;
    my $result = $transform->(@_);
    if ($signal_copy) { $signal_copy = ''; CORE::kill('USR1', $$) == 1 or die 'cannot signal bound context'; }
    return $result;
};
local *FSM::Support::ProcessSupervisor::Reservation::_pipe = sub {
    $pipe_calls++; my $ok = $pipe->(@_); push @pipes, ${$_[0]}, ${$_[1]} if $ok; return $ok;
};
local *FSM::Support::ProcessSupervisor::Coordinator::_before_job_allocation = sub {
    $_[0]{service}->revoke_parent($_[0]->job_observation($_[1])->{admission}{id}) if $revoke_pipe;
    return $pipe_guard->(@_);
};
local *FSM::Support::ProcessSupervisor::Reservation::_fork = sub { $fork->($r_fork) };
local *FSM::Support::ProcessSupervisor::GatedPair::_fork = sub { $fork->($c_fork) };
local *FSM::Support::ProcessSupervisor::Reservation::_wait = sub { $wait->($r_wait, @_) };
local *FSM::Support::ProcessSupervisor::GatedPair::_wait = sub { $wait->($c_wait, @_) };
use warnings 'redefine';
local $SIG{ALRM} = sub { die "aggregate context fixture deadline\n" }; alarm 60;

subtest 'root snapshot is rebound to original context before native custody moves' => sub {
    reset_observers(); my $s = snapshot(); my $original = literal($s); prepare($s); $owner->open_run;
    my $context = $owner->context; my $expected = expected($s, $context);
    ok(literal($owner->{jobs}{1}{snapshot}) eq literal($expected), 'independent literal root snapshot changes only its original private context');
    ok(literal($s) eq $original, 'caller snapshot remains unchanged');
    is($owner->job_observation($owner->root)->{context_state}, 'ready', 'copied observation records completed original context binding');
    my $view = $owner->job_observation($owner->root); $view->{context_state} = 'failed';
    is($owner->job_observation($owner->root)->{context_state}, 'ready', 'copied state cannot rewrite original preparation');
    $owner->prepare_job($owner->root);
    ok(literal($owner->{jobs}{1}{native}{pair}{snapshot}) eq literal($expected), 'actual native graph receives the exact transformed root snapshot');
    ok(!exists $owner->{jobs}{1}{snapshot}, 'aggregate releases its snapshot copy only after native custody');
    finish($owner);
};

subtest 'nested contexts bind in admission order before out-of-order native starts' => sub {
    reset_observers(); my $root = root_ready(); my @grants; my @expected;
    for my $id (2, 3) {
        my $s = snapshot(15); my $original = literal($s);
        local $WATCH_ENTROPY = 1;
        my $g = $owner->reserve_job(parent => $root, snapshot => $s); push @grants, $g;
        my $context = $owner->{service}->parent_context($id); push @expected, expected($s, $context);
        is((split /:/, $context)[3], $id, 'original Service context names the matching admitted child');
        ok(literal($owner->{jobs}{$id}{snapshot}) eq literal($expected[-1]), 'nested literal bytes bind to that child rather than root authority');
        ok(literal($s) eq $original, 'nested caller snapshot remains detached');
    }
    is_deeply(\@EFFECTS, [map { ('check:entropy_open', 'open', 'check:entropy_read', 'read') } 1 .. 2], 'each actual token effect follows its original aggregate grant check');
    is_deeply(\@checks, [map { my $id = $_; map { [$id, 'preparing', 'reserved', 'create', $_, [1, 1]] } qw(entropy_open entropy_read) } 2, 3], 'original context state and grant credit precede every entropy effect under the mask');
    ready($grants[1]); ready($grants[0]);
    for my $index (0, 1) {
        my $id = $index + 2;
        ok(literal($owner->{jobs}{$id}{native}{pair}{snapshot}) eq literal($expected[$index]), 'out-of-order native start retains the original child snapshot');
        open my $fh, '<&', $owner->{jobs}{$id}{native}{received}{stdout} or die 'cannot retain independent context execution witness';
        push @witnesses, $fh;
    }
    finish($owner);
};

subtest 'copied or expired grants and insufficient scratch refuse before the selected entropy effect' => sub {
    for my $mode (qw(grant service id expire cancel scratch)) {
        for my $operation (qw(entropy_open entropy_read)) {
            reset_observers(); my $root = root_ready(); $fault = $mode; $cut = $operation;
            my $error;
            { local $WATCH_ENTROPY = 1; $error = error_from(sub { $owner->reserve_job(parent => $root, snapshot => snapshot(10)) }); }
            like($error, qr/foreign, copied|original open Service|reserved job custody|deadline expired|admission revoked|scratch credit/, "$mode refuses its original token boundary");
            is($opens, $operation eq 'entropy_open' ? 0 : 1, 'no unadmitted entropy open occurs');
            is($NATIVE_READS, 0, 'no unadmitted native entropy read occurs');
            is($owner->{jobs}{2}{context_state}, 'failed', 'original failed context preparation remains retained');
            is($owner->job_observation($owner->{jobs}{2}{grant})->{admission}{phase}, 'closing', 'failure revokes only the original child grant before cleanup');
            ok(!defined $owner->{jobs}{2}{native}, 'token failure creates no child native graph');
            $clock_ns = undef; finish($owner);
        }
    }
};

subtest 'snapshot refusal preserves original custody and actual bounded cleanup' => sub {
    for my $nested (0, 1) {
        reset_observers(); my $root = $nested ? root_ready() : undef;
        my $s = snapshot(15); my $original = literal($s);
        prepare($s) unless $nested; $copy_fault = 1;
        my $error = error_from(sub { $nested ? $owner->reserve_job(parent => $root, snapshot => $s) : $owner->open_run });
        $copy_fault = '';
        like($error, qr/selected context snapshot refusal/, 'original transformation failure survives');
        my $id = $nested ? 2 : 1;
        is($owner->{jobs}{$id}{context_state}, 'failed', 'failed pure replacement cannot publish ready context binding');
        ok(literal($owner->{jobs}{$id}{snapshot}) eq $original, 'original snapshot remains retained when replacement refuses');
        ok(!defined $owner->{jobs}{$id}{native}, 'failed replacement starts no native graph');
        finish($owner);
    }
    reset_observers(); my $s = snapshot();
    $s->{environment} = [map { [sprintf('A%04d', $_), ''] } 1 .. 4096];
    prepare($s);
    like(error_from(sub { $owner->open_run }), qr/invalid execution vector/, 'actual insertion excess refuses after root endpoint preparation');
    is($owner->{jobs}{1}{context_state}, 'failed', 'inclusive snapshot bounds remain authoritative at aggregate binding');
    finish($owner);
};

subtest 'pending creator signal observes bound snapshots before interrupted publication return' => sub {
    for my $nested (0, 1) {
        reset_observers(); my $root = $nested ? root_ready() : undef;
        prepare() unless $nested; my ($view, $exact);
        my $old = POSIX::SigSet->new;
        defined POSIX::sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGUSR1), $old) or die 'cannot select context signal';
        defined POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new(SIGUSR2)) or die 'cannot select context mask';
        local $SIG{USR1} = sub {
            my $id = $nested ? 2 : 1; my $entry = $owner->{jobs}{$id};
            $view = $owner->job_observation($entry->{grant});
            my ($pair) = grep { $_->[0] eq $key } @{$entry->{snapshot}{environment}};
            $exact = $pair && $pair->[1] eq $owner->{service}->parent_context($id);
            die "selected aggregate context interruption\n";
        };
        $signal_copy = 1;
        my $error = error_from(sub { $nested ? $owner->reserve_job(parent => $root, snapshot => snapshot(15)) : $owner->open_run }); $signal_copy = '';
        like($error, qr/selected aggregate context interruption/, 'actual creator signal interrupts after original binding');
        is_deeply(mask_state(), [0, 1], 'original caller mask is restored');
        defined POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore context fixture mask';
        ok($view && $view->{context_state} eq 'ready' && $exact, 'handler sees original ready state and matching complete snapshot');
        ok(!$view->{native}, 'context publication precedes native preparation');
        finish($owner);
    }
};

subtest 'revoked context cannot allocate fork or advance an original native job' => sub {
    for my $point (qw(prepare pipe fork advance)) {
        reset_observers(); prepare(); $owner->open_run; my $g = $owner->root;
        $owner->prepare_job($g) if $point eq 'fork' || $point eq 'advance';
        $owner->start_job($g) if $point eq 'advance';
        my $before_pipes = $pipe_calls; my $before_children = scalar keys %births;
        if ($point eq 'pipe') { $revoke_pipe = 1; }
        else { $owner->{service}->revoke_parent(1); }
        my $error = error_from(sub {
            if ($point eq 'prepare' || $point eq 'pipe') { $owner->prepare_job($g); }
            elsif ($point eq 'fork') { $owner->start_job($g); }
            else { $owner->advance_job($g); }
        });
        $revoke_pipe = 0;
        like($error, qr/unknown or revoked|no longer retained|root authority/, "$point refuses revoked original context");
        is($pipe_calls, $before_pipes, 'no additional pipe follows revoked context');
        is(scalar keys %births, $before_children, 'no additional native child follows revoked context');
        finish($owner);
    }
};

is_deeply(census(), $initial, 'independent endpoint census returns to original membership');
done_testing;
