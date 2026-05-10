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

subtest 'manifest-embedded debug runtime public key and family metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{debug_runtime};
    my $expected = build_debug_runtime_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'decoded manifest debug runtime keeps public_top_level_presence_keys');
    is_deeply($contract->{'family_map'}, $expected->{'family_map'}, 'decoded manifest debug runtime keeps family_map');
};
done_testing();
