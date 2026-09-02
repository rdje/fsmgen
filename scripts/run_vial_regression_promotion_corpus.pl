#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Cwd ();
use File::Spec;
use FindBin;
use Getopt::Long qw(GetOptions);
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator';
my $maximum_output_bytes = 1_048_576;
my ($limits, $inventory, $capture, $validate, $help);

Getopt::Long::Configure(qw(no_auto_abbrev no_ignore_case));
GetOptions(
    'limits' => \$limits,
    'inventory' => \$inventory,
    'capture' => \$capture,
    'validate' => \$validate,
    'help' => \$help,
) or usage(2);

my $operation_count = grep { $_ } ($limits, $inventory, $capture, $validate);
usage(0) if $help && !$operation_count && !@ARGV;
usage(2) if $help || @ARGV || $operation_count != 1;

my $repo_root = Cwd::realpath(File::Spec->catdir($FindBin::Bin, '..'));
die "corpus CLI repository root is unavailable\n"
    unless defined($repo_root) && -d($repo_root) && !-l($repo_root);

my $result = $limits ? {
    schema =>
        'fsmgen.vial_architecture_scale_regression_promotion_corpus_cli_limits.v1',
    schema_version => 1,
    maximum_output_bytes => $maximum_output_bytes,
    coordination => $class->coordination_limits,
} : $inventory ? $class->inventory({repository_root => $repo_root})
    : $capture ? $class->capture({repository_root => $repo_root})
    : $class->validate({repository_root => $repo_root});

my $output = JSON::PP->new->canonical(1)->utf8(1)->encode($result) . "\n";
die "corpus CLI result exceeds the bounded CLI output envelope\n"
    if bytes::length($output) > $maximum_output_bytes;
print $output or die "cannot write corpus CLI result: $!\n";

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage:
  scripts/run_vial_regression_promotion_corpus.pl OPERATION

Exactly one operation is required:
  --limits     Print fixed coordinator and CLI-output envelopes without running.
  --inventory  Census current profile and complete publications without workers.
  --capture    Capture missing or resume present profiles, then seal when complete.
  --validate   Resume-validate every profile and load an existing complete seal.
  --help       Show this help without selecting an operation.

Inventory, capture, and validation require the repository RAM guard and one
clean Git revision. The repository root is derived from this tracked script;
there is no caller path, plan, profile, result, worker, or callback injection.
--capture may execute real providers and tools. It publishes a complete seal
only after every selected profile passes. --inventory executes no worker.
--validate is producer-free, requires an existing seal, and never republishes.

Canonical JSON output, including its newline, is bounded before any byte is
written. This command creates evidence; it does not promote a performance
budget, support or capacity claim, or ordinary hosted-CI capture cadence.
USAGE
    exit $status;
}
