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
use JSON::PP;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker = File::Spec->catfile($repo_root, 'scripts', 'check_readme_entrypoint.sh');
my $resulting_checker = File::Spec->catfile(
    $repo_root, 'scripts', 'check_live_document_resulting_tree.pl',
);
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'live README routes use the common pressure-controlled surface graph' => sub {
    my ($ok, $output) = run_checker($repo_root);
    ok($ok, 'live README and common surface registries pass') or diag($output);
    like($output, qr/all README entry-point invariants hold/, 'landing-page invariant remains explicit');
    like($output, qr/all routed-destination pressure invariants hold/, 'route-pressure invariant remains explicit');
    like($output, qr/all live-document size-containment invariants hold \(19 surfaces\)/, 'common project-wide checker is delegated');
    like($output, qr/containment pressure migrated: 2 surface\(s\)/,
        'migrated pressure is reported separately');
    like($output, qr/containment pressure pinned_deferred: 8 surface\(s\)/,
        'pinned/deferred pressure remains visible');
};

subtest 'minimal marker-to-surface routes pass without duplicated budgets' => sub {
    my $fixture = make_fixture();
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'valid minimal route and surface registries pass') or diag($output);
    like($output, qr/route shipped_behavior: reader_navigation README\.md marker -> shipped_behavior/,
        'README checker reports typed marker mapping');
    like($output, qr/surface shipped_behavior: actual files=1,/, 'common checker owns destination measurement');
};

subtest 'project adapter executes delegated verifier before proving it to the core' => sub {
    my $fixture = make_fixture();
    write_file(
        $fixture,
        'bin/freshness',
        "#!/bin/sh\nprintf 'adapter-ran\\n' > adapter-ran\n",
    );
    write_file(
        $fixture,
        'bin/currency',
        "#!/bin/sh\nprintf 'currency-adapter-ran\\n' > currency-adapter-ran\n",
    );
    chmod 0755, File::Spec->catfile($fixture, 'bin', 'freshness'),
        File::Spec->catfile($fixture, 'bin', 'currency')
        or die "cannot chmod adapter fixture verifier: $!";
    mutate_file(
        $fixture,
        'doctrine/live_document_size/surfaces.jsonl',
        sub { $_[0] =~ s/core:bin\/freshness/adapter:bin\/freshness/ },
    );
    mutate_surface_record($fixture, 'active_index', sub {
        $_[0]{currency} = {
            contract_id => 'active_index_alignment',
            verifier => 'adapter:bin/currency',
        };
    });
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'adapter execution plus matching proof passes') or diag($output);
    ok(-f File::Spec->catfile($fixture, 'adapter-ran'),
        'delegated verifier side effect proves actual execution');
    ok(-f File::Spec->catfile($fixture, 'currency-adapter-ran'),
        'delegated currency side effect proves actual execution');
    like($output, qr/adapter verifier execution proved: surface:fact_index/,
        'core consumes the exact adapter proof');
    like($output, qr/adapter verifier execution proved: currency:active_index/,
        'core consumes the exact namespaced currency proof');
};

