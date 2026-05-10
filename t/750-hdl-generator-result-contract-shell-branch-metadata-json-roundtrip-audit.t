#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

subtest 'HDLGenerator result shell-only branch metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    for my $field (qw(
        fsm_module_shell_only
        raw_ast_shell_only
        resolved_package_imports_shell_only
        composition_spec_shell_only
        composition_plan_shell_only
        composition_report_shell_only
    )) {
        is($decoded->{$field}, 1, "decoded $field remains true");
    }

    is($decoded->{fsm_module_raw_value_class_when_defined}, 'FSM::CoreAST::FSMModule', 'decoded fsm_module raw value class remains explicit');
    is($decoded->{raw_ast_value_shape}, 'ARRAY', 'decoded raw_ast value shape remains explicit');
    is($decoded->{resolved_package_imports_raw_value_class}, 'FSM::Package::Spec', 'decoded package import raw value class remains explicit');
    is($decoded->{composition_report_raw_hash_json_safe}, 0, 'decoded composition_report raw hash remains not JSON-safe');
};

done_testing();
