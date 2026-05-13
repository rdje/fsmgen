package FSM::Support::ISFPublicInterfaceContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

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
    isf_public_interface_schedule_report_compile_issues_success_shape
    isf_public_interface_schedule_report_clock_shape
    isf_public_interface_schedule_report_dt_assignments_shape
    isf_public_interface_schedule_report_dt_kind_values
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
    isf_public_interface_schedule_report_storage_width_shape
    isf_public_interface_schedule_report_top_level_keys
    isf_public_interface_schedule_report_transaction_count_shape
    isf_public_interface_schedule_report_transaction_ordering
    isf_public_interface_schedule_report_transaction_states_shape
    isf_public_interface_schedule_report_transaction_keys
    isf_public_interface_schedule_report_watchdog_shape
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
        lower_result_file_map_shape => 'hash reference mapping scheduled .fsm basename to scheduled .fsm source text',
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
        schedule_report_storage_width_shape => isf_public_interface_schedule_report_storage_width_shape(),
        schedule_report_transaction_keys => isf_public_interface_schedule_report_transaction_keys(),
        schedule_report_transaction_states_shape => isf_public_interface_schedule_report_transaction_states_shape(),
        schedule_report_transaction_count_shape => isf_public_interface_schedule_report_transaction_count_shape(),
        schedule_report_transaction_ordering => isf_public_interface_schedule_report_transaction_ordering(),
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
        ],
        guidance => [
            'Treat this as the first bounded public ISF downstream-consumer contract, advertised through embedding.isf_public_interface.',
            'The public in-process seam is the parser/scheduler facade pair, not the raw parser AST or LoweringIR internals.',
            'The lower(...) result currently stabilizes the files map as scheduled .fsm artifacts; the whole result hash is not yet a broad API.',
            'The schedule report stabilizes only the advertised top-level and summary key families for now; wider schema promises must be documented and regression-backed before downstream tools rely on them.',
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
            schedule_report_storage_width_shape
            schedule_report_transaction_keys
            schedule_report_transaction_states_shape
            schedule_report_transaction_count_shape
            schedule_report_transaction_ordering
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
    return '--outdir DIR writes scheduled .fsm files by basename into DIR and keeps stderr empty on success';
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
    return 'actor_name is scalar; transactions is an array reference; interface is a hash reference';
}

sub isf_public_interface_actor_shell_actor_name_shape {
    return 'actor_name is a non-empty scalar actor identifier preserved from the ISF actor root';
}

sub isf_public_interface_actor_shell_timing_shape {
    return 'clock is a non-empty scalar when configured; reset is null when omitted or a hash with scalar name, kind, and polarity; watchdog is null when omitted or a positive integer';
}

sub isf_public_interface_actor_shell_interface_shape {
    return 'interface has inputs and outputs arrays; each public port entry has scalar name and positive integer width, defaulting omitted source widths to 1';
}

sub isf_public_interface_actor_shell_transaction_shape {
    return 'transactions is an array of public transaction shell entries; each entry has scalar name and clauses array, while clause payload contents remain private scheduler input';
}

sub isf_public_interface_actor_shell_rule_shape {
    return 'rules is an array of public rule shell entries; each entry has scalar name, optional normalized when clause, and actions array; shorthand rule guards normalize into when while rule payload contents remain private scheduler input';
}

sub isf_public_interface_actor_shell_drive_shape {
    return 'drives is a hash of public drive shell entries keyed by drive name; each entry has params and body arrays, while drive body payload contents remain private scheduler input';
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
    return 'scheduled .fsm basename with no directory components';
}

sub isf_public_interface_lower_result_file_text_shape {
    return 'scheduled .fsm source text rooted at (?fsm:<basename-stem> ...)';
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
            dt_blocks
            compile_issues
        ),
    ];
}

sub isf_public_interface_schedule_report_compile_issues_success_shape {
    return 'array reference; empty on successful schedule reports';
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
    return 'current_report_describes_parent_module_only; child_scheduled_fsm_texts_are_available_through_lower_result_files';
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

sub isf_public_interface_schedule_report_storage_width_shape {
    return 'positive integer bit width when present; currently present for inferred scheduler counters';
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
            latency_counter
            rule
            rule_trigger_fanin
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
        schedule_report_transaction_keys => isf_public_interface_schedule_report_transaction_keys(),
        schedule_report_dt_keys => isf_public_interface_schedule_report_dt_keys(),
    };
}

sub isf_public_interface_live_document_paths {
    return [
        qw(
            docs/ISF_PUBLIC_INTERFACE_CONTRACT.md
            docs/ISF_SPEC.md
            docs/book/src/13-intent-scheduling.md
        ),
    ];
}

1;
