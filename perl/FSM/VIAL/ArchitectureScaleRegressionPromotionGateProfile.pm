package FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile;

use v5.20;
use strict;
use warnings;

use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use Errno qw(EAGAIN EINTR EWOULDBLOCK);
use Fcntl qw(
    FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL O_NONBLOCK
);
use File::Spec;
use File::Temp qw(tempfile);
use JSON::PP ();
use POSIX qw(
    WEXITSTATUS WIFEXITED WIFSIGNALED WNOHANG WTERMSIG _exit setpgid
);
use Scalar::Util qw(blessed);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Support::VIALVHDLEmissionContract qw(
    build_vial_vhdl_emission_contract
);
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract;
use FSM::VIAL::ArchitectureScaleRegressionPromotionQualification;
use FSM::VIAL::Backend::OSVVM2026_05Materialization;
use FSM::VIAL::Backend::ProcessSupervisor;

my $CONTRACT =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract';
my $QUALIFICATION =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualification';
my $OSVVM = 'FSM::VIAL::Backend::OSVVM2026_05Materialization';
my $SUPERVISOR = 'FSM::VIAL::Backend::ProcessSupervisor';
my $COORDINATOR =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator';
my $SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_gate_profile_result.v1';
my $WORKER_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_gate_profile_worker.v1';
my $RESULT_IDENTITY_PREFIX = 'regression-promotion-gate-profile-result/';
my $CORRECTNESS_IDENTITY_PREFIX = 'regression-promotion-correctness/';
my $REVISION = 'regression_promotion_gate_profile_v1';
my $WORKER_TIMEOUT_SECONDS = 4_000;
my $VERSION_TIMEOUT_SECONDS = 10;
my $VERSION_CAPTURE_BYTES = 65_536;
my $OSVVM_ROOT = '.artifacts/cache/providers/osvvm/2026.05/source';
my $MAX_SAFE_INTEGER = 9_007_199_254_740_991;

my @RESULT_KEYS = qw(
    schema schema_version profile_result_identity contract_identity
    qualification_identity qualification_publication_identity
    qualification_file_set_sha256 ordinal selection_key execution_revision
    report observation observed_environment provider performance outcome
    diagnostics cleanup explicit_nonclaims
);
my @REPORT_RESULT_KEYS = qw(identity sha256 bytes);
my @OBSERVATION_KEYS = qw(
    validation_records raw_measurement_records controller_invocations
    sample_exclusions validation_identity raw_measurement_identities
    accepted_run_totals observed_maximum workload_identity
    correctness_projection_identity
);
my @ENVIRONMENT_KEYS = qw(
    environment_identity host_profile tool_profile resource_guard
    provider_status
);
my @PROVIDER_KEYS = qw(
    requirement availability reason observed_tool_profile
);
my @PERFORMANCE_KEYS = qw(
    classification reason exact_environment qualified_budget
    observed_maximum comparisons
);
my @COMPARISON_KEYS = qw(observed budget within_budget);
my @METRICS = qw(wall_time_ns cpu_time_ns peak_tree_rss_bytes);
my @RUN_TOTAL_KEYS = qw(
    measurement_identity run_ordinal wall_time_ns cpu_time_ns
    peak_tree_rss_bytes
);
my @CLEANUP_KEYS = qw(
    anonymous_report_spool_removed worker_process_residue
);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @PROVIDER_REQUIREMENT_KEYS = qw(
    kind external_verification_tool logical_name provider_identity
    tool_profile_identity
);
my @WORKER_ENVELOPE_KEYS = qw(schema schema_version ok payload error);
my @NONCLAIMS = qw(
    qualification_evidence
    qualification_recalibration
    qualification_overwrite
    historical_artifact_reuse
    support_promotion
    architecture_scale_capacity
    whole_product_capacity
);
my @OSVVM_VOLATILE_LIFECYCLE_STAGES = qw(
    compile_analyze elaborate run trace_validate result_produce publish
);
my @PORTABLE_VOLATILE_LIFECYCLE_STAGES = qw(
    compile_analyze run trace_validate result_produce publish
);
my $OSVVM_RUNTIME_MEASUREMENT_SCHEMA =
    'fsmgen.vial_architecture_scale_osvvm_runtime_measurement_set.v1';
my $PORTABLE_RUNTIME_MEASUREMENT_SCHEMA =
    'fsmgen.vial_architecture_scale_portable_runtime_measurement_set.v1';
my $PORTABLE_VHDL_RUNTIME_MEASUREMENT_SCHEMA =
    'fsmgen.vial_architecture_scale_portable_vhdl_runtime_measurement_set.v1';
my $CORRECTNESS_PROJECTION_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_correctness.v1';
my $VOLATILE_DIGEST_SENTINEL = 'process-telemetry-derived';
my @STABLE_PROCESS_TELEMETRY_PROFILES = (
    {
        measurement_schema => $OSVVM_RUNTIME_MEASUREMENT_SCHEMA,
        backend_profile => 'vhdl_osvvm_qualified',
        lifecycle_prefix => 'osvvm_runtime',
        volatile_stages => \@OSVVM_VOLATILE_LIFECYCLE_STAGES,
        artifact_kind_overrides => {},
    },
    {
        measurement_schema => $PORTABLE_RUNTIME_MEASUREMENT_SCHEMA,
        backend_profile => 'sv_portable_verilator',
        lifecycle_prefix => 'portable_runtime',
        volatile_stages => \@PORTABLE_VOLATILE_LIFECYCLE_STAGES,
        artifact_kind_overrides => {},
    },
    {
        measurement_schema => $PORTABLE_VHDL_RUNTIME_MEASUREMENT_SCHEMA,
        backend_profile => 'vhdl_portable_ghdl',
        lifecycle_prefix => 'portable_runtime',
        volatile_stages => \@OSVVM_VOLATILE_LIFECYCLE_STAGES,
        artifact_kind_overrides => {
            publish => {
                evidence => 'portable_vhdl_lifecycle_evidence',
            },
        },
    },
);

my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub result_keys($class) {
    _exact_invocant($class, 'result_keys');
    return [@RESULT_KEYS];
}

sub observation_keys($class) {
    _exact_invocant($class, 'observation_keys');
    return [@OBSERVATION_KEYS];
}

sub profile_limits($class) {
    _exact_invocant($class, 'profile_limits');
    my $limits = $CONTRACT->contract_limits;
    return {
        implementation_revision => $REVISION,
        maximum_report_bytes => $limits->{maximum_profile_report_bytes},
        maximum_ipc_bytes => $limits->{maximum_profile_ipc_bytes},
        maximum_error_bytes => $limits->{maximum_error_bytes},
        worker_timeout_seconds => $WORKER_TIMEOUT_SECONDS,
        validation_records => 1,
        raw_measurement_records => 3,
        controller_invocations => 4,
    };
}

sub run($class, @args) {
    _exact_invocant($class, 'run');
    my $request = _request('run', \@args, [qw(repository_root ordinal)]);
    _require_active_guard();
    my $repository_root = _repository_root($request->{repository_root});
    confess "regression gate profile ordinal is invalid\n"
        unless _json_positive_integer($request->{ordinal});
    my $contract = $CONTRACT->derive({
        repository_root => $repository_root,
    });
    my $profile = _contract_profile($contract, $request->{ordinal});
    my $execution_revision = _require_clean_revision($repository_root);
    return _clone(_run_authorized({
        repository_root => $repository_root,
        contract => $contract,
        profile => $profile,
        execution_revision => $execution_revision,
    }));
}

sub _run_for_coordinator($class, @args) {
    _exact_invocant($class, '_run_for_coordinator');
    confess "regression gate profile coordinator execution is caller-sealed\n"
        unless (caller)[0] eq $COORDINATOR;
    my $request = _request(
        '_run_for_coordinator', \@args,
        [qw(repository_root ordinal contract execution_revision)],
    );
    _require_active_guard();
    my $repository_root = _repository_root($request->{repository_root});
    confess "regression gate profile ordinal is invalid\n"
        unless _json_positive_integer($request->{ordinal});
    confess "regression gate profile coordinator contract is invalid\n"
        unless ref($request->{contract}) eq 'HASH'
            && !blessed($request->{contract});
    confess "regression gate profile coordinator revision is invalid\n"
        unless defined($request->{execution_revision})
            && !ref($request->{execution_revision})
            && $request->{execution_revision} =~ /\A[0-9a-f]{40}\z/;
    my $profile = _contract_profile(
        $request->{contract}, $request->{ordinal},
    );
    _require_unchanged_clean_revision(
        $repository_root, $request->{execution_revision},
    );
    return _clone(_run_authorized({
        repository_root => $repository_root,
        contract => $request->{contract},
        profile => $profile,
        execution_revision => $request->{execution_revision},
    }));
}

