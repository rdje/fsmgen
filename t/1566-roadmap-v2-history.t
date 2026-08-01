#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::ProjectDataLocality qw(create_project_tempdir);

my $repo = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $verifier = File::Spec->catfile(
    $repo, 'scripts', 'check_roadmap_v2_history.pl');

subtest 'exact activation object and bounded strategic view pass' => sub {
    my $fixture = make_fixture();
    my ($ok, $output) = run_verifier($fixture);
    ok($ok, 'exact Git source, descriptor, and bounded live roadmap pass')
        or diag($output);
    like(
        $output,
        qr/exact activation source recovery and bounded live direction verified/,
        'success reports both durable history and bounded current direction',
    );
};

subtest 'descriptor drift and missing Git history fail independently' => sub {
    my $descriptor = make_fixture();
    rewrite_descriptor($descriptor->{root}, sub { $_[0]{sha256} = '0' x 64 });
    my ($descriptor_ok, $descriptor_output) = run_verifier($descriptor);
    ok(!$descriptor_ok, 'descriptor identity drift fails');
    like($descriptor_output, qr/descriptor .* field sha256 changed/,
        'descriptor mismatch names the changed field');

    my $history = make_fixture();
    $history->{revision} = '0' x 40;
    my ($history_ok, $history_output) = run_verifier($history);
    ok(!$history_ok, 'missing version object fails');
    like($history_output, qr/cannot retrieve/,
        'missing required history is explicit');
};

subtest 'chronology residue and missing authority routes fail closed' => sub {
    my $chronology = make_fixture();
    append_file($chronology->{root}, 'ROADMAP_V2.md',
        "\n## Current intent\n- appended leaf chronology\n");
    my ($chronology_ok, $chronology_output) = run_verifier($chronology);
    ok(!$chronology_ok, 'revived chronology heading fails');
    like($chronology_output, qr/unbounded Current intent chronology heading/,
        'chronology residue is named');

    my $route = make_fixture();
    my $current = read_file($route->{root}, 'ROADMAP_V2.md');
    $current =~ s{docs/book/src/SUMMARY\.md}{docs/book/src/REMOVED.md}g;
    write_file($route->{root}, 'ROADMAP_V2.md', $current);
    my ($route_ok, $route_output) = run_verifier($route);
    ok(!$route_ok, 'missing shipped-behavior route fails');
    like($route_output, qr/omits required direction\/recovery marker: docs\/book\/src\/SUMMARY\.md/,
        'missing canonical route is named');
};

subtest 'warning-safe live bounds are enforced independently' => sub {
    my $fixture = make_fixture();
    $fixture->{max_live_lines} = 5;
    my ($ok, $output) = run_verifier($fixture);
    ok(!$ok, 'live roadmap above configured warning-safe line bound fails');
    like($output, qr/line count exceeds warning-safe bound/,
        'pressure failure names the exceeded dimension');
};

done_testing();

sub make_fixture {
    my $root = create_project_tempdir(purpose => 'roadmap-v2-history-tests');
    run_git($root, 'init');
    run_git($root, 'config', 'user.name', 'Fixture');
    run_git($root, 'config', 'user.email', 'fixture@example.invalid');

    my $source = "# Old roadmap\n\n## Current intent\n\n- exact chronology\n";
    write_file($root, 'ROADMAP_V2.md', $source);
    run_git($root, 'add', 'ROADMAP_V2.md');
    run_git($root, 'commit', '-m', 'fixture roadmap activation source');
    my $revision = run_git_output($root, 'rev-parse', 'HEAD');
    my $sha256 = sha256_hex($source);
    my $lines = line_count($source);
    my $bytes = length($source);
    my $longest = longest_line($source);

    my $current = join("\n",
        '# Bounded roadmap',
        'MEMORY.md docs/TASK_TREE.md docs/book/src/SUMMARY.md',
        '## Product objective',
        '## Governing principles',
        '### R8. Language-contract hardening',
        '### R9. Strict mode and support-tier enforcement',
        '### R10. Source provenance and diagnostics',
        '### R11. Composition, types, and compiler ownership',
        '### R12. Regression corpus and support accounting',
        '### R13. Embedding, reports, and semantic introspection',
        '### R14. Intent scheduling and layered intent',
        '## Dependency and sequencing policy',
        '## Current execution',
        '## Long-term horizon',
        '### H1. Rust and portable implementations',
        '### H2. Public project website',
        '### H3. HDL import and intent recovery',
        '### H4. Specification-driven intent capture',
        '### H5. VHDL backend',
        '### H6. End-to-end large-design scalability',
        '## Exact pre-containment roadmap recovery',
        "git show $revision:ROADMAP_V2.md",
        '',
    );
    write_file($root, 'ROADMAP_V2.md', $current);

    my $descriptor = {
        record_type => 'descriptor', schema_version => 1,
        descriptor_id => 'roadmap_fixture', surface_id => 'exact_history',
        former_path => 'ROADMAP_V2.md',
        range_id => 'complete-activation-source', revision => $revision,
        lines => $lines, bytes => $bytes, sha256 => $sha256,
        retrieval_kind => 'version_object',
        retrieval_locator => "git show $revision:ROADMAP_V2.md",
        current_pointer => 'ROADMAP_V2.md', sealed_on => '2030-01-01',
        verifier => 'adapter:scripts/check_roadmap_v2_history.pl',
        retention_contract => 'fsmgen_required_history',
    };
    write_jsonl($root, 'registry/archive.jsonl', $descriptor);
    return {
        root => $root, revision => $revision, sha256 => $sha256,
        lines => $lines, bytes => $bytes, longest => $longest,
        descriptor_id => 'roadmap_fixture',
    };
}

