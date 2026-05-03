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

{
    package FSM::Pipeline::HDLGenerator::BoundaryAuditSubclass;

    use strict;
    use warnings;

    our @ISA = ('FSM::Pipeline::HDLGenerator');

    sub hash_receiver {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub array_receiver {
        my ($class) = @_;
        return bless [], $class;
    }
}

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

my $generation_receiver_instance_shape = 'exact hash-backed FSM::Pipeline::HDLGenerator instance constructed by new(...) with required facade state';
my $generation_receiver_instance_error = qr/FSM::Pipeline::HDLGenerator expects generate_hdl_from_file\(\.\.\.\) invocant to be a blessed FSM::Pipeline::HDLGenerator object constructed by new\(\.\.\.\) with valid facade state/s;

subtest 'manifests advertise the facade generation receiver instance shape' => sub {
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
            $facade->{generation_receiver_instance_shape},
            $generation_receiver_instance_shape,
            "$label advertises exact constructed-facade receiver instances",
        );
        is(
            $facade->{generation_receiver_shape},
            'blessed FSM::Pipeline::HDLGenerator object',
            "$label still advertises the public receiver object family",
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

subtest 'HDLGenerator accepts real constructed facade instances as generation receivers' => sub {
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

    ok($result, 'facade accepts a real constructed HDLGenerator receiver instance')
        or diag($error);
    is(
        $result->{module_info}{module_name},
        'facade_generation_receiver_instance_smoke',
        'accepted constructed receiver still reaches generation',
    ) if $result;
};

subtest 'HDLGenerator rejects fake exact-class and subclass receivers before lower-level fallout' => sub {
    my $fixture = make_direct_source_fixture();
    my $source = $fixture->{fsm_path};

    for my $case (
        {
            label => 'manually blessed exact-class hash',
            receiver => bless({}, 'FSM::Pipeline::HDLGenerator'),
        },
        {
            label => 'manually blessed exact-class array',
            receiver => bless([], 'FSM::Pipeline::HDLGenerator'),
        },
        {
            label => 'subclass hash receiver',
            receiver => FSM::Pipeline::HDLGenerator::BoundaryAuditSubclass->hash_receiver(),
        },
        {
            label => 'subclass array receiver',
            receiver => FSM::Pipeline::HDLGenerator::BoundaryAuditSubclass->array_receiver(),
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator::generate_hdl_from_file(
                $case->{receiver},
                $source,
            );
        });

        like(
            $error,
            $generation_receiver_instance_error,
            "$case->{label} receives the constructed-instance receiver diagnostic",
        );
        unlike(
            $error,
            qr/SourceGenerationOrchestrator|Source file:|Failed to open FSM file|Not a HASH reference|Can't call method|Can't use .* as/s,
            "$case->{label} does not leak source orchestration or raw Perl receiver diagnostics",
        );
    }
};

subtest 'HDLGenerator rejects corrupted constructed receiver state before source orchestration' => sub {
    my $fixture = make_direct_source_fixture();

    for my $case (
        {
            label => 'missing extension registry state',
            mutate => sub { delete $_[0]->{extension_registry}; },
        },
        {
            label => 'invalid source path resolver state',
            mutate => sub { $_[0]->{source_path_resolver} = 'not-a-resolver'; },
        },
        {
            label => 'invalid target language state',
            mutate => sub { $_[0]->{target_language} = 'system-verilog'; },
        },
        {
            label => 'invalid debug level state',
            mutate => sub { $_[0]->{debug_level} = 5; },
        },
    ) {
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            strict_mode => 1,
        );
        $case->{mutate}->($pipeline);

        my $error = capture_exception(sub {
            $pipeline->generate_hdl_from_file($fixture->{fsm_path});
        });

        like(
            $error,
            $generation_receiver_instance_error,
            "$case->{label} receives the constructed-instance receiver diagnostic",
        );
        unlike(
            $error,
            qr/SourceGenerationOrchestrator|Source file:|after_parse_source|normalized_search_paths|Unsupported target language|Debug\.pm|Can't call method|Can't use .* as/s,
            "$case->{label} does not leak lower-level state fallout",
        );
    }
};

subtest 'invalid generation receiver instances preserve caller debug state' => sub {
    my $fixture = make_direct_source_fixture();
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator::generate_hdl_from_file(
            FSM::Pipeline::HDLGenerator::BoundaryAuditSubclass->hash_receiver(),
            $fixture->{fsm_path},
        );
    });

    like(
        $error,
        $generation_receiver_instance_error,
        'invalid receiver instance still reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'invalid receiver instance does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'invalid receiver instance does not mutate caller trace verbosity');

    restore_fsm_debug_state($INITIAL_DEBUG_STATE);
};

done_testing();

sub make_direct_source_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'facade_generation_receiver_instance_smoke.fsm');

    write_file(
        $fsm_path,
        <<'FSM',
(?fsm:facade_generation_receiver_instance_smoke
  (+system
    (clock clk)
    (sreset reset)
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
