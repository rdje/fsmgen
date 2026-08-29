package FSM::VIAL::Backend::GHDLLifecycle;

use v5.20;
use strict;
use warnings;
use bytes ();
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_WRONLY);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use Time::HiRes qw(time);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::Backend::ProcessSupervisor;
use FSM::VIAL::Backend::VHDLPortableTraceValidator;

my $JSON = JSON::PP->new->canonical(1);
my $LIFECYCLE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle.v1';
my $STATE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle_state.v1';
my $HANDLE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle_handle.v1';
my $STORAGE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle_storage.v1';
my $OWNER_SCHEMA = 'fsmgen.vial_ghdl_lifecycle_owner.v1';
my @STATE_ORDER = qw(
    admitted prepared tool_verified analyzed elaborated ran trace_validated
    result_produced assembled cleaned
);
my %STATE_ORDINAL = map { $STATE_ORDER[$_] => $_ } 0 .. $#STATE_ORDER;
my @RESULT_KEYS = qw(
    ok status lifecycle_identity handle assembled_result stage_evidence
    diagnostics cleanup
);
my @HANDLE_KEYS = qw(
    schema schema_version lifecycle_identity state ordinal state_identity
    state_relpath next_state storage_context
);
my @STATE_KEYS = qw(
    schema schema_version lifecycle_identity state ordinal state_identity
    predecessor_identity predecessor_relpath next_state authority objects
    evidence
);
my @OBJECT_KEYS = qw(kind sha256 bytes executable relative_path);
my @PROVIDER_KEYS = qw(
    root archive archive_bytes archive_sha256 binary binary_sha256
    version_output
);
my @COMMAND_KEYS = qw(version analyze elaborate run);
my @VALIDATION_KEYS = qw(
    expected_record_counts expected_plan_id expected_run_ids
    expected_observation_catalog run_repetitions
);
my @STORAGE_KEYS = qw(
    schema schema_version mode staging_identity containment
);
my @CAPTURE_KEYS = qw(
    ok exit_code signal timed_out output_limited exec_failed exec_error
    started_monotonic_ns exec_handoff_monotonic_ns
    first_output_monotonic_ns finished_monotonic_ns spawn_to_exec_ns
    execution_ns exec_to_first_output_ns first_output_to_exit_ns containment
    timeout_seconds capture_limit_bytes output_bytes
);
my %EVIDENCE_KEYS = (
    admitted => [qw(
        authority_sha256 workspace_files workspace_sha256
    )],
    prepared => [qw(
        library_identity source_count workspace_files workspace_sha256
    )],
    tool_verified => [qw(
        version_sha256 capture workspace_files workspace_sha256
    )],
    analyzed => [qw(
        command_digest capture workspace_files workspace_sha256
    )],
    elaborated => [qw(
        command_digest capture workspace_files workspace_sha256
    )],
    ran => [qw(
        command_digest captures output_sha256 deterministic
        workspace_files workspace_sha256
    )],
    trace_validated => [qw(
        trace_sha256 record_count validation_sha256
        workspace_files workspace_sha256
    )],
    result_produced => [qw(
        result_sha256 result_status workspace_files workspace_sha256
    )],
    assembled => [qw(
        assembly_sha256 object_count workspace_files workspace_sha256
    )],
);
my %AUTHORIZED_CALLER = (
    'FSM::VIAL::Backend::VHDLPortableGHDLQualification' => 'qualification',
    'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement' =>
        'architecture_scale_measurement',
);
my %PHASE_POLICY = (
    tool_verified => [10, 65_536],
    analyzed => [120, 8_388_608],
    elaborated => [60, 8_388_608],
    ran => [30, 67_108_864],
);

sub state_order($class) {
    _exact_class($class, 'state_order');
    return [@STATE_ORDER];
}

sub result_keys($class) {
    _exact_class($class, 'result_keys');
    return [@RESULT_KEYS];
}

