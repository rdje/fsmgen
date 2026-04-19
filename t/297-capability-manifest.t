#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DiagnosticCodes qw(diagnostic_code_ids);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);

my @entries = regression_corpus_entries();
my @diagnostic_codes = diagnostic_code_ids();
my $manifest = build_capability_manifest();

subtest 'module manifest is generated from support accounting' => sub {
    is($manifest->{manifest_schema_version}, 1, 'manifest exposes its schema version');
    is($manifest->{manifest_contract}{schema_version}, 1, 'manifest exposes top-level manifest contract schema version');
    is($manifest->{manifest_contract}{status}, 'bounded_public', 'manifest marks the top-level manifest shell as bounded public');
    is(
        $manifest->{manifest_contract}{contract_source},
        'FSM::Support::CapabilityManifestContract',
        'manifest records the top-level manifest contract owner',
    );
    ok(
        scalar(@{$manifest->{manifest_contract}{public_top_level_presence_keys} || []}) >= 10,
        'manifest advertises bounded top-level manifest key presence',
    );
    ok(
        scalar(@{$manifest->{manifest_contract}{producer_presence_keys} || []}) >= 6,
        'manifest advertises bounded producer key presence',
    );
    ok(
        scalar(@{$manifest->{manifest_contract}{support_accounting_presence_keys} || []}) >= 24,
        'manifest advertises bounded support-accounting section key presence',
    );
    is($manifest->{producer}{name}, 'FSMGen', 'manifest identifies FSMGen as producer');
    like($manifest->{producer}{version}, qr/\A\d+\.\d+-dev\z/, 'manifest exposes a producer version string');
    like($manifest->{producer}{git_commit}, qr/\A(?:unknown|[0-9a-f]{7,12})\z/, 'manifest exposes a bounded producer commit identity');
    ok($manifest->{producer}{contract_authority}, 'manifest marks producer identity as authoritative');
    is(
        $manifest->{producer}{section_contract}{schema_version},
        1,
        'manifest records producer contract schema version',
    );
    is(
        $manifest->{producer}{section_contract}{status},
        'bounded_public',
        'manifest marks producer contract as bounded public',
    );
    is(
        $manifest->{producer}{section_contract}{contract_source},
        'FSM::Support::ProducerContract',
        'manifest records the producer contract owner',
    );
    ok(
        scalar(@{$manifest->{producer}{section_contract}{public_top_level_presence_keys} || []}) >= 6,
        'manifest advertises bounded producer top-level key presence',
    );
    ok(
        scalar(@{$manifest->{producer}{section_contract}{scalar_string_keys} || []}) >= 4,
        'manifest advertises bounded producer scalar-string key presence',
    );
    ok(
        scalar(@{$manifest->{producer}{section_contract}{boolean_keys} || []}) >= 1,
        'manifest advertises bounded producer boolean key presence',
    );
    is($manifest->{support_accounting}{schema_version}, 1, 'manifest records support-accounting schema version');
    is($manifest->{support_accounting}{status}, 'bounded_public', 'manifest marks support accounting as bounded public');
    is(
        $manifest->{support_accounting}{contract_source},
        'FSM::Support::SupportAccountingContract',
        'manifest records the support-accounting contract owner',
    );
    is(
        $manifest->{support_accounting}{section_contract}{schema_version},
        1,
        'manifest records support-accounting section contract schema version',
    );
    is(
        $manifest->{support_accounting}{section_contract}{status},
        'bounded_public',
        'manifest marks support-accounting section contract as bounded public',
    );
    is(
        $manifest->{support_accounting}{section_contract}{contract_source},
        'FSM::Support::SupportAccountingContract',
        'manifest records the support-accounting section contract owner',
    );
    is($manifest->{support_accounting}{source}, 'FSM::Support::RegressionCorpus', 'manifest records the corpus owner');
    is($manifest->{support_accounting}{entry_count}, scalar(@entries), 'manifest entry count follows the corpus');
    ok(
        scalar(@{$manifest->{support_accounting}{public_top_level_presence_keys} || []}) >= 11,
        'manifest advertises bounded support-accounting top-level key presence',
    );
    ok(
        scalar(@{$manifest->{support_accounting}{section_contract}{public_top_level_presence_keys} || []}) >= 11,
        'manifest advertises bounded nested support-accounting top-level key presence',
    );
    ok(
        scalar(@{$manifest->{support_accounting}{catalog_entry_required_keys} || []}) >= 9,
        'manifest advertises bounded support-accounting catalog-entry required keys',
    );

    is(
        scalar(@{$manifest->{support_accounting}{catalog_entries}}),
        scalar(@entries),
        'manifest exposes one sanitized catalog entry per corpus entry',
    );

    is(
        $manifest->{support_accounting}{classifications}{supported_smoke},
        scalar(grep { $_->{classification} eq 'supported_smoke' } @entries),
        'manifest supported-smoke count follows the corpus',
    );
    is(
        $manifest->{support_accounting}{classifications}{expected_failure},
        scalar(grep { $_->{classification} eq 'expected_failure' } @entries),
        'manifest expected-failure count follows the corpus',
    );
    is(
        scalar(@{$manifest->{support_accounting}{strict_supported_ids}}),
        scalar(grep { $_->{strict_supported} } @entries),
        'manifest strict-supported ids follow the corpus',
    );

    my ($strict_infix_entry) = grep { $_->{id} eq 'legacy.infix_assignment.strict_rejection' }
        @{$manifest->{support_accounting}{catalog_entries}};
    is(
        $strict_infix_entry->{diagnostic_code},
        'FSMGEN_STRICT_INFIX_ASSIGNMENT',
        'manifest exposes stable diagnostic codes on expected-failure catalog entries',
    );
};

