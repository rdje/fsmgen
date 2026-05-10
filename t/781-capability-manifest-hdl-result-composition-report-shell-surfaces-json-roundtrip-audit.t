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

subtest 'manifest-embedded HDLGenerator `composition_report` shell surfaces survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{composition_report_contract_source}, $expected->{composition_report_contract_source}, 'decoded manifest result contract keeps composition_report contract owner');
    is($contract->{composition_report_shell_only} ? 1 : 0, $expected->{composition_report_shell_only} ? 1 : 0, 'decoded manifest result contract keeps composition_report shell-only flag');
    is($contract->{composition_report_json_fragment_path}, $expected->{composition_report_json_fragment_path}, 'decoded manifest result contract keeps composition_report JSON fragment path');
    is($contract->{composition_report_raw_hash_json_safe} ? 1 : 0, $expected->{composition_report_raw_hash_json_safe} ? 1 : 0, 'decoded manifest result contract keeps composition_report raw JSON safety flag');
    is_deeply($contract->{shell_only_fallback_surface_family_map}{composition_report}, $expected->{shell_only_fallback_surface_family_map}{composition_report}, 'decoded manifest result contract keeps composition_report fallback family');

};

done_testing();
