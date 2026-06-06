#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CheckFailureDiagnosticContract qw(
    check_failure_diagnostic_contract_source
    check_failure_diagnostic_matched_presence_keys
    check_failure_diagnostic_presence_keys
    check_failure_diagnostic_support_accounting_matched_presence_keys
    check_failure_diagnostic_support_accounting_presence_keys
);
use FSM::Support::ReportCommandContract qw(
    report_command_contract_source
);
use FSM::Support::ReportGeneratedOutputContract qw(
    report_generated_output_contract_source
);
use FSM::Support::SerializableGenerationResultSnapshot qw(
    serializable_generation_result_snapshot_contract_source
);
use FSM::Support::SerializableDiagnosticSummary qw(
    serializable_diagnostic_summary_contract_source
);
use FSM::Support::ReportProducerContract qw(
    report_producer_contract_source
);
use FSM::Support::ReportSourceContract qw(
    report_source_contract_source
);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_contract_source
);
use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_contract_source
    normalized_semantic_composition_presence_keys
);
use FSM::Support::NormalizedSemanticExplicitSystemContract qw(
    normalized_semantic_explicit_system_contract_source
    normalized_semantic_explicit_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticForwardIRContract qw(
    normalized_semantic_forward_ir_contract_source
    normalized_semantic_forward_ir_intent_hir_contract_source
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_intent_hir_presence_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_contract_source
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys
    normalized_semantic_forward_ir_structural_rtl_ir_contract_source
    normalized_semantic_forward_ir_structural_rtl_ir_presence_keys
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    build_normalized_semantic_report_contract
    normalized_semantic_report_contract_source
    normalized_semantic_composition_child_entry_keys
    normalized_semantic_composition_child_parameter_override_entry_keys
    normalized_semantic_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_generated_child_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_keys
    normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_assertion_keys
    normalized_semantic_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_composition_standalone_dt_child_entry_keys
    normalized_semantic_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_explicit_system_contract_keys
    normalized_semantic_failure_diagnostic_keys
    normalized_semantic_failure_diagnostic_support_accounting_keys
    normalized_semantic_forward_ir_keys
    normalized_semantic_forward_ir_intent_hir_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds
    normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning
    normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_keys
    normalized_semantic_matched_failure_diagnostic_keys
    normalized_semantic_matched_failure_diagnostic_support_accounting_keys
    normalized_semantic_matched_failure_support_accounting_keys
    normalized_semantic_matched_success_support_accounting_keys
    normalized_semantic_module_keys
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_nested_presence_key_map
    normalized_semantic_presence_key_family_map
    normalized_semantic_public_top_level_keys
    normalized_semantic_signal_analysis_entry_keys
    normalized_semantic_signal_analysis_keys
    normalized_semantic_system_contract_keys
    normalized_semantic_symbol_contract_keys
    normalized_semantic_success_only_top_level_keys
    normalized_semantic_success_semantic_optional_child_presence_keys
    normalized_semantic_success_semantic_keys
    normalized_semantic_support_accounting_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
    normalized_semantic_payload_contract_source
    normalized_semantic_payload_composition_child_entry_keys
    normalized_semantic_payload_composition_child_parameter_override_entry_keys
    normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_composition_generated_child_entry_keys
    normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_composition_keys
    normalized_semantic_payload_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_payload_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_payload_composition_shared_datapath_assertion_keys
    normalized_semantic_payload_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_payload_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_payload_composition_standalone_dt_child_entry_keys
    normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_payload_explicit_system_contract_keys
    normalized_semantic_payload_forward_ir_nested_contract_source_map
    normalized_semantic_payload_forward_ir_nested_presence_key_map
    normalized_semantic_payload_nested_presence_key_map
    normalized_semantic_payload_presence_key_family_map
    normalized_semantic_payload_forward_ir_intent_hir_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_child_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys
    normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds
    normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning
    normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_presence_keys
    normalized_semantic_payload_optional_child_presence_keys
    normalized_semantic_payload_signal_analysis_keys
    normalized_semantic_payload_system_contract_keys
    normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_payload_symbol_contract_constant_value_entry_keys
    normalized_semantic_payload_symbol_contract_keys
);
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(
    normalized_semantic_signal_analysis_contract_source
    normalized_semantic_signal_analysis_entry_presence_keys
    normalized_semantic_signal_analysis_presence_keys
);
use FSM::Support::NormalizedSemanticSystemContract qw(
    normalized_semantic_system_contract_source
    normalized_semantic_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    normalized_semantic_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_symbol_contract_constant_value_entry_keys
    normalized_semantic_symbol_contract_source
    normalized_semantic_symbol_contract_presence_keys
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_contract_source
);
use FSM::Support::ReportCommandContract qw(report_command_presence_keys);
use FSM::Support::ReportGeneratedOutputContract qw(report_generated_output_presence_keys);
use FSM::Support::ReportProducerContract qw(
    normalized_semantic_report_producer_extra_keys
    report_producer_common_keys
);
use FSM::Support::ReportSourceContract qw(report_source_presence_keys);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'contract exposes the bounded normalized semantic surface' => sub {
    my $contract = build_normalized_semantic_report_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks normalized semantic JSON as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_report_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::NormalizedSemanticReport',
        'contract records the normalized semantic report owner',
    );
    ok(!$contract->{emits_hdl}, 'contract says normalized semantic JSON emits no HDL');
    ok($contract->{emits_support_accounting_object}, 'contract says normalized semantic JSON emits support accounting');
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            command => report_command_contract_source(),
            failure_diagnostic => check_failure_diagnostic_contract_source(),
            diagnostic_summary => serializable_diagnostic_summary_contract_source(),
            generated_output => report_generated_output_contract_source(),
            generation_result_snapshot => serializable_generation_result_snapshot_contract_source(),
            composition => normalized_semantic_composition_contract_source(),
            explicit_system_contract => normalized_semantic_explicit_system_contract_source(),
            forward_ir => normalized_semantic_forward_ir_contract_source(),
            module => normalized_semantic_module_contract_source(),
            semantic => normalized_semantic_payload_contract_source(),
            signal_analysis => normalized_semantic_signal_analysis_contract_source(),
            system_contract => normalized_semantic_system_contract_source(),
            symbol_contract => normalized_semantic_symbol_contract_source(),
            producer => report_producer_contract_source(),
            source => report_source_contract_source(),
            support_accounting => support_accounting_match_contract_source(),
        },
        'contract publishes the bounded normalized-semantic nested-contract ownership map',
    );
    is_deeply(
        $contract->{forward_ir_nested_contract_source_map},
        normalized_semantic_payload_forward_ir_nested_contract_source_map(),
        'contract publishes the bounded grouped forward-ir child-owner map',
    );
    is_deeply(
        $contract->{forward_ir_nested_presence_key_map},
        normalized_semantic_payload_forward_ir_nested_presence_key_map(),
        'contract publishes the bounded grouped forward-ir child key-family map',
    );
    is_deeply(
        $contract->{semantic_nested_presence_key_map},
        normalized_semantic_payload_nested_presence_key_map(),
        'contract publishes the bounded grouped semantic child key-family map',
    );
    is_deeply(
        $contract->{semantic_presence_key_family_map},
        normalized_semantic_payload_presence_key_family_map(),
        'contract republishes the grouped semantic payload shell key-family map',
    );
    is_deeply(
        $contract->{nested_presence_key_map},
        normalized_semantic_nested_presence_key_map(),
        'contract publishes the bounded normalized-semantic nested key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_presence_key_family_map(),
        'contract publishes the bounded normalized-semantic shell-owned key-family map',
    );
    is(
        $contract->{command_contract_source},
        report_command_contract_source(),
        'contract records the shared command nested-object owner',
    );
    is(
        $contract->{failure_diagnostic_contract_source},
        check_failure_diagnostic_contract_source(),
        'contract records the shared failure diagnostic nested-object owner',
    );
    is(
        $contract->{diagnostic_summary_contract_source},
        serializable_diagnostic_summary_contract_source(),
        'contract records the diagnostic summary owner',
    );
    is(
        $contract->{generated_output_contract_source},
        report_generated_output_contract_source(),
        'contract records the shared generated_output nested-object owner',
    );
    is(
        $contract->{generation_result_snapshot_contract_source},
        serializable_generation_result_snapshot_contract_source(),
        'contract records the success-only generation-result snapshot owner',
    );
    is(
        $contract->{composition_contract_source},
        normalized_semantic_composition_contract_source(),
        'contract records the nested composition object owner',
    );
    is(
        $contract->{explicit_system_contract_source},
        normalized_semantic_explicit_system_contract_source(),
        'contract records the nested explicit-system-contract object owner',
    );
    is(
        $contract->{signal_analysis_contract_source},
        normalized_semantic_signal_analysis_contract_source(),
        'contract records the nested signal-analysis object owner',
    );
    is(
        $contract->{forward_ir_contract_source},
        normalized_semantic_forward_ir_contract_source(),
        'contract records the nested forward-IR object owner',
    );
    is(
        $contract->{module_contract_source},
        normalized_semantic_module_contract_source(),
        'contract records the nested module object owner',
    );
    is(
        $contract->{semantic_contract_source},
        normalized_semantic_payload_contract_source(),
        'contract records the semantic success payload owner',
    );
    is(
        $contract->{system_contract_source},
        normalized_semantic_system_contract_source(),
        'contract records the nested system-contract object owner',
    );
    is(
        $contract->{symbol_contract_source},
        normalized_semantic_symbol_contract_source(),
        'contract records the nested symbol-contract object owner',
    );
    is(
        $contract->{producer_contract_source},
        report_producer_contract_source(),
        'contract records the shared producer nested-object owner',
    );
    is(
        $contract->{source_contract_source},
        report_source_contract_source(),
        'contract records the shared source nested-object owner',
    );
    is(
        $contract->{support_accounting_contract_source},
        support_accounting_match_contract_source(),
        'contract records the shared support-accounting nested-object owner',
    );
    ok($contract->{failure_omits_semantic_payload}, 'contract says failed reports omit semantic payload');
    ok($contract->{full_report_json_safe}, 'contract says the emitted report is JSON-safe');
    ok(!$contract->{full_export_stable}, 'contract keeps full export stabilization out of the bounded promise');

    is_deeply(
        $contract->{public_top_level_presence_keys},
        normalized_semantic_public_top_level_keys(),
        'contract publishes the bounded top-level key list',
    );
    is_deeply(
        $contract->{success_only_top_level_keys},
        normalized_semantic_success_only_top_level_keys(),
        'contract publishes the success-only top-level key list',
    );
    is_deeply(
        $contract->{command_presence_keys},
        report_command_presence_keys(),
        'contract publishes the bounded command-object key list',
    );
    is_deeply(
        $contract->{generated_output_presence_keys},
        report_generated_output_presence_keys(),
        'contract publishes the bounded generated_output-object key list',
    );
    is_deeply(
        $contract->{producer_presence_keys},
        report_producer_common_keys(),
        'contract publishes the bounded producer-object common key list',
    );
    is_deeply(
        $contract->{producer_extra_presence_keys},
        normalized_semantic_report_producer_extra_keys(),
        'contract publishes the bounded normalized-semantic producer extra key list',
    );
    is_deeply(
        $contract->{source_presence_keys},
        report_source_presence_keys(),
        'contract publishes the bounded source-object key list',
    );
    is_deeply(
        $contract->{support_accounting_presence_keys},
        normalized_semantic_support_accounting_keys(),
        'contract publishes the common support-accounting key list',
    );
    is_deeply(
        $contract->{failure_diagnostic_presence_keys},
        normalized_semantic_failure_diagnostic_keys(),
        'contract publishes the bounded failure-diagnostic key list',
    );
    is_deeply(
        normalized_semantic_failure_diagnostic_keys(),
        check_failure_diagnostic_presence_keys(),
        'normalized semantic failure-diagnostic keys map to the shared failure-diagnostic owner',
    );
    is_deeply(
        $contract->{matched_failure_diagnostic_presence_keys},
        normalized_semantic_matched_failure_diagnostic_keys(),
        'contract publishes the matched failure-diagnostic key list',
    );
    is_deeply(
        normalized_semantic_matched_failure_diagnostic_keys(),
        check_failure_diagnostic_matched_presence_keys(),
        'normalized semantic matched failure-diagnostic keys map to the shared failure-diagnostic owner',
    );
    is_deeply(
        $contract->{failure_diagnostic_support_accounting_presence_keys},
        normalized_semantic_failure_diagnostic_support_accounting_keys(),
        'contract publishes the common failure-diagnostic support-accounting key list',
    );
    is_deeply(
        normalized_semantic_failure_diagnostic_support_accounting_keys(),
        check_failure_diagnostic_support_accounting_presence_keys(),
        'normalized semantic failure-diagnostic support-accounting keys map to the shared failure-diagnostic owner',
    );
    is_deeply(
        $contract->{matched_failure_diagnostic_support_accounting_presence_keys},
        normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        'contract publishes the matched failure-diagnostic support-accounting key list',
    );
    is_deeply(
        normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        check_failure_diagnostic_support_accounting_matched_presence_keys(),
        'normalized semantic matched failure-diagnostic support-accounting keys map to the shared failure-diagnostic owner',
    );
    is_deeply(
        $contract->{matched_success_support_accounting_presence_keys},
        normalized_semantic_matched_success_support_accounting_keys(),
        'contract publishes the matched success support-accounting key list',
    );
    is_deeply(
        $contract->{matched_failure_support_accounting_presence_keys},
        normalized_semantic_matched_failure_support_accounting_keys(),
        'contract publishes the matched failure support-accounting key list',
    );
    is_deeply(
        $contract->{success_semantic_presence_keys},
        normalized_semantic_payload_presence_keys(),
        'contract publishes the bounded semantic payload key list',
    );
    is_deeply(
        $contract->{success_semantic_optional_child_presence_keys},
        normalized_semantic_success_semantic_optional_child_presence_keys(),
        'contract publishes the optional semantic child key list',
    );
    is_deeply(
        normalized_semantic_success_semantic_optional_child_presence_keys(),
        normalized_semantic_payload_optional_child_presence_keys(),
        'report optional semantic child keys map to the payload owner',
    );
    is_deeply(
        $contract->{semantic_presence_key_family_map}{optional_child_presence_keys},
        normalized_semantic_payload_optional_child_presence_keys(),
        'semantic presence family map republishes optional payload children',
    );
    is_deeply(
        $contract->{semantic_presence_key_family_map}{composition_child_entry_keys},
        normalized_semantic_payload_composition_child_entry_keys(),
        'semantic presence family map republishes composition child entry keys',
    );
    for my $case (
        [
            'composition_child_parameter_override_entry_keys',
            normalized_semantic_payload_composition_child_parameter_override_entry_keys(),
        ],
        [
            'composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys(),
        ],
    ) {
        is_deeply(
            $contract->{semantic_presence_key_family_map}{$case->[0]},
            $case->[1],
            "semantic presence family map republishes $case->[0]",
        );
    }
    is_deeply(
        $contract->{semantic_presence_key_family_map}{composition_generated_child_entry_keys},
        normalized_semantic_payload_composition_generated_child_entry_keys(),
        'semantic presence family map republishes composition generated-child entry keys',
    );
    for my $case (
        [
            'composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys(),
        ],
        [
            'composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        ],
    ) {
        is_deeply(
            $contract->{semantic_presence_key_family_map}{$case->[0]},
            $case->[1],
            "semantic presence family map republishes $case->[0]",
        );
    }
    is_deeply(
        $contract->{semantic_presence_key_family_map}{composition_standalone_dt_child_entry_keys},
        normalized_semantic_payload_composition_standalone_dt_child_entry_keys(),
        'semantic presence family map republishes composition standalone-DT child entry keys',
    );
    is_deeply(
        $contract->{semantic_presence_key_family_map}{composition_standalone_dt_enable_family_entry_keys},
        normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys(),
        'semantic presence family map republishes composition standalone-DT enable-family entry keys',
    );
    is_deeply(
        $contract->{semantic_presence_key_family_map}{composition_standalone_dt_module_enable_family_keys},
        normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys(),
        'semantic presence family map republishes composition standalone-DT module-enable-family keys',
    );
    is_deeply(
        $contract->{semantic_presence_key_family_map}{composition_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys(),
        'semantic presence family map republishes composition standalone-DT multi-drive target entry keys',
    );
    is_deeply(
        $contract->{semantic_presence_key_family_map}{composition_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys(),
        'semantic presence family map republishes composition standalone-DT multi-drive assertion keys',
    );
    for my $case (composition_shared_datapath_alias_cases()) {
        my ($field, $report_helper, $payload_helper) = @{$case};
        is_deeply(
            $contract->{semantic_presence_key_family_map}{$field},
            $payload_helper->(),
            "semantic presence family map republishes $field",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{success_semantic_optional_child_presence_keys},
        normalized_semantic_success_semantic_optional_child_presence_keys(),
        'report presence family map publishes optional semantic children',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_child_entry_keys},
        normalized_semantic_composition_child_entry_keys(),
        'report presence family map publishes composition child entry keys',
    );
    for my $case (
        [
            'composition_child_parameter_override_entry_keys',
            normalized_semantic_composition_child_parameter_override_entry_keys(),
        ],
        [
            'composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_composition_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys(),
        ],
    ) {
        is_deeply(
            $contract->{presence_key_family_map}{$case->[0]},
            $case->[1],
            "report presence family map publishes $case->[0]",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{composition_generated_child_entry_keys},
        normalized_semantic_composition_generated_child_entry_keys(),
        'report presence family map publishes composition generated-child entry keys',
    );
    for my $case (
        [
            'composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_composition_generated_child_parameter_override_entry_keys(),
        ],
        [
            'composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        ],
    ) {
        is_deeply(
            $contract->{presence_key_family_map}{$case->[0]},
            $case->[1],
            "report presence family map publishes $case->[0]",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_child_entry_keys},
        normalized_semantic_composition_standalone_dt_child_entry_keys(),
        'report presence family map publishes composition standalone-DT child entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_enable_family_entry_keys},
        normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        'report presence family map publishes composition standalone-DT enable-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_module_enable_family_keys},
        normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        'report presence family map publishes composition standalone-DT module-enable-family keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        'report presence family map publishes composition standalone-DT multi-drive target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{composition_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        'report presence family map publishes composition standalone-DT multi-drive assertion keys',
    );
    for my $case (composition_shared_datapath_alias_cases()) {
        my ($field, $report_helper) = @{$case};
        is_deeply(
            $contract->{presence_key_family_map}{$field},
            $report_helper->(),
            "report presence family map publishes $field",
        );
    }
    is_deeply(
        $contract->{success_module_presence_keys},
        normalized_semantic_module_keys(),
        'contract publishes the bounded module key list',
    );
    is_deeply(
        normalized_semantic_module_keys(),
        FSM::Support::NormalizedSemanticModuleContract::normalized_semantic_module_presence_keys(),
        'normalized semantic module keys map to the nested module owner',
    );
    is_deeply(
        $contract->{success_module_optional_metric_keys},
        normalized_semantic_module_optional_metric_keys(),
        'contract publishes the bounded optional module metric key list',
    );
    is_deeply(
        normalized_semantic_module_optional_metric_keys(),
        FSM::Support::NormalizedSemanticModuleContract::normalized_semantic_module_optional_metric_keys(),
        'normalized semantic optional module metric keys map to the nested module owner',
    );
    is_deeply(
        $contract->{success_explicit_system_contract_presence_keys},
        normalized_semantic_explicit_system_contract_keys(),
        'contract publishes the bounded explicit-system-contract key list',
    );
    is_deeply(
        normalized_semantic_explicit_system_contract_keys(),
        normalized_semantic_explicit_system_contract_presence_keys(),
        'normalized semantic explicit-system-contract keys map to the nested explicit-system-contract owner',
    );
    is_deeply(
        normalized_semantic_payload_explicit_system_contract_keys(),
        normalized_semantic_explicit_system_contract_presence_keys(),
        'semantic payload explicit-system-contract keys map to the nested explicit-system-contract owner',
    );
    is_deeply(
        $contract->{success_signal_analysis_presence_keys},
        normalized_semantic_signal_analysis_keys(),
        'contract publishes the bounded signal-analysis key list',
    );
    is_deeply(
        $contract->{success_signal_analysis_entry_presence_keys},
        normalized_semantic_signal_analysis_entry_keys(),
        'contract publishes the bounded signal-analysis entry key list',
    );
    is_deeply(
        normalized_semantic_signal_analysis_entry_keys(),
        normalized_semantic_signal_analysis_entry_presence_keys(),
        'normalized semantic signal-analysis entry keys map to the nested signal-analysis owner',
    );
    is_deeply(
        normalized_semantic_signal_analysis_keys(),
        normalized_semantic_signal_analysis_presence_keys(),
        'normalized semantic signal-analysis keys map to the nested signal-analysis owner',
    );
    is_deeply(
        normalized_semantic_payload_signal_analysis_keys(),
        normalized_semantic_signal_analysis_presence_keys(),
        'semantic payload signal-analysis keys map to the nested signal-analysis owner',
    );
    is_deeply(
        $contract->{success_system_contract_presence_keys},
        normalized_semantic_system_contract_keys(),
        'contract publishes the bounded system-contract key list',
    );
    is_deeply(
        normalized_semantic_system_contract_keys(),
        normalized_semantic_system_contract_presence_keys(),
        'normalized semantic system-contract keys map to the nested system-contract owner',
    );
    is_deeply(
        normalized_semantic_payload_system_contract_keys(),
        normalized_semantic_system_contract_presence_keys(),
        'semantic payload system-contract keys map to the nested system-contract owner',
    );
    is_deeply(
        $contract->{success_forward_ir_presence_keys},
        normalized_semantic_forward_ir_keys(),
        'contract publishes the bounded forward-IR key list',
    );
    is(
        $contract->{forward_ir_intent_hir_contract_source},
        normalized_semantic_forward_ir_intent_hir_contract_source(),
        'contract records the nested forward-ir intent-hir object owner',
    );
    is_deeply(
        $contract->{success_forward_ir_intent_hir_presence_keys},
        normalized_semantic_forward_ir_intent_hir_keys(),
        'contract publishes the bounded forward-ir intent-hir key list',
    );
    is_deeply(
        $contract->{success_forward_ir_intent_hir_optional_composition_keys},
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'contract publishes the bounded forward-ir intent-hir composition-only key list',
    );
    for my $case (intent_hir_alias_cases()) {
        my ($report_field, $semantic_field, $report_helper, $payload_helper) = @{$case};

        is_deeply(
            $contract->{$report_field},
            $report_helper->(),
            "contract publishes the bounded $report_field",
        );
        is_deeply(
            $contract->{presence_key_family_map}{$report_field},
            $report_helper->(),
            "report presence family map publishes $report_field",
        );
        is_deeply(
            $contract->{semantic_presence_key_family_map}{$semantic_field},
            $payload_helper->(),
            "semantic payload family map publishes $semantic_field",
        );
        is_deeply(
            $report_helper->(),
            $payload_helper->(),
            "$report_field maps to the semantic payload owner",
        );
    }
    is(
        $contract->{forward_ir_lowered_rtl_ir_contract_source},
        normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        'contract records the nested forward-ir lowered-rtl-ir object owner',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_presence_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_optional_composition_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir composition-only key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive family entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive rhs-family key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict target entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict rhs-enable-family entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict multi-value assertion key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict same-value assertion key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir standalone-DT multi-drive target entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir standalone-DT multi-drive assertion key list',
    );
    for my $case (
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        ],
    ) {
        is_deeply(
            $contract->{$case->[0]},
            $case->[1],
            "contract publishes the bounded $case->[0]",
        );
    }
    is(
        $contract->{forward_ir_structural_rtl_ir_contract_source},
        normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        'contract records the nested forward-ir structural-rtl-ir object owner',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_presence_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds},
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'contract publishes the bounded forward-ir structural-rtl-ir auxiliary-assignment entry value-kind family',
    );
    is(
        $contract->{success_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning},
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        'contract publishes the bounded forward-ir structural-rtl-ir auxiliary-assignment entry value meaning',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port composition extension key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_net_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir net entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir declared-link entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir resolved-link entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_instance_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance shallow entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance interface-port entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance parameter-override core entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance parameter-override raw-value extension key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance parameter-override value-metadata extension key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance port-binding core entry key list',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance port-binding typed extension key list',
    );
    is_deeply(
        normalized_semantic_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'normalized semantic forward-IR keys map to the nested forward-IR owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_intent_hir_keys(),
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'normalized semantic report forward-ir intent-hir keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'normalized semantic report forward-ir intent-hir composition keys map to the nested intent-hir owner',
    );
    for my $case (intent_hir_alias_cases()) {
        my ($report_field, $semantic_field, $report_helper) = @{$case};
        my $forward_helper_name = "normalized_semantic_$semantic_field";

        is_deeply(
            $report_helper->(),
            FSM::Support::NormalizedSemanticForwardIRContract->$forward_helper_name(),
            "normalized semantic report $report_field maps to the nested intent-hir owner",
        );
    }
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'normalized semantic report forward-ir lowered-rtl-ir keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'normalized semantic report forward-ir lowered-rtl-ir composition keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'report presence family map publishes selector-conflict target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'report presence family map publishes output-drive family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'report presence family map publishes output-drive rhs-enable-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'report presence family map publishes selector-conflict rhs-enable-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'report presence family map publishes standalone-DT multi-drive target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'report presence family map publishes standalone-DT multi-drive assertion keys',
    );
    for my $case (
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
        ],
    ) {
        is_deeply(
            $contract->{presence_key_family_map}{$case->[0]},
            $case->[1],
            "report presence family map publishes $case->[0]",
        );
    }
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds},
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'report presence family map publishes structural-rtl-ir auxiliary-assignment entry value kinds',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'report presence family map publishes structural-rtl-ir port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'report presence family map publishes structural-rtl-ir port composition extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_net_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'report presence family map publishes structural-rtl-ir net entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'report presence family map publishes structural-rtl-ir declared-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'report presence family map publishes structural-rtl-ir resolved-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_instance_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'report presence family map publishes structural-rtl-ir instance shallow entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'report presence family map publishes structural-rtl-ir instance interface-port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'report presence family map publishes structural-rtl-ir instance parameter-override core entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'report presence family map publishes structural-rtl-ir instance parameter-override raw-value extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'report presence family map publishes structural-rtl-ir instance parameter-override value-metadata extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'report presence family map publishes structural-rtl-ir instance port-binding core entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{success_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'report presence family map publishes structural-rtl-ir instance port-binding typed extension keys',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'normalized semantic report forward-ir structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_intent_hir_keys(),
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'semantic payload forward-ir intent-hir keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'semantic payload forward-ir intent-hir composition keys map to the nested intent-hir owner',
    );
    for my $case (intent_hir_alias_cases()) {
        my ($report_field, $semantic_field, undef, $payload_helper) = @{$case};
        my $forward_helper_name = "normalized_semantic_$semantic_field";

        is_deeply(
            $payload_helper->(),
            FSM::Support::NormalizedSemanticForwardIRContract->$forward_helper_name(),
            "semantic payload $semantic_field maps to the nested intent-hir owner",
        );
    }
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'semantic payload forward-ir lowered-rtl-ir keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'semantic payload forward-ir lowered-rtl-ir composition keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir output-drive family entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir output-drive rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir standalone-DT multi-drive target entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'semantic payload forward-ir lowered-rtl-ir standalone-DT multi-drive assertion keys map to the nested lowered-rtl-ir owner',
    );
    for my $case (
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
            'candidate entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
            'candidate declared-type extension',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
            'candidate contributor entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
            'candidate contributor declared-type extension',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
            'candidate contributor drive-intent entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
            'candidate contributor drive-intent rhs-enable-family entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
            'bound connection expression',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            'aggregate-enable family entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
            'aggregate-enable contributor entry',
        ],
        [
            normalized_semantic_payload_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
            FSM::Support::NormalizedSemanticForwardIRContract::normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
            'assertion metadata',
        ],
    ) {
        is_deeply(
            $case->[0],
            $case->[1],
            "semantic payload forward-ir lowered-rtl-ir shared-datapath $case->[2] keys map to the nested lowered-rtl-ir owner",
        );
    }
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'semantic payload forward-ir structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'semantic payload forward-ir structural-rtl-ir auxiliary-assignment entry value kinds map to the nested structural-rtl-ir owner',
    );
    is(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        'semantic payload forward-ir structural-rtl-ir auxiliary-assignment entry value meaning maps to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir port composition extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir net entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir declared-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir resolved-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir instance shallow entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir instance interface-port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir instance parameter-override core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir instance parameter-override raw-value extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir instance parameter-override value-metadata extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'semantic payload forward-ir structural-rtl-ir instance port-binding core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'semantic payload forward-ir structural-rtl-ir instance port-binding typed extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        $contract->{composition_presence_keys},
        normalized_semantic_payload_composition_keys(),
        'contract publishes the bounded composition key list',
    );
    is_deeply(
        $contract->{success_symbol_contract_presence_keys},
        normalized_semantic_symbol_contract_keys(),
        'contract publishes the bounded symbol-contract key list',
    );
    is_deeply(
        normalized_semantic_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'normalized semantic symbol-contract keys map to the nested symbol-contract owner',
    );
    is_deeply(
        normalized_semantic_payload_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'semantic payload symbol-contract keys map to the nested symbol-contract owner',
    );
    for my $case (
        [
            'symbol_contract_constant_value_entry_keys',
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_symbol_contract_constant_value_entry_keys(),
            normalized_semantic_payload_symbol_contract_constant_value_entry_keys(),
            FSM::Support::NormalizedSemanticSymbolContract::normalized_semantic_symbol_contract_constant_value_entry_keys(),
            'constant value core keys',
        ],
        [
            'symbol_contract_constant_scalar_value_extension_keys',
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
            normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys(),
            FSM::Support::NormalizedSemanticSymbolContract::normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
            'scalar constant value extension keys',
        ],
        [
            'symbol_contract_constant_list_value_extension_keys',
            FSM::Support::NormalizedSemanticReportContract::normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
            normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys(),
            FSM::Support::NormalizedSemanticSymbolContract::normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
            'list constant value extension keys',
        ],
    ) {
        my ($field, $report_keys, $payload_keys, $symbol_keys, $label) = @{$case};

        is_deeply(
            $contract->{$field},
            $report_keys,
            "contract publishes the bounded symbol-contract $label",
        );
        is_deeply(
            $contract->{presence_key_family_map}{$field},
            $report_keys,
            "grouped report family map publishes symbol-contract $label",
        );
        is_deeply(
            $report_keys,
            $payload_keys,
            "normalized semantic report symbol-contract $label map to the payload owner",
        );
        is_deeply(
            $payload_keys,
            $symbol_keys,
            "semantic payload symbol-contract $label map to the nested symbol-contract owner",
        );
    }
    is_deeply(
        normalized_semantic_composition_keys(),
        normalized_semantic_composition_presence_keys(),
        'normalized semantic composition keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_child_entry_keys},
        normalized_semantic_composition_child_entry_keys(),
        'contract publishes the bounded composition child entry key list',
    );
    is_deeply(
        normalized_semantic_composition_child_entry_keys(),
        normalized_semantic_payload_composition_child_entry_keys(),
        'normalized semantic composition child entry keys map to the payload owner',
    );
    is_deeply(
        normalized_semantic_composition_child_entry_keys(),
        FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_child_entry_keys(),
        'normalized semantic composition child entry keys map to the nested composition owner',
    );
    for my $case (
        [
            'composition_child_parameter_override_entry_keys',
            normalized_semantic_composition_child_parameter_override_entry_keys(),
            normalized_semantic_payload_composition_child_parameter_override_entry_keys(),
            FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_child_parameter_override_entry_keys(),
            'core entry',
        ],
        [
            'composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_composition_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_payload_composition_child_parameter_override_raw_value_extension_keys(),
            FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_child_parameter_override_raw_value_extension_keys(),
            'raw-value extension',
        ],
        [
            'composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_payload_composition_child_parameter_override_value_metadata_extension_keys(),
            FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys(),
            'value-metadata extension',
        ],
    ) {
        my ($field, $report_keys, $payload_keys, $composition_keys, $label) = @{$case};

        is_deeply(
            $contract->{$field},
            $report_keys,
            "contract publishes composition child parameter-override $label keys",
        );
        is_deeply(
            $report_keys,
            $payload_keys,
            "normalized semantic composition child parameter-override $label keys map to the payload owner",
        );
        is_deeply(
            $report_keys,
            $composition_keys,
            "normalized semantic composition child parameter-override $label keys map to the nested composition owner",
        );
    }
    is_deeply(
        $contract->{composition_generated_child_entry_keys},
        normalized_semantic_composition_generated_child_entry_keys(),
        'contract publishes the bounded composition generated-child entry key list',
    );
    is_deeply(
        normalized_semantic_composition_generated_child_entry_keys(),
        normalized_semantic_payload_composition_generated_child_entry_keys(),
        'normalized semantic composition generated-child entry keys map to the payload owner',
    );
    is_deeply(
        normalized_semantic_composition_generated_child_entry_keys(),
        FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_generated_child_entry_keys(),
        'normalized semantic composition generated-child entry keys map to the nested composition owner',
    );
    for my $case (
        [
            'composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_composition_generated_child_parameter_override_entry_keys(),
            normalized_semantic_payload_composition_generated_child_parameter_override_entry_keys(),
            FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_generated_child_parameter_override_entry_keys(),
            'core entry',
        ],
        [
            'composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_payload_composition_generated_child_parameter_override_raw_value_extension_keys(),
            FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys(),
            'raw-value extension',
        ],
        [
            'composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_payload_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            'value-metadata extension',
        ],
    ) {
        my ($field, $report_keys, $payload_keys, $composition_keys, $label) = @{$case};

        is_deeply(
            $contract->{$field},
            $report_keys,
            "contract publishes composition generated-child parameter-override $label keys",
        );
        is_deeply(
            $report_keys,
            $payload_keys,
            "normalized semantic composition generated-child parameter-override $label keys map to the payload owner",
        );
        is_deeply(
            $report_keys,
            $composition_keys,
            "normalized semantic composition generated-child parameter-override $label keys map to the nested composition owner",
        );
    }
    is_deeply(
        $contract->{composition_standalone_dt_child_entry_keys},
        normalized_semantic_composition_standalone_dt_child_entry_keys(),
        'contract publishes the bounded composition standalone-DT child entry key list',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_child_entry_keys(),
        normalized_semantic_payload_composition_standalone_dt_child_entry_keys(),
        'normalized semantic composition standalone-DT child entry keys map to the payload owner',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_child_entry_keys(),
        FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_standalone_dt_child_entry_keys(),
        'normalized semantic composition standalone-DT child entry keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_standalone_dt_enable_family_entry_keys},
        normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        'contract publishes the bounded composition standalone-DT enable-family entry key list',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        normalized_semantic_payload_composition_standalone_dt_enable_family_entry_keys(),
        'normalized semantic composition standalone-DT enable-family entry keys map to the payload owner',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        'normalized semantic composition standalone-DT enable-family entry keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_standalone_dt_module_enable_family_keys},
        normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        'contract publishes the bounded composition standalone-DT module-enable-family key list',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        normalized_semantic_payload_composition_standalone_dt_module_enable_family_keys(),
        'normalized semantic composition standalone-DT module-enable-family keys map to the payload owner',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        'normalized semantic composition standalone-DT module-enable-family keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        'contract publishes the bounded composition standalone-DT multi-drive target entry key list',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        normalized_semantic_payload_composition_standalone_dt_multi_drive_target_entry_keys(),
        'normalized semantic composition standalone-DT multi-drive target entry keys map to the payload owner',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        'normalized semantic composition standalone-DT multi-drive target entry keys map to the nested composition owner',
    );
    is_deeply(
        $contract->{composition_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        'contract publishes the bounded composition standalone-DT multi-drive assertion key list',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        normalized_semantic_payload_composition_standalone_dt_multi_drive_assertion_keys(),
        'normalized semantic composition standalone-DT multi-drive assertion keys map to the payload owner',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        FSM::Support::NormalizedSemanticCompositionContract::normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        'normalized semantic composition standalone-DT multi-drive assertion keys map to the nested composition owner',
    );
    for my $case (composition_shared_datapath_alias_cases()) {
        my ($field, $report_helper, $payload_helper) = @{$case};
        my $composition_helper_name = "normalized_semantic_$field";
        is_deeply(
            $contract->{$field},
            $report_helper->(),
            "contract publishes the bounded $field list",
        );
        is_deeply(
            $report_helper->(),
            $payload_helper->(),
            "normalized semantic $field maps to the payload owner",
        );
        is_deeply(
            $report_helper->(),
            FSM::Support::NormalizedSemanticCompositionContract->$composition_helper_name(),
            "normalized semantic $field maps to the nested composition owner",
        );
    }
};

