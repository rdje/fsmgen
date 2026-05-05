package FSM::Support::HDLGeneratorResultContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::CompositionReportContract qw(
    composition_report_contract_source
    composition_report_json_fragment_path
    composition_report_raw_report_json_safe
);
use FSM::Support::HDLGeneratorCompositionPlanContract qw(
    hdl_generator_composition_plan_contract_source
    hdl_generator_composition_plan_fallback_surface_map
    hdl_generator_composition_plan_raw_value_class_when_defined
    hdl_generator_composition_plan_summary_surfaces
);
use FSM::Support::HDLGeneratorCompositionSpecContract qw(
    hdl_generator_composition_spec_contract_source
    hdl_generator_composition_spec_fallback_surface_map
    hdl_generator_composition_spec_raw_value_class_when_defined
    hdl_generator_composition_spec_summary_surfaces
);
use FSM::Support::HDLGeneratorFSMModuleContract qw(
    hdl_generator_fsm_module_contract_source
    hdl_generator_fsm_module_fallback_surface_map
    hdl_generator_fsm_module_raw_value_class_when_defined
    hdl_generator_fsm_module_summary_surfaces
);
use FSM::Support::HDLGeneratorRawASTContract qw(
    hdl_generator_raw_ast_contract_source
    hdl_generator_raw_ast_fallback_surface_map
    hdl_generator_raw_ast_summary_surfaces
    hdl_generator_raw_ast_value_shape
);
use FSM::Support::HDLGeneratorModuleInfoContract qw(
    hdl_generator_module_info_contract_source
    hdl_generator_module_info_identity_keys
    hdl_generator_module_info_optional_composition_summary_keys
    hdl_generator_module_info_stable_subsurfaces
    hdl_generator_module_info_summary_keys
);
use FSM::Support::HDLGeneratorResolvedPackageImportsContract qw(
    hdl_generator_resolved_package_imports_contract_source
    hdl_generator_resolved_package_imports_fallback_surface_map
    hdl_generator_resolved_package_imports_raw_value_class
    hdl_generator_resolved_package_imports_summary_surface
);
use FSM::Support::HDLGeneratorStatisticsContract qw(
    hdl_generator_statistics_contract_source
    hdl_generator_statistics_optional_composition_keys
    hdl_generator_statistics_stable_subsurfaces
    hdl_generator_statistics_summary_keys
);
use FSM::Support::HDLGeneratorSourceInfoContract qw(
    hdl_generator_source_info_contract_source
    hdl_generator_source_info_identity_keys
    hdl_generator_source_info_package_import_summary_copy_policy
    hdl_generator_source_info_stable_subsurfaces
    hdl_generator_source_info_summary_keys
);
use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    normalized_semantic_intent_hir_contract_source
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_keys
);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_contract_source
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_presence_keys
);
use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(
    normalized_semantic_structural_rtl_ir_contract_source
    normalized_semantic_structural_rtl_ir_presence_keys
);

our @EXPORT_OK = qw(
    build_hdl_generator_result_contract
    hdl_generator_result_contract_source
    hdl_generator_result_intent_hir_keys
    hdl_generator_result_intent_hir_optional_composition_keys
    hdl_generator_result_known_top_level_keys
    hdl_generator_result_lowered_rtl_ir_keys
    hdl_generator_result_lowered_rtl_ir_optional_composition_keys
    hdl_generator_result_module_info_identity_keys
    hdl_generator_result_module_info_optional_composition_summary_keys
    hdl_generator_result_optional_composition_key_family_map
    hdl_generator_result_semantic_layer_presence_key_family_map
    hdl_generator_result_module_info_summary_keys
    hdl_generator_result_shell_only_fallback_surface_family_map
    hdl_generator_result_shell_only_fallback_surface_map
    hdl_generator_result_source_info_identity_keys
    hdl_generator_result_stable_subsurface_map
    hdl_generator_result_source_info_summary_keys
    hdl_generator_result_statistics_optional_composition_keys
    hdl_generator_result_statistics_summary_keys
    hdl_generator_result_structural_rtl_ir_keys
);

