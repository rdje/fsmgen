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

subtest 'manifest-embedded HDLGenerator facade constructor option families rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_facade};

    mutate_structure($mutated->{'public_constructor_option_names'});
    mutate_structure($mutated->{'core_constructor_option_names'});
    mutate_structure($mutated->{'compatibility_constructor_option_names'});
    mutate_structure($mutated->{'direct_extension_option_names'});
    mutate_structure($mutated->{'constructor_option_family_map'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is_deeply($contract->{'public_constructor_option_names'}, $expected->{'public_constructor_option_names'}, 'fresh manifest facade rebuilds clean public_constructor_option_names');
    is_deeply($contract->{'core_constructor_option_names'}, $expected->{'core_constructor_option_names'}, 'fresh manifest facade rebuilds clean core_constructor_option_names');
    is_deeply($contract->{'compatibility_constructor_option_names'}, $expected->{'compatibility_constructor_option_names'}, 'fresh manifest facade rebuilds clean compatibility_constructor_option_names');
    is_deeply($contract->{'direct_extension_option_names'}, $expected->{'direct_extension_option_names'}, 'fresh manifest facade rebuilds clean direct_extension_option_names');
    is_deeply($contract->{'constructor_option_family_map'}, $expected->{'constructor_option_family_map'}, 'fresh manifest facade rebuilds clean constructor_option_family_map');
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
