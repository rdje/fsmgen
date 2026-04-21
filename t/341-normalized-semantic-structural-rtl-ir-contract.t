#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(
    build_normalized_semantic_structural_rtl_ir_contract
    normalized_semantic_structural_rtl_ir_collection_presence_keys
    normalized_semantic_structural_rtl_ir_contract_source
    normalized_semantic_structural_rtl_ir_presence_key_family_map
    normalized_semantic_structural_rtl_ir_presence_keys
    normalized_semantic_structural_rtl_ir_summary_presence_keys
);

subtest 'contract exposes the bounded normalized semantic structural-rtl-ir object' => sub {
    my $contract = build_normalized_semantic_structural_rtl_ir_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested structural-rtl-ir object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_structural_rtl_ir_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'structural_rtl_ir', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.forward_ir.structural_rtl_ir', 'contract records the nested parent path');
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested structural-rtl-ir object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_structural_rtl_ir_presence_keys(),
        'contract publishes the bounded structural-rtl-ir key list',
    );
    is_deeply(
        $contract->{summary_presence_keys},
        normalized_semantic_structural_rtl_ir_summary_presence_keys(),
        'contract publishes the bounded structural-rtl-ir summary key family',
    );
    is_deeply(
        $contract->{collection_presence_keys},
        normalized_semantic_structural_rtl_ir_collection_presence_keys(),
        'contract publishes the bounded structural-rtl-ir collection key family',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_structural_rtl_ir_presence_key_family_map(),
        'contract publishes the grouped structural-rtl-ir key-family map',
    );
};

done_testing();
