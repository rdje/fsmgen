package FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement;
use FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement;
use FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;
use FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement;
use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement;
use FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy;
use FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement;

my $POLICY = 'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy';
my $SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_capture_plan.v2';
my $PUBLICATION_BASE = '.artifacts/qualification/vial-scale/v2';
my $PUBLICATION_ID = 'regression-promotion-corpus-v1';
my $PUBLICATION_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1';
my $REPOSITORY_ROOT_BINDING = 'validated_capture_repository_root';
my $VALIDATION_RECORDS = 1;
my $RAW_MEASUREMENT_RECORDS = 3;
my $CONTROLLER_INVOCATIONS = 4;

my @REPORT_KEYS = qw(
    schema schema_version plan_identity policy_identity publication_base
    publication_id publication_schema worker_count
    controller_invocations_per_worker total_validation_records
    total_raw_measurement_records total_controller_invocations entries
    explicit_nonclaims
);
my @ENTRY_KEYS = qw(
    ordinal selection_key coordinates worker_ordinal adapter_class
    adapter_method repository_root_binding adapter_arguments
    producer_authority producer_authority_identity provider_requirement
    report_coordinate_authority applicability_requirement validation_records
    raw_measurement_records controller_invocations publication_relative_path
);
my @COORDINATE_KEYS = qw(
    authority family level primary_axis backend_profile
);
my @REPORT_COORDINATE_KEYS = qw(
    family level primary_axis backend_profile
);
my @REPORT_COORDINATE_AUTHORITY_KEYS = (
    'authority_identity', @REPORT_COORDINATE_KEYS,
);
my @PROVIDER_KEYS = qw(
    kind external_verification_tool logical_name provider_identity
    tool_profile_identity
);
my @APPLICABILITY_KEYS = qw(required predicate);
my @NONCLAIMS = qw(
    producer_execution
    provider_execution
    simulator_execution
    measurement_controller_execution
    publication_transaction
    current_measurement_evidence
    performance_budget_promotion
    support_promotion
    architecture_scale_capacity
    historical_artifact_reuse
);

