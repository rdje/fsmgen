#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use JSON::PP ();
use POSIX ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Test::TaskAcceptanceFixtureRuntime qw(
    run_fixture_checker
    run_fixture_git
);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker_source = File::Spec->catfile($repo_root, 'scripts', 'check_task_acceptance.sh');

subtest 'documentation-only staged work validates config and remains exempt' => sub {
    my $repo = make_fixture_repo();
    write_file($repo, 'README.md', "fixture docs changed\n");
    git_ok($repo, 'add', '--', 'README.md');

    my ($ok, $output, undef, $observation) = run_checker($repo);
    ok($ok, 'checker accepts a docs-only staged change') or diag($output);
    like($output, qr/no configured implementation change staged/, 'exemption is explicit');
    ok(ref($observation) eq 'HASH' && $observation->{checker_diagnostic_observed},
        'unmodified checker output proves native diagnostic progress');
};

subtest 'project-native literal and ERE evidence passes in one fresh task file' => sub {
    my $repo = make_fixture_repo();
    write_file($repo, 'perl/Foo.pm', "package Foo;\nsub changed { 1 }\n1;\n");
    write_file($repo, 'docs/tasks/OWNER.md', complete_checklist());
    git_ok($repo, 'add', '--', 'perl/Foo.pm', 'docs/tasks/OWNER.md');

    my ($ok, $output) = run_checker($repo);
    ok($ok, 'checker accepts fresh complete box-scoped evidence') or diag($output);
    like($output, qr/root=fsmgen_trace/, 'matched root-cause family is reported');
    like($output, qr/no-regression=prove_summary/, 'matched no-regression family is reported');
};

subtest 'implementation change without staged task owner fails closed' => sub {
    my $repo = make_fixture_repo();
    write_file($repo, 'perl/Foo.pm', "package Foo;\nsub changed { 1 }\n1;\n");
    git_ok($repo, 'add', '--', 'perl/Foo.pm');

    my ($ok, $output) = run_checker($repo);
    ok(!$ok, 'checker rejects code without a staged task file');
    like($output, qr/no owning docs\/tasks\/\*\.md file is staged/, 'failure names the owner requirement');
};

subtest 'missing or unchecked required box fails closed' => sub {
    my $repo = make_fixture_repo();
    write_file($repo, 'perl/Foo.pm', "package Foo;\nsub changed { 1 }\n1;\n");
    my $task = complete_checklist();
    $task =~ s/- \[x\] \*\*ROOT CAUSE/- [ ] **ROOT CAUSE/;
    write_file($repo, 'docs/tasks/OWNER.md', $task);
    git_ok($repo, 'add', '--', 'perl/Foo.pm', 'docs/tasks/OWNER.md');

    my ($ok, $output) = run_checker($repo);
    ok(!$ok, 'checker rejects an unchecked root-cause box');
    like($output, qr/fresh checked ROOT CAUSE box/, 'failure names the missing hard-gated box');
};

subtest 'required boxes cannot be assembled across staged task files' => sub {
    my $repo = make_fixture_repo();
    write_file($repo, 'perl/Foo.pm', "package Foo;\nsub changed { 1 }\n1;\n");
    write_file(
        $repo,
        'docs/tasks/CAUSE.md',
        "# Cause\n\n- [x] **ROOT CAUSE (WHY + WHERE)** — `fsmgen --trace-log case.fsm` identified the branch.\n"
            . "- [x] **ADDRESSED (verified)** — focused replay changed REJECT to PASS.\n",
    );
    write_file(
        $repo,
        'docs/tasks/REGRESSION.md',
        "# Regression\n\n- [x] **NO REGRESSION** — Files=1, Tests=9.\n",
    );
    git_ok($repo, 'add', '--', 'perl/Foo.pm', 'docs/tasks/CAUSE.md', 'docs/tasks/REGRESSION.md');

    my ($ok, $output) = run_checker($repo);
    ok(!$ok, 'checker rejects cross-file checklist assembly');
    like($output, qr/no staged task file independently satisfies/, 'failure states the one-file rule');
};

