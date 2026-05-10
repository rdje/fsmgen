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

subtest 'manifest-embedded HDLGenerator facade generation boundary metadata rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{hdl_generator_facade};
    $mutated->{'constructor_receiver_shape'} = $sentinel;
    $mutated->{'generation_receiver_shape'} = $sentinel;
    $mutated->{'generation_receiver_instance_shape'} = $sentinel;
    $mutated->{'generation_argument_list_shape'} = $sentinel;
    $mutated->{'generation_argument_shape'} = $sentinel;

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();
    is($contract->{'constructor_receiver_shape'}, $expected->{'constructor_receiver_shape'}, 'fresh manifest facade rebuilds clean constructor_receiver_shape');
    is($contract->{'generation_receiver_shape'}, $expected->{'generation_receiver_shape'}, 'fresh manifest facade rebuilds clean generation_receiver_shape');
    is($contract->{'generation_receiver_instance_shape'}, $expected->{'generation_receiver_instance_shape'}, 'fresh manifest facade rebuilds clean generation_receiver_instance_shape');
    is($contract->{'generation_argument_list_shape'}, $expected->{'generation_argument_list_shape'}, 'fresh manifest facade rebuilds clean generation_argument_list_shape');
    is($contract->{'generation_argument_shape'}, $expected->{'generation_argument_shape'}, 'fresh manifest facade rebuilds clean generation_argument_shape');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