sub begin_session($class, @args) {
    my $role = _authorized_role($class, 'begin_session', scalar caller);
    return _failure('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL lifecycle admission is caller-sealed', '/', undef)
        unless defined $role;
    return _failure('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'begin_session expects one closed argument hash', '/', undef)
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $session;
    my $result = eval {
        $session = _session($args[0], $role);
        _begin($session);
    };
    return $result if defined $result;
    return _exception($@, $session);
}

sub advance_session($class, @args) {
    my $role = _authorized_role($class, 'advance_session', scalar caller);
    return _failure('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL lifecycle advancement is caller-sealed', '/', undef)
        unless defined $role;
    return _failure('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'advance_session expects one closed argument hash', '/', undef)
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $session;
    my $result = eval {
        _session_with_handle($args[0], $role, \$session);
        my $target = $session->{handle}{next_state};
        _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
            'assembled lifecycle must be finished, not advanced',
            '/handle/next_state') if !defined($target) || $target eq 'cleaned';
        _advance($session, $target);
    };
    return $result if defined $result;
    return _exception($@, $session);
}

sub finish_session($class, @args) {
    my $role = _authorized_role($class, 'finish_session', scalar caller);
    return _failure('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL lifecycle finish is caller-sealed', '/', undef)
        unless defined $role;
    return _failure('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'finish_session expects one closed argument hash', '/', undef)
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $session;
    my $result = eval {
        _session_with_handle($args[0], $role, \$session);
        _finish($session);
    };
    return $result if defined $result;
    return _exception($@, $session);
}

sub abort_session($class, @args) {
    my $role = _authorized_role($class, 'abort_session', scalar caller);
    return _failure('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL lifecycle abort is caller-sealed', '/', undef)
        unless defined $role;
    return _failure('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'abort_session expects one closed argument hash', '/', undef)
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $session;
    my $result = eval {
        _session_with_handle($args[0], $role, \$session);
        _remove_owned_root($session);
        _result($session, 'aborted_cleaned', undef, {
            removed => JSON::PP::true, residue => [],
        });
    };
    return $result if defined $result;
    return _exception($@, $session);
}

sub _authorized_role($class, $method, $caller) {
    return undef unless defined($class) && !ref($class)
        && $class eq __PACKAGE__;
    return $AUTHORIZED_CALLER{$caller};
}

sub _session_with_handle($raw, $role, $session_out) {
    _closed($raw, [qw(
        repo_root provider source_set source_identity emission_identity
        commands validation storage_context handle
    )], 'GHDL lifecycle resume request');
    my $copy = _clone($raw);
    my $handle = delete $copy->{handle};
    my $session = _session($copy, $role, 0);
    $$session_out = $session;
    _closed($handle, \@HANDLE_KEYS, 'GHDL lifecycle handle');
    $session->{handle} = $handle;
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'lifecycle handle schema or authority differs', '/handle')
        unless ($handle->{schema} // '') eq $HANDLE_SCHEMA
            && ($handle->{schema_version} // 0) == 1
            && ($handle->{lifecycle_identity} // '')
                eq $session->{lifecycle_identity}
            && _canonical($handle->{storage_context})
                eq _canonical($session->{storage_context});
    my $state = $handle->{state};
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle handle state or successor is invalid', '/handle')
        unless defined($state) && exists($STATE_ORDINAL{$state})
            && $state ne 'cleaned'
            && ($handle->{ordinal} // -1) == $STATE_ORDINAL{$state}
            && ($handle->{next_state} // '')
                eq ($STATE_ORDER[$STATE_ORDINAL{$state} + 1] // '')
            && ($handle->{state_identity} // '')
                =~ m{\Astate/[0-9a-f]{64}\z}
            && ($handle->{state_relpath} // '') =~
                m{\A\Q$session->{stage_rel}\E/states/[0-9]{2}-[a-z_]+-[0-9a-f]{64}[.]json\z};
    $session->{cleanup_on_error} = 1;
    _validate_current_provider($session);
    _validate_current_sources($session);
    _load_chain($session, $handle);
    return $session;
}

sub _session($raw, $role, $validate_inputs = 1) {
    _closed($raw, [qw(
        repo_root provider source_set source_identity emission_identity
        commands validation storage_context
    )], 'GHDL lifecycle request');
    my $repo_root = abs_path($raw->{repo_root});
    _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
        'repository root is not one readable non-symlink directory',
        '/repo_root') unless defined($repo_root) && -d $repo_root
            && !-l $repo_root;
    my @root_stat = stat($repo_root);
    _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
        'repository filesystem identity is unavailable', '/repo_root')
        unless @root_stat;
    my $provider = _validated_provider(
        $repo_root, $root_stat[0], $raw->{provider}, $validate_inputs,
    );
    my $source_set = _validated_sources(
        $repo_root, $root_stat[0], $raw->{source_set}, $validate_inputs,
    );
    my %identity_kind = (
        source_identity => 'source', emission_identity => 'emission',
    );
    for my $field (qw(source_identity emission_identity)) {
        my $kind = $identity_kind{$field};
        _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
            "$field is not one content identity", "/$field")
            unless defined($raw->{$field}) && !ref($raw->{$field})
                && $raw->{$field} =~
                    /\A\Q$kind\E\/[0-9a-f]{64}\z/;
    }
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'source identity does not authenticate the ordered source set',
        '/source_identity') unless $raw->{source_identity} eq
            'source/' . sha256_hex(_canonical($source_set));
    my $storage = _validated_storage($raw->{storage_context}, $role);
    my $commands = _validated_commands(
        $raw->{commands}, $provider->{binary}, $storage->{staging_identity},
        $source_set,
    );
    my $validation = _validated_validation($raw->{validation});
    my $authority = {
        schema => $LIFECYCLE_SCHEMA,
        schema_version => 1,
        role => $role,
        provider => $provider,
        source_set => $source_set,
        source_identity => $raw->{source_identity},
        emission_identity => $raw->{emission_identity},
        commands => $commands,
        validation => $validation,
        storage_context => $storage,
    };
    my $lifecycle_identity = 'lifecycle/' . sha256_hex(_canonical($authority));
    my $stage_rel = $storage->{staging_identity};
    return {
        repo_root => $repo_root,
        root_device => $root_stat[0],
        authority => $authority,
        lifecycle_identity => $lifecycle_identity,
        provider => $provider,
        source_set => $source_set,
        commands => $commands,
        validation => $validation,
        storage_context => $storage,
        stage_rel => $stage_rel,
        stage_abs => _repo_path($repo_root, $stage_rel),
        library_rel => "$stage_rel/library",
        library_abs => _repo_path($repo_root, "$stage_rel/library"),
        objects => [],
        state => undef,
        handle => undef,
        cleanup_on_error => 0,
    };
}

sub _validated_provider($repo_root, $root_device, $raw, $validate_inputs) {
    _closed($raw, \@PROVIDER_KEYS, 'GHDL provider authority');
    for my $field (qw(root archive binary)) {
        _safe_relpath($raw->{$field}, "/provider/$field");
    }
    for my $field (qw(archive_sha256 binary_sha256)) {
        _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
            "provider $field is not one SHA-256 digest", "/provider/$field")
            unless defined($raw->{$field}) && !ref($raw->{$field})
                && $raw->{$field} =~ /\A[0-9a-f]{64}\z/;
    }
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'provider archive byte size is not one positive integer',
        '/provider/archive_bytes')
        unless defined($raw->{archive_bytes}) && !ref($raw->{archive_bytes})
            && $raw->{archive_bytes} =~ /\A[1-9][0-9]*\z/;
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'provider version output is not one scalar', '/provider/version_output')
        unless defined($raw->{version_output}) && !ref($raw->{version_output});
    _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
        'provider binary is outside its exact provider root',
        '/provider/binary') unless index($raw->{binary}, "$raw->{root}/") == 0;
    if ($validate_inputs) {
        my $probe = {
            repo_root => $repo_root, root_device => $root_device,
            provider => $raw,
        };
        _validate_current_provider($probe);
    }
    return _clone($raw);
}

sub _validated_sources($repo_root, $root_device, $raw, $validate_inputs) {
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL source set must be one nonempty ordered array', '/source_set')
        unless ref($raw) eq 'ARRAY' && @$raw;
    my (%seen, @source);
    for my $index (0 .. $#$raw) {
        my $entry = $raw->[$index];
        _closed($entry, [qw(relpath bytes sha256)], "GHDL source $index");
        _safe_relpath($entry->{relpath}, "/source_set/$index/relpath");
        _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
            'GHDL source identity is duplicated', "/source_set/$index")
            if $seen{$entry->{relpath}}++;
        _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
            'GHDL source byte size is invalid', "/source_set/$index/bytes")
            unless defined($entry->{bytes}) && !ref($entry->{bytes})
                && $entry->{bytes} =~ /\A(?:0|[1-9][0-9]*)\z/;
        _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
            'GHDL source digest is invalid', "/source_set/$index/sha256")
            unless defined($entry->{sha256}) && !ref($entry->{sha256})
                && $entry->{sha256} =~ /\A[0-9a-f]{64}\z/;
        push @source, _clone($entry);
    }
    if ($validate_inputs) {
        _validate_current_sources({
            repo_root => $repo_root, root_device => $root_device,
            source_set => \@source,
        });
    }
    return \@source;
}