subtest 'manifest exposes the stable diagnostic-code registry' => sub {
    is(
        $manifest->{diagnostics}{registry_source},
        'FSM::Support::DiagnosticCodes',
        'manifest records the production diagnostic-code owner',
    );
    is(
        scalar(@{$manifest->{diagnostics}{stable_codes}}),
        scalar(@diagnostic_codes),
        'manifest stable diagnostic-code count follows the registry',
    );

    my %stable_codes = map { $_->{code} => $_ } @{$manifest->{diagnostics}{stable_codes}};
    ok($stable_codes{FSMGEN_STRICT_INFIX_ASSIGNMENT}, 'manifest includes the strict infix-assignment diagnostic code');
    is(
        $stable_codes{FSMGEN_STRICT_INFIX_ASSIGNMENT}{severity},
        'error',
        'manifest diagnostic-code entries carry severity metadata',
    );
    is(
        $stable_codes{FSMGEN_STRICT_INFIX_ASSIGNMENT}{stability},
        'stable',
        'manifest diagnostic-code entries carry stability metadata',
    );
    is(
        $manifest->{diagnostics}{stable_code_registry}{schema_version},
        1,
        'manifest records stable-code registry schema version',
    );
    is(
        $manifest->{diagnostics}{stable_code_registry}{status},
        'bounded_public',
        'manifest marks stable-code registry as bounded public',
    );
    is(
        $manifest->{diagnostics}{stable_code_registry}{contract_source},
        'FSM::Support::DiagnosticCodeRegistryContract',
        'manifest records the stable-code registry contract owner',
    );
    is(
        $manifest->{diagnostics}{section_contract}{schema_version},
        1,
        'manifest records diagnostics section contract schema version',
    );
    is(
        $manifest->{diagnostics}{section_contract}{status},
        'bounded_public',
        'manifest marks diagnostics section contract as bounded public',
    );
    is(
        $manifest->{diagnostics}{section_contract}{contract_source},
        'FSM::Support::DiagnosticsContract',
        'manifest records the diagnostics section contract owner',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{section_contract}{public_top_level_presence_keys} || []}) >= 5,
        'manifest advertises bounded diagnostics section top-level key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{section_contract}{stable_code_entry_presence_keys} || []}) >= 5,
        'manifest advertises bounded diagnostics stable-code entry key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{stable_code_registry}{public_sibling_keys} || []}) >= 3,
        'manifest advertises bounded stable-code registry sibling keys',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{stable_code_registry}{entry_presence_keys} || []}) >= 5,
        'manifest advertises bounded stable-code registry entry keys',
    );
    is($manifest->{diagnostics}{check_json}{schema_version}, 1, 'manifest records check JSON schema version');
    is($manifest->{diagnostics}{check_json}{status}, 'bounded_public', 'manifest marks check JSON as bounded public');
    ok($manifest->{diagnostics}{check_json}{emits_stable_codes}, 'manifest says check JSON emits stable codes');
    ok(!$manifest->{diagnostics}{check_json}{emits_hdl}, 'manifest says check JSON does not emit HDL');
    ok(
        $manifest->{diagnostics}{check_json}{emits_support_accounting_object},
        'manifest says check JSON emits a support-accounting object',
    );
    ok(
        $manifest->{diagnostics}{check_json}{emits_success_support_accounting_object},
        'manifest says check JSON emits a success support-accounting object',
    );
    is(
        $manifest->{diagnostics}{check_json}{support_accounting_contract_source},
        'FSM::Support::SupportAccountingMatchContract',
        'manifest records the shared check-JSON support-accounting nested-object owner',
    );
    ok(
        $manifest->{diagnostics}{check_json}{supported_smoke_corpus_covered},
        'manifest says check JSON is covered across supported-smoke corpus entries',
    );
    ok(
        $manifest->{diagnostics}{check_json}{strict_supported_corpus_covered},
        'manifest says check JSON is covered across strict-supported corpus entries',
    );
    ok(
        $manifest->{diagnostics}{check_json}{expected_failure_corpus_covered},
        'manifest says check JSON is covered across expected-failure corpus entries',
    );
    is(
        $manifest->{diagnostics}{check_json}{classifier_match_policy},
        'most_specific_expected_error_pattern',
        'manifest records the check JSON classifier match policy',
    );
    is(
        $manifest->{diagnostics}{check_json}{success_match_policy},
        'resolved_source_path_to_non_failure_corpus_entry',
        'manifest records the check JSON success match policy',
    );
    is(
        $manifest->{diagnostics}{check_json}{report_source},
        'FSM::Support::CheckDiagnostics',
        'manifest records the check JSON report owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{command_contract_source},
        'FSM::Support::ReportCommandContract',
        'manifest records the shared check-JSON command nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{result_contract_source},
        'FSM::Support::CheckResultContract',
        'manifest records the check-JSON result nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{failure_diagnostic_contract_source},
        'FSM::Support::CheckFailureDiagnosticContract',
        'manifest records the check-JSON failure diagnostic nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{generated_output_contract_source},
        'FSM::Support::ReportGeneratedOutputContract',
        'manifest records the shared check-JSON generated_output nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{producer_contract_source},
        'FSM::Support::ReportProducerContract',
        'manifest records the shared check-JSON producer nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{source_contract_source},
        'FSM::Support::ReportSourceContract',
        'manifest records the shared check-JSON source nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{contract_source},
        'FSM::Support::CheckDiagnosticsContract',
        'manifest records the check JSON contract owner',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{public_top_level_presence_keys} || []}) >= 7,
        'manifest advertises bounded check JSON top-level key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{command_presence_keys} || []}) >= 4,
        'manifest advertises bounded check JSON command-object key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{generated_output_presence_keys} || []}) >= 1,
        'manifest advertises bounded check JSON generated_output-object key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{producer_presence_keys} || []}) >= 2,
        'manifest advertises bounded check JSON producer-object key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{source_presence_keys} || []}) >= 2,
        'manifest advertises bounded check JSON source-object key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{success_result_presence_keys} || []}) >= 4,
        'manifest advertises bounded check JSON success-result key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{failure_diagnostic_presence_keys} || []}) >= 9,
        'manifest advertises bounded check JSON failure-diagnostic key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{success_support_accounting_presence_keys} || []}) >= 1,
        'manifest advertises bounded check JSON common support-accounting key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{matched_success_support_accounting_presence_keys} || []}) >= 6,
        'manifest advertises bounded check JSON matched success support-accounting key presence',
    );
    ok(
        scalar(@{$manifest->{diagnostics}{check_json}{matched_failure_diagnostic_support_accounting_presence_keys} || []}) >= 6,
        'manifest advertises bounded check JSON matched failure support-accounting key presence',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{schema_version},
        1,
        'manifest records normalized semantic JSON schema version',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{status},
        'bounded_public',
        'manifest marks normalized semantic JSON as bounded public',
    );
    ok(
        !$manifest->{semantic_exports}{normalized_semantic_json}{emits_hdl},
        'manifest says normalized semantic JSON does not emit HDL',
    );
    ok(
        $manifest->{semantic_exports}{normalized_semantic_json}{emits_support_accounting_object},
        'manifest says normalized semantic JSON emits support accounting',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{support_accounting_contract_source},
        'FSM::Support::SupportAccountingMatchContract',
        'manifest records the shared normalized-semantic support-accounting nested-object owner',
    );
    ok(
        $manifest->{semantic_exports}{normalized_semantic_json}{failure_diagnostics_reuse_stable_codes},
        'manifest says normalized semantic JSON reuses stable diagnostic codes on failures',
    );
    ok(
        $manifest->{semantic_exports}{normalized_semantic_json}{supported_smoke_corpus_covered},
        'manifest says normalized semantic JSON is covered across supported-smoke corpus entries',
    );
    ok(
        $manifest->{semantic_exports}{normalized_semantic_json}{strict_supported_corpus_covered},
        'manifest says normalized semantic JSON is covered across strict-supported corpus entries',
    );
    ok(
        $manifest->{semantic_exports}{normalized_semantic_json}{expected_failure_corpus_covered},
        'manifest says normalized semantic JSON is covered across expected-failure corpus entries',
    );
    ok(
        $manifest->{semantic_exports}{normalized_semantic_json}{sanitizes_private_perl_objects},
        'manifest says normalized semantic JSON sanitizes private Perl objects',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{report_source},
        'FSM::Support::NormalizedSemanticReport',
        'manifest records the normalized semantic report owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{command_contract_source},
        'FSM::Support::ReportCommandContract',
        'manifest records the shared normalized-semantic command nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{failure_diagnostic_contract_source},
        'FSM::Support::CheckFailureDiagnosticContract',
        'manifest records the shared normalized-semantic failure diagnostic nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{generated_output_contract_source},
        'FSM::Support::ReportGeneratedOutputContract',
        'manifest records the shared normalized-semantic generated_output nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{composition_contract_source},
        'FSM::Support::NormalizedSemanticCompositionContract',
        'manifest records the normalized-semantic composition nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{explicit_system_contract_source},
        'FSM::Support::NormalizedSemanticExplicitSystemContract',
        'manifest records the normalized-semantic explicit-system-contract nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{signal_analysis_contract_source},
        'FSM::Support::NormalizedSemanticSignalAnalysisContract',
        'manifest records the normalized-semantic signal-analysis nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{forward_ir_contract_source},
        'FSM::Support::NormalizedSemanticForwardIRContract',
        'manifest records the normalized-semantic forward-IR nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{module_contract_source},
        'FSM::Support::NormalizedSemanticModuleContract',
        'manifest records the normalized-semantic module nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{semantic_contract_source},
        'FSM::Support::NormalizedSemanticPayloadContract',
        'manifest records the normalized-semantic success payload owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{system_contract_source},
        'FSM::Support::NormalizedSemanticSystemContract',
        'manifest records the normalized-semantic system-contract nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{symbol_contract_source},
        'FSM::Support::NormalizedSemanticSymbolContract',
        'manifest records the normalized-semantic symbol-contract nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{producer_contract_source},
        'FSM::Support::ReportProducerContract',
        'manifest records the shared normalized-semantic producer nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{source_contract_source},
        'FSM::Support::ReportSourceContract',
        'manifest records the shared normalized-semantic source nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{contract_source},
        'FSM::Support::NormalizedSemanticReportContract',
        'manifest records the normalized semantic report contract owner',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{public_top_level_presence_keys} || []}) >= 8,
        'manifest advertises bounded normalized semantic top-level key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{command_presence_keys} || []}) >= 4,
        'manifest advertises bounded normalized semantic command-object key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{generated_output_presence_keys} || []}) >= 1,
        'manifest advertises bounded normalized semantic generated_output-object key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{producer_presence_keys} || []}) >= 2,
        'manifest advertises bounded normalized semantic producer-object common key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{producer_extra_presence_keys} || []}) >= 1,
        'manifest advertises bounded normalized semantic producer-object extra key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{source_presence_keys} || []}) >= 2,
        'manifest advertises bounded normalized semantic source-object key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{success_semantic_presence_keys} || []}) >= 5,
        'manifest advertises bounded normalized semantic success payload key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{support_accounting_presence_keys} || []}) >= 1,
        'manifest advertises bounded normalized semantic common support-accounting key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{matched_success_support_accounting_presence_keys} || []}) >= 6,
        'manifest advertises bounded normalized semantic matched success support-accounting key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{matched_failure_support_accounting_presence_keys} || []}) >= 6,
        'manifest advertises bounded normalized semantic matched failure support-accounting key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{success_signal_analysis_entry_presence_keys} || []}) >= 4,
        'manifest advertises bounded normalized semantic signal-analysis entry key presence',
    );
    ok(
        !$manifest->{semantic_exports}{normalized_semantic_json}{full_export_stable},
        'manifest keeps full normalized semantic export stabilization separate from the bounded slice',
    );
    is(
        $manifest->{semantic_exports}{section_contract}{schema_version},
        1,
        'manifest records semantic-exports section contract schema version',
    );
    is(
        $manifest->{semantic_exports}{section_contract}{status},
        'bounded_public',
        'manifest marks semantic-exports section contract as bounded public',
    );
    is(
        $manifest->{semantic_exports}{section_contract}{contract_source},
        'FSM::Support::SemanticExportsContract',
        'manifest records the semantic-exports section contract owner',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{section_contract}{public_top_level_presence_keys} || []}) >= 2,
        'manifest advertises bounded semantic-exports top-level key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{section_contract}{nested_contract_keys} || []}) >= 1,
        'manifest advertises bounded semantic-exports nested-contract key presence',
    );
    is(
        $manifest->{backend_validation}{systemverilog_external}{schema_version},
        1,
        'manifest records external SystemVerilog validation schema version',
    );
    is(
        $manifest->{backend_validation}{systemverilog_external}{status},
        'optional_when_tools_installed',
        'manifest marks external SystemVerilog validation as optional when tools are installed',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{tools},
        [qw(verilator yosys)],
        'manifest records Verilator and Yosys as the external validation tools',
    );
    is(
        $manifest->{backend_validation}{systemverilog_external}{yosys_stage},
        'read_verilog_sv_noautowire_synth_noabc_stat',
        'manifest records the ABC-free Yosys structural synthesis stage',
    );
    ok(
        !$manifest->{backend_validation}{systemverilog_external}{yosys_abc_enabled},
        'manifest records that the Yosys ABC algorithm is disabled',
    );
    is(
        $manifest->{backend_validation}{systemverilog_external}{report_source},
        'FSM::Support::HDLExternalValidation',
        'manifest records the external HDL validation owner',
    );
    is(
        $manifest->{backend_validation}{systemverilog_external}{contract_source},
        'FSM::Support::HDLExternalValidationContract',
        'manifest records the external HDL validation contract owner',
    );
    ok(
        scalar(@{$manifest->{backend_validation}{systemverilog_external}{success_top_level_presence_keys} || []}) >= 4,
        'manifest advertises bounded external validation success top-level key presence',
    );
    ok(
        scalar(@{$manifest->{backend_validation}{systemverilog_external}{success_step_presence_keys} || []}) >= 4,
        'manifest advertises bounded external validation step key presence',
    );
    is(
        $manifest->{backend_validation}{section_contract}{schema_version},
        1,
        'manifest records backend-validation section contract schema version',
    );
    is(
        $manifest->{backend_validation}{section_contract}{status},
        'bounded_public',
        'manifest marks backend-validation section contract as bounded public',
    );
    is(
        $manifest->{backend_validation}{section_contract}{contract_source},
        'FSM::Support::BackendValidationContract',
        'manifest records the backend-validation section contract owner',
    );
    ok(
        scalar(@{$manifest->{backend_validation}{section_contract}{public_top_level_presence_keys} || []}) >= 2,
        'manifest advertises bounded backend-validation top-level key presence',
    );
    ok(
        scalar(@{$manifest->{backend_validation}{section_contract}{nested_contract_keys} || []}) >= 1,
        'manifest advertises bounded backend-validation nested-contract key presence',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{schema_version},
        1,
        'manifest records HDLGenerator result contract schema version',
    );
    is(
        $manifest->{embedding}{section_contract}{schema_version},
        1,
        'manifest records embedding section contract schema version',
    );
    is(
        $manifest->{embedding}{section_contract}{status},
        'bounded_public',
        'manifest marks embedding section contract as bounded public',
    );
    is(
        $manifest->{embedding}{section_contract}{contract_source},
        'FSM::Support::EmbeddingContract',
        'manifest records the embedding section contract owner',
    );
    ok(
        scalar(@{$manifest->{embedding}{section_contract}{public_top_level_presence_keys} || []}) >= 4,
        'manifest advertises bounded embedding top-level key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{section_contract}{nested_contract_keys} || []}) >= 3,
        'manifest advertises bounded embedding nested-contract key presence',
    );
    is(
        $manifest->{embedding}{composition_report}{schema_version},
        1,
        'manifest records composition report contract schema version',
    );
    is(
        $manifest->{embedding}{composition_report}{status},
        'bounded_public_json_fragment',
        'manifest marks composition report as a bounded JSON fragment',
    );
    ok(
        !$manifest->{embedding}{composition_report}{raw_report_json_safe},
        'manifest says raw composition_report is not JSON-safe',
    );
    ok(
        $manifest->{embedding}{composition_report}{sanitized_report_json_safe},
        'manifest says sanitized composition report is JSON-safe',
    );
    is(
        $manifest->{embedding}{composition_report}{contract_source},
        'FSM::Support::CompositionReportContract',
        'manifest records the composition report contract owner',
    );
    is(
        $manifest->{embedding}{composition_report}{json_fragment_path},
        'semantic_exports.normalized_semantic_json.semantic.composition.provenance_report',
        'manifest records where the sanitized composition report is exported',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{status},
        'bounded_top_level_presence',
        'manifest marks HDLGenerator result contract as bounded top-level presence',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_result}{full_result_json_safe},
        'manifest says the raw HDLGenerator result is not JSON-safe as a whole',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{nested_identity_slices_advertised},
        'manifest says the HDLGenerator result advertises bounded nested identity slices',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{json_safe_export_surface},
        'semantic_exports.normalized_semantic_json',
        'manifest points JSON consumers at normalized semantic JSON',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{contract_source},
        'FSM::Support::HDLGeneratorResultContract',
        'manifest records the HDLGenerator result contract owner',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{source_info_identity_presence_keys} || []}) >= 2,
        'manifest advertises bounded HDLGenerator source_info identity key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{module_info_identity_presence_keys} || []}) >= 2,
        'manifest advertises bounded HDLGenerator module_info identity key presence',
    );
    is(
        $manifest->{embedding}{typed_extensions}{schema_version},
        1,
        'manifest records typed extension contract schema version',
    );
    is(
        $manifest->{embedding}{typed_extensions}{status},
        'bounded_public',
        'manifest marks typed extension contract as bounded public',
    );
    is(
        $manifest->{embedding}{typed_extensions}{contract_source},
        'FSM::Support::ExtensionContract',
        'manifest records the typed extension contract owner',
    );
    my %extension_hooks = map { $_ => 1 } @{$manifest->{embedding}{typed_extensions}{hook_names}};
    ok($extension_hooks{after_parse_source}, 'manifest advertises the parse-source extension hook');
    ok($extension_hooks{after_generate_result}, 'manifest advertises the result extension hook');
    ok(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{must_be_blessed_object},
        'manifest records the typed extension object boundary',
    );
    ok(
        !$manifest->{embedding}{typed_extensions}{extension_object_contract}{legacy_plg_discovery},
        'manifest records that legacy .plg discovery is not part of typed extensions',
    );
    ok(
        scalar(@{$manifest->{manifest_contract}{diagnostics_presence_keys} || []}) >= 4,
        'manifest advertises bounded diagnostics section key presence',
    );
    ok(
        scalar(@{$manifest->{manifest_contract}{language_surface_presence_keys} || []}) >= 8,
        'manifest advertises bounded language-surface section key presence',
    );
    ok(
        scalar(@{$manifest->{manifest_contract}{documentation_presence_keys} || []}) >= 3,
        'manifest advertises bounded documentation section key presence',
    );
};

