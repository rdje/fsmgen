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

subtest 'manifest-embedded HDLGenerator statistics key lists survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    for my $field (qw(
        statistics_summary_presence_keys
        statistics_optional_composition_keys
        statistics_stable_subsurfaces
    )) {
        is_deeply(
            $contract->{$field},
            $expected->{$field},
            "decoded manifest result contract keeps $field",
        );
    }

};

done_testing();
