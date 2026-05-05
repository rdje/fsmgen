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
    set_fsm_trace_verbosity
);
use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

my $legacy_debug_error =
    qr/FSM::Pipeline::HDLGenerator expects 'debug' to be a scalar boolean 0 or 1/s;

subtest 'legacy debug stays out of the public facade manifest surface' => sub {
    my @views = (
        {
            label => 'direct facade contract',
            facade => build_hdl_generator_facade_contract(),
        },
        {
            label => 'in-process capability manifest',
            facade => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI capability manifest',
            facade => run_capability_manifest('--capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI alias capability manifest',
            facade => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
    );

    for my $view (@views) {
        my $facade = $view->{facade};
        my $label = $view->{label};

        ok(
            !contains_value($facade->{public_constructor_option_names}, 'debug'),
            "$label does not publish legacy debug as a public constructor option",
        );
        ok(
            !contains_value($facade->{core_constructor_option_names}, 'debug'),
            "$label does not classify legacy debug as a core runtime option",
        );
        ok(
            !contains_value($facade->{compatibility_constructor_option_names}, 'debug'),
            "$label does not classify legacy debug as public compatibility state",
        );
        ok(
            !contains_value($facade->{direct_extension_option_names}, 'debug'),
            "$label does not classify legacy debug as direct extension injection",
        );
        ok(
            !exists $facade->{constructor_option_shape_map}{debug},
            "$label does not advertise a public shape for legacy debug",
        );
        is(
            $facade->{constructor_unknown_option_policy},
            'reject unsupported constructor option names before debug-state setup',
            "$label keeps unsupported names rejected at the facade seam",
        );
        ok(
            !$facade->{object_injection_args_public},
            "$label still keeps non-public constructor names out of the facade surface",
        );
    }
};

subtest 'legacy debug accepts only scalar boolean compatibility values' => sub {
    for my $case (
        {
            label => 'integer false',
            value => 0,
            expected => 0,
        },
        {
            label => 'integer true',
            value => 1,
            expected => 1,
        },
        {
            label => 'string false',
            value => '0',
            expected => 0,
        },
        {
            label => 'string true',
            value => '1',
            expected => 1,
        },
        {
            label => 'whitespace-padded string false',
            value => ' 0 ',
            expected => 0,
        },
        {
            label => 'whitespace-padded string true',
            value => ' 1 ',
            expected => 1,
        },
    ) {
        my $pipeline = eval {
            FSM::Pipeline::HDLGenerator->new(
                debug => $case->{value},
                target_language => 'systemverilog',
                quiet => 1,
            );
        };
        my $error = $@;

        ok($pipeline, "$case->{label} legacy debug constructs a facade object")
            or diag($error);
        is(
            $pipeline->{debug_level},
            $case->{expected},
            "$case->{label} legacy debug maps to the canonical debug_level",
        ) if $pipeline;
    }
};

subtest 'public debug_level takes precedence over legacy debug' => sub {
    for my $case (
        {
            label => 'public false beats legacy true',
            debug => 1,
            debug_level => 0,
            expected => 0,
        },
        {
            label => 'public high verbosity beats legacy false',
            debug => 0,
            debug_level => 4,
            expected => 4,
        },
    ) {
        my $pipeline = eval {
            FSM::Pipeline::HDLGenerator->new(
                debug => $case->{debug},
                debug_level => $case->{debug_level},
                target_language => 'systemverilog',
                quiet => 1,
            );
        };
        my $error = $@;

        ok($pipeline, "$case->{label} constructs a facade object")
            or diag($error);
        is(
            $pipeline->{debug_level},
            $case->{expected},
            "$case->{label} stores the public debug_level value",
        ) if $pipeline;
    }
};

subtest 'malformed legacy debug values fail before debug-runtime setup' => sub {
    for my $case (
        {
            label => 'negative integer',
            value => -1,
        },
        {
            label => 'above-range integer',
            value => 2,
        },
        {
            label => 'multi-digit false-looking string',
            value => '00',
        },
        {
            label => 'multi-digit true-looking string',
            value => '01',
        },
        {
            label => 'named trace verbosity',
            value => 'debug',
        },
        {
            label => 'empty string',
            value => '',
        },
        {
            label => 'whitespace-only string',
            value => ' ',
        },
        {
            label => 'arrayref',
            value => [1],
        },
        {
            label => 'hashref',
            value => { debug => 1 },
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug => $case->{value},
                target_language => 'systemverilog',
                quiet => 1,
            );
        });

        like(
            $error,
            $legacy_debug_error,
            "$case->{label} legacy debug receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/Debug\.pm|Unsupported trace verbosity|SourcePathResolver|Extension::Loader|Extension::Registry/s,
            "$case->{label} legacy debug does not leak lower-level constructor diagnostics",
        );
    }
};

subtest 'invalid legacy debug rejection preserves caller debug state' => sub {
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug => 'debug',
            target_language => 'systemverilog',
            quiet => 1,
        );
    });

    like(
        $error,
        $legacy_debug_error,
        'invalid legacy debug still reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'invalid legacy debug does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'invalid legacy debug does not mutate caller trace verbosity');

    restore_fsm_debug_state($INITIAL_DEBUG_STATE);
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

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
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
