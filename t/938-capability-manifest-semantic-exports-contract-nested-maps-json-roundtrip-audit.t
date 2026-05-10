#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SemanticExportsContract qw(build_semantic_exports_contract);

subtest 'manifest semantic-exports contract nested source and presence maps survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'semantic_exports'}{'section_contract'};
    my $expected = build_semantic_exports_contract();
    is_deeply($contract->{'nested_contract_source_map'}, $expected->{'nested_contract_source_map'}, 'decoded manifest semantic-exports contract keeps nested_contract_source_map');
    is_deeply($contract->{'nested_presence_key_map'}, $expected->{'nested_presence_key_map'}, 'decoded manifest semantic-exports contract keeps nested_presence_key_map');
};
done_testing();
