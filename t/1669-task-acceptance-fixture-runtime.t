#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Errno qw(EPERM);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp ();
use FindBin;
use JSON::PP qw(decode_json);
use Test::More;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::ProjectDataLocality qw(create_project_tempdir ensure_project_artifact_dir);
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor::Wire ();
use FSM::Test::ProcessSupervisor qw(
    repository_root
    supervise_process
);
use FSM::Test::TaskAcceptanceFixtureRuntime qw(
    run_fixture_checker
    run_fixture_git
);
use FSM::Test::RustProxyFixture qw(prepare_rust_proxy);

my $repo_root = repository_root();
my $perl = abs_path($^X)
    or die "cannot resolve the current Perl interpreter: $!";
my $workspace = create_project_tempdir(
    purpose => 'process-supervisor-tests',
);

subtest 'shared engine keeps one closed success contract' => sub {
    my $program = File::Spec->catfile($workspace, 'success');
    write_executable($program, <<'PROGRAM');
#!/usr/bin/env perl
use strict;
use warnings;
print STDOUT "stdout-ready\n";
print STDERR "stderr-ready\n";
exit 0;
PROGRAM
    my %environment_before = %ENV;
    my $result = supervise_process(
        schema => 'fsmgen.test.process_supervisor_probe.v1',
        stage => 'probe',
        bounds => {
            timeout_seconds => 1,
            capture_limit_bytes => 65_536,
        },
        containment => 'process_supervisor_probe_group',
        cwd => $workspace,
        argv => [$perl, $program],
    );
    is_deeply(\%ENV, \%environment_before, 'caller environment remains exact');
    ok($result->{ok}, 'supervised argv succeeds once');
    is($result->{schema}, 'fsmgen.test.process_supervisor_probe.v1', 'caller policy owns the result schema');
    is($result->{stage}, 'probe', 'caller policy owns the stage');
    is($result->{stdout}, "stdout-ready\n", 'stdout remains separate');
    is($result->{stderr}, "stderr-ready\n", 'stderr remains separate');
    ok(defined($result->{exec_handoff_monotonic_ns})
            && $result->{exec_handoff_monotonic_ns} <= $result->{first_output_monotonic_ns},
        'successful command retains observed control closure before output');
    is($result->{timeout_seconds}, 1, 'selected wall is explicit');
    is($result->{capture_limit_bytes}, 65_536, 'selected capture ceiling is explicit');
    is($result->{cleanup}{containment}, 'process_supervisor_probe_group', 'caller policy owns the containment label');
    ok($result->{cleanup}{leader_reaped}, 'leader is reaped');
    ok($result->{cleanup}{group_gone}, 'process group is gone');
};

subtest 'child containment must be established before exec' => sub {
    my $caller_group = getpgrp(0);
    my $real_setpgid = \&POSIX::setpgid;
    for my $mode (qw(undefined negative false_success exception native_session success_stale)) {
        my $observation = File::Spec->catfile($workspace, "containment-$mode.json");
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::setpgid = sub {
            # Native session admission precedes any parent group move.
            return 0 if $_[0] != 0 && $mode eq 'native_session';
            my ($returned, $session);
            if ($mode eq 'native_session') {
                $session = POSIX::setsid();
                die "native session control failed\n"
                    unless defined($session) && $session == $$;
                $! = 0;
                $returned = $real_setpgid->(@_);
            }
            elsif ($mode eq 'success_stale') {
                $returned = $real_setpgid->(@_);
                $! = EPERM; # A successful syscall need not clear old errno.
            }
            else {
                $! = EPERM;
                $returned = $mode eq 'undefined' ? undef
                    : $mode eq 'negative' ? -1 : 0;
            }
            my $number = 0 + $!;
            if ($_[0] == 0) {
                my $actual_group = CORE::getpgrp(0);
                open my $record, '>', $observation or die $!;
                print {$record} JSON::PP->new->canonical->encode({
                    pid => $$, actual_group => $actual_group,
                    returned => $returned, errno => $number, session => $session,
                }) or die $!;
                close $record or die $!;
            }
            $! = $number;
            die "injected containment exception\n" if $mode eq 'exception';
            return $returned;
        };
        my $result = supervise_process(
            schema => 'fsmgen.test.process_supervisor_probe.v1',
            stage => 'probe',
            bounds => {timeout_seconds => 1, capture_limit_bytes => 65_536},
            containment => 'process_supervisor_probe_group',
            cwd => $workspace,
            argv => [$perl, '-e', 'print "command-executed=$$\n"'],
        );
        my $observed = eval { decode_json(slurp($observation)) };
        ok(ref($observed) eq 'HASH', "$mode retains the actual child's group observation")
            or do { diag explain $result; next };
        my $pid = $observed->{pid};
        ok(defined($pid) && $pid > 0, "$mode reports its actual child PID");
        if ($mode eq 'success_stale') {
            ok($result->{ok}, 'stale errno cannot reject successful group admission')
                or diag explain $result;
            is($result->{stdout}, "command-executed=$pid\n", 'admitted native child executes once');
            is($observed->{actual_group}, $pid, 'successful child independently observes its owned group');
            is($observed->{errno}, EPERM, 'success control actually carries stale errno');
        }
        else {
            is($result->{status}, 'exec_error', "$mode rejects the exec handoff");
            ok($result->{exec_failed}, "$mode reports failed handoff");
            my $prefix = "process-group containment failed: pid=$pid ";
            if ($mode eq 'false_success') {
                is($observed->{actual_group}, $caller_group, 'false return leaves the child in its inherited group');
                is($result->{exec_error},
                    $prefix . "operation=membership expected=$pid observed=$caller_group",
                    'membership mismatch cannot be mislabeled as a syscall failure');
            }
            elsif ($mode eq 'exception') {
                is($result->{exec_error},
                    $prefix . 'operation=setpgid exception=injected containment exception',
                    'exception keeps its own cause without ambient errno');
            }
            else {
                my $returned = $mode eq 'negative' ? '-1' : 'undef';
                like($result->{exec_error} // '',
                    qr/^\Q${prefix}operation=setpgid result=$returned errno=\E@{[EPERM]} \([^()\r\n]+\)$/,
                    "$mode reports the failed operation, return and captured errno");
                if ($mode eq 'native_session') {
                    is($observed->{session}, $pid, 'native control actually becomes a session leader');
                    is($observed->{actual_group}, $pid, 'correct group alone cannot excuse a failed syscall');
                    is($observed->{errno}, EPERM, 'native syscall independently supplies EPERM');
                }
            }
            is($result->{stdout}, '', "$mode never executes the command");
        }
        ok($result->{cleanup}{leader_reaped}, "$mode reaps the child");
        ok($result->{cleanup}{group_gone}, "$mode leaves no child group");
        ok(!kill(0, $pid), "$mode independently leaves no child PID");
        is(getpgrp(0), $caller_group, "$mode leaves the caller group unchanged");
    }
};

subtest 'containment group-query diagnostics preserve their own provenance' => sub {
    my $probe = File::Spec->catfile($workspace, 'containment-query');
    write_executable($probe, <<'PROBE');
use strict;
use warnings;
use Errno qw(EINVAL EPERM);
use JSON::PP qw(encode_json);
our $mode = shift @ARGV;
BEGIN {
    *CORE::GLOBAL::getpgrp = sub {
        my $actual = CORE::getpgrp($_[0]);
        # Query failures are modeled in this isolated process. Its outer
        # supervisor establishes and owns the actual native group.
        $! = EINVAL;
        return undef if $mode eq 'undefined';
        return -1 if $mode eq 'negative';
        die "injected group-query exception\n" if $mode eq 'exception';
        return $actual + 1 if $mode eq 'mismatch';
        return $actual;
    };
}
require FSM::Support::ProcessSupervisor;
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::setpgid = sub { $! = EPERM; return 0 };
my $actual = CORE::getpgrp(0);
my $error = FSM::Support::ProcessSupervisor::_child_group_admission_error();
print encode_json({pid => $$, actual_group => $actual, error => $error});
PROBE
    for my $mode (qw(undefined negative exception mismatch success_stale)) {
        my $outer = supervise_process(
            schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'probe',
            bounds => {timeout_seconds => 10, capture_limit_bytes => 65_536},
            containment => 'process_supervisor_probe_group', cwd => $repo_root,
            argv => [$perl, '-Iperl', $probe, $mode],
        );
        ok($outer->{ok}, "$mode query oracle returns under its independent wall")
            or diag explain $outer;
        my $observed = eval { decode_json($outer->{stdout}) };
        ok(ref($observed) eq 'HASH', "$mode returns structured query evidence") or next;
        my $pid = $observed->{pid};
        is($observed->{actual_group}, $pid, "$mode outer established actual native containment");
        my $prefix = "process-group containment failed: pid=$pid ";
        if ($mode eq 'success_stale') {
            ok(!defined($observed->{error}), 'successful query ignores stale errno from both operations');
        }
        elsif ($mode eq 'exception') {
            is($observed->{error}, $prefix . 'operation=getpgrp exception=injected group-query exception',
                'query exception cannot become a setpgid error');
        }
        elsif ($mode eq 'mismatch') {
            is($observed->{error}, $prefix . "operation=membership expected=$pid observed=" . ($pid + 1),
                'membership diagnostic retains the returned group, without stale errno');
        }
        else {
            my $returned = $mode eq 'negative' ? '-1' : 'undef';
            my $number = Errno::EINVAL();
            like($observed->{error} // '',
                qr/^\Q${prefix}operation=getpgrp result=$returned errno=$number\E \([^()\r\n]+\)$/,
                "$mode query failure keeps its own return and errno");
        }
        ok($outer->{cleanup}{leader_reaped} && $outer->{cleanup}{group_gone},
            "$mode query oracle leaves no owned child/group");
        ok(!kill(0, $pid), "$mode query process is independently absent");
    }
};

