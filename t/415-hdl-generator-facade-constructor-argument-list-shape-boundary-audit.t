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

{
    package Test::FacadeConstructorArgumentListShapeExtension;

    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }
}

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

my $argument_list_shape = 'even-length list of scalar non-empty option-name/value pairs after class invocant';
my $pair_error = qr/FSM::Pipeline::HDLGenerator expects new\(\.\.\.\) arguments after the class invocant to be option\/value pairs/s;
my $name_error = qr/FSM::Pipeline::HDLGenerator expects new\(\.\.\.\) option names to be scalar non-empty strings before constructor option-name validation/s;

subtest 'manifests advertise the facade constructor argument-list shape' => sub {
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
            $facade->{constructor_argument_list_shape},
            $argument_list_shape,
            "$label advertises constructor option/value pair shape before hash coercion",
        );
        is_deeply(
            sorted($facade->{public_constructor_option_names}),
            sorted(hdl_generator_facade_public_constructor_option_names()),
            "$label keeps the public constructor option family builder-owned",
        );
        is(
            $facade->{constructor_unknown_option_policy},
            'reject unsupported constructor option names before debug-state setup',
            "$label still advertises unsupported constructor option-name rejection",
        );
    }
};

subtest 'HDLGenerator accepts well-formed constructor option/value lists' => sub {
    my $default_pipeline = eval {
        FSM::Pipeline::HDLGenerator->new();
    };
    my $default_error = $@;
    ok($default_pipeline, 'constructor accepts an empty option/value list')
        or diag($default_error);
    isa_ok($default_pipeline, 'FSM::Pipeline::HDLGenerator')
        if $default_pipeline;

    my $extension = Test::FacadeConstructorArgumentListShapeExtension->new();
    my $pipeline = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            strict_mode => 0,
            source_search_paths => [],
            extensions => [$extension],
        );
    };
    my $error = $@;

    ok($pipeline, 'constructor accepts well-formed public option/value pairs')
        or diag($error);
    isa_ok($pipeline, 'FSM::Pipeline::HDLGenerator')
        if $pipeline;
    is_deeply(
        $pipeline->{extension_registry}->extensions,
        [$extension],
        'accepted public option/value list still reaches normal registry construction',
    ) if $pipeline;
};

subtest 'HDLGenerator rejects odd constructor argument lists before hash assignment' => sub {
    for my $case (
        {
            label => 'single dangling option name',
            code => sub { FSM::Pipeline::HDLGenerator->new('debug_level'); },
        },
        {
            label => 'dangling option after valid pairs',
            code => sub {
                FSM::Pipeline::HDLGenerator->new(
                    debug_level => 0,
                    quiet => 1,
                    'strict_mode',
                );
            },
        },
        {
            label => 'dangling unsupported option after valid pairs',
            code => sub {
                FSM::Pipeline::HDLGenerator->new(
                    target_language => 'systemverilog',
                    'unknown_option',
                );
            },
        },
    ) {
        my $error = capture_exception($case->{code});

        like(
            $error,
            $pair_error,
            "$case->{label} receives the targeted option/value pair diagnostic",
        );
        unlike(
            $error,
            qr/Odd number of elements|unsupported constructor option|expects 'debug_level'|Debug\.pm|SourcePathResolver/s,
            "$case->{label} does not leak hash-assignment or lower-level fallout",
        );
    }
};

subtest 'HDLGenerator rejects non-scalar or empty constructor option names before stringification' => sub {
    for my $case (
        {
            label => 'undef option name',
            code => sub { FSM::Pipeline::HDLGenerator->new(undef, 1); },
        },
        {
            label => 'empty option name',
            code => sub { FSM::Pipeline::HDLGenerator->new('' => 1); },
        },
        {
            label => 'whitespace option name',
            code => sub { FSM::Pipeline::HDLGenerator->new(" \t" => 1); },
        },
        {
            label => 'arrayref option name',
            code => sub { FSM::Pipeline::HDLGenerator->new([] => 1); },
        },
        {
            label => 'hashref option name',
            code => sub { FSM::Pipeline::HDLGenerator->new({ name => 'debug_level' } => 1); },
        },
    ) {
        my $error = capture_exception($case->{code});

        like(
            $error,
            $name_error,
            "$case->{label} receives the targeted constructor option-name shape diagnostic",
        );
        my $primary_error_line = first_error_line($error);
        unlike(
            $primary_error_line,
            qr/unsupported constructor option|HASH\(0x|ARRAY\(0x|Use of uninitialized value|Odd number of elements/s,
            "$case->{label} primary diagnostic does not stringify malformed option names or leak raw hash diagnostics",
        );
    }
};

subtest 'malformed constructor argument lists preserve caller debug state' => sub {
    set_fsm_trace_verbosity('low');

    my $pair_shape_error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 4,
            target_language => 'systemverilog',
            'quiet',
        );
    });

    like(
        $pair_shape_error,
        $pair_error,
        'odd constructor argument list reports the facade pair-shape diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'odd constructor argument list does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'odd constructor argument list does not mutate caller trace verbosity');

    restore_fsm_debug_state($INITIAL_DEBUG_STATE);
    set_fsm_trace_verbosity('low');

    my $name_shape_error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 4,
            [] => 1,
        );
    });

    like(
        $name_shape_error,
        $name_error,
        'malformed constructor option name reports the facade option-name shape diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'malformed constructor option name does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'malformed constructor option name does not mutate caller trace verbosity');

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
sub first_error_line {
    my ($error) = @_;
    my ($line) = split /\n/, $error || '', 2;
    return $line || '';
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