sub _validated_storage($raw, $role) {
    _closed($raw, \@STORAGE_KEYS, 'GHDL storage context');
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL storage schema is not exact', '/storage_context/schema')
        unless ($raw->{schema} // '') eq $STORAGE_SCHEMA
            && ($raw->{schema_version} // 0) == 1;
    my %expected = (
        qualification => [
            'qualification', 'lifecycle_process_group',
            qr{\A[.]artifacts/tmp/vial-ghdl-qualification/[0-9a-f]{64}\z},
        ],
        architecture_scale_measurement => [
            'architecture_scale_measurement', 'outer_worker_process_group',
            qr{\A[.]artifacts/tmp/vial-scale/[0-9a-f]{64}/validation/[0-9]{2}/lifecycle\z},
        ],
    );
    my ($mode, $containment, $pattern) = @{$expected{$role}};
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL storage context differs from caller authority',
        '/storage_context') unless ($raw->{mode} // '') eq $mode
            && ($raw->{containment} // '') eq $containment
            && defined($raw->{staging_identity})
            && !ref($raw->{staging_identity})
            && $raw->{staging_identity} =~ $pattern;
    _safe_relpath($raw->{staging_identity},
        '/storage_context/staging_identity');
    return _clone($raw);
}

sub _validated_commands($raw, $binary, $stage_rel, $source_set) {
    _closed($raw, \@COMMAND_KEYS, 'GHDL command authority');
    my %mode = (version => '--version', analyze => '-a',
        elaborate => '-e', run => '-r');
    for my $name (@COMMAND_KEYS) {
        my $argv = $raw->{$name};
        _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
            "GHDL $name command is not one scalar argument vector",
            "/commands/$name") unless ref($argv) eq 'ARRAY' && @$argv >= 2
                && !grep { !defined($_) || ref($_) || /\x00/ } @$argv;
        _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
            "GHDL $name command executable or mode differs",
            "/commands/$name") unless $argv->[0] eq $binary
                && $argv->[1] eq $mode{$name};
        next if $name eq 'version';
        _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
            "GHDL $name command changed its language or work authority",
            "/commands/$name") unless grep({ $_ eq '--std=08' } @$argv) == 1
                && grep({ $_ eq '--work=fsmgen_vial' } @$argv) == 1;
        my @workdir = grep { index($_, '--workdir=') == 0 } @$argv;
        _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
            "GHDL $name command has a foreign work directory",
            "/commands/$name") unless @workdir == 1
                && $workdir[0] eq "--workdir=$stage_rel/library";
    }
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'GHDL version command is not exact', '/commands/version')
        unless @{$raw->{version}} == 2;
    my @source = map { $_->{relpath} } @$source_set;
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'GHDL analysis command is too short for its exact source set',
        '/commands/analyze') unless @{$raw->{analyze}} >= @source + 5;
    my @analysis_tail = @{$raw->{analyze}}[-@source .. -1];
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'GHDL analysis command does not bind the exact ordered source set',
        '/commands/analyze') unless
            _canonical(\@analysis_tail) eq _canonical(\@source);
    my $top = $raw->{elaborate}[-1];
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'GHDL elaboration top is not one safe exact identity',
        '/commands/elaborate') unless defined($top) && !ref($top)
            && $top =~ /\A[A-Za-z][A-Za-z0-9_]*\z/;
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'GHDL run command does not bind the elaborated top and assertion policy',
        '/commands/run') unless @{$raw->{run}} >= 7
            && $raw->{run}[-2] eq $top
            && $raw->{run}[-1] eq '--assert-level=error';
    return _clone($raw);
}

sub _validated_validation($raw) {
    _closed($raw, \@VALIDATION_KEYS, 'GHDL validation authority');
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL run repetition count must be one or two',
        '/validation/run_repetitions')
        unless defined($raw->{run_repetitions})
            && !ref($raw->{run_repetitions})
            && $raw->{run_repetitions} =~ /\A[12]\z/;
    my $probe = FSM::VIAL::Backend::VHDLPortableTraceValidator->validate({
        trace_text => "invalid\n",
        expected_record_counts => $raw->{expected_record_counts},
        expected_plan_id => $raw->{expected_plan_id},
        expected_run_ids => $raw->{expected_run_ids},
        expected_observation_catalog => $raw->{expected_observation_catalog},
    });
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        $probe->{diagnostics}[0]{message}, '/validation')
        if $probe->{diagnostics}[0]{code} =~ /(?:INVOCATION|SHAPE|CATALOG)/;
    return _clone($raw);
}

sub _begin($session) {
    _throw('VIAL_GHDL_LIFECYCLE_COLLISION',
        "GHDL lifecycle root '$session->{stage_rel}' already exists",
        '/storage_context/staging_identity')
        if -e $session->{stage_abs} || -l $session->{stage_abs};
    my $created = 0;
    my $ok = eval {
        make_path($session->{stage_abs});
        $created = 1;
        my @stat = stat($session->{stage_abs});
        _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
            'GHDL lifecycle root crossed the repository volume',
            '/storage_context/staging_identity')
            unless @stat && -d _ && !-l $session->{stage_abs}
                && $stat[0] == $session->{root_device};
        my $owner = {
            schema => $OWNER_SCHEMA,
            schema_version => 1,
            lifecycle_identity => $session->{lifecycle_identity},
            staging_identity => $session->{stage_rel},
        };
        _write_atomic("$session->{stage_abs}/.owner.json",
            _canonical($owner) . "\n");
        my $authority = _write_object(
            $session, 'lifecycle_authority',
            _canonical($session->{authority}) . "\n", 0,
        );
        $session->{objects} = [$authority];
        _persist($session, 'admitted', undef, {
            authority_sha256 => sha256_hex(_canonical($session->{authority})),
            _workspace_evidence($session),
        });
        1;
    };
    unless ($ok) {
        my $error = $@;
        if ($created && -d $session->{stage_abs} && !-l $session->{stage_abs}) {
            my $errors;
            remove_tree($session->{stage_abs}, {error => \$errors});
        }
        die $error;
    }
    return _result($session, 'admitted', undef, undef);
}

