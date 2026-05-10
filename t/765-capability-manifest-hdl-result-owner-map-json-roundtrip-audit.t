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

subtest 'manifest-embedded HDLGenerator nested owner map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply(
        $contract->{nested_contract_source_map},
        $expected->{nested_contract_source_map},
        'decoded manifest result contract keeps nested contract owner map',
    );
    is($contract->{nested_contract_source_map}{source_info}, $expected->{nested_contract_source_map}{source_info}, 'decoded owner map keeps source_info owner');
    is($contract->{nested_contract_source_map}{structural_rtl_ir}, $expected->{nested_contract_source_map}{structural_rtl_ir}, 'decoded owner map keeps structural_rtl_ir owner');

};

done_testing();
