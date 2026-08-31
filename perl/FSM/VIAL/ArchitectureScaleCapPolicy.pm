package FSM::VIAL::ArchitectureScaleCapPolicy;

use v5.20;
use strict;
use warnings;

use Carp qw(confess);
use Exporter 'import';
use Scalar::Util qw(blessed);

use FSM::Support::HIALVIALBridgeContract qw(
    build_hial_vial_bridge_contract
);
use FSM::Support::VIALExecutionContract qw(
    build_vial_execution_contract
);
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::BackendEmissionAuthority qw(
    backend_emission_profile_authorities
);
use FSM::VIAL::Parser;
use FSM::VIAL::SemanticBuilder;

our @EXPORT_OK = qw(
    assert_architecture_scale_cap_policy
    build_architecture_scale_cap_policy
);

my $SCHEMA = 'fsmgen.vial_architecture_scale_cap_policy.v1';
my $DECISION =
    'docs/decisions/0093-architecture-scale-caps-are-component-ceilings-with-explicit-route-authority.md';

my $SELECTION = {
    numeric_caps => 'retain_all_selected_component_ceilings',
    workload_levels => 'unchanged',
    route_truth =>
        'publish_component_ceiling_earliest_authority_and_measured_boundary',
    contract_repair =>
        'classify_component_scope_and_expose_route_dependencies',
    early_enforcement =>
        'reject_before_avoidable_same_layer_materialization',
    accepted_profiles => 'byte_identical',
    lower_layers => 'unchanged_without_separate_qualification',
};

my $AXIS_GROUPS = {
    semantic_catalog_v1 => {
        imports => 'semantic_parser_admission',
        declarations => 'semantic_declaration_cardinality',
        fixtures => 'semantic_declaration_cardinality',
        actions => 'semantic_action_cardinality',
        parallel_depth => 'semantic_action_shape',
        fibers_per_parallel => 'semantic_action_shape',
        scalar_or_list_length => 'semantic_type_shape',
        record_fields => 'semantic_type_shape',
        aggregate_depth => 'semantic_type_shape',
        scoreboard_capacity => 'semantic_service_scalar',
        coverage_bins => 'semantic_service_scalar',
        literal_repeat_count => 'semantic_repeat_layering',
        source_bytes_per_source => 'semantic_parser_admission',
        source_bytes_combined => 'semantic_parser_admission',
    },
    bridge_fanout_v1 => {
        selected_units => 'bridge_profile_cardinality',
        selected_domains => 'bridge_profile_cardinality',
        configurations => 'bridge_normalized_collections',
        types => 'bridge_normalized_collections',
        endpoints => 'bridge_normalized_collections',
        transactions => 'bridge_normalized_collections',
        events => 'bridge_normalized_collections',
        observations => 'bridge_normalized_collections',
        probes => 'bridge_normalized_collections',
        backend_bindings => 'bridge_normalized_collections',
        retained_residue_records => 'bridge_normalized_collections',
        source_map_records => 'bridge_normalized_collections',
        serialized_manifest_bytes => 'bridge_serialized_manifest',
    },
    execution_graph_v1 => {
        selected_fixtures => 'execution_profile_selection',
        selected_units => 'execution_profile_selection',
        selected_domains => 'execution_profile_selection',
        scenarios => 'execution_profile_selection',
        operations_per_scenario => 'execution_operation_cardinality',
        operations_total => 'execution_operation_cardinality',
        fibers_total => 'execution_fiber_cardinality',
        simultaneously_live_fibers => 'execution_fiber_cardinality',
        bindings => 'execution_route_collections',
        execution_types => 'execution_route_collections',
        source_map_records => 'execution_route_collections',
        random_attempts => 'execution_random_attempts',
        serialized_plan_bytes => 'execution_serialized_plan',
    },
    checking_state_v1 => {
        model_instances => 'checking_models',
        scalar_model_state_cells => 'checking_models',
        scoreboard_instances => 'checking_scoreboards',
        scoreboard_capacity => 'checking_scoreboards',
        coverpoints => 'checking_coverage',
        bins_and_cross_tuples => 'checking_coverage',
        faults => 'checking_faults',
        random_occurrences => 'checking_randomness',
    },
    backend_emission_v1 => {
        artifact_graph => 'backend_artifact_graph',
    },
    runtime_stream_v1 => {
        runtime_trace_records => 'runtime_stream_envelopes',
    },
};

