#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::DebugRuntimeContract qw(
    build_debug_runtime_contract
    debug_runtime_contract_source
    debug_runtime_emoji_control_names
    debug_runtime_family_map
    debug_runtime_named_trace_verbosity_values
    debug_runtime_public_top_level_keys
    debug_runtime_snapshot_helper_names
    debug_runtime_snapshot_state_keys
    debug_runtime_state_control_names
    debug_runtime_trace_output_control_names
);

subtest 'contract exposes the bounded embedding-facing debug runtime seam' => sub {
    my $contract = build_debug_runtime_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks the debug runtime seam as bounded public');
    is(
        $contract->{contract_source},
        debug_runtime_contract_source(),
        'contract records its own owner',
    );
    is_deeply(
        $contract->{implementation_owners},
        [
            'FSM::Debug',
            'FSM::Pipeline::HDLGenerator',
        ],
        'contract records the implementation owners of the shipped seam',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        debug_runtime_public_top_level_keys(),
        'contract publishes the bounded contract top-level keys',
    );
    is_deeply(
        $contract->{snapshot_helper_names},
        debug_runtime_snapshot_helper_names(),
        'contract publishes the bounded save/restore helper family',
    );
    is_deeply(
        $contract->{state_control_names},
        debug_runtime_state_control_names(),
        'contract publishes the bounded debug-level control family',
    );
    is_deeply(
        $contract->{trace_output_control_names},
        debug_runtime_trace_output_control_names(),
        'contract publishes the bounded trace-output control family',
    );
    is_deeply(
        $contract->{emoji_control_names},
        debug_runtime_emoji_control_names(),
        'contract publishes the bounded emoji control family',
    );
    is_deeply(
        $contract->{snapshot_state_keys},
        debug_runtime_snapshot_state_keys(),
        'contract publishes the bounded snapshot-state key family',
    );
    is_deeply(
        $contract->{family_map},
        debug_runtime_family_map(),
        'contract publishes the grouped helper and snapshot-state family map',
    );
    is_deeply(
        $contract->{named_trace_verbosity_values},
        debug_runtime_named_trace_verbosity_values(),
        'contract publishes the bounded named trace verbosity values',
    );
    is_deeply(
        $contract->{numeric_trace_level_range},
        { min => 0, max => 4 },
        'contract publishes the bounded numeric trace level range',
    );
    ok($contract->{process_global_singleton}, 'contract records that FSM::Debug is still process-global');
    ok(!$contract->{thread_safe}, 'contract does not claim the current debug seam is thread-safe');
    ok(!$contract->{snapshot_json_safe}, 'contract does not claim runtime snapshots are JSON-safe');
    ok(
        $contract->{snapshot_contains_live_filehandle_when_bound},
        'contract records that a captured snapshot can include a live trace filehandle',
    );
    ok(
        $contract->{pipeline_scopes_debug_state},
        'contract records that HDLGenerator scopes its requested debug state',
    );
    ok(
        !$contract->{general_debug_calls_auto_scoped},
        'contract does not claim every debug call is automatically scoped',
    );
};

done_testing();
