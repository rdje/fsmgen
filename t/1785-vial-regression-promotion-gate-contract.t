#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract;
use FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy;
use FSM::VIAL::ArchitectureScaleRegressionPromotionQualification;
use FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract';
my $plan_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $policy_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy';
my $qualification_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualification';
my $store_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $derive_from_evidence = $class->can('_derive_from_evidence');

{
    package FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile;

    sub qualified_correctness_projection_for_test {
        return FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract
            ->_qualified_correctness_projection(@_);
    }
}

my @routes = (
    [
        'semantic_bridge|semantic_catalog_v1|gate_candidate_v1|actions|-',
        'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement',
        'measure_profile',
        {family => 'semantic_catalog_v1', level => 'gate_candidate_v1',
            primary_axis => 'actions'},
        {family => 'semantic_catalog_v1', level => 'gate_candidate_v1',
            primary_axis => 'actions', backend_profile => undef},
    ],
    [
        'semantic_bridge|bridge_fanout_v1|gate_candidate_v1|backend_bindings|-',
        'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement',
        'measure_profile',
        {family => 'bridge_fanout_v1', level => 'gate_candidate_v1',
            primary_axis => 'backend_bindings'},
        {family => 'bridge_fanout_v1', level => 'gate_candidate_v1',
            primary_axis => 'backend_bindings', backend_profile => undef},
    ],
    [
        'execution_checking|execution_graph_v1|gate_candidate_v1|bindings|-',
        'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement',
        'measure_profile',
        {family => 'execution_graph_v1', level => 'gate_candidate_v1',
            primary_axis => 'bindings'},
        {family => 'execution_graph_v1', level => 'gate_candidate_v1',
            primary_axis => 'bindings', backend_profile => undef},
    ],
    [
        'execution_checking|checking_state_v1|gate_candidate_v1|random_occurrences|-',
        'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement',
        'measure_profile',
        {family => 'checking_state_v1', level => 'gate_candidate_v1',
            primary_axis => 'random_occurrences'},
        {family => 'checking_state_v1', level => 'gate_candidate_v1',
            primary_axis => 'random_occurrences', backend_profile => undef},
    ],
    map {
        my ($backend, $provider) = @{$_};
        [
            "backend_emission|backend_emission_v1|gate_candidate_v1|-|$backend",
            'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement',
            'measure_profile',
            {backend_profile => $backend, level => 'gate_candidate_v1'},
            {family => 'backend_emission_v1', level => 'gate_candidate_v1',
                primary_axis => 'artifact_graph', backend_profile => $backend},
            $provider,
        ]
    } (
        ['sv_portable_verilator', undef],
        ['vhdl_portable_ghdl', undef],
        ['vhdl_osvvm_qualified', 'repository_materialization'],
    ),
    [
        'portable_runtime|runtime_stream_v1|gate_candidate_v1|-|sv_portable_verilator',
        'FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement',
        'measure_profile',
        {level => 'gate_candidate_v1'},
        {family => 'runtime_stream_v1', level => 'gate_candidate_v1',
            primary_axis => 'runtime_trace_records',
            backend_profile => 'sv_portable_verilator'},
        'exact_tool_profile', 'verilator', 'qualified_verilator_5_046',
    ],
    [
        'portable_vhdl_runtime|runtime_stream_v1|gate_candidate_v1|-|vhdl_portable_ghdl',
        'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement',
        'measure_profile',
        {level => 'gate_candidate_v1'},
        {family => 'runtime_stream_v1', level => 'gate_candidate_v1',
            primary_axis => 'runtime_trace_records',
            backend_profile => 'vhdl_portable_ghdl'},
        'exact_tool_profile', 'ghdl', 'qualified_ghdl_6_0_0_llvm_jit',
    ],
    [
        'osvvm_runtime|runtime_stream_v1|gate_candidate_v1|-|vhdl_osvvm_qualified',
        'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement',
        'measure_profile',
        {level => 'gate_candidate_v1'},
        {family => 'runtime_stream_v1', level => 'gate_candidate_v1',
            primary_axis => 'runtime_trace_records',
            backend_profile => 'vhdl_osvvm_qualified'},
        'exact_tool_profile', 'ghdl',
        'qualified_osvvm_2026_05_ghdl_6_0_0_llvm_jit',
    ],
    [
        'balanced_portable|balanced_portable_v1|gate_candidate_v1|-|sv_portable_verilator',
        'FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement',
        'measure_member', {},
        {family => 'balanced_portable_v1', level => 'gate_candidate_v1',
            primary_axis => 'interaction_profile',
            backend_profile => 'sv_portable_verilator'},
    ],
);

