#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use JSON::PP;

my ($root_arg, $registry, $source, $help);
$registry = 'doctrine/readme_entrypoint/routed_destinations.jsonl';
$source = 'scripts/check_readme_entrypoint.sh';
GetOptions(
    'root=s'     => \$root_arg,
    'registry=s' => \$registry,
    'source=s'   => \$source,
    'help|h'     => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
if (!defined($root) || !-d $root) {
    print STDERR "live-doc-route-candidates: invalid project root\n";
    exit 2;
}

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_live_document_route_candidates.pl [--root DIR]
       [--registry FILE] [--source FILE]
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

sub read_file {
    my ($relative, $label) = @_;
    die "live-doc-route-candidates: unsafe $label path: $relative\n"
        if !relative_path_ok($relative);
    my $path = File::Spec->catfile($root, split m{/+}, $relative);
    die "live-doc-route-candidates: missing $label: $relative\n" if !-f $path || -l $path;
    open my $fh, '<:raw', $path
        or die "live-doc-route-candidates: cannot read $label $relative: $!\n";
    local $/;
    my $contents = <$fh> // '';
    close $fh or die "live-doc-route-candidates: cannot close $label $relative: $!\n";
    return $contents;
}

my $registry_text = read_file($registry, 'route registry');
my %declared;
my $line_number = 0;
for my $line (split /\n/, $registry_text) {
    $line_number++;
    next if $line eq '';
    my $record = eval { decode_json($line) };
    die "live-doc-route-candidates: invalid route registry line $line_number\n"
        if $@ || ref($record) ne 'HASH';
    next if ($record->{route_kind} // '') ne 'author_overflow';
    next if ($record->{source_path} // '') ne $source;
    my $key = join("\0", @{$record}{qw(route_kind target_surface_id marker)});
    die "live-doc-route-candidates: duplicate author route declaration at line $line_number\n"
        if $declared{$key}++;
}

my $source_text = read_file($source, 'route-candidate source');
my %emitted;
$line_number = 0;
for my $line (split /\n/, $source_text) {
    $line_number++;
    if ($line =~ /^\s*route_hint\s+(author_overflow|reader_navigation)\s+
            ([a-z][a-z0-9_]*)\s+'([^']+)'\s+'([^']*)'\s*$/x) {
        my ($kind, $target, $marker, $message) = ($1, $2, $3, $4);
        die "live-doc-route-candidates: route hint line $line_number does not emit marker: $marker\n"
            if index($message, $marker) < 0;
        my $key = join("\0", $kind, $target, $marker);
        die "live-doc-route-candidates: duplicate emitted route hint at line $line_number\n"
            if $emitted{$key}++;
        die "live-doc-route-candidates: undeclared emitted route hint at line $line_number: $kind $target $marker\n"
            if !$declared{$key};
    } elsif ($line =~ /^\s*note\s+"\s\s.*\b(?:move|route|send|write|record|append)\b.*
            (?:[A-Za-z0-9_.-]+\/|[A-Za-z0-9_.-]+\.md)\S*/ix) {
        die "live-doc-route-candidates: path-shaped author guidance bypasses route_hint at line $line_number\n";
    }
}

for my $key (sort keys %declared) {
    die "live-doc-route-candidates: declared author route is not emitted by $source\n"
        if !$emitted{$key};
}
die "live-doc-route-candidates: route-candidate source has no author_overflow hints: $source\n"
    if !%emitted;

print "live-doc-route-candidates: all emitted author-overflow routes are declared ("
    . scalar(keys %emitted) . " hints)\n";
