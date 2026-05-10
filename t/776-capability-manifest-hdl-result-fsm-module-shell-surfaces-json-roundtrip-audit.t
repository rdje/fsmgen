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

subtest 'manifest-embedded HDLGenerator `fsm_module` shell surfaces survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{fsm_module_contract_source}, $expected->{fsm_module_contract_source}, 'decoded manifest result contract keeps fsm_module contract owner');
    is($contract->{fsm_module_shell_only} ? 1 : 0, $expected->{fsm_module_shell_only} ? 1 : 0, 'decoded manifest result contract keeps fsm_module shell-only flag');
    is($contract->{fsm_module_raw_value_class_when_defined}, $expected->{fsm_module_raw_value_class_when_defined}, 'decoded manifest result contract keeps fsm_module raw value class');
    is_deeply($contract->{fsm_module_summary_surfaces}, $expected->{fsm_module_summary_surfaces}, 'decoded manifest result contract keeps fsm_module summary surfaces');
    is_deeply($contract->{fsm_module_fallback_surface_map}, $expected->{fsm_module_fallback_surface_map}, 'decoded manifest result contract keeps fsm_module fallback surface map');

};

done_testing();
