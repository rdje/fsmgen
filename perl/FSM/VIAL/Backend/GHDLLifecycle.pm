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
use FSM::VIAL::Backend::ResultProducer;
use FSM::VIAL::Backend::VHDLPortableTraceValidator;
use FSM::VIAL::Backend::VHDLResultSchema;

my $JSON = JSON::PP->new->canonical(1);
my $LIFECYCLE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle.v1';
my $STATE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle_state.v1';
my $HANDLE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle_handle.v1';
my $OSVVM_LIFECYCLE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle.v2';
my $OSVVM_STATE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle_state.v2';
my $OSVVM_HANDLE_SCHEMA = 'fsmgen.vial_ghdl_lifecycle_handle.v2';
my $OSVVM_COMMAND_SCHEMA =
    'fsmgen.vial_ghdl_lifecycle_osvvm_command_plan.v2';
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
my @OSVVM_COMMAND_KEYS = qw(
    schema schema_version version provider_analyze analyze_generated
    elaborate_fixture elaborate_provider_probe run_fixture run_provider_probe
    generated_settings libraries provider_reports resource_controls
);
my @OSVVM_SETTINGS_KEYS = qw(relpath content bytes sha256);
my @OSVVM_LIBRARY_KEYS = qw(root osvvm osvvm_common fsmgen_vial);
my @OSVVM_REPORT_KEYS = qw(name relpath);
my @OSVVM_RESOURCE_KEYS = qw(
    outer_guard descendant_rss_limit_mib host_occupied_cutoff_percent
    version_timeout_seconds provider_analysis_timeout_seconds_per_source
    generated_analysis_timeout_seconds elaboration_timeout_seconds
    execution_timeout_seconds version_capture_limit_bytes
    provider_capture_limit_bytes fixture_capture_limit_bytes
);
my @OSVVM_REPORT_NAMES = qw(
    OsvvmRun.yml AlertLogTop_alerts.yml AlertLogTop_cov.yml
    AlertLogTop_sb_slv.yml
);
my @VALIDATION_KEYS = qw(
    expected_record_counts expected_diagnostic_codes expected_domain_id
    expected_fixture_id expected_plan_id expected_random_decisions_sha256 expected_run_ids
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
        command_digest output_sha256 capture workspace_files workspace_sha256
    )],
    elaborated => [qw(
        command_digest output_sha256 capture workspace_files workspace_sha256
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
    'FSM::VIAL::Backend::VHDLOSVVMGHDLQualification' =>
        'osvvm_qualification',
    'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement' =>
        'architecture_scale_measurement',
    'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement' =>
        'osvvm_architecture_scale_measurement',
);
my %PHASE_POLICY = (
    tool_verified => [10, 65_536],
    analyzed => [120, 8_388_608],
    elaborated => [60, 8_388_608],
    ran => [30, 67_108_864],
);
my $RESULT_RECORD_MAX_BYTES = 67_108_864;

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

sub _is_osvvm_role($role) {
    return defined($role) && !ref($role)
        && $role =~ /\Aosvvm_(?:qualification|architecture_scale_measurement)\z/;
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
        unless ($handle->{schema} // '') eq $session->{handle_schema}
            && ($handle->{schema_version} // 0)
                == $session->{schema_version}
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
    _validate_osvvm_settings($session)
        if _is_osvvm_role($session->{role})
            && $handle->{ordinal} >= $STATE_ORDINAL{prepared};
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
        $source_set, $role,
    );
    my $validation = _validated_validation($raw->{validation});
    my $schema_version = _is_osvvm_role($role) ? 2 : 1;
    my $authority = {
        schema => $schema_version == 2
            ? $OSVVM_LIFECYCLE_SCHEMA : $LIFECYCLE_SCHEMA,
        schema_version => $schema_version,
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
        role => $role,
        schema_version => $schema_version,
        state_schema => $schema_version == 2
            ? $OSVVM_STATE_SCHEMA : $STATE_SCHEMA,
        handle_schema => $schema_version == 2
            ? $OSVVM_HANDLE_SCHEMA : $HANDLE_SCHEMA,
        lifecycle_identity => $lifecycle_identity,
        provider => $provider,
        source_set => $source_set,
        commands => $commands,
        validation => $validation,
        storage_context => $storage,
        stage_rel => $stage_rel,
        stage_abs => _repo_path($repo_root, $stage_rel),
        library_rel => _is_osvvm_role($role)
            ? $commands->{libraries}{root} : "$stage_rel/library",
        library_abs => _repo_path(
            $repo_root,
            _is_osvvm_role($role)
                ? $commands->{libraries}{root} : "$stage_rel/library",
        ),
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
        osvvm_qualification => [
            'osvvm_qualification', 'lifecycle_process_group',
            qr{\A[.]artifacts/tmp/vial-osvvm-ghdl-qualification/[0-9a-f]{64}\z},
        ],
        osvvm_architecture_scale_measurement => [
            'osvvm_architecture_scale_measurement',
            'outer_worker_process_group',
            qr{\A[.]artifacts/tmp/vial-scale/[0-9a-f]{64}/(?:validation|gate_measurement|qualification_measurement)/[0-9]{2}/lifecycle\z},
        ],
        architecture_scale_measurement => [
            'architecture_scale_measurement', 'outer_worker_process_group',
            qr{\A[.]artifacts/tmp/vial-scale/[0-9a-f]{64}/(?:validation|gate_measurement|qualification_measurement)/[0-9]{2}/lifecycle\z},
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

sub _validated_commands($raw, $binary, $stage_rel, $source_set, $role) {
    return _validated_osvvm_commands(
        $raw, $binary, $stage_rel, $source_set,
    ) if _is_osvvm_role($role);
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

sub _validated_osvvm_commands($raw, $binary, $stage_rel, $source_set) {
    _closed($raw, \@OSVVM_COMMAND_KEYS,
        'OSVVM/GHDL multi-command authority');
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM/GHDL command-plan schema is not exact', '/commands/schema')
        unless ($raw->{schema} // '') eq $OSVVM_COMMAND_SCHEMA
            && ($raw->{schema_version} // 0) == 2;

    _closed($raw->{generated_settings}, \@OSVVM_SETTINGS_KEYS,
        'OSVVM generated settings authority');
    my $settings = $raw->{generated_settings};
    my $settings_rel = "$stage_rel/OsvvmScriptSettingsPkg_generated.vhd";
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM generated settings identity is not exact',
        '/commands/generated_settings')
        unless ($settings->{relpath} // '') eq $settings_rel
            && defined($settings->{content}) && !ref($settings->{content})
            && ($settings->{bytes} // -1)
                == bytes::length($settings->{content})
            && ($settings->{sha256} // '')
                eq sha256_hex($settings->{content});

    _closed($raw->{libraries}, \@OSVVM_LIBRARY_KEYS,
        'OSVVM/GHDL library authority');
    my $libraries = $raw->{libraries};
    my $library_root = "$stage_rel/libraries";
    my %expected_library = (
        root => $library_root,
        osvvm => "$library_root/osvvm/v08",
        osvvm_common => "$library_root/osvvm_common/v08",
        fsmgen_vial => "$library_root/fsmgen_vial/v08",
    );
    for my $name (@OSVVM_LIBRARY_KEYS) {
        _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
            "OSVVM/GHDL $name library identity is not exact",
            "/commands/libraries/$name")
            unless ($libraries->{$name} // '') eq $expected_library{$name};
    }

    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM/GHDL provider analysis plan is not one nonempty command list',
        '/commands/provider_analyze')
        unless ref($raw->{provider_analyze}) eq 'ARRAY'
            && @{$raw->{provider_analyze}};
    my @analysis_source;
    for my $index (0 .. $#{$raw->{provider_analyze}}) {
        my $argv = $raw->{provider_analyze}[$index];
        _osvvm_argv($argv, $binary, '-a',
            "/commands/provider_analyze/$index");
        _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
            'OSVVM provider analysis command shape is not exact',
            "/commands/provider_analyze/$index") unless @$argv == 9;
        my ($work) = map { substr($_, length('--work=')) }
            grep { index($_, '--work=') == 0 } @$argv;
        my %workdir = (
            osvvm => $libraries->{osvvm},
            osvvm_common => $libraries->{osvvm_common},
        );
        _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
            'OSVVM provider analysis library is not exact',
            "/commands/provider_analyze/$index")
            unless defined($work) && exists($workdir{$work})
                && grep({ $_ eq "--workdir=$workdir{$work}" } @$argv) == 1
                && grep({ $_ eq "-P$libraries->{root}" } @$argv) == 1;
        push @analysis_source, $argv->[-1]
            unless $argv->[-1] eq $settings_rel;
    }

    my $generated = $raw->{analyze_generated};
    _osvvm_argv($generated, $binary, '-a',
        '/commands/analyze_generated');
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM generated-source analysis authority is not exact',
        '/commands/analyze_generated') unless @$generated >= 9
            && grep({ $_ eq '--work=fsmgen_vial' } @$generated) == 1
            && grep({ $_ eq "--workdir=$libraries->{fsmgen_vial}" }
                @$generated) == 1
            && grep({ $_ eq "-P$libraries->{root}" } @$generated) == 1;
    push @analysis_source, @$generated[8 .. $#$generated];
    my @expected_source = map { $_->{relpath} } @$source_set;
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM analysis commands do not bind the exact ordered source set',
        '/commands') unless _canonical(\@analysis_source)
            eq _canonical(\@expected_source);

    _osvvm_top_command(
        $raw->{elaborate_fixture}, $binary, '-e', $libraries,
        'base_output_arbitration_tb', '/commands/elaborate_fixture',
    );
    _osvvm_top_command(
        $raw->{elaborate_provider_probe}, $binary, '-e', $libraries,
        'fsmgen_vial_osvvm_runtime_probe',
        '/commands/elaborate_provider_probe',
    );
    _osvvm_top_command(
        $raw->{run_fixture}, $binary, '-r', $libraries,
        'base_output_arbitration_tb', '/commands/run_fixture',
    );
    _osvvm_top_command(
        $raw->{run_provider_probe}, $binary, '-r', $libraries,
        'fsmgen_vial_osvvm_runtime_probe', '/commands/run_provider_probe',
    );
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM runtime assertion policy is not exact', '/commands')
        unless $raw->{run_fixture}[-1] eq '--assert-level=error'
            && $raw->{run_provider_probe}[-1] eq '--assert-level=error';

    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM version command is not exact', '/commands/version')
        unless ref($raw->{version}) eq 'ARRAY'
            && @{$raw->{version}} == 2
            && $raw->{version}[0] eq $binary
            && $raw->{version}[1] eq '--version';

    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM provider report inventory is not one exact ordered list',
        '/commands/provider_reports')
        unless ref($raw->{provider_reports}) eq 'ARRAY'
            && @{$raw->{provider_reports}} == @OSVVM_REPORT_NAMES;
    for my $index (0 .. $#OSVVM_REPORT_NAMES) {
        my $report = $raw->{provider_reports}[$index];
        _closed($report, \@OSVVM_REPORT_KEYS,
            "OSVVM provider report $index");
        _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
            'OSVVM provider report identity is not exact',
            "/commands/provider_reports/$index")
            unless ($report->{name} // '') eq $OSVVM_REPORT_NAMES[$index]
                && ($report->{relpath} // '') eq
                    "$stage_rel/provider_reports/$OSVVM_REPORT_NAMES[$index]";
    }

    _closed($raw->{resource_controls}, \@OSVVM_RESOURCE_KEYS,
        'OSVVM/GHDL resource controls');
    my $expected_resource = {
        outer_guard =>
            'scripts/run_with_ram_guard.sh --process-max-rss-mb 4096',
        descendant_rss_limit_mib => 4_096,
        host_occupied_cutoff_percent => 88,
        version_timeout_seconds => 10,
        provider_analysis_timeout_seconds_per_source => 120,
        generated_analysis_timeout_seconds => 120,
        elaboration_timeout_seconds => 60,
        execution_timeout_seconds => 30,
        version_capture_limit_bytes => 65_536,
        provider_capture_limit_bytes => 8_388_608,
        fixture_capture_limit_bytes => 67_108_864,
    };
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM/GHDL resource controls differ from the qualified plan',
        '/commands/resource_controls') unless
            _canonical($raw->{resource_controls})
                eq _canonical($expected_resource);
    return _clone($raw);
}

sub _osvvm_argv($argv, $binary, $mode, $path) {
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM/GHDL command is not one scalar argument vector', $path)
        unless ref($argv) eq 'ARRAY' && @$argv >= 2
            && !grep { !defined($_) || ref($_) || /\x00/ } @$argv;
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM/GHDL command executable, mode, or language differs', $path)
        unless $argv->[0] eq $binary && $argv->[1] eq $mode
            && grep({ $_ eq '--std=08' } @$argv) == 1;
}

sub _osvvm_top_command($argv, $binary, $mode, $libraries, $top, $path) {
    _osvvm_argv($argv, $binary, $mode, $path);
    my $expected_length = $mode eq '-r' ? 8 : 7;
    my $top_index = $mode eq '-r' ? -2 : -1;
    _throw('VIAL_GHDL_LIFECYCLE_COMMAND_ERROR',
        'OSVVM/GHDL top command authority is not exact', $path)
        unless @$argv == $expected_length
            && grep({ $_ eq '--work=fsmgen_vial' } @$argv) == 1
            && grep({ $_ eq "--workdir=$libraries->{fsmgen_vial}" }
                @$argv) == 1
            && grep({ $_ eq "-P$libraries->{root}" } @$argv) == 1
            && $argv->[$top_index] eq $top;
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
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL expected domain identity is not one bounded safe identity',
        '/validation/expected_domain_id')
        unless _runtime_result_identity($raw->{expected_domain_id});
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL expected diagnostic codes must match the scenario count',
        '/validation/expected_diagnostic_codes')
        unless ref($raw->{expected_diagnostic_codes}) eq 'ARRAY'
            && @{$raw->{expected_diagnostic_codes}}
                == @{$raw->{expected_run_ids}};
    for my $index (0 .. $#{$raw->{expected_diagnostic_codes}}) {
        _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
            'GHDL expected diagnostic code is outside the emitted vocabulary',
            "/validation/expected_diagnostic_codes/$index")
            unless defined($raw->{expected_diagnostic_codes}[$index])
                && !ref($raw->{expected_diagnostic_codes}[$index])
                && $raw->{expected_diagnostic_codes}[$index]
                    =~ /\AVIAL_EXPECT_(?:SUCCESS|ERROR)\z/;
    }
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL expected fixture identity is not one bounded safe identity',
        '/validation/expected_fixture_id')
        unless _runtime_result_identity($raw->{expected_fixture_id});
    _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'GHDL expected random-decision digest is not one SHA-256 identity',
        '/validation/expected_random_decisions_sha256')
        unless defined($raw->{expected_random_decisions_sha256})
            && !ref($raw->{expected_random_decisions_sha256})
            && $raw->{expected_random_decisions_sha256}
                =~ /\A[0-9a-f]{64}\z/;
    my $run_prefix = "run/$raw->{expected_plan_id}/";
    for my $index (0 .. $#{$raw->{expected_run_ids}}) {
        my $run_id = $raw->{expected_run_ids}[$index];
        my $scenario_id = substr($run_id, length($run_prefix));
        my @scenario_part = split /::scenario::/, $scenario_id, -1;
        _throw('VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
            'GHDL expected run identity does not belong to its fixture',
            "/validation/expected_run_ids/$index")
            unless index($run_id, $run_prefix) == 0
                && @scenario_part == 2 && length($scenario_part[1])
                && $scenario_part[0] eq $raw->{expected_fixture_id};
    }
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
        if ($created) {
            my ($errors, $removed);
            if (-d $session->{stage_abs} && !-l $session->{stage_abs}) {
                remove_tree($session->{stage_abs}, {error => \$errors});
                $removed = !($errors && @$errors)
                    && !-e $session->{stage_abs}
                    && !-l $session->{stage_abs};
            }
            else {
                $removed = !-e $session->{stage_abs}
                    && !-l $session->{stage_abs};
            }
            $session->{failure_cleanup} = {
                removed => $removed
                    ? JSON::PP::true : JSON::PP::false,
                residue => $removed ? [] : [$session->{stage_rel}],
            };
            $error = bless {
                code => 'VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
                message => 'GHDL lifecycle admission cleanup failed',
                path => '/cleanup',
            }, 'FSM::VIAL::Backend::GHDLLifecycle::Failure'
                unless $removed;
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
    return _phase_osvvm_prepared($session)
        if _is_osvvm_role($session->{role});
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

sub _phase_osvvm_prepared($session) {
    my $commands = $session->{commands};
    for my $relative (
        @{$commands->{libraries}}{qw(osvvm osvvm_common fsmgen_vial)},
        "$session->{stage_rel}/provider_reports",
    ) {
        my $absolute = _repo_path($session->{repo_root}, $relative);
        make_path($absolute);
        my @stat = stat($absolute);
        _throw('VIAL_GHDL_LIFECYCLE_PATH_ERROR',
            'OSVVM/GHDL workspace is not one same-volume owned directory',
            '/prepared/libraries') unless @stat && -d _ && !-l $absolute
                && $stat[0] == $session->{root_device};
    }
    my $settings = $commands->{generated_settings};
    my $settings_abs = _repo_path(
        $session->{repo_root}, $settings->{relpath},
    );
    _write_atomic($settings_abs, $settings->{content});
    chmod 0600, $settings_abs or _throw(
        'VIAL_GHDL_LIFECYCLE_HOST_ERROR',
        'cannot seal generated OSVVM settings permissions',
        '/prepared/generated_settings',
    );
    _validate_osvvm_settings($session);
    push @{$session->{objects}}, _write_object(
        $session, 'generated_settings', $settings->{content}, 0,
    );
    return {
        library_identities => _clone($commands->{libraries}),
        source_count => scalar(@{$session->{source_set}}),
        settings_sha256 => $settings->{sha256},
        _workspace_evidence($session),
    };
}

sub _phase_tool_verified($session) {
    _validate_osvvm_execution_inputs($session)
        if _is_osvvm_role($session->{role});
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
    return _phase_osvvm_analyzed($session)
        if _is_osvvm_role($session->{role});
    my $capture = _run_phase(
        $session, 'analyzed', $session->{commands}{analyze},
    );
    push @{$session->{objects}}, _write_object(
        $session, 'analysis_output', $capture->{output}, 0,
    );
    return {
        command_digest => _command_digest($session->{commands}{analyze}),
        output_sha256 => sha256_hex($capture->{output}),
        capture => _capture_evidence($capture),
        _workspace_evidence($session),
    };
}

sub _phase_osvvm_analyzed($session) {
    _validate_osvvm_execution_inputs($session);
    my $resource = $session->{commands}{resource_controls};
    my (@captures, @digests, @outputs);
    for my $index (0 .. $#{$session->{commands}{provider_analyze}}) {
        my $argv = $session->{commands}{provider_analyze}[$index];
        my $capture = _run_command(
            $session, 'analyzed', $argv,
            $resource->{provider_analysis_timeout_seconds_per_source},
            $resource->{provider_capture_limit_bytes},
            "provider analysis $index",
        );
        push @captures, _capture_evidence($capture);
        push @digests, _command_digest($argv);
        push @outputs, sha256_hex($capture->{output});
        push @{$session->{objects}}, _write_object(
            $session, sprintf('provider_analysis_output_%02d', $index),
            $capture->{output}, 0,
        );
    }
    my $generated_argv = $session->{commands}{analyze_generated};
    my $generated_capture = _run_command(
        $session, 'analyzed', $generated_argv,
        $resource->{generated_analysis_timeout_seconds},
        $resource->{provider_capture_limit_bytes},
        'adapter and generated-fixture analysis',
    );
    push @{$session->{objects}}, _write_object(
        $session, 'generated_analysis_output',
        $generated_capture->{output}, 0,
    );
    return {
        command_digests => \@digests,
        captures => \@captures,
        output_sha256 => \@outputs,
        generated_command_digest => _command_digest($generated_argv),
        generated_capture => _capture_evidence($generated_capture),
        generated_output_sha256 => sha256_hex($generated_capture->{output}),
        _workspace_evidence($session),
    };
}

sub _phase_elaborated($session) {
    return _phase_osvvm_elaborated($session)
        if _is_osvvm_role($session->{role});
    my $capture = _run_phase(
        $session, 'elaborated', $session->{commands}{elaborate},
    );
    push @{$session->{objects}}, _write_object(
        $session, 'elaboration_output', $capture->{output}, 0,
    );
    return {
        command_digest => _command_digest($session->{commands}{elaborate}),
        output_sha256 => sha256_hex($capture->{output}),
        capture => _capture_evidence($capture),
        _workspace_evidence($session),
    };
}

sub _phase_osvvm_elaborated($session) {
    _validate_osvvm_execution_inputs($session);
    my $resource = $session->{commands}{resource_controls};
    my @spec = (
        [fixture => $session->{commands}{elaborate_fixture}],
        [provider_probe =>
            $session->{commands}{elaborate_provider_probe}],
    );
    my (@captures, @digests, @outputs);
    for my $entry (@spec) {
        my ($name, $argv) = @$entry;
        my $capture = _run_command(
            $session, 'elaborated', $argv,
            $resource->{elaboration_timeout_seconds},
            $resource->{provider_capture_limit_bytes},
            "$name elaboration",
        );
        push @captures, _capture_evidence($capture);
        push @digests, _command_digest($argv);
        push @outputs, sha256_hex($capture->{output});
        push @{$session->{objects}}, _write_object(
            $session, "${name}_elaboration_output", $capture->{output}, 0,
        );
    }
    return {
        command_digests => \@digests,
        captures => \@captures,
        output_sha256 => \@outputs,
        _workspace_evidence($session),
    };
}

sub _phase_ran($session) {
    return _phase_osvvm_ran($session)
        if _is_osvvm_role($session->{role});
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

sub _phase_osvvm_ran($session) {
    _validate_osvvm_execution_inputs($session);
    my $resource = $session->{commands}{resource_controls};
    my $repetitions = $session->{validation}{run_repetitions};
    my (@fixture_captures, @fixture_sha256);
    for my $index (0 .. $repetitions - 1) {
        my $capture = _run_command(
            $session, 'ran', $session->{commands}{run_fixture},
            $resource->{execution_timeout_seconds},
            $resource->{fixture_capture_limit_bytes},
            $index ? 'fixture deterministic rerun' : 'fixture execution',
        );
        push @fixture_captures, _capture_evidence($capture);
        push @fixture_sha256, sha256_hex($capture->{output});
        push @{$session->{objects}}, _write_object(
            $session, "fixture_runtime_output_$index",
            $capture->{output}, 0,
        );
    }

    my (@provider_captures, @provider_sha256, @report_sha256);
    for my $index (0 .. $repetitions - 1) {
        my $capture = _run_command(
            $session, 'ran', $session->{commands}{run_provider_probe},
            $resource->{execution_timeout_seconds},
            $resource->{provider_capture_limit_bytes},
            $index ? 'provider probe deterministic rerun'
                : 'provider probe execution',
        );
        push @provider_captures, _capture_evidence($capture);
        push @provider_sha256, sha256_hex($capture->{output});
        push @{$session->{objects}}, _write_object(
            $session, "provider_runtime_output_$index",
            $capture->{output}, 0,
        );
        my $reports = _snapshot_osvvm_reports($session, $index);
        push @report_sha256, sha256_hex(_canonical($reports));
        _clear_osvvm_reports($session);
    }
    _throw('VIAL_GHDL_LIFECYCLE_DETERMINISM_ERROR',
        'identical OSVVM fixture runtime repetitions differ', '/ran/fixture')
        if @fixture_sha256 == 2
            && $fixture_sha256[0] ne $fixture_sha256[1];
    _throw('VIAL_GHDL_LIFECYCLE_DETERMINISM_ERROR',
        'identical OSVVM provider runtime repetitions differ',
        '/ran/provider_probe') if @provider_sha256 == 2
            && $provider_sha256[0] ne $provider_sha256[1];
    _throw('VIAL_GHDL_LIFECYCLE_DETERMINISM_ERROR',
        'identical OSVVM provider reports differ', '/ran/provider_reports')
        if @report_sha256 == 2 && $report_sha256[0] ne $report_sha256[1];
    return {
        command_digests => {
            fixture => _command_digest($session->{commands}{run_fixture}),
            provider_probe =>
                _command_digest($session->{commands}{run_provider_probe}),
        },
        fixture_captures => \@fixture_captures,
        provider_captures => \@provider_captures,
        fixture_output_sha256 => \@fixture_sha256,
        provider_output_sha256 => \@provider_sha256,
        provider_report_sha256 => \@report_sha256,
        deterministic => $repetitions == 2
            ? JSON::PP::true : JSON::PP::false,
        _workspace_evidence($session),
    };
}

sub _phase_trace_validated($session) {
    my $runtime_kind = _is_osvvm_role($session->{role})
        ? 'fixture_runtime_output_0' : 'runtime_output_0';
    my $output = _object_content($session, $runtime_kind);
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
    my $runtime_kind = _is_osvvm_role($session->{role})
        ? 'fixture_runtime_output_0' : 'runtime_output_0';
    my $output = _object_content($session, $runtime_kind);
    my $decoded = _decode_runtime_result_record(
        $output, $RESULT_RECORD_MAX_BYTES,
    );
    _validate_runtime_result_plan_identity(
        $decoded, $session->{validation}{expected_plan_id},
    );
    _validate_runtime_result_scenario_identities(
        $decoded, $session->{validation}{expected_plan_id},
        $session->{validation}{expected_run_ids},
    );
    _validate_runtime_result_shapes($decoded);
    _validate_runtime_result_scenario_values(
        $decoded, $session->{validation}{expected_domain_id},
    );
    _validate_runtime_result_outcome_values(
        $decoded, $session->{validation}{expected_observation_catalog},
    );
    _validate_runtime_result_top_level_values(
        $decoded, $session->{validation}{expected_record_counts},
        $session->{validation}{expected_fixture_id},
        $session->{validation}{expected_random_decisions_sha256},
        $session->{validation}{expected_diagnostic_codes},
    );
    push @{$session->{objects}}, _write_object(
        $session, 'normalized_result', _canonical($decoded) . "\n", 0,
    );
    return {
        result_sha256 => sha256_hex(_canonical($decoded)),
        result_status => 'pass',
        _workspace_evidence($session),
    };
}

sub _decode_runtime_result_record($output, $byte_limit) {
    die "GHDL runtime result byte limit must be a positive integer\n"
        unless defined($byte_limit) && !ref($byte_limit)
            && $byte_limit =~ /\A[1-9][0-9]*\z/;
    my @result = map {
        substr($_, length("FSMGEN_VIAL_RESULT_V1\t"))
    } grep { index($_, "FSMGEN_VIAL_RESULT_V1\t") == 0 }
        split /\r?\n/, $output;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime must emit exactly one normalized result record',
        '/result_produced') unless @result == 1;
    _throw('VIAL_GHDL_LIFECYCLE_LIMIT_ERROR',
        'GHDL runtime normalized result exceeds its exact byte ceiling',
        '/result_produced')
        if bytes::length($result[0]) > $byte_limit;
    my $decoded = eval { $JSON->decode($result[0]) };
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result is malformed', '/result_produced')
        unless defined($decoded) && !$@ && ref($decoded) eq 'HASH'
            && !blessed($decoded);
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result is not canonical JSON', '/result_produced')
        unless $JSON->encode($decoded) eq $result[0];
    my $manifest_keys = FSM::VIAL::Backend::ResultProducer->manifest_keys;
    my %manifest_key = map { $_ => 1 } @$manifest_keys;
    my @unknown = sort grep { !$manifest_key{$_} } keys %$decoded;
    my @missing = grep { !exists($decoded->{$_}) } @$manifest_keys;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        "GHDL runtime result has unknown key '$unknown[0]'",
        '/result_produced') if @unknown;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        "GHDL runtime result is missing key '$missing[0]'",
        '/result_produced') if @missing;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime normalized result did not pass', '/result_produced')
        unless ($decoded->{schema} // '')
                eq 'fsmgen.verification_result_manifest.v1'
            && ($decoded->{schema_version} // 0) == 1
            && ($decoded->{status} // '') eq 'pass';
    return $decoded;
}

sub _validate_runtime_result_plan_identity($decoded, $expected_plan_id) {
    die "GHDL runtime expected plan identity is invalid\n"
        unless defined($expected_plan_id) && !ref($expected_plan_id)
            && $expected_plan_id =~ m{\Aplan/[0-9a-f]{64}\z};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result plan identity differs from trace authority',
        '/result_produced/plan_id')
        unless defined($decoded->{plan_id}) && !ref($decoded->{plan_id})
            && $decoded->{plan_id} eq $expected_plan_id;
    my $projection = $decoded->{parity_projection};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime parity projection is not one object',
        '/result_produced/parity_projection')
        unless ref($projection) eq 'HASH' && !blessed($projection);
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime parity-projection plan identity differs from trace authority',
        '/result_produced/parity_projection/plan_id')
        unless defined($projection->{plan_id}) && !ref($projection->{plan_id})
            && $projection->{plan_id} eq $expected_plan_id;
    return;
}

