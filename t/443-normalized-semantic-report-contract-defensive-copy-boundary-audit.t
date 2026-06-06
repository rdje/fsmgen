#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticPayloadContract qw(
    normalized_semantic_payload_forward_ir_nested_contract_source_map
    normalized_semantic_payload_forward_ir_nested_presence_key_map
    normalized_semantic_payload_nested_presence_key_map
    normalized_semantic_payload_optional_child_presence_keys
    normalized_semantic_payload_presence_key_family_map
);
use FSM::Support::NormalizedSemanticReportContract qw(
    build_normalized_semantic_report_contract
    normalized_semantic_composition_child_entry_keys
    normalized_semantic_composition_generated_child_entry_keys
    normalized_semantic_composition_keys
    normalized_semantic_composition_standalone_dt_child_entry_keys
    normalized_semantic_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_explicit_system_contract_keys
    normalized_semantic_failure_diagnostic_keys
    normalized_semantic_failure_diagnostic_optional_artifact_keys
    normalized_semantic_failure_diagnostic_support_accounting_keys
    normalized_semantic_forward_ir_intent_hir_keys
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_keys
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
    normalized_semantic_success_only_top_level_keys
    normalized_semantic_success_semantic_optional_child_presence_keys
    normalized_semantic_success_semantic_keys
    normalized_semantic_support_accounting_keys
    normalized_semantic_symbol_contract_keys
    normalized_semantic_system_contract_keys
);

my $sentinel = '__mutated_by_t443__';

subtest 'normalized semantic report contract builder returns fresh nested structures' => sub {
    my $first = build_normalized_semantic_report_contract();
    mutate_structure($first);

    my $second = build_normalized_semantic_report_contract();
    ok(!contains_sentinel($second), 'fresh normalized semantic report contract is not affected by prior caller mutation');
    is_deeply(
        $second->{nested_presence_key_map},
        normalized_semantic_nested_presence_key_map(),
        'fresh contract nested presence map matches its helper',
    );
    is_deeply(
        $second->{presence_key_family_map},
        normalized_semantic_presence_key_family_map(),
        'fresh contract presence family map matches its helper',
    );
    is_deeply(
        $second->{semantic_presence_key_family_map},
        normalized_semantic_payload_presence_key_family_map(),
        'fresh contract semantic presence family map matches payload helper',
    );
    is_deeply(
        $second->{semantic_nested_presence_key_map},
        normalized_semantic_payload_nested_presence_key_map(),
        'fresh contract semantic nested presence map matches payload helper',
    );
    is_deeply(
        $second->{forward_ir_nested_contract_source_map},
        normalized_semantic_payload_forward_ir_nested_contract_source_map(),
        'fresh contract forward-IR nested contract-source map matches payload helper',
    );
    is_deeply(
        $second->{forward_ir_nested_presence_key_map},
        normalized_semantic_payload_forward_ir_nested_presence_key_map(),
        'fresh contract forward-IR nested presence map matches payload helper',
    );
};