sub _advance($session, $target) {
    my $current = $session->{handle}{state};
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle successor is not exact', '/handle/next_state')
        unless defined($target) && exists($STATE_ORDINAL{$target})
            && $STATE_ORDINAL{$target} == $STATE_ORDINAL{$current} + 1;
    my %phase = (
        prepared => \&_phase_prepared,
        tool_verified => \&_phase_tool_verified,
        analyzed => \&_phase_analyzed,
        elaborated => \&_phase_elaborated,
        ran => \&_phase_ran,
        trace_validated => \&_phase_trace_validated,
        result_produced => \&_phase_result_produced,
        assembled => \&_phase_assembled,
    );
    my $evidence = $phase{$target}->($session);
    _persist($session, $target, $session->{state}, $evidence);
    return _result($session, $target, undef, undef);
}

sub _phase_prepared($session) {
    make_path($session->{library_abs});
    my @stat = stat($session->{library_abs});
    _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
        'GHDL work library is not one same-volume owned directory',
        '/prepared/library') unless @stat && -d _
            && !-l $session->{library_abs}
            && $stat[0] == $session->{root_device};
    return {
        library_identity => $session->{library_rel},
        source_count => scalar(@{$session->{source_set}}),
        _workspace_evidence($session),
    };
}

sub _phase_tool_verified($session) {
    my $capture = _run_phase($session, 'tool_verified',
        $session->{commands}{version});
    my $normalized = $capture->{output};
    $normalized =~ s/[\r\n]+\z//;
    _throw('VIAL_GHDL_LIFECYCLE_TOOL_ERROR',
        'installed GHDL version differs from caller authority',
        '/tool_verified/version')
        unless $normalized eq $session->{provider}{version_output};
    push @{$session->{objects}}, _write_object(
        $session, 'tool_version_output', $capture->{output}, 0,
    );
    return {
        version_sha256 => sha256_hex($capture->{output}),
        capture => _capture_evidence($capture),
        _workspace_evidence($session),
    };
}

sub _phase_analyzed($session) {
    my $capture = _run_phase(
        $session, 'analyzed', $session->{commands}{analyze},
    );
    push @{$session->{objects}}, _write_object(
        $session, 'analysis_output', $capture->{output}, 0,
    );
    return {
        command_digest => _command_digest($session->{commands}{analyze}),
        capture => _capture_evidence($capture),
        _workspace_evidence($session),
    };
}

sub _phase_elaborated($session) {
    my $capture = _run_phase(
        $session, 'elaborated', $session->{commands}{elaborate},
    );
    push @{$session->{objects}}, _write_object(
        $session, 'elaboration_output', $capture->{output}, 0,
    );
    return {
        command_digest => _command_digest($session->{commands}{elaborate}),
        capture => _capture_evidence($capture),
        _workspace_evidence($session),
    };
}

sub _phase_ran($session) {
    my (@captures, @digests);
    for my $index (0 .. $session->{validation}{run_repetitions} - 1) {
        my $capture = _run_phase(
            $session, 'ran', $session->{commands}{run},
        );
        push @captures, _capture_evidence($capture);
        push @digests, sha256_hex($capture->{output});
        push @{$session->{objects}}, _write_object(
            $session, "runtime_output_$index", $capture->{output}, 0,
        );
    }
    _throw('VIAL_GHDL_LIFECYCLE_DETERMINISM_ERROR',
        'identical GHDL runtime repetitions differ', '/ran')
        if @digests == 2 && $digests[0] ne $digests[1];
    return {
        command_digest => _command_digest($session->{commands}{run}),
        captures => \@captures,
        output_sha256 => \@digests,
        deterministic => @digests == 2
            ? JSON::PP::true : JSON::PP::false,
        _workspace_evidence($session),
    };
}

sub _phase_trace_validated($session) {
    my $output = _object_content($session, 'runtime_output_0');
    my @trace = grep { index($_, "FSMGEN_VIAL_TRACE_V2\t") == 0 }
        split /\r?\n/, $output;
    my $trace_text = @trace ? join("\n", @trace) . "\n" : '';
    my $validated = FSM::VIAL::Backend::VHDLPortableTraceValidator->validate({
        trace_text => $trace_text,
        expected_record_counts =>
            $session->{validation}{expected_record_counts},
        expected_plan_id => $session->{validation}{expected_plan_id},
        expected_run_ids => $session->{validation}{expected_run_ids},
        expected_observation_catalog =>
            $session->{validation}{expected_observation_catalog},
    });
    _throw('VIAL_GHDL_LIFECYCLE_TRACE_ERROR',
        $validated->{diagnostics}[0]{message},
        $validated->{diagnostics}[0]{path}) unless $validated->{ok};
    push @{$session->{objects}}, _write_object(
        $session, 'validated_trace', _canonical($validated) . "\n", 0,
    );
    return {
        trace_sha256 => $validated->{trace}{trace_sha256},
        record_count => 0 + $validated->{trace}{record_count},
        validation_sha256 => sha256_hex(_canonical($validated)),
        _workspace_evidence($session),
    };
}