sub _validate_runtime_result_scenario_identities(
    $decoded, $expected_plan_id, $expected_run_ids,
) {
    die "GHDL runtime expected run identities are invalid\n"
        unless ref($expected_run_ids) eq 'ARRAY'
            && !blessed($expected_run_ids) && @$expected_run_ids;
    my $run_prefix = "run/$expected_plan_id/";
    my @scenario_id;
    for my $run_id (@$expected_run_ids) {
        die "GHDL runtime expected run identity is invalid\n"
            unless defined($run_id) && !ref($run_id)
                && index($run_id, $run_prefix) == 0
                && length($run_id) > length($run_prefix);
        push @scenario_id, substr($run_id, length($run_prefix));
    }

    my $scenario_results = $decoded->{scenario_results};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime scenario-result count differs from trace authority',
        '/result_produced/scenario_results')
        unless ref($scenario_results) eq 'ARRAY'
            && !blessed($scenario_results)
            && @$scenario_results == @$expected_run_ids;
    for my $index (0 .. $#$expected_run_ids) {
        my $entry = $scenario_results->[$index];
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime scenario result is not one object',
            "/result_produced/scenario_results/$index")
            unless ref($entry) eq 'HASH' && !blessed($entry);
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime result run identity differs from trace authority',
            "/result_produced/scenario_results/$index/run_id")
            unless defined($entry->{run_id}) && !ref($entry->{run_id})
                && $entry->{run_id} eq $expected_run_ids->[$index];
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime result scenario identity differs from trace authority',
            "/result_produced/scenario_results/$index/scenario_id")
            unless defined($entry->{scenario_id})
                && !ref($entry->{scenario_id})
                && $entry->{scenario_id} eq $scenario_id[$index];
    }

    my $outcomes = $decoded->{parity_projection}{outcomes};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime parity-outcome count differs from trace authority',
        '/result_produced/parity_projection/outcomes')
        unless ref($outcomes) eq 'ARRAY' && !blessed($outcomes)
            && @$outcomes == @$expected_run_ids;
    for my $index (0 .. $#scenario_id) {
        my $outcome = $outcomes->[$index];
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime parity outcome is not one object',
            "/result_produced/parity_projection/outcomes/$index")
            unless ref($outcome) eq 'HASH' && !blessed($outcome);
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime parity scenario identity differs from trace authority',
            "/result_produced/parity_projection/outcomes/$index/scenario_id")
            unless defined($outcome->{scenario_id})
                && !ref($outcome->{scenario_id})
                && $outcome->{scenario_id} eq $scenario_id[$index];
    }
    return;
}

