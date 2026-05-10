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

subtest 'manifest-embedded HDLGenerator facade constructor shape metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is($contract->{'constructor_argument_list_shape'}, $expected->{'constructor_argument_list_shape'}, 'decoded manifest facade keeps constructor_argument_list_shape');
    is($contract->{'constructor_duplicate_option_policy'}, $expected->{'constructor_duplicate_option_policy'}, 'decoded manifest facade keeps constructor_duplicate_option_policy');
    is($contract->{'constructor_unknown_option_policy'}, $expected->{'constructor_unknown_option_policy'}, 'decoded manifest facade keeps constructor_unknown_option_policy');
    is($contract->{'default_target_language'}, $expected->{'default_target_language'}, 'decoded manifest facade keeps default_target_language');
    is_deeply($contract->{'constructor_option_shape_map'}, $expected->{'constructor_option_shape_map'}, 'decoded manifest facade keeps constructor_option_shape_map');
    is_deeply($contract->{'debug_level_numeric_range'}, $expected->{'debug_level_numeric_range'}, 'decoded manifest facade keeps debug_level_numeric_range');
};

done_testing();
