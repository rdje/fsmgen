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
    hdl_generator_result_module_info_identity_keys
    hdl_generator_result_module_info_optional_composition_summary_keys
    hdl_generator_result_module_info_summary_keys
);

subtest 'HDLGenerator result module_info keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{module_info_identity_presence_keys},
        hdl_generator_result_module_info_identity_keys(),
        'decoded contract keeps canonical module_info identity keys',
    );
    is_deeply(
        $decoded->{module_info_summary_presence_keys},
        hdl_generator_result_module_info_summary_keys(),
        'decoded contract keeps canonical module_info summary keys',
    );
    is_deeply(
        $decoded->{module_info_optional_composition_summary_keys},
        hdl_generator_result_module_info_optional_composition_summary_keys(),
        'decoded contract keeps canonical module_info optional composition keys',
    );
    ok(!$decoded->{module_info_full_hash_stable}, 'decoded contract keeps module_info full hash non-stable');
};

subtest 'decoded optional composition map mirrors module_info key list' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{optional_composition_key_family_map}{module_info_optional_composition_summary_keys},
        $decoded->{module_info_optional_composition_summary_keys},
        'decoded optional family map mirrors decoded module_info optional composition keys',
    );
};

done_testing();
