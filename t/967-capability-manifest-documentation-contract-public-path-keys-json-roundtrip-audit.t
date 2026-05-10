#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DocumentationContract qw(build_documentation_contract);

subtest 'manifest documentation contract public and path-list keys survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'documentation'}{'section_contract'};
    my $expected = build_documentation_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'decoded manifest documentation contract keeps public_top_level_presence_keys');
    is_deeply($contract->{'path_list_keys'}, $expected->{'path_list_keys'}, 'decoded manifest documentation contract keeps path_list_keys');
};
done_testing();
