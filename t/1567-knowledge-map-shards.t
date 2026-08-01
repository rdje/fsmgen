#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $core = File::Spec->catfile(
    $repo, 'knowledge-map', 'scripts', 'knowledge_map.pl');

subtest 'generation is deterministic, sharded, complete, and query-equivalent' => sub {
    my $root = make_fixture();
    my ($generated, $generate_output) = run_core($root, 'generate');
    ok($generated, 'fixture projection generates') or diag($generate_output);
    ok(-f path($root, 'KNOWLEDGE_MAP.md'), 'bounded root exists');
    ok(-f path($root, 'knowledge-map/generated/alpha-one.md'), 'first topic shard exists');
    ok(-f path($root, 'knowledge-map/generated/beta-two.md'), 'second topic shard exists');

    my $root_text = read_file($root, 'KNOWLEDGE_MAP.md');
    like($root_text, qr/\*\*2\*\* facts .* \*\*3\*\* unique questions/,
        'root reports unique questions rather than repeated occurrences');
    my $all_shards = read_file($root, 'knowledge-map/generated/alpha-one.md')
        . read_file($root, 'knowledge-map/generated/beta-two.md');
    is(count_occurrences($all_shards, 'shared retrieval question'), 1,
        'a question answered by two facts appears once across all shards');
    like($all_shards, qr/facts=\[alpha-one-fact\].*\[beta-two-fact\]/,
        'the unique question row retains both canonical fact links');
    is(count_occurrences($all_shards, '### alpha-one-fact'), 1,
        'first fact appears exactly once');
    is(count_occurrences($all_shards, '### beta-two-fact'), 1,
        'second fact appears exactly once');

    my $before = projection_bytes($root);
    my ($regenerated, $regenerate_output) = run_core($root, 'generate');
    ok($regenerated, 'second generation succeeds') or diag($regenerate_output);
    is(projection_bytes($root), $before, 'second generation is byte-identical');

    my ($checked, $check_output) = run_core($root, 'check');
    ok($checked, 'fresh bounded projection passes') or diag($check_output);
    like($check_output, qr/query parity verified/, 'checker proves query parity');

    my ($cached_ok, $cached) = run_core($root, 'query', 'shared retrieval');
    my ($direct_ok, $direct) = run_core($root, 'query', '--no-cache', 'shared retrieval');
    ok($cached_ok && $direct_ok, 'cached and direct queries both execute');
    is($cached, $direct, 'cached and direct query results are byte-identical');
    like($cached, qr/^shared retrieval question\talpha-one-fact,beta-two-fact\t/m,
        'query result is deterministic and routes to both facts');
    ok(-f path($root, '.artifacts/knowledge-map/query/questions.jsonl'),
        'disposable cache stays beneath the fixture repository root');

    write_file($root, '.artifacts/knowledge-map/query/questions.jsonl', "not-json\n");
    my ($rebuilt_ok, $rebuilt) = run_core($root, 'query', 'shared retrieval');
    ok($rebuilt_ok, 'invalid disposable cache is rebuilt automatically');
    is($rebuilt, $direct, 'rebuilt cache returns the direct result');

    my $cache_path = '.artifacts/knowledge-map/query/questions.jsonl';
    my $stale_cache = read_file($root, $cache_path);
    my $removed = $stale_cache =~ s/^.*"question":"beta-specific question".*\n//m;
    ok($removed, 'fixture creates a structurally valid stale cache');
    write_file($root, $cache_path, $stale_cache);
    my ($stale_rebuilt_ok, $stale_rebuilt) = run_core(
        $root, 'query', 'beta-specific question');
    my ($stale_direct_ok, $stale_direct) = run_core(
        $root, 'query', '--no-cache', 'beta-specific question');
    ok($stale_rebuilt_ok && $stale_direct_ok,
        'matching-fingerprint stale cache is rebuilt automatically');
    is($stale_rebuilt, $stale_direct,
        'semantic cache validation restores direct-query parity');
};

