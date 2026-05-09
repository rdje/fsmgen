#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_contract_source
);

subtest 'serializable plan/report identity metadata is explicit' => sub {
    my $contract = build_serializable_plan_report_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version 1');
    is($contract->{status}, 'bounded_public', 'contract status is bounded_public');
    is(
        $contract->{contract_source},
        serializable_plan_report_contract_source(),
        'contract_source points at the canonical owner',
    );
    ok(
        defined($contract->{purpose}) && !ref($contract->{purpose}) && length($contract->{purpose}),
        'purpose is a non-empty scalar',
    );
    like(
        $contract->{purpose},
        qr/JSON-safe plan\/report surfaces/,
        'purpose describes JSON-safe plan/report surfaces',
    );
};

done_testing();