sub hdl_generator_result_contract_source {
    return 'FSM::Support::HDLGeneratorResultContract';
}

sub build_hdl_generator_result_contract {
    return {
        schema_version => 1,
        status => 'bounded_top_level_presence',
        contract_source => hdl_generator_result_contract_source(),
        entrypoint => 'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)',
        tested_by => [
            't/305-hdl-generator-result-contract.t',
            't/438-hdl-generator-result-contract-defensive-copy-boundary-audit.t',
            't/495-source-info-package-import-summary-defensive-copy-boundary-audit.t',
        ],
        public_top_level_presence_keys => [
            qw(
                hdl_code
                module_info
                intent_hir
                lowered_rtl_ir
                structural_rtl_ir
                source_info
                resolved_package_imports
            ),
        ],
        direct_root_top_level_keys => [
            qw(fsm_module raw_ast statistics),
        ],
        composition_root_top_level_keys => [
            qw(fsm_module raw_ast statistics composition_spec composition_plan composition_report),
        ],
        nested_contract_source_map => {
            source_info => hdl_generator_source_info_contract_source(),
            module_info => hdl_generator_module_info_contract_source(),
            statistics => hdl_generator_statistics_contract_source(),
            fsm_module => hdl_generator_fsm_module_contract_source(),
            raw_ast => hdl_generator_raw_ast_contract_source(),
            resolved_package_imports => hdl_generator_resolved_package_imports_contract_source(),
            composition_spec => hdl_generator_composition_spec_contract_source(),
            composition_plan => hdl_generator_composition_plan_contract_source(),
            composition_report => composition_report_contract_source(),
            intent_hir => normalized_semantic_intent_hir_contract_source(),
            lowered_rtl_ir => normalized_semantic_lowered_rtl_ir_contract_source(),
            structural_rtl_ir => normalized_semantic_structural_rtl_ir_contract_source(),
        },
        source_info_contract_source => hdl_generator_source_info_contract_source(),
        source_info_identity_presence_keys => hdl_generator_result_source_info_identity_keys(),
        source_info_summary_presence_keys => hdl_generator_result_source_info_summary_keys(),
        source_info_package_import_summary_copy_policy => hdl_generator_source_info_package_import_summary_copy_policy(),
        source_info_full_hash_stable => JSON::PP::false,
        source_info_stable_subsurfaces => hdl_generator_source_info_stable_subsurfaces(),
        module_info_contract_source => hdl_generator_module_info_contract_source(),
        module_info_identity_presence_keys => hdl_generator_result_module_info_identity_keys(),
        module_info_summary_presence_keys => hdl_generator_result_module_info_summary_keys(),
        module_info_optional_composition_summary_keys => hdl_generator_result_module_info_optional_composition_summary_keys(),
        module_info_full_hash_stable => JSON::PP::false,
        module_info_stable_subsurfaces => hdl_generator_module_info_stable_subsurfaces(),
        statistics_contract_source => hdl_generator_statistics_contract_source(),
        statistics_summary_presence_keys => hdl_generator_result_statistics_summary_keys(),
        statistics_optional_composition_keys => hdl_generator_result_statistics_optional_composition_keys(),
        statistics_full_hash_stable => JSON::PP::false,
        statistics_stable_subsurfaces => hdl_generator_statistics_stable_subsurfaces(),
        stable_subsurface_map => hdl_generator_result_stable_subsurface_map(),
        optional_composition_key_family_map => hdl_generator_result_optional_composition_key_family_map(),
        fsm_module_contract_source => hdl_generator_fsm_module_contract_source(),
        fsm_module_shell_only => JSON::PP::true,
        fsm_module_raw_value_class_when_defined => hdl_generator_fsm_module_raw_value_class_when_defined(),
        fsm_module_summary_surfaces => hdl_generator_fsm_module_summary_surfaces(),
        fsm_module_fallback_surface_map => hdl_generator_fsm_module_fallback_surface_map(),
        raw_ast_contract_source => hdl_generator_raw_ast_contract_source(),
        raw_ast_shell_only => JSON::PP::true,
        raw_ast_value_shape => hdl_generator_raw_ast_value_shape(),
        raw_ast_summary_surfaces => hdl_generator_raw_ast_summary_surfaces(),
        raw_ast_fallback_surface_map => hdl_generator_raw_ast_fallback_surface_map(),
        resolved_package_imports_contract_source => hdl_generator_resolved_package_imports_contract_source(),
        resolved_package_imports_shell_only => JSON::PP::true,
        resolved_package_imports_raw_value_class => hdl_generator_resolved_package_imports_raw_value_class(),
        resolved_package_imports_summary_surface => hdl_generator_resolved_package_imports_summary_surface(),
        resolved_package_imports_fallback_surface_map => hdl_generator_resolved_package_imports_fallback_surface_map(),
        composition_spec_contract_source => hdl_generator_composition_spec_contract_source(),
        composition_spec_shell_only => JSON::PP::true,
        composition_spec_raw_value_class => hdl_generator_composition_spec_raw_value_class_when_defined(),
        composition_spec_summary_surfaces => hdl_generator_composition_spec_summary_surfaces(),
        composition_spec_fallback_surface_map => hdl_generator_composition_spec_fallback_surface_map(),
        composition_plan_contract_source => hdl_generator_composition_plan_contract_source(),
        composition_plan_shell_only => JSON::PP::true,
        composition_plan_raw_value_class => hdl_generator_composition_plan_raw_value_class_when_defined(),
        composition_plan_summary_surfaces => hdl_generator_composition_plan_summary_surfaces(),
        composition_plan_fallback_surface_map => hdl_generator_composition_plan_fallback_surface_map(),
        composition_report_shell_only => JSON::PP::true,
        composition_report_contract_source => composition_report_contract_source(),
        composition_report_json_fragment_path => composition_report_json_fragment_path(),
        composition_report_raw_hash_json_safe => composition_report_raw_report_json_safe(),
        shell_only_fallback_surface_map => hdl_generator_result_shell_only_fallback_surface_map(),
        shell_only_fallback_surface_family_map => hdl_generator_result_shell_only_fallback_surface_family_map(),
        intent_hir_contract_source => normalized_semantic_intent_hir_contract_source(),
        intent_hir_full_hash_stable => JSON::PP::false,
        intent_hir_presence_keys => hdl_generator_result_intent_hir_keys(),
        intent_hir_optional_composition_keys => hdl_generator_result_intent_hir_optional_composition_keys(),
        lowered_rtl_ir_contract_source => normalized_semantic_lowered_rtl_ir_contract_source(),
        lowered_rtl_ir_full_hash_stable => JSON::PP::false,
        lowered_rtl_ir_presence_keys => hdl_generator_result_lowered_rtl_ir_keys(),
        lowered_rtl_ir_optional_composition_keys => hdl_generator_result_lowered_rtl_ir_optional_composition_keys(),
        structural_rtl_ir_contract_source => normalized_semantic_structural_rtl_ir_contract_source(),
        structural_rtl_ir_full_hash_stable => JSON::PP::false,
        structural_rtl_ir_presence_keys => hdl_generator_result_structural_rtl_ir_keys(),
        semantic_layer_presence_key_family_map => hdl_generator_result_semantic_layer_presence_key_family_map(),
        live_or_unsanitized_keys => [
            qw(
                fsm_module
                raw_ast
                statistics
                module_info
                source_info
                resolved_package_imports
                composition_spec
                composition_plan
                composition_report
            ),
        ],
        nested_identity_slices_advertised => JSON::PP::true,
        source_info_summary_slices_advertised => JSON::PP::true,
        module_info_summary_slices_advertised => JSON::PP::true,
        statistics_summary_slices_advertised => JSON::PP::true,
        top_level_semantic_layer_contracts_advertised => JSON::PP::true,
        stable_nested_content => JSON::PP::false,
        full_result_json_safe => JSON::PP::false,
        json_safe_export_surface => 'semantic_exports.normalized_semantic_json',
        guidance => [
            'Treat the listed top-level keys as the bounded public presence contract.',
            'The advertised nested identity keys inside source_info and module_info are stabilized beyond that top-level shell.',
            'The whole source_info hash is not itself stabilized; only the advertised source_info identity and package-import summary subsurfaces are public.',
            'The advertised source_info package-import summary keys are stabilized, but the wider source_info hash still includes compatibility-heavy objects on composition roots.',
            'Use the grouped stable_subsurface_map to discover the bounded stable nested slices for source_info, module_info, and statistics without reconstructing that map from separate arrays.',
            'Use the grouped optional_composition_key_family_map to discover the bounded composition-only key families without collecting those optional key lists separately.',
            'Use the grouped shell_only_fallback_surface_map to discover the structured fallback surfaces for the shell-only compatibility branches without collecting those fallback paths one field at a time.',
            'Use the grouped shell_only_fallback_surface_family_map to discover the narrower fallback-surface families published by those shell-only compatibility branches without reconstructing the per-branch grouping yourself.',
            'The fsm_module branch is shell-only when defined: it is a raw FSM::CoreAST::FSMModule object kept for in-process compatibility, so prefer intent_hir, lowered_rtl_ir, structural_rtl_ir, or normalized semantic JSON for structured downstream inspection.',
            'The raw_ast branch is a shell-only frontend/debug artifact, so prefer intent_hir or normalized semantic JSON instead of treating parser-level AST arrays as a public interchange format.',
            'The resolved_package_imports branch is shell-only: its values are raw FSM::Package::Spec objects, so use source_info.package_import_count and source_info.package_import_names for stable package-import inspection.',
            'The composition_spec branch is shell-only when defined: it is a raw FSM::Composition::Spec object kept for in-process compatibility, so prefer semantic_exports.normalized_semantic_json.semantic.composition or semantic_exports.normalized_semantic_json.semantic.composition.provenance_report for structured downstream inspection.',
            'The composition_plan branch is shell-only when defined: it is a raw FSM::Composition::Plan object kept for in-process compatibility, so prefer semantic_exports.normalized_semantic_json.semantic.composition or semantic_exports.normalized_semantic_json.semantic.composition.provenance_report for structured downstream inspection.',
            'The raw composition_report branch is an in-process compatibility hash, not a stable JSON document; use FSM::Support::CompositionReportContract and semantic_exports.normalized_semantic_json.semantic.composition.provenance_report for serializable composition provenance.',
            'The whole module_info hash is not itself stabilized; only the advertised module_info identity and summary subsurfaces are public.',
            'The advertised scalar summary keys inside module_info are stabilized, but the whole module_info hash still includes compatibility-heavy nested payloads.',
            'The whole statistics hash is not itself stabilized; only the advertised statistics summary subsurfaces are public.',
            'The advertised statistics summary keys inside statistics are stabilized, but the whole statistics hash still includes compatibility-heavy payloads.',
            'Use the grouped semantic_layer_presence_key_family_map to discover the bounded top-level semantic-layer key families without collecting those semantic-layer key lists separately.',
            'The top-level intent_hir, lowered_rtl_ir, and structural_rtl_ir hashes also reuse the same bounded shell owners advertised through normalized semantic JSON; they are not separately stabilized as full top-level trees beyond those advertised shell keys.',
            'Do not treat the entire HDLGenerator result hash as a stable JSON document.',
            'Use --emit-semantic-json or FSM::Support::NormalizedSemanticReport for sanitized machine interchange.',
        ],
    };
}

