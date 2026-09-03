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

use FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator;
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore;

my $COORDINATOR =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator';
my $STORE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore';
my $MAX_OUTPUT_BYTES = 1_048_576;
my $MAX_ERROR_BYTES = 4_096;
my ($run, $validate_result, $help);

Getopt::Long::Configure(qw(no_auto_abbrev no_ignore_case));
GetOptions(
    'run' => sub { ++$run },
    'validate-result' => sub { ++$validate_result },
    'help' => sub { ++$help },
) or usage(2);

my $operation_count = ($run // 0) + ($validate_result // 0);
usage(0) if ($help // 0) == 1 && !$operation_count && !@ARGV;
usage(2) if $help || @ARGV || $operation_count != 1;

my $repository_root =
    Cwd::realpath(File::Spec->catdir($FindBin::Bin, '..'));
fail_bounded('repository root is unavailable', undef)
    unless defined($repository_root)
        && -d($repository_root) && !-l($repository_root);

my $output;
my $completed = eval {
    my $limits = $STORE->publication_limits;
    _exact_keys(
        $limits,
        [qw(
            publication_revision publication_relative_path
            staging_relative_path maximum_result_bytes maximum_error_bytes
            maximum_recovery_entries
        )],
        'store limits',
    );
    die "store result ceiling changed\n"
        unless _json_integer_equals(
                $limits->{maximum_result_bytes}, $MAX_OUTPUT_BYTES,
            )
            && _json_integer_equals(
                $limits->{maximum_error_bytes}, $MAX_ERROR_BYTES,
            );

    if ($run) {
        my $artifact = $STORE->publish({
            repository_root => $repository_root,
        });
        _exact_keys($artifact, $STORE->artifact_keys, 'store artifact');
    }
    my $load = $STORE->load({
        repository_root => $repository_root,
    });
    _exact_keys($load, $STORE->load_result_keys, 'store load');
    _exact_keys(
        $load->{artifact}, $STORE->artifact_keys,
        'loaded artifact',
    );
    _exact_keys(
        $load->{result}, $COORDINATOR->result_keys,
        'gate result',
    );
    $output = JSON::PP->new->canonical(1)->utf8(1)
        ->encode($load->{result}) . "\n";
    die "gate result exceeds the bounded CLI output envelope\n"
        if bytes::length($output) > $MAX_OUTPUT_BYTES;
    1;
};
fail_bounded($@, $repository_root) unless $completed;

print $output
    or fail_bounded("cannot write gate result: $!", $repository_root);

sub _exact_keys($value, $keys, $label) {
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

sub _json_integer_equals($value, $expected) {
    return defined($value) && !ref($value)
        && "$value" =~ /\A(?:0|[1-9][0-9]*)\z/
        && 0 + $value == $expected;
}

sub fail_bounded($raw, $repository_root) {
    my $message = defined($raw) && !ref($raw) && length($raw)
        ? $raw : 'unknown failure';
    $message =~ s/\Q$repository_root\E/<repository-root>/g
        if defined($repository_root) && length($repository_root);
    $message =~ s/[\r\n].*\z//s;
    $message =~ s/[\x00-\x1f\x7f]/ /g;
    $message =~ s/[^\x20-\x7e]/?/g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    $message = 'unknown failure' unless length($message);
    my $prefix = 'regression-promotion gate CLI failed: ';
    my $available = $MAX_ERROR_BYTES
        - bytes::length($prefix) - bytes::length("\n");
    $message = substr($message, 0, $available)
        if bytes::length($message) > $available;
    print STDERR $prefix, $message, "\n";
    exit 1;
}

sub usage($status) {
    print STDERR <<'USAGE';
Usage:
  scripts/run_vial_regression_promotion_gate.pl OPERATION

Exactly one operation is required:
  --run              Execute all eleven fresh gate profiles, atomically replace
                     the latest result, reload it, and print the gate result.
  --validate-result  Producer-free validation and printing of the current
                     stored gate result.
  --help             Show this help without selecting an operation.

Both operations require the repository RAM guard. --run additionally requires
one unchanged clean Git revision and may execute real providers, simulators,
and measurement controllers. There is no default expensive operation. The
repository root comes only from this tracked script; callers cannot supply a
path, result, qualification, budget, applicability identity, provider, worker,
or callback. No flag can downgrade exact-environment performance enforcement.

Canonical gate-result JSON, including its newline, is buffered completely and
capped at 1,048,576 bytes before stdout. Failures return status 1 with one
repository-path-sanitized diagnostic capped at 4,096 bytes. Usage errors
return status 2 and emit no JSON result. Gate observations never recalibrate,
overwrite, or become evidence for the immutable qualification and do not by
themselves promote support or capacity.
USAGE
    exit $status;
}