subtest 'handoff timing requires an observed control-pipe closure' => sub {
    my $real_setpgid = \&POSIX::setpgid;
    for my $mode (qw(timeout early_exit)) {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::setpgid = sub {
            my $result = $real_setpgid->(@_);
            if ($_[0] == 0) {
                # This independently fixes the child's position before cwd,
                # descriptor handoff and exec. The parent keeps advancing its
                # real deadline and cleaning up the actual process group.
                POSIX::_exit(23) if $mode eq 'early_exit';
                sleep 60;
            }
            return $result;
        };
        my $result = supervise_process(
            schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'probe',
            bounds => {timeout_seconds => 1, capture_limit_bytes => 65_536},
            containment => 'process_supervisor_probe_group', cwd => $workspace,
            argv => [$perl, '-e', 'print "command-executed\n"'],
        );
        is($result->{status}, $mode eq 'timeout' ? 'timed_out' : 'nonzero_exit',
            "$mode preserves the real failure class");
        is($result->{stdout}, '', "$mode cannot execute the command");
        ok(!defined($result->{first_output_monotonic_ns}),
            "$mode has no observed command output");
        ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone},
            "$mode leaves no child or group");
        if ($mode eq 'timeout') {
            for my $field (qw(exec_handoff_monotonic_ns spawn_to_exec_ns
                    execution_ns exec_to_first_output_ns)) {
                ok(!defined($result->{$field}),
                    "unobserved $field stays unknown after cleanup")
                    or diag explain $result;
            }
        }
        else {
            is($result->{exit_code}, 23, 'direct pre-exec exit remains nonzero');
            ok(defined($result->{exec_handoff_monotonic_ns}),
                'observed EOF can also come from child death before exec');
        }
    }
};

subtest 'shared engine kills a TERM-resistant process tree at its wall' => sub {
    my $program = File::Spec->catfile($workspace, 'timeout');
    write_executable($program, <<'PROGRAM');
#!/usr/bin/env perl
use strict;
use warnings;
$SIG{TERM} = 'IGNORE';
my $child = fork();
die "fork failed: $!" unless defined $child;
if ($child == 0) {
    $SIG{TERM} = 'IGNORE';
    sleep 60;
    exit 0;
}
$| = 1;
print STDOUT "descendant=$child\n";
sleep 60;
exit 0;
PROGRAM
    my $result = supervise_process(
        schema => 'fsmgen.test.process_supervisor_probe.v1',
        stage => 'probe',
        bounds => {
            timeout_seconds => 1,
            capture_limit_bytes => 65_536,
        },
        containment => 'process_supervisor_probe_group',
        cwd => $workspace,
        argv => [$perl, $program],
    );
    is($result->{status}, 'timed_out', 'first deadline remains failed');
    ok($result->{timed_out}, 'timeout evidence is explicit');
    ok($result->{cleanup}{term_sent}, 'TERM reaches the complete process group');
    ok($result->{cleanup}{kill_sent}, 'TERM resistance escalates to KILL');
    ok($result->{cleanup}{leader_reaped}, 'timed-out leader is reaped');
    ok($result->{cleanup}{group_gone}, 'timed-out group is proved gone');
    my ($descendant) = $result->{stdout} =~ /descendant=([0-9]+)/;
    ok(defined($descendant), 'hostile fixture reports its descendant');
    if (defined $descendant) {
        my $alive = 1;
        for (1 .. 100) {
            $alive = kill(0, $descendant) ? 1 : 0;
            last unless $alive;
            sleep(0.02);
        }
        ok(!$alive, 'hostile descendant leaves no process residue');
    }
};

subtest 'cleanup cannot block while waiting for an unreapable leader' => sub {
    my $probe = File::Spec->catfile($workspace, 'unreapable-leader');
    write_executable($probe, <<'PROBE');
use strict;
use warnings;
use JSON::PP qw(encode_json);
our $blocking_wait = 0;
BEGIN {
    *CORE::GLOBAL::waitpid = sub {
        if ($_[1] == 0) {
            $blocking_wait = 1;
            die "blocking wait bypasses cleanup deadline\n";
        }
        return 0;
    };
    # This oracle creates no process and must never signal a real PID.
    *CORE::GLOBAL::kill = sub { return 1 };
}
require FSM::Support::ProcessSupervisor;
my $clock = 0;
no warnings 'redefine';
local *FSM::Support::ProcessSupervisor::clock_gettime = sub { $clock += 0.25 };
local *FSM::Support::ProcessSupervisor::sleep = sub {};
local *FSM::Support::ProcessSupervisor::_group_alive = sub { return 1 };
my $cleanup = FSM::Support::ProcessSupervisor::_new_cleanup(1, 'probe');
my ($reaped, $status) = (0, undef);
my $finished = eval {
    FSM::Support::ProcessSupervisor::_terminate_owned_process(
        42, \$reaped, \$status, $cleanup,
    );
    1;
};
print encode_json({
    finished => $finished ? 1 : 0, error => "$@",
    blocking_wait => $blocking_wait, cleanup => $cleanup,
});
PROBE
    my $outer = supervise_process(
        schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'probe',
        bounds => {timeout_seconds => 10, capture_limit_bytes => 65_536},
        containment => 'process_supervisor_probe_group', cwd => $repo_root,
        argv => [$perl, '-Iperl', $probe],
    );
    ok($outer->{ok}, 'isolated mock oracle returns under a real deadline')
        or diag explain $outer;
    my $observed = eval { decode_json($outer->{stdout}) };
    ok(ref($observed) eq 'HASH', 'oracle returns structured evidence') or return;
    ok($observed->{finished}, 'cleanup returns when its grace expires')
        or diag $observed->{error};
    ok(!$observed->{blocking_wait}, 'cleanup never asks for a blocking wait');
    ok(!$observed->{cleanup}{leader_reaped}, 'unreapable leader remains unreaped');
    ok(!$observed->{cleanup}{group_gone}, 'surviving group remains explicitly present');
    ok($observed->{cleanup}{term_sent}, 'cleanup first attempts TERM');
    ok($observed->{cleanup}{kill_sent}, 'cleanup escalates to KILL');
};

