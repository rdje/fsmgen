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

subtest 'manifest-embedded serializable plan reports JSON-safe surface keys survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is_deeply($contract->{'json_safe_surface_keys'}, $expected->{'json_safe_surface_keys'}, 'decoded manifest serializable plan report contract keeps json_safe_surface_keys');
    is_deeply($contract->{'surface_registry_entry_keys'}, $expected->{'surface_registry_entry_keys'}, 'decoded manifest serializable plan report contract keeps surface_registry_entry_keys');
};
done_testing();
