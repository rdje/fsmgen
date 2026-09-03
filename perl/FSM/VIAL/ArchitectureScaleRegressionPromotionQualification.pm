package FSM::VIAL::ArchitectureScaleRegressionPromotionQualification;

use v5.20;
use strict;
use warnings;

use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore;
use FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

my $CORPUS_STORE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore';
my $POLICY = 'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy';
my $PROFILE_STORE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $GATE_PROFILE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile';
my $SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_qualification.v1';
my $CORPUS_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1';
my $CORPUS_MANIFEST_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus_manifest.v1';
my $PROFILE_PUBLICATION_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_publication.v1';
my $CORRECTNESS_PROJECTION_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_correctness.v1';
my $PUBLICATION_ID = 'regression-promotion-corpus-v1';
my $POLICY_IDENTITY =
    'regression-promotion-policy/'
    . '19cf41056da86d95c266597e7db76eff3810ee29511a005e1051053009a65ece';
my $MAX_REPORT_BYTES = 1_048_576;
my $MAX_CORRECTNESS_PROJECTION_BYTES = 262_144;
my $PROFILE_COUNT = 11;
my $VALIDATION_RECORDS = 11;
my $RAW_MEASUREMENT_RECORDS = 33;
my $CONTROLLER_INVOCATIONS = 44;
my $MAX_SAFE_INTEGER = 9_007_199_254_740_991;
my $MILLISECOND_NS = 1_000_000;
my $TWO_SECONDS_NS = 2_000_000_000;
my $MIB_16 = 16_777_216;
my $MIB_256 = 268_435_456;

my @STAGES = qw(
    construct parse_validate bridge bind_plan emit compile_analyze elaborate
    run trace_validate result_produce publish cleanup
);
my @REPORT_KEYS = qw(
    schema schema_version qualification_identity source_evidence formula
    performance_applicability summary profiles outcome diagnostics
    explicit_nonclaims
);
my @SOURCE_KEYS = qw(
    corpus_identity publication_identity file_set_sha256 plan_identity
    policy_identity publication_id publication_schema capture_revision
    dirty_state
);
my @FORMULA_KEYS = qw(authority wall_time_ns cpu_time_ns peak_tree_rss_bytes);
my @FORMULA_METRIC_KEYS = qw(floor multiplier_numerator multiplier_denominator quantum);
my @SUMMARY_KEYS = qw(
    profile_count validation_records raw_measurement_records
    controller_invocations sample_exclusions qualified_profiles
);
my @PROFILE_KEYS = qw(
    ordinal selection_key profile_qualification_identity source_report_identity
    workload_identity evidence_revision environment_identity
    correctness_projection_identity correctness_projection
    performance_applicability_identity validation_identity
    raw_measurement_identities accepted_run_totals aggregate_statistics
    qualified_budget provider_status outcome
);
my @ENVIRONMENT_KEYS = qw(
    environment_identity host_profile tool_profile resource_guard provider_status
);
my @RUN_TOTAL_KEYS = qw(
    measurement_identity run_ordinal wall_time_ns cpu_time_ns
    peak_tree_rss_bytes
);
my @AGGREGATE_KEYS = qw(wall_time_ns cpu_time_ns peak_tree_rss_bytes);
my @STATISTIC_KEYS = qw(
    sample_count minimum median maximum median_absolute_deviation
);
my @BUDGET_KEYS = qw(
    status formula_authority wall_time_ns cpu_time_ns peak_tree_rss_bytes
);
my @MEASUREMENT_RECORD_KEYS = qw(
    schema schema_version measurement_identity workload_identity
    workload_specification git_revision dirty_state host_profile tool_profile
    run_class run_ordinal stage_measurements correctness_oracles resource_guard
    artifacts outcome diagnostic cleanup explicit_nonclaims
);
my @STAGE_KEYS = qw(
    stage classification status command_identity timeout wall_time_ns
    controller_cpu descendant_cpu rss raw_samples input_counts output_counts
    semantic_object_counts correctness_oracle_ids process worker_status
    not_run_reason unsupported_counters
);
my @CORRECTNESS_PROJECTION_KEYS = qw(
    schema schema_version report_contract record_projections
);
my @CORRECTNESS_RECORD_KEYS = qw(
    schema schema_version workload_identity workload_specification run_class
    run_ordinal stage_measurements correctness_oracles artifact_records
    published_identity outcome diagnostic cleanup explicit_nonclaims
);
my @CORRECTNESS_STAGE_KEYS = qw(
    stage classification status input_counts output_counts
    semantic_object_counts correctness_oracle_ids process worker_status
    not_run_reason unsupported_counters
);
my @CORRECTNESS_ORACLE_KEYS = qw(
    stage oracle_id ok evidence_identity
);
my @ORACLE_KEYS = qw(stage oracle_id ok evidence_identity evidence);
my @ARTIFACT_RECORD_KEYS = qw(
    stage kind relative_path bytes lines sha256
);
my @GATE_OBSERVATION_KEYS = qw(
    workload_identity validation_identity raw_measurement_identities
    accepted_run_totals observed_maximum correctness_projection_identity
);
my @GATE_MAXIMUM_KEYS = qw(
    wall_time_ns cpu_time_ns peak_tree_rss_bytes
);
my @NONCLAIMS = qw(
    qualification_publication
    promoted_performance_gate
    observed_performance_result
    support_promotion
    architecture_scale_capacity
    historical_artifact_reuse
    producer_execution
    provider_execution
    simulator_execution
    measurement_controller_execution
);
my $EXPECTED_SUMMARY = {
    profile_count => $PROFILE_COUNT,
    validation_records => $VALIDATION_RECORDS,
    raw_measurement_records => $RAW_MEASUREMENT_RECORDS,
    controller_invocations => $CONTROLLER_INVOCATIONS,
    sample_exclusions => 0,
};
my $FORMULA = {
    authority => 'decision-0056',
    wall_time_ns => {
        floor => $TWO_SECONDS_NS,
        multiplier_numerator => 3,
        multiplier_denominator => 2,
        quantum => $MILLISECOND_NS,
    },
    cpu_time_ns => {
        floor => $TWO_SECONDS_NS,
        multiplier_numerator => 3,
        multiplier_denominator => 2,
        quantum => $MILLISECOND_NS,
    },
    peak_tree_rss_bytes => {
        floor => $MIB_256,
        multiplier_numerator => 5,
        multiplier_denominator => 4,
        quantum => $MIB_16,
    },
};

