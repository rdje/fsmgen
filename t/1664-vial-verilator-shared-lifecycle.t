#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::Runner;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Backend::VerilatorLifecycle;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1);
my ($execution_ir, $emission, $bridge_manifest, $backend_inputs) =
    canonical_route();
my $operation_id = $emission->{operation_id};
my $stage_rel = ".artifacts/tmp/vial/$operation_id";
my $stage_abs = repo_path($stage_rel);
my $symlink_target_rel = ".artifacts/test/vial-lifecycle-symlink-$$";
my $symlink_target_abs = repo_path($symlink_target_rel);
my $containment_rel = ".artifacts/test/vial-lifecycle-containment-$$.txt";
my $containment_abs = repo_path($containment_rel);
my $measurement_rel = '.artifacts/tmp/vial-scale/' . ('a' x 64)
    . '/validation/00/lifecycle';
my $measurement_abs = repo_path($measurement_rel);
my $measurement_owner_abs = repo_path(
    '.artifacts/tmp/vial-scale/' . ('a' x 64),
);

END {
    unlink $stage_abs if -l $stage_abs;
    remove_tree($stage_abs)
        if -d $stage_abs && !-l $stage_abs;
    remove_tree($symlink_target_abs)
        if -d $symlink_target_abs && !-l $symlink_target_abs;
    unlink $containment_abs if -f $containment_abs && !-l $containment_abs;
    remove_tree($measurement_owner_abs)
        if -d $measurement_owner_abs && !-l $measurement_owner_abs;
}

is_deeply(
    FSM::VIAL::Backend::VerilatorLifecycle->state_order,
    [qw(
        admitted prepared tool_verified compiled ran trace_validated
        result_produced assembled cleaned
    )],
    'shared lifecycle publishes the closed forward-only state order',
);

my $unsealed =
    FSM::VIAL::Backend::VerilatorLifecycle->execute_atomic({});
ok(!$unsealed->{ok}, 'unsealed lifecycle execution rejects');
is(
    $unsealed->{diagnostics}[0]{code},
    'VIAL_LIFECYCLE_INVOCATION_ERROR',
    'unsealed lifecycle execution has the exact diagnostic',
);

subtest 'Runner consumes the one shared lifecycle' => sub {
    my $called = 0;
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VerilatorLifecycle::execute_atomic = sub {
        $called++;
        return {
            ok => JSON::PP::false,
            status => 'error',
            operation_id => undef,
            lifecycle_identity => undef,
            handle => undef,
            assembled_result => undef,
            stage_evidence => [],
            diagnostics => [{
                code => 'VIAL_RUN_TOOL_ERROR',
                severity => 'error',
                message => 'sealed lifecycle sentinel',
                path => '/tool',
            }],
            cleanup => {
                staging_identity => undef,
                removed => JSON::PP::false,
                residue => [],
            },
        };
    };
    my $result = FSM::VIAL::Backend::Runner->run({});
    is($called, 1, 'Runner invokes the shared lifecycle exactly once');
    ok(!$result->{ok}, 'lifecycle rejection remains a Runner rejection');
    is(
        $result->{diagnostics}[0]{message},
        'sealed lifecycle sentinel',
        'Runner preserves the lifecycle diagnostic',
    );
    is_deeply($result->{artifacts}, [], 'Runner invents no failure artifact');
};

subtest 'Runner contains unexpected lifecycle exceptions' => sub {
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VerilatorLifecycle::execute_atomic = sub {
        die "private lifecycle failed at /Volumes/foreign/build.pm line 9.\n";
    };
    my $result = FSM::VIAL::Backend::Runner->run({});
    ok(!$result->{ok}, 'unexpected lifecycle exception remains a result');
    is(
        $result->{diagnostics}[0]{code}, 'VIAL_RUN_HOST_ERROR',
        'unexpected lifecycle exception uses the stable Runner code',
    );
    unlike(
        $result->{diagnostics}[0]{message}, qr{/Volumes|build[.]pm|line 9},
        'unexpected lifecycle exception leaks no host path or stack suffix',
    );
    is_deeply($result->{artifacts}, [], 'host exception publishes no artifact');
};

