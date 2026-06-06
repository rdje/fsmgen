#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    build_normalized_semantic_lowered_rtl_ir_contract
    normalized_semantic_lowered_rtl_ir_contract_source
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_presence_key_family_map
    normalized_semantic_lowered_rtl_ir_presence_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
);

subtest 'contract exposes the bounded normalized semantic lowered-rtl-ir object' => sub {
    my $contract = build_normalized_semantic_lowered_rtl_ir_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested lowered-rtl-ir object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_lowered_rtl_ir_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'lowered_rtl_ir', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.forward_ir.lowered_rtl_ir', 'contract records the nested parent path');
    ok(
        $contract->{optional_for_non_composition_sources},
        'contract says composition-only lowered-rtl-ir keys stay optional for non-composition sources',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested lowered-rtl-ir object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        'contract publishes the bounded lowered-rtl-ir core key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        [
            qw(
                module_name
                output_drive_families
                output_drive_family_count
                selector_conflict_target_count
                selector_conflict_targets
                source_root_kind
                standalone_dt_multi_drive_target_count
                standalone_dt_multi_drive_targets
                target_language
            ),
        ],
        'bounded lowered-rtl-ir core key list includes selector-conflict metadata',
    );
    is_deeply(
        $contract->{optional_composition_keys},
        normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        'contract publishes the bounded lowered-rtl-ir composition-only key list',
    );
    is_deeply(
        $contract->{output_drive_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys(),
        'contract publishes the bounded output-drive family entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys(),
        [
            qw(
                default_value
                driver_blocks
                driver_count
                driver_enable_signals
                family_enable_signals
                multiplexer_type
                reset_value
                rhs_enable_families
                rhs_values
                signal_name
                width
            ),
        ],
        'output-drive family entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'contract publishes the bounded output-drive rhs-enable-family entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        [
            qw(
                driver_blocks
                driver_enable_signals
                family_enable_signal
                rhs_value
            ),
        ],
        'output-drive rhs-enable-family entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{selector_conflict_target_entry_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'contract publishes the bounded selector-conflict target entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        [
            qw(
                family_enable_signals
                multi_value_assertion
                multiplexer_type
                rhs_enable_families
                rhs_values
                signal_name
            ),
        ],
        'selector-conflict target entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'contract publishes the bounded selector-conflict rhs-enable-family entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        [
            qw(
                driver_enable_signals
                family_enable_signal
                rhs_value
                same_value_assertion
            ),
        ],
        'selector-conflict rhs-enable-family entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{selector_conflict_multi_value_assertion_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'contract publishes the bounded selector-conflict multi-value assertion key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        [
            qw(
                input_count
                input_enable_signals
                kind
                target_signal
            ),
        ],
        'selector-conflict multi-value assertion key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{selector_conflict_same_value_assertion_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'contract publishes the bounded selector-conflict same-value assertion key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        [
            qw(
                input_count
                input_enable_signals
                kind
                rhs_value
                target_signal
            ),
        ],
        'selector-conflict same-value assertion key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'contract publishes the bounded standalone-DT multi-drive target entry key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        [
            qw(
                dt_enable_signals
                dt_names
                lhs_enable_signals
                multi_drive_assertion
                multiplexer_type
                rhs_values
                signal_name
            ),
        ],
        'standalone-DT multi-drive target entry key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'contract publishes the bounded standalone-DT multi-drive assertion key list',
    );
    is_deeply(
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        [
            qw(
                input_count
                input_enable_signals
                kind
                target_signal
            ),
        ],
        'standalone-DT multi-drive assertion key list stays bounded and ordered',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_lowered_rtl_ir_presence_key_family_map(),
        'contract publishes the grouped lowered-rtl-ir key-family discovery map',
    );
    is_deeply(
        $contract->{presence_key_family_map}{selector_conflict_target_entry_keys},
        normalized_semantic_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'grouped lowered-rtl-ir family map includes selector-conflict target entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{output_drive_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_output_drive_family_entry_keys(),
        'grouped lowered-rtl-ir family map includes output-drive family entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'grouped lowered-rtl-ir family map includes output-drive rhs-enable-family entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'grouped lowered-rtl-ir family map includes standalone-DT multi-drive target entries',
    );
    is_deeply(
        $contract->{presence_key_family_map}{standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'grouped lowered-rtl-ir family map includes standalone-DT multi-drive assertion entries',
    );
};

done_testing();
