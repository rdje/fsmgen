package FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator;

use v5.20;
use strict;
use warnings;

use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract;
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile;

my $CONTRACT =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract';
my $PROFILE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile';
my $SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1';
my $IDENTITY_PREFIX = 'regression-promotion-gate-result/';
my $REVISION = 'regression_promotion_gate_coordinator_v1';
my $PROFILE_COUNT = 11;
my $VALIDATION_RECORDS = 11;
my $RAW_MEASUREMENT_RECORDS = 33;
my $CONTROLLER_INVOCATIONS = 44;
my $SAMPLE_EXCLUSIONS = 0;
my $MAX_SAFE_INTEGER = 9_007_199_254_740_991;

my @RESULT_KEYS = qw(
    schema schema_version gate_result_identity contract_identity
    qualification_identity qualification_publication_identity
    qualification_file_set_sha256 execution_revision coordinator_revision
    summary profiles classification outcome diagnostics cleanup
    explicit_nonclaims
);
my @SUMMARY_KEYS = qw(
    profile_count required_validation_records
    required_raw_measurement_records required_controller_invocations
    observed_validation_records observed_raw_measurement_records
    observed_controller_invocations sample_exclusions passed_profiles
    failed_profiles informational_profiles unavailable_profiles
    complete_observation
);
my @CLEANUP_KEYS = qw(
    profile_report_spools_removed worker_process_residue
);
my @NONCLAIMS = qw(
    qualification_evidence
    qualification_recalibration
    qualification_overwrite
    result_publication
    historical_artifact_reuse
    support_promotion
    architecture_scale_capacity
    whole_product_capacity
);
my @CLASSIFICATION_ORDER = qw(
    fail unavailable informational pass
);
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub result_keys($class) {
    _exact_invocant($class, 'result_keys');
    return [@RESULT_KEYS];
}

sub summary_keys($class) {
    _exact_invocant($class, 'summary_keys');
    return [@SUMMARY_KEYS];
}

sub coordination_limits($class) {
    _exact_invocant($class, 'coordination_limits');
    my $limits = $CONTRACT->contract_limits;
    return {
        implementation_revision => $REVISION,
        maximum_result_bytes => $limits->{maximum_result_bytes},
        maximum_profile_ipc_bytes =>
            $limits->{maximum_profile_ipc_bytes},
        profile_count => $PROFILE_COUNT,
        validation_records => $VALIDATION_RECORDS,
        raw_measurement_records => $RAW_MEASUREMENT_RECORDS,
        controller_invocations => $CONTROLLER_INVOCATIONS,
        sample_exclusions => $SAMPLE_EXCLUSIONS,
    };
}