subtest 'Runner contains malformed private lifecycle projections' => sub {
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VerilatorLifecycle::execute_atomic = sub {
        return [];
    };
    my $result = eval { FSM::VIAL::Backend::Runner->run({}) };
    is($@, '', 'malformed lifecycle projection cannot escape Runner');
    ok(defined($result) && !$result->{ok}, 'malformed projection is a result');
    is(
        $result->{diagnostics}[0]{code}, 'VIAL_RUN_HOST_ERROR',
        'malformed projection uses the stable Runner code',
    );
    is_deeply(
        $result->{artifacts}, [],
        'malformed projection publishes no artifact',
    );
    ok(!$result->{cleanup}{removed}, 'malformed projection claims no cleanup');
};

subtest 'admission is closed, content-addressed, and abortable' => sub {
    my $begin = lifecycle_begin();
    ok($begin->{ok}, 'sealed Runner caller admits one canonical lifecycle');
    is($begin->{status}, 'admitted', 'first state is admitted');
    is($begin->{handle}{ordinal}, 0, 'admitted ordinal is zero');
    is(
        $begin->{handle}{next_state}, 'prepared',
        'admitted state names only its exact successor',
    );
    like(
        $begin->{handle}{state_identity},
        qr{\Astate/[0-9a-f]{64}\z},
        'admitted state has one content identity',
    );
    ok(
        -f repo_path($begin->{handle}{state_relpath})
            && !-l repo_path($begin->{handle}{state_relpath}),
        'admitted state is one regular repository-local file',
    );
    is(
        scalar(@{$begin->{stage_evidence}}), 1,
        'admission returns only one stage evidence record',
    );

    my $mutated = clone($begin);
    $mutated->{handle}{state} = 'prepared';
    is(
        $begin->{handle}{state}, 'admitted',
        'returned lifecycle values are defensive',
    );

    my $abort = lifecycle_abort($begin->{handle});
    ok($abort->{ok}, 'canonical admitted lifecycle aborts');
    is($abort->{status}, 'aborted_cleaned', 'abort is terminal and explicit');
    ok($abort->{cleanup}{removed}, 'abort reports exact removal');
    ok(!-e $stage_abs && !-l $stage_abs, 'abort leaves no lifecycle root');
};

subtest 'collision rejects without deleting the existing owner' => sub {
    my $first = lifecycle_begin();
    ok($first->{ok}, 'first owner admits');
    my $collision = lifecycle_begin();
    ok(!$collision->{ok}, 'second owner rejects on collision');
    is(
        $collision->{diagnostics}[0]{code}, 'VIAL_RUN_COLLISION',
        'collision has the stable Runner diagnostic',
    );
    ok(-d $stage_abs && !-l $stage_abs, 'collision preserves the first owner');
    my $abort = lifecycle_abort($first->{handle});
    ok($abort->{ok}, 'first owner can still clean its root');
    ok(!-e $stage_abs && !-l $stage_abs, 'collision cleanup is exact');
};

subtest 'post-creation admission failure cleans only its new root' => sub {
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VerilatorLifecycle::_write_content_object =
        sub { die "injected authority-object failure\n" };
    my $failed = lifecycle_begin();
    ok(!$failed->{ok}, 'injected authority-object failure rejects admission');
    is(
        $failed->{diagnostics}[0]{code}, 'VIAL_RUN_HOST_ERROR',
        'injected admission failure is one stable host diagnostic',
    );
    ok($failed->{cleanup}{removed}, 'newly owned root is cleaned');
    ok(
        !-e $stage_abs && !-l $stage_abs,
        'post-creation failure leaves no lifecycle residue',
    );
};

