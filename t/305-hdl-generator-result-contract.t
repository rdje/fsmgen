#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use File::Temp qw(tempdir);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
    hdl_generator_result_intent_hir_keys
    hdl_generator_result_intent_hir_optional_composition_keys
    hdl_generator_result_known_top_level_keys
    hdl_generator_result_lowered_rtl_ir_keys
    hdl_generator_result_lowered_rtl_ir_optional_composition_keys
    hdl_generator_result_module_info_identity_keys
    hdl_generator_result_module_info_optional_composition_summary_keys
    hdl_generator_result_module_info_summary_keys
    hdl_generator_result_source_info_identity_keys
    hdl_generator_result_source_info_summary_keys
    hdl_generator_result_statistics_optional_composition_keys
    hdl_generator_result_statistics_summary_keys
    hdl_generator_result_structural_rtl_ir_keys
);
use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    normalized_semantic_intent_hir_optional_composition_keys
    normalized_semantic_intent_hir_presence_keys
);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_lowered_rtl_ir_presence_keys
);
use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(
    normalized_semantic_structural_rtl_ir_presence_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $contract = build_hdl_generator_result_contract();

subtest 'contract declares the bounded HDLGenerator result surface' => sub {
    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_top_level_presence', 'contract declares bounded top-level presence status');
    is($contract->{contract_source}, 'FSM::Support::HDLGeneratorResultContract', 'contract records its owner');
    ok($contract->{nested_identity_slices_advertised}, 'contract advertises bounded nested identity slices');
    ok(!$contract->{stable_nested_content}, 'contract does not overpromise stable nested content');
    ok(!$contract->{full_result_json_safe}, 'contract does not claim the whole raw result is JSON-safe');
    is(
        $contract->{json_safe_export_surface},
        'semantic_exports.normalized_semantic_json',
        'contract points JSON consumers to normalized semantic JSON',
    );
    is_deeply(
        $contract->{source_info_identity_presence_keys},
        hdl_generator_result_source_info_identity_keys(),
        'contract publishes bounded source_info identity keys',
    );
    ok(
        $contract->{source_info_summary_slices_advertised},
        'contract advertises bounded source_info summary slices',
    );
    is_deeply(
        $contract->{source_info_summary_presence_keys},
        hdl_generator_result_source_info_summary_keys(),
        'contract publishes bounded source_info summary keys',
    );
    ok(
        $contract->{resolved_package_imports_shell_only},
        'contract advertises resolved_package_imports as a shell-only branch',
    );
    is(
        $contract->{resolved_package_imports_raw_value_class},
        'FSM::Package::Spec',
        'contract records the raw resolved_package_imports value class',
    );
    is_deeply(
        $contract->{resolved_package_imports_summary_surface},
        ['source_info.package_import_count', 'source_info.package_import_names'],
        'contract points package-import embedders at the bounded source_info summary surface',
    );
    is_deeply(
        $contract->{module_info_identity_presence_keys},
        hdl_generator_result_module_info_identity_keys(),
        'contract publishes bounded module_info identity keys',
    );
    ok(
        $contract->{module_info_summary_slices_advertised},
        'contract advertises bounded module_info summary slices',
    );
    is_deeply(
        $contract->{module_info_summary_presence_keys},
        hdl_generator_result_module_info_summary_keys(),
        'contract publishes bounded module_info summary keys',
    );
    is_deeply(
        $contract->{module_info_optional_composition_summary_keys},
        hdl_generator_result_module_info_optional_composition_summary_keys(),
        'contract publishes bounded composition-only module_info summary keys',
    );
    ok(
        $contract->{statistics_summary_slices_advertised},
        'contract advertises bounded statistics summary slices',
    );
    is_deeply(
        $contract->{statistics_summary_presence_keys},
        hdl_generator_result_statistics_summary_keys(),
        'contract publishes bounded statistics summary keys',
    );
    is_deeply(
        $contract->{statistics_optional_composition_keys},
        hdl_generator_result_statistics_optional_composition_keys(),
        'contract publishes bounded composition-only statistics summary keys',
    );
    ok(
        $contract->{top_level_semantic_layer_contracts_advertised},
        'contract advertises bounded semantic-layer shells for top-level result hashes',
    );
    is(
        $contract->{intent_hir_contract_source},
        'FSM::Support::NormalizedSemanticIntentHIRContract',
        'contract records the top-level intent-hir owner',
    );
    is_deeply(
        $contract->{intent_hir_presence_keys},
        hdl_generator_result_intent_hir_keys(),
        'contract publishes bounded intent-hir shell keys for top-level results',
    );
    is_deeply(
        $contract->{intent_hir_optional_composition_keys},
        hdl_generator_result_intent_hir_optional_composition_keys(),
        'contract publishes bounded intent-hir composition-only keys for top-level results',
    );
    is(
        $contract->{lowered_rtl_ir_contract_source},
        'FSM::Support::NormalizedSemanticLoweredRTLIRContract',
        'contract records the top-level lowered-rtl-ir owner',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_presence_keys},
        hdl_generator_result_lowered_rtl_ir_keys(),
        'contract publishes bounded lowered-rtl-ir shell keys for top-level results',
    );
    is_deeply(
        $contract->{lowered_rtl_ir_optional_composition_keys},
        hdl_generator_result_lowered_rtl_ir_optional_composition_keys(),
        'contract publishes bounded lowered-rtl-ir composition-only keys for top-level results',
    );
    is(
        $contract->{structural_rtl_ir_contract_source},
        'FSM::Support::NormalizedSemanticStructuralRTLIRContract',
        'contract records the top-level structural-rtl-ir owner',
    );
    is_deeply(
        $contract->{structural_rtl_ir_presence_keys},
        hdl_generator_result_structural_rtl_ir_keys(),
        'contract publishes bounded structural-rtl-ir shell keys for top-level results',
    );
    is_deeply(
        hdl_generator_result_intent_hir_keys(),
        normalized_semantic_intent_hir_presence_keys(),
        'result intent-hir shell maps to the normalized semantic intent-hir owner',
    );
    is_deeply(
        hdl_generator_result_intent_hir_optional_composition_keys(),
        normalized_semantic_intent_hir_optional_composition_keys(),
        'result intent-hir composition-only keys map to the normalized semantic intent-hir owner',
    );
    is_deeply(
        hdl_generator_result_lowered_rtl_ir_keys(),
        normalized_semantic_lowered_rtl_ir_presence_keys(),
        'result lowered-rtl-ir shell maps to the normalized semantic lowered-rtl-ir owner',
    );
    is_deeply(
        hdl_generator_result_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_lowered_rtl_ir_optional_composition_keys(),
        'result lowered-rtl-ir composition-only keys map to the normalized semantic lowered-rtl-ir owner',
    );
    is_deeply(
        hdl_generator_result_structural_rtl_ir_keys(),
        normalized_semantic_structural_rtl_ir_presence_keys(),
        'result structural-rtl-ir shell maps to the normalized semantic structural-rtl-ir owner',
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
    ok($unsanitized{resolved_package_imports}, 'contract marks resolved_package_imports as a raw compatibility branch');
    ok($unsanitized{statistics}, 'contract marks statistics as not wholly sanitized');
    ok(!$unsanitized{intent_hir}, 'contract no longer classifies top-level intent_hir as an unsanitized compatibility branch');
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

subtest 'source_info reports package import summaries when imports are present' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $direct_path = File::Spec->catfile($tempdir, 'direct_package_import_root.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'package_import_top.fsm');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'hA5)
  )
)
FSM
    );

    write_file(
        $direct_path,
        <<'FSM'
(?fsm:direct_package_import_root
  (+import shared_local shared_external)
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 8)
  )
  (idle
    (= (OUT shared_external.RESET_BYTE))
  )
)

