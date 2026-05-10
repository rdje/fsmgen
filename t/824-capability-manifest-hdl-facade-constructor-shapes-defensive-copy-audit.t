#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

my $sentinel = '__manifest_hdl_facade_mutation__';

subtest 'manifest-embedded HDLGenerator facade constructor shape metadata rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_facade};

    $mutated->{'constructor_argument_list_shape'} = $sentinel;
    $mutated->{'constructor_duplicate_option_policy'} = $sentinel;
    $mutated->{'constructor_unknown_option_policy'} = $sentinel;
    $mutated->{'default_target_language'} = $sentinel;
    mutate_structure($mutated->{'constructor_option_shape_map'});
    mutate_structure($mutated->{'debug_level_numeric_range'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is($contract->{'constructor_argument_list_shape'}, $expected->{'constructor_argument_list_shape'}, 'fresh manifest facade rebuilds clean constructor_argument_list_shape');
    is($contract->{'constructor_duplicate_option_policy'}, $expected->{'constructor_duplicate_option_policy'}, 'fresh manifest facade rebuilds clean constructor_duplicate_option_policy');
    is($contract->{'constructor_unknown_option_policy'}, $expected->{'constructor_unknown_option_policy'}, 'fresh manifest facade rebuilds clean constructor_unknown_option_policy');
    is($contract->{'default_target_language'}, $expected->{'default_target_language'}, 'fresh manifest facade rebuilds clean default_target_language');
    is_deeply($contract->{'constructor_option_shape_map'}, $expected->{'constructor_option_shape_map'}, 'fresh manifest facade rebuilds clean constructor_option_shape_map');
    is_deeply($contract->{'debug_level_numeric_range'}, $expected->{'debug_level_numeric_range'}, 'fresh manifest facade rebuilds clean debug_level_numeric_range');
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
