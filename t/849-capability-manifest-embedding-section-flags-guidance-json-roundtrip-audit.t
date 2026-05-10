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

subtest 'manifest-embedded embedding section contract flags and guidance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{section_contract};
    my $expected = build_embedding_contract();
    is($contract->{'nested_contracts_advertised'} ? 1 : 0, $expected->{'nested_contracts_advertised'} ? 1 : 0, 'decoded manifest embedding contract keeps nested_contracts_advertised');
    is($contract->{'full_embedding_section_stable'} ? 1 : 0, $expected->{'full_embedding_section_stable'} ? 1 : 0, 'decoded manifest embedding contract keeps full_embedding_section_stable');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest embedding contract keeps guidance');
};
done_testing();
