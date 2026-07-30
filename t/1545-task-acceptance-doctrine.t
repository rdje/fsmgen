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
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker_source = File::Spec->catfile($repo_root, 'scripts', 'check_task_acceptance.sh');

subtest 'documentation-only staged work validates config and remains exempt' => sub {
    my $repo = make_fixture_repo();
    write_file($repo, 'README.md', "fixture docs changed\n");
    git_ok($repo, 'add', '--', 'README.md');

    my ($ok, $output) = run_checker($repo);
    ok($ok, 'checker accepts a docs-only staged change') or diag($output);
    like($output, qr/no configured implementation change staged/, 'exemption is explicit');
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
    my ($ok, undef, undef, $stdout, $stderr) = run(command => $command);
    if (!$ok) {
        my $output = join('', @{$stdout || []}, @{$stderr || []});
        die "$label failed: $output";
    }
}

sub run_checker {
    my ($repo) = @_;
    my $checker = File::Spec->catfile($repo, 'scripts', 'check_task_acceptance.sh');
    my ($ok, undef, undef, $stdout, $stderr) = run(command => [$checker]);
    my $output = join('', @{$stdout || []}, @{$stderr || []});
    return ($ok ? 1 : 0, $output);
}
