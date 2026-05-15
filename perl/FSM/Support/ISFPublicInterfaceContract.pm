package FSM::Support::ISFPublicInterfaceContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();
use FSM::Support::ISFResourceCatalog qw(
    isf_backlog_resource_kind_values
    isf_enforced_resource_kind_values
    isf_resource_arbiter_values
    isf_resource_kind_meaning_map
    isf_resource_kind_status_map
    isf_resource_kind_values
);

our @EXPORT_OK = qw(
    build_isf_public_interface_contract
    isf_public_interface_actor_shell_drive_shape
    isf_public_interface_actor_shell_actor_name_shape
    isf_public_interface_actor_shell_interface_shape
    isf_public_interface_actor_shell_required_keys
    isf_public_interface_actor_shell_rule_shape
    isf_public_interface_actor_shell_timing_shape
    isf_public_interface_actor_shell_transaction_shape
    isf_public_interface_actor_shell_value_shape
    isf_public_interface_cli_hdl_generation_success_shape
    isf_public_interface_cli_option_names
    isf_public_interface_cli_outdir_success_shape
    isf_public_interface_cli_schedule_json_success_shape
    isf_public_interface_cli_strict_hdl_generation_success_shape
    isf_public_interface_contract_source
    isf_public_interface_constructor_option_names
    isf_public_interface_dt_assignment_operator_family_map
    isf_public_interface_facade_failure_diagnostic_shape
    isf_public_interface_backlog_resource_kind_values
    isf_public_interface_enforced_resource_kind_values
    isf_public_interface_library_catalog_entry_keys
    isf_public_interface_library_catalog_paths
    isf_public_interface_live_document_paths
    isf_public_interface_lower_return_shape
    isf_public_interface_lower_result_file_name_shape
    isf_public_interface_lower_result_file_text_shape
    isf_public_interface_lower_result_presence_keys
    isf_public_interface_dt_ordering_policy
    isf_public_interface_parse_file_return_shape
    isf_public_interface_parse_source_return_shape
    isf_public_interface_parser_method_names
    isf_public_interface_public_top_level_keys
    isf_public_interface_resource_arbiter_values
    isf_public_interface_resource_kind_meaning_map
    isf_public_interface_resource_kind_status_map
    isf_public_interface_resource_kind_values
    isf_public_interface_schedule_report_compile_issues_success_shape
    isf_public_interface_schedule_report_clock_shape
    isf_public_interface_schedule_report_compile_issue_keys
    isf_public_interface_schedule_report_compile_issue_proof_status_values
    isf_public_interface_schedule_report_compile_issue_severity_values
    isf_public_interface_schedule_report_compile_issue_source_keys
    isf_public_interface_schedule_report_bank_access_keys
    isf_public_interface_schedule_report_bank_access_kind_values
    isf_public_interface_schedule_report_bank_access_policy_values
    isf_public_interface_schedule_report_dt_assignments_shape
    isf_public_interface_schedule_report_dt_kind_values
    isf_public_interface_schedule_report_fanin_group_kind_values
    isf_public_interface_schedule_report_fanin_group_optional_keys
    isf_public_interface_schedule_report_fanin_group_required_keys
    isf_public_interface_schedule_report_priority_resolution_keys
    isf_public_interface_schedule_report_resource_arbitration_keys
    isf_public_interface_schedule_report_generated_composition_binding_keys
    isf_public_interface_schedule_report_generated_composition_child_keys
    isf_public_interface_schedule_report_generated_composition_child_parameter_keys
    isf_public_interface_schedule_report_generated_composition_drive_handoff_keys
    isf_public_interface_schedule_report_generated_composition_instance_keys
    isf_public_interface_schedule_report_generated_composition_kind_values
    isf_public_interface_schedule_report_generated_composition_link_keys
    isf_public_interface_schedule_report_generated_composition_parent_keys
    isf_public_interface_schedule_report_generated_composition_payload_keys
    isf_public_interface_schedule_report_generated_composition_required_keys
    isf_public_interface_schedule_report_library_use_binding_keys
    isf_public_interface_schedule_report_library_use_keys
    isf_public_interface_schedule_report_library_use_parameter_keys
    isf_public_interface_schedule_report_multi_file_scope
    isf_public_interface_schedule_report_interface_count_shape
    isf_public_interface_schedule_report_presence_key_family_map
    isf_public_interface_schedule_report_reset_kind_values
    isf_public_interface_schedule_report_reset_keys
    isf_public_interface_schedule_report_reset_polarity_values
    isf_public_interface_schedule_report_reset_shape
    isf_public_interface_schedule_report_scheduled_fsm_shape
    isf_public_interface_schedule_report_source_shape
    isf_public_interface_schedule_report_state_count_shape
    isf_public_interface_schedule_report_storage_kind_values
    isf_public_interface_schedule_report_storage_optional_keys
    isf_public_interface_schedule_report_storage_required_keys
    isf_public_interface_schedule_report_storage_role_values
    isf_public_interface_schedule_report_storage_width_shape
    isf_public_interface_schedule_report_temporal_contract_assertion_projection_values
    isf_public_interface_schedule_report_temporal_contract_keys
    isf_public_interface_schedule_report_temporal_contract_kind_values
    isf_public_interface_schedule_report_temporal_contract_overlap_policy_values
    isf_public_interface_schedule_report_temporal_contract_reset_policy_shape
    isf_public_interface_schedule_report_top_level_keys
    isf_public_interface_schedule_report_transaction_loop_keys
    isf_public_interface_schedule_report_transaction_wait_keys
    isf_public_interface_schedule_report_transaction_port_binding_keys
    isf_public_interface_schedule_report_transaction_port_binding_site_kind_values
    isf_public_interface_schedule_report_transaction_stage_keys
    isf_public_interface_schedule_report_transaction_stage_kind_values
    isf_public_interface_schedule_report_transaction_count_shape
    isf_public_interface_schedule_report_transaction_ordering
    isf_public_interface_schedule_report_transaction_states_shape
    isf_public_interface_schedule_report_transaction_keys
    isf_public_interface_schedule_report_watchdog_shape
    isf_public_interface_shipped_library_definitions
    isf_public_interface_report_return_shape
    isf_public_interface_schedule_report_dt_keys
    isf_public_interface_scheduler_method_names
);

sub isf_public_interface_contract_source {
    return 'FSM::Support::ISFPublicInterfaceContract';
}

