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

subtest 'manifest-embedded debug runtime flags, ranges, and guidance rebuild cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{debug_runtime};
    $mutated->{'process_global_singleton'} = $mutated->{'process_global_singleton'} ? 0 : 1;
    $mutated->{'thread_safe'} = $mutated->{'thread_safe'} ? 0 : 1;
    $mutated->{'snapshot_json_safe'} = $mutated->{'snapshot_json_safe'} ? 0 : 1;
    $mutated->{'snapshot_contains_live_filehandle_when_bound'} = $mutated->{'snapshot_contains_live_filehandle_when_bound'} ? 0 : 1;
    $mutated->{'pipeline_scopes_debug_state'} = $mutated->{'pipeline_scopes_debug_state'} ? 0 : 1;
    $mutated->{'general_debug_calls_auto_scoped'} = $mutated->{'general_debug_calls_auto_scoped'} ? 0 : 1;
    mutate_structure($mutated->{'named_trace_verbosity_values'});
    mutate_structure($mutated->{'numeric_trace_level_range'});
    mutate_structure($mutated->{'guidance'});

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{debug_runtime};
    my $expected = build_debug_runtime_contract();
    is($contract->{'process_global_singleton'} ? 1 : 0, $expected->{'process_global_singleton'} ? 1 : 0, 'fresh manifest debug runtime rebuilds clean process_global_singleton');
    is($contract->{'thread_safe'} ? 1 : 0, $expected->{'thread_safe'} ? 1 : 0, 'fresh manifest debug runtime rebuilds clean thread_safe');
    is($contract->{'snapshot_json_safe'} ? 1 : 0, $expected->{'snapshot_json_safe'} ? 1 : 0, 'fresh manifest debug runtime rebuilds clean snapshot_json_safe');
    is($contract->{'snapshot_contains_live_filehandle_when_bound'} ? 1 : 0, $expected->{'snapshot_contains_live_filehandle_when_bound'} ? 1 : 0, 'fresh manifest debug runtime rebuilds clean snapshot_contains_live_filehandle_when_bound');
    is($contract->{'pipeline_scopes_debug_state'} ? 1 : 0, $expected->{'pipeline_scopes_debug_state'} ? 1 : 0, 'fresh manifest debug runtime rebuilds clean pipeline_scopes_debug_state');
    is($contract->{'general_debug_calls_auto_scoped'} ? 1 : 0, $expected->{'general_debug_calls_auto_scoped'} ? 1 : 0, 'fresh manifest debug runtime rebuilds clean general_debug_calls_auto_scoped');
    is_deeply($contract->{'named_trace_verbosity_values'}, $expected->{'named_trace_verbosity_values'}, 'fresh manifest debug runtime rebuilds clean named_trace_verbosity_values');
    is_deeply($contract->{'numeric_trace_level_range'}, $expected->{'numeric_trace_level_range'}, 'fresh manifest debug runtime rebuilds clean numeric_trace_level_range');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'fresh manifest debug runtime rebuilds clean guidance');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