sub _validate_runtime_result_shapes($decoded) {
    my $scenario_results = $decoded->{scenario_results};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime scenario results are not one array',
        '/result_produced/scenario_results')
        unless ref($scenario_results) eq 'ARRAY' && !blessed($scenario_results);
    my $scenario_keys = FSM::VIAL::Backend::ResultProducer->scenario_keys;
    for my $index (0 .. $#$scenario_results) {
        my $path = "/result_produced/scenario_results/$index";
        my $entry = $scenario_results->[$index];
        _require_runtime_result_keys(
            $entry, $scenario_keys, $path, 'scenario result',
        );
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime passing result contains a non-pass scenario',
            "$path/status")
            unless defined($entry->{status}) && !ref($entry->{status})
                && $entry->{status} eq 'pass';
    }

    my $projection = $decoded->{parity_projection};
    _require_runtime_result_keys(
        $projection,
        FSM::VIAL::Backend::VHDLResultSchema->parity_projection_keys,
        '/result_produced/parity_projection', 'parity projection',
    );
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime parity-projection schema is not selected VHDL schema',
        '/result_produced/parity_projection/schema')
        unless defined($projection->{schema}) && !ref($projection->{schema})
            && $projection->{schema}
                eq FSM::VIAL::Backend::VHDLResultSchema->parity_schema;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime parity-projection schema version is unsupported',
        '/result_produced/parity_projection/schema_version')
        unless defined($projection->{schema_version})
            && !ref($projection->{schema_version})
            && $projection->{schema_version} =~ /\A[0-9]+\z/
            && $projection->{schema_version} ==
                FSM::VIAL::Backend::VHDLResultSchema->parity_schema_version;

    my $outcomes = $projection->{outcomes};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime parity outcomes are not one array',
        '/result_produced/parity_projection/outcomes')
        unless ref($outcomes) eq 'ARRAY' && !blessed($outcomes);
    my $outcome_keys = FSM::VIAL::Backend::VHDLResultSchema->parity_outcome_keys;
    for my $index (0 .. $#$outcomes) {
        my $path = "/result_produced/parity_projection/outcomes/$index";
        my $outcome = $outcomes->[$index];
        _require_runtime_result_keys(
            $outcome, $outcome_keys, $path, 'parity outcome',
        );
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime passing result contains a non-pass parity outcome',
            "$path/status")
            unless defined($outcome->{status}) && !ref($outcome->{status})
                && $outcome->{status} eq 'pass';
    }
    return;
}

