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

subtest 'manifest semantic-exports contract advertisement flags and guidance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'semantic_exports'}{'section_contract'};
    my $expected = build_semantic_exports_contract();
    is($contract->{'normalized_semantic_json_contract_advertised'} ? 1 : 0, $expected->{'normalized_semantic_json_contract_advertised'} ? 1 : 0, 'decoded manifest semantic-exports contract keeps normalized_semantic_json_contract_advertised');
    is($contract->{'full_semantic_exports_section_stable'} ? 1 : 0, $expected->{'full_semantic_exports_section_stable'} ? 1 : 0, 'decoded manifest semantic-exports contract keeps full_semantic_exports_section_stable');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest semantic-exports contract keeps guidance');
};
done_testing();