sub composition_shared_datapath_alias_cases {
    return (
        [
            'composition_shared_datapath_candidate_entry_keys',
            \&normalized_semantic_composition_shared_datapath_candidate_entry_keys,
            \&normalized_semantic_payload_composition_shared_datapath_candidate_entry_keys,
        ],
        [
            'composition_shared_datapath_candidate_declared_type_extension_keys',
            \&normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys,
            \&normalized_semantic_payload_composition_shared_datapath_candidate_declared_type_extension_keys,
        ],
        [
            'composition_shared_datapath_candidate_contributor_entry_keys',
            \&normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys,
            \&normalized_semantic_payload_composition_shared_datapath_candidate_contributor_entry_keys,
        ],
        [
            'composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            \&normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys,
            \&normalized_semantic_payload_composition_shared_datapath_candidate_contributor_declared_type_extension_keys,
        ],
        [
            'composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            \&normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys,
            \&normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys,
        ],
        [
            'composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            \&normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys,
            \&normalized_semantic_payload_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys,
        ],
        [
            'composition_shared_datapath_bound_connection_expr_keys',
            \&normalized_semantic_composition_shared_datapath_bound_connection_expr_keys,
            \&normalized_semantic_payload_composition_shared_datapath_bound_connection_expr_keys,
        ],
        [
            'composition_shared_datapath_aggregate_enable_family_entry_keys',
            \&normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys,
            \&normalized_semantic_payload_composition_shared_datapath_aggregate_enable_family_entry_keys,
        ],
        [
            'composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            \&normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys,
            \&normalized_semantic_payload_composition_shared_datapath_aggregate_enable_contributor_entry_keys,
        ],
        [
            'composition_shared_datapath_assertion_keys',
            \&normalized_semantic_composition_shared_datapath_assertion_keys,
            \&normalized_semantic_payload_composition_shared_datapath_assertion_keys,
        ],
    );
}

