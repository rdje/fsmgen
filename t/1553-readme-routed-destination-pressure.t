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
my $checker = File::Spec->catfile($repo_root, 'scripts', 'check_readme_entrypoint.sh');
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'live README routes use the common pressure-controlled surface graph' => sub {
    my ($ok, $output) = run_checker($repo_root);
    ok($ok, 'live README and common surface registries pass') or diag($output);
    like($output, qr/all README entry-point invariants hold/, 'landing-page invariant remains explicit');
    like($output, qr/all routed-destination pressure invariants hold/, 'route-pressure invariant remains explicit');
    like($output, qr/all live-document size-containment invariants hold \(20 surfaces\)/, 'common project-wide checker is delegated');
    like($output, qr/containment pressure migrated: 2 surface\(s\)/,
        'migrated pressure is reported separately');
    like($output, qr/containment pressure pinned_deferred: 9 surface\(s\)/,
        'pinned/deferred pressure remains visible');
};

subtest 'minimal marker-to-surface routes pass without duplicated budgets' => sub {
    my $fixture = make_fixture();
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'valid minimal route and surface registries pass') or diag($output);
    like($output, qr/route shipped_behavior: README marker -> shipped_behavior/, 'README checker reports marker mapping');
    like($output, qr/surface shipped_behavior: actual files=1,/, 'common checker owns destination measurement');
};

subtest 'missing required route fails closed' => sub {
    my $fixture = make_fixture();
    mutate_file(
        $fixture,
        'doctrine/readme_entrypoint/routed_destinations.jsonl',
        sub { $_[0] =~ s/^.*"route_id":"change_history".*\n//m },
    );
    my ($ok, $output) = run_checker($fixture);
    ok(!$ok, 'missing route is rejected');
    like($output, qr/required routed destination is undeclared: change_history/, 'missing route is named');
};

subtest 'stale GitHub landing-page marker fails closed' => sub {
    my $fixture = make_fixture();
    mutate_file($fixture, 'README.md', sub { $_[0] =~ s/^marker-active-index\n//m });
    my ($ok, $output) = run_checker($fixture);
    ok(!$ok, 'missing landing-page marker is rejected');
    like($output, qr/route active_index: README marker is absent/, 'README-specific diagnostic remains stable');
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

subtest 'common hard budget and frozen identity still close README destinations' => sub {
    my $budget_fixture = make_fixture();
    write_file($budget_fixture, 'bounded.md', join('', map { "line $_\n" } 1 .. 101));
    my ($budget_ok, $budget_output) = run_checker($budget_fixture);
    ok(!$budget_ok, 'destination hard limit is rejected');
    like($budget_output, qr/surface high_level_direction max lines is 101 \(> inclusive enforcement ceiling 100\)/,
        'hard failure comes from common authority');

    my $frozen_fixture = make_fixture();
    write_file($frozen_fixture, 'frozen-a.md', "changed\n");
    my ($frozen_ok, $frozen_output) = run_checker($frozen_fixture);
    ok(!$frozen_ok, 'frozen destination drift is rejected');
    like($frozen_output, qr/surface frozen_roadmap_status frozen identity changed/, 'frozen failure comes from common authority');
};

done_testing();

sub make_fixture {
    my $root = create_project_tempdir(purpose => 'readme-route-pressure-tests');
    my @route_ids = qw(
        shipped_behavior reported_capabilities high_level_direction active_resume
        active_index task_evidence rationale engineering_rationale fact_index
        change_history exact_history diagnostics enforced_rules
        frozen_roadmap_status frozen_achievement_status
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
        change_history            => 'marker-changes',
        exact_history             => 'marker-history',
        diagnostics               => 'marker-diagnostics',
        enforced_rules            => 'marker-rules',
        frozen_roadmap_status     => 'marker-frozen-roadmap',
        frozen_achievement_status => 'marker-frozen-achievement',
    );
    write_file($root, 'README.md', join("\n", map { $markers{$_} } @route_ids) . "\n");
    write_file($root, 'bounded.md', "one\ntwo\n");
    write_file($root, 'generated.md', "generated\n");
    write_file($root, 'parts/first.md', "part\n");
    write_file($root, 'index.md', "index\n");
    write_file($root, 'frozen-a.md', "frozen a\n");
    write_file($root, 'frozen-b.md', "frozen b\n");
    write_file($root, 'bin/query', "#!/bin/sh\nexit 0\n");
    write_file($root, 'bin/freshness', "#!/bin/sh\nexit 0\n");
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
            qw(engineering_rationale change_history)),
        measured('fact_index', 'generated_projection', 'generated_file', 'generated.md', 'parts/*.md', '-', 1, 100, 4096, 100, 4096, 'freshness:bin/freshness'),
        terminal('exact_history', 'archive_terminal', 'archive', '.git', 'terminal', 'archive:.git'),
        frozen('frozen_roadmap_status', 'frozen-a.md', sha256_hex("frozen a\n")),
        frozen('frozen_achievement_status', 'frozen-b.md', sha256_hex("frozen b\n")),
    );
    write_file(
        $root,
        'doctrine/live_document_size/surfaces.jsonl',
        join('', map { json_line($_) } @surface_rows),
    );

    my @route_rows = map {{
        route_id          => $_,
        source_surface_id => 'readme_entrypoint',
        marker            => $markers{$_},
        target_surface_id => $_,
    }} @route_ids;
    write_file(
        $root,
        'doctrine/readme_entrypoint/routed_destinations.jsonl',
        join('', map { json_line($_) } @route_rows),
    );
    write_file(
        $root,
        'doctrine/live_document_size/archive_descriptors.jsonl',
        json_line({ record_type => 'registry', schema_version => 1 }),
    );
    return $root;
}

sub measured {
    my ($id, $lifecycle, $locator, $target, $index, $routes,
        $max_files, $max_lines, $max_bytes, $total_lines, $total_bytes,
        $verifier) = @_;
    $verifier //= 'builtin:budget';
    my $generated = $locator eq 'generated_file';
    return {
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
            lines_total => $total_lines,
            bytes_total => $total_bytes,
        },
        enforcement_ceilings => {
            files       => $max_files,
            lines_each  => $max_lines,
            bytes_each  => $max_bytes,
            lines_total => $total_lines,
            bytes_total => $total_bytes,
        },
        milestones => { warning_pct => 80, rollover_pct => 90 },
        containment_status => 'steady', state => 'normal', baseline => undef,
        verifier => $verifier,
    };
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

sub frozen {
    my ($id, $target, $sha) = @_;
    return {
        surface_id => $id, lifecycle => 'frozen_legacy', locator => 'frozen',
        targets => [$target], index => undef, canonical_inputs => [],
        routes_to => [], owner => 'fixture-owner', health_targets => undef,
        enforcement_ceilings => undef, milestones => undef,
        containment_status => 'not_applicable', state => 'frozen',
        baseline => undef, verifier => "sha256:$sha",
    };
}

sub json_line {
    my ($record) = @_;
    return $json->encode($record) . "\n";
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

sub run_checker {
    my ($root) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$checker, '--root', $root],
    );
    return ($ok ? 1 : 0, join('', @{$stdout || []}, @{$stderr || []}));
}
