package FSM::Support::NormalizedSemanticModuleContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_module_contract
    normalized_semantic_module_contract_source
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_module_presence_key_family_map
    normalized_semantic_module_presence_keys
);

sub normalized_semantic_module_contract_source {
    return 'FSM::Support::NormalizedSemanticModuleContract';
}

sub build_normalized_semantic_module_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_module_contract_source(),
        object_name => 'module',
        parent_object_name => 'semantic.module',
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
        public_presence_keys => normalized_semantic_module_presence_keys(),
        optional_metric_keys => normalized_semantic_module_optional_metric_keys(),
        presence_key_family_map => normalized_semantic_module_presence_key_family_map(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `module` object used inside successful public normalized semantic JSON reports.},
            'The bounded public promise covers the core module identity, language, state, signal, parameter, and implicit-system-port summary keys.',
            'The same owner also publishes the currently bounded optional metric key family for output-drive, standalone-DT, and composition-specific counters.',
            'Use the grouped presence_key_family_map to discover the bounded core and optional-metric semantic.module key families without collecting those key-family lists separately.',
        ],
    };
}

sub normalized_semantic_module_presence_keys {
    return [
        qw(
            name
            source_root_kind
            target_language
            state_count
            regular_state_count
            regular_state_names
            standalone_dt_count
            standalone_dt_names
            signal_count
            signal_names
            parameter_count
            parameter_names
            requires_implicit_system_ports
        ),
    ];
}

sub normalized_semantic_module_optional_metric_keys {
    return [
        qw(
            output_drive_family_count
            standalone_dt_multi_drive_target_count
            composition_child_count
            composition_net_count
            composition_resolved_link_count
            composition_generated_child_count
            composition_generated_fsm_child_count
            composition_generated_dt_child_count
            composition_standalone_dt_child_count
            composition_standalone_dt_block_count
            composition_standalone_dt_multi_drive_target_count
            composition_shared_datapath_candidate_count
        ),
    ];
}

sub normalized_semantic_module_presence_key_family_map {
    return {
        public_presence_keys => normalized_semantic_module_presence_keys(),
        optional_metric_keys => normalized_semantic_module_optional_metric_keys(),
    };
}

1;