subtest 'contract surface is closed and bounded' => sub {
    is_deeply([sort @{$class->report_keys}], [sort qw(
        schema schema_version contract_identity qualification_evidence
        execution_contract result_contract cadence profiles explicit_nonclaims
    )], 'contract report has one closed schema');
    is_deeply([sort @{$class->profile_keys}], [sort qw(
        ordinal selection_key coordinates adapter_class adapter_method
        adapter_arguments producer_authority_identity
        report_coordinate_authority provider_requirement
        applicability_requirement profile_qualification_identity
        source_report_identity workload_identity evidence_revision
        environment_identity correctness_projection_identity
        performance_applicability_identity qualified_budget
    )], 'each profile has one closed execution and qualification join');
    is_deeply($class->contract_limits, {
        maximum_profile_report_bytes => 67_108_864,
        maximum_profile_ipc_bytes => 65_536,
        maximum_result_bytes => 1_048_576,
        maximum_error_bytes => 4_096,
        maximum_recovery_entries => 1,
    }, 'result, IPC, error, and recovery envelopes are explicit');
    ok(scalar(grep { $_ eq 'performance_enforcement_activation' }
        @{$class->explicit_nonclaims}),
        'derivation does not activate performance enforcement');

    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->derive({repository_root => $repo_root});
    }), qr/requires the active repository RAM guard/,
        'public derivation requires the repository guard');
    like(dies(sub {
        $class->derive({repository_root => $repo_root, qualification => {}});
    }), qr/contains unknown key 'qualification'/,
        'callers cannot inject qualification evidence');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract::derive(
            'borrowed', {repository_root => $repo_root},
        );
    }), qr/requires the exact class invocant/,
        'borrowed class invocants reject');
};

subtest 'authenticated evidence yields the exact eleven-profile gate contract' => sub {
    my ($load, $plan) = fixtures();
    my $contract = $derive_from_evidence->($load, $plan);
    is($contract->{schema},
        'fsmgen.vial_architecture_scale_regression_promotion_gate_contract.v1',
        'gate contract schema is versioned');
    like($contract->{contract_identity},
        qr{\Aregression-promotion-gate-contract/[0-9a-f]{64}\z},
        'gate contract is content addressed');
    is($contract->{qualification_evidence}{publication_identity},
        $load->{manifest}{publication_identity},
        'contract binds the immutable qualification publication');
    is($contract->{qualification_evidence}{qualification_file_set_sha256},
        $load->{artifact}{file_set_sha256},
        'contract binds the complete qualification file set');
    is($contract->{execution_contract}{profile_count}, 11,
        'all eleven qualified profiles are mandatory');
    is($contract->{execution_contract}{total_validation_records}, 11,
        'one fresh validation is required per profile');
    is($contract->{execution_contract}{total_raw_measurement_records}, 33,
        'three fresh measurements are required per profile');
    is($contract->{execution_contract}{total_controller_invocations}, 44,
        'the gate retains all controller invocations');
    is($contract->{execution_contract}{performance_sample_reduction},
        'maximum_each_metric_across_all_fresh_raw_records',
        'hard budgets compare against every fresh raw sample');
    is($contract->{execution_contract}{performance_enforcement},
        'exact_environment_only_after_correctness',
        'performance cannot precede correctness or escape exact applicability');
    is($contract->{execution_contract}{environment_mismatch},
        'correctness_required_performance_informational',
        'unmatched environments keep correctness and informational timing');
    is($contract->{execution_contract}{unavailable_exact_provider},
        'unavailable_not_pass',
        'unavailable exact providers cannot become passes');
    is_deeply($contract->{cadence}{entrypoint},
        ['scripts/run_vial_regression_promotion_gate.pl', '--run'],
        'the future executable entrypoint is repository-relative and closed');
    is($contract->{cadence}{ordinary_slice_commit},
        'contract_and_changed_path_focused_checks_only',
        'ordinary commits do not inherit the expensive full gate');
    is($contract->{cadence}{performance_override}, 'none',
        'no caller mode can suppress exact-host enforcement');
    is($contract->{result_contract}{publication_mode},
        'atomic_replaceable_latest_observation',
        'repeatable observations cannot mutate qualification evidence');
    ok(!$contract->{result_contract}{result_is_qualification_evidence},
        'a gate result cannot become qualification evidence');
    ok(!$contract->{result_contract}{qualification_overwrite},
        'the result path cannot overwrite qualification');

    is_deeply(
        [map { [@{$_}{qw(adapter_class adapter_method)}] }
            @{$contract->{profiles}}],
        [map { [@{$_}[1, 2]] } @routes],
        'all seven canonical adapters remain in the qualified order',
    );
    is_deeply(
        [map { $_->{qualified_budget} }
            @{$contract->{profiles}}],
        [map { $_->{qualified_budget} }
            @{$load->{report}{qualification}{profiles}}],
        'every frozen budget is copied without recalculation');
};

