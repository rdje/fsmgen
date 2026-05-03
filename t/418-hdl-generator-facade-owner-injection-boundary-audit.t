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
    package Test::FacadeOwnerInjectionResolver;

    use strict;
    use warnings;

    sub new { return bless {}, shift; }
    sub normalized_search_paths { return []; }
}

{
    package Test::FacadeOwnerInjectionLoader;

    use strict;
    use warnings;

    sub new { return bless {}, shift; }
    sub module_names_from_config_files { return []; }
    sub load_modules { return []; }
}

{
    package Test::FacadeOwnerInjectionRegistry;

    use strict;
    use warnings;

    sub new { return bless {}, shift; }
    sub after_parse_source { return; }
    sub after_generate_result { return; }
}

{
    package Test::FacadeOwnerInjectionRTLInterfaceLoader;

    use strict;
    use warnings;

    sub new { return bless {}, shift; }
    sub load_interface { return; }
}

{
    package Test::FacadeOwnerInjectionNoMethods;

    use strict;
    use warnings;

    sub new { return bless {}, shift; }
}

{
    package Test::FacadeOwnerInjectionFakeCan;

    use strict;
    use warnings;

    sub new { return bless {}, shift; }
    sub can { return sub { return; }; }
}

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

my @owner_injection_args = qw(
    source_path_resolver
    extension_loader
    extension_registry
    rtl_interface_loader
);
my $owner_injection_policy = 'non-public owner-injection values fail closed when present and must be blessed objects providing required owner methods';
my $owner_injection_error = qr/FSM::Pipeline::HDLGenerator expects non-public owner-injection constructor option '([^']+)' to be a blessed object providing required owner methods/s;

subtest 'manifests keep owner-injection hidden while advertising the fail-closed policy' => sub {
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
            !$facade->{object_injection_args_public},
            "$label keeps owner-injection constructor options non-public",
        );
        is(
            $facade->{object_injection_arg_policy},
            $owner_injection_policy,
            "$label advertises fail-closed handling for non-public owner-injection values",
        );
        is_deeply(
            sorted($facade->{public_constructor_option_names}),
            sorted(hdl_generator_facade_public_constructor_option_names()),
            "$label keeps the public constructor option family builder-owned",
        );
        assert_owner_injection_args_hidden($facade, $label);
    }
};

subtest 'HDLGenerator accepts valid non-public owner-injection objects internally' => sub {
    my $resolver = Test::FacadeOwnerInjectionResolver->new();
    my $loader = Test::FacadeOwnerInjectionLoader->new();
    my $registry = Test::FacadeOwnerInjectionRegistry->new();
    my $rtl_loader = Test::FacadeOwnerInjectionRTLInterfaceLoader->new();

    my $pipeline = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            strict_mode => 0,
            source_path_resolver => $resolver,
            extension_loader => $loader,
            extension_registry => $registry,
            rtl_interface_loader => $rtl_loader,
        );
    };
    my $error = $@;

    ok($pipeline, 'constructor accepts valid internal owner-injection objects')
        or diag($error);
    isa_ok($pipeline, 'FSM::Pipeline::HDLGenerator') if $pipeline;
    is($pipeline->{source_path_resolver}, $resolver, 'accepted source_path_resolver is stored unchanged') if $pipeline;
    is($pipeline->{extension_loader}, $loader, 'accepted extension_loader is stored unchanged') if $pipeline;
    is($pipeline->{extension_registry}, $registry, 'accepted extension_registry is stored unchanged') if $pipeline;
    is($pipeline->{rtl_interface_loader}, $rtl_loader, 'accepted rtl_interface_loader is stored unchanged') if $pipeline;
};

subtest 'HDLGenerator rejects malformed owner-injection values before owner calls or invalid state' => sub {
    for my $case (
        {
            label => 'scalar source_path_resolver',
            arg => 'source_path_resolver',
            value => 'not-a-resolver',
        },
        {
            label => 'scalar extension_loader',
            arg => 'extension_loader',
            value => 'not-a-loader',
        },
        {
            label => 'hashref extension_registry',
            arg => 'extension_registry',
            value => { registry => 'not-blessed' },
        },
        {
            label => 'blessed object without rtl_interface_loader methods',
            arg => 'rtl_interface_loader',
            value => Test::FacadeOwnerInjectionNoMethods->new(),
        },
        {
            label => 'fake can source_path_resolver',
            arg => 'source_path_resolver',
            value => Test::FacadeOwnerInjectionFakeCan->new(),
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                quiet => 1,
                strict_mode => 0,
                $case->{arg} => $case->{value},
            );
        });

        like(
            $error,
            qr/FSM::Pipeline::HDLGenerator expects non-public owner-injection constructor option '\Q$case->{arg}\E' to be a blessed object providing required owner methods/s,
            "$case->{label} receives the targeted owner-injection diagnostic",
        );
        unlike(
            $error,
            qr/Can't locate object method|Can't call method|SourcePathResolver|Extension::Loader|Extension::Registry|RTLInterfaceLoader|SourceGenerationOrchestrator|Not a HASH reference/s,
            "$case->{label} does not leak lower-level owner or raw Perl diagnostics",
        );
    }
};

subtest 'invalid owner-injection values preserve caller debug state' => sub {
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 4,
            target_language => 'systemverilog',
            quiet => 1,
            strict_mode => 0,
            extension_loader => 'not-a-loader',
        );
    });

    like(
        $error,
        $owner_injection_error,
        'invalid owner-injection value still reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'invalid owner-injection value does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'invalid owner-injection value does not mutate caller trace verbosity');

    restore_fsm_debug_state($INITIAL_DEBUG_STATE);
};

done_testing();

sub assert_owner_injection_args_hidden {
    my ($facade, $label) = @_;
    my @advertised = advertised_constructor_args($facade);
    my %advertised = map { $_ => 1 } @advertised;

    for my $arg (@owner_injection_args) {
        ok(
            !$advertised{$arg},
            "$label does not advertise non-public owner-injection option $arg",
        );
    }
}

sub advertised_constructor_args {
    my ($facade) = @_;
    my @args = (
        @{$facade->{public_constructor_option_names} || []},
        @{$facade->{core_constructor_option_names} || []},
        @{$facade->{direct_extension_option_names} || []},
    );

    my $family_map = $facade->{constructor_option_family_map} || {};
    for my $family (sort keys %{$family_map}) {
        push @args, @{$family_map->{$family} || []};
    }

    return @{sorted(\@args)};
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
    my %seen;
    return [sort grep { !$seen{$_}++ } @{$values || []}];
}