sub _phase_result_produced($session) {
    my $output = _object_content($session, 'runtime_output_0');
    my @result = map {
        substr($_, length("FSMGEN_VIAL_RESULT_V1\t"))
    } grep { index($_, "FSMGEN_VIAL_RESULT_V1\t") == 0 }
        split /\r?\n/, $output;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime must emit exactly one normalized result record',
        '/result_produced') unless @result == 1;
    my $decoded = eval { $JSON->decode($result[0]) };
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result is malformed', '/result_produced')
        unless defined($decoded) && !$@ && ref($decoded) eq 'HASH'
            && !blessed($decoded);
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime normalized result did not pass', '/result_produced')
        unless ($decoded->{schema} // '')
                eq 'fsmgen.verification_result_manifest.v1'
            && ($decoded->{schema_version} // 0) == 1
            && ($decoded->{status} // '') eq 'pass';
    push @{$session->{objects}}, _write_object(
        $session, 'normalized_result', _canonical($decoded) . "\n", 0,
    );
    return {
        result_sha256 => sha256_hex(_canonical($decoded)),
        result_status => 'pass',
        _workspace_evidence($session),
    };
}

sub _phase_assembled($session) {
    my $assembly = {
        schema => 'fsmgen.vial_ghdl_lifecycle_assembly.v1',
        schema_version => 1,
        lifecycle_identity => $session->{lifecycle_identity},
        runtime_output_sha256 =>
            _object_by_kind($session->{objects}, 'runtime_output_0')->{sha256},
        trace_validation_sha256 =>
            _object_by_kind($session->{objects}, 'validated_trace')->{sha256},
        normalized_result_sha256 =>
            _object_by_kind($session->{objects}, 'normalized_result')->{sha256},
    };
    push @{$session->{objects}}, _write_object(
        $session, 'assembly_payload', _canonical($assembly) . "\n", 0,
    );
    return {
        assembly_sha256 => sha256_hex(_canonical($assembly)),
        object_count => scalar(@{$session->{objects}}),
        _workspace_evidence($session),
    };
}

sub _run_phase($session, $phase, $argv) {
    _validate_current_sources($session);
    my ($timeout, $limit) = @{$PHASE_POLICY{$phase}};
    my @actual = @$argv;
    $actual[0] = _repo_path($session->{repo_root}, $actual[0]);
    my $capture = eval {
        my $policy = FSM::VIAL::Backend::ProcessSupervisor->policy(
            $session->{storage_context}{containment}, $timeout, $limit,
        );
        FSM::VIAL::Backend::ProcessSupervisor->capture({
            working_directory => $session->{repo_root},
            argv => \@actual,
            policy => $policy,
        });
    };
    unless (defined $capture) {
        my $error = $@;
        my $message = blessed($error)
            && $error->isa('FSM::VIAL::Backend::ProcessSupervisor::Failure')
            ? $error->{message} : _sanitize($error);
        _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR', $message, "/$phase");
    }
    _throw('VIAL_GHDL_LIFECYCLE_TIMEOUT',
        "GHDL $phase exceeded its exact deadline", "/$phase")
        if $capture->{timed_out};
    _throw('VIAL_GHDL_LIFECYCLE_LIMIT_ERROR',
        "GHDL $phase exceeded its exact capture ceiling", "/$phase")
        if $capture->{output_limited};
    _throw('VIAL_GHDL_LIFECYCLE_EXECUTION_ERROR',
        "GHDL $phase failed: " . _process_summary($capture), "/$phase")
        unless $capture->{ok} && $capture->{exit_code} == 0
            && $capture->{signal} == 0;
    return $capture;
}

sub _finish($session) {
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'only the exact assembled state may finish', '/handle/state')
        unless $session->{handle}{state} eq 'assembled'
            && ($session->{handle}{next_state} // '') eq 'cleaned';
    my $assembled = {
        runtime_outputs => [map {
            _object_content($session, "runtime_output_$_")
        } 0 .. $session->{validation}{run_repetitions} - 1],
        trace_validation => $JSON->decode(
            _object_content($session, 'validated_trace'),
        ),
        normalized_result => $JSON->decode(
            _object_content($session, 'normalized_result'),
        ),
    };
    _remove_owned_root($session);
    my $cleaned = {
        schema => $HANDLE_SCHEMA,
        schema_version => 1,
        lifecycle_identity => $session->{lifecycle_identity},
        state => 'cleaned', ordinal => $STATE_ORDINAL{cleaned},
        state_identity => 'state/' . sha256_hex(_canonical({
            lifecycle_identity => $session->{lifecycle_identity},
            predecessor_identity => $session->{handle}{state_identity},
            state => 'cleaned',
        })),
        state_relpath => undef, next_state => undef,
        storage_context => _clone($session->{storage_context}),
    };
    $session->{handle} = $cleaned;
    return _result($session, 'cleaned', $assembled, {
        removed => JSON::PP::true, residue => [],
    });
}

sub _persist($session, $state_name, $predecessor, $evidence) {
    my $ordinal = $STATE_ORDINAL{$state_name};
    my $record = {
        schema => $STATE_SCHEMA,
        schema_version => 1,
        lifecycle_identity => $session->{lifecycle_identity},
        state => $state_name,
        ordinal => $ordinal,
        state_identity => undef,
        predecessor_identity => defined($predecessor)
            ? $predecessor->{state_identity} : undef,
        predecessor_relpath => defined($predecessor)
            ? $session->{handle}{state_relpath} : undef,
        next_state => $STATE_ORDER[$ordinal + 1],
        authority => _clone($session->{authority}),
        objects => _clone($session->{objects}),
        evidence => _clone($evidence),
    };
    my $digest = sha256_hex(_canonical($record));
    $record->{state_identity} = "state/$digest";
    my $relative = sprintf(
        '%s/states/%02d-%s-%s.json', $session->{stage_rel}, $ordinal,
        $state_name, $digest,
    );
    my $absolute = _repo_path($session->{repo_root}, $relative);
    make_path(dirname($absolute));
    _throw('VIAL_GHDL_LIFECYCLE_COLLISION',
        'content-addressed GHDL state already exists', '/state')
        if -e $absolute || -l $absolute;
    _write_atomic($absolute, _canonical($record) . "\n");
    $session->{state} = $record;
    $session->{handle} = {
        schema => $HANDLE_SCHEMA,
        schema_version => 1,
        lifecycle_identity => $session->{lifecycle_identity},
        state => $state_name,
        ordinal => $ordinal,
        state_identity => $record->{state_identity},
        state_relpath => $relative,
        next_state => $record->{next_state},
        storage_context => _clone($session->{storage_context}),
    };
}

sub _load_chain($session, $handle) {
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle handle state is invalid', '/handle/state')
        unless defined($handle->{state})
            && exists($STATE_ORDINAL{$handle->{state}})
            && $handle->{state} ne 'cleaned'
            && ($handle->{ordinal} // -1)
                == $STATE_ORDINAL{$handle->{state}};
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle owner does not match', '/handle')
        unless _owner_matches($session);
    my $states_abs = "$session->{stage_abs}/states";
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle state directory is absent', '/state')
        unless -d $states_abs && !-l $states_abs;
    opendir my $dh, $states_abs
        or _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
            'cannot inspect GHDL lifecycle states', '/state');
    my @name = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle state tree is partial or has extra entries', '/state')
        unless @name == $handle->{ordinal} + 1;
    my @chain;
    for my $ordinal (0 .. $handle->{ordinal}) {
        my $name = $name[$ordinal];
        my ($file_ordinal, $file_state, $file_digest) =
            $name =~ /\A([0-9]{2})-([a-z_]+)-([0-9a-f]{64})[.]json\z/;
        _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
            'GHDL lifecycle state filename is foreign', '/state')
            unless defined($file_ordinal) && 0 + $file_ordinal == $ordinal
                && $file_state eq $STATE_ORDER[$ordinal];
        my $relative = "$session->{stage_rel}/states/$name";
        my $record = _read_state($session, $relative);
        _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
            'GHDL lifecycle state order or successor changed', '/state')
            unless $record->{ordinal} == $ordinal
                && $record->{state} eq $STATE_ORDER[$ordinal]
                && ($record->{next_state} // '')
                    eq ($STATE_ORDER[$ordinal + 1] // '');
        _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
            'GHDL lifecycle filename does not bind its content identity',
            '/state_identity')
            unless $file_digest
                eq substr($record->{state_identity}, length('state/'));
        if ($ordinal == 0) {
            _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
                'admitted GHDL state has a predecessor', '/state')
                if defined($record->{predecessor_identity})
                    || defined($record->{predecessor_relpath});
        }
        else {
            _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
                'GHDL predecessor chain changed', '/state')
                unless ($record->{predecessor_identity} // '')
                        eq $chain[-1]{state_identity}
                    && ($record->{predecessor_relpath} // '')
                        eq "$session->{stage_rel}/states/$name[$ordinal - 1]";
        }
        push @chain, $record;
    }
    my $current = $chain[-1];
    my $expected_rel = "$session->{stage_rel}/states/$name[-1]";
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle handle and current state differ', '/handle')
        unless ($handle->{state_identity} // '') eq $current->{state_identity}
            && ($handle->{state_relpath} // '') eq $expected_rel
            && ($handle->{next_state} // '') eq ($current->{next_state} // '');
    _validate_objects($session, $current->{objects});
    _validate_workspace($session, $current->{evidence});
    $session->{objects} = _clone($current->{objects});
    $session->{state} = _clone($current);
    return $current;
}

sub _read_state($session, $relative) {
    my $absolute = _repo_path($session->{repo_root}, $relative);
    _regular_same_volume($absolute, $relative, $session->{root_device});
    my $text = _slurp($absolute);
    my $record = eval { $JSON->decode($text) };
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle state is malformed', '/state')
        unless defined($record) && !$@ && ref($record) eq 'HASH'
            && !blessed($record) && $text eq _canonical($record) . "\n";
    _closed($record, \@STATE_KEYS, 'GHDL lifecycle state');
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle state schema or authority changed', '/state')
        unless ($record->{schema} // '') eq $STATE_SCHEMA
            && ($record->{schema_version} // 0) == 1
            && ($record->{lifecycle_identity} // '')
                eq $session->{lifecycle_identity}
            && _canonical($record->{authority})
                eq _canonical($session->{authority});
    my $identity = $record->{state_identity};
    my $copy = _clone($record);
    $copy->{state_identity} = undef;
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle state content identity changed', '/state_identity')
        unless ($identity // '') eq 'state/' . sha256_hex(_canonical($copy));
    _validate_state_shape($session, $record);
    return $record;
}

sub _validate_state_shape($session, $record) {
    my $state = $record->{state};
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL lifecycle state name is outside the closed order', '/state')
        unless defined($state) && exists($STATE_ORDINAL{$state})
            && $state ne 'cleaned';
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'GHDL lifecycle state object inventory is invalid', '/objects')
        unless ref($record->{objects}) eq 'ARRAY';
    _closed(
        $record->{evidence}, $EVIDENCE_KEYS{$state},
        "GHDL $state evidence",
    );
    my @expected = qw(lifecycle_authority);
    push @expected, 'tool_version_output'
        if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{tool_verified};
    push @expected, 'analysis_output'
        if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{analyzed};
    push @expected, 'elaboration_output'
        if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{elaborated};
    if ($STATE_ORDINAL{$state} >= $STATE_ORDINAL{ran}) {
        push @expected, map { "runtime_output_$_" }
            0 .. $session->{validation}{run_repetitions} - 1;
    }
    push @expected, 'validated_trace'
        if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{trace_validated};
    push @expected, 'normalized_result'
        if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{result_produced};
    push @expected, 'assembly_payload'
        if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{assembled};
    my @actual = map { $_->{kind} } @{$record->{objects}};
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'GHDL state object inventory is not exact', '/objects')
        unless _canonical(\@actual) eq _canonical(\@expected);
    if ($state =~ /\A(?:tool_verified|analyzed|elaborated)\z/) {
        _closed($record->{evidence}{capture}, \@CAPTURE_KEYS,
            "GHDL $state capture");
    }
    if ($state eq 'ran') {
        _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
            'GHDL run capture cardinality is not exact', '/evidence/captures')
            unless ref($record->{evidence}{captures}) eq 'ARRAY'
                && @{$record->{evidence}{captures}}
                    == $session->{validation}{run_repetitions};
        _closed($_, \@CAPTURE_KEYS, 'GHDL run capture')
            for @{$record->{evidence}{captures}};
    }
}

sub _write_object($session, $kind, $content, $executable) {
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'GHDL object kind is invalid', '/objects')
        unless defined($kind) && !ref($kind)
            && $kind =~ /\A[a-z][a-z0-9_]*\z/;
    my $digest = sha256_hex($content);
    my $relative = "$session->{stage_rel}/objects/$digest";
    my $absolute = _repo_path($session->{repo_root}, $relative);
    make_path(dirname($absolute));
    if (-e $absolute || -l $absolute) {
        _regular_same_volume($absolute, $relative, $session->{root_device});
        _throw('VIAL_GHDL_LIFECYCLE_COLLISION',
            'GHDL content-object collision changed bytes', '/objects')
            unless -s $absolute == bytes::length($content)
                && _file_sha256($absolute) eq $digest;
    }
    else {
        _write_atomic($absolute, $content);
        chmod($executable ? 0700 : 0600, $absolute)
            or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
                'cannot seal GHDL content-object permissions', '/objects');
    }
    return {
        kind => $kind,
        sha256 => $digest,
        bytes => bytes::length($content),
        executable => $executable ? JSON::PP::true : JSON::PP::false,
        relative_path => $relative,
    };
}

sub _validate_objects($session, $objects) {
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'GHDL object inventory is invalid', '/objects')
        unless ref($objects) eq 'ARRAY' && @$objects;
    my %kind;
    for my $object (@$objects) {
        _closed($object, \@OBJECT_KEYS, 'GHDL lifecycle object');
        _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
            'GHDL object kind is duplicated', '/objects')
            if $kind{$object->{kind}}++;
        my $expected = "$session->{stage_rel}/objects/$object->{sha256}";
        _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
            'GHDL object identity or path is invalid', '/objects')
            unless ($object->{sha256} // '') =~ /\A[0-9a-f]{64}\z/
                && ($object->{relative_path} // '') eq $expected;
        my $absolute = _repo_path($session->{repo_root}, $expected);
        _regular_same_volume($absolute, $expected, $session->{root_device});
        _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
            'GHDL content object changed after sealing', '/objects')
            unless -s $absolute == $object->{bytes}
                && _file_sha256($absolute) eq $object->{sha256};
    }
    my $objects_abs = "$session->{stage_abs}/objects";
    opendir my $dh, $objects_abs
        or _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
            'cannot inspect GHDL content-object tree', '/objects');
    my @actual = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    my %expected = map { $_->{sha256} => 1 } @$objects;
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'GHDL content-object tree has extra or missing entries', '/objects')
        unless @actual == keys(%expected)
            && !grep { !$expected{$_} } @actual;
}

