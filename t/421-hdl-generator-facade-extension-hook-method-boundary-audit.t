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
use FSM::Extension::Registry;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

my $extension_shape = 'array reference of blessed typed-extension objects with at least one supported hook method';
my $hook_policy = 'extension objects must provide at least one real supported hook method discoverable by UNIVERSAL::can';
my $facade_hook_error = qr/FSM::Pipeline::HDLGenerator expects each object in 'extensions' to provide at least one supported typed-extension hook method: after_parse_source, after_generate_result/s;
my $registry_hook_error = qr/FSM::Extension::Registry expects extension objects to provide at least one supported hook method: after_parse_source, after_generate_result/s;

{
    package Test::FacadeExtensionParseHookOnly;

    use strict;
    use warnings;

    sub new { return bless {}, shift }
    sub after_parse_source { return }
}

{
    package Test::FacadeExtensionResultHookOnly;

    use strict;
    use warnings;

    sub new { return bless {}, shift }
    sub after_generate_result { return }
}

{
    package Test::FacadeExtensionHooklessObject;

    use strict;
    use warnings;

    sub new { return bless {}, shift }
}

{
    package Test::FacadeExtensionUnsupportedHookOnly;

    use strict;
    use warnings;

    sub new { return bless {}, shift }
    sub before_parse_source { return }
    sub after_emit_hdl { return }
}

{
    package Test::FacadeExtensionLyingCanAutoloadOnly;

    use strict;
    use warnings;

    our @CAN_CALLS;
    our @AUTOLOAD_CALLS;
    our $AUTOLOAD;

    sub new { return bless {}, shift }

    sub can {
        my ($self, $method_name) = @_;
        push @CAN_CALLS, $method_name;
        return sub { } if $method_name =~ /\Aafter_(?:parse_source|generate_result)\z/;
        return $self->SUPER::can($method_name);
    }

    sub AUTOLOAD {
        push @AUTOLOAD_CALLS, $AUTOLOAD;
    }

    sub DESTROY {}
}

subtest 'manifests advertise the direct-extension hook-method shape' => sub {
    my @views = (
        {
            label => 'direct contracts',
            facade => build_hdl_generator_facade_contract(),
            typed_extensions => build_extension_contract(),
        },
        {
            label => 'in-process capability manifest',
            facade => build_capability_manifest()->{embedding}{hdl_generator_facade},
            typed_extensions => build_capability_manifest()->{embedding}{typed_extensions},
        },
        {
            label => 'CLI capability manifest',
            facade => run_capability_manifest('--capability-manifest')
                ->{embedding}{hdl_generator_facade},
            typed_extensions => run_capability_manifest('--capability-manifest')
                ->{embedding}{typed_extensions},
        },
        {
            label => 'CLI alias capability manifest',
            facade => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{hdl_generator_facade},
            typed_extensions => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{typed_extensions},
        },
    );

    for my $view (@views) {
        my $facade = $view->{facade};
        my $typed_extensions = $view->{typed_extensions};
        my $label = $view->{label};

        is(
            $facade->{constructor_option_shape_map}{extensions},
            $extension_shape,
            "$label advertises the hook-capable direct extensions shape",
        );
        ok(
            $typed_extensions->{extension_object_contract}{must_provide_supported_hook_method},
            "$label requires extension objects to expose a supported hook method",
        );
        is(
            $typed_extensions->{extension_object_contract}{supported_hook_method_policy},
            $hook_policy,
            "$label records the supported-hook discovery policy",
        );
        ok(
            contains_value(
                $typed_extensions->{tested_by},
                't/421-hdl-generator-facade-extension-hook-method-boundary-audit.t',
            ),
            "$label includes this audit in typed-extension tested_by provenance",
        );
    }
};

subtest 'HDLGenerator accepts direct extension objects with at least one real supported hook' => sub {
    for my $case (
        {
            label => 'parse hook only',
            extension => Test::FacadeExtensionParseHookOnly->new(),
        },
        {
            label => 'result hook only',
            extension => Test::FacadeExtensionResultHookOnly->new(),
        },
    ) {
        my $pipeline = eval {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                quiet => 1,
                strict_mode => 0,
                extensions => [$case->{extension}],
            );
        };
        my $error = $@;

        ok($pipeline, "constructor accepts $case->{label} extension")
            or diag($error);
        is_deeply(
            $pipeline->{extension_registry}->extensions,
            [$case->{extension}],
            "$case->{label} extension reaches the registry unchanged",
        ) if $pipeline;
    }
};

subtest 'HDLGenerator rejects hookless or unsupported-hook-only direct extension objects at construction' => sub {
    for my $case (
        {
            label => 'hookless blessed object',
            extension => Test::FacadeExtensionHooklessObject->new(),
        },
        {
            label => 'unsupported hook-shaped methods only',
            extension => Test::FacadeExtensionUnsupportedHookOnly->new(),
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                quiet => 1,
                strict_mode => 0,
                extensions => [$case->{extension}],
            );
        });

        like(
            $error,
            $facade_hook_error,
            "$case->{label} receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/FSM::Extension::Registry|after_emit_hdl|before_parse_source|Can't locate object method/s,
            "$case->{label} does not leak registry, unsupported-hook, or raw method fallout",
        );
    }
};

subtest 'HDLGenerator rejects can/AUTOLOAD hook claims without invoking extension-provided discovery' => sub {
    local @Test::FacadeExtensionLyingCanAutoloadOnly::CAN_CALLS = ();
    local @Test::FacadeExtensionLyingCanAutoloadOnly::AUTOLOAD_CALLS = ();

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            strict_mode => 0,
            extensions => [Test::FacadeExtensionLyingCanAutoloadOnly->new()],
        );
    });

    like(
        $error,
        $facade_hook_error,
        'can/AUTOLOAD hook claims receive the same supported-hook facade diagnostic',
    );
    is_deeply(
        \@Test::FacadeExtensionLyingCanAutoloadOnly::CAN_CALLS,
        [],
        'facade validation does not call extension-provided can()',
    );
    is_deeply(
        \@Test::FacadeExtensionLyingCanAutoloadOnly::AUTOLOAD_CALLS,
        [],
        'facade validation does not call AUTOLOAD',
    );
};

subtest 'registry direct construction enforces the same supported-hook object boundary' => sub {
    my $error = capture_exception(sub {
        FSM::Extension::Registry->new(
            extensions => [Test::FacadeExtensionHooklessObject->new()],
        );
    });

    like(
        $error,
        $registry_hook_error,
        'direct registry construction rejects hookless extension objects',
    );
};

subtest 'direct extension hook-shape rejection preserves caller debug state' => sub {
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 4,
            target_language => 'systemverilog',
            quiet => 1,
            strict_mode => 0,
            extensions => [Test::FacadeExtensionHooklessObject->new()],
        );
    });

    like(
        $error,
        $facade_hook_error,
        'hook-shape rejection reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'hook-shape rejection restores caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'hook-shape rejection restores caller trace verbosity');

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

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}