# The stable regression gate must use the exact same deterministic projection
# and record accounting as the immutable qualification.  This private seam is
# available only to the one-profile gate authority; it does not expose a new
# public evidence-injection surface and it never reads or mutates qualification
# artifacts.
sub _gate_observation($class, @args) {
    confess __PACKAGE__
        . "->_gate_observation requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess "regression-promotion gate observation is caller-sealed\n"
        unless (scalar caller) eq $GATE_PROFILE;
    confess "regression-promotion gate observation expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys(
        $args[0], [qw(measurement_set common_identity)],
        'regression-promotion gate observation request',
    );
    my $measurement_set = $args[0]{measurement_set};
    my $common = $args[0]{common_identity};
    confess "regression-promotion gate measurement set is invalid\n"
        unless ref($measurement_set) eq 'HASH' && !blessed($measurement_set);
    confess "regression-promotion gate common identity is invalid\n"
        unless ref($common) eq 'HASH' && !blessed($common);
    my $workload_identity = $measurement_set->{workload_identity};
    confess "regression-promotion gate workload identity is invalid\n"
        unless defined($workload_identity) && !ref($workload_identity)
            && $workload_identity =~ /\Aworkload\/[0-9a-f]{64}\z/;
    confess "regression-promotion gate measurement set is not accepted\n"
        unless ($measurement_set->{outcome} // '') eq 'accepted'
            && ref($measurement_set->{diagnostics}) eq 'ARRAY'
            && !@{$measurement_set->{diagnostics}};
    confess "regression-promotion gate exclusions are invalid\n"
        unless ref($measurement_set->{sample_exclusions}) eq 'ARRAY'
            && !@{$measurement_set->{sample_exclusions}};
    confess "regression-promotion gate measurement records are invalid\n"
        unless ref($measurement_set->{measurement_records}) eq 'ARRAY'
            && @{$measurement_set->{measurement_records}} == 3;

    my $validation = $measurement_set->{validation_record};
    _validate_measurement_record({
        record => $validation,
        common => $common,
        workload_identity => $workload_identity,
        run_class => 'validation',
        run_ordinal => 0,
        measured => 0,
    });
    my (@totals, @identities);
    for my $index (0 .. 2) {
        my $record = $measurement_set->{measurement_records}[$index];
        confess "regression-promotion gate workload specification changed\n"
            unless _canonical_json($record->{workload_specification}) eq
                _canonical_json($validation->{workload_specification});
        my $total = _validate_measurement_record({
            record => $record,
            common => $common,
            workload_identity => $workload_identity,
            run_class => 'gate_measurement',
            run_ordinal => $index + 1,
            measured => 1,
        });
        push @identities, $record->{measurement_identity};
        push @totals, {
            measurement_identity => $record->{measurement_identity},
            run_ordinal => $index + 1,
            %$total,
        };
    }
    my $correctness = _correctness_projection(
        $measurement_set,
        [$validation, @{$measurement_set->{measurement_records}}],
    );
    my $correctness_bytes = _canonical_json($correctness);
    confess "regression-promotion gate correctness projection exceeds its bound\n"
        if bytes::length($correctness_bytes) >
            $MAX_CORRECTNESS_PROJECTION_BYTES;
    my %maximum = map {
        my $metric = $_;
        ($metric => _statistics([map { $_->{$metric} } @totals])->{maximum})
    } @GATE_MAXIMUM_KEYS;
    my $result = {
        workload_identity => $workload_identity,
        validation_identity => $validation->{measurement_identity},
        raw_measurement_identities => \@identities,
        accepted_run_totals => \@totals,
        observed_maximum => \%maximum,
        correctness_projection_identity =>
            'regression-promotion-correctness/'
            . sha256_hex($correctness_bytes),
    };
    _exact_keys(
        $result, \@GATE_OBSERVATION_KEYS,
        'regression-promotion gate observation',
    );
    _exact_keys(
        $result->{observed_maximum}, \@GATE_MAXIMUM_KEYS,
        'regression-promotion gate observed maximum',
    );
    return _clone($result);
}
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub profile_keys($class) {
    _exact_invocant($class, 'profile_keys');
    return [@PROFILE_KEYS];
}

sub formula($class) {
    _exact_invocant($class, 'formula');
    return _clone($FORMULA);
}

sub qualification_limits($class) {
    _exact_invocant($class, 'qualification_limits');
    return {
        maximum_report_bytes => $MAX_REPORT_BYTES,
        maximum_correctness_projection_bytes =>
            $MAX_CORRECTNESS_PROJECTION_BYTES,
        profile_count => $PROFILE_COUNT,
        validation_records => $VALIDATION_RECORDS,
        raw_measurement_records => $RAW_MEASUREMENT_RECORDS,
        controller_invocations => $CONTROLLER_INVOCATIONS,
    };
}

sub derive($class, @args) {
    _exact_invocant($class, 'derive');
    my $request = _request('derive', \@args, [qw(repository_root)]);
    _require_active_guard();
    my $repository_root = _repository_root($request->{repository_root});
    my $corpus = $CORPUS_STORE->load({
        repository_root => $repository_root,
    });
    my $profiles = $PROFILE_STORE->load_all({
        repository_root => $repository_root,
    });
    return _clone(_derive_from_evidence($corpus, $profiles));
}

