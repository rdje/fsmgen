package FSM::Support::DebugRuntimeContract;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_debug_runtime_contract
    debug_runtime_contract_source
    debug_runtime_family_map
    debug_runtime_emoji_control_names
    debug_runtime_named_trace_verbosity_values
    debug_runtime_numeric_trace_level_range
    debug_runtime_public_top_level_keys
    debug_runtime_snapshot_helper_names
    debug_runtime_snapshot_state_keys
    debug_runtime_state_control_names
    debug_runtime_trace_output_control_names
);

sub debug_runtime_contract_source {
    return 'FSM::Support::DebugRuntimeContract';
}

sub build_debug_runtime_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => debug_runtime_contract_source(),
        implementation_owners => [
            'FSM::Debug',
            'FSM::Pipeline::HDLGenerator',
        ],
        entrypoints => {
            manifest => './bin/fsmgen --capability-manifest -> embedding.debug_runtime',
            in_process => [
                'FSM::Debug::capture_fsm_debug_state()',
                'FSM::Debug::restore_fsm_debug_state($snapshot)',
                'FSM::Debug::with_fsm_debug_state({ ... }, sub { ... })',
                'FSM::Pipeline::HDLGenerator->new(debug_level => ...)',
                'FSM::Pipeline::HDLGenerator->generate_hdl_from_file(...)',
            ],
        },
        public_top_level_presence_keys => debug_runtime_public_top_level_keys(),
        snapshot_helper_names => debug_runtime_snapshot_helper_names(),
        state_control_names => debug_runtime_state_control_names(),
        trace_output_control_names => debug_runtime_trace_output_control_names(),
        emoji_control_names => debug_runtime_emoji_control_names(),
        snapshot_state_keys => debug_runtime_snapshot_state_keys(),
        family_map => debug_runtime_family_map(),
        named_trace_verbosity_values => debug_runtime_named_trace_verbosity_values(),
        numeric_trace_level_range => debug_runtime_numeric_trace_level_range(),
        process_global_singleton => JSON::PP::true,
        thread_safe => JSON::PP::false,
        snapshot_json_safe => JSON::PP::false,
        snapshot_contains_live_filehandle_when_bound => JSON::PP::true,
        pipeline_scopes_debug_state => JSON::PP::true,
        general_debug_calls_auto_scoped => JSON::PP::false,
        guidance => [
            'Treat this contract as the bounded in-process debug save/restore and scoped-debug seam advertised through embedding.debug_runtime.',
            'Use the grouped family_map to discover the bounded helper-name and snapshot-state-key families without scraping prose or freezing every older FSM::Debug helper.',
            'The shipped snapshot is process-local and not JSON-safe: it can contain a live trace filehandle plus mutable global indent/output state.',
            'FSM::Debug is still one process-global singleton, not a thread-local debug context; the current guarantee is explicit save/restore plus scoped HDLGenerator debug use.',
            'Widen this debug-runtime contract only when additional embedding-facing debug helpers are regression-backed and intentionally stable.',
        ],
    };
}

sub debug_runtime_public_top_level_keys {
    return [
        qw(
            schema_version
            status
            contract_source
            implementation_owners
            entrypoints
            public_top_level_presence_keys
            snapshot_helper_names
            state_control_names
            trace_output_control_names
            emoji_control_names
            snapshot_state_keys
            family_map
            named_trace_verbosity_values
            numeric_trace_level_range
            process_global_singleton
            thread_safe
            snapshot_json_safe
            snapshot_contains_live_filehandle_when_bound
            pipeline_scopes_debug_state
            general_debug_calls_auto_scoped
            guidance
        ),
    ];
}

sub debug_runtime_snapshot_helper_names {
    return [
        qw(
            capture_fsm_debug_state
            restore_fsm_debug_state
            with_fsm_debug_state
        ),
    ];
}

sub debug_runtime_state_control_names {
    return [
        qw(
            set_fsm_debug_level
            get_fsm_debug_level
            set_fsm_trace_verbosity
            get_fsm_trace_verbosity
        ),
    ];
}

sub debug_runtime_trace_output_control_names {
    return [
        qw(
            set_fsm_trace_output_file
            clear_fsm_trace_output_file
            get_fsm_trace_output_file
        ),
    ];
}

sub debug_runtime_emoji_control_names {
    return [
        qw(
            set_fsm_trace_emojis
            trace_emojis_enabled
        ),
    ];
}

sub debug_runtime_snapshot_state_keys {
    return [
        qw(
            schema_version
            debug_level
            debug_enabled
            trace_indent_level
            trace_output_fh
            trace_output_file
            trace_emojis_enabled
        ),
    ];
}

sub debug_runtime_family_map {
    return {
        snapshot_helper_names => debug_runtime_snapshot_helper_names(),
        state_control_names => debug_runtime_state_control_names(),
        trace_output_control_names => debug_runtime_trace_output_control_names(),
        emoji_control_names => debug_runtime_emoji_control_names(),
        snapshot_state_keys => debug_runtime_snapshot_state_keys(),
    };
}

sub debug_runtime_named_trace_verbosity_values {
    return [
        qw(
            none
            low
            medium
            high
            debug
        ),
    ];
}

sub debug_runtime_numeric_trace_level_range {
    return {
        min => 0,
        max => 4,
    };
}

1;