sub hdl_generator_result_source_info_identity_keys {
    return hdl_generator_source_info_identity_keys();
}

sub hdl_generator_result_source_info_summary_keys {
    return hdl_generator_source_info_summary_keys();
}

sub hdl_generator_result_stable_subsurface_map {
    return {
        source_info => hdl_generator_source_info_stable_subsurfaces(),
        module_info => hdl_generator_module_info_stable_subsurfaces(),
        statistics => hdl_generator_statistics_stable_subsurfaces(),
    };
}

sub hdl_generator_result_optional_composition_key_family_map {
    return {
        module_info_optional_composition_summary_keys => hdl_generator_result_module_info_optional_composition_summary_keys(),
        statistics_optional_composition_keys => hdl_generator_result_statistics_optional_composition_keys(),
        intent_hir_optional_composition_keys => hdl_generator_result_intent_hir_optional_composition_keys(),
        lowered_rtl_ir_optional_composition_keys => hdl_generator_result_lowered_rtl_ir_optional_composition_keys(),
    };
}

sub hdl_generator_result_semantic_layer_presence_key_family_map {
    return {
        intent_hir_presence_keys => hdl_generator_result_intent_hir_keys(),
        lowered_rtl_ir_presence_keys => hdl_generator_result_lowered_rtl_ir_keys(),
        structural_rtl_ir_presence_keys => hdl_generator_result_structural_rtl_ir_keys(),
    };
}

