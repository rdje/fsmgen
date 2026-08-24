package FSM::VIAL::Backend::VerilatorLifecycle;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd qw(abs_path getcwd);
use Digest::SHA qw(sha256_hex);
use Errno qw(EINTR);
use Fcntl qw(
    FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL
    O_CREAT O_EXCL O_NOFOLLOW O_NONBLOCK O_WRONLY
);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use IO::Select;
use JSON::PP ();
use POSIX qw(WNOHANG _exit setpgid);
use Scalar::Util qw(blessed);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep time);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::Backend::ResultProducer;
use FSM::VIAL::Backend::TraceValidator;

my $BASE = 'backends/sv_portable_verilator';
my $PREFIX = "FSMGEN_VIAL_TRACE_V1\t";
my $JSON = JSON::PP->new->canonical(1);
my $LIFECYCLE_SCHEMA = 'fsmgen.vial_verilator_lifecycle.v1';
my $STATE_SCHEMA = 'fsmgen.vial_verilator_lifecycle_state.v1';
my $HANDLE_SCHEMA = 'fsmgen.vial_verilator_lifecycle_handle.v1';
my $STORAGE_SCHEMA = 'fsmgen.vial_verilator_lifecycle_storage.v1';
my @STATE_ORDER = qw(
    admitted prepared tool_verified compiled ran trace_validated
    result_produced assembled cleaned
);
my %STATE_ORDINAL = map { $STATE_ORDER[$_] => $_ } 0 .. $#STATE_ORDER;
my @RESULT_KEYS = qw(
    ok status operation_id lifecycle_identity handle assembled_result
    stage_evidence diagnostics cleanup
);
my @HANDLE_KEYS = qw(
    schema schema_version lifecycle_identity operation_id state ordinal
    state_identity state_relpath next_state storage_context
);
my @STORAGE_KEYS = qw(
    schema schema_version mode staging_identity containment
);
my @MEASUREMENT_ASSEMBLY_KEYS = qw(
    schema schema_version result_production_payload_sha256
    artifact_count artifact_identity_sha256 result_rel
);
my @STATE_KEYS = qw(
    schema schema_version lifecycle_identity operation_id state ordinal
    state_identity predecessor_identity predecessor_relpath next_state
    storage_context authority objects evidence
);
my @AUTHORITY_KEYS = qw(
    plan_id execution_ir_sha256 emission_sha256
    compile_command_digest run_command_digest
    compile_workspace_command_digest run_workspace_command_digest
);
my @OBJECT_KEYS = qw(kind sha256 bytes executable relative_path);
my @CAPTURE_KEYS = qw(
    ok exit_code signal timed_out output_limited exec_failed exec_error
    started_monotonic_ns exec_handoff_monotonic_ns
    first_output_monotonic_ns finished_monotonic_ns spawn_to_exec_ns
    execution_ns exec_to_first_output_ns first_output_to_exit_ns containment
    timeout_seconds capture_limit_bytes output_bytes
);
my %STATE_EVIDENCE_KEYS = (
    admitted => [qw(
        plan_id backend_profile execution_ir_sha256 emission_sha256
        command_seals
    )],
    prepared => [qw(input_count object_directory command_digest)],
    tool_verified => [qw(version_sha256 capture)],
    compiled => [qw(
        command_digest executable_sha256 executable_bytes capture
    )],
    ran => [qw(
        command_digest runtime_output_sha256 runtime_output_bytes capture
    )],
    trace_validated => [qw(
        trace_sha256 record_count validation_object_sha256
    )],
    result_produced => [qw(
        result_id result_status result_payload_sha256
    )],
    assembled => [qw(
        assembly_payload_sha256 artifact_count_before_cleanup
    )],
);
my %STATE_OBJECT_KINDS = (
    admitted => [qw(authority_execution_ir authority_emission)],
    prepared => [qw(authority_execution_ir authority_emission)],
    tool_verified => [qw(
        authority_execution_ir authority_emission tool_version_output
    )],
    compiled => [qw(
        authority_execution_ir authority_emission tool_version_output
        compile_raw_output compiled_executable
    )],
    ran => [qw(
        authority_execution_ir authority_emission tool_version_output
        compile_raw_output compiled_executable runtime_raw_output
        runtime_process_evidence
    )],
    trace_validated => [qw(
        authority_execution_ir authority_emission tool_version_output
        compile_raw_output compiled_executable runtime_raw_output
        runtime_process_evidence validated_trace runtime_trace_jsonl
        runtime_ordinary_lines
    )],
    result_produced => [qw(
        authority_execution_ir authority_emission tool_version_output
        compile_raw_output compiled_executable runtime_raw_output
        runtime_process_evidence validated_trace runtime_trace_jsonl
        runtime_ordinary_lines result_production_payload
    )],
    assembled => [qw(
        authority_execution_ir authority_emission tool_version_output
        compile_raw_output compiled_executable runtime_raw_output
        runtime_process_evidence validated_trace runtime_trace_jsonl
        runtime_ordinary_lines result_production_payload assembly_payload
    )],
);
my %AUTHORIZED_CALLER = (
    'FSM::VIAL::Backend::Runner' => 'public_runner',
    'FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement' =>
        'architecture_scale_measurement',
);

sub state_order($class) {
    confess __PACKAGE__ . "->state_order requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@STATE_ORDER];
}

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub execute_atomic($class, @args) {
    my $role = _authorized_role($class, 'execute_atomic', scalar caller);
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'shared Verilator lifecycle execution is caller-sealed', '/', undef,
    ) unless defined $role && $role eq 'public_runner';
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'execute_atomic expects one closed argument hash', '/', undef,
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $session;
    my $finished = eval {
        _require_exact_keys(
            $args[0], [qw(repo_root execution_ir emission)],
            'atomic lifecycle invocation',
        );
        my $emission = $args[0]{emission};
        my $operation_id = ref($emission) eq 'HASH'
            ? $emission->{operation_id} : undef;
        my $storage = {
            schema => $STORAGE_SCHEMA,
            schema_version => 1,
            mode => 'public_runner',
            staging_identity => defined($operation_id)
                ? ".artifacts/tmp/vial/$operation_id" : undef,
            containment => 'lifecycle_process_group',
        };
        $session = _begin_session({
            %{$args[0]},
            storage_context => $storage,
        }, $role, \$session);
        for my $target (@STATE_ORDER[1 .. $#STATE_ORDER - 1]) {
            _advance_session($session, $target);
        }
        return _finish_session($session);
    };
    return $finished if defined $finished;
    return _exception_result($@, $session);
}

sub begin_session($class, @args) {
    my $role = _authorized_role($class, 'begin_session', scalar caller);
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'shared Verilator lifecycle transitions are caller-sealed', '/', undef,
    ) unless defined $role;
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'begin_session expects one closed argument hash', '/', undef,
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $session;
    my $ok = eval {
        $session = _begin_session($args[0], $role, \$session);
        1;
    };
    return _session_result($session) if $ok;
    return _exception_result($@, $session);
}

sub advance_session($class, @args) {
    my $role = _authorized_role($class, 'advance_session', scalar caller);
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'shared Verilator lifecycle transitions are caller-sealed', '/', undef,
    ) unless defined $role;
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'advance_session expects one closed argument hash', '/', undef,
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $session;
    my $ok = eval {
        _require_exact_keys(
            $args[0],
            [qw(repo_root execution_ir emission storage_context handle)],
            'lifecycle transition invocation',
        );
        $session = _resume_session($args[0], $role, \$session);
        my $target = $session->{handle}{next_state};
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'assembled lifecycle must be finished rather than advanced',
            '/handle/next_state',
        ) unless defined($target) && $target ne 'cleaned';
        _advance_session($session, $target);
        1;
    };
    return _session_result($session) if $ok;
    return _exception_result($@, $session);
}

sub finish_session($class, @args) {
    my $role = _authorized_role($class, 'finish_session', scalar caller);
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'shared Verilator lifecycle transitions are caller-sealed', '/', undef,
    ) unless defined $role;
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'finish_session expects one closed argument hash', '/', undef,
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $session;
    my $finished = eval {
        _require_exact_keys(
            $args[0],
            [qw(repo_root execution_ir emission storage_context handle)],
            'lifecycle finish invocation',
        );
        $session = _resume_session($args[0], $role, \$session);
        return _finish_session($session);
    };
    return $finished if defined $finished;
    return _exception_result($@, $session);
}

sub finish_measurement_session($class, @args) {
    my $role = _authorized_role(
        $class, 'finish_measurement_session', scalar caller,
    );
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'measurement lifecycle terminal transition is caller-sealed',
        '/', undef,
    ) unless defined $role && $role eq 'architecture_scale_measurement';
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'finish_measurement_session expects one closed argument hash',
        '/', undef,
    ) unless @args == 1 && ref($args[0]) eq 'HASH'
        && !blessed($args[0]);
    my $session;
    my $finished = eval {
        _require_exact_keys(
            $args[0],
            [qw(repo_root execution_ir emission storage_context handle)],
            'measurement lifecycle terminal invocation',
        );
        $session = _resume_session($args[0], $role, \$session);
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'measurement terminal transition requires result_produced',
            '/handle/state',
        ) unless $session->{handle}{state} eq 'result_produced'
            && ($session->{handle}{next_state} // '') eq 'assembled';
        _advance_session($session, 'assembled');
        return _finish_session($session);
    };
    return $finished if defined $finished;
    return _exception_result($@, $session);
}

sub abort_session($class, @args) {
    my $role = _authorized_role($class, 'abort_session', scalar caller);
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'shared Verilator lifecycle transitions are caller-sealed', '/', undef,
    ) unless defined $role;
    return _failure_result(
        'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'abort_session expects one closed argument hash', '/', undef,
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $session;
    my $aborted = eval {
        _require_exact_keys(
            $args[0],
            [qw(repo_root execution_ir emission storage_context handle)],
            'lifecycle abort invocation',
        );
        $session = _resume_session($args[0], $role, \$session);
        my $evidence = _stage_evidence($session);
        _remove_session_root($session);
        return _lifecycle_result({
            ok => JSON::PP::true,
            status => 'aborted_cleaned',
            operation_id => $session->{operation_id},
            lifecycle_identity => $session->{lifecycle_identity},
            handle => _cleaned_handle($session),
            assembled_result => undef,
            stage_evidence => $evidence,
            diagnostics => [],
            cleanup => {
                staging_identity => $session->{stage_rel},
                removed => JSON::PP::true,
                residue => [],
            },
        });
    };
    return $aborted if defined $aborted;
    return _exception_result($@, $session);
}

sub _authorized_role($class, $method, $caller) {
    return undef unless defined($class) && !ref($class)
        && $class eq __PACKAGE__;
    return $AUTHORIZED_CALLER{$caller};
}

sub _begin_session($raw, $role, $ownership_out) {
    _require_exact_keys(
        $raw, [qw(repo_root execution_ir emission storage_context)],
        'lifecycle admission',
    );
    my $session = _authority_context($raw, $role);
    _throw(
        'VIAL_RUN_COLLISION',
        "runtime staging root '$session->{stage_rel}' already exists",
        '/cleanup/staging_identity',
    ) if -e $session->{stage_abs} || -l $session->{stage_abs};
    _make_directory($session->{stage_abs}, $session->{stage_rel});
    $session->{stage_created} = 1;
    ${$ownership_out} = $session if defined $ownership_out;

    my $execution_ref = _write_content_object(
        $session, 'authority_execution_ir',
        _canonical_json($session->{execution_hash}), 0,
    );
    my $emission_ref = _write_content_object(
        $session, 'authority_emission',
        _canonical_json($session->{emission}), 0,
    );
    $session->{objects} = [$execution_ref, $emission_ref];
    _persist_state(
        $session, 'admitted', undef, {
            plan_id => $session->{emission}{plan_id},
            backend_profile => 'sv_portable_verilator',
            execution_ir_sha256 => $execution_ref->{sha256},
            emission_sha256 => $emission_ref->{sha256},
            command_seals => {
                compile => $session->{compile}{command_digest},
                run => $session->{run}{command_digest},
            },
        },
    );
    return $session;
}

sub _resume_session($raw, $role, $ownership_out) {
    my $session = _authority_context($raw, $role);
    _validate_handle($raw->{handle}, $session);
    $session->{handle} = _clone($raw->{handle});
    # Publish cleanup authority only after the closed handle proves that it
    # belongs to this reconstructed lifecycle.  Subsequent state/object
    # validation may fail, but those failures must still clean the exact
    # proven-owned root.  A malformed or foreign handle never reaches this
    # assignment and therefore cannot authorize removal.
    ${$ownership_out} = $session if defined $ownership_out;
    $session->{state} = _load_state_chain($session, $session->{handle});
    $session->{objects} = _clone($session->{state}{objects});
    _validate_authority_objects($session);
    return $session;
}

