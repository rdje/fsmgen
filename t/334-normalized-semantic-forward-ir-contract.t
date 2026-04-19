#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticForwardIRContract qw(
    build_normalized_semantic_forward_ir_contract
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
    normalized_semantic_payload_forward_ir_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_forward_ir_keys
);

subtest 'contract exposes the bounded normalized semantic forward-IR object' => sub {
    my $contract = build_normalized_semantic_forward_ir_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested forward-IR object as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::NormalizedSemanticForwardIRContract',
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
        normalized_semantic_payload_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'semantic payload forward-IR keys map to the nested forward-IR owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'normalized semantic report forward-IR keys map to the nested forward-IR owner',
    );
};

done_testing();
