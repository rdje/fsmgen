package FSM::Support::SerializablePlanReportContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::CompositionReportContract qw(
    composition_report_contract_source
    composition_report_json_fragment_path
    composition_report_public_top_level_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_report_contract_source
    normalized_semantic_public_top_level_keys
);
use FSM::Support::SerializableCompositionPlanSnapshot qw(
    build_serializable_composition_plan_snapshot_contract
    serializable_composition_plan_snapshot_contract_source
);

our @EXPORT_OK = qw(
    build_serializable_plan_report_contract
    serializable_plan_report_contract_source
    serializable_plan_report_json_safe_surface_keys
    serializable_plan_report_nested_contract_source_map
    serializable_plan_report_public_top_level_keys
    serializable_plan_report_raw_shell_replacement_map
);

sub serializable_plan_report_contract_source {
    return 'FSM::Support::SerializablePlanReportContract';
}

sub build_serializable_plan_report_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => serializable_plan_report_contract_source(),
        purpose => 'Advertise JSON-safe plan/report surfaces for embedders instead of raw in-process compatibility shells.',
        public_top_level_presence_keys => serializable_plan_report_public_top_level_keys(),
        json_safe_surface_keys => serializable_plan_report_json_safe_surface_keys(),
        nested_contract_source_map => serializable_plan_report_nested_contract_source_map(),
        raw_shell_replacement_map => serializable_plan_report_raw_shell_replacement_map(),
        composition_plan_snapshot_contract => build_serializable_composition_plan_snapshot_contract(),
        normalized_semantic_report_public_top_level_keys => normalized_semantic_public_top_level_keys(),
        composition_report_public_top_level_keys => composition_report_public_top_level_keys(),
        composition_report_json_fragment_path => composition_report_json_fragment_path(),
        current_serializable_surfaces_json_safe => JSON::PP::true,
        raw_hdl_generator_branches_json_safe => JSON::PP::false,
        guidance => [
            'Prefer the advertised JSON-safe report surfaces for downstream tooling.',
            'Treat raw HDLGenerator branches as in-process compatibility shells, not portable interchange payloads.',
            'Use normalized_semantic_json for module, semantic IR, structural, and composition summaries.',
            'Use composition_plan_snapshot for bounded composition-plan inspection instead of traversing FSM::Composition::Plan.',
            'Use semantic.composition.provenance_report for serializable composition provenance.',
            'Add future plan snapshots here only when their schema, contract owner, and regression coverage are explicit.',
        ],
    };
}

sub serializable_plan_report_public_top_level_keys {
    return [
        qw(
            schema_version
            status
            contract_source
            purpose
            json_safe_surface_keys
            nested_contract_source_map
            raw_shell_replacement_map
            composition_plan_snapshot_contract
            current_serializable_surfaces_json_safe
            raw_hdl_generator_branches_json_safe
            guidance
        ),
    ];
}

sub serializable_plan_report_json_safe_surface_keys {
    return [
        qw(
            normalized_semantic_json
            composition_plan_snapshot
            composition_provenance_report
        ),
    ];
}

sub serializable_plan_report_nested_contract_source_map {
    return {
        normalized_semantic_json => normalized_semantic_report_contract_source(),
        composition_plan_snapshot => serializable_composition_plan_snapshot_contract_source(),
        composition_provenance_report => composition_report_contract_source(),
    };
}

sub serializable_plan_report_raw_shell_replacement_map {
    return {
        composition_report => 'semantic_exports.normalized_semantic_json.semantic.composition.provenance_report',
        composition_plan => 'embedding.serializable_plan_reports.composition_plan_snapshot',
        composition_spec => 'semantic_exports.normalized_semantic_json.semantic.composition',
        fsm_module => 'semantic_exports.normalized_semantic_json.semantic.forward_ir',
        raw_ast => 'semantic_exports.normalized_semantic_json.semantic.forward_ir.intent_hir',
        resolved_package_imports => 'embedding.hdl_generator_result.source_info_summary_presence_keys',
    };
}

1;
