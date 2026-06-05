#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

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
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_contract_source
    normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_presence_keys
    normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_contract_source
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_module_presence_keys
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
    normalized_semantic_symbol_contract_source
    normalized_semantic_symbol_contract_presence_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
    build_normalized_semantic_payload_contract
    normalized_semantic_payload_contract_source
    normalized_semantic_payload_composition_keys
    normalized_semantic_payload_explicit_system_contract_keys
    normalized_semantic_payload_presence_key_family_map
    normalized_semantic_payload_nested_presence_key_map
    normalized_semantic_payload_optional_child_presence_keys
    normalized_semantic_payload_forward_ir_keys
    normalized_semantic_payload_forward_ir_nested_contract_source_map
    normalized_semantic_payload_forward_ir_nested_presence_key_map
    normalized_semantic_payload_forward_ir_intent_hir_keys
    normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_presence_keys
    normalized_semantic_payload_signal_analysis_entry_keys
    normalized_semantic_payload_signal_analysis_keys
    normalized_semantic_payload_system_contract_keys
    normalized_semantic_payload_symbol_contract_keys
);

subtest 'contract exposes the bounded normalized semantic payload object' => sub {
    my $contract = build_normalized_semantic_payload_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested semantic object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_payload_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'semantic', 'contract records the nested object name');
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        'contract records the public report builder that reuses the nested object',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested semantic object is JSON-safe when embedded in public reports',
    );
    is(
        $contract->{module_contract_source},
        normalized_semantic_module_contract_source(),
        'contract records the nested module object owner',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_payload_presence_keys(),
        'contract publishes the bounded semantic-object key list',
    );
    is_deeply(
        $contract->{optional_child_presence_keys},
        normalized_semantic_payload_optional_child_presence_keys(),
        'contract publishes the optional semantic child key list',
    );
    is_deeply(
        normalized_semantic_payload_optional_child_presence_keys(),
        [qw(composition symbol_contract)],
        'optional semantic child key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            module => normalized_semantic_module_contract_source(),
            explicit_system_contract => normalized_semantic_explicit_system_contract_source(),
            signal_analysis => normalized_semantic_signal_analysis_contract_source(),
            system_contract => normalized_semantic_system_contract_source(),
            forward_ir => normalized_semantic_forward_ir_contract_source(),
            symbol_contract => normalized_semantic_symbol_contract_source(),
            composition => normalized_semantic_composition_contract_source(),
        },
        'contract publishes the bounded semantic-payload nested-contract ownership map',
    );
    is_deeply(
        $contract->{nested_presence_key_map},
        normalized_semantic_payload_nested_presence_key_map(),
        'contract publishes the bounded semantic-payload nested key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_payload_presence_key_family_map(),
        'contract publishes the grouped semantic-payload shell key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map}{optional_child_presence_keys},
        normalized_semantic_payload_optional_child_presence_keys(),
        'grouped semantic-payload family map publishes the optional child key list',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'grouped semantic-payload family map publishes selector-conflict target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'grouped semantic-payload family map publishes output-drive family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'grouped semantic-payload family map publishes output-drive rhs-enable-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'grouped semantic-payload family map publishes selector-conflict rhs-enable-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir port composition extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_net_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir net entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir declared-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir resolved-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_instance_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir instance shallow entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{forward_ir_structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'grouped semantic-payload family map publishes structural-rtl-ir instance interface-port entry keys',
    );
    is_deeply(
        $contract->{module_presence_keys},
        normalized_semantic_module_presence_keys(),
        'contract publishes the bounded module-object key list',
    );
    is_deeply(
        $contract->{module_optional_metric_keys},
        normalized_semantic_module_optional_metric_keys(),
        'contract publishes the bounded optional module metric key list',
    );
    is(
        $contract->{composition_contract_source},
        normalized_semantic_composition_contract_source(),
        'contract records the nested composition object owner',
    );
    is(
        $contract->{forward_ir_contract_source},
        normalized_semantic_forward_ir_contract_source(),
        'contract records the nested forward-IR object owner',
    );
    is(
        $contract->{signal_analysis_contract_source},
        normalized_semantic_signal_analysis_contract_source(),
        'contract records the nested signal-analysis object owner',
    );
    is(
        $contract->{explicit_system_contract_source},
        normalized_semantic_explicit_system_contract_source(),
        'contract records the nested explicit-system-contract object owner',
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
    is_deeply(
        $contract->{explicit_system_contract_presence_keys},
        normalized_semantic_payload_explicit_system_contract_keys(),
        'contract publishes the bounded explicit-system-contract key list',
    );
    is_deeply(
        normalized_semantic_payload_explicit_system_contract_keys(),
        normalized_semantic_explicit_system_contract_presence_keys(),
        'semantic payload explicit-system-contract keys map to the nested explicit-system-contract owner',
    );
    is_deeply(
        $contract->{signal_analysis_presence_keys},
        normalized_semantic_payload_signal_analysis_keys(),
        'contract publishes the bounded signal-analysis key list',
    );
    is_deeply(
        normalized_semantic_payload_signal_analysis_keys(),
        normalized_semantic_signal_analysis_presence_keys(),
        'semantic payload signal-analysis keys map to the nested signal-analysis owner',
    );
    is_deeply(
        $contract->{signal_analysis_entry_presence_keys},
        normalized_semantic_payload_signal_analysis_entry_keys(),
        'contract publishes the bounded signal-analysis entry key list',
    );
    is_deeply(
        normalized_semantic_payload_signal_analysis_entry_keys(),
        normalized_semantic_signal_analysis_entry_presence_keys(),
        'semantic payload signal-analysis entry keys map to the nested signal-analysis owner',
    );
    is_deeply(
        $contract->{system_contract_presence_keys},
        normalized_semantic_payload_system_contract_keys(),
        'contract publishes the bounded system-contract key list',
    );
    is_deeply(
        normalized_semantic_payload_system_contract_keys(),
        normalized_semantic_system_contract_presence_keys(),
        'semantic payload system-contract keys map to the nested system-contract owner',
    );
    is_deeply(
        $contract->{forward_ir_presence_keys},
        normalized_semantic_payload_forward_ir_keys(),
        'contract publishes the bounded forward-IR key list',
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
    is(
        $contract->{forward_ir_intent_hir_contract_source},
        normalized_semantic_forward_ir_intent_hir_contract_source(),
        'contract records the nested forward-ir intent-hir object owner',
    );
    is_deeply(
        $contract->{forward_ir_intent_hir_presence_keys},
        normalized_semantic_payload_forward_ir_intent_hir_keys(),
        'contract publishes the bounded forward-ir intent-hir key list',
    );
    is_deeply(
        $contract->{forward_ir_intent_hir_optional_composition_keys},
        normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        'contract publishes the bounded forward-ir intent-hir composition-only key list',
    );
    is(
        $contract->{forward_ir_lowered_rtl_ir_contract_source},
        normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        'contract records the nested forward-ir lowered-rtl-ir object owner',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_presence_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_optional_composition_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir composition-only key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive family entry key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive rhs-family key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict target entry key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict rhs-enable-family key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict multi-value assertion key list',
    );
    is_deeply(
        $contract->{forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys},
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector-conflict same-value assertion key list',
    );
    is(
        $contract->{forward_ir_structural_rtl_ir_contract_source},
        normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        'contract records the nested forward-ir structural-rtl-ir object owner',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_presence_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port composition extension key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_net_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir net entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir declared-link entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir resolved-link entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_instance_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance shallow entry key list',
    );
    is_deeply(
        $contract->{forward_ir_structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance interface-port entry key list',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'semantic payload forward-IR keys map to the nested forward-IR owner',
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
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir selector target entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'semantic payload forward-ir lowered-rtl-ir selector rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'semantic payload forward-ir lowered-rtl-ir selector multi-value assertion keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'semantic payload forward-ir lowered-rtl-ir selector same-value assertion keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'semantic payload forward-ir structural-rtl-ir keys map to the nested structural-rtl-ir owner',
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
        $contract->{symbol_contract_presence_keys},
        normalized_semantic_payload_symbol_contract_keys(),
        'contract publishes the bounded symbol-contract key list',
    );
    is_deeply(
        normalized_semantic_payload_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'semantic payload symbol-contract keys map to the nested symbol-contract owner',
    );
    is_deeply(
        $contract->{composition_presence_keys},
        normalized_semantic_composition_presence_keys(),
        'contract publishes the bounded composition key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_keys(),
        normalized_semantic_composition_presence_keys(),
        'semantic payload composition keys map to the nested composition owner',
    );
};

done_testing();
