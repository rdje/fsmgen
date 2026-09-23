#!/usr/bin/env perl
use strict;
use warnings;

use Errno qw(ECHILD ESRCH);
use IO::Select;
use POSIX qw(SIG_SETMASK SIGUSR1 WNOHANG);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use Test::More;
use lib 'perl', 't/lib', 'docs/audits/native-proxy-receipt-adapter-20260922';
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor ();
use FSM::Support::ProcessSupervisor::ReservedJob ();
use ReceiptAdapter;

my @jobs;
my %group_observations;
my $owner = $$;

# Retain the independent kernel observation while the real reservation still
# owns the identity. Final result checks must not probe its retired numeric PGID.
my $retire = FSM::Support::ProcessSupervisor::Reservation->can('retire');
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::Reservation::retire = sub {
    my ($r) = @_;
    my ($job) = grep { $_->{pair}->reservation == $r } @jobs;
    if ($job && $r->{pid} && $r->{moved} && !$r->{retired}) {
        die 'absence observer lost reservation identity' if $r->{reaped};
        local $! = 0;
        my $present = CORE::kill(0, -$r->{pid});
        $group_observations{refaddr($r)} = [$present, 0 + $!];
    }
    return $retire->(@_);
};
use warnings 'redefine';
sub now { return clock_gettime(CLOCK_MONOTONIC) }
sub error { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@; }
sub prepare {
    my ($program, %options) = @_;
    my $snapshot = FSM::Support::ProcessSupervisor::Wire::snapshot_request({
        argv => $options{argv} // [$^X, '-e', $program], cwd => '.',
        schema => 'private.reserved.fixture.v1', stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => $options{timeout} // 5,
            capture_limit_bytes => $options{cap} // 4096},
    }, sprintf('%.0f', now() * 1e9));
    my $deadline = $snapshot->{started_ns} / 1e9 + $snapshot->{timeout_seconds};
    my $job = FSM::Support::ProcessSupervisor::ReservedJob::prepare(
        snapshot => $snapshot, deadline => $deadline, close_handles => []);
    push @jobs, $job;
    return $job;
}
sub drive {
    my ($job, $phase) = @_;
    my $end = now() + 10;
    while (now() < $end) {
        return $job->observation if $job->observation->{phase} eq $phase;
        die "job finished before $phase\n" if $job->observation->{phase} eq 'finished';
        $job->advance;
        sleep(0.001);
    }
    die "reserved job observer expired waiting for $phase\n";
}
sub run {
    my $job = prepare(@_);
    $job->start; drive($job, 'ready'); $job->release; drive($job, 'finished');
    return $job;
}
sub closed {
    my ($job) = @_;
    my $state = $job->finished_job;
    ok($state->{resources_closed}, 'owned command/group/reservation resources closed');
    ok($state->{cleanup}{leader_reaped} && $state->{cleanup}{group_gone}
        && $state->{reservation_reaped}, 'distinct closure facts are all actual');
    for my $pid ($state->{pid}, $state->{group_identity}{pid}) {
        my $waited = waitpid($pid, WNOHANG);
        my $error = 0 + $!;
        is($waited, -1, 'no exact child wait remains');
        is($error, ECHILD, 'the exact wait was consumed');
    }
    is_deeply($group_observations{refaddr($job->{pair}->reservation)}, [0, ESRCH],
        'kernel proves group absence before identity retirement');
    return $state;
}

