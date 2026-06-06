#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_child_entry_keys
    normalized_semantic_composition_child_parameter_override_entry_keys
    normalized_semantic_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_generated_child_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_standalone_dt_child_entry_keys
    normalized_semantic_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys
);
use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    build_normalized_semantic_intent_hir_contract
    normalized_semantic_intent_hir_contract_source
    normalized_semantic_intent_hir_composition_child_entry_keys
    normalized_semantic_intent_hir_composition_child_parameter_override_entry_keys
    normalized_semantic_intent_hir_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_intent_hir_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_intent_hir_composition_generated_child_entry_keys
    normalized_semantic_intent_hir_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_intent_hir_composition_standalone_dt_child_entry_keys
    normalized_semantic_intent_hir_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_intent_hir_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_key_family_map
    normalized_semantic_intent_hir_presence_keys
    normalized_semantic_intent_hir_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_intent_hir_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_intent_hir_symbol_contract_constant_value_entry_keys
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    normalized_semantic_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_symbol_contract_constant_value_entry_keys
);

subtest 'contract exposes the bounded normalized semantic intent-hir object' => sub {
    my $contract = build_normalized_semantic_intent_hir_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested intent-hir object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_intent_hir_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'intent_hir', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.forward_ir.intent_hir', 'contract records the nested parent path');
    ok(
        $contract->{optional_for_non_composition_sources},
        'contract says composition-only intent-hir keys stay optional for non-composition sources',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested intent-hir object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_intent_hir_presence_keys(),
        'contract publishes the bounded intent-hir core key list',
    );
    is_deeply(
        $contract->{optional_composition_keys},
        normalized_semantic_intent_hir_optional_composition_keys(),
        'contract publishes the bounded intent-hir composition-only key list',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_intent_hir_presence_key_family_map(),
        'contract publishes the grouped intent-hir key-family discovery map',
    );
    for my $case (
        [
            'symbol_contract_constant_value_entry_keys',
            normalized_semantic_intent_hir_symbol_contract_constant_value_entry_keys(),
            normalized_semantic_symbol_contract_constant_value_entry_keys(),
        ],
        [
            'symbol_contract_constant_scalar_value_extension_keys',
            normalized_semantic_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
            normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
        ],
        [
            'symbol_contract_constant_list_value_extension_keys',
            normalized_semantic_intent_hir_symbol_contract_constant_list_value_extension_keys(),
            normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
        ],
        [
            'composition_child_entry_keys',
            normalized_semantic_intent_hir_composition_child_entry_keys(),
            normalized_semantic_composition_child_entry_keys(),
        ],
        [
            'composition_child_parameter_override_entry_keys',
            normalized_semantic_intent_hir_composition_child_parameter_override_entry_keys(),
            normalized_semantic_composition_child_parameter_override_entry_keys(),
        ],
        [
            'composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_composition_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys(),
        ],
        [
            'composition_generated_child_entry_keys',
            normalized_semantic_intent_hir_composition_generated_child_entry_keys(),
            normalized_semantic_composition_generated_child_entry_keys(),
        ],
        [
            'composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_intent_hir_composition_generated_child_parameter_override_entry_keys(),
            normalized_semantic_composition_generated_child_parameter_override_entry_keys(),
        ],
        [
            'composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
            normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys(),
        ],
        [
            'composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys(),
        ],
        [
            'composition_standalone_dt_child_entry_keys',
            normalized_semantic_intent_hir_composition_standalone_dt_child_entry_keys(),
            normalized_semantic_composition_standalone_dt_child_entry_keys(),
        ],
        [
            'composition_standalone_dt_enable_family_entry_keys',
            normalized_semantic_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
            normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        ],
        [
            'composition_standalone_dt_module_enable_family_keys',
            normalized_semantic_intent_hir_composition_standalone_dt_module_enable_family_keys(),
            normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        ],
        [
            'composition_standalone_dt_multi_drive_target_entry_keys',
            normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
            normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        ],
        [
            'composition_standalone_dt_multi_drive_assertion_keys',
            normalized_semantic_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
            normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        ],
    ) {
        my ($field, $intent_hir_keys, $composition_keys) = @{$case};

        is_deeply(
            $contract->{$field},
            $intent_hir_keys,
            "contract publishes $field",
        );
        is_deeply(
            $contract->{presence_key_family_map}{$field},
            $intent_hir_keys,
            "presence family map publishes $field",
        );
        is_deeply(
            $intent_hir_keys,
            $composition_keys,
            "$field delegates to the composition schema owner",
        );
    }
};

done_testing();
