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
    clear_fsm_trace_output_file
    get_fsm_debug_level
    get_fsm_trace_output_file
    get_fsm_trace_verbosity
    restore_fsm_debug_state
    set_fsm_trace_emojis
    set_fsm_trace_output_file
    set_fsm_trace_verbosity
    trace_emojis_enabled
);
use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_method_names
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $INITIAL_DEBUG_STATE = capture_fsm_debug_state();
END {
    restore_fsm_debug_state($INITIAL_DEBUG_STATE)
        if $INITIAL_DEBUG_STATE;
}

subtest 'facade manifests advertise stateful reuse without widening object injection' => sub {
    my @views = (
        {
            label => 'direct facade contract',
            contract => build_hdl_generator_facade_contract(),
        },
        {
            label => 'in-process capability manifest facade contract',
            contract => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI capability manifest facade contract',
            contract => run_capability_manifest('--capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI alias capability manifest facade contract',
            contract => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
    );

    for my $view (@views) {
        my $contract = $view->{contract};
        my $label = $view->{label};

        ok($contract->{stateful_reuse_supported}, "$label advertises stateful facade reuse");
        is_deeply(
            sorted($contract->{method_names}),
            sorted(hdl_generator_facade_method_names()),
            "$label method family matches the builder-owned facade methods",
        );
        is(
            $contract->{generation_argument_shape},
            'filesystem path to a .fsm source root',
            "$label keeps the filesystem-path generation argument boundary",
        );
        ok(
            !$contract->{object_injection_args_public},
            "$label does not make owner-injection constructor args public",
        );
        ok(
            !$contract->{result_surface_json_safe_as_a_whole},
            "$label does not claim the raw result surface is JSON-safe as a whole",
        );
    }
};

subtest 'one facade object preserves constructor state across success failure and reuse' => sub {
    my $fixture = make_stateful_reuse_fixture();
    my $trace_path = File::Spec->catfile($fixture->{tempdir}, 'stateful-reuse.trace');

    set_baseline_debug_state($trace_path);

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 2,
        target_language => 'verilog',
        quiet => 1,
        strict_mode => 1,
        source_search_paths => [$fixture->{libdir}],
    );
    isa_ok($pipeline, 'FSM::Pipeline::HDLGenerator', 'constructor returns a reusable facade object');
    assert_baseline_debug_state($trace_path, 'constructor restores caller debug state');

    my $first_result = $pipeline->generate_hdl_from_file($fixture->{first_root});
    assert_baseline_debug_state($trace_path, 'first generation restores caller debug state');
    assert_reuse_result(
        $first_result,
        'facade_reuse_first',
        "8'hA5",
        'first generation reuses target language and source search paths',
    );

    my $strict_error = capture_exception(sub {
        $pipeline->generate_hdl_from_file(repo_file('t/corpus/legacy_infix_assignment.fsm'));
    });
    like(
        $strict_error,
        qr/Strict mode rejects infix assignment '\(OUT = SRC\)'/s,
        'same facade object keeps strict_mode for a later failing generation',
    );
    like(
        $strict_error,
        qr/Use the canonical pair form '\(= \(OUT SRC\)\)'/s,
        'strict reuse failure keeps the canonical pair-form hint',
    );
    assert_baseline_debug_state($trace_path, 'failing generation restores caller debug state');

    my $second_result = $pipeline->generate_hdl_from_file($fixture->{second_root});
    assert_baseline_debug_state($trace_path, 'second generation restores caller debug state');
    assert_reuse_result(
        $second_result,
        'facade_reuse_second',
        "8'h3C",
        'same facade object remains reusable after a strict-mode failure',
    );

    clear_fsm_trace_output_file();
    set_fsm_trace_verbosity('none');
    set_fsm_trace_emojis(1);
};

done_testing();

sub make_stateful_reuse_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_name = 'facade_stateful_reuse_pkg';
    my $package_path = File::Spec->catfile($libdir, "$package_name.fsm");
    my $first_root = File::Spec->catfile($tempdir, 'facade_reuse_first.fsm');
    my $second_root = File::Spec->catfile($tempdir, 'facade_reuse_second.fsm');

    write_file(
        $package_path,
        <<"FSM",
(?pkg:$package_name
  (+constants
    (FIRST_RESET 8'hA5)
    (SECOND_RESET 8'h3C)
  )
)
FSM
    );
    write_file(
        $first_root,
        direct_root_source(
            module_name => 'facade_reuse_first',
            package_name => $package_name,
            constant_name => 'FIRST_RESET',
        ),
    );
    write_file(
        $second_root,
        direct_root_source(
            module_name => 'facade_reuse_second',
            package_name => $package_name,
            constant_name => 'SECOND_RESET',
        ),
    );

    return {
        tempdir => $tempdir,
        libdir => $libdir,
        first_root => $first_root,
        second_root => $second_root,
    };
}

sub direct_root_source {
    my (%args) = @_;
    return <<"FSM";
(?fsm:$args{module_name}
  (+import $args{package_name})
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (OUT 8)
  )
  (idle
    (= (OUT $args{package_name}.$args{constant_name}))
  )
)
FSM
}

sub assert_reuse_result {
    my ($result, $module_name, $literal, $label) = @_;

    is($result->{module_info}{module_name}, $module_name, "$label: module name");
    is_deeply(
        $result->{source_info}{package_import_names},
        ['facade_stateful_reuse_pkg'],
        "$label: source_search_paths-backed package import stays visible",
    );
    like($result->{hdl_code}, qr/\Q$literal\E/s, "$label: imported package literal reaches HDL");
    like(
        $result->{hdl_code},
        qr/\balways\s*@\(posedge\s+clk\)\s+begin/s,
        "$label: reused facade keeps Verilog sequential block form",
    );
    unlike(
        $result->{hdl_code},
        qr/\balways_(?:ff|comb)\b/s,
        "$label: reused facade does not fall back to SystemVerilog always_* forms",
    );
}

sub set_baseline_debug_state {
    my ($trace_path) = @_;

    set_fsm_trace_verbosity('low');
    set_fsm_trace_emojis(0);
    set_fsm_trace_output_file($trace_path);
}

sub assert_baseline_debug_state {
    my ($trace_path, $label) = @_;

    is(get_fsm_debug_level(), 1, "$label: debug level");
    is(get_fsm_trace_verbosity(), 'low', "$label: trace verbosity");
    is(trace_emojis_enabled(), 0, "$label: trace emoji state");
    is(get_fsm_trace_output_file(), $trace_path, "$label: caller trace sink");
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
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
    return [sort @{$values || []}];
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
