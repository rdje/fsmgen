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

subtest 'manifest-embedded serializable plan reports embedded child contracts survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is_deeply($contract->{'composition_plan_snapshot_contract'}, $expected->{'composition_plan_snapshot_contract'}, 'decoded manifest serializable plan report contract keeps composition_plan_snapshot_contract');
    is_deeply($contract->{'generation_result_snapshot_contract'}, $expected->{'generation_result_snapshot_contract'}, 'decoded manifest serializable plan report contract keeps generation_result_snapshot_contract');
    is_deeply($contract->{'diagnostic_summary_contract'}, $expected->{'diagnostic_summary_contract'}, 'decoded manifest serializable plan report contract keeps diagnostic_summary_contract');
};
done_testing();
