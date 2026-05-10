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
    hdl_generator_result_intent_hir_keys
    hdl_generator_result_intent_hir_optional_composition_keys
    hdl_generator_result_lowered_rtl_ir_keys
    hdl_generator_result_lowered_rtl_ir_optional_composition_keys
    hdl_generator_result_structural_rtl_ir_keys
);

subtest 'HDLGenerator result semantic layer keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{intent_hir_presence_keys},
        hdl_generator_result_intent_hir_keys(),
        'decoded contract keeps canonical intent_hir presence keys',
    );
    is_deeply(
        $decoded->{intent_hir_optional_composition_keys},
        hdl_generator_result_intent_hir_optional_composition_keys(),
        'decoded contract keeps canonical intent_hir optional composition keys',
    );
    is_deeply(
        $decoded->{lowered_rtl_ir_presence_keys},
        hdl_generator_result_lowered_rtl_ir_keys(),
        'decoded contract keeps canonical lowered_rtl_ir presence keys',
    );
    is_deeply(
        $decoded->{lowered_rtl_ir_optional_composition_keys},
        hdl_generator_result_lowered_rtl_ir_optional_composition_keys(),
        'decoded contract keeps canonical lowered_rtl_ir optional composition keys',
    );
    is_deeply(
        $decoded->{structural_rtl_ir_presence_keys},
        hdl_generator_result_structural_rtl_ir_keys(),
        'decoded contract keeps canonical structural_rtl_ir presence keys',
    );
};

subtest 'decoded grouped maps mirror semantic layer key lists' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    for my $field (qw(intent_hir_presence_keys lowered_rtl_ir_presence_keys structural_rtl_ir_presence_keys)) {
        is_deeply(
            $decoded->{semantic_layer_presence_key_family_map}{$field},
            $decoded->{$field},
            "decoded semantic family map mirrors decoded $field",
        );
    }

    for my $field (qw(intent_hir_optional_composition_keys lowered_rtl_ir_optional_composition_keys)) {
        is_deeply(
            $decoded->{optional_composition_key_family_map}{$field},
            $decoded->{$field},
            "decoded optional family map mirrors decoded $field",
        );
    }
};

subtest 'decoded semantic layer full-hash flags remain non-stable' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    ok(!$decoded->{intent_hir_full_hash_stable}, 'decoded contract keeps intent_hir full hash non-stable');
    ok(!$decoded->{lowered_rtl_ir_full_hash_stable}, 'decoded contract keeps lowered_rtl_ir full hash non-stable');
    ok(!$decoded->{structural_rtl_ir_full_hash_stable}, 'decoded contract keeps structural_rtl_ir full hash non-stable');
};

done_testing();
