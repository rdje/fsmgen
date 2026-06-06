package FSM::Support::NormalizedSemanticCompositionContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::CompositionReportContract qw(
    composition_report_contract_source
);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
);
use FSM::Support::SerializableCompositionPlanSnapshot qw(
    serializable_composition_plan_snapshot_contract_source
);

our @EXPORT_OK = qw(
    build_normalized_semantic_composition_contract
    normalized_semantic_composition_child_entry_keys
    normalized_semantic_composition_collection_keys
    normalized_semantic_composition_contract_source
    normalized_semantic_composition_generated_child_entry_keys
    normalized_semantic_composition_nested_presence_keys
    normalized_semantic_composition_presence_key_family_map
    normalized_semantic_composition_presence_keys
    normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_assertion_keys
    normalized_semantic_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_composition_standalone_dt_child_entry_keys
    normalized_semantic_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_composition_summary_presence_keys
);

sub normalized_semantic_composition_contract_source {
    return 'FSM::Support::NormalizedSemanticCompositionContract';
}

sub build_normalized_semantic_composition_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_composition_contract_source(),
        object_name => 'composition',
        parent_object_name => 'semantic.composition',
        report_sources => [
            qw(
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        entrypoints => {
            cli => [
                './bin/fsmgen --strict --emit-semantic-json path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)',
            ],
        },
        public_presence_keys => normalized_semantic_composition_presence_keys(),
        summary_presence_keys => normalized_semantic_composition_summary_presence_keys(),
        collection_keys => normalized_semantic_composition_collection_keys(),
        child_entry_keys => normalized_semantic_composition_child_entry_keys(),
        generated_child_entry_keys => normalized_semantic_composition_generated_child_entry_keys(),
        standalone_dt_child_entry_keys => normalized_semantic_composition_standalone_dt_child_entry_keys(),
        standalone_dt_enable_family_entry_keys =>
            normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        standalone_dt_module_enable_family_keys =>
            normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        shared_datapath_candidate_entry_keys =>
            normalized_semantic_composition_shared_datapath_candidate_entry_keys(),
        shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys(),
        shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys(),
        shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_composition_shared_datapath_bound_connection_expr_keys(),
        shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        shared_datapath_assertion_keys =>
            normalized_semantic_composition_shared_datapath_assertion_keys(),
        nested_presence_keys => normalized_semantic_composition_nested_presence_keys(),
        presence_key_family_map => normalized_semantic_composition_presence_key_family_map(),
        nested_contract_source_map => {
            plan_snapshot => serializable_composition_plan_snapshot_contract_source(),
            provenance_report => composition_report_contract_source(),
        },
        plan_snapshot_contract_source => serializable_composition_plan_snapshot_contract_source(),
        provenance_report_contract_source => composition_report_contract_source(),
        optional_for_non_composition_sources => JSON::PP::true,
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `composition` object used inside successful public normalized semantic JSON reports for composition sources.},
            'The bounded public promise covers the lane, child/net/link, generated-child, standalone-DT-child, shared-datapath, plan-snapshot, and sanitized provenance-report keys exported for composition roots.',
            'The children[] and generated_children[] entry key families describe shallow composition-child summaries while delegating child intent_hir, lowered_rtl_ir, and structural_rtl_ir objects to their existing bounded contracts.',
            'The standalone_dt_children[] entry key family describes shallow reusable standalone-DT child summaries while delegating child intent_hir, lowered_rtl_ir, structural_rtl_ir, and nested standalone-DT multi-drive assertion shapes to their existing bounded contracts.',
            'The shared_datapath_candidates[] entry key families are composition-side aliases of the already bounded lowered-RTL shared-datapath candidate, contributor, drive-intent, aggregate-enable, assertion, and bound-connection schemas.',
            'The nested plan_snapshot fragment stays bounded through FSM::Support::SerializableCompositionPlanSnapshot.',
            'The nested provenance_report fragment stays bounded through FSM::Support::CompositionReportContract.',
            'Use the grouped presence_key_family_map to discover the bounded composition summary, collection, child-entry, generated-child-entry, standalone-DT-child, plan-snapshot, and provenance key families without collecting those key-family lists separately.',
        ],
    };
}

sub normalized_semantic_composition_presence_keys {
    return [
        qw(
            lane
            child_count
            children
            net_count
            resolved_link_count
            generated_child_count
            generated_children
            standalone_dt_child_count
            standalone_dt_children
            shared_datapath_candidate_count
            shared_datapath_candidates
            plan_snapshot
            provenance_report
        ),
    ];
}

