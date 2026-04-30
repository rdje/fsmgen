#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Debug qw(
    capture_fsm_debug_state
    get_fsm_debug_level
    get_fsm_trace_verbosity
    restore_fsm_debug_state
    set_fsm_trace_emojis
    set_fsm_trace_verbosity
    trace_emojis_enabled
    with_fsm_debug_state
);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DebugRuntimeContract qw(
    build_debug_runtime_contract
    debug_runtime_snapshot_helper_names
);

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

subtest 'debug-runtime manifests advertise scoped helper boundaries' => sub {
    my @views = (
        {
            label => 'direct debug-runtime contract',
            contract => build_debug_runtime_contract(),
        },
        {
            label => 'in-process capability manifest debug-runtime contract',
            contract => build_capability_manifest()->{embedding}{debug_runtime},
        },
        {
            label => 'CLI capability manifest debug-runtime contract',
            contract => run_capability_manifest('--capability-manifest')->{embedding}{debug_runtime},
        },
        {
            label => 'CLI alias capability manifest debug-runtime contract',
            contract => run_capability_manifest('--emit-capability-manifest')->{embedding}{debug_runtime},
        },
    );

    for my $view (@views) {
        my $contract = $view->{contract};
        my $label = $view->{label};

        is_deeply(
            sorted($contract->{snapshot_helper_names}),
            sorted(debug_runtime_snapshot_helper_names()),
            "$label snapshot helper names match the builder-owned helper list",
        );
        ok(
            contains_value($contract->{snapshot_helper_names}, 'with_fsm_debug_state'),
            "$label advertises with_fsm_debug_state as a snapshot helper",
        );
        is_deeply(
            sorted($contract->{family_map}{snapshot_helper_names}),
            sorted($contract->{snapshot_helper_names}),
            "$label grouped family_map republishes snapshot helpers",
        );
        ok(
            $contract->{pipeline_scopes_debug_state},
            "$label records that HDLGenerator scopes its requested debug state",
        );
        ok(
            !$contract->{general_debug_calls_auto_scoped},
            "$label does not claim ordinary debug setters are auto-scoped",
        );
        ok($contract->{process_global_singleton}, "$label records process-global debug state");
        ok(!$contract->{thread_safe}, "$label does not claim thread-local debug state");
    }
};

subtest 'with_fsm_debug_state restores caller state for scalar list and void contexts' => sub {
    set_baseline_debug_state();

    my $scalar_result = with_fsm_debug_state(
        {
            debug_level => 'debug',
            trace_emojis_enabled => 1,
        },
        sub {
            assert_debug_state(
                4,
                'debug',
                1,
                'scalar scope sees requested debug state',
            );
            return 'scalar-result';
        },
    );

    is($scalar_result, 'scalar-result', 'scalar context returns the callback scalar value');
    assert_baseline_debug_state('scalar scope restores caller debug state');

    my @list_result = with_fsm_debug_state(
        {
            debug_level => 2,
            trace_emojis_enabled => 1,
        },
        sub {
            assert_debug_state(
                2,
                'medium',
                1,
                'list scope sees requested debug state',
            );
            return ('list', get_fsm_debug_level(), get_fsm_trace_verbosity(), trace_emojis_enabled());
        },
    );

    is_deeply(
        \@list_result,
        ['list', 2, 'medium', 1],
        'list context returns the callback list values',
    );
    assert_baseline_debug_state('list scope restores caller debug state');

    my $void_ran = 0;
    with_fsm_debug_state(
        {
            debug_level => 'high',
            trace_emojis_enabled => 1,
        },
        sub {
            $void_ran = 1;
            assert_debug_state(
                3,
                'high',
                1,
                'void scope sees requested debug state',
            );
            return 'ignored-in-void-context';
        },
    );

    ok($void_ran, 'void context still runs the callback');
    assert_baseline_debug_state('void scope restores caller debug state');
};

subtest 'with_fsm_debug_state restores caller state while rethrowing callback errors' => sub {
    set_baseline_debug_state();

    my $error = eval {
        with_fsm_debug_state(
            {
                debug_level => 'debug',
                trace_emojis_enabled => 1,
            },
            sub {
                assert_debug_state(
                    4,
                    'debug',
                    1,
                    'error scope sees requested debug state before failure',
                );
                die "scoped helper forced failure\n";
            },
        );
        undef;
    };
    $error = $@ if !$error;

    like($error, qr/scoped helper forced failure/s, 'callback error is rethrown to the caller');
    assert_baseline_debug_state('error scope restores caller debug state');
};

subtest 'ordinary debug setters remain process-global unless callers scope them' => sub {
    set_baseline_debug_state();

    set_fsm_trace_verbosity('high');
    set_fsm_trace_emojis(1);

    assert_debug_state(
        3,
        'high',
        1,
        'ordinary debug setters mutate process-global state',
    );

    set_baseline_debug_state();
    assert_baseline_debug_state('manual reset is required after ordinary setters');
};

subtest 'with_fsm_debug_state rejects invalid helper arguments without changing caller state' => sub {
    set_baseline_debug_state();

    my $bad_override_error = eval {
        with_fsm_debug_state([], sub { die "should not run" });
        undef;
    };
    $bad_override_error = $@ if !$bad_override_error;
    like(
        $bad_override_error,
        qr/Expected an override hashref/s,
        'with_fsm_debug_state rejects non-hashref overrides',
    );
    assert_baseline_debug_state('invalid override rejection preserves caller state');

    my $bad_code_error = eval {
        with_fsm_debug_state({}, undef);
        undef;
    };
    $bad_code_error = $@ if !$bad_code_error;
    like(
        $bad_code_error,
        qr/Expected a CODE reference/s,
        'with_fsm_debug_state rejects non-code callbacks',
    );
    assert_baseline_debug_state('invalid callback rejection preserves caller state');
};

done_testing();

sub set_baseline_debug_state {
    set_fsm_trace_verbosity('low');
    set_fsm_trace_emojis(0);
}

sub assert_baseline_debug_state {
    my ($label) = @_;
    assert_debug_state(1, 'low', 0, $label);
}

sub assert_debug_state {
    my ($level, $verbosity, $emojis_enabled, $label) = @_;

    is(get_fsm_debug_level(), $level, "$label: debug level");
    is(get_fsm_trace_verbosity(), $verbosity, "$label: trace verbosity");
    is(trace_emojis_enabled(), $emojis_enabled, "$label: trace emoji state");
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