sub run($class, @args) {
    _exact_invocant($class, 'run');
    my $request = _request('run', \@args, [qw(repository_root)]);
    _require_active_guard();
    my $repository_root = _repository_root($request->{repository_root});
    my $execution_revision = _require_clean_revision($repository_root);
    my $contract = $CONTRACT->derive({
        repository_root => $repository_root,
    });
    _require_unchanged_clean_revision(
        $repository_root, $execution_revision,
    );
    _validate_contract_boundary($contract);
    my $contract_snapshot = _canonical_json($contract);

    my (@profiles, @worker_results, @worker_snapshots);
    my %seen_identity;
    my $common_environment;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $contract_profile = $contract->{profiles}[$index];
        confess "regression gate coordination contract order changed\n"
            unless _json_integer_equals(
                $contract_profile->{ordinal}, $index + 1,
            );
        my $worker_result = $PROFILE->_run_for_coordinator({
            repository_root => $repository_root,
            ordinal => $index + 1,
            contract => $contract,
            execution_revision => $execution_revision,
        });
        confess "regression gate coordination contract mutated during worker execution\n"
            unless _canonical_json($contract) eq $contract_snapshot;
        _require_unchanged_clean_revision(
            $repository_root, $execution_revision,
        );
        confess "regression gate coordination worker result is malformed\n"
            unless ref($worker_result) eq 'HASH'
                && !blessed($worker_result);
        my $worker_bytes = _canonical_json($worker_result);
        confess "regression gate coordination worker result exceeds its bound\n"
            if bytes::length($worker_bytes) >
                $contract->{result_contract}{maximum_profile_ipc_bytes};
        my $admitted = $PROFILE->_admit_for_coordinator({
            result => $worker_result,
            contract => $contract,
            execution_revision => $execution_revision,
        });
        confess "regression gate coordination worker result changed on admission\n"
            unless _canonical_json($admitted) eq $worker_bytes;
        confess "regression gate coordination profile identity is duplicated\n"
            if $seen_identity{$admitted->{profile_result_identity}}++;
        $common_environment = _join_common_environment(
            $common_environment, $admitted,
        );
        push @worker_results, $worker_result;
        push @worker_snapshots, $worker_bytes;
        push @profiles, $admitted;
    }
    confess "regression gate coordination did not visit every profile once\n"
        unless @profiles == $PROFILE_COUNT;
    for my $index (0 .. $#worker_results) {
        confess "regression gate coordination worker evidence mutated\n"
            unless _canonical_json($worker_results[$index]) eq
                $worker_snapshots[$index];
    }
    _require_unchanged_clean_revision(
        $repository_root, $execution_revision,
    );

    my $summary = _summary($contract, \@profiles);
    my $classification = _aggregate_classification($summary);
    my $result = {
        schema => $SCHEMA,
        schema_version => 1,
        gate_result_identity => undef,
        contract_identity => $contract->{contract_identity},
        qualification_identity =>
            $contract->{qualification_evidence}{qualification_identity},
        qualification_publication_identity =>
            $contract->{qualification_evidence}{publication_identity},
        qualification_file_set_sha256 =>
            $contract->{qualification_evidence}
                {qualification_file_set_sha256},
        execution_revision => $execution_revision,
        coordinator_revision => $REVISION,
        summary => $summary,
        profiles => \@profiles,
        classification => $classification,
        outcome => _outcome($classification),
        diagnostics => [],
        cleanup => {
            profile_report_spools_removed => $PROFILE_COUNT,
            worker_process_residue => JSON::PP::false,
        },
        explicit_nonclaims => [@NONCLAIMS],
    };
    $result->{gate_result_identity} =
        $IDENTITY_PREFIX . sha256_hex(_canonical_json($result));
    _validate_result($result, $contract, $execution_revision);
    _require_unchanged_clean_revision(
        $repository_root, $execution_revision,
    );
    return _clone($result);
}

