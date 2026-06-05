package FSM::Support::NormalizedSemanticStructuralRTLIRContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_structural_rtl_ir_contract
    normalized_semantic_structural_rtl_ir_collection_presence_keys
    normalized_semantic_structural_rtl_ir_contract_source
    normalized_semantic_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_structural_rtl_ir_link_entry_keys
    normalized_semantic_structural_rtl_ir_net_entry_keys
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
        port_entry_keys => normalized_semantic_structural_rtl_ir_port_entry_keys(),
        port_composition_extension_keys =>
            normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        net_entry_keys => normalized_semantic_structural_rtl_ir_net_entry_keys(),
        declared_link_entry_keys =>
            normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        resolved_link_entry_keys =>
            normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
        presence_key_family_map => normalized_semantic_structural_rtl_ir_presence_key_family_map(),
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.forward_ir.structural_rtl_ir` object used by successful public normalized semantic JSON reports.},
            'The bounded public promise covers the current structural-RTL summary shared by direct roots and composition tops.',
            'The port entry key families describe the current `ports[]` entry schema shared by direct roots and composition tops.',
            'The net entry key family describes the current `nets[]` entry schema emitted by composition tops.',
            'The declared/resolved link entry key families describe the current `declared_links[]` and `resolved_links[]` entry schema emitted by composition tops.',
            'The deeper `instances` and `auxiliary_assignments` payload contents remain bounded only at the current object-shell level unless later widened deliberately.',
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
            auxiliary_assignments
            declared_links
            instances
            nets
            ports
            resolved_links
        ),
    ];
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

sub normalized_semantic_structural_rtl_ir_presence_key_family_map {
    return {
        summary_presence_keys => normalized_semantic_structural_rtl_ir_summary_presence_keys(),
        collection_presence_keys => normalized_semantic_structural_rtl_ir_collection_presence_keys(),
        port_entry_keys => normalized_semantic_structural_rtl_ir_port_entry_keys(),
        port_composition_extension_keys =>
            normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        net_entry_keys => normalized_semantic_structural_rtl_ir_net_entry_keys(),
        declared_link_entry_keys =>
            normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        resolved_link_entry_keys =>
            normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
    };
}

1;
