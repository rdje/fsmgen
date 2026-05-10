#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

subtest 'manifest-embedded HDLGenerator facade linked contract and guidance metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_facade};
    my $expected = build_hdl_generator_facade_contract();

    is($contract->{'result_contract_source'}, $expected->{'result_contract_source'}, 'decoded manifest facade keeps result_contract_source');
    is($contract->{'direct_extension_contract_source'}, $expected->{'direct_extension_contract_source'}, 'decoded manifest facade keeps direct_extension_contract_source');
    is($contract->{'debug_runtime_contract_source'}, $expected->{'debug_runtime_contract_source'}, 'decoded manifest facade keeps debug_runtime_contract_source');
    is($contract->{'object_injection_arg_policy'}, $expected->{'object_injection_arg_policy'}, 'decoded manifest facade keeps object_injection_arg_policy');
    is($contract->{'stateful_reuse_supported'} ? 1 : 0, $expected->{'stateful_reuse_supported'} ? 1 : 0, 'decoded manifest facade keeps stateful_reuse_supported');
    is($contract->{'result_surface_json_safe_as_a_whole'} ? 1 : 0, $expected->{'result_surface_json_safe_as_a_whole'} ? 1 : 0, 'decoded manifest facade keeps result_surface_json_safe_as_a_whole');
    is($contract->{'object_injection_args_public'} ? 1 : 0, $expected->{'object_injection_args_public'} ? 1 : 0, 'decoded manifest facade keeps object_injection_args_public');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest facade keeps guidance');
};

done_testing();
