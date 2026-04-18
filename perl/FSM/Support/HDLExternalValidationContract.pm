package FSM::Support::HDLExternalValidationContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_hdl_external_validation_contract
    hdl_external_validation_success_step_keys
    hdl_external_validation_success_step_names
    hdl_external_validation_success_top_level_keys
);

sub build_hdl_external_validation_contract {
    return {
        schema_version => 1,
        status => 'optional_when_tools_installed',
        contract_source => 'FSM::Support::HDLExternalValidationContract',
        report_source => 'FSM::Support::HDLExternalValidation',
        entrypoints => {
            cli => './bin/fsmgen --verify-hdl path/to/file.fsm',
            cli_aliases => [
                './bin/fsmgen --validate-hdl path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::HDLExternalValidation::missing_systemverilog_validation_tools()',
                'FSM::Support::HDLExternalValidation::validate_systemverilog_file(...)',
            ],
        },
        command_shape => './bin/fsmgen --verify-hdl path/to/file.fsm',
        alias => './bin/fsmgen --validate-hdl path/to/file.fsm',
        target_languages => [qw(systemverilog sv)],
        tools => [qw(verilator yosys)],
        verilator_stage => 'lint_only_sv',
        yosys_stage => 'read_verilog_sv_noautowire_synth_noabc_stat',
        yosys_abc_enabled => JSON::PP::false,
        yosys_purpose => 'abc_free_structural_netlist_sanity',
        emits_hdl => JSON::PP::true,
        vhdl_validation_deferred_until_vhdl_backend => JSON::PP::true,
        in_process_failures_throw => JSON::PP::true,
        cli_failures_exit_nonzero => JSON::PP::true,
        success_top_level_presence_keys => hdl_external_validation_success_top_level_keys(),
        success_step_presence_keys => hdl_external_validation_success_step_keys(),
        success_step_names => hdl_external_validation_success_step_names(),
        guidance => [
            'Treat the listed command shape, stage names, tool identities, and success-result key lists as the bounded external validation contract for schema version 1.',
            'This lane is optional and only active when Verilator and Yosys are installed.',
            'The promise is about generated SystemVerilog lint/netlist sanity, not about VHDL validation or ABC-enabled synthesis behavior.',
        ],
    };
}

sub hdl_external_validation_success_top_level_keys {
    return [
        qw(
            ok
            source_file
            top_module
            steps
        ),
    ];
}

sub hdl_external_validation_success_step_keys {
    return [
        qw(
            name
            command
            stdout
            stderr
        ),
    ];
}

sub hdl_external_validation_success_step_names {
    return [
        qw(
            verilator_lint
            yosys_synthesis
        ),
    ];
}

1;