sub _authority_context($raw, $role) {
    _throw(
        'VIAL_RUN_INVOCATION_ERROR',
        'execution_ir must be an exact FSM::VIAL::ExecutionIR object',
        '/execution_ir',
    ) unless blessed($raw->{execution_ir})
        && ref($raw->{execution_ir}) eq 'FSM::VIAL::ExecutionIR';
    _throw(
        'VIAL_RUN_INVOCATION_ERROR',
        'emission must be one successful private backend result',
        '/emission',
    ) unless ref($raw->{emission}) eq 'HASH' && !blessed($raw->{emission})
        && $raw->{emission}{ok}
        && ($raw->{emission}{backend_profile} // '')
            eq 'sv_portable_verilator';
    _throw(
        'VIAL_RUN_INVOCATION_ERROR',
        'repo_root must be a scalar directory path', '/repo_root',
    ) unless defined($raw->{repo_root}) && !ref($raw->{repo_root});
    my $repo_root = abs_path($raw->{repo_root});
    _throw(
        'VIAL_RUN_PATH_ERROR',
        'repository root is not a readable directory', '/repo_root',
    ) unless defined($repo_root) && -d $repo_root;
    my @root_stat = stat($repo_root);
    _throw(
        'VIAL_RUN_PATH_ERROR',
        'repository filesystem identity is unavailable', '/repo_root',
    ) unless @root_stat;

    my $emission = _clone($raw->{emission});
    my $operation_id = $emission->{operation_id};
    _throw(
        'VIAL_RUN_INVOCATION_ERROR',
        'emission operation identity is invalid',
        '/emission/operation_id',
    ) unless defined($operation_id) && !ref($operation_id)
        && $operation_id =~ /\Aop-[0-9a-f]{64}\z/;
    my $execution_hash = $raw->{execution_ir}->as_hashref;
    _throw(
        'VIAL_RUN_INVOCATION_ERROR',
        'emission and ExecutionIR plan identities differ',
        '/emission/plan_id',
    ) unless ($emission->{plan_id} // '')
        eq ($execution_hash->{plan_id} // '');

    my $storage = _validated_storage_context(
        $raw->{storage_context}, $role, $operation_id,
    );
    my $stage_rel = $storage->{staging_identity};
    my $stage_abs = _safe_destination(
        $repo_root, $stage_rel, $root_stat[0],
    );
    my %artifact;
    for my $index (0 .. $#{$emission->{artifacts}}) {
        my $entry = $emission->{artifacts}[$index];
        _throw(
            'VIAL_RUN_INVOCATION_ERROR',
            'emission artifact must be one closed content record',
            '/emission/artifacts',
        ) unless ref($entry) eq 'HASH' && !blessed($entry)
            && defined($entry->{relpath}) && !ref($entry->{relpath})
            && defined($entry->{content}) && !ref($entry->{content});
        _throw(
            'VIAL_RUN_INVOCATION_ERROR',
            "emission artifact '$entry->{relpath}' is duplicated",
            '/emission/artifacts',
        ) if exists $artifact{$entry->{relpath}};
        $artifact{$entry->{relpath}} = _clone($entry);
    }
    my $compile = _decode_artifact(
        \%artifact, "$BASE/commands/compile-command.json",
    );
    my $run = _decode_artifact(
        \%artifact, "$BASE/commands/run-command.json",
    );
    my $selected_profile = _decode_artifact(
        \%artifact, "$BASE/evidence/tool-profile.json",
    );
    if ($storage->{mode} eq 'architecture_scale_measurement') {
        my $emitted_stage = ".artifacts/tmp/vial/$operation_id";
        $compile = _rebase_command(
            $compile, $emitted_stage, $stage_rel,
        );
        $run = _rebase_command($run, $emitted_stage, $stage_rel);
        $artifact{"$BASE/commands/compile-command.json"}{content} =
            _json_text($compile);
        $artifact{"$BASE/commands/run-command.json"}{content} =
            _json_text($run);
    }
    _validate_command_records(
        $compile, $run, $stage_rel, $emission->{generated_top},
    );
    _throw(
        'VIAL_LIFECYCLE_STORAGE_ERROR',
        'measurement runtime evidence must remain below its lifecycle root',
        '/storage_context/staging_identity',
    ) if $storage->{mode} eq 'architecture_scale_measurement'
        && $run->{expected_outputs}[0]
            ne "$stage_rel/$BASE/evidence/runtime-trace.jsonl";
    my $compile_workspace_digest =
        _workspace_command_digest($compile, $stage_rel);
    my $run_workspace_digest =
        _workspace_command_digest($run, $stage_rel);
    my $execution_sha = sha256_hex(_canonical_json($execution_hash));
    my $emission_sha = sha256_hex(_canonical_json($emission));
    my $lifecycle_identity = 'lifecycle/' . sha256_hex(_canonical_json({
        schema => $LIFECYCLE_SCHEMA,
        schema_version => 1,
        operation_id => $operation_id,
        plan_id => $emission->{plan_id},
        backend_profile => 'sv_portable_verilator',
        execution_ir_sha256 => $execution_sha,
        emission_sha256 => $emission_sha,
        compile_command_digest => $compile->{command_digest},
        run_command_digest => $run->{command_digest},
        compile_workspace_command_digest => $compile_workspace_digest,
        run_workspace_command_digest => $run_workspace_digest,
        storage_mode => $storage->{mode},
    }));

    return {
        repo_root => $repo_root,
        root_device => $root_stat[0],
        execution_ir => $raw->{execution_ir},
        execution_hash => $execution_hash,
        emission => $emission,
        artifact => \%artifact,
        compile => $compile,
        run => $run,
        compile_workspace_digest => $compile_workspace_digest,
        run_workspace_digest => $run_workspace_digest,
        selected_profile => $selected_profile,
        operation_id => $operation_id,
        lifecycle_identity => $lifecycle_identity,
        storage_context => $storage,
        stage_rel => $stage_rel,
        stage_abs => $stage_abs,
        stage_created => 0,
    };
}

sub _validated_storage_context($raw, $role, $operation_id) {
    _throw(
        'VIAL_LIFECYCLE_STORAGE_ERROR',
        'storage context must be one closed object',
        '/storage_context',
    ) unless ref($raw) eq 'HASH' && !blessed($raw);
    _closed_with_code(
        $raw, \@STORAGE_KEYS, 'VIAL_LIFECYCLE_STORAGE_ERROR',
        'lifecycle storage context', '/storage_context',
    );
    _throw(
        'VIAL_LIFECYCLE_STORAGE_ERROR',
        'storage context schema is not exact',
        '/storage_context/schema',
    ) unless ($raw->{schema} // '') eq $STORAGE_SCHEMA
        && ($raw->{schema_version} // 0) == 1;
    my ($mode, $containment) = $role eq 'public_runner'
        ? ('public_runner', 'lifecycle_process_group')
        : ('architecture_scale_measurement', 'outer_worker_process_group');
    _throw(
        'VIAL_LIFECYCLE_STORAGE_ERROR',
        'storage mode does not match the sealed caller',
        '/storage_context/mode',
    ) unless ($raw->{mode} // '') eq $mode;
    _throw(
        'VIAL_LIFECYCLE_STORAGE_ERROR',
        'process containment does not match the storage mode',
        '/storage_context/containment',
    ) unless ($raw->{containment} // '') eq $containment;
    my $identity = $raw->{staging_identity};
    if ($mode eq 'public_runner') {
        _throw(
            'VIAL_LIFECYCLE_STORAGE_ERROR',
            'public Runner staging identity changed',
            '/storage_context/staging_identity',
        ) unless defined($identity) && !ref($identity)
            && $identity eq ".artifacts/tmp/vial/$operation_id";
    }
    else {
        _throw(
            'VIAL_LIFECYCLE_STORAGE_ERROR',
            'measurement lifecycle must remain below one exact controller run',
            '/storage_context/staging_identity',
        ) unless defined($identity) && !ref($identity)
            && $identity =~ m{\A[.]artifacts/tmp/vial-scale/[0-9a-f]{64}/(?:validation/00|gate_measurement/0[1-3]|qualification_measurement/0[1-5])/lifecycle\z};
    }
    _rel_abs('.', $identity);
    return _clone($raw);
}

sub _advance_session($session, $target) {
    my $current = $session->{handle}{state};
    my $expected = $STATE_ORDER[$STATE_ORDINAL{$current} + 1];
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        "lifecycle transition '$current' to '$target' is not the exact successor",
        '/handle/next_state',
    ) unless defined($expected) && $expected eq $target
        && $target ne 'cleaned';
    _load_state_chain($session, $session->{handle});
    _restore_transient($session);
    my $phase = {
        prepared => \&_phase_prepare,
        tool_verified => \&_phase_tool_verify,
        compiled => \&_phase_compile,
        ran => \&_phase_run,
        trace_validated => \&_phase_trace_validate,
        result_produced => \&_phase_result_produce,
        assembled => \&_phase_assemble,
    }->{$target};
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        "lifecycle target '$target' has no implementation",
        '/handle/next_state',
    ) unless defined $phase;
    my $outcome = $phase->($session);
    push @{$session->{objects}}, @{$outcome->{objects}};
    _persist_state(
        $session, $target, $session->{state}, $outcome->{evidence},
    );
    delete $session->{pending_stage_evidence};
    return $session;
}

sub _phase_prepare($session) {
    _materialize_inputs($session);
    my $obj_rel = _command_mdir($session->{compile});
    _make_directory(
        _owned_abs($session, $obj_rel), $obj_rel,
    );
    return {
        objects => [],
        evidence => {
            input_count => scalar @{$session->{compile}{inputs}},
            object_directory => $obj_rel,
            command_digest => $session->{compile}{command_digest},
        },
    };
}

sub _phase_tool_verify($session) {
    my $capture = _capture_process(
        $session, ['verilator', '--version'], 10, 65_536,
    );
    $session->{pending_stage_evidence} = {
        state => 'tool_verified',
        ordinal => $STATE_ORDINAL{tool_verified},
        evidence => {capture => _capture_evidence($capture)},
    };
    _throw(
        'VIAL_RUN_TOOL_ERROR',
        'Verilator version query failed', '/tool_profile',
    ) unless _process_succeeded($capture);
    my $version = $capture->{output};
    $version =~ s/[\r\n]+\z//;
    _throw(
        'VIAL_RUN_TOOL_ERROR',
        'installed Verilator identity does not match the qualified 5.046 profile',
        '/tool_profile',
    ) unless $version
        eq $session->{selected_profile}{qualified_version_output};
    my $object = _write_content_object(
        $session, 'tool_version_output', $version, 0,
    );
    return {
        objects => [$object],
        evidence => {
            version_sha256 => $object->{sha256},
            capture => _capture_evidence($capture),
        },
    };
}

sub _phase_compile($session) {
    my $object_root = _owned_abs(
        $session, _command_mdir($session->{compile}),
    );
    my @preexisting = _tree_files_relative($object_root);
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'compile object directory is not empty before the sealed command',
        '/compile',
    ) if @preexisting;
    my $capture = _capture_process(
        $session,
        [
            $session->{compile}{logical_executable},
            @{$session->{compile}{arguments}},
        ],
        120, 8_388_608,
    );
    $session->{pending_stage_evidence} = {
        state => 'compiled',
        ordinal => $STATE_ORDINAL{compiled},
        evidence => {
            command_digest => $session->{compile}{command_digest},
            capture => _capture_evidence($capture),
        },
    };
    _throw(
        'VIAL_RUN_COMPILE_ERROR',
        'Verilator compile exceeded its timeout', '/compile',
    ) if $capture->{timed_out};
    _throw(
        'VIAL_RUN_LIMIT_EXCEEDED',
        'Verilator compile output exceeded 8 MiB', '/compile',
    ) if $capture->{output_limited};
    unless (_process_succeeded($capture)
            && index($capture->{output}, '%Error:') < 0) {
        _throw(
            'VIAL_RUN_COMPILE_ERROR',
            'Verilator compile failed: '
                . _process_error_summary($capture->{output}),
            '/compile',
        );
    }
    my $executable_rel = $session->{compile}{expected_outputs}[0];
    my $executable_abs = _owned_abs($session, $executable_rel);
    _throw(
        'VIAL_RUN_COMPILE_ERROR',
        'Verilator did not produce the exact expected executable',
        '/compile/expected_outputs',
    ) unless -f $executable_abs && !-l $executable_abs
        && -x $executable_abs;
    my $transcript = _write_content_object(
        $session, 'compile_raw_output', $capture->{output}, 0,
    );
    my $executable = _write_file_object(
        $session, 'compiled_executable', $executable_abs, 1,
    );
    return {
        objects => [$transcript, $executable],
        evidence => {
            command_digest => $session->{compile}{command_digest},
            executable_sha256 => $executable->{sha256},
            executable_bytes => $executable->{bytes},
            capture => _capture_evidence($capture),
        },
    };
}

sub _phase_run($session) {
    my $executable = _object_by_kind(
        $session->{objects}, 'compiled_executable',
    );
    _validate_object($session, $executable);
    my $expected_abs = _owned_abs(
        $session, $session->{compile}{expected_outputs}[0],
    );
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'compiled executable changed after its sealed state',
        '/objects/compiled_executable',
    ) unless _file_sha256($expected_abs) eq $executable->{sha256};
    my $capture = _capture_process(
        $session, [$session->{compile}{expected_outputs}[0]],
        30, 67_108_864,
    );
    $session->{pending_stage_evidence} = {
        state => 'ran',
        ordinal => $STATE_ORDINAL{ran},
        evidence => {
            command_digest => $session->{run}{command_digest},
            capture => _capture_evidence($capture),
        },
    };
    _throw(
        'VIAL_RUN_RUNTIME_ERROR',
        'generated VIAL runtime exceeded its timeout', '/run',
    ) if $capture->{timed_out};
    _throw(
        'VIAL_RUN_LIMIT_EXCEEDED',
        'generated VIAL runtime output exceeded 64 MiB', '/run',
    ) if $capture->{output_limited};
    _throw(
        'VIAL_RUN_RUNTIME_ERROR',
        'generated VIAL runtime exited nonzero', '/run',
    ) unless _process_succeeded($capture);
    my $output = _write_content_object(
        $session, 'runtime_raw_output', $capture->{output}, 0,
    );
    my $process = _write_content_object(
        $session, 'runtime_process_evidence',
        _canonical_json(_capture_evidence($capture)), 0,
    );
    return {
        objects => [$output, $process],
        evidence => {
            command_digest => $session->{run}{command_digest},
            runtime_output_sha256 => $output->{sha256},
            runtime_output_bytes => $output->{bytes},
            capture => _capture_evidence($capture),
        },
    };
}

sub _phase_trace_validate($session) {
    my $raw = _read_object_content(
        $session, _object_by_kind(
            $session->{objects}, 'runtime_raw_output',
        ),
    );
    my ($trace_text, $trace_jsonl, $ordinary) =
        _extract_trace($raw);
    my $process = _decode_object_json(
        $session, _object_by_kind(
            $session->{objects}, 'runtime_process_evidence',
        ),
    );
    my $trace = FSM::VIAL::Backend::TraceValidator->validate({
        execution_ir => $session->{execution_ir},
        trace_text => $trace_text,
        simulator_exit_code => $process->{exit_code},
    });
    _throw(
        'VIAL_RUN_TRACE_ERROR',
        $trace->{diagnostics}[0]{message}
            . ' at ' . $trace->{diagnostics}[0]{path},
        '/trace',
    ) unless $trace->{ok};
    my @objects = (
        _write_content_object(
            $session, 'validated_trace',
            _canonical_json($trace), 0,
        ),
        _write_content_object(
            $session, 'runtime_trace_jsonl', $trace_jsonl, 0,
        ),
        _write_content_object(
            $session, 'runtime_ordinary_lines',
            _canonical_json($ordinary), 0,
        ),
    );
    return {
        objects => \@objects,
        evidence => {
            trace_sha256 => $trace->{projection}{trace_sha256},
            record_count => $trace->{projection}{record_count},
            validation_object_sha256 => $objects[0]{sha256},
        },
    };
}

sub _phase_result_produce($session) {
    my $trace = _decode_object_json(
        $session, _object_by_kind(
            $session->{objects}, 'validated_trace',
        ),
    );
    my $ordinary = _decode_object_json(
        $session, _object_by_kind(
            $session->{objects}, 'runtime_ordinary_lines',
        ),
    );
    my $version = _read_object_content(
        $session, _object_by_kind(
            $session->{objects}, 'tool_version_output',
        ),
    );
    my $compile_transcript = _compile_transcript(
        $session->{compile}, $version,
    );
    my $run_transcript = _run_transcript(
        $session->{run}, $trace, $ordinary,
    );
    my $transcript_sha = sha256_hex(
        $compile_transcript . "\0" . $run_transcript,
    );
    my $compile_id = 'compile/' . sha256_hex(
        $session->{compile}{command_digest} . "\0" . $version,
    );
    my $simulation_id = 'simulation/' . sha256_hex(
        $session->{run}{command_digest}
            . "\0" . $trace->{projection}{trace_sha256},
    );
    my $backend_manifest_id = 'backend-manifest/' . sha256_hex(
        $session->{emission}{plan_id}
            . "\0sv_portable_verilator\0" . $version,
    );
    my @generated_sha = sort map {
        sha256_hex($_->{content})
    } grep {
        $_->{kind} eq 'systemverilog_source'
    } values %{$session->{artifact}};
    my $tool_profile = {
        %{$session->{selected_profile}},
        selection_status => 'executed_qualified',
        execution_evidence => JSON::PP::true,
    };
    my $result = FSM::VIAL::Backend::ResultProducer->produce({
        execution_ir => $session->{execution_ir},
        trace_validation => $trace,
        negotiation => $session->{emission}{negotiation},
        tool_profile => $tool_profile,
        backend_manifest_id => $backend_manifest_id,
        compile_id => $compile_id,
        simulation_id => $simulation_id,
        generated_artifact_sha256s => \@generated_sha,
        transcript_sha256 => $transcript_sha,
    });
    _throw(
        'VIAL_RUN_RESULT_ERROR',
        $result->{diagnostics}[0]{message}, '/result',
    ) unless $result->{ok};
    my $payload = {
        trace => $trace,
        tool_profile => $tool_profile,
        compile_transcript => $compile_transcript,
        run_transcript => $run_transcript,
        trace_jsonl => _read_object_content(
            $session, _object_by_kind(
                $session->{objects}, 'runtime_trace_jsonl',
            ),
        ),
        result => $result,
        backend_manifest_id => $backend_manifest_id,
        compile_id => $compile_id,
        simulation_id => $simulation_id,
    };
    my $object = _write_content_object(
        $session, 'result_production_payload',
        _canonical_json($payload), 0,
    );
    return {
        objects => [$object],
        evidence => {
            result_id => $result->{manifest}{result_id},
            result_status => $result->{status},
            result_payload_sha256 => $object->{sha256},
        },
    };
}

sub _phase_assemble($session) {
    my $payload = _decode_object_json(
        $session, _object_by_kind(
            $session->{objects}, 'result_production_payload',
        ),
    );
    my $assembly = _build_assembly($session, $payload);
    $session->{terminal_assembly} = $assembly;
    my $stored = $session->{storage_context}{mode}
            eq 'architecture_scale_measurement'
        ? _measurement_assembly_descriptor($session, $assembly)
        : $assembly;
    my $object = _write_content_object(
        $session, 'assembly_payload',
        _canonical_json($stored), 0,
    );
    return {
        objects => [$object],
        evidence => {
            assembly_payload_sha256 => $object->{sha256},
            artifact_count_before_cleanup =>
                scalar keys %{$assembly->{artifact}},
        },
    };
}

sub _build_assembly($session, $payload) {
    my %artifact = map {
        $_ => _clone($session->{artifact}{$_})
    } keys %{$session->{artifact}};
    $artifact{"$BASE/evidence/tool-profile.json"}{content} =
        _json_text($payload->{tool_profile});
    $artifact{"$BASE/evidence/compile-transcript.txt"} = _artifact(
        "$BASE/evidence/compile-transcript.txt",
        'compile_transcript', 'text',
        'normalized_compile_transcript',
        $payload->{compile_transcript},
        [$payload->{compile_id}],
    );
    $artifact{"$BASE/evidence/run-transcript.txt"} = _artifact(
        "$BASE/evidence/run-transcript.txt",
        'run_transcript', 'text',
        'normalized_run_transcript',
        $payload->{run_transcript},
        [$payload->{simulation_id}],
    );
    $artifact{"$BASE/evidence/runtime-trace.jsonl"} = _artifact(
        "$BASE/evidence/runtime-trace.jsonl",
        'runtime_trace', 'jsonl', 'validated_runtime_trace',
        $payload->{trace_jsonl},
        [$payload->{simulation_id}],
    );
    my ($result_digest) =
        $payload->{result}{manifest}{result_id}
            =~ m{\Aresult/([0-9a-f]{64})\z};
    _throw(
        'VIAL_RUN_RESULT_ERROR',
        'normalized result identity is invalid',
        '/result/result_id',
    ) unless defined $result_digest;
    my $result_rel =
        "results/$result_digest/verification-result-manifest.json";
    $artifact{$result_rel} = _artifact(
        $result_rel, 'result_manifest', 'json',
        'verification_result_manifest',
        $payload->{result}{content},
        [$session->{emission}{plan_id}, $payload->{simulation_id}],
    );
    return {
        artifact => \%artifact,
        result => $payload->{result},
        result_rel => $result_rel,
        tool_profile => $payload->{tool_profile},
        backend_manifest_id => $payload->{backend_manifest_id},
        compile_id => $payload->{compile_id},
        simulation_id => $payload->{simulation_id},
    };
}

sub _measurement_assembly_descriptor(
    $session, $assembly, $objects = undef,
) {
    my $payload = _object_by_kind(
        $objects // $session->{objects}, 'result_production_payload',
    );
    _validate_object($session, $payload);
    my @identity = map {
        my $artifact = $assembly->{artifact}{$_};
        {
            relpath => $_,
            kind => $artifact->{kind},
            bytes => bytes::length($artifact->{content}),
            sha256 => sha256_hex($artifact->{content}),
        }
    } sort keys %{$assembly->{artifact}};
    return {
        schema => 'fsmgen.vial_verilator_measurement_assembly.v1',
        schema_version => 1,
        result_production_payload_sha256 => $payload->{sha256},
        artifact_count => scalar(@identity),
        artifact_identity_sha256 => sha256_hex(_canonical_json(\@identity)),
        result_rel => $assembly->{result_rel},
    };
}

sub _restore_measurement_assembly($session) {
    my $stored = _decode_object_json(
        $session, _object_by_kind(
            $session->{objects}, 'assembly_payload',
        ),
    );
    _require_exact_keys(
        $stored, \@MEASUREMENT_ASSEMBLY_KEYS,
        'measurement assembly descriptor',
    );
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'measurement assembly descriptor schema changed',
        '/objects/assembly_payload',
    ) unless ($stored->{schema} // '')
            eq 'fsmgen.vial_verilator_measurement_assembly.v1'
        && ($stored->{schema_version} // 0) == 1;
    my $payload_object = _object_by_kind(
        $session->{objects}, 'result_production_payload',
    );
    _validate_object($session, $payload_object);
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'measurement assembly result predecessor changed',
        '/objects/assembly_payload',
    ) unless ($stored->{result_production_payload_sha256} // '')
        eq $payload_object->{sha256};
    my $payload = _decode_object_json($session, $payload_object);
    my $assembly = _build_assembly($session, $payload);
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'measurement assembly descriptor identity changed',
        '/objects/assembly_payload',
    ) unless _canonical_json($stored)
        eq _canonical_json(
            _measurement_assembly_descriptor($session, $assembly),
        );
    return $assembly;
}

sub _finish_session($session) {
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'only an assembled lifecycle can be cleaned',
        '/handle/state',
    ) unless $session->{handle}{state} eq 'assembled'
        && ($session->{handle}{next_state} // '') eq 'cleaned';
    _load_state_chain($session, $session->{handle});
    my $evidence = _stage_evidence($session);
    my $assembly = delete($session->{terminal_assembly});
    $assembly //= $session->{storage_context}{mode}
            eq 'architecture_scale_measurement'
        ? _restore_measurement_assembly($session)
        : _decode_object_json(
            $session, _object_by_kind(
                $session->{objects}, 'assembly_payload',
            ),
        );
    my $assembled = $session->{storage_context}{mode}
            eq 'architecture_scale_measurement'
        ? _finalize_measurement_result($session, $assembly)
        : _finalize_public_result($session, $assembly);
    _remove_session_root($session);
    return _lifecycle_result({
        ok => JSON::PP::true,
        status => 'cleaned',
        operation_id => $session->{operation_id},
        lifecycle_identity => $session->{lifecycle_identity},
        handle => _cleaned_handle($session),
        assembled_result => $assembled,
        stage_evidence => $evidence,
        diagnostics => [],
        cleanup => {
            staging_identity => $session->{stage_rel},
            removed => JSON::PP::true,
            residue => [],
        },
    });
}

sub _finalize_public_result($session, $assembly, $clone_artifacts = 1) {
    my %artifact = %{$assembly->{artifact}};
    my $backend_manifest = _clone(
        $session->{emission}{backend_manifest},
    );
    $backend_manifest->{tool_profile} = {
        relpath => "$BASE/evidence/tool-profile.json",
        sha256 => sha256_hex(
            $artifact{"$BASE/evidence/tool-profile.json"}{content},
        ),
        selection_status => 'executed_qualified',
    };
    $backend_manifest->{capability_evidence}{compile} = 'passed';
    $backend_manifest->{capability_evidence}{runtime} = 'passed';
    $backend_manifest->{capability_evidence}{result} =
        $assembly->{result}{status};
    $backend_manifest->{limitations} = [
        'known-value trace observation only; complete four-state observation is not claimed',
        'one unit, one clock domain, no native extension, and declared probe adapters only',
        'direct endpoint drives require an input carrier in the scenario root fiber',
        'runtime result is produced; cross-backend parity remains unevaluated',
    ];
    for my $entry (
        [compile => "$BASE/commands/compile-command.json", $session->{compile}],
        [run => "$BASE/commands/run-command.json", $session->{run}],
    ) {
        my ($name, $relpath, $command) = @$entry;
        $backend_manifest->{commands}{$name} = {
            relpath => $relpath,
            command_digest => $command->{command_digest},
            sha256 => sha256_hex($artifact{$relpath}{content}),
            execution_status => 'passed',
        };
    }
    $backend_manifest->{result} = {
        schema => 'fsmgen.verification_result_manifest.v1',
        status => $assembly->{result}{status},
        relpath => $assembly->{result_rel},
        sha256 => sha256_hex($assembly->{result}{content}),
    };
    $backend_manifest->{cleanup} = {
        staging_identity => $session->{stage_rel},
        state => 'completed_removed',
        removed => JSON::PP::true,
    };
    my @backend_artifacts = grep {
        $_ ne "$BASE/backend-manifest.json"
            && index($_, 'results/') != 0
    } sort keys %artifact;
    $backend_manifest->{artifacts} = [
        map { _artifact_ref($artifact{$_}) } @backend_artifacts
    ];
    $artifact{"$BASE/backend-manifest.json"}{content} =
        _json_text($backend_manifest);
    my @artifacts = map {
        $clone_artifacts ? _clone($artifact{$_}) : $artifact{$_}
    } sort keys %artifact;
    return {
        ok => JSON::PP::true,
        status => $assembly->{result}{status},
        operation_id => $session->{operation_id},
        backend_profile => 'sv_portable_verilator',
        backend_manifest => $backend_manifest,
        result_manifest => $assembly->{result}{manifest},
        artifacts => \@artifacts,
        diagnostics => [],
        cleanup => {
            staging_identity => $session->{stage_rel},
            removed => JSON::PP::true,
        },
    };
}

sub _finalize_measurement_result($session, $assembly) {
    my $public = _finalize_public_result($session, $assembly, 0);
    my $controller_rel = $session->{stage_rel};
    _throw(
        'VIAL_LIFECYCLE_STORAGE_ERROR',
        'measurement lifecycle root has no exact controller parent',
        '/storage_context/staging_identity',
    ) unless $controller_rel =~ s{/lifecycle\z}{};
    my $graph_rel = "$controller_rel/outputs/publish/artifact-graph";
    my $graph_abs = _safe_destination(
        $session->{repo_root}, $graph_rel, $session->{root_device},
    );
    _throw(
        'VIAL_RUN_COLLISION',
        'measurement publication graph already exists',
        '/assembled_result/materialized_identity',
    ) if -e $graph_abs || -l $graph_abs;
    _make_directory($graph_abs, $graph_rel);
    my @identity;
    for my $artifact (@{$public->{artifacts}}) {
        my $relative = $artifact->{relpath};
        _rel_abs('.', $relative);
        my $content = $artifact->{content};
        _throw(
            'VIAL_RUN_RESULT_ERROR',
            'measurement publication artifact has invalid content',
            '/assembled_result/artifacts',
        ) unless defined($content) && !ref($content);
        my $target_rel = "$graph_rel/$relative";
        my $target_abs = _safe_destination(
            $session->{repo_root}, $target_rel, $session->{root_device},
        );
        _make_directory(dirname($target_abs), dirname($target_rel));
        _write_exact($target_abs, $content, $target_rel);
        my $lines = () = $content =~ /\n/g;
        push @identity, {
            relpath => $relative,
            kind => $artifact->{kind},
            bytes => bytes::length($content),
            lines => $lines,
            sha256 => sha256_hex($content),
        };
    }
    my %artifact = map { $_->{relpath} => $_ } @{$public->{artifacts}};
    my %transcript;
    for my $name (qw(compile run)) {
        my $relative = "$BASE/evidence/$name-transcript.txt";
        my $entry = $artifact{$relative};
        _throw(
            'VIAL_RUN_RESULT_ERROR',
            "measurement publication lacks the $name transcript",
            '/assembled_result/transcripts',
        ) unless ref($entry) eq 'HASH'
            && defined($entry->{content}) && !ref($entry->{content});
        $transcript{$name} = {
            content => $entry->{content},
            sha256 => sha256_hex($entry->{content}),
        };
    }
    return {
        ok => JSON::PP::true,
        status => $public->{status},
        operation_id => $public->{operation_id},
        backend_profile => $public->{backend_profile},
        backend_manifest => $public->{backend_manifest},
        result_manifest => $public->{result_manifest},
        artifacts => \@identity,
        materialized_identity => $graph_rel,
        commands => {
            compile => _clone($session->{compile}),
            run => _clone($session->{run}),
        },
        workspace_command_digests => {
            compile => $session->{compile_workspace_digest},
            run => $session->{run_workspace_digest},
        },
        transcripts => \%transcript,
        diagnostics => [],
        cleanup => $public->{cleanup},
    };
}

sub _session_result($session) {
    return _lifecycle_result({
        ok => JSON::PP::true,
        status => $session->{handle}{state},
        operation_id => $session->{operation_id},
        lifecycle_identity => $session->{lifecycle_identity},
        handle => _clone($session->{handle}),
        assembled_result => undef,
        stage_evidence => _stage_evidence($session),
        diagnostics => [],
        cleanup => {
            staging_identity => $session->{stage_rel},
            removed => JSON::PP::false,
            residue => [],
        },
    });
}

sub _exception_result($error, $session) {
    my ($code, $message, $path) = (
        'VIAL_RUN_HOST_ERROR', _sanitize_exception($error), '/',
    );
    if (blessed($error)
            && $error->isa(
                'FSM::VIAL::Backend::VerilatorLifecycle::Failure'
            )) {
        ($code, $message, $path) =
            @{$error}{qw(code message path)};
    }
    my $cleanup = {
        staging_identity => defined($session)
            ? $session->{stage_rel} : undef,
        removed => JSON::PP::false,
        residue => [],
    };
    if (defined($session) && defined($session->{handle})) {
        my $loaded = eval { _stage_evidence($session) };
        $session->{failure_stage_evidence} =
            defined($loaded) && ref($loaded) eq 'ARRAY' ? $loaded : [];
        push @{$session->{failure_stage_evidence}},
            _clone($session->{pending_stage_evidence})
            if defined $session->{pending_stage_evidence};
    }
    my $cleanup_authorized = defined($session)
        && ($session->{stage_created}
            || defined($session->{handle}));
    if ($cleanup_authorized && defined($session->{stage_abs})
            && (-e $session->{stage_abs} || -l $session->{stage_abs})) {
        my $ok = eval { _remove_session_root($session); 1 };
        if ($ok) {
            $cleanup->{removed} = JSON::PP::true;
        }
        else {
            ($code, $message, $path) = (
                'VIAL_RUN_CLEANUP_ERROR',
                _sanitize_exception($@), '/cleanup',
            );
            $cleanup->{residue} = _tree_files_relative(
                $session->{stage_abs},
            );
        }
    }
    return _failure_result(
        $code, $message, $path, $session, $cleanup,
    );
}

sub _failure_result($code, $message, $path, $session, $cleanup = undef) {
    $cleanup //= {
        staging_identity => defined($session)
            ? $session->{stage_rel} : undef,
        removed => JSON::PP::false,
        residue => [],
    };
    my $stage_evidence = defined($session)
            && ref($session->{failure_stage_evidence}) eq 'ARRAY'
        ? _clone($session->{failure_stage_evidence}) : [];
    if (!@$stage_evidence
            && defined($session) && defined($session->{handle})) {
        my $loaded = eval { _stage_evidence($session) };
        $stage_evidence = $loaded if defined $loaded && ref($loaded) eq 'ARRAY';
        push @$stage_evidence, _clone($session->{pending_stage_evidence})
            if defined $session->{pending_stage_evidence};
    }
    return _lifecycle_result({
        ok => JSON::PP::false,
        status => 'error',
        operation_id => defined($session)
            ? $session->{operation_id} : undef,
        lifecycle_identity => defined($session)
            ? $session->{lifecycle_identity} : undef,
        handle => defined($session) && defined($session->{handle})
            ? _clone($session->{handle}) : undef,
        assembled_result => undef,
        stage_evidence => $stage_evidence,
        diagnostics => [{
            code => $code,
            severity => 'error',
            message => $message,
            path => $path,
        }],
        cleanup => $cleanup,
    });
}

sub _lifecycle_result($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'lifecycle result has unknown key(s)'
        if grep { !$expected{$_} } keys %$value;
    confess 'lifecycle result is missing key(s)'
        if grep { !exists($value->{$_}) } @RESULT_KEYS;
    return _clone($value);
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _persist_state($session, $state_name, $predecessor, $evidence) {
    my $ordinal = $STATE_ORDINAL{$state_name};
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        "lifecycle state '$state_name' is unknown", '/state',
    ) unless defined $ordinal && $state_name ne 'cleaned';
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle evidence must be one closed JSON object', '/evidence',
    ) unless ref($evidence) eq 'HASH' && !blessed($evidence);
    my $execution = _object_by_kind(
        $session->{objects}, 'authority_execution_ir',
    );
    my $emission = _object_by_kind(
        $session->{objects}, 'authority_emission',
    );
    my $record = {
        schema => $STATE_SCHEMA,
        schema_version => 1,
        lifecycle_identity => $session->{lifecycle_identity},
        operation_id => $session->{operation_id},
        state => $state_name,
        ordinal => $ordinal,
        state_identity => undef,
        predecessor_identity => defined($predecessor)
            ? $predecessor->{state_identity} : undef,
        predecessor_relpath => defined($predecessor)
            ? $session->{handle}{state_relpath} : undef,
        next_state => $STATE_ORDER[$ordinal + 1],
        storage_context => _clone($session->{storage_context}),
        authority => {
            plan_id => $session->{emission}{plan_id},
            execution_ir_sha256 => $execution->{sha256},
            emission_sha256 => $emission->{sha256},
            compile_command_digest =>
                $session->{compile}{command_digest},
            run_command_digest => $session->{run}{command_digest},
            compile_workspace_command_digest =>
                $session->{compile_workspace_digest},
            run_workspace_command_digest =>
                $session->{run_workspace_digest},
        },
        objects => _clone($session->{objects}),
        evidence => _clone($evidence),
    };
    my $digest = sha256_hex(_canonical_json($record));
    $record->{state_identity} = "state/$digest";
    my $state_rel = sprintf(
        '%s/states/%02d-%s-%s.json',
        $session->{stage_rel}, $ordinal, $state_name, $digest,
    );
    my $state_abs = _owned_abs($session, $state_rel);
    _make_directory(dirname($state_abs), dirname($state_rel));
    _throw(
        'VIAL_LIFECYCLE_COLLISION',
        "lifecycle state '$state_rel' already exists",
        '/state_identity',
    ) if -e $state_abs || -l $state_abs;
    _write_atomic($state_abs, _canonical_json($record) . "\n");
    $session->{state} = _clone($record);
    $session->{handle} = {
        schema => $HANDLE_SCHEMA,
        schema_version => 1,
        lifecycle_identity => $session->{lifecycle_identity},
        operation_id => $session->{operation_id},
        state => $state_name,
        ordinal => $ordinal,
        state_identity => $record->{state_identity},
        state_relpath => $state_rel,
        next_state => $record->{next_state},
        storage_context => _clone($session->{storage_context}),
    };
    $session->{chain} = undef;
    return $session->{state};
}

sub _validate_handle($handle, $session) {
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle handle must be one closed object', '/handle',
    ) unless ref($handle) eq 'HASH' && !blessed($handle);
    _closed_with_code(
        $handle, \@HANDLE_KEYS, 'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle handle', '/handle',
    );
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle handle schema is not exact', '/handle/schema',
    ) unless ($handle->{schema} // '') eq $HANDLE_SCHEMA
        && ($handle->{schema_version} // 0) == 1;
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle handle authority changed', '/handle',
    ) unless ($handle->{lifecycle_identity} // '')
            eq $session->{lifecycle_identity}
        && ($handle->{operation_id} // '') eq $session->{operation_id}
        && _canonical_json($handle->{storage_context})
            eq _canonical_json($session->{storage_context});
    my $state = $handle->{state};
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle handle state or ordinal is invalid', '/handle/state',
    ) unless defined($state) && exists($STATE_ORDINAL{$state})
        && $state ne 'cleaned'
        && ($handle->{ordinal} // -1) == $STATE_ORDINAL{$state}
        && ($handle->{state_identity} // '')
            =~ m{\Astate/[0-9a-f]{64}\z};
    my ($digest) = $handle->{state_identity}
        =~ m{\Astate/([0-9a-f]{64})\z};
    my $expected = sprintf(
        '%s/states/%02d-%s-%s.json',
        $session->{stage_rel}, $handle->{ordinal}, $state, $digest,
    );
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle handle state path is not content-addressed',
        '/handle/state_relpath',
    ) unless ($handle->{state_relpath} // '') eq $expected;
    my $next = $STATE_ORDER[$handle->{ordinal} + 1];
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle handle successor changed', '/handle/next_state',
    ) unless ($handle->{next_state} // '') eq ($next // '');
    return 1;
}

sub _load_state_chain($session, $handle) {
    _validate_handle($handle, $session);
    my (@reverse, %seen);
    my $relative = $handle->{state_relpath};
    while (defined $relative) {
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'lifecycle predecessor chain contains a cycle',
            '/predecessor_relpath',
        ) if $seen{$relative}++;
        my $record = _read_state_record($session, $relative);
        push @reverse, $record;
        $relative = $record->{predecessor_relpath};
    }
    my @chain = reverse @reverse;
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle predecessor chain is empty', '/state',
    ) unless @chain;
    for my $index (0 .. $#chain) {
        my $state = $chain[$index];
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'lifecycle state chain skipped or reordered a state',
            '/state',
        ) unless $state->{ordinal} == $index
            && $state->{state} eq $STATE_ORDER[$index];
        if ($index == 0) {
            _throw(
                'VIAL_LIFECYCLE_STATE_ERROR',
                'admitted state has a predecessor',
                '/predecessor_identity',
            ) if defined($state->{predecessor_identity})
                || defined($state->{predecessor_relpath});
        }
        else {
            _throw(
                'VIAL_LIFECYCLE_STATE_ERROR',
                'lifecycle predecessor identity changed',
                '/predecessor_identity',
            ) unless ($state->{predecessor_identity} // '')
                eq $chain[$index - 1]{state_identity};
        }
    }
    my $current = $chain[-1];
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle handle and current state differ', '/handle',
    ) unless $current->{state_identity} eq $handle->{state_identity};
    my $states_abs = _owned_abs(
        $session, "$session->{stage_rel}/states",
    );
    my @actual = map { "$session->{stage_rel}/states/$_" }
        _tree_files_relative($states_abs);
    my @expected = sort map {
        my ($digest) = $_->{state_identity}
            =~ m{\Astate/([0-9a-f]{64})\z};
        sprintf(
            '%s/states/%02d-%s-%s.json',
            $session->{stage_rel}, $_->{ordinal}, $_->{state}, $digest,
        );
    } @chain;
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state tree contains a partial, extra, or missing state',
        '/state',
    ) unless _canonical_json(\@actual) eq _canonical_json(\@expected);
    $session->{chain} = \@chain;
    $session->{state} = _clone($current);
    $session->{objects} = _clone($current->{objects});
    return $session->{state};
}

