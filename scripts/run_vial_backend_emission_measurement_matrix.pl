#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Getopt::Long qw(GetOptions);
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmissionMeasurementMatrix;

my $class =
    'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurementMatrix';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my ($validate, $family, $inventory, $help);

GetOptions(
    'validate' => \$validate,
    'family' => \$family,
    'inventory' => \$inventory,
    'help' => \$help,
) or usage(2);
usage(0) if $help;
usage(2) if @ARGV || ($inventory && ($validate || $family));

my $result;
if ($inventory) {
    $result = $class->inventory;
}
elsif ($validate) {
    $result = $family
        ? $class->validate_family_publication({
            repository_root => $repo_root,
        })
        : $class->validate_complete_publication({
            repository_root => $repo_root,
        });
}
else {
    $result = $family
        ? $class->capture_family({repository_root => $repo_root})
        : $class->capture_all({repository_root => $repo_root});
}

print JSON::PP->new->canonical(1)->utf8(1)->encode($result), "\n";

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage:
  scripts/run_vial_backend_emission_measurement_matrix.pl [options]

Options:
  --validate   Reload and independently validate existing publication.
  --family     Capture or validate only the backend_emission_v1 manifest.
  --inventory  Print the immutable 20-profile inventory without running.
  --help       Show this help.

Capture and validation must run below scripts/run_with_ram_guard.sh. Capture
also requires a clean Git revision. Each profile executes in an isolated child
and publishes an immutable content-addressed report before its compact result
crosses the bounded IPC envelope. The family and complete manifests publish
only after all 20 profiles share one clean Git/host/tool/guard identity.

This is structural backend-emission evidence. It does not compile, simulate,
run IASIM, establish backend support, or claim performance/capacity limits.
USAGE
    exit $status;
}