sub hdl_generator_result_shell_only_fallback_surface_map {
    return {
        fsm_module => hdl_generator_fsm_module_summary_surfaces(),
        raw_ast => hdl_generator_raw_ast_summary_surfaces(),
        resolved_package_imports => hdl_generator_resolved_package_imports_summary_surface(),
        composition_spec => hdl_generator_composition_spec_summary_surfaces(),
        composition_plan => hdl_generator_composition_plan_summary_surfaces(),
        composition_report => [composition_report_json_fragment_path()],
    };
}

sub hdl_generator_result_shell_only_fallback_surface_family_map {
    return {
        fsm_module => hdl_generator_fsm_module_fallback_surface_map(),
        raw_ast => hdl_generator_raw_ast_fallback_surface_map(),
        resolved_package_imports => hdl_generator_resolved_package_imports_fallback_surface_map(),
        composition_spec => hdl_generator_composition_spec_fallback_surface_map(),
        composition_plan => hdl_generator_composition_plan_fallback_surface_map(),
        composition_report => {
            sanitized_json_fragment => [composition_report_json_fragment_path()],
        },
    };
}

sub hdl_generator_result_module_info_identity_keys {
    return hdl_generator_module_info_identity_keys();
}

sub hdl_generator_result_module_info_summary_keys {
    return hdl_generator_module_info_summary_keys();
}