subtest 'measurement caller has one distinct sealed storage context' => sub {
    my $public_begin = lifecycle_begin();
    my $public_state = decode_raw(
        repo_path($public_begin->{handle}{state_relpath}),
    );
    ok(
        lifecycle_abort($public_begin->{handle})->{ok},
        'comparison public lifecycle cleans before measurement admission',
    );
    my $measurement_emission =
        FSM::VIAL::Backend::SVPortableVerilator->emit({
            execution_ir => $execution_ir,
            bridge_manifest => $bridge_manifest,
            backend_inputs => clone($backend_inputs),
            artifact_root => $measurement_rel,
            backend_profile => 'sv_portable_verilator',
        });
    ok($measurement_emission->{ok}, 'measurement-root emission is canonical');
    my $request = {
        repo_root => $repo_root,
        execution_ir => $execution_ir,
        emission => clone($measurement_emission),
        storage_context => {
            schema => 'fsmgen.vial_verilator_lifecycle_storage.v1',
            schema_version => 1,
            mode => 'architecture_scale_measurement',
            staging_identity => $measurement_rel,
            containment => 'outer_worker_process_group',
        },
    };
    my $begin =
        FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::_lifecycle_begin_for_test(
            $request,
        );
    diag($json->encode($begin->{diagnostics})) unless $begin->{ok};
    ok($begin->{ok}, 'sealed measurement caller admits its exact root');
    my $measurement_state = decode_raw(
        repo_path($begin->{handle}{state_relpath}),
    );
    isnt(
        $measurement_state->{authority}{compile_command_digest},
        $public_state->{authority}{compile_command_digest},
        'actual compile command identity reflects the distinct storage root',
    );
    is(
        $measurement_state->{authority}{compile_workspace_command_digest},
        $public_state->{authority}{compile_workspace_command_digest},
        'compile workspace-normalized identity is stable across callers',
    );
    is(
        $measurement_state->{authority}{run_workspace_command_digest},
        $public_state->{authority}{run_workspace_command_digest},
        'run workspace-normalized identity is stable across callers',
    );
    is(
        $begin->{handle}{storage_context}{containment},
        'outer_worker_process_group',
        'measurement lifecycle inherits the controller containment domain',
    );
    my $prepared =
        FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::_lifecycle_advance_for_test({
            %$request,
            handle => clone($begin->{handle}),
        });
    ok($prepared->{ok}, 'measurement lifecycle advances through preparation');
    my $abort =
        FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::_lifecycle_abort_for_test({
            %$request,
            handle => clone($prepared->{handle}),
        });
    ok($abort->{ok}, 'measurement caller cleans its exact lifecycle root');
    ok(
        !-e $measurement_abs && !-l $measurement_abs,
        'measurement lifecycle leaves no controller-owned residue',
    );
};

subtest 'prepared transition rejects replay and cleans the owned chain' => sub {
    my $begin = lifecycle_begin();
    my $admitted_handle = clone($begin->{handle});
    my $prepared = lifecycle_advance($admitted_handle);
    ok($prepared->{ok}, 'admitted state advances to prepared');
    is($prepared->{status}, 'prepared', 'prepared state is exact');
    is(
        scalar(@{$prepared->{stage_evidence}}), 2,
        'prepared state independently reloads the complete chain',
    );
    my $replay = lifecycle_advance($admitted_handle);
    diag($json->pretty->encode($replay))
        unless $replay->{cleanup}{removed};
    ok(!$replay->{ok}, 'stale admitted handle cannot replay');
    is(
        $replay->{diagnostics}[0]{code},
        'VIAL_LIFECYCLE_STATE_ERROR',
        'replay fails as lifecycle state error',
    );
    ok($replay->{cleanup}{removed}, 'replay failure cleans proven-owned state');
    ok(!-e $stage_abs && !-l $stage_abs, 'replay leaves zero residue');
};

