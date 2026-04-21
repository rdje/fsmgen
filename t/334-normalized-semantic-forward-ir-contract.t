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
    normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys
    normalized_semantic_forward_ir_structural_rtl_ir_contract_source
    normalized_semantic_forward_ir_structural_rtl_ir_presence_keys
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
    normalized_semantic_payload_forward_ir_intent_hir_keys
    normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_forward_ir_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_forward_ir_keys
    normalized_semantic_forward_ir_intent_hir_keys
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
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
        normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'semantic payload structural-rtl-ir keys map to the nested structural-rtl-ir owner',
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
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'normalized semantic report structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
};

done_testing();