subtest 'normalized semantic report helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&normalized_semantic_public_top_level_keys,
        },
        {
            label => 'nested_presence_key_map',
            build => \&normalized_semantic_nested_presence_key_map,
        },
        {
            label => 'presence_key_family_map',
            build => \&normalized_semantic_presence_key_family_map,
        },
        {
            label => 'success_only_top_level_keys',
            build => \&normalized_semantic_success_only_top_level_keys,
        },
        {
            label => 'support_accounting_keys',
            build => \&normalized_semantic_support_accounting_keys,
        },
        {
            label => 'failure_diagnostic_keys',
            build => \&normalized_semantic_failure_diagnostic_keys,
        },
        {
            label => 'matched_failure_diagnostic_keys',
            build => \&normalized_semantic_matched_failure_diagnostic_keys,
        },
        {
            label => 'failure_diagnostic_optional_artifact_keys',
            build => \&normalized_semantic_failure_diagnostic_optional_artifact_keys,
        },
        {
            label => 'failure_diagnostic_support_accounting_keys',
            build => \&normalized_semantic_failure_diagnostic_support_accounting_keys,
        },
        {
            label => 'matched_failure_diagnostic_support_accounting_keys',
            build => \&normalized_semantic_matched_failure_diagnostic_support_accounting_keys,
        },
        {
            label => 'matched_success_support_accounting_keys',
            build => \&normalized_semantic_matched_success_support_accounting_keys,
        },
        {
            label => 'matched_failure_support_accounting_keys',
            build => \&normalized_semantic_matched_failure_support_accounting_keys,
        },
        {
            label => 'success_semantic_keys',
            build => \&normalized_semantic_success_semantic_keys,
        },
        {
            label => 'success_semantic_optional_child_presence_keys',
            build => \&normalized_semantic_success_semantic_optional_child_presence_keys,
        },
        {
            label => 'module_keys',
            build => \&normalized_semantic_module_keys,
        },
        {
            label => 'module_optional_metric_keys',
            build => \&normalized_semantic_module_optional_metric_keys,
        },
        {
            label => 'forward_ir_keys',
            build => \&normalized_semantic_forward_ir_keys,
        },
        {
            label => 'forward_ir_intent_hir_keys',
            build => \&normalized_semantic_forward_ir_intent_hir_keys,
        },
        {
            label => 'forward_ir_intent_hir_optional_composition_keys',
            build => \&normalized_semantic_forward_ir_intent_hir_optional_composition_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_optional_composition_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_output_drive_family_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys,
        },
        {
            label => 'forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys',
            build => \&normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds,
        },
        {
            label => 'forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning,
        },
        {
            label => 'forward_ir_structural_rtl_ir_port_entry_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_port_composition_extension_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_net_entry_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_declared_link_entry_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_resolved_link_entry_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_entry_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_interface_port_entry_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_port_binding_entry_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys,
        },
        {
            label => 'forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys',
            build => \&normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys,
        },
        {
            label => 'explicit_system_contract_keys',
            build => \&normalized_semantic_explicit_system_contract_keys,
        },
        {
            label => 'signal_analysis_keys',
            build => \&normalized_semantic_signal_analysis_keys,
        },
        {
            label => 'signal_analysis_entry_keys',
            build => \&normalized_semantic_signal_analysis_entry_keys,
        },
        {
            label => 'system_contract_keys',
            build => \&normalized_semantic_system_contract_keys,
        },
        {
            label => 'symbol_contract_keys',
            build => \&normalized_semantic_symbol_contract_keys,
        },
        {
            label => 'composition_keys',
            build => \&normalized_semantic_composition_keys,
        },
        {
            label => 'composition_child_entry_keys',
            build => \&normalized_semantic_composition_child_entry_keys,
        },
        {
            label => 'composition_generated_child_entry_keys',
            build => \&normalized_semantic_composition_generated_child_entry_keys,
        },
        {
            label => 'composition_standalone_dt_child_entry_keys',
            build => \&normalized_semantic_composition_standalone_dt_child_entry_keys,
        },
        {
            label => 'composition_standalone_dt_enable_family_entry_keys',
            build => \&normalized_semantic_composition_standalone_dt_enable_family_entry_keys,
        },
        {
            label => 'composition_standalone_dt_module_enable_family_keys',
            build => \&normalized_semantic_composition_standalone_dt_module_enable_family_keys,
        },
        {
            label => 'composition_standalone_dt_multi_drive_target_entry_keys',
            build => \&normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys,
        },
        {
            label => 'composition_standalone_dt_multi_drive_assertion_keys',
            build => \&normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh normalized semantic report maps stay aligned with helper families' => sub {
    my $nested_map = normalized_semantic_nested_presence_key_map();
    is_deeply($nested_map->{semantic}, normalized_semantic_success_semantic_keys(), 'semantic nested map entry matches helper');
    is_deeply($nested_map->{module}, normalized_semantic_module_keys(), 'module nested map entry matches helper');
    is_deeply($nested_map->{forward_ir}, normalized_semantic_forward_ir_keys(), 'forward-IR nested map entry matches helper');
    is_deeply($nested_map->{signal_analysis}, normalized_semantic_signal_analysis_keys(), 'signal-analysis nested map entry matches helper');
    is_deeply($nested_map->{system_contract}, normalized_semantic_system_contract_keys(), 'system-contract nested map entry matches helper');
    is_deeply($nested_map->{symbol_contract}, normalized_semantic_symbol_contract_keys(), 'symbol-contract nested map entry matches helper');
    is_deeply($nested_map->{composition}, normalized_semantic_composition_keys(), 'composition nested map entry matches helper');

    my $family_map = normalized_semantic_presence_key_family_map();
    is_deeply($family_map->{success_only_top_level_keys}, normalized_semantic_success_only_top_level_keys(), 'success-only family entry matches helper');
    is_deeply($family_map->{success_semantic_presence_keys}, normalized_semantic_success_semantic_keys(), 'success semantic family entry matches helper');
    is_deeply(
        $family_map->{success_semantic_optional_child_presence_keys},
        normalized_semantic_success_semantic_optional_child_presence_keys(),
        'success semantic optional child family entry matches helper',
    );
    is_deeply(
        normalized_semantic_success_semantic_optional_child_presence_keys(),
        normalized_semantic_payload_optional_child_presence_keys(),
        'success semantic optional child helper matches payload helper',
    );
    is_deeply($family_map->{composition_child_entry_keys}, normalized_semantic_composition_child_entry_keys(), 'composition child entry family matches helper');
    is_deeply($family_map->{composition_generated_child_entry_keys}, normalized_semantic_composition_generated_child_entry_keys(), 'composition generated-child entry family matches helper');
    is_deeply($family_map->{composition_standalone_dt_child_entry_keys}, normalized_semantic_composition_standalone_dt_child_entry_keys(), 'composition standalone-DT child entry family matches helper');
    is_deeply($family_map->{composition_standalone_dt_enable_family_entry_keys}, normalized_semantic_composition_standalone_dt_enable_family_entry_keys(), 'composition standalone-DT enable-family entry family matches helper');
    is_deeply($family_map->{composition_standalone_dt_module_enable_family_keys}, normalized_semantic_composition_standalone_dt_module_enable_family_keys(), 'composition standalone-DT module-enable-family family matches helper');
    is_deeply($family_map->{composition_standalone_dt_multi_drive_target_entry_keys}, normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(), 'composition standalone-DT multi-drive target entry family matches helper');
    is_deeply($family_map->{composition_standalone_dt_multi_drive_assertion_keys}, normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(), 'composition standalone-DT multi-drive assertion family matches helper');
    is_deeply($family_map->{support_accounting_presence_keys}, normalized_semantic_support_accounting_keys(), 'support accounting family entry matches helper');
    is_deeply($family_map->{failure_diagnostic_presence_keys}, normalized_semantic_failure_diagnostic_keys(), 'failure diagnostic family entry matches helper');
    is_deeply(
        $family_map->{matched_failure_diagnostic_support_accounting_presence_keys},
        normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        'matched failure diagnostic support-accounting family entry matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_intent_hir_optional_composition_keys},
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'intent-HIR optional composition family entry matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_lowered_rtl_ir_optional_composition_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'lowered-RTL optional composition family entry matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'lowered-RTL output-drive family entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'lowered-RTL output-drive rhs-enable-family entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'lowered-RTL selector-conflict target entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'lowered-RTL selector-conflict rhs-enable-family entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'lowered-RTL selector-conflict multi-value assertion family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'lowered-RTL selector-conflict same-value assertion family matches helper',
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
            $family_map->{$case->[0]},
            $case->[1],
            "$case->[0] family matches helper",
        );
    }
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds},
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'structural-RTL auxiliary-assignment value-kind family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'structural-RTL port entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'structural-RTL port composition extension family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_net_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'structural-RTL net entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'structural-RTL declared-link entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'structural-RTL resolved-link entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_instance_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'structural-RTL instance shallow entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'structural-RTL instance interface-port entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'structural-RTL instance parameter-override core entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'structural-RTL instance parameter-override raw-value extension family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'structural-RTL instance parameter-override value-metadata extension family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'structural-RTL instance port-binding core entry family matches helper',
    );
    is_deeply(
        $family_map->{success_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'structural-RTL instance port-binding typed extension family matches helper',
    );
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);

    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_) for @{$value};
        return;
    }

    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_) for values %{$value};
        return;
    }
}

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        for my $entry (@{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        for my $entry (values %{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    return 0;
}