subtest 'skipped successor rejects without claiming the active owner' => sub {
    my $begin = lifecycle_begin();
    my $skipped = clone($begin->{handle});
    $skipped->{next_state} = 'compiled';
    my $rejected = lifecycle_advance($skipped);
    ok(!$rejected->{ok}, 'mutated successor rejects');
    is(
        $rejected->{diagnostics}[0]{code},
        'VIAL_LIFECYCLE_STATE_ERROR',
        'skipped successor has the exact state diagnostic',
    );
    ok(
        -d $stage_abs && !-l $stage_abs,
        'unproved mutated handle cannot delete the active owner',
    );
    ok(lifecycle_abort($begin->{handle})->{ok}, 'valid owner still aborts');
};

subtest 'state, object, partial-state, and symlink mutations fail closed' => sub {
    my $begin = lifecycle_begin();
    my $state_path = repo_path($begin->{handle}{state_relpath});
    append_raw($state_path, ' ');
    my $state_rejected = lifecycle_advance($begin->{handle});
    ok(!$state_rejected->{ok}, 'mutated state bytes reject');
    is(
        $state_rejected->{diagnostics}[0]{code},
        'VIAL_LIFECYCLE_STATE_ERROR',
        'state mutation has the exact diagnostic',
    );
    ok(!-e $stage_abs && !-l $stage_abs, 'state mutation cleans exactly');

    $begin = lifecycle_begin();
    my $state = decode_raw(repo_path($begin->{handle}{state_relpath}));
    my ($emission_object) = grep {
        $_->{kind} eq 'authority_emission'
    } @{$state->{objects}};
    append_raw(repo_path($emission_object->{relative_path}), 'x');
    my $object_rejected = lifecycle_advance($begin->{handle});
    ok(!$object_rejected->{ok}, 'mutated authority object rejects');
    is(
        $object_rejected->{diagnostics}[0]{code},
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'object mutation has the exact diagnostic',
    );
    ok(!-e $stage_abs && !-l $stage_abs, 'object mutation cleans exactly');

    $begin = lifecycle_begin();
    my $partial = repo_path("$stage_rel/states/partial.json");
    write_raw($partial, "{}\n");
    my $partial_rejected = lifecycle_advance($begin->{handle});
    ok(!$partial_rejected->{ok}, 'extra partial state rejects');
    is(
        $partial_rejected->{diagnostics}[0]{code},
        'VIAL_LIFECYCLE_STATE_ERROR',
        'partial state has the exact diagnostic',
    );
    ok(!-e $stage_abs && !-l $stage_abs, 'partial state cleans exactly');

    $begin = lifecycle_begin();
    my $prepared = lifecycle_advance($begin->{handle});
    my ($compile_artifact) = grep {
        $_->{relpath} eq
            'backends/sv_portable_verilator/commands/compile-command.json'
    } @{$emission->{artifacts}};
    my $compile = $json->decode($compile_artifact->{content});
    append_raw(repo_path($compile->{inputs}[0]), ' ');
    my $input_rejected = lifecycle_advance($prepared->{handle});
    ok(!$input_rejected->{ok}, 'mutated prepared input rejects on resume');
    is(
        $input_rejected->{diagnostics}[0]{code},
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'prepared-input mutation has the exact object diagnostic',
    );
    ok(
        !-e $stage_abs && !-l $stage_abs,
        'prepared-input mutation cleans exactly',
    );

    make_path($symlink_target_abs);
    make_path(dirname($stage_abs));
    symlink($symlink_target_abs, $stage_abs)
        or die "cannot create lifecycle symlink probe: $!";
    my $symlink_rejected = lifecycle_begin();
    ok(!$symlink_rejected->{ok}, 'symlink staging root rejects');
    is(
        $symlink_rejected->{diagnostics}[0]{code},
        'VIAL_RUN_PATH_ERROR',
        'symlink root has the exact path diagnostic',
    );
    ok(-l $stage_abs, 'rejected symlink remains caller-owned');
    unlink($stage_abs) or die "cannot remove lifecycle symlink probe: $!";
    remove_tree($symlink_target_abs);
};

