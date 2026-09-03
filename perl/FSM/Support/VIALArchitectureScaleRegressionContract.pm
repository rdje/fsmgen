package FSM::Support::VIALArchitectureScaleRegressionContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_vial_architecture_scale_regression_contract
    vial_architecture_scale_regression_contract_keys
    vial_architecture_scale_regression_contract_source
);

my @PROFILE_ROWS = (
    [
        1,
        'semantic_bridge|semantic_catalog_v1|gate_candidate_v1|actions|-',
        'workload/6e503f6fa16c2e1399527ec657d8116ab707b04be36f9f3ad0b82a80ab80ab79',
        'regression-promotion-correctness/d75f0c1ddaebe200658a67168338ce6588db820b4dd957422ede8d1162642ee7',
        'regression-promotion-environment/655afa0ed64549afea6487d4a01a9e95e6c372623b0fb4a2a9eb2a8d50b82a1b',
        'not_applicable', undef, undef, undef,
        2_000_000_000, 2_000_000_000, 268_435_456,
    ],
    [
        2,
        'semantic_bridge|bridge_fanout_v1|gate_candidate_v1|backend_bindings|-',
        'workload/a3abcce7b47eb76169f03a56c7e91743f54358749365e6d3e122946ac6c9f09e',
        'regression-promotion-correctness/39a8343df087dd807901982581db70f776fd50098f0f1974314e421d67de33d0',
        'regression-promotion-environment/655afa0ed64549afea6487d4a01a9e95e6c372623b0fb4a2a9eb2a8d50b82a1b',
        'not_applicable', undef, undef, undef,
        18_325_000_000, 18_165_000_000, 671_088_640,
    ],
    [
        3,
        'execution_checking|execution_graph_v1|gate_candidate_v1|bindings|-',
        'workload/bdce8fb3b7b6c1fabacaec3366983b7bf20ce739cdca0afd1eba986fbd2c4555',
        'regression-promotion-correctness/4aad6bbc52e15999dec218a8027c5528cfbf675276dafa0f82fe1f5844c61ae8',
        'regression-promotion-environment/655afa0ed64549afea6487d4a01a9e95e6c372623b0fb4a2a9eb2a8d50b82a1b',
        'not_applicable', undef, undef, undef,
        31_479_000_000, 31_395_000_000, 1_325_400_064,
    ],
    [
        4,
        'execution_checking|checking_state_v1|gate_candidate_v1|random_occurrences|-',
        'workload/9f06f3b03d0e442568f5deeca3473eec000e50b6f0b7992f864a4435eeab7b5f',
        'regression-promotion-correctness/f8a5352eb1291db35668af8605e20b4eeba45d11bfebbd2f34bd2334394dc27f',
        'regression-promotion-environment/655afa0ed64549afea6487d4a01a9e95e6c372623b0fb4a2a9eb2a8d50b82a1b',
        'not_applicable', undef, undef, undef,
        34_683_000_000, 34_755_000_000, 1_040_187_392,
    ],
    [
        5,
        'backend_emission|backend_emission_v1|gate_candidate_v1|-|sv_portable_verilator',
        'workload/462af4c35f4917cfe919f0a06e38c6de97cf5988093487ebe6bddb3de2577b78',
        'regression-promotion-correctness/b979fa2268897960130a08d8ae45af8239052566e97c80453fc41251f50e2cff',
        'regression-promotion-environment/655afa0ed64549afea6487d4a01a9e95e6c372623b0fb4a2a9eb2a8d50b82a1b',
        'not_applicable', undef, undef, undef,
        35_836_000_000, 36_390_000_000, 1_090_519_040,
    ],
    [
        6,
        'backend_emission|backend_emission_v1|gate_candidate_v1|-|vhdl_portable_ghdl',
        'workload/eed62d48894eb05cfbc416b717e55cf464f6d660a9dfab2f88fd6ed6c12cd0ff',
        'regression-promotion-correctness/ae3d5a6cc0c9c317d27b2b478e1dcf46106b327b8c9fd02ebe74f3c36198dcea',
        'regression-promotion-environment/655afa0ed64549afea6487d4a01a9e95e6c372623b0fb4a2a9eb2a8d50b82a1b',
        'not_applicable', undef, undef, undef,
        24_033_000_000, 24_270_000_000, 922_746_880,
    ],
    [
        7,
        'backend_emission|backend_emission_v1|gate_candidate_v1|-|vhdl_osvvm_qualified',
        'workload/345d4bc51e1c8e8cf7e9cd459237cd5414af05197bf39a66b7993488bcc0aa7c',
        'regression-promotion-correctness/a229d9b517097e2a938ce9b0b3b906237b129ee1a27451955e29bdb46db7525a',
        'regression-promotion-environment/2d8870f070615efe8c763328015803d1c17e92793e8a1f250243d43d17537c6b',
        'repository_materialization', 'osvvm',
        'external_exact_osvvm_2026_05', undef,
        27_891_000_000, 25_305_000_000, 956_301_312,
    ],
    [
        8,
        'portable_runtime|runtime_stream_v1|gate_candidate_v1|-|sv_portable_verilator',
        'workload/c3abc507890d9c7c16d35be479ef765abe361d10569288b3c00758a6c5ebb17b',
        'regression-promotion-correctness/b95c62f169fd18720091879c8ff1bc08b93a8ddb919c0a0a2620b2e161f47cb8',
        'regression-promotion-environment/df3e02d4cf732527c9fac98eed233bbd8f48ae02524f9b24e9aeff8a178ec90c',
        'exact_tool_profile', 'verilator', 'qualified_verilator_5_046',
        'tool-profile/40de18b1140d38a1ea081f6e3ccdb26628b2e848a76a4e24c3c2a3bee56bc9c6',
        312_422_000_000, 298_875_000_000, 2_634_022_912,
    ],
    [
        9,
        'portable_vhdl_runtime|runtime_stream_v1|gate_candidate_v1|-|vhdl_portable_ghdl',
        'workload/5488d36362b411ed0c65c4c531071f500664365884b9775b11911eea095a4f5d',
        'regression-promotion-correctness/bc278bd00bb4801f293b0ba63e413f972005d87e44543a99425ee1eb6524004c',
        'regression-promotion-environment/334b75eeba880cb841eb2c661a299c080ca88ceb5ffe3d8ec2bb188e2b86bd9d',
        'exact_tool_profile', 'ghdl', 'qualified_ghdl_6_0_0_llvm_jit',
        'tool-profile/911258b328f62381fe59916c7d272d5f5cb5c31b6274e98b00bf3865ecf98191',
        46_812_000_000, 46_515_000_000, 1_157_627_904,
    ],
    [
        10,
        'osvvm_runtime|runtime_stream_v1|gate_candidate_v1|-|vhdl_osvvm_qualified',
        'workload/4cb12e908f42e55b90fc29a85954f6840564bc35514e08c14fe288833bbd93f7',
        'regression-promotion-correctness/c41a8f1049532e3735d3c969223a9007f4b6440b8daa28e6294e1252521e74b3',
        'regression-promotion-environment/1ae69b067e1b302f23cf96a8c6b35bdc2d06d5e403fd8ad8e79d498dc0c32024',
        'exact_tool_profile', 'ghdl',
        'qualified_osvvm_2026_05_ghdl_6_0_0_llvm_jit',
        'tool-profile/cb9962d5707404479548b6f837c908a76b1316d08251828324023d3560be46c6',
        194_013_000_000, 176_235_000_000, 1_694_498_816,
    ],
    [
        11,
        'balanced_portable|balanced_portable_v1|gate_candidate_v1|-|sv_portable_verilator',
        'workload/59442ebd7cf0f6eb29b48bb6b0d0cf5f74f3e7df077627ba66d1b7c10a1c2743',
        'regression-promotion-correctness/e716e336c09364c0f16caaa34e8201b086c3c92ed0d45684a7e90cbbc9f6e108',
        'regression-promotion-environment/655afa0ed64549afea6487d4a01a9e95e6c372623b0fb4a2a9eb2a8d50b82a1b',
        'not_applicable', undef, undef, undef,
        429_258_000_000, 462_510_000_000, 4_177_526_784,
    ],
);

