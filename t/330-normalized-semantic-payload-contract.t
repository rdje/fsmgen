#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_presence_keys
);
use FSM::Support::NormalizedSemanticForwardIRContract qw(
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_module_presence_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
    build_normalized_semantic_payload_contract
    normalized_semantic_payload_composition_keys
    normalized_semantic_payload_forward_ir_keys
    normalized_semantic_payload_presence_keys
);

subtest 'contract exposes the bounded normalized semantic payload object' => sub {
    my $contract = build_normalized_semantic_payload_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested semantic object as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::NormalizedSemanticPayloadContract',
        'contract records its own owner',
    );
    is($contract->{object_name}, 'semantic', 'contract records the nested object name');
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
        'contract says the nested semantic object is JSON-safe when embedded in public reports',
    );
    is(
        $contract->{module_contract_source},
        'FSM::Support::NormalizedSemanticModuleContract',
        'contract records the nested module object owner',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_payload_presence_keys(),
        'contract publishes the bounded semantic-object key list',
    );
    is_deeply(
        $contract->{module_presence_keys},
        normalized_semantic_module_presence_keys(),
        'contract publishes the bounded module-object key list',
    );
    is_deeply(
        $contract->{module_optional_metric_keys},
        normalized_semantic_module_optional_metric_keys(),
        'contract publishes the bounded optional module metric key list',
    );
    is(
        $contract->{composition_contract_source},
        'FSM::Support::NormalizedSemanticCompositionContract',
        'contract records the nested composition object owner',
    );
    is(
        $contract->{forward_ir_contract_source},
        'FSM::Support::NormalizedSemanticForwardIRContract',
        'contract records the nested forward-IR object owner',
    );
    is_deeply(
        $contract->{forward_ir_presence_keys},
        normalized_semantic_payload_forward_ir_keys(),
        'contract publishes the bounded forward-IR key list',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'semantic payload forward-IR keys map to the nested forward-IR owner',
    );
    is_deeply(
        $contract->{composition_presence_keys},
        normalized_semantic_composition_presence_keys(),
        'contract publishes the bounded composition key list',
    );
    is_deeply(
        normalized_semantic_payload_composition_keys(),
        normalized_semantic_composition_presence_keys(),
        'semantic payload composition keys map to the nested composition owner',
    );
};

done_testing();
