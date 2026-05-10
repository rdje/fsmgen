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

subtest 'manifest-embedded HDLGenerator optional composition map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply(
        $contract->{optional_composition_key_family_map},
        $expected->{optional_composition_key_family_map},
        'decoded manifest result contract keeps grouped optional composition key-family map',
    );
    is_deeply($contract->{module_info_optional_composition_summary_keys}, $expected->{module_info_optional_composition_summary_keys}, 'decoded manifest result contract keeps module_info optional composition keys');

};

done_testing();