sub _admit_for_coordinator($class, @args) {
    _exact_invocant($class, '_admit_for_coordinator');
    confess "regression gate profile coordinator admission is caller-sealed\n"
        unless (caller)[0] eq $COORDINATOR;
    my $request = _request(
        '_admit_for_coordinator', \@args,
        [qw(result contract execution_revision)],
    );
    confess "regression gate profile coordinator result is invalid\n"
        unless ref($request->{result}) eq 'HASH'
            && !blessed($request->{result});
    confess "regression gate profile coordinator contract is invalid\n"
        unless ref($request->{contract}) eq 'HASH'
            && !blessed($request->{contract});
    confess "regression gate profile coordinator revision is invalid\n"
        unless defined($request->{execution_revision})
            && !ref($request->{execution_revision})
            && $request->{execution_revision} =~ /\A[0-9a-f]{40}\z/;
    my $ordinal = $request->{result}{ordinal};
    confess "regression gate profile coordinator result ordinal is invalid\n"
        unless _json_positive_integer($ordinal);
    my $profile = _contract_profile($request->{contract}, $ordinal);
    _validate_result(
        $request->{result}, $request->{contract}, $profile,
        $request->{execution_revision},
    );
    return _clone($request->{result});
}

sub _run_authorized($request) {
    my ($repository_root, $contract, $profile, $execution_revision) =
        @{$request}{qw(
            repository_root contract profile execution_revision
        )};
    my ($spool, $spool_removed) = _anonymous_report_spool($repository_root);
    my $worker_result;
    my $result;
    my $ok = eval {
        $worker_result = _run_worker({
            repository_root => $repository_root,
            contract => $contract,
            profile => $profile,
            execution_revision => $execution_revision,
            spool => $spool,
        });
        _require_unchanged_clean_revision(
            $repository_root, $execution_revision,
        );
        $result = _revalidate_worker_result({
            repository_root => $repository_root,
            contract => $contract,
            profile => $profile,
            execution_revision => $execution_revision,
            spool => $spool,
            worker_result => $worker_result,
        });
        _require_unchanged_clean_revision(
            $repository_root, $execution_revision,
        );
        1;
    };
    my $worker_error = $@ unless $ok;
    my $close_ok = close($spool);
    confess "regression gate profile report spool cleanup failed\n"
        unless $close_ok && $spool_removed;
    die $worker_error unless $ok;
    _validate_result($result, $contract, $profile, $execution_revision);
    return $result;
}