sub _read_state_record($session, $relative) {
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state path is outside the exact state root',
        '/state',
    ) unless defined($relative) && !ref($relative)
        && index($relative, "$session->{stage_rel}/states/") == 0;
    my $path = _owned_abs($session, $relative);
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state is absent or not a regular non-symlink file',
        '/state',
    ) unless -f $path && !-l $path;
    my @stat = stat($path);
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state crossed the repository filesystem volume',
        '/state',
    ) unless @stat && $stat[0] == $session->{root_device}
        && $stat[7] <= 1_048_576
        && ($stat[2] & 07777) == 0600;
    open my $fh, '<:raw', $path
        or _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'cannot read lifecycle state', '/state',
        );
    local $/;
    my $content = <$fh>;
    close $fh or _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'cannot close lifecycle state', '/state',
    );
    my $record = eval { JSON::PP->new->decode($content) };
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state is not canonical JSON', '/state',
    ) unless defined($record) && !$@
        && ref($record) eq 'HASH' && !blessed($record)
        && $content eq _canonical_json($record) . "\n";
    _closed_with_code(
        $record, \@STATE_KEYS, 'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state', '/state',
    );
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state schema or authority changed', '/state',
    ) unless ($record->{schema} // '') eq $STATE_SCHEMA
        && ($record->{schema_version} // 0) == 1
        && ($record->{lifecycle_identity} // '')
            eq $session->{lifecycle_identity}
        && ($record->{operation_id} // '') eq $session->{operation_id}
        && _canonical_json($record->{storage_context})
            eq _canonical_json($session->{storage_context});
    my $identity = $record->{state_identity};
    my $copy = _clone($record);
    $copy->{state_identity} = undef;
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state content identity changed', '/state_identity',
    ) unless ($identity // '')
        eq 'state/' . sha256_hex(_canonical_json($copy));
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state authority object changed', '/authority',
    ) unless ref($record->{authority}) eq 'HASH'
        && !blessed($record->{authority})
        && ($record->{authority}{plan_id} // '')
            eq $session->{emission}{plan_id}
        && ($record->{authority}{compile_command_digest} // '')
            eq $session->{compile}{command_digest}
        && ($record->{authority}{run_command_digest} // '')
            eq $session->{run}{command_digest}
        && ($record->{authority}{compile_workspace_command_digest} // '')
            eq $session->{compile_workspace_digest}
        && ($record->{authority}{run_workspace_command_digest} // '')
            eq $session->{run_workspace_digest};
    _require_json_value($record->{evidence}, 'lifecycle state evidence');
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state object inventory is invalid', '/objects',
    ) unless ref($record->{objects}) eq 'ARRAY';
    _validate_object($session, $_) for @{$record->{objects}};
    _validate_state_shape($session, $record);
    return $record;
}

sub _validate_state_shape($session, $record) {
    _closed_lifecycle_record(
        $record->{authority}, \@AUTHORITY_KEYS,
        'lifecycle state authority', '/authority',
    );
    my $execution = _object_by_kind(
        $record->{objects}, 'authority_execution_ir',
    );
    my $emission = _object_by_kind(
        $record->{objects}, 'authority_emission',
    );
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state authority digests changed', '/authority',
    ) unless ($record->{authority}{execution_ir_sha256} // '')
            eq $execution->{sha256}
        && ($record->{authority}{emission_sha256} // '')
            eq $emission->{sha256};

    my $state = $record->{state};
    my $ordinal = $record->{ordinal};
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state name, ordinal, or successor is invalid', '/state',
    ) unless defined($state) && exists($STATE_ORDINAL{$state})
        && $state ne 'cleaned'
        && defined($ordinal) && !ref($ordinal)
        && $ordinal =~ /\A(?:0|[1-9][0-9]*)\z/
        && $ordinal == $STATE_ORDINAL{$state}
        && ($record->{next_state} // '')
            eq ($STATE_ORDER[$ordinal + 1] // '');

    my $expected_kinds = $STATE_OBJECT_KINDS{$state};
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'lifecycle state object inventory is not exact', '/objects',
    ) unless defined($expected_kinds)
        && _canonical_json([map { $_->{kind} } @{$record->{objects}}])
            eq _canonical_json($expected_kinds);

    _closed_lifecycle_record(
        $record->{evidence}, $STATE_EVIDENCE_KEYS{$state},
        "lifecycle $state evidence", '/evidence',
    );
    if ($state eq 'admitted') {
        _closed_lifecycle_record(
            $record->{evidence}{command_seals}, [qw(compile run)],
            'lifecycle admitted command seals', '/evidence/command_seals',
        );
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'admitted evidence differs from reconstructed authority',
            '/evidence',
        ) unless ($record->{evidence}{plan_id} // '')
                eq $session->{emission}{plan_id}
            && ($record->{evidence}{backend_profile} // '')
                eq 'sv_portable_verilator'
            && ($record->{evidence}{execution_ir_sha256} // '')
                eq $execution->{sha256}
            && ($record->{evidence}{emission_sha256} // '')
                eq $emission->{sha256}
            && ($record->{evidence}{command_seals}{compile} // '')
                eq $session->{compile}{command_digest}
            && ($record->{evidence}{command_seals}{run} // '')
                eq $session->{run}{command_digest};
    }
    elsif ($state eq 'prepared') {
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'prepared evidence differs from reconstructed commands',
            '/evidence',
        ) unless ($record->{evidence}{input_count} // -1)
                == @{$session->{compile}{inputs}}
            && ($record->{evidence}{object_directory} // '')
                eq _command_mdir($session->{compile})
            && ($record->{evidence}{command_digest} // '')
                eq $session->{compile}{command_digest};
    }
    elsif ($state =~ /\A(?:tool_verified|compiled|ran)\z/) {
        _validate_capture_evidence(
            $session, $state, $record->{evidence}{capture},
        );
        if ($state eq 'tool_verified') {
            my $version = _object_by_kind(
                $record->{objects}, 'tool_version_output',
            );
            _throw(
                'VIAL_LIFECYCLE_STATE_ERROR',
                'tool evidence differs from its sealed version object',
                '/evidence',
            ) unless ($record->{evidence}{version_sha256} // '')
                eq $version->{sha256};
        }
        elsif ($state eq 'compiled') {
            my $transcript = _object_by_kind(
                $record->{objects}, 'compile_raw_output',
            );
            my $executable = _object_by_kind(
                $record->{objects}, 'compiled_executable',
            );
            _throw(
                'VIAL_LIFECYCLE_STATE_ERROR',
                'compile evidence differs from sealed command or objects',
                '/evidence',
            ) unless ($record->{evidence}{command_digest} // '')
                    eq $session->{compile}{command_digest}
                && ($record->{evidence}{executable_sha256} // '')
                    eq $executable->{sha256}
                && ($record->{evidence}{executable_bytes} // -1)
                    == $executable->{bytes}
                && $record->{evidence}{capture}{output_bytes}
                    == $transcript->{bytes};
        }
        else {
            my $output = _object_by_kind(
                $record->{objects}, 'runtime_raw_output',
            );
            my $process = _decode_object_json(
                $session, _object_by_kind(
                    $record->{objects}, 'runtime_process_evidence',
                ),
            );
            _throw(
                'VIAL_LIFECYCLE_STATE_ERROR',
                'runtime evidence differs from sealed command or objects',
                '/evidence',
            ) unless ($record->{evidence}{command_digest} // '')
                    eq $session->{run}{command_digest}
                && ($record->{evidence}{runtime_output_sha256} // '')
                    eq $output->{sha256}
                && ($record->{evidence}{runtime_output_bytes} // -1)
                    == $output->{bytes}
                && _canonical_json($process)
                    eq _canonical_json($record->{evidence}{capture});
        }
    }
    elsif ($state eq 'trace_validated') {
        my $validation = _object_by_kind(
            $record->{objects}, 'validated_trace',
        );
        my $trace = _decode_object_json($session, $validation);
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'sealed trace validation payload is not one closed object',
            '/objects/validated_trace',
        ) unless ref($trace) eq 'HASH'
            && ref($trace->{projection}) eq 'HASH';
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'trace evidence differs from the sealed validation object',
            '/evidence',
        ) unless ($record->{evidence}{validation_object_sha256} // '')
                eq $validation->{sha256}
            && ($record->{evidence}{trace_sha256} // '')
                eq ($trace->{projection}{trace_sha256} // '')
            && ($record->{evidence}{record_count} // -1)
                == ($trace->{projection}{record_count} // -2);
    }
    elsif ($state eq 'result_produced') {
        my $payload_ref = _object_by_kind(
            $record->{objects}, 'result_production_payload',
        );
        my $payload = _decode_object_json($session, $payload_ref);
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'sealed result payload is not one closed object',
            '/objects/result_production_payload',
        ) unless ref($payload) eq 'HASH'
            && ref($payload->{result}) eq 'HASH'
            && ref($payload->{result}{manifest}) eq 'HASH';
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'result evidence differs from the sealed result payload',
            '/evidence',
        ) unless ($record->{evidence}{result_payload_sha256} // '')
                eq $payload_ref->{sha256}
            && ($record->{evidence}{result_id} // '')
                eq ($payload->{result}{manifest}{result_id} // '')
            && ($record->{evidence}{result_status} // '')
                eq ($payload->{result}{status} // '');
    }
    elsif ($state eq 'assembled') {
        my $assembly_ref = _object_by_kind(
            $record->{objects}, 'assembly_payload',
        );
        my $assembly = _decode_object_json($session, $assembly_ref);
        my $artifact_count;
        if ($session->{storage_context}{mode}
                eq 'architecture_scale_measurement') {
            _closed_lifecycle_record(
                $assembly, \@MEASUREMENT_ASSEMBLY_KEYS,
                'measurement assembly descriptor',
                '/objects/assembly_payload',
            );
            my $payload_ref = _object_by_kind(
                $record->{objects}, 'result_production_payload',
            );
            my $payload = _decode_object_json($session, $payload_ref);
            my $rebuilt = _build_assembly($session, $payload);
            _throw(
                'VIAL_LIFECYCLE_STATE_ERROR',
                'sealed measurement assembly descriptor changed',
                '/objects/assembly_payload',
            ) unless _canonical_json($assembly) eq _canonical_json(
                _measurement_assembly_descriptor(
                    $session, $rebuilt, $record->{objects},
                ),
            );
            $artifact_count = $assembly->{artifact_count};
        }
        else {
            _throw(
                'VIAL_LIFECYCLE_STATE_ERROR',
                'sealed assembly payload is not one closed object',
                '/objects/assembly_payload',
            ) unless ref($assembly) eq 'HASH'
                && ref($assembly->{artifact}) eq 'HASH';
            $artifact_count = scalar(keys %{$assembly->{artifact}});
        }
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'assembly evidence differs from the sealed artifact payload',
            '/evidence',
        ) unless ($record->{evidence}{assembly_payload_sha256} // '')
                eq $assembly_ref->{sha256}
            && ($record->{evidence}{artifact_count_before_cleanup} // -1)
                == $artifact_count;
    }
    return 1;
}

sub _closed_lifecycle_record($value, $keys, $label, $path) {
    return _closed_with_code(
        $value, $keys, 'VIAL_LIFECYCLE_STATE_ERROR', $label, $path,
    );
}

sub _closed_with_code($value, $keys, $code, $label, $path) {
    _throw(
        $code, "$label must be one closed object", $path,
    ) unless ref($value) eq 'HASH' && !blessed($value)
        && ref($keys) eq 'ARRAY';
    my %expected = map { $_ => 1 } @$keys;
    _throw(
        $code, "$label has an unknown or missing key", $path,
    ) if (grep { !$expected{$_} } keys %$value)
        || (grep { !exists($value->{$_}) } @$keys);
    return 1;
}

sub _validate_capture_evidence($session, $state, $capture) {
    _closed_lifecycle_record(
        $capture, \@CAPTURE_KEYS, "lifecycle $state capture",
        '/evidence/capture',
    );
    my %expected = (
        tool_verified => [10, 65_536],
        compiled => [120, 8_388_608],
        ran => [30, 67_108_864],
    );
    my ($timeout, $limit) = @{$expected{$state}};
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        "$state capture differs from the qualified process contract",
        '/evidence/capture',
    ) unless $capture->{ok}
        && !$capture->{timed_out}
        && !$capture->{output_limited}
        && !$capture->{exec_failed}
        && !defined($capture->{exec_error})
        && ($capture->{exit_code} // -1) == 0
        && ($capture->{signal} // -1) == 0
        && ($capture->{containment} // '')
            eq $session->{storage_context}{containment}
        && ($capture->{timeout_seconds} // -1) == $timeout
        && ($capture->{capture_limit_bytes} // -1) == $limit
        && defined($capture->{output_bytes})
        && $capture->{output_bytes} > 0;
    for my $key (qw(
        started_monotonic_ns exec_handoff_monotonic_ns
        first_output_monotonic_ns finished_monotonic_ns spawn_to_exec_ns
        execution_ns exec_to_first_output_ns first_output_to_exit_ns
    )) {
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            "$state capture timing is incomplete",
            '/evidence/capture',
        ) unless defined($capture->{$key}) && !ref($capture->{$key})
            && $capture->{$key} =~ /\A(?:0|[1-9][0-9]*)\z/;
    }
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        "$state capture timing is internally inconsistent",
        '/evidence/capture',
    ) unless $capture->{started_monotonic_ns}
            <= $capture->{exec_handoff_monotonic_ns}
        && $capture->{exec_handoff_monotonic_ns}
            <= $capture->{first_output_monotonic_ns}
        && $capture->{first_output_monotonic_ns}
            <= $capture->{finished_monotonic_ns}
        && $capture->{spawn_to_exec_ns}
            == $capture->{exec_handoff_monotonic_ns}
                - $capture->{started_monotonic_ns}
        && $capture->{execution_ns}
            == $capture->{finished_monotonic_ns}
                - $capture->{exec_handoff_monotonic_ns}
        && $capture->{exec_to_first_output_ns}
            == $capture->{first_output_monotonic_ns}
                - $capture->{exec_handoff_monotonic_ns}
        && $capture->{first_output_to_exit_ns}
            == $capture->{finished_monotonic_ns}
                - $capture->{first_output_monotonic_ns};
    return 1;
}

sub _write_content_object($session, $kind, $content, $executable) {
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle object kind is invalid', '/objects/kind',
    ) unless defined($kind) && !ref($kind)
        && $kind =~ /\A[a-z][a-z0-9_]*\z/;
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle object content must be a scalar', '/objects',
    ) unless defined($content) && !ref($content);
    my $digest = sha256_hex($content);
    my $relative = _object_relative($session, $digest);
    my $path = _owned_abs($session, $relative);
    _make_directory(dirname($path), dirname($relative));
    if (-e $path || -l $path) {
        my $existing = {
            kind => $kind,
            sha256 => $digest,
            bytes => bytes::length($content),
            executable => $executable ? JSON::PP::true : JSON::PP::false,
            relative_path => $relative,
        };
        _validate_object($session, $existing);
        return $existing;
    }
    _write_atomic($path, $content);
    chmod($executable ? 0755 : 0644, $path)
        or _throw(
            'VIAL_LIFECYCLE_OBJECT_ERROR',
            'cannot seal lifecycle object permissions', '/objects',
        );
    return {
        kind => $kind,
        sha256 => $digest,
        bytes => bytes::length($content),
        executable => $executable ? JSON::PP::true : JSON::PP::false,
        relative_path => $relative,
    };
}

sub _write_file_object($session, $kind, $source, $executable) {
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle file object source is not a regular non-symlink file',
        '/objects',
    ) unless -f $source && !-l $source;
    my $incoming_rel = "$session->{stage_rel}/objects/.incoming-$$-"
        . sha256_hex($kind . "\0" . time() . "\0" . rand());
    my $incoming = _owned_abs($session, $incoming_rel);
    _make_directory(dirname($incoming), dirname($incoming_rel));
    sysopen(
        my $out, $incoming,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600,
    ) or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot create lifecycle incoming object', '/objects',
    );
    open my $in, '<:raw', $source or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot read lifecycle file object source', '/objects',
    );
    my $sha = Digest::SHA->new(256);
    my $bytes = 0;
    while (1) {
        my $buffer = '';
        my $read = sysread($in, $buffer, 65_536);
        _throw(
            'VIAL_LIFECYCLE_OBJECT_ERROR',
            'cannot stream lifecycle file object source', '/objects',
        ) unless defined $read;
        last if $read == 0;
        $sha->add($buffer);
        $bytes += $read;
        my $offset = 0;
        while ($offset < $read) {
            my $written = syswrite(
                $out, $buffer, $read - $offset, $offset,
            );
            _throw(
                'VIAL_LIFECYCLE_OBJECT_ERROR',
                'cannot stream lifecycle file object', '/objects',
            ) unless defined($written) && $written > 0;
            $offset += $written;
        }
    }
    close $in or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot close lifecycle file object source', '/objects',
    );
    close $out or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot close lifecycle incoming object', '/objects',
    );
    my $digest = $sha->hexdigest;
    my $relative = _object_relative($session, $digest);
    my $target = _owned_abs($session, $relative);
    _make_directory(dirname($target), dirname($relative));
    if (-e $target || -l $target) {
        unlink($incoming) or _throw(
            'VIAL_LIFECYCLE_OBJECT_ERROR',
            'cannot remove duplicate lifecycle incoming object',
            '/objects',
        );
    }
    else {
        rename($incoming, $target) or _throw(
            'VIAL_LIFECYCLE_OBJECT_ERROR',
            'cannot commit lifecycle file object atomically',
            '/objects',
        );
    }
    chmod($executable ? 0755 : 0644, $target)
        or _throw(
            'VIAL_LIFECYCLE_OBJECT_ERROR',
            'cannot seal lifecycle file object permissions',
            '/objects',
        );
    my $object = {
        kind => $kind,
        sha256 => $digest,
        bytes => $bytes,
        executable => $executable ? JSON::PP::true : JSON::PP::false,
        relative_path => $relative,
    };
    _validate_object($session, $object);
    return $object;
}

sub _object_relative($session, $digest) {
    return "$session->{stage_rel}/objects/sha256/"
        . substr($digest, 0, 2) . "/$digest";
}

sub _validate_object($session, $object) {
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle object reference is not one closed object', '/objects',
    ) unless ref($object) eq 'HASH' && !blessed($object);
    _closed_with_code(
        $object, \@OBJECT_KEYS, 'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle object reference', '/objects',
    );
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle object reference is invalid', '/objects',
    ) unless ($object->{kind} // '') =~ /\A[a-z][a-z0-9_]*\z/
        && ($object->{sha256} // '') =~ /\A[0-9a-f]{64}\z/
        && defined($object->{bytes}) && !ref($object->{bytes})
        && $object->{bytes} =~ /\A(?:0|[1-9][0-9]*)\z/
        && blessed($object->{executable})
        && $object->{executable}->isa('JSON::PP::Boolean');
    my $relative = _object_relative($session, $object->{sha256});
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle object path is not content-addressed',
        '/objects/relative_path',
    ) unless ($object->{relative_path} // '') eq $relative;
    my $path = _owned_abs($session, $relative);
    my @stat = lstat($path);
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle object is absent, linked, or not a regular file',
        '/objects',
    ) unless @stat && -f _ && !-l _
        && $stat[0] == $session->{root_device}
        && $stat[7] == $object->{bytes}
        && ($stat[2] & 07777) == ($object->{executable} ? 0755 : 0644);
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle object content identity changed', '/objects/sha256',
    ) unless _file_sha256($path) eq $object->{sha256};
    return 1;
}

sub _object_by_kind($objects, $kind) {
    my @match = grep { ($_->{kind} // '') eq $kind } @$objects;
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        "lifecycle object kind '$kind' is absent or ambiguous",
        '/objects',
    ) unless @match == 1;
    return $match[0];
}

sub _validate_authority_objects($session) {
    my $execution = _object_by_kind(
        $session->{objects}, 'authority_execution_ir',
    );
    my $emission = _object_by_kind(
        $session->{objects}, 'authority_emission',
    );
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'caller ExecutionIR differs from admitted authority',
        '/execution_ir',
    ) unless $execution->{sha256}
        eq sha256_hex(_canonical_json($session->{execution_hash}));
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'caller emission differs from admitted authority', '/emission',
    ) unless $emission->{sha256}
        eq sha256_hex(_canonical_json($session->{emission}));
    return 1;
}

sub _read_object_content($session, $object) {
    _validate_object($session, $object);
    my $path = _owned_abs($session, $object->{relative_path});
    open my $fh, '<:raw', $path or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot read lifecycle object', '/objects',
    );
    local $/;
    my $content = <$fh>;
    close $fh or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot close lifecycle object', '/objects',
    );
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle object byte count changed while reading', '/objects',
    ) unless bytes::length($content) == $object->{bytes};
    return $content;
}

sub _decode_object_json($session, $object) {
    my $content = _read_object_content($session, $object);
    my $decoded = eval { JSON::PP->new->decode($content) };
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle JSON object is malformed', '/objects',
    ) unless defined($decoded) && !$@;
    _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'lifecycle JSON object is not canonical', '/objects',
    ) unless _canonical_json($decoded) eq $content;
    return $decoded;
}

sub _restore_transient($session) {
    _validate_authority_objects($session);
    _validate_materialized_inputs($session)
        if $session->{handle}{ordinal} >= $STATE_ORDINAL{prepared};
    if ($session->{handle}{ordinal} >= $STATE_ORDINAL{compiled}) {
        my $executable = _object_by_kind(
            $session->{objects}, 'compiled_executable',
        );
        my $work_copy = _owned_abs(
            $session, $session->{compile}{expected_outputs}[0],
        );
        _throw(
            'VIAL_LIFECYCLE_OBJECT_ERROR',
            'compiled executable work copy changed after sealing',
            '/objects/compiled_executable',
        ) unless -f $work_copy && !-l $work_copy && -x $work_copy
            && _file_sha256($work_copy) eq $executable->{sha256};
    }
    return 1;
}

sub _stage_evidence($session) {
    _load_state_chain($session, $session->{handle})
        unless defined $session->{chain};
    return [map {{
        state => $_->{state},
        ordinal => $_->{ordinal},
        state_identity => $_->{state_identity},
        predecessor_identity => $_->{predecessor_identity},
        evidence => _clone($_->{evidence}),
    }} @{$session->{chain}}];
}

sub _cleaned_handle($session) {
    my $identity = 'state/' . sha256_hex(_canonical_json({
        lifecycle_identity => $session->{lifecycle_identity},
        predecessor_identity => $session->{handle}{state_identity},
        state => 'cleaned',
        ordinal => $STATE_ORDINAL{cleaned},
        staging_identity => $session->{stage_rel},
        removed => JSON::PP::true,
    }));
    return {
        schema => $HANDLE_SCHEMA,
        schema_version => 1,
        lifecycle_identity => $session->{lifecycle_identity},
        operation_id => $session->{operation_id},
        state => 'cleaned',
        ordinal => $STATE_ORDINAL{cleaned},
        state_identity => $identity,
        state_relpath => undef,
        next_state => undef,
        storage_context => _clone($session->{storage_context}),
    };
}

sub _remove_session_root($session) {
    my $path = _safe_destination(
        $session->{repo_root}, $session->{stage_rel},
        $session->{root_device},
    );
    _throw(
        'VIAL_RUN_CLEANUP_ERROR',
        'runtime staging root became a symlink', '/cleanup',
    ) if -l $path;
    if (-e $path) {
        _throw(
            'VIAL_RUN_CLEANUP_ERROR',
            'runtime staging root is not a directory', '/cleanup',
        ) unless -d $path;
        _tree_files_relative($path, $session->{root_device});
        my $cleanup_error;
        remove_tree($path, {error => \$cleanup_error});
        _throw(
            'VIAL_RUN_CLEANUP_ERROR',
            "cannot remove runtime staging root '$session->{stage_rel}'",
            '/cleanup',
        ) if $cleanup_error && @$cleanup_error;
    }
    _throw(
        'VIAL_RUN_CLEANUP_ERROR',
        "runtime staging root '$session->{stage_rel}' remains after cleanup",
        '/cleanup',
    ) if -e $path || -l $path;
    return 1;
}

sub _write_atomic($path, $content) {
    my $temporary = "$path.tmp-$$-" . sha256_hex(
        time() . "\0" . rand() . "\0" . bytes::length($content),
    );
    sysopen(
        my $fh, $temporary,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600,
    ) or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot create lifecycle atomic temporary', '/state',
    );
    print {$fh} $content or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot write lifecycle atomic temporary', '/state',
    );
    close $fh or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot close lifecycle atomic temporary', '/state',
    );
    rename($temporary, $path) or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot commit lifecycle atomic object', '/state',
    );
    return 1;
}

sub _file_sha256($path) {
    open my $fh, '<:raw', $path or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot read lifecycle object for hashing', '/objects',
    );
    my $sha = Digest::SHA->new(256);
    while (1) {
        my $buffer = '';
        my $read = sysread($fh, $buffer, 65_536);
        _throw(
            'VIAL_LIFECYCLE_OBJECT_ERROR',
            'cannot hash lifecycle object', '/objects',
        ) unless defined $read;
        last if $read == 0;
        $sha->add($buffer);
    }
    close $fh or _throw(
        'VIAL_LIFECYCLE_OBJECT_ERROR',
        'cannot close lifecycle object after hashing', '/objects',
    );
    return $sha->hexdigest;
}

sub _tree_files_relative($root, $root_device = undef) {
    return () unless -d $root && !-l $root;
    my @files;
    _walk_tree($root, '', \@files, $root_device);
    return sort @files;
}

sub _walk_tree($root, $relative, $files, $root_device) {
    my $path = length($relative)
        ? File::Spec->catdir($root, split m{/}, $relative)
        : $root;
    my @root_stat = lstat($path);
    _throw(
        'VIAL_RUN_PATH_ERROR',
        'lifecycle tree crossed the repository filesystem volume',
        '/cleanup',
    ) if defined($root_device)
        && (!@root_stat || $root_stat[0] != $root_device);
    opendir my $dh, $path or _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'cannot inspect lifecycle state tree', '/state',
    );
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        'cannot close lifecycle state tree', '/state',
    );
    for my $name (@entries) {
        my $entry_rel = length($relative)
            ? "$relative/$name" : $name;
        my $entry = File::Spec->catfile($path, $name);
        my @entry_stat = lstat($entry);
        _throw(
            'VIAL_LIFECYCLE_STATE_ERROR',
            'lifecycle state tree contains a symlink', '/state',
        ) if !@entry_stat || -l _;
        _throw(
            'VIAL_RUN_PATH_ERROR',
            'lifecycle tree crossed the repository filesystem volume',
            '/cleanup',
        ) if defined($root_device) && $entry_stat[0] != $root_device;
        if (-d $entry) {
            _walk_tree($root, $entry_rel, $files, $root_device);
        }
        elsif (-f $entry) {
            push @$files, $entry_rel;
        }
        else {
            _throw(
                'VIAL_LIFECYCLE_STATE_ERROR',
                'lifecycle state tree contains a non-file entry',
                '/state',
            );
        }
    }
}

sub _require_json_value($value, $label) {
    my $encoded = eval { _canonical_json($value) };
    _throw(
        'VIAL_LIFECYCLE_STATE_ERROR',
        "$label is not closed JSON", '/state',
    ) unless defined($encoded) && !$@;
    return 1;
}

sub _materialize_inputs($session) {
    my $prefix = "$session->{stage_rel}/work/sv_portable_verilator/input/";
    for my $input (@{$session->{compile}{inputs}}) {
        _throw('VIAL_RUN_COMMAND_ERROR', 'compile input is outside the exact owned staging input root', '/compile/inputs')
            unless index($input, $prefix) == 0;
        my $relpath = substr($input, length($prefix));
        my $source = $session->{artifact}{$relpath};
        _throw('VIAL_RUN_COMMAND_ERROR', "compile input '$relpath' is not one emitted SystemVerilog artifact", '/compile/inputs')
            unless $source && $source->{kind} eq 'systemverilog_source';
        my $path = _owned_abs($session, $input);
        _make_directory(dirname($path), dirname($input));
        _write_exact($path, $source->{content}, $input);
    }
}

sub _rebase_command($raw, $from, $to) {
    my $command = _clone($raw);
    for my $key (qw(arguments inputs expected_outputs)) {
        _throw(
            'VIAL_RUN_COMMAND_ERROR',
            "command $key must be an array before storage rebasing",
            '/commands',
        ) unless ref($command->{$key}) eq 'ARRAY';
        for my $value (@{$command->{$key}}) {
            next unless defined($value) && !ref($value);
            $value = $to . substr($value, length($from))
                if $value eq $from
                    || index($value, "$from/") == 0;
        }
    }
    delete $command->{command_digest};
    $command->{command_digest} =
        sha256_hex(_canonical_json($command));
    return $command;
}

sub _workspace_command_digest($raw, $stage_rel) {
    my $command = _clone($raw);
    delete $command->{command_digest};
    for my $key (qw(arguments inputs expected_outputs)) {
        for my $value (@{$command->{$key}}) {
            next unless defined($value) && !ref($value);
            if ($key eq 'expected_outputs'
                    && $value =~ m{/$BASE/evidence/runtime-trace[.]jsonl\z}) {
                $value = "<artifact-root>/$BASE/evidence/runtime-trace.jsonl";
            }
            elsif ($value eq $stage_rel
                    || index($value, "$stage_rel/") == 0) {
                $value = '<lifecycle-root>'
                    . substr($value, length($stage_rel));
            }
        }
    }
    return 'workspace-command/'
        . sha256_hex(_canonical_json($command));
}

sub _validate_materialized_inputs($session) {
    my $prefix = "$session->{stage_rel}/work/sv_portable_verilator/input/";
    for my $input (@{$session->{compile}{inputs}}) {
        my $relpath = substr($input, length($prefix));
        my $source = $session->{artifact}{$relpath};
        my $path = _owned_abs($session, $input);
        my @stat = lstat($path);
        _throw(
            'VIAL_LIFECYCLE_OBJECT_ERROR',
            "prepared input '$input' changed after sealing",
            '/compile/inputs',
        ) unless defined($source) && @stat && -f _ && !-l _
            && $stat[0] == $session->{root_device}
            && $stat[7] == bytes::length($source->{content})
            && _file_sha256($path) eq sha256_hex($source->{content});
    }
    return 1;
}

sub _validate_command_records($compile, $run, $stage_rel, $top) {
    my @compile_keys = qw(
        schema schema_version logical_executable arguments working_directory
        inputs expected_outputs command_digest
    );
    _closed_record($compile, \@compile_keys, 'compile command');
    _closed_record($run, \@compile_keys, 'run command');
    for my $pair ([$compile, 'compile'], [$run, 'run']) {
        my ($record, $label) = @$pair;
        _throw('VIAL_RUN_COMMAND_ERROR', "$label command schema is not exact", "/$label/schema")
            unless $record->{schema} eq 'fsmgen.vial_backend_command.v1'
                && $record->{schema_version} == 1;
        my $identity = _clone($record);
        delete $identity->{command_digest};
        _throw('VIAL_RUN_COMMAND_ERROR', "$label command digest does not match its content", "/$label/command_digest")
            unless $record->{command_digest} eq sha256_hex($JSON->encode($identity));
    }
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command executable is not exact', '/compile/logical_executable')
        unless $compile->{logical_executable} eq 'verilator';
    my @prefix = qw(
        --binary --timing --assert -j 1 --threads 1 --x-initial 0 --x-assign 0
        --timescale 1ns/1ps --top-module
    );
    my $object_root = "$stage_rel/work/sv_portable_verilator/obj";
    my $input_root = "$stage_rel/work/sv_portable_verilator/input/";
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command input cardinality is not exact', '/compile/inputs')
        unless @{$compile->{inputs}} == 3;
    my %seen_input;
    for my $input (@{$compile->{inputs}}) {
        _throw('VIAL_RUN_COMMAND_ERROR', 'compile command input is outside the operation-owned SystemVerilog tree', '/compile/inputs')
            unless defined($input) && !ref($input) && index($input, $input_root) == 0
                && $input =~ /\.sv\z/ && !$seen_input{$input}++;
    }
    my @expected_arguments = (@prefix, $top, '--Mdir', $object_root, @{$compile->{inputs}});
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command arguments differ from the exact qualified profile', '/compile/arguments')
        unless $JSON->encode($compile->{arguments}) eq $JSON->encode(\@expected_arguments);
    my $executable = "$object_root/V$top";
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command output identity is not exact', '/compile/expected_outputs')
        unless @{$compile->{expected_outputs}} == 1
            && $compile->{expected_outputs}[0] eq $executable;
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command working directory must be repository root', '/compile/working_directory')
        unless $compile->{working_directory} eq '.' && $run->{working_directory} eq '.';
    _throw('VIAL_RUN_COMMAND_ERROR', 'run command executable identity is wrong', '/run/logical_executable')
        unless $run->{logical_executable} eq "V$top" && !@{$run->{arguments}};
    _throw('VIAL_RUN_COMMAND_ERROR', 'run command input does not match the compile executable', '/run/inputs')
        unless @{$run->{inputs}} == 1 && @{$compile->{expected_outputs}} == 1
            && $run->{inputs}[0] eq $compile->{expected_outputs}[0]
            && $run->{inputs}[0] eq $executable;
    _throw('VIAL_RUN_COMMAND_ERROR', 'run command output identity is not one repository-relative runtime trace', '/run/expected_outputs')
        unless @{$run->{expected_outputs}} == 1
            && defined($run->{expected_outputs}[0]) && !ref($run->{expected_outputs}[0])
            && $run->{expected_outputs}[0] =~ m{\A[A-Za-z0-9_.][A-Za-z0-9_.\/-]*/backends/sv_portable_verilator/evidence/runtime-trace\.jsonl\z}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $run->{expected_outputs}[0], -1;
}

sub _command_mdir($compile) {
    for my $index (0 .. $#{$compile->{arguments}} - 1) {
        return $compile->{arguments}[$index + 1]
            if $compile->{arguments}[$index] eq '--Mdir';
    }
    _throw('VIAL_RUN_COMMAND_ERROR', 'compile command has no object directory', '/compile/arguments');
}

sub _capture_process($session, $argv, $timeout, $limit) {
    _throw(
        'VIAL_RUN_TOOL_ERROR',
        'selected tool command is not one non-empty scalar argument vector',
        '/tool',
    ) unless ref($argv) eq 'ARRAY' && @$argv
        && !grep { !defined($_) || ref($_) || /\x00/ } @$argv;
    my ($stdin_reader, $stdin_writer);
    my ($output_reader, $output_writer);
    my ($control_reader, $control_writer);
    pipe($stdin_reader, $stdin_writer)
        or _throw(
            'VIAL_RUN_HOST_ERROR',
            'cannot create selected-tool stdin pipe', '/tool',
        );
    pipe($output_reader, $output_writer)
        or _throw(
            'VIAL_RUN_HOST_ERROR',
            'cannot create selected-tool output pipe', '/tool',
        );
    pipe($control_reader, $control_writer)
        or _throw(
            'VIAL_RUN_HOST_ERROR',
            'cannot create selected-tool exec-control pipe', '/tool',
        );
    my $control_flags = fcntl($control_writer, F_GETFD, 0);
    _throw(
        'VIAL_RUN_HOST_ERROR',
        'cannot inspect selected-tool exec-control pipe', '/tool',
    ) unless defined $control_flags;
    _throw(
        'VIAL_RUN_HOST_ERROR',
        'cannot seal selected-tool exec-control pipe close-on-exec', '/tool',
    ) unless fcntl(
        $control_writer, F_SETFD, $control_flags | FD_CLOEXEC,
    );

    my $started = clock_gettime(CLOCK_MONOTONIC);
    my $pid = fork();
    _throw(
        'VIAL_RUN_HOST_ERROR',
        'cannot fork the selected tool', '/tool',
    ) unless defined $pid;
    if ($pid == 0) {
        close $stdin_writer;
        close $output_reader;
        close $control_reader;
        if ($session->{storage_context}{containment}
                eq 'lifecycle_process_group') {
            unless (eval { setpgid(0, 0); 1 }) {
                _write_child_control(
                    $control_writer,
                    "process-group containment failed: $!",
                );
                _exit(126);
            }
        }
        unless (chdir($session->{repo_root})) {
            _write_child_control(
                $control_writer,
                "repository working-directory handoff failed: $!",
            );
            _exit(126);
        }
        unless (open STDIN, '<&', $stdin_reader) {
            _write_child_control(
                $control_writer, "stdin handoff failed: $!",
            );
            _exit(126);
        }
        unless (open STDOUT, '>&', $output_writer) {
            _write_child_control(
                $control_writer, "stdout handoff failed: $!",
            );
            _exit(126);
        }
        unless (open STDERR, '>&', $output_writer) {
            _write_child_control(
                $control_writer, "stderr handoff failed: $!",
            );
            _exit(126);
        }
        close $stdin_reader;
        close $output_writer;
        {
            no warnings 'exec';
            exec {$argv->[0]} @$argv;
        }
        _write_child_control($control_writer, "exec failed: $!");
        _exit(127);
    }

    close $stdin_reader;
    close $output_writer;
    close $control_writer;
    close $stdin_writer;
    eval { setpgid($pid, $pid); 1 }
        if $session->{storage_context}{containment}
            eq 'lifecycle_process_group';
    for my $fh ($output_reader, $control_reader) {
        my $flags = fcntl($fh, F_GETFL, 0);
        fcntl($fh, F_SETFL, $flags | O_NONBLOCK)
            if defined $flags;
    }
    my $output_fileno = fileno($output_reader);
    my $control_fileno = fileno($control_reader);
    my $select = IO::Select->new($control_reader, $output_reader);
    my ($output, $exec_error) = ('', '');
    my ($timed_out, $limited) = (0, 0);
    my ($exec_handoff, $first_output);
    while ($select->count) {
        my $now = clock_gettime(CLOCK_MONOTONIC);
        if ($now - $started > $timeout) {
            $timed_out = 1;
            last;
        }
        my @ready = sort {
            (fileno($a) == $control_fileno ? 0 : 1)
                <=> (fileno($b) == $control_fileno ? 0 : 1)
        } $select->can_read(0.05);
        for my $fh (@ready) {
            my $chunk = '';
            my $read = sysread($fh, $chunk, 65_536);
            if (defined($read) && $read > 0) {
                if (fileno($fh) == $output_fileno) {
                    $first_output //= clock_gettime(CLOCK_MONOTONIC);
                    $output .= $chunk;
                    if (bytes::length($output) > $limit) {
                        $limited = 1;
                        last;
                    }
                }
                elsif (fileno($fh) == $control_fileno) {
                    $exec_error .= $chunk;
                }
            }
            elsif (defined($read) && $read == 0) {
                $exec_handoff //= clock_gettime(CLOCK_MONOTONIC)
                    if fileno($fh) == $control_fileno
                        && !length($exec_error);
                $select->remove($fh);
                close $fh;
            }
        }
        last if $limited;
    }
    my $status;
    if ($timed_out || $limited) {
        $select->remove($_) for $select->handles;
        close $_ for grep { defined(fileno($_)) }
            ($output_reader, $control_reader);
        my $owns_group =
            $session->{storage_context}{containment}
                eq 'lifecycle_process_group';
        $status = _terminate_process($pid, $owns_group);
    }
    else {
        while (1) {
            my $waited = waitpid($pid, WNOHANG);
            if ($waited == $pid || $waited == -1) {
                $status = $?;
                last;
            }
            if (clock_gettime(CLOCK_MONOTONIC) - $started > $timeout) {
                $timed_out = 1;
                my $owns_group =
                    $session->{storage_context}{containment}
                        eq 'lifecycle_process_group';
                $status = _terminate_process($pid, $owns_group);
                last;
            }
            sleep(0.01);
        }
    }
    my $finished = clock_gettime(CLOCK_MONOTONIC);
    $exec_handoff //= $finished unless length $exec_error;
    $exec_error =~ s/[\r\n\t]+/ /g;
    $exec_error =~ s/\s+/ /g;
    $exec_error = substr($exec_error, 0, 2_048)
        if length($exec_error) > 2_048;
    my $started_ns = int($started * 1_000_000_000);
    my $exec_handoff_ns = defined($exec_handoff)
        ? int($exec_handoff * 1_000_000_000) : undef;
    my $first_output_ns = defined($first_output)
        ? int($first_output * 1_000_000_000) : undef;
    my $finished_ns = int($finished * 1_000_000_000);
    return {
        ok => (!$timed_out && !$limited && !length($exec_error)
                && ($status & 127) == 0)
            ? JSON::PP::true : JSON::PP::false,
        exit_code => ($status & 127)
            ? 128 + ($status & 127) : ($status >> 8),
        signal => $status & 127,
        output => $output,
        timed_out => $timed_out
            ? JSON::PP::true : JSON::PP::false,
        output_limited => $limited
            ? JSON::PP::true : JSON::PP::false,
        exec_failed => length($exec_error)
            ? JSON::PP::true : JSON::PP::false,
        exec_error => length($exec_error) ? $exec_error : undef,
        started_monotonic_ns => $started_ns,
        exec_handoff_monotonic_ns => $exec_handoff_ns,
        first_output_monotonic_ns => $first_output_ns,
        finished_monotonic_ns => $finished_ns,
        spawn_to_exec_ns => defined($exec_handoff_ns)
            ? $exec_handoff_ns - $started_ns : undef,
        execution_ns => defined($exec_handoff_ns)
            ? $finished_ns - $exec_handoff_ns : undef,
        exec_to_first_output_ns =>
            defined($exec_handoff_ns) && defined($first_output_ns)
                ? $first_output_ns - $exec_handoff_ns
                : undef,
        first_output_to_exit_ns => defined($first_output_ns)
            ? $finished_ns - $first_output_ns : undef,
        containment => $session->{storage_context}{containment},
        timeout_seconds => $timeout,
        capture_limit_bytes => $limit,
        output_bytes => bytes::length($output),
    };
}

sub _capture_evidence($capture) {
    return {map { $_ => _clone($capture->{$_}) } qw(
        ok exit_code signal timed_out output_limited exec_failed exec_error
        started_monotonic_ns exec_handoff_monotonic_ns
        first_output_monotonic_ns finished_monotonic_ns spawn_to_exec_ns
        execution_ns exec_to_first_output_ns first_output_to_exit_ns containment
        timeout_seconds capture_limit_bytes output_bytes
    )};
}

sub _write_child_control($fh, $message) {
    $message = substr($message, 0, 2_048);
    my $offset = 0;
    while ($offset < bytes::length($message)) {
        my $written = syswrite(
            $fh, $message, bytes::length($message) - $offset, $offset,
        );
        next if !defined($written) && $! == EINTR;
        last unless defined($written) && $written > 0;
        $offset += $written;
    }
    return;
}

sub _process_succeeded($process) {
    return $process->{ok} && $process->{exit_code} == 0;
}

sub _terminate_process($pid, $process_group) {
    my $target = $process_group ? -$pid : $pid;
    kill 'TERM', $target;
    my $deadline = time() + 2;
    my ($leader_reaped, $leader_status) = (0, undef);
    while (time() < $deadline) {
        unless ($leader_reaped) {
            my $waited = waitpid($pid, WNOHANG);
            if ($waited == $pid || $waited == -1) {
                $leader_reaped = 1;
                $leader_status = $?;
            }
        }
        my $domain_alive = $process_group
            ? kill(0, -$pid)
            : (!$leader_reaped && kill(0, $pid));
        return defined($leader_status) ? $leader_status : 0
            if $leader_reaped && !$domain_alive;
        select undef, undef, undef, 0.02;
    }
    kill 'KILL', $target;
    unless ($leader_reaped) {
        waitpid($pid, 0);
        $leader_status = $?;
    }
    if ($process_group) {
        my $kill_deadline = time() + 2;
        while (kill(0, -$pid) && time() < $kill_deadline) {
            select undef, undef, undef, 0.02;
        }
        _throw(
            'VIAL_RUN_HOST_ERROR',
            'selected-tool process group survived TERM/KILL containment',
            '/tool',
        ) if kill(0, -$pid);
    }
    return defined($leader_status) ? $leader_status : 0;
}

sub _extract_trace($output) {
    if ($output =~ /\r/) {
        my $offset = index($output, "\r");
        my $start = $offset > 16 ? $offset - 16 : 0;
        my $context = unpack('H*', substr($output, $start, 33));
        _throw(
            'VIAL_RUN_RUNTIME_ERROR',
            "runtime output contains a carriage return at byte $offset (hex context $context)",
            '/run/output',
        );
    }
    my @line = split /\n/, $output;
    my (@trace, @json, @ordinary);
    for my $line (@line) {
        if (index($line, $PREFIX) == 0) {
            push @trace, $line;
            push @json, substr($line, length($PREFIX));
        }
        else {
            push @ordinary, $line if length $line;
        }
    }
    _throw('VIAL_RUN_TRACE_ERROR', 'runtime produced no machine trace', '/trace') unless @trace;
    return (join("\n", @trace) . "\n", join("\n", @json) . "\n", \@ordinary);
}

sub _compile_transcript($command, $version) {
    return join("\n",
        'schema: fsmgen.vial_compile_transcript.v1',
        "command-digest: $command->{command_digest}",
        "tool-version: $version",
        'exit-code: 0',
        'diagnostics: none',
        '',
    );
}

sub _process_error_summary($output) {
    my @line = grep { /%(?:Error|Warning)-|%Error:/ } split /\n/, $output;
    @line = grep { length } split /\n/, $output unless @line;
    my @selected = @line ? @line[0 .. (@line > 3 ? 2 : $#line)] : ();
    my $summary = join(' | ', @selected);
    $summary = 'tool returned no diagnostic text' unless length $summary;
    $summary =~ s/[\r\n\t]+/ /g;
    $summary =~ s/\s+/ /g;
    $summary = substr($summary, 0, 2_048) if length($summary) > 2_048;
    return $summary;
}

sub _run_transcript($command, $trace, $ordinary) {
    my $semantic_lines = scalar grep { /\AVIAL / } @$ordinary;
    return join("\n",
        'schema: fsmgen.vial_run_transcript.v1',
        "command-digest: $command->{command_digest}",
        'exit-code: 0',
        "trace-records: $trace->{projection}{record_count}",
        "trace-sha256: $trace->{projection}{trace_sha256}",
        "semantic-diagnostic-lines: $semantic_lines",
        '',
    );
}

sub _decode_artifact($artifact, $relpath) {
    _throw('VIAL_RUN_COMMAND_ERROR', "emission is missing '$relpath'", '/emission/artifacts')
        unless $artifact->{$relpath};
    my $decoded = eval { JSON::PP->new->decode($artifact->{$relpath}{content}) };
    _throw('VIAL_RUN_COMMAND_ERROR', "artifact '$relpath' is not one JSON object", '/emission/artifacts')
        unless defined($decoded) && !$@ && ref($decoded) eq 'HASH' && !blessed($decoded);
    return $decoded;
}

sub _closed_record($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    _throw('VIAL_RUN_COMMAND_ERROR', "$label has an unknown key", '/commands')
        if grep { !$expected{$_} } keys %$value;
    _throw('VIAL_RUN_COMMAND_ERROR', "$label is missing a key", '/commands')
        if grep { !exists($value->{$_}) } @$keys;
}

sub _safe_destination($repo_root, $relative, $root_device) {
    my $path = $repo_root;
    my $existing = $repo_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catfile($path, $part);
        if (-e $path || -l $path) {
            my @stat = lstat($path);
            _throw('VIAL_RUN_PATH_ERROR', "path '$relative' contains an unreadable component", '/cleanup')
                unless @stat;
            _throw('VIAL_RUN_PATH_ERROR', "path '$relative' must not traverse a symlink", '/cleanup') if -l _;
            $existing = $path;
        }
    }
    my @existing_stat = stat($existing);
    _throw('VIAL_RUN_PATH_ERROR', "path '$relative' must remain on the repository filesystem volume", '/cleanup')
        unless @existing_stat && $existing_stat[0] == $root_device;
    return $path;
}

sub _owned_abs($session, $relative) {
    _throw(
        'VIAL_RUN_PATH_ERROR',
        'lifecycle path is outside the exact owned staging root', '/path',
    ) unless defined($relative) && !ref($relative)
        && ($relative eq $session->{stage_rel}
            || index($relative, "$session->{stage_rel}/") == 0);
    return _safe_destination(
        $session->{repo_root}, $relative, $session->{root_device},
    );
}

sub _rel_abs($repo_root, $relative) {
    _throw('VIAL_RUN_PATH_ERROR', 'runtime path is not a safe repository-relative identity', '/path')
        unless defined($relative) && !ref($relative) && length($relative)
            && $relative !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $relative, -1;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub _make_directory($path, $identity) {
    if (-e $path || -l $path) {
        _throw('VIAL_RUN_PATH_ERROR', "path '$identity' must be a non-symlink directory", '/cleanup')
            unless -d $path && !-l $path;
        return;
    }
    eval { make_path($path); 1 }
        or _throw('VIAL_RUN_HOST_ERROR', "cannot create runtime directory '$identity'", '/cleanup');
}

sub _write_exact($path, $content, $identity) {
    sysopen(
        my $fh, $path,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600,
    )
        or _throw('VIAL_RUN_HOST_ERROR', "cannot create runtime input '$identity'", '/compile/inputs');
    binmode($fh, ':raw')
        or _throw('VIAL_RUN_HOST_ERROR', "cannot set raw mode for runtime input '$identity'", '/compile/inputs');
    print {$fh} $content
        or _throw('VIAL_RUN_HOST_ERROR', "cannot write runtime input '$identity'", '/compile/inputs');
    close $fh
        or _throw('VIAL_RUN_HOST_ERROR', "cannot close runtime input '$identity'", '/compile/inputs');
}

sub _artifact($relpath, $kind, $language, $role, $content, $generated_from) {
    return {
        relpath => $relpath,
        kind => $kind,
        language => $language,
        role => $role,
        content => $content,
        encoding => 'utf-8',
        source_layer => 'VIAL_BACKEND',
        generated_from => _clone($generated_from),
    };
}

sub _artifact_ref($artifact) {
    return {
        relpath => $artifact->{relpath},
        kind => $artifact->{kind},
        role => $artifact->{role},
        sha256 => sha256_hex($artifact->{content}),
        bytes => bytes::length($artifact->{content}),
    };
}

sub _json_text($value) {
    my $text = JSON::PP->new->ascii->canonical->pretty->encode($value);
    $text .= "\n" unless $text =~ /\n\z/;
    return $text;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_RUN_INVOCATION_ERROR', "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_RUN_INVOCATION_ERROR', "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::VerilatorLifecycle::Failure';
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown runner host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown runner host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'lifecycle projection contains an unsupported reference' if ref($value);
    return $value;
}

package FSM::VIAL::Backend::VerilatorLifecycle::Failure;

use overload '""' => sub { $_[0]{message} // 'VIAL Verilator lifecycle failure' }, fallback => 1;

1;
