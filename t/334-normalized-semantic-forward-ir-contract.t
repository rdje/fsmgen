#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticForwardIRContract qw(
    build_normalized_semantic_forward_ir_contract
    normalized_semantic_forward_ir_contract_source
    normalized_semantic_forward_ir_intent_hir_contract_source
    normalized_semantic_forward_ir_nested_presence_key_map
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
    normalized_semantic_forward_ir_presence_key_family_map
    normalized_semantic_forward_ir_structural_rtl_ir_contract_source
    normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_presence_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
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
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_forward_ir_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_forward_ir_keys
    normalized_semantic_forward_ir_intent_hir_keys
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_keys
);

subtest 'contract exposes the bounded normalized semantic forward-IR object' => sub {
    my $contract = build_normalized_semantic_forward_ir_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested forward-IR object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_forward_ir_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'semantic.forward_ir', 'contract records the nested object name');
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
        'contract says the nested forward-IR object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_forward_ir_presence_keys(),
        'contract publishes the bounded forward-IR key list',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            intent_hir => normalized_semantic_forward_ir_intent_hir_contract_source(),
            lowered_rtl_ir => normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
            structural_rtl_ir => normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        },
        'contract publishes the bounded forward-ir nested-contract ownership map',
    );
    is_deeply(
        $contract->{nested_presence_key_map},
        normalized_semantic_forward_ir_nested_presence_key_map(),
        'contract publishes the bounded forward-ir nested key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_forward_ir_presence_key_family_map(),
        'contract publishes the grouped forward-ir shell key-family discovery map',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'grouped forward-ir family map publishes selector-conflict target entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'grouped forward-ir family map publishes output-drive family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'grouped forward-ir family map publishes output-drive rhs-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'grouped forward-ir family map publishes selector-conflict rhs-family entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir port composition extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_net_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir net entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir declared-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir resolved-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance shallow entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance interface-port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance port-binding core entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'grouped forward-ir family map publishes structural-rtl-ir instance port-binding typed extension keys',
    );
    is(
        $contract->{intent_hir_contract_source},
        normalized_semantic_forward_ir_intent_hir_contract_source(),
        'contract records the nested intent-hir object owner',
    );
    is_deeply(
        $contract->{intent_hir_presence_keys},
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'contract publishes the bounded forward-ir intent-hir key list',
    );
    is_deeply(
        $contract->{intent_hir_optional_composition_keys},
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'contract publishes the bounded forward-ir intent-hir composition-only key list',
    );
    is(
        $contract->{lowered_rtl_ir_contract_source},
        normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        'contract records the nested lowered-rtl-ir object owner',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_presence_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_optional_composition_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir composition-only key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive family entry key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir output-drive rhs-family key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector target entry key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector rhs-family key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_selector_conflict_multi_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector multi-value assertion key list',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_selector_conflict_same_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir selector same-value assertion key list',
    );
    is(
        $contract->{structural_rtl_ir_contract_source},
        normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        'contract records the nested structural-rtl-ir object owner',
    );
    is_deeply(
        $contract->{structural_rtl_ir_presence_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir port composition extension key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_net_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir net entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir declared-link entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir resolved-link entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance shallow entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance interface-port entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance port-binding core entry key list',
    );
    is_deeply(
        $contract->{structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir instance port-binding typed extension key list',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'semantic payload forward-IR keys map to the nested forward-IR owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_intent_hir_keys(),
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'semantic payload intent-hir keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'semantic payload intent-hir composition keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'semantic payload lowered-rtl-ir keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'semantic payload lowered-rtl-ir composition keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'semantic payload lowered-rtl-ir output-drive family entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'semantic payload lowered-rtl-ir output-drive rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'semantic payload lowered-rtl-ir selector target entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'semantic payload lowered-rtl-ir selector rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'semantic payload lowered-rtl-ir selector multi-value assertion keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'semantic payload lowered-rtl-ir selector same-value assertion keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'semantic payload structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'semantic payload structural-rtl-ir port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'semantic payload structural-rtl-ir port composition extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_net_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'semantic payload structural-rtl-ir net entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'semantic payload structural-rtl-ir declared-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'semantic payload structural-rtl-ir resolved-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'semantic payload structural-rtl-ir instance shallow entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'semantic payload structural-rtl-ir instance interface-port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'semantic payload structural-rtl-ir instance port-binding core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'semantic payload structural-rtl-ir instance port-binding typed extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'normalized semantic report forward-IR keys map to the nested forward-IR owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_intent_hir_keys(),
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'normalized semantic report intent-hir keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'normalized semantic report intent-hir composition keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'normalized semantic report lowered-rtl-ir keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'normalized semantic report lowered-rtl-ir composition keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'normalized semantic report lowered-rtl-ir output-drive family entry keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'normalized semantic report lowered-rtl-ir output-drive rhs-family keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'normalized semantic report structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'normalized semantic report structural-rtl-ir port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'normalized semantic report structural-rtl-ir port composition extension keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'normalized semantic report structural-rtl-ir net entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'normalized semantic report structural-rtl-ir declared-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'normalized semantic report structural-rtl-ir resolved-link entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'normalized semantic report structural-rtl-ir instance shallow entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'normalized semantic report structural-rtl-ir instance interface-port entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'normalized semantic report structural-rtl-ir instance port-binding core entry keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'normalized semantic report structural-rtl-ir instance port-binding typed extension keys map to the nested structural-rtl-ir owner',
    );
};

done_testing();
