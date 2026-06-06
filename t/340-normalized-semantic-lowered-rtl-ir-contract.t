#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    build_normalized_semantic_lowered_rtl_ir_contract
    normalized_semantic_lowered_rtl_ir_contract_source
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_presence_key_family_map
    normalized_semantic_lowered_rtl_ir_presence_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
);

subtest 'contract exposes the bounded normalized semantic lowered-rtl-ir object' => sub {
    my $contract = build_normalized_semantic_lowered_rtl_ir_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested lowered-rtl-ir object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_lowered_rtl_ir_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'lowered_rtl_ir', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.forward_ir.lowered_rtl_ir', 'contract records the nested parent path');
    ok(
        $contract->{optional_for_non_composition_sources},
        'contract says composition-only lowered-rtl-ir keys stay optional for non-composition sources',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested lowered-rtl-ir object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        'contract publishes the bounded lowered-rtl-ir core key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        [
            qw(
                module_name
                output_drive_families
                output_drive_family_count
                selector_conflict_target_count
                selector_conflict_targets
                source_root_kind
                standalone_dt_multi_drive_target_count
                standalone_dt_multi_drive_targets
                target_language
            ),
        ],
        'bounded lowered-rtl-ir core key list includes selector-conflict metadata',
    );
    is_deeply(
        $contract->{optional_composition_keys},
        normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        'contract publishes the bounded lowered-rtl-ir composition-only key list',
    );
    is_deeply(
        $contract->{output_drive_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys(),
        'contract publishes the bounded output-drive family entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys(),
        [
            qw(
                default_value
                driver_blocks
                driver_count
                driver_enable_signals
                family_enable_signals
                multiplexer_type
                reset_value
                rhs_enable_families
                rhs_values
                signal_name
                width
            ),
        ],
        'output-drive family entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'contract publishes the bounded output-drive rhs-enable-family entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        [
            qw(
                driver_blocks
                driver_enable_signals
                family_enable_signal
                rhs_value
            ),
        ],
        'output-drive rhs-enable-family entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{selector_conflict_target_entry_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'contract publishes the bounded selector-conflict target entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        [
            qw(
                family_enable_signals
                multi_value_assertion
                multiplexer_type
                rhs_enable_families
                rhs_values
                signal_name
            ),
        ],
        'selector-conflict target entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'contract publishes the bounded selector-conflict rhs-enable-family entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        [
            qw(
                driver_enable_signals
                family_enable_signal
                rhs_value
                same_value_assertion
            ),
        ],
        'selector-conflict rhs-enable-family entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{selector_conflict_multi_value_assertion_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'contract publishes the bounded selector-conflict multi-value assertion key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        [
            qw(
                input_count
                input_enable_signals
                kind
                target_signal
            ),
        ],
        'selector-conflict multi-value assertion key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{selector_conflict_same_value_assertion_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'contract publishes the bounded selector-conflict same-value assertion key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        [
            qw(
                input_count
                input_enable_signals
                kind
                rhs_value
                target_signal
            ),
        ],
        'selector-conflict same-value assertion key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'contract publishes the bounded standalone-DT multi-drive target entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        [
            qw(
                dt_enable_signals
                dt_names
                lhs_enable_signals
                multi_drive_assertion
                multiplexer_type
                rhs_values
                signal_name
            ),
        ],
        'standalone-DT multi-drive target entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'contract publishes the bounded standalone-DT multi-drive assertion key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        [
            qw(
                input_count
                input_enable_signals
                kind
                target_signal
            ),
        ],
        'standalone-DT multi-drive assertion key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{composition_shared_datapath_candidate_entry_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        'contract publishes the bounded composition shared-datapath candidate entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        [
            qw(
                signal_name
                width
                interface_type
                storage_class
                reset_value
                contributor_count
                contributors
                top_output_signals
                peer_input_count
                peer_input_endpoints
                default_lifted_visibility
                planned_reexport_top_output_signals
                loopback_allowed
                lifted_runtime_kind
                lifted_runtime_signal
                lifted_runtime_next_signal
                lifted_runtime_reset_value
                lifted_runtime_reset_active_level
                lifted_runtime_reset_kind
                lifted_runtime_reset_keyword
                aggregate_target_enable_signal
                multi_value_conflict_signal
                multi_value_assertion
                aggregate_enable_family_count
                aggregate_enable_families
            ),
        ],
        'composition shared-datapath candidate entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{composition_shared_datapath_candidate_declared_type_extension_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        'contract publishes the optional composition shared-datapath candidate declared-type extension key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        [qw(declared_type_name declared_type_spec)],
        'composition shared-datapath candidate declared-type extension key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{composition_shared_datapath_candidate_contributor_entry_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        'contract publishes the bounded composition shared-datapath contributor entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        [
            qw(
                kind
                instance_name
                module_name
                source_name
                endpoint
                bound_signal
                bound_signals
                bound_connection_expr
                output_drive_family
                drive_intent
                intent_hir
                lowered_rtl_ir
                structural_rtl_ir
            ),
        ],
        'composition shared-datapath contributor entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{composition_shared_datapath_candidate_contributor_declared_type_extension_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        'contract publishes the optional composition shared-datapath contributor declared-type extension key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        [qw(declared_type_name declared_type_spec)],
        'composition shared-datapath contributor declared-type extension key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{composition_shared_datapath_bound_connection_expr_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        'contract publishes the bounded composition shared-datapath contributor bound connection expression key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        [qw(kind signal_name)],
        'composition shared-datapath bound connection expression key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{composition_shared_datapath_aggregate_enable_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        'contract publishes the bounded composition shared-datapath aggregate-enable family entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        [
            qw(
                rhs_value
                aggregate_enable_signal
                same_value_conflict_signal
                same_value_assertion
                contributor_count
                contributors
            ),
        ],
        'composition shared-datapath aggregate-enable family entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{composition_shared_datapath_aggregate_enable_contributor_entry_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        'contract publishes the bounded composition shared-datapath aggregate-enable contributor entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        [
            qw(
                endpoint
                family_enable_signal
                source_enable_signal
                driver_blocks
                driver_enable_signals
            ),
        ],
        'composition shared-datapath aggregate-enable contributor entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{composition_shared_datapath_assertion_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        'contract publishes the bounded composition shared-datapath assertion key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        [
            qw(
                input_count
                input_enable_signals
                kind
                result_signal
            ),
        ],
        'composition shared-datapath assertion key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_lowered_rtl_ir_presence_key_family_map(),
        'contract publishes the grouped lowered-rtl-ir key-family discovery map',
    );
    is_deeply(
        $contract->{presence_key_family_map}{selector_conflict_target_entry_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'grouped lowered-rtl-ir family map includes selector-conflict target entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{output_drive_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys(),
        'grouped lowered-rtl-ir family map includes output-drive family entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'grouped lowered-rtl-ir family map includes output-drive rhs-enable-family entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'grouped lowered-rtl-ir family map includes standalone-DT multi-drive target entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'grouped lowered-rtl-ir family map includes standalone-DT multi-drive assertion entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_shared_datapath_candidate_entry_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        'grouped lowered-rtl-ir family map includes composition shared-datapath candidate entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_shared_datapath_candidate_declared_type_extension_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        'grouped lowered-rtl-ir family map includes composition shared-datapath candidate declared-type extensions',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_shared_datapath_candidate_contributor_entry_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        'grouped lowered-rtl-ir family map includes composition shared-datapath contributor entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_shared_datapath_candidate_contributor_declared_type_extension_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        'grouped lowered-rtl-ir family map includes composition shared-datapath contributor declared-type extensions',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_shared_datapath_bound_connection_expr_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        'grouped lowered-rtl-ir family map includes composition shared-datapath bound connection expressions',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_shared_datapath_aggregate_enable_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        'grouped lowered-rtl-ir family map includes composition shared-datapath aggregate-enable family entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_shared_datapath_aggregate_enable_contributor_entry_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        'grouped lowered-rtl-ir family map includes composition shared-datapath aggregate-enable contributors',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_shared_datapath_assertion_keys},
        normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        'grouped lowered-rtl-ir family map includes composition shared-datapath assertion metadata',
    );
};

done_testing();
