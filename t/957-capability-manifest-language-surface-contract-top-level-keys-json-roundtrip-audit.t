#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::LanguageSurfaceContract qw(build_language_surface_contract);

subtest 'manifest language-surface contract top-level and mode key lists survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'language_surface'}{'surface_contract'};
    my $expected = build_language_surface_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'decoded manifest language-surface contract keeps public_top_level_presence_keys');
    is_deeply($contract->{'strict_mode_presence_keys'}, $expected->{'strict_mode_presence_keys'}, 'decoded manifest language-surface contract keeps strict_mode_presence_keys');
    is_deeply($contract->{'default_mode_compatibility_presence_keys'}, $expected->{'default_mode_compatibility_presence_keys'}, 'decoded manifest language-surface contract keeps default_mode_compatibility_presence_keys');
};
done_testing();
