#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use Errno qw(EPERM);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);
use Test::More;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(
    repository_root
    supervise_process
);
use FSM::Test::TaskAcceptanceFixtureRuntime qw(
    run_fixture_checker
    run_fixture_git
);

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
    is($result->{timeout_seconds}, 1, 'selected wall is explicit');
    is($result->{capture_limit_bytes}, 65_536, 'selected capture ceiling is explicit');
    is($result->{cleanup}{containment}, 'process_supervisor_probe_group', 'caller policy owns the containment label');
    ok($result->{cleanup}{leader_reaped}, 'leader is reaped');
    ok($result->{cleanup}{group_gone}, 'process group is gone');
};

subtest 'child containment must be established before exec' => sub {
    my $caller_group = getpgrp(0);
    for my $mode (qw(undefined negative false_success exception)) {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::setpgid = sub {
            $! = EPERM;
            die "injected containment exception\n" if $mode eq 'exception';
            return undef if $mode eq 'undefined';
            return -1 if $mode eq 'negative';
            return 0;
        };
        my $result = supervise_process(
            schema => 'fsmgen.test.process_supervisor_probe.v1',
            stage => 'probe',
            bounds => {timeout_seconds => 1, capture_limit_bytes => 65_536},
            containment => 'process_supervisor_probe_group',
            cwd => $workspace,
            argv => [$perl, '-e', 'print "command-executed\n"'],
        );
        is($result->{status}, 'exec_error', "$mode rejects the exec handoff");
        ok($result->{exec_failed}, "$mode reports failed handoff");
        like($result->{exec_error} // '', qr/process-group containment failed/,
            "$mode identifies the containment boundary");
        is($result->{stdout}, '', "$mode never executes the command");
        ok($result->{cleanup}{leader_reaped}, "$mode reaps the rejected child");
        ok($result->{cleanup}{group_gone}, "$mode leaves no child group");
        is(getpgrp(0), $caller_group, "$mode leaves the caller group unchanged");
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
    my $probe = File::Spec->catfile($workspace, 'rust-tool-resolution');
    write_executable($probe, <<'PROBE');
use strict;
use warnings;
use JSON::PP qw(encode_json);
$ENV{PATH} = shift @ARGV;
require FSM::Test::RustParityRuntime;
print encode_json(FSM::Test::RustParityRuntime::run_rust_parity());
PROBE
    my $bin = File::Spec->catdir($workspace, 'rust-tools');
    make_path(File::Spec->catdir($bin, 'cargo'));
    my $cargo = File::Spec->catfile($bin, 'cargo');
    my $proxy = File::Spec->catfile($bin, 'rustup');
    for my $mode (qw(directory proxy_nonzero proxy_decoy)) {
        if ($mode ne 'directory') {
            rmdir $cargo if -d $cargo;
            unlink $cargo if -l $cargo;
            write_executable($proxy, "#!$perl\n" . ($mode eq 'proxy_nonzero'
                ? "print STDERR qq(resolution-failed\\n); exit 9;\n"
                : "print qq(relative-cargo\\n);\n"));
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
        ok(ref($result) eq 'HASH', "$mode returns a structured adapter result") or return;
        ok(!$result->{ok}, "$mode fails closed");
        is($result->{failure_stage}, $mode eq 'proxy_decoy' ? 'tool_admission' : 'tool_resolution', "$mode has exact stage attribution");
        is($result->{status}, $mode eq 'proxy_nonzero' ? 'nonzero_exit' : 'invocation_error', "$mode preserves failure class");
        ok(!grep($_->{stage} eq 'cargo_build', @{$result->{stages}}), "$mode cannot start Cargo build");
        ok(!grep(!$_->{cleanup}{group_gone}, @{$result->{stages}}), "$mode leaves no owned process group");
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
            t/lib/FSM/Test/RustParityRuntime.pm
            t/lib/FSM/Test/TaskAcceptanceFixtureRuntime.pm
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

done_testing();

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
