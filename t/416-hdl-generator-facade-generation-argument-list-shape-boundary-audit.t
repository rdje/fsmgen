#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
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
    hdl_generator_facade_method_names
);

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

my $generation_argument_list_shape = 'exactly one source-path argument after object invocant';
my $generation_argument_list_error = qr/FSM::Pipeline::HDLGenerator expects generate_hdl_from_file\(\.\.\.\) arguments after the object invocant to contain exactly one source-path argument/s;
my $generation_argument_shape_error = qr/FSM::Pipeline::HDLGenerator expects generate_hdl_from_file\(\.\.\.\) argument to be a scalar filesystem path to a supported \.fsm, \.isf, or \.ppif source root/s;

subtest 'manifests advertise the facade generation argument-list shape' => sub {
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
            $facade->{generation_argument_list_shape},
            $generation_argument_list_shape,
            "$label advertises exact generation argument-list cardinality",
        );
        is(
            $facade->{generation_argument_shape},
            'scalar filesystem path to a supported .fsm, .isf, or .ppif source root',
            "$label still advertises the scalar supported-source value shape",
        );
        ok(
            contains_value($facade->{method_names}, 'generate_hdl_from_file'),
            "$label keeps generate_hdl_from_file in the public method family",
        );
        is_deeply(
            sorted($facade->{method_names}),
            sorted(hdl_generator_facade_method_names()),
            "$label method family remains builder-owned",
        );
    }
};

subtest 'HDLGenerator accepts exactly one generation source-path argument' => sub {
    my $fixture = make_direct_source_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 1,
    );

    my $result = eval {
        $pipeline->generate_hdl_from_file($fixture->{fsm_path});
    };
    my $error = $@;

    ok($result, 'facade accepts exactly one .fsm source-path argument')
        or diag($error);
    is(
        $result->{module_info}{module_name},
        'facade_generation_argument_list_smoke',
        'accepted argument list still reaches generation',
    ) if $result;
};

subtest 'HDLGenerator rejects missing or extra generation arguments at the facade boundary' => sub {
    my $fixture = make_direct_source_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 1,
    );

    for my $case (
        {
            label => 'omitted source-path argument',
            code => sub { $pipeline->generate_hdl_from_file(); },
        },
        {
            label => 'two source-path arguments',
            code => sub {
                $pipeline->generate_hdl_from_file(
                    $fixture->{fsm_path},
                    $fixture->{fsm_path},
                );
            },
        },
        {
            label => 'valid source-path plus undef',
            code => sub {
                $pipeline->generate_hdl_from_file(
                    $fixture->{fsm_path},
                    undef,
                );
            },
        },
        {
            label => 'valid source-path plus malformed reference',
            code => sub {
                $pipeline->generate_hdl_from_file(
                    $fixture->{fsm_path},
                    { extra => 'not-public' },
                );
            },
        },
    ) {
        my $error = capture_exception($case->{code});

        like(
            $error,
            $generation_argument_list_error,
            "$case->{label} receives the targeted argument-list diagnostic",
        );
        unlike(
            $error,
            qr/Too many arguments|expected at most|SourceGenerationOrchestrator|Source file:|Failed to open FSM file|Can't use .* as/s,
            "$case->{label} does not leak Perl signature or lower-level source diagnostics",
        );
    }
};

subtest 'single malformed generation arguments still use the value-shape diagnostic' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 1,
    );

    for my $case (
        {
            label => 'single undef argument',
            code => sub { $pipeline->generate_hdl_from_file(undef); },
        },
        {
            label => 'single arrayref argument',
            code => sub { $pipeline->generate_hdl_from_file(['source_root.fsm']); },
        },
        {
            label => 'single non-fsm scalar argument',
            code => sub { $pipeline->generate_hdl_from_file('source_root.sv'); },
        },
    ) {
        my $error = capture_exception($case->{code});

        like(
            $error,
            $generation_argument_shape_error,
            "$case->{label} remains covered by the scalar supported-source value-shape diagnostic",
        );
        unlike(
            $error,
            $generation_argument_list_error,
            "$case->{label} is not misclassified as an argument-list cardinality failure",
        );
    }
};

subtest 'malformed generation argument lists preserve caller debug state' => sub {
    my $fixture = make_direct_source_fixture();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 1,
    );
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        $pipeline->generate_hdl_from_file(
            $fixture->{fsm_path},
            $fixture->{fsm_path},
        );
    });

    like(
        $error,
        $generation_argument_list_error,
        'extra generation argument still reports the facade argument-list diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'malformed generation argument list does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'malformed generation argument list does not mutate caller trace verbosity');

    restore_fsm_debug_state($INITIAL_DEBUG_STATE);
};

done_testing();

sub make_direct_source_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'facade_generation_argument_list_smoke.fsm');

    write_file(
        $fsm_path,
        <<'FSM',
(?fsm:facade_generation_argument_list_smoke
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 1))
  )
)
FSM
    );

    return {
        tempdir => $tempdir,
        fsm_path => $fsm_path,
    };
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

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