sub _require_runtime_result_keys($value, $expected, $path, $label) {
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        "GHDL runtime $label is not one object", $path)
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$expected;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$expected;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        "GHDL runtime $label has unknown key '$unknown[0]'",
        "$path/$unknown[0]") if @unknown;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        "GHDL runtime $label is missing key '$missing[0]'",
        "$path/$missing[0]") if @missing;
    return;
}

sub _validate_runtime_result_top_level_values(
    $decoded, $expected_counts, $expected_fixture_id,
    $expected_random_decisions_sha256, $expected_diagnostic_codes,
) {
    die "GHDL runtime expected record counts are invalid\n"
        unless ref($expected_counts) eq 'HASH' && !blessed($expected_counts)
            && !grep {
                !_runtime_result_nonnegative_integer($expected_counts->{$_})
            } qw(coverage expectations faults scoreboards);
    die "GHDL runtime expected fixture identity is invalid\n"
        unless _runtime_result_identity($expected_fixture_id);
    die "GHDL runtime expected random-decision digest is invalid\n"
        unless defined($expected_random_decisions_sha256)
            && !ref($expected_random_decisions_sha256)
            && $expected_random_decisions_sha256 =~ /\A[0-9a-f]{64}\z/;
    my $contract =
        FSM::VIAL::Backend::VHDLResultSchema->runtime_result_contract;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result schema differs from the VHDL result contract',
        '/result_produced/schema')
        unless defined($decoded->{schema}) && !ref($decoded->{schema})
            && $decoded->{schema} eq $contract->{schema};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result schema version is unsupported',
        '/result_produced/schema_version')
        unless _canonical($decoded->{schema_version})
            eq _canonical($contract->{schema_version});
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime projection assigned a finalized result identity',
        '/result_produced/result_id') if defined($decoded->{result_id});
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime fixture identity differs from plan authority',
        '/result_produced/fixture_id')
        unless defined($decoded->{fixture_id}) && !ref($decoded->{fixture_id})
            && $decoded->{fixture_id} eq $expected_fixture_id;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime execution profile differs from the VHDL result contract',
        '/result_produced/execution_profile')
        unless defined($decoded->{execution_profile})
            && !ref($decoded->{execution_profile})
            && $decoded->{execution_profile} eq $contract->{execution_profile};
    _require_runtime_result_exact(
        $decoded->{backend_profile}, $contract->{backend_profile},
        '/result_produced/backend_profile', 'backend profile',
    );
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result did not retain passing status',
        '/result_produced/status')
        unless defined($decoded->{status}) && !ref($decoded->{status})
            && $decoded->{status} eq 'pass';
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL VHDL outcome projection claimed portable parity eligibility',
        '/result_produced/portable_parity_eligible')
        unless JSON::PP::is_bool($decoded->{portable_parity_eligible})
            && !$decoded->{portable_parity_eligible};
    _require_runtime_result_exact(
        $decoded->{capability_evidence}, $contract->{capability_evidence},
        '/result_produced/capability_evidence', 'capability evidence',
    );
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL VHDL outcome projection claimed a portable parity digest',
        '/result_produced/parity_digest') if defined($decoded->{parity_digest});
    _require_runtime_result_exact(
        $decoded->{backend_evidence}, $contract->{backend_evidence},
        '/result_produced/backend_evidence', 'backend evidence',
    );

    for my $field (@{$contract->{collection_keys}}) {
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime top-level collection is not one array',
            "/result_produced/$field")
            unless ref($decoded->{$field}) eq 'ARRAY'
                && !blessed($decoded->{$field});
    }
    for my $field (@{$contract->{empty_collection_keys}}) {
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime projection-only collection is not empty',
            "/result_produced/$field") if @{$decoded->{$field}};
    }
    for my $index (0 .. $#{$decoded->{random_decisions}}) {
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime random decision is not one object',
            "/result_produced/random_decisions/$index")
            unless ref($decoded->{random_decisions}[$index]) eq 'HASH'
                && !blessed($decoded->{random_decisions}[$index]);
    }
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime random decisions differ from plan authority',
        '/result_produced/random_decisions')
        unless sha256_hex(_canonical($decoded->{random_decisions}))
            eq $expected_random_decisions_sha256;

    my $metrics = _validate_runtime_result_metrics($decoded, $contract);
    my $coverage = _validate_runtime_result_coverage($decoded, $contract);
    my $fault = _validate_runtime_result_fault($decoded, $contract);
    my $scoreboard = _validate_runtime_result_scoreboard($decoded, $contract);
    my $diagnostics = _validate_runtime_result_diagnostics(
        $decoded, $contract, $expected_diagnostic_codes,
    );

    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime coverage metrics differ from their coverage record',
        '/result_produced/metrics')
        unless $metrics->{coverage_not_stalled}
                == $coverage->{bins}{not_stalled}
            && $metrics->{coverage_stalled}
                == $coverage->{bins}{stalled}
            && $metrics->{coverage_not_stalled} + $metrics->{coverage_stalled}
                == $expected_counts->{coverage};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime diagnostic metric differs from its collection',
        '/result_produced/metrics/diagnostic_records')
        unless $metrics->{diagnostic_records} == @$diagnostics;
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime diagnostic count differs from authenticated trace records',
        '/result_produced/diagnostics')
        unless @$diagnostics == $expected_counts->{expectations};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime fault metric differs from its fault record',
        '/result_produced/metrics/fault_applications')
        unless $metrics->{fault_applications} == $fault->{applications};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime scoreboard-comparison metric differs from its record',
        '/result_produced/metrics/scoreboard_comparisons')
        unless $metrics->{scoreboard_comparisons}
            == $scoreboard->{comparisons};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime scoreboard-mismatch metric differs from its record',
        '/result_produced/metrics/scoreboard_mismatches')
        unless $metrics->{scoreboard_mismatches}
            == $scoreboard->{mismatches};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime fault applications differ from authenticated trace records',
        '/result_produced/faults/0/applications')
        unless 2 * $fault->{applications} == $expected_counts->{faults};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime scoreboard comparisons differ from authenticated trace records',
        '/result_produced/scoreboards/0/comparisons')
        unless 2 * $scoreboard->{comparisons}
            == $expected_counts->{scoreboards};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime passing result contains a scoreboard mismatch',
        '/result_produced/metrics/scoreboard_mismatches')
        if $metrics->{scoreboard_mismatches} != 0;
    return;
}

