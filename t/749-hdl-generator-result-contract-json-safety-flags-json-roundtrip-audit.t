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
);

subtest 'HDLGenerator result stability and advertisement flags survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    for my $field (qw(
        nested_identity_slices_advertised
        source_info_summary_slices_advertised
        module_info_summary_slices_advertised
        statistics_summary_slices_advertised
        top_level_semantic_layer_contracts_advertised
    )) {
        is($decoded->{$field}, 1, "decoded $field remains true");
    }

    for my $field (qw(
        stable_nested_content
        full_result_json_safe
    )) {
        is($decoded->{$field}, 0, "decoded $field remains false");
    }

    is(
        $decoded->{json_safe_export_surface},
        'semantic_exports.normalized_semantic_json',
        'decoded contract keeps sanitized JSON export surface',
    );
};

done_testing();
