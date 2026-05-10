#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
);

subtest 'manifest-embedded HDLGenerator facade identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest facade keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest facade keeps contract_source');
    is_deeply($contract->{'implementation_owners'}, $expected->{'implementation_owners'}, 'decoded manifest facade keeps implementation_owners');
    is_deeply($contract->{'entrypoints'}, $expected->{'entrypoints'}, 'decoded manifest facade keeps entrypoints');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest facade keeps schema version');
};

done_testing();
