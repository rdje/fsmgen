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

subtest 'manifest-embedded HDLGenerator `fsm_module` shell surfaces rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    $mutated->{'fsm_module_contract_source'} = $sentinel;
    $mutated->{'fsm_module_raw_value_class_when_defined'} = $sentinel;
    $mutated->{'fsm_module_shell_only'} = $mutated->{'fsm_module_shell_only'} ? 0 : 1;
    mutate_structure($mutated->{'fsm_module_summary_surfaces'});
    mutate_structure($mutated->{'fsm_module_fallback_surface_map'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{'fsm_module_contract_source'}, $expected->{'fsm_module_contract_source'}, 'fresh manifest result contract rebuilds clean fsm_module_contract_source');
    is($contract->{'fsm_module_raw_value_class_when_defined'}, $expected->{'fsm_module_raw_value_class_when_defined'}, 'fresh manifest result contract rebuilds clean fsm_module_raw_value_class_when_defined');
    is($contract->{'fsm_module_shell_only'} ? 1 : 0, $expected->{'fsm_module_shell_only'} ? 1 : 0, 'fresh manifest result contract rebuilds clean fsm_module_shell_only');
    is_deeply($contract->{'fsm_module_summary_surfaces'}, $expected->{'fsm_module_summary_surfaces'}, 'fresh manifest result contract rebuilds clean fsm_module_summary_surfaces');
    is_deeply($contract->{'fsm_module_fallback_surface_map'}, $expected->{'fsm_module_fallback_surface_map'}, 'fresh manifest result contract rebuilds clean fsm_module_fallback_surface_map');

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
