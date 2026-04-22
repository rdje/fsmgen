#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ReportSourceContract qw(
    build_report_source_contract
    report_source_input_keys
    report_source_presence_key_family_map
    report_source_contract_source
    report_source_presence_keys
    report_source_resolution_keys
);

subtest 'contract exposes the bounded shared report source object' => sub {
    my $contract = build_report_source_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the shared nested object as bounded public');
    is(
        $contract->{contract_source},
        report_source_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'source', 'contract records the nested object name');
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
        'contract says the nested source object is JSON-safe when embedded in public reports',
    );
    ok(
        $contract->{reused_across_public_reports},
        'contract says the nested source object is reused across public report surfaces',
    );
    is_deeply(
        $contract->{public_presence_keys},
        report_source_presence_keys(),
        'contract publishes the bounded source-object key list',
    );
    is_deeply(
        $contract->{input_keys},
        report_source_input_keys(),
        'contract publishes the bounded source input key family',
    );
    is_deeply(
        $contract->{resolution_keys},
        report_source_resolution_keys(),
        'contract publishes the bounded source resolution key family',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        report_source_presence_key_family_map(),
        'contract publishes the grouped source key-family map',
    );
};

done_testing();
