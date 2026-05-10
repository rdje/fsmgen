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
    build_hdl_generator_result_contract
);

subtest 'manifest-embedded HDLGenerator `tested_by` provenance list survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply(
        $contract->{tested_by},
        $expected->{tested_by},
        'decoded manifest result contract keeps tested_by provenance list',
    );
    ok(grep({ $_ eq 't/305-hdl-generator-result-contract.t' } @{$contract->{tested_by}}), 'decoded manifest result contract keeps parent result-contract test provenance');

};

done_testing();