sub run_verifier {
    my ($fixture) = @_;
    my @command = (
        $verifier,
        '--root', $fixture->{root},
        '--archives', 'registry/archive.jsonl',
        '--descriptor-id', $fixture->{descriptor_id},
        '--revision', $fixture->{revision},
        '--sha256', $fixture->{sha256},
        '--lines', $fixture->{lines},
        '--bytes', $fixture->{bytes},
        '--longest', $fixture->{longest},
    );
    push @command, '--max-live-lines', $fixture->{max_live_lines}
        if defined $fixture->{max_live_lines};
    my ($ok, undef, undef, $stdout, $stderr) = run(command => \@command);
    return ($ok, join('', @{$stdout || []}, @{$stderr || []}));
}

sub rewrite_descriptor {
    my ($root, $mutator) = @_;
    my $relative = 'registry/archive.jsonl';
    my $contents = read_file($root, $relative);
    my @records = map { JSON::PP::decode_json($_) }
        grep { $_ ne '' } split /\n/, $contents;
    $mutator->($_) for grep { ($_->{record_type} // '') eq 'descriptor' } @records;
    my $json = JSON::PP->new->canonical(1);
    write_file($root, $relative,
        join('', map { $json->encode($_) . "\n" } @records));
}

sub write_jsonl {
    my ($root, $relative, $descriptor) = @_;
    my $json = JSON::PP->new->canonical(1);
    my $registry = {
        record_type => 'registry', schema_version => 1,
        max_records => 8, max_bytes => 8192, max_record_bytes => 4096,
    };
    write_file($root, $relative,
        $json->encode($registry) . "\n" . $json->encode($descriptor) . "\n");
}

sub line_count {
    my ($contents) = @_;
    return scalar(() = $contents =~ /\n/g);
}

sub longest_line {
    my ($contents) = @_;
    my $longest = 0;
    for my $line (split /\n/, $contents, -1) {
        $longest = length($line) if length($line) > $longest;
    }
    return $longest;
}

sub read_file {
    my ($root, $relative) = @_;
    my $path = File::Spec->catfile($root, split m{/+}, $relative);
    open my $fh, '<:raw', $path or die "cannot read $relative: $!";
    local $/;
    my $contents = <$fh> // '';
    close $fh;
    return $contents;
}

sub append_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/+}, $relative);
    open my $fh, '>>:raw', $path or die "cannot append $relative: $!";
    print {$fh} $contents or die "cannot append $relative: $!";
    close $fh;
}

sub write_file {
    my ($root, $relative, $contents) = @_;
    my $path = File::Spec->catfile($root, split m{/+}, $relative);
    my (undef, $dirs) = File::Spec->splitpath($path);
    make_path($dirs) if $dirs ne '' && !-d $dirs;
    open my $fh, '>:raw', $path or die "cannot write $relative: $!";
    print {$fh} $contents or die "cannot write $relative: $!";
    close $fh;
}

sub run_git {
    my ($root, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $root, @args]);
    die "git @args failed: " . join('', @{$stdout || []}, @{$stderr || []})
        if !$ok;
}

sub run_git_output {
    my ($root, @args) = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $root, @args]);
    die "git @args failed: " . join('', @{$stdout || []}, @{$stderr || []})
        if !$ok;
    my $output = join('', @{$stdout || []});
    $output =~ s/\s+\z//;
    return $output;
}
