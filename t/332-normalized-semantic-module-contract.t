#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticModuleContract qw(
    build_normalized_semantic_module_contract
    normalized_semantic_module_contract_source
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_module_presence_key_family_map
    normalized_semantic_module_presence_keys
);

subtest 'contract exposes the bounded normalized semantic module object' => sub {
    my $contract = build_normalized_semantic_module_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested module object as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_module_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'module', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.module', 'contract records the nested parent path');
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        'contract records the public report builder that reuses the nested module object',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested module object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_module_presence_keys(),
        'contract publishes the bounded module-object key list',
    );
    is_deeply(
        $contract->{optional_metric_keys},
        normalized_semantic_module_optional_metric_keys(),
        'contract publishes the bounded optional module metric key list',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_module_presence_key_family_map(),
        'contract publishes the grouped semantic.module key-family discovery map',
    );
};

done_testing();