subtest 'missing required route fails closed' => sub {
    my $fixture = make_fixture();
    mutate_file(
        $fixture,
        'doctrine/readme_entrypoint/routed_destinations.jsonl',
        sub { $_[0] =~ s/^.*"route_id":"diagnostics".*\n//m },
    );
    my ($ok, $output) = run_checker($fixture);
    ok(!$ok, 'missing route is rejected');
    like($output, qr/required routed destination is undeclared: diagnostics/, 'missing route is named');
};

subtest 'undeclared author hint and wrong route kind fail closed' => sub {
    my $undeclared = make_fixture();
    mutate_file($undeclared, 'scripts/check_readme_entrypoint.sh', sub {
        $_[0] .= "route_hint author_overflow task_evidence 'probe/tasks/' 'Move evidence to probe/tasks/'\n";
    });
    my ($undeclared_ok, $undeclared_output) = run_checker($undeclared);
    ok(!$undeclared_ok, 'path-shaped emitted hint requires a declared route');
    like($undeclared_output, qr/undeclared emitted route hint/,
        'undeclared author hint is diagnosed by the source-derived inventory');

    my $wrong_kind = make_fixture();
    mutate_file(
        $wrong_kind,
        'doctrine/readme_entrypoint/routed_destinations.jsonl',
        sub { $_[0] =~ s/("route_id":"author_task_evidence".*?"route_kind":)"author_overflow"/${1}"reader_navigation"/ },
    );
    my ($wrong_ok, $wrong_output) = run_checker($wrong_kind);
    ok(!$wrong_ok, 'author and reader route kinds cannot be silently unified');
    like($wrong_output, qr/undeclared emitted route hint/,
        'wrong kind breaks the exact author-route match');
};

subtest 'staged resulting tree cannot diverge from checked structural inputs' => sub {
    my $fixture = make_fixture();
    run_git($fixture, 'init');
    run_git($fixture, 'config', 'user.name', 'Fixture');
    run_git($fixture, 'config', 'user.email', 'fixture@example.invalid');
    run_git($fixture, 'add', '.');
    run_git($fixture, 'commit', '-m', 'fixture baseline');
    write_file(
        $fixture,
        'evidence.md',
        "<!-- EVIDENCE:BEGIN -->\n| Concern | Evidence |\n| --- | --- |\n"
            . "| Staged missing | `absent.md` |\n<!-- EVIDENCE:END -->\n",
    );
    run_git($fixture, 'add', 'evidence.md');
    write_file(
        $fixture,
        'evidence.md',
        "<!-- EVIDENCE:BEGIN -->\n| Concern | Evidence |\n| --- | --- |\n"
            . "| Fixture | `evidence-proof.md` |\n<!-- EVIDENCE:END -->\n",
    );
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$resulting_checker, '--root', $fixture],
    );
    my $output = join('', @{$stdout || []}, @{$stderr || []});
    ok(!$ok, 'staged structural result cannot hide behind different worktree content');
    like($output, qr/controlled path differs between staged result and worktree: evidence\.md/,
        'staged/worktree mismatch names the controlled evidence map');
};

