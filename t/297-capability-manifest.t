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
use FSM::Support::CapabilityManifestContract qw(
    capability_manifest_contract_source
    capability_manifest_presence_key_family_map
    capability_manifest_top_level_contract_source_map
    capability_manifest_top_level_section_presence_key_map
);
use FSM::Support::CheckFailureDiagnosticContract qw(
    check_failure_diagnostic_contract_source
);
use FSM::Support::CheckDiagnosticsContract qw(
    check_diagnostics_contract_source
    check_json_nested_presence_key_map
    check_json_presence_key_family_map
    check_json_public_top_level_keys
);
use FSM::Support::CheckResultContract qw(
    check_result_contract_source
);
use FSM::Support::CompositionReportContract qw(
    composition_report_collection_keys
    composition_report_contract_source
    composition_report_count_map_keys
    composition_report_example_map_keys
    composition_report_json_fragment_path
    composition_report_ordered_list_keys
    composition_report_presence_key_family_map
    composition_report_summary_keys
);
use FSM::Support::DebugRuntimeContract qw(
    debug_runtime_contract_source
    debug_runtime_family_map
    debug_runtime_named_trace_verbosity_values
    debug_runtime_public_top_level_keys
    debug_runtime_snapshot_state_keys
);
use FSM::Support::ExtensionContract qw(
    extension_contract_context_accessors
    extension_contract_loader_constructor_option_names
    extension_contract_loader_method_names
    extension_contract_name_family_map
    extension_contract_registry_constructor_option_names
    extension_contract_registry_method_names
    extension_contract_source
);
use FSM::Support::HDLGeneratorFacadeContract qw(
    hdl_generator_facade_constructor_option_family_map
    hdl_generator_facade_contract_source
    hdl_generator_facade_default_generation_mode
    hdl_generator_facade_generation_mode_names
    hdl_generator_facade_method_names
    hdl_generator_facade_public_constructor_option_names
    hdl_generator_facade_public_top_level_keys
    hdl_generator_facade_structured_nonflattened_generation_status
);
use FSM::Support::HDLExternalValidationContract qw(
    hdl_external_validation_abc_mapping_status
    hdl_external_validation_abc_mapping_success_step_names
    hdl_external_validation_optional_tool_names
    hdl_external_validation_required_tool_names
    hdl_external_validation_contract_source
    hdl_external_validation_failure_mode_family_map
    hdl_external_validation_failure_mode_names
    hdl_external_validation_failure_text_prefix_map
    hdl_external_validation_success_presence_key_family_map
);
use FSM::Support::HDLGeneratorCompositionPlanContract qw(
    hdl_generator_composition_plan_contract_source
    hdl_generator_composition_plan_fallback_surface_map
);
use FSM::Support::HDLGeneratorCompositionSpecContract qw(
    hdl_generator_composition_spec_contract_source
    hdl_generator_composition_spec_fallback_surface_map
);
use FSM::Support::HDLGeneratorFSMModuleContract qw(
    hdl_generator_fsm_module_contract_source
    hdl_generator_fsm_module_fallback_surface_map
);
use FSM::Support::HDLGeneratorModuleInfoContract qw(
    hdl_generator_module_info_contract_source
);
use FSM::Support::HDLGeneratorRawASTContract qw(
    hdl_generator_raw_ast_contract_source
    hdl_generator_raw_ast_fallback_surface_map
);
use FSM::Support::HDLGeneratorResolvedPackageImportsContract qw(
    hdl_generator_resolved_package_imports_contract_source
    hdl_generator_resolved_package_imports_fallback_surface_map
);
use FSM::Support::HDLGeneratorSourceInfoContract qw(
    hdl_generator_source_info_contract_source
);
use FSM::Support::HDLGeneratorStatisticsContract qw(
    hdl_generator_statistics_contract_source
);
use FSM::Support::HDLGeneratorResultContract qw(
    hdl_generator_result_contract_source
    hdl_generator_result_shell_only_fallback_surface_family_map
    hdl_generator_result_shell_only_fallback_surface_map
    hdl_generator_result_stable_subsurface_map
    hdl_generator_result_optional_composition_key_family_map
    hdl_generator_result_semantic_layer_presence_key_family_map
);
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_contract_source
    isf_public_interface_parser_method_names
    isf_public_interface_public_top_level_keys
    isf_public_interface_schedule_report_presence_key_family_map
    isf_public_interface_schedule_report_top_level_keys
    isf_public_interface_scheduler_method_names
);
use FSM::Support::DiagnosticCodes qw(diagnostic_code_ids);
use FSM::Support::DiagnosticCodeRegistryContract qw(
    diagnostic_code_registry_contract_source
    diagnostic_code_registry_public_keys
);
use FSM::Support::BackendValidationContract qw(
    backend_validation_contract_source
    backend_validation_nested_presence_key_map
);
use FSM::Support::EmbeddingContract qw(
    embedding_contract_source
    embedding_nested_presence_key_map
);
use FSM::Support::NormalizedSemanticForwardIRContract qw(
    normalized_semantic_forward_ir_contract_source
    normalized_semantic_forward_ir_intent_hir_contract_source
    normalized_semantic_forward_ir_lowered_rtl_ir_contract_source
    normalized_semantic_forward_ir_structural_rtl_ir_contract_source
);
use FSM::Support::NormalizedSemanticCompositionContract qw(
    normalized_semantic_composition_contract_source
);
use FSM::Support::NormalizedSemanticExplicitSystemContract qw(
    normalized_semantic_explicit_system_contract_source
);
use FSM::Support::NormalizedSemanticIntentHIRContract qw(
    normalized_semantic_intent_hir_contract_source
);
use FSM::Support::NormalizedSemanticLoweredRTLIRContract qw(
    normalized_semantic_lowered_rtl_ir_contract_source
);
use FSM::Support::NormalizedSemanticModuleContract qw(
    normalized_semantic_module_contract_source
);
use FSM::Support::NormalizedSemanticPayloadContract qw(
    normalized_semantic_payload_contract_source
    normalized_semantic_payload_forward_ir_nested_contract_source_map
    normalized_semantic_payload_forward_ir_nested_presence_key_map
    normalized_semantic_payload_nested_presence_key_map
    normalized_semantic_payload_optional_child_presence_keys
);
use FSM::Support::NormalizedSemanticReportContract qw(
    normalized_semantic_composition_child_entry_keys
    normalized_semantic_composition_child_parameter_override_entry_keys
    normalized_semantic_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_generated_child_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_assertion_keys
    normalized_semantic_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_composition_standalone_dt_child_entry_keys
    normalized_semantic_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds
    normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys
    normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds
    normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning
    normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_net_source_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_net_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_source_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_source_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_target_entry_keys
    normalized_semantic_forward_ir_structural_rtl_ir_port_target_extension_keys
    normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys
    normalized_semantic_nested_presence_key_map
    normalized_semantic_presence_key_family_map
    normalized_semantic_report_contract_source
    normalized_semantic_symbol_contract_constant_list_value_extension_keys
    normalized_semantic_symbol_contract_constant_scalar_value_extension_keys
    normalized_semantic_symbol_contract_constant_value_entry_keys
    normalized_semantic_symbol_contract_enum_entry_value_kinds
    normalized_semantic_symbol_contract_enum_member_value_kinds
    normalized_semantic_symbol_contract_package_import_entry_value_kinds
    normalized_semantic_symbol_contract_package_import_entry_value_meaning
    normalized_semantic_symbol_contract_type_aggregate_value_kinds
    normalized_semantic_symbol_contract_type_entry_keys
    normalized_semantic_symbol_contract_type_list_extension_keys
    normalized_semantic_symbol_contract_type_record_extension_keys
    normalized_semantic_symbol_contract_type_scalar_value_kinds
    normalized_semantic_symbol_contract_type_state_model_extension_keys
    normalized_semantic_success_semantic_optional_child_presence_keys
);
use FSM::Support::NormalizedSemanticSignalAnalysisContract qw(
    normalized_semantic_signal_analysis_contract_source
);
use FSM::Support::NormalizedSemanticStructuralRTLIRContract qw(
    normalized_semantic_structural_rtl_ir_contract_source
);
use FSM::Support::NormalizedSemanticSystemContract qw(
    normalized_semantic_system_contract_source
);
use FSM::Support::NormalizedSemanticSymbolContract qw(
    normalized_semantic_symbol_contract_source
);
use FSM::Support::DocumentationContract qw(
    documentation_contract_source
    documentation_path_list_contract_map
);
use FSM::Support::DiagnosticsContract qw(
    diagnostics_contract_source
    diagnostics_presence_key_family_map
);
use FSM::Support::LanguageSurfaceContract qw(
    language_surface_contract_source
    language_surface_file_surface_entry_keys
    language_surface_nested_presence_key_map
);
use FSM::Support::ProducerContract qw(
    producer_contract_source
    producer_presence_key_family_map
);
use FSM::Support::SemanticExportsContract qw(
    semantic_exports_contract_source
    semantic_exports_nested_presence_key_map
);
use FSM::Support::ReportCommandContract qw(
    report_command_contract_source
);
use FSM::Support::ReportGeneratedOutputContract qw(
    report_generated_output_contract_source
);
use FSM::Support::SerializableGenerationResultSnapshot qw(
    build_serializable_generation_result_snapshot_contract
    serializable_generation_result_snapshot_contract_source
    serializable_generation_result_snapshot_public_top_level_keys
);
use FSM::Support::SerializableDiagnosticSummary qw(
    serializable_diagnostic_summary_contract_source
);
use FSM::Support::ReportProducerContract qw(
    report_producer_contract_source
);
use FSM::Support::ReportSourceContract qw(
    report_source_contract_source
);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::SupportAccountingMatchContract qw(
    support_accounting_match_contract_source
);
use FSM::Support::SupportAccountingContract qw(
    support_accounting_contract_source
    support_accounting_presence_key_family_map
);
use FSM::Support::VerificationOutputsContract qw(
    verification_outputs_contract_source
    verification_outputs_presence_key_family_map
    verification_outputs_target_entry_keys
);

my @entries = regression_corpus_entries();
my @diagnostic_codes = diagnostic_code_ids();
my $manifest = build_capability_manifest();

