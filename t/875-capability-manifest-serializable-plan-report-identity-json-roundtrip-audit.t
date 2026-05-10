#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'manifest-embedded serializable plan reports identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest serializable plan report contract keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest serializable plan report contract keeps contract_source');
    is($contract->{'purpose'}, $expected->{'purpose'}, 'decoded manifest serializable plan report contract keeps purpose');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest serializable plan report contract keeps schema_version');
};
done_testing();