sub build_isf_public_interface_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => isf_public_interface_contract_source(),
        implementation_owners => [
            'FSM::Adapter::ISF',
            'FSM::Scheduler::ISF',
            'FSM::Scheduler::ISF::Emitter::FSM',
            'FSM::Scheduler::ISF::Emitter::JSON',
        ],
        entrypoints => {
            manifest => './bin/fsmgen --capability-manifest -> embedding.isf_public_interface',
            cli => [
                './bin/fsmgen path/to/file.isf',
                './bin/fsmgen --emit-schedule-json path/to/file.isf',
                './bin/fsmgen --outdir path/to/outdir path/to/file.isf',
            ],
            in_process => [
                'FSM::Adapter::ISF->new(%args)',
                'FSM::Adapter::ISF->new(%args)->parse_file($path)',
                'FSM::Adapter::ISF->new(%args)->parse_source($source_text, $source_label)',
                'FSM::Scheduler::ISF->new(%args)',
                'FSM::Scheduler::ISF->new(%args)->lower($actor)',
                'FSM::Scheduler::ISF->new(%args)->report($actor)',
            ],
        },
        public_top_level_presence_keys => isf_public_interface_public_top_level_keys(),
        parser_method_names => isf_public_interface_parser_method_names(),
        scheduler_method_names => isf_public_interface_scheduler_method_names(),
        constructor_option_names => isf_public_interface_constructor_option_names(),
        cli_option_names => isf_public_interface_cli_option_names(),
        resource_arbiter_values => isf_public_interface_resource_arbiter_values(),
        resource_kind_values => isf_public_interface_resource_kind_values(),
        resource_kind_status_map => isf_public_interface_resource_kind_status_map(),
        resource_kind_meaning_map => isf_public_interface_resource_kind_meaning_map(),
        enforced_resource_kind_values => isf_public_interface_enforced_resource_kind_values(),
        backlog_resource_kind_values => isf_public_interface_backlog_resource_kind_values(),
        library_catalog_paths => isf_public_interface_library_catalog_paths(),
        library_catalog_entry_keys => isf_public_interface_library_catalog_entry_keys(),
        shipped_library_definitions => isf_public_interface_shipped_library_definitions(),
        cli_schedule_json_success_shape => isf_public_interface_cli_schedule_json_success_shape(),
        cli_outdir_success_shape => isf_public_interface_cli_outdir_success_shape(),
        cli_hdl_generation_success_shape => isf_public_interface_cli_hdl_generation_success_shape(),
        cli_strict_hdl_generation_success_shape => isf_public_interface_cli_strict_hdl_generation_success_shape(),
        constructor_receiver_shape => 'exact class invocant: FSM::Adapter::ISF or FSM::Scheduler::ISF',
        constructor_argument_shape => 'even-length option/value list after class invocant; currently only debug is public',
        parser_method_receiver_shape => 'object returned by FSM::Adapter::ISF->new(...)',
        scheduler_method_receiver_shape => 'object returned by FSM::Scheduler::ISF->new(...)',
        parse_file_argument_shape => 'exactly one scalar filesystem path to a .isf source after object invocant',
        parse_file_path_requirement => 'defined scalar path with .isf suffix naming a readable regular file before private parsing',
        parse_source_argument_shape => 'exactly two scalar arguments after object invocant: source text and source label',
        parse_file_return_shape => isf_public_interface_parse_file_return_shape(),
        parse_source_return_shape => isf_public_interface_parse_source_return_shape(),
        lower_argument_shape => 'scheduler-consumable actor value returned by FSM::Adapter::ISF',
        report_argument_shape => 'scheduler-consumable actor value returned by FSM::Adapter::ISF',
        facade_failure_diagnostic_shape => isf_public_interface_facade_failure_diagnostic_shape(),
        lower_return_shape => isf_public_interface_lower_return_shape(),
        report_return_shape => isf_public_interface_report_return_shape(),
        actor_shell_required_keys => isf_public_interface_actor_shell_required_keys(),
        actor_shell_value_shape => isf_public_interface_actor_shell_value_shape(),
        actor_shell_actor_name_shape => isf_public_interface_actor_shell_actor_name_shape(),
        actor_shell_timing_shape => isf_public_interface_actor_shell_timing_shape(),
        actor_shell_interface_shape => isf_public_interface_actor_shell_interface_shape(),
        actor_shell_transaction_shape => isf_public_interface_actor_shell_transaction_shape(),
        actor_shell_rule_shape => isf_public_interface_actor_shell_rule_shape(),
        actor_shell_drive_shape => isf_public_interface_actor_shell_drive_shape(),
        lower_result_presence_keys => isf_public_interface_lower_result_presence_keys(),
        lower_result_file_map_shape => 'hash reference mapping .fsm basename to scheduled module, specialized library-child module, or generated composition-top .fsm source text',
        lower_result_file_name_shape => isf_public_interface_lower_result_file_name_shape(),
        lower_result_file_text_shape => isf_public_interface_lower_result_file_text_shape(),
        dt_assignment_operator_family_map => isf_public_interface_dt_assignment_operator_family_map(),
        scheduled_fsm_dt_ordering => isf_public_interface_dt_ordering_policy(),
        schedule_report_top_level_keys => isf_public_interface_schedule_report_top_level_keys(),
        schedule_report_source_shape => isf_public_interface_schedule_report_source_shape(),
        schedule_report_scheduled_fsm_shape => isf_public_interface_schedule_report_scheduled_fsm_shape(),
        schedule_report_clock_shape => isf_public_interface_schedule_report_clock_shape(),
        schedule_report_watchdog_shape => isf_public_interface_schedule_report_watchdog_shape(),
        schedule_report_compile_issues_success_shape => isf_public_interface_schedule_report_compile_issues_success_shape(),
        schedule_report_compile_issue_keys => isf_public_interface_schedule_report_compile_issue_keys(),
        schedule_report_compile_issue_source_keys => isf_public_interface_schedule_report_compile_issue_source_keys(),
        schedule_report_bank_access_keys => isf_public_interface_schedule_report_bank_access_keys(),
        schedule_report_bank_access_kind_values => isf_public_interface_schedule_report_bank_access_kind_values(),
        schedule_report_bank_access_policy_values => isf_public_interface_schedule_report_bank_access_policy_values(),
        schedule_report_transaction_port_binding_keys => isf_public_interface_schedule_report_transaction_port_binding_keys(),
        schedule_report_transaction_port_binding_site_kind_values => isf_public_interface_schedule_report_transaction_port_binding_site_kind_values(),
        schedule_report_compile_issue_severity_values => isf_public_interface_schedule_report_compile_issue_severity_values(),
        schedule_report_compile_issue_proof_status_values => isf_public_interface_schedule_report_compile_issue_proof_status_values(),
        schedule_report_fanin_group_required_keys => isf_public_interface_schedule_report_fanin_group_required_keys(),
        schedule_report_fanin_group_optional_keys => isf_public_interface_schedule_report_fanin_group_optional_keys(),
        schedule_report_fanin_group_kind_values => isf_public_interface_schedule_report_fanin_group_kind_values(),
        schedule_report_priority_resolution_keys => isf_public_interface_schedule_report_priority_resolution_keys(),
        schedule_report_resource_arbitration_keys => isf_public_interface_schedule_report_resource_arbitration_keys(),
        schedule_report_generated_composition_required_keys => isf_public_interface_schedule_report_generated_composition_required_keys(),
        schedule_report_generated_composition_kind_values => isf_public_interface_schedule_report_generated_composition_kind_values(),
        schedule_report_generated_composition_parent_keys => isf_public_interface_schedule_report_generated_composition_parent_keys(),
        schedule_report_generated_composition_child_keys => isf_public_interface_schedule_report_generated_composition_child_keys(),
        schedule_report_generated_composition_child_parameter_keys => isf_public_interface_schedule_report_generated_composition_child_parameter_keys(),
        schedule_report_generated_composition_instance_keys => isf_public_interface_schedule_report_generated_composition_instance_keys(),
        schedule_report_generated_composition_link_keys => isf_public_interface_schedule_report_generated_composition_link_keys(),
        schedule_report_generated_composition_binding_keys => isf_public_interface_schedule_report_generated_composition_binding_keys(),
        schedule_report_generated_composition_drive_handoff_keys => isf_public_interface_schedule_report_generated_composition_drive_handoff_keys(),
        schedule_report_generated_composition_payload_keys => isf_public_interface_schedule_report_generated_composition_payload_keys(),
        schedule_report_library_use_keys => isf_public_interface_schedule_report_library_use_keys(),
        schedule_report_library_use_parameter_keys => isf_public_interface_schedule_report_library_use_parameter_keys(),
        schedule_report_library_use_binding_keys => isf_public_interface_schedule_report_library_use_binding_keys(),
        schedule_report_multi_file_scope => isf_public_interface_schedule_report_multi_file_scope(),
        schedule_report_interface_count_shape => isf_public_interface_schedule_report_interface_count_shape(),
        schedule_report_state_count_shape => isf_public_interface_schedule_report_state_count_shape(),
        schedule_report_presence_key_family_map => isf_public_interface_schedule_report_presence_key_family_map(),
        schedule_report_reset_shape => isf_public_interface_schedule_report_reset_shape(),
        schedule_report_reset_keys => isf_public_interface_schedule_report_reset_keys(),
        schedule_report_reset_kind_values => isf_public_interface_schedule_report_reset_kind_values(),
        schedule_report_reset_polarity_values => isf_public_interface_schedule_report_reset_polarity_values(),
        schedule_report_storage_required_keys => isf_public_interface_schedule_report_storage_required_keys(),
        schedule_report_storage_optional_keys => isf_public_interface_schedule_report_storage_optional_keys(),
        schedule_report_storage_kind_values => isf_public_interface_schedule_report_storage_kind_values(),
        schedule_report_storage_role_values => isf_public_interface_schedule_report_storage_role_values(),
        schedule_report_storage_width_shape => isf_public_interface_schedule_report_storage_width_shape(),
        schedule_report_transaction_keys => isf_public_interface_schedule_report_transaction_keys(),
        schedule_report_transaction_states_shape => isf_public_interface_schedule_report_transaction_states_shape(),
        schedule_report_transaction_count_shape => isf_public_interface_schedule_report_transaction_count_shape(),
        schedule_report_transaction_ordering => isf_public_interface_schedule_report_transaction_ordering(),
        schedule_report_transaction_loop_keys => isf_public_interface_schedule_report_transaction_loop_keys(),
        schedule_report_transaction_wait_keys => isf_public_interface_schedule_report_transaction_wait_keys(),
        schedule_report_transaction_stage_keys => isf_public_interface_schedule_report_transaction_stage_keys(),
        schedule_report_transaction_stage_kind_values => isf_public_interface_schedule_report_transaction_stage_kind_values(),
        schedule_report_temporal_contract_keys => isf_public_interface_schedule_report_temporal_contract_keys(),
        schedule_report_temporal_contract_kind_values => isf_public_interface_schedule_report_temporal_contract_kind_values(),
        schedule_report_temporal_contract_overlap_policy_values => isf_public_interface_schedule_report_temporal_contract_overlap_policy_values(),
        schedule_report_temporal_contract_assertion_projection_values => isf_public_interface_schedule_report_temporal_contract_assertion_projection_values(),
        schedule_report_temporal_contract_reset_policy_shape => isf_public_interface_schedule_report_temporal_contract_reset_policy_shape(),
        schedule_report_dt_keys => isf_public_interface_schedule_report_dt_keys(),
        schedule_report_dt_kind_values => isf_public_interface_schedule_report_dt_kind_values(),
        schedule_report_dt_assignments_shape => isf_public_interface_schedule_report_dt_assignments_shape(),
        schedule_report_dt_ordering => isf_public_interface_dt_ordering_policy(),
        live_document_paths => isf_public_interface_live_document_paths(),
        live_contract_documentation => JSON::PP::true,
        evolves_with_isf_implementation => JSON::PP::true,
        raw_actor_full_hash_stable => JSON::PP::false,
        lowering_ir_full_hash_stable => JSON::PP::false,
        schedule_report_full_schema_stable => JSON::PP::false,
        scheduled_fsm_text_is_review_artifact => JSON::PP::true,
        tested_by => [
            't/1096-isf-schedule-json-report.t',
            't/1112-isf-public-interface-contract.t',
            't/1113-isf-public-interface-contract-json-roundtrip-audit.t',
            't/1114-isf-public-interface-contract-defensive-copy-audit.t',
            't/1115-isf-public-interface-cli-manifest-audit.t',
            't/1116-isf-public-schedule-report-key-family-audit.t',
            't/1117-isf-public-lower-result-files-audit.t',
            't/1118-isf-public-parse-source-facade-audit.t',
            't/1119-isf-deterministic-dt-block-order.t',
            't/1120-isf-public-live-document-path-audit.t',
            't/1121-isf-public-cli-schedule-report-audit.t',
            't/1122-isf-public-cli-outdir-lowering-audit.t',
            't/1123-isf-public-cli-hdl-generation-audit.t',
            't/1124-isf-public-cli-strict-mode-audit.t',
            't/1125-isf-public-constructor-boundary-audit.t',
            't/1126-isf-public-parser-method-boundary-audit.t',
            't/1127-isf-public-scheduler-method-boundary-audit.t',
            't/1128-isf-public-multifile-schedule-report-audit.t',
            't/1129-isf-public-actor-shell-contract-audit.t',
            't/1130-isf-public-compile-issues-success-audit.t',
            't/1131-isf-public-top-level-discovery-audit.t',
            't/1132-isf-public-method-receiver-boundary-audit.t',
            't/1133-isf-public-constructor-receiver-boundary-audit.t',
            't/1134-isf-public-parse-file-path-boundary-audit.t',
            't/1135-isf-public-entrypoint-metadata-audit.t',
            't/1136-isf-public-cli-option-metadata-audit.t',
            't/1137-isf-public-method-name-metadata-audit.t',
            't/1138-isf-public-constructor-option-metadata-audit.t',
            't/1139-isf-public-lower-result-metadata-audit.t',
            't/1140-isf-public-schedule-report-metadata-audit.t',
            't/1141-isf-public-identity-flags-metadata-audit.t',
            't/1142-isf-public-guidance-metadata-audit.t',
            't/1143-isf-public-facade-shape-metadata-audit.t',
            't/1144-isf-public-tested-by-metadata-audit.t',
            't/1145-isf-public-scheduled-fsm-metadata-audit.t',
            't/1146-isf-public-dt-assignment-metadata-audit.t',
            't/1147-isf-public-report-dt-assignment-count-audit.t',
            't/1148-isf-public-storage-metadata-audit.t',
            't/1149-isf-public-transaction-metadata-audit.t',
            't/1150-isf-public-reset-metadata-audit.t',
            't/1151-isf-public-report-count-metadata-audit.t',
            't/1152-isf-public-report-scalar-metadata-audit.t',
            't/1153-isf-public-cli-success-metadata-audit.t',
            't/1154-isf-public-facade-return-metadata-audit.t',
            't/1155-isf-public-cli-strict-success-metadata-audit.t',
            't/1156-isf-public-lower-result-file-shape-audit.t',
            't/1157-isf-public-report-transaction-ordering-audit.t',
            't/1158-isf-public-report-dt-kind-metadata-audit.t',
            't/1159-isf-public-report-reset-shape-metadata-audit.t',
            't/1160-isf-public-actor-shell-value-shape-audit.t',
            't/1161-isf-public-facade-failure-diagnostic-metadata-audit.t',
            't/1162-isf-public-actor-shell-interface-shape-audit.t',
            't/1163-isf-public-actor-shell-transaction-shape-audit.t',
            't/1164-isf-public-actor-shell-actor-name-shape-audit.t',
            't/1165-isf-public-actor-shell-timing-shape-audit.t',
            't/1166-isf-public-actor-shell-rule-shape-audit.t',
            't/1167-isf-public-actor-shell-drive-shape-audit.t',
            't/1168-isf-rule-guard-factoring.t',
            't/1169-isf-rule-shorthand-guard.t',
            't/1171-isf-rule-trigger-fanin.t',
            't/1172-isf-rule-trigger-fanin-schedule-report.t',
            't/1173-isf-shift-right-explicit-width.t',
            't/1174-isf-extract-explicit-widths.t',
            't/1175-isf-contract-fail-closed.t',
            't/1176-isf-resource-priority-boundary.t',
            't/1177-isf-do-child-done-pulse.t',
            't/1178-isf-handshake-compatibility-boundary.t',
            't/1179-isf-phase-stage-boundary.t',
            't/1180-isf-unsupported-transaction-clause-boundary.t',
            't/1181-isf-rule-action-boundary.t',
            't/1182-isf-rule-trigger-target-boundary.t',
            't/1184-isf-child-transaction-target-boundary.t',
            't/1185-isf-transaction-name-boundary.t',
            't/1186-isf-rule-name-boundary.t',
            't/1187-isf-drive-name-boundary.t',
            't/1188-isf-interface-port-boundary.t',
            't/1189-isf-drive-parameter-boundary.t',
            't/1190-isf-rule-priority-target-boundary.t',
            't/1191-isf-actor-priority-target-boundary.t',
            't/1192-isf-singleton-actor-clause-boundary.t',
            't/1193-isf-drive-call-arity-boundary.t',
            't/1194-isf-drive-body-boundary.t',
            't/1195-isf-sample-clause-boundary.t',
            't/1196-isf-complete-clause-boundary.t',
            't/1197-isf-latency-clause-boundary.t',
            't/1198-isf-update-clause-boundary.t',
            't/1199-isf-shift-clause-boundary.t',
            't/1200-isf-assemble-clause-boundary.t',
            't/1201-isf-extract-clause-boundary.t',
            't/1202-isf-repeat-clause-boundary.t',
            't/1203-isf-await-sync-clause-boundary.t',
            't/1204-isf-child-composition-clause-boundary.t',
            't/1205-isf-switch-clause-boundary.t',
            't/1206-isf-when-clause-boundary.t',
            't/1209-isf-static-conflict-detection.t',
            't/1210-isf-priority-conflict-resolution.t',
            't/1211-isf-runtime-selector-conflict-instrumentation.t',
            't/1212-isf-schedule-report-compile-issues-projection.t',
            't/1213-isf-schedule-report-compatible-fanin-projection.t',
            't/1214-isf-rejected-conflict-diagnostics.t',
            't/1215-isf-spawn-parameter-binding.t',
            't/1216-isf-generated-composition-top.t',
            't/1217-isf-generated-composition-schedule-report.t',
            't/1218-isf-rule-slot-resource-arbitration.t',
            't/1219-isf-rule-transaction-priority.t',
            't/1220-isf-arbitration-schedule-report.t',
            't/1221-isf-rule-expression-assignment.t',
            't/1222-isf-rule-expression-conflict-report.t',
            't/1223-isf-stage-lowering.t',
            't/1224-isf-contract-lowering.t',
            't/1225-isf-stage-contract-schedule-report.t',
            't/1226-isf-data-width-storage-report.t',
            't/1227-isf-schedule-report-freeze-boundary.t',
            't/1228-isf-spi-fixture-coverage.t',
            't/1229-isf-compatibility-cli-parity.t',
            't/1230-isf-library-import-resolution.t',
            't/1231-isf-library-generated-top.t',
            't/1232-isf-actor-storage-declarations.t',
            't/1233-isf-rule-expression-guards.t',
            't/1234-isf-disjoint-rule-writes.t',
            't/1235-isf-fifo-same-cycle-update-matrix.t',
            't/1236-isf-bank-access-lowering.t',
            't/1237-isf-fifo-library-fixture.t',
            't/1238-isf-fifo-library-hdl-generation.t',
            't/1239-isf-library-catalog-contract.t',
            't/1240-isf-transaction-port-declarations.t',
            't/1241-isf-transaction-port-bindings.t',
            't/1242-isf-port-binding-conflict-semantics.t',
            't/1243-isf-port-binding-schedule-report.t',
            't/1244-isf-wait-clause-lowering.t',
            't/1245-isf-transaction-loop-lowering.t',
            't/1246-isf-setter-syntax.t',
        ],
        guidance => [
            'Treat this as the first bounded public ISF downstream-consumer contract, advertised through embedding.isf_public_interface.',
            'Treat the contract as live: exact metadata audits describe the current advertised surface, not a promise that ISF or the schedule-report schema is frozen.',
            'The public in-process seam is the parser/scheduler facade pair, not the raw parser AST or LoweringIR internals.',
            'The lower(...) result currently advertises the files map as scheduled module, specialized library-child module, and generated composition-top .fsm artifacts; the whole result hash is not yet a broad API.',
            'The library catalog path list and shipped_library_definitions entries are live discovery metadata for reusable ISF definitions; add or change entries only with source, limitations, and tests updated together.',
            'The schedule report currently advertises only the named top-level and summary key families; wider schema promises must be documented and regression-backed before downstream tools rely on them.',
            'The live human contract documents must evolve in the same slices that change supported ISF syntax, facade behavior, lower result shape, or schedule-report shape.',
        ],
    };
}