subtest 'derivation executes no producer, provider, simulator, or controller' => sub {
    my ($load, $plan) = fixtures();
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement::measure_profile =
        sub { die "semantic producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement::measure_profile =
        sub { die "execution producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement::measure_profile =
        sub { die "backend producer executed\n" };
    local *FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::measure_profile =
        sub { die "portable runtime executed\n" };
    local *FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement::measure_profile =
        sub { die "portable VHDL runtime executed\n" };
    local *FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::measure_profile =
        sub { die "OSVVM runtime executed\n" };
    local *FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement::measure_member =
        sub { die "balanced producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleMeasurement::measure =
        sub { die "measurement controller executed\n" };
    my $contract = $derive_from_evidence->($load, $plan);
    is(scalar @{$contract->{profiles}}, 11,
        'metadata-only derivation succeeds with every work entrypoint poisoned');
};

subtest 'evidence, applicability, dispatch, and budget drift fail closed' => sub {
    my @mutations = (
        ['plan identity', sub {
            $_[1]{plan_identity} = 'regression-promotion-capture-plan/'
                . ('f' x 64);
        }, qr/capture plan changed/],
        ['profile order', sub {
            @{$ _[0]{report}{qualification}{profiles}}[0, 1] =
                @{$ _[0]{report}{qualification}{profiles}}[1, 0];
        }, qr/profile order changed/],
        ['manifest binding', sub {
            $_[0]{manifest}{profile_bindings}[0]{workload_identity} =
                'workload/' . ('e' x 64);
        }, qr/manifest profile binding changed/],
        ['provider', sub {
            $_[0]{report}{qualification}{profiles}[7]{provider_status}
                {provider_identity} = 'forged-provider';
        }, qr/manifest profile binding changed|profile provider binding changed/],
        ['correctness identity', sub {
            $_[0]{report}{qualification}{profiles}[0]
                {correctness_projection_identity} =
                    'regression-promotion-correctness/' . ('e' x 64);
        }, qr/manifest profile binding changed/],
        ['budget zero', sub {
            $_[0]{report}{qualification}{profiles}[0]
                {qualified_budget}{wall_time_ns} = 0;
            $_[0]{manifest}{profile_bindings}[0]
                {qualified_budget}{wall_time_ns} = 0;
        }, qr/qualified budget changed/],
        ['environment rule', sub {
            $_[0]{report}{qualification}{performance_applicability}
                {environment_mismatch} = 'pass';
        }, qr/performance applicability changed/],
        ['qualification overwrite', sub {
            $_[0]{report}{publication_contract}{replacement_policy}
                {overwrite} = JSON::PP::true;
        }, qr/publication contract changed/],
        ['unknown report key', sub {
            $_[0]{report}{caller_budget} = 1;
        }, qr/contains unknown key 'caller_budget'/],
        ['dispatch omission', sub {
            pop @{$_[1]{entries}};
        }, qr/qualification summary changed/],
    );
    for my $mutation (@mutations) {
        my ($name, $change, $expected) = @{$mutation};
        my ($load, $plan) = fixtures();
        $change->($load, $plan);
        like(dies(sub { $derive_from_evidence->($load, $plan) }),
            $expected, "$name drift rejects");
    }
};

subtest 'public derivation is caller-sealed and returned values are defensive' => sub {
    my ($load, $plan) = fixtures();
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore::load =
        sub { return clone($load) };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan::derive =
        sub { return clone($plan) };

    my $first = $class->derive({repository_root => $repo_root});
    my $identity = $first->{contract_identity};
    $first->{profiles}[0]{qualified_budget}{wall_time_ns} = 1;
    $first->{cadence}{performance_override} = 'caller_disabled';
    my $second = $class->derive({repository_root => $repo_root});
    is($second->{contract_identity}, $identity,
        'repeated derivation has one stable identity');
    cmp_ok($second->{profiles}[0]{qualified_budget}{wall_time_ns}, '>', 1,
        'nested budget values are defensive');
    is($second->{cadence}{performance_override}, 'none',
        'nested cadence values are defensive');
};

subtest 'qualified full projection fallback is authenticated and defensive' => sub {
    my ($load) = fixtures();
    my $profile = $load->{report}{qualification}{profiles}[9];
    my $binding = $load->{manifest}{profile_bindings}[9];
    my $projection = {
        schema => 'synthetic.qualified.correctness.v1',
        ordinal => 10,
    };
    my $identity = 'regression-promotion-correctness/'
        . sha256_hex($json->encode($projection));
    $profile->{correctness_projection} = clone($projection);
    $profile->{correctness_projection_identity} = $identity;
    $binding->{correctness_projection_identity} = $identity;
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore::load =
        sub { return clone($load) };
    my $request = {
        repository_root => $repo_root,
        ordinal => 10,
        selection_key => $profile->{selection_key},
        correctness_projection_identity => $identity,
        qualification_identity =>
            $load->{report}{qualification}{qualification_identity},
        publication_identity => $load->{manifest}{publication_identity},
        qualification_file_set_sha256 =>
            $load->{artifact}{file_set_sha256},
    };
    my $first =
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::qualified_correctness_projection_for_test(
            $request,
        );
    is_deeply($first, $projection,
        'sealed fallback returns the selected authenticated full projection');
    $first->{ordinal} = 1;
    is_deeply(
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::qualified_correctness_projection_for_test(
            $request,
        ),
        $projection,
        'returned full projection is defensive',
    );
    my $wrong_selection = clone($request);
    $wrong_selection->{selection_key} = 'foreign';
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::qualified_correctness_projection_for_test(
            $wrong_selection,
        );
    }), qr/profile binding changed/,
        'selection substitution rejects');
    $profile->{correctness_projection}{ordinal} = 11;
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::qualified_correctness_projection_for_test(
            $request,
        );
    }), qr/projection is invalid/,
        'projection mutation under the qualified identity rejects');
};

