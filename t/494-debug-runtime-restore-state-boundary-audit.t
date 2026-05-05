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
);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DebugRuntimeContract qw(build_debug_runtime_contract);

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
my $restore_snapshot_argument_shape = 'exact schema-version-1 snapshot hash with the advertised snapshot_state_keys and bounded scalar values';
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

subtest 'debug-runtime manifests publish the restore snapshot argument shape' => sub {
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
        is(
            $view->{contract}{restore_snapshot_argument_shape},
            $restore_snapshot_argument_shape,
            "$view->{label} advertises the restore snapshot argument shape",
        );
    }
};

subtest 'restore accepts captured snapshots and restores bounded scalar state' => sub {
    set_baseline_debug_state();
    my $saved = capture_fsm_debug_state();

    set_fsm_trace_verbosity('debug');
    set_fsm_trace_emojis(1);
    restore_fsm_debug_state($saved);

    assert_baseline_debug_state('valid captured snapshot restores caller state');
};

subtest 'restore rejects malformed snapshots before mutating caller state' => sub {
    set_baseline_debug_state();
    my $valid = capture_fsm_debug_state();

    my @cases = (
        {
            label => 'non-hash snapshot',
            snapshot => [],
            pattern => qr/Expected a hashref state snapshot/s,
        },
        {
            label => 'missing snapshot key',
            snapshot => mutated_snapshot($valid, delete_key => 'debug_level'),
            pattern => qr/Missing debug-state snapshot key\(s\): debug_level/s,
        },
        {
            label => 'unsupported snapshot key',
            snapshot => mutated_snapshot($valid, set => { unexpected => 1 }),
            pattern => qr/Unsupported debug-state snapshot key\(s\): unexpected/s,
        },
        {
            label => 'unsupported schema version',
            snapshot => mutated_snapshot($valid, set => { schema_version => 2 }),
            pattern => qr/Unsupported debug-state schema version/s,
        },
        {
            label => 'reference debug level',
            snapshot => mutated_snapshot($valid, set => { debug_level => [] }),
            pattern => qr/Expected debug_level to be an integer trace level from 0 through 4/s,
        },
        {
            label => 'out-of-range debug level',
            snapshot => mutated_snapshot($valid, set => { debug_level => 5 }),
            pattern => qr/Expected debug_level to be an integer trace level from 0 through 4/s,
        },
        {
            label => 'malformed debug enabled flag',
            snapshot => mutated_snapshot($valid, set => { debug_enabled => 2 }),
            pattern => qr/Expected debug_enabled to be boolean 0 or 1/s,
        },
        {
            label => 'negative trace indent',
            snapshot => mutated_snapshot($valid, set => { trace_indent_level => -1 }),
            pattern => qr/Expected trace_indent_level to be a non-negative integer/s,
        },
        {
            label => 'reference trace output path',
            snapshot => mutated_snapshot($valid, set => { trace_output_file => [] }),
            pattern => qr/Expected trace_output_file to be undef or a scalar non-empty path/s,
        },
        {
            label => 'empty trace output path',
            snapshot => mutated_snapshot($valid, set => { trace_output_file => '' }),
            pattern => qr/Expected trace_output_file to be undef or a scalar non-empty path/s,
        },
        {
            label => 'non-filehandle trace snapshot',
            snapshot => mutated_snapshot(
                $valid,
                set => {
                    trace_output_file => 'synthetic.trace',
                    trace_output_fh => [],
                },
            ),
            pattern => qr/Expected trace_output_fh to be undef or a filehandle snapshot/s,
        },
        {
            label => 'malformed emoji flag',
            snapshot => mutated_snapshot($valid, set => { trace_emojis_enabled => 'yes' }),
            pattern => qr/Expected trace_emojis_enabled to be boolean 0 or 1/s,
        },
    );

    for my $case (@cases) {
        set_baseline_debug_state();
        my $ok = eval {
            restore_fsm_debug_state($case->{snapshot});
            1;
        };
        my $error = $@ unless $ok;

        ok(!$ok, "$case->{label} is rejected");
        like($error, $case->{pattern}, "$case->{label} receives the targeted diagnostic");
        assert_baseline_debug_state("$case->{label} rejection preserves caller state");
    }
};

done_testing();

sub set_baseline_debug_state {
    set_fsm_trace_verbosity('low');
    set_fsm_trace_emojis(0);
}

sub assert_baseline_debug_state {
    my ($label) = @_;

    is(get_fsm_debug_level(), 1, "$label: debug level");
    is(get_fsm_trace_verbosity(), 'low', "$label: trace verbosity");
    ok(!trace_emojis_enabled(), "$label: trace emoji state");
}

sub mutated_snapshot {
    my ($snapshot, %opts) = @_;
    my %copy = %{$snapshot};

    delete $copy{$opts{delete_key}}
        if exists $opts{delete_key};
    if (exists $opts{set}) {
        for my $key (keys %{$opts{set}}) {
            $copy{$key} = $opts{set}{$key};
        }
    }

    return \%copy;
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
