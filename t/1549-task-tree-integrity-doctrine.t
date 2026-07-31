#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP;

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
        qr/all active task-tree invariants hold \(trees=[1-9][0-9]*, nodes=[1-9][0-9]*, segments=[0-9]+, compact_terminals=[0-9]+, index_archives=[0-9]+, migrations=[0-9]+\)/,
        'live result reports measured tree, node, segment, terminal, and index-archive counts',
    );
};

subtest 'valid minimal active tree passes unchanged' => sub {
    my $fixture = make_fixture(valid_task());
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'valid active tree passes') or diag($output);
    like(
        $output,
        qr/trees=1, nodes=3, segments=0, compact_terminals=0, index_archives=0, migrations=0/,
        'legacy in-file fixture result reports exact counts',
    );
};

my @legacy_negative_cases = (
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
            my $new = container(
                'EXAMPLE.1', 'done', 'Complete EXAMPLE.1.', ['EXAMPLE.1.1']
            ) . leaf('EXAMPLE.1.1', 'pending');
            $task =~ s/\Q$old\E/$new/;
            return $task;
        },
        qr/done container EXAMPLE\.1 has nonterminal direct children EXAMPLE\.1\.1/,
    ],
);

for my $case (@legacy_negative_cases) {
    my ($label, $mutate, $expected) = @{$case};
    subtest $label => sub {
        expect_failure(make_fixture($mutate->()), $expected, $label);
    };
}

subtest 'exact-source sealed subtree segment passes across files' => sub {
    my $fixture = make_segment_fixture();
    my ($ok, $output) = run_checker($fixture->{root});
    ok($ok, 'sealed segment fixture passes') or diag($output);
    like(
        $output,
        qr/trees=1, nodes=3, segments=1, compact_terminals=0, index_archives=0, migrations=0/,
        'sealed node participates in the combined measured tree',
    );
};

subtest 'segment manifest rejects unknown schema keys' => sub {
    my $fixture = make_segment_fixture();
    mutate_file(
        $fixture->{manifest},
        sub { $_[0] =~ s/"record_type":"segment"/"record_type":"segment","mystery":1/; },
    );
    expect_failure(
        $fixture->{root}, qr/record 2 has unknown key mystery/,
        'unknown manifest key',
    );
};

subtest 'segment manifest enforces its declared bound' => sub {
    my $fixture = make_segment_fixture();
    mutate_file(
        $fixture->{manifest},
        sub { $_[0] =~ s/"max_records":64/"max_records":0/; },
    );
    expect_failure(
        $fixture->{root}, qr/registry max_records must be an integer >=1/,
        'unbounded or zero-cap manifest',
    );
};

subtest 'segment destinations enforce independent per-part bounds' => sub {
    my $fixture = make_segment_fixture();
    mutate_file(
        $fixture->{manifest},
        sub { $_[0] =~ s/"max_segment_bytes":65536/"max_segment_bytes":1/; },
    );
    expect_failure(
        $fixture->{root}, qr/bytes [0-9]+ exceeds max_segment_bytes 1/,
        'oversized segment destination',
    );
};

subtest 'segment destinations enforce independent aggregate bounds' => sub {
    my $fixture = make_segment_fixture();
    mutate_file(
        $fixture->{manifest},
        sub {
            $_[0] =~ s/"max_segment_nodes":1024/"max_segment_nodes":1/;
            $_[0] =~ s/"max_total_nodes":4096/"max_total_nodes":1/;
            my @lines = split /\n/, $_[0];
            my $duplicate = $lines[1];
            $duplicate =~ s/"segment_id":"EXAMPLE\.1"/"segment_id":"EXAMPLE.copy"/;
            $_[0] = join("\n", @lines[0, 1], $duplicate, '');
        },
    );
    expect_failure(
        $fixture->{root}, qr/total segment nodes 2 exceeds max_total_nodes 1/,
        'aggregate segment destination',
    );
};

subtest 'segment paths are repository-relative' => sub {
    my $fixture = make_segment_fixture();
    mutate_file(
        $fixture->{manifest},
        sub { $_[0] =~ s/"path":"[^"]+"/"path":"..\/escape.md"/; },
    );
    expect_failure(
        $fixture->{root}, qr/unsafe or non-Markdown segment path/,
        'unsafe segment path',
    );
};

