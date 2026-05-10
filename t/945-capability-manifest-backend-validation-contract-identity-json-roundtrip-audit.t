#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::BackendValidationContract qw(build_backend_validation_contract);

subtest 'manifest backend-validation contract identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'backend_validation'}{'section_contract'};
    my $expected = build_backend_validation_contract();
    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest backend-validation contract keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest backend-validation contract keeps contract_source');
    is($contract->{'report_source'}, $expected->{'report_source'}, 'decoded manifest backend-validation contract keeps report_source');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest backend validation contract keeps schema_version');
};
done_testing();
