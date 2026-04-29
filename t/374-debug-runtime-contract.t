#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Debug ();
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
        [sort @{$contract->{public_top_level_presence_keys}}],
        [sort keys %{$contract}],
        'contract top-level presence list covers every emitted debug-runtime contract key',
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

subtest 'advertised debug runtime helpers stay backed by exported FSM::Debug functions' => sub {
    my %exported = map { $_ => 1 } @FSM::Debug::EXPORT;

    for my $name (@{advertised_debug_runtime_function_names()}) {
        ok(FSM::Debug->can($name), "FSM::Debug implements advertised helper $name");
        ok($exported{$name}, "FSM::Debug exports advertised helper $name");
    }
};

subtest 'advertised trace verbosity values stay backed by FSM::Debug runtime mapping' => sub {
    my $contract = build_debug_runtime_contract();
    my @levels = values %FSM::Debug::VERBOSITY_TO_LEVEL;

    is_deeply(
        [sort @{$contract->{named_trace_verbosity_values}}],
        [sort keys %FSM::Debug::VERBOSITY_TO_LEVEL],
        'contract named trace verbosity values match the live debug mapping',
    );
    is_deeply(
        $contract->{numeric_trace_level_range},
        {
            min => min_value(@levels),
            max => max_value(@levels),
        },
        'contract numeric trace level range matches the live debug mapping',
    );

    my $saved = FSM::Debug::capture_fsm_debug_state();
    for my $name (@{$contract->{named_trace_verbosity_values}}) {
        FSM::Debug::set_fsm_trace_verbosity($name);
        is(
            FSM::Debug::get_fsm_trace_verbosity(),
            $name,
            "FSM::Debug accepts advertised trace verbosity $name",
        );
    }
    FSM::Debug::restore_fsm_debug_state($saved);
};

subtest 'advertised snapshot state keys stay backed by captured FSM::Debug snapshots' => sub {
    my $contract = build_debug_runtime_contract();
    my $saved = FSM::Debug::capture_fsm_debug_state();
    my $tempdir = tempdir(CLEANUP => 1);
    my $trace_path = File::Spec->catfile($tempdir, 'snapshot-contract.trace');

    FSM::Debug::set_fsm_trace_verbosity('high');
    FSM::Debug::set_fsm_trace_emojis(0);
    FSM::Debug::set_fsm_trace_output_file($trace_path);

    my $snapshot = FSM::Debug::capture_fsm_debug_state();

    is_deeply(
        [sort keys %{$snapshot}],
        [sort @{debug_runtime_snapshot_state_keys()}],
        'captured debug-state snapshot keys match the contract snapshot key builder',
    );
    is_deeply(
        [sort keys %{$snapshot}],
        [sort @{$contract->{snapshot_state_keys}}],
        'captured debug-state snapshot keys match the emitted contract key list',
    );
    is($snapshot->{schema_version}, 1, 'captured snapshot keeps schema version 1');
    is(
        $snapshot->{debug_level},
        $FSM::Debug::VERBOSITY_TO_LEVEL{high},
        'captured snapshot records the live debug level',
    );
    ok($snapshot->{debug_enabled}, 'captured snapshot records debug enabled');
    is($snapshot->{trace_output_file}, $trace_path, 'captured snapshot records trace output path');
    ok(live_filehandle($snapshot->{trace_output_fh}), 'captured snapshot keeps a live trace filehandle');
    ok(!$snapshot->{trace_emojis_enabled}, 'captured snapshot records disabled trace emojis');
    ok(
        !json_encode_succeeds($snapshot),
        'trace-bound debug-state snapshot is not JSON-safe as a whole',
    );

    FSM::Debug::restore_fsm_debug_state($saved);
};

done_testing();

sub advertised_debug_runtime_function_names {
    return [
        @{debug_runtime_snapshot_helper_names()},
        @{debug_runtime_state_control_names()},
        @{debug_runtime_trace_output_control_names()},
        @{debug_runtime_emoji_control_names()},
    ];
}

sub min_value {
    my (@values) = @_;
    my $min = shift @values;
    for my $value (@values) {
        $min = $value if $value < $min;
    }
    return $min;
}

sub max_value {
    my (@values) = @_;
    my $max = shift @values;
    for my $value (@values) {
        $max = $value if $value > $max;
    }
    return $max;
}

sub live_filehandle {
    my ($fh) = @_;
    return 0 unless defined $fh;
    return defined eval { fileno($fh) } ? 1 : 0;
}

sub json_encode_succeeds {
    my ($value) = @_;
    return eval {
        encode_json($value);
        1;
    } ? 1 : 0;
}
