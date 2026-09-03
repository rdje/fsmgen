#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_NOFOLLOW O_RDONLY);
use File::Spec;
use FindBin;
use JSON::PP ();
use Scalar::Util qw(blessed);

my $ROOT = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "hosted gate verifier: repository root is unavailable\n";
my $RESULT_RELATIVE = join '/', qw(
    .artifacts qualification vial-scale v2 regression-promotion-gate-v1
    current regression-promotion-gate-result.json
);
my $STAGING_RELATIVE = join '/', qw(
    .artifacts tmp vial-scale regression-promotion-gate-publication v1
);
my $QUALIFICATION_IDENTITY =
    'regression-promotion-qualification/'
    . 'd8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97';
my $QUALIFICATION_PUBLICATION_IDENTITY =
    'regression-promotion-budget-qualification-publication/'
    . '1c2a3832b2b4163e1a6a8124feff2b452f8522c2929098447f3903115ad2945f';
my $QUALIFICATION_FILE_SET_SHA256 =
    '28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095';
my $MAX_RESULT_BYTES = 1_048_576;
my $MAX_OUTPUT_BYTES = 16_384;
my $MAX_ERROR_BYTES = 4_096;
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

my @RESULT_KEYS = qw(
    schema schema_version gate_result_identity contract_identity
    qualification_identity qualification_publication_identity
    qualification_file_set_sha256 execution_revision coordinator_revision
    summary profiles classification outcome diagnostics cleanup
    explicit_nonclaims
);
my @SUMMARY_KEYS = qw(
    profile_count required_validation_records required_raw_measurement_records
    required_controller_invocations observed_validation_records
    observed_raw_measurement_records observed_controller_invocations
    sample_exclusions passed_profiles failed_profiles informational_profiles
    unavailable_profiles complete_observation
);
my @PROFILE_KEYS = qw(
    schema schema_version profile_result_identity contract_identity
    qualification_identity qualification_publication_identity
    qualification_file_set_sha256 ordinal selection_key execution_revision
    report observation observed_environment provider performance outcome
    diagnostics cleanup explicit_nonclaims
);

@ARGV == 0 or _fail('caller arguments are forbidden');
my $verified;
my $ok = eval {
    _require_guard();
    _require_root();
    _fail('result-publication staging residue is present')
        if -e "$ROOT/$STAGING_RELATIVE" || -l "$ROOT/$STAGING_RELATIVE";
    my ($result, $bytes) = _load_result();
    _validate_result($result);
    $verified = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_hosted_verification.v1',
        schema_version => 1,
        outcome => 'accepted_hosted_gate_observation',
        gate_result_identity => $result->{gate_result_identity},
        qualification_identity => $result->{qualification_identity},
        qualification_publication_identity =>
            $result->{qualification_publication_identity},
        qualification_file_set_sha256 =>
            $result->{qualification_file_set_sha256},
        result_bytes => bytes::length($bytes),
        aggregate_classification => $result->{classification},
        aggregate_outcome => $result->{outcome},
        informational_ordinals => [1 .. 7, 11],
        unavailable_ordinals => [8 .. 10],
        required_topology => {
            validation_records => 11,
            raw_measurement_records => 33,
            controller_invocations => 44,
        },
        observed_topology => {
            validation_records => 8,
            raw_measurement_records => 24,
            controller_invocations => 32,
        },
        explicit_nonclaims => [qw(
            hosted_performance support_promotion architecture_scale_capacity
        )],
    };
    1;
};
_fail($@) unless $ok;

my $output = $JSON->encode($verified) . "\n";
_fail('verification output exceeds its bounded ceiling')
    if bytes::length($output) > $MAX_OUTPUT_BYTES;
print $output or _fail("cannot write verification result: $!");