(?pkg:shared_local
  (+constants
    (BUSY 1)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:package_import_top
  (+import shared_local shared_external)
  (?ports:public_io
    shared_out>8
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=shared_external.RESET_BYTE/shared_out/
    /=shared_local.mode.BUSY/uart_tx.enable/
  )
)

(?pkg:shared_local
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
)

(?rtlif:uart_tx
  enable<1:data
)
FSM
    );

    my $direct = generate_result_from_path($direct_path, source_search_paths => [$libdir]);
    is($direct->{source_info}{package_import_count}, 2, 'direct result source_info records package import count');
    is_deeply(
        $direct->{source_info}{package_import_names},
        [qw(shared_local shared_external)],
        'direct result source_info preserves package import names in authored order',
    );
    is(
        ref($direct->{resolved_package_imports}{shared_external}),
        'FSM::Package::Spec',
        'direct result still carries raw package-spec objects under resolved_package_imports',
    );

    my $composition = generate_result_from_path($composition_path, source_search_paths => [$libdir]);
    is($composition->{source_info}{package_import_count}, 2, 'composition result source_info records package import count');
    is_deeply(
        $composition->{source_info}{package_import_names},
        [qw(shared_local shared_external)],
        'composition result source_info preserves package import names in authored order',
    );
    is(
        ref($composition->{resolved_package_imports}{shared_external}),
        'FSM::Package::Spec',
        'composition result still carries raw package-spec objects under resolved_package_imports',
    );
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

