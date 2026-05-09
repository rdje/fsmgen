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
    hdl_generator_result_stable_subsurface_map
);

subtest 'HDLGenerator result stable subsurface map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{stable_subsurface_map},
        hdl_generator_result_stable_subsurface_map(),
        'decoded contract keeps canonical stable subsurface map',
    );
    is_deeply(
        $decoded->{stable_subsurface_map}{source_info},
        $decoded->{source_info_stable_subsurfaces},
        'decoded source_info stable subsurfaces match grouped map',
    );
    is_deeply(
        $decoded->{stable_subsurface_map}{module_info},
        $decoded->{module_info_stable_subsurfaces},
        'decoded module_info stable subsurfaces match grouped map',
    );
    is_deeply(
        $decoded->{stable_subsurface_map}{statistics},
        $decoded->{statistics_stable_subsurfaces},
        'decoded statistics stable subsurfaces match grouped map',
    );
};

done_testing();
