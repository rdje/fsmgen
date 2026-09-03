package FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract;

use v5.20;
use strict;
use warnings;

use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;
use FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;
use FSM::VIAL::ArchitectureScaleRegressionPromotionQualification;
use FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore;

my $PLAN = 'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $POLICY = 'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy';
my $PROFILE_CAPTURE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture';
my $PROFILE_STORE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $QUALIFICATION =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualification';
my $QUALIFICATION_STORE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore';

my $SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_gate_contract.v1';
my $RESULT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1';
my $PROFILE_RESULT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_gate_profile_result.v1';
my $PUBLICATION_RELATIVE = join '/', qw(
    .artifacts qualification vial-scale v2 regression-promotion-gate-v1
    current regression-promotion-gate-result.json
);
my $STAGING_RELATIVE = join '/', qw(
    .artifacts tmp vial-scale regression-promotion-gate-publication v1
);
my $ENTRYPOINT = 'scripts/run_vial_regression_promotion_gate.pl';
my $MAX_RESULT_BYTES = 1_048_576;
my $MAX_ERROR_BYTES = 4_096;

my @REPORT_KEYS = qw(
    schema schema_version contract_identity qualification_evidence
    execution_contract result_contract cadence profiles explicit_nonclaims
);
my @QUALIFICATION_EVIDENCE_KEYS = qw(
    publication_identity publication_report_identity qualification_identity
    publisher_revision qualification_file_set_sha256 source_evidence
    formula_authority applicability_identity
);
my @EXECUTION_CONTRACT_KEYS = qw(
    execution_revision_role clean_revision_required worker_topology
    profile_count validation_records_per_profile
    raw_measurement_records_per_profile controller_invocations_per_profile
    total_validation_records total_raw_measurement_records
    total_controller_invocations fresh_canonical_producers
    stage_local_oracles_required deterministic_comparison
    performance_sample_reduction performance_enforcement
    environment_mismatch unavailable_exact_provider safety_guard
    qualification_mutation
);
my @RESULT_CONTRACT_KEYS = qw(
    schema profile_schema identity_prefix publication_relative_path
    staging_relative_path publication_mode maximum_profile_report_bytes
    maximum_profile_ipc_bytes maximum_result_bytes maximum_error_bytes
    maximum_recovery_entries same_volume atomic
    interrupted_run_preserves_previous_result result_is_qualification_evidence
    qualification_overwrite cleanup
);
my @CADENCE_KEYS = qw(
    entrypoint ordinary_slice_commit full_pre_push selected_important_step
    hosted_ci performance_override
);
my @PROFILE_KEYS = qw(
    ordinal selection_key coordinates adapter_class adapter_method
    adapter_arguments producer_authority_identity report_coordinate_authority
    provider_requirement applicability_requirement
    profile_qualification_identity source_report_identity workload_identity
    evidence_revision environment_identity correctness_projection_identity
    performance_applicability_identity qualified_budget
);
my @SUMMARY_KEYS = qw(
    profile_count validation_records raw_measurement_records
    controller_invocations sample_exclusions qualified_profiles
);
my @BUDGET_KEYS = qw(
    status formula_authority wall_time_ns cpu_time_ns peak_tree_rss_bytes
);
my @ENVIRONMENT_KEYS = qw(
    environment_identity host_profile tool_profile resource_guard provider_status
);
my @NONCLAIMS = qw(
    producer_execution
    provider_execution
    simulator_execution
    measurement_controller_execution
    result_publication
    performance_enforcement_activation
    observed_performance_result
    qualification_recalibration
    qualification_overwrite
    support_promotion
    architecture_scale_capacity
    historical_artifact_reuse
);

my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub profile_keys($class) {
    _exact_invocant($class, 'profile_keys');
    return [@PROFILE_KEYS];
}

sub qualification_evidence_keys($class) {
    _exact_invocant($class, 'qualification_evidence_keys');
    return [@QUALIFICATION_EVIDENCE_KEYS];
}

sub execution_contract_keys($class) {
    _exact_invocant($class, 'execution_contract_keys');
    return [@EXECUTION_CONTRACT_KEYS];
}

