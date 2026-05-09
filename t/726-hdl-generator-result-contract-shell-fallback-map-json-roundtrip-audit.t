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
    hdl_generator_result_shell_only_fallback_surface_map
);

subtest 'HDLGenerator result shell-only fallback map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));
    my $fallback_map = $decoded->{shell_only_fallback_surface_map};

    is_deeply(
        $fallback_map,
        hdl_generator_result_shell_only_fallback_surface_map(),
        'decoded contract keeps canonical shell-only fallback map',
    );
    is_deeply($fallback_map->{fsm_module}, $decoded->{fsm_module_summary_surfaces}, 'fsm_module fallback matches scalar field');
    is_deeply($fallback_map->{raw_ast}, $decoded->{raw_ast_summary_surfaces}, 'raw_ast fallback matches scalar field');
    is_deeply(
        $fallback_map->{resolved_package_imports},
        $decoded->{resolved_package_imports_summary_surface},
        'resolved_package_imports fallback matches scalar field',
    );
    is_deeply($fallback_map->{composition_spec}, $decoded->{composition_spec_summary_surfaces}, 'composition_spec fallback matches scalar field');
    is_deeply($fallback_map->{composition_plan}, $decoded->{composition_plan_summary_surfaces}, 'composition_plan fallback matches scalar field');
    is_deeply(
        $fallback_map->{composition_report},
        [$decoded->{composition_report_json_fragment_path}],
        'composition_report fallback matches JSON fragment path',
    );
};

done_testing();
