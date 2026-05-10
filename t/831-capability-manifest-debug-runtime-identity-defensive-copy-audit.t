#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DebugRuntimeContract qw(build_debug_runtime_contract);
my $sentinel = '__manifest_debug_runtime_mutation__';

subtest 'manifest-embedded debug runtime identity metadata rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{debug_runtime};
    $mutated->{'status'} = $sentinel;
    $mutated->{'contract_source'} = $sentinel;
    $mutated->{'restore_snapshot_argument_shape'} = $sentinel;
    mutate_structure($mutated->{'implementation_owners'});
    mutate_structure($mutated->{'entrypoints'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{debug_runtime};
    my $expected = build_debug_runtime_contract();
    is($contract->{'status'}, $expected->{'status'}, 'fresh manifest debug runtime rebuilds clean status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'fresh manifest debug runtime rebuilds clean contract_source');
    is($contract->{'restore_snapshot_argument_shape'}, $expected->{'restore_snapshot_argument_shape'}, 'fresh manifest debug runtime rebuilds clean restore_snapshot_argument_shape');
    is_deeply($contract->{'implementation_owners'}, $expected->{'implementation_owners'}, 'fresh manifest debug runtime rebuilds clean implementation_owners');
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'fresh manifest debug runtime rebuilds clean entrypoints');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
