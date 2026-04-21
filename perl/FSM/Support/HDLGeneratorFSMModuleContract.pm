package FSM::Support::HDLGeneratorFSMModuleContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hdl_generator_fsm_module_contract
    hdl_generator_fsm_module_contract_source
    hdl_generator_fsm_module_raw_value_class_when_defined
    hdl_generator_fsm_module_summary_surfaces
);

sub hdl_generator_fsm_module_contract_source {
    return 'FSM::Support::HDLGeneratorFSMModuleContract';
}

sub build_hdl_generator_fsm_module_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => hdl_generator_fsm_module_contract_source(),
        object_name => 'fsm_module',
        parent_object_name => 'HDLGeneratorResult.fsm_module',
        report_sources => [
            qw(
                FSM::Pipeline::HDLGenerator
            ),
        ],
        entrypoints => {
            in_process => [
                'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)->{fsm_module}',
            ],
        },
        shell_only => JSON::PP::true,
        value_may_be_undef => JSON::PP::true,
        raw_value_class_when_defined => hdl_generator_fsm_module_raw_value_class_when_defined(),
        summary_surfaces => hdl_generator_fsm_module_summary_surfaces(),
        full_hash_stable => JSON::PP::false,
        json_safe_as_whole => JSON::PP::false,
        guidance => [
            q{Treat this contract as the bounded shell-only `fsm_module` branch reused by in-process `HDLGenerator` results.},
            'When defined, the branch remains a raw FSM::CoreAST::FSMModule object kept for in-process compatibility rather than a JSON-safe public interchange payload.',
            'Use intent_hir, lowered_rtl_ir, structural_rtl_ir, or normalized semantic JSON for structured downstream inspection instead of binding to the live CoreAST object as public API.',
        ],
    };
}

sub hdl_generator_fsm_module_raw_value_class_when_defined {
    return 'FSM::CoreAST::FSMModule';
}

sub hdl_generator_fsm_module_summary_surfaces {
    return [
        'intent_hir',
        'lowered_rtl_ir',
        'structural_rtl_ir',
    ];
}

1;
