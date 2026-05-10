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

subtest 'manifest-embedded HDLGenerator shell-only branch metadata survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    for my $field (qw(
        fsm_module_shell_only
        raw_ast_shell_only
        resolved_package_imports_shell_only
        composition_spec_shell_only
        composition_plan_shell_only
        composition_report_shell_only
    )) {
        is($contract->{$field} ? 1 : 0, $expected->{$field} ? 1 : 0, "decoded manifest result contract keeps $field");
    }
    for my $field (qw(
        fsm_module_raw_value_class_when_defined
        raw_ast_value_shape
        resolved_package_imports_raw_value_class
        composition_spec_raw_value_class
        composition_plan_raw_value_class
        composition_report_json_fragment_path
    )) {
        is($contract->{$field}, $expected->{$field}, "decoded manifest result contract keeps $field");
    }

};

done_testing();
