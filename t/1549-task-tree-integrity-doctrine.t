#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker = File::Spec->catfile(
    $repo_root, 'scripts', 'check_task_tree_integrity.pl'
);

subtest 'live active task trees satisfy the integrity contract' => sub {
    my ($ok, $output) = run_checker($repo_root);
    ok($ok, 'live task-tree integrity passes') or diag($output);
    like(
        $output,
        qr/all active task-tree invariants hold \(trees=[1-9][0-9]*, nodes=[1-9][0-9]*\)/,
        'live result reports measured tree and node counts',
    );
};

subtest 'valid minimal active tree passes' => sub {
    my $fixture = make_fixture(valid_task());
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'valid active tree passes') or diag($output);
    like($output, qr/trees=1, nodes=3/, 'fixture result reports exact counts');
};

my @negative_cases = (
    [
        'missing direct-child reference',
        sub { my $task = valid_task(); $task =~ s/, EXAMPLE\.2//; return $task; },
        qr/container EXAMPLE omits direct children EXAMPLE\.2/,
    ],
    [
        'extra direct-child reference',
        sub { my $task = valid_task(); $task =~ s/EXAMPLE\.2`/EXAMPLE.2, EXAMPLE.3`/; return $task; },
        qr/container EXAMPLE lists nonexistent direct children EXAMPLE\.3/,
    ],
    [
        'malformed direct-child reference',
        sub { my $task = valid_task(); $task =~ s/EXAMPLE\.2`/EXAMPLE.02`/; return $task; },
        qr/container EXAMPLE has malformed direct child EXAMPLE\.02/,
    ],
    [
        'duplicate node ID',
        sub {
            my $task = valid_task();
            $task =~ s/^## Current Frontier/leaf('EXAMPLE.2', 'done') . "## Current Frontier"/me;
            return $task;
        },
        qr/duplicate node ID EXAMPLE\.2/,
    ],
    [
        'unknown status',
        sub { my $task = valid_task(); $task =~ s/Status: `done`/Status: `completed`/; return $task; },
        qr/node EXAMPLE\.1 has unknown status completed/,
    ],
    [
        'leaf missing commit evidence field',
        sub {
            my $task = valid_task();
            $task =~ s/(^- ID: `EXAMPLE\.2`\n.*?^  Verification: `pending`\n)^  Commit: `pending`\n/$1/ms;
            return $task;
        },
        qr/leaf EXAMPLE\.2 must have exactly one Commit field/,
    ],
    [
        'malformed active root status',
        sub { my $task = valid_task(); $task =~ s/Status: `active`/Status: `done`/; return $task; },
        qr/indexed active tree root EXAMPLE has status done/,
    ],
    [
        'orphan descendant node',
        sub {
            my $task = valid_task();
            $task =~ s/^## Current Frontier/leaf('EXAMPLE.9.1', 'pending') . "## Current Frontier"/me;
            return $task;
        },
        qr/node EXAMPLE\.9\.1 has missing parent EXAMPLE\.9/,
    ],
    [
        'done container with nonterminal child',
        sub {
            my $task = valid_task();
            my $old = leaf('EXAMPLE.1', 'done');
            my $new = "- ID: `EXAMPLE.1`\n"
                . "  Status: `done`\n"
                . "  Goal: `Complete EXAMPLE.1.`\n"
                . "  Children: `EXAMPLE.1.1`\n\n"
                . leaf('EXAMPLE.1.1', 'pending');
            $task =~ s/\Q$old\E/$new/;
            return $task;
        },
        qr/done container EXAMPLE\.1 has nonterminal direct children EXAMPLE\.1\.1/,
    ],
);

for my $case (@negative_cases) {
    my ($label, $mutate, $expected) = @{$case};
    subtest $label => sub {
        my $fixture = make_fixture($mutate->());
        my ($ok, $output) = run_checker($fixture);
        ok(!$ok, "$label fails closed");
        like($output, $expected, 'diagnostic is deterministic and actionable');
    };
}

done_testing();

sub valid_task {
    return "# Example\n\n## Task Tree\n\n"
        . "- ID: `EXAMPLE`\n"
        . "  Status: `active`\n"
        . "  Goal: `Exercise task-tree integrity.`\n"
        . "  Children: `EXAMPLE.1, EXAMPLE.2`\n\n"
        . leaf('EXAMPLE.1', 'done')
        . leaf('EXAMPLE.2', 'pending')
        . "## Current Frontier\n";
}

sub leaf {
    my ($id, $status) = @_;
    return "- ID: `$id`\n"
        . "  Status: `$status`\n"
        . "  Goal: `Complete $id.`\n"
        . "  Acceptance: `The fixture is structurally complete.`\n"
        . "  Verification: `pending`\n"
        . "  Commit: `pending`\n\n";
}

sub make_fixture {
    my ($task) = @_;
    my $root = create_project_tempdir(purpose => 'task-tree-integrity-tests');
    write_file(
        $root,
        'docs/TASK_TREE.md',
        "# Index\n\n"
            . "| Tree | Status | Roadmap lane | Current frontier | File |\n"
            . "| --- | --- | --- | --- | --- |\n"
            . "| `EXAMPLE` | `active` | `fixture` | `EXAMPLE.2` | "
            . "[docs/tasks/EXAMPLE.md](docs/tasks/EXAMPLE.md) |\n",
    );
    write_file($root, 'docs/tasks/EXAMPLE.md', $task);
    return $root;
}

sub write_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    make_path(dirname($path));
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub run_checker {
    my ($root) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$checker, '--root', $root],
    );
    my $output = join('', @{$stdout || []}, @{$stderr || []});
    return ($ok ? 1 : 0, $output);
}
