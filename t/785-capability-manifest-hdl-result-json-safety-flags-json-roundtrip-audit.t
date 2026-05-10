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

subtest 'manifest-embedded HDLGenerator JSON-safety flags survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    for my $field (qw(
        stable_nested_content
        full_result_json_safe
        composition_report_raw_hash_json_safe
        source_info_full_hash_stable
        module_info_full_hash_stable
        statistics_full_hash_stable
        intent_hir_full_hash_stable
        lowered_rtl_ir_full_hash_stable
        structural_rtl_ir_full_hash_stable
    )) {
        is($contract->{$field} ? 1 : 0, $expected->{$field} ? 1 : 0, "decoded manifest result contract keeps $field");
    }

};

done_testing();
