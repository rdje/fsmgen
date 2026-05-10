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

subtest 'manifest-embedded HDLGenerator facade generation boundary metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is($contract->{'constructor_receiver_shape'}, $expected->{'constructor_receiver_shape'}, 'decoded manifest facade keeps constructor_receiver_shape');
    is($contract->{'generation_receiver_shape'}, $expected->{'generation_receiver_shape'}, 'decoded manifest facade keeps generation_receiver_shape');
    is($contract->{'generation_receiver_instance_shape'}, $expected->{'generation_receiver_instance_shape'}, 'decoded manifest facade keeps generation_receiver_instance_shape');
    is($contract->{'generation_argument_list_shape'}, $expected->{'generation_argument_list_shape'}, 'decoded manifest facade keeps generation_argument_list_shape');
    is($contract->{'generation_argument_shape'}, $expected->{'generation_argument_shape'}, 'decoded manifest facade keeps generation_argument_shape');
};

done_testing();
