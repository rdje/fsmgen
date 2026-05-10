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

subtest 'manifest-embedded debug runtime helper and state key lists rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{debug_runtime};
    mutate_structure($mutated->{'snapshot_helper_names'});
    mutate_structure($mutated->{'state_control_names'});
    mutate_structure($mutated->{'trace_output_control_names'});
    mutate_structure($mutated->{'emoji_control_names'});
    mutate_structure($mutated->{'snapshot_state_keys'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{debug_runtime};
    my $expected = build_debug_runtime_contract();
    is_deeply($contract->{'snapshot_helper_names'}, $expected->{'snapshot_helper_names'}, 'fresh manifest debug runtime rebuilds clean snapshot_helper_names');
    is_deeply($contract->{'state_control_names'}, $expected->{'state_control_names'}, 'fresh manifest debug runtime rebuilds clean state_control_names');
    is_deeply($contract->{'trace_output_control_names'}, $expected->{'trace_output_control_names'}, 'fresh manifest debug runtime rebuilds clean trace_output_control_names');
    is_deeply($contract->{'emoji_control_names'}, $expected->{'emoji_control_names'}, 'fresh manifest debug runtime rebuilds clean emoji_control_names');
    is_deeply($contract->{'snapshot_state_keys'}, $expected->{'snapshot_state_keys'}, 'fresh manifest debug runtime rebuilds clean snapshot_state_keys');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