subtest 'asynchronous capture and cleanup steps never wait inside the engine' => sub {
    my $probe = File::Spec->catfile($workspace, 'nonblocking-advancement');
    write_executable($probe, <<'PROBE');
use strict;
use warnings;
use JSON::PP qw(encode_json);
use Time::HiRes ();
use FSM::Support::ProcessSupervisor ();
my $owner = $$;
my $mode = shift @ARGV;
my $state;
END {
    local $?;
    if ($$ == $owner && $state && $state->{phase} ne 'finished') {
        FSM::Support::ProcessSupervisor::_terminate_owned_process(
            $state->{pid}, \$state->{leader_reaped},
            \$state->{leader_status}, $state->{cleanup},
        );
    }
}
$SIG{ALRM} = sub { die "independent advancement oracle deadline\n" };
alarm 8;
my $code = $mode eq 'timeout'
    ? '$SIG{TERM} = "IGNORE"; $| = 1; print "ready\n"; sleep 30;'
    : 'select undef, undef, undef, 0.1; print STDOUT "out\x00\xff\n"; print STDERR "err\n";';
$state = FSM::Support::ProcessSupervisor::_start_supervision({
    schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'probe',
    bounds => {timeout_seconds => 1, capture_limit_bytes => 65_536},
    containment => 'process_supervisor_probe_group',
    cwd => FSM::Support::ProcessSupervisor::repository_root(),
    argv => [$^X, '-e', $code],
});
my $read_ready = IO::Select->can('can_read');
my $finished = eval {
    while ($state->{phase} ne 'finished') {
        {
            no warnings 'redefine';
            local *FSM::Support::ProcessSupervisor::sleep = sub {
                die "advancement attempted to sleep\n";
            };
            local *IO::Select::can_read = sub {
                die "advancement attempted a blocking select\n"
                    unless defined($_[1]) && $_[1] == 0;
                return $read_ready->(@_);
            };
            # Deliberately broken drivers prove each independent trap is live.
            FSM::Support::ProcessSupervisor::sleep(0.01)
                if $mode eq 'control_sleep';
            $state->{select}->can_read(0.01) if $mode eq 'control_wait';
            FSM::Support::ProcessSupervisor::_advance_supervision($state);
        }
        Time::HiRes::sleep(0.01) if $state->{phase} ne 'finished';
    }
    1;
};
my $error = "$@";
alarm 0;
print encode_json({
    finished => $finished ? 1 : 0, error => $error,
    command_pid => $state->{pid}, result => $state->{result},
});
exit($finished ? 0 : 1);
PROBE
    for my $mode (qw(success timeout control_sleep control_wait)) {
        my $outer = supervise_process(
            schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'probe',
            bounds => {timeout_seconds => 15, capture_limit_bytes => 65_536},
            containment => 'process_supervisor_probe_group', cwd => $repo_root,
            argv => [$perl, '-Iperl', $probe, $mode],
        );
        my $observed = eval { decode_json($outer->{stdout}) };
        ok(ref($observed) eq 'HASH', "$mode returns independent oracle evidence")
            or do { diag explain $outer; next };
        if ($mode =~ /^control_/) {
            is($outer->{status}, 'nonzero_exit', "$mode rejects a blocking driver");
            ok(!$observed->{finished}, "$mode cannot claim advancement completed");
            like($observed->{error}, $mode eq 'control_sleep'
                ? qr/advancement attempted to sleep/
                : qr/advancement attempted a blocking select/,
                "$mode exercises the intended trap");
        }
        else {
            ok($outer->{ok} && $observed->{finished}, "$mode advances without hidden waiting")
                or diag explain $outer;
            my $result = $observed->{result};
            is($result->{status}, $mode eq 'success' ? 'success' : 'timed_out',
                "$mode preserves the closed command outcome");
            ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone},
                "$mode finishes both cleanup obligations");
            if ($mode eq 'success') {
                is($result->{stdout}, "out\x00\xff\n", 'asynchronous capture preserves raw bytes');
                is($result->{stderr}, "err\n", 'asynchronous capture keeps streams separate');
            }
            else {
                ok($result->{cleanup}{term_sent} && $result->{cleanup}{kill_sent},
                    'cleanup advances through both graces without sleeping in a step');
            }
        }
        my $pid = $observed->{command_pid};
        ok(defined($pid) && $pid > 0, "$mode identifies its actual command") or next;
        ok(!kill(0, $pid), "$mode independently leaves no command process");
        ok(!kill(0, -$pid), "$mode independently leaves no command group");
    }
};

subtest 'prospective coordinator can reserve group identity through command cleanup' => sub {
    my $probe = File::Spec->catfile($workspace, 'group-reservation');
    write_executable($probe, <<'PROBE');
use strict;
use warnings;
use JSON::PP qw(encode_json);
use POSIX qw(setpgid WNOHANG _exit);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);

my $owner = $$;
my $caller_group = getpgrp(0);
my ($reservation, $command);
my %reaped;
my $group_retired = 0;
my $caller_terms = 0;
my %observed;
$SIG{TERM} = sub { ++$caller_terms };
$SIG{ALRM} = sub { die "reservation oracle deadline\n" };

sub byte {
    my ($fh, $expected, $write) = @_;
    my $value = '';
    my $count = $write ? syswrite($fh, $expected, 1)
        : sysread($fh, $value, 1);
    die "reservation oracle handoff failed\n"
        unless defined($count) && $count == 1
            && ($write || $value eq $expected);
}

sub reap {
    my ($pid) = @_;
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + 2;
    while (clock_gettime(CLOCK_MONOTONIC) < $deadline) {
        my $waited = waitpid($pid, WNOHANG);
        if ($waited == $pid) {
            my $status = $?;
            $reaped{$pid} = 1;
            return $status;
        }
        die "reservation oracle lost child status\n" if $waited == -1;
        sleep(0.01);
    }
    die "reservation oracle reap deadline\n";
}

# Only the original oracle process may clean up. Never release the reserved
# numeric identity before its last possible group signal; never signal a
# direct child after harvesting it. Children also have their own final alarm.
END {
    local $?; # Reaping fixture children must not overwrite the oracle exit.
    if ($$ == $owner) {
        alarm 0;
        kill 'KILL', -$reservation
            if $reservation && !$reaped{$reservation} && !$group_retired;
        for my $pid (grep { defined($_) && $_ > 0 } ($command, $reservation)) {
            next if $reaped{$pid};
            kill 'KILL', $pid;
            eval { reap($pid) };
        }
    }
}

alarm 8;
my $finished = eval {
    pipe(my $reserve_read, my $reserve_write) or die "reserve pipe: $!";
    pipe(my $reply_read, my $reply_write) or die "reply pipe: $!";
    $reservation = fork();
    die "reservation fork: $!" unless defined $reservation;
    if (!$reservation) {
        $SIG{ALRM} = $SIG{TERM} = 'DEFAULT';
        alarm 6;
        close $reserve_write;
        close $reply_read;
        my $ok = eval {
            my $set = setpgid(0, 0);
            die "reservation group admission" unless defined($set)
                && $set == 0 && getpgrp(0) == $$;
            byte($reply_write, 'G', 1);
            byte($reserve_read, 'M', 0);
            unless ($ARGV[0] eq 'unmoved') {
                $set = setpgid(0, $caller_group);
                die "reservation group departure" unless defined($set)
                    && $set == 0 && getpgrp(0) == $caller_group;
            }
            byte($reply_write, 'M', 1);
            byte($reserve_read, 'X', 0);
            1;
        };
        _exit($ok ? 0 : 91);
    }
    close $reserve_read;
    close $reply_write;
    byte($reply_read, 'G', 0);

    pipe(my $command_read, my $command_write) or die "command pipe: $!";
    pipe(my $ready_read, my $ready_write) or die "ready pipe: $!";
    $command = fork();
    die "command fork: $!" unless defined $command;
    if (!$command) {
        $SIG{ALRM} = 'DEFAULT';
        $SIG{TERM} = sub { _exit(19) };
        alarm 6;
        close $reserve_write;
        close $reply_read;
        close $command_write;
        close $ready_read;
        my $ok = eval {
            my $set = setpgid(0, $reservation);
            die "command group admission" unless defined($set)
                && $set == 0 && getpgrp(0) == $reservation;
            byte($ready_write, 'C', 1);
            byte($command_read, 'X', 0);
            1;
        };
        _exit($ok ? 0 : 92);
    }
    close $command_read;
    close $ready_write;
    $observed{reservation_pid} = $reservation;
    $observed{command_pid} = $command;
    byte($ready_read, 'C', 0);
    byte($reserve_write, 'M', 1);
    byte($reply_read, 'M', 0);
    $observed{group_present} = kill(0, -$reservation) ? 1 : 0;
    if ($ARGV[0] eq 'cancel') {
        $observed{term_sent} = kill('TERM', -$reservation) ? 1 : 0;
    }
    else {
        byte($command_write, 'X', 1);
    }
    $observed{command_status} = reap($command);
    $observed{group_gone} = kill(0, -$reservation) ? 0 : 1;
    die "command group survived\n" unless $observed{group_gone};
    $group_retired = 1;
    $observed{reservation_live_after_group} = kill(0, $reservation) ? 1 : 0;
    byte($reserve_write, 'X', 1);
    $observed{reservation_status} = reap($reservation);
    $observed{children_reaped} = $reaped{$command} && $reaped{$reservation} ? 1 : 0;
    $observed{caller_group_unchanged} = getpgrp(0) == $caller_group ? 1 : 0;
    1;
};
alarm 0;
$observed{finished} = $finished ? 1 : 0;
$observed{error} = "$@";
$observed{caller_terms} = $caller_terms;
print encode_json(\%observed);
exit($finished ? 0 : 1);
PROBE
    for my $mode (qw(normal cancel)) {
        my $outer = supervise_process(
            schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'probe',
            bounds => {timeout_seconds => 15, capture_limit_bytes => 65_536},
            containment => 'process_supervisor_probe_group', cwd => $repo_root,
            argv => [$perl, $probe, $mode],
        );
        ok($outer->{ok}, "$mode kernel oracle completes under its independent wall")
            or diag explain $outer;
        my $observed = eval { decode_json($outer->{stdout}) };
        ok(ref($observed) eq 'HASH', "$mode returns structured evidence") or next;
        ok($observed->{finished}, "$mode completes every handoff")
            or diag $observed->{error};
        ok($observed->{group_present}, "$mode command retains the reserved group");
        is($observed->{command_status}, $mode eq 'cancel' ? 19 << 8 : 0,
            "$mode preserves the direct child's actual wait status");
        ok($observed->{group_gone}, "$mode proves group absence before identity release");
        ok($observed->{reservation_live_after_group}, "$mode retains its reservation through group cleanup");
        is($observed->{reservation_status}, 0, "$mode releases the reservation normally");
        ok($observed->{children_reaped}, "$mode reaps both exact direct children");
        ok($observed->{caller_group_unchanged}, "$mode leaves caller membership unchanged");
        is($observed->{caller_terms}, 0, "$mode never signals the caller group");
        ok($observed->{term_sent}, 'cancellation reaches only the command group')
            if $mode eq 'cancel';
        ok($outer->{cleanup}{group_gone}, "$mode oracle leaves no outer group");
    }
    my $control = supervise_process(
        schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'probe',
        bounds => {timeout_seconds => 15, capture_limit_bytes => 65_536},
        containment => 'process_supervisor_probe_group', cwd => $repo_root,
        argv => [$perl, $probe, 'unmoved'],
    );
    is($control->{status}, 'nonzero_exit', 'unmoved reservation is a failed control');
    my $observed = eval { decode_json($control->{stdout}) };
    ok(ref($observed) eq 'HASH', 'negative control returns evidence') or return;
    ok(!$observed->{group_gone}, 'negative control detects the reservation inside the command group');
    like($observed->{error} // '', qr/command group survived/,
        'negative control fails at the actual group-absence check');
    for my $field (qw(command_pid reservation_pid)) {
        my $pid = $observed->{$field};
        ok(defined($pid) && $pid > 0, "negative control identifies $field") or next;
        ok(!kill(0, $pid), "negative control cleaned its exact $field before returning");
    }
};