subtest 'process capture distinguishes handoff, output, and contained timeout' => sub {
    my $session = {
        repo_root => $repo_root,
        storage_context => {containment => 'lifecycle_process_group'},
    };
    my $success =
        FSM::VIAL::Backend::VerilatorLifecycle::_capture_process(
            $session,
            [$^X, '-e', '$|=1; print "capture-ready\\n"'],
            5, 4_096,
        );
    ok($success->{ok}, 'controlled child executes successfully');
    is($success->{output}, "capture-ready\n", 'combined capture is exact');
    ok(
        $success->{started_monotonic_ns}
            <= $success->{exec_handoff_monotonic_ns}
            && $success->{exec_handoff_monotonic_ns}
                <= $success->{first_output_monotonic_ns}
            && $success->{first_output_monotonic_ns}
                <= $success->{finished_monotonic_ns},
        'monotonic evidence separates spawn, exec, first output, and exit',
    );
    is(
        $success->{execution_ns},
        $success->{finished_monotonic_ns}
            - $success->{exec_handoff_monotonic_ns},
        'execution duration is independently recomputable',
    );

    my $missing =
        FSM::VIAL::Backend::VerilatorLifecycle::_capture_process(
            $session, ['./fsmgen-lifecycle-definitely-absent'], 5, 4_096,
        );
    ok(!$missing->{ok}, 'failed exec is not reported as child execution');
    ok($missing->{exec_failed}, 'failed exec has an explicit handoff flag');
    like(
        $missing->{exec_error}, qr/exec failed:/,
        'failed exec retains a bounded handoff diagnostic',
    );
    ok(
        !defined($missing->{first_output_monotonic_ns}),
        'failed exec invents no generated-process output time',
    );

    my $limited =
        FSM::VIAL::Backend::VerilatorLifecycle::_capture_process(
            $session,
            [$^X, '-e', '$|=1; print "x" x 8192'],
            5, 1_024,
        );
    ok(!$limited->{ok}, 'capture overflow is not successful execution');
    ok($limited->{output_limited}, 'capture overflow is explicit');
    ok(
        $limited->{output_bytes} > $limited->{capture_limit_bytes},
        'capture overflow preserves the observed bounded-crossing evidence',
    );

    my $signalled =
        FSM::VIAL::Backend::VerilatorLifecycle::_capture_process(
            $session, [$^X, '-e', 'kill 15, $$'], 5, 4_096,
        );
    ok(!$signalled->{ok}, 'signalled child is not successful execution');
    is($signalled->{signal}, 15, 'child signal is exact');
    is($signalled->{exit_code}, 143, 'signal-derived exit code is exact');

    my $silent_hang =
        FSM::VIAL::Backend::VerilatorLifecycle::_capture_process(
            $session,
            [$^X, '-e', 'close STDOUT; close STDERR; sleep 10'],
            1, 4_096,
        );
    ok(
        $silent_hang->{timed_out},
        'deadline remains active after every output pipe closes',
    );
    ok(
        !defined($silent_hang->{first_output_monotonic_ns}),
        'silent timeout invents no output observation',
    );

    make_path(dirname($containment_abs));
    my $containment_program = <<'PERL';
use strict;
use warnings;
use Fcntl qw(O_APPEND O_CREAT O_WRONLY);
my $sentinel = shift @ARGV;
my $append = sub {
    my ($text) = @_;
    sysopen(my $fh, $sentinel, O_WRONLY | O_CREAT | O_APPEND, 0600)
        or die "cannot open containment sentinel: $!";
    print {$fh} $text or die "cannot write containment sentinel: $!";
    close $fh or die "cannot close containment sentinel: $!";
};
my $child = fork();
die "cannot fork containment descendant: $!" unless defined $child;
if ($child == 0) {
    $SIG{TERM} = sub { $append->("descendant-term\n"); exit 0 };
    $append->("descendant-ready\n");
    sleep 10;
    exit 0;
}
$SIG{TERM} = sub { $append->("parent-term\n"); exit 0 };
$append->("parent-ready\n");
sleep 10;
PERL
    my $timed_out =
        FSM::VIAL::Backend::VerilatorLifecycle::_capture_process(
            $session, [$^X, '-e', $containment_program, $containment_rel],
            1, 4_096,
        );
    ok($timed_out->{timed_out}, 'bounded capture reaches its exact timeout');
    is(
        $timed_out->{containment}, 'lifecycle_process_group',
        'timeout evidence names lifecycle process-group containment',
    );
    my $sentinel = slurp_raw($containment_abs);
    like($sentinel, qr/^parent-ready$/m, 'worker entered the process group');
    like(
        $sentinel, qr/^descendant-ready$/m,
        'worker descendant entered the inherited process group',
    );
    like($sentinel, qr/^parent-term$/m, 'timeout terminates the worker');
    like(
        $sentinel, qr/^descendant-term$/m,
        'timeout terminates the inherited descendant',
    );
    unlink($containment_abs)
        or die "cannot remove containment sentinel: $!";
};

