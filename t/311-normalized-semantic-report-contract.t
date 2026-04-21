#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CheckFailureDiagnosticContract qw(
    check_failure_diagnostic_contract_source
    check_failure_diagnostic_matched_presence_keys
    check_failure_diagnostic_presence_keys
    check_failure_diagnostic_support_accounting_matched_presence_keys
    check_failure_diagnostic_support_accounting_presence_keys
);
use FSM::Support::ReportCommandContract qw(
    report_command_contract_source
);
use FSM::Support::ReportGeneratedOutputContract qw(
    report_generated_output_contract_source
);
use FSM::Support::ReportProducerContract qw(
    report_producer_contract_source
);
use FSM::Support::ReportSourceContract qw(
    report_source_contract_source
);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_contract_source
);
use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_contract_source
    normalized_semantic_composition_presence_keys
);
use FSM::Support::NormalizedSemanticExplicitSystemContract qw(
    normalized_semantic_explicit_system_contract_source
    normalized_semantic_explicit_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticForwardIRContract qw(
    normalized_semantic_forward_ir_contract_source
    normalized_semantic_forward_ir_intent_hir_contract_source
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_intent_hir_presence_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_contract_source
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys
    normalized_semantic_forward_ir_structural_rtl_ir_contract_source
    normalized_semantic_forward_ir_structural_rtl_ir_presence_keys
    normalized_semantic_forward_ir_presence_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    build_normalized_semantic_report_contract
    normalized_semantic_report_contract_source
    normalized_semantic_composition_keys
    normalized_semantic_explicit_system_contract_keys
    normalized_semantic_failure_diagnostic_keys
    normalized_semantic_failure_diagnostic_support_accounting_keys
    normalized_semantic_forward_ir_keys
    normalized_semantic_forward_ir_intent_hir_keys
    normalized_semantic_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_forward_ir_structural_rtl_ir_keys
    normalized_semantic_matched_failure_diagnostic_keys
    normalized_semantic_matched_failure_diagnostic_support_accounting_keys
    normalized_semantic_matched_failure_support_accounting_keys
    normalized_semantic_matched_success_support_accounting_keys
    normalized_semantic_module_keys
    normalized_semantic_module_optional_metric_keys
    normalized_semantic_nested_presence_key_map
    normalized_semantic_presence_key_family_map
    normalized_semantic_public_top_level_keys
    normalized_semantic_signal_analysis_entry_keys
    normalized_semantic_signal_analysis_keys
    normalized_semantic_system_contract_keys
    normalized_semantic_symbol_contract_keys
    normalized_semantic_success_only_top_level_keys
    normalized_semantic_success_semantic_keys
    normalized_semantic_support_accounting_keys
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
    normalized_semantic_payload_contract_source
    normalized_semantic_payload_composition_keys
    normalized_semantic_payload_explicit_system_contract_keys
    normalized_semantic_payload_forward_ir_nested_contract_source_map
    normalized_semantic_payload_forward_ir_nested_presence_key_map
    normalized_semantic_payload_nested_presence_key_map
    normalized_semantic_payload_presence_key_family_map
    normalized_semantic_payload_forward_ir_intent_hir_keys
    normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys
    normalized_semantic_payload_forward_ir_structural_rtl_ir_keys
    normalized_semantic_payload_presence_keys
    normalized_semantic_payload_signal_analysis_keys
    normalized_semantic_payload_system_contract_keys
    normalized_semantic_payload_symbol_contract_keys
);
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(
    normalized_semantic_signal_analysis_contract_source
    normalized_semantic_signal_analysis_entry_presence_keys
    normalized_semantic_signal_analysis_presence_keys
);
use FSM::Support::NormalizedSemanticSystemContract qw(
    normalized_semantic_system_contract_source
    normalized_semantic_system_contract_presence_keys
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    normalized_semantic_symbol_contract_source
    normalized_semantic_symbol_contract_presence_keys
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_contract_source
);
use FSM::Support::ReportCommandContract qw(report_command_presence_keys);
use FSM::Support::ReportGeneratedOutputContract qw(report_generated_output_presence_keys);
use FSM::Support::ReportProducerContract qw(
    normalized_semantic_report_producer_extra_keys
    report_producer_common_keys
);
use FSM::Support::ReportSourceContract qw(report_source_presence_keys);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);

