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

subtest 'manifest-embedded debug runtime helper and state key lists survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{debug_runtime};
    my $expected = build_debug_runtime_contract();
    is_deeply($contract->{'snapshot_helper_names'}, $expected->{'snapshot_helper_names'}, 'decoded manifest debug runtime keeps snapshot_helper_names');
    is_deeply($contract->{'state_control_names'}, $expected->{'state_control_names'}, 'decoded manifest debug runtime keeps state_control_names');
    is_deeply($contract->{'trace_output_control_names'}, $expected->{'trace_output_control_names'}, 'decoded manifest debug runtime keeps trace_output_control_names');
    is_deeply($contract->{'emoji_control_names'}, $expected->{'emoji_control_names'}, 'decoded manifest debug runtime keeps emoji_control_names');
    is_deeply($contract->{'snapshot_state_keys'}, $expected->{'snapshot_state_keys'}, 'decoded manifest debug runtime keeps snapshot_state_keys');
};
done_testing();