subtest 'freshness rejects root, shard, membership, and source drift' => sub {
    my $stale_shard = make_fixture();
    run_core($stale_shard, 'generate');
    append_file($stale_shard, 'knowledge-map/generated/alpha-one.md', "stale\n");
    my ($stale_ok, $stale_output) = run_core($stale_shard, 'check');
    ok(!$stale_ok, 'edited shard fails');
    like($stale_output, qr/alpha-one\.md is out of sync/,
        'stale shard is named');

    my $extra = make_fixture();
    run_core($extra, 'generate');
    write_file($extra, 'knowledge-map/generated/extra.md', "extra\n");
    my ($extra_ok, $extra_output) = run_core($extra, 'check');
    ok(!$extra_ok, 'unexpected shard fails');
    like($extra_output, qr/unexpected generated shard: .*extra\.md/,
        'unexpected member is named');

    my $stale_root = make_fixture();
    run_core($stale_root, 'generate');
    append_file($stale_root, 'KNOWLEDGE_MAP.md', "stale root\n");
    my ($root_ok, $root_output) = run_core($stale_root, 'check');
    ok(!$root_ok, 'edited root fails');
    like($root_output, qr/KNOWLEDGE_MAP\.md is out of sync/,
        'stale root is named');

    my $source = make_fixture();
    run_core($source, 'generate');
    my $card = read_file($source, 'docs/knowledge/alpha-one-fact.md');
    $card =~ s/alpha-specific question/changed source question/;
    write_file($source, 'docs/knowledge/alpha-one-fact.md', $card);
    my ($source_ok, $source_output) = run_core($source, 'check');
    ok(!$source_ok, 'canonical source drift without regeneration fails');
    like($source_output, qr/out of sync with canonical facts/,
        'source/projection mismatch is explicit');
};

subtest 'field, card, shard, and locality bounds fail closed' => sub {
    my $missing = make_fixture();
    my $card = read_file($missing, 'docs/knowledge/alpha-one-fact.md');
    $card =~ s/^date:.*\n//m;
    write_file($missing, 'docs/knowledge/alpha-one-fact.md', $card);
    my ($missing_ok, $missing_output) = run_core($missing, 'generate');
    ok(!$missing_ok, 'missing required field blocks generation');
    like($missing_output, qr/missing required field date/,
        'missing field is named');

    my $wide = make_fixture();
    my $wide_card = read_file($wide, 'docs/knowledge/alpha-one-fact.md');
    $wide_card =~ s{^evidence:.*$}{'evidence: ' . ('x' x 820)}me;
    write_file($wide, 'docs/knowledge/alpha-one-fact.md', $wide_card);
    my ($wide_ok, $wide_output) = run_core($wide, 'generate');
    ok(!$wide_ok, 'over-width card blocks generation');
    like($wide_output, qr/card line width .* exceeds 819/,
        'independent card line bound is explicit');

    my $shard = make_fixture();
    run_core($shard, 'generate');
    my ($shard_ok, $shard_output) = run_core(
        $shard, 'check', {KM_SHARD_MAX_LINES => 1});
    ok(!$shard_ok, 'per-shard line overflow fails');
    like($shard_output, qr/shard .* lines .* exceed 1/,
        'per-shard bound is named');

    my $aggregate = make_fixture();
    run_core($aggregate, 'generate');
    my ($aggregate_ok, $aggregate_output) = run_core(
        $aggregate, 'check', {KM_SHARD_MAX_TOTAL_BYTES => 1});
    ok(!$aggregate_ok, 'shard aggregate overflow fails');
    like($aggregate_output, qr/shard aggregate bytes .* exceed 1/,
        'aggregate bound is named');

    my $off_volume = make_fixture();
    my ($off_ok, $off_output) = run_core(
        $off_volume, 'generate', {KM_QUERY_CACHE_DIR => $repo});
    ok(!$off_ok, 'absolute query-cache path is rejected before generation');
    like($off_output, qr/unsafe KM_QUERY_CACHE_DIR path/,
        'off-repository cache failure is explicit');

    my $symlink_root = make_fixture();
    my $outside = create_project_tempdir(purpose => 'knowledge-map-symlink-outside');
    symlink $outside, path($symlink_root, 'escape')
        or die "cannot create fixture symlink: $!";
    my ($symlink_ok, $symlink_output) = run_core(
        $symlink_root, 'generate', {KM_SHARD_DIR => 'escape/shards'});
    ok(!$symlink_ok, 'symlink escape in a generated path is rejected');
    like($symlink_output, qr/unsafe KM_SHARD_DIR symlink component/,
        'symlink breakout failure names the configured path');
};

