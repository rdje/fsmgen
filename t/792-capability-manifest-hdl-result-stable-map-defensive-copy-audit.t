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

subtest 'manifest-embedded HDLGenerator stable nested subsurface map rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    mutate_structure($mutated->{'stable_subsurface_map'});
    mutate_structure($mutated->{'source_info_stable_subsurfaces'});
    mutate_structure($mutated->{'module_info_stable_subsurfaces'});
    mutate_structure($mutated->{'statistics_stable_subsurfaces'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply($contract->{'stable_subsurface_map'}, $expected->{'stable_subsurface_map'}, 'fresh manifest result contract rebuilds clean stable_subsurface_map');
    is_deeply($contract->{'source_info_stable_subsurfaces'}, $expected->{'source_info_stable_subsurfaces'}, 'fresh manifest result contract rebuilds clean source_info_stable_subsurfaces');
    is_deeply($contract->{'module_info_stable_subsurfaces'}, $expected->{'module_info_stable_subsurfaces'}, 'fresh manifest result contract rebuilds clean module_info_stable_subsurfaces');
    is_deeply($contract->{'statistics_stable_subsurfaces'}, $expected->{'statistics_stable_subsurfaces'}, 'fresh manifest result contract rebuilds clean statistics_stable_subsurfaces');

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
