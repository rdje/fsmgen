#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CheckResultContract qw(
    build_check_result_contract
    check_result_contract_source
    check_result_presence_keys
);

subtest 'contract exposes the bounded check success result object' => sub {
    my $contract = build_check_result_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested result object as bounded public');
    is(
        $contract->{contract_source},
        check_result_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'result', 'contract records the nested object name');
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Support::CheckDiagnostics
            ),
        ],
        'contract records the public report builder that reuses the nested object',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested result object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        check_result_presence_keys(),
        'contract publishes the bounded result-object key list',
    );
};

done_testing();
