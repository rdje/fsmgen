package FSM::Support::NormalizedSemanticReportContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::ReportSourceContract qw(report_source_presence_keys);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
    support_accounting_match_success_keys
);

our @EXPORT_OK = qw(
    build_normalized_semantic_report_contract
    normalized_semantic_composition_keys
    normalized_semantic_forward_ir_keys
    normalized_semantic_matched_failure_support_accounting_keys
    normalized_semantic_matched_success_support_accounting_keys
    normalized_semantic_public_top_level_keys
    normalized_semantic_success_only_top_level_keys
    normalized_semantic_success_semantic_keys
    normalized_semantic_support_accounting_keys
);

sub build_normalized_semantic_report_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => 'FSM::Support::NormalizedSemanticReportContract',
        report_source => 'FSM::Support::NormalizedSemanticReport',
        entrypoints => {
            cli => './bin/fsmgen --strict --emit-semantic-json path/to/file.fsm',
            cli_aliases => [
                './bin/fsmgen --strict --semantic-json path/to/file.fsm',
                './bin/fsmgen --strict --emit-normalized-json path/to/file.fsm',
                './bin/fsmgen --strict --normalized-json path/to/file.fsm',
            ],
            in_process => [
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_success_report(...)',
                'FSM::Support::NormalizedSemanticReport::build_normalized_semantic_failure_report(...)',
            ],
        },
        emits_hdl => JSON::PP::false,
        emits_support_accounting_object => JSON::PP::true,
        failure_diagnostics_reuse_stable_codes => JSON::PP::true,
        sanitizes_private_perl_objects => JSON::PP::true,
        public_layers => [qw(intent_hir lowered_rtl_ir structural_rtl_ir)],
        source_contract_source => 'FSM::Support::ReportSourceContract',
        support_accounting_contract_source => 'FSM::Support::SupportAccountingMatchContract',
        public_top_level_presence_keys => normalized_semantic_public_top_level_keys(),
        source_presence_keys => report_source_presence_keys(),
        success_only_top_level_keys => normalized_semantic_success_only_top_level_keys(),
        support_accounting_presence_keys => normalized_semantic_support_accounting_keys(),
        matched_success_support_accounting_presence_keys => normalized_semantic_matched_success_support_accounting_keys(),
        matched_failure_support_accounting_presence_keys => normalized_semantic_matched_failure_support_accounting_keys(),
        success_semantic_presence_keys => normalized_semantic_success_semantic_keys(),
        success_forward_ir_presence_keys => normalized_semantic_forward_ir_keys(),
        composition_presence_keys => normalized_semantic_composition_keys(),
        failure_omits_semantic_payload => JSON::PP::true,
        full_report_json_safe => JSON::PP::true,
        full_export_stable => JSON::PP::false,
        guidance => [
            'Treat the listed top-level and bounded nested key-presence lists as the public normalized semantic JSON contract for schema version 1.',
            'The nested source object is shared with check JSON and stays bounded through FSM::Support::ReportSourceContract.',
            'Do not treat every nested scalar/list/hash field inside those branches as frozen unless it is separately documented and regression-backed.',
            'Use the contract owner plus regression coverage to widen this surface deliberately instead of dumping raw pipeline state.',
        ],
    };
}

sub normalized_semantic_public_top_level_keys {
    return [
        qw(
            normalized_semantic_schema_version
            producer
            command
            source
            success
            diagnostics
            support_accounting
            generated_output
        ),
    ];
}

sub normalized_semantic_success_only_top_level_keys {
    return [
        qw(semantic),
    ];
}

sub normalized_semantic_support_accounting_keys {
    return support_accounting_match_common_keys();
}

sub normalized_semantic_matched_success_support_accounting_keys {
    return support_accounting_match_success_keys();
}

sub normalized_semantic_matched_failure_support_accounting_keys {
    return support_accounting_match_failure_keys();
}

sub normalized_semantic_success_semantic_keys {
    return [
        qw(
            module
            system_contract
            explicit_system_contract
            signal_analysis
            forward_ir
        ),
    ];
}

sub normalized_semantic_forward_ir_keys {
    return [
        qw(
            intent_hir
            lowered_rtl_ir
            structural_rtl_ir
        ),
    ];
}

sub normalized_semantic_composition_keys {
    return [
        qw(
            lane
            child_count
            children
            net_count
            resolved_link_count
            generated_child_count
            generated_children
            standalone_dt_child_count
            standalone_dt_children
            shared_datapath_candidate_count
            shared_datapath_candidates
            provenance_report
        ),
    ];
}

1;
