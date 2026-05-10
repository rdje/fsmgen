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

subtest 'manifest documentation contract identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'documentation'}{'section_contract'};
    my $expected = build_documentation_contract();
    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest documentation contract keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest documentation contract keeps contract_source');
    is($contract->{'report_source'}, $expected->{'report_source'}, 'decoded manifest documentation contract keeps report_source');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest documentation contract keeps schema_version');
};
done_testing();
