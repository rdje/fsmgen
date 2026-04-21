#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ReportGeneratedOutputContract qw(
    build_report_generated_output_contract
    report_generated_output_contract_source
    report_generated_output_presence_keys
);

subtest 'contract exposes the bounded shared report generated_output object' => sub {
    my $contract = build_report_generated_output_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the shared nested object as bounded public');
    is(
        $contract->{contract_source},
        report_generated_output_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'generated_output', 'contract records the nested object name');
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
        'contract says the nested generated_output object is JSON-safe when embedded in public reports',
    );
    ok(
        $contract->{reused_across_public_reports},
        'contract says the nested generated_output object is reused across public report surfaces',
    );
    is_deeply(
        $contract->{public_presence_keys},
        report_generated_output_presence_keys(),
        'contract publishes the bounded generated_output-object key list',
    );
};

done_testing();
