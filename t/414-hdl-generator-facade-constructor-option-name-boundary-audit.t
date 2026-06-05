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
    package Test::FacadeConstructorOptionNameExtension;

    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub after_generate_result {
        return;
    }
}

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

my $unknown_option_policy = 'reject unsupported constructor option names before debug-state setup';
my $unknown_option_error = qr/FSM::Pipeline::HDLGenerator does not accept unsupported constructor option\(s\):/s;

subtest 'manifests advertise the facade constructor unknown-option policy' => sub {
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
            $facade->{constructor_unknown_option_policy},
            $unknown_option_policy,
            "$label advertises unsupported constructor option-name rejection",
        );
        is_deeply(
            sorted($facade->{public_constructor_option_names}),
            sorted(hdl_generator_facade_public_constructor_option_names()),
            "$label keeps the public constructor option family builder-owned",
        );
        ok(
            !$facade->{object_injection_args_public},
            "$label still keeps internal owner-injection args non-public",
        );
        ok(
            !contains_value(
                $facade->{public_constructor_option_names},
                'generation_mode',
            ),
            "$label does not advertise generation_mode before a non-flattened backend path exists",
        );
        ok(
            !$facade->{generation_mode_constructor_option_public},
            "$label records generation_mode as non-public",
        );
    }
};

subtest 'HDLGenerator accepts the advertised public constructor option names' => sub {
    my $extension = Test::FacadeConstructorOptionNameExtension->new();
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

    ok($pipeline, 'constructor accepts the bounded public constructor option names')
        or diag($error);
    isa_ok($pipeline, 'FSM::Pipeline::HDLGenerator') if $pipeline;
    is_deeply(
        $pipeline->{extension_registry}->extensions,
        [$extension],
        'accepted public extension option still reaches normal registry construction',
    ) if $pipeline;
};

subtest 'HDLGenerator still accepts known non-public constructor names internally' => sub {
    my $pipeline = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug => 0,
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            extension_modules => [],
            extension_config_files => [],
        );
    };
    my $error = $@;

    ok(
        $pipeline,
        'constructor option-name guard does not reject known non-public extension-loading and legacy compatibility names',
    ) or diag($error);
    isa_ok($pipeline, 'FSM::Pipeline::HDLGenerator') if $pipeline;
};

subtest 'HDLGenerator rejects unsupported constructor option names before lower-level handling' => sub {
    for my $case (
        {
            label => 'debug mode typo',
            args => {
                debug_mode => 1,
            },
            expect => qr/unsupported constructor option\(s\): debug_mode/s,
        },
        {
            label => 'target language typo',
            args => {
                target_lang => 'systemverilog',
            },
            expect => qr/unsupported constructor option\(s\): target_lang/s,
        },
        {
            label => 'generation mode not public',
            args => {
                generation_mode => 'structured',
            },
            expect => qr/unsupported constructor option\(s\): generation_mode/s,
        },
        {
            label => 'source path typo',
            args => {
                source_paths => [],
            },
            expect => qr/unsupported constructor option\(s\): source_paths/s,
        },
        {
            label => 'multiple unsupported names',
            args => {
                zz_unknown => 1,
                aa_unknown => 1,
            },
            expect => qr/unsupported constructor option\(s\): aa_unknown, zz_unknown/s,
        },
        {
            label => 'unknown name wins before known option shape validation',
            args => {
                debug_level => 'verbose',
                target => 'systemverilog',
            },
            expect => qr/unsupported constructor option\(s\): target/s,
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                quiet => 1,
                %{$case->{args}},
            );
        });

        like(
            $error,
            $unknown_option_error,
            "$case->{label} receives the targeted constructor option-name diagnostic",
        );
        like(
            $error,
            $case->{expect},
            "$case->{label} reports the unsupported constructor option name",
        );
        unlike(
            $error,
            qr/Debug\.pm|SourcePathResolver|Extension::Loader|Extension::Registry|SourceGenerationOrchestrator|expects 'debug_level'/s,
            "$case->{label} does not leak lower-level constructor fallout",
        );
    }
};

subtest 'unsupported constructor option names preserve caller debug state' => sub {
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 4,
            target_language => 'systemverilog',
            quiet => 1,
            unsupported_constructor_option => 1,
        );
    });

    like(
        $error,
        qr/unsupported constructor option\(s\): unsupported_constructor_option/s,
        'unsupported constructor option still reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'unsupported constructor option does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'unsupported constructor option does not mutate caller trace verbosity');

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

sub contains_value {
    my ($values, $target) = @_;
    return grep { $_ eq $target } @{$values || []};
}
