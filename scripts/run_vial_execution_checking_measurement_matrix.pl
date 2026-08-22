#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Getopt::Long qw(GetOptions);
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix;

my $class =
    'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $family = 'all';
my ($validate, $inventory, $help);

GetOptions(
    'family=s' => \$family,
    'validate' => \$validate,
    'inventory' => \$inventory,
    'help' => \$help,
) or usage(2);
usage(0) if $help;
usage(2) if @ARGV || ($inventory && $validate);

my %selected = map { $_ => 1 }
    qw(all execution_graph_v1 checking_state_v1);
die "matrix family must be all, execution_graph_v1, or checking_state_v1\n"
    unless $selected{$family};

my $result;
if ($inventory) {
    die "--inventory does not accept --family\n" unless $family eq 'all';
    $result = $class->inventory;
}
elsif ($validate) {
    $result = $family eq 'all'
        ? $class->validate_complete_publication({
            repository_root => $repo_root,
        })
        : $class->validate_family_publication({
            repository_root => $repo_root,
            family => $family,
        });
}
else {
    $result = $family eq 'all'
        ? $class->capture_all({repository_root => $repo_root})
        : $class->capture_family({
            repository_root => $repo_root,
            family => $family,
        });
}

print JSON::PP->new->canonical(1)->utf8(1)->encode($result), "\n";

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage:
  scripts/run_vial_execution_checking_measurement_matrix.pl [options]

Options:
  --family FAMILY  Capture or validate one selected family; default: all.
                   FAMILY is execution_graph_v1 or checking_state_v1.
  --validate       Reload and independently validate existing publication.
  --inventory      Print the immutable 72-profile inventory without running.
  --help           Show this help.

Capture and validation must run below scripts/run_with_ram_guard.sh. Capture
also requires a clean revision. Completed profile sets are immutable and
resumable; source-free reports are sealed by the capture provenance envelope
without inventing a controller record. Family and complete manifests publish
only after their exact child inventories share one revision/host/tool/guard.
USAGE
    exit $status;
}