my @ROUTES = (
    {
        selection_key =>
            'semantic_bridge|semantic_catalog_v1|gate_candidate_v1|actions|-',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {
            family => 'semantic_catalog_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'actions',
        },
        ownership_method => 'family_authorities',
        ownership_key => 'semantic_catalog_v1',
        ownership_digest =>
            'e12f590edd984a5d140cce741df4d42474ba64c0d4c7bb683879fedd266ce4e8',
        report_coordinates_digest =>
            '80e8438cbdd92e07a773d994af0445babd6ff6003dded1e47a940d5f65fc66cf',
        applicability => 'accepted_validation_and_family_evaluation',
    },
    {
        selection_key =>
            'semantic_bridge|bridge_fanout_v1|gate_candidate_v1|backend_bindings|-',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {
            family => 'bridge_fanout_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'backend_bindings',
        },
        ownership_method => 'family_authorities',
        ownership_key => 'bridge_fanout_v1',
        ownership_digest =>
            '9d4503da87edcaddd284968ddbb49697ea719b74fbf3dfb64ddfbb5119069236',
        report_coordinates_digest =>
            'da80402fd33fcda9c8c79087ae42a5101b90e37b6018434ecc2af59858844c3e',
        applicability => 'accepted_validation_and_family_evaluation',
    },
    {
        selection_key =>
            'execution_checking|execution_graph_v1|gate_candidate_v1|bindings|-',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {
            family => 'execution_graph_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'bindings',
        },
        ownership_method => 'family_authorities',
        ownership_key => 'execution_graph_v1',
        ownership_digest =>
            '754c3ada61a11967d06fff4b86e413de4169aa95e61dec65dd162f28ab850aca',
        report_coordinates_digest =>
            'b6c5ad217c7f080a619dcda4d52b8d6c5e06fab63d66af582a232cfef8c20ab4',
        applicability => 'accepted_construction_and_canonical_evaluation',
    },
    {
        selection_key =>
            'execution_checking|checking_state_v1|gate_candidate_v1|random_occurrences|-',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {
            family => 'checking_state_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'random_occurrences',
        },
        ownership_method => 'family_authorities',
        ownership_key => 'checking_state_v1',
        ownership_digest =>
            'c62bf4e00749d2e57e1d187d255a0aaf03f39694ae0edf14b6898f035af61684',
        report_coordinates_digest =>
            '5ddcbd50a30ff637d61bbb79c37def270e05e54c693d0d6499950f706b7db313',
        applicability => 'accepted_construction_and_canonical_evaluation',
    },
    {
        selection_key =>
            'backend_emission|backend_emission_v1|gate_candidate_v1|-|sv_portable_verilator',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {
            backend_profile => 'sv_portable_verilator',
            level => 'gate_candidate_v1',
        },
        ownership_method => 'profile_authorities',
        ownership_key => 'sv_portable_verilator',
        ownership_digest =>
            'eaedf84c302ecc476118584a7950a69c82360e63a5338b36fb97b8fb899105b8',
        report_coordinates_digest =>
            'f28dd646a152d4b621b5605d93a6c91c3f4c85b9408fff36a7b71472effaad36',
        applicability => 'accepted_validation_and_artifacts_emitted',
    },
    {
        selection_key =>
            'backend_emission|backend_emission_v1|gate_candidate_v1|-|vhdl_portable_ghdl',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {
            backend_profile => 'vhdl_portable_ghdl',
            level => 'gate_candidate_v1',
        },
        ownership_method => 'profile_authorities',
        ownership_key => 'vhdl_portable_ghdl',
        ownership_digest =>
            'f4f93c6378df2e91f683a4f5241fa2f5152229a97ef9911ee62f4c30da75092b',
        report_coordinates_digest =>
            '2f7cd1622928f84bb4a689bd4392dbdbd855813aa3e9928925320613f87314e5',
        applicability => 'accepted_validation_and_artifacts_emitted',
    },
    {
        selection_key =>
            'backend_emission|backend_emission_v1|gate_candidate_v1|-|vhdl_osvvm_qualified',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {
            backend_profile => 'vhdl_osvvm_qualified',
            level => 'gate_candidate_v1',
        },
        ownership_method => 'profile_authorities',
        ownership_key => 'vhdl_osvvm_qualified',
        ownership_digest =>
            '4a3a318f249a18d6685d04b9849190987774c48e64e1d1d967caa12512346b9b',
        report_coordinates_digest =>
            '4a6433482cab4ad58054295c12dc84d88391abd6caf33f9fb76e4a0219d34448',
        applicability => 'accepted_validation_and_artifacts_emitted',
        materialization_provider => 'external_exact_osvvm_2026_05',
    },
    {
        selection_key =>
            'portable_runtime|runtime_stream_v1|gate_candidate_v1|-|sv_portable_verilator',
        adapter_class =>
            'FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {level => 'gate_candidate_v1'},
        ownership_method => 'owned_shapes',
        ownership_digest =>
            '235335570485b9d84b51fa028e5a695b654bcf384580dca418a0d89ebc77eba6',
        report_coordinates_digest =>
            '0a0f04cfb1318c87b58e5b39a3b19640a988af2289a35505974b10f6256d29fc',
        applicability =>
            'structurally_qualified_materialization_and_accepted_validation',
        tool_digest =>
            '40de18b1140d38a1ea081f6e3ccdb26628b2e848a76a4e24c3c2a3bee56bc9c6',
        tool_name => 'verilator',
        provider_identity => 'qualified_verilator_5_046',
    },
    {
        selection_key =>
            'portable_vhdl_runtime|runtime_stream_v1|gate_candidate_v1|-|vhdl_portable_ghdl',
        adapter_class =>
            'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {level => 'gate_candidate_v1'},
        ownership_method => 'owned_shapes',
        ownership_digest =>
            '9e6b49f0b00b517a9aad0e354424286cc38dfe9165dd65a2aec66c70e9760cd3',
        report_coordinates_digest =>
            '6b585d8fda4c1c69023f784304eb622263698e6770fea6e4bc132b98775aaf25',
        applicability =>
            'structurally_qualified_materialization_and_accepted_validation',
        tool_digest =>
            '911258b328f62381fe59916c7d272d5f5cb5c31b6274e98b00bf3865ecf98191',
        tool_name => 'ghdl',
        provider_identity => 'qualified_ghdl_6_0_0_llvm_jit',
    },
    {
        selection_key =>
            'osvvm_runtime|runtime_stream_v1|gate_candidate_v1|-|vhdl_osvvm_qualified',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement',
        adapter_method => 'measure_profile',
        adapter_arguments => {level => 'gate_candidate_v1'},
        ownership_method => 'owned_shapes',
        ownership_digest =>
            '73cc8ffecaae5428fe9508f948cb953c2d91c1ce00d83bdd602f052356886dd2',
        report_coordinates_digest =>
            'cf1895e9af13cab073e417f3b999d30030e08cb2cf343bd35ccb8c5b38c8724b',
        applicability =>
            'provider_structurally_qualified_and_accepted_validation',
        tool_digest =>
            'cb9962d5707404479548b6f837c908a76b1316d08251828324023d3560be46c6',
        tool_name => 'ghdl',
        provider_identity =>
            'qualified_osvvm_2026_05_ghdl_6_0_0_llvm_jit',
    },
    {
        selection_key =>
            'balanced_portable|balanced_portable_v1|gate_candidate_v1|-|sv_portable_verilator',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement',
        adapter_method => 'measure_member',
        adapter_arguments => {},
        ownership_method => 'member_authority',
        ownership_digest =>
            '57ea0cf228d807c11a4acce9e2b04729d24c1b93be8f3553a0fcc53cb328d1fd',
        report_coordinates_digest =>
            'fb8104156b8fb7b6457b8afbf13c302b947fd77fb530e9c89ed91bf0c3f2439b',
        applicability => 'accepted_validation',
    },
);

