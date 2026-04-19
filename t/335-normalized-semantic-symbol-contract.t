#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticPayloadContract qw(
    normalized_semantic_payload_symbol_contract_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_symbol_contract_keys
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    build_normalized_semantic_symbol_contract
    normalized_semantic_symbol_contract_presence_keys
);

subtest 'contract exposes the bounded normalized semantic symbol-contract object' => sub {
    my $contract = build_normalized_semantic_symbol_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested symbol-contract object as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::NormalizedSemanticSymbolContract',
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
        normalized_semantic_payload_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'semantic payload symbol-contract keys map to the nested symbol-contract owner',
    );
    is_deeply(
        normalized_semantic_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'normalized semantic report symbol-contract keys map to the nested symbol-contract owner',
    );
};

done_testing();
