#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
    hdl_generator_result_semantic_layer_presence_key_family_map
);

subtest 'HDLGenerator result semantic-layer family map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));
    my $family_map = $decoded->{semantic_layer_presence_key_family_map};

    is_deeply(
        $family_map,
        hdl_generator_result_semantic_layer_presence_key_family_map(),
        'decoded contract keeps canonical semantic-layer presence family map',
    );
    is_deeply(
        $family_map->{intent_hir_presence_keys},
        $decoded->{intent_hir_presence_keys},
        'decoded intent_hir presence keys match grouped map',
    );
    is_deeply(
        $family_map->{lowered_rtl_ir_presence_keys},
        $decoded->{lowered_rtl_ir_presence_keys},
        'decoded lowered_rtl_ir presence keys match grouped map',
    );
    is_deeply(
        $family_map->{structural_rtl_ir_presence_keys},
        $decoded->{structural_rtl_ir_presence_keys},
        'decoded structural_rtl_ir presence keys match grouped map',
    );
};

done_testing();