sub result_contract_keys($class) {
    _exact_invocant($class, 'result_contract_keys');
    return [@RESULT_CONTRACT_KEYS];
}

sub cadence_keys($class) {
    _exact_invocant($class, 'cadence_keys');
    return [@CADENCE_KEYS];
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub contract_limits($class) {
    _exact_invocant($class, 'contract_limits');
    my $profile_store = $PROFILE_STORE->publication_limits;
    my $profile_capture = $PROFILE_CAPTURE->capture_limits;
    return {
        maximum_profile_report_bytes =>
            $profile_store->{maximum_publication_bytes},
        maximum_profile_ipc_bytes =>
            $profile_capture->{maximum_ipc_bytes},
        maximum_result_bytes => $MAX_RESULT_BYTES,
        maximum_error_bytes => $MAX_ERROR_BYTES,
        maximum_recovery_entries => 1,
    };
}

sub derive($class, @args) {
    _exact_invocant($class, 'derive');
    my $request = _request('derive', \@args, [qw(repository_root)]);
    _require_active_guard();
    my $repository_root = _repository_root($request->{repository_root});
    my $qualification_load = $QUALIFICATION_STORE->load({
        repository_root => $repository_root,
    });
    my $plan = $PLAN->derive({repository_root => $repository_root});
    return _clone(_derive_from_evidence($qualification_load, $plan));
}

sub _derive_from_evidence($qualification_load, $plan) {
    _validate_evidence($qualification_load, $plan);

    my $report = $qualification_load->{report};
    my $manifest = $qualification_load->{manifest};
    my $artifact = $qualification_load->{artifact};
    my $qualification = $report->{qualification};
    my $applicability = $qualification->{performance_applicability};
    my $profile_count = scalar @{$plan->{entries}};

    my @profiles;
    for my $index (0 .. $profile_count - 1) {
        my $entry = $plan->{entries}[$index];
        my $qualified = $qualification->{profiles}[$index];
        push @profiles, {
            ordinal => $entry->{ordinal},
            selection_key => $entry->{selection_key},
            coordinates => _clone($entry->{coordinates}),
            adapter_class => $entry->{adapter_class},
            adapter_method => $entry->{adapter_method},
            adapter_arguments => _clone($entry->{adapter_arguments}),
            producer_authority_identity =>
                $entry->{producer_authority_identity},
            report_coordinate_authority =>
                _clone($entry->{report_coordinate_authority}),
            provider_requirement =>
                _clone($entry->{provider_requirement}),
            applicability_requirement =>
                _clone($entry->{applicability_requirement}),
            profile_qualification_identity =>
                $qualified->{profile_qualification_identity},
            source_report_identity =>
                $qualified->{source_report_identity},
            workload_identity => $qualified->{workload_identity},
            evidence_revision => $qualified->{evidence_revision},
            environment_identity =>
                _clone($qualified->{environment_identity}),
            correctness_projection_identity =>
                $qualified->{correctness_projection_identity},
            performance_applicability_identity =>
                $qualified->{performance_applicability_identity},
            qualified_budget => _clone($qualified->{qualified_budget}),
        };
    }

    my $limits = __PACKAGE__->contract_limits;
    my $contract = {
        schema => $SCHEMA,
        schema_version => 1,
        contract_identity => undef,
        qualification_evidence => {
            publication_identity => $manifest->{publication_identity},
            publication_report_identity =>
                $report->{publication_report_identity},
            qualification_identity =>
                $qualification->{qualification_identity},
            publisher_revision => $report->{publisher_revision},
            qualification_file_set_sha256 =>
                $artifact->{file_set_sha256},
            source_evidence => _clone($qualification->{source_evidence}),
            formula_authority => $qualification->{formula}{authority},
            applicability_identity =>
                $applicability->{applicability_identity},
        },
        execution_contract => {
            execution_revision_role =>
                'fresh_clean_provenance_not_qualification_applicability',
            clean_revision_required => JSON::PP::true,
            worker_topology => 'one_guard_visible_profile_worker_in_plan_order',
            profile_count => $profile_count,
            validation_records_per_profile =>
                $plan->{entries}[0]{validation_records},
            raw_measurement_records_per_profile =>
                $plan->{entries}[0]{raw_measurement_records},
            controller_invocations_per_profile =>
                $plan->{entries}[0]{controller_invocations},
            total_validation_records =>
                $plan->{total_validation_records},
            total_raw_measurement_records =>
                $plan->{total_raw_measurement_records},
            total_controller_invocations =>
                $plan->{total_controller_invocations},
            fresh_canonical_producers => JSON::PP::true,
            stage_local_oracles_required => JSON::PP::true,
            deterministic_comparison =>
                'exact_selection_workload_and_correctness_before_performance',
            performance_sample_reduction =>
                'maximum_each_metric_across_all_fresh_raw_records',
            performance_enforcement =>
                'exact_environment_only_after_correctness',
            environment_mismatch =>
                'correctness_required_performance_informational',
            unavailable_exact_provider => 'unavailable_not_pass',
            safety_guard => 'repository_ram_guard_required',
            qualification_mutation => JSON::PP::false,
        },
        result_contract => {
            schema => $RESULT_SCHEMA,
            profile_schema => $PROFILE_RESULT_SCHEMA,
            identity_prefix => 'regression-promotion-gate-result/',
            publication_relative_path => $PUBLICATION_RELATIVE,
            staging_relative_path => $STAGING_RELATIVE,
            publication_mode => 'atomic_replaceable_latest_observation',
            maximum_profile_report_bytes =>
                $limits->{maximum_profile_report_bytes},
            maximum_profile_ipc_bytes =>
                $limits->{maximum_profile_ipc_bytes},
            maximum_result_bytes => $limits->{maximum_result_bytes},
            maximum_error_bytes => $limits->{maximum_error_bytes},
            maximum_recovery_entries =>
                $limits->{maximum_recovery_entries},
            same_volume => JSON::PP::true,
            atomic => JSON::PP::true,
            interrupted_run_preserves_previous_result => JSON::PP::true,
            result_is_qualification_evidence => JSON::PP::false,
            qualification_overwrite => JSON::PP::false,
            cleanup => 'owned_staging_absent_after_result_reload',
        },
        cadence => {
            entrypoint => [$ENTRYPOINT, '--run'],
            ordinary_slice_commit =>
                'contract_and_changed_path_focused_checks_only',
            full_pre_push => 'guarded_complete_gate',
            selected_important_step => 'guarded_complete_gate',
            hosted_ci =>
                'available_correctness_with_identity_derived_performance_classification',
            performance_override => 'none',
        },
        profiles => \@profiles,
        explicit_nonclaims => [@NONCLAIMS],
    };
    $contract->{contract_identity} =
        'regression-promotion-gate-contract/'
        . sha256_hex(_canonical_json($contract));
    _validate_contract($contract);
    return $contract;
}

sub _validate_evidence($load, $plan) {
    _exact_keys(
        $load, $QUALIFICATION_STORE->load_result_keys,
        'regression gate qualification load',
    );
    my ($report, $manifest, $artifact) =
        @{$load}{qw(report manifest artifact)};
    _exact_keys(
        $report, $QUALIFICATION_STORE->report_keys,
        'regression gate qualification report',
    );
    _exact_keys(
        $manifest, $QUALIFICATION_STORE->manifest_keys,
        'regression gate qualification manifest',
    );
    _exact_keys(
        $artifact, $QUALIFICATION_STORE->artifact_keys,
        'regression gate qualification artifact',
    );
    confess "regression gate qualification publication report changed\n"
        unless ($report->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_publication_report.v1'
            && _json_integer_equals($report->{schema_version}, 1)
            && ($report->{publication_report_identity} // '') =~
                m{\Aregression-promotion-budget-qualification-report/[0-9a-f]{64}\z}
            && ($report->{publisher_revision} // '') =~ /\A[0-9a-f]{40}\z/
            && ($report->{outcome} // '') eq
                'accepted_published_qualification'
            && ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};
    confess "regression gate qualification manifest changed\n"
        unless ($manifest->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_manifest.v1'
            && _json_integer_equals($manifest->{schema_version}, 1)
            && ($manifest->{publication_identity} // '') =~
                m{\Aregression-promotion-budget-qualification-publication/[0-9a-f]{64}\z}
            && ($manifest->{publication_report_identity} // '') eq
                $report->{publication_report_identity}
            && ($manifest->{publisher_revision} // '') eq
                $report->{publisher_revision}
            && ($manifest->{outcome} // '') eq
                'accepted_published_qualification';
    confess "regression gate qualification artifact changed\n"
        unless ($artifact->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_artifact.v1'
            && _json_integer_equals($artifact->{schema_version}, 1)
            && ($artifact->{status} // '') =~ /\A(?:loaded|unchanged|published|recovered)\z/
            && ($artifact->{publication_relative_path} // '') eq
                '.artifacts/qualification/vial-scale/v2/regression-promotion-budget-qualification-v1/current'
            && ($artifact->{file_set_sha256} // '') =~ /\A[0-9a-f]{64}\z/
            && _json_true($artifact->{same_volume})
            && _json_true($artifact->{atomic});

    my $publication_contract = $QUALIFICATION_STORE->publication_contract;
    confess "regression gate qualification publication contract changed\n"
        unless _canonical_json($report->{publication_contract}) eq
                _canonical_json($publication_contract)
            && _canonical_json($manifest->{publication_contract}) eq
                _canonical_json($publication_contract)
            && ($publication_contract->{enforcement_state} // '') eq
                'not_activated'
            && !_json_true(
                $publication_contract->{replacement_policy}{overwrite},
            )
            && !_json_true(
                $publication_contract->{rollback}{publication_mutation},
            );

    my $qualification = $report->{qualification};
    _exact_keys(
        $qualification, $QUALIFICATION->report_keys,
        'regression gate qualification',
    );
    confess "regression gate qualification identity changed\n"
        unless ($qualification->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_qualification.v1'
            && _json_integer_equals($qualification->{schema_version}, 1)
            && ($qualification->{qualification_identity} // '') =~
                m{\Aregression-promotion-qualification/[0-9a-f]{64}\z}
            && ($qualification->{outcome} // '') eq
                'accepted_qualified_unpublished'
            && ($manifest->{qualification_identity} // '') eq
                $qualification->{qualification_identity}
            && ($manifest->{formula_authority} // '') eq 'decision-0056'
            && ($qualification->{formula}{authority} // '') eq 'decision-0056';

    my $applicability = $qualification->{performance_applicability};
    _exact_keys(
        $applicability, $POLICY->performance_applicability_keys,
        'regression gate performance applicability',
    );
    confess "regression gate performance applicability changed\n"
        unless ($applicability->{applicability_identity} // '') =~
                m{\Aregression-promotion-performance-applicability/[0-9a-f]{64}\z}
            && ($applicability->{matching_later_revision} // '') eq
                'performance_enforcement_eligible_after_correctness'
            && ($applicability->{deterministic_mismatch} // '') eq
                'correctness_rejects_before_performance'
            && ($applicability->{environment_mismatch} // '') eq
                'correctness_required_performance_informational'
            && ($applicability->{unavailable_exact_provider} // '') eq
                'unavailable_not_pass'
            && ($applicability->{recalibration} // '') eq
                'owned_version_replacement_with_old_new_evidence';

    _exact_keys($plan, $PLAN->report_keys, 'regression gate capture plan');
    confess "regression gate capture plan changed\n"
        unless ($plan->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_capture_plan.v2'
            && _json_integer_equals($plan->{schema_version}, 2)
            && ($plan->{plan_identity} // '') =~
                m{\Aregression-promotion-capture-plan/[0-9a-f]{64}\z}
            && ($plan->{plan_identity} // '') eq
                ($qualification->{source_evidence}{plan_identity} // '')
            && ($plan->{policy_identity} // '') eq
                ($qualification->{source_evidence}{policy_identity} // '')
            && ref($plan->{entries}) eq 'ARRAY'
            && @{$plan->{entries}} > 0;

    my $summary = $qualification->{summary};
    _exact_keys($summary, \@SUMMARY_KEYS, 'regression gate qualification summary');
    my $profile_count = scalar @{$plan->{entries}};
    confess "regression gate qualification summary changed\n"
        unless _json_integer_equals($summary->{profile_count}, $profile_count)
            && _json_integer_equals($summary->{qualified_profiles}, $profile_count)
            && _json_integer_equals($summary->{validation_records},
                $plan->{total_validation_records})
            && _json_integer_equals($summary->{raw_measurement_records},
                $plan->{total_raw_measurement_records})
            && _json_integer_equals($summary->{controller_invocations},
                $plan->{total_controller_invocations})
            && _json_integer_equals($summary->{sample_exclusions}, 0)
            && ref($qualification->{profiles}) eq 'ARRAY'
            && @{$qualification->{profiles}} == $profile_count
            && ref($manifest->{profile_bindings}) eq 'ARRAY'
            && @{$manifest->{profile_bindings}} == $profile_count;

    for my $index (0 .. $profile_count - 1) {
        my $entry = $plan->{entries}[$index];
        my $profile = $qualification->{profiles}[$index];
        my $binding = $manifest->{profile_bindings}[$index];
        _exact_keys($entry, $PLAN->entry_keys, 'regression gate plan entry');
        _exact_keys(
            $profile, $QUALIFICATION->profile_keys,
            'regression gate qualified profile',
        );
        _exact_keys(
            $binding, $QUALIFICATION_STORE->profile_binding_keys,
            'regression gate qualification binding',
        );
        confess "regression gate profile order changed\n"
            unless _json_integer_equals($entry->{ordinal}, $index + 1)
                && _json_integer_equals($profile->{ordinal}, $index + 1)
                && _json_integer_equals($binding->{ordinal}, $index + 1)
                && ($entry->{selection_key} // '') eq
                    ($profile->{selection_key} // '')
                && ($entry->{selection_key} // '') eq
                    ($binding->{selection_key} // '');
        confess "regression gate profile evidence binding changed\n"
            unless ($profile->{workload_identity} // '') =~
                    m{\Aworkload/[0-9a-f]{64}\z}
                && ($profile->{correctness_projection_identity} // '') =~
                    m{\Aregression-promotion-correctness/[0-9a-f]{64}\z}
                && ($profile->{performance_applicability_identity} // '') =~
                    m{\Aregression-promotion-profile-applicability/[0-9a-f]{64}\z}
                && ($profile->{evidence_revision} // '') eq
                    ($qualification->{source_evidence}{capture_revision} // '')
                && ($profile->{outcome} // '') eq
                    'accepted_qualified_unpublished';
        for my $key (qw(
            profile_qualification_identity source_report_identity
            workload_identity evidence_revision environment_identity
            correctness_projection_identity
            performance_applicability_identity qualified_budget provider_status
        )) {
            confess "regression gate manifest profile binding changed\n"
                unless _canonical_json($binding->{$key}) eq
                    _canonical_json($profile->{$key});
        }
        confess "regression gate profile provider binding changed\n"
            unless _canonical_json($entry->{provider_requirement}) eq
                    _canonical_json($profile->{provider_status})
                && ref($profile->{environment_identity}) eq 'HASH'
                && !blessed($profile->{environment_identity});
        _exact_keys(
            $profile->{environment_identity}, \@ENVIRONMENT_KEYS,
            'regression gate profile environment',
        );
        confess "regression gate profile environment provider changed\n"
            unless _canonical_json(
                $profile->{environment_identity}{provider_status},
            ) eq _canonical_json($profile->{provider_status});
        _exact_keys(
            $profile->{qualified_budget}, \@BUDGET_KEYS,
            'regression gate qualified budget',
        );
        confess "regression gate qualified budget changed\n"
            unless ($profile->{qualified_budget}{status} // '') eq
                    'qualified_unpublished'
                && ($profile->{qualified_budget}{formula_authority} // '') eq
                    'decision-0056'
                && _positive_integer(
                    $profile->{qualified_budget}{wall_time_ns},
                )
                && _positive_integer(
                    $profile->{qualified_budget}{cpu_time_ns},
                )
                && _positive_integer(
                    $profile->{qualified_budget}{peak_tree_rss_bytes},
                );
        confess "regression gate plan record topology changed\n"
            unless _json_integer_equals($entry->{validation_records}, 1)
                && _json_integer_equals($entry->{raw_measurement_records}, 3)
                && _json_integer_equals($entry->{controller_invocations}, 4)
                && _json_true($entry->{applicability_requirement}{required});
    }
    return 1;
}

sub _validate_contract($contract) {
    _exact_keys($contract, \@REPORT_KEYS, 'regression gate contract');
    confess "regression gate contract schema is invalid\n"
        unless ($contract->{schema} // '') eq $SCHEMA
            && _json_integer_equals($contract->{schema_version}, 1);
    my $projection = _clone($contract);
    my $identity = $projection->{contract_identity};
    $projection->{contract_identity} = undef;
    confess "regression gate contract identity is invalid\n"
        unless defined($identity) && !ref($identity)
            && $identity eq 'regression-promotion-gate-contract/'
                . sha256_hex(_canonical_json($projection));
    _exact_keys(
        $contract->{qualification_evidence}, \@QUALIFICATION_EVIDENCE_KEYS,
        'regression gate qualification evidence',
    );
    _exact_keys(
        $contract->{execution_contract}, \@EXECUTION_CONTRACT_KEYS,
        'regression gate execution contract',
    );
    _exact_keys(
        $contract->{result_contract}, \@RESULT_CONTRACT_KEYS,
        'regression gate result contract',
    );
    _exact_keys(
        $contract->{cadence}, \@CADENCE_KEYS,
        'regression gate cadence',
    );
    confess "regression gate contract profile inventory is invalid\n"
        unless ref($contract->{profiles}) eq 'ARRAY'
            && @{$contract->{profiles}} ==
                $contract->{execution_contract}{profile_count};
    for my $profile (@{$contract->{profiles}}) {
        _exact_keys($profile, \@PROFILE_KEYS, 'regression gate profile contract');
    }
    confess "regression gate contract nonclaims changed\n"
        unless _canonical_json($contract->{explicit_nonclaims}) eq
            _canonical_json(\@NONCLAIMS);
    return 1;
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @{$args} == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "regression gate $method request");
    return $args->[0];
}

sub _repository_root($value) {
    confess "regression gate repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "regression gate repository root is unavailable\n"
        unless defined($root) && -d $root && !-l $root;
    my $git = File::Spec->catfile($root, '.git');
    confess "regression gate repository Git identity is invalid\n"
        unless (-d $git || -f $git) && !-l $git;
    my @stat = lstat($root);
    confess "regression gate repository root cannot be inspected\n"
        unless @stat && !-l _ && -d _;
    confess "regression gate repository root owner changed\n"
        unless $stat[4] == $<;
    return $root;
}

sub _require_active_guard() {
    confess "regression gate contract requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1'
            && ($ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} // '') =~
                /\A[0-9]+\z/
            && ($ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} // '') =~
                /\A[0-9]+\z/;
    return 1;
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return 1;
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value)
            && ref($keys) eq 'ARRAY';
    my %expected = map { $_ => 1 } @{$keys};
    confess "$label contains unknown key '$_'\n"
        for grep { !$expected{$_} } keys %{$value};
    confess "$label is missing '$_'\n"
        for grep { !exists($value->{$_}) } @{$keys};
    return 1;
}

sub _json_true($value) {
    return JSON::PP::is_bool($value) && $value ? 1 : 0;
}

sub _json_integer_equals($value, $expected) {
    return defined($value) && !ref($value)
        && "$value" =~ /\A(?:0|[1-9][0-9]*)\z/
        && 0 + $value == $expected;
}

sub _positive_integer($value) {
    return defined($value) && !ref($value)
        && "$value" =~ /\A[1-9][0-9]*\z/;
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
