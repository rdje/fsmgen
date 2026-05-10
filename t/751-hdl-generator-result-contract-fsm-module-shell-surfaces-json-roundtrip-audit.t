#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorFSMModuleContract qw(
    hdl_generator_fsm_module_fallback_surface_map
    hdl_generator_fsm_module_summary_surfaces
);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

subtest 'HDLGenerator result fsm_module shell surfaces survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{fsm_module_summary_surfaces},
        hdl_generator_fsm_module_summary_surfaces(),
        'decoded result contract keeps canonical fsm_module summary surfaces',
    );
    is_deeply(
        $decoded->{fsm_module_fallback_surface_map},
        hdl_generator_fsm_module_fallback_surface_map(),
        'decoded result contract keeps canonical fsm_module fallback surface map',
    );
    is_deeply(
        $decoded->{shell_only_fallback_surface_map}{fsm_module},
        $decoded->{fsm_module_summary_surfaces},
        'decoded grouped shell fallback map mirrors fsm_module summary surfaces',
    );
    is_deeply(
        $decoded->{shell_only_fallback_surface_family_map}{fsm_module},
        $decoded->{fsm_module_fallback_surface_map},
        'decoded grouped shell fallback family map mirrors fsm_module fallback map',
    );
};

done_testing();
