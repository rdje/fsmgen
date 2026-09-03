#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use bytes ();
use Cwd ();
use File::Spec;
use FindBin;
use Getopt::Long qw(GetOptions);
use JSON::PP ();
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore';
my $maximum_output_bytes = 1_048_576;
my $maximum_error_bytes = 4_096;
my ($publish, $validate, $help);

Getopt::Long::Configure(qw(no_auto_abbrev no_ignore_case));
GetOptions(
    'publish' => \$publish,
    'validate' => \$validate,
    'help' => \$help,
) or usage(2);

my $operation_count = grep { $_ } ($publish, $validate);
usage(0) if $help && !$operation_count && !@ARGV;
usage(2) if $help || @ARGV || $operation_count != 1;

my $repo_root = Cwd::realpath(File::Spec->catdir($FindBin::Bin, '..'));
fail_bounded('repository root is unavailable', undef)
    unless defined($repo_root) && -d($repo_root) && !-l($repo_root);

my ($result, $output);
my $completed = eval {
    $result = $publish
        ? $class->publish({repository_root => $repo_root})
        : $class->load({repository_root => $repo_root});
    my $keys = $publish
        ? $class->artifact_keys : $class->load_result_keys;
    exact_keys($result, $keys, 'store result');
    $output = JSON::PP->new->canonical(1)->utf8(1)->encode($result) . "\n";
    die "result exceeds the bounded CLI output envelope\n"
        if bytes::length($output) > $maximum_output_bytes;
    1;
};
fail_bounded($@, $repo_root) unless $completed;

print $output
    or fail_bounded("cannot write result: $!", $repo_root);

sub exact_keys($value, $keys, $label) {
    die "$label is invalid\n"
        unless ref($value) eq 'HASH' && !blessed($value)
            && ref($keys) eq 'ARRAY';
    my %expected = map { $_ => 1 } @$keys;
    die "$label contains an unknown key\n"
        if grep { !$expected{$_} } keys %$value;
    die "$label is missing a key\n"
        if grep { !exists($value->{$_}) } @$keys;
    return 1;
}

sub fail_bounded($raw, $repo_root) {
    my $message = defined($raw) && !ref($raw) && length($raw)
        ? $raw : 'unknown failure';
    $message =~ s/\Q$repo_root\E/<repository-root>/g
        if defined($repo_root) && length($repo_root);
    $message =~ s/[\r\n].*\z//s;
    $message =~ s/[\x00-\x1f\x7f]/ /g;
    $message =~ s/[^\x20-\x7e]/?/g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    $message = 'unknown failure' unless length($message);
    my $prefix = 'qualification publication CLI failed: ';
    my $available = $maximum_error_bytes
        - bytes::length($prefix) - bytes::length("\n");
    $message = substr($message, 0, $available)
        if bytes::length($message) > $available;
    print STDERR $prefix, $message, "\n";
    exit 1;
}

sub usage($status) {
    print STDERR <<'USAGE';
Usage:
  scripts/run_vial_regression_promotion_budget_qualification.pl OPERATION

Exactly one operation is required:
  --publish   Derive the current qualification and create its immutable seal.
  --validate  Rederive the current qualification and validate the existing seal.
  --help      Show this help without selecting an operation.

Publish and validate require the repository RAM guard. Publish additionally
requires one unchanged clean Git revision. The repository root is derived from
this tracked script; there is no caller path, evidence, budget, publisher,
predecessor, recalibration, rollback, worker, or callback injection.

Neither operation executes a producer, provider, simulator, or measurement
controller. Publication does not activate performance enforcement, promote a
support or capacity claim, or report a fresh performance result.

Canonical JSON output, including its newline, is capped at 1,048,576 bytes and
is buffered completely before writing. Failures return status 1 with one
repository-path-sanitized diagnostic capped at 4,096 bytes. Usage errors return
status 2 and emit no JSON result.
USAGE
    exit $status;
}