subtest 'exact tool traverses every sealed state and cleans atomically' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_LIFECYCLE_EXACT=1 for the real staged-tool proof'
        unless $ENV{FSMGEN_VIAL_LIFECYCLE_EXACT};
    my ($version_status, $version_output) = capture_command(
        'verilator', '--version',
    );
    plan skip_all => 'exact qualified Verilator 5.046 build is not installed'
        unless $version_status == 0
            && $version_output
                eq "Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228\n";

    my @states = @{
        FSM::VIAL::Backend::VerilatorLifecycle->state_order
    };
    my $current = lifecycle_begin();
    ok($current->{ok}, 'real lifecycle admits');
    for my $ordinal (1 .. $#states - 1) {
        $current = lifecycle_advance($current->{handle});
        ok($current->{ok}, "real lifecycle advances to $states[$ordinal]");
        unless ($current->{ok}) {
            diag($json->pretty->encode({
                diagnostics => $current->{diagnostics},
                stage_evidence => $current->{stage_evidence},
                cleanup => $current->{cleanup},
            }));
            return;
        }
        is($current->{status}, $states[$ordinal], 'state name is exact');
        is($current->{handle}{ordinal}, $ordinal, 'state ordinal is exact');
        is_deeply(
            [map { $_->{state} } @{$current->{stage_evidence}}],
            [@states[0 .. $ordinal]],
            'independently reconstructed predecessor chain is complete',
        );
        if ($states[$ordinal] =~ /\A(?:tool_verified|compiled|ran)\z/) {
            my $capture = $current->{stage_evidence}[-1]{evidence}{capture};
            ok($capture->{ok}, 'external phase capture succeeded');
            is(
                $capture->{containment}, 'lifecycle_process_group',
                'external phase remains in the lifecycle process group',
            );
            ok(
                defined($capture->{spawn_to_exec_ns})
                    && defined($capture->{execution_ns}),
                'external phase preserves separated handoff timing',
            );
        }
    }
    my $finished = lifecycle_finish($current->{handle});
    ok($finished->{ok}, 'assembled lifecycle finishes successfully');
    is($finished->{status}, 'cleaned', 'terminal state is cleaned');
    ok($finished->{cleanup}{removed}, 'terminal cleanup is explicit');
    ok(!-e $stage_abs && !-l $stage_abs, 'terminal cleanup leaves no root');
    is(
        scalar(@{$finished->{assembled_result}{artifacts}}), 12,
        'terminal projection preserves the Runner-owned artifact graph',
    );
};

done_testing();

sub lifecycle_begin {
    return FSM::VIAL::Backend::Runner::_lifecycle_begin_for_test(
        lifecycle_request(),
    );
}

