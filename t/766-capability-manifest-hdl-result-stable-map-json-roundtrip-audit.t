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

subtest 'manifest-embedded HDLGenerator stable subsurface map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply(
        $contract->{stable_subsurface_map},
        $expected->{stable_subsurface_map},
        'decoded manifest result contract keeps grouped stable subsurface map',
    );
    is_deeply($contract->{source_info_stable_subsurfaces}, $expected->{source_info_stable_subsurfaces}, 'decoded manifest result contract keeps source_info stable subsurfaces');

};

done_testing();