sub hdl_generator_result_module_info_optional_composition_summary_keys {
    return hdl_generator_module_info_optional_composition_summary_keys();
}

sub hdl_generator_result_statistics_summary_keys {
    return hdl_generator_statistics_summary_keys();
}

sub hdl_generator_result_statistics_optional_composition_keys {
    return hdl_generator_statistics_optional_composition_keys();
}

sub hdl_generator_result_intent_hir_keys {
    return normalized_semantic_intent_hir_presence_keys();
}

sub hdl_generator_result_intent_hir_optional_composition_keys {
    return normalized_semantic_intent_hir_optional_composition_keys();
}

sub hdl_generator_result_lowered_rtl_ir_keys {
    return normalized_semantic_lowered_rtl_ir_presence_keys();
}

sub hdl_generator_result_lowered_rtl_ir_optional_composition_keys {
    return normalized_semantic_lowered_rtl_ir_optional_composition_keys();
}

sub hdl_generator_result_structural_rtl_ir_keys {
    return normalized_semantic_structural_rtl_ir_presence_keys();
}

sub hdl_generator_result_known_top_level_keys {
    my $contract = build_hdl_generator_result_contract();
    my %known;
    for my $field (qw(
        public_top_level_presence_keys
        direct_root_top_level_keys
        composition_root_top_level_keys
    )) {
        $known{$_} = 1 for @{$contract->{$field} || []};
    }
    return [sort keys %known];
}

1;
