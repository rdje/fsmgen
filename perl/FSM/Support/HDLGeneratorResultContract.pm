package FSM::Support::HDLGeneratorResultContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::HDLGeneratorModuleInfoContract qw(
    hdl_generator_module_info_identity_keys
    hdl_generator_module_info_optional_composition_summary_keys
    hdl_generator_module_info_stable_subsurfaces
    hdl_generator_module_info_summary_keys
);
use FSM::Support::HDLGeneratorStatisticsContract qw(
    hdl_generator_statistics_optional_composition_keys
    hdl_generator_statistics_stable_subsurfaces
    hdl_generator_statistics_summary_keys
);
use FSM::Support::HDLGeneratorSourceInfoContract qw(
    hdl_generator_source_info_identity_keys
    hdl_generator_source_info_stable_subsurfaces
    hdl_generator_source_info_summary_keys
);
use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_keys
);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_presence_keys
);
use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(
    normalized_semantic_structural_rtl_ir_presence_keys
);

our @EXPORT_OK = qw(
    build_hdl_generator_result_contract
    hdl_generator_result_intent_hir_keys
    hdl_generator_result_intent_hir_optional_composition_keys
    hdl_generator_result_known_top_level_keys
    hdl_generator_result_lowered_rtl_ir_keys
    hdl_generator_result_lowered_rtl_ir_optional_composition_keys
    hdl_generator_result_module_info_identity_keys
    hdl_generator_result_module_info_optional_composition_summary_keys
    hdl_generator_result_module_info_summary_keys
    hdl_generator_result_source_info_identity_keys
    hdl_generator_result_source_info_summary_keys
    hdl_generator_result_statistics_optional_composition_keys
    hdl_generator_result_statistics_summary_keys
    hdl_generator_result_structural_rtl_ir_keys
);

sub build_hdl_generator_result_contract {
    return {
        schema_version => 1,
        status => 'bounded_top_level_presence',
        contract_source => 'FSM::Support::HDLGeneratorResultContract',
        entrypoint => 'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)',
        tested_by => [
            't/305-hdl-generator-result-contract.t',
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
        source_info_contract_source => 'FSM::Support::HDLGeneratorSourceInfoContract',
        source_info_identity_presence_keys => hdl_generator_result_source_info_identity_keys(),
        source_info_summary_presence_keys => hdl_generator_result_source_info_summary_keys(),
        source_info_full_hash_stable => JSON::PP::false,
        source_info_stable_subsurfaces => hdl_generator_source_info_stable_subsurfaces(),
        module_info_contract_source => 'FSM::Support::HDLGeneratorModuleInfoContract',
        module_info_identity_presence_keys => hdl_generator_result_module_info_identity_keys(),
        module_info_summary_presence_keys => hdl_generator_result_module_info_summary_keys(),
        module_info_optional_composition_summary_keys => hdl_generator_result_module_info_optional_composition_summary_keys(),
        module_info_full_hash_stable => JSON::PP::false,
        module_info_stable_subsurfaces => hdl_generator_module_info_stable_subsurfaces(),
        statistics_contract_source => 'FSM::Support::HDLGeneratorStatisticsContract',
        statistics_summary_presence_keys => hdl_generator_result_statistics_summary_keys(),
        statistics_optional_composition_keys => hdl_generator_result_statistics_optional_composition_keys(),
        statistics_full_hash_stable => JSON::PP::false,
        statistics_stable_subsurfaces => hdl_generator_statistics_stable_subsurfaces(),
        fsm_module_shell_only => JSON::PP::true,
        fsm_module_raw_value_class_when_defined => 'FSM::CoreAST::FSMModule',
        fsm_module_summary_surfaces => [
            'intent_hir',
            'lowered_rtl_ir',
            'structural_rtl_ir',
        ],
        raw_ast_shell_only => JSON::PP::true,
        raw_ast_value_shape => 'ARRAY',
        raw_ast_summary_surfaces => [
            'intent_hir',
        ],
        resolved_package_imports_shell_only => JSON::PP::true,
        resolved_package_imports_raw_value_class => 'FSM::Package::Spec',
        resolved_package_imports_summary_surface => [
            'source_info.package_import_count',
            'source_info.package_import_names',
        ],
        composition_spec_shell_only => JSON::PP::true,
        composition_spec_raw_value_class => 'FSM::Composition::Spec',
        composition_plan_shell_only => JSON::PP::true,
        composition_plan_raw_value_class => 'FSM::Composition::Plan',
        composition_report_shell_only => JSON::PP::true,
        composition_report_contract_source => 'FSM::Support::CompositionReportContract',
        composition_report_json_fragment_path => 'semantic_exports.normalized_semantic_json.semantic.composition.provenance_report',
        composition_report_raw_hash_json_safe => JSON::PP::false,
        intent_hir_contract_source => 'FSM::Support::NormalizedSemanticIntentHIRContract',
        intent_hir_full_hash_stable => JSON::PP::false,
        intent_hir_presence_keys => hdl_generator_result_intent_hir_keys(),
        intent_hir_optional_composition_keys => hdl_generator_result_intent_hir_optional_composition_keys(),
        lowered_rtl_ir_contract_source => 'FSM::Support::NormalizedSemanticLoweredRTLIRContract',
        lowered_rtl_ir_full_hash_stable => JSON::PP::false,
        lowered_rtl_ir_presence_keys => hdl_generator_result_lowered_rtl_ir_keys(),
        lowered_rtl_ir_optional_composition_keys => hdl_generator_result_lowered_rtl_ir_optional_composition_keys(),
        structural_rtl_ir_contract_source => 'FSM::Support::NormalizedSemanticStructuralRTLIRContract',
        structural_rtl_ir_full_hash_stable => JSON::PP::false,
        structural_rtl_ir_presence_keys => hdl_generator_result_structural_rtl_ir_keys(),
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
            'The fsm_module branch is shell-only when defined: it is a raw FSM::CoreAST::FSMModule object kept for in-process compatibility, so prefer intent_hir, lowered_rtl_ir, structural_rtl_ir, or normalized semantic JSON for structured downstream inspection.',
            'The raw_ast branch is a shell-only frontend/debug artifact, so prefer intent_hir or normalized semantic JSON instead of treating parser-level AST arrays as a public interchange format.',
            'The resolved_package_imports branch is shell-only: its values are raw FSM::Package::Spec objects, so use source_info.package_import_count and source_info.package_import_names for stable package-import inspection.',
            'The composition_spec and composition_plan branches are shell-only: they are raw FSM::Composition::Spec and FSM::Composition::Plan objects kept for in-process compatibility.',
            'The raw composition_report branch is an in-process compatibility hash, not a stable JSON document; use FSM::Support::CompositionReportContract and semantic_exports.normalized_semantic_json.semantic.composition.provenance_report for serializable composition provenance.',
            'The whole module_info hash is not itself stabilized; only the advertised module_info identity and summary subsurfaces are public.',
            'The advertised scalar summary keys inside module_info are stabilized, but the whole module_info hash still includes compatibility-heavy nested payloads.',
            'The whole statistics hash is not itself stabilized; only the advertised statistics summary subsurfaces are public.',
            'The advertised statistics summary keys inside statistics are stabilized, but the whole statistics hash still includes compatibility-heavy payloads.',
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
