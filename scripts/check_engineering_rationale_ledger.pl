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

my $default_revision = 'd3c22e003d6e732a51dc69e6a999cdbd41963e84';
my $default_source_sha256 =
    'bf5a03fd8f99ba15cee146e35cce301f53f12e3c9ba514ef9c261c842a25c840';
my ($root_arg, $revision, $source_sha256, $source_path, $current_path,
    $index_path, $archives_path, $ledgers_path, $ledger_id, $help);
$revision = $default_revision;
$source_sha256 = $default_source_sha256;
$source_path = 'DEVELOPMENT_NOTES.md';
$current_path = 'DEVELOPMENT_NOTES.md';
$index_path = 'DEVELOPMENT_NOTES_INDEX.md';
$archives_path = 'doctrine/live_document_size/archive_descriptors.jsonl';
$ledgers_path = 'doctrine/live_document_size/ledger_manifests.jsonl';
$ledger_id = 'engineering_rationale';
GetOptions(
    'root=s'          => \$root_arg,
    'revision=s'      => \$revision,
    'source-sha256=s' => \$source_sha256,
    'source-path=s'   => \$source_path,
    'current-path=s'  => \$current_path,
    'index-path=s'    => \$index_path,
    'archives=s'      => \$archives_path,
    'ledgers=s'       => \$ledgers_path,
    'ledger-id=s'     => \$ledger_id,
    'help|h'          => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
die "engineering-rationale-ledger: invalid repository root\n"
    if !defined($root) || !-d $root;
for my $pair (
    [source_path => $source_path], [current_path => $current_path],
    [index_path => $index_path], [archives => $archives_path],
    [ledgers => $ledgers_path],
) {
    die "engineering-rationale-ledger: unsafe $pair->[0]\n"
        if !relative_path_ok($pair->[1]);
}
die "engineering-rationale-ledger: invalid ledger id\n"
    if $ledger_id !~ /\A[a-z][a-z0-9_.-]*\z/;
die "engineering-rationale-ledger: invalid expected source SHA-256\n"
    if $source_sha256 !~ /\A[0-9a-f]{64}\z/;

my @problems;
my ($git_status, $source, $git_stderr) = run_git('show', "$revision:$source_path");
if ($git_status != 0) {
    push @problems, "cannot retrieve immutable source $revision:$source_path: $git_stderr";
    $source = '';
}
elsif (sha256_hex($source) ne $source_sha256) {
    push @problems, 'immutable source SHA-256 changed';
}

my $archives = read_jsonl($archives_path, 'archive descriptor registry');
my $ledger_rows = read_jsonl($ledgers_path, 'ledger manifest registry');
my %descriptor = map {
    (($_->{descriptor_id} // '') => $_)
} grep { ($_->{record_type} // '') eq 'descriptor' } @{$archives};
my ($ledger) = grep {
    ($_->{record_type} // '') eq 'ledger'
        && ($_->{ledger_id} // '') eq $ledger_id
} @{$ledger_rows};
if (!$ledger) {
    push @problems, "missing ledger manifest $ledger_id";
    finish();
}
check_equal('ledger surface', $ledger->{surface_id}, 'engineering_rationale');
check_equal('ledger current path', $ledger->{current_path}, $current_path);
check_equal('ledger index path', $ledger->{index_path}, $index_path);
check_equal('ledger entry prefix', $ledger->{entry_start_prefix}, '## ');
check_equal('ledger ordering', $ledger->{ordering}, 'append_only');
check_equal(
    'ledger reconstruction verifier',
    $ledger->{reconstruction_verifier},
    'adapter:scripts/check_engineering_rationale_ledger.pl',
);

my @ranges = sort {
    ($a->{sequence} // 0) <=> ($b->{sequence} // 0)
} grep {
    ($_->{record_type} // '') eq 'range'
        && ($_->{ledger_id} // '') eq $ledger_id
} @{$ledger_rows};
push @problems, "ledger $ledger_id declares no ranges" if !@ranges;

my $source_descriptor = $descriptor{$ledger->{source_descriptor_id} // ''};
if (!$source_descriptor) {
    push @problems, "ledger $ledger_id source descriptor is missing";
} else {
    check_equal('source descriptor revision', $source_descriptor->{revision}, $revision);
    check_equal('source descriptor surface', $source_descriptor->{surface_id}, 'engineering_rationale');
    check_equal('source descriptor former path', $source_descriptor->{former_path}, $source_path);
    check_equal('source descriptor range id', $source_descriptor->{range_id}, 'complete-source');
    check_equal('source descriptor current pointer', $source_descriptor->{current_pointer}, $current_path);
    check_equal('source descriptor digest', $source_descriptor->{sha256}, $source_sha256);
    check_equal('source descriptor line count', $source_descriptor->{lines}, raw_line_count($source));
    check_equal('source descriptor byte count', $source_descriptor->{bytes}, length($source));
    check_equal('source descriptor retrieval kind', $source_descriptor->{retrieval_kind}, 'version_object');
}

my ($source_body, $source_entries) = ledger_entries($source, 1, 'immutable source');
my $current = read_regular($current_path, 'current rationale view');
my ($current_body, $current_entries) = ledger_entries($current, 1, 'current rationale view');
my $index = read_regular($index_path, 'rationale index');
push @problems, "current rationale view does not route to $index_path"
    if index($current, $ledger->{index_path} // '') < 0;

my @bodies;
my $expected_sequence = 0;
my $expected_ordinal = 1;
my $current_ranges = 0;
for my $range (@ranges) {
    my $range_id = $range->{range_id} // '<missing>';
    check_equal("range $range_id sequence", $range->{sequence}, ++$expected_sequence);
    check_equal("range $range_id first ordinal", $range->{first_ordinal}, $expected_ordinal);
    my $last = $range->{last_ordinal} // 0;
    my $count = $range->{entry_count} // 0;
    check_equal("range $range_id ordinal span", $last - $expected_ordinal + 1, $count);
    $expected_ordinal = $last + 1;
    push @problems, "rationale index omits range $range_id"
        if index($index, $range_id) < 0;

    my $body = '';
    my @entries;
    if (($range->{storage_kind} // '') eq 'current') {
        $current_ranges++;
        $body = $current_body;
        @entries = @{$current_entries};
    } elsif (($range->{storage_kind} // '') eq 'archive_descriptor') {
        my $range_descriptor = $descriptor{$range->{storage_locator} // ''};
        if (!$range_descriptor) {
            push @problems, "range $range_id archive descriptor is missing";
            next;
        }
        check_equal("range $range_id descriptor revision", $range_descriptor->{revision}, $revision);
        check_equal("range $range_id descriptor surface", $range_descriptor->{surface_id}, 'engineering_rationale');
        check_equal("range $range_id descriptor range id", $range_descriptor->{range_id}, $range_id);
        check_equal("range $range_id descriptor current pointer", $range_descriptor->{current_pointer}, $current_path);
        my $first_index = ($range->{first_ordinal} // 0) - 1;
        my $last_index = ($range->{last_ordinal} // 0) - 1;
        if ($first_index < 0 || $last_index > $#{$source_entries}) {
            push @problems, "range $range_id is not contained in the immutable source";
            next;
        }
        @entries = @{$source_entries}[$first_index .. $last_index];
        $body = join('', @entries);
        check_equal("range $range_id descriptor digest", $range_descriptor->{sha256}, sha256_hex($body));
        check_equal("range $range_id descriptor line count", $range_descriptor->{lines}, raw_line_count($body));
        check_equal("range $range_id descriptor byte count", $range_descriptor->{bytes}, length($body));
    } else {
        push @problems, "range $range_id uses unsupported storage kind";
        next;
    }

    check_equal("range $range_id entry count", scalar(@entries), $count);
    check_equal("range $range_id line count", raw_line_count($body), $range->{lines});
    check_equal("range $range_id byte count", length($body), $range->{bytes});
    check_equal("range $range_id digest", sha256_hex($body), $range->{sha256});
    check_equal("range $range_id first-entry digest", sha256_hex($entries[0] // ''), $range->{first_entry_sha256});
    check_equal("range $range_id last-entry digest", sha256_hex($entries[-1] // ''), $range->{last_entry_sha256});
    push @bodies, $body;
}

check_equal('current range count', $current_ranges, 1);
my $reconstructed = join('', @bodies);
check_equal('reconstructed entry count', $expected_ordinal - 1, $ledger->{total_entries});
check_equal('reconstructed line count', raw_line_count($reconstructed), $ledger->{entries_lines});
check_equal('reconstructed byte count', length($reconstructed), $ledger->{entries_bytes});
check_equal('reconstructed digest', sha256_hex($reconstructed), $ledger->{entries_sha256});
push @problems, 'immutable source entries are not the exact reconstruction prefix'
    if index($reconstructed, $source_body) != 0;
push @problems, 'post-cutover append proof is absent'
    if @{$source_entries} >= ($ledger->{total_entries} // 0);
push @problems, 'current range must contain at least one post-cutover entry'
    if !@{$current_entries};

finish();

sub finish {
    if (@problems) {
        print STDERR "engineering-rationale-ledger: $_\n" for @problems;
        exit 1;
    }
    print 'engineering-rationale-ledger: exact immutable source prefix plus '
        . scalar(@{$current_entries}) . " post-cutover current entr"
        . (scalar(@{$current_entries}) == 1 ? 'y' : 'ies')
        . " reconstructed across " . scalar(@ranges) . " ranges\n";
    exit 0;
}

sub check_equal {
    my ($label, $actual, $expected) = @_;
    $actual = '<undefined>' if !defined $actual;
    $expected = '<undefined>' if !defined $expected;
    push @problems, "$label changed ($actual != $expected)" if "$actual" ne "$expected";
}

sub ledger_entries {
    my ($contents, $allow_preamble, $label) = @_;
    my $prefix = '## ';
    my $first;
    if ($contents =~ /^\Q$prefix\E/m) {
        $first = $-[0];
    } else {
        push @problems, "$label contains no whole rationale entry";
        return ('', []);
    }
    if (!$allow_preamble && $first != 0) {
        push @problems, "$label has bytes before its first rationale entry";
    }
    my $body = substr($contents, $first);
    my @entries = ($body =~ /(\Q$prefix\E.*?)(?=^\Q$prefix\E|\z)/msg);
    push @problems, "$label entry parse did not cover its body"
        if join('', @entries) ne $body;
    return ($body, \@entries);
}

sub raw_line_count {
    my ($contents) = @_;
    return scalar(() = ($contents // '') =~ /\n/g);
}

sub read_jsonl {
    my ($relative, $label) = @_;
    my $contents = read_regular($relative, $label);
    my @records;
    my $line_number = 0;
    for my $line (split /\n/, $contents) {
        $line_number++;
        next if $line eq '';
        my $record = eval { decode_json($line) };
        die "engineering-rationale-ledger: invalid $label line $line_number\n"
            if $@ || ref($record) ne 'HASH';
        push @records, $record;
    }
    return \@records;
}

sub read_regular {
    my ($relative, $label) = @_;
    die "engineering-rationale-ledger: unsafe $label path\n"
        if !relative_path_ok($relative);
    my $path = root_path($relative);
    die "engineering-rationale-ledger: missing or unsafe $label: $relative\n"
        if !-f $path || -l $path;
    open my $fh, '<:raw', $path
        or die "engineering-rationale-ledger: cannot read $label: $!\n";
    local $/;
    my $contents = <$fh> // '';
    close $fh or die "engineering-rationale-ledger: cannot close $label: $!\n";
    return $contents;
}

sub relative_path_ok {
    my ($relative) = @_;
    return 0 if !defined($relative) || $relative eq '' || $relative =~ /\0/;
    return 0 if File::Spec->file_name_is_absolute($relative) || $relative =~ /\A~(?:\/|$)/;
    return 0 if grep { $_ eq '..' || $_ eq '' } split m{/+}, $relative;
    return 1;
}

sub root_path {
    my ($relative) = @_;
    return File::Spec->catfile($root, split m{/+}, $relative);
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

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_engineering_rationale_ledger.pl [--root DIR]
       [--revision REV] [--source-sha256 HEX] [--source-path PATH]
       [--current-path PATH] [--index-path PATH]
       [--archives PATH] [--ledgers PATH] [--ledger-id ID]
USAGE
    exit $status;
}
