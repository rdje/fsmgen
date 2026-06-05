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
    normalized_semantic_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_structural_rtl_ir_link_entry_keys
    normalized_semantic_structural_rtl_ir_net_entry_keys
    normalized_semantic_structural_rtl_ir_presence_key_family_map
    normalized_semantic_structural_rtl_ir_presence_keys
    normalized_semantic_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_structural_rtl_ir_port_entry_keys
    normalized_semantic_structural_rtl_ir_resolved_link_entry_keys
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
        $contract->{port_entry_keys},
        normalized_semantic_structural_rtl_ir_port_entry_keys(),
        'contract publishes the bounded structural-rtl-ir port entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_port_entry_keys(),
        [qw(direction name signed type width)],
        'structural-rtl-ir port entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{port_composition_extension_keys},
        normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        'contract publishes the bounded structural-rtl-ir port composition extension key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        [qw(binding_mode origin_kind)],
        'structural-rtl-ir port composition extension keys stay exact and ordered',
    );
    is_deeply(
        $contract->{net_entry_keys},
        normalized_semantic_structural_rtl_ir_net_entry_keys(),
        'contract publishes the bounded structural-rtl-ir net entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_net_entry_keys(),
        [qw(name source targets width)],
        'structural-rtl-ir net entry keys stay exact and ordered',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_link_entry_keys(),
        [qw(origin_kind raw_token source target)],
        'structural-rtl-ir shared link entry keys stay exact and ordered',
    );
    is_deeply(
        $contract->{declared_link_entry_keys},
        normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        'contract publishes the bounded structural-rtl-ir declared-link entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        normalized_semantic_structural_rtl_ir_link_entry_keys(),
        'structural-rtl-ir declared-link entry keys reuse the shared link entry shape',
    );
    is_deeply(
        $contract->{resolved_link_entry_keys},
        normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
        'contract publishes the bounded structural-rtl-ir resolved-link entry key family',
    );
    is_deeply(
        normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
        normalized_semantic_structural_rtl_ir_link_entry_keys(),
        'structural-rtl-ir resolved-link entry keys reuse the shared link entry shape',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_structural_rtl_ir_presence_key_family_map(),
        'contract publishes the grouped structural-rtl-ir key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map}{port_entry_keys},
        normalized_semantic_structural_rtl_ir_port_entry_keys(),
        'grouped structural-rtl-ir family map publishes port entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{port_composition_extension_keys},
        normalized_semantic_structural_rtl_ir_port_composition_extension_keys(),
        'grouped structural-rtl-ir family map publishes port composition extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{net_entry_keys},
        normalized_semantic_structural_rtl_ir_net_entry_keys(),
        'grouped structural-rtl-ir family map publishes net entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{declared_link_entry_keys},
        normalized_semantic_structural_rtl_ir_declared_link_entry_keys(),
        'grouped structural-rtl-ir family map publishes declared-link entry keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{resolved_link_entry_keys},
        normalized_semantic_structural_rtl_ir_resolved_link_entry_keys(),
        'grouped structural-rtl-ir family map publishes resolved-link entry keys',
    );
};

done_testing();