sub intent_hir_alias_cases {
    return (
        [
            'success_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys',
            'forward_ir_intent_hir_symbol_contract_constant_value_entry_keys',
            \&normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys,
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys',
            'forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys',
            \&normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys,
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys',
            'forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys',
            \&normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_child_entry_keys',
            'forward_ir_intent_hir_composition_child_entry_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_child_entry_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_child_parameter_override_entry_keys',
            'forward_ir_intent_hir_composition_child_parameter_override_entry_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_entry_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys',
            'forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys',
            'forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_generated_child_entry_keys',
            'forward_ir_intent_hir_composition_generated_child_entry_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_entry_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys',
            'forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys',
            'forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys',
            'forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys',
            'forward_ir_intent_hir_composition_standalone_dt_child_entry_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys',
            'forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys',
            'forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys',
            'forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys,
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys',
            'forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys',
            \&normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys,
            \&normalized_semantic_payload_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys,
        ],
    );
}

my $ok_path = File::Spec->catfile($tempdir, 'semantic_contract_ok.fsm');
my $bad_path = File::Spec->catfile($tempdir, 'semantic_contract_bad.fsm');
my $ok_out_path = File::Spec->catfile($tempdir, 'semantic_contract_ok.sv');
my $bad_out_path = File::Spec->catfile($tempdir, 'semantic_contract_bad.sv');