subtest 'segment digest is fail-closed' => sub {
    my $fixture = make_segment_fixture();
    mutate_file(
        $fixture->{segment},
        sub { $_[0] =~ s/Close sealed work/Alter sealed work/; },
    );
    expect_failure(
        $fixture->{root}, qr/sha256 mismatch/,
        'mutated sealed segment',
    );
};

subtest 'segment nodes must match the exact source revision' => sub {
    my $fixture = make_segment_fixture(segment_goal => 'Different sealed goal.');
    expect_failure(
        $fixture->{root}, qr/segment node EXAMPLE\.1 differs from exact source/,
        'source-divergent segment',
    );
};

subtest 'segment nodes must be terminal' => sub {
    my $fixture = make_segment_fixture(segment_status => 'pending');
    expect_failure(
        $fixture->{root}, qr/segment node EXAMPLE\.1 is not terminal/,
        'nonterminal sealed node',
    );
};

subtest 'sealed terminal evidence cannot remain pending' => sub {
    my $fixture = make_segment_fixture(pending_evidence => 1);
    expect_failure(
        $fixture->{root}, qr/sealed terminal leaf EXAMPLE\.1 has pending verification or commit evidence/,
        'pending sealed evidence',
    );
};

subtest 'version-object use requires a declared retention contract' => sub {
    my $fixture = make_segment_fixture();
    mutate_file(
        $fixture->{manifest},
        sub { $_[0] =~ s/,"retention_contract":"fixture_history"//; },
    );
    expect_failure(
        $fixture->{root}, qr/is missing required key retention_contract/,
        'missing segment retention contract',
    );
};

subtest 'missing history reports owner and recovery action' => sub {
    my $fixture = make_compact_fixture(revision => ('0' x 40));
    expect_failure(
        $fixture->{root},
        qr/retention contract fixture_history owner fixture-maintainers requires recovery: Fetch complete fixture history/,
        'actionable missing-history diagnostic',
    );
};

subtest 'complete migration evidence passes without partition arithmetic' => sub {
    my $fixture = make_migration_fixture();
    my ($ok, $output) = run_checker($fixture->{root});
    ok($ok, 'complete migration fixture passes') or diag($output);
    like($output, qr/migrations=1/, 'one migration proof is measured');
};

subtest 'migration semantic node mismatch fails closed' => sub {
    my $fixture = make_migration_fixture();
    mutate_file(
        $fixture->{migration},
        sub { $_[0] =~ s/"authoritative_nodes":1/"authoritative_nodes":2/; },
    );
    expect_failure(
        $fixture->{root}, qr/does not match sealed semantic node count 1/,
        'migration node-count mismatch',
    );
};

subtest 'migration source identity mismatch fails closed' => sub {
    my $fixture = make_migration_fixture();
    mutate_file(
        $fixture->{migration},
        sub { $_[0] =~ s/"source_sha256":"[0-9a-f]{64}"/"source_sha256":"@{['0' x 64]}"/; },
    );
    expect_failure(
        $fixture->{root}, qr/complete-source digest mismatch/,
        'migration full-source mismatch',
    );
};

subtest 'migration rejects false disjoint arithmetic' => sub {
    my $fixture = make_migration_fixture();
    mutate_file(
        $fixture->{migration},
        sub { $_[0] =~ s/overlapping_non_partition/disjoint_partition/; },
    );
    expect_failure(
        $fixture->{root}, qr/product_relationship must be overlapping_non_partition/,
        'false migration partition',
    );
};

subtest 'migration loss residue fails closed unless retained by content' => sub {
    my $fixture = make_migration_fixture();
    mutate_file(
        $fixture->{migration},
        sub { $_[0] =~ s/"loss_residue_bytes":0/"loss_residue_bytes":1/; },
    );
    expect_failure(
        $fixture->{root}, qr/loss residue declared none but dimensions are nonzero/,
        'unretained loss residue',
    );
};

subtest 'compact completed version-object terminal passes' => sub {
    my $fixture = make_compact_fixture();
    my ($ok, $output) = run_checker($fixture->{root});
    ok($ok, 'compact terminal fixture passes') or diag($output);
    like(
        $output,
        qr/trees=1, nodes=3, segments=0, compact_terminals=1, index_archives=0, migrations=0/,
        'compact terminal reports one exact retrieved subtree',
    );
};

subtest 'exact completed-index version object passes with bounded PNT views' => sub {
    my $fixture = make_index_archive_fixture();
    my ($ok, $output) = run_checker($fixture->{root});
    ok($ok, 'completed-index archive fixture passes') or diag($output);
    like(
        $output,
        qr/trees=1, nodes=3, segments=0, compact_terminals=0, index_archives=1, migrations=0/,
        'one exact completed-index archive is measured',
    );
};

subtest 'completed-index archive verifies exact retrieved digest' => sub {
    my $fixture = make_index_archive_fixture();
    mutate_file(
        $fixture->{manifest},
        sub { $_[0] =~ s/"sha256":"[0-9a-f]{64}"/"sha256":"@{['0' x 64]}"/; },
    );
    expect_failure(
        $fixture->{root}, qr/completed-history digest mismatch/,
        'completed-index digest mismatch',
    );
};

subtest 'completed-index archive rejects unknown schema keys' => sub {
    my $fixture = make_index_archive_fixture();
    mutate_file(
        $fixture->{manifest},
        sub { $_[0] =~ s/"record_type":"version_object"/"mystery":1,"record_type":"version_object"/; },
    );
    expect_failure(
        $fixture->{root}, qr/record 2 has unknown key mystery/,
        'unknown completed-index key',
    );
};

subtest 'completed-index archive enforces its declared bound' => sub {
    my $fixture = make_index_archive_fixture();
    mutate_file(
        $fixture->{manifest},
        sub { $_[0] =~ s/"max_records":1/"max_records":0/; },
    );
    expect_failure(
        $fixture->{root}, qr/registry max_records must be an integer >=1/,
        'unbounded completed-index manifest',
    );
};

subtest 'completed-index manifest requires an archive record' => sub {
    my $fixture = make_index_archive_fixture();
    mutate_file(
        $fixture->{manifest},
        sub { $_[0] =~ s/\n\{[^\n]+\}\n\z/\n/; },
    );
    expect_failure(
        $fixture->{root}, qr/contains no completed-history archive records/,
        'empty completed-index manifest',
    );
};

subtest 'completed-index archive proves exact task-file retrieval' => sub {
    my $fixture = make_index_archive_fixture(missing_source_task => 1);
    expect_failure(
        $fixture->{root}, qr/cannot retrieve .*:docs\/tasks\/MISSING\.md/,
        'missing archived task version object',
    );
};

subtest 'live PNT view rejects terminal row retention' => sub {
    my $fixture = make_index_archive_fixture();
    mutate_file(
        $fixture->{index},
        sub {
            $_[0] =~ s/(\| `EXAMPLE` \| `active` .*\n)/$1
                . "| `ARCHIVED` | `done` | `fixture` | `closed` | "
                . "[docs\/tasks\/ARCHIVED.md](docs\/tasks\/ARCHIVED.md) |\n"/e;
        },
    );
    expect_failure(
        $fixture->{root},
        qr/Active Task Trees row ARCHIVED has status done, expected active/,
        'terminal row retained in live PNT view',
    );
};

subtest 'compact terminal requires retrievable exact revision' => sub {
    my $fixture = make_compact_fixture(revision => ('0' x 40));
    expect_failure(
        $fixture->{root}, qr/cannot retrieve exact version object/,
        'missing compact revision',
    );
};

subtest 'compact terminal verifies retrieved digest' => sub {
    my $fixture = make_compact_fixture(digest => ('0' x 64));
    expect_failure(
        $fixture->{root}, qr/retrieved digest mismatch/,
        'compact digest mismatch',
    );
};

subtest 'compact terminal verifies archived subtree cardinality' => sub {
    my $fixture = make_compact_fixture(node_count => 3);
    expect_failure(
        $fixture->{root}, qr/Archived node count 3 does not match retrieved count 2/,
        'compact node-count mismatch',
    );
};

subtest 'compact terminal rejects nonterminal archived subtree' => sub {
    my $fixture = make_compact_fixture(archived_status => 'active');
    expect_failure(
        $fixture->{root}, qr/retrieves nonterminal node EXAMPLE\.1/,
        'nonterminal archived subtree',
    );
};

subtest 'compact terminal keeps closed live evidence' => sub {
    my $fixture = make_compact_fixture(pending_evidence => 1);
    expect_failure(
        $fixture->{root}, qr/has pending verification or commit evidence/,
        'pending compact evidence',
    );
};

done_testing();

sub valid_task {
    return "# Example\n\n## Task Tree\n\n"
        . container(
            'EXAMPLE', 'active', 'Exercise task-tree integrity.',
            ['EXAMPLE.1', 'EXAMPLE.2']
        )
        . leaf('EXAMPLE.1', 'done')
        . leaf('EXAMPLE.2', 'pending')
        . "## Current Frontier\n";
}

sub source_task_for_segment {
    my (%args) = @_;
    my $status = $args{segment_status} // 'done';
    my $evidence = $args{pending_evidence} ? 'pending' : 'sealed proof passed';
    my $commit = $args{pending_evidence} ? 'pending' : 'EXAMPLE.1: close sealed work';
    return "# Example\n\n## Task Tree\n\n"
        . container(
            'EXAMPLE', 'active', 'Exercise segmented task-tree integrity.',
            ['EXAMPLE.1', 'EXAMPLE.2']
        )
        . closed_leaf(
            'EXAMPLE.1', $status, 'Close sealed work.', $evidence, $commit
        )
        . leaf('EXAMPLE.2', 'pending');
}

sub make_segment_fixture {
    my (%args) = @_;
    my $source = source_task_for_segment(%args);
    my ($root, $revision) = initialize_versioned_fixture($source);

    my $status = $args{segment_status} // 'done';
    my $goal = $args{segment_goal} // 'Close sealed work.';
    my $evidence = $args{pending_evidence} ? 'pending' : 'sealed proof passed';
    my $commit = $args{pending_evidence} ? 'pending' : 'EXAMPLE.1: close sealed work';
    my $node = closed_leaf('EXAMPLE.1', $status, $goal, $evidence, $commit);
    my $segment_contents =
        "# EXAMPLE sealed segment\n\n## Task Tree Segment\n\n$node";
    my $digest = sha256_hex($segment_contents);
    my $segment_relative = "docs/tasks/segments/EXAMPLE/$digest.md";
    write_file($root, $segment_relative, $segment_contents);

    my $manifest_relative = 'docs/tasks/segments/EXAMPLE/manifest.jsonl';
    my $json = JSON::PP->new->canonical;
    my $manifest_contents = join(
        "\n",
        $json->encode({
            record_type => 'registry', schema_version => 1,
            tree_id => 'EXAMPLE', max_records => 64, max_bytes => 65536,
            max_segment_nodes => 1024, max_segment_lines => 8192,
            max_segment_bytes => 65536, max_total_nodes => 4096,
            max_total_lines => 32768, max_total_bytes => 262144,
        }),
        $json->encode({
            record_type => 'segment', schema_version => 1,
            segment_id => 'EXAMPLE.1', path => $segment_relative,
            root_ids => ['EXAMPLE.1'], node_count => 1,
            sha256 => $digest, source_revision => $revision,
            source_path => 'docs/tasks/EXAMPLE.md',
            retention_contract => 'fixture_history',
        }),
        '',
    );
    write_file($root, $manifest_relative, $manifest_contents);

    my $live = "# Example\n\n"
        . "- Segment manifest: `$manifest_relative`\n\n"
        . "## Task Tree\n\n"
        . container(
            'EXAMPLE', 'active', 'Exercise segmented task-tree integrity.',
            ['EXAMPLE.1', 'EXAMPLE.2']
        )
        . leaf('EXAMPLE.2', 'pending');
    write_file($root, 'docs/tasks/EXAMPLE.md', $live);
    return {
        root => $root,
        revision => $revision,
        manifest_relative => $manifest_relative,
        segment_relative => $segment_relative,
        manifest => File::Spec->catfile($root, split m{/}, $manifest_relative),
        segment => File::Spec->catfile($root, split m{/}, $segment_relative),
    };
}

sub make_migration_fixture {
    my $fixture = make_segment_fixture();
    my $task_relative = 'docs/tasks/EXAMPLE.md';
    my $migration_relative = 'docs/tasks/segments/EXAMPLE/migration.jsonl';
    my $task_path = File::Spec->catfile($fixture->{root}, split m{/}, $task_relative);
    mutate_file(
        $task_path,
        sub {
            $_[0] =~ s/(^- Segment manifest: `[^`]+`\n)/$1
                . "- Migration manifest: `$migration_relative`\n"/me;
        },
    );

    my $source = source_task_for_segment();
    my @working_paths = (
        $task_relative, $fixture->{manifest_relative}, $fixture->{segment_relative},
    );
    my ($working_lines, $working_bytes) = (0, 0);
    for my $relative (@working_paths) {
        my $contents = read_fixture_file($fixture->{root}, $relative);
        $working_lines += fixture_line_count($contents);
        $working_bytes += length($contents);
    }
    my $json = JSON::PP->new->canonical;
    my $migration = join(
        "\n",
        $json->encode({
            record_type => 'registry', schema_version => 1,
            tree_id => 'EXAMPLE', max_records => 1, max_bytes => 4096,
        }),
        $json->encode({
            record_type => 'migration', schema_version => 1,
            migration_id => 'example_reform', outcome => 're-form',
            source_revision => $fixture->{revision},
            source_path => $task_relative, source_sha256 => sha256_hex($source),
            source_lines => fixture_line_count($source), source_bytes => length($source),
            retention_contract => 'fixture_history',
            semantic_manifest => $fixture->{manifest_relative},
            authoritative_nodes => 1, working_set_paths => \@working_paths,
            working_set_lines => $working_lines, working_set_bytes => $working_bytes,
            product_relationship => 'overlapping_non_partition',
            loss_residue_kind => 'none', loss_residue_path => '-',
            loss_residue_sha256 => '-', loss_residue_lines => 0,
            loss_residue_bytes => 0,
        }),
        '',
    );
    write_file($fixture->{root}, $migration_relative, $migration);
    $fixture->{migration} = File::Spec->catfile(
        $fixture->{root}, split m{/}, $migration_relative
    );
    return $fixture;
}

sub make_compact_fixture {
    my (%args) = @_;
    my $archived_status = $args{archived_status} // 'done';
    my $source = "# Example\n\n## Task Tree\n\n"
        . container(
            'EXAMPLE', 'active', 'Exercise compact task-tree integrity.',
            ['EXAMPLE.1', 'EXAMPLE.2']
        )
        . container(
            'EXAMPLE.1', $archived_status, 'Complete archived subtree.',
            ['EXAMPLE.1.1']
        )
        . closed_leaf(
            'EXAMPLE.1.1', 'done', 'Close archived leaf.',
            'archived proof passed', 'EXAMPLE.1.1: close archived leaf'
        )
        . leaf('EXAMPLE.2', 'pending');
    my ($root, $source_revision) = initialize_versioned_fixture($source);

    my $revision = $args{revision} // $source_revision;
    my $digest = $args{digest} // sha256_hex($source);
    my $node_count = $args{node_count} // 2;
    my $verification = $args{pending_evidence}
        ? 'pending'
        : 'exact version-object retrieval passed';
    my $commit = $args{pending_evidence}
        ? 'pending'
        : 'EXAMPLE.1: complete archived subtree';
    my $compact = "- ID: `EXAMPLE.1`\n"
        . "  Status: `done`\n"
        . "  Goal: `Complete archived subtree.`\n"
        . "  Terminal: `version_object`\n"
        . "  Revision: `$revision`\n"
        . "  Retrieval path: `docs/tasks/EXAMPLE.md`\n"
        . "  Retrieved SHA256: `$digest`\n"
        . "  Archived node count: `$node_count`\n"
        . "  Retention contract: `fixture_history`\n"
        . "  Verification: `$verification`\n"
        . "  Commit: `$commit`\n\n";
    my $live = "# Example\n\n## Task Tree\n\n"
        . container(
            'EXAMPLE', 'active', 'Exercise compact task-tree integrity.',
            ['EXAMPLE.1', 'EXAMPLE.2']
        )
        . $compact
        . leaf('EXAMPLE.2', 'pending');
    write_file($root, 'docs/tasks/EXAMPLE.md', $live);
    return { root => $root };
}

sub make_index_archive_fixture {
    my (%args) = @_;
    my $root = create_project_tempdir(purpose => 'task-tree-index-archive-tests');
    my $archived_path = $args{missing_source_task}
        ? 'docs/tasks/MISSING.md'
        : 'docs/tasks/ARCHIVED.md';
    my $source_index = "# Index\n\n"
        . "## Active Task Trees\n\n"
        . "| Tree | Status | Roadmap lane | Current frontier | File |\n"
        . "| --- | --- | --- | --- | --- |\n"
        . "| `EXAMPLE` | `active` | `fixture` | `EXAMPLE.2` | "
        . "[docs/tasks/EXAMPLE.md](docs/tasks/EXAMPLE.md) |\n\n"
        . "## Proposed Task Trees\n\n"
        . "| Tree | Status | Roadmap lane | Proposed first leaf | File |\n"
        . "| --- | --- | --- | --- | --- |\n\n"
        . "## Completed Task Trees\n\n"
        . "| Tree | Status | Roadmap lane | Completed frontier | File |\n"
        . "| --- | --- | --- | --- | --- |\n"
        . "| `ARCHIVED` | `done` | `fixture` | `closed` | "
        . "[$archived_path]($archived_path) |\n";
    write_file($root, 'docs/TASK_TREE.md', $source_index);
    write_file($root, 'docs/tasks/EXAMPLE.md', valid_task());
    write_file(
        $root,
        'docs/tasks/ARCHIVED.md',
        "# Archived\n\n## Task Tree\n\n"
            . closed_leaf(
                'ARCHIVED', 'done', 'Close archived tree.',
                'archive proof passed', 'ARCHIVED: close tree'
            ),
    );
    run_git($root, 'init', '--quiet');
    run_git($root, 'add', 'docs/TASK_TREE.md', 'docs/tasks/EXAMPLE.md',
        'docs/tasks/ARCHIVED.md');
    run_git(
        $root, '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
        'commit', '--quiet', '-m', 'fixture index source'
    );
    my $revision = run_git($root, 'rev-parse', 'HEAD');
    $revision =~ s/\s+\z//;

    my $manifest_relative = 'doctrine/task_tree/index_archives.jsonl';
    my $current_index = "# Index\n\n"
        . "## Active Task Trees\n\n"
        . "| Tree | Status | Roadmap lane | Current frontier | File |\n"
        . "| --- | --- | --- | --- | --- |\n"
        . "| `EXAMPLE` | `active` | `fixture` | `EXAMPLE.2` | "
        . "[docs/tasks/EXAMPLE.md](docs/tasks/EXAMPLE.md) |\n\n"
        . "## Proposed Task Trees\n\n"
        . "| Tree | Status | Roadmap lane | Proposed first leaf | File |\n"
        . "| --- | --- | --- | --- | --- |\n\n"
        . "## Completed Task Trees\n\n"
        . "- Completed-history manifest: `$manifest_relative`\n";
    write_file($root, 'docs/TASK_TREE.md', $current_index);

    my $json = JSON::PP->new->canonical;
    my $lines = ($source_index =~ tr/\n//);
    my $manifest = join(
        "\n",
        $json->encode({
            record_type => 'registry', schema_version => 1,
            max_records => 1, max_bytes => 2048,
        }),
        $json->encode({
            record_type => 'version_object', schema_version => 1,
            archive_id => 'fixture-completed-index', revision => $revision,
            path => 'docs/TASK_TREE.md', sha256 => sha256_hex($source_index),
            lines => $lines, bytes => length($source_index), terminal_rows => 1,
            unique_tree_ids => 1, statuses => ['done', 'deferred', 'superseded'],
            current_pointer => 'docs/TASK_TREE.md', sealed_on => '2026-07-31',
            retention_contract => 'fixture_history',
        }),
        '',
    );
    write_file($root, $manifest_relative, $manifest);
    write_retention_registry($root);
    return {
        root => $root,
        index => File::Spec->catfile($root, 'docs', 'TASK_TREE.md'),
        manifest => File::Spec->catfile(
            $root, 'doctrine', 'task_tree', 'index_archives.jsonl'
        ),
    };
}

sub initialize_versioned_fixture {
    my ($task) = @_;
    my $root = create_project_tempdir(purpose => 'task-tree-integrity-tests');
    write_index($root);
    write_file($root, 'docs/tasks/EXAMPLE.md', $task);
    run_git($root, 'init', '--quiet');
    run_git($root, 'add', 'docs/TASK_TREE.md', 'docs/tasks/EXAMPLE.md');
    run_git(
        $root, '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
        'commit', '--quiet', '-m', 'fixture source'
    );
    my $revision = run_git($root, 'rev-parse', 'HEAD');
    $revision =~ s/\s+\z//;
    write_retention_registry($root);
    return ($root, $revision);
}

sub write_retention_registry {
    my ($root) = @_;
    my $json = JSON::PP->new->canonical;
    write_file(
        $root,
        'doctrine/live_document_size/version_retention_contracts.jsonl',
        join(
            "\n",
            $json->encode({
                record_type => 'registry', schema_version => 1,
                max_records => 4, max_bytes => 4096, max_record_bytes => 1024,
            }),
            $json->encode({
                record_type => 'contract', schema_version => 1,
                contract_id => 'fixture_history', owner => 'fixture-maintainers',
                guarantee => 'Fixture revisions remain reachable.',
                recovery => 'Fetch complete fixture history, restore the object, and rerun the gate.',
            }),
            '',
        ),
    );
}

sub read_fixture_file {
    my ($root, $relative) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $contents = <$fh> // '';
    close $fh or die "cannot close $path: $!";
    return $contents;
}

sub fixture_line_count {
    my ($contents) = @_;
    return 0 if $contents eq '';
    my $lines = ($contents =~ tr/\n//);
    $lines++ if $contents !~ /\n\z/;
    return $lines;
}

sub container {
    my ($id, $status, $goal, $children) = @_;
    return "- ID: `$id`\n"
        . "  Status: `$status`\n"
        . "  Goal: `$goal`\n"
        . "  Children: `" . join(', ', @{$children}) . "`\n\n";
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

sub closed_leaf {
    my ($id, $status, $goal, $verification, $commit) = @_;
    return "- ID: `$id`\n"
        . "  Status: `$status`\n"
        . "  Goal: `$goal`\n"
        . "  Acceptance: `The closed fixture is structurally complete.`\n"
        . "  Verification: `$verification`\n"
        . "  Commit: `$commit`\n\n";
}

sub make_fixture {
    my ($task) = @_;
    my $root = create_project_tempdir(purpose => 'task-tree-integrity-tests');
    write_index($root);
    write_file($root, 'docs/tasks/EXAMPLE.md', $task);
    return $root;
}

sub write_index {
    my ($root) = @_;
    write_file(
        $root,
        'docs/TASK_TREE.md',
        "# Index\n\n"
            . "| Tree | Status | Roadmap lane | Current frontier | File |\n"
            . "| --- | --- | --- | --- | --- |\n"
            . "| `EXAMPLE` | `active` | `fixture` | `EXAMPLE.2` | "
            . "[docs/tasks/EXAMPLE.md](docs/tasks/EXAMPLE.md) |\n",
    );
}

sub mutate_file {
    my ($path, $mutator) = @_;
    open my $in, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $contents = <$in>;
    close $in or die "cannot close $path: $!";
    $mutator->($contents);
    open my $out, '>:raw', $path or die "cannot write $path: $!";
    print {$out} $contents;
    close $out or die "cannot close $path: $!";
}

sub write_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub run_git {
    my ($root, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $root, @args],
    );
    die "git @args failed: " . join('', @{$stderr || []}) if !$ok;
    return join('', @{$stdout || []});
}

sub expect_failure {
    my ($root, $expected, $label) = @_;
    my ($ok, $output) = run_checker($root);
    ok(!$ok, "$label fails closed");
    like($output, $expected, 'diagnostic is deterministic and actionable');
}

sub run_checker {
    my ($root) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$checker, '--root', $root],
    );
    my $output = join('', @{$stdout || []}, @{$stderr || []});
    return ($ok ? 1 : 0, $output);
}
