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

subtest 'manifest-embedded HDLGenerator facade identity metadata rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_facade};

    $mutated->{'status'} = $sentinel;
    $mutated->{'contract_source'} = $sentinel;
    mutate_structure($mutated->{'implementation_owners'});
    mutate_structure($mutated->{'entrypoints'});


    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is($contract->{'status'}, $expected->{'status'}, 'fresh manifest facade rebuilds clean status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'fresh manifest facade rebuilds clean contract_source');
    is_deeply($contract->{'implementation_owners'}, $expected->{'implementation_owners'}, 'fresh manifest facade rebuilds clean implementation_owners');
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'fresh manifest facade rebuilds clean entrypoints');
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
