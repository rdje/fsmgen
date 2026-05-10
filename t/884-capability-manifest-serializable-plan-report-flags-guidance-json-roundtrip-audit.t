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

subtest 'manifest-embedded serializable plan reports JSON-safety flags and guidance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is($contract->{'current_serializable_surfaces_json_safe'} ? 1 : 0, $expected->{'current_serializable_surfaces_json_safe'} ? 1 : 0, 'decoded manifest serializable plan report contract keeps current_serializable_surfaces_json_safe');
    is($contract->{'raw_hdl_generator_branches_json_safe'} ? 1 : 0, $expected->{'raw_hdl_generator_branches_json_safe'} ? 1 : 0, 'decoded manifest serializable plan report contract keeps raw_hdl_generator_branches_json_safe');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest serializable plan report contract keeps guidance');
};
done_testing();
