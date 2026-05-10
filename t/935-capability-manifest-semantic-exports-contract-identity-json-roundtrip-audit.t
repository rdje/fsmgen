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

subtest 'manifest semantic-exports contract identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'semantic_exports'}{'section_contract'};
    my $expected = build_semantic_exports_contract();
    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest semantic-exports contract keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest semantic-exports contract keeps contract_source');
    is($contract->{'report_source'}, $expected->{'report_source'}, 'decoded manifest semantic-exports contract keeps report_source');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest semantic exports contract keeps schema_version');
};
done_testing();
