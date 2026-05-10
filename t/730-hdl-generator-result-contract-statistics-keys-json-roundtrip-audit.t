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
    hdl_generator_result_statistics_optional_composition_keys
    hdl_generator_result_statistics_summary_keys
);

subtest 'HDLGenerator result statistics keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{statistics_summary_presence_keys},
        hdl_generator_result_statistics_summary_keys(),
        'decoded contract keeps canonical statistics summary keys',
    );
    is_deeply(
        $decoded->{statistics_optional_composition_keys},
        hdl_generator_result_statistics_optional_composition_keys(),
        'decoded contract keeps canonical statistics optional composition keys',
    );
    ok(!$decoded->{statistics_full_hash_stable}, 'decoded contract keeps statistics full hash non-stable');
};

subtest 'decoded optional composition map mirrors statistics key list' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{optional_composition_key_family_map}{statistics_optional_composition_keys},
        $decoded->{statistics_optional_composition_keys},
        'decoded optional family map mirrors decoded statistics optional composition keys',
    );
};

done_testing();
