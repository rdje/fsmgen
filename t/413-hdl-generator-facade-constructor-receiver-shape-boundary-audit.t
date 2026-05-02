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
    package FSM::BoundaryAudit::NotGenerator;
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

my $constructor_receiver_shape = 'scalar FSM::Pipeline::HDLGenerator class name';
my $constructor_receiver_error = qr/FSM::Pipeline::HDLGenerator expects new\(\.\.\.\) invocant to be the FSM::Pipeline::HDLGenerator class name/s;

subtest 'manifests advertise the facade constructor receiver shape' => sub {
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
            $facade->{constructor_receiver_shape},
            $constructor_receiver_shape,
            "$label advertises the HDLGenerator constructor class-name boundary",
        );
        is_deeply(
            sorted($facade->{public_constructor_option_names}),
            sorted(hdl_generator_facade_public_constructor_option_names()),
            "$label constructor option family remains builder-owned",
        );
    }
};

subtest 'HDLGenerator accepts the advertised class receiver at construction' => sub {
    my $pipeline = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
        );
    };
    my $error = $@;

    ok($pipeline, 'facade accepts the advertised HDLGenerator class receiver')
        or diag($error);
    isa_ok($pipeline, 'FSM::Pipeline::HDLGenerator') if $pipeline;
    is($pipeline->{debug_level}, 0, 'accepted constructor receiver still reaches option parsing')
        if $pipeline;
};

subtest 'HDLGenerator rejects malformed constructor receivers at the facade boundary' => sub {
    for my $case (
        {
            label => 'plain string invocant',
            code => sub { FSM::Pipeline::HDLGenerator::new('notobject', debug_level => 0, quiet => 1); },
        },
        {
            label => 'undef invocant',
            code => sub { FSM::Pipeline::HDLGenerator::new(undef, debug_level => 0, quiet => 1); },
        },
        {
            label => 'hashref invocant',
            code => sub { FSM::Pipeline::HDLGenerator::new({ class => 'FSM::Pipeline::HDLGenerator' }, debug_level => 0, quiet => 1); },
        },
        {
            label => 'arrayref invocant',
            code => sub { FSM::Pipeline::HDLGenerator::new(['FSM::Pipeline::HDLGenerator'], debug_level => 0, quiet => 1); },
        },
        {
            label => 'unrelated blessed object invocant',
            code => sub { FSM::Pipeline::HDLGenerator::new(FSM::BoundaryAudit::NotGenerator->new(), debug_level => 0, quiet => 1); },
        },
        {
            label => 'object method call',
            code => sub {
                my $pipeline = FSM::Pipeline::HDLGenerator->new(
                    debug_level => 0,
                    target_language => 'systemverilog',
                    quiet => 1,
                );
                $pipeline->new(debug_level => 0, quiet => 1);
            },
        },
    ) {
        my $error = capture_exception($case->{code});

        like(
            $error,
            $constructor_receiver_error,
            "$case->{label} receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/Attempt to bless|Explicit blessing|Use of uninitialized value|Can't use .* as|HASH ref/s,
            "$case->{label} does not leak raw Perl bless or dereference diagnostics",
        );
    }
};

subtest 'invalid constructor receivers preserve caller debug state' => sub {
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator::new(
            { class => 'FSM::Pipeline::HDLGenerator' },
            debug_level => 4,
            target_language => 'systemverilog',
            quiet => 1,
        );
    });

    like(
        $error,
        $constructor_receiver_error,
        'invalid constructor receiver still reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'invalid constructor receiver does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'invalid constructor receiver does not mutate caller trace verbosity');

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