sub _derive_from_evidence($corpus, $profile_bundle) {
    _exact_keys(
        $corpus, $CORPUS_STORE->load_result_keys,
        'regression-promotion qualification corpus load',
    );
    _exact_keys(
        $profile_bundle, $PROFILE_STORE->load_all_result_keys,
        'regression-promotion qualification profile bundle',
    );
    my $source_report = $corpus->{report};
    my $manifest = $corpus->{manifest};
    my $artifact = $corpus->{artifact};
    _validate_source_envelope($source_report, $manifest, $artifact);

    my $plan = $profile_bundle->{plan};
    my $profile_loads = $profile_bundle->{profiles};
    confess "regression-promotion qualification profile plan is invalid\n"
        unless ref($plan) eq 'HASH' && !blessed($plan)
            && ref($plan->{entries}) eq 'ARRAY'
            && @{$plan->{entries}} == $PROFILE_COUNT;
    confess "regression-promotion qualification profile loads are invalid\n"
        unless ref($profile_loads) eq 'ARRAY'
            && @$profile_loads == $PROFILE_COUNT;
    for my $key (qw(plan_identity policy_identity publication_id publication_schema)) {
        confess "regression-promotion qualification plan binding changed\n"
            unless _canonical_json($plan->{$key}) eq
                _canonical_json($source_report->{$key});
    }

    my $performance_applicability =
        $POLICY->performance_applicability_contract;
    my @profiles;
    my ($validation_records, $raw_records, $exclusions) = (0, 0, 0);
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $profile = _derive_profile({
            source_profile => $source_report->{profiles}[$index],
            profile_load => $profile_loads->[$index],
            plan_entry => $plan->{entries}[$index],
            source_envelope => $source_report,
            source_common => $source_report->{common_identity},
            performance_applicability => $performance_applicability,
        });
        push @profiles, $profile;
        $validation_records++;
        $raw_records += @{$profile->{raw_measurement_identities}};
    }
    $exclusions = $source_report->{summary}{sample_exclusions};
    my $derived_summary = {
        profile_count => scalar(@profiles),
        validation_records => $validation_records,
        raw_measurement_records => $raw_records,
        controller_invocations => $validation_records + $raw_records,
        sample_exclusions => $exclusions,
        qualified_profiles => scalar(@profiles),
    };
    for my $key (keys %$EXPECTED_SUMMARY) {
        confess "regression-promotion qualification source summary changed\n"
            unless _json_integer_equals(
                $derived_summary->{$key}, $EXPECTED_SUMMARY->{$key},
            ) && _json_integer_equals(
                $source_report->{summary}{$key}, $EXPECTED_SUMMARY->{$key},
            );
    }

    my $source_evidence = {
        corpus_identity => $source_report->{corpus_identity},
        publication_identity => $manifest->{publication_identity},
        file_set_sha256 => $artifact->{file_set_sha256},
        plan_identity => $source_report->{plan_identity},
        policy_identity => $source_report->{policy_identity},
        publication_id => $source_report->{publication_id},
        publication_schema => $source_report->{publication_schema},
        capture_revision => $source_report->{common_identity}{git_revision},
        dirty_state => _clone($source_report->{common_identity}{dirty_state}),
    };
    my $report = {
        schema => $SCHEMA,
        schema_version => 1,
        qualification_identity => undef,
        source_evidence => $source_evidence,
        formula => _clone($FORMULA),
        performance_applicability => $performance_applicability,
        summary => $derived_summary,
        profiles => \@profiles,
        outcome => 'accepted_qualified_unpublished',
        diagnostics => [],
        explicit_nonclaims => [@NONCLAIMS],
    };
    $report->{qualification_identity} =
        'regression-promotion-qualification/'
        . sha256_hex(_canonical_json($report));
    _validate_qualification_report($report);
    return $report;
}

