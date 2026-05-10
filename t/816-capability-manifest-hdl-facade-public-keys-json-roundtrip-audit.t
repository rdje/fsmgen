#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
);

subtest 'manifest-embedded HDLGenerator facade public key and method lists survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'decoded manifest facade keeps public_top_level_presence_keys');
    is_deeply($contract->{'method_names'}, $expected->{'method_names'}, 'decoded manifest facade keeps method_names');
    is_deeply($contract->{'target_language_names'}, $expected->{'target_language_names'}, 'decoded manifest facade keeps target_language_names');
};

done_testing();
