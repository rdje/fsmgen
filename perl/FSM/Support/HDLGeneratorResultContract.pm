package FSM::Support::HDLGeneratorResultContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
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
        source_info_identity_presence_keys => hdl_generator_result_source_info_identity_keys(),
        source_info_summary_presence_keys => hdl_generator_result_source_info_summary_keys(),
        module_info_identity_presence_keys => hdl_generator_result_module_info_identity_keys(),
        module_info_summary_presence_keys => hdl_generator_result_module_info_summary_keys(),
        module_info_optional_composition_summary_keys => hdl_generator_result_module_info_optional_composition_summary_keys(),
        statistics_summary_presence_keys => hdl_generator_result_statistics_summary_keys(),
        statistics_optional_composition_keys => hdl_generator_result_statistics_optional_composition_keys(),
        resolved_package_imports_shell_only => JSON::PP::true,
        resolved_package_imports_raw_value_class => 'FSM::Package::Spec',
        resolved_package_imports_summary_surface => [
            'source_info.package_import_count',
            'source_info.package_import_names',
        ],
        intent_hir_contract_source => 'FSM::Support::NormalizedSemanticIntentHIRContract',
        intent_hir_presence_keys => hdl_generator_result_intent_hir_keys(),
        intent_hir_optional_composition_keys => hdl_generator_result_intent_hir_optional_composition_keys(),
        lowered_rtl_ir_contract_source => 'FSM::Support::NormalizedSemanticLoweredRTLIRContract',
        lowered_rtl_ir_presence_keys => hdl_generator_result_lowered_rtl_ir_keys(),
        lowered_rtl_ir_optional_composition_keys => hdl_generator_result_lowered_rtl_ir_optional_composition_keys(),
        structural_rtl_ir_contract_source => 'FSM::Support::NormalizedSemanticStructuralRTLIRContract',
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
            'The advertised source_info package-import summary keys are stabilized, but the wider source_info hash still includes compatibility-heavy objects on composition roots.',
            'The resolved_package_imports branch is shell-only: its values are raw FSM::Package::Spec objects, so use source_info.package_import_count and source_info.package_import_names for stable package-import inspection.',
            'The advertised scalar summary keys inside module_info are stabilized, but the whole module_info hash still includes compatibility-heavy nested payloads.',
            'The advertised statistics summary keys inside statistics are stabilized, but the whole statistics hash still includes compatibility-heavy payloads.',
            'The top-level intent_hir, lowered_rtl_ir, and structural_rtl_ir hashes also reuse the same bounded shell owners advertised through normalized semantic JSON.',
            'Do not treat the entire HDLGenerator result hash as a stable JSON document.',
            'Use --emit-semantic-json or FSM::Support::NormalizedSemanticReport for sanitized machine interchange.',
        ],
    };
}

sub hdl_generator_result_source_info_identity_keys {
    return [qw(header kind)];
}

sub hdl_generator_result_source_info_summary_keys {
    return [qw(
        package_import_count
        package_import_names
    )];
}

sub hdl_generator_result_module_info_identity_keys {
    return [qw(module_name source_root_kind)];
}

sub hdl_generator_result_module_info_summary_keys {
    return [qw(
        output_drive_family_count
        parameter_count
        regular_state_count
        requires_implicit_system_ports
        signal_count
        standalone_dt_count
        standalone_dt_multi_drive_target_count
        state_count
    )];
}

sub hdl_generator_result_module_info_optional_composition_summary_keys {
    return [qw(
        auxiliary_assignment_count
        composition_block_count
        composition_child_count
        composition_generated_child_count
        composition_generated_dt_child_count
        composition_generated_fsm_child_count
        composition_lane
        composition_net_count
        composition_override_count
        composition_resolved_link_count
        composition_shared_datapath_candidate_count
        composition_standalone_dt_block_count
        composition_standalone_dt_child_count
        composition_standalone_dt_multi_drive_target_count
        instance_count
        internal_net_count
    )];
}

sub hdl_generator_result_statistics_summary_keys {
    return [qw(
        factoring_enabled
        global_expressions
        intermediate_signals
    )];
}

sub hdl_generator_result_statistics_optional_composition_keys {
    return [qw(
        composition_block_count
        composition_child_count
        composition_lane
        composition_net_count
        composition_override_count
        composition_resolved_link_count
        composition_shared_datapath_candidate_count
        composition_top_port_count
    )];
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