subtest 'contract exposes the bounded normalized semantic surface' => sub {
    my $contract = build_normalized_semantic_report_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks normalized semantic JSON as bounded public');
    is(
        $contract->{contract_source},
        normalized_semantic_report_contract_source(),
        'contract records its own owner',
    );
    is(
        $contract->{report_source},
        'FSM::Support::NormalizedSemanticReport',
        'contract records the normalized semantic report owner',
    );
    ok(!$contract->{emits_hdl}, 'contract says normalized semantic JSON emits no HDL');
    ok($contract->{emits_support_accounting_object}, 'contract says normalized semantic JSON emits support accounting');
    is_deeply(
        $contract->{nested_contract_source_map},
        {
            command => report_command_contract_source(),
            failure_diagnostic => check_failure_diagnostic_contract_source(),
            generated_output => report_generated_output_contract_source(),
            composition => normalized_semantic_composition_contract_source(),
            explicit_system_contract => normalized_semantic_explicit_system_contract_source(),
            forward_ir => normalized_semantic_forward_ir_contract_source(),
            module => normalized_semantic_module_contract_source(),
            semantic => normalized_semantic_payload_contract_source(),
            signal_analysis => normalized_semantic_signal_analysis_contract_source(),
            system_contract => normalized_semantic_system_contract_source(),
            symbol_contract => normalized_semantic_symbol_contract_source(),
            producer => report_producer_contract_source(),
            source => report_source_contract_source(),
            support_accounting => support_accounting_match_contract_source(),
        },
        'contract publishes the bounded normalized-semantic nested-contract ownership map',
    );
    is_deeply(
        $contract->{forward_ir_nested_contract_source_map},
        normalized_semantic_payload_forward_ir_nested_contract_source_map(),
        'contract publishes the bounded grouped forward-ir child-owner map',
    );
    is_deeply(
        $contract->{forward_ir_nested_presence_key_map},
        normalized_semantic_payload_forward_ir_nested_presence_key_map(),
        'contract publishes the bounded grouped forward-ir child key-family map',
    );
    is_deeply(
        $contract->{semantic_nested_presence_key_map},
        normalized_semantic_payload_nested_presence_key_map(),
        'contract publishes the bounded grouped semantic child key-family map',
    );
    is_deeply(
        $contract->{semantic_presence_key_family_map},
        normalized_semantic_payload_presence_key_family_map(),
        'contract republishes the grouped semantic payload shell key-family map',
    );
    is_deeply(
        $contract->{nested_presence_key_map},
        normalized_semantic_nested_presence_key_map(),
        'contract publishes the bounded normalized-semantic nested key-family map',
    );
    is_deeply(
        $contract->{presence_key_family_map},
        normalized_semantic_presence_key_family_map(),
        'contract publishes the bounded normalized-semantic shell-owned key-family map',
    );
    is(
        $contract->{command_contract_source},
        report_command_contract_source(),
        'contract records the shared command nested-object owner',
    );
    is(
        $contract->{failure_diagnostic_contract_source},
        check_failure_diagnostic_contract_source(),
        'contract records the shared failure diagnostic nested-object owner',
    );
    is(
        $contract->{generated_output_contract_source},
        report_generated_output_contract_source(),
        'contract records the shared generated_output nested-object owner',
    );
    is(
        $contract->{composition_contract_source},
        normalized_semantic_composition_contract_source(),
        'contract records the nested composition object owner',
    );
    is(
        $contract->{explicit_system_contract_source},
        normalized_semantic_explicit_system_contract_source(),
        'contract records the nested explicit-system-contract object owner',
    );
    is(
        $contract->{signal_analysis_contract_source},
        normalized_semantic_signal_analysis_contract_source(),
        'contract records the nested signal-analysis object owner',
    );
    is(
        $contract->{forward_ir_contract_source},
        normalized_semantic_forward_ir_contract_source(),
        'contract records the nested forward-IR object owner',
    );
    is(
        $contract->{module_contract_source},
        normalized_semantic_module_contract_source(),
        'contract records the nested module object owner',
    );
    is(
        $contract->{semantic_contract_source},
        normalized_semantic_payload_contract_source(),
        'contract records the semantic success payload owner',
    );
    is(
        $contract->{system_contract_source},
        normalized_semantic_system_contract_source(),
        'contract records the nested system-contract object owner',
    );
    is(
        $contract->{symbol_contract_source},
        normalized_semantic_symbol_contract_source(),
        'contract records the nested symbol-contract object owner',
    );
    is(
        $contract->{producer_contract_source},
        report_producer_contract_source(),
        'contract records the shared producer nested-object owner',
    );
    is(
        $contract->{source_contract_source},
        report_source_contract_source(),
        'contract records the shared source nested-object owner',
    );
    is(
        $contract->{support_accounting_contract_source},
        support_accounting_match_contract_source(),
        'contract records the shared support-accounting nested-object owner',
    );
    ok($contract->{failure_omits_semantic_payload}, 'contract says failed reports omit semantic payload');
    ok($contract->{full_report_json_safe}, 'contract says the emitted report is JSON-safe');
    ok(!$contract->{full_export_stable}, 'contract keeps full export stabilization out of the bounded promise');

    is_deeply(
        $contract->{public_top_level_presence_keys},
        normalized_semantic_public_top_level_keys(),
        'contract publishes the bounded top-level key list',
    );
    is_deeply(
        $contract->{success_only_top_level_keys},
        normalized_semantic_success_only_top_level_keys(),
        'contract publishes the success-only top-level key list',
    );
    is_deeply(
        $contract->{command_presence_keys},
        report_command_presence_keys(),
        'contract publishes the bounded command-object key list',
    );
    is_deeply(
        $contract->{generated_output_presence_keys},
        report_generated_output_presence_keys(),
        'contract publishes the bounded generated_output-object key list',
    );
    is_deeply(
        $contract->{producer_presence_keys},
        report_producer_common_keys(),
        'contract publishes the bounded producer-object common key list',
    );
    is_deeply(
        $contract->{producer_extra_presence_keys},
        normalized_semantic_report_producer_extra_keys(),
        'contract publishes the bounded normalized-semantic producer extra key list',
    );
    is_deeply(
        $contract->{source_presence_keys},
        report_source_presence_keys(),
        'contract publishes the bounded source-object key list',
    );
    is_deeply(
        $contract->{support_accounting_presence_keys},
        normalized_semantic_support_accounting_keys(),
        'contract publishes the common support-accounting key list',
    );
    is_deeply(
        $contract->{failure_diagnostic_presence_keys},
        normalized_semantic_failure_diagnostic_keys(),
        'contract publishes the bounded failure-diagnostic key list',
    );
    is_deeply(
        normalized_semantic_failure_diagnostic_keys(),
        check_failure_diagnostic_presence_keys(),
        'normalized semantic failure-diagnostic keys map to the shared failure-diagnostic owner',
    );
    is_deeply(
        $contract->{matched_failure_diagnostic_presence_keys},
        normalized_semantic_matched_failure_diagnostic_keys(),
        'contract publishes the matched failure-diagnostic key list',
    );
    is_deeply(
        normalized_semantic_matched_failure_diagnostic_keys(),
        check_failure_diagnostic_matched_presence_keys(),
        'normalized semantic matched failure-diagnostic keys map to the shared failure-diagnostic owner',
    );
    is_deeply(
        $contract->{failure_diagnostic_support_accounting_presence_keys},
        normalized_semantic_failure_diagnostic_support_accounting_keys(),
        'contract publishes the common failure-diagnostic support-accounting key list',
    );
    is_deeply(
        normalized_semantic_failure_diagnostic_support_accounting_keys(),
        check_failure_diagnostic_support_accounting_presence_keys(),
        'normalized semantic failure-diagnostic support-accounting keys map to the shared failure-diagnostic owner',
    );
    is_deeply(
        $contract->{matched_failure_diagnostic_support_accounting_presence_keys},
        normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        'contract publishes the matched failure-diagnostic support-accounting key list',
    );
    is_deeply(
        normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        check_failure_diagnostic_support_accounting_matched_presence_keys(),
        'normalized semantic matched failure-diagnostic support-accounting keys map to the shared failure-diagnostic owner',
    );
    is_deeply(
        $contract->{matched_success_support_accounting_presence_keys},
        normalized_semantic_matched_success_support_accounting_keys(),
        'contract publishes the matched success support-accounting key list',
    );
    is_deeply(
        $contract->{matched_failure_support_accounting_presence_keys},
        normalized_semantic_matched_failure_support_accounting_keys(),
        'contract publishes the matched failure support-accounting key list',
    );
    is_deeply(
        $contract->{success_semantic_presence_keys},
        normalized_semantic_payload_presence_keys(),
        'contract publishes the bounded semantic payload key list',
    );
    is_deeply(
        $contract->{success_module_presence_keys},
        normalized_semantic_module_keys(),
        'contract publishes the bounded module key list',
    );
    is_deeply(
        normalized_semantic_module_keys(),
        FSM::Support::NormalizedSemanticModuleContract::normalized_semantic_module_presence_keys(),
        'normalized semantic module keys map to the nested module owner',
    );
    is_deeply(
        $contract->{success_module_optional_metric_keys},
        normalized_semantic_module_optional_metric_keys(),
        'contract publishes the bounded optional module metric key list',
    );
    is_deeply(
        normalized_semantic_module_optional_metric_keys(),
        FSM::Support::NormalizedSemanticModuleContract::normalized_semantic_module_optional_metric_keys(),
        'normalized semantic optional module metric keys map to the nested module owner',
    );
    is_deeply(
        $contract->{success_explicit_system_contract_presence_keys},
        normalized_semantic_explicit_system_contract_keys(),
        'contract publishes the bounded explicit-system-contract key list',
    );
    is_deeply(
        normalized_semantic_explicit_system_contract_keys(),
        normalized_semantic_explicit_system_contract_presence_keys(),
        'normalized semantic explicit-system-contract keys map to the nested explicit-system-contract owner',
    );
    is_deeply(
        normalized_semantic_payload_explicit_system_contract_keys(),
        normalized_semantic_explicit_system_contract_presence_keys(),
        'semantic payload explicit-system-contract keys map to the nested explicit-system-contract owner',
    );
    is_deeply(
        $contract->{success_signal_analysis_presence_keys},
        normalized_semantic_signal_analysis_keys(),
        'contract publishes the bounded signal-analysis key list',
    );
    is_deeply(
        $contract->{success_signal_analysis_entry_presence_keys},
        normalized_semantic_signal_analysis_entry_keys(),
        'contract publishes the bounded signal-analysis entry key list',
    );
    is_deeply(
        normalized_semantic_signal_analysis_entry_keys(),
        normalized_semantic_signal_analysis_entry_presence_keys(),
        'normalized semantic signal-analysis entry keys map to the nested signal-analysis owner',
    );
    is_deeply(
        normalized_semantic_signal_analysis_keys(),
        normalized_semantic_signal_analysis_presence_keys(),
        'normalized semantic signal-analysis keys map to the nested signal-analysis owner',
    );
    is_deeply(
        normalized_semantic_payload_signal_analysis_keys(),
        normalized_semantic_signal_analysis_presence_keys(),
        'semantic payload signal-analysis keys map to the nested signal-analysis owner',
    );
    is_deeply(
        $contract->{success_system_contract_presence_keys},
        normalized_semantic_system_contract_keys(),
        'contract publishes the bounded system-contract key list',
    );
    is_deeply(
        normalized_semantic_system_contract_keys(),
        normalized_semantic_system_contract_presence_keys(),
        'normalized semantic system-contract keys map to the nested system-contract owner',
    );
    is_deeply(
        normalized_semantic_payload_system_contract_keys(),
        normalized_semantic_system_contract_presence_keys(),
        'semantic payload system-contract keys map to the nested system-contract owner',
    );
    is_deeply(
        $contract->{success_forward_ir_presence_keys},
        normalized_semantic_forward_ir_keys(),
        'contract publishes the bounded forward-IR key list',
    );
    is(
        $contract->{forward_ir_intent_hir_contract_source},
        normalized_semantic_forward_ir_intent_hir_contract_source(),
        'contract records the nested forward-ir intent-hir object owner',
    );
    is_deeply(
        $contract->{success_forward_ir_intent_hir_presence_keys},
        normalized_semantic_forward_ir_intent_hir_keys(),
        'contract publishes the bounded forward-ir intent-hir key list',
    );
    is_deeply(
        $contract->{success_forward_ir_intent_hir_optional_composition_keys},
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'contract publishes the bounded forward-ir intent-hir composition-only key list',
    );
    is(
        $contract->{forward_ir_lowered_rtl_ir_contract_source},
        normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        'contract records the nested forward-ir lowered-rtl-ir object owner',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_presence_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir key list',
    );
    is_deeply(
        $contract->{success_forward_ir_lowered_rtl_ir_optional_composition_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'contract publishes the bounded forward-ir lowered-rtl-ir composition-only key list',
    );
    is(
        $contract->{forward_ir_structural_rtl_ir_contract_source},
        normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        'contract records the nested forward-ir structural-rtl-ir object owner',
    );
    is_deeply(
        $contract->{success_forward_ir_structural_rtl_ir_presence_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        'contract publishes the bounded forward-ir structural-rtl-ir key list',
    );
    is_deeply(
        normalized_semantic_forward_ir_keys(),
        normalized_semantic_forward_ir_presence_keys(),
        'normalized semantic forward-IR keys map to the nested forward-IR owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_intent_hir_keys(),
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'normalized semantic report forward-ir intent-hir keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'normalized semantic report forward-ir intent-hir composition keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'normalized semantic report forward-ir lowered-rtl-ir keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'normalized semantic report forward-ir lowered-rtl-ir composition keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'normalized semantic report forward-ir structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_intent_hir_keys(),
        normalized_semantic_forward_ir_intent_hir_presence_keys(),
        'semantic payload forward-ir intent-hir keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_intent_hir_optional_composition_keys(),
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'semantic payload forward-ir intent-hir composition keys map to the nested intent-hir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_presence_keys(),
        'semantic payload forward-ir lowered-rtl-ir keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'semantic payload forward-ir lowered-rtl-ir composition keys map to the nested lowered-rtl-ir owner',
    );
    is_deeply(
        normalized_semantic_payload_forward_ir_structural_rtl_ir_keys(),
        normalized_semantic_forward_ir_structural_rtl_ir_presence_keys(),
        'semantic payload forward-ir structural-rtl-ir keys map to the nested structural-rtl-ir owner',
    );
    is_deeply(
        $contract->{composition_presence_keys},
        normalized_semantic_payload_composition_keys(),
        'contract publishes the bounded composition key list',
    );
    is_deeply(
        $contract->{success_symbol_contract_presence_keys},
        normalized_semantic_symbol_contract_keys(),
        'contract publishes the bounded symbol-contract key list',
    );
    is_deeply(
        normalized_semantic_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'normalized semantic symbol-contract keys map to the nested symbol-contract owner',
    );
    is_deeply(
        normalized_semantic_payload_symbol_contract_keys(),
        normalized_semantic_symbol_contract_presence_keys(),
        'semantic payload symbol-contract keys map to the nested symbol-contract owner',
    );
    is_deeply(
        normalized_semantic_composition_keys(),
        normalized_semantic_composition_presence_keys(),
        'normalized semantic composition keys map to the nested composition owner',
    );
};

my $ok_path = File::Spec->catfile($tempdir, 'semantic_contract_ok.fsm');
my $bad_path = File::Spec->catfile($tempdir, 'semantic_contract_bad.fsm');
my $ok_out_path = File::Spec->catfile($tempdir, 'semantic_contract_ok.sv');
my $bad_out_path = File::Spec->catfile($tempdir, 'semantic_contract_bad.sv');

write_file(
    $ok_path,
    <<'FSM'
(?fsm:semantic_contract_ok
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (COND 1)
    (SRC 8)
    (OUT 8)
  )

  (idle
    (<COND
      (= (OUT SRC))
    )
  )
)
FSM
);

write_file(
    $bad_path,
    <<'FSM'
(?fsm:semantic_contract_bad
  (+system
    (clock clk)
    (sreset reset)
  )

  (+size
    (SRC 8)
    (OUT 8)
  )

  (idle
    (OUT = SRC)
  )
)
FSM
);

subtest 'successful direct semantic JSON conforms to the bounded contract' => sub {
    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $ok_out_path, $ok_path],
        'strict semantic JSON succeeds for direct sample',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'direct success report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{command},
        report_command_presence_keys(),
        'direct success report keeps bounded command-object keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        report_generated_output_presence_keys(),
        'direct success report keeps bounded generated_output-object keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'direct success report keeps bounded producer-object common keys',
    );
    assert_keys_present(
        $decoded->{producer},
        normalized_semantic_report_producer_extra_keys(),
        'direct success report keeps bounded producer-object extra keys',
    );
    assert_keys_present(
        $decoded->{source},
        report_source_presence_keys(),
        'direct success report keeps bounded source-object keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'direct success report keeps common support-accounting keys',
    );
    assert_keys_present(
        $decoded,
        normalized_semantic_success_only_top_level_keys(),
        'direct success report keeps success-only top-level keys',
    );
    assert_keys_present(
        $decoded->{semantic},
        normalized_semantic_success_semantic_keys(),
        'direct success semantic payload keeps bounded semantic keys',
    );
    assert_keys_present(
        $decoded->{semantic}{module},
        normalized_semantic_module_keys(),
        'direct success module payload keeps bounded module keys',
    );
    assert_keys_present(
        $decoded->{semantic}{signal_analysis},
        normalized_semantic_signal_analysis_keys(),
        'direct success semantic payload keeps bounded signal-analysis keys',
    );
    for my $bucket (qw(inputs outputs multi_bit single_bit)) {
        next unless @{$decoded->{semantic}{signal_analysis}{$bucket} || []};
        assert_keys_present(
            $decoded->{semantic}{signal_analysis}{$bucket}[0],
            normalized_semantic_signal_analysis_entry_keys(),
            "direct success semantic payload keeps bounded signal-analysis entry keys for $bucket",
        );
    }
    assert_keys_present(
        $decoded->{semantic}{explicit_system_contract},
        normalized_semantic_explicit_system_contract_keys(),
        'direct success semantic payload keeps bounded explicit-system-contract keys',
    );
    assert_keys_present(
        $decoded->{semantic}{system_contract},
        normalized_semantic_system_contract_keys(),
        'direct success semantic payload keeps bounded system-contract keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir},
        normalized_semantic_forward_ir_keys(),
        'direct success semantic payload keeps bounded forward-IR keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{intent_hir},
        normalized_semantic_forward_ir_intent_hir_keys(),
        'direct success semantic payload keeps bounded forward-ir intent-hir keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{lowered_rtl_ir},
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        'direct success semantic payload keeps bounded forward-ir lowered-rtl-ir keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{structural_rtl_ir},
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        'direct success semantic payload keeps bounded forward-ir structural-rtl-ir keys',
    );
    for my $key (@{normalized_semantic_forward_ir_intent_hir_optional_composition_keys() || []}) {
        ok(
            !exists $decoded->{semantic}{forward_ir}{intent_hir}{$key},
            "direct success semantic payload omits composition-only intent-hir key $key",
        );
    }
    for my $key (@{normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys() || []}) {
        ok(
            !exists $decoded->{semantic}{forward_ir}{lowered_rtl_ir}{$key},
            "direct success semantic payload omits composition-only lowered-rtl-ir key $key",
        );
    }

    ok(!exists $decoded->{semantic}{composition}, 'direct success omits optional composition payload');
    ok(!$decoded->{generated_output}{emitted}, 'direct success still records no HDL emission');
};

