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

subtest 'manifest-embedded HDLGenerator facade public key and method lists rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_facade};

    mutate_structure($mutated->{'public_top_level_presence_keys'});
    mutate_structure($mutated->{'method_names'});
    mutate_structure($mutated->{'target_language_names'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'fresh manifest facade rebuilds clean public_top_level_presence_keys');
    is_deeply($contract->{'method_names'}, $expected->{'method_names'}, 'fresh manifest facade rebuilds clean method_names');
    is_deeply($contract->{'target_language_names'}, $expected->{'target_language_names'}, 'fresh manifest facade rebuilds clean target_language_names');
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