sub _derive_profile($args) {
    for my $key (qw(
        source_profile profile_load plan_entry source_envelope source_common
        performance_applicability
    )) {
        confess "regression-promotion qualification profile input is incomplete\n"
            unless exists($args->{$key});
    }
    my $source = $args->{source_profile};
    my $load = $args->{profile_load};
    my $entry = $args->{plan_entry};
    _exact_keys(
        $source, $CORPUS_STORE->profile_keys,
        'regression-promotion qualification source profile',
    );
    _exact_keys(
        $load, $PROFILE_STORE->load_result_keys,
        'regression-promotion qualification profile load',
    );
    my $publication = $load->{publication};
    _exact_keys(
        $publication, [qw(
            schema schema_version publication_identity plan_identity
            policy_identity publication_id publication_schema profile report
        )],
        'regression-promotion qualification profile publication',
    );
    confess "regression-promotion qualification profile schema changed\n"
        unless ($publication->{schema} // '') eq $PROFILE_PUBLICATION_SCHEMA
            && _json_integer_equals($publication->{schema_version}, 1);
    confess "regression-promotion qualification profile order changed\n"
        unless _canonical_json($publication->{profile}) eq _canonical_json($entry)
            && _json_integer_equals($source->{ordinal}, $entry->{ordinal})
            && ($source->{selection_key} // '') eq ($entry->{selection_key} // '');
    my %profile_corpus_common = map { $_ => $source->{common_identity}{$_} }
        qw(git_revision dirty_state host_profile resource_guard);
    confess "regression-promotion qualification corpus common identity changed\n"
        unless _canonical_json(\%profile_corpus_common) eq
            _canonical_json($args->{source_common});
    for my $key (qw(plan_identity policy_identity publication_id publication_schema)) {
        confess "regression-promotion qualification profile binding changed\n"
            unless _canonical_json($publication->{$key}) eq
                _canonical_json($args->{source_envelope}{$key});
    }
    my $measurement_set = $publication->{report};
    confess "regression-promotion qualification measurement set is invalid\n"
        unless ref($measurement_set) eq 'HASH' && !blessed($measurement_set);
    confess "regression-promotion qualification report identity changed\n"
        unless ($measurement_set->{report_identity} // '') eq
            ($source->{report_identity} // '');
    _validate_profile_artifact_binding($source, $load->{artifact}, $entry);

    my $workload_identity = $measurement_set->{workload_identity};
    confess "regression-promotion qualification workload identity is invalid\n"
        unless defined($workload_identity) && !ref($workload_identity)
            && $workload_identity =~ /\Aworkload\/[0-9a-f]{64}\z/;
    confess "regression-promotion qualification applicability is invalid\n"
        unless _closed_applicable($measurement_set->{measurement_applicability});
    confess "regression-promotion qualification measurement set is not accepted\n"
        unless ($measurement_set->{outcome} // '') eq 'accepted'
            && ref($measurement_set->{diagnostics}) eq 'ARRAY'
            && !@{$measurement_set->{diagnostics}};
    confess "regression-promotion qualification exclusions are invalid\n"
        unless ref($measurement_set->{sample_exclusions}) eq 'ARRAY'
            && !@{$measurement_set->{sample_exclusions}};
    confess "regression-promotion qualification measurement records are invalid\n"
        unless ref($measurement_set->{measurement_records}) eq 'ARRAY'
            && @{$measurement_set->{measurement_records}} == 3;

    my $validation = $measurement_set->{validation_record};
    _validate_measurement_record({
        record => $validation,
        common => $source->{common_identity},
        workload_identity => $workload_identity,
        run_class => 'validation',
        run_ordinal => 0,
        measured => 0,
    });
    my @run_totals;
    my @measurement_identities;
    for my $index (0 .. 2) {
        my $record = $measurement_set->{measurement_records}[$index];
        confess "regression-promotion qualification workload specification changed\n"
            unless _canonical_json($record->{workload_specification}) eq
                _canonical_json($validation->{workload_specification});
        my $total = _validate_measurement_record({
            record => $record,
            common => $source->{common_identity},
            workload_identity => $workload_identity,
            run_class => 'gate_measurement',
            run_ordinal => $index + 1,
            measured => 1,
        });
        push @measurement_identities, $record->{measurement_identity};
        push @run_totals, {
            measurement_identity => $record->{measurement_identity},
            run_ordinal => $index + 1,
            %$total,
        };
    }
    my $aggregate = {
        wall_time_ns => _statistics([map { $_->{wall_time_ns} } @run_totals]),
        cpu_time_ns => _statistics([map { $_->{cpu_time_ns} } @run_totals]),
        peak_tree_rss_bytes => _statistics([
            map { $_->{peak_tree_rss_bytes} } @run_totals
        ]),
    };
    my $budget = _budget($aggregate);
    my $correctness_projection = _correctness_projection(
        $measurement_set,
        [$validation, @{$measurement_set->{measurement_records}}],
    );
    my $correctness_bytes = _canonical_json($correctness_projection);
    confess "regression-promotion correctness projection exceeds its bound\n"
        if bytes::length($correctness_bytes) >
            $MAX_CORRECTNESS_PROJECTION_BYTES;
    my $correctness_identity =
        'regression-promotion-correctness/' . sha256_hex($correctness_bytes);

    my $environment = {
        environment_identity => undef,
        host_profile => _clone($source->{common_identity}{host_profile}),
        tool_profile => _clone($source->{common_identity}{tool_profile}),
        resource_guard => _clone($source->{common_identity}{resource_guard}),
        provider_status => _clone($source->{provider_status}),
    };
    $environment->{environment_identity} =
        'regression-promotion-environment/'
        . sha256_hex(_canonical_json($environment));
    my $applicability_projection = {
        contract_identity =>
            $args->{performance_applicability}{applicability_identity},
        exact_environment => $environment,
        exact_deterministic => {
            selection_key => $source->{selection_key},
            workload_identity => $workload_identity,
            correctness_projection_identity => $correctness_identity,
        },
    };
    my $profile = {
        ordinal => $source->{ordinal},
        selection_key => $source->{selection_key},
        profile_qualification_identity => undef,
        source_report_identity => $source->{report_identity},
        workload_identity => $workload_identity,
        evidence_revision => $source->{common_identity}{git_revision},
        environment_identity => $environment,
        correctness_projection_identity => $correctness_identity,
        correctness_projection => $correctness_projection,
        performance_applicability_identity =>
            'regression-promotion-profile-applicability/'
            . sha256_hex(_canonical_json($applicability_projection)),
        validation_identity => $validation->{measurement_identity},
        raw_measurement_identities => \@measurement_identities,
        accepted_run_totals => \@run_totals,
        aggregate_statistics => $aggregate,
        qualified_budget => $budget,
        provider_status => _clone($source->{provider_status}),
        outcome => 'accepted_qualified_unpublished',
    };
    $profile->{profile_qualification_identity} =
        'regression-promotion-profile-qualification/'
        . sha256_hex(_canonical_json($profile));
    _validate_qualified_profile($profile);
    return $profile;
}

sub _validate_source_envelope($report, $manifest, $artifact) {
    _exact_keys(
        $report, $CORPUS_STORE->report_keys,
        'regression-promotion qualification source report',
    );
    _exact_keys(
        $manifest, $CORPUS_STORE->manifest_keys,
        'regression-promotion qualification source manifest',
    );
    _exact_keys(
        $artifact, $CORPUS_STORE->artifact_keys,
        'regression-promotion qualification source artifact',
    );
    confess "regression-promotion qualification source schema changed\n"
        unless ($report->{schema} // '') eq $CORPUS_SCHEMA
            && _json_integer_equals($report->{schema_version}, 1)
            && ($manifest->{schema} // '') eq $CORPUS_MANIFEST_SCHEMA
            && _json_integer_equals($manifest->{schema_version}, 1);
    confess "regression-promotion qualification source is not current\n"
        unless ($report->{publication_id} // '') eq $PUBLICATION_ID
            && ($report->{policy_identity} // '') eq $POLICY_IDENTITY
            && ($manifest->{outcome} // '') eq 'accepted'
            && ($artifact->{status} // '') eq 'loaded';
    for my $key (qw(
        corpus_identity plan_identity policy_identity publication_id summary
    )) {
        confess "regression-promotion qualification source binding changed\n"
            unless _canonical_json($report->{$key}) eq
                _canonical_json($manifest->{$key});
    }
    confess "regression-promotion qualification source profile count changed\n"
        unless ref($report->{profiles}) eq 'ARRAY'
            && @{$report->{profiles}} == $PROFILE_COUNT;
    confess "regression-promotion qualification source common identity is invalid\n"
        unless ref($report->{common_identity}) eq 'HASH'
            && !blessed($report->{common_identity})
            && ($report->{common_identity}{git_revision} // '')
                =~ /\A[0-9a-f]{40}\z/
            && _json_false($report->{common_identity}{dirty_state});
    confess "regression-promotion qualification file-set identity is invalid\n"
        unless ($artifact->{file_set_sha256} // '') =~ /\A[0-9a-f]{64}\z/
            && ($manifest->{publication_identity} // '')
                =~ /\Aregression-promotion-corpus-publication\/[0-9a-f]{64}\z/;
}

sub _validate_profile_artifact_binding($source, $artifact, $entry) {
    _exact_keys(
        $artifact, $PROFILE_STORE->artifact_keys,
        'regression-promotion qualification profile artifact',
    );
    my $source_artifact = $source->{artifact};
    confess "regression-promotion qualification source artifact is invalid\n"
        unless ref($source_artifact) eq 'HASH' && !blessed($source_artifact);
    confess "regression-promotion qualification profile artifact changed\n"
        unless _json_integer_equals($artifact->{ordinal}, $entry->{ordinal})
            && ($artifact->{selection_key} // '') eq ($entry->{selection_key} // '')
            && ($artifact->{artifact_relative_path} // '') eq
                ($source_artifact->{relative_path} // '')
            && ($artifact->{artifact_sha256} // '') eq
                ($source_artifact->{sha256} // '')
            && _json_integer_equals(
                $artifact->{artifact_bytes}, $source_artifact->{bytes},
            )
            && _json_true($artifact->{same_volume})
            && _json_true($artifact->{atomic});
}

sub _validate_measurement_record($args) {
    my $record = $args->{record};
    _exact_keys(
        $record, \@MEASUREMENT_RECORD_KEYS,
        'regression-promotion qualification measurement record',
    );
    confess "regression-promotion qualification measurement identity is invalid\n"
        unless ($record->{measurement_identity} // '')
            =~ /\Ameasurement\/[0-9a-f]{64}\z/;
    confess "regression-promotion qualification record coordinate changed\n"
        unless ($record->{workload_identity} // '') eq $args->{workload_identity}
            && ($record->{run_class} // '') eq $args->{run_class}
            && _json_integer_equals($record->{run_ordinal}, $args->{run_ordinal});
    my %actual_common = map { $_ => $record->{$_} }
        qw(git_revision dirty_state host_profile tool_profile resource_guard);
    confess "regression-promotion qualification record identity changed\n"
        unless _canonical_json(\%actual_common) eq _canonical_json($args->{common})
            && _json_false($record->{dirty_state});
    confess "regression-promotion qualification record is not accepted\n"
        unless ($record->{outcome} // '') eq 'accepted'
            && !defined($record->{diagnostic});
    confess "regression-promotion qualification workload specification is invalid\n"
        unless ref($record->{workload_specification}) eq 'HASH'
            && !blessed($record->{workload_specification});
    confess "regression-promotion qualification stage vector changed\n"
        unless ref($record->{stage_measurements}) eq 'ARRAY'
            && @{$record->{stage_measurements}} == @STAGES;
    my ($wall, $cpu, $rss, $measured) = (0, 0, undef, 0);
    for my $index (0 .. $#STAGES) {
        my $stage = $record->{stage_measurements}[$index];
        _exact_keys(
            $stage, \@STAGE_KEYS,
            'regression-promotion qualification stage measurement',
        );
        confess "regression-promotion qualification stage order changed\n"
            unless ($stage->{stage} // '') eq $STAGES[$index];
        _validate_stage_determinism($stage);
        my $status = $stage->{status} // '';
        if ($args->{measured} && $status eq 'measured') {
            my $stage_wall = _json_nonnegative_integer(
                $stage->{wall_time_ns}, 'stage wall time',
            );
            my $stage_cpu = _stage_cpu($stage);
            my $stage_rss = $stage->{rss}{peak_process_tree_bytes};
            confess "regression-promotion measured stage RSS is invalid\n"
                unless defined($stage_rss)
                    ? _json_nonnegative_integer($stage_rss, 'stage RSS') >= 0
                    : $stage->{stage} eq 'cleanup'
                        && ($stage->{rss}{unsupported_reason} // '') eq
                            'cleanup_is_controller_local';
            confess "regression-promotion measured stage process failed\n"
                unless _json_integer_equals($stage->{process}{exit_code}, 0)
                    && _json_integer_equals($stage->{process}{signal}, 0)
                    && _json_false($stage->{process}{timed_out});
            $wall = _checked_add($wall, $stage_wall, 'run wall time');
            $cpu = _checked_add($cpu, $stage_cpu, 'run CPU time');
            $rss = $stage_rss
                if defined($stage_rss)
                    && (!defined($rss) || $stage_rss > $rss);
            $measured++;
        }
        elsif ($args->{measured}) {
            confess "regression-promotion measurement stage status changed\n"
                unless $status eq 'not_run';
        }
        else {
            confess "regression-promotion validation stage status changed\n"
                unless $status eq 'validated_unmeasured'
                    || $status eq 'not_run';
        }
    }
    _validate_record_correctness($record);
    _validate_record_artifacts($record);
    if ($args->{measured}) {
        confess "regression-promotion measurement record has no measured stage\n"
            unless $measured && defined($rss);
        return {
            wall_time_ns => $wall,
            cpu_time_ns => $cpu,
            peak_tree_rss_bytes => $rss,
        };
    }
    return undef;
}

sub _validate_stage_determinism($stage) {
    for my $name (qw(input_counts output_counts)) {
        _exact_keys(
            $stage->{$name}, [qw(bytes files lines objects)],
            "regression-promotion $name",
        );
        for my $key (qw(bytes files lines objects)) {
            _json_nonnegative_integer(
                $stage->{$name}{$key}, "stage $name $key",
            );
        }
    }
    confess "regression-promotion semantic object counts are invalid\n"
        unless ref($stage->{semantic_object_counts}) eq 'HASH'
            && !blessed($stage->{semantic_object_counts});
    for my $key (keys %{$stage->{semantic_object_counts}}) {
        confess "regression-promotion semantic object count name is invalid\n"
            unless $key =~ /\A[A-Za-z0-9_]+\z/;
        _json_nonnegative_integer(
            $stage->{semantic_object_counts}{$key},
            "semantic object count '$key'",
        );
    }
    confess "regression-promotion stage oracle identifiers are invalid\n"
        unless ref($stage->{correctness_oracle_ids}) eq 'ARRAY';
    my %seen;
    for my $id (@{$stage->{correctness_oracle_ids}}) {
        confess "regression-promotion stage oracle identifier is invalid\n"
            unless defined($id) && !ref($id)
                && $id =~ /\A[A-Za-z0-9_.-]+\z/
                && !$seen{$id}++;
    }
}

sub _validate_record_correctness($record) {
    confess "regression-promotion qualification correctness oracles are invalid\n"
        unless ref($record->{correctness_oracles}) eq 'ARRAY'
            && @{$record->{correctness_oracles}};
    my %oracle_seen;
    for my $oracle (@{$record->{correctness_oracles}}) {
        _exact_keys(
            $oracle, \@ORACLE_KEYS,
            'regression-promotion qualification correctness oracle',
        );
        confess "regression-promotion qualification correctness oracle failed\n"
            unless ref($oracle) eq 'HASH' && !blessed($oracle)
                && ($oracle->{oracle_id} // '') =~ /\A[A-Za-z0-9_.-]+\z/
                && ($oracle->{stage} // '') =~ /\A[A-Za-z0-9_.-]+\z/
                && _json_true($oracle->{ok})
                && ref($oracle->{evidence})
                && !$oracle_seen{$oracle->{oracle_id}}++
                && ($oracle->{evidence_identity} // '') eq
                    sha256_hex(_canonical_json($oracle->{evidence}));
    }
    my %stage_oracles;
    for my $stage (@{$record->{stage_measurements}}) {
        for my $id (@{$stage->{correctness_oracle_ids}}) {
            confess "regression-promotion qualification stage oracle is duplicated\n"
                if exists($stage_oracles{$id});
            $stage_oracles{$id} = $stage->{stage};
        }
    }
    my %record_oracles = map {
        $_->{oracle_id} => $_->{stage}
    } @{$record->{correctness_oracles}};
    confess "regression-promotion qualification stage/oracle membership changed\n"
        unless _canonical_json(\%stage_oracles) eq
            _canonical_json(\%record_oracles);
    confess "regression-promotion qualification record cleanup failed\n"
        unless ref($record->{cleanup}) eq 'HASH'
            && _json_true($record->{cleanup}{ephemeral_removed})
            && ref($record->{cleanup}{residue}) eq 'ARRAY'
            && !@{$record->{cleanup}{residue}};
}

sub _validate_record_artifacts($record) {
    _exact_keys(
        $record->{artifacts}, [qw(published_identity records staging_identity)],
        'regression-promotion qualification record artifacts',
    );
    confess "regression-promotion qualification artifact records are invalid\n"
        unless ref($record->{artifacts}{records}) eq 'ARRAY';
    for my $artifact (@{$record->{artifacts}{records}}) {
        _exact_keys(
            $artifact, \@ARTIFACT_RECORD_KEYS,
            'regression-promotion qualification artifact record',
        );
        for my $key (qw(bytes lines)) {
            _json_nonnegative_integer(
                $artifact->{$key}, "artifact $key",
            );
        }
        confess "regression-promotion qualification artifact identity is invalid\n"
            unless ($artifact->{stage} // '') =~ /\A[A-Za-z0-9_.-]+\z/
                && ($artifact->{kind} // '') =~ /\A[A-Za-z0-9_.-]+\z/
                && ($artifact->{relative_path} // '') =~ m{\Aoutputs/}
                && $artifact->{relative_path} !~ m{(?:\A|/)\.\.(?:/|\z)}
                && ($artifact->{sha256} // '') =~ /\A[0-9a-f]{64}\z/;
    }
}

sub _correctness_projection($measurement_set, $records) {
    my $report_contract = _clone($measurement_set);
    delete @{$report_contract}{qw(
        report_identity validation_record measurement_records
        sample_exclusions cleanup
    )};
    my @record_projections = map {
        _record_correctness_projection($_)
    } @$records;
    return {
        schema => $CORRECTNESS_PROJECTION_SCHEMA,
        schema_version => 1,
        report_contract => $report_contract,
        record_projections => \@record_projections,
    };
}

sub _record_correctness_projection($record) {
    my @stages = map {
        my $stage = $_;
        +{map { $_ => _clone($stage->{$_}) } @CORRECTNESS_STAGE_KEYS}
    } @{$record->{stage_measurements}};
    my @oracles = map {
        my $oracle = $_;
        +{map { $_ => _clone($oracle->{$_}) } @CORRECTNESS_ORACLE_KEYS}
    } @{$record->{correctness_oracles}};
    return {
        schema => $record->{schema},
        schema_version => $record->{schema_version},
        workload_identity => $record->{workload_identity},
        workload_specification => _clone($record->{workload_specification}),
        run_class => $record->{run_class},
        run_ordinal => $record->{run_ordinal},
        stage_measurements => \@stages,
        correctness_oracles => \@oracles,
        artifact_records => _clone($record->{artifacts}{records}),
        published_identity => _clone($record->{artifacts}{published_identity}),
        outcome => $record->{outcome},
        diagnostic => _clone($record->{diagnostic}),
        cleanup => {
            ephemeral_removed => _clone($record->{cleanup}{ephemeral_removed}),
            residue => _clone($record->{cleanup}{residue}),
        },
        explicit_nonclaims => _clone($record->{explicit_nonclaims}),
    };
}

sub _stage_cpu($stage) {
    my $total = 0;
    for my $kind (qw(controller_cpu descendant_cpu)) {
        confess "regression-promotion measured stage CPU counters are invalid\n"
            unless ref($stage->{$kind}) eq 'HASH';
        for my $field (qw(user_ns system_ns)) {
            my $value = $stage->{$kind}{$field};
            if (defined($value)) {
                $total = _checked_add(
                    $total,
                    _json_nonnegative_integer($value, 'stage CPU counter'),
                    'stage CPU time',
                );
                next;
            }
            confess "regression-promotion measured stage CPU counter is unsupported\n"
                unless $kind eq 'descendant_cpu'
                    && $stage->{stage} eq 'cleanup'
                    && ($stage->{$kind}{unsupported_reason} // '') eq
                        'no_descendant_cleanup_process';
        }
    }
    return $total;
}

sub _statistics($values) {
    confess "regression-promotion statistics require three samples\n"
        unless ref($values) eq 'ARRAY' && @$values == 3;
    my @sorted = sort { $a <=> $b } map {
        _json_nonnegative_integer($_, 'statistic sample')
    } @$values;
    my $median = $sorted[1];
    my @deviations = sort { $a <=> $b } map {
        $_ >= $median ? $_ - $median : $median - $_
    } @sorted;
    return {
        sample_count => 3,
        minimum => $sorted[0],
        median => $median,
        maximum => $sorted[2],
        median_absolute_deviation => $deviations[1],
    };
}

sub _budget($aggregate) {
    return {
        status => 'qualified_unpublished',
        formula_authority => 'decision-0056',
        wall_time_ns => _rounded_budget(
            $aggregate->{wall_time_ns}{maximum}, $FORMULA->{wall_time_ns},
        ),
        cpu_time_ns => _rounded_budget(
            $aggregate->{cpu_time_ns}{maximum}, $FORMULA->{cpu_time_ns},
        ),
        peak_tree_rss_bytes => _rounded_budget(
            $aggregate->{peak_tree_rss_bytes}{maximum},
            $FORMULA->{peak_tree_rss_bytes},
        ),
    };
}

sub _rounded_budget($maximum, $formula) {
    my $product = _checked_multiply(
        $maximum, $formula->{multiplier_numerator}, 'budget multiplier',
    );
    my $scaled = _ceil_divide(
        $product, $formula->{multiplier_denominator}, 'budget multiplier',
    );
    $scaled = $formula->{floor} if $scaled < $formula->{floor};
    my $quanta = _ceil_divide($scaled, $formula->{quantum}, 'budget quantum');
    return _checked_multiply(
        $quanta, $formula->{quantum}, 'rounded budget',
    );
}

sub _validate_qualified_profile($profile) {
    _exact_keys(
        $profile, \@PROFILE_KEYS,
        'regression-promotion qualified profile',
    );
    confess "regression-promotion profile qualification identity changed\n"
        unless _content_identity_matches(
            $profile, 'profile_qualification_identity',
            'regression-promotion-profile-qualification/',
        );
    _exact_keys(
        $profile->{environment_identity}, \@ENVIRONMENT_KEYS,
        'regression-promotion qualification environment',
    );
    confess "regression-promotion environment identity changed\n"
        unless _content_identity_matches(
            $profile->{environment_identity}, 'environment_identity',
            'regression-promotion-environment/',
        );
    _validate_correctness_projection($profile->{correctness_projection});
    confess "regression-promotion correctness identity changed\n"
        unless $profile->{correctness_projection_identity} eq
            'regression-promotion-correctness/'
            . sha256_hex(_canonical_json($profile->{correctness_projection}));
    confess "regression-promotion qualified profile provenance is invalid\n"
        unless ($profile->{source_report_identity} // '') ne ''
            && ($profile->{workload_identity} // '')
                =~ /\Aworkload\/[0-9a-f]{64}\z/
            && ($profile->{evidence_revision} // '') =~ /\A[0-9a-f]{40}\z/
            && _canonical_json($profile->{provider_status}) eq
                _canonical_json(
                    $profile->{environment_identity}{provider_status},
                );
    my $contract = $POLICY->performance_applicability_contract;
    my $applicability_projection = {
        contract_identity => $contract->{applicability_identity},
        exact_environment => $profile->{environment_identity},
        exact_deterministic => {
            selection_key => $profile->{selection_key},
            workload_identity => $profile->{workload_identity},
            correctness_projection_identity =>
                $profile->{correctness_projection_identity},
        },
    };
    confess "regression-promotion profile applicability identity changed\n"
        unless ($profile->{performance_applicability_identity} // '') eq
            'regression-promotion-profile-applicability/'
            . sha256_hex(_canonical_json($applicability_projection));
    confess "regression-promotion accepted run totals changed\n"
        unless ref($profile->{accepted_run_totals}) eq 'ARRAY'
            && @{$profile->{accepted_run_totals}} == 3;
    for my $total (@{$profile->{accepted_run_totals}}) {
        _exact_keys(
            $total, \@RUN_TOTAL_KEYS,
            'regression-promotion accepted run total',
        );
        for my $metric (@AGGREGATE_KEYS) {
            _json_nonnegative_integer($total->{$metric}, 'accepted run metric');
        }
    }
    _exact_keys(
        $profile->{aggregate_statistics}, \@AGGREGATE_KEYS,
        'regression-promotion aggregate statistics',
    );
    for my $metric (@AGGREGATE_KEYS) {
        _exact_keys(
            $profile->{aggregate_statistics}{$metric}, \@STATISTIC_KEYS,
            'regression-promotion statistic',
        );
        for my $key (@STATISTIC_KEYS) {
            _json_nonnegative_integer(
                $profile->{aggregate_statistics}{$metric}{$key},
                'aggregate statistic',
            );
        }
    }
    my %expected_aggregate;
    for my $metric (@AGGREGATE_KEYS) {
        $expected_aggregate{$metric} = _statistics([
            map { $_->{$metric} } @{$profile->{accepted_run_totals}}
        ]);
    }
    confess "regression-promotion aggregate statistics changed\n"
        unless _canonical_json($profile->{aggregate_statistics}) eq
            _canonical_json(\%expected_aggregate);
    _exact_keys(
        $profile->{qualified_budget}, \@BUDGET_KEYS,
        'regression-promotion qualified budget',
    );
    confess "regression-promotion qualified budget status changed\n"
        unless ($profile->{qualified_budget}{status} // '') eq
                'qualified_unpublished'
            && ($profile->{qualified_budget}{formula_authority} // '') eq
                'decision-0056';
    confess "regression-promotion qualified budget arithmetic changed\n"
        unless _canonical_json($profile->{qualified_budget}) eq
            _canonical_json(_budget($profile->{aggregate_statistics}));
    confess "regression-promotion qualified profile outcome changed\n"
        unless ($profile->{outcome} // '') eq 'accepted_qualified_unpublished';
}

sub _validate_correctness_projection($projection) {
    _exact_keys(
        $projection, \@CORRECTNESS_PROJECTION_KEYS,
        'regression-promotion correctness projection',
    );
    confess "regression-promotion correctness projection schema changed\n"
        unless ($projection->{schema} // '') eq
                $CORRECTNESS_PROJECTION_SCHEMA
            && _json_integer_equals($projection->{schema_version}, 1)
            && ref($projection->{report_contract}) eq 'HASH'
            && !blessed($projection->{report_contract})
            && ref($projection->{record_projections}) eq 'ARRAY'
            && @{$projection->{record_projections}} == 4;
    for my $index (0 .. 3) {
        my $record = $projection->{record_projections}[$index];
        _exact_keys(
            $record, \@CORRECTNESS_RECORD_KEYS,
            'regression-promotion correctness record projection',
        );
        confess "regression-promotion correctness record coordinate changed\n"
            unless ($record->{workload_identity} // '')
                    =~ /\Aworkload\/[0-9a-f]{64}\z/
                && ($record->{run_class} // '') eq
                    ($index ? 'gate_measurement' : 'validation')
                && _json_integer_equals($record->{run_ordinal}, $index)
                && ref($record->{stage_measurements}) eq 'ARRAY'
                && @{$record->{stage_measurements}} == @STAGES
                && ref($record->{correctness_oracles}) eq 'ARRAY'
                && @{$record->{correctness_oracles}}
                && ref($record->{artifact_records}) eq 'ARRAY';
        for my $stage_index (0 .. $#STAGES) {
            my $stage = $record->{stage_measurements}[$stage_index];
            _exact_keys(
                $stage, \@CORRECTNESS_STAGE_KEYS,
                'regression-promotion correctness stage projection',
            );
            confess "regression-promotion correctness stage order changed\n"
                unless ($stage->{stage} // '') eq $STAGES[$stage_index];
        }
        for my $oracle (@{$record->{correctness_oracles}}) {
            _exact_keys(
                $oracle, \@CORRECTNESS_ORACLE_KEYS,
                'regression-promotion correctness oracle projection',
            );
            confess "regression-promotion correctness oracle projection changed\n"
                unless _json_true($oracle->{ok})
                    && ($oracle->{evidence_identity} // '')
                        =~ /\A[0-9a-f]{64}\z/;
        }
        for my $artifact (@{$record->{artifact_records}}) {
            _exact_keys(
                $artifact, \@ARTIFACT_RECORD_KEYS,
                'regression-promotion correctness artifact projection',
            );
        }
        _exact_keys(
            $record->{cleanup}, [qw(ephemeral_removed residue)],
            'regression-promotion correctness cleanup projection',
        );
        confess "regression-promotion correctness cleanup projection changed\n"
            unless _json_true($record->{cleanup}{ephemeral_removed})
                && ref($record->{cleanup}{residue}) eq 'ARRAY'
                && !@{$record->{cleanup}{residue}};
    }
}

sub _validate_qualification_report($report) {
    _exact_keys(
        $report, \@REPORT_KEYS,
        'regression-promotion qualification report',
    );
    confess "regression-promotion qualification schema changed\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && _json_integer_equals($report->{schema_version}, 1);
    confess "regression-promotion qualification identity changed\n"
        unless _content_identity_matches(
            $report, 'qualification_identity',
            'regression-promotion-qualification/',
        );
    _exact_keys(
        $report->{source_evidence}, \@SOURCE_KEYS,
        'regression-promotion qualification source evidence',
    );
    confess "regression-promotion qualification source evidence changed\n"
        unless ($report->{source_evidence}{corpus_identity} // '')
                =~ /\Aregression-promotion-corpus\/[0-9a-f]{64}\z/
            && ($report->{source_evidence}{publication_identity} // '')
                =~ /\Aregression-promotion-corpus-publication\/[0-9a-f]{64}\z/
            && ($report->{source_evidence}{file_set_sha256} // '')
                =~ /\A[0-9a-f]{64}\z/
            && ($report->{source_evidence}{plan_identity} // '')
                =~ /\Aregression-promotion-capture-plan\/[0-9a-f]{64}\z/
            && ($report->{source_evidence}{policy_identity} // '') eq
                $POLICY_IDENTITY
            && ($report->{source_evidence}{publication_id} // '') eq
                $PUBLICATION_ID
            && ($report->{source_evidence}{publication_schema} // '') eq
                $CORPUS_SCHEMA
            && ($report->{source_evidence}{capture_revision} // '')
                =~ /\A[0-9a-f]{40}\z/
            && _json_false($report->{source_evidence}{dirty_state});
    _exact_keys(
        $report->{formula}, \@FORMULA_KEYS,
        'regression-promotion qualification formula',
    );
    confess "regression-promotion qualification formula changed\n"
        unless _canonical_json($report->{formula}) eq _canonical_json($FORMULA);
    for my $metric (@AGGREGATE_KEYS) {
        _exact_keys(
            $report->{formula}{$metric}, \@FORMULA_METRIC_KEYS,
            'regression-promotion qualification formula metric',
        );
    }
    _exact_keys(
        $report->{summary}, \@SUMMARY_KEYS,
        'regression-promotion qualification summary',
    );
    my $expected_summary = {
        %$EXPECTED_SUMMARY,
        qualified_profiles => $PROFILE_COUNT,
    };
    confess "regression-promotion qualification summary changed\n"
        unless _canonical_json($report->{summary}) eq
            _canonical_json($expected_summary);
    confess "regression-promotion performance applicability changed\n"
        unless _canonical_json($report->{performance_applicability}) eq
            _canonical_json($POLICY->performance_applicability_contract);
    confess "regression-promotion qualification profiles changed\n"
        unless ref($report->{profiles}) eq 'ARRAY'
            && @{$report->{profiles}} == $PROFILE_COUNT;
    my (%selection_seen, %identity_seen, %measurement_seen);
    for my $index (0 .. $PROFILE_COUNT - 1) {
        _validate_qualified_profile($report->{profiles}[$index]);
        confess "regression-promotion qualification ordinal changed\n"
            unless _json_integer_equals(
                $report->{profiles}[$index]{ordinal}, $index + 1,
            );
        confess "regression-promotion qualification profile is duplicated\n"
            if $selection_seen{$report->{profiles}[$index]{selection_key}}++
                || $identity_seen{
                    $report->{profiles}[$index]{profile_qualification_identity}
                }++;
        confess "regression-promotion qualification evidence revision changed\n"
            unless $report->{profiles}[$index]{evidence_revision} eq
                $report->{source_evidence}{capture_revision};
        for my $identity (
            $report->{profiles}[$index]{validation_identity},
            @{$report->{profiles}[$index]{raw_measurement_identities}},
        ) {
            confess "regression-promotion qualification measurement identity is duplicated\n"
                if $measurement_seen{$identity}++;
        }
    }
    confess "regression-promotion qualification outcome changed\n"
        unless ($report->{outcome} // '') eq 'accepted_qualified_unpublished'
            && ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}}
            && _canonical_json($report->{explicit_nonclaims}) eq
                _canonical_json(\@NONCLAIMS);
    confess "regression-promotion qualification report exceeds its bound\n"
        if bytes::length(_canonical_json($report)) > $MAX_REPORT_BYTES;
    return 1;
}

sub _closed_applicable($value) {
    return 0 unless ref($value) eq 'HASH' && !blessed($value);
    _exact_keys(
        $value, [qw(applicable reason)],
        'regression-promotion measurement applicability',
    );
    return _json_true($value->{applicable}) && !defined($value->{reason});
}

sub _content_identity_matches($value, $key, $prefix) {
    my $copy = _clone($value);
    my $identity = $copy->{$key};
    $copy->{$key} = undef;
    return defined($identity) && !ref($identity)
        && $identity eq $prefix . sha256_hex(_canonical_json($copy));
}

sub _checked_add($left, $right, $label) {
    confess "regression-promotion $label exceeds the safe integer range\n"
        if $left > $MAX_SAFE_INTEGER - $right;
    return $left + $right;
}

sub _checked_multiply($left, $right, $label) {
    confess "regression-promotion $label exceeds the safe integer range\n"
        if $left && $right > int($MAX_SAFE_INTEGER / $left);
    return $left * $right;
}

sub _ceil_divide($numerator, $denominator, $label) {
    confess "regression-promotion $label divisor is invalid\n"
        unless $denominator > 0;
    my $quotient = int($numerator / $denominator);
    return $quotient + ($numerator % $denominator ? 1 : 0);
}

sub _json_nonnegative_integer($value, $label) {
    my $canonical = defined($value) && !ref($value)
        ? _canonical_json($value) : '';
    confess "regression-promotion $label is not a safe JSON integer\n"
        unless $canonical =~ /\A(?:0|[1-9][0-9]*)\z/
            && (length($canonical) < length("$MAX_SAFE_INTEGER")
                || (length($canonical) == length("$MAX_SAFE_INTEGER")
                    && $canonical le "$MAX_SAFE_INTEGER"));
    return 0 + $canonical;
}

sub _json_integer_equals($value, $expected) {
    return defined($value) && !ref($value)
        && _canonical_json($value) eq "$expected";
}

sub _json_true($value) {
    return JSON::PP::is_bool($value) && $value;
}

sub _json_false($value) {
    return JSON::PP::is_bool($value) && !$value;
}

sub _repository_root($value) {
    confess "regression-promotion qualification repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "regression-promotion qualification repository root is unavailable\n"
        unless defined($root) && -d $root
            && -d File::Spec->catdir($root, '.git');
    return $root;
}

sub _require_active_guard() {
    confess "regression-promotion qualification requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "regression-promotion qualification guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss <= 4096;
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @$args == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    my %allowed = map { $_ => 1 } @$keys;
    for my $key (keys %{$args->[0]}) {
        confess "$method received unknown key '$key'\n"
            unless $allowed{$key};
    }
    for my $key (@$keys) {
        confess "$method is missing '$key'\n"
            unless exists($args->[0]{$key});
    }
    return $args->[0];
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be one closed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my @actual = sort keys %$value;
    my @expected = sort @$keys;
    confess "$label keys changed\n"
        unless _canonical_json(\@actual) eq _canonical_json(\@expected);
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
