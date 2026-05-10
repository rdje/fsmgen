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

subtest 'manifest language-surface contract nested map flags and guidance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'language_surface'}{'surface_contract'};
    my $expected = build_language_surface_contract();
    is($contract->{'full_language_surface_stable'} ? 1 : 0, $expected->{'full_language_surface_stable'} ? 1 : 0, 'decoded manifest language-surface contract keeps full_language_surface_stable');
    is_deeply($contract->{'nested_presence_key_map'}, $expected->{'nested_presence_key_map'}, 'decoded manifest language-surface contract keeps nested_presence_key_map');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest language-surface contract keeps guidance');
};
done_testing();
