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

subtest 'manifest contract tooling section presence keys survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{manifest_contract};
    my $expected = build_capability_manifest_contract();
    is_deeply($contract->{'backend_validation_presence_keys'}, $expected->{'backend_validation_presence_keys'}, 'decoded manifest contract keeps backend_validation_presence_keys');
    is_deeply($contract->{'embedding_presence_keys'}, $expected->{'embedding_presence_keys'}, 'decoded manifest contract keeps embedding_presence_keys');
    is_deeply($contract->{'language_surface_presence_keys'}, $expected->{'language_surface_presence_keys'}, 'decoded manifest contract keeps language_surface_presence_keys');
    is_deeply($contract->{'documentation_presence_keys'}, $expected->{'documentation_presence_keys'}, 'decoded manifest contract keeps documentation_presence_keys');
};
done_testing();