subtest 'folded metadata preserves scalar meaning and becomes bounded' => sub {
    my $root = make_fixture();
    my $long = join(' ', ('evidence-token') x 80);
    my $card = read_file($root, 'docs/knowledge/alpha-one-fact.md');
    $card =~ s/^evidence:.*$/evidence: $long/m;
    write_file($root, 'docs/knowledge/alpha-one-fact.md', $card);
    my ($formatted, $format_output) = run_core($root, 'format');
    ok($formatted, 'over-width metadata formats') or diag($format_output);
    my $formatted_card = read_file($root, 'docs/knowledge/alpha-one-fact.md');
    like($formatted_card, qr/^evidence: >-$/m, 'portable folded-scalar marker is emitted');
    unlike($formatted_card, qr/^.{820}/m, 'no formatted line reaches 820 bytes');
    my ($generated, $generate_output) = run_core($root, 'generate');
    ok($generated, 'folded card still generates') or diag($generate_output);
    my ($checked, $check_output) = run_core($root, 'check');
    ok($checked, 'folded card remains valid and fresh') or diag($check_output);
};

done_testing();

sub make_fixture {
    my $root = create_project_tempdir(purpose => 'knowledge-map-shards-tests');
    write_file($root, 'docs/knowledge/alpha-one-fact.md', fact_card(
        'alpha-one-fact', 'Alpha fact',
        ['shared retrieval question', 'alpha-specific question'],
    ));
    write_file($root, 'docs/knowledge/beta-two-fact.md', fact_card(
        'beta-two-fact', 'Beta fact',
        ['shared retrieval question', 'beta-specific question'],
    ));
    return $root;
}

sub fact_card {
    my ($id, $title, $answers) = @_;
    return join('',
        "---\n",
        "id: $id\n",
        "title: $title\n",
        "answers:\n",
        (map { "  - \"$_\"\n" } @{$answers}),
        "date: 2030-01-01\n",
        "status: current\n",
        "evidence: docs/reference.md\n",
        "reverify: test -f docs/reference.md\n",
        "---\n\n",
        "Bounded fixture signpost.\n",
    );
}

sub run_core {
    my ($root, $command, @args) = @_;
    my $overrides = @args && ref($args[-1]) eq 'HASH' ? pop @args : {};
    local %ENV = %ENV;
    $ENV{KM_ROOT} = $root;
    $ENV{KM_SCAN_DIRS} = 'docs/knowledge';
    $ENV{KM_OUTPUT} = 'KNOWLEDGE_MAP.md';
    $ENV{KM_SHARD_DIR} = 'knowledge-map/generated';
    $ENV{KM_QUERY_CACHE_DIR} = '.artifacts/knowledge-map/query';
    $ENV{KM_TITLE} = 'Fixture Knowledge Map';
    @ENV{keys %{$overrides}} = values %{$overrides};
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => [$^X, $core, $command, @args],
    );
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub projection_bytes {
    my ($root) = @_;
    my @paths = ('KNOWLEDGE_MAP.md');
    my $dir = path($root, 'knowledge-map/generated');
    opendir my $dh, $dir or die "cannot read $dir: $!";
    push @paths, map { "knowledge-map/generated/$_" }
        sort grep { /\.md\z/ } readdir $dh;
    closedir $dh;
    return join("\0", map { $_ . "\0" . read_file($root, $_) } @paths);
}

sub count_occurrences {
    my ($text, $needle) = @_;
    my $count = 0;
    my $position = 0;
    while (($position = index($text, $needle, $position)) >= 0) {
        ++$count;
        $position += length($needle);
    }
    return $count;
}

sub path {
    my ($root, $relative) = @_;
    return File::Spec->catfile($root, split m{/}, $relative);
}

sub read_file {
    my ($root, $relative) = @_;
    my $path = path($root, $relative);
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $contents = <$fh> // '';
    close $fh;
    return $contents;
}

sub write_file {
    my ($root, $relative, $contents) = @_;
    my $path = path($root, $relative);
    make_path(dirname($path)) if !-d dirname($path);
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $contents or die "cannot write $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub append_file {
    my ($root, $relative, $contents) = @_;
    my $path = path($root, $relative);
    open my $fh, '>>:raw', $path or die "cannot append $path: $!";
    print {$fh} $contents or die "cannot append $path: $!";
    close $fh or die "cannot close $path: $!";
}