subtest 'task-acceptance adapter seals path, command, interpreter, and bounds' => sub {
    my $fixture = create_project_tempdir(
        purpose => 'task-acceptance-tests',
    );
    my $path_trap = File::Spec->catdir($workspace, 'path-trap');
    make_path($path_trap);
    write_executable(File::Spec->catfile($path_trap, 'git'), "#!/bin/sh\nexit 97\n");
    write_executable(File::Spec->catfile($path_trap, 'bash'), "#!/bin/sh\nexit 98\n");
    local $ENV{PATH} = join(':', $path_trap, $ENV{PATH});
    my %environment_before = %ENV;
    my $git = run_fixture_git($fixture, ['init', '-q']);
    is_deeply(\%ENV, \%environment_before, 'fixture Git leaves the environment exact');
    ok($git->{ok}, 'load-time canonical Git ignores later PATH replacement');
    is($git->{schema}, 'fsmgen.test.task_acceptance_fixture_result.v1', 'fixture result schema is exact');
    is($git->{stage}, 'fixture_git', 'fixture Git stage is exact');
    is($git->{timeout_seconds}, 10, 'fixture Git wall cannot be widened');
    is($git->{capture_limit_bytes}, 1_048_576, 'fixture Git capture cannot be widened');
    is($git->{cleanup}{containment}, 'task_acceptance_fixture_process_group', 'fixture containment is exact');

    my $inadmissible = run_fixture_git($fixture, ['status']);
    is($inadmissible->{status}, 'invocation_error', 'unregistered Git subcommand fails closed');
    ok(!$inadmissible->{cleanup}{leader_started}, 'rejected Git command starts no process');
    my $global = run_fixture_git(
        $fixture, ['config', '--global', 'user.name', 'unsafe'],
    );
    is($global->{status}, 'invocation_error', 'global Git configuration fails closed');
    ok(!$global->{cleanup}{leader_started}, 'rejected global configuration starts no process');
    my $outside = run_fixture_git($repo_root, ['init', '-q']);
    is($outside->{status}, 'invocation_error', 'non-fixture repository fails closed');
    ok(!$outside->{cleanup}{leader_started}, 'rejected repository starts no process');

    my $checker = File::Spec->catfile(
        $fixture, 'scripts', 'check_task_acceptance.sh',
    );
    write_executable($checker, <<'CHECKER');
#!/usr/bin/env bash
set -u
values=()
for value in "${values[@]}"; do
  printf '%s\n' "${value}"
done
printf 'modern-bash-ready\n'
CHECKER
    my $checked = run_fixture_checker($fixture);
    ok($checked->{ok}, 'load-time canonical Bash ignores later PATH replacement and env handoff');
    is($checked->{stdout}, "modern-bash-ready\n", 'checker output is exact');
    is($checked->{stage}, 'task_acceptance_checker', 'checker stage is exact');
    is($checked->{timeout_seconds}, 10, 'checker wall cannot be widened');
    is($checked->{capture_limit_bytes}, 4_194_304, 'checker capture cannot be widened');

    write_executable($checker, "#!/usr/bin/env bash\nexit 7\n");
    my $failed = run_fixture_checker($fixture);
    is($failed->{status}, 'nonzero_exit', 'checker nonzero remains failed');
    is($failed->{exit_code}, 7, 'checker exit code is exact');
    ok($failed->{cleanup}{group_gone}, 'failed checker group is gone');
};

subtest 'Rust parity rejects unresolved and misleading tool identities before building' => sub {
    for my $mode (qw(directory proxy_nonzero proxy_decoy)) {
        # Keep each source path unchanged for its entire mode lifetime so a
        # delayed path-only policy record cannot name a later proxy's bytes.
        my $mode_workspace = File::Temp->newdir(
            'fsmgen-XXXXXXXX',
            DIR => ensure_project_artifact_dir(qw(tmp process-supervisor-tests)),
            CLEANUP => 0,
        );
        my $probe = File::Spec->catfile($mode_workspace, 'rust-tool-resolution');
        write_executable($probe, <<'PROBE');
use strict;
use warnings;
use JSON::PP qw(encode_json);
$ENV{PATH} = shift @ARGV;
require FSM::Test::RustParityRuntime;
print encode_json(FSM::Test::RustParityRuntime::run_rust_parity());
PROBE
        my $bin = File::Spec->catdir($mode_workspace, 'rust-tools');
        my $cargo = File::Spec->catfile($bin, 'cargo');
        my $prepared;
        if ($mode eq 'directory') {
            make_path($cargo);
        }
        else {
            $prepared = prepare_rust_proxy("$mode_workspace", $mode);
            # Preserve preparation identity before runtime can fail or cleanup
            # can remove these files. This is not a loaded-image observation.
            diag 'Rust proxy preparation: ' . JSON::PP->new->ascii->canonical->encode({
                mode => $mode, prepared => $prepared,
            });
            ok($prepared->{ok}, "$mode proxy preparation succeeds") or do {
                diag explain $prepared;
                diag 'Retained proxy workspace: ' . File::Spec->abs2rel("$mode_workspace", $repo_root);
                return;
            };
            my $proxy = File::Spec->catfile($repo_root, $prepared->{executable});
            symlink $proxy, $cargo or die "cannot make Cargo proxy: $!";
        }
        my $outer = supervise_process(
            schema => 'fsmgen.test.rust_tool_resolution_probe.v1', stage => 'probe',
            bounds => {timeout_seconds => 20, capture_limit_bytes => 65_536},
            containment => 'rust_tool_resolution_probe_group', cwd => $repo_root,
            argv => [$perl, '-Iperl', '-It/lib', $probe, $bin],
        );
        ok($outer->{ok}, "$mode probe terminates under the independent watcher") or diag explain $outer;
        my $result = eval { decode_json($outer->{stdout}) };
        ok(ref($result) eq 'HASH' && ref($result->{stages}) eq 'ARRAY' && scalar(@{$result->{stages}}),
            "$mode returns a structured adapter result") or do {
                diag 'Retained proxy workspace: ' . File::Spec->abs2rel("$mode_workspace", $repo_root);
                return;
            };
        ok(!$result->{ok}, "$mode fails closed");
        is($result->{failure_stage}, $mode eq 'proxy_decoy' ? 'tool_admission' : 'tool_resolution', "$mode has exact stage attribution");
        is($result->{status}, $mode eq 'proxy_nonzero' ? 'nonzero_exit' : 'invocation_error', "$mode preserves failure class")
            or diag('Rust tool-resolution result: ' . JSON::PP->new->ascii->canonical->encode({
                mode => $mode, adapter => $result, outer => $outer,
            }));
        ok(!grep($_->{stage} eq 'cargo_build', @{$result->{stages}}), "$mode cannot start Cargo build");
        ok(!grep(!$_->{cleanup}{group_gone}, @{$result->{stages}}), "$mode leaves no owned process group");
        my @owners = ($outer, @{$result->{stages}});
        push @owners, $prepared->{compilation} if $prepared && defined($prepared->{compilation});
        retire_rust_proxy_workspace("$mode_workspace", @owners) or return;
    }
};

