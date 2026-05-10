#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

my $sentinel = '__manifest_hdl_result_mutation__';

subtest 'manifest-embedded HDLGenerator JSON-safety flags rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    $mutated->{'stable_nested_content'} = $mutated->{'stable_nested_content'} ? 0 : 1;
    $mutated->{'full_result_json_safe'} = $mutated->{'full_result_json_safe'} ? 0 : 1;
    $mutated->{'composition_report_raw_hash_json_safe'} = $mutated->{'composition_report_raw_hash_json_safe'} ? 0 : 1;
    $mutated->{'source_info_full_hash_stable'} = $mutated->{'source_info_full_hash_stable'} ? 0 : 1;
    $mutated->{'module_info_full_hash_stable'} = $mutated->{'module_info_full_hash_stable'} ? 0 : 1;
    $mutated->{'statistics_full_hash_stable'} = $mutated->{'statistics_full_hash_stable'} ? 0 : 1;
    $mutated->{'intent_hir_full_hash_stable'} = $mutated->{'intent_hir_full_hash_stable'} ? 0 : 1;
    $mutated->{'lowered_rtl_ir_full_hash_stable'} = $mutated->{'lowered_rtl_ir_full_hash_stable'} ? 0 : 1;
    $mutated->{'structural_rtl_ir_full_hash_stable'} = $mutated->{'structural_rtl_ir_full_hash_stable'} ? 0 : 1;


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{'stable_nested_content'} ? 1 : 0, $expected->{'stable_nested_content'} ? 1 : 0, 'fresh manifest result contract rebuilds clean stable_nested_content');
    is($contract->{'full_result_json_safe'} ? 1 : 0, $expected->{'full_result_json_safe'} ? 1 : 0, 'fresh manifest result contract rebuilds clean full_result_json_safe');
    is($contract->{'composition_report_raw_hash_json_safe'} ? 1 : 0, $expected->{'composition_report_raw_hash_json_safe'} ? 1 : 0, 'fresh manifest result contract rebuilds clean composition_report_raw_hash_json_safe');
    is($contract->{'source_info_full_hash_stable'} ? 1 : 0, $expected->{'source_info_full_hash_stable'} ? 1 : 0, 'fresh manifest result contract rebuilds clean source_info_full_hash_stable');
    is($contract->{'module_info_full_hash_stable'} ? 1 : 0, $expected->{'module_info_full_hash_stable'} ? 1 : 0, 'fresh manifest result contract rebuilds clean module_info_full_hash_stable');
    is($contract->{'statistics_full_hash_stable'} ? 1 : 0, $expected->{'statistics_full_hash_stable'} ? 1 : 0, 'fresh manifest result contract rebuilds clean statistics_full_hash_stable');
    is($contract->{'intent_hir_full_hash_stable'} ? 1 : 0, $expected->{'intent_hir_full_hash_stable'} ? 1 : 0, 'fresh manifest result contract rebuilds clean intent_hir_full_hash_stable');
    is($contract->{'lowered_rtl_ir_full_hash_stable'} ? 1 : 0, $expected->{'lowered_rtl_ir_full_hash_stable'} ? 1 : 0, 'fresh manifest result contract rebuilds clean lowered_rtl_ir_full_hash_stable');
    is($contract->{'structural_rtl_ir_full_hash_stable'} ? 1 : 0, $expected->{'structural_rtl_ir_full_hash_stable'} ? 1 : 0, 'fresh manifest result contract rebuilds clean structural_rtl_ir_full_hash_stable');

};

done_testing();
