package FSM::Support::ISFPublicInterfaceContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_isf_public_interface_contract
    isf_public_interface_cli_option_names
    isf_public_interface_contract_source
    isf_public_interface_constructor_option_names
    isf_public_interface_live_document_paths
    isf_public_interface_lower_result_presence_keys
    isf_public_interface_dt_ordering_policy
    isf_public_interface_parser_method_names
    isf_public_interface_public_top_level_keys
    isf_public_interface_schedule_report_presence_key_family_map
    isf_public_interface_schedule_report_reset_keys
    isf_public_interface_schedule_report_storage_optional_keys
    isf_public_interface_schedule_report_storage_required_keys
    isf_public_interface_schedule_report_top_level_keys
    isf_public_interface_schedule_report_transaction_keys
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
        constructor_argument_shape => 'even-length option/value list after class invocant; currently only debug is public',
        parse_file_argument_shape => 'exactly one scalar filesystem path to a .isf source after object invocant',
        parse_source_argument_shape => 'exactly two scalar arguments after object invocant: source text and source label',
        lower_argument_shape => 'scheduler-consumable actor value returned by FSM::Adapter::ISF',
        report_argument_shape => 'scheduler-consumable actor value returned by FSM::Adapter::ISF',
        lower_result_presence_keys => isf_public_interface_lower_result_presence_keys(),
        lower_result_file_map_shape => 'hash reference mapping scheduled .fsm basename to scheduled .fsm source text',
        scheduled_fsm_dt_ordering => isf_public_interface_dt_ordering_policy(),
        schedule_report_top_level_keys => isf_public_interface_schedule_report_top_level_keys(),
        schedule_report_presence_key_family_map => isf_public_interface_schedule_report_presence_key_family_map(),
        schedule_report_reset_keys => isf_public_interface_schedule_report_reset_keys(),
        schedule_report_storage_required_keys => isf_public_interface_schedule_report_storage_required_keys(),
        schedule_report_storage_optional_keys => isf_public_interface_schedule_report_storage_optional_keys(),
        schedule_report_transaction_keys => isf_public_interface_schedule_report_transaction_keys(),
        schedule_report_dt_keys => isf_public_interface_schedule_report_dt_keys(),
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
            constructor_argument_shape
            parse_file_argument_shape
            parse_source_argument_shape
            lower_argument_shape
            report_argument_shape
            lower_result_presence_keys
            lower_result_file_map_shape
            scheduled_fsm_dt_ordering
            schedule_report_top_level_keys
            schedule_report_presence_key_family_map
            schedule_report_reset_keys
            schedule_report_storage_required_keys
            schedule_report_storage_optional_keys
            schedule_report_transaction_keys
            schedule_report_dt_keys
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

sub isf_public_interface_lower_result_presence_keys {
    return [
        qw(
            files
        ),
    ];
}

sub isf_public_interface_dt_ordering_policy {
    return join(
        '',
        'deterministic_lowering_order: ',
        'transaction_and_rule_dt_blocks_keep_construction_order; ',
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

sub isf_public_interface_schedule_report_reset_keys {
    return [
        qw(
            name
            kind
            polarity
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

sub isf_public_interface_schedule_report_transaction_keys {
    return [
        qw(
            name
            states
            count
        ),
    ];
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