my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub entry_keys($class) {
    _exact_invocant($class, 'entry_keys');
    return [@ENTRY_KEYS];
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub derive($class, @args) {
    _exact_invocant($class, 'derive');
    my $request = _request('derive', \@args, [qw(repository_root)]);
    my $policy = $POLICY->derive({
        repository_root => $request->{repository_root},
    });
    return _clone(_derive_from_policy($policy));
}

sub _derive_from_policy($policy) {
    _validate_policy($policy);

    my @entries;
    for my $index (0 .. $#ROUTES) {
        my $route = $ROUTES[$index];
        my $selected = $policy->{selected_profiles}[$index];
        confess "capture plan selected profile order changed\n"
            unless $selected->{selection_key} eq $route->{selection_key};
        push @entries, _entry($index + 1, $route, $selected);
    }

    my $plan = {
        schema => $SCHEMA,
        schema_version => 2,
        plan_identity => undef,
        policy_identity => $policy->{policy_identity},
        publication_base => $PUBLICATION_BASE,
        publication_id => $PUBLICATION_ID,
        publication_schema => $PUBLICATION_SCHEMA,
        worker_count => scalar @entries,
        controller_invocations_per_worker => $CONTROLLER_INVOCATIONS,
        total_validation_records => scalar(@entries) * $VALIDATION_RECORDS,
        total_raw_measurement_records =>
            scalar(@entries) * $RAW_MEASUREMENT_RECORDS,
        total_controller_invocations =>
            scalar(@entries) * $CONTROLLER_INVOCATIONS,
        entries => \@entries,
        explicit_nonclaims => [@NONCLAIMS],
    };
    $plan->{plan_identity} = 'regression-promotion-capture-plan/'
        . sha256_hex(_canonical_json($plan));
    _validate_plan($plan);
    return $plan;
}

sub _entry($ordinal, $route, $selected) {
    my $adapter = $route->{adapter_class};
    confess "capture plan adapter measurement method is unavailable\n"
        unless $adapter->can($route->{adapter_method});

    my $producer_authority = _producer_authority($route, $selected);
    my $producer_digest = sha256_hex(_canonical_json($producer_authority));
    my $provider = _provider_requirement($route, $producer_authority);
    my $report_coordinate_authority =
        _report_coordinate_authority($route);
    my $profile_token = sha256_hex($selected->{selection_key});
    my $publication_path = join '/',
        $PUBLICATION_BASE, $PUBLICATION_ID, 'profiles',
        sprintf('%02d-%s', $ordinal, $profile_token),
        'measurement-report.json';

    return {
        ordinal => $ordinal,
        selection_key => $selected->{selection_key},
        coordinates => {
            map { $_ => $selected->{$_} } @COORDINATE_KEYS
        },
        worker_ordinal => $ordinal,
        adapter_class => $adapter,
        adapter_method => $route->{adapter_method},
        repository_root_binding => $REPOSITORY_ROOT_BINDING,
        adapter_arguments => _clone($route->{adapter_arguments}),
        producer_authority => $producer_authority,
        producer_authority_identity =>
            'capture-producer-authority/' . $producer_digest,
        provider_requirement => $provider,
        report_coordinate_authority => $report_coordinate_authority,
        applicability_requirement => {
            required => JSON::PP::true,
            predicate => $route->{applicability},
        },
        validation_records => $VALIDATION_RECORDS,
        raw_measurement_records => $RAW_MEASUREMENT_RECORDS,
        controller_invocations => $CONTROLLER_INVOCATIONS,
        publication_relative_path => $publication_path,
    };
}

sub _report_coordinate_authority($route) {
    my $adapter = $route->{adapter_class};
    confess "capture plan adapter report-coordinate method is unavailable\n"
        unless $adapter->can('report_coordinates');
    my $coordinates = $adapter->report_coordinates(
        _clone($route->{adapter_arguments}),
    );
    _exact_keys(
        $coordinates, \@REPORT_COORDINATE_KEYS,
        'capture plan report coordinates',
    );
    my $authority = {
        authority_identity => undef,
        map { $_ => $coordinates->{$_} } @REPORT_COORDINATE_KEYS
    };
    my $digest = sha256_hex(_canonical_json($authority));
    confess "capture plan report coordinate authority changed\n"
        unless $digest eq $route->{report_coordinates_digest};
    $authority->{authority_identity} =
        'report-coordinate-authority/' . $digest;
    return $authority;
}

sub _producer_authority($route, $selected) {
    my $adapter = $route->{adapter_class};
    my $method = $route->{ownership_method};
    confess "capture plan adapter ownership method is unavailable\n"
        unless $adapter->can($method);
    my $metadata = $adapter->$method();
    my $digest = sha256_hex(_canonical_json($metadata));
    if ($method eq 'family_authorities' || $method eq 'profile_authorities') {
        confess "capture plan adapter ownership inventory is invalid\n"
            unless ref($metadata) eq 'HASH' && !blessed($metadata)
                && exists $metadata->{$route->{ownership_key}};
        my $authority = $metadata->{$route->{ownership_key}};
        my $authority_digest = sha256_hex(_canonical_json($authority));
        confess "capture plan producer authority changed\n"
            unless $authority_digest eq $route->{ownership_digest};
        return _clone($authority);
    }
    if ($method eq 'owned_shapes') {
        confess "capture plan adapter owned-shape inventory changed\n"
            unless $digest eq $route->{ownership_digest};
        my @matches = grep {
            ref($_) eq 'HASH'
                && ($_->{level} // '') eq $selected->{level}
                && ($_->{backend_profile} // '') eq
                    ($selected->{backend_profile} // '')
        } @{$metadata};
        confess "capture plan selected shape must be owned exactly once\n"
            unless @matches == 1;
        return {
            ownership_method => $method,
            owned_shape => _clone($matches[0]),
            owned_shapes_identity => 'owned-shapes/' . $digest,
        };
    }
    confess "capture plan balanced authority changed\n"
        unless $method eq 'member_authority'
            && $digest eq $route->{ownership_digest};
    return _clone($metadata);
}

sub _provider_requirement($route, $producer_authority) {
    if (defined $route->{tool_digest}) {
        my $adapter = $route->{adapter_class};
        confess "capture plan adapter tool-profile method is unavailable\n"
            unless $adapter->can('tool_profile');
        my $profile = $adapter->tool_profile;
        my $digest = sha256_hex(_canonical_json($profile));
        confess "capture plan exact tool profile changed\n"
            unless $digest eq $route->{tool_digest}
                && ($profile->{external_verification_tool} // 0)
                && ($profile->{logical_name} // '') eq $route->{tool_name}
                && ($profile->{provider_identity} // '') eq
                    $route->{provider_identity};
        return {
            kind => 'exact_tool_profile',
            external_verification_tool => JSON::PP::true,
            logical_name => $route->{tool_name},
            provider_identity => $route->{provider_identity},
            tool_profile_identity => 'tool-profile/' . $digest,
        };
    }
    if (defined $route->{materialization_provider}) {
        confess "capture plan materialization provider changed\n"
            unless ref($producer_authority->{structural_authority}) eq 'HASH'
                && ($producer_authority->{structural_authority}
                    {provider_materialization} // '') eq
                    $route->{materialization_provider};
        return {
            kind => 'repository_materialization',
            external_verification_tool => JSON::PP::false,
            logical_name => 'osvvm',
            provider_identity => $route->{materialization_provider},
            tool_profile_identity => undef,
        };
    }
    return {
        kind => 'not_applicable',
        external_verification_tool => JSON::PP::false,
        logical_name => undef,
        provider_identity => undef,
        tool_profile_identity => undef,
    };
}

sub _validate_policy($policy) {
    _exact_keys($policy, $POLICY->report_keys, 'capture plan policy');
    confess "capture plan policy schema changed\n"
        unless ($policy->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_policy.v1'
            && ($policy->{schema_version} // 0) == 1;
    my $projection = _clone($policy);
    my $identity = delete $projection->{policy_identity};
    $projection->{policy_identity} = undef;
    confess "capture plan policy identity changed\n"
        unless defined($identity)
            && $identity eq 'regression-promotion-policy/'
                . sha256_hex(_canonical_json($projection));
    confess "capture plan requires current recapture\n"
        unless $policy->{selected_strategy}{current_capture_required}
            && !$policy->{selected_strategy}{historical_sample_reuse_allowed};
    my $capture = $policy->{capture_contract};
    confess "capture plan publication contract changed\n"
        unless ref($capture) eq 'HASH'
            && ($capture->{publication_base} // '') eq $PUBLICATION_BASE
            && ($capture->{publication_id} // '') eq $PUBLICATION_ID
            && ($capture->{schema} // '') eq $PUBLICATION_SCHEMA
            && ($capture->{profile_count} // 0) == @ROUTES
            && ($capture->{validation_records_per_profile} // 0) ==
                $VALIDATION_RECORDS
            && ($capture->{raw_measurement_records_per_profile} // 0) ==
                $RAW_MEASUREMENT_RECORDS
            && ($capture->{sample_exclusions_allowed} // -1) == 0
            && $capture->{current_revision_required}
            && $capture->{fresh_common_identity_required}
            && $capture->{exact_qualified_tool_required_when_applicable}
            && $capture->{atomic_publication_required}
            && $capture->{same_volume_cleanup_required}
            && !$capture->{historical_artifact_substitution_allowed};
    confess "capture plan selected profile inventory changed\n"
        unless ref($policy->{selected_profiles}) eq 'ARRAY'
            && @{$policy->{selected_profiles}} == @ROUTES;
    my %seen;
    for my $index (0 .. $#ROUTES) {
        my $selected = $policy->{selected_profiles}[$index];
        _exact_keys(
            $selected, $POLICY->selected_profile_keys,
            'capture plan selected profile',
        );
        confess "capture plan selected profile ordinal changed\n"
            unless ($selected->{ordinal} // 0) == $index + 1;
        confess "capture plan selected profile is duplicated\n"
            if $seen{$selected->{selection_key} // ''}++;
        my $derived_key = join '|', map { defined($_) ? $_ : '-' } (
            @{$selected}{@COORDINATE_KEYS},
        );
        confess "capture plan selected profile key disagrees with coordinates\n"
            unless ($selected->{selection_key} // '') eq $derived_key;
        confess "capture plan selected profile order changed\n"
            unless ($selected->{selection_key} // '') eq
                $ROUTES[$index]{selection_key};
    }
}

sub _validate_plan($plan) {
    _exact_keys($plan, \@REPORT_KEYS, 'capture plan');
    confess "capture plan schema is invalid\n"
        unless ($plan->{schema} // '') eq $SCHEMA
            && ($plan->{schema_version} // 0) == 2;
    my $projection = _clone($plan);
    my $identity = delete $projection->{plan_identity};
    $projection->{plan_identity} = undef;
    confess "capture plan identity is invalid\n"
        unless defined($identity)
            && $identity eq 'regression-promotion-capture-plan/'
                . sha256_hex(_canonical_json($projection));
    confess "capture plan cardinality is invalid\n"
        unless $plan->{worker_count} == @ROUTES
            && $plan->{controller_invocations_per_worker} ==
                $CONTROLLER_INVOCATIONS
            && $plan->{total_validation_records} == 11
            && $plan->{total_raw_measurement_records} == 33
            && $plan->{total_controller_invocations} == 44
            && ref($plan->{entries}) eq 'ARRAY'
            && @{$plan->{entries}} == @ROUTES;
    my (%selection, %publication);
    for my $index (0 .. $#{$plan->{entries}}) {
        my $entry = $plan->{entries}[$index];
        _exact_keys($entry, \@ENTRY_KEYS, 'capture plan entry');
        _exact_keys(
            $entry->{coordinates}, \@COORDINATE_KEYS,
            'capture plan coordinates',
        );
        _exact_keys(
            $entry->{provider_requirement}, \@PROVIDER_KEYS,
            'capture plan provider requirement',
        );
        _exact_keys(
            $entry->{report_coordinate_authority},
            \@REPORT_COORDINATE_AUTHORITY_KEYS,
            'capture plan report-coordinate authority',
        );
        _exact_keys(
            $entry->{applicability_requirement}, \@APPLICABILITY_KEYS,
            'capture plan applicability requirement',
        );
        confess "capture plan entry order is invalid\n"
            unless $entry->{ordinal} == $index + 1
                && $entry->{worker_ordinal} == $entry->{ordinal};
        confess "capture plan entry selection is duplicated\n"
            if $selection{$entry->{selection_key}}++;
        confess "capture plan publication coordinate is duplicated\n"
            if $publication{$entry->{publication_relative_path}}++;
        confess "capture plan publication coordinate is invalid\n"
            unless $entry->{publication_relative_path} =~
                m{\A[.]artifacts/qualification/vial-scale/v2/
                    regression-promotion-corpus-v1/profiles/
                    [0-9]{2}-[0-9a-f]{64}/measurement-report[.]json\z}x
                && $entry->{publication_relative_path} !~ m{(?:\A|/)[.][.](?:/|\z)};
        confess "capture plan record sequence is invalid\n"
            unless $entry->{validation_records} == $VALIDATION_RECORDS
                && $entry->{raw_measurement_records} ==
                    $RAW_MEASUREMENT_RECORDS
                && $entry->{controller_invocations} ==
                    $CONTROLLER_INVOCATIONS;
        confess "capture plan repository-root binding is invalid\n"
            unless $entry->{repository_root_binding} eq
                $REPOSITORY_ROOT_BINDING;
        my $report_authority = _clone(
            $entry->{report_coordinate_authority},
        );
        my $report_authority_identity =
            $report_authority->{authority_identity};
        $report_authority->{authority_identity} = undef;
        my $report_authority_digest =
            sha256_hex(_canonical_json($report_authority));
        confess "capture plan report-coordinate authority is invalid\n"
            unless defined($report_authority_identity)
                && !ref($report_authority_identity)
                && $report_authority_identity eq
                    'report-coordinate-authority/'
                        . $report_authority_digest
                && $report_authority_digest eq
                    $ROUTES[$index]{report_coordinates_digest};
        for my $key (qw(family level primary_axis)) {
            confess "capture plan report coordinate '$key' is invalid\n"
                unless defined($report_authority->{$key})
                    && !ref($report_authority->{$key})
                    && length($report_authority->{$key});
        }
        for my $key (qw(family level backend_profile)) {
            confess "capture plan selection/report coordinate '$key' disagrees\n"
                unless _canonical_json($entry->{coordinates}{$key}) eq
                    _canonical_json($report_authority->{$key});
        }
        if (defined $entry->{coordinates}{primary_axis}) {
            confess "capture plan selection/report coordinate 'primary_axis' disagrees\n"
                unless $entry->{coordinates}{primary_axis} eq
                    $report_authority->{primary_axis};
        }
        else {
            confess "capture plan nullable selection axis aliases report coordinates\n"
                unless length($report_authority->{primary_axis});
        }
    }
    confess "capture plan nonclaims changed\n"
        unless _canonical_json($plan->{explicit_nonclaims}) eq
            _canonical_json(\@NONCLAIMS);
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @{$args} == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    my %allowed = map { $_ => 1 } @{$keys};
    for my $key (keys %{$args->[0]}) {
        confess "$method received unknown key '$key'\n"
            unless $allowed{$key};
    }
    for my $key (@{$keys}) {
        confess "$method is missing '$key'\n"
            unless exists $args->[0]{$key};
    }
    return $args->[0];
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be a hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @{$keys};
    for my $key (keys %{$value}) {
        confess "$label contains unknown key '$key'\n"
            unless $expected{$key};
    }
    for my $key (@{$keys}) {
        confess "$label is missing '$key'\n"
            unless exists $value->{$key};
    }
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