sub isf_public_interface_public_top_level_keys {
    return [
        qw(
            schema_version
            status
            contract_source
            implementation_owners
            entrypoints
            public_top_level_presence_keys
            parser_method_names
            scheduler_method_names
            constructor_option_names
            cli_option_names
            resource_arbiter_values
            resource_kind_values
            resource_kind_status_map
            resource_kind_meaning_map
            enforced_resource_kind_values
            backlog_resource_kind_values
            library_catalog_paths
            library_catalog_entry_keys
            shipped_library_definitions
            cli_schedule_json_success_shape
            cli_outdir_success_shape
            cli_hdl_generation_success_shape
            cli_strict_hdl_generation_success_shape
            constructor_receiver_shape
            constructor_argument_shape
            parser_method_receiver_shape
            scheduler_method_receiver_shape
            parse_file_argument_shape
            parse_file_path_requirement
            parse_source_argument_shape
            parse_file_return_shape
            parse_source_return_shape
            lower_argument_shape
            report_argument_shape
            facade_failure_diagnostic_shape
            lower_return_shape
            report_return_shape
            actor_shell_required_keys
            actor_shell_value_shape
            actor_shell_actor_name_shape
            actor_shell_timing_shape
            actor_shell_interface_shape
            actor_shell_transaction_shape
            actor_shell_rule_shape
            actor_shell_drive_shape
            lower_result_presence_keys
            lower_result_file_map_shape
            lower_result_file_name_shape
            lower_result_file_text_shape
            dt_assignment_operator_family_map
            scheduled_fsm_dt_ordering
            schedule_report_top_level_keys
            schedule_report_source_shape
            schedule_report_scheduled_fsm_shape
            schedule_report_clock_shape
            schedule_report_watchdog_shape
            schedule_report_compile_issues_success_shape
            schedule_report_compile_issue_keys
            schedule_report_compile_issue_source_keys
            schedule_report_bank_access_keys
            schedule_report_bank_access_kind_values
            schedule_report_bank_access_policy_values
            schedule_report_transaction_port_binding_keys
            schedule_report_transaction_port_binding_site_kind_values
            schedule_report_compile_issue_severity_values
            schedule_report_compile_issue_proof_status_values
            schedule_report_fanin_group_required_keys
            schedule_report_fanin_group_optional_keys
            schedule_report_fanin_group_kind_values
            schedule_report_priority_resolution_keys
            schedule_report_resource_arbitration_keys
            schedule_report_generated_composition_required_keys
            schedule_report_generated_composition_kind_values
            schedule_report_generated_composition_parent_keys
            schedule_report_generated_composition_child_keys
            schedule_report_generated_composition_child_parameter_keys
            schedule_report_generated_composition_instance_keys
            schedule_report_generated_composition_link_keys
            schedule_report_generated_composition_binding_keys
            schedule_report_generated_composition_drive_handoff_keys
            schedule_report_generated_composition_payload_keys
            schedule_report_library_use_keys
            schedule_report_library_use_parameter_keys
            schedule_report_library_use_binding_keys
            schedule_report_multi_file_scope
            schedule_report_interface_count_shape
            schedule_report_state_count_shape
            schedule_report_presence_key_family_map
            schedule_report_reset_shape
            schedule_report_reset_keys
            schedule_report_reset_kind_values
            schedule_report_reset_polarity_values
            schedule_report_storage_required_keys
            schedule_report_storage_optional_keys
            schedule_report_storage_kind_values
            schedule_report_storage_role_values
            schedule_report_storage_width_shape
            schedule_report_transaction_keys
            schedule_report_transaction_states_shape
            schedule_report_transaction_count_shape
            schedule_report_transaction_ordering
            schedule_report_transaction_loop_keys
            schedule_report_transaction_wait_keys
            schedule_report_transaction_stage_keys
            schedule_report_transaction_stage_kind_values
            schedule_report_temporal_contract_keys
            schedule_report_temporal_contract_kind_values
            schedule_report_temporal_contract_overlap_policy_values
            schedule_report_temporal_contract_assertion_projection_values
            schedule_report_temporal_contract_reset_policy_shape
            schedule_report_dt_keys
            schedule_report_dt_kind_values
            schedule_report_dt_assignments_shape
            schedule_report_dt_ordering
            live_document_paths
            live_contract_documentation
            evolves_with_isf_implementation
            raw_actor_full_hash_stable
            lowering_ir_full_hash_stable
            schedule_report_full_schema_stable
            scheduled_fsm_text_is_review_artifact
            tested_by
            guidance
        ),
    ];
}