sub lifecycle_advance {
    my ($handle) = @_;
    return FSM::VIAL::Backend::Runner::_lifecycle_advance_for_test({
        %{lifecycle_request()},
        handle => clone($handle),
    });
}

sub lifecycle_abort {
    my ($handle) = @_;
    return FSM::VIAL::Backend::Runner::_lifecycle_abort_for_test({
        %{lifecycle_request()},
        handle => clone($handle),
    });
}

sub lifecycle_finish {
    my ($handle) = @_;
    return FSM::VIAL::Backend::Runner::_lifecycle_finish_for_test({
        %{lifecycle_request()},
        handle => clone($handle),
    });
}

sub lifecycle_request {
    return {
        repo_root => $repo_root,
        execution_ir => $execution_ir,
        emission => clone($emission),
        storage_context => {
            schema => 'fsmgen.vial_verilator_lifecycle_storage.v1',
            schema_version => 1,
            mode => 'public_runner',
            staging_identity => $stage_rel,
            containment => 'lifecycle_process_group',
        },
    };
}

sub canonical_route {
    my $vial_path = 'vial/ahb_subordinate_base_output_arbitration.vial';
    my $hial_path = 'ppif/ahb_lite_subordinate.ppif';
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path($vial_path)),
        source_name => $vial_path,
        source_catalog => {},
    });
    my $built = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => source_envelope(
            $hial_path, slurp_raw(repo_path($hial_path)), 'ppif',
        ),
        fixture_id => 'base_output_arbitration',
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    die 'canonical lifecycle qualification plan failed'
        unless $built->{ok};
    my $emission = FSM::VIAL::Backend::SVPortableVerilator->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => ".artifacts/test/vial-lifecycle-contract-$$",
        backend_profile => 'sv_portable_verilator',
    });
    die 'canonical lifecycle qualification emission failed'
        unless $emission->{ok};
    return (
        $built->{execution_ir}, $emission,
        $built->{bridge_manifest}, $built->{backend_inputs},
    );
}

sub source_envelope {
    my ($relative, $text, $kind) = @_;
    return {
        source_id => $relative,
        source_kind_hint => $kind,
        text => $text,
        encoding => 'utf-8',
        origin => 'repository',
        display_name => $relative,
        canonical_id => undef,
        relative_path => $relative,
        metadata => {},
    };
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $content;
}

sub decode_raw {
    my ($path) = @_;
    return JSON::PP->new->decode(slurp_raw($path));
}

sub write_raw {
    my ($path, $content) = @_;
    make_path(dirname($path));
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $content or die "cannot write content to $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub append_raw {
    my ($path, $content) = @_;
    open my $fh, '>>:raw', $path or die "cannot append $path: $!";
    print {$fh} $content or die "cannot append content to $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub capture_command {
    my (@command) = @_;
    my $stderr = gensym;
    my $stdout;
    my $pid = eval { open3(undef, $stdout, $stderr, @command) };
    return (127, '') unless defined $pid;
    my $output = do { local $/; <$stdout> // '' };
    $output .= do { local $/; <$stderr> // '' };
    waitpid($pid, 0);
    return ($? & 127 ? 128 + ($? & 127) : $? >> 8, $output);
}

sub clone {
    my ($value) = @_;
    return JSON::PP->new->decode($json->encode($value));
}

package FSM::VIAL::Backend::Runner;

sub _lifecycle_begin_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->begin_session($raw);
}

sub _lifecycle_advance_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->advance_session($raw);
}

sub _lifecycle_abort_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->abort_session($raw);
}

sub _lifecycle_finish_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->finish_session($raw);
}

package main;

package FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement;

sub _lifecycle_begin_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->begin_session($raw);
}

sub _lifecycle_advance_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->advance_session($raw);
}

sub _lifecycle_abort_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->abort_session($raw);
}

package main;
