#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(serializable_plan_report_contract_source);

subtest 'manifest plan/report identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};

    is($contract->{schema_version}, 1, 'decoded manifest keeps schema version 1');
    is($contract->{status}, 'bounded_public', 'decoded manifest keeps bounded_public status');
    is(
        $contract->{contract_source},
        serializable_plan_report_contract_source(),
        'decoded manifest keeps canonical contract source',
    );
    ok(
        defined($contract->{purpose}) && !ref($contract->{purpose}) && length($contract->{purpose}),
        'decoded manifest keeps non-empty scalar purpose',
    );
    like(
        $contract->{purpose},
        qr/JSON-safe plan\/report surfaces/,
        'decoded manifest purpose describes JSON-safe plan/report surfaces',
    );
};

done_testing();