write_file(
    $ok_path,
    <<'FSM'
(?fsm:semantic_contract_ok
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (COND 1)
    (SRC 8)
    (OUT 8)
  )

  (idle
    (<COND
      (= (OUT SRC))
    )
  )
)
FSM
);

write_file(
    $bad_path,
    <<'FSM'
(?fsm:semantic_contract_bad
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (SRC 8)
    (OUT 8)
  )

  (idle
    (OUT = SRC)
  )
)
FSM
);

subtest 'successful direct semantic JSON conforms to the bounded contract' => sub {
    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $ok_out_path, $ok_path],
        'strict semantic JSON succeeds for direct sample',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'direct success report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{command},
        report_command_presence_keys(),
        'direct success report keeps bounded command-object keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        report_generated_output_presence_keys(),
        'direct success report keeps bounded generated_output-object keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'direct success report keeps bounded producer-object common keys',
    );
    assert_keys_present(
        $decoded->{producer},
        normalized_semantic_report_producer_extra_keys(),
        'direct success report keeps bounded producer-object extra keys',
    );
    assert_keys_present(
        $decoded->{source},
        report_source_presence_keys(),
        'direct success report keeps bounded source-object keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'direct success report keeps common support-accounting keys',
    );
    assert_keys_present(
        $decoded,
        normalized_semantic_success_only_top_level_keys(),
        'direct success report keeps success-only top-level keys',
    );
    assert_keys_present(
        $decoded->{semantic},
        normalized_semantic_success_semantic_keys(),
        'direct success semantic payload keeps bounded semantic keys',
    );
    assert_keys_present(
        $decoded->{semantic}{module},
        normalized_semantic_module_keys(),
        'direct success module payload keeps bounded module keys',
    );
    assert_keys_present(
        $decoded->{semantic}{signal_analysis},
        normalized_semantic_signal_analysis_keys(),
        'direct success semantic payload keeps bounded signal-analysis keys',
    );
    for my $bucket (qw(inputs outputs multi_bit single_bit)) {
        next unless @{$decoded->{semantic}{signal_analysis}{$bucket} || []};
        assert_keys_present(
            $decoded->{semantic}{signal_analysis}{$bucket}[0],
            normalized_semantic_signal_analysis_entry_keys(),
            "direct success semantic payload keeps bounded signal-analysis entry keys for $bucket",
        );
    }
    assert_keys_present(
        $decoded->{semantic}{explicit_system_contract},
        normalized_semantic_explicit_system_contract_keys(),
        'direct success semantic payload keeps bounded explicit-system-contract keys',
    );
    assert_keys_present(
        $decoded->{semantic}{system_contract},
        normalized_semantic_system_contract_keys(),
        'direct success semantic payload keeps bounded system-contract keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir},
        normalized_semantic_forward_ir_keys(),
        'direct success semantic payload keeps bounded forward-IR keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{intent_hir},
        normalized_semantic_forward_ir_intent_hir_keys(),
        'direct success semantic payload keeps bounded forward-ir intent-hir keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{lowered_rtl_ir},
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        'direct success semantic payload keeps bounded forward-ir lowered-rtl-ir keys',
    );
    ok(
        exists $decoded->{semantic}{forward_ir}{lowered_rtl_ir}{selector_conflict_target_count},
        'direct success lowered-rtl-ir payload keeps selector-conflict target count',
    );
    ok(
        exists $decoded->{semantic}{forward_ir}{lowered_rtl_ir}{selector_conflict_targets},
        'direct success lowered-rtl-ir payload keeps selector-conflict target list',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{structural_rtl_ir},
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        'direct success semantic payload keeps bounded forward-ir structural-rtl-ir keys',
    );
    my $direct_port = $decoded->{semantic}{forward_ir}{structural_rtl_ir}{ports}[0];
    ok($direct_port, 'direct success structural-rtl-ir includes at least one port entry');
    assert_keys_present(
        $direct_port,
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'direct success structural-rtl-ir port entry keeps bounded keys',
    );
    for my $key (@{normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys() || []}) {
        ok(
            !exists $direct_port->{$key},
            "direct success structural-rtl-ir port entry omits composition-only key $key",
        );
    }
    for my $key (@{normalized_semantic_forward_ir_intent_hir_optional_composition_keys() || []}) {
        ok(
            !exists $decoded->{semantic}{forward_ir}{intent_hir}{$key},
            "direct success semantic payload omits composition-only intent-hir key $key",
        );
    }
    for my $key (@{normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys() || []}) {
        ok(
            !exists $decoded->{semantic}{forward_ir}{lowered_rtl_ir}{$key},
            "direct success semantic payload omits composition-only lowered-rtl-ir key $key",
        );
    }

    ok(!exists $decoded->{semantic}{composition}, 'direct success omits optional composition payload');
    ok(!exists $decoded->{semantic}{symbol_contract}, 'direct success omits optional symbol-contract payload');
    is_deeply(
        normalized_semantic_success_semantic_optional_child_presence_keys(),
        [qw(composition symbol_contract)],
        'optional semantic child key list stays bounded and ordered',
    );
    ok(!$decoded->{generated_output}{emitted}, 'direct success still records no HDL emission');
};

