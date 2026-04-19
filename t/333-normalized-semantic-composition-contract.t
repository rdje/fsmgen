#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::NormalizedSemanticCompositionContract qw(
    build_normalized_semantic_composition_contract
    normalized_semantic_composition_presence_keys
);

subtest 'contract exposes the bounded normalized semantic composition object' => sub {
    my $contract = build_normalized_semantic_composition_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested composition object as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::NormalizedSemanticCompositionContract',
        'contract records its own owner',
    );
    is($contract->{object_name}, 'composition', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'semantic.composition', 'contract records the nested parent path');
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        'contract records the public report builder that reuses the nested composition object',
    );
    is(
        $contract->{provenance_report_contract_source},
        'FSM::Support::CompositionReportContract',
        'contract records the nested provenance-report owner',
    );
    ok(
        $contract->{optional_for_non_composition_sources},
        'contract says the nested composition object is optional for non-composition sources',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested composition object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        normalized_semantic_composition_presence_keys(),
        'contract publishes the bounded composition-object key list',
    );
};

done_testing();
