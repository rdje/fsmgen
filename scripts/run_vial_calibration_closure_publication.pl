#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Getopt::Long qw(GetOptions);
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleCalibrationClosurePublication;

my $class =
    'FSM::VIAL::ArchitectureScaleCalibrationClosurePublication';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my ($validate, $limits, $help);

GetOptions(
    'validate' => \$validate,
    'limits' => \$limits,
    'help' => \$help,
) or usage(2);
usage(0) if $help;
usage(2) if @ARGV || ($validate && $limits);

my $result = $limits ? $class->publication_limits
    : $validate ? $class->validate_complete_publication({
        repository_root => $repo_root,
    })
    : $class->capture_all({repository_root => $repo_root});

print JSON::PP->new->canonical(1)->utf8(1)->encode($result), "\n";

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage:
  scripts/run_vial_calibration_closure_publication.pl [options]

Options:
  --validate  Reload and independently validate the immutable publication.
  --limits    Print fixed storage and worker-result envelopes without running.
  --help      Show this help.

Capture and validation must run below scripts/run_with_ram_guard.sh. Capture
also requires a clean Git revision. The closure authority derives inside an
isolated child, atomically publishes a full canonical report plus compact
manifest on the repository volume, and returns only the manifest through the
bounded IPC envelope. Validation reloads the two immutable files in a distinct
child and rechecks their schemas, content identities, census, candidate-only
formula, hashes, applicability, exclusions, cleanup, dominance, and nonclaims.

The publication is calibration evidence only. It does not promote a budget,
implement a cap or performance gate, establish support or capacity, or change
a public API.
USAGE
    exit $status;
}
