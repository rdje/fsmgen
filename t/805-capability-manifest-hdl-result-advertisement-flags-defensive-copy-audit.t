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

subtest 'manifest-embedded HDLGenerator advertisement flags rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    $mutated->{'nested_identity_slices_advertised'} = $mutated->{'nested_identity_slices_advertised'} ? 0 : 1;
    $mutated->{'source_info_summary_slices_advertised'} = $mutated->{'source_info_summary_slices_advertised'} ? 0 : 1;
    $mutated->{'module_info_summary_slices_advertised'} = $mutated->{'module_info_summary_slices_advertised'} ? 0 : 1;
    $mutated->{'statistics_summary_slices_advertised'} = $mutated->{'statistics_summary_slices_advertised'} ? 0 : 1;
    $mutated->{'top_level_semantic_layer_contracts_advertised'} = $mutated->{'top_level_semantic_layer_contracts_advertised'} ? 0 : 1;


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{'nested_identity_slices_advertised'} ? 1 : 0, $expected->{'nested_identity_slices_advertised'} ? 1 : 0, 'fresh manifest result contract rebuilds clean nested_identity_slices_advertised');
    is($contract->{'source_info_summary_slices_advertised'} ? 1 : 0, $expected->{'source_info_summary_slices_advertised'} ? 1 : 0, 'fresh manifest result contract rebuilds clean source_info_summary_slices_advertised');
    is($contract->{'module_info_summary_slices_advertised'} ? 1 : 0, $expected->{'module_info_summary_slices_advertised'} ? 1 : 0, 'fresh manifest result contract rebuilds clean module_info_summary_slices_advertised');
    is($contract->{'statistics_summary_slices_advertised'} ? 1 : 0, $expected->{'statistics_summary_slices_advertised'} ? 1 : 0, 'fresh manifest result contract rebuilds clean statistics_summary_slices_advertised');
    is($contract->{'top_level_semantic_layer_contracts_advertised'} ? 1 : 0, $expected->{'top_level_semantic_layer_contracts_advertised'} ? 1 : 0, 'fresh manifest result contract rebuilds clean top_level_semantic_layer_contracts_advertised');

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
