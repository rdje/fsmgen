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

my $generation_argument_shape = 'scalar filesystem path to a supported .fsm, .isf, or .ppif source root';

subtest 'manifests advertise the facade generation path argument shape' => sub {
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
            $facade->{generation_argument_shape},
            $generation_argument_shape,
            "$label advertises the scalar supported-source generation argument boundary",
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

subtest 'HDLGenerator accepts scalar .fsm source paths for generation' => sub {
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

    ok($result, 'facade accepts a scalar .fsm source path')
        or diag($error);
    is(
        $result->{module_info}{module_name},
        'facade_generation_argument_smoke',
        'accepted .fsm source path still reaches generation',
    ) if $result;
};

subtest 'HDLGenerator rejects malformed generation arguments at the facade boundary' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 1,
    );

    for my $case (
        {
            label => 'undef argument',
            code => sub { $pipeline->generate_hdl_from_file(undef); },
        },
        {
            label => 'empty string',
            code => sub { $pipeline->generate_hdl_from_file(''); },
        },
        {
            label => 'whitespace string',
            code => sub { $pipeline->generate_hdl_from_file('  '); },
        },
        {
            label => 'extensionless path',
            code => sub { $pipeline->generate_hdl_from_file('source_root'); },
        },
        {
            label => 'unsupported source suffix path',
            code => sub { $pipeline->generate_hdl_from_file('source_root.sv'); },
        },
        {
            label => 'arrayref',
            code => sub { $pipeline->generate_hdl_from_file(['source_root.fsm']); },
        },
        {
            label => 'hashref',
            code => sub { $pipeline->generate_hdl_from_file({ source => 'source_root.fsm' }); },
        },
    ) {
        my $error = capture_exception($case->{code});

        like(
            $error,
            qr/FSM::Pipeline::HDLGenerator expects generate_hdl_from_file\(\.\.\.\) argument to be a scalar filesystem path to a supported \.fsm, \.isf, or \.ppif source root/s,
            "$case->{label} receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/SourceGenerationOrchestrator requires an fsm_file|SourceFrontend requires an fsm_file|Failed to open FSM file|Source file:|Can't use .* as/s,
            "$case->{label} does not leak lower-level source-open or raw Perl diagnostics",
        );
    }
};

subtest 'invalid generation arguments preserve caller debug state' => sub {
    set_fsm_trace_verbosity('low');
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 1,
    );

    my $error = capture_exception(sub {
        $pipeline->generate_hdl_from_file({ source => 'not-a-scalar.fsm' });
    });

    like(
        $error,
        qr/FSM::Pipeline::HDLGenerator expects generate_hdl_from_file/s,
        'invalid generation argument still reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'invalid generation argument does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'invalid generation argument does not mutate caller trace verbosity');

    restore_fsm_debug_state($INITIAL_DEBUG_STATE);
};

done_testing();

sub make_direct_source_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'facade_generation_argument_smoke.fsm');

    write_file(
        $fsm_path,
        <<'FSM',
(?fsm:facade_generation_argument_smoke
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
