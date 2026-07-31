#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use JSON::PP;

my ($root_arg, $registry, $archives, $help);
$registry = 'doctrine/live_document_size/surfaces.jsonl';
$archives = 'doctrine/live_document_size/archive_descriptors.jsonl';
GetOptions(
    'root=s'     => \$root_arg,
    'registry=s' => \$registry,
    'archives=s' => \$archives,
    'help|h'     => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
if (!defined($root) || !-d $root) {
    print STDERR "live-doc-adapter-verifier: invalid project root\n";
    exit 2;
}

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: run_live_document_adapter_verifiers.pl [--root DIR]
       [--registry FILE] [--archives FILE]
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

sub root_path {
    my ($relative) = @_;
    return File::Spec->catfile($root, split m{/+}, $relative);
}

sub read_jsonl {
    my ($relative, $label) = @_;
    die "live-doc-adapter-verifier: unsafe $label path: $relative\n"
        if !relative_path_ok($relative);
    my $path = root_path($relative);
    die "live-doc-adapter-verifier: missing $label: $relative\n" if !-f $path || -l $path;
    open my $fh, '<:raw', $path
        or die "live-doc-adapter-verifier: cannot read $label $relative: $!\n";
    my @records;
    my $line_number = 0;
    while (my $line = <$fh>) {
        $line_number++;
        $line =~ s/\r?\n\z//;
        die "live-doc-adapter-verifier: blank $label line $line_number\n" if $line eq '';
        my $record = eval { decode_json($line) };
        die "live-doc-adapter-verifier: invalid $label line $line_number\n"
            if $@ || ref($record) ne 'HASH';
        push @records, $record;
    }
    close $fh or die "live-doc-adapter-verifier: cannot close $label $relative: $!\n";
    return \@records;
}

sub execute_adapter {
    my ($proof_id, $relative) = @_;
    die "live-doc-adapter-verifier: unsafe adapter verifier for $proof_id: $relative\n"
        if !relative_path_ok($relative);
    my $absolute = root_path($relative);
    die "live-doc-adapter-verifier: adapter verifier is absent or not executable for $proof_id: $relative\n"
        if !-f $absolute || !-x $absolute;
    my $pid = fork();
    die "live-doc-adapter-verifier: cannot fork $relative: $!\n" if !defined $pid;
    if ($pid == 0) {
        chdir $root or exit 126;
        open STDIN, '<', File::Spec->devnull() or exit 126;
        open STDOUT, '>&', STDERR or exit 126;
        exec {$absolute} $absolute;
        exit 126;
    }
    waitpid($pid, 0);
    if ($? != 0) {
        my $status = $? & 127 ? 'signal ' . ($? & 127) : 'exit ' . ($? >> 8);
        die "live-doc-adapter-verifier: adapter verifier failed ($status) for $proof_id: $relative\n";
    }
    print "$proof_id\n";
}

my @adapters;
my $surface_records = read_jsonl($registry, 'surface registry');
for my $record (@{$surface_records}) {
    my $verifier = $record->{verifier} // '';
    next if $verifier !~ /\Aadapter:(.+)\z/;
    my $path = $1;
    my $id = $record->{surface_id} // '';
    die "live-doc-adapter-verifier: invalid adapter surface id\n"
        if $id !~ /\A[a-z][a-z0-9_]*\z/;
    push @adapters, ["surface:$id", $path];
}
for my $record (@{$surface_records}) {
    my $currency = $record->{currency};
    next if ref($currency) ne 'HASH';
    next if ($record->{lifecycle} // '')
        =~ /\A(?:archive_terminal|external_terminal|frozen_legacy)\z/;
    next if ($currency->{contract_id} // '') !~ /\A[a-z][a-z0-9_.-]*\z/;
    my $verifier = $currency->{verifier} // '';
    next if $verifier !~ /\Aadapter:(.+)\z/;
    my $path = $1;
    my $id = $record->{surface_id} // '';
    die "live-doc-adapter-verifier: invalid currency surface id\n"
        if $id !~ /\A[a-z][a-z0-9_]*\z/;
    push @adapters, ["currency:$id", $path];
}
for my $record (@{read_jsonl($archives, 'archive descriptor registry')}) {
    next if ($record->{record_type} // '') ne 'descriptor';
    next if ($record->{retrieval_kind} // '') ne 'version_object';
    my $verifier = $record->{verifier} // '';
    next if $verifier !~ /\Aadapter:(.+)\z/;
    my $path = $1;
    my $id = $record->{descriptor_id} // '';
    die "live-doc-adapter-verifier: invalid adapter archive id\n"
        if $id !~ /\A[a-z][a-z0-9_.-]*\z/;
    push @adapters, ["archive:$id", $path];
}

my %seen;
for my $adapter (@adapters) {
    die "live-doc-adapter-verifier: duplicate adapter proof id: $adapter->[0]\n"
        if $seen{$adapter->[0]}++;
    execute_adapter(@{$adapter});
}