my $GROUPS = {
    semantic_parser_admission => _group(
        'FSM::VIAL::Parser', 'parse_validate', ['VIAL_LIMIT_ERROR'],
        'source-or-import semantic path',
        'source_bytes_before_lex_and_direct_import_fanout_before_recursion',
        'no_semantic_ir_or_artifact',
        'retain_early_preflight_and_per_edge_terminal_defense',
        '.17.4.2', [
            't/1601-vial-architecture-scale-semantic-catalog.t',
            't/1687-vial-parser-direct-import-cap-order.t',
            't/1693-vial-parser-source-byte-cap-order.t',
        ],
    ),
    semantic_declaration_cardinality => _group(
        'FSM::VIAL::SemanticBuilder', 'parse_validate', ['VIAL_LIMIT_ERROR'],
        'package declaration collection',
        'per_section_before_later_section_shape_parsing',
        'no_semantic_ir_or_artifact',
        'retain_per_section_preflight_before_dependent_parsing',
        '.17.4.2', [
            't/1601-vial-architecture-scale-semantic-catalog.t',
            't/1689-vial-semantic-declaration-cap-order.t',
        ],
    ),
    semantic_action_cardinality => _group(
        'FSM::VIAL::SemanticBuilder', 'parse_validate', ['VIAL_LIMIT_ERROR'],
        'scenario semantic path',
        'capacity_reserved_before_action_form_and_repeat_copy_multiplication',
        'no_semantic_ir_or_artifact',
        'retain_early_reservation_and_terminal_defense',
        '.17.4.2', [
            't/1601-vial-architecture-scale-semantic-catalog.t',
            't/1686-vial-semantic-action-cap-order.t',
        ],
    ),
    semantic_action_shape => _group(
        'FSM::VIAL::SemanticBuilder', 'parse_validate', ['VIAL_LIMIT_ERROR'],
        'action or fiber semantic path',
        'parallel_depth_and_fiber_count_before_join_value_resolution',
        'no_semantic_ir_or_artifact',
        'retain_shape_preflight_before_semantic_resolution',
        '.17.4.2', [
            't/1601-vial-architecture-scale-semantic-catalog.t',
            't/1688-vial-semantic-parallel-fiber-cap-order.t',
        ],
    ),
    semantic_type_shape => _group(
        'FSM::VIAL::SemanticBuilder', 'parse_validate', ['VIAL_LIMIT_ERROR'],
        'type semantic path',
        'length_field_count_and_depth_before_inner_type_resolution',
        'no_semantic_ir_or_artifact',
        'retain_shape_preflight_before_recursive_resolution',
        '.17.4.2', [
            't/1601-vial-architecture-scale-semantic-catalog.t',
            't/1692-vial-semantic-type-shape-cap-order.t',
        ],
    ),
    semantic_service_scalar => _group(
        'FSM::VIAL::SemanticBuilder', 'parse_validate', ['VIAL_LIMIT_ERROR'],
        'service declaration scalar path',
        'before_dependent_reference_resolution',
        'no_semantic_ir_or_artifact',
        'retain_scalar_preflight_before_dependent_resolution',
        '.17.4.2', [
            't/1601-vial-architecture-scale-semantic-catalog.t',
            't/1690-vial-semantic-scoreboard-capacity-order.t',
            't/1691-vial-semantic-cross-max-bins-order.t',
        ],
    ),
    semantic_repeat_layering => _group(
        'FSM::VIAL::SemanticBuilder', 'parse_validate', ['VIAL_LIMIT_ERROR'],
        'repeat count or enclosing scenario path',
        'compact_body_then_bounded_copy_reservation',
        'no_semantic_ir_or_artifact',
        'retain_intrinsic_repeat_ceiling_and_overflow_safe_action_layering',
        '.17.4.2', [
            't/1601-vial-architecture-scale-semantic-catalog.t',
            't/1686-vial-semantic-action-cap-order.t',
            'docs/decisions/0059-vial-literal-repeat-scale-is-currently-dominated-by-expanded-actions.md',
        ],
    ),
    bridge_profile_cardinality => _group(
        'FSM::Support::HIALVIALBridgeContract', 'bridge',
        ['HIAL_VIAL_BRIDGE_CAPABILITY_ERROR'], 'actor profile semantic path',
        'before_normalized_manifest_construction', 'no_manifest_or_report',
        'verify_existing_early_boundary', '.17.4.3',
        ['t/1602-vial-architecture-scale-bridge-fanout.t'],
    ),
    bridge_normalized_collections => _group(
        'FSM::Support::HIALVIALBridgeContract', 'bridge',
        ['HIAL_VIAL_BRIDGE_LIMIT_ERROR'], 'normalized manifest collection path',
        'raw_collections_before_normalization_distinct_types_and_source_map_entries_before_materialization_remaining_checks_terminal',
        'no_manifest_or_report',
        'move_same_layer_check_before_avoidable_materialization', '.17.4.3',
        [
            't/1602-vial-architecture-scale-bridge-fanout.t',
            't/1694-hial-vial-bridge-configuration-cap-order.t',
            't/1695-hial-vial-bridge-endpoint-cap-order.t',
            't/1696-hial-vial-bridge-observation-cap-order.t',
            't/1697-hial-vial-bridge-probe-cap-order.t',
            't/1698-hial-vial-bridge-type-cap-order.t',
            't/1699-hial-vial-bridge-transaction-cap-order.t',
            't/1700-hial-vial-bridge-event-cap-order.t',
            't/1701-hial-vial-bridge-residue-cap-order.t',
            't/1702-hial-vial-bridge-backend-binding-cap-order.t',
            't/1703-hial-vial-bridge-source-map-cap-order.t',
        ],
    ),
    bridge_serialized_manifest => _group(
        'FSM::Support::HIALVIALBridgeContract', 'bridge',
        ['HIAL_VIAL_BRIDGE_LIMIT_ERROR'], 'manifest root path',
        'after_canonical_encoding', 'no_manifest_or_report',
        'retain_terminal_canonical_byte_check', '.17.4.3',
        [
            't/1602-vial-architecture-scale-bridge-fanout.t',
            't/1704-hial-vial-bridge-serialized-manifest-terminal-authority.t',
        ],
    ),
    execution_profile_selection => _group(
        'FSM::Support::VIALExecutionContract', 'bind_plan',
        ['VIAL_EXECUTION_LIMIT_ERROR', 'VIAL_CAPABILITY_ERROR'],
        'invocation or bridge-profile path', 'before_execution_context_build',
        'no_execution_ir_plan_or_replay',
        'classify_layered_route_and_harden_local_check', '.17.4.4',
        ['t/1616-vial-architecture-scale-execution-scenario-qualification.t'],
    ),
    execution_operation_cardinality => _group(
        'FSM::Support::VIALExecutionContract', 'bind_plan',
        ['VIAL_EXECUTION_LIMIT_ERROR', 'VIAL_LIMIT_ERROR'],
        'scenario or operation-graph path',
        'compact_total_preflight_and_per_scenario_terminal_defense',
        'no_execution_ir_plan_or_replay',
        'retain_preflight_and_move_remaining_same_layer_checks', '.17.4.4',
        [
            't/1620-vial-architecture-scale-execution-operation-limit.t',
            't/1626-vial-architecture-scale-execution-total-operation-limit.t',
        ],
    ),
    execution_fiber_cardinality => _group(
        'FSM::Support::VIALExecutionContract', 'bind_plan',
        ['VIAL_EXECUTION_LIMIT_ERROR'], 'operation-graph fiber path',
        'after_operation_graph_materialization', 'no_execution_ir_plan_or_replay',
        'move_same_layer_check_before_avoidable_materialization', '.17.4.4',
        [
            't/1624-vial-architecture-scale-execution-live-fiber-limit.t',
            't/1625-vial-architecture-scale-execution-total-fiber-limit.t',
        ],
    ),
    execution_route_collections => _group(
        'FSM::Support::VIALExecutionContract', 'bind_plan',
        ['VIAL_EXECUTION_LIMIT_ERROR', 'HIAL_VIAL_BRIDGE_LIMIT_ERROR'],
        'binding, type-table, source-map, bridge, or plan path',
        'mixed_terminal_and_lower_layer_authority',
        'no_execution_ir_plan_or_replay',
        'classify_layered_route_and_harden_local_check', '.17.4.4',
        [
            't/1607-vial-architecture-scale-execution-source-maps.t',
            't/1627-vial-architecture-scale-execution-type-qualification.t',
            't/1628-vial-architecture-scale-execution-binding-limits.t',
        ],
    ),
    execution_random_attempts => _group(
        'FSM::Support::VIALExecutionContract', 'bind_plan',
        ['VIAL_RANDOM_EXHAUSTED'], 'random choice semantic path',
        'bounded_generation_before_plan_materialization',
        'no_partial_random_decision_execution_ir_or_plan',
        'verify_existing_early_boundary', '.17.4.4',
        [
            't/1614-vial-architecture-scale-execution-random-limit.t',
            't/1615-vial-architecture-scale-execution-random-over-limit.t',
        ],
    ),
    execution_serialized_plan => _group(
        'FSM::Support::VIALExecutionContract', 'bind_plan',
        ['VIAL_EXECUTION_LIMIT_ERROR'], 'plan root path',
        'preflight_projection_plus_terminal_defense',
        'no_execution_ir_plan_or_replay',
        'retain_preflight_and_terminal_defense', '.17.4.4',
        ['t/1612-vial-architecture-scale-execution-plan-over-limit.t'],
    ),
    checking_models => _group(
        'FSM::Support::VIALExecutionContract', 'bind_plan',
        ['VIAL_EXECUTION_LIMIT_ERROR'], 'models path',
        'after_model_normalization', 'no_execution_ir_plan_or_checking_result',
        'move_same_layer_check_before_avoidable_materialization', '.17.4.5',
        ['t/1630-vial-architecture-scale-checking-models.t'],
    ),
    checking_scoreboards => _group(
        'FSM::Support::VIALExecutionContract', 'parse_validate_or_bind_plan',
        ['VIAL_LIMIT_ERROR', 'VIAL_EXECUTION_LIMIT_ERROR'],
        'scoreboard declaration or normalized path',
        'scalar_semantic_admission_then_instance_normalization',
        'no_execution_ir_plan_or_checking_result',
        'move_same_layer_check_before_avoidable_materialization', '.17.4.5',
        ['t/1631-vial-architecture-scale-checking-scoreboards.t'],
    ),
    checking_coverage => _group(
        'FSM::Support::VIALExecutionContract', 'parse_validate_or_bind_plan',
        ['VIAL_LIMIT_ERROR', 'VIAL_EXECUTION_LIMIT_ERROR'],
        'coverage declaration, source, or normalized path',
        'mixed_semantic_normalization_and_lower_source_authority',
        'no_execution_ir_plan_or_checking_result',
        'classify_layered_route_and_harden_local_check', '.17.4.5',
        ['t/1632-vial-architecture-scale-checking-coverage.t'],
    ),
    checking_faults => _group(
        'FSM::Support::VIALExecutionContract', 'bind_plan',
        ['VIAL_EXECUTION_LIMIT_ERROR'], 'faults path',
        'after_fault_normalization', 'no_execution_ir_plan_or_checking_result',
        'move_same_layer_check_before_avoidable_materialization', '.17.4.5',
        ['t/1633-vial-architecture-scale-checking-faults.t'],
    ),
    checking_randomness => _group(
        'FSM::Support::VIALExecutionContract', 'bind_plan',
        ['VIAL_EXECUTION_LIMIT_ERROR'], 'random decisions or plan path',
        'count_then_plan_preflight_before_decision_materialization',
        'no_execution_ir_plan_replay_or_checking_result',
        'retain_preflight_and_move_remaining_same_layer_checks', '.17.4.5',
        ['t/1634-vial-architecture-scale-checking-random-replay.t'],
    ),
    backend_artifact_graph => _group(
        'FSM::VIAL::BackendEmissionAuthority', 'emit',
        ['profile_specific_backend_limit_error'],
        'backend artifact graph or generated source path',
        'profile_specific_preflight_and_terminal_validation',
        'no_partial_final_artifact_graph',
        'retain_profile_specific_component_ceilings', '.17.4.6',
        ['t/1650-vial-architecture-scale-backend-emission-family-qualification.t'],
    ),
    runtime_stream_envelopes => _group(
        'FSM::Support::VIALExecutionContract', 'run',
        ['profile_specific_backend_or_tool_limit_error'],
        'runtime capture, trace, result, or artifact root path',
        'structural_preflight_then_shared_bounded_lifecycle',
        'no_partial_public_artifact_graph',
        'retain_profile_specific_component_ceilings', '.17.4.7',
        [
            't/1663-vial-architecture-scale-portable-runtime-materialization.t',
            't/1672-vial-architecture-scale-portable-vhdl-runtime-materialization.t',
            't/1676-vial-architecture-scale-osvvm-runtime-materialization.t',
        ],
    ),
};

