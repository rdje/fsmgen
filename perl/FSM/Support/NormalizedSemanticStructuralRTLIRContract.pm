package FSM::Support::NormalizedSemanticStructuralRTLIRContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_structural_rtl_ir_contract
    normalized_semantic_structural_rtl_ir_assignment_record_entry_keys
    normalized_semantic_structural_rtl_ir_assignment_record_lhs_entry_keys
    normalized_semantic_structural_rtl_ir_assignment_record_provenance_entry_keys
    normalized_semantic_structural_rtl_ir_assignment_record_rhs_entry_keys
    normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds
    normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_meaning
    normalized_semantic_structural_rtl_ir_collection_presence_keys
    normalized_semantic_structural_rtl_ir_contract_source
    normalized_semantic_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_structural_rtl_ir_instance_entry_keys
    normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_structural_rtl_ir_link_entry_keys
    normalized_semantic_structural_rtl_ir_net_entry_keys
    normalized_semantic_structural_rtl_ir_net_source_entry_keys
    normalized_semantic_structural_rtl_ir_net_target_entry_keys
    normalized_semantic_structural_rtl_ir_presence_key_family_map
    normalized_semantic_structural_rtl_ir_presence_keys
    normalized_semantic_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_structural_rtl_ir_port_entry_keys
    normalized_semantic_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_structural_rtl_ir_summary_presence_keys
);