subtest 'stale GitHub landing-page marker fails closed' => sub {
    my $fixture = make_fixture();
    mutate_file($fixture, 'README.md', sub { $_[0] =~ s/^marker-active-index\n//m });
    my ($ok, $output) = run_checker($fixture);
    ok(!$ok, 'missing landing-page marker is rejected');
    like($output, qr/route active_index: README\.md marker is absent/,
        'README-specific diagnostic remains stable');
    like($output, qr/route active_index marker is absent from README\.md/, 'common graph also rejects the stale edge');
};

subtest 'unknown target surface and wrong source fail closed' => sub {
    my $target_fixture = make_fixture();
    mutate_file(
        $target_fixture,
        'doctrine/readme_entrypoint/routed_destinations.jsonl',
        sub { $_[0] =~ s/"target_surface_id":"diagnostics"/"target_surface_id":"missing_surface"/ },
    );
    my ($target_ok, $target_output) = run_checker($target_fixture);
    ok(!$target_ok, 'unknown target surface is rejected');
    like($target_output, qr/targets an undeclared live-document surface: missing_surface/, 'unknown target is explicit');

    my $source_fixture = make_fixture();
    mutate_file(
        $source_fixture,
        'doctrine/readme_entrypoint/routed_destinations.jsonl',
        sub { $_[0] =~ s/("route_id":"rationale".*"source_surface_id":)"readme_entrypoint"/${1}"active_resume"/ },
    );
    my ($source_ok, $source_output) = run_checker($source_fixture);
    ok(!$source_ok, 'non-README route source is rejected');
    like($source_output, qr/must originate at readme_entrypoint/, 'wrong source is explicit');
};

subtest 'common hard budget still closes README destinations' => sub {
    my $budget_fixture = make_fixture();
    write_file($budget_fixture, 'bounded.md', join('', map { "line $_\n" } 1 .. 101));
    my ($budget_ok, $budget_output) = run_checker($budget_fixture);
    ok(!$budget_ok, 'destination hard limit is rejected');
    like($budget_output, qr/surface high_level_direction max lines is 101 \(> inclusive enforcement ceiling 100\)/,
        'hard failure comes from common authority');

};

done_testing();

sub make_fixture {
    my $root = create_project_tempdir(purpose => 'readme-route-pressure-tests');
    my @route_ids = qw(
        shipped_behavior reported_capabilities high_level_direction active_resume
        active_index task_evidence rationale engineering_rationale fact_index
        exact_history diagnostics enforced_rules
    );
    my %markers = (
        shipped_behavior          => 'marker-shipped',
        reported_capabilities     => 'marker-reported',
        high_level_direction      => 'marker-direction',
        active_resume             => 'marker-resume',
        active_index              => 'marker-active-index',
        task_evidence             => 'marker-task',
        rationale                 => 'marker-rationale',
        engineering_rationale     => 'marker-engineering',
        fact_index                => 'marker-fact',
        exact_history             => 'marker-history',
        diagnostics               => 'marker-diagnostics',
        enforced_rules            => 'marker-rules',
    );
    write_file($root, 'README.md', join("\n", map { $markers{$_} } @route_ids) . "\n");
    write_file($root, 'bounded.md', "one\ntwo\n");
    write_file($root, 'generated.md', "generated\n");
    write_file($root, 'parts/first.md', "part\n");
    write_file($root, 'index.md', "[Part](parts/first.md)\n");
    write_file($root, 'bin/query', "#!/bin/sh\nexit 0\n");
    write_file($root, 'bin/freshness', "#!/bin/sh\nexit 0\n");
    write_file($root, 'evidence-proof.md', "proof\n");
    write_file(
        $root,
        'evidence.md',
        "<!-- EVIDENCE:BEGIN -->\n| Concern | Evidence |\n| --- | --- |\n"
            . "| Fixture | `evidence-proof.md` |\n<!-- EVIDENCE:END -->\n",
    );
    write_file(
        $root,
        'scripts/check_readme_entrypoint.sh',
        join('',
            "route_hint author_overflow task_evidence 'docs/tasks/' 'Move detail to docs/tasks/'\n",
            "route_hint author_overflow rationale 'docs/decisions/' 'Move rationale to docs/decisions/'\n",
            "route_hint author_overflow shipped_behavior 'docs/book/' 'Move behavior to docs/book/'\n",
            "route_hint author_overflow exact_history 'git log --grep=<UNIT-ID>' 'Leave history to git log --grep=<UNIT-ID>'\n",
        ),
    );
    chmod 0755, File::Spec->catfile($root, 'bin', 'query'),
        File::Spec->catfile($root, 'bin', 'freshness')
        or die "cannot chmod fixture executables: $!";
    make_path(File::Spec->catdir($root, '.git'));

    my @surface_rows = (
        measured('readme_entrypoint', 'bounded_snapshot', 'file', 'README.md', 'self', join(',', @route_ids), 1, 100, 4096, 100, 4096),
        measured('shipped_behavior', 'partitioned_canonical', 'collection', 'parts/*.md', 'index.md', '-', 4, 100, 4096, 200, 8192),
        terminal('reported_capabilities', 'generated_projection', 'query', 'bin/query', 'terminal', 'executable:bin/query'),
        (map { measured($_, 'bounded_snapshot', 'file', 'bounded.md', 'self', '-', 1, 100, 4096, 100, 4096) }
            qw(high_level_direction active_resume active_index diagnostics enforced_rules)),
        (map { measured($_, 'partitioned_canonical', 'collection', 'parts/*.md', 'index.md', '-', 4, 100, 4096, 200, 8192) }
            qw(task_evidence rationale)),
        (map { measured($_, 'rolling_ledger', 'file', 'bounded.md', 'self', '-', 1, 100, 4096, 100, 4096) }
            qw(engineering_rationale)),
        measured('fact_index', 'generated_projection', 'generated_file', 'generated.md', 'parts/*.md', '-', 1, 100, 4096, 100, 4096, 'core:bin/freshness'),
        terminal('exact_history', 'archive_terminal', 'archive', '.git', 'terminal', 'archive:.git'),
    );
    write_file(
        $root,
        'doctrine/live_document_size/surfaces.jsonl',
        registry_header(32, 32768, 4096)
            . join('', map { json_line($_) } @surface_rows),
    );

    my @route_rows = map {{
        route_id          => $_,
        route_kind        => 'reader_navigation',
        source_path       => 'README.md',
        source_surface_id => 'readme_entrypoint',
        marker            => $markers{$_},
        target_surface_id => $_,
    }} @route_ids;
    push @route_rows,
        author_route('author_task_evidence', 'task_evidence', 'docs/tasks/'),
        author_route('author_rationale', 'rationale', 'docs/decisions/'),
        author_route('author_shipped_behavior', 'shipped_behavior', 'docs/book/'),
        author_route('author_exact_history', 'exact_history', 'git log --grep=<UNIT-ID>');
    write_file(
        $root,
        'doctrine/readme_entrypoint/routed_destinations.jsonl',
        registry_header(32, 16384, 1024)
            . join('', map { json_line($_) } @route_rows),
    );
    write_file(
        $root,
        'doctrine/live_document_size/archive_descriptors.jsonl',
        registry_header(8, 8192, 2048),
    );
    write_file(
        $root,
        'doctrine/live_document_size/ledger_manifests.jsonl',
        registry_header(8, 8192, 2048),
    );
    write_file(
        $root,
        'doctrine/live_document_size/version_retention_contracts.jsonl',
        json_line({
            record_type => 'registry', schema_version => 1,
            max_records => 4, max_bytes => 4096, max_record_bytes => 2048,
        }),
    );
    write_file(
        $root,
        'doctrine/live_document_size/evidence_maps.jsonl',
        registry_header(8, 4096, 1024) . json_line({
            map_id => 'fixture', source_path => 'evidence.md',
            begin_marker => '<!-- EVIDENCE:BEGIN -->',
            end_marker => '<!-- EVIDENCE:END -->',
        }),
    );
    return $root;
}

sub author_route {
    my ($route_id, $target, $marker) = @_;
    return {
        route_id => $route_id, route_kind => 'author_overflow',
        source_path => 'scripts/check_readme_entrypoint.sh',
        source_surface_id => 'readme_entrypoint', marker => $marker,
        target_surface_id => $target,
    };
}

sub measured {
    my ($id, $lifecycle, $locator, $target, $index, $routes,
        $max_files, $max_lines, $max_bytes, $total_lines, $total_bytes,
        $verifier) = @_;
    $verifier //= 'builtin:budget';
    my $generated = $locator eq 'generated_file';
    my $record = {
        surface_id      => $id,
        lifecycle       => $lifecycle,
        locator         => $locator,
        targets         => [$target],
        index           => $generated || $index eq '-' || $index eq 'self' ? undef : $index,
        canonical_inputs => $generated ? [$index] : [],
        routes_to       => $routes eq '-' ? [] : [split /,/, $routes],
        owner           => 'fixture-owner',
        health_targets  => {
            files       => $max_files,
            lines_each  => $max_lines,
            bytes_each  => $max_bytes,
            line_bytes_each => 1024,
            lines_total => $total_lines,
            bytes_total => $total_bytes,
        },
        enforcement_ceilings => {
            files       => $max_files,
            lines_each  => $max_lines,
            bytes_each  => $max_bytes,
            line_bytes_each => 1024,
            lines_total => $total_lines,
            bytes_total => $total_bytes,
        },
        milestones => { warning_pct => 80, rollover_pct => 90 },
        containment_status => 'steady', state => 'normal', baseline => undef,
        verifier => $verifier,
    };
    $record->{index_contract} = {
        kind => 'membership', verifier => 'builtin:markdown_links',
    } if $locator eq 'collection' && defined $record->{index};
    return $record;
}

sub terminal {
    my ($id, $lifecycle, $locator, $target, $state, $verifier) = @_;
    return {
        surface_id => $id, lifecycle => $lifecycle, locator => $locator,
        targets => [$target], index => undef, canonical_inputs => [],
        routes_to => [], owner => 'fixture-owner', health_targets => undef,
        enforcement_ceilings => undef, milestones => undef,
        containment_status => 'not_applicable', state => $state,
        baseline => undef, verifier => $verifier,
    };
}

sub json_line {
    my ($record) = @_;
    return $json->encode($record) . "\n";
}

sub registry_header {
    my ($max_records, $max_bytes, $max_record_bytes) = @_;
    return json_line({
        record_type => 'registry', schema_version => 1,
        max_records => $max_records, max_bytes => $max_bytes,
        max_record_bytes => $max_record_bytes,
    });
}

sub write_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    make_path(dirname($path));
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $contents;
    close $fh or die "cannot close $path: $!";
}

sub mutate_file {
    my ($root, $relative, $mutator) = @_;
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    open my $in, '<', $path or die "cannot read $path: $!";
    local $/;
    my $contents = <$in>;
    close $in or die "cannot close $path: $!";
    $mutator->($contents);
    write_file($root, $relative, $contents);
}

sub mutate_surface_record {
    my ($root, $surface_id, $mutator) = @_;
    mutate_file(
        $root,
        'doctrine/live_document_size/surfaces.jsonl',
        sub {
            my @records = map { decode_json($_) } grep { $_ ne '' } split /\n/, $_[0];
            my $found = 0;
            for my $record (@records) {
                next if ($record->{surface_id} // '') ne $surface_id;
                $mutator->($record);
                $found++;
            }
            die "fixture surface $surface_id not found" if !$found;
            $_[0] = join('', map { json_line($_) } @records);
        },
    );
}

sub run_checker {
    my ($root) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$checker, '--root', $root],
    );
    return ($ok ? 1 : 0, join('', @{$stdout || []}, @{$stderr || []}));
}

sub run_git {
    my ($root, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $root, @args],
    );
    die "fixture git @args failed: " . join('', @{$stdout || []}, @{$stderr || []})
        if !$ok;
}