sub _validate_runtime_result_metrics($decoded, $contract) {
    my $metrics = $decoded->{metrics};
    _require_runtime_result_keys(
        $metrics, $contract->{metric_keys},
        '/result_produced/metrics', 'runtime metrics',
    );
    for my $field (@{$contract->{metric_keys}}) {
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime metric is not a nonnegative integer',
            "/result_produced/metrics/$field")
            unless _runtime_result_nonnegative_integer($metrics->{$field});
    }
    return $metrics;
}

sub _validate_runtime_result_coverage($decoded, $contract) {
    my $coverage = $decoded->{coverage};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result does not contain one coverage record',
        '/result_produced/coverage') unless @$coverage == 1;
    my $record = $coverage->[0];
    _require_runtime_result_keys(
        $record, $contract->{coverage_record_keys},
        '/result_produced/coverage/0', 'coverage record',
    );
    _require_runtime_result_keys(
        $record->{bins}, $contract->{coverage_bin_keys},
        '/result_produced/coverage/0/bins', 'coverage bins',
    );
    for my $field (@{$contract->{coverage_bin_keys}}) {
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime coverage bin is not a nonnegative integer',
            "/result_produced/coverage/0/bins/$field")
            unless _runtime_result_nonnegative_integer($record->{bins}{$field});
    }
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime coverage record uses a foreign coverpoint',
        '/result_produced/coverage/0/coverpoint_id')
        unless defined($record->{coverpoint_id})
            && !ref($record->{coverpoint_id})
            && $record->{coverpoint_id} eq $contract->{coverage_coverpoint_id};
    return $record;
}

