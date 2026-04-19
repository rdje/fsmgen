package FSM::Support::NormalizedSemanticLoweredRTLIRContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_normalized_semantic_lowered_rtl_ir_contract
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_presence_keys
);

sub build_normalized_semantic_lowered_rtl_ir_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::NormalizedSemanticLoweredRTLIRContract',
        object_name => 'lowered_rtl_ir',
        parent_object_name => 'semantic.forward_ir.lowered_rtl_ir',
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
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)->{semantic}{forward_ir}{lowered_rtl_ir}',
            ],
        },
        public_presence_keys => normalized_semantic_lowered_rtl_ir_presence_keys(),
        optional_composition_keys => normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        optional_for_non_composition_sources => JSON::PP::true,
        json_safe_when_embedded_in_public_reports => JSON::PP::true,
        guidance => [
            q{Treat this contract as the bounded nested `semantic.forward_ir.lowered_rtl_ir` object used by successful public normalized semantic JSON reports.},
            'The bounded public promise covers the current lowered-RTL summary shared by direct roots plus the current composition-only extension keys.',
            'The deeper `output_drive_families`, `standalone_dt_multi_drive_targets`, and composition candidate payload contents remain bounded only at the current object-shell level unless later widened deliberately.',
        ],
    };
}

sub normalized_semantic_lowered_rtl_ir_presence_keys {
    return [
        qw(
            module_name
            output_drive_families
            output_drive_family_count
            source_root_kind
            standalone_dt_multi_drive_target_count
            standalone_dt_multi_drive_targets
            target_language
        ),
    ];
}

sub normalized_semantic_lowered_rtl_ir_optional_composition_keys {
    return [
        qw(
            auxiliary_assignment_count
            composition_shared_datapath_candidate_count
            composition_shared_datapath_candidates
            instance_count
            instance_names
            internal_net_count
            internal_net_names
        ),
    ];
}

1;
