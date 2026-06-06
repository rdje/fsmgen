#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(
    composition_report_contract_source
);
use FSM::Support::NormalizedSemanticCompositionContract qw(
    build_normalized_semantic_composition_contract
    normalized_semantic_composition_child_entry_keys
    normalized_semantic_composition_collection_keys
    normalized_semantic_composition_contract_source
    normalized_semantic_composition_generated_child_entry_keys
    normalized_semantic_composition_nested_presence_keys
    normalized_semantic_composition_presence_key_family_map
    normalized_semantic_composition_presence_keys
    normalized_semantic_composition_standalone_dt_child_entry_keys
    normalized_semantic_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_composition_summary_presence_keys
);
use FSM::Support::SerializableCompositionPlanSnapshot qw(
    serializable_composition_plan_snapshot_contract_source
);

subtest 'contract exposes the bounded normalized semantic composition object' => sub {
    my $contract = build_normalized_semantic_composition_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested composition object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_composition_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'composition', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.composition', 'contract records the nested parent path');
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        'contract records the public report builder that reuses the nested composition object',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            plan_snapshot => serializable_composition_plan_snapshot_contract_source(),
            provenance_report => composition_report_contract_source(),
        },
        'contract publishes the bounded composition nested-contract ownership map',
    );
    is(
        $contract->{plan_snapshot_contract_source},
        serializable_composition_plan_snapshot_contract_source(),
        'contract records the nested plan-snapshot owner',
    );
    is(
        $contract->{provenance_report_contract_source},
        composition_report_contract_source(),
        'contract records the nested provenance-report owner',
    );
    ok(
        $contract->{optional_for_non_composition_sources},
        'contract says the nested composition object is optional for non-composition sources',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested composition object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_composition_presence_keys(),
        'contract publishes the bounded composition-object key list',
    );
    is_deeply(
        $contract->{summary_presence_keys},
        normalized_semantic_composition_summary_presence_keys(),
        'contract publishes the bounded composition summary key family',
    );
    is_deeply(
        $contract->{collection_keys},
        normalized_semantic_composition_collection_keys(),
        'contract publishes the bounded composition collection key family',
    );
    is_deeply(
        $contract->{child_entry_keys},
        normalized_semantic_composition_child_entry_keys(),
        'contract publishes the bounded composition child entry key family',
    );
    is_deeply(
        normalized_semantic_composition_child_entry_keys(),
        [
            qw(
                kind
                instance_name
                module_name
                source_name
                source_root_kind
                regular_state_count
                standalone_dt_count
                output_drive_family_count
                standalone_dt_multi_drive_target_count
                parameter_override_count
                parameter_overrides
                intent_hir
                lowered_rtl_ir
                structural_rtl_ir
            ),
        ],
        'composition child entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{generated_child_entry_keys},
        normalized_semantic_composition_generated_child_entry_keys(),
        'contract publishes the bounded composition generated-child entry key family',
    );
    is_deeply(
        normalized_semantic_composition_generated_child_entry_keys(),
        [
            qw(
                kind
                instance_name
                module_name
                source_name
                source_root_kind
                regular_state_count
                standalone_dt_count
                output_drive_family_count
                standalone_dt_multi_drive_target_count
                intent_hir
                lowered_rtl_ir
                structural_rtl_ir
            ),
        ],
        'composition generated-child entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{standalone_dt_child_entry_keys},
        normalized_semantic_composition_standalone_dt_child_entry_keys(),
        'contract publishes the bounded composition standalone-DT child entry key family',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_child_entry_keys(),
        [
            qw(
                instance_name
                module_name
                source_name
                standalone_dt_count
                standalone_dt_names
                standalone_dt_enable_families
                standalone_dt_module_enable_family
                standalone_dt_multi_drive_target_count
                standalone_dt_multi_drive_targets
                intent_hir
                lowered_rtl_ir
                structural_rtl_ir
            ),
        ],
        'composition standalone-DT child entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{standalone_dt_enable_family_entry_keys},
        normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        'contract publishes the bounded composition standalone-DT enable-family entry key family',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
        [qw(dt_name enable_signal)],
        'composition standalone-DT enable-family entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{standalone_dt_module_enable_family_keys},
        normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        'contract publishes the bounded composition standalone-DT module-enable-family key family',
    );
    is_deeply(
        normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
        [qw(dt_names enable_signals)],
        'composition standalone-DT module-enable-family keys stay exact and ordered',
    );
    is_deeply(
        $contract->{standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
        'contract publishes the delegated standalone-DT multi-drive target key family',
    );
    is_deeply(
        $contract->{standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
        'contract publishes the delegated standalone-DT multi-drive assertion key family',
    );
    is_deeply(
        $contract->{nested_presence_keys},
        normalized_semantic_composition_nested_presence_keys(),
        'contract publishes the bounded composition nested key family',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_composition_presence_key_family_map(),
        'contract publishes the grouped composition key-family map',
    );
};

done_testing();