sub _validate_runtime_result_fault($decoded, $contract) {
    my $faults = $decoded->{faults};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result does not contain one fault record',
        '/result_produced/faults') unless @$faults == 1;
    my $record = $faults->[0];
    _require_runtime_result_keys(
        $record, $contract->{fault_record_keys},
        '/result_produced/faults/0', 'fault record',
    );
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime fault application count is not a nonnegative integer',
        '/result_produced/faults/0/applications')
        unless _runtime_result_nonnegative_integer($record->{applications});
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result uses a foreign fault projection',
        '/result_produced/faults/0')
        unless defined($record->{fault_id}) && !ref($record->{fault_id})
            && $record->{fault_id} eq $contract->{fault_id}
            && defined($record->{kind}) && !ref($record->{kind})
            && $record->{kind} eq $contract->{fault_kind};
    return $record;
}

sub _validate_runtime_result_scoreboard($decoded, $contract) {
    my $scoreboards = $decoded->{scoreboards};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime result does not contain one scoreboard record',
        '/result_produced/scoreboards') unless @$scoreboards == 1;
    my $record = $scoreboards->[0];
    _require_runtime_result_keys(
        $record, $contract->{scoreboard_record_keys},
        '/result_produced/scoreboards/0', 'scoreboard record',
    );
    for my $field (@{$contract->{scoreboard_record_keys}}) {
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime scoreboard value is not a nonnegative integer',
            "/result_produced/scoreboards/0/$field")
            unless _runtime_result_nonnegative_integer($record->{$field});
    }
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime scoreboard capacity differs from the VHDL contract',
        '/result_produced/scoreboards/0/capacity')
        unless $record->{capacity} == $contract->{scoreboard_capacity};
    return $record;
}

sub _validate_runtime_result_diagnostics(
    $decoded, $contract, $expected_diagnostic_codes,
) {
    my $diagnostics = $decoded->{diagnostics};
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        'GHDL runtime diagnostic count differs from emitted scenario authority',
        '/result_produced/diagnostics')
        unless @$diagnostics == @$expected_diagnostic_codes
            && @$diagnostics == @{$decoded->{scenario_results}};
    for my $index (0 .. $#$diagnostics) {
        my $path = "/result_produced/diagnostics/$index";
        my $diagnostic = $diagnostics->[$index];
        _require_runtime_result_keys(
            $diagnostic, $contract->{diagnostic_record_keys},
            $path, 'diagnostic record',
        );
        _require_runtime_result_keys(
            $diagnostic->{logical_time}, $contract->{diagnostic_time_keys},
            "$path/logical_time", 'diagnostic logical time',
        );
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime diagnostic code differs from emitted scenario authority',
            "$path/code")
            unless _runtime_result_identity($diagnostic->{code})
                && $diagnostic->{code} eq $expected_diagnostic_codes->[$index];
        for my $field (@{$contract->{diagnostic_time_keys}}) {
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime diagnostic time value is not a nonnegative integer',
                "$path/logical_time/$field")
                unless _runtime_result_nonnegative_integer(
                    $diagnostic->{logical_time}{$field},
                );
        }
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime diagnostic phase rank is unsupported',
            "$path/logical_time/phase_rank")
            if $diagnostic->{logical_time}{phase_rank} > 3;
        my $expected_time = {
            cycle => $decoded->{scenario_results}[$index]{end_time}{cycle},
            local_index => $contract->{diagnostic_local_index},
            phase_rank => $contract->{diagnostic_phase_rank},
            static_rank => $contract->{diagnostic_static_rank},
        };
        for my $field (@{$contract->{diagnostic_time_keys}}) {
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime diagnostic time differs from scenario authority',
                "$path/logical_time/$field")
                unless $diagnostic->{logical_time}{$field}
                    == $expected_time->{$field};
        }
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime passing diagnostic has a foreign outcome or severity',
            $path)
            unless defined($diagnostic->{outcome})
                && !ref($diagnostic->{outcome})
                && $diagnostic->{outcome} eq 'pass'
                && defined($diagnostic->{severity})
                && !ref($diagnostic->{severity})
                && $diagnostic->{severity} eq 'info';
    }
    return $diagnostics;
}

sub _require_runtime_result_exact($actual, $expected, $path, $label) {
    _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
        "GHDL runtime $label differs from the VHDL result contract", $path)
        unless _canonical($actual) eq _canonical($expected);
    return;
}

sub _validate_runtime_result_scenario_values($decoded, $expected_domain_id) {
    my $time_keys = FSM::VIAL::Backend::ResultProducer->logical_time_keys;
    for my $index (0 .. $#{$decoded->{scenario_results}}) {
        my $entry = $decoded->{scenario_results}[$index];
        my $path = "/result_produced/scenario_results/$index";
        my $start = $entry->{start_time};
        my $end = $entry->{end_time};
        _require_runtime_result_keys(
            $start, $time_keys, "$path/start_time", 'scenario start time',
        );
        _require_runtime_result_keys(
            $end, $time_keys, "$path/end_time", 'scenario end time',
        );
        for my $time_name (qw(start_time end_time)) {
            my $time = $entry->{$time_name};
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime scenario domain identity is unsafe',
                "$path/$time_name/domain_id")
                unless _runtime_result_identity($time->{domain_id});
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime scenario domain differs from plan authority',
                "$path/$time_name/domain_id")
                unless $time->{domain_id} eq $expected_domain_id;
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime scenario cycle is not a nonnegative integer',
                "$path/$time_name/cycle")
                unless _runtime_result_nonnegative_integer($time->{cycle});
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime scenario ordinal is not a nonnegative integer',
                "$path/$time_name/ordinal")
                unless _runtime_result_nonnegative_integer($time->{ordinal});
        }
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime scenario end domain differs from its start domain',
            "$path/end_time/domain_id")
            unless $end->{domain_id} eq $start->{domain_id};
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime scenario start does not use cycle-zero drive origin',
            "$path/start_time/cycle") unless $start->{cycle} == 0;
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime scenario start does not use the drive phase',
            "$path/start_time/phase")
            unless defined($start->{phase}) && !ref($start->{phase})
                && $start->{phase} eq 'drive';
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime scenario end does not use the check phase',
            "$path/end_time/phase")
            unless defined($end->{phase}) && !ref($end->{phase})
                && $end->{phase} eq 'check';
        for my $time_name (qw(start_time end_time)) {
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime scenario boundary ordinal is not zero',
                "$path/$time_name/ordinal")
                unless $entry->{$time_name}{ordinal} == 0;
        }
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime scenario logical cycle count is not positive',
            "$path/logical_cycle_count")
            unless _runtime_result_positive_integer(
                $entry->{logical_cycle_count},
            );
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime scenario end cycle differs from its cycle count',
            "$path/end_time/cycle")
            unless $end->{cycle} == $entry->{logical_cycle_count} - 1;
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime passing scenario has a foreign completion reason',
            "$path/completion_reason")
            unless defined($entry->{completion_reason})
                && !ref($entry->{completion_reason})
                && $entry->{completion_reason} eq 'completed';
        for my $collection_name (qw(
            expectation_ids diagnostic_ids cancelled_fiber_ids
        )) {
            my $collection = $entry->{$collection_name};
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime scenario identity collection is not one array',
                "$path/$collection_name")
                unless ref($collection) eq 'ARRAY' && !blessed($collection);
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime scenario identity projection is not empty',
                "$path/$collection_name") if @$collection;
        }
    }
    return;
}

