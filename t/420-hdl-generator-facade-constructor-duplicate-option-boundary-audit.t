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
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_public_constructor_option_names
);

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

my $duplicate_option_policy = 'reject duplicate constructor option names before debug-state setup';
my $duplicate_option_error = qr/FSM::Pipeline::HDLGenerator does not accept duplicate constructor option\(s\):/s;

subtest 'manifests advertise the facade constructor duplicate-option policy' => sub {
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

        is(
            $facade->{constructor_duplicate_option_policy},
            $duplicate_option_policy,
            "$label advertises duplicate constructor option-name rejection",
        );
        is_deeply(
            sorted($facade->{public_constructor_option_names}),
            sorted(hdl_generator_facade_public_constructor_option_names()),
            "$label keeps the public constructor option family builder-owned",
        );
        is(
            $facade->{constructor_argument_list_shape},
            'even-length list of scalar non-empty option-name/value pairs after class invocant',
            "$label still advertises pair-list validation before duplicate checks",
        );
        is(
            $facade->{constructor_unknown_option_policy},
            'reject unsupported constructor option names before debug-state setup',
            "$label still advertises unsupported option-name rejection",
        );
    }
};

subtest 'HDLGenerator rejects duplicate constructor option names before hash overwrite semantics' => sub {
    for my $case (
        {
            label => 'duplicate public debug_level',
            code => sub {
                FSM::Pipeline::HDLGenerator->new(
                    debug_level => 0,
                    target_language => 'systemverilog',
                    debug_level => 4,
                    quiet => 1,
                );
            },
            expect => qr/duplicate constructor option\(s\): debug_level/s,
        },
        {
            label => 'duplicate public quiet',
            code => sub {
                FSM::Pipeline::HDLGenerator->new(
                    debug_level => 0,
                    quiet => 0,
                    quiet => 1,
                );
            },
            expect => qr/duplicate constructor option\(s\): quiet/s,
        },
        {
            label => 'duplicate non-public legacy debug',
            code => sub {
                FSM::Pipeline::HDLGenerator->new(
                    debug => 0,
                    debug => 1,
                    target_language => 'systemverilog',
                    quiet => 1,
                );
            },
            expect => qr/duplicate constructor option\(s\): debug/s,
        },
        {
            label => 'multiple duplicate names report sorted',
            code => sub {
                FSM::Pipeline::HDLGenerator->new(
                    target_language => 'systemverilog',
                    strict_mode => 0,
                    quiet => 0,
                    target_language => 'verilog',
                    quiet => 1,
                    strict_mode => 1,
                );
            },
            expect => qr/duplicate constructor option\(s\): quiet, strict_mode, target_language/s,
        },
    ) {
        my $error = capture_exception($case->{code});

        like(
            $error,
            $duplicate_option_error,
            "$case->{label} receives the targeted duplicate-option diagnostic",
        );
        like(
            $error,
            $case->{expect},
            "$case->{label} reports the duplicated constructor option name",
        );
        unlike(
            $error,
            qr/Debug\.pm|SourcePathResolver|Extension::Loader|Extension::Registry|expects 'debug_level'|expects 'quiet'|expects 'target_language'/s,
            "$case->{label} does not leak lower-level constructor fallout or value-shape diagnostics",
        );
    }
};

subtest 'duplicate constructor option names win before option value-shape validation' => sub {
    for my $case (
        {
            label => 'duplicate name before invalid first debug_level value',
            code => sub {
                FSM::Pipeline::HDLGenerator->new(
                    debug_level => 'debug',
                    debug_level => 0,
                    quiet => 1,
                );
            },
            expect => qr/duplicate constructor option\(s\): debug_level/s,
            reject => qr/expects 'debug_level' to be a scalar integer in the range 0\.\.4/s,
        },
        {
            label => 'duplicate name before invalid later quiet value',
            code => sub {
                FSM::Pipeline::HDLGenerator->new(
                    debug_level => 0,
                    quiet => 1,
                    quiet => 'yes',
                );
            },
            expect => qr/duplicate constructor option\(s\): quiet/s,
            reject => qr/expects 'quiet' to be a scalar boolean 0 or 1/s,
        },
        {
            label => 'duplicate name before unsupported name validation',
            code => sub {
                FSM::Pipeline::HDLGenerator->new(
                    debug_level => 0,
                    target_lang => 'systemverilog',
                    target_lang => 'verilog',
                    quiet => 1,
                );
            },
            expect => qr/duplicate constructor option\(s\): target_lang/s,
            reject => qr/unsupported constructor option\(s\): target_lang/s,
        },
    ) {
        my $error = capture_exception($case->{code});

        like(
            $error,
            $case->{expect},
            "$case->{label} reports duplicate names first",
        );
        unlike(
            $error,
            $case->{reject},
            "$case->{label} does not reach the later constructor boundary",
        );
    }
};

subtest 'duplicate constructor option rejection preserves caller debug state' => sub {
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 4,
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
        );
    });

    like(
        $error,
        qr/duplicate constructor option\(s\): debug_level/s,
        'duplicate option rejection reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'duplicate option rejection does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'duplicate option rejection does not mutate caller trace verbosity');

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

sub capture_exception {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };

    return '' if $ok;
    return $@ || 'unknown error';
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