subtest 'selector-instrumented semantic JSON keeps bounded selector-conflict entry keys' => sub {
    my $selector_path = File::Spec->catfile($repo_root, 'fsm', 'apb_requester.fsm');
    my $selector_out_path = File::Spec->catfile($tempdir, 'semantic_contract_apb_requester.sv');

    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $selector_out_path, $selector_path],
        'strict semantic JSON succeeds for selector-instrumented direct sample',
    );
    my $selector_target = $decoded->{semantic}{forward_ir}{lowered_rtl_ir}{selector_conflict_targets}[0];
    ok($selector_target, 'selector-instrumented success includes at least one selector-conflict target entry');
    assert_keys_present(
        $selector_target,
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'selector-instrumented target entry keeps bounded keys',
    );
    my $rhs_family = $selector_target->{rhs_enable_families}[0];
    ok($rhs_family, 'selector-instrumented target includes at least one rhs-enable-family entry');
    assert_keys_present(
        $rhs_family,
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'selector-instrumented rhs-enable-family entry keeps bounded keys',
    );
    assert_keys_present(
        $selector_target->{multi_value_assertion},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'selector-instrumented multi-value assertion keeps bounded keys',
    );
    assert_keys_present(
        $rhs_family->{same_value_assertion},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'selector-instrumented same-value assertion keeps bounded keys',
    );
};

