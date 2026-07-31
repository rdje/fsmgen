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

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $checker = File::Spec->catfile(
    $repo_root, 'scripts', 'check_readme_entrypoint.sh'
);

subtest 'live README routes are pressure-closed' => sub {
    my ($ok, $output) = run_checker($repo_root);
    ok($ok, 'live routed-destination registry passes') or diag($output);
    like(
        $output,
        qr/all routed-destination pressure invariants hold/,
        'live result reports the added pressure invariant',
    );
};

subtest 'minimal bounded, query, archive, and frozen routes pass' => sub {
    my $fixture = make_fixture();
    my ($ok, $output) = run_checker($fixture);
    ok($ok, 'valid minimal routed destinations pass') or diag($output);
    like($output, qr/route shipped_behavior: 1 file\(s\)/, 'collection measurement is reported');
    like($output, qr/route exact_history: archive terminal/, 'archive terminal is explicit');
    like($output, qr/route frozen_roadmap_status: frozen identity/, 'frozen identity is checked');
};

subtest 'missing required route fails closed' => sub {
    my $fixture = make_fixture();
    mutate_file(
        $fixture,
        'doctrine/readme_entrypoint/routed_destinations.tsv',
        sub { $_[0] =~ s/^change_history\t.*\n//m },
    );
    my ($ok, $output) = run_checker($fixture);
    ok(!$ok, 'missing route is rejected');
    like($output, qr/required routed destination is undeclared: change_history/, 'missing route is named');
};

subtest 'stale README marker fails closed' => sub {
    my $fixture = make_fixture();
    mutate_file($fixture, 'README.md', sub { $_[0] =~ s/^marker-active-index\n//m });
    my ($ok, $output) = run_checker($fixture);
    ok(!$ok, 'missing marker is rejected');
    like($output, qr/route active_index: README marker is absent/, 'stale registry link is named');
};

subtest 'per-file and aggregate budgets fail independently' => sub {
    my $line_fixture = make_fixture();
    write_file($line_fixture, 'bounded.md', "one\ntwo\nthree\nfour\nfive\nsix\n");
    my ($line_ok, $line_output) = run_checker($line_fixture);
    ok(!$line_ok, 'per-file line overflow is rejected');
    like($line_output, qr/bounded\.md is 6 lines \(> per-file cap 5\)/, 'line failure names measured and allowed values');

    my $total_fixture = make_fixture();
    write_file($total_fixture, 'parts/second.md', "abcdefghijklmnopqrst\n");
    my ($total_ok, $total_output) = run_checker($total_fixture);
    ok(!$total_ok, 'collection aggregate overflow is rejected');
    like($total_output, qr/route shipped_behavior: is [0-9]+ bytes total \(> cap 16\)/, 'aggregate failure names the route and byte cap');
};

subtest 'frozen content identity drift fails closed' => sub {
    my $fixture = make_fixture();
    write_file($fixture, 'frozen-a.md', "changed\n");
    my ($ok, $output) = run_checker($fixture);
    ok(!$ok, 'frozen content drift is rejected');
    like($output, qr/route frozen_roadmap_status: frozen target changed/, 'identity drift is explicit');
};

subtest 'escaping target and malformed terminal budgets fail closed' => sub {
    my $path_fixture = make_fixture();
    mutate_file(
        $path_fixture,
        'doctrine/readme_entrypoint/routed_destinations.tsv',
        sub { $_[0] =~ s/\tbounded\.md\t1\t5/\t..\/bounded.md\t1\t5/ },
    );
    my ($path_ok, $path_output) = run_checker($path_fixture);
    ok(!$path_ok, 'repository-escaping target is rejected');
    like($path_output, qr/target must stay repository-relative/, 'path failure names locality rule');

    my $query_fixture = make_fixture();
    mutate_file(
        $query_fixture,
        'doctrine/readme_entrypoint/routed_destinations.tsv',
        sub { $_[0] =~ s/^(reported_capabilities\tquery\t[^\n]*?\tbin\/query)\t-/$1\t1/m },
    );
    my ($query_ok, $query_output) = run_checker($query_fixture);
    ok(!$query_ok, 'query route with file budget is rejected');
    like($query_output, qr/query routes use lifecycle controls, not file budgets/, 'terminal-kind mismatch is explicit');
};

done_testing();

sub make_fixture {
    my $root = create_project_tempdir(purpose => 'readme-route-pressure-tests');
    my @markers = map { "marker-$_" } qw(
        shipped reported direction resume active-index task rationale
        engineering fact changes history diagnostics rules frozen-roadmap
        frozen-achievement
    );
    write_file($root, 'README.md', join("\n", @markers) . "\n");
    write_file($root, 'bounded.md', "one\ntwo\n");
    write_file($root, 'generated.md', "generated\n");
    write_file($root, 'parts/first.md', "part\n");
    write_file($root, 'frozen-a.md', "frozen a\n");
    write_file($root, 'frozen-b.md', "frozen b\n");
    write_file($root, 'bin/query', "#!/bin/sh\nexit 0\n");
    chmod 0755, File::Spec->catfile($root, 'bin', 'query')
        or die "cannot chmod fixture query: $!";
    make_path(File::Spec->catdir($root, '.git'));

    my $frozen_a = sha256_hex("frozen a\n");
    my $frozen_b = sha256_hex("frozen b\n");
    my @rows = (
        row('shipped_behavior', 'collection', 'marker-shipped', 'parts/*.md', 4, 5, 64, 10, 16, 'partitioned'),
        row('reported_capabilities', 'query', 'marker-reported', 'bin/query', '-', '-', '-', '-', '-', 'generated-query'),
        row('high_level_direction', 'file', 'marker-direction', 'bounded.md', 1, 5, 64, 5, 64, 'bounded'),
        row('active_resume', 'file', 'marker-resume', 'bounded.md', 1, 5, 64, 5, 64, 'bounded'),
        row('active_index', 'file', 'marker-active-index', 'bounded.md', 1, 5, 64, 5, 64, 'bounded'),
        row('task_evidence', 'collection', 'marker-task', 'parts/*.md', 4, 5, 64, 10, 16, 'partitioned'),
        row('rationale', 'collection', 'marker-rationale', 'parts/*.md', 4, 5, 64, 10, 16, 'partitioned'),
        row('engineering_rationale', 'file', 'marker-engineering', 'bounded.md', 1, 5, 64, 5, 64, 'shard'),
        row('fact_index', 'generated_file', 'marker-fact', 'generated.md', 1, 5, 64, 5, 64, 'freshness'),
        row('change_history', 'file', 'marker-changes', 'bounded.md', 1, 5, 64, 5, 64, 'shard'),
        row('exact_history', 'archive', 'marker-history', '.git', '-', '-', '-', '-', '-', 'query-first'),
        row('diagnostics', 'file', 'marker-diagnostics', 'bounded.md', 1, 5, 64, 5, 64, 'bounded'),
        row('enforced_rules', 'file', 'marker-rules', 'bounded.md', 1, 5, 64, 5, 64, 'bounded'),
        row('frozen_roadmap_status', 'frozen', 'marker-frozen-roadmap', 'frozen-a.md', '-', '-', '-', '-', '-', "sha256:$frozen_a"),
        row('frozen_achievement_status', 'frozen', 'marker-frozen-achievement', 'frozen-b.md', '-', '-', '-', '-', '-', "sha256:$frozen_b"),
    );
    my $header = join("\t", qw(
        route_id kind readme_marker target max_files max_lines_each
        max_bytes_each max_lines_total max_bytes_total control
    ));
    write_file(
        $root,
        'doctrine/readme_entrypoint/routed_destinations.tsv',
        $header . "\n" . join("\n", @rows) . "\n",
    );
    return $root;
}

sub row {
    return join("\t", @_);
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
    my $output = join('', @{$stdout || []}, @{$stderr || []});
    return ($ok ? 1 : 0, $output);
}