sub _validate_runtime_result_outcome_values($decoded, $catalog) {
    die "GHDL runtime expected observation catalog is invalid\n"
        unless ref($catalog) eq 'HASH' && !blessed($catalog)
            && ref($catalog->{entries}) eq 'ARRAY'
            && !blessed($catalog->{entries});
    my %catalog_width;
    for my $entry (@{$catalog->{entries}}) {
        die "GHDL runtime expected observation catalog entry is invalid\n"
            unless ref($entry) eq 'HASH' && !blessed($entry)
                && _runtime_result_identity($entry->{semantic_id})
                && _runtime_result_positive_integer($entry->{width})
                && !exists($catalog_width{$entry->{semantic_id}});
        $catalog_width{$entry->{semantic_id}} = 0 + $entry->{width};
    }

    my $scalar_binding =
        FSM::VIAL::Backend::VHDLResultSchema->parity_scalar_catalog_bindings;
    my $bit_binding =
        FSM::VIAL::Backend::VHDLResultSchema->parity_bit_catalog_bindings;
    for my $field (sort keys %$scalar_binding) {
        my $semantic_id = $scalar_binding->{$field};
        die "GHDL runtime expected scalar observation is not one catalog bit\n"
            unless ($catalog_width{$semantic_id} // 0) == 1;
    }
    for my $field (sort keys %$bit_binding) {
        my $semantic_id = $bit_binding->{$field};
        die "GHDL runtime expected vector observation is absent from the catalog\n"
            unless ($catalog_width{$semantic_id} // 0) >= 1;
    }

    my $outcomes = $decoded->{parity_projection}{outcomes};
    my $scenario_results = $decoded->{scenario_results};
    die "GHDL runtime result outcome/scenario collections are invalid\n"
        unless ref($outcomes) eq 'ARRAY' && !blessed($outcomes)
            && ref($scenario_results) eq 'ARRAY'
            && !blessed($scenario_results)
            && @$outcomes == @$scenario_results;
    my $counter_keys =
        FSM::VIAL::Backend::VHDLResultSchema->parity_counter_keys;
    my $scalar_keys =
        FSM::VIAL::Backend::VHDLResultSchema->parity_scalar_keys;
    for my $index (0 .. $#$outcomes) {
        my $path = "/result_produced/parity_projection/outcomes/$index";
        my $outcome = $outcomes->[$index];
        my $cycle_count = $scenario_results->[$index]{logical_cycle_count};
        die "GHDL runtime validated scenario cycle count is invalid\n"
            unless _runtime_result_positive_integer($cycle_count);
        for my $field (@$counter_keys) {
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime parity counter is not a nonnegative integer',
                "$path/$field")
                unless _runtime_result_nonnegative_integer($outcome->{$field});
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime parity counter exceeds its scenario cycle count',
                "$path/$field") if $outcome->{$field} > $cycle_count;
        }
        for my $field (@$scalar_keys) {
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime passing parity scalar is not zero or one',
                "$path/$field")
                unless defined($outcome->{$field}) && !ref($outcome->{$field})
                    && $outcome->{$field} =~ /\A[01]\z/;
        }
        for my $field (sort keys %$bit_binding) {
            my $bits = $outcome->{$field};
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime parity bits use a foreign normalized alphabet',
                "$path/$field")
                unless defined($bits) && !ref($bits)
                    && $bits =~ /\A[01XZ]+\z/;
            my $expected_width =
                $catalog_width{$bit_binding->{$field}};
            _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
                'GHDL runtime parity bit width differs from its observation catalog entry',
                "$path/$field") unless length($bits) == $expected_width;
        }
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime final nonzero read data has no counted nonzero cycle',
            "$path/nonzero_read_data_cycles")
            if $outcome->{final_read_data_bits} =~ /1/
                && $outcome->{nonzero_read_data_cycles} == 0;
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime asserted final response has no counted error cycle',
            "$path/response_error_cycles")
            if $outcome->{final_response} == 1
                && $outcome->{response_error_cycles} == 0;
        _throw('VIAL_GHDL_LIFECYCLE_RESULT_ERROR',
            'GHDL runtime deasserted final ready has no counted ready-low cycle',
            "$path/ready_low_cycles")
            if $outcome->{final_ready} == 0
                && $outcome->{ready_low_cycles} == 0;
    }
    return;
}

sub _runtime_result_identity($value) {
    return defined($value) && !ref($value)
        && length($value) >= 1 && length($value) <= 4_096
        && $value =~ /\A[A-Za-z0-9_.:\/-]+\z/;
}

sub _runtime_result_nonnegative_integer($value) {
    return defined($value) && !ref($value)
        && _canonical($value) =~ /\A(?:0|[1-9][0-9]*)\z/;
}

sub _runtime_result_positive_integer($value) {
    return defined($value) && !ref($value)
        && _canonical($value) =~ /\A[1-9][0-9]*\z/;
}