sub _validate_contract_boundary($contract) {
    my $limits = $CONTRACT->contract_limits;
    confess "regression gate coordination contract is malformed\n"
        unless ref($contract) eq 'HASH' && !blessed($contract)
            && ($contract->{contract_identity} // '') =~
                m{\Aregression-promotion-gate-contract/[0-9a-f]{64}\z}
            && ref($contract->{qualification_evidence}) eq 'HASH'
            && ref($contract->{execution_contract}) eq 'HASH'
            && ref($contract->{result_contract}) eq 'HASH'
            && ref($contract->{profiles}) eq 'ARRAY';
    confess "regression gate coordination qualification evidence changed\n"
        unless ($contract->{qualification_evidence}
                    {qualification_identity} // '') =~
                m{\Aregression-promotion-qualification/[0-9a-f]{64}\z}
            && ($contract->{qualification_evidence}
                    {publication_identity} // '') =~
                m{\Aregression-promotion-budget-qualification-publication/[0-9a-f]{64}\z}
            && ($contract->{qualification_evidence}
                    {qualification_file_set_sha256} // '') =~
                /\A[0-9a-f]{64}\z/;
    confess "regression gate coordination contract result schema changed\n"
        unless ($contract->{result_contract}{schema} // '') eq $SCHEMA
            && ($contract->{result_contract}{profile_schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_gate_profile_result.v1'
            && ($contract->{result_contract}{identity_prefix} // '') eq
                $IDENTITY_PREFIX
            && _json_integer_equals(
                $contract->{result_contract}{maximum_result_bytes},
                $limits->{maximum_result_bytes},
            )
            && _json_integer_equals(
                $contract->{result_contract}{maximum_profile_ipc_bytes},
                $limits->{maximum_profile_ipc_bytes},
            );
    confess "regression gate coordination contract workload changed\n"
        unless @{$contract->{profiles}} == $PROFILE_COUNT
            && _json_integer_equals(
                $contract->{execution_contract}{profile_count},
                $PROFILE_COUNT,
            )
            && _json_integer_equals(
                $contract->{execution_contract}{total_validation_records},
                $VALIDATION_RECORDS,
            )
            && _json_integer_equals(
                $contract->{execution_contract}
                    {total_raw_measurement_records},
                $RAW_MEASUREMENT_RECORDS,
            )
            && _json_integer_equals(
                $contract->{execution_contract}
                    {total_controller_invocations},
                $CONTROLLER_INVOCATIONS,
            );
    for my $index (0 .. $PROFILE_COUNT - 1) {
        confess "regression gate coordination contract order changed\n"
            unless _json_integer_equals(
                    $contract->{profiles}[$index]{ordinal}, $index + 1,
                )
                && defined($contract->{profiles}[$index]{selection_key})
                && !ref($contract->{profiles}[$index]{selection_key});
    }
    return 1;
}

sub _join_common_environment($common, $profile) {
    return $common
        if ($profile->{performance}{classification} // '') eq
            'unavailable';
    my $environment = $profile->{observed_environment};
    confess "regression gate coordination environment is malformed\n"
        unless ref($environment) eq 'HASH';
    my $candidate = {
        host_profile => _clone($environment->{host_profile}),
        resource_guard => _clone($environment->{resource_guard}),
    };
    confess "regression gate coordination mixed host or guard state\n"
        if defined($common)
            && _canonical_json($candidate) ne _canonical_json($common);
    return defined($common) ? $common : $candidate;
}

sub _summary($contract, $profiles) {
    my %counts = map { ($_ => 0) } qw(
        pass fail informational unavailable
    );
    my ($validations, $measurements, $invocations, $exclusions) =
        (0, 0, 0, 0);
    for my $profile (@$profiles) {
        my $classification = $profile->{performance}{classification} // '';
        confess "regression gate coordination classification is invalid\n"
            unless exists $counts{$classification};
        ++$counts{$classification};
        $validations += _json_nonnegative_integer(
            $profile->{observation}{validation_records},
            'regression gate observed validation count',
        );
        $measurements += _json_nonnegative_integer(
            $profile->{observation}{raw_measurement_records},
            'regression gate observed measurement count',
        );
        $invocations += _json_nonnegative_integer(
            $profile->{observation}{controller_invocations},
            'regression gate observed invocation count',
        );
        $exclusions += _json_nonnegative_integer(
            $profile->{observation}{sample_exclusions},
            'regression gate sample exclusion count',
        );
    }
    confess "regression gate coordination admitted sample exclusions\n"
        unless $exclusions == $SAMPLE_EXCLUSIONS;
    my $complete = $validations == $VALIDATION_RECORDS
        && $measurements == $RAW_MEASUREMENT_RECORDS
        && $invocations == $CONTROLLER_INVOCATIONS;
    return {
        profile_count => 0 + scalar(@$profiles),
        required_validation_records =>
            0 + $contract->{execution_contract}
                {total_validation_records},
        required_raw_measurement_records =>
            0 + $contract->{execution_contract}
                {total_raw_measurement_records},
        required_controller_invocations =>
            0 + $contract->{execution_contract}
                {total_controller_invocations},
        observed_validation_records => $validations,
        observed_raw_measurement_records => $measurements,
        observed_controller_invocations => $invocations,
        sample_exclusions => $exclusions,
        passed_profiles => $counts{pass},
        failed_profiles => $counts{fail},
        informational_profiles => $counts{informational},
        unavailable_profiles => $counts{unavailable},
        complete_observation => $complete
            ? JSON::PP::true : JSON::PP::false,
    };
}

sub _aggregate_classification($summary) {
    my %present = (
        fail => $summary->{failed_profiles},
        unavailable => $summary->{unavailable_profiles},
        informational => $summary->{informational_profiles},
        pass => $summary->{passed_profiles},
    );
    for my $classification (@CLASSIFICATION_ORDER) {
        return $classification if $present{$classification};
    }
    confess "regression gate coordination has no profile classification\n";
}

sub _outcome($classification) {
    return 'performance_failed' if $classification eq 'fail';
    return 'unavailable' if $classification eq 'unavailable';
    return 'accepted_informational'
        if $classification eq 'informational';
    return 'accepted' if $classification eq 'pass';
    confess "regression gate coordination outcome is invalid\n";
}

sub _validate_result($result, $contract, $revision) {
    _exact_keys($result, \@RESULT_KEYS, 'regression gate result');
    confess "regression gate result schema is invalid\n"
        unless ($result->{schema} // '') eq $SCHEMA
            && _json_integer_equals($result->{schema_version}, 1);
    my $projection = _clone($result);
    my $identity = $projection->{gate_result_identity};
    $projection->{gate_result_identity} = undef;
    confess "regression gate result identity is invalid\n"
        unless ($identity // '') eq $IDENTITY_PREFIX
            . sha256_hex(_canonical_json($projection));
    confess "regression gate result evidence changed\n"
        unless ($result->{contract_identity} // '') eq
                ($contract->{contract_identity} // '')
            && ($result->{qualification_identity} // '') eq
                ($contract->{qualification_evidence}
                    {qualification_identity} // '')
            && ($result->{qualification_publication_identity} // '') eq
                ($contract->{qualification_evidence}
                    {publication_identity} // '')
            && ($result->{qualification_file_set_sha256} // '') eq
                ($contract->{qualification_evidence}
                    {qualification_file_set_sha256} // '')
            && ($result->{execution_revision} // '') eq $revision
            && ($result->{coordinator_revision} // '') eq $REVISION;
    confess "regression gate result diagnostics changed\n"
        unless ref($result->{diagnostics}) eq 'ARRAY'
            && !@{$result->{diagnostics}};
    confess "regression gate result nonclaims changed\n"
        unless _canonical_json($result->{explicit_nonclaims}) eq
            _canonical_json(\@NONCLAIMS);
    _exact_keys(
        $result->{cleanup}, \@CLEANUP_KEYS,
        'regression gate result cleanup',
    );
    confess "regression gate result cleanup changed\n"
        unless _json_integer_equals(
                $result->{cleanup}{profile_report_spools_removed},
                $PROFILE_COUNT,
            )
            && !_json_boolean(
                $result->{cleanup}{worker_process_residue},
                'regression gate result process residue',
            );
    confess "regression gate result profile inventory changed\n"
        unless ref($result->{profiles}) eq 'ARRAY'
            && @{$result->{profiles}} == $PROFILE_COUNT;
    my %seen_identity;
    my $common_environment;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $profile = $result->{profiles}[$index];
        confess "regression gate result profile order changed\n"
            unless ref($profile) eq 'HASH'
                && _json_integer_equals($profile->{ordinal}, $index + 1)
                && ($profile->{selection_key} // '') eq
                    ($contract->{profiles}[$index]{selection_key} // '');
        my $admitted = $PROFILE->_admit_for_coordinator({
            result => $profile,
            contract => $contract,
            execution_revision => $revision,
        });
        confess "regression gate result profile changed on readmission\n"
            unless _canonical_json($admitted) eq _canonical_json($profile);
        confess "regression gate result profile identity is duplicated\n"
            if $seen_identity{$profile->{profile_result_identity}}++;
        $common_environment = _join_common_environment(
            $common_environment, $profile,
        );
    }
    my $expected_summary = _summary($contract, $result->{profiles});
    _exact_keys(
        $result->{summary}, \@SUMMARY_KEYS,
        'regression gate result summary',
    );
    confess "regression gate result summary changed\n"
        unless _canonical_json($result->{summary}) eq
            _canonical_json($expected_summary);
    my $classification = _aggregate_classification($expected_summary);
    confess "regression gate result classification changed\n"
        unless ($result->{classification} // '') eq $classification
            && ($result->{outcome} // '') eq _outcome($classification);
    confess "regression gate result exceeds its byte bound\n"
        if bytes::length(_canonical_json($result)) >
            $contract->{result_contract}{maximum_result_bytes};
    return 1;
}

sub _repository_root($value) {
    confess "regression gate coordination repository root is invalid\n"
        unless defined($value) && !ref($value) && -d $value;
    my $root = Cwd::abs_path($value);
    confess "regression gate coordination repository root is invalid\n"
        unless defined($root)
            && (-d "$root/.git" || -f "$root/.git")
            && !-l "$root/.git";
    return $root;
}

sub _require_clean_revision($repo) {
    my ($revision, $revision_status) = _capture_command(
        'git', '-C', $repo, 'rev-parse', 'HEAD',
    );
    confess "regression gate coordination cannot read repository revision\n"
        unless $revision_status == 0;
    chomp $revision;
    confess "regression gate coordination repository revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my ($status, $status_code) = _capture_command(
        'git', '-C', $repo, 'status', '--porcelain=v1',
        '--untracked-files=all',
    );
    confess "regression gate coordination cannot inspect repository state\n"
        unless $status_code == 0;
    confess "regression gate coordination requires a clean repository\n"
        if length $status;
    return $revision;
}

sub _require_unchanged_clean_revision($repo, $expected) {
    my $current = _require_clean_revision($repo);
    confess "regression gate coordination repository revision changed\n"
        unless $current eq $expected;
    return 1;
}

sub _capture_command(@command) {
    open my $pipe, '-|', @command
        or confess "regression gate coordination cannot execute command\n";
    local $/;
    my $output = <$pipe> // '';
    close $pipe;
    return ($output, $? >> 8);
}

sub _require_active_guard() {
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "regression gate coordination requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    confess "regression gate coordination guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host > 0 && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss > 0 && $rss <= 4096;
    return 1;
}

sub _request($method, $args, $keys) {
    confess "regression gate coordination $method expects one hash argument\n"
        unless @$args == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys(
        $args->[0], $keys, "regression gate coordination $method request",
    );
    return $args->[0];
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { ($_ => 1) } @$keys;
    for my $key (keys %$value) {
        confess "$label contains unknown key '$key'\n"
            unless $expected{$key};
    }
    for my $key (@$keys) {
        confess "$label lacks key '$key'\n"
            unless exists $value->{$key};
    }
    return 1;
}

sub _exact_invocant($class, $method) {
    confess "regression gate coordination $method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _json_boolean($value, $label) {
    my $encoded = eval { _canonical_json($value) };
    confess "$label is not a JSON boolean\n"
        unless defined($encoded)
            && ($encoded eq 'true' || $encoded eq 'false');
    return $encoded eq 'true' ? 1 : 0;
}

sub _json_integer_equals($actual, $expected) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) eq "$expected";
}

sub _json_positive_integer($actual) {
    return 0 unless defined($actual) && !ref($actual)
        && _canonical_json($actual) =~ /\A[1-9][0-9]*\z/
        && $actual <= $MAX_SAFE_INTEGER;
    return 1;
}

sub _json_nonnegative_integer($actual, $label) {
    confess "$label is not a JSON nonnegative integer\n"
        unless defined($actual) && !ref($actual)
            && _canonical_json($actual) =~ /\A(?:0|[1-9][0-9]*)\z/
            && $actual <= $MAX_SAFE_INTEGER;
    return 0 + $actual;
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
