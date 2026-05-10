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

subtest 'manifest-embedded HDLGenerator `raw_ast` shell surfaces survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is($contract->{raw_ast_contract_source}, $expected->{raw_ast_contract_source}, 'decoded manifest result contract keeps raw_ast contract owner');
    is($contract->{raw_ast_shell_only} ? 1 : 0, $expected->{raw_ast_shell_only} ? 1 : 0, 'decoded manifest result contract keeps raw_ast shell-only flag');
    is($contract->{raw_ast_value_shape}, $expected->{raw_ast_value_shape}, 'decoded manifest result contract keeps raw_ast value shape');
    is_deeply($contract->{raw_ast_summary_surfaces}, $expected->{raw_ast_summary_surfaces}, 'decoded manifest result contract keeps raw_ast summary surfaces');
    is_deeply($contract->{raw_ast_fallback_surface_map}, $expected->{raw_ast_fallback_surface_map}, 'decoded manifest result contract keeps raw_ast fallback surface map');

};

done_testing();
