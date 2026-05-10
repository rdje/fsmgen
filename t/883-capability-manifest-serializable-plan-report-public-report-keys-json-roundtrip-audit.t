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

subtest 'manifest-embedded serializable plan reports public report key metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is($contract->{'composition_report_json_fragment_path'}, $expected->{'composition_report_json_fragment_path'}, 'decoded manifest serializable plan report contract keeps composition_report_json_fragment_path');
    is_deeply($contract->{'normalized_semantic_report_public_top_level_keys'}, $expected->{'normalized_semantic_report_public_top_level_keys'}, 'decoded manifest serializable plan report contract keeps normalized_semantic_report_public_top_level_keys');
    is_deeply($contract->{'composition_report_public_top_level_keys'}, $expected->{'composition_report_public_top_level_keys'}, 'decoded manifest serializable plan report contract keeps composition_report_public_top_level_keys');
};
done_testing();