subtest 'module manifest is generated from support accounting' => sub {
    is($manifest->{manifest_schema_version}, 1, 'manifest exposes its schema version');
    is($manifest->{manifest_contract}{schema_version}, 1, 'manifest exposes top-level manifest contract schema version');
    is($manifest->{manifest_contract}{status}, 'bounded_public', 'manifest marks the top-level manifest shell as bounded public');
    is(
        $manifest->{manifest_contract}{contract_source},
        capability_manifest_contract_source(),
        'manifest records the top-level manifest contract owner',
    );
    ok(
        scalar(@{$manifest->{manifest_contract}{public_top_level_presence_keys} || []}) >= 10,
        'manifest advertises bounded top-level manifest key presence',
    );
    is_deeply(
        $manifest->{manifest_contract}{top_level_contract_source_map},
        capability_manifest_top_level_contract_source_map(),
        'manifest advertises the grouped top-level section ownership map',
    );
    is_deeply(
        $manifest->{manifest_contract}{top_level_section_presence_key_map},
        capability_manifest_top_level_section_presence_key_map(),
        'manifest advertises the grouped top-level section key-family map',
    );
    is_deeply(
        $manifest->{manifest_contract}{presence_key_family_map},
        capability_manifest_presence_key_family_map(),
        'manifest advertises the grouped manifest-owned presence-key family map',
    );
    assert_manifest_section_contract_sources(
        $manifest,
        capability_manifest_top_level_contract_source_map(),
        'manifest',
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
        producer_contract_source(),
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
    is_deeply(
        $manifest->{producer}{section_contract}{presence_key_family_map},
        producer_presence_key_family_map(),
        'manifest records the grouped producer key-family map through the producer section contract',
    );
    is($manifest->{support_accounting}{schema_version}, 1, 'manifest records support-accounting schema version');
    is($manifest->{support_accounting}{status}, 'bounded_public', 'manifest marks support accounting as bounded public');
    is(
        $manifest->{support_accounting}{contract_source},
        support_accounting_contract_source(),
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
        support_accounting_contract_source(),
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
    is_deeply(
        $manifest->{support_accounting}{section_contract}{presence_key_family_map},
        support_accounting_presence_key_family_map(),
        'manifest records the grouped support-accounting key-family map through the support-accounting section contract',
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
    ok($stable_codes{FSMGEN_STRICT_LEGACY_LTEPLUS_ASSIGNMENT}, 'manifest includes the strict legacy <=+ diagnostic code');
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
        diagnostic_code_registry_contract_source(),
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
        diagnostics_contract_source(),
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
    is(
        $manifest->{diagnostics}{section_contract}{nested_contract_source_map}{stable_code_registry},
        diagnostic_code_registry_contract_source(),
        'manifest records the diagnostics stable-code registry nested contract owner',
    );
    is(
        $manifest->{diagnostics}{section_contract}{nested_contract_source_map}{check_json},
        check_diagnostics_contract_source(),
        'manifest records the diagnostics check-json nested contract owner',
    );
    is_deeply(
        $manifest->{diagnostics}{section_contract}{nested_presence_key_map},
        {
            stable_code_registry => diagnostic_code_registry_public_keys(),
            check_json => check_json_public_top_level_keys(),
        },
        'manifest records the grouped diagnostics child key-family map through the diagnostics section contract',
    );
    is_deeply(
        $manifest->{diagnostics}{section_contract}{presence_key_family_map},
        diagnostics_presence_key_family_map(),
        'manifest records the grouped diagnostics-owned key-family map through the diagnostics section contract',
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
        support_accounting_match_contract_source(),
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
        $manifest->{diagnostics}{check_json}{nested_contract_source_map}{command},
        report_command_contract_source(),
        'manifest records the check-json command nested contract owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{nested_contract_source_map}{diagnostic_summary},
        serializable_diagnostic_summary_contract_source(),
        'manifest records the check-json diagnostic summary owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{nested_contract_source_map}{result},
        check_result_contract_source(),
        'manifest records the check-json result nested contract owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{nested_contract_source_map}{failure_diagnostic},
        check_failure_diagnostic_contract_source(),
        'manifest records the check-json failure diagnostic nested contract owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{nested_contract_source_map}{generated_output},
        report_generated_output_contract_source(),
        'manifest records the check-json generated_output nested contract owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{nested_contract_source_map}{producer},
        report_producer_contract_source(),
        'manifest records the check-json producer nested contract owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{nested_contract_source_map}{source},
        report_source_contract_source(),
        'manifest records the check-json source nested contract owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{nested_contract_source_map}{support_accounting},
        support_accounting_match_contract_source(),
        'manifest records the check-json support-accounting nested contract owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{command_contract_source},
        report_command_contract_source(),
        'manifest records the shared check-JSON command nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{diagnostic_summary_contract_source},
        serializable_diagnostic_summary_contract_source(),
        'manifest records the shared check-JSON diagnostic summary owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{result_contract_source},
        check_result_contract_source(),
        'manifest records the check-JSON result nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{failure_diagnostic_contract_source},
        check_failure_diagnostic_contract_source(),
        'manifest records the check-JSON failure diagnostic nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{generated_output_contract_source},
        report_generated_output_contract_source(),
        'manifest records the shared check-JSON generated_output nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{producer_contract_source},
        report_producer_contract_source(),
        'manifest records the shared check-JSON producer nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{source_contract_source},
        report_source_contract_source(),
        'manifest records the shared check-JSON source nested-object owner',
    );
    is(
        $manifest->{diagnostics}{check_json}{contract_source},
        check_diagnostics_contract_source(),
        'manifest records the check JSON contract owner',
    );
    is_deeply(
        $manifest->{diagnostics}{check_json}{nested_presence_key_map},
        check_json_nested_presence_key_map(),
        'manifest records the grouped check-json nested key-family map',
    );
    is_deeply(
        $manifest->{diagnostics}{check_json}{presence_key_family_map},
        check_json_presence_key_family_map(),
        'manifest records the grouped check-json shell-owned key-family map',
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
        support_accounting_match_contract_source(),
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
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{nested_contract_source_map},
        {
            command => report_command_contract_source(),
            failure_diagnostic => check_failure_diagnostic_contract_source(),
            diagnostic_summary => serializable_diagnostic_summary_contract_source(),
            generated_output => report_generated_output_contract_source(),
            generation_result_snapshot => serializable_generation_result_snapshot_contract_source(),
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
        'manifest records the normalized semantic nested-contract ownership map',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{command_contract_source},
        report_command_contract_source(),
        'manifest records the shared normalized-semantic command nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{failure_diagnostic_contract_source},
        check_failure_diagnostic_contract_source(),
        'manifest records the shared normalized-semantic failure diagnostic nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{diagnostic_summary_contract_source},
        serializable_diagnostic_summary_contract_source(),
        'manifest records the normalized-semantic diagnostic summary owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{generated_output_contract_source},
        report_generated_output_contract_source(),
        'manifest records the shared normalized-semantic generated_output nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{generation_result_snapshot_contract_source},
        serializable_generation_result_snapshot_contract_source(),
        'manifest records the normalized-semantic generation-result snapshot owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{composition_contract_source},
        normalized_semantic_composition_contract_source(),
        'manifest records the normalized-semantic composition nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{explicit_system_contract_source},
        normalized_semantic_explicit_system_contract_source(),
        'manifest records the normalized-semantic explicit-system-contract nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{signal_analysis_contract_source},
        normalized_semantic_signal_analysis_contract_source(),
        'manifest records the normalized-semantic signal-analysis nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{forward_ir_contract_source},
        normalized_semantic_forward_ir_contract_source(),
        'manifest records the normalized-semantic forward-IR nested-object owner',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{forward_ir_nested_contract_source_map},
        normalized_semantic_payload_forward_ir_nested_contract_source_map(),
        'manifest records the grouped normalized-semantic forward-ir child-owner map',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{forward_ir_nested_presence_key_map},
        normalized_semantic_payload_forward_ir_nested_presence_key_map(),
        'manifest records the grouped normalized-semantic forward-ir child key-family map',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{semantic_nested_presence_key_map},
        normalized_semantic_payload_nested_presence_key_map(),
        'manifest records the grouped normalized-semantic semantic-child key-family map',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{semantic_presence_key_family_map}{optional_child_presence_keys},
        normalized_semantic_payload_optional_child_presence_keys(),
        'manifest records optional normalized-semantic child keys in the semantic family map',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{nested_presence_key_map},
        normalized_semantic_nested_presence_key_map(),
        'manifest records the grouped normalized-semantic nested key-family map',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map},
        normalized_semantic_presence_key_family_map(),
        'manifest records the grouped normalized-semantic shell-owned key-family map',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{forward_ir_intent_hir_contract_source},
        normalized_semantic_forward_ir_intent_hir_contract_source(),
        'manifest records the normalized-semantic forward-ir intent-hir nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{forward_ir_lowered_rtl_ir_contract_source},
        normalized_semantic_forward_ir_lowered_rtl_ir_contract_source(),
        'manifest records the normalized-semantic forward-ir lowered-rtl-ir nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{forward_ir_structural_rtl_ir_contract_source},
        normalized_semantic_forward_ir_structural_rtl_ir_contract_source(),
        'manifest records the normalized-semantic forward-ir structural-rtl-ir nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{module_contract_source},
        normalized_semantic_module_contract_source(),
        'manifest records the normalized-semantic module nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{semantic_contract_source},
        normalized_semantic_payload_contract_source(),
        'manifest records the normalized-semantic success payload owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{system_contract_source},
        normalized_semantic_system_contract_source(),
        'manifest records the normalized-semantic system-contract nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{symbol_contract_source},
        normalized_semantic_symbol_contract_source(),
        'manifest records the normalized-semantic symbol-contract nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{producer_contract_source},
        report_producer_contract_source(),
        'manifest records the shared normalized-semantic producer nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{source_contract_source},
        report_source_contract_source(),
        'manifest records the shared normalized-semantic source nested-object owner',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{contract_source},
        normalized_semantic_report_contract_source(),
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
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_semantic_optional_child_presence_keys},
        normalized_semantic_success_semantic_optional_child_presence_keys(),
        'manifest advertises optional normalized semantic success payload child keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{success_semantic_optional_child_presence_keys},
        normalized_semantic_success_semantic_optional_child_presence_keys(),
        'manifest records optional semantic child keys in the report family map',
    );
    for my $case (
        [
            'symbol_contract_constant_value_entry_keys',
            normalized_semantic_symbol_contract_constant_value_entry_keys(),
            'symbol-contract constant value core keys',
        ],
        [
            'symbol_contract_constant_scalar_value_extension_keys',
            normalized_semantic_symbol_contract_constant_scalar_value_extension_keys(),
            'symbol-contract scalar constant value extension keys',
        ],
        [
            'symbol_contract_constant_list_value_extension_keys',
            normalized_semantic_symbol_contract_constant_list_value_extension_keys(),
            'symbol-contract list constant value extension keys',
        ],
        [
            'symbol_contract_enum_entry_value_kinds',
            normalized_semantic_symbol_contract_enum_entry_value_kinds(),
            'symbol-contract enum entry value kinds',
        ],
        [
            'symbol_contract_enum_member_value_kinds',
            normalized_semantic_symbol_contract_enum_member_value_kinds(),
            'symbol-contract enum member value kinds',
        ],
        [
            'symbol_contract_package_import_entry_value_kinds',
            normalized_semantic_symbol_contract_package_import_entry_value_kinds(),
            'symbol-contract package-import entry value kinds',
        ],
        [
            'symbol_contract_package_import_entry_value_meaning',
            normalized_semantic_symbol_contract_package_import_entry_value_meaning(),
            'symbol-contract package-import entry value meaning',
        ],
        [
            'symbol_contract_type_entry_keys',
            normalized_semantic_symbol_contract_type_entry_keys(),
            'symbol-contract type entry keys',
        ],
        [
            'symbol_contract_type_scalar_value_kinds',
            normalized_semantic_symbol_contract_type_scalar_value_kinds(),
            'symbol-contract scalar type value kinds',
        ],
        [
            'symbol_contract_type_aggregate_value_kinds',
            normalized_semantic_symbol_contract_type_aggregate_value_kinds(),
            'symbol-contract aggregate type value kinds',
        ],
        [
            'symbol_contract_type_state_model_extension_keys',
            normalized_semantic_symbol_contract_type_state_model_extension_keys(),
            'symbol-contract type state-model extension keys',
        ],
        [
            'symbol_contract_type_list_extension_keys',
            normalized_semantic_symbol_contract_type_list_extension_keys(),
            'symbol-contract type list extension keys',
        ],
        [
            'symbol_contract_type_record_extension_keys',
            normalized_semantic_symbol_contract_type_record_extension_keys(),
            'symbol-contract type record extension keys',
        ],
    ) {
        my ($field, $expected, $label) = @{$case};

        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{$field},
            $expected,
            "manifest records exact normalized semantic $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{$field},
            _family_map_expected($field, $expected),
            "manifest report family map records $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{semantic_presence_key_family_map}{$field},
            _family_map_expected($field, $expected),
            "manifest semantic family map records $label",
        );
    }
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{composition_child_entry_keys},
        normalized_semantic_composition_child_entry_keys(),
        'manifest records exact normalized semantic composition child entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{composition_child_entry_keys},
        normalized_semantic_composition_child_entry_keys(),
        'manifest report family map records composition child entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{semantic_presence_key_family_map}{composition_child_entry_keys},
        normalized_semantic_composition_child_entry_keys(),
        'manifest semantic family map records composition child entry keys',
    );
    for my $case (
        [
            'composition_child_parameter_override_entry_keys',
            normalized_semantic_composition_child_parameter_override_entry_keys(),
            'composition child parameter-override core entry keys',
        ],
        [
            'composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_composition_child_parameter_override_raw_value_extension_keys(),
            'composition child parameter-override raw-value extension keys',
        ],
        [
            'composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_composition_child_parameter_override_value_metadata_extension_keys(),
            'composition child parameter-override value-metadata extension keys',
        ],
    ) {
        my ($field, $expected, $label) = @{$case};

        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{$field},
            $expected,
            "manifest records exact normalized semantic $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{$field},
            $expected,
            "manifest report family map records $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{semantic_presence_key_family_map}{$field},
            $expected,
            "manifest semantic family map records $label",
        );
    }
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{composition_generated_child_entry_keys},
        normalized_semantic_composition_generated_child_entry_keys(),
        'manifest records exact normalized semantic composition generated-child entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{composition_generated_child_entry_keys},
        normalized_semantic_composition_generated_child_entry_keys(),
        'manifest report family map records composition generated-child entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{semantic_presence_key_family_map}{composition_generated_child_entry_keys},
        normalized_semantic_composition_generated_child_entry_keys(),
        'manifest semantic family map records composition generated-child entry keys',
    );
    for my $case (
        [
            'composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_composition_generated_child_parameter_override_entry_keys(),
            'composition generated-child parameter-override core entry keys',
        ],
        [
            'composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_composition_generated_child_parameter_override_raw_value_extension_keys(),
            'composition generated-child parameter-override raw-value extension keys',
        ],
        [
            'composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            'composition generated-child parameter-override value-metadata extension keys',
        ],
    ) {
        my ($field, $expected, $label) = @{$case};

        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{$field},
            $expected,
            "manifest records exact normalized semantic $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{$field},
            $expected,
            "manifest report family map records $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{semantic_presence_key_family_map}{$field},
            $expected,
            "manifest semantic family map records $label",
        );
    }
    for my $case (
        [
            'composition_standalone_dt_child_entry_keys',
            normalized_semantic_composition_standalone_dt_child_entry_keys(),
            'composition standalone-DT child entry keys',
        ],
        [
            'composition_standalone_dt_enable_family_entry_keys',
            normalized_semantic_composition_standalone_dt_enable_family_entry_keys(),
            'composition standalone-DT enable-family entry keys',
        ],
        [
            'composition_standalone_dt_module_enable_family_keys',
            normalized_semantic_composition_standalone_dt_module_enable_family_keys(),
            'composition standalone-DT module-enable-family keys',
        ],
        [
            'composition_standalone_dt_multi_drive_target_entry_keys',
            normalized_semantic_composition_standalone_dt_multi_drive_target_entry_keys(),
            'composition standalone-DT multi-drive target entry keys',
        ],
        [
            'composition_standalone_dt_multi_drive_assertion_keys',
            normalized_semantic_composition_standalone_dt_multi_drive_assertion_keys(),
            'composition standalone-DT multi-drive assertion keys',
        ],
    ) {
        my ($field, $expected, $label) = @{$case};

        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{$field},
            $expected,
            "manifest records exact normalized semantic $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{$field},
            $expected,
            "manifest report family map records $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{semantic_presence_key_family_map}{$field},
            $expected,
            "manifest semantic family map records $label",
        );
    }
    for my $case (
        [
            'composition_shared_datapath_candidate_entry_keys',
            normalized_semantic_composition_shared_datapath_candidate_entry_keys(),
            'composition shared-datapath candidate entry keys',
        ],
        [
            'composition_shared_datapath_candidate_declared_type_extension_keys',
            normalized_semantic_composition_shared_datapath_candidate_declared_type_extension_keys(),
            'composition shared-datapath candidate declared-type extension keys',
        ],
        [
            'composition_shared_datapath_candidate_contributor_entry_keys',
            normalized_semantic_composition_shared_datapath_candidate_contributor_entry_keys(),
            'composition shared-datapath contributor entry keys',
        ],
        [
            'composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            normalized_semantic_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
            'composition shared-datapath contributor declared-type extension keys',
        ],
        [
            'composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
            'composition shared-datapath contributor drive-intent entry keys',
        ],
        [
            'composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            normalized_semantic_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
            'composition shared-datapath contributor drive-intent rhs-enable-family entry keys',
        ],
        [
            'composition_shared_datapath_bound_connection_expr_keys',
            normalized_semantic_composition_shared_datapath_bound_connection_expr_keys(),
            'composition shared-datapath bound-connection expression keys',
        ],
        [
            'composition_shared_datapath_aggregate_enable_family_entry_keys',
            normalized_semantic_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            'composition shared-datapath aggregate-enable family entry keys',
        ],
        [
            'composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            normalized_semantic_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
            'composition shared-datapath aggregate-enable contributor entry keys',
        ],
        [
            'composition_shared_datapath_assertion_keys',
            normalized_semantic_composition_shared_datapath_assertion_keys(),
            'composition shared-datapath assertion keys',
        ],
    ) {
        my ($field, $expected, $label) = @{$case};

        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{$field},
            $expected,
            "manifest records exact normalized semantic $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{$field},
            $expected,
            "manifest report family map records $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{semantic_presence_key_family_map}{$field},
            $expected,
            "manifest semantic family map records $label",
        );
    }
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
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_intent_hir_presence_keys} || []}) >= 18,
        'manifest advertises bounded normalized semantic forward-ir intent-hir core key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_intent_hir_optional_composition_keys} || []}) >= 11,
        'manifest advertises bounded normalized semantic forward-ir intent-hir composition-only key presence',
    );
    for my $case (
        [
            'success_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys',
            'forward_ir_intent_hir_symbol_contract_constant_value_entry_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_value_entry_keys(),
            'intent-HIR symbol-contract constant value core keys',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys',
            'forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_scalar_value_extension_keys(),
            'intent-HIR symbol-contract scalar constant value extension keys',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys',
            'forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_constant_list_value_extension_keys(),
            'intent-HIR symbol-contract list constant value extension keys',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds',
            'forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_entry_value_kinds(),
            'intent-HIR symbol-contract enum entry value kinds',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds',
            'forward_ir_intent_hir_symbol_contract_enum_member_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_enum_member_value_kinds(),
            'intent-HIR symbol-contract enum member value kinds',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds',
            'forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_kinds(),
            'intent-HIR symbol-contract package-import entry value kinds',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning',
            'forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_package_import_entry_value_meaning(),
            'intent-HIR symbol-contract package-import entry value meaning',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_type_entry_keys',
            'forward_ir_intent_hir_symbol_contract_type_entry_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_entry_keys(),
            'intent-HIR symbol-contract type entry keys',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds',
            'forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_scalar_value_kinds(),
            'intent-HIR symbol-contract scalar type value kinds',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds',
            'forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_aggregate_value_kinds(),
            'intent-HIR symbol-contract aggregate type value kinds',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys',
            'forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_state_model_extension_keys(),
            'intent-HIR symbol-contract type state-model extension keys',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_type_list_extension_keys',
            'forward_ir_intent_hir_symbol_contract_type_list_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_list_extension_keys(),
            'intent-HIR symbol-contract type list extension keys',
        ],
        [
            'success_forward_ir_intent_hir_symbol_contract_type_record_extension_keys',
            'forward_ir_intent_hir_symbol_contract_type_record_extension_keys',
            normalized_semantic_forward_ir_intent_hir_symbol_contract_type_record_extension_keys(),
            'intent-HIR symbol-contract type record extension keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_child_entry_keys',
            'forward_ir_intent_hir_composition_child_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_child_entry_keys(),
            'intent-HIR composition child entry keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_child_parameter_override_entry_keys',
            'forward_ir_intent_hir_composition_child_parameter_override_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_entry_keys(),
            'intent-HIR composition child parameter-override core entry keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys',
            'forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_raw_value_extension_keys(),
            'intent-HIR composition child parameter-override raw-value extension keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys',
            'forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_forward_ir_intent_hir_composition_child_parameter_override_value_metadata_extension_keys(),
            'intent-HIR composition child parameter-override value-metadata extension keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_generated_child_entry_keys',
            'forward_ir_intent_hir_composition_generated_child_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_entry_keys(),
            'intent-HIR composition generated-child entry keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys',
            'forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_entry_keys(),
            'intent-HIR composition generated-child parameter-override core entry keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys',
            'forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys',
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_raw_value_extension_keys(),
            'intent-HIR composition generated-child parameter-override raw-value extension keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys',
            'forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys',
            normalized_semantic_forward_ir_intent_hir_composition_generated_child_parameter_override_value_metadata_extension_keys(),
            'intent-HIR composition generated-child parameter-override value-metadata extension keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys',
            'forward_ir_intent_hir_composition_standalone_dt_child_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_child_entry_keys(),
            'intent-HIR composition standalone-DT child entry keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys',
            'forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_enable_family_entry_keys(),
            'intent-HIR composition standalone-DT enable-family entry keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys',
            'forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_module_enable_family_keys(),
            'intent-HIR composition standalone-DT module-enable-family keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys',
            'forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_target_entry_keys(),
            'intent-HIR composition standalone-DT multi-drive target entry keys',
        ],
        [
            'success_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys',
            'forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys',
            normalized_semantic_forward_ir_intent_hir_composition_standalone_dt_multi_drive_assertion_keys(),
            'intent-HIR composition standalone-DT multi-drive assertion keys',
        ],
    ) {
        my ($report_field, $semantic_field, $expected, $label) = @{$case};

        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{$report_field},
            $expected,
            "manifest records exact normalized semantic $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{$report_field},
            _family_map_expected($report_field, $expected),
            "manifest report family map records $label",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{semantic_presence_key_family_map}{$semantic_field},
            _family_map_expected($semantic_field, $expected),
            "manifest semantic family map records $label",
        );
    }
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_presence_keys} || []}) >= 7,
        'manifest advertises bounded normalized semantic forward-ir lowered-rtl-ir core key presence',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_presence_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_keys(),
        'manifest records exact normalized semantic lowered-rtl-ir keys including selector-conflict metadata',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_family_entry_keys(),
        'manifest records exact normalized semantic output-drive family entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_output_drive_rhs_enable_family_entry_keys(),
        'manifest records exact normalized semantic output-drive rhs-enable-family entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_target_entry_keys(),
        'manifest records exact normalized semantic selector-conflict target entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_rhs_enable_family_entry_keys(),
        'manifest records exact normalized semantic selector-conflict rhs-enable-family entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_multi_value_assertion_keys(),
        'manifest records exact normalized semantic selector-conflict multi-value assertion keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_selector_conflict_same_value_assertion_keys(),
        'manifest records exact normalized semantic selector-conflict same-value assertion keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'manifest records exact normalized semantic standalone-DT multi-drive target entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'manifest records exact normalized semantic standalone-DT multi-drive assertion keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{success_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_target_entry_keys(),
        'manifest report family map records standalone-DT multi-drive target entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{success_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys},
        normalized_semantic_forward_ir_lowered_rtl_ir_standalone_dt_multi_drive_assertion_keys(),
        'manifest report family map records standalone-DT multi-drive assertion keys',
    );
    for my $case (
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_entry_keys(),
            'candidate entry',
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_declared_type_extension_keys(),
            'candidate declared-type extension',
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_entry_keys(),
            'candidate contributor entry',
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_declared_type_extension_keys(),
            'candidate contributor declared-type extension',
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_entry_keys(),
            'candidate contributor drive-intent entry',
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_candidate_contributor_drive_intent_rhs_enable_family_entry_keys(),
            'candidate contributor drive-intent rhs-enable-family entry',
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_bound_connection_expr_keys(),
            'bound connection expression',
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_family_entry_keys(),
            'aggregate-enable family entry',
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_aggregate_enable_contributor_entry_keys(),
            'aggregate-enable contributor entry',
        ],
        [
            'success_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys',
            normalized_semantic_forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys(),
            'assertion metadata',
        ],
    ) {
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{$case->[0]},
            $case->[1],
            "manifest records exact normalized semantic shared-datapath $case->[2] keys",
        );
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{presence_key_family_map}{$case->[0]},
            $case->[1],
            "manifest report family map records shared-datapath $case->[2] keys",
        );
    }
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_lowered_rtl_ir_optional_composition_keys} || []}) >= 7,
        'manifest advertises bounded normalized semantic forward-ir lowered-rtl-ir composition-only key presence',
    );
    ok(
        scalar(@{$manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_presence_keys} || []}) >= 15,
        'manifest advertises bounded normalized semantic forward-ir structural-rtl-ir key presence',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds},
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_kinds(),
        'manifest records exact normalized semantic structural-rtl-ir auxiliary-assignment entry value kinds',
    );
    is(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning},
        normalized_semantic_forward_ir_structural_rtl_ir_auxiliary_assignment_entry_value_meaning(),
        'manifest records normalized semantic structural-rtl-ir auxiliary-assignment entry value meaning',
    );
    for my $case (
        [
            success_forward_ir_structural_rtl_ir_assignment_record_entry_keys =>
                normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_entry_keys(),
            'assignment-record entry',
        ],
        [
            success_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys =>
                normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_lhs_entry_keys(),
            'assignment-record lhs',
        ],
        [
            success_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys =>
                normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_rhs_entry_keys(),
            'assignment-record rhs',
        ],
        [
            success_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys =>
                normalized_semantic_forward_ir_structural_rtl_ir_assignment_record_provenance_entry_keys(),
            'assignment-record provenance',
        ],
    ) {
        is_deeply(
            $manifest->{semantic_exports}{normalized_semantic_json}{$case->[0]},
            $case->[1],
            "manifest records exact normalized semantic structural-rtl-ir $case->[2] keys",
        );
    }
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir port entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_port_composition_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_composition_extension_keys(),
        'manifest records exact normalized semantic structural-rtl-ir port composition extension keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_port_source_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_source_extension_keys(),
        'manifest records exact normalized semantic structural-rtl-ir port source extension keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_port_source_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_source_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir port source entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_port_target_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_extension_keys(),
        'manifest records exact normalized semantic structural-rtl-ir port target extension keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_port_target_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_port_target_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir port target entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_net_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir net entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_net_source_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_source_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir net source entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_net_target_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_net_target_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir net target entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_declared_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_declared_link_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir declared-link entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_resolved_link_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_resolved_link_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir resolved-link entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_instance_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir instance shallow entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_interface_port_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir instance interface-port entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir instance parameter-override core entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_raw_value_extension_keys(),
        'manifest records exact normalized semantic structural-rtl-ir instance parameter-override raw-value extension keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_parameter_override_value_metadata_extension_keys(),
        'manifest records exact normalized semantic structural-rtl-ir instance parameter-override value-metadata extension keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_entry_keys(),
        'manifest records exact normalized semantic structural-rtl-ir instance port-binding core entry keys',
    );
    is_deeply(
        $manifest->{semantic_exports}{normalized_semantic_json}{success_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys},
        normalized_semantic_forward_ir_structural_rtl_ir_instance_port_binding_typed_extension_keys(),
        'manifest records exact normalized semantic structural-rtl-ir instance port-binding typed extension keys',
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
        semantic_exports_contract_source(),
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
    is_deeply(
        $manifest->{semantic_exports}{section_contract}{nested_presence_key_map},
        semantic_exports_nested_presence_key_map(),
        'manifest records the grouped semantic-exports child key-family map through the semantic-exports section contract',
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
        hdl_external_validation_required_tool_names(),
        'manifest records Verilator and Yosys as the external validation tools',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{required_tools},
        hdl_external_validation_required_tool_names(),
        'manifest records required external validation tools separately',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{optional_tools},
        hdl_external_validation_optional_tool_names(),
        'manifest records optional external validation-adjacent tools separately',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{abc_tool_candidates},
        [qw(yosys-abc berkeley-abc abc)],
        'manifest records optional ABC executable discovery candidates',
    );
    is(
        $manifest->{backend_validation}{systemverilog_external}{abc_mapping_status},
        hdl_external_validation_abc_mapping_status(),
        'manifest records that ABC discovery is optional and not run by validation',
    );
    ok(
        !$manifest->{backend_validation}{systemverilog_external}{abc_mapping_required},
        'manifest records that ABC mapping is not required for external validation',
    );
    ok(
        $manifest->{backend_validation}{systemverilog_external}{abc_mapping_opt_in_supported},
        'manifest records explicit ABC mapping opt-in support',
    );
    ok(
        !$manifest->{backend_validation}{systemverilog_external}{abc_mapping_default_enabled},
        'manifest records that ABC mapping is not enabled by default',
    );
    is(
        $manifest->{backend_validation}{systemverilog_external}{abc_mapping_invocation},
        'FSM::Support::HDLExternalValidation::validate_systemverilog_file(..., abc_mapping => 1)',
        'manifest records the in-process ABC mapping opt-in spelling',
    );
    is(
        $manifest->{backend_validation}{systemverilog_external}{abc_mapping_yosys_stage},
        'read_verilog_sv_noautowire_synth_abc_stat',
        'manifest records the ABC-enabled Yosys stage',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{abc_mapping_success_step_names},
        hdl_external_validation_abc_mapping_success_step_names(),
        'manifest records the ABC mapping opt-in success step names',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{target_languages},
        [qw(systemverilog sv)],
        'manifest records that external validation remains SystemVerilog-only',
    );
    ok(
        $manifest->{backend_validation}{systemverilog_external}{vhdl_generation_scaffold_active},
        'manifest records the active direct VHDL generation scaffold',
    );
    ok(
        $manifest->{backend_validation}{systemverilog_external}{vhdl_validation_deferred_until_ghdl_validation_lane},
        'manifest records that VHDL validation remains deferred to a GHDL validation lane',
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
        hdl_external_validation_contract_source(),
        'manifest records the external HDL validation contract owner',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{success_presence_key_family_map},
        hdl_external_validation_success_presence_key_family_map(),
        'manifest records the grouped external validation success key-family map',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{failure_mode_names},
        hdl_external_validation_failure_mode_names(),
        'manifest records the bounded external validation failure mode names',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{failure_mode_family_map},
        hdl_external_validation_failure_mode_family_map(),
        'manifest records the grouped external validation failure mode families',
    );
    is_deeply(
        $manifest->{backend_validation}{systemverilog_external}{failure_text_prefix_map},
        hdl_external_validation_failure_text_prefix_map(),
        'manifest records the bounded external validation failure text prefixes',
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
        backend_validation_contract_source(),
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
    is_deeply(
        $manifest->{backend_validation}{section_contract}{nested_presence_key_map},
        backend_validation_nested_presence_key_map(),
        'manifest records the grouped backend-validation child key-family map through the backend-validation section contract',
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
        embedding_contract_source(),
        'manifest records the embedding section contract owner',
    );
    ok(
        scalar(@{$manifest->{embedding}{section_contract}{public_top_level_presence_keys} || []}) >= 6,
        'manifest advertises bounded embedding top-level key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{section_contract}{nested_contract_keys} || []}) >= 5,
        'manifest advertises bounded embedding nested-contract key presence',
    );
    is_deeply(
        $manifest->{embedding}{section_contract}{nested_presence_key_map},
        embedding_nested_presence_key_map(),
        'manifest records the grouped embedding child key-family map through the embedding section contract',
    );
    is(
        $manifest->{embedding}{section_contract}{nested_contract_source_map}{serializable_generation_result_snapshot},
        serializable_generation_result_snapshot_contract_source(),
        'manifest records generation result snapshot as a direct embedding child contract owner',
    );
    is_deeply(
        $manifest->{embedding}{section_contract}{nested_presence_key_map}{serializable_generation_result_snapshot},
        serializable_generation_result_snapshot_public_top_level_keys(),
        'manifest records generation result snapshot public keys in the embedding child key-family map',
    );
    is_deeply(
        $manifest->{embedding}{serializable_generation_result_snapshot},
        build_serializable_generation_result_snapshot_contract(),
        'manifest embeds the direct generation result snapshot contract',
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
        composition_report_contract_source(),
        'manifest records the composition report contract owner',
    );
    is(
        $manifest->{embedding}{composition_report}{json_fragment_path},
        composition_report_json_fragment_path(),
        'manifest records where the sanitized composition report is exported',
    );
    is_deeply(
        $manifest->{embedding}{composition_report}{summary_keys},
        composition_report_summary_keys(),
        'manifest records the grouped composition-report summary key family',
    );
    is_deeply(
        $manifest->{embedding}{composition_report}{collection_keys},
        composition_report_collection_keys(),
        'manifest records the grouped composition-report collection key family',
    );
    is_deeply(
        $manifest->{embedding}{composition_report}{count_map_keys},
        composition_report_count_map_keys(),
        'manifest records the grouped composition-report count-map key family',
    );
    is_deeply(
        $manifest->{embedding}{composition_report}{example_map_keys},
        composition_report_example_map_keys(),
        'manifest records the grouped composition-report example-map key family',
    );
    is_deeply(
        $manifest->{embedding}{composition_report}{ordered_list_keys},
        composition_report_ordered_list_keys(),
        'manifest records the grouped composition-report ordered-list key family',
    );
    is_deeply(
        $manifest->{embedding}{composition_report}{presence_key_family_map},
        composition_report_presence_key_family_map(),
        'manifest records the grouped composition-report key-family map',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{schema_version},
        1,
        'manifest records HDLGenerator facade contract schema version',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{status},
        'bounded_public',
        'manifest marks the HDLGenerator facade seam as bounded public',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{contract_source},
        hdl_generator_facade_contract_source(),
        'manifest records the HDLGenerator facade contract owner',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_facade}{public_top_level_presence_keys},
        hdl_generator_facade_public_top_level_keys(),
        'manifest records the bounded HDLGenerator facade top-level keys',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_facade}{method_names},
        hdl_generator_facade_method_names(),
        'manifest records the bounded HDLGenerator facade method family',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_facade}{public_constructor_option_names},
        hdl_generator_facade_public_constructor_option_names(),
        'manifest records the bounded HDLGenerator facade public constructor options',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_facade}{constructor_option_family_map},
        hdl_generator_facade_constructor_option_family_map(),
        'manifest records the grouped HDLGenerator facade constructor-option families',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{default_target_language},
        'systemverilog',
        'manifest records the bounded HDLGenerator facade default target language',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{default_generation_mode},
        hdl_generator_facade_default_generation_mode(),
        'manifest records the current HDLGenerator facade default generation mode',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_facade}{generation_mode_names},
        hdl_generator_facade_generation_mode_names(),
        'manifest records the bounded HDLGenerator facade generation-mode family',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_facade}{generation_mode_constructor_option_public},
        'manifest records that generation_mode is not a public constructor option',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_facade}{structured_nonflattened_generation_enabled},
        'manifest records that structured non-flattened generation is not enabled',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{structured_nonflattened_generation_status},
        hdl_generator_facade_structured_nonflattened_generation_status(),
        'manifest records the structured non-flattened generation deferral status',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{backend_generation_family},
        'flattened_decision_tree_debug_first',
        'manifest records the current backend generation family',
    );
    ok(
        !contains_value(
            $manifest->{embedding}{hdl_generator_facade}{public_constructor_option_names},
            'generation_mode',
        ),
        'manifest does not advertise generation_mode as a public constructor option',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{result_contract_source},
        hdl_generator_result_contract_source(),
        'manifest records the HDLGenerator facade result contract owner',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{direct_extension_contract_source},
        extension_contract_source(),
        'manifest records the HDLGenerator facade direct extension contract owner',
    );
    is(
        $manifest->{embedding}{hdl_generator_facade}{debug_runtime_contract_source},
        debug_runtime_contract_source(),
        'manifest records the HDLGenerator facade debug runtime contract owner',
    );
    ok(
        $manifest->{embedding}{hdl_generator_facade}{stateful_reuse_supported},
        'manifest records that the HDLGenerator facade supports stateful reuse',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_facade}{result_surface_json_safe_as_a_whole},
        'manifest does not claim the whole HDLGenerator result surface is JSON-safe',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_facade}{object_injection_args_public},
        'manifest does not claim the current owner-injection constructor args are public',
    );
    is(
        $manifest->{embedding}{isf_public_interface}{schema_version},
        1,
        'manifest records ISF public-interface contract schema version',
    );
    is(
        $manifest->{embedding}{isf_public_interface}{status},
        'bounded_public',
        'manifest marks the ISF public-interface seam as bounded public',
    );
    is(
        $manifest->{embedding}{isf_public_interface}{contract_source},
        isf_public_interface_contract_source(),
        'manifest records the ISF public-interface contract owner',
    );
    is_deeply(
        $manifest->{embedding}{isf_public_interface}{public_top_level_presence_keys},
        isf_public_interface_public_top_level_keys(),
        'manifest records the bounded ISF public-interface top-level keys',
    );
    is_deeply(
        $manifest->{embedding}{isf_public_interface}{parser_method_names},
        isf_public_interface_parser_method_names(),
        'manifest records the bounded ISF parser method family',
    );
    is_deeply(
        $manifest->{embedding}{isf_public_interface}{scheduler_method_names},
        isf_public_interface_scheduler_method_names(),
        'manifest records the bounded ISF scheduler method family',
    );
    is_deeply(
        $manifest->{embedding}{isf_public_interface}{schedule_report_top_level_keys},
        isf_public_interface_schedule_report_top_level_keys(),
        'manifest records the bounded ISF schedule-report top-level keys',
    );
    is_deeply(
        $manifest->{embedding}{isf_public_interface}{schedule_report_presence_key_family_map},
        isf_public_interface_schedule_report_presence_key_family_map(),
        'manifest records the grouped ISF schedule-report key families',
    );
    ok(
        $manifest->{embedding}{isf_public_interface}{live_contract_documentation},
        'manifest records ISF public-interface docs as live documentation',
    );
    ok(
        $manifest->{embedding}{isf_public_interface}{evolves_with_isf_implementation},
        'manifest records ISF public-interface contract evolution policy',
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
        hdl_generator_result_contract_source(),
        'manifest records the HDLGenerator result contract owner',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{nested_contract_source_map},
        {
            source_info => hdl_generator_source_info_contract_source(),
            module_info => hdl_generator_module_info_contract_source(),
            statistics => hdl_generator_statistics_contract_source(),
            fsm_module => hdl_generator_fsm_module_contract_source(),
            raw_ast => hdl_generator_raw_ast_contract_source(),
            resolved_package_imports => hdl_generator_resolved_package_imports_contract_source(),
            composition_spec => hdl_generator_composition_spec_contract_source(),
            composition_plan => hdl_generator_composition_plan_contract_source(),
            composition_report => composition_report_contract_source(),
            intent_hir => normalized_semantic_intent_hir_contract_source(),
            lowered_rtl_ir => normalized_semantic_lowered_rtl_ir_contract_source(),
            structural_rtl_ir => normalized_semantic_structural_rtl_ir_contract_source(),
        },
        'manifest records the HDLGenerator nested-contract ownership map',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{stable_subsurface_map},
        hdl_generator_result_stable_subsurface_map(),
        'manifest records the grouped HDLGenerator stable nested-subsurface map',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{optional_composition_key_family_map},
        hdl_generator_result_optional_composition_key_family_map(),
        'manifest records the grouped HDLGenerator composition-only key-family map',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{semantic_layer_presence_key_family_map},
        hdl_generator_result_semantic_layer_presence_key_family_map(),
        'manifest records the grouped HDLGenerator semantic-layer key-family map',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{shell_only_fallback_surface_map},
        hdl_generator_result_shell_only_fallback_surface_map(),
        'manifest records the grouped HDLGenerator shell-only fallback surface map',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{shell_only_fallback_surface_family_map},
        hdl_generator_result_shell_only_fallback_surface_family_map(),
        'manifest records the grouped HDLGenerator shell-only fallback surface family map',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{fsm_module_shell_only},
        'manifest says fsm_module is a shell-only compatibility branch',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{fsm_module_contract_source},
        hdl_generator_fsm_module_contract_source(),
        'manifest records the nested HDLGenerator fsm_module contract owner',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{fsm_module_raw_value_class_when_defined},
        'FSM::CoreAST::FSMModule',
        'manifest records the raw fsm_module value class when defined',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{fsm_module_summary_surfaces},
        ['intent_hir', 'lowered_rtl_ir', 'structural_rtl_ir'],
        'manifest points fsm_module embedders at the structured semantic summaries',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{fsm_module_fallback_surface_map},
        hdl_generator_fsm_module_fallback_surface_map(),
        'manifest records the grouped fsm_module fallback-surface families',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{raw_ast_shell_only},
        'manifest says raw_ast is a shell-only compatibility branch',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{raw_ast_contract_source},
        hdl_generator_raw_ast_contract_source(),
        'manifest records the nested HDLGenerator raw_ast contract owner',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{raw_ast_value_shape},
        'ARRAY',
        'manifest records the raw_ast value shape',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{raw_ast_summary_surfaces},
        ['intent_hir'],
        'manifest points raw_ast consumers at intent_hir for structured semantic inspection',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{raw_ast_fallback_surface_map},
        hdl_generator_raw_ast_fallback_surface_map(),
        'manifest records the grouped raw_ast fallback-surface families',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{source_info_identity_presence_keys} || []}) >= 2,
        'manifest advertises bounded HDLGenerator source_info identity key presence',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{source_info_contract_source},
        hdl_generator_source_info_contract_source(),
        'manifest records the nested HDLGenerator source_info contract owner',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_result}{source_info_full_hash_stable},
        'manifest does not claim the whole source_info hash is stable',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{source_info_summary_slices_advertised},
        'manifest says the HDLGenerator result advertises bounded source_info summary slices',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{source_info_summary_presence_keys} || []}) >= 2,
        'manifest advertises bounded HDLGenerator source_info summary key presence',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{source_info_package_import_summary_copy_policy},
        'package_import_names is a fresh caller-owned array on each returned source_info object',
        'manifest records the HDLGenerator source_info package-import summary copy policy',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{source_info_stable_subsurfaces},
        ['source_info.header', 'source_info.kind', 'source_info.package_import_count', 'source_info.package_import_names'],
        'manifest publishes the bounded stable source_info subsurfaces',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{resolved_package_imports_shell_only},
        'manifest says resolved_package_imports is a shell-only compatibility branch',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{resolved_package_imports_contract_source},
        hdl_generator_resolved_package_imports_contract_source(),
        'manifest records the nested HDLGenerator resolved_package_imports contract owner',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{resolved_package_imports_raw_value_class},
        'FSM::Package::Spec',
        'manifest records the raw resolved_package_imports value class',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{resolved_package_imports_summary_surface},
        ['source_info.package_import_count', 'source_info.package_import_names'],
        'manifest points package-import embedders at the bounded source_info summary surface',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{resolved_package_imports_fallback_surface_map},
        hdl_generator_resolved_package_imports_fallback_surface_map(),
        'manifest records the grouped resolved_package_imports fallback-surface families',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{composition_spec_shell_only},
        'manifest says composition_spec is a shell-only compatibility branch',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{composition_spec_contract_source},
        hdl_generator_composition_spec_contract_source(),
        'manifest records the nested HDLGenerator composition_spec contract owner',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{composition_spec_raw_value_class},
        'FSM::Composition::Spec',
        'manifest records the raw composition_spec value class',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{composition_spec_summary_surfaces},
        [
            'semantic_exports.normalized_semantic_json.semantic.composition',
            'semantic_exports.normalized_semantic_json.semantic.composition.provenance_report',
        ],
        'manifest points composition_spec embedders at the structured semantic fallback surfaces',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{composition_spec_fallback_surface_map},
        hdl_generator_composition_spec_fallback_surface_map(),
        'manifest records the grouped composition_spec fallback-surface families',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{composition_plan_shell_only},
        'manifest says composition_plan is a shell-only compatibility branch',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{composition_plan_contract_source},
        hdl_generator_composition_plan_contract_source(),
        'manifest records the nested HDLGenerator composition_plan contract owner',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{composition_plan_raw_value_class},
        'FSM::Composition::Plan',
        'manifest records the raw composition_plan value class',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{composition_plan_summary_surfaces},
        [
            'semantic_exports.normalized_semantic_json.semantic.composition',
            'semantic_exports.normalized_semantic_json.semantic.composition.provenance_report',
        ],
        'manifest points composition_plan embedders at the structured semantic fallback surfaces',
    );
    is_deeply(
        $manifest->{embedding}{hdl_generator_result}{composition_plan_fallback_surface_map},
        hdl_generator_composition_plan_fallback_surface_map(),
        'manifest records the grouped composition_plan fallback-surface families',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{composition_report_shell_only},
        'manifest says composition_report is a shell-only compatibility branch',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_result}{composition_report_raw_hash_json_safe},
        'manifest says raw composition_report is not JSON-safe',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{composition_report_contract_source},
        composition_report_contract_source(),
        'manifest records the raw composition_report contract owner',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{composition_report_json_fragment_path},
        composition_report_json_fragment_path(),
        'manifest points composition-report embedders at the sanitized semantic JSON fragment',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{module_info_identity_presence_keys} || []}) >= 2,
        'manifest advertises bounded HDLGenerator module_info identity key presence',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{module_info_contract_source},
        hdl_generator_module_info_contract_source(),
        'manifest records the nested HDLGenerator module_info contract owner',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_result}{module_info_full_hash_stable},
        'manifest does not claim the whole module_info hash is stable',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{module_info_summary_slices_advertised},
        'manifest says the HDLGenerator result advertises bounded module_info summary slices',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{module_info_summary_presence_keys} || []}) >= 8,
        'manifest advertises bounded HDLGenerator module_info summary key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{module_info_optional_composition_summary_keys} || []}) >= 16,
        'manifest advertises bounded HDLGenerator composition-only module_info summary key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{module_info_stable_subsurfaces} || []}) >= 10,
        'manifest advertises bounded HDLGenerator module_info stable subsurfaces',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{statistics_summary_slices_advertised},
        'manifest says the HDLGenerator result advertises bounded statistics summary slices',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{statistics_contract_source},
        hdl_generator_statistics_contract_source(),
        'manifest records the nested HDLGenerator statistics contract owner',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_result}{statistics_full_hash_stable},
        'manifest does not claim the whole statistics hash is stable',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{statistics_summary_presence_keys} || []}) >= 3,
        'manifest advertises bounded HDLGenerator statistics summary key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{statistics_optional_composition_keys} || []}) >= 8,
        'manifest advertises bounded HDLGenerator composition-only statistics summary key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{statistics_stable_subsurfaces} || []}) >= 3,
        'manifest advertises bounded HDLGenerator statistics stable subsurfaces',
    );
    ok(
        $manifest->{embedding}{hdl_generator_result}{top_level_semantic_layer_contracts_advertised},
        'manifest says the HDLGenerator result advertises bounded top-level semantic-layer shells',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{intent_hir_contract_source},
        normalized_semantic_intent_hir_contract_source(),
        'manifest records the HDLGenerator top-level intent-hir owner',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_result}{intent_hir_full_hash_stable},
        'manifest does not claim the whole top-level intent_hir hash is stable',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{lowered_rtl_ir_contract_source},
        normalized_semantic_lowered_rtl_ir_contract_source(),
        'manifest records the HDLGenerator top-level lowered-rtl-ir owner',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_result}{lowered_rtl_ir_full_hash_stable},
        'manifest does not claim the whole top-level lowered_rtl_ir hash is stable',
    );
    is(
        $manifest->{embedding}{hdl_generator_result}{structural_rtl_ir_contract_source},
        normalized_semantic_structural_rtl_ir_contract_source(),
        'manifest records the HDLGenerator top-level structural-rtl-ir owner',
    );
    ok(
        !$manifest->{embedding}{hdl_generator_result}{structural_rtl_ir_full_hash_stable},
        'manifest does not claim the whole top-level structural_rtl_ir hash is stable',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{intent_hir_presence_keys} || []}) >= 18,
        'manifest advertises bounded HDLGenerator top-level intent-hir key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{intent_hir_optional_composition_keys} || []}) >= 11,
        'manifest advertises bounded HDLGenerator top-level intent-hir composition-only key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{lowered_rtl_ir_presence_keys} || []}) >= 7,
        'manifest advertises bounded HDLGenerator top-level lowered-rtl-ir key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{lowered_rtl_ir_optional_composition_keys} || []}) >= 7,
        'manifest advertises bounded HDLGenerator top-level lowered-rtl-ir composition-only key presence',
    );
    ok(
        scalar(@{$manifest->{embedding}{hdl_generator_result}{structural_rtl_ir_presence_keys} || []}) >= 15,
        'manifest advertises bounded HDLGenerator top-level structural-rtl-ir key presence',
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
        extension_contract_source(),
        'manifest records the typed extension contract owner',
    );
    is_deeply(
        $manifest->{embedding}{typed_extensions}{name_family_map},
        extension_contract_name_family_map(),
        'manifest records the grouped typed-extension name families',
    );
    my %extension_hooks = map { $_ => 1 } @{$manifest->{embedding}{typed_extensions}{hook_names}};
    ok($extension_hooks{after_parse_source}, 'manifest advertises the parse-source extension hook');
    ok($extension_hooks{after_generate_result}, 'manifest advertises the result extension hook');
    ok(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{must_be_blessed_object},
        'manifest records the typed extension object boundary',
    );
    ok(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{must_provide_supported_hook_method},
        'manifest records the typed extension supported-hook object boundary',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{supported_hook_method_policy},
        'extension objects must provide at least one real supported hook method discoverable by UNIVERSAL::can',
        'manifest records the typed extension supported-hook method policy',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{loader_constructor_receiver_shape},
        'scalar FSM::Extension::Loader class name',
        'manifest records the typed extension direct loader constructor receiver shape',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{loader_constructor_argument_list_shape},
        'no option/value arguments after class invocant',
        'manifest records the typed extension direct loader constructor argument-list shape',
    );
    is_deeply(
        sorted($manifest->{embedding}{typed_extensions}{extension_object_contract}{loader_constructor_supported_option_names}),
        sorted(extension_contract_loader_constructor_option_names()),
        'manifest records the typed extension direct loader constructor option names',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{loader_method_receiver_shape},
        'exact hash-backed FSM::Extension::Loader object constructed by new(...)',
        'manifest records the typed extension direct loader method receiver shape',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{loader_method_argument_list_shape},
        'exactly one payload argument after the loader invocant',
        'manifest records the typed extension direct loader method argument-list shape',
    );
    is_deeply(
        sorted($manifest->{embedding}{typed_extensions}{extension_object_contract}{loader_method_names}),
        sorted(extension_contract_loader_method_names()),
        'manifest records the typed extension direct loader method names',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{registry_constructor_receiver_shape},
        'scalar FSM::Extension::Registry class name',
        'manifest records the typed extension direct registry constructor receiver shape',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{registry_constructor_argument_list_shape},
        'even-length list of unique scalar non-empty supported option-name/value pairs after class invocant',
        'manifest records the typed extension direct registry constructor argument-list shape',
    );
    is_deeply(
        sorted($manifest->{embedding}{typed_extensions}{extension_object_contract}{registry_constructor_supported_option_names}),
        sorted(extension_contract_registry_constructor_option_names()),
        'manifest records the typed extension direct registry constructor option names',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{registry_method_receiver_shape},
        'exact hash-backed FSM::Extension::Registry object constructed by new(...)',
        'manifest records the typed extension direct registry method receiver shape',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{registry_method_argument_list_shape},
        'extensions takes no payload arguments; dispatch_hook takes hook name and context; hook wrapper methods take one context argument after the registry invocant',
        'manifest records the typed extension direct registry method argument-list shape',
    );
    is_deeply(
        sorted($manifest->{embedding}{typed_extensions}{extension_object_contract}{registry_method_names}),
        sorted(extension_contract_registry_method_names()),
        'manifest records the typed extension direct registry method names',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{registry_dispatch_context_shape},
        'exact hash-backed FSM::Extension::Context object constructed by new(...) whose stage matches the dispatched hook name',
        'manifest records the typed extension direct registry dispatch context shape',
    );
    is(
        $manifest->{embedding}{typed_extensions}{extension_object_contract}{registry_extension_list_policy},
        'constructor and extensions accessor copy the extension array; extension objects remain live hook objects',
        'manifest records the typed extension registry extension-list copy policy',
    );
    is(
        $manifest->{embedding}{typed_extensions}{context_contract}{constructor_receiver_shape},
        'scalar FSM::Extension::Context class name',
        'manifest records the typed extension context constructor receiver shape',
    );
    is(
        $manifest->{embedding}{typed_extensions}{context_contract}{constructor_argument_list_shape},
        'even-length list of unique scalar non-empty supported option-name/value pairs after class invocant',
        'manifest records the typed extension context constructor argument-list shape',
    );
    is_deeply(
        sorted($manifest->{embedding}{typed_extensions}{context_contract}{constructor_supported_option_names}),
        sorted(extension_contract_context_accessors()),
        'manifest records the supported typed extension context constructor option names',
    );
    is(
        $manifest->{embedding}{typed_extensions}{context_contract}{accessor_receiver_shape},
        'exact hash-backed FSM::Extension::Context object constructed by new(...)',
        'manifest records the typed extension context accessor receiver shape',
    );
    is(
        $manifest->{embedding}{typed_extensions}{context_contract}{accessor_argument_list_shape},
        'no payload arguments after the context invocant',
        'manifest records the typed extension context accessor argument-list shape',
    );
    is_deeply(
        sorted($manifest->{embedding}{typed_extensions}{context_contract}{accessor_method_names}),
        sorted(extension_contract_context_accessors()),
        'manifest records the typed extension context accessor method names',
    );
    is(
        $manifest->{embedding}{typed_extensions}{context_contract}{constructor_stage_shape},
        'supported hook stage name',
        'manifest records the typed extension context constructor stage shape',
    );
    is(
        $manifest->{embedding}{typed_extensions}{context_contract}{constructor_common_payload_shape},
        'blessed pipeline object, scalar non-empty source_path, scalar non-empty target_language, and source_info hash with scalar non-empty kind',
        'manifest records the typed extension context constructor common payload shape',
    );
    is(
        $manifest->{embedding}{typed_extensions}{context_contract}{constructor_stage_payload_shape},
        'after_parse_source requires raw_ast ARRAY and no result; after_generate_result requires result HASH and no raw_ast',
        'manifest records the typed extension context constructor stage payload shape',
    );
    is_deeply(
        $manifest->{embedding}{typed_extensions}{context_contract}{accessor_copy_policy},
        {
            source_info => 'fresh caller-owned source_info snapshot on every accessor call',
            raw_ast => 'fresh caller-owned raw_ast snapshot on every accessor call when available',
            result => 'live result hash on after_generate_result; in-process result mutation is allowed',
        },
        'manifest records the typed extension context accessor copy policy',
    );
    ok(
        !$manifest->{embedding}{typed_extensions}{extension_object_contract}{legacy_plg_discovery},
        'manifest records that legacy .plg discovery is not part of typed extensions',
    );
    is(
        $manifest->{embedding}{debug_runtime}{schema_version},
        1,
        'manifest records debug-runtime contract schema version',
    );
    is(
        $manifest->{embedding}{debug_runtime}{status},
        'bounded_public',
        'manifest marks the embedding debug runtime seam as bounded public',
    );
    is(
        $manifest->{embedding}{debug_runtime}{contract_source},
        debug_runtime_contract_source(),
        'manifest records the debug-runtime contract owner',
    );
    is_deeply(
        $manifest->{embedding}{debug_runtime}{public_top_level_presence_keys},
        debug_runtime_public_top_level_keys(),
        'manifest records the bounded debug-runtime contract top-level keys',
    );
    is_deeply(
        $manifest->{embedding}{debug_runtime}{family_map},
        debug_runtime_family_map(),
        'manifest records the grouped debug-runtime helper and snapshot-state families',
    );
    is_deeply(
        $manifest->{embedding}{debug_runtime}{snapshot_state_keys},
        debug_runtime_snapshot_state_keys(),
        'manifest records the bounded debug-runtime snapshot-state keys',
    );
    is(
        $manifest->{embedding}{debug_runtime}{restore_snapshot_argument_shape},
        'exact schema-version-1 snapshot hash with the advertised snapshot_state_keys and bounded scalar values',
        'manifest records the bounded debug-runtime restore snapshot argument shape',
    );
    is_deeply(
        $manifest->{embedding}{debug_runtime}{named_trace_verbosity_values},
        debug_runtime_named_trace_verbosity_values(),
        'manifest records the bounded named debug trace verbosity values',
    );
    ok(
        $manifest->{embedding}{debug_runtime}{process_global_singleton},
        'manifest records that the debug runtime is still process-global',
    );
    ok(
        !$manifest->{embedding}{debug_runtime}{thread_safe},
        'manifest does not claim the debug runtime seam is thread-safe',
    );
    ok(
        !$manifest->{embedding}{debug_runtime}{snapshot_json_safe},
        'manifest does not claim saved debug snapshots are JSON-safe',
    );
    ok(
        $manifest->{embedding}{debug_runtime}{pipeline_scopes_debug_state},
        'manifest records that HDLGenerator scopes the current debug runtime seam',
    );
    ok(
        !$manifest->{embedding}{debug_runtime}{general_debug_calls_auto_scoped},
        'manifest does not claim all debug calls are automatically scoped',
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
    is(
        $manifest->{verification_outputs}{schema_version},
        1,
        'manifest records verification-output schema version',
    );
    is(
        $manifest->{verification_outputs}{status},
        'bounded_public',
        'manifest marks verification outputs as bounded public',
    );
    is(
        $manifest->{verification_outputs}{contract_source},
        verification_outputs_contract_source(),
        'manifest records the verification-output contract owner',
    );
    is(
        $manifest->{verification_outputs}{section_contract}{contract_source},
        verification_outputs_contract_source(),
        'manifest records the verification-output section contract owner',
    );
    is_deeply(
        $manifest->{verification_outputs}{section_contract}{presence_key_family_map},
        verification_outputs_presence_key_family_map(),
        'manifest records the grouped verification-output key-family map',
    );
    is_deeply(
        $manifest->{verification_outputs}{target_entry_keys},
        verification_outputs_target_entry_keys(),
        'manifest advertises bounded verification-output target entry keys',
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
    is_deeply(
        $manifest->{language_surface}{file_surfaces}{entry_presence_keys},
        language_surface_file_surface_entry_keys(),
        'manifest advertises bounded file-surface entry key presence',
    );
    my %suffixes = map { $_ => 1 } @{$manifest->{language_surface}{file_surfaces}{shipped_suffixes}};
    ok($suffixes{'.fsm'}, 'manifest advertises .fsm as a shipped file surface');
    ok($suffixes{'.isf'}, 'manifest advertises .isf as a shipped file surface');
    ok($suffixes{'.ppif'}, 'manifest advertises .ppif as a shipped file surface');
    ok($suffixes{'.axi'}, 'manifest advertises .axi as a shipped profile-alias file surface');
    ok($suffixes{'.apb'}, 'manifest advertises .apb as a shipped profile-alias file surface');
    ok($suffixes{'.ahb'}, 'manifest advertises .ahb as a shipped profile-alias file surface');
    ok(
        !$manifest->{language_surface}{file_surfaces}{direct_ial2_to_ial0_allowed},
        'manifest states direct IAL2-to-IAL0 lowering is not allowed',
    );
    my %file_surface_by_suffix = map { $_->{suffix} => $_ } @{$manifest->{language_surface}{file_surfaces}{entries}};
    my %isf_cli_modes = map { $_ => 1 } @{$file_surface_by_suffix{'.isf'}{supported_cli_modes} || []};
    ok(
        $isf_cli_modes{'--emit-verification-output uvm-passive-monitor --verification-outdir'},
        'manifest records .isf UVM verification-output CLI mode',
    );
    ok(
        $isf_cli_modes{'--emit-verification-output vhdl-observation-package --verification-outdir'},
        'manifest records .isf VHDL verification-output CLI mode',
    );
    is($file_surface_by_suffix{'.ppif'}{intent_layer}, 'IAL2', 'manifest marks .ppif as IAL2');
    is(
        $file_surface_by_suffix{'.ppif'}{status},
        'shipped_bounded_public',
        'manifest marks .ppif as a bounded public shipped surface',
    );
    is_deeply(
        $file_surface_by_suffix{'.ppif'}{lowers_to},
        ['.isf', '.fsm'],
        'manifest records .ppif lowering through .isf before .fsm',
    );
    is_deeply(
        $file_surface_by_suffix{'.ppif'}{generated_review_artifacts},
        ['.isf', '.fsm'],
        'manifest records .ppif generated review artifacts',
    );
    my %ppif_cli_modes = map { $_ => 1 } @{$file_surface_by_suffix{'.ppif'}{supported_cli_modes} || []};
    ok($ppif_cli_modes{'--emit-schedule-json'}, 'manifest records .ppif schedule-report CLI mode');
    ok($ppif_cli_modes{'--emit-semantic-json'}, 'manifest records .ppif semantic JSON CLI mode');
    ok($ppif_cli_modes{'--check --json / --check-json'}, 'manifest records .ppif check JSON CLI mode');
    ok(
        !$ppif_cli_modes{'--emit-verification-output uvm-passive-monitor --verification-outdir'},
        'manifest does not advertise UVM verification-output CLI mode for .ppif yet',
    );
    ok(
        !$ppif_cli_modes{'--emit-verification-output vhdl-observation-package --verification-outdir'},
        'manifest does not advertise VHDL verification-output CLI mode for .ppif yet',
    );
    is(
        $file_surface_by_suffix{'.ppif'}{sample_path},
        'ppif/axi_aw_valid_ready.ppif',
        'manifest points at the first runnable PPIF sample',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/AXI AW\/W multi-channel Valid-Ready bundle/,
        'manifest advertises the AXI AW/W multi-channel bundle explicitly',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AXI manager AW address-channel driver source/,
        'manifest advertises the bounded AXI manager AW address-channel driver source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AXI manager AR read-address-channel driver source/,
        'manifest advertises the bounded AXI manager AR read-address-channel driver source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AXI manager R read-data beat acceptor source/,
        'manifest advertises the bounded AXI manager R read-data beat acceptor source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AXI manager AR\/R fixed-single-beat full-read transaction composition source/,
        'manifest advertises the bounded AXI manager AR/R full-read transaction composition source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AXI manager AR\/R fixed-four-beat full-width INCR read transaction composition source/,
        'manifest advertises the bounded AXI manager AR/R fixed-four read transaction composition source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AXI manager W write-data-channel driver source/,
        'manifest advertises the bounded AXI manager W write-data-channel driver source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AXI manager B write-response acceptor source/,
        'manifest advertises the bounded AXI manager B write-response acceptor source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AXI manager AW\/W single-beat write-request composition source/,
        'manifest advertises the bounded AXI manager AW/W single-beat write-request composition source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AXI manager AW\/W\/B single-beat full-write transaction composition source/,
        'manifest advertises the bounded AXI manager AW/W/B single-beat full-write transaction composition source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/protocol-neutral valid-ready handshake sample/,
        'manifest advertises the protocol-neutral valid-ready handshake sample',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/protocol-neutral dual-channel Valid-Ready bundle/,
        'manifest advertises the protocol-neutral dual-channel valid-ready bundle',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/APB completer source/,
        'manifest advertises the APB completer PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/APB multi-register completer source/,
        'manifest advertises the APB multi-register completer PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/APB busy-capable requester-transfer source/,
        'manifest advertises the APB busy-capable requester-transfer PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/APB status-capable requester-transfer source/,
        'manifest advertises the APB status-capable requester-transfer PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/sideband-aware APB requester-transfer source/,
        'manifest advertises the sideband-aware APB requester-transfer PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/one-requester\/one-completer APB composition source/,
        'manifest advertises the APB composition PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/busy-capable one-requester\/one-completer APB composition source/,
        'manifest advertises the APB busy-capable composition PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/status-capable one-requester\/one-completer APB composition source/,
        'manifest advertises the APB status-capable composition PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/status-capable multi-register one-requester\/one-completer APB composition source/,
        'manifest advertises the APB status-capable multi-register composition PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/sideband-aware APB multi-register completer source/,
        'manifest advertises the sideband-aware APB multi-register completer PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/sideband-aware multi-register one-requester\/one-completer APB composition source/,
        'manifest advertises the sideband-aware APB multi-register composition PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/sideband-aware one-requester\/two-peripheral APB interconnect\/decode composition source/,
        'manifest advertises the sideband-aware APB multi-peripheral composition PPIF source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/AXI is the first shipped IAL2 profile\/example, not the definition of IAL2/,
        'manifest states AXI is the first shipped IAL2 profile, not the IAL2 definition',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/\.axi is now the first profile-alias file surface over the same IAL2 model/,
        'manifest states .axi is the first shipped IAL2 profile alias over the same model',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/\.apb is now the bounded APB requester-transfer\/completer\/composition plus busy-capable, status-capable, selected back-to-back, selected multi-register, selected multi-peripheral interconnect\/decode, selected multi-peripheral back-to-back, sideband-aware, sideband protection, selected sideband protection back-to-back, selected sideband no-policy multi-peripheral multi-register back-to-back, selected bounded sideband generalized no-policy multi-peripheral multi-register back-to-back, selected sideband protection multi-peripheral multi-register back-to-back, selected sideband protection multi-peripheral back-to-back, sideband data16, selected sideband data16 back-to-back, selected sideband data16 no-policy multi-peripheral multi-register back-to-back, selected bounded sideband data16 generalized no-policy multi-peripheral multi-register back-to-back, sideband data16 protection, selected sideband data16 protection back-to-back, and selected sideband data16 protection multi-peripheral multi-register back-to-back profile-alias file surface/,
        'manifest states .apb is the bounded APB profile alias over the same model',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/\.ahb is now the bounded AHB requester, word-only subordinate, byte-lane\/narrow-transfer subordinate, byte-lane in-word SEQ subordinate, one-requester\/one-subordinate aggregate interconnect, selected one-requester\/two-subordinate aggregate interconnect, selected one-requester\/one-subordinate aggregate byte-lane interconnect, selected one-requester\/two-subordinate aggregate byte-lane interconnect, selected one-requester\/one-subordinate aggregate byte-lane in-word SEQ interconnect, and selected one-requester\/two-subordinate aggregate byte-lane in-word SEQ interconnect profile-alias file surface/,
        'manifest states .ahb is the bounded AHB requester, subordinate, aggregate interconnect, aggregate byte-lane, and aggregate byte-lane SEQ profile alias over the same model',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/bounded AHB requester source, the bounded AHB-Lite word-only subordinate source, the bounded AHB-Lite byte-lane\/narrow-transfer subordinate source, the bounded AHB-Lite byte-lane in-word SEQ subordinate source, the bounded AHB-Lite byte-lane HBURST WRAP4\/INCR4 SEQ subordinate source/,
        'manifest states .ppif includes the bounded AHB requester and subordinate sources',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/selected one-requester\/one-subordinate AHB interconnect\/decode source/,
        'manifest states .ppif includes the selected AHB interconnect/decode source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/selected one-requester\/two-subordinate static-window AHB interconnect\/decode source/,
        'manifest states .ppif includes the selected generic two-subordinate AHB interconnect/decode source',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/selected one-requester\/one-subordinate AHB aggregate byte-lane in-word SEQ propagation source, the selected one-requester\/two-subordinate AHB aggregate byte-lane in-word SEQ propagation source/,
        'manifest states .ppif includes selected aggregate byte-lane in-word SEQ propagation sources',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/selected one-requester\/one-subordinate AHB aggregate HBURST-aware byte-lane SEQ propagation source with BUSY-in-burst parking, the selected one-requester\/two-subordinate AHB aggregate HBURST-aware byte-lane SEQ propagation source with BUSY-in-burst parking/,
        'manifest states .ppif includes the selected aggregate HBURST-aware byte-lane SEQ propagation sources with BUSY-in-burst parking',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/selected status back-to-back APB requester-transfer, sideband-aware APB requester-transfer, sideband-aware data16 APB requester-transfer, selected sideband-aware data16 status back-to-back APB requester-transfer, APB completer, selected back-to-back APB completer, APB multi-register completer, .*selected sideband-aware data16 back-to-back APB multi-register completer, .*selected sideband-aware data16 protection back-to-back APB multi-register completer, .*selected status back-to-back one-requester\/one-completer APB composition, .*sideband-aware data16 multi-register one-requester\/one-completer APB composition, selected sideband-aware data16 status back-to-back multi-register one-requester\/one-completer APB composition, .*sideband-aware data16 protection multi-register one-requester\/one-completer APB composition, selected sideband-aware data16 protection status back-to-back multi-register one-requester\/one-completer APB composition, .*selected sideband-aware protection multi-register status back-to-back one-requester\/two-peripheral APB interconnect\/decode composition, .*selected sideband-aware data16 no-policy multi-register status back-to-back one-requester\/two-peripheral APB interconnect\/decode composition, selected bounded sideband-aware data16 generalized no-policy multi-register status back-to-back one-requester\/two-peripheral APB interconnect\/decode composition, .*sideband-aware protection one-requester\/two-peripheral APB interconnect\/decode composition, .*sideband-aware data16 protection one-requester\/two-peripheral APB interconnect\/decode composition \.ppif sources through support-accounted profile-alias fixtures/,
        'manifest states .apb mirrors the sideband-aware data16 APB PPIF sources through profile aliases',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/APB address widths other than 32, wait-count widths other than 4, data widths beyond the selected sideband-aware 16\/32-bit boundary, additional APB PPROT policy families, APB back-to-back variants beyond the selected fixed\/status, selected sideband-aware fixed\/status, selected sideband-aware protected fixed multi-register status, selected sideband-aware data16 fixed multi-register status, selected sideband-aware data16-protection fixed multi-register status, no-sideband multi-peripheral status, selected sideband-aware multi-peripheral status, selected sideband-aware no-policy multi-peripheral multi-register status, selected bounded sideband-aware generalized no-policy multi-peripheral multi-register status, selected sideband-aware protection multi-peripheral multi-register status, selected sideband-aware data16 no-policy multi-peripheral multi-register status, selected bounded sideband-aware data16 generalized no-policy multi-peripheral multi-register status, selected sideband-aware protection multi-peripheral status, selected sideband-aware data16-protection multi-peripheral status\/control families/,
        'manifest keeps remaining APB width and sideband follow-on work explicit after data16 support shipped',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/broader AHB interconnect\/decode beyond the selected one-requester\/one-subordinate static-window PPIF\/\.ahb source and selected one-requester\/two-subordinate static-window PPIF\/\.ahb source/,
        'manifest keeps broader AHB interconnect/decode deferred beyond the selected one- and two-subordinate sources',
    );
    unlike(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/APB sidebands/,
        'manifest no longer defers APB sidebands broadly after sideband/strobe support shipped',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/additional protocol-specific suffixes such as \.chi, \.ace, \.atb, \.smbus, or \.i2s remain future profile aliases/,
        'manifest states remaining non-APB and non-AHB protocol-specific suffixes are future IAL2 profile aliases',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/common IAL2 constructs stay small until compatible reuse is proven across multiple profiles/,
        'manifest keeps common IAL2 construct promotion evidence-driven across profiles',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/read single-beat and read burst-last queue-head response-demux including multiple\/mixed depth-3 scalar, raw-ARLEN, runtime-validation, and multi-beat output-bank read-data groups/,
        'manifest advertises shipped queue-head scalar, raw-ARLEN, runtime-validation, and multi-beat read-data',
    );
    my ($uvm_target) = grep { $_->{id} eq 'uvm_passive_monitor_skeleton' }
        @{$manifest->{verification_outputs}{targets} || []};
    ok($uvm_target, 'manifest advertises the UVM passive-monitor skeleton target');
    is($uvm_target->{cli_target}, 'uvm-passive-monitor', 'manifest records the verification-output CLI target');
    is_deeply($uvm_target->{source_suffixes}, ['.isf'], 'manifest limits the first verification-output target to .isf');
    ok($uvm_target->{requires_verification_observations}, 'manifest records the observation metadata prerequisite');
    is(
        $uvm_target->{artifact_relpath_pattern},
        'uvm/<actor>_observation_uvm_pkg.sv',
        'manifest records the UVM package artifact path pattern',
    );
    is(
        $uvm_target->{manifest_relpath},
        'verification-output-manifest.json',
        'manifest records the verification-output artifact manifest path',
    );
    ok(
        !$manifest->{verification_outputs}{validation}{claimed_uvm_compile_support},
        'manifest does not claim UVM compile support for the skeleton target',
    );
    my ($vhdl_target) = grep { $_->{id} eq 'vhdl_observation_package_skeleton' }
        @{$manifest->{verification_outputs}{targets} || []};
    ok($vhdl_target, 'manifest advertises the VHDL observation package skeleton target');
    is($vhdl_target->{cli_target}, 'vhdl-observation-package', 'manifest records the VHDL verification-output CLI target');
    is_deeply($vhdl_target->{source_suffixes}, ['.isf'], 'manifest limits the VHDL verification-output target to .isf');
    ok($vhdl_target->{requires_verification_observations}, 'manifest records the VHDL observation metadata prerequisite');
    is(
        $vhdl_target->{artifact_language},
        'vhdl',
        'manifest records the VHDL artifact language',
    );
    is(
        $vhdl_target->{artifact_relpath_pattern},
        'vhdl/<actor>_observation_vhdl_pkg.vhd',
        'manifest records the VHDL package artifact path pattern',
    );
    is(
        $vhdl_target->{manifest_relpath},
        'verification-output-manifest.json',
        'manifest records the VHDL artifact manifest path',
    );
    ok(
        !$manifest->{verification_outputs}{validation}{claimed_vhdl_compile_support},
        'manifest does not claim VHDL compile support for the skeleton target',
    );
    is(
        $manifest->{verification_outputs}{validation}{vhdl_syntax_validator},
        'none',
        'manifest records no VHDL syntax validator for the skeleton target',
    );
    ok(
        !$manifest->{verification_outputs}{validation}{claimed_psl_support},
        'manifest does not claim PSL support for the skeleton target',
    );
    is(
        $manifest->{verification_outputs}{validation}{psl_validator},
        'none',
        'manifest records no PSL validator for the skeleton target',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/same-family mixed auto-ID plus concrete queue-head response-demux with scalar, raw-ARLEN, runtime-validation, and multi-beat output-bank read-data over the selected read burst-last shape/,
        'manifest advertises shipped mixed auto-ID queue-head scalar, runtime-validation, and multi-beat read-data',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/generated one-dynamic plus one-concrete-static mixed dynamic\/static same-ID issue-order queue behavior for write BID, read single-beat RID, and read burst-last RID\/RLAST, generated one-dynamic plus two-concrete-static mixed dynamic\/static write BID same-ID issue-order queue behavior, paired scalar read-data over the generated mixed read single-beat and burst-last queue completions, report-only raw-ARLEN burst-length capture, runtime beat-count\/RLAST validation, and runtime-validation multi-beat output banks over the generated mixed read burst-last queue completion/,
        'manifest advertises shipped mixed dynamic/static same-ID issue-order queues, selected write multi-static coverage, scalar read-data, raw-ARLEN, runtime validation, and multi-beat output banks',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/paired scalar read-data over the generated mixed read single-beat and burst-last queue completions, report-only raw-ARLEN burst-length capture, runtime beat-count\/RLAST validation, and runtime-validation multi-beat output banks over the generated mixed read burst-last queue completion/,
        'manifest advertises shipped mixed dynamic/static issue-order queue scalar read-data, raw-ARLEN, runtime validation, and multi-beat output banks',
    );
    like(
        $file_surface_by_suffix{'.ppif'}{current_boundary},
        qr/Broader mixed issue-order queue cardinality beyond that selected write BID multi-static shape/,
        'manifest keeps broader mixed dynamic/static issue-order queue cardinality deferred beyond the selected write multi-static shape',
    );
    is($file_surface_by_suffix{'.axi'}{intent_layer}, 'IAL2', 'manifest marks .axi as IAL2');
    is(
        $file_surface_by_suffix{'.axi'}{status},
        'shipped_bounded_profile_alias',
        'manifest marks .axi as a bounded profile-alias surface',
    );
    is_deeply(
        $file_surface_by_suffix{'.axi'}{lowers_to},
        ['.isf', '.fsm'],
        'manifest records .axi lowering through .isf before .fsm',
    );
    is_deeply(
        $file_surface_by_suffix{'.axi'}{generated_review_artifacts},
        ['.isf', '.fsm'],
        'manifest records .axi generated review artifacts',
    );
    my %axi_cli_modes = map { $_ => 1 } @{$file_surface_by_suffix{'.axi'}{supported_cli_modes} || []};
    ok($axi_cli_modes{'--emit-schedule-json'}, 'manifest records .axi schedule-report CLI mode');
    ok($axi_cli_modes{'--emit-semantic-json'}, 'manifest records .axi semantic JSON CLI mode');
    ok($axi_cli_modes{'--check --json / --check-json'}, 'manifest records .axi check JSON CLI mode');
    is(
        $file_surface_by_suffix{'.axi'}{sample_path},
        'ppif/axi_aw_valid_ready.axi',
        'manifest points at the first .axi profile-alias sample',
    );
    like(
        $file_surface_by_suffix{'.axi'}{current_boundary},
        qr/first IAL2 profile-alias suffix/,
        'manifest describes .axi as the first IAL2 profile-alias suffix',
    );
    like(
        $file_surface_by_suffix{'.axi'}{current_boundary},
        qr/only an AXI example over IAL2, not the definition of IAL2/,
        'manifest keeps .axi scoped as an example over IAL2',
    );
    like(
        $file_surface_by_suffix{'.axi'}{current_boundary},
        qr/must declare an explicit AXI-family profile axi, axi3, axi4, or axi5/,
        'manifest records explicit AXI-family profile matching for .axi',
    );
    like(
        $file_surface_by_suffix{'.axi'}{current_boundary},
        qr/Direct IAL2-to-IAL0 lowering remains forbidden/,
        'manifest keeps direct IAL2-to-IAL0 lowering forbidden for .axi',
    );
    is($file_surface_by_suffix{'.apb'}{intent_layer}, 'IAL2', 'manifest marks .apb as IAL2');
    is(
        $file_surface_by_suffix{'.apb'}{status},
        'shipped_bounded_profile_alias',
        'manifest marks .apb as a bounded profile-alias surface',
    );
    is_deeply(
        $file_surface_by_suffix{'.apb'}{lowers_to},
        ['.isf', '.fsm'],
        'manifest records .apb lowering through .isf before .fsm',
    );
    is_deeply(
        $file_surface_by_suffix{'.apb'}{generated_review_artifacts},
        ['.isf', '.fsm'],
        'manifest records .apb generated review artifacts',
    );
    my %apb_cli_modes = map { $_ => 1 } @{$file_surface_by_suffix{'.apb'}{supported_cli_modes} || []};
    ok($apb_cli_modes{'--emit-schedule-json'}, 'manifest records .apb schedule-report CLI mode');
    ok($apb_cli_modes{'--emit-semantic-json'}, 'manifest records .apb semantic JSON CLI mode');
    ok($apb_cli_modes{'--check --json / --check-json'}, 'manifest records .apb check JSON CLI mode');
    is(
        $file_surface_by_suffix{'.apb'}{sample_path},
        'ppif/apb_requester_transfer.apb',
        'manifest points at the first .apb profile-alias sample',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected status back-to-back APB requester-transfer, sideband-aware APB requester-transfer, sideband-aware data16 APB requester-transfer, selected sideband-aware data16 status back-to-back APB requester-transfer, APB completer, selected back-to-back APB completer, selected sideband-aware back-to-back APB completer, APB multi-register completer, sideband-aware APB multi-register completer, selected sideband-aware back-to-back APB multi-register completer, sideband-aware protection APB multi-register completer, selected sideband-aware protection back-to-back APB multi-register completer, sideband-aware data16 APB multi-register completer, selected sideband-aware data16 back-to-back APB multi-register completer, sideband-aware data16 protection APB multi-register completer, selected sideband-aware data16 protection back-to-back APB multi-register completer, fixed one-requester\/one-completer APB composition, .*selected status back-to-back fixed APB composition, selected sideband-aware status back-to-back fixed APB composition, .*selected sideband-aware status back-to-back multi-register fixed APB composition, sideband-aware protection multi-register fixed APB composition, selected sideband-aware protection status back-to-back multi-register fixed APB composition, .*sideband-aware data16 multi-register fixed APB composition, selected sideband-aware data16 status back-to-back multi-register fixed APB composition, .*sideband-aware data16 protection multi-register fixed APB composition, selected sideband-aware data16 protection status back-to-back multi-register fixed APB composition, .*selected sideband-aware data16 no-policy multi-register status back-to-back one-requester\/two-peripheral APB interconnect\/decode composition, selected bounded sideband-aware data16 generalized no-policy multi-register status back-to-back one-requester\/two-peripheral APB interconnect\/decode composition, .*sideband-aware protection one-requester\/two-peripheral APB interconnect\/decode composition, .*sideband-aware data16 one-requester\/two-peripheral APB interconnect\/decode composition, .*sideband-aware data16 protection one-requester\/two-peripheral APB interconnect\/decode composition, and selected sideband-aware data16 protection status back-to-back one-requester\/two-peripheral APB interconnect\/decode composition IAL2 profile-alias suffix/,
        'manifest describes .apb as the bounded APB profile-alias suffix',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/optional response \(busy NAME\)/,
        'manifest records the optional APB requester busy response for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected busy-gated \(status NAME width 2\)/,
        'manifest records the selected APB requester status response for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected back-to-back response \(accepted NAME\) with \(timing-policy \(back-to-back queued\) \(queue-depth 1\) \(overflow reject\)\) for the 32-bit no-sideband requester, selected 32-bit sideband-aware requester, or selected sideband-aware data16 requester/,
        'manifest records the selected APB requester back-to-back response for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/optional selected \(timing-policy \(setup-admission adjacent\)\)/,
        'manifest records the selected APB completer adjacent setup timing policy for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware data16 two-register no-policy completer/,
        'manifest records the selected APB data16 two-register adjacent setup timing policy for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware data16 two-register protection completer/,
        'manifest records the selected APB data16 protected two-register adjacent setup timing policy for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected 32-bit sideband-aware two-register protection completer/,
        'manifest records the selected APB protected two-register adjacent setup timing policy for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/must declare explicit \(profile apb\)/,
        'manifest records explicit APB profile matching for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/lower through generated \.isf before generated \.fsm/,
        'manifest records generated APB review artifacts for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/ppif\/apb_requester_transfer\.ppif, ppif\/apb_requester_transfer_busy\.ppif, ppif\/apb_requester_transfer_status\.ppif, ppif\/apb_requester_transfer_status_back_to_back\.ppif, ppif\/apb_requester_transfer_sideband\.ppif, ppif\/apb_requester_transfer_sideband_status_back_to_back\.ppif, ppif\/apb_requester_transfer_sideband_data16\.ppif, ppif\/apb_requester_transfer_sideband_data16_status_back_to_back\.ppif, ppif\/apb_completer\.ppif, ppif\/apb_completer_back_to_back\.ppif, ppif\/apb_completer_sideband_back_to_back\.ppif, ppif\/apb_completer_multi_register\.ppif, ppif\/apb_completer_multi_register_sideband\.ppif, ppif\/apb_completer_multi_register_sideband_back_to_back\.ppif, ppif\/apb_completer_multi_register_sideband_protection\.ppif, ppif\/apb_completer_multi_register_sideband_protection_back_to_back\.ppif, ppif\/apb_completer_multi_register_sideband_data16\.ppif, ppif\/apb_completer_multi_register_sideband_data16_back_to_back\.ppif, ppif\/apb_completer_multi_register_sideband_data16_protection\.ppif, ppif\/apb_completer_multi_register_sideband_data16_protection_back_to_back\.ppif, ppif\/apb_composition\.ppif, ppif\/apb_composition_busy\.ppif, ppif\/apb_composition_status\.ppif, ppif\/apb_composition_status_back_to_back\.ppif, ppif\/apb_composition_sideband_status_back_to_back\.ppif, ppif\/apb_composition_multi_register\.ppif, ppif\/apb_composition_multi_register_sideband\.ppif, ppif\/apb_composition_multi_register_sideband_status_back_to_back\.ppif, ppif\/apb_composition_multi_register_sideband_protection\.ppif, ppif\/apb_composition_multi_register_sideband_protection_status_back_to_back\.ppif, ppif\/apb_composition_multi_register_sideband_data16\.ppif, ppif\/apb_composition_multi_register_sideband_data16_status_back_to_back\.ppif, ppif\/apb_composition_multi_register_sideband_data16_protection\.ppif, ppif\/apb_composition_multi_register_sideband_data16_protection_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral\.ppif, ppif\/apb_composition_multi_peripheral_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_sideband_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_sideband\.ppif, ppif\/apb_composition_multi_peripheral_sideband_protection\.ppif, ppif\/apb_composition_multi_peripheral_sideband_protection_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_sideband_data16\.ppif, ppif\/apb_composition_multi_peripheral_sideband_data16_protection\.ppif, ppif\/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back\.ppif, ppif\/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back\.ppif, and ppif\/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back\.ppif at matching \.apb paths/,
        'manifest records the shipped APB profile-alias samples',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/busy-capable requester and composition aliases add the requester busy output/,
        'manifest records the APB busy output on busy-capable aliases',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/status-capable requester and composition aliases add busy plus a 2-bit requester status output/,
        'manifest records the APB status output on status-capable aliases',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected back-to-back requester\/composition aliases add accepted pulses plus a depth-1 queued admission path with overflow reject and adjacent next setup/,
        'manifest records the selected APB back-to-back requester and composition alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband requester back-to-back aliases also queue and relaunch PPROT\/PSTRB with the accepted request payload/,
        'manifest records the selected APB sideband requester back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband data16 requester back-to-back aliases queue and relaunch 16-bit PWDATA\/PRDATA plus 2-bit PSTRB with the accepted request payload/,
        'manifest records the selected APB sideband data16 requester back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware fixed composition aliases combine that queued sideband requester policy with adjacent sideband completer setup admission/,
        'manifest records the selected APB sideband fixed-composition back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware data16 multi-register fixed composition aliases combine queued data16 sideband requester timing with adjacent sideband data16 two-register no-policy or protected completer setup admission/,
        'manifest records the selected APB sideband data16 multi-register fixed-composition back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware protected multi-register fixed composition aliases combine that queued sideband requester policy with adjacent sideband two-register protection completer setup admission/,
        'manifest records the selected APB sideband protection multi-register fixed-composition back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware multi-peripheral status back-to-back aliases also propagate queued PPROT\/PSTRB through the generated interconnect/,
        'manifest records the selected APB sideband multi-peripheral back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected 32-bit sideband-aware no-policy two-register two-peripheral shape with requester accepted\/busy\/status and adjacent setup admission on both reg0\/reg1 peripheral completers/,
        'manifest records the selected APB no-policy multi-register multi-peripheral adjacent setup timing policy for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware data16 no-policy two-register two-peripheral shape with requester accepted\/busy\/status and adjacent setup admission on both reg0\/reg1 peripheral completers/,
        'manifest records the selected APB data16 no-policy multi-register multi-peripheral adjacent setup timing policy for .apb',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware no-policy multi-peripheral multi-register status back-to-back aliases propagate queued 32-bit PWDATA plus PPROT\/PSTRB through the generated interconnect and use adjacent setup on both selected reg0\/reg1 no-policy peripheral completers/,
        'manifest records the selected APB no-policy multi-peripheral multi-register back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware data16 no-policy multi-peripheral multi-register status back-to-back aliases propagate queued 16-bit PWDATA plus PPROT\/PSTRB through the generated interconnect and use adjacent setup on both selected reg0\/reg1 no-policy peripheral completers/,
        'manifest records the selected APB data16 no-policy multi-peripheral multi-register back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected bounded sideband-aware data16 generalized no-policy multi-register status back-to-back one-requester\/two-peripheral APB interconnect\/decode composition/,
        'manifest records the selected APB data16 generalized no-policy multi-peripheral multi-register back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected bounded sideband-aware data16 generalized no-policy multi-register status back-to-back aliases propagate queued 16-bit PWDATA plus PPROT\/PSTRB through the generated interconnect and use adjacent setup on both selected reg0\.\.regN no-policy two-to-six-register peripheral completers/,
        'manifest records the selected APB data16 generalized no-policy two-to-six boundary',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware multi-peripheral protection status back-to-back aliases propagate queued 32-bit PWDATA plus PPROT\/PSTRB through the generated interconnect and keep protection enforcement in selected peripheral completers/,
        'manifest records the selected APB sideband protection multi-peripheral back-to-back alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected back-to-back completer aliases explicitly report adjacent PSEL && !PENABLE setup admission/,
        'manifest records the selected APB back-to-back completer alias behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware two-register protection/,
        'manifest records selected protected two-register completer adjacent setup behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/selected sideband-aware data16 two-register protection/,
        'manifest records selected protected data16 two-register completer adjacent setup behavior',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/multi-register completer\/composition aliases decode source-ordered 32-bit aligned register addresses/,
        'manifest records the APB multi-register decode boundary for profile aliases',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/sideband-aware requester\/completer\/composition aliases propagate PPROT, drive or sample PSTRB, and apply PSTRB byte-lane writes/,
        'manifest records the APB sideband/strobe boundary for profile aliases',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/sideband-aware data16 aliases use 16-bit PWDATA\/PRDATA\/register data with 2-bit PSTRB and two byte lanes/,
        'manifest records the APB data16 sideband width boundary for profile aliases',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/sideband-aware 32-bit and data16 protection completer\/composition aliases enforce register-local privileged PPROT\[0\] policies/,
        'manifest records the APB sideband data16 protection policy boundary for profile aliases',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/multi-peripheral composition aliases fan out decoded PSEL, translate local PADDR, mux selected responses, and return PSLVERR for unmapped active accesses/,
        'manifest records the APB multi-peripheral interconnect/decode boundary for profile aliases',
    );
    like(
        $file_surface_by_suffix{'.apb'}{current_boundary},
        qr/Direct IAL2-to-IAL0 lowering|direct IAL2-to-IAL0 lowering/,
        'manifest keeps direct IAL2-to-IAL0 lowering forbidden for .apb',
    );
    is($file_surface_by_suffix{'.ahb'}{intent_layer}, 'IAL2', 'manifest marks .ahb as IAL2');
    is(
        $file_surface_by_suffix{'.ahb'}{status},
        'shipped_bounded_profile_alias',
        'manifest marks .ahb as a bounded profile-alias surface',
    );
    is_deeply(
        $file_surface_by_suffix{'.ahb'}{lowers_to},
        ['.isf', '.fsm'],
        'manifest records .ahb lowering through .isf before .fsm',
    );
    is_deeply(
        $file_surface_by_suffix{'.ahb'}{generated_review_artifacts},
        ['.isf', '.fsm'],
        'manifest records .ahb generated review artifacts',
    );
    my %ahb_cli_modes = map { $_ => 1 } @{$file_surface_by_suffix{'.ahb'}{supported_cli_modes} || []};
    ok($ahb_cli_modes{'--emit-schedule-json'}, 'manifest records .ahb schedule-report CLI mode');
    ok($ahb_cli_modes{'--emit-semantic-json'}, 'manifest records .ahb semantic JSON CLI mode');
    ok($ahb_cli_modes{'--check --json / --check-json'}, 'manifest records .ahb check JSON CLI mode');
    is(
        $file_surface_by_suffix{'.ahb'}{sample_path},
        'ppif/ahb_requester.ahb',
        'manifest points at the .ahb profile-alias sample',
    );
    like(
        $file_surface_by_suffix{'.ahb'}{current_boundary},
        qr/bounded public \.ahb is the AHB requester, word-only subordinate, byte-lane\/narrow-transfer subordinate, byte-lane in-word SEQ subordinate, HBURST-aware byte-lane in-word SEQ subordinate, HBURST-aware byte-lane in-word SEQ subordinate with BUSY-in-burst parking, one-requester\/one-subordinate aggregate interconnect, selected one-requester\/two-subordinate aggregate interconnect, selected one-requester\/one-subordinate aggregate byte-lane interconnect, selected one-requester\/two-subordinate aggregate byte-lane interconnect, selected one-requester\/one-subordinate aggregate byte-lane in-word SEQ interconnect, selected one-requester\/two-subordinate aggregate byte-lane in-word SEQ interconnect, selected one-requester\/one-subordinate aggregate HBURST-aware byte-lane SEQ interconnect, selected one-requester\/two-subordinate aggregate HBURST-aware byte-lane SEQ interconnect, selected one-requester\/one-subordinate aggregate HBURST-aware byte-lane SEQ interconnect with BUSY-in-burst parking, and selected one-requester\/two-subordinate aggregate HBURST-aware byte-lane SEQ interconnect with BUSY-in-burst parking profile-alias suffix/,
        'manifest describes .ahb as the bounded AHB requester, subordinate, aggregate interconnect, aggregate byte-lane, and aggregate byte-lane SEQ profile-alias suffix',
    );
    like(
        $file_surface_by_suffix{'.ahb'}{current_boundary},
        qr/must declare explicit \(profile ahb\)/,
        'manifest records explicit AHB profile matching for .ahb',
    );
    like(
        $file_surface_by_suffix{'.ahb'}{current_boundary},
        qr/support exactly one \(ahb-requester amba_requester \.\.\.\) object, exactly one word-only \(ahb-subordinate ahb_lite_subordinate \.\.\.\) object, exactly one byte-lane\/narrow-transfer \(ahb-subordinate ahb_lite_subordinate_byte_lane \.\.\.\) object, exactly one byte-lane in-word SEQ \(ahb-subordinate ahb_lite_subordinate_byte_lane_seq \.\.\.\) object, exactly one HBURST-aware byte-lane in-word SEQ \(ahb-subordinate ahb_lite_subordinate_byte_lane_hburst_seq \.\.\.\) object, exactly one HBURST-aware byte-lane in-word SEQ with BUSY-in-burst parking \(ahb-subordinate ahb_lite_subordinate_byte_lane_hburst_seq_busy_park \.\.\.\) object, the selected aggregate one-requester\/one-subordinate \(ahb-interconnect ahb_tb \.\.\.\) shape, or the selected aggregate one-requester\/two-subordinate \(ahb-interconnect ahb_tb \.\.\.\) shape in this slice, including aggregate byte-lane subordinate variants/,
        'manifest records the selected AHB requester, subordinate, or aggregate interconnect boundaries for .ahb',
    );
    like(
        $file_surface_by_suffix{'.ahb'}{current_boundary},
        qr/lower through generated \.isf before generated \.fsm/,
        'manifest records generated AHB review artifacts for .ahb',
    );
    like(
        $file_surface_by_suffix{'.ahb'}{current_boundary},
        qr/mirror ppif\/ahb_requester\.ppif at ppif\/ahb_requester\.ahb, ppif\/ahb_lite_subordinate\.ppif at ppif\/ahb_lite_subordinate\.ahb, ppif\/ahb_lite_subordinate_byte_lane\.ppif at ppif\/ahb_lite_subordinate_byte_lane\.ahb, ppif\/ahb_lite_subordinate_byte_lane_seq\.ppif at ppif\/ahb_lite_subordinate_byte_lane_seq\.ahb, ppif\/ahb_lite_subordinate_byte_lane_hburst_seq\.ppif at ppif\/ahb_lite_subordinate_byte_lane_hburst_seq\.ahb, ppif\/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park\.ppif at ppif\/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park\.ahb, ppif\/ahb_interconnect\.ppif at ppif\/ahb_interconnect\.ahb, ppif\/ahb_interconnect_two_subordinate\.ppif at ppif\/ahb_interconnect_two_subordinate\.ahb, ppif\/ahb_interconnect_byte_lane\.ppif at ppif\/ahb_interconnect_byte_lane\.ahb, ppif\/ahb_interconnect_two_subordinate_byte_lane\.ppif at ppif\/ahb_interconnect_two_subordinate_byte_lane\.ahb, ppif\/ahb_interconnect_byte_lane_seq\.ppif at ppif\/ahb_interconnect_byte_lane_seq\.ahb, ppif\/ahb_interconnect_two_subordinate_byte_lane_seq\.ppif at ppif\/ahb_interconnect_two_subordinate_byte_lane_seq\.ahb, ppif\/ahb_interconnect_byte_lane_hburst_seq\.ppif at ppif\/ahb_interconnect_byte_lane_hburst_seq\.ahb, and ppif\/ahb_interconnect_two_subordinate_byte_lane_hburst_seq\.ppif at ppif\/ahb_interconnect_two_subordinate_byte_lane_hburst_seq\.ahb/,
        'manifest records the shipped AHB profile-alias samples',
    );
    like(
        $file_surface_by_suffix{'.ahb'}{current_boundary},
        qr/plus the aggregate BUSY-park pair ppif\/ahb_interconnect_byte_lane_hburst_seq_busy_park\.ppif at ppif\/ahb_interconnect_byte_lane_hburst_seq_busy_park\.ahb and ppif\/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park\.ppif at ppif\/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park\.ahb/,
        'manifest records the shipped aggregate BUSY-park .ahb profile-alias samples',
    );
    like(
        $file_surface_by_suffix{'.ahb'}{current_boundary},
        qr/Non-AHB profiles are rejected as suffix\/profile mismatches for \.ahb/,
        'manifest records non-AHB suffix/profile rejection for .ahb',
    );
    like(
        $file_surface_by_suffix{'.ahb'}{current_boundary},
        qr/AHB completers, broader AHB interconnect\/decode beyond the selected one-requester\/one-subordinate and one-requester\/two-subordinate static-window aggregates, optional subordinate signals/,
        'manifest keeps broader AHB profile-alias follow-on work deferred for .ahb',
    );
    like(
        $file_surface_by_suffix{'.ahb'}{current_boundary},
        qr/direct IAL2-to-IAL0 lowering/,
        'manifest keeps direct IAL2-to-IAL0 lowering forbidden for .ahb',
    );
    my %unsupported_aliases = map { $_ => 1 } @{$manifest->{language_surface}{file_surfaces}{unsupported_first_slice_aliases}};
    ok($unsupported_aliases{'.pif'}, 'manifest keeps .pif unsupported in the first PPIF slice');
    ok($unsupported_aliases{'.ppi'}, 'manifest keeps .ppi unsupported in the first PPIF slice');
    ok(!$unsupported_aliases{'.axi'}, 'manifest no longer lists .axi as unsupported after the first profile-alias slice');
    ok(!$unsupported_aliases{'.apb'}, 'manifest no longer lists .apb as unsupported after the APB profile-alias slice');
    ok(!$unsupported_aliases{'.ahb'}, 'manifest no longer lists .ahb as unsupported after the AHB profile-alias slice');
    for my $profile_alias (qw(.chi .ace .atb .smbus .i2s)) {
        ok(
            $unsupported_aliases{$profile_alias},
            "manifest keeps $profile_alias unsupported as a future IAL2 profile alias",
        );
    }
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
        language_surface_contract_source(),
        'manifest records the language-surface contract owner',
    );
    is_deeply(
        $manifest->{language_surface}{surface_contract}{nested_presence_key_map},
        language_surface_nested_presence_key_map(),
        'manifest records the grouped language-surface first nested key-family map through the language-surface contract',
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
        documentation_contract_source(),
        'manifest records the documentation contract owner',
    );
    is_deeply(
        $manifest->{documentation}{section_contract}{path_list_contract_map},
        documentation_path_list_contract_map(),
        'manifest records the grouped documentation path-list contract map through the documentation section contract',
    );

    my %literal_families = map { $_ => 1 } @{$manifest->{language_surface}{expressions}{literal_families}};
    ok(
        $literal_families{q{FSMGen intent-sized literals like 5'23, 8'-10, 8'-0xA, 8'-0b1010, and 20'x1}},
        'manifest advertises intent-level sized literal normalization',
    );
    my %guard_forms = map { $_ => 1 } @{$manifest->{language_surface}{expressions}{guard_forms}};
    ok(
        $guard_forms{'state DT DTE headers such as (idle <entry_event ...) and non-state DT DTE headers such as (-route <req ...)'},
        'manifest advertises guarded state and non-state DT DTE headers',
    );

    my %human_contract_docs = map { $_ => 1 } @{$manifest->{documentation}{human_contract} || []};
    ok($human_contract_docs{'docs/book/src/SUMMARY.md'}, 'manifest points human readers at the book summary');
    ok($human_contract_docs{'docs/book/src/90-reference-map.md'}, 'manifest points human readers at the book reference map');
    ok(
        $human_contract_docs{'docs/book/src/10-errors-strict-mode-and-troubleshooting.md'},
        'manifest points human readers at runtime diagnostic guidance',
    );
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

sub _family_map_expected {
    my ($field, $expected) = @_;
    return [$expected] if ($field || '') =~ /package_import_entry_value_meaning\z/;
    return $expected;
}

sub assert_manifest_section_contract_sources {
    my ($manifest, $expected_map, $label) = @_;
    for my $key (sort keys %{$expected_map || {}}) {
        my $slot = $key eq 'language_surface' ? 'surface_contract' : 'section_contract';
        is(
            $manifest->{$key}{$slot}{contract_source},
            $expected_map->{$key},
            "$label: $key keeps advertised section contract owner",
        );
    }
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub contains_value {
    my ($values, $target) = @_;
    return grep { $_ eq $target } @{$values || []};
}
