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

subtest 'manifest-embedded HDLGenerator advertisement flags survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    for my $field (qw(
        nested_identity_slices_advertised
        source_info_summary_slices_advertised
        module_info_summary_slices_advertised
        statistics_summary_slices_advertised
        top_level_semantic_layer_contracts_advertised
    )) {
        is($contract->{$field} ? 1 : 0, $expected->{$field} ? 1 : 0, "decoded manifest result contract keeps $field");
    }

};

done_testing();