sub _phase_assembled($session) {
    return _phase_osvvm_assembled($session)
        if _is_osvvm_role($session->{role});
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

sub _phase_osvvm_assembled($session) {
    my $repetitions = $session->{validation}{run_repetitions};
    my $assembly = {
        schema => 'fsmgen.vial_ghdl_lifecycle_osvvm_assembly.v2',
        schema_version => 2,
        lifecycle_identity => $session->{lifecycle_identity},
        fixture_runtime_output_sha256 => [map {
            _object_by_kind(
                $session->{objects}, "fixture_runtime_output_$_",
            )->{sha256}
        } 0 .. $repetitions - 1],
        provider_runtime_output_sha256 => [map {
            _object_by_kind(
                $session->{objects}, "provider_runtime_output_$_",
            )->{sha256}
        } 0 .. $repetitions - 1],
        provider_report_sha256 => [map {
            my $run = $_;
            [map {
                _object_by_kind(
                    $session->{objects}, "provider_report_${run}_$_",
                )->{sha256}
            } 0 .. $#{$session->{commands}{provider_reports}}]
        } 0 .. $repetitions - 1],
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
    _validate_current_sources($session)
        unless _is_osvvm_role($session->{role});
    my ($timeout, $limit) = @{$PHASE_POLICY{$phase}};
    return _run_command(
        $session, $phase, $argv, $timeout, $limit, "GHDL $phase",
    );
}

sub _run_command($session, $phase, $argv, $timeout, $limit, $label) {
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
        "$label exceeded its exact deadline", "/$phase")
        if $capture->{timed_out};
    _throw('VIAL_GHDL_LIFECYCLE_LIMIT_ERROR',
        "$label exceeded its exact capture ceiling", "/$phase")
        if $capture->{output_limited};
    _throw('VIAL_GHDL_LIFECYCLE_EXECUTION_ERROR',
        "$label failed: " . _process_summary($capture), "/$phase")
        unless $capture->{ok} && $capture->{exit_code} == 0
            && $capture->{signal} == 0;
    return $capture;
}

sub _validate_osvvm_execution_inputs($session) {
    _validate_current_provider($session);
    _validate_current_sources($session);
    _validate_osvvm_settings($session);
}

sub _finish($session) {
    _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        'only the exact assembled state may finish', '/handle/state')
        unless $session->{handle}{state} eq 'assembled'
            && ($session->{handle}{next_state} // '') eq 'cleaned';
    my $assembled = _is_osvvm_role($session->{role})
        ? _osvvm_assembled_result($session) : {
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
        schema => $session->{handle_schema},
        schema_version => $session->{schema_version},
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

sub _osvvm_assembled_result($session) {
    my $repetitions = $session->{validation}{run_repetitions};
    my @reports;
    for my $run (0 .. $repetitions - 1) {
        my @snapshot;
        for my $index (0 .. $#{$session->{commands}{provider_reports}}) {
            my $authority = $session->{commands}{provider_reports}[$index];
            my $content = _object_content(
                $session, "provider_report_${run}_$index",
            );
            push @snapshot, {
                relpath => $authority->{relpath},
                name => $authority->{name},
                bytes => bytes::length($content),
                sha256 => sha256_hex($content),
                content => $content,
            };
        }
        push @reports, \@snapshot;
    }
    my $provider_output_bytes = 0;
    for my $index (0 .. $#{$session->{commands}{provider_analyze}}) {
        $provider_output_bytes += _object_by_kind(
            $session->{objects},
            sprintf('provider_analysis_output_%02d', $index),
        )->{bytes};
    }
    return {
        fixture_runtime_outputs => [map {
            _object_content($session, "fixture_runtime_output_$_")
        } 0 .. $repetitions - 1],
        provider_runtime_outputs => [map {
            _object_content($session, "provider_runtime_output_$_")
        } 0 .. $repetitions - 1],
        provider_reports => \@reports,
        provider_compiler_output_bytes => $provider_output_bytes,
        generated_settings_sha256 =>
            $session->{commands}{generated_settings}{sha256},
        trace_validation => $JSON->decode(
            _object_content($session, 'validated_trace'),
        ),
        normalized_result => $JSON->decode(
            _object_content($session, 'normalized_result'),
        ),
    };
}

sub _persist($session, $state_name, $predecessor, $evidence) {
    my $ordinal = $STATE_ORDINAL{$state_name};
    my $record = {
        schema => $session->{state_schema},
        schema_version => $session->{schema_version},
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
        schema => $session->{handle_schema},
        schema_version => $session->{schema_version},
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
        unless ($record->{schema} // '') eq $session->{state_schema}
            && ($record->{schema_version} // 0)
                == $session->{schema_version}
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
        $record->{evidence}, _evidence_keys($session, $state),
        "GHDL $state evidence",
    );
    my @expected = _expected_objects($session, $state);
    my @actual = map { $_->{kind} } @{$record->{objects}};
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'GHDL state object inventory is not exact', '/objects')
        unless _canonical(\@actual) eq _canonical(\@expected);
    if ($state eq 'tool_verified'
            || (!_is_osvvm_role($session->{role})
                && $state =~ /\A(?:analyzed|elaborated)\z/)) {
        _closed($record->{evidence}{capture}, \@CAPTURE_KEYS,
            "GHDL $state capture");
    }
    if ($state eq 'ran' && !_is_osvvm_role($session->{role})) {
        _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
            'GHDL run capture cardinality is not exact', '/evidence/captures')
            unless ref($record->{evidence}{captures}) eq 'ARRAY'
                && @{$record->{evidence}{captures}}
                    == $session->{validation}{run_repetitions};
        _closed($_, \@CAPTURE_KEYS, 'GHDL run capture')
            for @{$record->{evidence}{captures}};
    }
    if (_is_osvvm_role($session->{role})) {
        _validate_osvvm_capture_shape($session, $record);
    }
}

sub _evidence_keys($session, $state) {
    return $EVIDENCE_KEYS{$state}
        unless _is_osvvm_role($session->{role});
    my %keys = (
        admitted => [qw(
            authority_sha256 workspace_files workspace_sha256
        )],
        prepared => [qw(
            library_identities source_count settings_sha256
            workspace_files workspace_sha256
        )],
        tool_verified => [qw(
            version_sha256 capture workspace_files workspace_sha256
        )],
        analyzed => [qw(
            command_digests captures output_sha256
            generated_command_digest generated_capture
            generated_output_sha256 workspace_files workspace_sha256
        )],
        elaborated => [qw(
            command_digests captures output_sha256
            workspace_files workspace_sha256
        )],
        ran => [qw(
            command_digests fixture_captures provider_captures
            fixture_output_sha256 provider_output_sha256
            provider_report_sha256 deterministic
            workspace_files workspace_sha256
        )],
        trace_validated => $EVIDENCE_KEYS{trace_validated},
        result_produced => $EVIDENCE_KEYS{result_produced},
        assembled => $EVIDENCE_KEYS{assembled},
    );
    return $keys{$state};
}

sub _expected_objects($session, $state) {
    my @expected = qw(lifecycle_authority);
    if (_is_osvvm_role($session->{role})) {
        push @expected, 'generated_settings'
            if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{prepared};
        push @expected, 'tool_version_output'
            if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{tool_verified};
        if ($STATE_ORDINAL{$state} >= $STATE_ORDINAL{analyzed}) {
            push @expected, map { sprintf('provider_analysis_output_%02d', $_) }
                0 .. $#{$session->{commands}{provider_analyze}};
            push @expected, 'generated_analysis_output';
        }
        if ($STATE_ORDINAL{$state} >= $STATE_ORDINAL{elaborated}) {
            push @expected, qw(
                fixture_elaboration_output
                provider_probe_elaboration_output
            );
        }
        if ($STATE_ORDINAL{$state} >= $STATE_ORDINAL{ran}) {
            my $repetitions = $session->{validation}{run_repetitions};
            push @expected, map { "fixture_runtime_output_$_" }
                0 .. $repetitions - 1;
            for my $run (0 .. $repetitions - 1) {
                push @expected, "provider_runtime_output_$run";
                push @expected, map { "provider_report_${run}_$_" }
                    0 .. $#{$session->{commands}{provider_reports}};
            }
        }
    }
    else {
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
    }
    push @expected, 'validated_trace'
        if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{trace_validated};
    push @expected, 'normalized_result'
        if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{result_produced};
    push @expected, 'assembly_payload'
        if $STATE_ORDINAL{$state} >= $STATE_ORDINAL{assembled};
    return @expected;
}

sub _validate_osvvm_capture_shape($session, $record) {
    my $state = $record->{state};
    if ($state eq 'analyzed') {
        my $count = scalar(@{$session->{commands}{provider_analyze}});
        _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
            'OSVVM provider-analysis capture cardinality is not exact',
            '/evidence/captures')
            unless ref($record->{evidence}{captures}) eq 'ARRAY'
                && @{$record->{evidence}{captures}} == $count;
        _closed($_, \@CAPTURE_KEYS, 'OSVVM provider-analysis capture')
            for @{$record->{evidence}{captures}};
        _closed($record->{evidence}{generated_capture}, \@CAPTURE_KEYS,
            'OSVVM generated-analysis capture');
    }
    elsif ($state eq 'elaborated') {
        _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
            'OSVVM elaboration capture cardinality is not exact',
            '/evidence/captures')
            unless ref($record->{evidence}{captures}) eq 'ARRAY'
                && @{$record->{evidence}{captures}} == 2;
        _closed($_, \@CAPTURE_KEYS, 'OSVVM elaboration capture')
            for @{$record->{evidence}{captures}};
    }
    elsif ($state eq 'ran') {
        my $count = $session->{validation}{run_repetitions};
        for my $name (qw(fixture_captures provider_captures)) {
            _throw('VIAL_GHDL_LIFECYCLE_STATE_ERROR',
                'OSVVM runtime capture cardinality is not exact',
                "/evidence/$name")
                unless ref($record->{evidence}{$name}) eq 'ARRAY'
                    && @{$record->{evidence}{$name}} == $count;
            _closed($_, \@CAPTURE_KEYS, 'OSVVM runtime capture')
                for @{$record->{evidence}{$name}};
        }
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

sub _snapshot_osvvm_reports($session, $run_index) {
    my $reports_rel = "$session->{stage_rel}/provider_reports";
    my $reports_abs = _repo_path($session->{repo_root}, $reports_rel);
    opendir my $dh, $reports_abs or _throw(
        'VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'cannot inspect OSVVM provider reports', '/ran/provider_reports',
    );
    my @actual = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    my @expected = sort map { $_->{name} }
        @{$session->{commands}{provider_reports}};
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'OSVVM provider report inventory is not exact',
        '/ran/provider_reports') unless _canonical(\@actual)
            eq _canonical(\@expected);
    my @snapshot;
    for my $index (0 .. $#{$session->{commands}{provider_reports}}) {
        my $authority = $session->{commands}{provider_reports}[$index];
        my $absolute = _repo_path(
            $session->{repo_root}, $authority->{relpath},
        );
        _regular_same_volume(
            $absolute, $authority->{relpath}, $session->{root_device},
        );
        my $content = _slurp($absolute);
        push @{$session->{objects}}, _write_object(
            $session, "provider_report_${run_index}_$index", $content, 0,
        );
        push @snapshot, {
            name => $authority->{name},
            bytes => bytes::length($content),
            sha256 => sha256_hex($content),
        };
    }
    return \@snapshot;
}

sub _clear_osvvm_reports($session) {
    for my $authority (@{$session->{commands}{provider_reports}}) {
        my $absolute = _repo_path(
            $session->{repo_root}, $authority->{relpath},
        );
        _regular_same_volume(
            $absolute, $authority->{relpath}, $session->{root_device},
        );
        unlink $absolute or _throw(
            'VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
            'cannot remove one sealed OSVVM report between executions',
            '/ran/provider_reports',
        );
    }
}

sub _validate_osvvm_settings($session) {
    my $settings = $session->{commands}{generated_settings};
    my $absolute = _repo_path($session->{repo_root}, $settings->{relpath});
    _regular_same_volume(
        $absolute, $settings->{relpath}, $session->{root_device},
    );
    _throw('VIAL_GHDL_LIFECYCLE_OBJECT_ERROR',
        'generated OSVVM settings changed after preparation',
        '/commands/generated_settings')
        unless -s $absolute == $settings->{bytes}
            && _file_sha256($absolute) eq $settings->{sha256}
            && _slurp($absolute) eq $settings->{content};
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
    my $cleanup = defined($session)
        ? $session->{failure_cleanup} : undef;
    if (defined($session) && $session->{cleanup_on_error}
            && _owner_matches($session)) {
        my $removed = eval { _remove_owned_root($session); 1 };
        my $cleanup_error = $@;
        if (!$removed) {
            if (blessed($cleanup_error)
                    && $cleanup_error->isa(
                        'FSM::VIAL::Backend::GHDLLifecycle::Failure'
                    )) {
                ($code, $message, $path) =
                    @{$cleanup_error}{qw(code message path)};
            }
            else {
                ($code, $message, $path) = (
                    'VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR',
                    _sanitize($cleanup_error), '/cleanup',
                );
            }
        }
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
            predecessor_identity => $state->{predecessor_identity},
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
        ? $capture->{output} : ($capture->{exec_error} // '');
    $summary = sprintf(
        'exit=%d signal=%d exec_failed=%d timed_out=%d output_limited=%d',
        map { 0 + ($capture->{$_} // 0) }
            qw(exit_code signal exec_failed timed_out output_limited),
    ) unless length $summary;
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
