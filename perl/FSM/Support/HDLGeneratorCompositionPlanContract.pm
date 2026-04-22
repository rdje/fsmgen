package FSM::Support::HDLGeneratorCompositionPlanContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hdl_generator_composition_plan_contract
    hdl_generator_composition_plan_contract_source
    hdl_generator_composition_plan_fallback_surface_map
    hdl_generator_composition_plan_raw_value_class_when_defined
    hdl_generator_composition_plan_summary_surfaces
);

sub hdl_generator_composition_plan_contract_source {
    return 'FSM::Support::HDLGeneratorCompositionPlanContract';
}

sub build_hdl_generator_composition_plan_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => hdl_generator_composition_plan_contract_source(),
        object_name => 'composition_plan',
        parent_object_name => 'HDLGeneratorResult.composition_plan',
        report_sources => [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        entrypoints => {
            in_process => [
                'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)->{composition_plan}',
            ],
        },
        shell_only => JSON::PP::true,
        value_may_be_undef => JSON::PP::true,
        raw_value_class_when_defined => hdl_generator_composition_plan_raw_value_class_when_defined(),
        summary_surfaces => hdl_generator_composition_plan_summary_surfaces(),
        fallback_surface_map => hdl_generator_composition_plan_fallback_surface_map(),
        full_hash_stable => JSON::PP::false,
        json_safe_as_whole => JSON::PP::false,
        guidance => [
            q{Treat this contract as the bounded shell-only `composition_plan` branch reused by in-process `HDLGenerator` results.},
            'When defined, the branch remains a raw FSM::Composition::Plan object kept for in-process compatibility rather than a JSON-safe public interchange payload.',
            'Use semantic_exports.normalized_semantic_json.semantic.composition or semantic_exports.normalized_semantic_json.semantic.composition.provenance_report for structured downstream inspection instead of binding to the live composition plan object as public API.',
            'Use the grouped fallback_surface_map to discover the bounded semantic composition fallback surfaces for composition_plan without collecting those paths separately.',
        ],
    };
}

sub hdl_generator_composition_plan_raw_value_class_when_defined {
    return 'FSM::Composition::Plan';
}

sub hdl_generator_composition_plan_summary_surfaces {
    return [
        'semantic_exports.normalized_semantic_json.semantic.composition',
        'semantic_exports.normalized_semantic_json.semantic.composition.provenance_report',
    ];
}

sub hdl_generator_composition_plan_fallback_surface_map {
    return {
        semantic_composition => [
            'semantic_exports.normalized_semantic_json.semantic.composition',
        ],
        semantic_composition_provenance_report => [
            'semantic_exports.normalized_semantic_json.semantic.composition.provenance_report',
        ],
    };
}

1;
