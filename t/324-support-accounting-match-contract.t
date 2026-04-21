#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SupportAccountingMatchContract qw(
    build_support_accounting_match_contract
    support_accounting_match_contract_source
    support_accounting_match_common_keys
    support_accounting_match_failure_keys
    support_accounting_match_success_keys
);

subtest 'contract exposes the bounded shared support-accounting match object' => sub {
    my $contract = build_support_accounting_match_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the shared nested object as bounded public');
    is(
        $contract->{contract_source},
        support_accounting_match_contract_source(),
        'contract records its own owner',
    );
    ok(
        $contract->{json_safe_when_embedded_in_public_reports},
        'contract says the nested object is JSON-safe when embedded in public reports',
    );
    ok(
        $contract->{reused_across_public_reports},
        'contract says the nested object is reused across public report surfaces',
    );
    is_deeply(
        $contract->{common_presence_keys},
        support_accounting_match_common_keys(),
        'contract publishes the common key list',
    );
    is_deeply(
        $contract->{matched_success_presence_keys},
        support_accounting_match_success_keys(),
        'contract publishes the matched success key list',
    );
    is_deeply(
        $contract->{matched_failure_presence_keys},
        support_accounting_match_failure_keys(),
        'contract publishes the matched failure key list',
    );
};

done_testing();