sub vial_architecture_scale_regression_contract_source {
    return 'FSM::Support::VIALArchitectureScaleRegressionContract';
}

sub vial_architecture_scale_regression_contract_keys {
    return [qw(
        schema_version status contract_source capability
        implementation_entrypoints schemas evidence
        qualified_reference_environment topology profiles
        performance_applicability cadence latest_result cleanup
        supported_claim explicit_nonclaims guidance
    )];
}

sub build_vial_architecture_scale_regression_contract {
    die "build_vial_architecture_scale_regression_contract accepts no arguments\n"
        if @_;

    my @profiles = map {
        my (
            $ordinal, $selection_key, $workload_identity,
            $correctness_projection_identity, $environment_identity,
            $provider_kind, $logical_name, $provider_identity,
            $tool_profile_identity, $wall_time_ns, $cpu_time_ns,
            $peak_tree_rss_bytes,
        ) = @{$_};
        {
            ordinal => $ordinal,
            selection_key => $selection_key,
            workload_identity => $workload_identity,
            correctness_projection_identity =>
                $correctness_projection_identity,
            environment_identity => $environment_identity,
            provider_requirement => {
                external_verification_tool =>
                    $provider_kind eq 'exact_tool_profile'
                        ? JSON::PP::true : JSON::PP::false,
                kind => $provider_kind,
                logical_name => $logical_name,
                provider_identity => $provider_identity,
                tool_profile_identity => $tool_profile_identity,
            },
            qualified_budget => {
                status => 'qualified_unpublished',
                formula_authority => 'decision-0056',
                wall_time_ns => $wall_time_ns,
                cpu_time_ns => $cpu_time_ns,
                peak_tree_rss_bytes => $peak_tree_rss_bytes,
            },
        }
    } @PROFILE_ROWS;

    return {
        schema_version => 1,
        status => 'shipped_bounded_regression_gate',
        contract_source =>
            vial_architecture_scale_regression_contract_source(),
        capability => 'vial.architecture_scale.regression_gate.v1',
        implementation_entrypoints => [
            './bin/ci-regression vial-gate [--no-book]',
            './bin/ci-regression vial-gate --dry-run [--no-book]',
            './bin/ci-regression [--no-book]',
            'scripts/run_with_ram_guard.sh -- scripts/run_vial_regression_promotion_gate.pl --validate-result',
            'perl scripts/verify_vial_regression_promotion_evidence_transport.pl',
        ],
        schemas => {
            policy =>
                'fsmgen.vial_architecture_scale_regression_promotion_policy.v1',
            corpus =>
                'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1',
            qualification =>
                'fsmgen.vial_architecture_scale_regression_promotion_qualification.v1',
            qualification_publication =>
                'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_publication_report.v1',
            gate_contract =>
                'fsmgen.vial_architecture_scale_regression_promotion_gate_contract.v1',
            gate_profile_result =>
                'fsmgen.vial_architecture_scale_regression_promotion_gate_profile_result.v1',
            gate_result =>
                'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1',
            evidence_transport =>
                'fsmgen.vial_regression_promotion_gate_evidence_transport.v1',
        },
        evidence => {
            transport_relative_path =>
                'vial/qualification/regression_promotion_gate/evidence-v1',
            transport_identity =>
                'regression-promotion-gate-evidence-transport/3b4c486e8e3f853f626d85d2abc713846d0594230d922913c8655be3f682bbc6',
            corpus_identity =>
                'regression-promotion-corpus/ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505',
            corpus_publication_identity =>
                'regression-promotion-corpus-publication/865c5cce3deee3eaaca9b66cd5d7f007a6e10b6423ac7d5dff2dc7484cd8432e',
            corpus_file_set_sha256 =>
                'dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f',
            capture_revision =>
                '155aa22ea3099642eb6b7f5de81ea03633e72bcb',
            qualification_identity =>
                'regression-promotion-qualification/d8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97',
            qualification_publication_identity =>
                'regression-promotion-budget-qualification-publication/1c2a3832b2b4163e1a6a8124feff2b452f8522c2929098447f3903115ad2945f',
            qualification_file_set_sha256 =>
                '28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095',
            qualification_report_identity =>
                'regression-promotion-budget-qualification-report/0da2324912a8ffcaa0c167e75a5ecac87911eb3bc44f6d8c2b128d07e869622c',
            qualification_publisher_revision =>
                '8667f766cfb5721600c466568b432ac4432255f7',
            performance_applicability_identity =>
                'regression-promotion-performance-applicability/b5976719c47be42095c2bf90e93c2f0bd5e68fff93bb7cd07adbf1172dba8018',
        },
        qualified_reference_environment => {
            host_profile => {
                os_name => 'Darwin',
                os_version => '25.5.0',
                architecture => 'arm64',
                cpu_model => 'Apple M4 Pro',
                logical_core_count => 12,
                physical_memory_bytes => 25_769_803_776,
                filesystem_type => 'apfs',
                measurement_implementation =>
                    'fsmgen.perl_process_tree_sampler.v1',
            },
            resource_guard => {
                active => JSON::PP::true,
                enforcement => 'repository_ram_guard',
                host_max_percent => 88,
                single_descendant_max_mib => 4096,
                sampler_interval_ns => 250_000_000,
            },
            provider_profiles => [
                {
                    kind => 'repository_materialization',
                    logical_name => 'osvvm',
                    provider_identity => 'external_exact_osvvm_2026_05',
                    version => '2026.05',
                    revision =>
                        '2f7c391051dfb11890fa4bdbda9918d1db492250',
                },
                {
                    kind => 'exact_tool_profile',
                    logical_name => 'verilator',
                    provider_identity => 'qualified_verilator_5_046',
                    version => '5.046',
                    tool_profile_identity =>
                        'tool-profile/40de18b1140d38a1ea081f6e3ccdb26628b2e848a76a4e24c3c2a3bee56bc9c6',
                },
                {
                    kind => 'exact_tool_profile',
                    logical_name => 'ghdl',
                    provider_identity => 'qualified_ghdl_6_0_0_llvm_jit',
                    version => '6.0.0-llvm-jit',
                    revision =>
                        'e589c698c351369ac5bcfe7abe1f1152ac5d4727',
                    tool_profile_identity =>
                        'tool-profile/911258b328f62381fe59916c7d272d5f5cb5c31b6274e98b00bf3865ecf98191',
                },
                {
                    kind => 'exact_tool_profile',
                    logical_name => 'ghdl',
                    provider_identity =>
                        'qualified_osvvm_2026_05_ghdl_6_0_0_llvm_jit',
                    version => '6.0.0-llvm-jit+OSVVM-2026.05',
                    tool_profile_identity =>
                        'tool-profile/cb9962d5707404479548b6f837c908a76b1316d08251828324023d3560be46c6',
                },
            ],
        },
        topology => {
            profile_workers => 11,
            validation_records_per_profile => 1,
            raw_measurement_records_per_profile => 3,
            controller_invocations_per_profile => 4,
            total_validation_records => 11,
            total_raw_measurement_records => 33,
            total_controller_invocations => 44,
            sample_exclusions => 0,
        },
        profiles => \@profiles,
        performance_applicability => {
            schema =>
                'fsmgen.vial_architecture_scale_regression_performance_applicability.v1',
            schema_version => 1,
            refines_policy_schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_policy.v1',
            applicability_identity =>
                'regression-promotion-performance-applicability/b5976719c47be42095c2bf90e93c2f0bd5e68fff93bb7cd07adbf1172dba8018',
            evidence_revision_role =>
                'immutable_qualification_provenance_only',
            exact_deterministic_fields => [qw(
                selection_key workload_identity
                correctness_projection_identity
            )],
            exact_environment_fields => [qw(
                host_profile tool_profile resource_guard provider_status
            )],
            matching_later_revision =>
                'performance_enforcement_eligible_after_correctness',
            deterministic_mismatch =>
                'correctness_rejects_before_performance',
            exact_environment =>
                'maximum_each_metric_inclusive_qualified_budget_pass_or_fail',
            environment_mismatch =>
                'correctness_required_performance_informational',
            unavailable_exact_provider => 'unavailable_not_pass',
            present_provider_drift => 'fail',
            recalibration =>
                'owned_version_replacement_with_old_new_evidence',
        },
        cadence => {
            ordinary_slice_commit => 'focused_checks_only',
            selected_important_step =>
                './bin/ci-regression vial-gate [--no-book]',
            full_pre_push => './bin/ci-regression [--no-book]',
            hosted_ci =>
                'required_unsharded_correctness_and_applicability_gate',
            performance_override => 'none',
        },
        latest_result => {
            publication_relative_path =>
                '.artifacts/qualification/vial-scale/v2/regression-promotion-gate-v1/current/regression-promotion-gate-result.json',
            publication_mode => 'atomic_replaceable_latest_observation',
            schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1',
            maximum_bytes => 1_048_576,
            producer_free_validation =>
                'scripts/run_with_ram_guard.sh -- scripts/run_vial_regression_promotion_gate.pl --validate-result',
            qualification_evidence => JSON::PP::false,
        },
        cleanup => {
            profile_report_spools => 'anonymous_unlinked_before_worker_exit',
            process_residue => 'forbidden',
            staging_residue => 'forbidden',
            evidence_cleanup => 'receipt_owned_exact_roots_only',
            latest_result_preserved => JSON::PP::true,
        },
        supported_claim => {
            scope => 'eleven_exact_qualified_gate_candidate_profiles',
            correctness => 'required_for_every_available_profile',
            performance => 'enforced_only_on_exact_qualified_environment',
            provider_absence => 'unavailable_not_pass',
            unmatched_environment =>
                'correctness_required_performance_informational',
            support_promotion => JSON::PP::false,
            capacity_claim => JSON::PP::false,
        },
        explicit_nonclaims => [qw(
            architecture_scale_capacity
            whole_product_big
            whole_product_really_big
            multi_unit
            multi_domain
            mixed_language
            native_uvm_runtime
            full_language
            synthesis
            arbitrary_tool_capacity
            support_promotion
            general_cross_backend_parity
            unmatched_host_performance_enforcement
            unavailable_provider_pass
        )],
        guidance => [
            'Treat this record as discovery for the shipped bounded regression gate, not as evidence that an arbitrary VIAL design or tool environment meets a capacity target.',
            'Deterministic workload and correctness identities must match before any timing or memory comparison; a deterministic mismatch fails on every host.',
            'Only the exact qualified host, tool, guard, and provider tuple activates inclusive performance budgets; other hosts retain correctness with informational performance.',
            'The latest gate result is a replaceable observation and never calibration evidence. Recalibration requires a separately owned version with old and new immutable evidence.',
        ],
    };
}

1;