sub _object_by_kind($objects, $kind) {
    my @found = grep { $_->{kind} eq $kind } @$objects;
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        "GHDL object '$kind' is absent or duplicated", '/objects')
        unless @found == 1;
    return $found[0];
}

sub _object_content($session, $kind) {
    my $object = _object_by_kind($session->{objects}, $kind);
    my $content = _slurp(
        _repo_path($session->{repo_root}, $object->{relative_path}),
    );
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        "GHDL object '$kind' changed after sealing", '/objects')
        unless bytes::length($content) == $object->{bytes}
            && sha256_hex($content) eq $object->{sha256};
    return $content;
}

sub _workspace_evidence($session) {
    my $files = _workspace_files($session);
    return (
        workspace_files => $files,
        workspace_sha256 => sha256_hex(_canonical($files)),
    );
}

sub _validate_workspace($session, $evidence) {
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'GHDL state has no workspace evidence', '/state/evidence')
        unless ref($evidence) eq 'HASH'
            && ref($evidence->{workspace_files}) eq 'ARRAY'
            && defined($evidence->{workspace_sha256});
    my $files = _workspace_files($session);
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'GHDL work library changed after state sealing', '/workspace')
        unless _canonical($files) eq _canonical($evidence->{workspace_files})
            && sha256_hex(_canonical($files))
                eq $evidence->{workspace_sha256};
}