subtest 'legacy RAM-guard capture controls expose signal loss and blocked streams' => sub {
    # Exact pre-repair run_guard body: helper SHA-256
    # cb9a8d6d041b37a50abd7bbcea3740018b1777bd52e5ff26856d96fe014fdebe.
    # This intentionally broken fixture runs only inside the bounded hostile oracle.
    my $legacy = <<'LEGACY';
use strict;
use warnings;
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use JSON::PP qw(encode_json);
my ($fake_bin, $guard) = @ARGV;
sub run_guard {
    my (%args) = @_;
    local %ENV = %ENV;
    $ENV{PATH} = $fake_bin . ':' . $ENV{PATH};
    $ENV{FSMGEN_TEST_TOTAL_BYTES} = 4_096_000;
    $ENV{FSMGEN_TEST_VM_STAT_FILE} = $args{vm_stat_file};

    my @command = (
        $guard,
        '--host-max-pct', '88',
        '--process-max-rss-mb', '4096',
        '--poll-seconds', '0.02',
        '--grace-seconds', '0',
        '--',
        @{$args{command}},
    );

    my $stderr_fh = gensym();
    my $pid = open3(my $stdin_fh, my $stdout_fh, $stderr_fh, @command);
    close $stdin_fh;
    local $/;
    my $stdout = <$stdout_fh> // '';
    my $stderr = <$stderr_fh> // '';
    waitpid($pid, 0);
    return ($? >> 8, $stdout, $stderr);
}

my @result = run_guard(vm_stat_file => 'unused', command => ['unused']);
my $raw = $?;
print encode_json({projected_exit => $result[0], stdout => $result[1],
    stderr => $result[2], native_wait_status => $raw});
LEGACY
    my $probe = File::Spec->catfile($workspace, 'legacy-ram-capture');
    write_executable($probe, "#!$perl\n$legacy");
    for my $mode (qw(signal streams)) {
        my $producer = File::Spec->catfile($workspace, "legacy-ram-$mode");
        my $progress = File::Spec->catfile($workspace, "legacy-ram-$mode-progress");
        my $prefix = "#!$perl\nmy \$progress = pack('H*', '" . unpack('H*', $progress) . "');\n";
        my $body = <<'PRODUCER';
use strict;
use warnings;
open my $marker, '>', $progress or die $!;
print {$marker} "entered\n" or die $!;
close $marker or die $!;
PRODUCER
        if ($mode eq 'signal') {
            $body .= '$| = 1; print "signal-body-entered\n"; kill q(TERM), $$; die q(signal did not terminate);';
        }
        else {
            $body .= <<'STREAMS';
print STDERR 'x' x 262_144 or die $!;
open my $marker_after, '>>', $progress or die $!;
print {$marker_after} "drained\n" or die $!;
close $marker_after or die $!;
print STDOUT "stdout-after-stderr\n";
STREAMS
        }
        write_executable($producer, $prefix . $body);
        my $result = supervise_process(
            schema => 'fsmgen.test.legacy_ram_capture_probe.v1', stage => 'legacy_capture',
            bounds => {timeout_seconds => 5, capture_limit_bytes => 65_536},
            containment => 'legacy_ram_capture_probe_group', cwd => $workspace,
            argv => [$perl, $probe, $workspace, $producer],
        );
        my $progress_exists = -f $progress;
        my $progress_content = $progress_exists ? (slurp($progress) // '') : undef;
        my $entry_ok = ok($progress_exists, "$mode producer independently records main entry");
        my $progress_ok = !$progress_exists || is($progress_content, "entered\n",
            "$mode progress excludes an assumed completed write");
        if (!$entry_ok || !$progress_ok) {
            my $source = slurp($producer);
            diag('Legacy main-entry result: ' . JSON::PP->new->ascii->canonical->encode({
                mode => $mode,
                fixture => {path => File::Spec->abs2rel($producer, $repo_root),
                    size_bytes => length($source), sha256 => sha256_hex($source)},
                marker => {path => File::Spec->abs2rel($progress, $repo_root),
                    regular_file => $progress_exists ? 1 : 0, content => $progress_content},
                result => $result,
            }));
        }
        if ($mode eq 'signal') {
            ok($result->{ok}, 'old capture wrapper returns despite its signalled child') or diag explain $result;
            my $record = eval { decode_json($result->{stdout}) };
            ok($record, 'old wrapper retains its independently observed wait status in the probe');
            if ($record) {
                is($record->{native_wait_status}, 15, 'native wait reports the actual TERM signal');
                is($record->{projected_exit}, 0, 'old shifted projection falsely reports exit zero');
                is($record->{stdout}, "signal-body-entered\n", 'signalled child reached its body');
            }
        }
        else {
            is($result->{status}, 'timed_out', 'old sequential reader cannot drain stderr while waiting for stdout')
                or diag explain $result;
        }
        ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone},
            "$mode negative control leaves no owned group");
    }
};