my $INTERACTIONS = {
    'semantic_catalog_v1/literal_repeat_count' => _interaction(
        'expanded_action_ceiling', 'literal_repeat_ceiling', undef,
        'retain_both_component_ceilings_and_report_earliest',
        'docs/decisions/0059-vial-literal-repeat-scale-is-currently-dominated-by-expanded-actions.md',
    ),
    'bridge_fanout_v1/configurations' => _bridge_map_interaction(),
    'bridge_fanout_v1/types' => _bridge_map_interaction(),
    'bridge_fanout_v1/endpoints' => _bridge_map_interaction(),
    'bridge_fanout_v1/backend_bindings' => _bridge_map_interaction(),
    'bridge_fanout_v1/source_map_records' => _interaction(
        'serialized_manifest_byte_ceiling', 'source_map_record_ceiling', undef,
        'retain_both_component_ceilings_and_report_earliest',
        't/1602-vial-architecture-scale-bridge-fanout.t',
    ),
    'execution_graph_v1/selected_fixtures' => _execution_profile_interaction(),
    'execution_graph_v1/selected_units' => _execution_profile_interaction(),
    'execution_graph_v1/selected_domains' => _execution_profile_interaction(),
    'execution_graph_v1/operations_per_scenario' => _interaction(
        'serialized_plan_byte_ceiling', 'expanded_action_ceiling', undef,
        'retain_component_ceilings_and_preserve_levels',
        't/1620-vial-architecture-scale-execution-operation-limit.t',
    ),
    'execution_graph_v1/operations_total' => _interaction(
        'serialized_plan_byte_preflight', 'total_operation_ceiling', undef,
        'retain_component_ceilings_and_preserve_levels',
        't/1626-vial-architecture-scale-execution-total-operation-limit.t',
    ),
    'execution_graph_v1/fibers_total' => _interaction(
        'serialized_plan_byte_ceiling', 'total_fiber_ceiling', undef,
        'retain_component_ceilings_and_preserve_levels',
        't/1625-vial-architecture-scale-execution-total-fiber-limit.t',
    ),
    'execution_graph_v1/bindings' => _route_interaction(
        'bridge_event_and_manifest_authority',
        'docs/decisions/0072-an-unreachable-declared-cap-is-a-result-not-a-level-to-rewrite.md',
    ),
    'execution_graph_v1/execution_types' => _route_interaction(
        'parser_declaration_and_bridge_manifest_authority',
        'docs/decisions/0072-an-unreachable-declared-cap-is-a-result-not-a-level-to-rewrite.md',
    ),
    'execution_graph_v1/source_map_records' => _route_interaction(
        'serialized_plan_byte_authority',
        'docs/decisions/0072-an-unreachable-declared-cap-is-a-result-not-a-level-to-rewrite.md',
    ),
    'checking_state_v1/coverpoints' => _route_interaction(
        'parser_source_byte_authority',
        't/1632-vial-architecture-scale-checking-coverage.t',
    ),
    'checking_state_v1/random_occurrences' => _interaction(
        'serialized_plan_byte_preflight', 'random_occurrence_ceiling',
        'measured_compact_route_boundary',
        'retain_component_ceilings_and_preserve_levels',
        't/1634-vial-architecture-scale-checking-random-replay.t',
    ),
    'backend_emission_v1/artifact_graph' => _interaction(
        'profile_specific_earliest_authority',
        'profile_specific_first_representable_excess',
        'profile_specific_structural_boundary',
        'retain_profile_specific_component_ceilings',
        'docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md',
    ),
    'runtime_stream_v1/runtime_trace_records' => _interaction(
        'profile_specific_structural_or_complete_graph_byte_authority',
        'profile_specific_structural_or_capture_authority',
        'profile_specific_reachable_stream_boundary',
        'retain_component_ceilings_and_preserve_levels',
        'docs/decisions/0083-portable-systemverilog-runtime-scale-uses-authored-cycle-sampling-and-one-shared-staged-lifecycle.md',
    ),
};

