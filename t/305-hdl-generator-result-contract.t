#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
    hdl_generator_result_known_top_level_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $contract = build_hdl_generator_result_contract();

subtest 'contract declares the bounded HDLGenerator result surface' => sub {
    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_top_level_presence', 'contract declares bounded top-level presence status');
    is($contract->{contract_source}, 'FSM::Support::HDLGeneratorResultContract', 'contract records its owner');
    ok(!$contract->{stable_nested_content}, 'contract does not overpromise stable nested content');
    ok(!$contract->{full_result_json_safe}, 'contract does not claim the whole raw result is JSON-safe');
    is(
        $contract->{json_safe_export_surface},
        'semantic_exports.normalized_semantic_json',
        'contract points JSON consumers to normalized semantic JSON',
    );

    my %public = map { $_ => 1 } @{$contract->{public_top_level_presence_keys}};
    ok($public{hdl_code}, 'contract includes generated HDL text');
    ok($public{module_info}, 'contract includes module_info presence');
    ok($public{intent_hir}, 'contract includes intent_hir presence');
    ok($public{lowered_rtl_ir}, 'contract includes lowered_rtl_ir presence');
    ok($public{structural_rtl_ir}, 'contract includes structural_rtl_ir presence');

    my %unsanitized = map { $_ => 1 } @{$contract->{live_or_unsanitized_keys}};
    ok($unsanitized{raw_ast}, 'contract marks raw AST as unsanitized');
    ok($unsanitized{fsm_module}, 'contract marks live fsm_module as unsanitized');
    ok($unsanitized{composition_plan}, 'contract marks composition plan object as unsanitized');
    ok($unsanitized{statistics}, 'contract marks statistics as not wholly sanitized');
};

subtest 'direct-root result uses only declared top-level keys' => sub {
    my $result = generate_result('fsm/apb_requester.fsm');

    assert_no_unknown_top_level_keys($result, 'direct-root result');
    assert_common_result_contract(
        $result,
        source_kind => 'fsm',
        module_name => 'apb_requester',
        source_root_kind => 'fsm',
    );
    isa_ok($result->{fsm_module}, 'FSM::CoreAST::FSMModule', 'direct root fsm_module');
    is(ref($result->{raw_ast}), 'ARRAY', 'direct root carries raw AST compatibility payload');
    ok(!exists $result->{composition_spec}, 'direct root omits composition_spec');
    ok(!exists $result->{composition_plan}, 'direct root omits composition_plan');
    ok(!exists $result->{composition_report}, 'direct root omits composition_report');
};

subtest 'composition result uses only declared top-level keys' => sub {
    my $result = generate_result('fsm/apb_tb.fsm');

    assert_no_unknown_top_level_keys($result, 'composition result');
    assert_common_result_contract(
        $result,
        source_kind => 'composition',
        module_name => 'apb_tb',
        source_root_kind => 'top',
    );
    ok(exists $result->{fsm_module}, 'composition result still carries fsm_module compatibility key');
    ok(!defined $result->{fsm_module}, 'composition result fsm_module compatibility key is undef');
    is(ref($result->{raw_ast}), 'ARRAY', 'composition result carries raw AST compatibility payload');
    isa_ok($result->{composition_spec}, 'FSM::Composition::Spec', 'composition spec');
    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan', 'composition plan');
    is(ref($result->{composition_report}), 'HASH', 'composition result carries composition report hash');
};

done_testing();

sub generate_result {
    my ($relpath) = @_;
    my $path = File::Spec->catfile($repo_root, split m{/}, $relpath);
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub assert_no_unknown_top_level_keys {
    my ($result, $label) = @_;

    my %known = map { $_ => 1 } @{hdl_generator_result_known_top_level_keys()};
    my @unknown = grep { !$known{$_} } sort keys %{$result || {}};
    is_deeply(\@unknown, [], "$label has no undeclared top-level result keys");
}

sub assert_common_result_contract {
    my ($result, %args) = @_;

    is(ref($result), 'HASH', "$args{module_name} result is a hash");
    ok(!ref($result->{hdl_code}) && length($result->{hdl_code}), "$args{module_name} has generated HDL text");
    like($result->{hdl_code}, qr/\bmodule\s+\Q$args{module_name}\E\b/s, "$args{module_name} HDL names the module/top");

    for my $key (qw(module_info intent_hir lowered_rtl_ir structural_rtl_ir source_info resolved_package_imports statistics)) {
        is(ref($result->{$key}), 'HASH', "$args{module_name} result carries hashref $key");
    }

    is($result->{source_info}{kind}, $args{source_kind}, "$args{module_name} records source kind");
    is($result->{module_info}{module_name}, $args{module_name}, "$args{module_name} module_info records name");
    is($result->{module_info}{source_root_kind}, $args{source_root_kind}, "$args{module_name} module_info records root kind");
    is($result->{intent_hir}{module_name}, $args{module_name}, "$args{module_name} intent_hir records name");
    is($result->{intent_hir}{source_root_kind}, $args{source_root_kind}, "$args{module_name} intent_hir records root kind");
    is($result->{lowered_rtl_ir}{module_name}, $args{module_name}, "$args{module_name} lowered_rtl_ir records name");
    is($result->{structural_rtl_ir}{module_name}, $args{module_name}, "$args{module_name} structural_rtl_ir records name");

    is_deeply(
        $result->{module_info}{lowered_rtl_ir},
        $result->{lowered_rtl_ir},
        "$args{module_name} module_info mirrors lowered_rtl_ir",
    );
    is_deeply(
        $result->{module_info}{structural_rtl_ir},
        $result->{structural_rtl_ir},
        "$args{module_name} module_info mirrors structural_rtl_ir",
    );
}
