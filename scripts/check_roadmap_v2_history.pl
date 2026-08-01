#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IPC::Open3 qw(open3);
use JSON::PP qw(decode_json);
use Symbol qw(gensym);

my $default_revision = 'dc1c64afb62bc128d2cf28c493d5eebc7726b02a';
my $default_sha256 =
    '6c7e00fe39cd8052b4a19d497d1fff60a37a1a6db9511126fa0735a030ade2b3';
my ($root_arg, $archives, $descriptor_id, $revision, $path, $sha256,
    $lines, $bytes, $longest, $max_live_lines, $max_live_bytes,
    $max_live_line_bytes, $help);
$archives = 'doctrine/live_document_size/archive_descriptors.jsonl';
$descriptor_id = 'roadmap-v2-pre-containment-2026-08-01';
$revision = $default_revision;
$path = 'ROADMAP_V2.md';
$sha256 = $default_sha256;
$lines = 10_451;
$bytes = 772_074;
$longest = 2_297;
$max_live_lines = 1_599;
$max_live_bytes = 209_715;
$max_live_line_bytes = 819;
GetOptions(
    'root=s'                => \$root_arg,
    'archives=s'            => \$archives,
    'descriptor-id=s'       => \$descriptor_id,
    'revision=s'            => \$revision,
    'path=s'                => \$path,
    'sha256=s'              => \$sha256,
    'lines=i'               => \$lines,
    'bytes=i'               => \$bytes,
    'longest=i'             => \$longest,
    'max-live-lines=i'      => \$max_live_lines,
    'max-live-bytes=i'      => \$max_live_bytes,
    'max-live-line-bytes=i' => \$max_live_line_bytes,
    'help|h'                => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
die "roadmap-history: invalid repository root\n"
    if !defined($root) || !-d $root;
for my $relative ($archives, $path) {
    die "roadmap-history: unsafe project path: $relative\n"
        if !relative_path_ok($relative);
}

my @problems;
my @descriptors = grep {
    ($_->{record_type} // '') eq 'descriptor'
        && ($_->{descriptor_id} // '') eq $descriptor_id
} @{read_jsonl($archives)};
if (@descriptors != 1) {
    push @problems,
        "descriptor $descriptor_id must appear exactly once (found "
        . scalar(@descriptors) . ')';
} else {
    my $descriptor = $descriptors[0];
    my %expected = (
        surface_id => 'exact_history', former_path => $path,
        range_id => 'complete-activation-source', revision => $revision,
        lines => $lines, bytes => $bytes, sha256 => $sha256,
        retrieval_kind => 'version_object',
        retrieval_locator => "git show $revision:$path",
        current_pointer => $path,
        verifier => 'adapter:scripts/check_roadmap_v2_history.pl',
        retention_contract => 'fsmgen_required_history',
    );
    for my $field (sort keys %expected) {
        my $actual = $descriptor->{$field};
        $actual = '' if !defined($actual) || ref($actual);
        push @problems,
            "descriptor $descriptor_id field $field changed ($actual != $expected{$field})"
            if "$actual" ne "$expected{$field}";
    }
}

my ($status, $source, $stderr) = run_git('show', "$revision:$path");
if ($status != 0) {
    push @problems, "cannot retrieve $revision:$path: $stderr";
} else {
    check_identity('retrieved activation source', $source,
        $lines, $bytes, $longest, $sha256, \@problems);
}

my $current = read_regular($path);
if (!defined $current) {
    push @problems, "current roadmap is missing, irregular, or unreadable: $path";
} else {
    my ($current_lines, $current_bytes, $current_longest, $current_sha256) =
        dimensions($current);
    push @problems, "current roadmap line count exceeds warning-safe bound ($current_lines > $max_live_lines)"
        if $current_lines > $max_live_lines;
    push @problems, "current roadmap byte count exceeds warning-safe bound ($current_bytes > $max_live_bytes)"
        if $current_bytes > $max_live_bytes;
    push @problems, "current roadmap line width exceeds warning-safe bound ($current_longest > $max_live_line_bytes)"
        if $current_longest > $max_live_line_bytes;
    push @problems, 'current roadmap still equals the activation chronology object'
        if $current_sha256 eq $sha256;
    push @problems, 'current roadmap retains the unbounded Current intent chronology heading'
        if $current =~ /^## Current intent\s*$/m;

    my @required = (
        '## Product objective', '## Governing principles',
        '### R8. Language-contract hardening',
        '### R9. Strict mode and support-tier enforcement',
        '### R10. Source provenance and diagnostics',
        '### R11. Composition, types, and compiler ownership',
        '### R12. Regression corpus and support accounting',
        '### R13. Embedding, reports, and semantic introspection',
        '### R14. Intent scheduling and layered intent',
        '## Dependency and sequencing policy', '## Current execution',
        '## Long-term horizon', '### H1. Rust and portable implementations',
        '### H2. Public project website',
        '### H3. HDL import and intent recovery',
        '### H4. Specification-driven intent capture',
        '### H5. VHDL backend',
        '### H6. End-to-end large-design scalability',
        '## Exact pre-containment roadmap recovery',
        'MEMORY.md', 'docs/TASK_TREE.md', 'docs/book/src/SUMMARY.md',
        "git show $revision:$path",
    );
    for my $marker (@required) {
        push @problems, "current roadmap omits required direction/recovery marker: $marker"
            if index($current, $marker) < 0;
    }
}

if (@problems) {
    print STDERR "roadmap-history: $_\n" for @problems;
    exit 1;
}

print "roadmap-history: exact activation source recovery and bounded live direction verified\n";
exit 0;

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_roadmap_v2_history.pl [--root DIR] [--archives PATH]
       [--descriptor-id ID] [--revision REV] [--path PATH]
       [--sha256 HEX] [--lines N] [--bytes N] [--longest N]
       [--max-live-lines N] [--max-live-bytes N] [--max-live-line-bytes N]
USAGE
    exit $status;
}

sub relative_path_ok {
    my ($relative) = @_;
    return 0 if !defined($relative) || $relative eq '' || $relative =~ /\0/;
    return 0 if File::Spec->file_name_is_absolute($relative)
        || $relative =~ m{\A~(?:/|$)};
    return 0 if grep { $_ eq '..' } split m{/+}, $relative;
    return 1;
}

sub root_path {
    my ($relative) = @_;
    return File::Spec->catfile($root, split m{/+}, $relative);
}

sub read_regular {
    my ($relative) = @_;
    return undef if !relative_path_ok($relative);
    my $absolute = root_path($relative);
    return undef if !-f $absolute || -l $absolute;
    open my $fh, '<:raw', $absolute or return undef;
    local $/;
    my $contents = <$fh> // '';
    close $fh;
    return $contents;
}

sub read_jsonl {
    my ($relative) = @_;
    my $contents = read_regular($relative);
    if (!defined $contents) {
        push @problems, "archive descriptor registry is missing or unreadable: $relative";
        return [];
    }
    my @records;
    my $line_number = 0;
    for my $line (split /\n/, $contents) {
        ++$line_number;
        next if $line =~ /^\s*$/;
        my $record = eval { decode_json($line) };
        if (!$record || ref($record) ne 'HASH') {
            push @problems, "invalid JSON object in $relative line $line_number";
            next;
        }
        push @records, $record;
    }
    return \@records;
}

sub dimensions {
    my ($contents) = @_;
    my $line_count = () = $contents =~ /\n/g;
    my $byte_count = length($contents);
    my $longest_line = 0;
    for my $line (split /\n/, $contents, -1) {
        my $width = length($line);
        $longest_line = $width if $width > $longest_line;
    }
    return ($line_count, $byte_count, $longest_line, sha256_hex($contents));
}

sub check_identity {
    my ($label, $contents, $expected_lines, $expected_bytes,
        $expected_longest, $expected_sha256, $problems) = @_;
    my ($actual_lines, $actual_bytes, $actual_longest, $actual_sha256) =
        dimensions($contents);
    push @{$problems}, "$label line count changed ($actual_lines != $expected_lines)"
        if $actual_lines != $expected_lines;
    push @{$problems}, "$label byte count changed ($actual_bytes != $expected_bytes)"
        if $actual_bytes != $expected_bytes;
    push @{$problems}, "$label longest line changed ($actual_longest != $expected_longest)"
        if $actual_longest != $expected_longest;
    push @{$problems}, "$label SHA-256 changed ($actual_sha256 != $expected_sha256)"
        if $actual_sha256 ne $expected_sha256;
}

sub run_git {
    my (@args) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, 'git', '-C', $root, @args);
    close $stdin;
    binmode $stdout;
    binmode $stderr;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? >> 8, $out, $err);
}
