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

subtest 'manifest-embedded HDLGenerator `composition_spec` shell surfaces rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    $mutated->{'composition_spec_contract_source'} = $sentinel;
    $mutated->{'composition_spec_raw_value_class'} = $sentinel;
    $mutated->{'composition_spec_shell_only'} = $mutated->{'composition_spec_shell_only'} ? 0 : 1;
    mutate_structure($mutated->{'composition_spec_summary_surfaces'});
    mutate_structure($mutated->{'composition_spec_fallback_surface_map'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{'composition_spec_contract_source'}, $expected->{'composition_spec_contract_source'}, 'fresh manifest result contract rebuilds clean composition_spec_contract_source');
    is($contract->{'composition_spec_raw_value_class'}, $expected->{'composition_spec_raw_value_class'}, 'fresh manifest result contract rebuilds clean composition_spec_raw_value_class');
    is($contract->{'composition_spec_shell_only'} ? 1 : 0, $expected->{'composition_spec_shell_only'} ? 1 : 0, 'fresh manifest result contract rebuilds clean composition_spec_shell_only');
    is_deeply($contract->{'composition_spec_summary_surfaces'}, $expected->{'composition_spec_summary_surfaces'}, 'fresh manifest result contract rebuilds clean composition_spec_summary_surfaces');
    is_deeply($contract->{'composition_spec_fallback_surface_map'}, $expected->{'composition_spec_fallback_surface_map'}, 'fresh manifest result contract rebuilds clean composition_spec_fallback_surface_map');

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