subtest 'signature outside its own box does not count' => sub {
    my $repo = make_fixture_repo();
    write_file($repo, 'perl/Foo.pm', "package Foo;\nsub changed { 1 }\n1;\n");
    write_file(
        $repo,
        'docs/tasks/OWNER.md',
        "# Owner\n\n"
            . "- [x] **ROOT CAUSE (WHY + WHERE)** — mechanism and locus recorded without a declared token.\n"
            . "- [x] **ADDRESSED (verified)** — `fsmgen --trace-log case.fsm` now passes.\n"
            . "- [x] **NO REGRESSION** — Files=1, Tests=9.\n",
    );
    git_ok($repo, 'add', '--', 'perl/Foo.pm', 'docs/tasks/OWNER.md');

    my ($ok, $output) = run_checker($repo);
    ok(!$ok, 'checker rejects incidental signature text in another box');
    like($output, qr/box-scoped root_cause signature/, 'failure identifies root-cause scoping');
};

subtest 'old checked checklist cannot satisfy a later implementation slice' => sub {
    my $repo = make_fixture_repo(baseline_task => complete_checklist());
    write_file($repo, 'perl/Foo.pm', "package Foo;\nsub changed { 1 }\n1;\n");
    append_file($repo, 'docs/tasks/OWNER.md', "\nUnrelated current-slice note.\n");
    git_ok($repo, 'add', '--', 'perl/Foo.pm', 'docs/tasks/OWNER.md');

    my ($ok, $output) = run_checker($repo);
    ok(!$ok, 'checker rejects stale checked boxes');
    like($output, qr/fresh checked ROOT CAUSE box/, 'failure identifies freshness rather than content absence');
};

subtest 'malformed registries fail even for otherwise documentation-only work' => sub {
    my @cases = (
        [
            'invalid path ERE',
            'doctrine/task_acceptance/change_paths.tsv',
            "path_ere\tdescription\n([\tbroken expression\n",
            qr/invalid POSIX ERE/,
        ],
        [
            'unknown signature match mode',
            'doctrine/task_acceptance/evidence_signatures.tsv',
            "scope\tfamily\tmatch\tcase\tpattern\tdescription\n"
                . "root_cause\ttrace\tglob\tsensitive\t--trace-log\tbad mode\n"
                . "no_regression\tprove\tliteral\tsensitive\tAll tests successful\tprove\n",
            qr/unknown match mode/,
        ],
        [
            'missing required root-cause scope',
            'doctrine/task_acceptance/evidence_signatures.tsv',
            "scope\tfamily\tmatch\tcase\tpattern\tdescription\n"
                . "no_regression\tprove\tliteral\tsensitive\tAll tests successful\tprove\n",
            qr/declares no root_cause signatures/,
        ],
    );

    for my $case (@cases) {
        my ($label, $path, $contents, $expected) = @{$case};
        my $repo = make_fixture_repo();
        write_file($repo, $path, $contents);
        write_file($repo, 'README.md', "fixture docs changed\n");
        git_ok($repo, 'add', '--', $path, 'README.md');
        my ($ok, $output) = run_checker($repo);
        ok(!$ok, "$label fails closed");
        like($output, $expected, "$label reports an actionable reason");
    }
};

subtest 'unstaged worktree evidence cannot satisfy the staged index' => sub {
    my $repo = make_fixture_repo();
    write_file($repo, 'perl/Foo.pm', "package Foo;\nsub changed { 1 }\n1;\n");
    write_file(
        $repo,
        'docs/tasks/OWNER.md',
        "# Owner\n\n- [x] **ROOT CAUSE (WHY + WHERE)** — no declared evidence yet.\n"
            . "- [x] **ADDRESSED (verified)** — replay passes.\n"
            . "- [x] **NO REGRESSION** — Files=1, Tests=9.\n",
    );
    git_ok($repo, 'add', '--', 'perl/Foo.pm', 'docs/tasks/OWNER.md');
    my $with_unstaged_evidence = complete_checklist();
    write_file($repo, 'docs/tasks/OWNER.md', $with_unstaged_evidence);

    my ($ok, $output) = run_checker($repo);
    ok(!$ok, 'checker ignores unstaged worktree evidence');
    like($output, qr/box-scoped root_cause signature/, 'failure reflects the staged snapshot');
};

