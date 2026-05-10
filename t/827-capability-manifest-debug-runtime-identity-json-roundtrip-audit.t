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

subtest 'manifest-embedded debug runtime identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{debug_runtime};
    my $expected = build_debug_runtime_contract();
    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest debug runtime keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest debug runtime keeps contract_source');
    is($contract->{'restore_snapshot_argument_shape'}, $expected->{'restore_snapshot_argument_shape'}, 'decoded manifest debug runtime keeps restore_snapshot_argument_shape');
    is_deeply($contract->{'implementation_owners'}, $expected->{'implementation_owners'}, 'decoded manifest debug runtime keeps implementation_owners');
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'decoded manifest debug runtime keeps entrypoints');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest debug runtime keeps schema version');
};
done_testing();