sub generate_result_from_path {
    my ($path, %extra) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        %extra,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents;
    close $fh or die "Cannot close $path: $!";
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
    assert_keys_present(
        $result->{source_info},
        hdl_generator_result_source_info_identity_keys(),
        "$args{module_name} source_info keeps bounded nested identity keys",
    );
    assert_keys_present(
        $result->{source_info},
        hdl_generator_result_source_info_summary_keys(),
        "$args{module_name} source_info keeps bounded summary keys",
    );
    assert_keys_present(
        $result->{module_info},
        hdl_generator_result_module_info_identity_keys(),
        "$args{module_name} module_info keeps bounded nested identity keys",
    );
    assert_keys_present(
        $result->{module_info},
        hdl_generator_result_module_info_summary_keys(),
        "$args{module_name} module_info keeps bounded summary keys",
    );
    assert_keys_present(
        $result->{statistics},
        hdl_generator_result_statistics_summary_keys(),
        "$args{module_name} statistics keeps bounded summary keys",
    );
    assert_keys_present(
        $result->{intent_hir},
        hdl_generator_result_intent_hir_keys(),
        "$args{module_name} top-level intent_hir keeps bounded shell keys",
    );
    assert_keys_present(
        $result->{lowered_rtl_ir},
        hdl_generator_result_lowered_rtl_ir_keys(),
        "$args{module_name} top-level lowered_rtl_ir keeps bounded shell keys",
    );
    assert_keys_present(
        $result->{structural_rtl_ir},
        hdl_generator_result_structural_rtl_ir_keys(),
        "$args{module_name} top-level structural_rtl_ir keeps bounded shell keys",
    );

    if ($args{source_kind} eq 'composition') {
        assert_keys_present(
            $result->{module_info},
            hdl_generator_result_module_info_optional_composition_summary_keys(),
            "$args{module_name} module_info keeps bounded composition-only summary keys",
        );
        assert_keys_present(
            $result->{statistics},
            hdl_generator_result_statistics_optional_composition_keys(),
            "$args{module_name} statistics keeps bounded composition-only summary keys",
        );
        assert_keys_present(
            $result->{intent_hir},
            hdl_generator_result_intent_hir_optional_composition_keys(),
            "$args{module_name} top-level intent_hir keeps bounded composition-only keys",
        );
        assert_keys_present(
            $result->{lowered_rtl_ir},
            hdl_generator_result_lowered_rtl_ir_optional_composition_keys(),
            "$args{module_name} top-level lowered_rtl_ir keeps bounded composition-only keys",
        );
    } else {
        for my $key (@{hdl_generator_result_module_info_optional_composition_summary_keys() || []}) {
            ok(!exists $result->{module_info}{$key}, "$args{module_name} direct result omits composition-only module_info key $key");
        }
        for my $key (@{hdl_generator_result_statistics_optional_composition_keys() || []}) {
            ok(!exists $result->{statistics}{$key}, "$args{module_name} direct result omits composition-only statistics key $key");
        }
        for my $key (@{hdl_generator_result_intent_hir_optional_composition_keys() || []}) {
            ok(!exists $result->{intent_hir}{$key}, "$args{module_name} direct result omits composition-only intent_hir key $key");
        }
        for my $key (@{hdl_generator_result_lowered_rtl_ir_optional_composition_keys() || []}) {
            ok(!exists $result->{lowered_rtl_ir}{$key}, "$args{module_name} direct result omits composition-only lowered_rtl_ir key $key");
        }
    }

    is($result->{source_info}{kind}, $args{source_kind}, "$args{module_name} records source kind");
    is(ref($result->{source_info}{package_import_names}), 'ARRAY', "$args{module_name} source_info package import names stay array-shaped");
    is(
        $result->{source_info}{package_import_count},
        scalar(@{$result->{source_info}{package_import_names} || []}),
        "$args{module_name} source_info package import count matches package import names",
    );
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

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}
