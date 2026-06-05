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
    normalized_semantic_lowered_rtl_ir_presence_key_family_map
    normalized_semantic_lowered_rtl_ir_presence_keys
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
        $contract->{presence_key_family_map},
        normalized_semantic_lowered_rtl_ir_presence_key_family_map(),
        'contract publishes the grouped lowered-rtl-ir key-family discovery map',
    );
};

done_testing();
