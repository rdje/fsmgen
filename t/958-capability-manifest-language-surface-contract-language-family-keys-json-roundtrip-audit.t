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

subtest 'manifest language-surface contract language family key lists survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'language_surface'}{'surface_contract'};
    my $expected = build_language_surface_contract();
    is_deeply($contract->{'assignments_presence_keys'}, $expected->{'assignments_presence_keys'}, 'decoded manifest language-surface contract keeps assignments_presence_keys');
    is_deeply($contract->{'system_contracts_presence_keys'}, $expected->{'system_contracts_presence_keys'}, 'decoded manifest language-surface contract keeps system_contracts_presence_keys');
    is_deeply($contract->{'expressions_presence_keys'}, $expected->{'expressions_presence_keys'}, 'decoded manifest language-surface contract keeps expressions_presence_keys');
    is_deeply($contract->{'declarations_presence_keys'}, $expected->{'declarations_presence_keys'}, 'decoded manifest language-surface contract keeps declarations_presence_keys');
    is_deeply($contract->{'composition_presence_keys'}, $expected->{'composition_presence_keys'}, 'decoded manifest language-surface contract keeps composition_presence_keys');
};
done_testing();
