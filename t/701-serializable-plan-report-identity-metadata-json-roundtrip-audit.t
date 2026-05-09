#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_contract_source
);

subtest 'serializable plan/report identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));

    is($decoded->{schema_version}, 1, 'decoded contract keeps schema version 1');
    is($decoded->{status}, 'bounded_public', 'decoded contract keeps bounded_public status');
    is(
        $decoded->{contract_source},
        serializable_plan_report_contract_source(),
        'decoded contract keeps canonical contract source',
    );
    ok(
        defined($decoded->{purpose}) && !ref($decoded->{purpose}) && length($decoded->{purpose}),
        'decoded contract keeps non-empty scalar purpose',
    );
    like(
        $decoded->{purpose},
        qr/JSON-safe plan\/report surfaces/,
        'decoded purpose describes JSON-safe plan/report surfaces',
    );
};

done_testing();
