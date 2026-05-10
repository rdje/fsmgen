#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DebugRuntimeContract qw(build_debug_runtime_contract);

subtest 'manifest-embedded debug runtime flags, ranges, and guidance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{debug_runtime};
    my $expected = build_debug_runtime_contract();
    is($contract->{'process_global_singleton'} ? 1 : 0, $expected->{'process_global_singleton'} ? 1 : 0, 'decoded manifest debug runtime keeps process_global_singleton');
    is($contract->{'thread_safe'} ? 1 : 0, $expected->{'thread_safe'} ? 1 : 0, 'decoded manifest debug runtime keeps thread_safe');
    is($contract->{'snapshot_json_safe'} ? 1 : 0, $expected->{'snapshot_json_safe'} ? 1 : 0, 'decoded manifest debug runtime keeps snapshot_json_safe');
    is($contract->{'snapshot_contains_live_filehandle_when_bound'} ? 1 : 0, $expected->{'snapshot_contains_live_filehandle_when_bound'} ? 1 : 0, 'decoded manifest debug runtime keeps snapshot_contains_live_filehandle_when_bound');
    is($contract->{'pipeline_scopes_debug_state'} ? 1 : 0, $expected->{'pipeline_scopes_debug_state'} ? 1 : 0, 'decoded manifest debug runtime keeps pipeline_scopes_debug_state');
    is($contract->{'general_debug_calls_auto_scoped'} ? 1 : 0, $expected->{'general_debug_calls_auto_scoped'} ? 1 : 0, 'decoded manifest debug runtime keeps general_debug_calls_auto_scoped');
    is_deeply($contract->{'named_trace_verbosity_values'}, $expected->{'named_trace_verbosity_values'}, 'decoded manifest debug runtime keeps named_trace_verbosity_values');
    is_deeply($contract->{'numeric_trace_level_range'}, $expected->{'numeric_trace_level_range'}, 'decoded manifest debug runtime keeps numeric_trace_level_range');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest debug runtime keeps guidance');
};
done_testing();
