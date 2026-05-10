#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CapabilityManifestContract qw(build_capability_manifest_contract);

subtest 'manifest contract manifest safety flags survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{manifest_contract};
    my $expected = build_capability_manifest_contract();
    is($contract->{'full_manifest_json_safe'} ? 1 : 0, $expected->{'full_manifest_json_safe'} ? 1 : 0, 'decoded manifest contract keeps full_manifest_json_safe');
    is($contract->{'nested_section_contracts_advertised'} ? 1 : 0, $expected->{'nested_section_contracts_advertised'} ? 1 : 0, 'decoded manifest contract keeps nested_section_contracts_advertised');
};
done_testing();
