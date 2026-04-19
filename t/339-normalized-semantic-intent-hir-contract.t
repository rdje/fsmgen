#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    build_normalized_semantic_intent_hir_contract
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_keys
);

subtest 'contract exposes the bounded normalized semantic intent-hir object' => sub {
    my $contract = build_normalized_semantic_intent_hir_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested intent-hir object as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::NormalizedSemanticIntentHIRContract',
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
};

done_testing();