subtest 'direct semantic JSON keeps bounded output-drive entry keys' => sub {
    my $direct_path = File::Spec->catfile($repo_root, 'fsm', 'apb_requester.fsm');
    my $direct_out_path = File::Spec->catfile($tempdir, 'semantic_contract_apb_requester_output_drive.sv');

    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $direct_out_path, $direct_path],
        'strict semantic JSON succeeds for output-drive direct sample',
    );
    my $family = $decoded->{semantic}{forward_ir}{lowered_rtl_ir}{output_drive_families}[0];
    ok($family, 'direct success includes at least one output-drive family entry');
    assert_keys_present(
        $family,
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'direct output-drive family entry keeps bounded keys',
    );
    my $rhs_family = $family->{rhs_enable_families}[0];
    ok($rhs_family, 'direct output-drive family includes at least one rhs-enable-family entry');
    assert_keys_present(
        $rhs_family,
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'direct output-drive rhs-enable-family entry keeps bounded keys',
    );
};

subtest 'successful composition semantic JSON conforms to the bounded contract' => sub {
    my $composition_path = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');
    my $composition_out_path = File::Spec->catfile($tempdir, 'semantic_contract_apb_tb.sv');

    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $composition_out_path, $composition_path],
        'strict semantic JSON succeeds for composition sample',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'composition success report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{command},
        report_command_presence_keys(),
        'composition success report keeps bounded command-object keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        report_generated_output_presence_keys(),
        'composition success report keeps bounded generated_output-object keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'composition success report keeps bounded producer-object common keys',
    );
    assert_keys_present(
        $decoded->{producer},
        normalized_semantic_report_producer_extra_keys(),
        'composition success report keeps bounded producer-object extra keys',
    );
    assert_keys_present(
        $decoded->{source},
        report_source_presence_keys(),
        'composition success report keeps bounded source-object keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'composition success report keeps common support-accounting keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_matched_success_support_accounting_keys(),
        'composition success report keeps matched support-accounting keys',
    );
    assert_keys_present(
        $decoded->{semantic},
        normalized_semantic_success_semantic_keys(),
        'composition success semantic payload keeps bounded semantic keys',
    );
    assert_keys_present(
        $decoded->{semantic}{module},
        normalized_semantic_module_keys(),
        'composition success module payload keeps bounded module keys',
    );
    assert_keys_present(
        $decoded->{semantic}{signal_analysis},
        normalized_semantic_signal_analysis_keys(),
        'composition success semantic payload keeps bounded signal-analysis keys',
    );
    for my $bucket (qw(inputs outputs multi_bit single_bit)) {
        next unless @{$decoded->{semantic}{signal_analysis}{$bucket} || []};
        assert_keys_present(
            $decoded->{semantic}{signal_analysis}{$bucket}[0],
            normalized_semantic_signal_analysis_entry_keys(),
            "composition success semantic payload keeps bounded signal-analysis entry keys for $bucket",
        );
    }
    assert_keys_present(
        $decoded->{semantic}{composition},
        normalized_semantic_composition_keys(),
        'composition success semantic payload keeps bounded composition keys',
    );
    ok(
        grep { $_ eq 'composition' } @{normalized_semantic_success_semantic_optional_child_presence_keys()},
        'composition success optional child family names composition',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{intent_hir},
        normalized_semantic_forward_ir_intent_hir_keys(),
        'composition success semantic payload keeps bounded forward-ir intent-hir keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{intent_hir},
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'composition success semantic payload keeps bounded forward-ir intent-hir composition-only keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{lowered_rtl_ir},
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        'composition success semantic payload keeps bounded forward-ir lowered-rtl-ir keys',
    );
    ok(
        exists $decoded->{semantic}{forward_ir}{lowered_rtl_ir}{selector_conflict_target_count},
        'composition success lowered-rtl-ir payload keeps selector-conflict target count',
    );
    ok(
        exists $decoded->{semantic}{forward_ir}{lowered_rtl_ir}{selector_conflict_targets},
        'composition success lowered-rtl-ir payload keeps selector-conflict target list',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{lowered_rtl_ir},
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'composition success semantic payload keeps bounded forward-ir lowered-rtl-ir composition-only keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{structural_rtl_ir},
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        'composition success semantic payload keeps bounded forward-ir structural-rtl-ir keys',
    );
    my $composition_port = $decoded->{semantic}{forward_ir}{structural_rtl_ir}{ports}[0];
    ok($composition_port, 'composition success structural-rtl-ir includes at least one port entry');
    assert_keys_present(
        $composition_port,
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'composition success structural-rtl-ir port entry keeps bounded keys',
    );
    assert_keys_present(
        $composition_port,
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'composition success structural-rtl-ir port entry keeps bounded composition extension keys',
    );
    my $composition_net = $decoded->{semantic}{forward_ir}{structural_rtl_ir}{nets}[0];
    ok($composition_net, 'composition success structural-rtl-ir includes at least one net entry');
    assert_keys_present(
        $composition_net,
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'composition success structural-rtl-ir net entry keeps bounded keys',
    );
    is(
        ref($composition_net->{targets}),
        'ARRAY',
        'composition success structural-rtl-ir net entry keeps targets as a JSON array',
    );
    my $composition_declared_link = $decoded->{semantic}{forward_ir}{structural_rtl_ir}{declared_links}[0];
    ok($composition_declared_link, 'composition success structural-rtl-ir includes at least one declared-link entry');
    assert_keys_present(
        $composition_declared_link,
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'composition success structural-rtl-ir declared-link entry keeps bounded keys',
    );
    my $composition_resolved_link = $decoded->{semantic}{forward_ir}{structural_rtl_ir}{resolved_links}[0];
    ok($composition_resolved_link, 'composition success structural-rtl-ir includes at least one resolved-link entry');
    assert_keys_present(
        $composition_resolved_link,
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'composition success structural-rtl-ir resolved-link entry keeps bounded keys',
    );
    my $composition_instance = $decoded->{semantic}{forward_ir}{structural_rtl_ir}{instances}[0];
    ok($composition_instance, 'composition success structural-rtl-ir includes at least one instance entry');
    assert_keys_present(
        $composition_instance,
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'composition success structural-rtl-ir instance entry keeps bounded shallow keys',
    );
    my $composition_instance_interface_port = $composition_instance->{interface_ports}[0];
    ok(
        $composition_instance_interface_port,
        'composition success structural-rtl-ir instance includes at least one interface-port entry',
    );
    assert_keys_present(
        $composition_instance_interface_port,
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'composition success structural-rtl-ir instance interface-port entry keeps bounded keys',
    );
    my $composition_instance_port_binding = $composition_instance->{port_bindings}[0];
    ok(
        $composition_instance_port_binding,
        'composition success structural-rtl-ir instance includes at least one port-binding entry',
    );
    assert_keys_present(
        $composition_instance_port_binding,
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'composition success structural-rtl-ir instance port-binding entry keeps bounded core keys',
    );
    my ($composition_instance_typed_port_binding) =
        grep { exists $_->{connection_type_spec} } @{$composition_instance->{port_bindings} || []};
    ok(
        $composition_instance_typed_port_binding,
        'composition success structural-rtl-ir instance includes at least one typed port-binding entry',
    );
    assert_keys_present(
        $composition_instance_typed_port_binding,
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'composition success structural-rtl-ir instance typed port-binding entry keeps bounded typed extension keys',
    );
    ok(
        exists $decoded->{semantic}{module}{composition_child_count},
        'composition success module payload exposes composition child count',
    );
};