subtest 'successful composition semantic JSON conforms to the bounded contract' => sub {
    my $composition_path = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');
    my $composition_out_path = File::Spec->catfile($tempdir, 'semantic_contract_apb_tb.sv');

    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $composition_out_path, $composition_path],
        'strict semantic JSON succeeds for composition sample',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'composition success report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{command},
        report_command_presence_keys(),
        'composition success report keeps bounded command-object keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        report_generated_output_presence_keys(),
        'composition success report keeps bounded generated_output-object keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'composition success report keeps bounded producer-object common keys',
    );
    assert_keys_present(
        $decoded->{producer},
        normalized_semantic_report_producer_extra_keys(),
        'composition success report keeps bounded producer-object extra keys',
    );
    assert_keys_present(
        $decoded->{source},
        report_source_presence_keys(),
        'composition success report keeps bounded source-object keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'composition success report keeps common support-accounting keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_matched_success_support_accounting_keys(),
        'composition success report keeps matched support-accounting keys',
    );
    assert_keys_present(
        $decoded->{semantic},
        normalized_semantic_success_semantic_keys(),
        'composition success semantic payload keeps bounded semantic keys',
    );
    assert_keys_present(
        $decoded->{semantic}{module},
        normalized_semantic_module_keys(),
        'composition success module payload keeps bounded module keys',
    );
    assert_keys_present(
        $decoded->{semantic}{signal_analysis},
        normalized_semantic_signal_analysis_keys(),
        'composition success semantic payload keeps bounded signal-analysis keys',
    );
    for my $bucket (qw(inputs outputs multi_bit single_bit)) {
        next unless @{$decoded->{semantic}{signal_analysis}{$bucket} || []};
        assert_keys_present(
            $decoded->{semantic}{signal_analysis}{$bucket}[0],
            normalized_semantic_signal_analysis_entry_keys(),
            "composition success semantic payload keeps bounded signal-analysis entry keys for $bucket",
        );
    }
    assert_keys_present(
        $decoded->{semantic}{composition},
        normalized_semantic_composition_keys(),
        'composition success semantic payload keeps bounded composition keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{intent_hir},
        normalized_semantic_forward_ir_intent_hir_keys(),
        'composition success semantic payload keeps bounded forward-ir intent-hir keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{intent_hir},
        normalized_semantic_forward_ir_intent_hir_optional_composition_keys(),
        'composition success semantic payload keeps bounded forward-ir intent-hir composition-only keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{lowered_rtl_ir},
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        'composition success semantic payload keeps bounded forward-ir lowered-rtl-ir keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{lowered_rtl_ir},
        normalized_semantic_forward_ir_lowered_rtl_ir_optional_composition_keys(),
        'composition success semantic payload keeps bounded forward-ir lowered-rtl-ir composition-only keys',
    );
    assert_keys_present(
        $decoded->{semantic}{forward_ir}{structural_rtl_ir},
        normalized_semantic_forward_ir_structural_rtl_ir_keys(),
        'composition success semantic payload keeps bounded forward-ir structural-rtl-ir keys',
    );
    ok(
        exists $decoded->{semantic}{module}{composition_child_count},
        'composition success module payload exposes composition child count',
    );
};

