#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorCompositionPlanContract qw(
    hdl_generator_composition_plan_fallback_surface_map
    hdl_generator_composition_plan_summary_surfaces
);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

subtest 'HDLGenerator result composition_plan shell surfaces survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{composition_plan_summary_surfaces},
        hdl_generator_composition_plan_summary_surfaces(),
        'decoded result contract keeps canonical composition_plan summary surfaces',
    );
    is_deeply(
        $decoded->{composition_plan_fallback_surface_map},
        hdl_generator_composition_plan_fallback_surface_map(),
        'decoded result contract keeps canonical composition_plan fallback surface map',
    );
    is_deeply(
        $decoded->{shell_only_fallback_surface_map}{composition_plan},
        $decoded->{composition_plan_summary_surfaces},
        'decoded grouped shell fallback map mirrors composition_plan summary surfaces',
    );
    is_deeply(
        $decoded->{shell_only_fallback_surface_family_map}{composition_plan},
        $decoded->{composition_plan_fallback_surface_map},
        'decoded grouped shell fallback family map mirrors composition_plan fallback map',
    );
};

done_testing();