sub build_normalized_semantic_structural_rtl_ir_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => normalized_semantic_structural_rtl_ir_contract_source(),
        object_name => 'structural_rtl_ir',
        parent_object_name => 'semantic.forward_ir.structural_rtl_ir',
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
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{semantic}{forward_ir}{structural_rtl_ir}',
            ],
        },
        public_presence_keys => normalized_semantic_structural_rtl_ir_presence_keys(),
        summary_presence_keys => normalized_semantic_structural_rtl_ir_summary_presence_keys(),
        collection_presence_keys => normalized_semantic_structural_rtl_ir_collection_presence_keys(),
        auxiliary_assignment_entry_value_kinds =>
            normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        auxiliary_assignment_entry_value_meaning =>
            normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        assignment_record_entry_keys =>
            normalized_semantic_structural_rtl_ir_assignment_record_entry_keys(),
        assignment_record_lhs_entry_keys =>
            normalized_semantic_structural_rtl_ir_assignment_record_lhs_entry_keys(),
        assignment_record_rhs_entry_keys =>
            normalized_semantic_structural_rtl_ir_assignment_record_rhs_entry_keys(),
        assignment_record_provenance_entry_keys =>
            normalized_semantic_structural_rtl_ir_assignment_record_provenance_entry_keys(),
        port_entry_keys => normalized_semantic_structural_rtl_ir_port_entry_keys(),
        port_composition_extension_keys =>
            normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        net_entry_keys => normalized_semantic_structural_rtl_ir_net_entry_keys(),
        net_source_entry_keys => normalized_semantic_structural_rtl_ir_net_source_entry_keys(),
        net_target_entry_keys => normalized_semantic_structural_rtl_ir_net_target_entry_keys(),
        declared_link_entry_keys =>
            normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        resolved_link_entry_keys =>
            normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
        instance_entry_keys => normalized_semantic_structural_rtl_ir_instance_entry_keys(),
        instance_interface_port_entry_keys =>
            normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys(),
        instance_parameter_override_entry_keys =>
            normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys(),
        instance_parameter_override_raw_value_extension_keys =>
            normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        instance_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        instance_port_binding_entry_keys =>
            normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys(),
        instance_port_binding_typed_extension_keys =>
            normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        presence_key_family_map => normalized_semantic_structural_rtl_ir_presence_key_family_map(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.forward_ir.structural_rtl_ir` object used by successful public normalized semantic JSON reports.},
            'The bounded public promise covers the current structural-RTL summary shared by direct roots and composition tops.',
            'The port entry key families describe the current `ports[]` entry schema shared by direct roots and composition tops.',
            'The net entry key family describes the current `nets[]` entry schema emitted by composition tops and by direct roots for declaration-only storage/helper nets plus generated enable wires projected from already-prepared direct backend state.',
            'The net source/target entry key families describe structured generated-enable assignment-record connectivity on direct-root nets where the selected source or target is known from `assignment_records[]`; other direct entries keep a null source and empty targets array.',
            'The declared/resolved link entry key families describe the current `declared_links[]` and `resolved_links[]` entry schema emitted by composition tops.',
            'The instance entry key family describes the current shallow `instances[]` entry schema emitted by composition tops without freezing nested instance binding arrays.',
            'The instance interface-port entry key family describes the current nested `instances[].interface_ports[]` entry schema emitted by composition tops.',
            'The instance parameter-override entry key family describes the current nested `instances[].parameter_overrides[]` core entry schema emitted by parameterized composition tops.',
            'The instance parameter-override raw-value extension key family describes optional authored-token metadata on parameter overrides where a single token survives validation.',
            'The instance parameter-override value-metadata extension key family describes optional resolved type, packed-width, and matched declaration-default metadata on parameter overrides where the value resolver and child/interface declaration validation provide it.',
            'The instance port-binding entry key family describes the current nested `instances[].port_bindings[]` core entry schema emitted by composition tops.',
            'The instance port-binding typed-extension key family describes optional `connection_type_spec` metadata on typed structural instance bindings.',
            'The assignment-record key families describe the preferred machine-readable `assignment_records[]` entries emitted by direct roots for generated enable assignments, including structured lhs, rhs AST/text, rendered SystemVerilog, and provenance metadata.',
            'The auxiliary-assignment entry value-kind family describes the compatibility `auxiliary_assignments[]` scalar string mirror emitted by composition tops and direct roots; direct downstream consumers should prefer `assignment_records[]` when present.',
            'Use the grouped presence_key_family_map to discover the bounded structural-RTL shell summary and collection key families without collecting those key-family lists separately.',
        ],
    };
}

sub normalized_semantic_structural_rtl_ir_contract_source {
    return 'FSM::Support::NormalizedSemanticStructuralRTLIRContract';
}

sub normalized_semantic_structural_rtl_ir_presence_keys {
    return [
        qw(
            assignment_record_count
            assignment_records
            auxiliary_assignment_count
            auxiliary_assignments
            declared_link_count
            declared_links
            instance_count
            instances
            module_name
            net_count
            nets
            port_count
            ports
            resolved_link_count
            resolved_links
            source_root_kind
            target_language
        ),
    ];
}

sub normalized_semantic_structural_rtl_ir_summary_presence_keys {
    return [
        qw(
            assignment_record_count
            auxiliary_assignment_count
            declared_link_count
            instance_count
            module_name
            net_count
            port_count
            resolved_link_count
            source_root_kind
            target_language
        ),
    ];
}

sub normalized_semantic_structural_rtl_ir_collection_presence_keys {
    return [
        qw(
            assignment_records
            auxiliary_assignments
            declared_links
            instances
            nets
            ports
            resolved_links
        ),
    ];
}

sub normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds {
    return [qw(scalar_string)];
}

sub normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_meaning {
    return 'compatibility SystemVerilog continuous assignment line text; prefer assignment_records[] when present';
}

sub normalized_semantic_structural_rtl_ir_assignment_record_entry_keys {
    return [qw(kind lhs provenance rendered rhs)];
}

sub normalized_semantic_structural_rtl_ir_assignment_record_lhs_entry_keys {
    return [qw(kind name)];
}

sub normalized_semantic_structural_rtl_ir_assignment_record_rhs_entry_keys {
    return [qw(ast kind language text)];
}

sub normalized_semantic_structural_rtl_ir_assignment_record_provenance_entry_keys {
    return [qw(clean_dt_name dt_name dte_gate_signal family lhs_signal rhs_value role state_name)];
}

sub normalized_semantic_structural_rtl_ir_port_entry_keys {
    return [
        qw(
            direction
            name
            signed
            type
            width
        ),
    ];
}

sub normalized_semantic_structural_rtl_ir_port_composition_extension_keys {
    return [
        qw(
            binding_mode
            origin_kind
        ),
    ];
}

sub normalized_semantic_structural_rtl_ir_net_entry_keys {
    return [
        qw(
            name
            source
            targets
            width
        ),
    ];
}

sub normalized_semantic_structural_rtl_ir_net_source_entry_keys {
    return [qw(assignment_kind assignment_lhs family kind role)];
}

sub normalized_semantic_structural_rtl_ir_net_target_entry_keys {
    return [qw(assignment_kind assignment_lhs family kind role)];
}

sub normalized_semantic_structural_rtl_ir_link_entry_keys {
    return [
        qw(
            origin_kind
            raw_token
            source
            target
        ),
    ];
}

sub normalized_semantic_structural_rtl_ir_declared_link_entry_keys {
    return normalized_semantic_structural_rtl_ir_link_entry_keys();
}

sub normalized_semantic_structural_rtl_ir_resolved_link_entry_keys {
    return normalized_semantic_structural_rtl_ir_link_entry_keys();
}

sub normalized_semantic_structural_rtl_ir_instance_entry_keys {
    return [
        qw(
            instance_name
            interface_ports
            kind
            module_name
            parameter_overrides
            port_bindings
            source_name
        ),
    ];
}

sub normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys {
    return normalized_semantic_structural_rtl_ir_port_entry_keys();
}

sub normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys {
    return [qw(name origin_kind raw_value_ast value_kind value_payload value_text)];
}

sub normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys {
    return [qw(raw_value)];
}

sub normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys {
    return [qw(declaration_default_value_kind declaration_default_value_width value_type_spec value_width)];
}

sub normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys {
    return [qw(connection_expr port_name signal_name)];
}

sub normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys {
    return [qw(connection_type_spec)];
}

sub normalized_semantic_structural_rtl_ir_presence_key_family_map {
    return {
        summary_presence_keys => normalized_semantic_structural_rtl_ir_summary_presence_keys(),
        collection_presence_keys => normalized_semantic_structural_rtl_ir_collection_presence_keys(),
        auxiliary_assignment_entry_value_kinds =>
            normalized_semantic_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        assignment_record_entry_keys =>
            normalized_semantic_structural_rtl_ir_assignment_record_entry_keys(),
        assignment_record_lhs_entry_keys =>
            normalized_semantic_structural_rtl_ir_assignment_record_lhs_entry_keys(),
        assignment_record_rhs_entry_keys =>
            normalized_semantic_structural_rtl_ir_assignment_record_rhs_entry_keys(),
        assignment_record_provenance_entry_keys =>
            normalized_semantic_structural_rtl_ir_assignment_record_provenance_entry_keys(),
        port_entry_keys => normalized_semantic_structural_rtl_ir_port_entry_keys(),
        port_composition_extension_keys =>
            normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        net_entry_keys => normalized_semantic_structural_rtl_ir_net_entry_keys(),
        net_source_entry_keys => normalized_semantic_structural_rtl_ir_net_source_entry_keys(),
        net_target_entry_keys => normalized_semantic_structural_rtl_ir_net_target_entry_keys(),
        declared_link_entry_keys =>
            normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        resolved_link_entry_keys =>
            normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
        instance_entry_keys => normalized_semantic_structural_rtl_ir_instance_entry_keys(),
        instance_interface_port_entry_keys =>
            normalized_semantic_structural_rtl_ir_instance_interface_port_entry_keys(),
        instance_parameter_override_entry_keys =>
            normalized_semantic_structural_rtl_ir_instance_parameter_override_entry_keys(),
        instance_parameter_override_raw_value_extension_keys =>
            normalized_semantic_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        instance_parameter_override_value_metadata_extension_keys =>
            normalized_semantic_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        instance_port_binding_entry_keys =>
            normalized_semantic_structural_rtl_ir_instance_port_binding_entry_keys(),
        instance_port_binding_typed_extension_keys =>
            normalized_semantic_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
    };
}

1;