sub _workspace_files($session) {
    return [] unless -d $session->{library_abs}
        && !-l $session->{library_abs};
    my @files;
    _walk_files($session, $session->{library_abs}, '', \@files);
    return [sort { $a->{relpath} cmp $b->{relpath} } @files];
}

sub _walk_files($session, $root, $relative, $files) {
    my $path = length($relative)
        ? File::Spec->catfile($root, split m{/}, $relative) : $root;
    opendir my $dh, $path
        or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
            'cannot inspect GHDL work library', '/workspace');
    my @entry = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    for my $name (@entry) {
        my $child_rel = length($relative) ? "$relative/$name" : $name;
        my $child = File::Spec->catfile($root, split m{/}, $child_rel);
        my @stat = lstat($child);
        _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
            'GHDL work library contains a foreign entry', '/workspace')
            unless @stat && !-l _ && $stat[0] == $session->{root_device};
        if (-d _) {
            _walk_files($session, $root, $child_rel, $files);
        }
        elsif (-f _) {
            push @$files, {
                relpath => $child_rel,
                bytes => 0 + $stat[7],
                sha256 => _file_sha256($child),
            };
        }
        else {
            _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
                'GHDL work library contains a non-file entry', '/workspace');
        }
    }
}

sub _validate_current_sources($session) {
    for my $entry (@{$session->{source_set}}) {
        my $path = _repo_path($session->{repo_root}, $entry->{relpath});
        _regular_same_volume(
            $path, $entry->{relpath}, $session->{root_device},
        );
        _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
            "GHDL source '$entry->{relpath}' changed after admission",
            '/source_set') unless -s $path == $entry->{bytes}
                && _file_sha256($path) eq $entry->{sha256};
    }
}

sub _validate_current_provider($session) {
    for my $spec (
        [$session->{provider}{archive},
            $session->{provider}{archive_bytes},
            $session->{provider}{archive_sha256}, 0],
        [$session->{provider}{binary}, undef,
            $session->{provider}{binary_sha256}, 1],
    ) {
        my ($relative, $bytes, $digest, $executable) = @$spec;
        my $path = _repo_path($session->{repo_root}, $relative);
        _regular_same_volume($path, $relative, $session->{root_device});
        _throw('VIAL_GHDL_LIFECYCLE_TOOL_ERROR',
            "provider input '$relative' has a foreign byte size", '/provider')
            if defined($bytes) && -s $path != $bytes;
        _throw('VIAL_GHDL_LIFECYCLE_TOOL_ERROR',
            "provider input '$relative' has a foreign digest", '/provider')
            unless _file_sha256($path) eq $digest;
        _throw('VIAL_GHDL_LIFECYCLE_TOOL_ERROR',
            'qualified GHDL binary is not executable', '/provider/binary')
            if $executable && !-x $path;
    }
}

sub _capture_evidence($capture) {
    return {map { $_ => _clone($capture->{$_}) } @CAPTURE_KEYS};
}

sub _command_digest($argv) {
    return sha256_hex(_canonical($argv));
}

