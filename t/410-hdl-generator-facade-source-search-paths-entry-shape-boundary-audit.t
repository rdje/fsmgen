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
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

my $source_search_paths_shape = 'array reference of scalar non-empty filesystem search roots';
my $source_search_paths_entry_error = qr/FSM::Pipeline::HDLGenerator expects 'source_search_paths' entries to be scalar non-empty filesystem search roots/s;

subtest 'manifests advertise source_search_paths entry shape' => sub {
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
            $facade->{constructor_option_shape_map}{source_search_paths},
            $source_search_paths_shape,
            "$label advertises source_search_paths as an array of scalar non-empty filesystem roots",
        );
        ok(
            contains_value($facade->{public_constructor_option_names}, 'source_search_paths'),
            "$label keeps source_search_paths in the public constructor option family",
        );
        ok(
            contains_value(
                $facade->{constructor_option_family_map}{core_constructor_option_names},
                'source_search_paths',
            ),
            "$label groups source_search_paths with core constructor options",
        );
    }
};

subtest 'HDLGenerator accepts scalar non-empty source_search_paths entries' => sub {
    my $fixture = make_source_search_path_fixture();
    my $pipeline = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            strict_mode => 1,
            quiet => 1,
            source_search_paths => [
                $fixture->{lib_a},
                File::Spec->catdir($fixture->{tempdir}, 'directory with spaces'),
            ],
        );
    };
    my $error = $@;

    ok($pipeline, 'constructor accepts scalar non-empty source_search_paths entries')
        or diag($error);
    is_deeply(
        $pipeline->{source_path_resolver}->extra_search_paths(),
        [
            $fixture->{lib_a},
            File::Spec->catdir($fixture->{tempdir}, 'directory with spaces'),
        ],
        'accepted search roots are forwarded to the source path resolver unchanged',
    ) if $pipeline;
};

subtest 'HDLGenerator rejects malformed source_search_paths entries at the facade boundary' => sub {
    for my $case (
        {
            label => 'undef entry',
            value => [undef],
        },
        {
            label => 'empty-string entry',
            value => [''],
        },
        {
            label => 'whitespace-only entry',
            value => ['  '],
        },
        {
            label => 'arrayref entry',
            value => [['t/corpus']],
        },
        {
            label => 'hashref entry',
            value => [{ root => 't/corpus' }],
        },
        {
            label => 'mixed valid and invalid entries',
            value => ['t/corpus', { root => 't/corpus' }],
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                quiet => 1,
                source_search_paths => $case->{value},
            );
        });

        like(
            $error,
            $source_search_paths_entry_error,
            "$case->{label} receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/SourcePathResolver|Can't use .* as/s,
            "$case->{label} does not leak path-resolver or raw Perl diagnostics",
        );
    }
};

subtest 'invalid source_search_paths entries preserve caller debug state' => sub {
    set_fsm_trace_verbosity('low');

    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            source_search_paths => [{ root => 'not-a-scalar-root' }],
        );
    });

    like(
        $error,
        $source_search_paths_entry_error,
        'invalid source_search_paths entry still reports the facade diagnostic',
    );
    is(get_fsm_debug_level(), 1, 'invalid source_search_paths entry does not mutate caller debug level');
    is(get_fsm_trace_verbosity(), 'low', 'invalid source_search_paths entry does not mutate caller trace verbosity');

    restore_fsm_debug_state($INITIAL_DEBUG_STATE);
};

done_testing();

sub make_source_search_path_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $lib_a = File::Spec->catdir($tempdir, 'pkg_lib_a');
    mkdir $lib_a or die "Cannot create $lib_a: $!";

    return {
        tempdir => $tempdir,
        lib_a => $lib_a,
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
