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

subtest 'manifest-embedded HDLGenerator shell-only branch metadata rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    $mutated->{'fsm_module_raw_value_class_when_defined'} = $sentinel;
    $mutated->{'raw_ast_value_shape'} = $sentinel;
    $mutated->{'resolved_package_imports_raw_value_class'} = $sentinel;
    $mutated->{'composition_spec_raw_value_class'} = $sentinel;
    $mutated->{'composition_plan_raw_value_class'} = $sentinel;
    $mutated->{'composition_report_json_fragment_path'} = $sentinel;
    $mutated->{'fsm_module_shell_only'} = $mutated->{'fsm_module_shell_only'} ? 0 : 1;
    $mutated->{'raw_ast_shell_only'} = $mutated->{'raw_ast_shell_only'} ? 0 : 1;
    $mutated->{'resolved_package_imports_shell_only'} = $mutated->{'resolved_package_imports_shell_only'} ? 0 : 1;
    $mutated->{'composition_spec_shell_only'} = $mutated->{'composition_spec_shell_only'} ? 0 : 1;
    $mutated->{'composition_plan_shell_only'} = $mutated->{'composition_plan_shell_only'} ? 0 : 1;
    $mutated->{'composition_report_shell_only'} = $mutated->{'composition_report_shell_only'} ? 0 : 1;


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{'fsm_module_raw_value_class_when_defined'}, $expected->{'fsm_module_raw_value_class_when_defined'}, 'fresh manifest result contract rebuilds clean fsm_module_raw_value_class_when_defined');
    is($contract->{'raw_ast_value_shape'}, $expected->{'raw_ast_value_shape'}, 'fresh manifest result contract rebuilds clean raw_ast_value_shape');
    is($contract->{'resolved_package_imports_raw_value_class'}, $expected->{'resolved_package_imports_raw_value_class'}, 'fresh manifest result contract rebuilds clean resolved_package_imports_raw_value_class');
    is($contract->{'composition_spec_raw_value_class'}, $expected->{'composition_spec_raw_value_class'}, 'fresh manifest result contract rebuilds clean composition_spec_raw_value_class');
    is($contract->{'composition_plan_raw_value_class'}, $expected->{'composition_plan_raw_value_class'}, 'fresh manifest result contract rebuilds clean composition_plan_raw_value_class');
    is($contract->{'composition_report_json_fragment_path'}, $expected->{'composition_report_json_fragment_path'}, 'fresh manifest result contract rebuilds clean composition_report_json_fragment_path');
    is($contract->{'fsm_module_shell_only'} ? 1 : 0, $expected->{'fsm_module_shell_only'} ? 1 : 0, 'fresh manifest result contract rebuilds clean fsm_module_shell_only');
    is($contract->{'raw_ast_shell_only'} ? 1 : 0, $expected->{'raw_ast_shell_only'} ? 1 : 0, 'fresh manifest result contract rebuilds clean raw_ast_shell_only');
    is($contract->{'resolved_package_imports_shell_only'} ? 1 : 0, $expected->{'resolved_package_imports_shell_only'} ? 1 : 0, 'fresh manifest result contract rebuilds clean resolved_package_imports_shell_only');
    is($contract->{'composition_spec_shell_only'} ? 1 : 0, $expected->{'composition_spec_shell_only'} ? 1 : 0, 'fresh manifest result contract rebuilds clean composition_spec_shell_only');
    is($contract->{'composition_plan_shell_only'} ? 1 : 0, $expected->{'composition_plan_shell_only'} ? 1 : 0, 'fresh manifest result contract rebuilds clean composition_plan_shell_only');
    is($contract->{'composition_report_shell_only'} ? 1 : 0, $expected->{'composition_report_shell_only'} ? 1 : 0, 'fresh manifest result contract rebuilds clean composition_report_shell_only');

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