sub isf_public_interface_resource_arbiter_values {
    return isf_resource_arbiter_values();
}

sub isf_public_interface_resource_kind_values {
    return isf_resource_kind_values();
}

sub isf_public_interface_resource_kind_status_map {
    return isf_resource_kind_status_map();
}

sub isf_public_interface_resource_kind_meaning_map {
    return isf_resource_kind_meaning_map();
}

sub isf_public_interface_enforced_resource_kind_values {
    return isf_enforced_resource_kind_values();
}

sub isf_public_interface_backlog_resource_kind_values {
    return isf_backlog_resource_kind_values();
}

sub isf_public_interface_library_catalog_paths {
    return [
        qw(
            docs/ISF_LIBRARY_CATALOG.md
        ),
    ];
}

sub isf_public_interface_library_catalog_entry_keys {
    return [
        qw(
            qualified_name
            library
            export
            kind
            status
            source
            import_fixture
            parameters
            interface
            storage
            semantics
            tests
            limitations
        ),
    ];
}

sub isf_public_interface_shipped_library_definitions {
    return [
        {
            qualified_name => 'common.fifo.fifo',
            library => 'common.fifo',
            export => 'fifo',
            kind => 'actor',
            status => 'shipped',
            source => 'isf/common/fifo.isf',
            import_fixture => 'isf/fifo_library_use.isf',
            parameters => [
                { name => 'DATA_WIDTH', value => '8' },
                { name => 'DEPTH', value => '4' },
                { name => 'PTR_WIDTH', value => '2' },
                { name => 'OCC_WIDTH', value => '3' },
            ],
            interface => {
                inputs => [
                    { name => 'write_req', width => 1 },
                    { name => 'data_in', width => 8 },
                    { name => 'read_req', width => 1 },
                ],
                outputs => [
                    { name => 'full', width => 1 },
                    { name => 'empty', width => 1 },
                    { name => 'data_out', width => 8 },
                ],
            },
            storage => [
                { name => 'wr_ptr', kind => 'state', width => 2 },
                { name => 'rd_ptr', kind => 'state', width => 2 },
                { name => 'occupancy', kind => 'state', width => 3 },
                { name => 'data', kind => 'bank', width => 8, depth => 4 },
            ],
            semantics => [
                'actor-maintained full and empty flags',
                'idle, push-only, pop-only, and push-plus-pop request cases',
                'depth-4 pointer wrap for wr_ptr and rd_ptr',
                'read-before-write same-cycle bank access policy',
            ],
            tests => [
                't/1237-isf-fifo-library-fixture.t',
                't/1238-isf-fifo-library-hdl-generation.t',
            ],
            limitations => [
                'fixed-shape DATA_WIDTH=8 DEPTH=4 fixture',
                'no parameter-driven interface or storage elaboration yet',
                'no memory-array backend emission yet',
                'no automatic non-zero reset values yet',
                'no standalone transaction or drive library exports yet',
                'no nested library imports from library actors yet',
                'no clock/reset name remapping at use sites yet',
            ],
        },
    ];
}