sub _revalidate_worker_result($raw) {
    my ($repo, $contract, $profile, $revision, $spool, $worker) =
        @{$raw}{qw(
            repository_root contract profile execution_revision spool
            worker_result
        )};
    _validate_result($worker, $contract, $profile, $revision);
    my $expected;
    if (($worker->{provider}{availability} // '') eq 'unavailable') {
        my $availability = _provider_availability($repo, $profile);
        confess "regression gate profile provider availability changed\n"
            unless ($availability->{availability} // '') eq 'unavailable';
        my $bytes = _read_spool($spool, 1);
        confess "unavailable regression gate profile produced report bytes\n"
            if bytes::length($bytes);
        $expected = _unavailable_result(
            $contract, $profile, $revision, $availability,
        );
    }
    else {
        my $maximum =
            $contract->{result_contract}{maximum_profile_report_bytes};
        my $bytes = _read_spool($spool, $maximum + 1);
        confess "regression gate profile report is absent\n"
            unless bytes::length($bytes);
        confess "regression gate profile report exceeds its byte bound\n"
            if bytes::length($bytes) > $maximum;
        confess "regression gate profile report spool binding changed\n"
            unless _json_integer_equals(
                    $worker->{report}{bytes}, bytes::length($bytes),
                )
                && ($worker->{report}{sha256} // '') eq sha256_hex($bytes);
        my $report = eval { JSON::PP->new->utf8(1)->decode($bytes) };
        confess "regression gate profile report is not valid JSON\n"
            unless defined $report;
        confess "regression gate profile report is not canonical JSON\n"
            unless _canonical_json($report) eq $bytes;
        my $adapter = $profile->{adapter_class};
        confess "regression gate profile parent adapter validator is unavailable\n"
            unless defined($adapter) && !ref($adapter)
                && $adapter->can('validate_report');
        my $validated = $adapter->validate_report({
            repository_root => $repo,
            report => $report,
        });
        confess "regression gate profile parent adapter changed the report\n"
            unless _canonical_json($validated) eq $bytes;
        $expected = _result_from_report(
            $repo, $contract, $profile, $revision, $report,
        );
    }
    confess "regression gate profile worker metadata changed in parent\n"
        unless _canonical_json($expected) eq _canonical_json($worker);
    return _clone($expected);
}

sub _execute_child($raw) {
    my ($repo, $contract, $profile, $revision, $spool) =
        @{$raw}{qw(
            repository_root contract profile execution_revision spool
        )};
    _require_unchanged_clean_revision($repo, $revision);
    my $availability = _provider_availability($repo, $profile);
    if (($availability->{availability} // '') eq 'unavailable') {
        return _unavailable_result(
            $contract, $profile, $revision, $availability,
        );
    }
    my $adapter = $profile->{adapter_class};
    my $method = $profile->{adapter_method};
    confess "regression gate profile adapter method is unavailable\n"
        unless defined($adapter) && !ref($adapter)
            && defined($method) && !ref($method)
            && $adapter->can($method);
    confess "regression gate profile adapter validator is unavailable\n"
        unless $adapter->can('validate_report');
    my $arguments = _clone($profile->{adapter_arguments});
    confess "regression gate profile contract injected repository_root\n"
        if exists $arguments->{repository_root};
    $arguments->{repository_root} = $repo;
    my $report = $adapter->$method($arguments);
    my $validated = $adapter->validate_report({
        repository_root => $repo,
        report => $report,
    });
    my $report_bytes = _canonical_json($report);
    confess "regression gate profile child adapter changed the report\n"
        unless _canonical_json($validated) eq $report_bytes;
    my $maximum = $contract->{result_contract}{maximum_profile_report_bytes};
    confess "regression gate profile report exceeds its byte bound\n"
        if bytes::length($report_bytes) > $maximum;
    my $result = _result_from_report(
        $repo, $contract, $profile, $revision, $report,
    );
    _write_spool($spool, $report_bytes);
    _require_unchanged_clean_revision($repo, $revision);
    return $result;
}

sub _result_from_report($repo, $contract, $profile, $revision, $report) {
    my ($common, $provider_status) =
        _admit_report($report, $profile, $revision);
    my $observation = _observe_report($report, $common);
    confess "regression gate profile workload identity changed\n"
        unless ($observation->{workload_identity} // '') eq
            ($profile->{workload_identity} // '');
    _admit_correctness_projection(
        $repo, $contract, $profile, $report, $observation,
    );

    my $environment = {
        environment_identity => undef,
        host_profile => _clone($common->{host_profile}),
        tool_profile => _clone($common->{tool_profile}),
        resource_guard => _clone($common->{resource_guard}),
        provider_status => _clone($provider_status),
    };
    $environment->{environment_identity} =
        'regression-promotion-environment/'
        . sha256_hex(_canonical_json($environment));
    my $exact_environment =
        _canonical_json($environment) eq
            _canonical_json($profile->{environment_identity});
    my $performance = _performance(
        $profile->{qualified_budget}, $observation->{observed_maximum},
        $exact_environment,
    );
    my $provider = {
        requirement => _clone($profile->{provider_requirement}),
        availability => 'available',
        reason => undef,
        observed_tool_profile => _clone($common->{tool_profile}),
    };
    my $report_bytes = _canonical_json($report);
    my $result = _base_result($contract, $profile, $revision);
    $result->{report} = {
        identity => $report->{report_identity},
        sha256 => sha256_hex($report_bytes),
        bytes => bytes::length($report_bytes),
    };
    $result->{observation} = {
        validation_records => 1,
        raw_measurement_records => 3,
        controller_invocations => 4,
        sample_exclusions => 0,
        validation_identity => $observation->{validation_identity},
        raw_measurement_identities =>
            _clone($observation->{raw_measurement_identities}),
        accepted_run_totals =>
            _clone($observation->{accepted_run_totals}),
        observed_maximum => _clone($observation->{observed_maximum}),
        workload_identity => $observation->{workload_identity},
        correctness_projection_identity =>
            $observation->{correctness_projection_identity},
    };
    $result->{observed_environment} = $environment;
    $result->{provider} = $provider;
    $result->{performance} = $performance;
    $result->{outcome} = $performance->{classification} eq 'fail'
        ? 'performance_failed'
        : $performance->{classification} eq 'informational'
            ? 'accepted_informational'
            : 'accepted';
    return _finalize_result($result, $contract, $profile, $revision);
}

sub _admit_correctness_projection(
    $repo, $contract, $profile, $report, $observation,
) {
    my $current_identity =
        $observation->{correctness_projection_identity} // '';
    my $qualified_identity =
        $profile->{correctness_projection_identity} // '';
    return 1 if $current_identity eq $qualified_identity;

    my $current = $QUALIFICATION->_gate_correctness_projection({
        measurement_set => $report,
    });
    confess "regression gate profile current correctness projection identity changed\n"
        unless $current_identity eq $CORRECTNESS_IDENTITY_PREFIX
            . sha256_hex(_canonical_json($current));
    my $evidence = $contract->{qualification_evidence};
    my $qualified = $CONTRACT->_qualified_correctness_projection({
        repository_root => $repo,
        ordinal => $profile->{ordinal},
        selection_key => $profile->{selection_key},
        correctness_projection_identity => $qualified_identity,
        qualification_identity => $evidence->{qualification_identity},
        publication_identity => $evidence->{publication_identity},
        qualification_file_set_sha256 =>
            $evidence->{qualification_file_set_sha256},
    });
    confess "regression gate profile qualified correctness projection identity changed\n"
        unless $qualified_identity eq $CORRECTNESS_IDENTITY_PREFIX
            . sha256_hex(_canonical_json($qualified));
    my $stable_current = _stable_correctness_projection($current);
    my $stable_qualified = _stable_correctness_projection($qualified);
    confess "regression gate profile correctness changed after stable projection"
        . " at ordinal $profile->{ordinal} selection '$profile->{selection_key}'\n"
        unless _canonical_json($stable_current) eq
            _canonical_json($stable_qualified);

    # The result records admission against the immutable qualification, not a
    # second public identity for volatile process telemetry.
    $observation->{correctness_projection_identity} = $qualified_identity;
    return 1;
}

sub _stable_correctness_projection($projection) {
    confess "regression gate correctness projection must be one unblessed hash\n"
        unless ref($projection) eq 'HASH' && !blessed($projection);
    my $stable = _clone($projection);
    my $report = $stable->{report_contract};
    return $stable unless ref($report) eq 'HASH' && !blessed($report);
    my ($profile) = grep {
        ($report->{schema} // '') eq $_->{measurement_schema}
            && ($report->{backend_profile} // '') eq $_->{backend_profile}
    } @STABLE_PROCESS_TELEMETRY_PROFILES;
    return $stable unless $profile
        && ($report->{family} // '') eq 'runtime_stream_v1'
        && ($report->{level} // '') eq 'gate_candidate_v1'
        && ($report->{primary_axis} // '') eq 'runtime_trace_records';

    confess "regression gate stable process-telemetry correctness projection schema changed\n"
        unless ($stable->{schema} // '') eq $CORRECTNESS_PROJECTION_SCHEMA
            && _json_integer_equals($stable->{schema_version}, 1);
    my $records = $stable->{record_projections};
    confess "regression gate stable process-telemetry correctness record topology changed\n"
        unless ref($records) eq 'ARRAY' && @$records == 4;
    for my $index (0 .. $#$records) {
        my $record = $records->[$index];
        my $run_class = $index ? 'gate_measurement' : 'validation';
        confess "regression gate stable process-telemetry correctness record order changed\n"
            unless ref($record) eq 'HASH' && !blessed($record)
                && ($record->{run_class} // '') eq $run_class
                && _json_integer_equals($record->{run_ordinal}, $index);
        _normalize_process_lifecycle_artifacts($record, $index, $profile);
        _normalize_process_lifecycle_oracles($record, $index, $profile);
        _normalize_process_lifecycle_stage_bytes($record, $index, $profile);
    }
    return $stable;
}

sub _normalize_process_lifecycle_artifacts(
    $record, $record_index, $profile,
) {
    my $artifacts = $record->{artifact_records};
    confess "regression gate stable process-telemetry artifact records changed\n"
        unless ref($artifacts) eq 'ARRAY';
    my @stages = @{$profile->{volatile_stages}};
    my %volatile_stage = map { ($_ => 1) } @stages;
    my %expected = map {
        ("outputs/$_/lifecycle-evidence.json" => [$_, 'evidence'])
    } @stages;
    $expected{"outputs/$_/lifecycle-handle.json"} = [$_, 'handle']
        for grep { $_ ne 'publish' } @stages;
    my %seen;
    for my $artifact (@$artifacts) {
        next unless ref($artifact) eq 'HASH' && !blessed($artifact);
        my $path = $artifact->{relative_path} // '';
        my $stage = $artifact->{stage} // '';
        next unless $volatile_stage{$stage}
            && $path =~ m{/lifecycle-(?:evidence|handle)\.json\z};
        my $coordinate = $expected{$path};
        my $expected_kind;
        if ($coordinate) {
            my $overrides =
                $profile->{artifact_kind_overrides}{$stage};
            $expected_kind = $overrides->{$coordinate->[1]}
                if ref($overrides) eq 'HASH';
            $expected_kind //=
                "$profile->{lifecycle_prefix}_lifecycle_$coordinate->[1]";
        }
        confess "regression gate unexpected volatile lifecycle artifact"
            . " at record $record_index stage '$stage' path '$path'\n"
            unless $coordinate
                && $coordinate->[0] eq $stage
                && ($artifact->{kind} // '') eq $expected_kind;
        confess "regression gate duplicate volatile lifecycle artifact"
            . " at record $record_index stage '$stage' path '$path'\n"
            if $seen{$path}++;
        confess "regression gate volatile lifecycle artifact digest changed shape\n"
            unless ($artifact->{sha256} // '') =~ /\A[0-9a-f]{64}\z/;
        $artifact->{sha256} = $VOLATILE_DIGEST_SENTINEL;
        if ($coordinate->[1] eq 'evidence') {
            _json_nonnegative_integer(
                $artifact->{bytes},
                'regression gate volatile lifecycle artifact bytes',
            );
            $artifact->{bytes} = 0;
        }
    }
    for my $path (sort keys %expected) {
        my $stage = $expected{$path}[0];
        confess "regression gate missing volatile lifecycle artifact"
            . " at record $record_index stage '$stage' path '$path'\n"
            unless ($seen{$path} // 0) == 1;
    }
    return 1;
}

sub _normalize_process_lifecycle_oracles($record, $record_index, $profile) {
    my $oracles = $record->{correctness_oracles};
    confess "regression gate stable process-telemetry correctness oracles changed\n"
        unless ref($oracles) eq 'ARRAY';
    my @stages = @{$profile->{volatile_stages}};
    my %volatile_stage = map { ($_ => 1) } @stages;
    my %seen;
    for my $oracle (@$oracles) {
        next unless ref($oracle) eq 'HASH' && !blessed($oracle);
        my $stage = $oracle->{stage} // '';
        next unless $volatile_stage{$stage};
        my $expected =
            "$profile->{lifecycle_prefix}_${stage}_lifecycle_canonical";
        confess "regression gate volatile lifecycle oracle at record"
            . " $record_index stage '$stage' changed\n"
            unless ($oracle->{oracle_id} // '') eq $expected;
        confess "regression gate volatile lifecycle oracle at record"
            . " $record_index stage '$stage' must occur exactly once\n"
            if $seen{$stage}++;
        confess "regression gate volatile lifecycle oracle identity changed shape\n"
            unless ($oracle->{evidence_identity} // '') =~ /\A[0-9a-f]{64}\z/;
        $oracle->{evidence_identity} = $VOLATILE_DIGEST_SENTINEL;
    }
    for my $stage (@stages) {
        confess "regression gate volatile lifecycle oracle at record"
            . " $record_index stage '$stage' must occur exactly once\n"
            unless ($seen{$stage} // 0) == 1;
    }
    return 1;
}

sub _normalize_process_lifecycle_stage_bytes(
    $record, $record_index, $profile,
) {
    my $measurements = $record->{stage_measurements};
    confess "regression gate stable process-telemetry stage measurements changed\n"
        unless ref($measurements) eq 'ARRAY';
    my @stages = @{$profile->{volatile_stages}};
    my %volatile_stage = map { ($_ => 1) } @stages;
    my %seen;
    for my $measurement (@$measurements) {
        next unless ref($measurement) eq 'HASH' && !blessed($measurement);
        my $stage = $measurement->{stage} // '';
        next unless $volatile_stage{$stage};
        confess "regression gate volatile lifecycle stage at record"
            . " $record_index stage '$stage' must occur exactly once\n"
            if $seen{$stage}++;
        confess "regression gate volatile lifecycle stage output bytes changed shape\n"
            unless ref($measurement->{output_counts}) eq 'HASH'
                && exists($measurement->{output_counts}{bytes});
        _json_nonnegative_integer(
            $measurement->{output_counts}{bytes},
            'regression gate volatile lifecycle stage output bytes',
        );
        $measurement->{output_counts}{bytes} = 0;
    }
    for my $stage (@stages) {
        confess "regression gate volatile lifecycle stage at record"
            . " $record_index stage '$stage' must occur exactly once\n"
            unless ($seen{$stage} // 0) == 1;
    }
    return 1;
}

sub _unavailable_result($contract, $profile, $revision, $availability) {
    confess "regression gate unavailable result lacks unavailable provider\n"
        unless ($profile->{provider_requirement}{kind} // '') eq
                'exact_tool_profile'
            && ($availability->{availability} // '') eq 'unavailable';
    my %comparison = map {
        ($_ => {
            observed => undef,
            budget => 0 + $profile->{qualified_budget}{$_},
            within_budget => undef,
        })
    } @METRICS;
    my $result = _base_result($contract, $profile, $revision);
    $result->{report} = {identity => undef, sha256 => undef, bytes => 0};
    $result->{observation} = {
        validation_records => 0,
        raw_measurement_records => 0,
        controller_invocations => 0,
        sample_exclusions => 0,
        validation_identity => undef,
        raw_measurement_identities => [],
        accepted_run_totals => [],
        observed_maximum => {map { ($_ => undef) } @METRICS},
        workload_identity => $profile->{workload_identity},
        correctness_projection_identity => undef,
    };
    $result->{observed_environment} = undef;
    $result->{provider} = {
        requirement => _clone($profile->{provider_requirement}),
        availability => 'unavailable',
        reason => $availability->{reason},
        observed_tool_profile =>
            _clone($availability->{observed_tool_profile}),
    };
    $result->{performance} = {
        classification => 'unavailable',
        reason => 'exact_provider_unavailable',
        exact_environment => JSON::PP::false,
        qualified_budget => _clone($profile->{qualified_budget}),
        observed_maximum => {map { ($_ => undef) } @METRICS},
        comparisons => \%comparison,
    };
    $result->{outcome} = 'unavailable';
    return _finalize_result($result, $contract, $profile, $revision);
}

sub _base_result($contract, $profile, $revision) {
    return {
        schema => $SCHEMA,
        schema_version => 1,
        profile_result_identity => undef,
        contract_identity => $contract->{contract_identity},
        qualification_identity =>
            $contract->{qualification_evidence}{qualification_identity},
        qualification_publication_identity =>
            $contract->{qualification_evidence}{publication_identity},
        qualification_file_set_sha256 =>
            $contract->{qualification_evidence}
                {qualification_file_set_sha256},
        ordinal => 0 + $profile->{ordinal},
        selection_key => $profile->{selection_key},
        execution_revision => $revision,
        report => undef,
        observation => undef,
        observed_environment => undef,
        provider => undef,
        performance => undef,
        outcome => undef,
        diagnostics => [],
        cleanup => {
            anonymous_report_spool_removed => JSON::PP::true,
            worker_process_residue => JSON::PP::false,
        },
        explicit_nonclaims => [@NONCLAIMS],
    };
}

sub _finalize_result($result, $contract, $profile, $revision) {
    $result->{profile_result_identity} =
        $RESULT_IDENTITY_PREFIX . sha256_hex(_canonical_json($result));
    _validate_result($result, $contract, $profile, $revision);
    my $bytes = _canonical_json($result);
    confess "regression gate profile result exceeds its IPC bound\n"
        if bytes::length($bytes) >
            $contract->{result_contract}{maximum_profile_ipc_bytes};
    return $result;
}

sub _performance($budget, $observed, $exact_environment) {
    my (%comparisons, $within_all);
    $within_all = 1;
    for my $metric (@METRICS) {
        my $actual = _json_nonnegative_integer(
            $observed->{$metric}, "regression gate observed $metric",
        );
        my $limit = _json_positive_integer_value(
            $budget->{$metric}, "regression gate budget $metric",
        );
        my $within = $actual <= $limit;
        $within_all &&= $within;
        $comparisons{$metric} = {
            observed => $actual,
            budget => $limit,
            within_budget => $within
                ? JSON::PP::true : JSON::PP::false,
        };
    }
    my ($classification, $reason) = !$exact_environment
        ? ('informational', 'environment_identity_mismatch')
        : $within_all
            ? ('pass', 'within_inclusive_qualified_budget')
            : ('fail', 'exceeded_qualified_budget');
    return {
        classification => $classification,
        reason => $reason,
        exact_environment => $exact_environment
            ? JSON::PP::true : JSON::PP::false,
        qualified_budget => _clone($budget),
        observed_maximum => _clone($observed),
        comparisons => \%comparisons,
    };
}

sub _observe_report($report, $common) {
    return $QUALIFICATION->_gate_observation({
        measurement_set => $report,
        common_identity => $common,
    });
}

sub _admit_report($report, $profile, $revision) {
    confess "regression gate profile report must be one unblessed hash\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    for my $key (qw(family level primary_axis backend_profile)) {
        my $expected = $profile->{report_coordinate_authority}{$key};
        if (defined $expected) {
            confess "regression gate report coordinate '$key' changed\n"
                unless defined($report->{$key}) && !ref($report->{$key})
                    && $report->{$key} eq $expected;
        }
        elsif (exists($report->{$key}) && defined($report->{$key})) {
            confess "regression gate report coordinate '$key' appeared\n";
        }
    }
    confess "regression gate report mode changed\n"
        unless ($report->{mode} // '') eq 'gate_measurement';
    confess "regression gate report identity is invalid\n"
        unless ($report->{report_identity} // '') =~
            m{\A[A-Za-z0-9_.-]+/[0-9a-f]{64}\z};
    confess "regression gate validation record is invalid\n"
        unless ref($report->{validation_record}) eq 'HASH'
            && !blessed($report->{validation_record});
    confess "regression gate measurement records are invalid\n"
        unless ref($report->{measurement_records}) eq 'ARRAY'
            && @{$report->{measurement_records}} == 3;
    confess "regression gate sample exclusions are invalid\n"
        unless ref($report->{sample_exclusions}) eq 'ARRAY'
            && !@{$report->{sample_exclusions}};
    confess "regression gate diagnostics are invalid\n"
        unless ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};
    confess "regression gate report outcome did not accept\n"
        unless ($report->{outcome} // '') eq 'accepted';
    my @records = (
        $report->{validation_record}, @{$report->{measurement_records}},
    );
    for my $index (0 .. $#records) {
        my $expected_class = $index ? 'gate_measurement' : 'validation';
        confess "regression gate record order changed\n"
            unless ($records[$index]{run_class} // '') eq $expected_class
                && _json_integer_equals($records[$index]{run_ordinal}, $index);
        confess "regression gate record $index did not accept\n"
            unless ($records[$index]{outcome} // '') eq 'accepted';
    }
    for my $key (qw(controller_applicability measurement_applicability)) {
        next if $key eq 'controller_applicability'
            && !defined($report->{$key});
        confess "regression gate report $key is invalid\n"
            unless ref($report->{$key}) eq 'HASH'
                && !blessed($report->{$key})
                && _json_boolean(
                    $report->{$key}{applicable},
                    "regression gate $key applicable",
                )
                && !defined($report->{$key}{reason});
    }
    my $cleanup = $report->{cleanup};
    _exact_keys(
        $cleanup, [qw(ephemeral_removed records_total residue)],
        'regression gate report cleanup',
    );
    confess "regression gate report cleanup failed\n"
        unless _json_integer_equals($cleanup->{records_total}, 4)
            && _json_boolean(
                $cleanup->{ephemeral_removed},
                'regression gate report cleanup removed',
            )
            && ref($cleanup->{residue}) eq 'ARRAY'
            && !@{$cleanup->{residue}};
    my $common = _record_common_identity($records[0]);
    for my $record (@records) {
        confess "regression gate mixed host/tool/guard/common identities\n"
            unless _canonical_json(_record_common_identity($record)) eq
                _canonical_json($common);
    }
    confess "regression gate execution revision changed\n"
        unless ($common->{git_revision} // '') eq $revision;
    confess "regression gate report is dirty\n"
        if _json_boolean($common->{dirty_state}, 'regression gate dirty state');
    confess "regression gate host/tool/guard identity is invalid\n"
        unless ref($common->{host_profile}) eq 'HASH'
            && ref($common->{tool_profile}) eq 'HASH'
            && ref($common->{resource_guard}) eq 'HASH'
            && _json_boolean(
                $common->{resource_guard}{active},
                'regression gate resource guard active',
            );
    my $provider = _provider_status($report, $profile, $common);
    return (_clone($common), $provider);
}

sub _provider_status($report, $profile, $common) {
    my $required = $profile->{provider_requirement};
    _exact_keys(
        $required, \@PROVIDER_REQUIREMENT_KEYS,
        'regression gate provider requirement',
    );
    my $kind = $required->{kind} // '';
    if ($kind eq 'exact_tool_profile') {
        my $tool = $report->{tool_profile};
        confess "regression gate exact provider tool profile is absent\n"
            unless ref($tool) eq 'HASH' && !blessed($tool);
        confess "regression gate exact provider identity changed\n"
            unless _json_boolean(
                    $tool->{external_verification_tool},
                    'regression gate external provider flag',
                )
                && ($tool->{logical_name} // '') eq
                    ($required->{logical_name} // '')
                && ($tool->{provider_identity} // '') eq
                    ($required->{provider_identity} // '')
                && 'tool-profile/' . sha256_hex(_canonical_json($tool)) eq
                    ($required->{tool_profile_identity} // '')
                && _canonical_json($tool) eq
                    _canonical_json($common->{tool_profile});
    }
    elsif ($kind eq 'repository_materialization') {
        my $authority = $report->{profile_authority};
        my $verification = $report->{provider_verification};
        confess "regression gate repository provider became external\n"
            if _json_boolean(
                    $required->{external_verification_tool},
                    'regression gate repository provider requirement flag',
                )
                || _json_boolean(
                    $common->{tool_profile}{external_verification_tool},
                    'regression gate repository common tool external flag',
                );
        confess "regression gate repository provider authority changed\n"
            unless ref($authority) eq 'HASH'
                && ref($authority->{structural_authority}) eq 'HASH'
                && ($authority->{structural_authority}
                    {provider_materialization} // '') eq
                    ($required->{provider_identity} // '');
        confess "regression gate repository provider status changed\n"
            unless ref($verification) eq 'HASH'
                && _json_boolean(
                    $verification->{applicable},
                    'regression gate repository provider applicable',
                )
                && _json_boolean(
                    $verification->{included_in_emit},
                    'regression gate repository provider inclusion',
                )
                && _json_boolean(
                    $verification->{read_only},
                    'regression gate repository provider read-only',
                )
                && !_json_boolean(
                    $verification->{external_verification_tool},
                    'regression gate repository provider external flag',
                )
                && ($verification->{classification} // '') eq
                    'sealed_osvvm_2026_05_provider_materialization';
    }
    elsif ($kind eq 'not_applicable') {
        confess "regression gate inapplicable provider became external\n"
            if _json_boolean(
                    $required->{external_verification_tool},
                    'regression gate inapplicable provider external flag',
                )
                || defined($required->{logical_name})
                || defined($required->{provider_identity})
                || defined($required->{tool_profile_identity})
                || _json_boolean(
                    $common->{tool_profile}{external_verification_tool},
                    'regression gate common tool external flag',
                );
        if (exists $report->{provider_verification}) {
            my $verification = $report->{provider_verification};
            confess "regression gate inapplicable provider status changed\n"
                unless ref($verification) eq 'HASH'
                    && !_json_boolean(
                        $verification->{applicable},
                        'regression gate inapplicable provider applicable',
                    )
                    && !_json_boolean(
                        $verification->{included_in_emit},
                        'regression gate inapplicable provider inclusion',
                    )
                    && !_json_boolean(
                        $verification->{read_only},
                        'regression gate inapplicable provider read-only',
                    )
                    && !_json_boolean(
                        $verification->{external_verification_tool},
                        'regression gate inapplicable provider external flag',
                    )
                    && ($verification->{classification} // '') eq
                        'not_applicable';
        }
    }
    else {
        confess "regression gate provider kind is invalid\n";
    }
    return _clone($required);
}

sub _provider_availability($repo, $profile) {
    my $required = $profile->{provider_requirement};
    _exact_keys(
        $required, \@PROVIDER_REQUIREMENT_KEYS,
        'regression gate provider availability requirement',
    );
    return {
        availability => 'available',
        reason => undef,
        observed_tool_profile => undef,
    } unless ($required->{kind} // '') eq 'exact_tool_profile';

    my $adapter = $profile->{adapter_class};
    confess "regression gate exact provider profile authority is unavailable\n"
        unless defined($adapter) && !ref($adapter)
            && $adapter->can('tool_profile');
    my $tool = $adapter->tool_profile;
    confess "regression gate exact provider profile authority changed\n"
        unless ref($tool) eq 'HASH' && !blessed($tool)
            && ($tool->{logical_name} // '') eq
                ($required->{logical_name} // '')
            && ($tool->{provider_identity} // '') eq
                ($required->{provider_identity} // '')
            && 'tool-profile/' . sha256_hex(_canonical_json($tool)) eq
                ($required->{tool_profile_identity} // '');

    my $logical = $required->{logical_name} // '';
    my $executable = $logical;
    if ($logical eq 'ghdl') {
        my $vhdl = build_vial_vhdl_emission_contract();
        my $selection = $vhdl->{tool_selection};
        my $archive = _provider_file(
            $repo, $selection->{archive}, $selection->{archive_sha256},
            undef, 0,
        );
        my $binary = _provider_file(
            $repo, $selection->{binary}, $selection->{binary_sha256},
            undef, 1,
        );
        return {
            availability => 'unavailable',
            reason => 'exact_provider_not_materialized',
            observed_tool_profile => undef,
        } unless $archive && $binary;
        $executable = File::Spec->catfile(
            $repo, split(m{/}, $selection->{binary}),
        );
        if (($required->{provider_identity} // '') =~ /osvvm/) {
            my $osvvm_abs = File::Spec->catdir(
                $repo, split(m{/}, $OSVVM_ROOT),
            );
            return {
                availability => 'unavailable',
                reason => 'exact_provider_not_materialized',
                observed_tool_profile => undef,
            } unless -d $osvvm_abs && !-l $osvvm_abs;
            my $verified = _verify_osvvm($repo);
            confess "regression gate exact OSVVM provider identity drifted\n"
                unless ref($verified) eq 'HASH'
                    && $verified->{ok}
                    && ($verified->{status} // '') eq
                        'complete_recursive_verified';
        }
    }
    elsif ($logical ne 'verilator') {
        confess "regression gate exact provider logical name is unknown\n";
    }
    my $capture = $SUPERVISOR->capture({
        working_directory => $repo,
        argv => [$executable, '--version'],
        policy => $SUPERVISOR->policy(
            'outer_worker_process_group',
            $VERSION_TIMEOUT_SECONDS,
            $VERSION_CAPTURE_BYTES,
        ),
    });
    if (_json_boolean(
            $capture->{exec_failed},
            'regression gate provider exec failure',
        )) {
        return {
            availability => 'unavailable',
            reason => 'exact_provider_executable_unavailable',
            observed_tool_profile => undef,
        };
    }
    confess "regression gate exact provider version query failed\n"
        unless $capture->{ok}
            && _json_integer_equals($capture->{exit_code}, 0)
            && _json_integer_equals($capture->{signal}, 0)
            && !_json_boolean(
                $capture->{timed_out},
                'regression gate provider version timeout',
            )
            && !_json_boolean(
                $capture->{output_limited},
                'regression gate provider version output limit',
            );
    my $version = $capture->{output};
    $version =~ s/[\r\n]+\z//;
    confess "regression gate exact provider version identity drifted\n"
        unless $version eq ($tool->{reported_version} // '');
    return {
        availability => 'available',
        reason => undef,
        observed_tool_profile => _clone($tool),
    };
}

sub _provider_file($repo, $relative, $digest, $bytes, $executable) {
    confess "regression gate provider path authority is invalid\n"
        unless defined($relative) && !ref($relative)
            && $relative =~ m{\A[.A-Za-z0-9_/-]+\z}
            && $relative !~ m{(?:\A|/)\.\.(?:/|\z)};
    my $path = File::Spec->catfile($repo, split(m{/}, $relative));
    return 0 unless -e $path || -l $path;
    my @root = stat($repo);
    my @file = lstat($path);
    confess "regression gate provider file identity drifted\n"
        unless @root && @file && -f _ && !-l _
            && $file[0] == $root[0];
    return 0 if $executable && !-x $path;
    confess "regression gate provider file byte size drifted\n"
        if defined($bytes) && $file[7] != $bytes;
    open my $fh, '<', $path
        or confess "regression gate provider file cannot be read\n";
    binmode $fh;
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh
        or confess "regression gate provider file cannot be closed\n";
    confess "regression gate provider file digest drifted\n"
        unless $sha->hexdigest eq $digest;
    return 1;
}

sub _verify_osvvm($repo) {
    my $original = Cwd::getcwd();
    confess "regression gate cannot capture current directory\n"
        unless defined $original;
    chdir $repo or confess "regression gate cannot enter repository root\n";
    my $result = eval {
        $OSVVM->verify({dependency_root => $OSVVM_ROOT});
    };
    my $error = $@;
    chdir $original
        or confess "regression gate cannot restore current directory\n";
    die $error if length($error);
    return $result;
}

sub _run_worker($raw) {
    pipe(my $reader, my $writer)
        or confess "cannot create regression gate profile worker pipe\n";
    my $prepared = eval {
        _set_close_on_exec($reader, 'reader');
        _set_close_on_exec($writer, 'writer');
        my $flags = fcntl($reader, F_GETFL, 0);
        confess "cannot inspect regression gate worker reader flags\n"
            unless defined $flags;
        confess "cannot make regression gate worker reader nonblocking\n"
            unless fcntl($reader, F_SETFL, $flags | O_NONBLOCK);
        1;
    };
    if (!$prepared) {
        my $error = $@;
        close $reader;
        close $writer;
        die $error;
    }
    my $pid = fork();
    if (!defined $pid) {
        close $reader;
        close $writer;
        confess "cannot fork regression gate profile worker\n";
    }
    if ($pid == 0) {
        close $reader;
        setpgid(0, 0);
        my ($payload, $error);
        my $ok = eval {
            $payload = _execute_child($raw);
            1;
        };
        $error = $@ unless $ok;
        my $envelope = defined($error)
            ? _failure_envelope($error, $raw->{contract})
            : {
                schema => $WORKER_SCHEMA,
                schema_version => 1,
                ok => JSON::PP::true,
                payload => $payload,
                error => undef,
            };
        my $encoded = _encode_worker_envelope($envelope);
        my $exit_code = defined($error) ? 70 : 0;
        my $maximum =
            $raw->{contract}{result_contract}{maximum_profile_ipc_bytes};
        if (!defined($encoded) || ref($encoded)
                || bytes::length($encoded) > $maximum) {
            $envelope = _failure_envelope(
                'regression gate profile worker result exceeded the bounded envelope',
                $raw->{contract},
            );
            $encoded = _canonical_json($envelope);
            $exit_code = 75;
        }
        my $written = _write_worker_result($writer, $encoded);
        close $writer;
        _exit($written ? $exit_code : 74);
    }
    close $writer;
    eval { setpgid($pid, $pid); 1 };
    my $deadline = clock_gettime(CLOCK_MONOTONIC)
        + _worker_timeout_seconds();
    my ($buffer, $read_error, $wait_status, $done, $timed_out) =
        ('', undef, undef, 0, 0);
    while (!$done) {
        $read_error //= _drain_worker_pipe(
            $reader, \$buffer,
            $raw->{contract}{result_contract}{maximum_profile_ipc_bytes},
        );
        if (defined $read_error) {
            _terminate_worker_group($pid);
            my $waited = waitpid($pid, 0);
            $wait_status = $? if $waited == $pid;
            last;
        }
        my $waited = waitpid($pid, WNOHANG);
        if ($waited == $pid) {
            $wait_status = $?;
            $done = 1;
        }
        elsif ($waited == -1) {
            $read_error = 'cannot wait for regression gate profile worker';
            $done = 1;
        }
        elsif (clock_gettime(CLOCK_MONOTONIC) >= $deadline) {
            $timed_out = 1;
            _terminate_worker_group($pid);
            my $reaped = waitpid($pid, 0);
            $wait_status = $? if $reaped == $pid;
            $done = 1;
        }
        else {
            sleep(0.01);
        }
    }
    $read_error //= _drain_worker_pipe(
        $reader, \$buffer,
        $raw->{contract}{result_contract}{maximum_profile_ipc_bytes},
    );
    close $reader
        or $read_error //= 'cannot close regression gate worker reader';
    confess "regression gate profile worker timed out\n" if $timed_out;
    confess "$read_error\n" if defined $read_error;
    if (kill(0, -$pid)) {
        _terminate_worker_group($pid);
        confess "regression gate profile worker retained process residue\n";
    }
    my $signal = defined($wait_status) && WIFSIGNALED($wait_status)
        ? WTERMSIG($wait_status) : 0;
    confess "regression gate profile worker terminated by signal $signal\n"
        if $signal;
    my ($envelope, $decode_error) = _decode_worker_envelope(
        $buffer, $raw->{contract},
    );
    my $exit_code = defined($wait_status) && WIFEXITED($wait_status)
        ? WEXITSTATUS($wait_status) : undef;
    if (defined $decode_error) {
        my $status = defined($exit_code)
            ? " with exit status $exit_code" : '';
        confess "regression gate profile worker $decode_error$status\n";
    }
    confess "regression gate profile worker failed: $envelope->{error}\n"
        unless $envelope->{ok};
    confess "regression gate profile worker exited with status $exit_code\n"
        unless defined($exit_code) && $exit_code == 0;
    return _clone($envelope->{payload});
}

sub _encode_worker_envelope($envelope) {
    return eval { _canonical_json($envelope) };
}

sub _worker_timeout_seconds() {
    return $WORKER_TIMEOUT_SECONDS;
}

sub _terminate_worker_group($pid) {
    kill 'TERM', -$pid;
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + 1;
    while (kill(0, -$pid)
            && clock_gettime(CLOCK_MONOTONIC) < $deadline) {
        sleep(0.01);
    }
    kill 'KILL', -$pid if kill(0, -$pid);
}

sub _failure_envelope($error, $contract) {
    return {
        schema => $WORKER_SCHEMA,
        schema_version => 1,
        ok => JSON::PP::false,
        payload => undef,
        error => _bounded_error(
            $error,
            $contract->{result_contract}{maximum_error_bytes},
        ),
    };
}

sub _bounded_error($error, $maximum) {
    $error = 'regression gate profile worker failed without an exception'
        unless defined($error) && !ref($error) && length($error);
    $error =~ s/[^\x20-\x7e]+/ /g;
    $error =~ s/\s+/ /g;
    $error =~ s/\A\s+|\s+\z//g;
    return substr($error, 0, $maximum);
}

sub _decode_worker_envelope($buffer, $contract) {
    return (undef, 'returned no result') unless length($buffer // '');
    return (undef, 'result exceeded the bounded envelope')
        if bytes::length($buffer) >
            $contract->{result_contract}{maximum_profile_ipc_bytes};
    my $decoded = eval { JSON::PP->new->utf8(1)->decode($buffer) };
    return (undef, 'result is not valid JSON') unless defined $decoded;
    return (undef, 'result is not canonical JSON')
        unless _canonical_json($decoded) eq $buffer;
    my $valid = eval {
        _exact_keys(
            $decoded, \@WORKER_ENVELOPE_KEYS,
            'regression gate profile worker envelope',
        );
        confess "regression gate profile worker envelope schema is invalid\n"
            unless ($decoded->{schema} // '') eq $WORKER_SCHEMA
                && _json_integer_equals($decoded->{schema_version}, 1);
        _json_boolean(
            $decoded->{ok}, 'regression gate profile worker envelope ok',
        );
        if ($decoded->{ok}) {
            confess "successful regression gate worker retained an error\n"
                if defined $decoded->{error};
            confess "successful regression gate worker payload is invalid\n"
                unless ref($decoded->{payload}) eq 'HASH'
                    && !blessed($decoded->{payload});
        }
        else {
            confess "failed regression gate worker retained a payload\n"
                if defined $decoded->{payload};
            confess "failed regression gate worker error is invalid\n"
                unless defined($decoded->{error})
                    && !ref($decoded->{error})
                    && length($decoded->{error})
                    && bytes::length($decoded->{error}) <=
                        $contract->{result_contract}{maximum_error_bytes};
        }
        1;
    };
    return (
        undef,
        _bounded_error(
            $@, $contract->{result_contract}{maximum_error_bytes},
        ),
    ) unless $valid;
    return ($decoded, undef);
}

sub _write_worker_result($writer, $encoded) {
    my $offset = 0;
    while ($offset < bytes::length($encoded)) {
        my $written = syswrite(
            $writer, $encoded,
            bytes::length($encoded) - $offset, $offset,
        );
        if (!defined $written) {
            next if $! == EINTR;
            return 0;
        }
        return 0 unless $written > 0;
        $offset += $written;
    }
    return 1;
}

sub _drain_worker_pipe($reader, $buffer_ref, $maximum) {
    while (1) {
        my $chunk = '';
        my $read = sysread($reader, $chunk, 16_384);
        if (!defined $read) {
            next if $! == EINTR;
            return undef if $! == EAGAIN || $! == EWOULDBLOCK;
            return 'cannot read regression gate profile worker result';
        }
        return undef if $read == 0;
        $$buffer_ref .= $chunk;
        return 'regression gate profile worker result exceeded the bounded envelope'
            if bytes::length($$buffer_ref) > $maximum;
    }
}

sub _anonymous_report_spool($repo) {
    my ($spool, $path) = tempfile(
        '.fsmgen-vial-gate-profile-XXXXXX',
        DIR => $repo,
        UNLINK => 0,
    );
    binmode $spool;
    my @root = stat($repo);
    my @file = lstat($path);
    confess "regression gate report spool identity is invalid\n"
        unless @root && @file && -f _ && !-l _
            && $file[0] == $root[0]
            && ($file[2] & 07777) == 0600;
    _set_close_on_exec($spool, 'report spool');
    my $removed = unlink($path);
    confess "regression gate report spool cannot be anonymized\n"
        unless $removed && !-e $path && !-l $path;
    return ($spool, 1);
}

sub _write_spool($spool, $bytes) {
    seek($spool, 0, 0)
        or confess "regression gate report spool cannot seek\n";
    truncate($spool, 0)
        or confess "regression gate report spool cannot truncate\n";
    my $offset = 0;
    while ($offset < bytes::length($bytes)) {
        my $written = syswrite(
            $spool, $bytes, bytes::length($bytes) - $offset, $offset,
        );
        confess "regression gate report spool cannot be written\n"
            unless defined($written) && $written > 0;
        $offset += $written;
    }
}

sub _read_spool($spool, $maximum) {
    seek($spool, 0, 0)
        or confess "regression gate report spool cannot seek\n";
    my $bytes = '';
    while (bytes::length($bytes) < $maximum) {
        my $chunk = '';
        my $wanted = $maximum - bytes::length($bytes);
        $wanted = 65_536 if $wanted > 65_536;
        my $read = sysread($spool, $chunk, $wanted);
        confess "regression gate report spool cannot be read\n"
            unless defined $read;
        last if $read == 0;
        $bytes .= $chunk;
    }
    return $bytes;
}

sub _set_close_on_exec($handle, $label) {
    my $flags = fcntl($handle, F_GETFD, 0);
    confess "cannot inspect regression gate worker $label descriptor\n"
        unless defined $flags;
    confess "cannot protect regression gate worker $label descriptor\n"
        unless fcntl($handle, F_SETFD, $flags | FD_CLOEXEC);
}

sub _contract_profile($contract, $ordinal) {
    confess "regression gate contract profile inventory is invalid\n"
        unless ref($contract->{profiles}) eq 'ARRAY';
    my @matches = grep {
        _json_integer_equals($_->{ordinal}, $ordinal)
    } @{$contract->{profiles}};
    confess "regression gate profile ordinal is unknown\n"
        unless @matches == 1;
    return _clone($matches[0]);
}

sub _record_common_identity($record) {
    confess "regression gate record must be one unblessed hash\n"
        unless ref($record) eq 'HASH' && !blessed($record);
    my $common = {
        git_revision => $record->{git_revision},
        dirty_state => _clone($record->{dirty_state}),
        host_profile => _clone($record->{host_profile}),
        tool_profile => _clone($record->{tool_profile}),
        resource_guard => _clone($record->{resource_guard}),
    };
    _exact_keys($common, \@COMMON_KEYS, 'regression gate common identity');
    return $common;
}

sub _validate_result($result, $contract, $profile, $revision) {
    _exact_keys($result, \@RESULT_KEYS, 'regression gate profile result');
    confess "regression gate profile result schema is invalid\n"
        unless ($result->{schema} // '') eq $SCHEMA
            && _json_integer_equals($result->{schema_version}, 1);
    my $projection = _clone($result);
    my $identity = $projection->{profile_result_identity};
    $projection->{profile_result_identity} = undef;
    confess "regression gate profile result identity is invalid\n"
        unless ($identity // '') eq $RESULT_IDENTITY_PREFIX
            . sha256_hex(_canonical_json($projection));
    confess "regression gate profile evidence identity changed\n"
        unless ($result->{contract_identity} // '') eq
                ($contract->{contract_identity} // '')
            && ($result->{qualification_identity} // '') eq
                ($contract->{qualification_evidence}
                    {qualification_identity} // '')
            && ($result->{qualification_publication_identity} // '') eq
                ($contract->{qualification_evidence}
                    {publication_identity} // '')
            && ($result->{qualification_file_set_sha256} // '') eq
                ($contract->{qualification_evidence}
                    {qualification_file_set_sha256} // '');
    confess "regression gate profile result dispatch changed\n"
        unless _json_integer_equals($result->{ordinal}, $profile->{ordinal})
            && ($result->{selection_key} // '') eq
                ($profile->{selection_key} // '')
            && ($result->{execution_revision} // '') eq $revision;
    _exact_keys($result->{report}, \@REPORT_RESULT_KEYS,
        'regression gate profile report result');
    _exact_keys($result->{observation}, \@OBSERVATION_KEYS,
        'regression gate profile observation');
    _exact_keys($result->{provider}, \@PROVIDER_KEYS,
        'regression gate profile provider');
    _exact_keys($result->{performance}, \@PERFORMANCE_KEYS,
        'regression gate profile performance');
    _exact_keys($result->{cleanup}, \@CLEANUP_KEYS,
        'regression gate profile cleanup');
    confess "regression gate profile cleanup changed\n"
        unless _json_boolean(
                $result->{cleanup}{anonymous_report_spool_removed},
                'regression gate report spool cleanup',
            )
            && !_json_boolean(
                $result->{cleanup}{worker_process_residue},
                'regression gate worker process residue',
            );
    confess "regression gate profile diagnostics changed\n"
        unless ref($result->{diagnostics}) eq 'ARRAY'
            && !@{$result->{diagnostics}};
    confess "regression gate profile nonclaims changed\n"
        unless _canonical_json($result->{explicit_nonclaims}) eq
            _canonical_json(\@NONCLAIMS);
    confess "regression gate profile provider requirement changed\n"
        unless _canonical_json($result->{provider}{requirement}) eq
            _canonical_json($profile->{provider_requirement});
    _exact_keys($result->{performance}{comparisons}, \@METRICS,
        'regression gate profile metric comparisons');
    for my $metric (@METRICS) {
        _exact_keys(
            $result->{performance}{comparisons}{$metric},
            \@COMPARISON_KEYS,
            "regression gate profile $metric comparison",
        );
    }
    my $classification = $result->{performance}{classification} // '';
    confess "regression gate profile performance classification is invalid\n"
        unless $classification =~ /\A(?:pass|fail|informational|unavailable)\z/;
    if ($classification eq 'unavailable') {
        confess "regression gate unavailable profile result changed\n"
            unless ($result->{provider}{availability} // '') eq 'unavailable'
                && ($profile->{provider_requirement}{kind} // '') eq
                    'exact_tool_profile'
                && ($result->{provider}{reason} // '') =~
                    /\Aexact_provider_(?:not_materialized|executable_unavailable)\z/
                && !defined($result->{provider}{observed_tool_profile})
                && ($result->{outcome} // '') eq 'unavailable'
                && !defined($result->{observed_environment})
                && _json_integer_equals($result->{report}{bytes}, 0)
                && !defined($result->{report}{identity})
                && !defined($result->{report}{sha256})
                && _json_integer_equals(
                    $result->{observation}{controller_invocations}, 0,
                )
                && !defined(
                    $result->{observation}
                        {correctness_projection_identity},
                )
                && ($result->{observation}{workload_identity} // '') eq
                    ($profile->{workload_identity} // '')
                && ref($result->{observation}
                    {raw_measurement_identities}) eq 'ARRAY'
                && !@{$result->{observation}
                    {raw_measurement_identities}}
                && ref($result->{observation}{accepted_run_totals}) eq
                    'ARRAY'
                && !@{$result->{observation}{accepted_run_totals}};
        my %unavailable_comparison = map {
            ($_ => {
                observed => undef,
                budget => 0 + $profile->{qualified_budget}{$_},
                within_budget => undef,
            })
        } @METRICS;
        my $expected_performance = {
            classification => 'unavailable',
            reason => 'exact_provider_unavailable',
            exact_environment => JSON::PP::false,
            qualified_budget => _clone($profile->{qualified_budget}),
            observed_maximum => {map { ($_ => undef) } @METRICS},
            comparisons => \%unavailable_comparison,
        };
        confess "regression gate unavailable performance changed\n"
            unless _canonical_json($result->{performance}) eq
                _canonical_json($expected_performance)
                && _canonical_json(
                    $result->{observation}{observed_maximum},
                ) eq _canonical_json({map { ($_ => undef) } @METRICS});
    }
    else {
        _exact_keys(
            $result->{observed_environment}, \@ENVIRONMENT_KEYS,
            'regression gate observed environment',
        );
        confess "regression gate available profile result changed\n"
            unless ($result->{provider}{availability} // '') eq 'available'
                && ($result->{report}{identity} // '') =~
                    m{\A[A-Za-z0-9_.-]+/[0-9a-f]{64}\z}
                && ($result->{report}{sha256} // '') =~ /\A[0-9a-f]{64}\z/
                && _json_positive_integer($result->{report}{bytes})
                && $result->{report}{bytes} <=
                    $contract->{result_contract}
                        {maximum_profile_report_bytes}
                && _json_integer_equals(
                    $result->{observation}{validation_records}, 1,
                )
                && _json_integer_equals(
                    $result->{observation}{raw_measurement_records}, 3,
                )
                && _json_integer_equals(
                    $result->{observation}{controller_invocations}, 4,
                )
                && _json_integer_equals(
                    $result->{observation}{sample_exclusions}, 0,
                )
                && ($result->{observation}{workload_identity} // '') eq
                    ($profile->{workload_identity} // '')
                && ($result->{observation}
                    {correctness_projection_identity} // '') eq
                    ($profile->{correctness_projection_identity} // '');
        confess "regression gate available provider metadata changed\n"
            unless !defined($result->{provider}{reason})
                && _canonical_json(
                    $result->{provider}{observed_tool_profile},
                ) eq _canonical_json(
                    $result->{observed_environment}{tool_profile},
                );
        my $environment_projection =
            _clone($result->{observed_environment});
        my $environment_identity =
            $environment_projection->{environment_identity};
        $environment_projection->{environment_identity} = undef;
        confess "regression gate observed environment identity changed\n"
            unless ($environment_identity // '') eq
                'regression-promotion-environment/'
                . sha256_hex(_canonical_json($environment_projection));
        _exact_keys(
            $result->{observation}{observed_maximum}, \@METRICS,
            'regression gate observation maximum',
        );
        my $totals = $result->{observation}{accepted_run_totals};
        my $identities =
            $result->{observation}{raw_measurement_identities};
        confess "regression gate observation record inventory changed\n"
            unless ref($totals) eq 'ARRAY' && @$totals == 3
                && ref($identities) eq 'ARRAY' && @$identities == 3;
        my %maximum;
        for my $index (0 .. 2) {
            my $total = $totals->[$index];
            _exact_keys(
                $total, \@RUN_TOTAL_KEYS,
                'regression gate accepted run total',
            );
            confess "regression gate accepted run identity changed\n"
                unless _json_integer_equals($total->{run_ordinal}, $index + 1)
                    && ($total->{measurement_identity} // '') eq
                        ($identities->[$index] // '')
                    && ($identities->[$index] // '') =~
                        m{\Ameasurement/[0-9a-f]{64}\z};
            for my $metric (@METRICS) {
                my $value = _json_nonnegative_integer(
                    $total->{$metric},
                    "regression gate accepted $metric",
                );
                $maximum{$metric} = $value
                    if !defined($maximum{$metric})
                        || $value > $maximum{$metric};
            }
        }
        confess "regression gate observation maximum changed\n"
            unless _canonical_json(\%maximum) eq _canonical_json(
                $result->{observation}{observed_maximum},
            );
        my $exact_environment = _canonical_json(
            $result->{observed_environment},
        ) eq _canonical_json($profile->{environment_identity});
        my $expected_performance = _performance(
            $profile->{qualified_budget}, \%maximum, $exact_environment,
        );
        confess "regression gate performance classification changed\n"
            unless _canonical_json($result->{performance}) eq
                _canonical_json($expected_performance);
        my $expected_outcome = $classification eq 'fail'
            ? 'performance_failed'
            : $classification eq 'informational'
                ? 'accepted_informational'
                : 'accepted';
        confess "regression gate profile outcome changed\n"
            unless ($result->{outcome} // '') eq $expected_outcome;
    }
    confess "regression gate profile result exceeds its IPC bound\n"
        if bytes::length(_canonical_json($result)) >
            $contract->{result_contract}{maximum_profile_ipc_bytes};
    return 1;
}

sub _repository_root($value) {
    confess "regression gate profile repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "regression gate profile repository root is unavailable\n"
        unless defined($root) && -d $root && !-l $root;
    my $git = File::Spec->catfile($root, '.git');
    confess "regression gate profile repository Git identity is invalid\n"
        unless (-d $git || -f $git) && !-l $git;
    return $root;
}

sub _require_clean_revision($repo) {
    my ($revision_ok, $revision) = _capture_command(
        'git', '-C', $repo, 'rev-parse', 'HEAD',
    );
    confess "cannot derive regression gate profile Git revision\n"
        unless $revision_ok;
    $revision =~ s/\s+\z//;
    confess "regression gate profile Git revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my ($status_ok, $status) = _capture_command(
        'git', '-C', $repo, 'status', '--porcelain=v1',
        '--untracked-files=normal',
    );
    confess "cannot derive regression gate profile Git state\n"
        unless $status_ok;
    confess "regression gate profile requires a clean Git revision\n"
        if length($status);
    return $revision;
}

sub _require_unchanged_clean_revision($repo, $expected) {
    my $actual = _require_clean_revision($repo);
    confess "regression gate profile Git revision changed during execution\n"
        unless $actual eq $expected;
}

sub _capture_command(@command) {
    open my $fh, '-|', @command or return (0, '');
    local $/;
    my $output = <$fh> // '';
    my $ok = close $fh;
    return ($ok ? 1 : 0, $output);
}

sub _require_active_guard() {
    confess "regression gate profile requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "regression gate profile guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host > 0 && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss > 0 && $rss <= 4096;
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @{$args} == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "regression gate profile $method request");
    return $args->[0];
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be a hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @{$keys};
    for my $key (keys %{$value}) {
        confess "$label contains unknown key '$key'\n"
            unless $expected{$key};
    }
    for my $key (@{$keys}) {
        confess "$label is missing '$key'\n"
            unless exists $value->{$key};
    }
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _json_boolean($value, $label) {
    my $encoded = eval { _canonical_json($value) };
    confess "$label is not a JSON boolean\n"
        unless defined($encoded)
            && ($encoded eq 'true' || $encoded eq 'false');
    return $encoded eq 'true' ? 1 : 0;
}

sub _json_integer_equals($actual, $expected) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) eq "$expected";
}

sub _json_positive_integer($actual) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) =~ /\A[1-9][0-9]*\z/
        && $actual <= $MAX_SAFE_INTEGER;
}

sub _json_nonnegative_integer($actual, $label) {
    confess "$label is not a safe nonnegative JSON integer\n"
        unless defined($actual) && !ref($actual)
            && _canonical_json($actual) =~ /\A(?:0|[1-9][0-9]*)\z/
            && $actual <= $MAX_SAFE_INTEGER;
    return 0 + $actual;
}

sub _json_positive_integer_value($actual, $label) {
    confess "$label is not a safe positive JSON integer\n"
        unless _json_positive_integer($actual);
    return 0 + $actual;
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