subtest 'successful composition semantic JSON keeps bounded auxiliary assignment scalar-string entries' => sub {
    my $auxiliary_path = File::Spec->catfile($tempdir, 'semantic_contract_auxiliary_assignments_top.fsm');
    my $auxiliary_out_path = File::Spec->catfile($tempdir, 'semantic_contract_auxiliary_assignments_top.sv');

    write_file(
        $auxiliary_path,
        <<'FSM'
(?top:auxiliary_assignments_top
  (?ports:public_io
    clk
    rstn
    start<8
    tap_a>8
    tap_b>8
    serial_out>
  )
  (?rtl:u_tx uart_tx)
  (?wiring:wiring
    (start tap_a)
    (start tap_b)
    (start u_tx.data_in)
    (u_tx.txd serial_out)
  )
)

(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data_in<8:data
  txd>:data
)
FSM
    );

    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $auxiliary_out_path, $auxiliary_path],
        'strict semantic JSON succeeds for auxiliary-assignment composition',
    );

    my $structural = $decoded->{semantic}{forward_ir}{structural_rtl_ir};
    is(
        $structural->{auxiliary_assignment_count},
        2,
        'auxiliary-assignment composition structural-rtl-ir reports the assignment count',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        [qw(scalar_string)],
        'auxiliary-assignment contract advertises scalar-string entry values',
    );
    is_deeply(
        $structural->{auxiliary_assignments},
        [
            '    assign tap_a = start;',
            '    assign tap_b = start;',
        ],
        'auxiliary-assignment composition structural-rtl-ir preserves assignment strings',
    );
    for my $assignment (@{$structural->{auxiliary_assignments} || []}) {
        ok(!ref($assignment), 'auxiliary-assignment entry is a scalar string');
        like($assignment, qr/\A\s*assign\s+\w+\s*=\s*\w+;\z/, 'auxiliary-assignment entry is assignment line text');
    }
};

subtest 'successful parameterized composition semantic JSON conforms to bounded structural parameter-override contracts' => sub {
    my $parameterized_path = File::Spec->catfile($tempdir, 'semantic_contract_parameterized_rtl_top.fsm');
    my $parameterized_out_path = File::Spec->catfile($tempdir, 'semantic_contract_parameterized_rtl_top.sv');

    write_file(
        $parameterized_path,
        <<'FSM'
(?top:parameterized_rtl_top
  (+constants
    (OVERRIDE_WIDTH 16)
    (LOCAL_LANES (8'hA5 8'h3C))
  )
  (+enums
    (frame_mode
      (RUN 2'b10)
    )
  )
  (+import
    param_pkg
  )
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (WIDTH OVERRIDE_WIDTH)
      (RESET_VALUE param_pkg.RESET_A5)
      (LANES LOCAL_LANES)
      (FRAME ((mode frame_mode.RUN) (flag param_pkg.FLAG_ON)))
    )
  )
  (?wiring:wiring
    (payload_in u_uart.data_in)
    (u_uart.txd serial_out)
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH param_pkg.DEFAULT_WIDTH)
    (RESET_VALUE param_pkg.DEFAULT_RESET)
    (LANES param_pkg.DEFAULT_LANES)
    (FRAME param_pkg.DEFAULT_FRAME)
  )
  core_clk:clock
  rst_async_n:reset
  data_in<16:data
  txd>:data
)