subtest 'failed fixture Git diagnostics retain the complete supervisor result' => sub {
    my $repo = make_fixture_repo();
    my $real_git = \&run_fixture_git;
    my $real_setpgid = \&POSIX::setpgid;
    my (@diagnostics, $result, $error);
    {
        no warnings 'redefine';
        local *main::diag = sub { push @diagnostics, @_; return 1; };
        local *main::run_fixture_git = sub {
            $result = $real_git->(@_);
            return $result;
        };
        local *FSM::Support::ProcessSupervisor::setpgid = sub {
            # Keep the parent from creating the group before the child can
            # become a native session leader. The real child setpgid then
            # refuses with EPERM; no Git command is executed or retried.
            return 0 if $_[0] != 0;
            my $session = POSIX::setsid();
            die "native session control failed\n"
                unless defined($session) && $session == $$;
            return $real_setpgid->(@_);
        };
        eval {
            command_ok(['git', '-C', $repo, 'add', '.'], 'stage fixture baseline');
            1;
        } or $error = $@;
    }
    like($error // '', qr/stage fixture baseline failed \(exec_error\)/,
        'original stage failure and status remain visible');
    is($result->{stage}, 'fixture_git', 'failure belongs to the actual Git stage');
    is($result->{status}, 'exec_error', 'native child cannot reach exec');
    like($result->{exec_error} // '', qr/operation=setpgid result=undef errno=/,
        'native containment refusal supplies its own error detail');
    is($result->{stdout}, '', 'pre-exec refusal has no Git stdout');
    is($result->{stderr}, '', 'pre-exec refusal has no Git stderr');

    my @encoded = grep { /^fixture Git result: / } @diagnostics;
    is(scalar(@encoded), 1, 'one complete failed Git diagnostic is emitted') or return;
    $encoded[0] =~ s/\Afixture Git result: //;
    my $record = eval { JSON::PP->new->decode($encoded[0]) };
    ok(ref($record) eq 'HASH', 'diagnostic is recoverable canonical JSON') or return;
    is_deeply($record, $result, 'diagnostic preserves the complete actual result');
    ok($record->{cleanup}{leader_reaped} && $record->{cleanup}{group_gone},
        'native failed control retains completed cleanup evidence');
    my ($pid) = $record->{exec_error} =~ /pid=([0-9]+)/;
    ok(defined($pid), 'native failure identifies its actual child') or return;
    ok(!kill(0, $pid), 'failed native child is independently absent');
};

subtest 'failed checker diagnostics retain the complete supervisor result' => sub {
    my $repo = make_fixture_repo();
    for my $streams (0, 1) {
        write_file($repo, 'scripts/check_task_acceptance.sh',
            ($streams ? "printf 'stdout sentinel'\nprintf 'stderr sentinel' >&2\n" : '')
                . "exit 23\n");
        my (@diagnostics, $ok, $output, $result);
        {
            no warnings 'redefine';
            local *main::diag = sub { push @diagnostics, @_; return 1; };
            ($ok, $output, $result) = run_checker($repo);
        }
        ok(!$ok, 'deliberate nonzero checker remains failed');
        is($output, $streams ? 'stdout sentinelstderr sentinel' : '',
            'checker-output assertions receive only the original streams');
        my $encoded = join('', grep { /^fixture checker result: / } @diagnostics);
        like($encoded, qr/\Afixture checker result: /,
            'failure emits structured evidence even with empty streams');
        $encoded =~ s/\Afixture checker result: //;
        my $record = eval { JSON::PP->new->decode($encoded) };
        ok(ref($record) eq 'HASH', 'diagnostic is a recoverable JSON result');
        next unless ref($record) eq 'HASH';
        is_deeply($record, $result, 'diagnostic preserves every returned result field');
        is($record->{status}, 'nonzero_exit', 'actual wait status is classified');
        is($record->{exit_code}, 23, 'independent shell exit is preserved');
        is($record->{signal}, 0, 'ordinary exit is distinct from a signal');
        like($record->{diagnostic}, qr/exited nonzero/, 'supervisor explanation survives');
        is($record->{stdout}, $streams ? 'stdout sentinel' : '', 'stdout stays separate');
        is($record->{stderr}, $streams ? 'stderr sentinel' : '', 'stderr stays separate');
        ok(defined($record->{started_monotonic_ns})
                && defined($record->{finished_monotonic_ns}),
            'monotonic start and completion evidence survives');
        ok($record->{cleanup}{leader_reaped} && $record->{cleanup}{group_gone},
            'real failed control retains completed cleanup evidence');
    }
};

