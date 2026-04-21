#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ReportProducerContract qw(
    build_report_producer_contract
    normalized_semantic_report_producer_extra_keys
    report_producer_presence_key_family_map
    report_producer_contract_source
    report_producer_common_keys
);

subtest 'contract exposes the bounded shared report producer object' => sub {
    my $contract = build_report_producer_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the shared nested object as bounded public');
    is(
        $contract->{contract_source},
        report_producer_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'producer', 'contract records the nested object name');
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Support::CheckDiagnostics
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        'contract records the public report builders that reuse the nested object',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested producer object is JSON-safe when embedded in public reports',
    );
    ok(
        $contract->{reused_across_public_reports},
        'contract says the nested producer object is reused across public report surfaces',
    );
    is_deeply(
        $contract->{common_presence_keys},
        report_producer_common_keys(),
        'contract publishes the bounded producer common key list',
    );
    is_deeply(
        $contract->{normalized_semantic_extra_presence_keys},
        normalized_semantic_report_producer_extra_keys(),
        'contract publishes the bounded normalized-semantic producer extra key list',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        report_producer_presence_key_family_map(),
        'contract publishes the grouped producer key-family discovery map',
    );
};

done_testing();
