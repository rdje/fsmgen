#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CheckFailureDiagnosticContract qw(
    build_check_failure_diagnostic_contract
    check_failure_diagnostic_contract_source
    check_failure_diagnostic_matched_presence_keys
    check_failure_diagnostic_optional_artifact_keys
    check_failure_diagnostic_presence_key_family_map
    check_failure_diagnostic_presence_keys
    check_failure_diagnostic_support_accounting_matched_presence_keys
    check_failure_diagnostic_support_accounting_presence_keys
);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_contract_source
);

subtest 'contract exposes the bounded check failure diagnostic object' => sub {
    my $contract = build_check_failure_diagnostic_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the nested failure diagnostic object as bounded public');
    is(
        $contract->{contract_source},
        check_failure_diagnostic_contract_source(),
        'contract records its own owner',
    );
    is($contract->{object_name}, 'diagnostic', 'contract records the nested object name');
    is($contract->{parent_object_name}, 'diagnostics[]', 'contract records the parent diagnostics array');
    is_deeply(
        $contract->{report_sources},
        [
            qw(
                FSM::Support::CheckDiagnostics
                FSM::Support::NormalizedSemanticReport
            ),
        ],
        'contract records the public report builders that reuse the nested diagnostic object',
    );
    ok(
        $contract->{reused_across_public_reports},
        'contract says the nested failure diagnostic object is reused across public reports',
    );
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            support_accounting => support_accounting_match_contract_source(),
        },
        'contract publishes the bounded failure-diagnostic nested-contract ownership map',
    );
    is(
        $contract->{support_accounting_contract_source},
        support_accounting_match_contract_source(),
        'contract records the nested support-accounting owner',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested failure diagnostic object is JSON-safe when embedded in public reports',
    );
    is_deeply(
        $contract->{public_presence_keys},
        check_failure_diagnostic_presence_keys(),
        'contract publishes the bounded failure-diagnostic key list',
    );
    is_deeply(
        $contract->{matched_presence_keys},
        check_failure_diagnostic_matched_presence_keys(),
        'contract publishes the matched-only failure-diagnostic key list',
    );
    is_deeply(
        $contract->{optional_artifact_keys},
        check_failure_diagnostic_optional_artifact_keys(),
        'contract publishes the optional extracted artifact key list',
    );
    is_deeply(
        $contract->{support_accounting_presence_keys},
        check_failure_diagnostic_support_accounting_presence_keys(),
        'contract publishes the common nested support-accounting key list',
    );
    is_deeply(
        $contract->{matched_support_accounting_presence_keys},
        check_failure_diagnostic_support_accounting_matched_presence_keys(),
        'contract publishes the matched nested support-accounting key list',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        check_failure_diagnostic_presence_key_family_map(),
        'contract publishes the grouped failure-diagnostic key-family discovery map',
    );
};

done_testing();
