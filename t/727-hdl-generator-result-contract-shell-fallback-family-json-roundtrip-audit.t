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
    hdl_generator_result_shell_only_fallback_surface_family_map
);

subtest 'HDLGenerator result shell-only fallback family map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));
    my $family_map = $decoded->{shell_only_fallback_surface_family_map};

    is_deeply(
        $family_map,
        hdl_generator_result_shell_only_fallback_surface_family_map(),
        'decoded contract keeps canonical shell-only fallback family map',
    );
    is_deeply($family_map->{fsm_module}, $decoded->{fsm_module_fallback_surface_map}, 'fsm_module family matches scalar field');
    is_deeply($family_map->{raw_ast}, $decoded->{raw_ast_fallback_surface_map}, 'raw_ast family matches scalar field');
    is_deeply(
        $family_map->{resolved_package_imports},
        $decoded->{resolved_package_imports_fallback_surface_map},
        'resolved_package_imports family matches scalar field',
    );
    is_deeply($family_map->{composition_spec}, $decoded->{composition_spec_fallback_surface_map}, 'composition_spec family matches scalar field');
    is_deeply($family_map->{composition_plan}, $decoded->{composition_plan_fallback_surface_map}, 'composition_plan family matches scalar field');
    is_deeply(
        $family_map->{composition_report}{sanitized_json_fragment},
        [$decoded->{composition_report_json_fragment_path}],
        'composition_report family matches JSON fragment path',
    );
};

done_testing();