sub isf_public_interface_parser_method_names {
    return [
        qw(
            new
            parse_file
            parse_source
        ),
    ];
}

sub isf_public_interface_scheduler_method_names {
    return [
        qw(
            new
            lower
            report
        ),
    ];
}

sub isf_public_interface_constructor_option_names {
    return [
        qw(
            debug
        ),
    ];
}

sub isf_public_interface_cli_option_names {
    return [
        qw(
            --emit-schedule-json
            --outdir
            --strict
        ),
    ];
}

sub isf_public_interface_cli_schedule_json_success_shape {
    return '--emit-schedule-json writes schedule-report JSON to stdout and keeps stderr empty on success';
}

sub isf_public_interface_cli_outdir_success_shape {
    return '--outdir DIR writes lower-result .fsm files by basename into DIR and keeps stderr empty on success';
}

sub isf_public_interface_cli_hdl_generation_success_shape {
    return 'plain file.isf generation lowers through scheduled .fsm and writes requested HDL output with empty stderr on success';
}

sub isf_public_interface_cli_strict_hdl_generation_success_shape {
    return '--strict file.isf generation follows cli_hdl_generation_success_shape for accepted ISF inputs and keeps stderr empty on success';
}

sub isf_public_interface_actor_shell_required_keys {
    return [
        qw(
            actor_name
            transactions
            interface
        ),
    ];
}

