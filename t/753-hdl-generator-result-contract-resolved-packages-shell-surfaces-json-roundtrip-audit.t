#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResolvedPackageImportsContract qw(
    hdl_generator_resolved_package_imports_fallback_surface_map
    hdl_generator_resolved_package_imports_summary_surface
);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

subtest 'HDLGenerator result resolved_package_imports shell surfaces survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{resolved_package_imports_summary_surface},
        hdl_generator_resolved_package_imports_summary_surface(),
        'decoded result contract keeps canonical resolved_package_imports summary surface',
    );
    is_deeply(
        $decoded->{resolved_package_imports_fallback_surface_map},
        hdl_generator_resolved_package_imports_fallback_surface_map(),
        'decoded result contract keeps canonical resolved_package_imports fallback surface map',
    );
    is_deeply(
        $decoded->{shell_only_fallback_surface_map}{resolved_package_imports},
        $decoded->{resolved_package_imports_summary_surface},
        'decoded grouped shell fallback map mirrors resolved_package_imports summary surface',
    );
    is_deeply(
        $decoded->{shell_only_fallback_surface_family_map}{resolved_package_imports},
        $decoded->{resolved_package_imports_fallback_surface_map},
        'decoded grouped shell fallback family map mirrors resolved_package_imports fallback map',
    );
};

done_testing();
