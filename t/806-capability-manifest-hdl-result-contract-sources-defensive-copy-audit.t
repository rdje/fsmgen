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

subtest 'manifest-embedded HDLGenerator scalar nested contract-source fields rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    $mutated->{'source_info_contract_source'} = $sentinel;
    $mutated->{'module_info_contract_source'} = $sentinel;
    $mutated->{'statistics_contract_source'} = $sentinel;
    $mutated->{'fsm_module_contract_source'} = $sentinel;
    $mutated->{'raw_ast_contract_source'} = $sentinel;
    $mutated->{'resolved_package_imports_contract_source'} = $sentinel;
    $mutated->{'composition_spec_contract_source'} = $sentinel;
    $mutated->{'composition_plan_contract_source'} = $sentinel;
    $mutated->{'composition_report_contract_source'} = $sentinel;
    $mutated->{'intent_hir_contract_source'} = $sentinel;
    $mutated->{'lowered_rtl_ir_contract_source'} = $sentinel;
    $mutated->{'structural_rtl_ir_contract_source'} = $sentinel;


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{'source_info_contract_source'}, $expected->{'source_info_contract_source'}, 'fresh manifest result contract rebuilds clean source_info_contract_source');
    is($contract->{'module_info_contract_source'}, $expected->{'module_info_contract_source'}, 'fresh manifest result contract rebuilds clean module_info_contract_source');
    is($contract->{'statistics_contract_source'}, $expected->{'statistics_contract_source'}, 'fresh manifest result contract rebuilds clean statistics_contract_source');
    is($contract->{'fsm_module_contract_source'}, $expected->{'fsm_module_contract_source'}, 'fresh manifest result contract rebuilds clean fsm_module_contract_source');
    is($contract->{'raw_ast_contract_source'}, $expected->{'raw_ast_contract_source'}, 'fresh manifest result contract rebuilds clean raw_ast_contract_source');
    is($contract->{'resolved_package_imports_contract_source'}, $expected->{'resolved_package_imports_contract_source'}, 'fresh manifest result contract rebuilds clean resolved_package_imports_contract_source');
    is($contract->{'composition_spec_contract_source'}, $expected->{'composition_spec_contract_source'}, 'fresh manifest result contract rebuilds clean composition_spec_contract_source');
    is($contract->{'composition_plan_contract_source'}, $expected->{'composition_plan_contract_source'}, 'fresh manifest result contract rebuilds clean composition_plan_contract_source');
    is($contract->{'composition_report_contract_source'}, $expected->{'composition_report_contract_source'}, 'fresh manifest result contract rebuilds clean composition_report_contract_source');
    is($contract->{'intent_hir_contract_source'}, $expected->{'intent_hir_contract_source'}, 'fresh manifest result contract rebuilds clean intent_hir_contract_source');
    is($contract->{'lowered_rtl_ir_contract_source'}, $expected->{'lowered_rtl_ir_contract_source'}, 'fresh manifest result contract rebuilds clean lowered_rtl_ir_contract_source');
    is($contract->{'structural_rtl_ir_contract_source'}, $expected->{'structural_rtl_ir_contract_source'}, 'fresh manifest result contract rebuilds clean structural_rtl_ir_contract_source');

};

done_testing();


sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);

    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_) for @{$value};
        return;
    }

    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_) for values %{$value};
        return;
    }
}