sub _owner_matches($session) {
    my $path = "$session->{stage_abs}/.owner.json";
    return 0 unless -f $path && !-l $path;
    my @stat = stat($path);
    return 0 unless @stat && $stat[0] == $session->{root_device};
    my $text = eval { _slurp($path) };
    return 0 unless defined $text;
    my $owner = eval { $JSON->decode($text) };
    return 0 unless ref($owner) eq 'HASH' && !blessed($owner)
        && $text eq _canonical($owner) . "\n";
    return ($owner->{schema} // '') eq $OWNER_SCHEMA
        && ($owner->{schema_version} // 0) == 1
        && ($owner->{lifecycle_identity} // '')
            eq $session->{lifecycle_identity}
        && ($owner->{staging_identity} // '') eq $session->{stage_rel};
}

sub _remove_owned_root($session) {
    _throw('VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
        'GHDL lifecycle cannot prove ownership before cleanup', '/cleanup')
        unless _owner_matches($session);
    my $errors;
    remove_tree($session->{stage_abs}, {error => \$errors});
    _throw('VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
        'GHDL lifecycle cleanup failed', '/cleanup')
        if $errors && @$errors;
    _throw('VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
        'GHDL lifecycle cleanup left residue', '/cleanup')
        if -e $session->{stage_abs} || -l $session->{stage_abs};
}

sub _exception($error, $session) {
    my ($code, $message, $path) = (
        'VIAL_GHDL_LIFECYCLE_HOST_ERROR', _sanitize($error), '/',
    );
    if (blessed($error)
            && $error->isa('FSM::VIAL::Backend::GHDLLifecycle::Failure')) {
        ($code, $message, $path) = @{$error}{qw(code message path)};
    }
    my $cleanup;
    if (defined($session) && $session->{cleanup_on_error}
            && _owner_matches($session)) {
        my $removed = eval { _remove_owned_root($session); 1 };
        $cleanup = {
            removed => $removed ? JSON::PP::true : JSON::PP::false,
            residue => $removed ? [] : [$session->{stage_rel}],
        };
    }
    return _failure($code, $message, $path, $session, $cleanup);
}

sub _failure($code, $message, $path, $session, $cleanup = undef) {
    $cleanup //= {removed => JSON::PP::false, residue => []};
    my $value = {
        ok => JSON::PP::false,
        status => 'error',
        lifecycle_identity => defined($session)
            ? $session->{lifecycle_identity} : undef,
        handle => defined($session) ? _clone($session->{handle}) : undef,
        assembled_result => undef,
        stage_evidence => defined($session) && defined($session->{handle})
            ? _stage_evidence($session) : [],
        diagnostics => [{
            code => $code, severity => 'error', message => $message,
            path => $path,
        }],
        cleanup => {
            staging_identity => defined($session)
                ? $session->{stage_rel} : undef,
            removed => $cleanup->{removed},
            residue => _clone($cleanup->{residue}),
        },
    };
    _closed($value, \@RESULT_KEYS, 'GHDL lifecycle result');
    return _clone($value);
}

sub _result($session, $status, $assembled, $cleanup) {
    $cleanup //= {removed => JSON::PP::false, residue => []};
    my $value = {
        ok => JSON::PP::true,
        status => $status,
        lifecycle_identity => $session->{lifecycle_identity},
        handle => _clone($session->{handle}),
        assembled_result => _clone($assembled),
        stage_evidence => $status eq 'cleaned' ? [] : _stage_evidence($session),
        diagnostics => [],
        cleanup => {
            staging_identity => $session->{stage_rel},
            removed => $cleanup->{removed},
            residue => _clone($cleanup->{residue}),
        },
    };
    _closed($value, \@RESULT_KEYS, 'GHDL lifecycle result');
    return _clone($value);
}

sub _stage_evidence($session) {
    return [] unless defined($session->{handle})
        && $session->{handle}{state} ne 'cleaned';
    my $states_abs = "$session->{stage_abs}/states";
    return [] unless -d $states_abs && !-l $states_abs;
    opendir my $dh, $states_abs or return [];
    my @name = sort grep { /[.]json\z/ } readdir $dh;
    closedir $dh;
    my @evidence;
    for my $name (@name) {
        my $relative = "$session->{stage_rel}/states/$name";
        my $state = eval { _read_state($session, $relative) };
        last unless defined $state;
        push @evidence, {
            state => $state->{state}, ordinal => $state->{ordinal},
            state_identity => $state->{state_identity},
            evidence => _clone($state->{evidence}),
        };
    }
    return \@evidence;
}

sub _write_atomic($path, $content) {
    my $temporary = $path . '.tmp-' . sha256_hex(
        $path . "\0" . time() . "\0" . rand() . "\0"
            . bytes::length($content),
    );
    sysopen my $fh, $temporary,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600
        or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
            'cannot create GHDL atomic object', '/state');
    print {$fh} $content
        or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
            'cannot write GHDL atomic object', '/state');
    close $fh or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
        'cannot close GHDL atomic object', '/state');
    rename $temporary, $path
        or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
            'cannot commit GHDL atomic object', '/state');
}

sub _regular_same_volume($path, $identity, $root_device) {
    _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
        "required GHDL path '$identity' is not one regular non-symlink file",
        '/path') unless -f $path && !-l $path;
    my @stat = stat($path);
    _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
        "required GHDL path '$identity' crossed the repository volume",
        '/path') unless @stat && $stat[0] == $root_device;
}

sub _repo_path($root, $relative) {
    _safe_relpath($relative, '/path');
    my $path = $root;
    for my $component (split m{/}, $relative) {
        $path = File::Spec->catfile($path, $component);
        _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
            'GHDL repository-relative path crosses a symlink component',
            '/path') if -l $path;
    }
    return $path;
}

sub _safe_relpath($value, $path) {
    _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
        'GHDL path is not one safe repository-relative identity', $path)
        unless defined($value) && !ref($value) && length($value)
            && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split m{/}, $value, -1;
    return 1;
}

sub _file_sha256($path) {
    open my $fh, '<:raw', $path
        or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
            'cannot read one GHDL lifecycle input', '/path');
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
        'cannot close one GHDL lifecycle input', '/path');
    return $sha->hexdigest;
}

sub _slurp($path) {
    open my $fh, '<:raw', $path
        or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
            'cannot read one GHDL lifecycle object', '/path');
    local $/;
    my $content = <$fh>;
    close $fh or _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
        'cannot close one GHDL lifecycle object', '/path');
    return $content;
}

sub _process_summary($capture) {
    my $summary = length($capture->{output})
        ? $capture->{output} : ($capture->{exec_error} // 'unknown failure');
    $summary =~ s/[\r\n\t]+/ /g;
    $summary =~ s/\s+/ /g;
    return length($summary) > 1_024 ? substr($summary, 0, 1_024) : $summary;
}

sub _closed($value, $keys, $label) {
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        "$label is not one closed hash", '/')
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _canonical($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    _throw('VIAL_GHDL_LIFECYCLE_HOST_ERROR',
        'GHDL lifecycle projection contains an unsupported reference', '/')
        if ref($value);
    return $value;
}

sub _exact_class($class, $method) {
    die __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _sanitize($error) {
    my $message = defined($error) ? "$error" : 'unknown GHDL lifecycle failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+[.]?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown GHDL lifecycle failure';
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::GHDLLifecycle::Failure';
}

package FSM::VIAL::Backend::GHDLLifecycle::Failure;

use overload '""' => sub {
    $_[0]{message} // 'portable VHDL GHDL lifecycle failure'
}, fallback => 1;

1;