my $NON_AXIS_ENVELOPES = {
    fixture_construction => _envelope(
        'fixture_safety_not_product_limit',
        'FSM::VIAL::ArchitectureScaleWorkload input_limits',
        'retain_and_never_publish_as_product_capacity', '.17.4.8',
        't/1600-vial-architecture-scale-workload-foundation.t',
    ),
    measurement_process_guard => _envelope(
        'measurement_safety_not_product_limit',
        'scripts/run_with_ram_guard.sh and decision 0056',
        'retain_and_invalidate_guard_trips', '.17.4.8',
        't/1656-vial-architecture-scale-measurement-foundation.t',
    ),
    backend_transcripts_and_timeouts => _envelope(
        'product_backend_envelope',
        'FSM::Support::VIALExecutionContract backend_limits',
        'retain_smaller_of_backend_and_measurement_timeout', '.17.4.7',
        't/1558-vial-verilator-run-integration.t',
    ),
    trace_result_and_public_artifact_graph => _envelope(
        'product_runtime_and_tooling_envelope',
        'VIAL trace validators, result producer, and tooling contract',
        'retain_and_reject_before_partial_publication', '.17.4.7',
        't/1663-vial-architecture-scale-portable-runtime-materialization.t',
    ),
    measurement_ipc_and_publication => _envelope(
        'evidence_transport_not_product_limit',
        'architecture-scale measurement matrix publishers',
        'retain_fail_closed_transport_and_atomic_publication', '.17.4.8',
        't/1684-vial-architecture-scale-calibration-closure-publication.t',
    ),
    same_volume_cleanup => _envelope(
        'project_data_lifecycle', 'decision 0056 and shared staged lifecycles',
        'retain_exact_owned_success_and_failure_cleanup', '.17.4.8',
        'scripts/check_project_data_locality.sh',
    ),
};