subtest 'successful symbol-rich semantic JSON conforms to the bounded symbol-contract contract' => sub {
    my $symbol_path = File::Spec->catfile($repo_root, 't', 'corpus', 'direct_size_expression_widths.fsm');
    my $symbol_out_path = File::Spec->catfile($tempdir, 'semantic_contract_symbol_rich.sv');

    my $decoded = run_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $symbol_out_path, $symbol_path],
        'strict semantic JSON succeeds for symbol-rich sample',
    );

    ok($decoded->{semantic}{symbol_contract}, 'symbol-rich success report exposes the optional symbol-contract payload');
    assert_keys_present(
        $decoded->{semantic}{symbol_contract},
        normalized_semantic_symbol_contract_keys(),
        'symbol-rich success report keeps bounded symbol-contract keys',
    );
};

subtest 'failed semantic JSON conforms to the bounded contract' => sub {
    my $decoded = run_failed_semantic_json(
        ['./bin/fsmgen', '--strict', '--emit-semantic-json', '-o', $bad_out_path, $bad_path],
        'strict semantic JSON fails for rejected source',
    );

    assert_keys_present(
        $decoded,
        normalized_semantic_public_top_level_keys(),
        'failed report keeps bounded top-level keys',
    );
    assert_keys_present(
        $decoded->{command},
        report_command_presence_keys(),
        'failed report keeps bounded command-object keys',
    );
    assert_keys_present(
        $decoded->{generated_output},
        report_generated_output_presence_keys(),
        'failed report keeps bounded generated_output-object keys',
    );
    assert_keys_present(
        $decoded->{producer},
        report_producer_common_keys(),
        'failed report keeps bounded producer-object common keys',
    );
    assert_keys_present(
        $decoded->{producer},
        normalized_semantic_report_producer_extra_keys(),
        'failed report keeps bounded producer-object extra keys',
    );
    assert_keys_present(
        $decoded->{source},
        report_source_presence_keys(),
        'failed report keeps bounded source-object keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_support_accounting_keys(),
        'failed report keeps common support-accounting keys',
    );
    assert_keys_present(
        $decoded->{support_accounting},
        normalized_semantic_matched_failure_support_accounting_keys(),
        'failed report keeps matched failure support-accounting keys',
    );
    is(scalar(@{$decoded->{diagnostics}}), 1, 'failed report keeps one diagnostic');
    assert_keys_present(
        $decoded->{diagnostics}[0],
        normalized_semantic_failure_diagnostic_keys(),
        'failed report diagnostic keeps bounded failure-diagnostic keys',
    );
    assert_keys_present(
        $decoded->{diagnostics}[0],
        normalized_semantic_matched_failure_diagnostic_keys(),
        'failed report diagnostic keeps matched failure-diagnostic keys',
    );
    assert_keys_present(
        $decoded->{diagnostics}[0]{support_accounting},
        normalized_semantic_failure_diagnostic_support_accounting_keys(),
        'failed report diagnostic keeps common nested support-accounting keys',
    );
    assert_keys_present(
        $decoded->{diagnostics}[0]{support_accounting},
        normalized_semantic_matched_failure_diagnostic_support_accounting_keys(),
        'failed report diagnostic keeps matched nested support-accounting keys',
    );
    ok(!exists $decoded->{semantic}, 'failed report omits semantic payload');
    ok(!$decoded->{success}, 'failed report keeps success false');
    ok(!$decoded->{generated_output}{emitted}, 'failed report records no HDL emission');
};

done_testing();

sub run_semantic_json {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
    );

    ok($success, $label);
    is(join('', @{$stderr_buf || []}), '', "$label keeps stderr clean");

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, "$label emits decodable JSON");
    return $decoded;
}

sub run_failed_semantic_json {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => $command,
    );

    ok(!$success, $label);
    is(join('', @{$stderr_buf || []}), '', "$label keeps stderr clean");

    my $decoded = eval { decode_json(join('', @{$stdout_buf || []})) };
    ok($decoded, "$label emits decodable JSON");
    return $decoded;
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
