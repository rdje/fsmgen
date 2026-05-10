#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

subtest 'manifest-embedded HDLGenerator `resolved_package_imports` shell surfaces survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{resolved_package_imports_contract_source}, $expected->{resolved_package_imports_contract_source}, 'decoded manifest result contract keeps package-import contract owner');
    is($contract->{resolved_package_imports_shell_only} ? 1 : 0, $expected->{resolved_package_imports_shell_only} ? 1 : 0, 'decoded manifest result contract keeps package-import shell-only flag');
    is($contract->{resolved_package_imports_raw_value_class}, $expected->{resolved_package_imports_raw_value_class}, 'decoded manifest result contract keeps package-import raw value class');
    is_deeply($contract->{resolved_package_imports_summary_surface}, $expected->{resolved_package_imports_summary_surface}, 'decoded manifest result contract keeps package-import summary surface');
    is_deeply($contract->{resolved_package_imports_fallback_surface_map}, $expected->{resolved_package_imports_fallback_surface_map}, 'decoded manifest result contract keeps package-import fallback surface map');

};

done_testing();