sub isf_public_interface_actor_shell_value_shape {
    return 'actor_name is scalar; transactions is an array reference; interface is a hash reference; storage is an optional array reference for authored state and bank declarations when actor-owned storage is declared';
}

sub isf_public_interface_actor_shell_actor_name_shape {
    return 'actor_name is a non-empty scalar actor identifier preserved from the ISF actor root';
}

sub isf_public_interface_actor_shell_timing_shape {
    return 'clock is a non-empty scalar when configured; reset is null when omitted or a hash with scalar name, kind, and polarity; watchdog is null when omitted or a positive integer; source clock, reset, watchdog, interface, resources, and storage clauses are singleton actor clauses';
}

sub isf_public_interface_actor_shell_interface_shape {
    return 'interface has inputs and outputs arrays; each public port entry has unique non-empty scalar name and positive integer width, defaulting omitted source widths to 1';
}

sub isf_public_interface_actor_shell_transaction_shape {
    return 'transactions is an array of public transaction shell entries; each entry has unique non-empty scalar name, ports hash with inputs/outputs arrays, and clauses array, while clause payload contents remain private scheduler input';
}

sub isf_public_interface_actor_shell_rule_shape {
    return 'rules is an array of public rule shell entries; each entry has unique non-empty scalar name, optional normalized when clause, and actions array; scalar or expression shorthand rule guards normalize into when while rule payload contents remain private scheduler input';
}

sub isf_public_interface_actor_shell_drive_shape {
    return 'drives is a hash of public drive shell entries keyed by unique non-empty drive name; each entry has unique scalar params and body arrays; body entries are scalar (port value) pairs while detailed drive semantics remain private scheduler input';
}

sub isf_public_interface_facade_failure_diagnostic_shape {
    return 'public facade boundary failures die with bounded scalar diagnostics before object creation, private parsing, or private lowering/reporting';
}

sub isf_public_interface_parse_file_return_shape {
    return 'scheduler-consumable actor hash reference with actor_shell_required_keys';
}

sub isf_public_interface_parse_source_return_shape {
    return 'scheduler-consumable actor hash reference with actor_shell_required_keys';
}

sub isf_public_interface_lower_return_shape {
    return 'hash reference with lower_result_presence_keys; files map is the bounded public lower-result surface';
}

sub isf_public_interface_report_return_shape {
    return 'JSON string encoding a schedule report with schedule_report_top_level_keys';
}

sub isf_public_interface_lower_result_presence_keys {
    return [
        qw(
            files
        ),
    ];
}

sub isf_public_interface_lower_result_file_name_shape {
    return '.fsm basename with no directory components';
}

sub isf_public_interface_lower_result_file_text_shape {
    return 'scheduled module or specialized library-child .fsm source text rooted at (?fsm:<basename-stem> ...) or generated composition-top .fsm text rooted at (?top:<basename-stem> ...)';
}

sub isf_public_interface_dt_assignment_operator_family_map {
    return {
        combinational => ['='],
        sequential    => ['<-', '<=', '<1'],
    };
}

sub isf_public_interface_dt_ordering_policy {
    return join(
        '',
        'deterministic_lowering_order: ',
        'transaction_and_rule_dt_blocks_keep_construction_order; ',
        'generated_rule_trigger_fanin_dt_blocks_follow_rule_dt_blocks_by_transaction_name; ',
        'hash_backed_drive_dt_blocks_are_sorted_lexically_by_drive_name',
    );
}

sub isf_public_interface_schedule_report_top_level_keys {
    return [
        qw(
            source
            scheduled_fsm
            clock
            reset
            watchdog
            port_count
            inputs
            outputs
            state_count
            inferred_storage
            transactions
            transaction_waits
            transaction_loops
            transaction_stages
            temporal_contracts
            bank_accesses
            transaction_port_bindings
            dt_blocks
            generated_composition
            library_uses
            compatible_fanin_groups
            priority_resolutions
            resource_arbitration
            compile_issues
        ),
    ];
}

