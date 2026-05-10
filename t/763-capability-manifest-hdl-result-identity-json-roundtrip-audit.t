#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorResultContract qw(
    hdl_generator_result_contract_source
);

subtest 'manifest-embedded HDLGenerator result identity survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};

    is($contract->{schema_version}, 1, 'decoded manifest result contract keeps schema version');
    is($contract->{status}, 'bounded_top_level_presence', 'decoded manifest result contract keeps bounded status');
    is($contract->{contract_source}, hdl_generator_result_contract_source(), 'decoded manifest result contract keeps source owner');
    like($contract->{entrypoint}, qr/FSM::Pipeline::HDLGenerator/, 'decoded manifest result contract keeps HDLGenerator entrypoint');
    ok(ref($contract->{tested_by}) eq 'ARRAY', 'decoded manifest result contract keeps tested_by list');
};

done_testing();