subtest 'policy adapters exclusively own low-level test supervision' => sub {
    my $support = slurp(File::Spec->catfile(
        $repo_root, qw(perl FSM Support ProcessSupervisor.pm),
    ));
    my $wrapper = slurp(File::Spec->catfile(
        $repo_root, qw(t lib FSM Test ProcessSupervisor.pm),
    ));
    like(
        $support,
        qr/^package FSM::Support::ProcessSupervisor;/m,
        'the reviewed mechanics have one production support owner',
    );
    unlike(
        $wrapper,
        qr/\b(?:fork|waitpid|setpgid|IO::Select|_terminate_owned_process)\b/,
        'the test compatibility module contains no copied process mechanics',
    );
    like(
        $wrapper,
        qr/FSM::Support::ProcessSupervisor::supervise_process\s*\(/,
        'the test compatibility boundary delegates process creation',
    );
    unlike(
        $support,
        qr/FSM::VIAL::Backend::ProcessSupervisor/,
        'the shared engine does not borrow VIAL lifecycle authority',
    );
    like(
        capture_error(sub {
            FSM::Support::ProcessSupervisor::supervise_process();
        }),
        qr/caller-sealed; 'main' cannot launch a process/,
        'a caller outside the two sealed policy boundaries cannot launch',
    );

    my @production_owner;
    for my $path (glob File::Spec->catfile(
            $repo_root, qw(perl FSM Support *.pm),
        )) {
        next if $path =~ /ProcessSupervisor\.pm\z/;
        my $source = slurp($path);
        push @production_owner, File::Spec->abs2rel($path, $repo_root)
            if $source =~ /\bsupervise_process\s*\(/;
    }
    is_deeply(
        [sort @production_owner],
        ['perl/FSM/Support/HDLExternalValidation.pm'],
        'only HDL external validation holds production supervision authority',
    );

    my $t1545 = slurp(File::Spec->catfile(
        $repo_root, 't', '1545-task-acceptance-doctrine.t',
    ));
    unlike($t1545, qr/IPC::Cmd|run\s*\(\s*command\s*=>/, 't1545 has no direct IPC launch');
    like($t1545, qr/use FSM::Test::TaskAcceptanceFixtureRuntime qw\(/, 't1545 imports its sealed adapter');
    like($t1545, qr/\brun_fixture_git\s*\(/, 'fixture Git is adapter-owned');
    like($t1545, qr/\brun_fixture_checker\s*\(/, 'fixture checker is adapter-owned');

    my $t1467 = slurp(File::Spec->catfile($repo_root, 't', '1467-rust-portable-api-check-parity.t'));
    unlike($t1467, qr/IPC::Cmd|run\s*\(\s*command\s*=>/, 'T1467 has no unbounded IPC launch');
    like($t1467, qr/use FSM::Test::RustParityRuntime qw\(run_rust_parity\)/, 'Rust parity uses its sealed adapter');

    my $t1595 = slurp(File::Spec->catfile($repo_root, 't', '1595-agent-runtime-ram-guard-macos-metric.t'));
    unlike($t1595, qr/IPC::Open3|\bopen3\s*\(|\bwaitpid\s*\(/,
        'T1595 has no direct IPC or unbounded wait');
    like($t1595, qr/use FSM::Test::RamGuardFixtureRuntime qw\(/,
        'RAM-guard fixtures use their sealed adapter');

    my @owner;
    for my $path (glob File::Spec->catfile(
            $repo_root, qw(t lib FSM Test *.pm),
        )) {
        next if $path =~ /ProcessSupervisor\.pm\z/;
        my $source = slurp($path);
        push @owner, File::Spec->abs2rel($path, $repo_root)
            if $source =~ /\bsupervise_process\s*\(/;
    }
    is_deeply(
        [sort @owner],
        [qw(
            t/lib/FSM/Test/HDLBehaviorRuntime.pm
            t/lib/FSM/Test/RamGuardFixtureRuntime.pm
            t/lib/FSM/Test/RustParityRuntime.pm
            t/lib/FSM/Test/RustProxyFixture.pm
            t/lib/FSM/Test/TaskAcceptanceFixtureRuntime.pm
            t/lib/FSM/Test/TaskAcceptanceIndexRuntime.pm
            t/lib/FSM/Test/VerilatorRuntime.pm
        )],
        'only sealed policy adapters call the low-level supervisor',
    );

    my @direct_test;
    for my $path (glob File::Spec->catfile($repo_root, 't', '*.t')) {
        my $source = slurp($path);
        push @direct_test, File::Spec->abs2rel($path, $repo_root)
            if $source =~ /\bsupervise_process\s*\(/;
    }
    is_deeply(
        [sort @direct_test],
        ['t/1669-task-acceptance-fixture-runtime.t'],
        'only the hostile-process oracle bypasses a sealed policy adapter',
    );
};

subtest 'private wire uses exact network bytes and rejects malformed frames' => sub {
    my $wire = 'FSM::Support::ProcessSupervisor::Wire';
    my $encode = $wire->can('encode_frame');
    my $decode = $wire->can('decode_frame');
    my $run = pack('C*', 0 .. 15);
    my $token = pack('C*', 128 .. 159);
    my $spawn = {
        type => 'SPAWN', started_ns => '18446744073709551615',
        schema => 's', stage => 't', containment => 'c', cwd => '.',
        timeout_seconds => 10, capture_limit_bytes => 1_048_576, umask => 0027,
        argv => ['p', '', "\xff"], environment => [['A', ''], ['B', "x\ny"]],
    };
    # Literal expected bodies do not call the codec's packing helpers.
    my @cases = (
        ['client', {type => 'HELLO', run => $run, parent => 17, token => $token},
            "\x01\x01" . $run . pack('H*', '00000011') . $token],
        ['coordinator', {type => 'READY', run => $run, parent => 17},
            "\x01\x02" . $run . pack('H*', '00000011')],
        ['client', $spawn, pack('H*',
            '0103ffffffffffffffff000000017300000001740000000163000000012e'
            . '0000000a00100000000000170000000300000001700000000000000001ff'
            . '00000002000000014100000000000000014200000003780a79')],
        ['coordinator', {type => 'ACCEPT', job => 2}, pack('H*', '010400000002')],
        ['coordinator', {type => 'STDOUT', job => 2, offset => '4294967296', chunk => "\0\xff"},
            pack('H*', '01050000000200000001000000000000000200ff')],
        ['coordinator', {type => 'STDERR', job => 2, offset => 0, chunk => ''},
            pack('H*', '010600000002000000000000000000000000')],
        ['client', {type => 'CANCEL', job => 2}, pack('H*', '010700000002')],
        ['client', {type => 'ACK', job => 2}, pack('H*', '010900000002')],
        ['coordinator', {type => 'REJECT', class => 1, diagnostic => 'invalid request'},
            pack('H*', '010a010000000f') . 'invalid request'],
        ['coordinator', {type => 'STDOUT_END', job => 2, offset => '18446744073709551615'},
            pack('H*', '010b00000002ffffffffffffffff')],
        ['coordinator', {type => 'STDERR_END', job => 2, offset => 0},
            pack('H*', '010c000000020000000000000000')],
    );
    for my $case (@cases) {
        my ($direction, $message, $body) = @$case;
        my $frame = pack('N', length($body)) . $body;
        is($encode->($direction, $message), $frame, "$message->{type} has independent exact wire bytes");
        is_deeply($decode->($direction, $frame), $message, "$message->{type} decodes the independent vector");
        is($wire->can('payload_size')->(substr($frame, 0, 4)), length($body),
            "$message->{type} admits only its declared payload");
        is($wire->can('frame_size')->($direction, substr($frame, 0, 6)), length($frame),
            "$message->{type} validates direction and cap before the body");
        my $other = $direction eq 'client' ? 'coordinator' : 'client';
        like(capture_error(sub { $decode->($other, $frame) }), qr/wrong direction/,
            "$message->{type} rejects the opposite direction");
        # Every byte boundary is deliberately incomplete; no framing retry can
        # turn a prefix into a complete message or accept concatenated frames.
        my @accepted_prefix;
        for my $end (0 .. length($frame) - 1) {
            push @accepted_prefix, $end unless length capture_error(sub {
                $decode->($direction, substr($frame, 0, $end));
            });
        }
        is_deeply(\@accepted_prefix, [], "$message->{type} rejects every truncated prefix");
        like(capture_error(sub { $decode->($direction, $frame . 'x') }), qr/trailing data/,
            "$message->{type} rejects data after its frame");
        my $extra = pack('N', length($body) + 1) . $body . 'x';
        like(capture_error(sub { $decode->($direction, $extra) }), qr/trailing message fields/,
            "$message->{type} rejects unknown fields inside its frame");
    }
    for my $case (
        ['unknown version', pack('H*', '000000020201'), qr/unknown wire version/],
        ['unknown type', pack('H*', '00000002010d'), qr/unknown message type/],
        ['short payload', pack('N', 1) . "\x01\x01", qr/payload length/],
        ['request cap plus one', pack('N', 1_048_577) . "\x01\x03", qr/payload length/],
        ['control cap plus one', pack('N', 8_193) . "\x01\x01", qr/payload exceeds/],
    ) {
        like(capture_error(sub { $wire->can('frame_size')->('client', $case->[1]) }),
            $case->[2], "$case->[0] rejects before requesting body storage");
    }
    my $bad_vector = pack('H*',
        '01030000000000000000000000017300000001740000000163000000012e'
        . '00000001000000010000000000001001');
    like(capture_error(sub { $decode->('client', pack('N', length($bad_vector)) . $bad_vector) }),
        qr/declared vector exceeds/, 'vector count rejects before reading or allocating its members');
    substr($bad_vector, -4) = pack('NN', 1, 65_537);
    like(capture_error(sub { $decode->('client', pack('N', length($bad_vector)) . $bad_vector) }),
        qr/declared scalar exceeds/, 'scalar length rejects before reading or allocating its bytes');
    my $unknown = {%$spawn, unrecognized => 1};
    like(capture_error(sub { $encode->('client', $unknown) }), qr/record fields/,
        'encoder rejects unknown request metadata');
    like(capture_error(sub { $decode->('other', $encode->('client', $spawn)) }), qr/unknown direction/,
        'unknown direction fails closed');
    my $flagged_frame = $encode->('client', $spawn);
    utf8::upgrade($flagged_frame);
    like(capture_error(sub { $decode->('client', $flagged_frame) }), qr/unflagged octets/,
        'decoder never silently transcodes wire bytes');
};

subtest 'wire snapshot, scalar, vector and context limits have boundary controls' => sub {
    my $wire = 'FSM::Support::ProcessSupervisor::Wire';
    my $encode = $wire->can('encode_frame');
    my $decode = $wire->can('decode_frame');
    my $base = {
        type => 'SPAWN', started_ns => 0, schema => 's', stage => 't', containment => 'c',
        cwd => '.', timeout_seconds => 1, capture_limit_bytes => 1, umask => 0,
        argv => ['p'], environment => [],
    };
    my @cases = (
        ['argv count', argv => [ ('') x 4_096 ], [ ('') x 4_097 ]],
        ['scalar bytes', argv => ['x' x 65_536], ['x' x 65_537]],
        ['snapshot total', argv => [('x' x 65_536) x 8], [('x' x 65_536) x 8, 'x']],
        ['environment count', environment => [map { [sprintf('K%04d', $_), ''] } 1 .. 4_096],
            [map { [sprintf('K%04d', $_), ''] } 1 .. 4_097]],
        ['metadata bytes', schema => 's' x 256, 's' x 257],
        ['cwd bytes', cwd => 'x' x 4_096, 'x' x 4_097],
        ['timeout u32', timeout_seconds => '4294967295', '4294967296'],
        ['capture u32', capture_limit_bytes => '4294967295', '4294967296'],
        ['umask bits', umask => 511, 512],
        ['monotonic u64', started_ns => '18446744073709551615', '18446744073709551616'],
    );
    for my $case (@cases) {
        my ($name, $field, $at, $over) = @$case;
        my $admitted = {%$base, $field => $at};
        is_deeply($decode->('client', $encode->('client', $admitted)), $admitted,
            "$name inclusive boundary passes");
        like(capture_error(sub { $encode->('client', {%$base, $field => $over}) }), qr/private process wire:/,
            "$name boundary plus one rejects");
    }
    for my $chunk_size (16_384, 16_385) {
        my $message = {type => 'STDOUT', job => 1, offset => 0, chunk => "\0" x $chunk_size};
        my $error = capture_error(sub { $decode->('coordinator', $encode->('coordinator', $message)) });
        $chunk_size == 16_384 ? is($error, '', 'full binary stream chunk passes')
            : like($error, qr/byte bound/, 'stream chunk boundary plus one rejects');
    }
    my $rejection = {type => 'REJECT', class => 2, diagnostic => 'x' x 2_048};
    is_deeply($decode->('coordinator', $encode->('coordinator', $rejection)), $rejection,
        'rejection diagnostic boundary passes');
    $rejection->{diagnostic} .= 'x';
    like(capture_error(sub { $encode->('coordinator', $rejection) }), qr/byte bound/,
        'diagnostic boundary plus one rejects');
    for my $mutation (
        [argv => []], [argv => [undef]], [argv => [{}]], [argv => ["a\0b"]],
        [schema => ''], [stage => "\xff"], [containment => "\0"],
        [environment => [['', 'v']]], [environment => [['A=B', 'v']]],
        [environment => [["A\0B", 'v']]], [environment => [['A', "v\0"]]],
        [environment => [['B', 'v'], ['A', 'v']]], [environment => [['A', 'x'], ['A', 'y']]],
        [environment => [['A']]], [environment => [['A', 'v', 'extra']]],
        [cwd => '/outside'], [cwd => '../escape'], [cwd => 'a/./b'], [cwd => 'a//b'],
        [cwd => 'a/../b'], [cwd => 'a/'], [timeout_seconds => 0], [timeout_seconds => '01'],
        [started_ns => '-1'], [started_ns => '1e9'], [started_ns => '1.0'],
    ) {
        my ($field, $value) = @$mutation;
        like(capture_error(sub { $encode->('client', {%$base, $field => $value}) }),
            qr/private process wire:/, "$field malformed value rejects");
    }
    my $colliding_key = chr(0xe9);
    utf8::upgrade($colliding_key);
    like(capture_error(sub { $encode->('client', {%$base,
        environment => [[$colliding_key, 'x'], ["\xc3\xa9", 'y']]}) }),
        qr/unique and byte ordered/, 'environment key collisions after byte conversion reject');
    my $mixed_overflow = {%$base, argv => [('x' x 65_536) x 8], environment => [['K', '']]};
    like(capture_error(sub { $encode->('client', $mixed_overflow) }), qr/aggregate byte bound/,
        'argv and environment share one aggregate budget');
    my $flagged_chunk = 'text';
    utf8::upgrade($flagged_chunk);
    like(capture_error(sub { $encode->('coordinator',
        {type => 'STDOUT', job => 1, offset => 0, chunk => $flagged_chunk}) }), qr/unflagged octets/,
        'stream bytes never pass through argv text conversion');
    # Decoder hostility is constructed independently of the rejecting encoder.
    my $frame = $encode->('client', {%$base, environment => [['A', 'x'], ['B', 'y']]});
    substr($frame, -6, 1) = 'A';
    like(capture_error(sub { $decode->('client', $frame) }), qr/unique and byte ordered/,
        'raw duplicate environment keys reject at the receiver');
    my $context = {directory => '.artifacts/tmp/process-coordinator/run_1',
        run => "\0" x 16, parent => 1, token => "\xff" x 32};
    my $encoded = $wire->can('encode_context')->($context);
    my $expected = '1:' . unpack('H*', $context->{directory}) . ':' . ('00' x 16) . ':1:' . ('ff' x 32);
    is($encoded, $expected, 'context has independently constructed canonical bytes');
    is_deeply($wire->can('decode_context')->($expected), $context, 'context syntax decodes exactly');
    my $endpoint_root = '.artifacts/tmp/process-coordinator/';
    my $max_directory = $endpoint_root . ('x' x (256 - length($endpoint_root)));
    is(length($max_directory), 256, 'endpoint boundary is independently constructed');
    my $largest = {%$context, directory => $max_directory, parent => '4294967295'};
    is_deeply($wire->can('decode_context')->($wire->can('encode_context')->($largest)), $largest,
        'maximum endpoint and job ID pass');
    for my $mutation (
        [directory => $max_directory . 'x'], [directory => '.artifacts/tmp/process-coordinator/..'],
        [directory => '.artifacts/tmp/process-coordinator/a/b'], [directory => '.artifacts/tmp/foreign/x'],
        [run => 'x' x 15], [token => 'x' x 33], [parent => 0], [parent => '4294967296'],
    ) {
        my ($field, $value) = @$mutation;
        like(capture_error(sub { $wire->can('encode_context')->({%$context, $field => $value}) }),
            qr/private process wire:/, "context rejects invalid $field");
    }
    for my $invalid (undef, '', '1:', '2:' . substr($expected, 2), uc($expected),
            $expected . ':extra', 'x' x 8_193, $expected =~ s/:1:/:01:/r) {
        like(capture_error(sub { $wire->can('decode_context')->($invalid) }), qr/private process wire:/,
            'invalid inherited context has no fallback admission');
    }
    my $limits = $wire->can('limits')->();
    $limits->{jobs} = 999;
    is_deeply($wire->can('limits')->(), {
        jobs => 8, depth => 8, children => 16, connections => 8, backlog => 8,
        descriptors => 128, context => 8_192, cwd => 4_096, endpoint => 256,
        request => 1_048_576, control => 8_192, argv => 4_096, environment => 4_096,
        scalar => 65_536, snapshot => 524_288, metadata => 256, chunk => 16_384,
        stream_queue => 65_536, control_queue => 16_384, diagnostic => 2_048,
        handshake_seconds => 2, delivery_seconds => 2, idle_seconds => 0.05,
    }, 'selected finite limits are defensive and cannot be widened by callers');
};

subtest 'snapshot bytes match the existing direct exec and preserve caller context' => sub {
    my $wire = 'FSM::Support::ProcessSupervisor::Wire';
    local %ENV = %ENV;
    my $flagged = chr(0xe9);
    utf8::upgrade($flagged);
    $ENV{FSMGEN_WIRE_ORACLE_BYTES} = "\xff\xe9\n'\"";
    $ENV{FSMGEN_WIRE_ORACLE_FLAGGED} = $flagged;
    $ENV{FSMGEN_WIRE_ORACLE_EMPTY} = '';
    delete $ENV{FSMGEN_WIRE_ORACLE_ABSENT};
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $ENV{FSMGEN_WIRE_ORACLE_WIDE} = chr(0x100);
    }
    my @arguments = ('', "a b\n'\"", "\xff\xe9", $flagged, chr(0x100), chr(0x1f600));
    my $observer = <<'OBSERVER';
use strict; use warnings; use JSON::PP;
binmode STDOUT, ':raw';
my %env = map { $_ => [exists($ENV{$_}) ? 1 : 0,
    exists($ENV{$_}) ? unpack('H*', $ENV{$_}) : undef] }
    map { 'FSMGEN_WIRE_ORACLE_' . $_ } qw(BYTES FLAGGED WIDE EMPTY ABSENT);
print JSON::PP->new->ascii->canonical->encode({
    argv => [map { unpack('H*', $_) } @ARGV], environment => \%env, mask => umask(),
});
OBSERVER
    my $request = {
        schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'wire_oracle',
        bounds => {timeout_seconds => 10, capture_limit_bytes => 65_536},
        containment => 'process_supervisor_probe_group', cwd => $repo_root,
        argv => [$perl, '-e', $observer, @arguments],
    };
    my %environment_before = %ENV;
    my $cwd_before = Cwd::getcwd();
    my $mask_before = umask();
    my @flags_before = map { utf8::is_utf8($_) ? 1 : 0 } @{$request->{argv}};
    # This arm goes straight through the pre-existing fork/exec implementation,
    # with the original scalars and ENV. It never imports a conversion rule.
    my $direct = supervise_process(%$request);
    ok($direct->{ok}, 'independent original exec returns successfully') or diag explain $direct;
    my $snapshot = $wire->can('snapshot_request')->($request, 123_456_789);
    is_deeply(\%ENV, \%environment_before, 'snapshot does not mutate caller environment');
    is(Cwd::getcwd(), $cwd_before, 'snapshot leaves caller cwd unchanged');
    is(umask(), $mask_before, 'snapshot observes umask without changing it');
    is_deeply([map { utf8::is_utf8($_) ? 1 : 0 } @{$request->{argv}}], \@flags_before,
        'snapshot does not change caller scalar flags');
    {
        local %ENV = map { (sprintf('K%04d', $_), '') } 1 .. 4_097;
        like(capture_error(sub { $wire->can('snapshot_request')->($request, 0) }),
            qr/too many environment pairs/, 'live environment count rejects before snapshot construction');
    }
    {
        local %ENV = map { ('K' . $_, 'v' x 65_536) } 1 .. 8;
        like(capture_error(sub { $wire->can('snapshot_request')->($request, 0) }),
            qr/aggregate byte bound/, 'live environment byte sum rejects while accumulating the snapshot');
    }
    like(capture_error(sub { $wire->can('snapshot_request')->({%$request, cwd => 'no-such-wire-directory'}, 0) }),
        qr/not an admitted repository directory/, 'snapshot rejects a nonexistent cwd');
    is_deeply(\%ENV, \%environment_before, 'failed snapshot admission leaves the environment unchanged');
    ok(!grep(utf8::is_utf8($_), @{$snapshot->{argv}}), 'decoded argv contains only byte strings');
    my $transported;
    {
        local %ENV = map { @$_ } @{$snapshot->{environment}};
        $transported = supervise_process(%$request, argv => $snapshot->{argv});
    }
    ok($transported->{ok}, 'transported bytes execute successfully') or diag explain $transported;
    is($transported->{stdout}, $direct->{stdout},
        'kernel exec observes identical argv, environment presence/values and umask');
    my $observed = decode_json($direct->{stdout});
    is_deeply($observed->{argv}, ['', '6120620a2722', 'ffe9', 'c3a9', 'c480', 'f09f9880'],
        'independent literal byte oracle distinguishes bytes from flagged text');
    is_deeply($observed->{environment}{FSMGEN_WIRE_ORACLE_FLAGGED}, [1, 'e9'],
        'live ENV magic already converts low flagged text differently from argv');
    is_deeply($observed->{environment}{FSMGEN_WIRE_ORACLE_WIDE}, [1, 'c480'],
        'wide environment text reaches exec as encoded bytes');
    is_deeply($observed->{environment}{FSMGEN_WIRE_ORACLE_EMPTY}, [1, ''], 'empty value is present');
    is_deeply($observed->{environment}{FSMGEN_WIRE_ORACLE_ABSENT}, [0, undef], 'absent value stays absent');
    my @broken = @{$snapshot->{argv}};
    # Deliberately transcode an already-admitted argument twice. The same
    # transport round trip would accept it, but the independent exec oracle must
    # detect that it changes what the program receives.
    utf8::upgrade($broken[-1]);
    utf8::encode($broken[-1]);
    my $control = supervise_process(%$request, argv => \@broken);
    ok($control->{ok}, 'deliberately wrong conversion still executes normally');
    isnt($control->{stdout}, $direct->{stdout}, 'direct-exec comparison rejects double encoding');
    for my $result ($direct, $transported, $control) {
        ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone},
            'each independent exec leaves its group and child closed');
    }
    my $result_metadata = {%$direct};
    delete @{$result_metadata}{qw(stdout stderr)};
    my $metadata = {result => $result_metadata, reservation_reaped => 1,
        subtree_closed => 1, delivery_complete => 0};
    my $json = JSON::PP->new->ascii->canonical->encode($metadata);
    my $body = pack('CCNN', 1, 8, 1, length($json)) . $json;
    my $expected = pack('N', length($body)) . $body;
    my $message = {type => 'RESULT', job => 1, metadata => $metadata};
    is($wire->can('encode_frame')->('coordinator', $message), $expected,
        'actual producer result has independent RESULT framing');
    is_deeply($wire->can('decode_frame')->('coordinator', $expected), $message,
        'actual producer result retains its complete closed metadata');
    for my $change (
        sub { $_[0]{delivery_complete} = 1 },
        sub { $_[0]{reservation_reaped} = 0 },
        sub { $_[0]{subtree_closed} = 0 },
        sub { $_[0]{result}{ok} = '1' },
        sub { $_[0]{result}{cleanup}{group_gone} = 0 },
        sub { $_[0]{result}{stdout} = 'hidden stream' },
        sub { $_[0]{result}{signal} = 9 },
        sub { $_[0]{result}{capture_limit_bytes} = 0 },
        sub { $_[0]{result}{stdout_bytes} = 65_537 },
        sub { $_[0]{result}{spawn_to_exec_ns} += 1 },
        sub { $_[0]{result}{status} = 'nonzero_exit' },
        sub { $_[0]{result}{schema_version} = 2 },
    ) {
        my $mutated = decode_json($json);
        $change->($mutated);
        my $encoded = JSON::PP->new->ascii->canonical->encode($mutated);
        my $raw_body = pack('CCNN', 1, 8, 1, length($encoded)) . $encoded;
        like(capture_error(sub { $wire->can('decode_frame')->('coordinator',
            pack('N', length($raw_body)) . $raw_body) }), qr/private process wire:/,
            'receiver rejects inconsistent or malformed terminal metadata');
    }
    for my $bad_json (' ' . $json, $json =~ s/\A\{/\{"delivery_complete":0,/r) {
        my $raw_body = pack('CCNN', 1, 8, 1, length($bad_json)) . $bad_json;
        like(capture_error(sub { $wire->can('decode_frame')->('coordinator',
            pack('N', length($raw_body)) . $raw_body) }), qr/not canonical JSON/,
            'receiver rejects whitespace and duplicate JSON keys');
    }
};

done_testing();

sub retire_rust_proxy_workspace {
    my ($directory, @owners) = @_;
    # A group disappearing is not enough if its leader remains unreaped.
    # Failed pre-launch stages have no leader; missing evidence stays unknown.
    my $settled = @owners && !grep {
        my $cleanup = ref($_) eq 'HASH' ? $_->{cleanup} : undef;
        ref($cleanup) ne 'HASH' || (grep {
            !defined($cleanup->{$_}) || ref($cleanup->{$_}) || $cleanup->{$_} !~ /\A[01]\z/
        } qw(leader_started leader_reaped group_gone)) || !$cleanup->{group_gone}
            || ($cleanup->{leader_started} && !$cleanup->{leader_reaped})
    } @owners;
    unless ($settled) {
        fail('proxy workspace requires complete process cleanup');
        diag 'Retained proxy workspace: ' . File::Spec->abs2rel($directory, $repo_root);
        return 0;
    }
    my $errors;
    my $removed = eval { remove_tree($directory, {error => \$errors}); 1 };
    my $gone = $removed && !@$errors && !-e $directory && !-l $directory;
    ok($gone, 'settled proxy workspace is removed') or diag explain $errors;
    return $gone;
}

sub capture_error {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 };
    return "$@";
}

sub write_executable {
    my ($path, $content) = @_;
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $content or die "cannot populate $path: $!";
    close $fh or die "cannot close $path: $!";
    chmod 0755, $path or die "cannot make $path executable: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $source = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $source;
}