sub isf_public_interface_schedule_report_compile_issues_success_shape {
    return 'array reference; empty when a successful schedule report has no nonfatal compile issues';
}

sub isf_public_interface_schedule_report_compile_issue_keys {
    return [
        qw(
            code
            severity
            target
            domain
            proof_status
            reason
            sources
        ),
    ];
}

sub isf_public_interface_schedule_report_compile_issue_source_keys {
    return [
        qw(
            owner
            owner_kind
            source_kind
            target
            operator
            rhs
            domain
        ),
    ];
}

sub isf_public_interface_schedule_report_bank_access_keys {
    return [
        qw(
            kind
            owner
            owner_kind
            container_kind
            container_name
            bank
            index
            width
            depth
            scalar_entries
            same_cycle_policy
            value
            target
        ),
    ];
}

sub isf_public_interface_schedule_report_bank_access_kind_values {
    return [
        qw(
            store
            load
        ),
    ];
}

sub isf_public_interface_schedule_report_bank_access_policy_values {
    return [
        qw(
            read_before_write
        ),
    ];
}

sub isf_public_interface_schedule_report_transaction_port_binding_keys {
    return [
        qw(
            site_kind
            owner
            owner_kind
            target_transaction
            role
            port
            actor_signal
            width
            instance
            parent_port
            child_port
            start_signal
            done_signal
            trigger_source
            payload_source
        ),
    ];
}

sub isf_public_interface_schedule_report_transaction_port_binding_site_kind_values {
    return [
        qw(
            do
            spawn
            rule_trigger
        ),
    ];
}

sub isf_public_interface_schedule_report_compile_issue_severity_values {
    return [
        qw(
            warning
        ),
    ];
}

sub isf_public_interface_schedule_report_compile_issue_proof_status_values {
    return [
        qw(
            not_doable
        ),
    ];
}

sub isf_public_interface_schedule_report_fanin_group_required_keys {
    return [
        qw(
            kind
            domain
            sources
        ),
    ];
}

sub isf_public_interface_schedule_report_fanin_group_optional_keys {
    return [
        qw(
            target
            target_transaction
            fanin_target
            operator
            rhs
        ),
    ];
}

sub isf_public_interface_schedule_report_fanin_group_kind_values {
    return [
        qw(
            same_target_value
            request
            pulse
            rule_trigger_fanin
        ),
    ];
}

sub isf_public_interface_schedule_report_priority_resolution_keys {
    return [
        qw(
            target
            winner
            winner_kind
            loser
            loser_kind
        ),
    ];
}

