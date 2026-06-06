#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticPayloadContract qw(
    normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_payload_symbol_contract_constant_value_entry_keys
    normalized_semantic_payload_symbol_contract_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_symbol_contract_keys
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    build_normalized_semantic_symbol_contract
    normalized_semantic_symbol_contract_constant_detail_keys
    normalized_semantic_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_symbol_contract_constant_value_entry_keys
    normalized_semantic_symbol_contract_package_import_keys
    normalized_semantic_symbol_contract_presence_key_family_map
    normalized_semantic_symbol_contract_source
    normalized_semantic_symbol_contract_presence_keys
    normalized_semantic_symbol_contract_summary_presence_keys
    normalized_semantic_symbol_contract_symbol_map_keys
    normalized_semantic_symbol_contract_symbol_name_keys
);

subtest 'contract exposes the bounded normalized semantic symbol-contract object' => sub {
    my $contract = build_normalized_semantic_symbol_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested symbol-contract object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_symbol_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'semantic.symbol_contract', 'contract records the nested object name');
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
        $contract->{optional_for_symbol_free_sources},
        'contract says the nested symbol-contract object is optional for symbol-free sources',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested symbol-contract object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_symbol_contract_presence_keys(),
        'contract publishes the bounded symbol-contract key list',
    );
    is_deeply(
        $contract->{summary_presence_keys},
        normalized_semantic_symbol_contract_summary_presence_keys(),
        'contract publishes the bounded symbol-contract summary key family',
    );
    is_deeply(
        $contract->{symbol_name_keys},
        normalized_semantic_symbol_contract_symbol_name_keys(),
        'contract publishes the bounded symbol-contract symbol-name key family',
    );
    is_deeply(
        $contract->{symbol_map_keys},
        normalized_semantic_symbol_contract_symbol_map_keys(),
        'contract publishes the bounded symbol-contract symbol-map key family',
    );
    is_deeply(
        $contract->{constant_detail_keys},
        normalized_semantic_symbol_contract_constant_detail_keys(),
        'contract publishes the bounded symbol-contract constant-detail key family',
    );
    is_deeply(
        $contract->{constant_value_entry_keys},
        normalized_semantic_symbol_contract_constant_value_entry_keys(),
        'contract publishes the bounded symbol-contract constant value core key family',
    );
    is_deeply(
        $contract->{constant_scalar_value_extension_keys},
        normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
        'contract publishes the bounded symbol-contract scalar constant value extension keys',
    );
    is_deeply(
        $contract->{constant_list_value_extension_keys},
        normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
        'contract publishes the bounded symbol-contract list constant value extension keys',
    );
    is_deeply(
        $contract->{package_import_keys},
        normalized_semantic_symbol_contract_package_import_keys(),
        'contract publishes the bounded symbol-contract package-import key family',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_symbol_contract_presence_key_family_map(),
        'contract publishes the grouped symbol-contract key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map}{constant_value_entry_keys},
        normalized_semantic_symbol_contract_constant_value_entry_keys(),
        'grouped symbol-contract family map publishes constant value core keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{constant_scalar_value_extension_keys},
        normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
        'grouped symbol-contract family map publishes scalar constant value extension keys',
    );
    is_deeply(
        $contract->{presence_key_family_map}{constant_list_value_extension_keys},
        normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
        'grouped symbol-contract family map publishes list constant value extension keys',
    );
    is_deeply(
        normalized_semantic_symbol_contract_constant_value_entry_keys(),
        [qw(kind)],
        'constant value entries always advertise a bounded kind discriminator',
    );
    is_deeply(
        normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
        [qw(payload)],
        'scalar constant values advertise the bounded payload extension',
    );
    is_deeply(
        normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
        [qw(items)],
        'list constant values advertise the bounded items extension',
    );
    is_deeply(
        normalized_semantic_payload_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'semantic payload symbol-contract keys map to the nested symbol-contract owner',
    );
    is_deeply(
        normalized_semantic_payload_symbol_contract_constant_value_entry_keys(),
        normalized_semantic_symbol_contract_constant_value_entry_keys(),
        'semantic payload symbol-contract constant value core keys map to the nested symbol-contract owner',
    );
    is_deeply(
        normalized_semantic_payload_symbol_contract_constant_scalar_value_extension_keys(),
        normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
        'semantic payload scalar constant value extension keys map to the nested symbol-contract owner',
    );
    is_deeply(
        normalized_semantic_payload_symbol_contract_constant_list_value_extension_keys(),
        normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
        'semantic payload list constant value extension keys map to the nested symbol-contract owner',
    );
    is_deeply(
        normalized_semantic_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'normalized semantic report symbol-contract keys map to the nested symbol-contract owner',
    );
    is_deeply(
        FSM::Support::NormalizedSemanticReportContract::normalized_semantic_symbol_contract_constant_value_entry_keys(),
        normalized_semantic_symbol_contract_constant_value_entry_keys(),
        'normalized semantic report symbol-contract constant value core keys map to the nested symbol-contract owner',
    );
    is_deeply(
        FSM::Support::NormalizedSemanticReportContract::normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
        normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
        'normalized semantic report scalar constant value extension keys map to the nested symbol-contract owner',
    );
    is_deeply(
        FSM::Support::NormalizedSemanticReportContract::normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
        normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
        'normalized semantic report list constant value extension keys map to the nested symbol-contract owner',
    );
};

done_testing();
