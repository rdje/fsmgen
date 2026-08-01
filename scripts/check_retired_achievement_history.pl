#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

my $default_revision = 'b4d07fee5ffd6621503007958dcac3af8d44b345';
my $default_sha256 =
    '46c3c8ad2a0b7375a02b0a111bcc65410f78e0dd1df97709aeabe5f97b735d18';
my ($root_arg, $revision, $path, $sha256, $lines, $bytes, $longest, $help);
$revision = $default_revision;
$path = 'LIVE_ACHIEVEMENT_STATUS.md';
$sha256 = $default_sha256;
$lines = 16_618;
$bytes = 955_308;
$longest = 358;
GetOptions(
    'root=s'     => \$root_arg,
    'revision=s' => \$revision,
    'path=s'     => \$path,
    'sha256=s'   => \$sha256,
    'lines=i'    => \$lines,
    'bytes=i'    => \$bytes,
    'longest=i'  => \$longest,
    'help|h'     => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
die "retired-achievement-history: invalid repository root\n"
    if !defined($root) || !-d $root;
die "retired-achievement-history: unsafe retired path\n"
    if !relative_path_ok($path);

my @problems;
my $live = root_path($path);
push @problems, "$path is retired and must remain absent" if -e $live;

my ($status, $source, $stderr) = run_git('show', "$revision:$path");
if ($status != 0) {
    push @problems, "cannot retrieve $revision:$path: $stderr";
} else {
    my $actual_lines = () = $source =~ /\n/g;
    my $actual_bytes = length($source);
    my $actual_sha256 = sha256_hex($source);
    my $actual_longest = 0;
    for my $line (split /\n/, $source, -1) {
        my $width = length($line);
        $actual_longest = $width if $width > $actual_longest;
    }
    push @problems, "retrieved line count changed ($actual_lines != $lines)"
        if $actual_lines != $lines;
    push @problems, "retrieved byte count changed ($actual_bytes != $bytes)"
        if $actual_bytes != $bytes;
    push @problems, "retrieved longest line changed ($actual_longest != $longest)"
        if $actual_longest != $longest;
    push @problems, "retrieved SHA-256 changed ($actual_sha256 != $sha256)"
        if $actual_sha256 ne $sha256;
}

my @policy_paths = qw(
    AGENTS.md
    COMMIT.md
    MEMORY.md
    README.md
    TOOLBOX.md
    docs/TASK_TREE.md
    docs/book/src/90-reference-map.md
    doctrine/live_document_size/surfaces.jsonl
    doctrine/readme_entrypoint/routed_destinations.jsonl
);
for my $relative (@policy_paths) {
    my $contents = read_regular($relative);
    next if !defined $contents;
    push @problems, "active policy consumer still names retired $path: $relative"
        if index($contents, $path) >= 0
            || index($contents, 'frozen_achievement_status') >= 0;
}

my ($listed_status, $listed, $listed_stderr) = run_git('ls-files', '-z');
if ($listed_status != 0) {
    push @problems, "cannot enumerate tracked executable consumers: $listed_stderr";
} else {
    my %excluded = map { $_ => 1 } (
        'scripts/check_retired_achievement_history.pl',
        'scripts/check_doctrine_bootstrap.sh',
        't/1563-retired-achievement-history.t',
    );
    for my $relative (split /\0/, $listed) {
        next if $relative eq '' || $excluded{$relative};
        next if $relative ne 'Makefile'
            && $relative !~ m{\A(?:\.githooks|\.github|bin|perl|rust|scripts|t)/};
        my $contents = read_regular($relative);
        next if !defined($contents) || index($contents, "\0") >= 0;
        push @problems, "executable consumer still names retired $path: $relative"
            if index($contents, $path) >= 0;
    }
}

if (@problems) {
    print STDERR "retired-achievement-history: $_\n" for @problems;
    exit 1;
}

print "retired-achievement-history: exact $revision:$path recovery and zero live consumers verified\n";
exit 0;

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_retired_achievement_history.pl [--root DIR] [--revision REV]
       [--path PATH] [--sha256 HEX] [--lines N] [--bytes N] [--longest N]
USAGE
    exit $status;
}

sub relative_path_ok {
    my ($relative) = @_;
    return 0 if !defined($relative) || $relative eq '' || $relative =~ /\0/;
    return 0 if File::Spec->file_name_is_absolute($relative) || $relative =~ m{\A~(?:/|$)};
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