sub isf_public_interface_schedule_report_resource_arbitration_keys {
    return [
        qw(
            resource
            kind
            arbiter
            user
            user_kind
            suppressed_by
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_required_keys {
    return [
        qw(
            kind
            top_module
            top_fsm
            parent
            children
            instances
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_kind_values {
    return [
        qw(
            activation_generated_top
            spawn_generated_top
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_parent_keys {
    return [
        qw(
            module
            scheduled_fsm
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_child_keys {
    return [
        qw(
            transaction
            module
            scheduled_fsm
            parameters
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_child_parameter_keys {
    return [
        qw(
            name
            default
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_instance_keys {
    return [
        qw(
            instance
            child
            activation_kind
            start
            done
            parameter_bindings
            drive_handoffs
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_link_keys {
    return [
        qw(
            parent_port
            child_port
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_binding_keys {
    return [
        qw(
            name
            source
            value
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_drive_handoff_keys {
    return [
        qw(
            drive
            request
            payloads
        ),
    ];
}

sub isf_public_interface_schedule_report_generated_composition_payload_keys {
    return [
        qw(
            parameter
            child_port
            parent_port
            width
        ),
    ];
}

sub isf_public_interface_schedule_report_library_use_keys {
    return [
        qw(
            library
            alias
            export
            kind
            instance
            module
            scheduled_fsm
            parameters
            bindings
        ),
    ];
}

sub isf_public_interface_schedule_report_library_use_parameter_keys {
    return [
        qw(
            name
            source
            value
        ),
    ];
}

sub isf_public_interface_schedule_report_library_use_binding_keys {
    return [
        qw(
            role
            library_name
            parent_name
            width
        ),
    ];
}

sub isf_public_interface_schedule_report_source_shape {
    return 'scheduled report source basename derived from the actor name with .isf suffix';
}

sub isf_public_interface_schedule_report_scheduled_fsm_shape {
    return 'scheduled .fsm basename for the current parent actor report scope';
}

sub isf_public_interface_schedule_report_clock_shape {
    return 'scalar clock signal name from the ISF actor clock declaration';
}

sub isf_public_interface_schedule_report_watchdog_shape {
    return 'scalar watchdog limit when configured; null when omitted';
}

sub isf_public_interface_schedule_report_multi_file_scope {
    return 'report transaction/state/dt/storage summaries describe the parent module; generated_composition summarizes generated top, child files, spawned instances, handoffs, and bindings; library_uses summarizes resolved reusable library actor instances and their child scheduled .fsm artifacts; child scheduled .fsm text remains available through lower_result files';
}

sub isf_public_interface_schedule_report_interface_count_shape {
    return 'non-negative integer counts: inputs and outputs count interface ports by direction, and port_count equals inputs plus outputs';
}

sub isf_public_interface_schedule_report_state_count_shape {
    return 'non-negative integer count of scheduled .fsm state blocks in the current parent report scope';
}

sub isf_public_interface_schedule_report_reset_keys {
    return [
        qw(
            name
            kind
            polarity
        ),
    ];
}

sub isf_public_interface_schedule_report_reset_shape {
    return 'hash reference with schedule_report_reset_keys when configured; null when omitted';
}

sub isf_public_interface_schedule_report_reset_kind_values {
    return [
        qw(
            async
            sync
        ),
    ];
}

sub isf_public_interface_schedule_report_reset_polarity_values {
    return [
        qw(
            active_high
            active_low
        ),
    ];
}

sub isf_public_interface_schedule_report_storage_required_keys {
    return [
        qw(
            name
            kind
        ),
    ];
}

sub isf_public_interface_schedule_report_storage_optional_keys {
    return [
        qw(
            role
            width
        ),
    ];
}

sub isf_public_interface_schedule_report_storage_kind_values {
    return [
        qw(
            counter
            register
        ),
    ];
}

sub isf_public_interface_schedule_report_storage_role_values {
    return [
        qw(
            completion_pulse
            data_register
            drive_payload
            drive_request
            extract_field
            latency_counter
            repeat_counter
            sample_alias
            watchdog_counter
            actor_storage
        ),
    ];
}

sub isf_public_interface_schedule_report_storage_width_shape {
    return 'positive integer bit width when present; currently present for declared actor-owned storage, inferred scheduler counters, and register storage with known ISF width evidence';
}

sub isf_public_interface_schedule_report_transaction_keys {
    return [
        qw(
            name
            states
            count
        ),
    ];
}

sub isf_public_interface_schedule_report_transaction_states_shape {
    return 'array reference of scheduled state names belonging to the transaction in emitted order';
}

sub isf_public_interface_schedule_report_transaction_count_shape {
    return 'non-negative integer count equal to the transaction states array length';
}

sub isf_public_interface_schedule_report_transaction_ordering {
    return 'transaction summaries are sorted lexically by transaction name; each states array keeps scheduled .fsm state emission order';
}

sub isf_public_interface_schedule_report_transaction_wait_keys {
    return [
        qw(
            transaction
            cycles
            entry_state
            exit_state
            counter_signal
        ),
    ];
}

sub isf_public_interface_schedule_report_transaction_loop_keys {
    return [
        qw(
            transaction
            kind
            condition
            entry_state
            decision_states
            body_start
            body_states
            exit_state
            body_clause_count
        ),
    ];
}

sub isf_public_interface_schedule_report_transaction_stage_keys {
    return [
        qw(
            transaction
            name
            kind
            state
            ready
            valid
        ),
    ];
}

sub isf_public_interface_schedule_report_transaction_stage_kind_values {
    return [
        qw(
            ready_valid_barrier
        ),
    ];
}

sub isf_public_interface_schedule_report_temporal_contract_keys {
    return [
        qw(
            transaction
            name
            kind
            trigger
            signal
            within_cycles
            pending_signal
            counter_signal
            fail_signal
            overlap_policy
            reset_policy
            assertion_projection
        ),
    ];
}

sub isf_public_interface_schedule_report_temporal_contract_kind_values {
    return [
        qw(
            bounded_eventually
        ),
    ];
}

sub isf_public_interface_schedule_report_temporal_contract_overlap_policy_values {
    return [
        qw(
            fail
        ),
    ];
}

sub isf_public_interface_schedule_report_temporal_contract_assertion_projection_values {
    return [
        qw(
            none
        ),
    ];
}

sub isf_public_interface_schedule_report_temporal_contract_reset_policy_shape {
    return 'same bounded shape as top-level reset summary when reset is configured; null when the actor omits reset';
}

sub isf_public_interface_schedule_report_dt_keys {
    return [
        qw(
            name
            kind
            assignments
        ),
    ];
}

sub isf_public_interface_schedule_report_dt_kind_values {
    return [
        qw(
            drive
            do_port_binding
            latency_counter
            rule
            rule_trigger_fanin
            spawn_port_binding
            temporal_contract_monitor
        ),
    ];
}

sub isf_public_interface_schedule_report_dt_assignments_shape {
    return 'non-negative integer count of assignments in the matching scheduled .fsm DT block; not an assignment payload list';
}

sub isf_public_interface_schedule_report_presence_key_family_map {
    return {
        schedule_report_top_level_keys => isf_public_interface_schedule_report_top_level_keys(),
        schedule_report_reset_keys => isf_public_interface_schedule_report_reset_keys(),
        schedule_report_storage_required_keys => isf_public_interface_schedule_report_storage_required_keys(),
        schedule_report_storage_optional_keys => isf_public_interface_schedule_report_storage_optional_keys(),
        schedule_report_bank_access_keys => isf_public_interface_schedule_report_bank_access_keys(),
        schedule_report_transaction_port_binding_keys => isf_public_interface_schedule_report_transaction_port_binding_keys(),
        schedule_report_transaction_keys => isf_public_interface_schedule_report_transaction_keys(),
        schedule_report_transaction_loop_keys => isf_public_interface_schedule_report_transaction_loop_keys(),
        schedule_report_transaction_wait_keys => isf_public_interface_schedule_report_transaction_wait_keys(),
        schedule_report_transaction_stage_keys => isf_public_interface_schedule_report_transaction_stage_keys(),
        schedule_report_temporal_contract_keys => isf_public_interface_schedule_report_temporal_contract_keys(),
        schedule_report_dt_keys => isf_public_interface_schedule_report_dt_keys(),
        schedule_report_compile_issue_keys => isf_public_interface_schedule_report_compile_issue_keys(),
        schedule_report_compile_issue_source_keys => isf_public_interface_schedule_report_compile_issue_source_keys(),
        schedule_report_fanin_group_required_keys => isf_public_interface_schedule_report_fanin_group_required_keys(),
        schedule_report_fanin_group_optional_keys => isf_public_interface_schedule_report_fanin_group_optional_keys(),
        schedule_report_priority_resolution_keys => isf_public_interface_schedule_report_priority_resolution_keys(),
        schedule_report_resource_arbitration_keys => isf_public_interface_schedule_report_resource_arbitration_keys(),
        schedule_report_generated_composition_required_keys => isf_public_interface_schedule_report_generated_composition_required_keys(),
        schedule_report_generated_composition_parent_keys => isf_public_interface_schedule_report_generated_composition_parent_keys(),
        schedule_report_generated_composition_child_keys => isf_public_interface_schedule_report_generated_composition_child_keys(),
        schedule_report_generated_composition_child_parameter_keys => isf_public_interface_schedule_report_generated_composition_child_parameter_keys(),
        schedule_report_generated_composition_instance_keys => isf_public_interface_schedule_report_generated_composition_instance_keys(),
        schedule_report_generated_composition_link_keys => isf_public_interface_schedule_report_generated_composition_link_keys(),
        schedule_report_generated_composition_binding_keys => isf_public_interface_schedule_report_generated_composition_binding_keys(),
        schedule_report_generated_composition_drive_handoff_keys => isf_public_interface_schedule_report_generated_composition_drive_handoff_keys(),
        schedule_report_generated_composition_payload_keys => isf_public_interface_schedule_report_generated_composition_payload_keys(),
        schedule_report_library_use_keys => isf_public_interface_schedule_report_library_use_keys(),
        schedule_report_library_use_parameter_keys => isf_public_interface_schedule_report_library_use_parameter_keys(),
        schedule_report_library_use_binding_keys => isf_public_interface_schedule_report_library_use_binding_keys(),
    };
}

sub isf_public_interface_live_document_paths {
    return [
        qw(
            docs/ISF_PUBLIC_INTERFACE_CONTRACT.md
            docs/ISF_SPEC.md
            docs/ISF_LIBRARY_CATALOG.md
            docs/book/src/13-intent-scheduling.md
        ),
    ];
}

1;
