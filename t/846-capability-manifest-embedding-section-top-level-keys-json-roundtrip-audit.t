#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::EmbeddingContract qw(build_embedding_contract);

subtest 'manifest-embedded embedding section contract top-level and nested contract keys survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{section_contract};
    my $expected = build_embedding_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'decoded manifest embedding contract keeps public_top_level_presence_keys');
    is_deeply($contract->{'nested_contract_keys'}, $expected->{'nested_contract_keys'}, 'decoded manifest embedding contract keeps nested_contract_keys');
};
done_testing();
