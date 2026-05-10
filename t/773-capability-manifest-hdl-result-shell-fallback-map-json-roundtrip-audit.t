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

subtest 'manifest-embedded HDLGenerator shell-only fallback surface map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply(
        $contract->{shell_only_fallback_surface_map},
        $expected->{shell_only_fallback_surface_map},
        'decoded manifest result contract keeps grouped shell fallback surface map',
    );
    is_deeply($contract->{shell_only_fallback_surface_map}{composition_report}, $expected->{shell_only_fallback_surface_map}{composition_report}, 'decoded manifest result contract keeps composition_report fallback surface');

};

done_testing();