SKIP: {
    skip 'real qualification authentication is opt-in', 7
        unless $ENV{FSMGEN_VIAL_REGRESSION_GATE_CONTRACT_EXACT};
    my $contract = $class->derive({repository_root => $repo_root});
    is($contract->{execution_contract}{profile_count}, 11,
        'real contract contains every qualified profile');
    is($contract->{execution_contract}{total_validation_records}, 11,
        'real contract retains every validation');
    is($contract->{execution_contract}{total_raw_measurement_records}, 33,
        'real contract retains every fresh measurement');
    is($contract->{execution_contract}{total_controller_invocations}, 44,
        'real contract retains every invocation');
    is_deeply([
        $contract->{qualification_evidence}{publication_identity},
        $contract->{qualification_evidence}{qualification_file_set_sha256},
    ], [
        'regression-promotion-budget-qualification-publication/'
        . '1c2a3832b2b4163e1a6a8124feff2b452f8522c2929098447f3903115ad2945f',
        '28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095',
    ], 'real contract binds the immutable qualification publication and file set');
    is($contract->{qualification_evidence}{qualification_identity},
        'regression-promotion-qualification/'
        . 'd8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97',
        'real contract binds the qualified budget identity');
    is($contract->{contract_identity},
        'regression-promotion-gate-contract/'
        . '0150f4b39e1d099eec9a592c1abd1c75ed2758efff0ccf1514ec57599179e368',
        'real gate contract has the exact qualified content identity');
}

done_testing;