sub _validate_result {
    my ($result) = @_;
    _exact_keys($result, \@RESULT_KEYS, 'gate result');
    _fail('gate result schema changed')
        unless ($result->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1'
            && _integer_is($result->{schema_version}, 1);

    my $identity = $result->{gate_result_identity} // '';
    my $projection = _clone($result);
    $projection->{gate_result_identity} = undef;
    _fail('gate result content identity changed')
        unless $identity eq 'regression-promotion-gate-result/'
            . sha256_hex($JSON->encode($projection));
    _fail('gate result authority identity changed')
        unless ($result->{contract_identity} // '') =~
                m{\Aregression-promotion-gate-contract/[0-9a-f]{64}\z}
            && ($result->{execution_revision} // '') =~ /\A[0-9a-f]{40}\z/
            && ($result->{coordinator_revision} // '') eq
                'regression_promotion_gate_coordinator_v1';
    _fail('gate result qualification identity changed')
        unless ($result->{qualification_identity} // '') eq
                $QUALIFICATION_IDENTITY
            && ($result->{qualification_publication_identity} // '') eq
                $QUALIFICATION_PUBLICATION_IDENTITY
            && ($result->{qualification_file_set_sha256} // '') eq
                $QUALIFICATION_FILE_SET_SHA256;
    _fail('hosted aggregate outcome changed')
        unless ($result->{classification} // '') eq 'unavailable'
            && ($result->{outcome} // '') eq 'unavailable';
    _fail('hosted gate diagnostics are nonempty')
        unless ref($result->{diagnostics}) eq 'ARRAY'
            && !@{$result->{diagnostics}};

    my $summary = $result->{summary};
    _exact_keys($summary, \@SUMMARY_KEYS, 'gate summary');
    my %expected = (
        profile_count => 11,
        required_validation_records => 11,
        required_raw_measurement_records => 33,
        required_controller_invocations => 44,
        observed_validation_records => 8,
        observed_raw_measurement_records => 24,
        observed_controller_invocations => 32,
        sample_exclusions => 0,
        passed_profiles => 0,
        failed_profiles => 0,
        informational_profiles => 8,
        unavailable_profiles => 3,
    );
    for my $key (sort keys %expected) {
        _fail("hosted gate summary $key changed")
            unless _integer_is($summary->{$key}, $expected{$key});
    }
    _fail('hosted gate falsely reports complete observation')
        unless _boolean_is($summary->{complete_observation}, 0);

    my $profiles = $result->{profiles};
    _fail('hosted gate profile inventory changed')
        unless ref($profiles) eq 'ARRAY' && @$profiles == 11;
    for my $index (0 .. 10) {
        my $profile = $profiles->[$index];
        my $ordinal = $index + 1;
        _exact_keys($profile, \@PROFILE_KEYS, "gate profile $ordinal");
        my $profile_identity = $profile->{profile_result_identity} // '';
        my $profile_projection = _clone($profile);
        $profile_projection->{profile_result_identity} = undef;
        _fail("hosted gate profile $ordinal content identity changed")
            unless $profile_identity eq
                'regression-promotion-gate-profile-result/'
                . sha256_hex($JSON->encode($profile_projection));
        _fail("hosted gate profile $ordinal order changed")
            unless _integer_is($profile->{ordinal}, $ordinal)
                && defined($profile->{selection_key})
                && !ref($profile->{selection_key})
                && length($profile->{selection_key});
        _fail("hosted gate profile $ordinal identity binding changed")
            unless ($profile->{contract_identity} // '') eq
                    $result->{contract_identity}
                && ($profile->{qualification_identity} // '') eq
                    $QUALIFICATION_IDENTITY
                && ($profile->{qualification_publication_identity} // '') eq
                    $QUALIFICATION_PUBLICATION_IDENTITY
                && ($profile->{qualification_file_set_sha256} // '') eq
                    $QUALIFICATION_FILE_SET_SHA256
                && ($profile->{execution_revision} // '') eq
                    $result->{execution_revision};
        _fail("hosted gate profile $ordinal structure changed")
            unless ref($profile->{observation}) eq 'HASH'
                && ref($profile->{provider}) eq 'HASH'
                && ref($profile->{performance}) eq 'HASH';

        my $informational = $ordinal <= 7 || $ordinal == 11;
        my ($classification, $outcome, $availability, $reason) =
            $informational
                ? qw(informational accepted_informational available environment_identity_mismatch)
                : qw(unavailable unavailable unavailable exact_provider_unavailable);
        _fail("hosted gate profile $ordinal classification changed")
            unless ($profile->{performance}{classification} // '') eq
                    $classification
                && ($profile->{performance}{reason} // '') eq $reason
                && ($profile->{outcome} // '') eq $outcome
                && ($profile->{provider}{availability} // '') eq
                    $availability
                && _boolean_is(
                    $profile->{performance}{exact_environment}, 0,
                );
        my @counts = $informational ? (1, 3, 4) : (0, 0, 0);
        for my $pair (
            ['validation_records', $counts[0]],
            ['raw_measurement_records', $counts[1]],
            ['controller_invocations', $counts[2]],
        ) {
            _fail("hosted gate profile $ordinal $pair->[0] changed")
                unless _integer_is(
                    $profile->{observation}{$pair->[0]}, $pair->[1],
                );
        }
        _fail("hosted gate profile $ordinal has sample exclusions")
            unless _integer_is(
                $profile->{observation}{sample_exclusions}, 0,
            );
        _fail("hosted gate profile $ordinal unavailable provider passed")
            if !$informational
                && ($profile->{performance}{classification} // '') eq 'pass';
    }
    return 1;
}

sub _load_result {
    my $path = "$ROOT/$RESULT_RELATIVE";
    my @root_stat = lstat($ROOT);
    my @before = lstat($path);
    _fail('hosted gate result is unavailable') unless @before;
    _fail('hosted gate result file identity is unsafe')
        unless -f _ && !-l _ && $before[0] == $root_stat[0]
            && $before[4] == $> && $before[3] == 1
            && $before[7] <= $MAX_RESULT_BYTES;
    sysopen my $fh, $path, O_RDONLY | O_NOFOLLOW
        or _fail('cannot open hosted gate result');
    my $bytes = '';
    while (bytes::length($bytes) <= $MAX_RESULT_BYTES) {
        my $read = sysread($fh, my $chunk, 65_536);
        _fail('cannot read hosted gate result') unless defined $read;
        last unless $read;
        $bytes .= $chunk;
    }
    close $fh or _fail('cannot close hosted gate result');
    my @after = lstat($path);
    _fail('hosted gate result changed while reading')
        unless @after && join(':', @before[0, 1, 3, 4, 7, 9]) eq
            join(':', @after[0, 1, 3, 4, 7, 9]);
    _fail('hosted gate result exceeds its bounded ceiling')
        if bytes::length($bytes) > $MAX_RESULT_BYTES;
    my $result = eval { $JSON->decode($bytes) };
    _fail('hosted gate result is not canonical JSON')
        unless ref($result) eq 'HASH' && !blessed($result)
            && $JSON->encode($result) . "\n" eq $bytes;
    return ($result, $bytes);
}

sub _require_guard {
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    _fail('active repository RAM guard is required')
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1'
            && defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host > 0 && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss > 0 && $rss <= 4096;
}

sub _require_root {
    my @stat = lstat($ROOT);
    _fail('repository root identity is invalid')
        unless @stat && -d _ && !-l _ && $stat[4] == $>
            && (-d "$ROOT/.git" || -f "$ROOT/.git")
            && !-l "$ROOT/.git";
}

sub _exact_keys {
    my ($value, $keys, $label) = @_;
    _fail("$label is malformed")
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { ($_ => 1) } @$keys;
    _fail("$label contains an unknown key")
        if grep { !$expected{$_} } keys %$value;
    _fail("$label is missing a key")
        if grep { !exists($value->{$_}) } @$keys;
}

sub _integer_is {
    my ($value, $expected) = @_;
    return defined($value) && !ref($value)
        && "$value" =~ /\A(?:0|[1-9][0-9]*)\z/
        && 0 + $value == $expected;
}

sub _boolean_is {
    my ($value, $expected) = @_;
    return JSON::PP::is_bool($value)
        && ($value ? 1 : 0) == $expected;
}

sub _clone {
    return $JSON->decode($JSON->encode($_[0]));
}

sub _fail {
    my ($raw) = @_;
    my $message = defined($raw) && !ref($raw) && length($raw)
        ? $raw : 'unknown failure';
    $message =~ s/\Q$ROOT\E/<repository-root>/g;
    $message =~ s/[\r\n].*\z//s;
    $message =~ s/[\x00-\x1f\x7f]/ /g;
    $message =~ s/[^\x20-\x7e]/?/g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    my $prefix = 'hosted gate verifier: ';
    my $available = $MAX_ERROR_BYTES
        - bytes::length($prefix) - bytes::length("\n");
    $message = substr($message, 0, $available)
        if bytes::length($message) > $available;
    print STDERR $prefix, $message, "\n";
    exit 1;
}
