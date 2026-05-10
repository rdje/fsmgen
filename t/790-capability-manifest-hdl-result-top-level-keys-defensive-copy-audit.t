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

subtest 'manifest-embedded HDLGenerator top-level key families rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_result};

    mutate_structure($mutated->{'public_top_level_presence_keys'});
    mutate_structure($mutated->{'direct_root_top_level_keys'});
    mutate_structure($mutated->{'composition_root_top_level_keys'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'fresh manifest result contract rebuilds clean public_top_level_presence_keys');
    is_deeply($contract->{'direct_root_top_level_keys'}, $expected->{'direct_root_top_level_keys'}, 'fresh manifest result contract rebuilds clean direct_root_top_level_keys');
    is_deeply($contract->{'composition_root_top_level_keys'}, $expected->{'composition_root_top_level_keys'}, 'fresh manifest result contract rebuilds clean composition_root_top_level_keys');

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
