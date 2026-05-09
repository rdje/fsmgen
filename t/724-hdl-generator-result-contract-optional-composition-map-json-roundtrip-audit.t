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
    hdl_generator_result_optional_composition_key_family_map
);

subtest 'HDLGenerator result optional composition family map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));
    my $family_map = $decoded->{optional_composition_key_family_map};

    is_deeply(
        $family_map,
        hdl_generator_result_optional_composition_key_family_map(),
        'decoded contract keeps canonical optional composition family map',
    );
    is_deeply(
        $family_map->{module_info_optional_composition_summary_keys},
        $decoded->{module_info_optional_composition_summary_keys},
        'decoded module_info optional composition keys match grouped map',
    );
    is_deeply(
        $family_map->{statistics_optional_composition_keys},
        $decoded->{statistics_optional_composition_keys},
        'decoded statistics optional composition keys match grouped map',
    );
    is_deeply(
        $family_map->{intent_hir_optional_composition_keys},
        $decoded->{intent_hir_optional_composition_keys},
        'decoded intent_hir optional composition keys match grouped map',
    );
    is_deeply(
        $family_map->{lowered_rtl_ir_optional_composition_keys},
        $decoded->{lowered_rtl_ir_optional_composition_keys},
        'decoded lowered_rtl_ir optional composition keys match grouped map',
    );
};

done_testing();
