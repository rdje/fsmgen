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

subtest 'manifest contract guidance list survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{manifest_contract};
    my $expected = build_capability_manifest_contract();
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest contract keeps guidance');
};
done_testing();
