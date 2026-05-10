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

subtest 'manifest-embedded HDLGenerator facade constructor option families survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is_deeply($contract->{'public_constructor_option_names'}, $expected->{'public_constructor_option_names'}, 'decoded manifest facade keeps public_constructor_option_names');
    is_deeply($contract->{'core_constructor_option_names'}, $expected->{'core_constructor_option_names'}, 'decoded manifest facade keeps core_constructor_option_names');
    is_deeply($contract->{'compatibility_constructor_option_names'}, $expected->{'compatibility_constructor_option_names'}, 'decoded manifest facade keeps compatibility_constructor_option_names');
    is_deeply($contract->{'direct_extension_option_names'}, $expected->{'direct_extension_option_names'}, 'decoded manifest facade keeps direct_extension_option_names');
    is_deeply($contract->{'constructor_option_family_map'}, $expected->{'constructor_option_family_map'}, 'decoded manifest facade keeps constructor_option_family_map');
};

done_testing();