sub fixtures {
    my $plan_identity = 'regression-promotion-capture-plan/' . ('a' x 64);
    my $policy_identity = 'regression-promotion-policy/' . ('b' x 64);
    my @entries;
    my @profiles;
    my @bindings;
    for my $index (0 .. $#routes) {
        my $ordinal = $index + 1;
        my $route = $routes[$index];
        my ($selection, $adapter, $method, $arguments, $report_coordinates,
            $provider_kind, $logical_name, $provider_identity) = @{$route};
        $provider_kind //= 'not_applicable';
        my $provider = {
            kind => $provider_kind,
            external_verification_tool =>
                $provider_kind eq 'exact_tool_profile'
                    ? JSON::PP::true : JSON::PP::false,
            logical_name => $logical_name,
            provider_identity => $provider_identity,
            tool_profile_identity => $provider_kind eq 'exact_tool_profile'
                ? 'tool-profile/' . sha256_hex("tool-$ordinal") : undef,
        };
        if ($provider_kind eq 'repository_materialization') {
            $provider->{logical_name} = 'osvvm';
            $provider->{provider_identity} =
                'external_exact_osvvm_2026_05';
        }
        my $authority = {
            authority_identity =>
                'report-coordinate-authority/'
                . sha256_hex("coordinates-$ordinal"),
            %{$report_coordinates},
        };
        my @coordinate_parts = split /\|/, $selection, -1;
        my $entry = {
            ordinal => $ordinal,
            selection_key => $selection,
            coordinates => {
                authority => $coordinate_parts[0],
                family => $coordinate_parts[1],
                level => $coordinate_parts[2],
                primary_axis => $coordinate_parts[3] eq '-'
                    ? undef : $coordinate_parts[3],
                backend_profile => $coordinate_parts[4] eq '-'
                    ? undef : $coordinate_parts[4],
            },
            worker_ordinal => $ordinal,
            adapter_class => $adapter,
            adapter_method => $method,
            repository_root_binding => 'validated_capture_repository_root',
            adapter_arguments => clone($arguments),
            producer_authority => {fixture_ordinal => $ordinal},
            producer_authority_identity =>
                'capture-producer-authority/'
                . sha256_hex("producer-$ordinal"),
            provider_requirement => clone($provider),
            report_coordinate_authority => $authority,
            applicability_requirement => {
                required => JSON::PP::true,
                predicate => 'fixture_accepted',
            },
            validation_records => 1,
            raw_measurement_records => 3,
            controller_invocations => 4,
            publication_relative_path => sprintf(
                '.artifacts/qualification/vial-scale/v2/regression-promotion-corpus-v1/profiles/%02d-%s/measurement-report.json',
                $ordinal, sha256_hex($selection),
            ),
        };
        push @entries, $entry;

        my $environment = {
            environment_identity =>
                'regression-promotion-environment/'
                . sha256_hex("environment-$ordinal"),
            host_profile => {fixture_host => 'exact'},
            tool_profile => {fixture_tool => $ordinal},
            resource_guard => {active => JSON::PP::true},
            provider_status => clone($provider),
        };
        my $budget = {
            status => 'qualified_unpublished',
            formula_authority => 'decision-0056',
            wall_time_ns => 2_000_000_000 + $ordinal,
            cpu_time_ns => 2_000_000_000 + $ordinal,
            peak_tree_rss_bytes => 268_435_456 + $ordinal,
        };
        my $profile = {
            ordinal => $ordinal,
            selection_key => $selection,
            profile_qualification_identity =>
                'regression-promotion-profile-qualification/'
                . sha256_hex("qualified-$ordinal"),
            source_report_identity =>
                'fixture-report/' . sha256_hex("report-$ordinal"),
            workload_identity =>
                'workload/' . sha256_hex("workload-$ordinal"),
            evidence_revision => 'c' x 40,
            environment_identity => $environment,
            correctness_projection_identity =>
                'regression-promotion-correctness/'
                . sha256_hex("correctness-$ordinal"),
            correctness_projection => {fixture_ordinal => $ordinal},
            performance_applicability_identity =>
                'regression-promotion-profile-applicability/'
                . sha256_hex("applicability-$ordinal"),
            validation_identity =>
                'measurement/' . sha256_hex("validation-$ordinal"),
            raw_measurement_identities => [map {
                'measurement/' . sha256_hex("raw-$ordinal-$_")
            } 1 .. 3],
            accepted_run_totals => [],
            aggregate_statistics => {},
            qualified_budget => $budget,
            provider_status => clone($provider),
            outcome => 'accepted_qualified_unpublished',
        };
        push @profiles, $profile;
        push @bindings, {
            map { $_ => clone($profile->{$_}) } qw(
                ordinal selection_key profile_qualification_identity
                source_report_identity workload_identity evidence_revision
                environment_identity correctness_projection_identity
                performance_applicability_identity qualified_budget
                provider_status
            )
        };
    }

    my $plan = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_capture_plan.v2',
        schema_version => 2,
        plan_identity => $plan_identity,
        policy_identity => $policy_identity,
        publication_base => '.artifacts/qualification/vial-scale/v2',
        publication_id => 'regression-promotion-corpus-v1',
        publication_schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1',
        worker_count => 11,
        controller_invocations_per_worker => 4,
        total_validation_records => 11,
        total_raw_measurement_records => 33,
        total_controller_invocations => 44,
        entries => \@entries,
        explicit_nonclaims => [],
    };
    my $applicability = $policy_class->performance_applicability_contract;
    my $qualification = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_qualification.v1',
        schema_version => 1,
        qualification_identity =>
            'regression-promotion-qualification/' . ('d' x 64),
        source_evidence => {
            capture_revision => 'c' x 40,
            corpus_identity => 'regression-promotion-corpus/' . ('e' x 64),
            publication_identity =>
                'regression-promotion-corpus-publication/' . ('f' x 64),
            file_set_sha256 => '1' x 64,
            plan_identity => $plan_identity,
            policy_identity => $policy_identity,
            publication_id => 'regression-promotion-corpus-v1',
            publication_schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1',
            dirty_state => JSON::PP::false,
        },
        formula => {
            authority => 'decision-0056',
            wall_time_ns => {}, cpu_time_ns => {}, peak_tree_rss_bytes => {},
        },
        performance_applicability => $applicability,
        summary => {
            profile_count => 11,
            validation_records => 11,
            raw_measurement_records => 33,
            controller_invocations => 44,
            sample_exclusions => 0,
            qualified_profiles => 11,
        },
        profiles => \@profiles,
        outcome => 'accepted_qualified_unpublished',
        diagnostics => [],
        explicit_nonclaims => [],
    };
    my $publication_contract = $store_class->publication_contract;
    my $report_identity =
        'regression-promotion-budget-qualification-report/' . ('2' x 64);
    my $publication_identity =
        'regression-promotion-budget-qualification-publication/' . ('3' x 64);
    my $report = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_publication_report.v1',
        schema_version => 1,
        publication_report_identity => $report_identity,
        publisher_revision => '4' x 40,
        qualification => $qualification,
        publication_contract => clone($publication_contract),
        outcome => 'accepted_published_qualification',
        diagnostics => [],
        explicit_nonclaims => [],
    };
    my $manifest = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_manifest.v1',
        schema_version => 1,
        publication_identity => $publication_identity,
        publication_report_identity => $report_identity,
        qualification_identity => $qualification->{qualification_identity},
        publisher_revision => $report->{publisher_revision},
        source_evidence => clone($qualification->{source_evidence}),
        formula_authority => 'decision-0056',
        profile_bindings => \@bindings,
        publication_contract => clone($publication_contract),
        report_artifact => {
            relative_path =>
                '.artifacts/qualification/vial-scale/v2/regression-promotion-budget-qualification-v1/current/regression-promotion-budget-qualification.json',
            sha256 => '5' x 64,
            bytes => 1000,
        },
        summary => clone($qualification->{summary}),
        outcome => 'accepted_published_qualification',
        explicit_nonclaims => [],
    };
    my $artifact = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_artifact.v1',
        schema_version => 1,
        status => 'loaded',
        publication_relative_path =>
            '.artifacts/qualification/vial-scale/v2/regression-promotion-budget-qualification-v1/current',
        report_artifact => clone($manifest->{report_artifact}),
        manifest_artifact => {
            relative_path =>
                '.artifacts/qualification/vial-scale/v2/regression-promotion-budget-qualification-v1/current/qualification-manifest.json',
            sha256 => '6' x 64,
            bytes => 1000,
        },
        file_set_sha256 => '7' x 64,
        same_volume => JSON::PP::true,
        atomic => JSON::PP::true,
    };
    return ({report => $report, manifest => $manifest, artifact => $artifact},
        $plan);
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub dies {
    my ($code) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    return $error // '';
}
