package FSM::Support::HDLExternalValidationContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::HDLExternalValidation qw(
    hdl_external_validation_abc_tool_candidates
    hdl_external_validation_required_tools
);

our @EXPORT_OK = qw(
    build_hdl_external_validation_contract
    hdl_external_validation_abc_mapping_status
    hdl_external_validation_abc_mapping_success_step_names
    hdl_external_validation_contract_source
    hdl_external_validation_execution_failure_modes
    hdl_external_validation_failure_mode_family_map
    hdl_external_validation_failure_mode_names
    hdl_external_validation_failure_text_prefix_map
    hdl_external_validation_input_failure_modes
    hdl_external_validation_optional_tool_names
    hdl_external_validation_required_tool_names
    hdl_external_validation_success_presence_key_family_map
    hdl_external_validation_success_step_keys
    hdl_external_validation_success_step_names
    hdl_external_validation_success_top_level_keys
);

sub hdl_external_validation_contract_source {
    return 'FSM::Support::HDLExternalValidationContract';
}

sub hdl_external_validation_required_tool_names {
    return [hdl_external_validation_required_tools()];
}

sub hdl_external_validation_optional_tool_names {
    return [qw(abc_mapping)];
}

sub hdl_external_validation_abc_mapping_status {
    return 'optional_explicit_opt_in_not_required_not_default';
}

sub hdl_external_validation_abc_mapping_success_step_names {
    return [qw(verilator_lint yosys_abc_synthesis)];
}

sub build_hdl_external_validation_contract {
    return {
        schema_version => 1,
        status => 'optional_when_tools_installed',
        contract_source => hdl_external_validation_contract_source(),
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
        tools => hdl_external_validation_required_tool_names(),
        required_tools => hdl_external_validation_required_tool_names(),
        optional_tools => hdl_external_validation_optional_tool_names(),
        abc_tool_candidates => [hdl_external_validation_abc_tool_candidates()],
        abc_mapping_status => hdl_external_validation_abc_mapping_status(),
        abc_mapping_required => JSON::PP::false,
        abc_mapping_opt_in_supported => JSON::PP::true,
        abc_mapping_default_enabled => JSON::PP::false,
        abc_mapping_invocation => 'FSM::Support::HDLExternalValidation::validate_systemverilog_file(..., abc_mapping => 1)',
        abc_mapping_yosys_stage => 'read_verilog_sv_noautowire_synth_abc_stat',
        abc_mapping_success_step_names => hdl_external_validation_abc_mapping_success_step_names(),
        verilator_stage => 'lint_only_sv',
        yosys_stage => 'read_verilog_sv_noautowire_synth_noabc_stat',
        yosys_abc_enabled => JSON::PP::false,
        yosys_purpose => 'abc_free_structural_netlist_sanity',
        emits_hdl => JSON::PP::true,
        vhdl_generation_scaffold_active => JSON::PP::true,
        vhdl_validation_deferred_until_ghdl_validation_lane => JSON::PP::true,
        vhdl_validation_deferred_until_vhdl_backend => JSON::PP::true,
        in_process_failures_throw => JSON::PP::true,
        cli_failures_exit_nonzero => JSON::PP::true,
        success_top_level_presence_keys => hdl_external_validation_success_top_level_keys(),
        success_step_presence_keys => hdl_external_validation_success_step_keys(),
        success_presence_key_family_map => hdl_external_validation_success_presence_key_family_map(),
        success_step_names => hdl_external_validation_success_step_names(),
        failure_mode_names => hdl_external_validation_failure_mode_names(),
        failure_mode_family_map => hdl_external_validation_failure_mode_family_map(),
        failure_text_prefix_map => hdl_external_validation_failure_text_prefix_map(),
        guidance => [
            'Treat the listed command shape, stage names, tool identities, success-result key lists, failure-mode families, and failure text prefixes as the bounded external validation contract for schema version 1.',
            'Use the grouped success_presence_key_family_map to discover the bounded success top-level and step key families without collecting those success key lists separately.',
            'Use the grouped failure_mode_family_map plus failure_text_prefix_map to recognize the bounded input-side and step-failure categories without treating the full thrown stderr/stdout payload as frozen.',
            'This lane is optional and only active when Verilator and Yosys are installed.',
            'The promise is about generated SystemVerilog lint/netlist sanity, not about VHDL validation or ABC-enabled synthesis behavior.',
            'ABC executable discovery is optional metadata for the default validation lane; it does not make ABC a required validation tool and does not add ABC to the default CLI validation sequence.',
            'ABC mapping validation is available only through explicit in-process opt-in via abc_mapping => 1; default --verify-hdl remains ABC-free.',
            'Direct VHDL generation has a scaffold subset, but this external validation contract remains SystemVerilog-only until a separate GHDL validation lane is runnable, documented, support-accounted, and regression-backed.',
            'The legacy vhdl_validation_deferred_until_vhdl_backend flag is retained for compatibility; prefer vhdl_validation_deferred_until_ghdl_validation_lane for the current blocker.',
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

sub hdl_external_validation_success_presence_key_family_map {
    return {
        success_top_level_presence_keys => hdl_external_validation_success_top_level_keys(),
        success_step_presence_keys => hdl_external_validation_success_step_keys(),
    };
}

sub hdl_external_validation_success_step_names {
    return [
        qw(
            verilator_lint
            yosys_synthesis
        ),
    ];
}

sub hdl_external_validation_input_failure_modes {
    return [
        qw(
            missing_source_file
            missing_top_module
            source_file_not_found
            missing_tools
            unsupported_top_module_identifier
        ),
    ];
}

sub hdl_external_validation_execution_failure_modes {
    return [
        qw(
            tool_step_failed
        ),
    ];
}

sub hdl_external_validation_failure_mode_names {
    return [
        @{hdl_external_validation_input_failure_modes()},
        @{hdl_external_validation_execution_failure_modes()},
    ];
}

sub hdl_external_validation_failure_mode_family_map {
    return {
        input_failure_modes => hdl_external_validation_input_failure_modes(),
        execution_failure_modes => hdl_external_validation_execution_failure_modes(),
    };
}

sub hdl_external_validation_failure_text_prefix_map {
    return {
        missing_source_file => "[HDLExternalValidation.pm][validate_systemverilog_file()] Missing required 'source_file'",
        missing_top_module => "[HDLExternalValidation.pm][validate_systemverilog_file()] Missing required 'top_module'",
        source_file_not_found => '[HDLExternalValidation.pm][validate_systemverilog_file()] Source file does not exist: ',
        missing_tools => '[HDLExternalValidation.pm][validate_systemverilog_file()] Missing external HDL validation tool(s): ',
        unsupported_top_module_identifier => "[HDLExternalValidation.pm][_yosys_identifier()] Unsupported top-module identifier '",
        tool_step_failed => "External HDL validation step '",
    };
}

1;
