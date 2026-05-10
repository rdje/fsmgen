#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

subtest 'manifest-embedded HDLGenerator semantic layer map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply(
        $contract->{semantic_layer_presence_key_family_map},
        $expected->{semantic_layer_presence_key_family_map},
        'decoded manifest result contract keeps grouped semantic-layer key-family map',
    );
    is_deeply($contract->{structural_rtl_ir_presence_keys}, $expected->{structural_rtl_ir_presence_keys}, 'decoded manifest result contract keeps structural RTL IR presence keys');

};

done_testing();