subtest 'manifest captures the first downstream tool contract surface' => sub {
    ok($manifest->{language_surface}{strict_mode}{intended_for_generated_fsm}, 'strict mode is marked as the generated-FSM target');
    ok(!$manifest->{language_surface}{strict_mode}{compatibility_syntax_is_canonical}, 'compatibility syntax is not canonical');

    my %direct_roots = map { $_ => 1 } @{$manifest->{language_surface}{strict_mode}{canonical_direct_roots}};
    ok($direct_roots{'?fsm'}, 'manifest names ?fsm as a canonical direct root');
    ok($direct_roots{'?dt'}, 'manifest names ?dt as a canonical direct root');
    ok(
        scalar(@{$manifest->{language_surface}{surface_contract}{public_top_level_presence_keys} || []}) >= 9,
        'manifest advertises bounded language-surface top-level key presence',
    );
    ok(
        scalar(@{$manifest->{language_surface}{surface_contract}{strict_mode_presence_keys} || []}) >= 5,
        'manifest advertises bounded strict-mode language-surface key presence',
    );
    is(
        $manifest->{language_surface}{surface_contract}{schema_version},
        1,
        'manifest records language-surface contract schema version',
    );
    is(
        $manifest->{language_surface}{surface_contract}{status},
        'bounded_public',
        'manifest marks the language-surface section as bounded public',
    );
    is(
        $manifest->{language_surface}{surface_contract}{contract_source},
        'FSM::Support::LanguageSurfaceContract',
        'manifest records the language-surface contract owner',
    );
    ok(
        scalar(@{$manifest->{documentation}{section_contract}{public_top_level_presence_keys} || []}) >= 3,
        'manifest advertises bounded documentation top-level key presence',
    );
    ok(
        scalar(@{$manifest->{documentation}{section_contract}{path_list_keys} || []}) >= 2,
        'manifest advertises bounded documentation path-list keys',
    );
    is(
        $manifest->{documentation}{section_contract}{schema_version},
        1,
        'manifest records documentation contract schema version',
    );
    is(
        $manifest->{documentation}{section_contract}{status},
        'bounded_public',
        'manifest marks the documentation section as bounded public',
    );
    is(
        $manifest->{documentation}{section_contract}{contract_source},
        'FSM::Support::DocumentationContract',
        'manifest records the documentation contract owner',
    );

    my %literal_families = map { $_ => 1 } @{$manifest->{language_surface}{expressions}{literal_families}};
    ok(
        $literal_families{q{FSMGen intent-sized literals like 5'23, 8'-10, 8'-0xA, 8'-0b1010, and 20'x1}},
        'manifest advertises intent-level sized literal normalization',
    );

    my %human_contract_docs = map { $_ => 1 } @{$manifest->{documentation}{human_contract} || []};
    ok($human_contract_docs{'docs/book/src/SUMMARY.md'}, 'manifest points human readers at the book summary');
    ok($human_contract_docs{'docs/USER_GUIDE.md'}, 'manifest points human readers at the live user guide');

    my %blocked = map { $_ => 1 } @{$manifest->{language_surface}{intentionally_blocked_or_not_yet_public}};
    ok($blocked{'full check-only JSON diagnostic schema stabilization'}, 'manifest keeps full JSON diagnostic API stabilization blocked');
    ok(
        $blocked{'full normalized semantic JSON export beyond the bounded public semantic JSON slice'},
        'manifest tells downstream tools that broader normalized JSON export is not stable yet',
    );
};

subtest 'CLI emits the same valid JSON manifest without an input file' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'CLI capability manifest command succeeds without an input source');
    is(join('', @{$stderr_buf || []}), '', 'CLI capability manifest command does not print stderr');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    is($decoded->{manifest_schema_version}, 1, 'CLI manifest JSON decodes with schema version');
    is($decoded->{support_accounting}{entry_count}, scalar(@entries), 'CLI manifest JSON uses corpus entry count');
    is($decoded->{support_accounting}{source}, 'FSM::Support::RegressionCorpus', 'CLI manifest JSON records the corpus owner');

    my ($alias_success, $alias_error, $alias_full, $alias_stdout, $alias_stderr) = run(
        command => ['./bin/fsmgen', '--emit-capability-manifest'],
    );
    ok($alias_success, 'CLI manifest alias succeeds without an input source');
    my $alias_decoded = decode_json(join('', @{$alias_stdout || []}));
    is($alias_decoded->{manifest_schema_version}, 1, 'CLI manifest alias emits valid manifest JSON');
};

done_testing();