sub normalized_semantic_composition_summary_presence_keys {
    return [
        qw(
            lane
            child_count
            net_count
            resolved_link_count
            generated_child_count
            standalone_dt_child_count
            shared_datapath_candidate_count
        ),
    ];
}

sub normalized_semantic_composition_collection_keys {
    return [
        qw(
            children
            generated_children
            standalone_dt_children
            shared_datapath_candidates
        ),
    ];
}

sub normalized_semantic_composition_child_entry_keys {
    return [
        qw(
            kind
            instance_name
            module_name
            source_name
            source_root_kind
            regular_state_count
            standalone_dt_count
            output_drive_family_count
            standalone_dt_multi_drive_target_count
            parameter_override_count
            parameter_overrides
            intent_hir
            lowered_rtl_ir
            structural_rtl_ir
        ),
    ];
}

sub normalized_semantic_composition_generated_child_entry_keys {
    return [
        qw(
            kind
            instance_name
            module_name
            source_name
            source_root_kind
            regular_state_count
            standalone_dt_count
            output_drive_family_count
            standalone_dt_multi_drive_target_count
            intent_hir
            lowered_rtl_ir
            structural_rtl_ir
        ),
    ];
}

sub normalized_semantic_composition_standalone_dt_child_entry_keys {
    return [
        qw(
            instance_name
            module_name
            source_name
            standalone_dt_count
            standalone_dt_names
            standalone_dt_enable_families
            standalone_dt_module_enable_family
            standalone_dt_multi_drive_target_count
            standalone_dt_multi_drive_targets
            intent_hir
            lowered_rtl_ir
            structural_rtl_ir
        ),
    ];
}

sub normalized_semantic_composition_standalone_dt_enable_family_entry_keys {
    return [
        qw(
            dt_name
            enable_signal
        ),
    ];
}

sub normalized_semantic_composition_standalone_dt_module_enable_family_keys {
    return [
        qw(
            dt_names
            enable_signals
        ),
    ];
}

sub normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys {
    return normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys();
}

sub normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys {
    return normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys();
}

sub normalized_semantic_composition_shared_datapath_candidate_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys();
}

sub normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys();
}

sub normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys();
}

sub normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys();
}

sub normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys();
}

sub normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys();
}

sub normalized_semantic_composition_shared_datapath_bound_connection_expr_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys();
}

sub normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys();
}

sub normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys();
}

sub normalized_semantic_composition_shared_datapath_assertion_keys {
    return normalized_semantic_lowered_rtl_ir_composition_shared_datapath_assertion_keys();
}

sub normalized_semantic_composition_nested_presence_keys {
    return [
        qw(
            provenance_report
            plan_snapshot
        ),
    ];
}

sub normalized_semantic_composition_presence_key_family_map {
    return {
        summary_presence_keys => normalized_semantic_composition_summary_presence_keys(),
        collection_keys => normalized_semantic_composition_collection_keys(),
        child_entry_keys => normalized_semantic_composition_child_entry_keys(),
        generated_child_entry_keys => normalized_semantic_composition_generated_child_entry_keys(),
        standalone_dt_child_entry_keys => normalized_semantic_composition_standalone_dt_child_entry_keys(),
        standalone_dt_enable_family_entry_keys =>
            normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        standalone_dt_module_enable_family_keys =>
            normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        standalone_dt_multi_drive_target_entry_keys =>
            normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        standalone_dt_multi_drive_assertion_keys =>
            normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        shared_datapath_candidate_entry_keys =>
            normalized_semantic_composition_shared_datapath_candidate_entry_keys(),
        shared_datapath_candidate_declared_type_extension_keys =>
            normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys(),
        shared_datapath_candidate_contributor_entry_keys =>
            normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys(),
        shared_datapath_candidate_contributor_declared_type_extension_keys =>
            normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        shared_datapath_candidate_contributor_drive_intent_entry_keys =>
            normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys =>
            normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        shared_datapath_bound_connection_expr_keys =>
            normalized_semantic_composition_shared_datapath_bound_connection_expr_keys(),
        shared_datapath_aggregate_enable_family_entry_keys =>
            normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        shared_datapath_aggregate_enable_contributor_entry_keys =>
            normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        shared_datapath_assertion_keys =>
            normalized_semantic_composition_shared_datapath_assertion_keys(),
        nested_presence_keys => normalized_semantic_composition_nested_presence_keys(),
    };
}

1;
