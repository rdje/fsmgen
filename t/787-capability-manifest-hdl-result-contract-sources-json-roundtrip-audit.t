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

subtest 'manifest-embedded HDLGenerator scalar nested contract-source fields survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    for my $field (qw(
        source_info_contract_source
        module_info_contract_source
        statistics_contract_source
        fsm_module_contract_source
        raw_ast_contract_source
        resolved_package_imports_contract_source
        composition_spec_contract_source
        composition_plan_contract_source
        composition_report_contract_source
        intent_hir_contract_source
        lowered_rtl_ir_contract_source
        structural_rtl_ir_contract_source
    )) {
        is($contract->{$field}, $expected->{$field}, "decoded manifest result contract keeps $field");
    }

};

done_testing();
