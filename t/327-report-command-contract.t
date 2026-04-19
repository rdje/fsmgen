#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::ReportCommandContract qw(
    build_report_command_contract
    report_command_presence_keys
);

subtest 'contract exposes the bounded shared report command object' => sub {
    my $contract = build_report_command_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the shared nested object as bounded public');
    is(
        $contract->{contract_source},
        'FSM::Support::ReportCommandContract',
        'contract records its own owner',
    );
    is($contract->{object_name}, 'command', 'contract records the nested object name');
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
    is_deeply(
        $contract->{report_mode_map},
        {
            'FSM::Support::CheckDiagnostics' => 'check',
            'FSM::Support::NormalizedSemanticReport' => 'semantic_export',
        },
        'contract records the report-specific mode values',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested command object is JSON-safe when embedded in public reports',
    );
    ok(
        $contract->{reused_across_public_reports},
        'contract says the nested command object is reused across public report surfaces',
    );
    is_deeply(
        $contract->{public_presence_keys},
        report_command_presence_keys(),
        'contract publishes the bounded command-object key list',
    );
};

done_testing();
