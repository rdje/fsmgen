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

subtest 'manifest-embedded HDLGenerator `composition_spec` shell surfaces survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{composition_spec_contract_source}, $expected->{composition_spec_contract_source}, 'decoded manifest result contract keeps composition_spec contract owner');
    is($contract->{composition_spec_shell_only} ? 1 : 0, $expected->{composition_spec_shell_only} ? 1 : 0, 'decoded manifest result contract keeps composition_spec shell-only flag');
    is($contract->{composition_spec_raw_value_class}, $expected->{composition_spec_raw_value_class}, 'decoded manifest result contract keeps composition_spec raw value class');
    is_deeply($contract->{composition_spec_summary_surfaces}, $expected->{composition_spec_summary_surfaces}, 'decoded manifest result contract keeps composition_spec summary surfaces');
    is_deeply($contract->{composition_spec_fallback_surface_map}, $expected->{composition_spec_fallback_surface_map}, 'decoded manifest result contract keeps composition_spec fallback surface map');

};

done_testing();
