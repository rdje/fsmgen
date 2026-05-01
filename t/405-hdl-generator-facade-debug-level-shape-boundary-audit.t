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
    get_fsm_debug_level
    get_fsm_trace_verbosity
    set_fsm_trace_verbosity
);
use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DebugRuntimeContract qw(build_debug_runtime_contract);
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_debug_level_numeric_range
);

my $debug_level_range = {
    min => 0,
    max => 4,
};

subtest 'manifests advertise the facade debug_level numeric range' => sub {
    my $in_process_manifest = build_capability_manifest();
    my @views = (
        {
            label => 'direct facade contract',
            facade => build_hdl_generator_facade_contract(),
            debug_runtime => build_debug_runtime_contract(),
        },
        {
            label => 'in-process capability manifest',
            facade => $in_process_manifest->{embedding}{hdl_generator_facade},
            debug_runtime => $in_process_manifest->{embedding}{debug_runtime},
        },
        {
            label => 'CLI capability manifest',
            manifest => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI alias capability manifest',
            manifest => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        my $facade = $view->{facade}
            || $view->{manifest}{embedding}{hdl_generator_facade};
        my $debug_runtime = $view->{debug_runtime}
            || $view->{manifest}{embedding}{debug_runtime};
        my $label = $view->{label};

        is_deeply(
            $facade->{debug_level_numeric_range},
            $debug_level_range,
            "$label advertises the accepted facade debug_level range",
        );
        is_deeply(
            hdl_generator_facade_debug_level_numeric_range(),
            $debug_level_range,
            "$label debug_level range stays builder-owned",
        );
        is_deeply(
            $facade->{debug_level_numeric_range},
            $debug_runtime->{numeric_trace_level_range},
            "$label facade debug_level range matches the debug-runtime numeric trace range",
        );
        is(
            $facade->{constructor_option_shape_map}{debug_level},
            'integer in debug_level_numeric_range',
            "$label advertises debug_level as a bounded integer range",
        );
    }
};

subtest 'HDLGenerator accepts only debug_level values in the advertised range at construction' => sub {
    for my $debug_level (0 .. 4) {
        my $pipeline = eval {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => $debug_level,
                target_language => 'systemverilog',
                quiet => 1,
            );
        };
        my $error = $@;

        ok($pipeline, "constructor accepts debug_level => $debug_level")
            or diag($error);
        is(
            $pipeline->{debug_level},
            $debug_level,
            "constructor stores canonical debug_level => $debug_level",
        ) if $pipeline;
    }

    for my $case (
        {
            label => 'numeric string',
            value => '2',
            expected => 2,
        },
        {
            label => 'whitespace-padded numeric string',
            value => ' 3 ',
            expected => 3,
        },
    ) {
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            debug_level => $case->{value},
            target_language => 'systemverilog',
            quiet => 1,
        );

        is(
            $pipeline->{debug_level},
            $case->{expected},
            "$case->{label} debug_level is accepted and canonicalized",
        );
    }
};

subtest 'HDLGenerator rejects unsupported debug_level values before debug-runtime normalization' => sub {
    for my $case (
        {
            label => 'negative integer',
            value => -1,
        },
        {
            label => 'above-range integer',
            value => 5,
        },
        {
            label => 'larger above-range integer',
            value => 99,
        },
        {
            label => 'fractional string',
            value => '2.5',
        },
        {
            label => 'named trace verbosity',
            value => 'debug',
        },
        {
            label => 'legacy on alias',
            value => 'on',
        },
        {
            label => 'empty string',
            value => '',
        },
        {
            label => 'arrayref',
            value => [2],
        },
        {
            label => 'hashref',
            value => { debug_level => 2 },
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => $case->{value},
                target_language => 'systemverilog',
                quiet => 1,
            );
        });

        like(
            $error,
            qr/FSM::Pipeline::HDLGenerator expects 'debug_level' to be a scalar integer in the range 0\.\.4/s,
            "$case->{label} debug_level receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/Debug\.pm|Unsupported trace verbosity/s,
            "$case->{label} debug_level does not leak lower-level debug-runtime diagnostics",
        );
    }
};

subtest 'invalid debug_level rejection preserves caller debug state' => sub {
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 'debug',
            target_language => 'systemverilog',
            quiet => 1,
        );
    });

    like(
        $error,
        qr/FSM::Pipeline::HDLGenerator expects 'debug_level'/s,
        'invalid debug_level still reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'invalid constructor debug_level does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'invalid constructor debug_level does not mutate caller trace verbosity');

    set_fsm_trace_verbosity('none');
};

done_testing();

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub capture_exception {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };

    return '' if $ok;
    return $@ || 'unknown error';
}