END {
    local $?;
    if ($$ == $owner) {
        alarm 0;
        for my $job (@jobs) {
            my $p = $job->{pair};
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
local $SIG{ALRM} = sub { die "reserved job test deadline\n" };
alarm 60;

subtest 'published release is explicit and binary capture keeps the closed facade' => sub {
    my $job = prepare('print "stdout\0\xff"; print STDERR "stderr\0\xfe"; exit 0');
    like(error(sub { $job->finished_job }), qr/finished job/, 'prepared job has no terminal facade');
    $job->start; drive($job, 'ready');
    for (1 .. 5) { $job->advance; }
    ok(!$job->{state}{select}->can_read(0.05), 'actual ready command emits nothing before release');
    ok(!$job->observation->{command}{released}, 'advancement cannot publish execution');
    my $cleanup_identity = refaddr($job->{state}{cleanup});
    $job->release; drive($job, 'finished');
    my $state = closed($job);
    my $r = $state->{result};
    is($r->{status}, 'success', 'actual command succeeds');
    is($r->{stdout}, "stdout\0\xff", 'stdout bytes survive shared capture');
    is($r->{stderr}, "stderr\0\xfe", 'stderr bytes stay separate');
    is($r->{stdout_bytes}, 8, 'stdout byte count is actual binary length');
    is($r->{stderr_bytes}, 8, 'stderr byte count is actual binary length');
    is(refaddr($state->{cleanup}), $cleanup_identity, 'original private cleanup identity survives');
    isnt(refaddr($r->{cleanup}), $cleanup_identity, 'public result copies cleanup');
    my $receipt = $state->{receipt_observation};
    is($receipt->{role}, 'outer', 'stage receipt role is unchanged');
    is($receipt->{birth}{pid}, $state->{pid}, 'receipt command birth is the actual command');
    is($receipt->{group}{pid}, $state->{reservation_observation}{pid}, 'receipt group is the retained reservation birth');
    isnt($receipt->{birth}{pid}, $receipt->{group}{pid}, 'distinct process identities are never aliased');
    is($receipt->{cleanup_identity}, $cleanup_identity, 'receipt retains original cleanup identity');
    ok(!NativeProxyReceiptAdapter::receipt_bound($receipt, 'outer', {closed => 1}),
        'historical own-group adapter correctly refuses the distinct-group receipt');
    my %metadata = %$r; delete @metadata{qw(stdout stderr)};
    my $frame = eval { FSM::Support::ProcessSupervisor::Wire::encode_frame('coordinator', {
        type => 'RESULT', job => 1, metadata => {result => \%metadata,
            reservation_reaped => $state->{reservation_reaped}, subtree_closed => 1, delivery_complete => 0},
    }) };
    ok(defined $frame, 'existing terminal wire grammar accepts the unchanged result schema') or diag $@;
    my $legacy = FSM::Support::ProcessSupervisor::process_failure(
        schema => 'private.reserved.fixture.v1', stage => 'probe',
        bounds => {timeout_seconds => 5, capture_limit_bytes => 4096},
        containment => 'fixture-group', status => 'host_error', diagnostic => 'shape control');
    is_deeply([sort keys %$r], [sort keys %$legacy], 'no public result key is added or lost');
    my $before = $r;
    $job->advance;
    is($job->finished_job->{result}, $before, 'terminal advancement cannot replace the result');
};

subtest 'real failures retain original wait truth and bounded captured output' => sub {
    for my $case (
        ['print STDERR "nonzero"; exit 23', {}, 'nonzero_exit', 23, 0],
        ['kill "TERM", $$; sleep 2', {}, 'signaled', undef, 15],
        ['', {argv => ['./.artifacts/absent-reserved-command']}, 'exec_error', 127, 0],
        ['$|=1; print "123456789"; sleep 2', {cap => 8}, 'output_limited', undef, undef],
        ['$SIG{TERM}="IGNORE"; $|=1; print "ready"; sleep 10', {timeout => 1}, 'timed_out', undef, 9],
    ) {
        my ($program, $options, $status, $exit, $signal) = @$case;
        my $job = run($program, %$options);
        my $state = closed($job);
        my $r = $state->{result};
        is($r->{status}, $status, "$status remains the primary failure");
        ok(!$r->{ok}, "$status cannot become success after cleanup");
        is($r->{exit_code}, $exit, "$status retains actual exit code") if defined($exit) || defined($signal);
        is($r->{signal}, $signal, "$status retains actual signal") if defined $signal;
        if ($status eq 'output_limited') {
            is($r->{stdout}, '12345678', 'overflow retains the exact admitted prefix');
            ok($r->{output_limited}, 'overflow flag remains explicit');
        }
        if ($status eq 'exec_error') {
            like($r->{exec_error}, qr/exec failed:/, 'actual exec diagnostic is captured');
            ok(!defined($r->{exec_handoff_monotonic_ns}), 'exec error does not fabricate a handoff');
        }
        if ($status eq 'timed_out') {
            is($r->{stdout}, 'ready', 'timeout captures the command readiness witness');
            ok($r->{timed_out} && $r->{cleanup}{kill_sent}, 'timeout and real escalation stay visible');
        }
    }
};

subtest 'cancellation before release never executes or renews the cleanup wall' => sub {
    for my $phase (qw(prepared ready releasing)) {
        my $job = prepare('print "FORBIDDEN"');
        if ($phase ne 'prepared') { $job->start; drive($job, 'ready'); }
        $job->release if $phase eq 'releasing';
        my $end = now() + 4;
        $job->cancel('first cancellation', $end);
        $job->cancel('later cancellation', $end + 1);
        drive($job, 'finished');
        my $state = $job->finished_job;
        is($state->{result}{diagnostic}, 'first cancellation', "$phase preserves the first cause");
        is($state->{result}{stdout}, '', "$phase produces no execution witness");
        ok(!$job->observation->{command}{released}, "$phase never released exec");
        is($job->{closure}->observation->{deadline}, $end, "$phase cannot renew cleanup");
        ok($state->{resources_closed}, "$phase closes partial ownership");
    }
};

subtest 'invocation time bounds include launch and cannot be reset by admission' => sub {
    my $request = {argv => [$^X, '-e', 'exit 0'], cwd => '.', schema => 'private.wall.v1',
        stage => 'probe', containment => 'fixture-group',
        bounds => {timeout_seconds => 1, capture_limit_bytes => 64}};
    for my $offset (-2, 2) {
        my $snapshot = FSM::Support::ProcessSupervisor::Wire::snapshot_request(
            $request, sprintf('%.0f', (now() + $offset) * 1e9));
        like(error(sub { FSM::Support::ProcessSupervisor::ReservedJob::prepare(
            snapshot => $snapshot, deadline => now() + 1, close_handles => []) }),
            qr/original invocation wall/, 'expired/future start cannot create a new wall');
    }
    my $job = prepare('print "FORBIDDEN"', timeout => 1);
    $job->start; drive($job, 'ready');
    # No exec release occurs while the original wall expires.
    drive($job, 'finished');
    is($job->finished_job->{result}{status}, 'timed_out', 'publication delay spends the invocation wall');
    is($job->finished_job->{result}{stdout}, '', 'expired publication cannot execute');
    ok(!$job->observation->{command}{released}, 'timeout revokes the unpublished gate');
};

subtest 'shared reader latches the first observed failure without changing legacy priority' => sub {
    for my $latch (0, 1) {
        pipe(my $out, my $ow) or die $!;
        pipe(my $control, my $cw) or die $!;
        syswrite($ow, 'overflow'); syswrite($cw, 'exec failure witness');
        close $ow; close $cw;
        my $state = {stdout => '', stderr => '', exec_error => '', latch_failures => $latch,
            bounds => {capture_limit_bytes => 1}, select => IO::Select->new($out, $control),
            control_fileno => fileno($control), streams => {
                fileno($out) => ['stdout', $out], fileno($control) => ['control', $control]}};
        FSM::Support::ProcessSupervisor::_read_supervision_streams($state);
        ok($state->{output_limited}, 'later output overflow still records its actual flag');
        is($state->{stdout}, 'o', 'aggregate prefix stays unchanged');
        if ($latch) {
            is($state->{first_failure}{status}, 'exec_error', 'control-first observation survives later overflow');
            FSM::Support::ProcessSupervisor::_latch_supervision_failure($state, 'host_error', 'later cleanup');
            is($state->{first_failure}{status}, 'exec_error', 'cleanup cannot replace that first failure');
        }
        else { ok(!exists($state->{first_failure}), 'legacy reader acquires no new precedence state'); }
        close $out; close $control;
    }
};

subtest 'an actual interrupted transfer remains reachable by composed cleanup' => sub {
    my $job = prepare('print "FORBIDDEN"');
    my $transfer = FSM::Support::ProcessSupervisor::GatedPair->can('transfer_streams');
    my $mask = FSM::Support::ProcessSupervisor::GatedPair->can('_mask');
    our $TRANSFER_ACTIVE = 0;
    no warnings 'redefine';
    local $SIG{USR1} = sub { die "actual transfer interruption\n" };
    local *FSM::Support::ProcessSupervisor::GatedPair::transfer_streams = sub {
        local $TRANSFER_ACTIVE = 1;
        return $transfer->(@_);
    };
    local *FSM::Support::ProcessSupervisor::GatedPair::_mask = sub {
        kill SIGUSR1, $$ if $TRANSFER_ACTIVE && $_[0] == SIG_SETMASK;
        return $mask->(@_);
    };
    $job->start;
    like(error(sub { drive($job, 'ready') }), qr/actual transfer interruption/,
        'restoring the real signal mask interrupts the handoff return');
    my @handles = values %{$job->{received}};
    is(scalar @handles, 3, 'the retained recipient owns every transferred stream');
    $job->cancel('actual transfer interruption', now() + 4);
    drive($job, 'finished');
    closed($job);
    ok(!grep(defined(fileno($_)), @handles), 'composed cleanup closes all retained streams');
    is($job->finished_job->{result}{diagnostic}, 'actual transfer interruption', 'original interruption is retained');
    is($job->finished_job->{result}{stdout}, '', 'interrupted handoff executes no command');
};

subtest 'a modeled later closure failure cannot replace the actual nonzero wait' => sub {
    my $native = FSM::Support::ProcessSupervisor::GroupClosure->can('observation');
    no warnings 'redefine';
    local *FSM::Support::ProcessSupervisor::GroupClosure::observation = sub {
        my $o = $native->(@_);
        return $o unless $o->{phase} eq 'finished';
        return {%$o, complete => 0, group_gone => 0, failure => 'modeled later closure failure'};
    };
    my $job = run('exit 23');
    my $s = $job->finished_job;
    is($s->{result}{status}, 'nonzero_exit', 'earlier actual command failure remains primary');
    is($s->{result}{exit_code}, 23, 'original exact wait remains independently visible');
    ok(!$s->{result}{cleanup}{group_gone} && !$s->{resources_closed}, 'modeled incomplete cleanup cannot become success');
    is($s->{closure_observation}{failure}, 'modeled later closure failure', 'later cleanup cause is retained separately');
};

subtest 'sealed callers retain legacy execution and the same result facade' => sub {
    for my $exit (0, 17) {
        my $program = 'print "out"; print STDERR "err"; exit ' . $exit;
        my $reserved = run($program)->finished_job;
        my $legacy = FSM::Test::ProcessSupervisor::sealed_supervise_process(
            schema => 'private.reserved.fixture.v1', stage => 'probe', containment => 'fixture-group',
            bounds => {timeout_seconds => 5, capture_limit_bytes => 4096},
            cwd => '.', argv => [$^X, '-e', $program]);
        ok(!exists($legacy->{reservation_observation}), 'sealed launch still selects the legacy strategy');
        is_deeply($legacy->{receipt_observation}{group}, $legacy->{receipt_observation}{birth},
            'legacy receipt retains its actual own-group identity');
        my @normalized;
        for my $state ($legacy, $reserved) {
            my %copy = %{$state->{result}};
            delete @copy{grep { /_ns\z/ } keys %copy};
            push @normalized, \%copy;
        }
        is_deeply($normalized[0], $normalized[1], "exit $exit preserves every non-timing facade field");
    }
};

alarm 0;
done_testing();
