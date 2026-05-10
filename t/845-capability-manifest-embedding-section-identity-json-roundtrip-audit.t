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

subtest 'manifest-embedded embedding section contract identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{section_contract};
    my $expected = build_embedding_contract();
    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest embedding contract keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest embedding contract keeps contract_source');
    is($contract->{'report_source'}, $expected->{'report_source'}, 'decoded manifest embedding contract keeps report_source');
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'decoded manifest embedding contract keeps entrypoints');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest embedding contract keeps schema version');
};
done_testing();
