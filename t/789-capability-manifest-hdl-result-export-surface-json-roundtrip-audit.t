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

subtest 'manifest-embedded HDLGenerator JSON-safe export surface pointer survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is(
        $contract->{json_safe_export_surface},
        $expected->{json_safe_export_surface},
        'decoded manifest result contract keeps JSON-safe export surface pointer',
    );
    like($contract->{json_safe_export_surface}, qr/semantic_exports/, 'decoded manifest result contract still points to semantic exports');

};

done_testing();