(?pkg:param_pkg
  (+constants
    (DEFAULT_WIDTH 8)
    (DEFAULT_RESET 8'h00)
    (DEFAULT_LANES (8'h00 8'h00))
    (DEFAULT_FRAME ((mode 2'b00) (flag 0)))
    (RESET_A5 8'hA5)
    (FLAG_ON 1)
  )
)
FSM
    );

    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $parameterized_out_path, $parameterized_path],
        'strict semantic JSON succeeds for parameterized RTL composition',
    );

    my $parameterized_instance = $decoded->{semantic}{forward_ir}{structural_rtl_ir}{instances}[0];
    ok($parameterized_instance, 'parameterized composition success structural-rtl-ir includes an instance entry');
    is(
        scalar(@{$parameterized_instance->{parameter_overrides} || []}),
        4,
        'parameterized composition success structural-rtl-ir includes parameter overrides',
    );
    my %override_by_name =
        map { $_->{name} => $_ } @{$parameterized_instance->{parameter_overrides} || []};
    my $width_override = $override_by_name{WIDTH};
    ok($width_override, 'parameterized composition structural-rtl-ir includes WIDTH parameter override');
    assert_keys_present(
        $width_override,
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'parameterized composition structural-rtl-ir parameter override keeps bounded core keys',
    );
    assert_keys_present(
        $width_override,
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'parameterized composition structural-rtl-ir parameter override keeps bounded raw-value extension keys',
    );
    assert_keys_present(
        $width_override,
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'parameterized composition structural-rtl-ir parameter override keeps bounded value-metadata extension keys',
    );
    my $frame_override = $override_by_name{FRAME};
    ok($frame_override, 'parameterized composition structural-rtl-ir includes FRAME parameter override');
    assert_keys_present(
        $frame_override,
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'record parameter override keeps bounded core keys',
    );
    assert_keys_present(
        $frame_override,
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'record parameter override keeps bounded value-metadata extension keys',
    );
    ok(!exists $frame_override->{raw_value}, 'record parameter override is not required to carry raw_value');

    my %composition_child_by_instance =
        map { $_->{instance_name} => $_ } @{$decoded->{semantic}{composition}{children} || []};
    my $composition_child = $composition_child_by_instance{u_uart} || {};
    ok($composition_child, 'parameterized composition semantic.composition.children includes the RTL child');
    is_deeply(
        $composition_child->{parameter_overrides},
        $parameterized_instance->{parameter_overrides},
        'semantic.composition.children[].parameter_overrides aliases structural-rtl instance overrides',
    );
    my %composition_override_by_name =
        map { $_->{name} => $_ } @{$composition_child->{parameter_overrides} || []};
    $composition_override_by_name{WIDTH} ||= {};
    $composition_override_by_name{FRAME} ||= {};
    assert_keys_present(
        $composition_override_by_name{WIDTH},
        normalized_semantic_composition_child_parameter_override_entry_keys(),
        'composition child WIDTH parameter override keeps bounded core keys',
    );
    assert_keys_present(
        $composition_override_by_name{WIDTH},
        normalized_semantic_composition_child_parameter_override_raw_value_extension_keys(),
        'composition child WIDTH parameter override keeps bounded raw-value extension keys',
    );
    assert_keys_present(
        $composition_override_by_name{WIDTH},
        normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys(),
        'composition child WIDTH parameter override keeps bounded value-metadata extension keys',
    );
    assert_keys_present(
        $composition_override_by_name{FRAME},
        normalized_semantic_composition_child_parameter_override_entry_keys(),
        'composition child FRAME parameter override keeps bounded core keys',
    );
    assert_keys_present(
        $composition_override_by_name{FRAME},
        normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys(),
        'composition child FRAME parameter override keeps bounded value-metadata extension keys',
    );
    ok(!exists $composition_override_by_name{FRAME}{raw_value}, 'composition child FRAME override is not required to carry raw_value');

    my %intent_child_by_instance =
        map { $_->{instance_name} => $_ } @{$decoded->{semantic}{forward_ir}{intent_hir}{composition_children} || []};
    my $intent_child = $intent_child_by_instance{u_uart} || {};
    ok($intent_child, 'parameterized composition intent-HIR composition_children includes the RTL child');
    is_deeply(
        $intent_child->{parameter_overrides},
        $composition_child->{parameter_overrides},
        'semantic.forward_ir.intent_hir.composition_children[].parameter_overrides aliases composition child overrides',
    );
    my %intent_override_by_name =
        map { $_->{name} => $_ } @{$intent_child->{parameter_overrides} || []};
    $intent_override_by_name{WIDTH} ||= {};
    $intent_override_by_name{FRAME} ||= {};
    assert_keys_present(
        $intent_override_by_name{WIDTH},
        normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
        'intent-HIR composition child WIDTH parameter override keeps bounded core keys',
    );
    assert_keys_present(
        $intent_override_by_name{WIDTH},
        normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
        'intent-HIR composition child WIDTH parameter override keeps bounded raw-value extension keys',
    );
    assert_keys_present(
        $intent_override_by_name{WIDTH},
        normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        'intent-HIR composition child WIDTH parameter override keeps bounded value-metadata extension keys',
    );
    assert_keys_present(
        $intent_override_by_name{FRAME},
        normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
        'intent-HIR composition child FRAME parameter override keeps bounded core keys',
    );
    assert_keys_present(
        $intent_override_by_name{FRAME},
        normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
        'intent-HIR composition child FRAME parameter override keeps bounded value-metadata extension keys',
    );
    ok(!exists $intent_override_by_name{FRAME}{raw_value}, 'intent-HIR composition child FRAME override is not required to carry raw_value');
};

subtest 'successful symbol-rich semantic JSON conforms to the bounded symbol-contract contract' => sub {
    my $symbol_path = File::Spec->catfile($repo_root, 't', 'corpus', 'direct_size_expression_widths.fsm');
    my $symbol_out_path = File::Spec->catfile($tempdir, 'semantic_contract_symbol_rich.sv');

    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $symbol_out_path, $symbol_path],
        'strict semantic JSON succeeds for symbol-rich sample',
    );

    ok($decoded->{semantic}{symbol_contract}, 'symbol-rich success report exposes the optional symbol-contract payload');
    ok(
        grep { $_ eq 'symbol_contract' } @{normalized_semantic_success_semantic_optional_child_presence_keys()},
        'symbol-rich success optional child family names symbol_contract',
    );
    assert_keys_present(
        $decoded->{semantic}{symbol_contract},
        normalized_semantic_symbol_contract_keys(),
        'symbol-rich success report keeps bounded symbol-contract keys',
    );
};

subtest 'failed semantic JSON conforms to the bounded contract' => sub {
    my $decoded = run_failed_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $bad_out_path, $bad_path],
        'strict semantic JSON fails for rejected source',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'failed report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{command},
        report_command_presence_keys(),
        'failed report keeps bounded command-object keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        report_generated_output_presence_keys(),
        'failed report keeps bounded generated_output-object keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'failed report keeps bounded producer-object common keys',
    );
    assert_keys_present(
        $decoded->{producer},
        normalized_semantic_report_producer_extra_keys(),
        'failed report keeps bounded producer-object extra keys',
    );
    assert_keys_present(
        $decoded->{source},
        report_source_presence_keys(),
        'failed report keeps bounded source-object keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'failed report keeps common support-accounting keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_matched_failure_support_accounting_keys(),
        'failed report keeps matched failure support-accounting keys',
    );
    is(scalar(@{$decoded->{diagnostics}}), 1, 'failed report keeps one diagnostic');
    assert_keys_present(
        $decoded->{diagnostics}[0],
        normalized_semantic_failure_diagnostic_keys(),
        'failed report diagnostic keeps bounded failure-diagnostic keys',
    );
    assert_keys_present(
        $decoded->{diagnostics}[0],
        normalized_semantic_matched_failure_diagnostic_keys(),
        'failed report diagnostic keeps matched failure-diagnostic keys',
    );
    assert_keys_present(
        $decoded->{diagnostics}[0]{support_accounting},
        normalized_semantic_failure_diagnostic_support_accounting_keys(),
        'failed report diagnostic keeps common nested support-accounting keys',
    );
    assert_keys_present(
        $decoded->{diagnostics}[0]{support_accounting},
        normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        'failed report diagnostic keeps matched nested support-accounting keys',
    );
    ok(!exists $decoded->{semantic}, 'failed report omits semantic payload');
    ok(!$decoded->{success}, 'failed report keeps success false');
    ok(!$decoded->{generated_output}{emitted}, 'failed report records no HDL emission');
};

done_testing();

sub run_semantic_json {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
    );

    ok($success, $label);
    is(join('', @{$stderr_buf || []}), '', "$label keeps stderr clean");

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, "$label emits decodable JSON");
    return $decoded;
}

sub run_failed_semantic_json {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
    );

    ok(!$success, $label);
    is(join('', @{$stderr_buf || []}), '', "$label keeps stderr clean");

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, "$label emits decodable JSON");
    return $decoded;
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