subtest 'launch observation retains independent identity and honest progress' => sub {
    my $repo = make_fixture_repo();
    write_file($repo, 'scripts/check_task_acceptance.sh',
        "printf 'shell-pid=%s\\n' \"\$\$\"\nexit 23\n");
    my (@diagnostics, $result, $observation);
    {
        no warnings 'redefine';
        local *main::diag = sub { push @diagnostics, @_; return 1; };
        (undef, undef, $result, $observation) = run_checker($repo);
    }
    ok(ref($observation) eq 'HASH', 'launch observation is retained separately') or return;
    my ($shell_pid) = $result->{stdout} =~ /\Ashell-pid=([0-9]+)\n\z/;
    ok(defined($shell_pid), 'Bash independently reports its own process identity') or return;
    is($observation->{child_pid}, $shell_pid, 'observation names the actual executed child');
    is($observation->{parent_pid}, $$, 'observation names the supervising test');
    is($observation->{launch_count}, 1, 'one sealed checker launch is observed');
    ok($observation->{control_eof_observed} && $observation->{first_output_observed},
        'control closure and actual output are independently retained');
    ok(!$observation->{checker_diagnostic_observed},
        'unrelated output cannot impersonate a native checker diagnostic');
    ok($observation->{finished_observed}, 'terminal observation is retained');
    ok(!kill(0, $shell_pid), 'observed child is absent after result delivery');
    my @encoded = grep { /^fixture checker launch: / } @diagnostics;
    is(scalar(@encoded), 1, 'one separate JSON observation is emitted') or return;
    $encoded[0] =~ s/\Afixture checker launch: //;
    is_deeply(JSON::PP->new->decode($encoded[0]), $observation,
        'TAP retains the complete bounded observation');

    my $real_setpgid = \&POSIX::setpgid;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::setpgid = sub {
            my $return = $real_setpgid->(@_);
            POSIX::pause() if $_[0] == 0; # The child cannot reach exec.
            return $return;
        };
        (undef, undef, $result, $observation) = run_checker($repo);
    }
    is($result->{status}, 'timed_out', 'sealed checker deadline remains authoritative');
    is($observation->{launch_count}, 1, 'timed-out attempt is never retried');
    ok($observation->{child_pid}, 'identity survives an empty-output timeout') or return;
    ok(!$observation->{control_eof_observed} && !$observation->{first_output_observed}
            && !$observation->{checker_diagnostic_observed},
        'pre-exec hold never fabricates launch or main progress');
    ok($observation->{cleanup_observed} && $observation->{finished_observed},
        'timeout cleanup and terminal progress remain visible');
    ok(!kill(0, $observation->{child_pid}), 'timed-out child is independently absent');
    ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone},
        'timed-out group cleanup is complete');
};

done_testing();

sub complete_checklist {
    return <<'MARKDOWN';
# Owner

## Acceptance Checklist (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `fsmgen --trace-log case.fsm` identified the failing branch.
- [x] **ADDRESSED (verified)** — the focused replay changed REJECT to PASS.
- [x] **NO REGRESSION** — `prove -Iperl t/focused.t`: Files=1, Tests=9.
MARKDOWN
}

sub valid_change_registry {
    return "path_ere\tdescription\n"
        . "^perl/\tPerl implementation\n"
        . "^scripts/\tChecker implementation\n"
        . "^t/\tExecutable tests\n"
        . "^doctrine/task_acceptance/\tTask-acceptance configuration\n";
}

sub valid_signature_registry {
    return "scope\tfamily\tmatch\tcase\tpattern\tdescription\n"
        . "root_cause\tfsmgen_trace\tliteral\tinsensitive\t--TRACE-LOG\tFSMGen trace command\n"
        . "no_regression\tprove_summary\tere\tsensitive\tFiles=[0-9]+, Tests=[0-9]+\tMeasured prove summary\n";
}