my @NONCLAIMS = qw(
    architecture_scale_capacity
    whole_product_big
    whole_product_really_big
    support_promotion
    performance_budget_promotion
    lower_layer_capacity_increase
    accepted_profile_change
);

sub build_architecture_scale_cap_policy {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my $backend = backend_emission_profile_authorities();
    my @backend_profiles = sort keys %{$catalog->{backend_profiles}};
    my @runtime_profiles = sort grep {
        $catalog->{backend_profiles}{$_}{runtime_eligible}
    } @backend_profiles;
    my $policy = {
        schema => $SCHEMA,
        schema_version => 1,
        decision => $DECISION,
        selection => _clone($SELECTION),
        axis_groups => _clone($AXIS_GROUPS),
        groups => _clone($GROUPS),
        interactions => _clone($INTERACTIONS),
        backend_profiles => {
            names => \@backend_profiles,
            authorities => $backend,
        },
        runtime_profiles => \@runtime_profiles,
        non_axis_envelopes => _clone($NON_AXIS_ENVELOPES),
        explicit_nonclaims => [@NONCLAIMS],
    };
    assert_architecture_scale_cap_policy($policy);
    return _clone($policy);
}

sub assert_architecture_scale_cap_policy {
    my ($policy) = @_;
    confess "architecture-scale cap policy must be one unblessed hash\n"
        unless @_ == 1 && ref($policy) eq 'HASH' && !blessed($policy);
    _assert_exact_keys($policy, [qw(
        schema schema_version decision selection axis_groups groups interactions
        backend_profiles runtime_profiles non_axis_envelopes explicit_nonclaims
    )], 'architecture-scale cap policy');
    confess "architecture-scale cap policy schema is unsupported\n"
        unless ($policy->{schema} // '') eq $SCHEMA
            && ($policy->{schema_version} // 0) == 1;
    confess "architecture-scale cap policy decision is unsupported\n"
        unless ($policy->{decision} // '') eq $DECISION;
    _assert_selection($policy->{selection});
    _assert_axis_and_group_coverage($policy);
    _assert_interactions($policy);
    _assert_profiles($policy);
    _assert_envelopes($policy->{non_axis_envelopes});
    _assert_declared_values();
    _assert_string_array($policy->{explicit_nonclaims}, 'explicit nonclaims');
    confess "architecture-scale cap policy explicit nonclaims contradict decision 0093\n"
        unless join("\0", @{$policy->{explicit_nonclaims}})
            eq join("\0", @NONCLAIMS);
    return 1;
}

sub _assert_selection {
    my ($selection) = @_;
    _assert_exact_keys($selection, [sort keys %$SELECTION], 'cap policy selection');
    for my $field (sort keys %$SELECTION) {
        confess "selection field '$field' contradicts decision 0093\n"
            unless defined($selection->{$field}) && !ref($selection->{$field})
                && $selection->{$field} eq $SELECTION->{$field};
    }
}

sub _assert_axis_and_group_coverage {
    my ($policy) = @_;
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my @catalog_axes;
    for my $family (sort keys %{$catalog->{families}}) {
        push @catalog_axes,
            map { "$family/$_" } sort keys %{$catalog->{families}{$family}{axes}};
    }
    my @policy_axes;
    confess "architecture-scale cap policy axis_groups must be one hash\n"
        unless ref($policy->{axis_groups}) eq 'HASH'
            && !blessed($policy->{axis_groups});
    for my $family (sort keys %{$policy->{axis_groups}}) {
        my $axes = $policy->{axis_groups}{$family};
        confess "architecture-scale cap policy family '$family' axes must be one hash\n"
            unless ref($axes) eq 'HASH' && !blessed($axes);
        push @policy_axes, map { "$family/$_" } sort keys %$axes;
    }
    confess "policy axis coverage contradicts the workload catalog\n"
        unless join("\0", @policy_axes) eq join("\0", @catalog_axes);

    confess "architecture-scale cap policy groups must be one hash\n"
        unless ref($policy->{groups}) eq 'HASH' && !blessed($policy->{groups});
    for my $axis (@policy_axes) {
        my ($family, $name) = split m{/}, $axis, 2;
        my $group_name = $policy->{axis_groups}{$family}{$name};
        confess "policy axis '$axis' has no selected group\n"
            unless defined($group_name) && !ref($group_name)
                && exists $policy->{groups}{$group_name};
    }
    for my $name (sort keys %{$policy->{groups}}) {
        _assert_group($name, $policy->{groups}{$name});
        confess "policy group '$name' is unreferenced\n"
            unless grep {
                my ($family, $axis) = split m{/}, $_, 2;
                $policy->{axis_groups}{$family}{$axis} eq $name;
            } @policy_axes;
    }
}

sub _assert_group {
    my ($name, $group) = @_;
    _assert_exact_keys($group, [qw(
        declared_authority earliest_stage diagnostic_families path_contract
        current_enforcement atomicity selected_treatment implementation_leaf
        evidence
    )], "policy group '$name'");
    for my $field (qw(
        declared_authority earliest_stage path_contract current_enforcement
        atomicity selected_treatment implementation_leaf
    )) {
        confess "policy group '$name/$field' must be a non-empty scalar\n"
            unless defined($group->{$field}) && !ref($group->{$field})
                && length($group->{$field});
    }
    confess "policy group '$name' selects an unauthorized cap rewrite\n"
        if $group->{selected_treatment} =~ /(?:raise|lower|relevel|rewrite)/;
    _assert_string_array($group->{diagnostic_families},
        "policy group '$name' diagnostics");
    _assert_string_array($group->{evidence}, "policy group '$name' evidence");
}

sub _assert_interactions {
    my ($policy) = @_;
    confess "architecture-scale cap policy interactions must be one hash\n"
        unless ref($policy->{interactions}) eq 'HASH'
            && !blessed($policy->{interactions});
    for my $axis (sort keys %{$policy->{interactions}}) {
        my ($family, $name) = split m{/}, $axis, 2;
        confess "cap interaction '$axis' does not name a selected axis\n"
            unless defined($name)
                && exists $policy->{axis_groups}{$family}{$name};
        my $interaction = $policy->{interactions}{$axis};
        _assert_exact_keys($interaction, [qw(
            limit_authority over_limit_authority route_boundary treatment evidence
        )], "cap interaction '$axis'");
        for my $field (qw(limit_authority over_limit_authority treatment evidence)) {
            confess "cap interaction '$axis/$field' must be a non-empty scalar\n"
                unless defined($interaction->{$field})
                    && !ref($interaction->{$field})
                    && length($interaction->{$field});
        }
        confess "cap interaction '$axis' selects an unauthorized cap rewrite\n"
            if $interaction->{treatment} =~ /(?:raise|lower|relevel|rewrite)/;
        confess "cap interaction '$axis/route_boundary' must be null or a scalar\n"
            if defined($interaction->{route_boundary})
                && ref($interaction->{route_boundary});
    }
    my @expected = sort keys %$INTERACTIONS;
    my @actual = sort keys %{$policy->{interactions}};
    confess "cap interaction inventory contradicts decision 0093\n"
        unless join("\0", @actual) eq join("\0", @expected);
}

sub _assert_profiles {
    my ($policy) = @_;
    _assert_exact_keys($policy->{backend_profiles}, [qw(names authorities)],
        'backend profile policy');
    _assert_string_array($policy->{backend_profiles}{names}, 'backend profile names');
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my @expected_backend = sort keys %{$catalog->{backend_profiles}};
    confess "backend profile cap inventory contradicts the workload catalog\n"
        unless join("\0", @{$policy->{backend_profiles}{names}})
            eq join("\0", @expected_backend);
    my $expected_authorities = backend_emission_profile_authorities();
    confess "backend profile authorities contradict the selected source\n"
        unless _same_plain($policy->{backend_profiles}{authorities},
            $expected_authorities);
    _assert_string_array($policy->{runtime_profiles}, 'runtime profile names');
    my @expected_runtime = sort grep {
        $catalog->{backend_profiles}{$_}{runtime_eligible}
    } @expected_backend;
    confess "runtime profile cap inventory contradicts the workload catalog\n"
        unless join("\0", @{$policy->{runtime_profiles}})
            eq join("\0", @expected_runtime);
}

sub _assert_envelopes {
    my ($envelopes) = @_;
    confess "non-axis envelopes must be one hash\n"
        unless ref($envelopes) eq 'HASH' && !blessed($envelopes);
    my @expected = sort keys %$NON_AXIS_ENVELOPES;
    my @actual = sort keys %$envelopes;
    confess "non-axis envelope inventory contradicts decision 0093\n"
        unless join("\0", @actual) eq join("\0", @expected);
    for my $name (@actual) {
        _assert_exact_keys($envelopes->{$name}, [qw(
            classification authority selected_treatment implementation_leaf evidence
        )], "non-axis envelope '$name'");
        for my $field (qw(
            classification authority selected_treatment implementation_leaf evidence
        )) {
            confess "non-axis envelope '$name/$field' must be a non-empty scalar\n"
                unless defined($envelopes->{$name}{$field})
                    && !ref($envelopes->{$name}{$field})
                    && length($envelopes->{$name}{$field});
        }
    }
}

sub _assert_declared_values {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my %semantic = (
        imports => FSM::VIAL::Parser::MAX_IMPORTS(),
        declarations => FSM::VIAL::SemanticBuilder::MAX_DECLARATIONS(),
        fixtures => FSM::VIAL::SemanticBuilder::MAX_FIXTURES(),
        actions => FSM::VIAL::SemanticBuilder::MAX_SCENARIO_ACTIONS(),
        parallel_depth => FSM::VIAL::SemanticBuilder::MAX_PARALLEL_DEPTH(),
        fibers_per_parallel => FSM::VIAL::SemanticBuilder::MAX_PARALLEL_FIBERS(),
        scalar_or_list_length => FSM::VIAL::SemanticBuilder::MAX_LIST_LENGTH(),
        record_fields => FSM::VIAL::SemanticBuilder::MAX_RECORD_FIELDS(),
        aggregate_depth => FSM::VIAL::SemanticBuilder::MAX_AGGREGATE_DEPTH(),
        scoreboard_capacity => FSM::VIAL::SemanticBuilder::MAX_SCOREBOARD_CAPACITY(),
        coverage_bins => FSM::VIAL::SemanticBuilder::MAX_CROSS_BINS(),
        literal_repeat_count => FSM::VIAL::SemanticBuilder::MAX_REPEAT(),
        source_bytes_per_source => FSM::VIAL::Parser::MAX_SOURCE_BYTES(),
        source_bytes_combined => FSM::VIAL::Parser::MAX_COMBINED_BYTES(),
    );
    confess "semantic scalar/list selected cap contradicts scalar width\n"
        unless $semantic{scalar_or_list_length}
            == FSM::VIAL::SemanticBuilder::MAX_SCALAR_WIDTH();
    _assert_family_limits($catalog, 'semantic_catalog_v1', \%semantic);

    my $bridge = build_hial_vial_bridge_contract()->{limits};
    my %bridge_map = (
        selected_units => 'units',
        selected_domains => 'domains',
        configurations => 'configurations',
        types => 'types',
        endpoints => 'endpoints',
        transactions => 'transactions',
        events => 'events',
        observations => 'observations',
        probes => 'probes',
        backend_bindings => 'backend_bindings',
        retained_residue_records => 'unsupported_residue',
        source_map_records => 'source_map',
        serialized_manifest_bytes => 'serialized_manifest_bytes',
    );
    my %bridge_expected = map { $_ => $bridge->{$bridge_map{$_}} }
        keys %bridge_map;
    _assert_family_limits($catalog, 'bridge_fanout_v1', \%bridge_expected);

    my $execution_contract = build_vial_execution_contract();
    my $execution = $execution_contract->{limits};
    my %execution_map = (
        selected_fixtures => 'selected_fixtures',
        selected_units => 'selected_units',
        selected_domains => 'selected_domains',
        scenarios => 'selected_scenarios',
        operations_per_scenario => 'expanded_operations_per_scenario',
        operations_total => 'expanded_operations_total',
        fibers_total => 'total_fibers',
        simultaneously_live_fibers => 'simultaneous_live_fibers',
        bindings => 'bindings',
        execution_types => 'execution_types',
        source_map_records => 'source_map_records',
        random_attempts => 'random_attempts',
        serialized_plan_bytes => 'serialized_plan_bytes',
    );
    my %execution_expected = map { $_ => $execution->{$execution_map{$_}} }
        keys %execution_map;
    _assert_family_limits($catalog, 'execution_graph_v1', \%execution_expected);

    my %checking_map = (
        model_instances => 'model_instances',
        scalar_model_state_cells => 'scalar_state_cells',
        scoreboard_instances => 'scoreboard_instances',
        scoreboard_capacity => 'scoreboard_declared_capacity',
        coverpoints => 'coverpoints',
        bins_and_cross_tuples => 'coverage_bins_and_cross_tuples',
        faults => 'faults',
        random_occurrences => 'random_occurrences',
    );
    my %checking_expected = map { $_ => $execution->{$checking_map{$_}} }
        keys %checking_map;
    _assert_family_limits($catalog, 'checking_state_v1', \%checking_expected);

    my $runtime = $catalog->{families}{runtime_stream_v1}{axes}
        {runtime_trace_records}{levels};
    my $backend_limits = $execution_contract->{backend_limits};
    confess "runtime record selected cap contradicts the execution contract\n"
        unless $runtime->{limit_v1}{structural_trace_records}
                == $backend_limits->{runtime_trace_records}
            && $runtime->{limit_v1}{structural_trace_bytes}
                == $backend_limits->{runtime_trace_bytes}
            && $runtime->{over_limit_v1}{structural_trace_records}
                == $backend_limits->{runtime_trace_records} + 1
            && $runtime->{over_limit_v1}{structural_trace_bytes}
                == $backend_limits->{runtime_trace_bytes} + 1;
}

sub _assert_family_limits {
    my ($catalog, $family, $expected) = @_;
    my $axes = $catalog->{families}{$family}{axes};
    for my $axis (sort keys %$expected) {
        my $levels = $axes->{$axis}{levels};
        confess "$family/$axis selected cap contradicts its declared authority\n"
            unless defined($levels->{limit_v1}{$axis})
                && $levels->{limit_v1}{$axis} == $expected->{$axis};
        my $over = $levels->{over_limit_v1};
        my $adjacent = exists($over->{$axis})
            ? $over->{$axis}
            : $over->{minimum_bytes};
        confess "$family/$axis selected excess is not the adjacent boundary\n"
            unless defined($adjacent) && $adjacent == $expected->{$axis} + 1;
        if (exists $over->{declared_cap_bytes}) {
            confess "$family/$axis byte excess contradicts its declared cap\n"
                unless $over->{declared_cap_bytes} == $expected->{$axis};
        }
    }
}

sub _group {
    my ($declared_authority, $earliest_stage, $diagnostic_families,
        $path_contract, $current_enforcement, $atomicity, $selected_treatment,
        $implementation_leaf, $evidence) = @_;
    return {
        declared_authority => $declared_authority,
        earliest_stage => $earliest_stage,
        diagnostic_families => $diagnostic_families,
        path_contract => $path_contract,
        current_enforcement => $current_enforcement,
        atomicity => $atomicity,
        selected_treatment => $selected_treatment,
        implementation_leaf => $implementation_leaf,
        evidence => $evidence,
    };
}

sub _interaction {
    my ($limit_authority, $over_limit_authority, $route_boundary, $treatment,
        $evidence) = @_;
    return {
        limit_authority => $limit_authority,
        over_limit_authority => $over_limit_authority,
        route_boundary => $route_boundary,
        treatment => $treatment,
        evidence => $evidence,
    };
}

sub _bridge_map_interaction {
    return _interaction(
        'bridge_source_map_ceiling', 'axis_component_ceiling', undef,
        'retain_both_component_ceilings_and_report_earliest',
        't/1602-vial-architecture-scale-bridge-fanout.t',
    );
}

sub _execution_profile_interaction {
    return _interaction(
        'canonical_route_profile', 'canonical_route_profile', undef,
        'retain_component_ceiling_as_defense_in_depth',
        'docs/decisions/0061-vial-execution-scale-uses-a-caller-sealed-qualification-binder.md',
    );
}

sub _route_interaction {
    my ($route_boundary, $evidence) = @_;
    return _interaction(
        'fixture_or_lower_layer_authority',
        'fixture_or_lower_layer_authority', $route_boundary,
        'retain_intrinsic_ceiling_and_publish_route_authority', $evidence,
    );
}

sub _envelope {
    my ($classification, $authority, $selected_treatment, $implementation_leaf,
        $evidence) = @_;
    return {
        classification => $classification,
        authority => $authority,
        selected_treatment => $selected_treatment,
        implementation_leaf => $implementation_leaf,
        evidence => $evidence,
    };
}

sub _assert_exact_keys {
    my ($value, $expected, $label) = @_;
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$expected;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$expected;
    confess "$label has unknown field '$unknown[0]'\n" if @unknown;
    confess "$label is missing field '$missing[0]'\n" if @missing;
}

sub _assert_string_array {
    my ($value, $label) = @_;
    confess "$label must be one non-empty array\n"
        unless ref($value) eq 'ARRAY' && @$value;
    my %seen;
    for my $entry (@$value) {
        confess "$label must contain unique non-empty scalars\n"
            unless defined($entry) && !ref($entry) && length($entry)
                && !$seen{$entry}++;
    }
}

sub _same_plain {
    my ($left, $right) = @_;
    return 1 if !defined($left) && !defined($right);
    return 0 unless defined($left) && defined($right);
    return $left eq $right unless ref($left) || ref($right);
    return 0 unless ref($left) eq ref($right);
    if (ref($left) eq 'HASH') {
        return 0 unless join("\0", sort keys %$left)
            eq join("\0", sort keys %$right);
        return 0 if grep { !_same_plain($left->{$_}, $right->{$_}) }
            keys %$left;
        return 1;
    }
    if (ref($left) eq 'ARRAY') {
        return 0 unless @$left == @$right;
        for my $index (0 .. $#$left) {
            return 0 unless _same_plain($left->[$index], $right->[$index]);
        }
        return 1;
    }
    return 0;
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return {map { $_ => _clone($value->{$_}) } keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

1;
