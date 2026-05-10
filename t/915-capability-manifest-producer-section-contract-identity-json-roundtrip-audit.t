#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ProducerContract qw(build_producer_contract);

subtest 'manifest producer section contract identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'producer'}{section_contract};
    my $expected = build_producer_contract();
    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest producer contract keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest producer contract keeps contract_source');
    is($contract->{'report_source'}, $expected->{'report_source'}, 'decoded manifest producer contract keeps report_source');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest producer contract keeps schema_version');
};
done_testing();
