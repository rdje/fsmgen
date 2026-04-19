package FSM::Support::HDLGeneratorResultContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hdl_generator_result_contract
    hdl_generator_result_known_top_level_keys
    hdl_generator_result_module_info_identity_keys
    hdl_generator_result_source_info_identity_keys
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
        module_info_identity_presence_keys => hdl_generator_result_module_info_identity_keys(),
        live_or_unsanitized_keys => [
            qw(
                fsm_module
                raw_ast
                statistics
                module_info
                intent_hir
                source_info
                composition_spec
                composition_plan
                composition_report
            ),
        ],
        nested_identity_slices_advertised => JSON::PP::true,
        stable_nested_content => JSON::PP::false,
        full_result_json_safe => JSON::PP::false,
        json_safe_export_surface => 'semantic_exports.normalized_semantic_json',
        guidance => [
            'Treat the listed top-level keys as the bounded public presence contract.',
            'Only the advertised nested identity keys inside source_info and module_info are currently stabilized beyond that top-level shell.',
            'Do not treat the entire HDLGenerator result hash as a stable JSON document.',
            'Use --emit-semantic-json or FSM::Support::NormalizedSemanticReport for sanitized machine interchange.',
        ],
    };
}

sub hdl_generator_result_source_info_identity_keys {
    return [qw(header kind)];
}

sub hdl_generator_result_module_info_identity_keys {
    return [qw(module_name source_root_kind)];
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
