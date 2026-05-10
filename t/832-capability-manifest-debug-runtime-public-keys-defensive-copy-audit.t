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

subtest 'manifest-embedded debug runtime public key and family metadata rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{debug_runtime};
    mutate_structure($mutated->{'public_top_level_presence_keys'});
    mutate_structure($mutated->{'family_map'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{debug_runtime};
    my $expected = build_debug_runtime_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'fresh manifest debug runtime rebuilds clean public_top_level_presence_keys');
    is_deeply($contract->{'family_map'}, $expected->{'family_map'}, 'fresh manifest debug runtime rebuilds clean family_map');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
