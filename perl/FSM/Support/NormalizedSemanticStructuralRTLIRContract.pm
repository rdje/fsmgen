package FSM::Support::NormalizedSemanticStructuralRTLIRContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_structural_rtl_ir_contract
    normalized_semantic_structural_rtl_ir_presence_keys
);

sub build_normalized_semantic_structural_rtl_ir_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::NormalizedSemanticStructuralRTLIRContract',
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
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.forward_ir.structural_rtl_ir` object used by successful public normalized semantic JSON reports.},
            'The bounded public promise covers the current structural-RTL summary shared by direct roots and composition tops.',
            'The deeper `ports`, `nets`, `instances`, `resolved_links`, `declared_links`, and `auxiliary_assignments` payload contents remain bounded only at the current object-shell level unless later widened deliberately.',
        ],
    };
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

1;
