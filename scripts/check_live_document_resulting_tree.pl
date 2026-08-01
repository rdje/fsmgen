#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Glob qw(bsd_glob GLOB_NOSORT);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IPC::Open3 qw(open3);
use JSON::PP;
use Symbol qw(gensym);

my ($root_arg, $surfaces, $routes, $archives, $ledgers, $evidence_maps,
    $retention_contracts, $help);
$surfaces = 'doctrine/live_document_size/surfaces.jsonl';
$routes = 'doctrine/readme_entrypoint/routed_destinations.jsonl';
$archives = 'doctrine/live_document_size/archive_descriptors.jsonl';
$ledgers = 'doctrine/live_document_size/ledger_manifests.jsonl';
$evidence_maps = 'doctrine/live_document_size/evidence_maps.jsonl';
$retention_contracts =
    'doctrine/live_document_size/version_retention_contracts.jsonl';
GetOptions(
    'root=s'          => \$root_arg,
    'surfaces=s'      => \$surfaces,
    'routes=s'        => \$routes,
    'archives=s'      => \$archives,
    'ledgers=s'       => \$ledgers,
    'evidence-maps=s' => \$evidence_maps,
    'retention-contracts=s' => \$retention_contracts,
    'help|h'          => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
if (!defined($root) || !-d $root) {
    print STDERR "live-doc-resulting-tree: invalid project root\n";
    exit 2;
}

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_live_document_resulting_tree.pl [--root DIR]
       [--surfaces FILE] [--routes FILE] [--archives FILE]
       [--ledgers FILE]
       [--evidence-maps FILE] [--retention-contracts FILE]
USAGE
    exit $status;
}

sub relative_path_ok {
    my ($path) = @_;
    return 0 if !defined($path) || $path eq '' || $path =~ /\0/;
    return 0 if File::Spec->file_name_is_absolute($path) || $path =~ m{^~(?:/|$)};
    return 0 if grep { $_ eq '..' } split m{/+}, $path;
    return 1;
}

sub run_git {
    my (@args) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, 'git', '-C', $root, @args);
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? >> 8, $out, $err);
}

sub read_file {
    my ($relative) = @_;
    return undef if !relative_path_ok($relative);
    my $path = File::Spec->catfile($root, split m{/+}, $relative);
    return undef if !-f $path || -l $path;
    open my $fh, '<:raw', $path or return undef;
    local $/;
    my $contents = <$fh> // '';
    close $fh;
    return $contents;
}

sub jsonl {
    my ($relative) = @_;
    my $contents = read_file($relative);
    return [] if !defined $contents;
    my @records;
    for my $line (grep { $_ ne '' } split /\n/, $contents) {
        my $record = eval { decode_json($line) };
        push @records, $record if !$@ && ref($record) eq 'HASH';
    }
    return \@records;
}

my ($git_status) = run_git('rev-parse', '--is-inside-work-tree');
if ($git_status != 0) {
    print "live-doc-resulting-tree: non-Git fixture uses the checked worktree\n";
    exit 0;
}

my ($staged_status, $staged) = run_git('diff', '--cached', '--name-only');
if ($staged_status != 0 || $staged eq '') {
    print "live-doc-resulting-tree: checked worktree mode (no staged result)\n";
    exit 0;
}

my %controlled = map { $_ => 1 }
    ($surfaces, $routes, $archives, $ledgers, $evidence_maps, $retention_contracts);
for my $record (@{jsonl($surfaces)}) {
    $controlled{$record->{index}} = 1 if relative_path_ok($record->{index});
    for my $pattern (@{$record->{targets} || []}) {
        next if !relative_path_ok($pattern) || $pattern =~ /\A[^\/]+:[^\/]/;
        my $absolute = File::Spec->catfile($root, split m{/+}, $pattern);
        for my $match (bsd_glob($absolute, GLOB_NOSORT)) {
            next if !-f $match;
            my $prefix = $root . '/';
            $controlled{substr($match, length($prefix))} = 1
                if index($match, $prefix) == 0;
        }
    }
}
for my $record (@{jsonl($routes)}) {
    $controlled{$record->{source_path}} = 1 if relative_path_ok($record->{source_path});
}
for my $record (@{jsonl($ledgers)}) {
    next if ($record->{record_type} // '') !~ /\A(?:ledger|range)\z/;
    for my $key (qw(current_path index_path storage_locator)) {
        my $path = $record->{$key};
        $controlled{$path} = 1 if relative_path_ok($path) && -f File::Spec->catfile(
            $root, split m{/+}, $path,
        );
    }
}
for my $record (@{jsonl($evidence_maps)}) {
    my $source = $record->{source_path};
    next if !relative_path_ok($source);
    $controlled{$source} = 1;
    my $contents = read_file($source) // '';
    my $begin = $record->{begin_marker} // '';
    my $end = $record->{end_marker} // '';
    my $begin_at = $begin eq '' ? -1 : index($contents, $begin);
    my $end_at = $begin_at < 0 || $end eq '' ? -1
        : index($contents, $end, $begin_at + length($begin));
    next if $begin_at < 0 || $end_at < 0;
    my $body = substr($contents, $begin_at + length($begin),
        $end_at - ($begin_at + length($begin)));
    $controlled{$_} = 1 for grep { relative_path_ok($_) }
        ($body =~ /^\|[^\n|]*\|\s*`([^`]+)`\s*\|\s*$/mg);
}

my ($status_code, $status) = run_git('status', '--porcelain=v1', '-z', '--untracked-files=all');
if ($status_code != 0) {
    print STDERR "live-doc-resulting-tree: cannot inspect staged/worktree agreement\n";
    exit 1;
}
my @problems;
for my $entry (split /\0/, $status) {
    next if length($entry) < 4;
    my $xy = substr($entry, 0, 2);
    my $path = substr($entry, 3);
    next if !$controlled{$path};
    push @problems, $path if substr($xy, 1, 1) ne ' ' || $xy eq '??';
}
if (@problems) {
    print STDERR "live-doc-resulting-tree: controlled path differs between staged result and worktree: $_\n"
        for sort @problems;
    exit 1;
}

print "live-doc-resulting-tree: staged result and checked worktree agree on controlled paths\n";