sub make_fixture_repo {
    my (%args) = @_;
    my $repo = create_project_tempdir(purpose => 'task-acceptance-tests');

    write_file($repo, '.gitignore', ".artifacts/\n");
    write_file($repo, 'README.md', "fixture baseline\n");
    write_file($repo, 'perl/Foo.pm', "package Foo;\n1;\n");
    write_file($repo, 'doctrine/task_acceptance/change_paths.tsv', valid_change_registry());
    write_file($repo, 'doctrine/task_acceptance/evidence_signatures.tsv', valid_signature_registry());
    write_file($repo, 'docs/tasks/OWNER.md', $args{baseline_task})
        if defined $args{baseline_task};

    my $checker_destination = File::Spec->catfile($repo, 'scripts', 'check_task_acceptance.sh');
    make_path(dirname($checker_destination));
    copy($checker_source, $checker_destination)
        or die "cannot copy checker into fixture: $!";
    chmod 0755, $checker_destination
        or die "cannot make fixture checker executable: $!";

    command_ok(['git', '-C', $repo, 'init', '-q'], 'initialize fixture repository');
    command_ok(['git', '-C', $repo, 'config', 'user.email', 'fixture@example.invalid'], 'configure fixture email');
    command_ok(['git', '-C', $repo, 'config', 'user.name', 'Fixture'], 'configure fixture name');
    command_ok(['git', '-C', $repo, 'add', '.'], 'stage fixture baseline');
    command_ok(['git', '-C', $repo, 'commit', '-q', '-m', 'fixture baseline'], 'commit fixture baseline');
    return $repo;
}

sub write_file {
    my ($repo, $relative, $contents) = @_;
    my $path = File::Spec->catfile($repo, split m{/}, $relative);
    make_path(dirname($path));
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub append_file {
    my ($repo, $relative, $contents) = @_;
    my $path = File::Spec->catfile($repo, split m{/}, $relative);
    open my $fh, '>>', $path or die "cannot append $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub git_ok {
    my ($repo, @args) = @_;
    command_ok(['git', '-C', $repo, @args], "git @args");
}

sub command_ok {
    my ($command, $label) = @_;
    die "$label requires a git -C fixture command"
        unless ref($command) eq 'ARRAY' && @$command >= 4
            && $command->[0] eq 'git' && $command->[1] eq '-C';
    my $result = run_fixture_git($command->[2], [@{$command}[3 .. $#$command]]);
    if (!$result->{ok}) {
        diag('fixture Git result: ' . JSON::PP->new->ascii->canonical->encode($result));
        die "$label failed ($result->{status}): "
            . $result->{stdout} . $result->{stderr};
    }
}

sub run_checker {
    my ($repo) = @_;
    my $observation = {
        schema => 'fsmgen.test.task_acceptance_launch_observation.v1',
        schema_version => 1,
        parent_pid => $$, child_pid => undef, launch_count => 0,
        control_eof_observed => 0, first_output_observed => 0,
        checker_diagnostic_observed => 0,
        cleanup_observed => 0, finished_observed => 0,
    };
    # Test-private observation of existing state: no new child work, streams,
    # waits, or policy controls. EOF is not proof of exec, and absent output
    # cannot locate a silent child relative to main entry.
    my $observe = sub {
        my ($state) = @_;
        $observation->{control_eof_observed} = 1 if defined $state->{exec_handoff};
        $observation->{first_output_observed} = 1 if defined $state->{first_output};
        if (!$observation->{checker_diagnostic_observed}) {
            for my $stream (qw(stdout stderr)) {
                $observation->{checker_diagnostic_observed} = 1
                    if ($state->{$stream} // '') =~ /^\[task-acceptance\] (?:OK|FAIL):/m;
            }
        }
        $observation->{cleanup_observed} = 1 if $state->{phase} eq 'cleanup';
        $observation->{finished_observed} = 1 if $state->{phase} eq 'finished';
    };
    my $start = \&FSM::Support::ProcessSupervisor::_start_supervision;
    my $advance = \&FSM::Support::ProcessSupervisor::_advance_supervision;
    my $result;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::_start_supervision = sub {
            my $state = $start->(@_);
            if (defined $state->{pid}) {
                $observation->{child_pid} = $state->{pid};
                ++$observation->{launch_count};
            }
            $observe->($state);
            return $state;
        };
        local *FSM::Support::ProcessSupervisor::_advance_supervision = sub {
            my $return = $advance->(@_);
            $observe->($_[0]);
            return $return;
        };
        $result = run_fixture_checker($repo);
    }
    my $output = $result->{stdout} . $result->{stderr};
    # Diagnostics are TAP evidence, never checker output: the existing output
    # assertions must not accidentally match supervisor metadata. Preserve the
    # complete closed record even when the failed child produced no bytes.
    diag('fixture checker result: ' . JSON::PP->new->ascii->canonical->encode($result))
        unless $result->{ok};
    diag('fixture checker launch: ' . JSON::PP->new->ascii->canonical->encode($observation));
    return ($result->{ok} ? 1 : 0, $output, $result, $observation);
}
