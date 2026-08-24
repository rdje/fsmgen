package FSM::VIAL::ArchitectureScaleMeasurement;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Config ();
use Digest::SHA qw(sha256_hex);
use Errno qw(EAGAIN EEXIST EWOULDBLOCK);
use Fcntl qw(
    FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL LOCK_EX LOCK_NB
    O_CREAT O_NOFOLLOW O_NONBLOCK O_RDWR
);
use File::Basename qw(dirname);
use File::Path qw(remove_tree);
use File::Spec;
use JSON::PP ();
use POSIX qw(WNOHANG _exit setpgid uname);
use Scalar::Util qw(blessed);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleWorkload;

my $SCHEMA = 'fsmgen.vial_architecture_scale_measurement.v1';
my $PUBLICATION_SCHEMA =
    'fsmgen.vial_architecture_scale_measurement_publication.v1';
my $IMPLEMENTATION = 'fsmgen.perl_process_tree_sampler.v1';
my $SAMPLER_INTERVAL_NS = 250_000_000;
my $MAX_WORKER_RESULT_BYTES = 1_048_576;
my $STAGING_BASE = '.artifacts/tmp/vial-scale';
my $LOCK_BASE = '.artifacts/locks/vial-scale-measurement';
my $PUBLICATION_BASE = '.artifacts/qualification/vial-scale';
my @STAGES = qw(
    construct parse_validate bridge bind_plan emit compile_analyze elaborate
    run trace_validate result_produce publish cleanup
);
my %STAGE_INDEX = map { $STAGES[$_] => $_ } 0 .. $#STAGES;
my %OUTER_TIMEOUT_SECONDS = (
    construct => 120,
    parse_validate => 120,
    bridge => 120,
    bind_plan => 300,
    emit => 300,
    compile_analyze => 900,
    elaborate => 60,
    run => 300,
    trace_validate => 120,
    result_produce => 120,
    publish => 120,
    cleanup => 120,
);
my %RUN_ORDINAL_MAX = (
    validation => 0,
    gate_measurement => 3,
    qualification_measurement => 5,
);
my @NONCLAIMS = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language native_uvm_runtime full_language
    synthesis general_cross_backend_parity public_performance_budget
);
my @RECORD_KEYS = qw(
    schema schema_version measurement_identity workload_identity
    workload_specification git_revision dirty_state host_profile tool_profile
    run_class run_ordinal stage_measurements correctness_oracles resource_guard
    artifacts outcome diagnostic cleanup explicit_nonclaims
);
my @STAGE_KEYS = qw(
    stage status worker_status classification not_run_reason timeout wall_time_ns
    controller_cpu descendant_cpu rss input_counts output_counts
    semantic_object_counts command_identity process raw_samples
    unsupported_counters correctness_oracle_ids
);
my @SAMPLE_KEYS = qw(
    ordinal monotonic_offset_ns controller_rss_bytes
    descendant_tree_rss_bytes process_tree_rss_bytes
    single_descendant_rss_bytes live_descendant_count
    descendant_user_cpu_ns descendant_system_cpu_ns unsupported_reason
);
my @COUNT_KEYS = qw(files lines bytes objects);
my @COMMAND_KEYS = qw(logical_name arguments thread_count job_count);
my @PLAN_KEYS = qw(
    stage classification command_identity input_counts
    backend_timeout_seconds worker
);
my @WORKER_RESULT_KEYS = qw(
    ok status output_counts semantic_object_counts correctness_oracles
    artifacts diagnostic
);
my @WORKER_ORACLE_KEYS = qw(oracle_id ok evidence);
my @WORKER_ARTIFACT_KEYS = qw(relative_path kind bytes lines sha256);
my @RECORD_ARTIFACT_KEYS = qw(stage relative_path kind bytes lines sha256);
my @HOST_KEYS = qw(
    os_name os_version architecture cpu_model logical_core_count
    physical_memory_bytes filesystem_type measurement_implementation
);
my @TOOL_KEYS = qw(
    applicability logical_name reported_version build provider_identity
    arguments thread_count job_count external_verification_tool
);
my @GUARD_KEYS = qw(
    active enforcement host_max_percent single_descendant_max_mib
    sampler_interval_ns
);
my @TIMEOUT_KEYS = qw(
    outer_seconds backend_seconds effective_seconds authority
);
my @CPU_KEYS = qw(user_ns system_ns unsupported_reason);
my @RSS_KEYS = qw(
    peak_process_tree_bytes peak_single_descendant_bytes unsupported_reason
);
my @PROCESS_KEYS = qw(exit_code signal timed_out);
my @DIAGNOSTIC_KEYS = qw(
    code severity message source_locations semantic_path related notes hints
);
my @PUBLICATION_KEYS = qw(
    ok status schema schema_version measurement_identity
    publication_identity artifact_relative_path same_volume atomic diagnostics
);

sub record_keys($class) {
    _exact_invocant($class, 'record_keys');
    return [@RECORD_KEYS];
}

sub stage_keys($class) {
    _exact_invocant($class, 'stage_keys');
    return [@STAGE_KEYS];
}

sub stage_order($class) {
    _exact_invocant($class, 'stage_order');
    return [@STAGES];
}

sub publication_keys($class) {
    _exact_invocant($class, 'publication_keys');
    return [@PUBLICATION_KEYS];
}

sub stage_timeouts($class) {
    _exact_invocant($class, 'stage_timeouts');
    return {map { $_ => $OUTER_TIMEOUT_SECONDS{$_} } @STAGES};
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub sampler_interval_ns($class) {
    _exact_invocant($class, 'sampler_interval_ns');
    return $SAMPLER_INTERVAL_NS;
}

sub effective_timeout($class, @args) {
    _exact_invocant($class, 'effective_timeout');
    confess __PACKAGE__ . "->effective_timeout expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys(
        $args[0], [qw(stage backend_timeout_seconds)],
        'measurement timeout request',
    );
    return _effective_timeout(
        $args[0]{stage}, $args[0]{backend_timeout_seconds},
    );
}

sub measure($class, @args) {
    _exact_invocant($class, 'measure');
    confess __PACKAGE__ . "->measure expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    my @keys = qw(
        repository_root construction run_class run_ordinal
        validation_record stage_plan
    );
    if (exists $args[0]{tool_profile}) {
        my $caller = caller;
        confess "external-tool measurement is private to the selected runtime adapter\n"
            unless defined($caller) && $caller eq
                'FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement';
        push @keys, 'tool_profile';
    }
    _exact_keys($args[0], \@keys, 'measurement invocation');
    return _measure($args[0]);
}

sub validate_record($class, @args) {
    _exact_invocant($class, 'validate_record');
    confess __PACKAGE__ . "->validate_record expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys($args[0], [qw(record)], 'measurement record validation');
    _validate_record($args[0]{record});
    return _clone($args[0]{record});
}

sub publish_record($class, @args) {
    _exact_invocant($class, 'publish_record');
    confess __PACKAGE__ . "->publish_record expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH'
            && !blessed($args[0]);
    _exact_keys(
        $args[0], [qw(repository_root contract_version profile_id record)],
        'measurement publication',
    );
    return _publish_record($args[0]);
}

sub _measure($raw) {
    my ($repo_root, $root_device) =
        _validated_repository_root($raw->{repository_root});
    my $construction = _validated_construction($raw->{construction});
    my ($run_class, $run_ordinal) =
        _validated_run($raw->{run_class}, $raw->{run_ordinal});
    my $plan = _validated_stage_plan(
        $raw->{stage_plan}, $construction->{specification},
    );
    my $git = _git_profile($repo_root);
    my $host = _host_profile($repo_root);
    my $tool = _selected_tool_profile(
        $construction->{specification}, $raw->{tool_profile},
    );
    my $guard = _resource_guard($run_class);

    if ($run_class eq 'validation') {
        confess "validation_record must be null for a validation run\n"
            if defined $raw->{validation_record};
    }
    else {
        confess "measured runs require the active repository RAM guard\n"
            unless $guard->{active};
        _validate_preceding_validation(
            $raw->{validation_record}, $construction, $git, $host,
        );
    }

    my ($digest) = $construction->{workload_identity}
        =~ m{\Aworkload/([0-9a-f]{64})\z};
    confess "measurement construction workload identity is invalid\n"
        unless defined $digest;
    my $stage_rel = join(
        '/', $STAGING_BASE, $digest, $run_class,
        sprintf('%02d', $run_ordinal),
    );
    my $stage_lock = _acquire_stage_lock(
        $repo_root, $root_device, $stage_rel,
    );
    my $recovered = _recover_interrupted_stage(
        $repo_root, $root_device, $stage_rel,
    );
    print STDERR "vial-scale-measurement: recovered $stage_rel\n"
        if $recovered;
    my ($stage_abs, $created) = _create_owned_stage(
        $repo_root, $root_device, $stage_rel,
    );

    my (%planned, @measurements, @oracles, @artifact_records);
    $planned{$_->{stage}} = $_ for @$plan;
    my $prior_failure;
    my $controller_ok = eval {
        for my $stage (@STAGES) {
            last if $stage eq 'cleanup';
            if (!exists $planned{$stage}) {
                push @measurements, _not_run_stage(
                    $stage,
                    defined($prior_failure)
                        ? 'prior_stage_failed'
                        : 'not_applicable_to_invocation',
                );
                next;
            }
            if (defined $prior_failure) {
                push @measurements,
                    _not_run_stage($stage, 'prior_stage_failed');
                next;
            }
            my $measurement = _run_stage({
                plan => $planned{$stage},
                run_class => $run_class,
                stage_abs => $stage_abs,
                stage_rel => $stage_rel,
                workload_identity => $construction->{workload_identity},
                run_ordinal => $run_ordinal,
            });
            push @measurements, $measurement->{stage_measurement};
            push @oracles, @{$measurement->{correctness_oracles}};
            push @artifact_records, @{$measurement->{artifacts}};
            $prior_failure = $measurement->{diagnostic}
                unless $measurement->{ok};
        }
        _validate_owned_artifact_census($stage_abs, \@artifact_records);
        1;
    };
    if (!$controller_ok) {
        $prior_failure //= _diagnostic(
            'VIAL_SCALE_MEASUREMENT_CONTROLLER_ERROR',
            _sanitize_exception($@), '/stage_measurements',
        );
        for my $index (scalar(@measurements) .. $#STAGES - 1) {
            push @measurements,
                _not_run_stage($STAGES[$index], 'controller_failure');
        }
    }

    my $cleanup_started = clock_gettime(CLOCK_MONOTONIC);
    my @cleanup_times_before = times;
    my $cleanup_error = _remove_owned_stage($stage_abs, $stage_rel, $created);
    my @cleanup_times_after = times;
    my $cleanup_finished = clock_gettime(CLOCK_MONOTONIC);
    my $cleanup_ok = !defined $cleanup_error;
    my $cleanup_residue = $cleanup_ok
        ? [] : _cleanup_residue($stage_abs, $stage_rel);
    my $cleanup_oracle = {
        stage => 'cleanup',
        oracle_id => 'owned_stage_absent',
        ok => $cleanup_ok ? JSON::PP::true : JSON::PP::false,
        evidence => {
            staging_identity => $stage_rel,
            absent => $cleanup_ok ? JSON::PP::true : JSON::PP::false,
            residue => _clone($cleanup_residue),
        },
    };
    $cleanup_oracle->{evidence_identity} = sha256_hex(
        _canonical_json($cleanup_oracle->{evidence}),
    );
    push @oracles, $cleanup_oracle;
    push @measurements, _cleanup_measurement({
        run_class => $run_class,
        ok => $cleanup_ok,
        reason => $cleanup_error,
        started => $cleanup_started,
        finished => $cleanup_finished,
        times_before => \@cleanup_times_before,
        times_after => \@cleanup_times_after,
        oracle_id => $cleanup_oracle->{oracle_id},
    });

    my $diagnostic = $prior_failure;
    $diagnostic = _diagnostic(
        'VIAL_SCALE_MEASUREMENT_CLEANUP_ERROR',
        $cleanup_error, '/cleanup',
    ) if !$cleanup_ok;
    my $all_oracles = !grep { !$_->{ok} } @oracles;
    my $outcome = !$cleanup_ok ? 'cleanup_failure'
        : !$all_oracles ? 'correctness_failure'
        : defined($prior_failure) ? 'stage_failure'
        : 'accepted';
    $diagnostic //= _diagnostic(
        'VIAL_SCALE_MEASUREMENT_CORRECTNESS_ERROR',
        'one or more stage-local correctness oracles rejected the run',
        '/correctness_oracles',
    ) if !$all_oracles;

    my $record = {
        schema => $SCHEMA,
        schema_version => 1,
        measurement_identity => undef,
        workload_identity => $construction->{workload_identity},
        workload_specification => _clone($construction->{specification}),
        git_revision => $git->{revision},
        dirty_state => $git->{dirty_state},
        host_profile => $host,
        tool_profile => $tool,
        run_class => $run_class,
        run_ordinal => $run_ordinal,
        stage_measurements => \@measurements,
        correctness_oracles => \@oracles,
        resource_guard => $guard,
        artifacts => {
            staging_identity => $stage_rel,
            published_identity => undef,
            records => \@artifact_records,
        },
        outcome => $outcome,
        diagnostic => $diagnostic,
        cleanup => {
            staging_identity => $stage_rel,
            ephemeral_removed => $cleanup_ok
                ? JSON::PP::true : JSON::PP::false,
            residue => $cleanup_residue,
        },
        explicit_nonclaims => [@NONCLAIMS],
    };
    $record->{measurement_identity} = _measurement_identity($record);
    _validate_record($record);
    return _clone($record);
}

sub _run_stage($raw) {
    my $plan = $raw->{plan};
    my $stage = $plan->{stage};
    my $measured = $raw->{run_class} ne 'validation';
    my $timeout = _effective_timeout(
        $stage, $plan->{backend_timeout_seconds},
    );
    my ($reader, $writer);
    pipe($reader, $writer)
        or confess "cannot create measurement worker pipe\n";
    my @times_before = times;
    my $started = clock_gettime(CLOCK_MONOTONIC);
    my $pid = fork();
    if (!defined $pid) {
        close $reader;
        close $writer;
        confess "cannot fork measurement worker\n";
    }
    if ($pid == 0) {
        close $reader;
        eval { setpgid(0, 0); 1 };
        my $result = eval {
            $plan->{worker}->({
                stage => $stage,
                staging_identity => $raw->{stage_rel},
                staging_root => $raw->{stage_abs},
                output_identity => "outputs/$stage",
                output_root => File::Spec->catdir(
                    $raw->{stage_abs}, 'outputs', $stage,
                ),
                workload_identity => $raw->{workload_identity},
                run_class => $raw->{run_class},
                run_ordinal => $raw->{run_ordinal},
            });
        };
        if ($@) {
            $result = {
                ok => JSON::PP::false,
                status => 'worker_exception',
                output_counts => _zero_counts(),
                semantic_object_counts => {},
                correctness_oracles => [],
                artifacts => [],
                diagnostic => _diagnostic(
                    'VIAL_SCALE_MEASUREMENT_WORKER_ERROR',
                    _sanitize_exception($@), "/stage_measurements/$stage",
                ),
            };
        }
        my $encoded = eval { _canonical_json($result) };
        if (!defined($encoded)
                || bytes::length($encoded) > $MAX_WORKER_RESULT_BYTES) {
            $encoded = _canonical_json({
                ok => JSON::PP::false,
                status => 'worker_result_error',
                output_counts => _zero_counts(),
                semantic_object_counts => {},
                correctness_oracles => [],
                artifacts => [],
                diagnostic => _diagnostic(
                    'VIAL_SCALE_MEASUREMENT_WORKER_RESULT_ERROR',
                    'worker result is not bounded canonical JSON',
                    "/stage_measurements/$stage",
                ),
            });
        }
        my $written = print {$writer} $encoded;
        close $writer;
        _exit($written ? 0 : 74);
    }

    close $writer;
    eval { setpgid($pid, $pid); 1 };
    my $flags = fcntl($reader, F_GETFL, 0);
    fcntl($reader, F_SETFL, $flags | O_NONBLOCK)
        if defined $flags;
    my ($buffer, @samples, @unsupported) = ('');
    my $next_sample = $started;
    my ($wait_status, $timed_out, $done) = (undef, 0, 0);
    while (!$done) {
        my $now = clock_gettime(CLOCK_MONOTONIC);
        if ($measured && $now >= $next_sample) {
            push @samples, _process_sample(
                $pid, $started, scalar(@samples), \@unsupported,
            );
            $next_sample += $SAMPLER_INTERVAL_NS / 1_000_000_000
                while $next_sample <= $now;
        }
        _drain_pipe($reader, \$buffer);
        my $waited = waitpid($pid, WNOHANG);
        if ($waited == $pid) {
            $wait_status = $?;
            $done = 1;
            last;
        }
        if (($now - $started) >= $timeout->{effective_seconds}) {
            $timed_out = 1;
            _terminate_process_group($pid);
            waitpid($pid, 0);
            $wait_status = $?;
            $done = 1;
            last;
        }
        my $remaining = $measured ? $next_sample - $now : 0.01;
        $remaining = 0.01 if $remaining > 0.01 || $remaining <= 0;
        sleep($remaining);
    }
    _drain_pipe($reader, \$buffer, 1);
    close $reader;
    my $finished = clock_gettime(CLOCK_MONOTONIC);
    my @times_after = times;

    my ($worker_result, $result_error) = _decode_worker_result($buffer, $stage);
    my ($exit_code, $signal) = (
        defined($wait_status) ? ($wait_status >> 8) : undef,
        defined($wait_status) ? ($wait_status & 127) : undef,
    );
    my $diagnostic;
    if ($timed_out) {
        $diagnostic = _diagnostic(
            'VIAL_SCALE_MEASUREMENT_TIMEOUT',
            "stage '$stage' exceeded its effective timeout",
            "/stage_measurements/$stage/timeout",
        );
    }
    elsif (defined $result_error) {
        $diagnostic = $result_error;
    }
    elsif (($exit_code // 1) != 0 || ($signal // 0) != 0) {
        $diagnostic = _diagnostic(
            'VIAL_SCALE_MEASUREMENT_PROCESS_ERROR',
            "stage '$stage' worker did not exit successfully",
            "/stage_measurements/$stage/process",
        );
    }
    elsif (!$worker_result->{ok}) {
        $diagnostic = $worker_result->{diagnostic} // _diagnostic(
            'VIAL_SCALE_MEASUREMENT_STAGE_ERROR',
            "stage '$stage' returned a failed result",
            "/stage_measurements/$stage",
        );
    }

    my ($oracles, $artifacts, $validation_error, $result_validated) =
        ([], [], undef, 0);
    if (!defined $diagnostic) {
        my $ok = eval {
            $oracles = _validated_worker_oracles(
                $stage, $worker_result->{correctness_oracles},
            );
            $artifacts = _validated_worker_artifacts(
                $raw->{stage_abs}, $stage, $worker_result->{artifacts},
            );
            _validate_output_counts(
                $worker_result->{output_counts}, $artifacts,
            );
            _validate_semantic_counts(
                $worker_result->{semantic_object_counts},
            );
            $result_validated = 1;
            1;
        };
        if (!$ok) {
            $validation_error = _sanitize_exception($@);
            $diagnostic = _diagnostic(
                'VIAL_SCALE_MEASUREMENT_RESULT_VALIDATION_ERROR',
                $validation_error,
                "/stage_measurements/$stage",
            );
        }
    }
    my $all_oracles = !grep { !$_->{ok} } @$oracles;
    my $ok = !defined($diagnostic) && $all_oracles;
    $diagnostic //= _diagnostic(
        'VIAL_SCALE_MEASUREMENT_CORRECTNESS_ERROR',
        "stage '$stage' correctness oracle rejected the run",
        "/stage_measurements/$stage/correctness_oracle_ids",
    ) unless $all_oracles;

    my $metrics = $measured
        ? _measured_metrics(
            $started, $finished, \@times_before, \@times_after,
            \@samples, \@unsupported,
        )
        : _unmeasured_metrics();
    my $status = $measured
        ? ($ok ? 'measured' : 'measured_rejected')
        : ($ok ? 'validated_unmeasured' : 'validation_rejected');
    my $measurement = {
        stage => $stage,
        status => $status,
        worker_status => defined($worker_result)
            ? $worker_result->{status} : 'worker_result_unavailable',
        classification => $plan->{classification},
        not_run_reason => undef,
        timeout => $timeout,
        wall_time_ns => $metrics->{wall_time_ns},
        controller_cpu => $metrics->{controller_cpu},
        descendant_cpu => $metrics->{descendant_cpu},
        rss => $metrics->{rss},
        input_counts => _clone($plan->{input_counts}),
        output_counts => $result_validated
            ? _clone($worker_result->{output_counts}) : _zero_counts(),
        semantic_object_counts => $result_validated
            ? _clone($worker_result->{semantic_object_counts}) : {},
        command_identity => _clone($plan->{command_identity}),
        process => {
            exit_code => $exit_code,
            signal => $signal,
            timed_out => $timed_out
                ? JSON::PP::true : JSON::PP::false,
        },
        raw_samples => $metrics->{raw_samples},
        unsupported_counters => $metrics->{unsupported_counters},
        correctness_oracle_ids => [map { $_->{oracle_id} } @$oracles],
    };
    return {
        ok => $ok ? JSON::PP::true : JSON::PP::false,
        stage_measurement => $measurement,
        correctness_oracles => $oracles,
        artifacts => $artifacts,
        diagnostic => $diagnostic,
    };
}

sub _validated_stage_plan($raw, $specification) {
    confess "stage_plan must be a non-empty array\n"
        unless ref($raw) eq 'ARRAY' && @$raw;
    my (@plan, %seen);
    my $last = -1;
    for my $index (0 .. $#$raw) {
        my $entry = $raw->[$index];
        confess "stage plan entry $index must be one unblessed hash\n"
            unless ref($entry) eq 'HASH' && !blessed($entry);
        _exact_keys($entry, \@PLAN_KEYS, "stage plan entry $index");
        my $stage = $entry->{stage};
        confess "stage plan entry $index names an unknown stage\n"
            unless defined($stage) && !ref($stage)
                && exists $STAGE_INDEX{$stage};
        confess "cleanup is controller-owned and cannot be planned\n"
            if $stage eq 'cleanup';
        confess "stage plan contains duplicate stage '$stage'\n"
            if $seen{$stage}++;
        confess "stage plan must follow normative stage order\n"
            if $STAGE_INDEX{$stage} <= $last;
        $last = $STAGE_INDEX{$stage};
        confess "stage classification is not selected by the measurement foundation\n"
            unless defined($entry->{classification})
                && !ref($entry->{classification})
                && $entry->{classification}
                    =~ /\A(?:fsmgen_owned|external_tool)\z/;
        confess "external-tool stage admission is not implemented for this construction\n"
            if $entry->{classification} eq 'external_tool'
                && !defined($specification->{tool_profile});
        _validated_command_identity($entry->{command_identity});
        _validated_counts($entry->{input_counts}, 'stage input counts');
        _effective_timeout($stage, $entry->{backend_timeout_seconds});
        confess "stage worker must be one code reference\n"
            unless ref($entry->{worker}) eq 'CODE';
        push @plan, {%$entry};
    }
    return \@plan;
}

sub _validated_construction($raw) {
    confess "measurement construction must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    for my $key (qw(inputs workload_identity specification)) {
        confess "measurement construction is missing '$key'\n"
            unless exists $raw->{$key};
    }
    my $specification = $raw->{specification};
    confess "measurement construction specification is invalid\n"
        unless ref($specification) eq 'HASH' && !blessed($specification);
    for my $key (qw(
        family level primary_axis backend_profile tool_profile
    )) {
        confess "measurement construction specification is missing '$key'\n"
            unless exists $specification->{$key};
    }
    my $rebuilt = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $specification->{family},
        level => $specification->{level},
        primary_axis => $specification->{primary_axis},
        backend_profile => $specification->{backend_profile},
        tool_profile => $specification->{tool_profile},
        inputs => $raw->{inputs},
    });
    confess "measurement construction did not rebuild successfully\n"
        unless $rebuilt->{ok};
    confess "measurement construction is not canonical\n"
        unless _canonical_json($rebuilt) eq _canonical_json($raw);
    return _clone($rebuilt);
}

sub _validated_run($run_class, $ordinal) {
    confess "run_class is not selected by the measurement contract\n"
        unless defined($run_class) && !ref($run_class)
            && exists $RUN_ORDINAL_MAX{$run_class};
    confess "run_ordinal must be an unsigned integer\n"
        unless defined($ordinal) && !ref($ordinal)
            && $ordinal =~ /\A(?:0|[1-9][0-9]*)\z/;
    if ($run_class eq 'validation') {
        confess "validation run ordinal must be zero\n" unless $ordinal == 0;
    }
    else {
        confess "measured run ordinal is outside the selected repetition contract\n"
            unless $ordinal >= 1 && $ordinal <= $RUN_ORDINAL_MAX{$run_class};
    }
    return ($run_class, 0 + $ordinal);
}

sub _validate_preceding_validation($record, $construction, $git, $host) {
    confess "measured run requires one validation record\n"
        unless ref($record) eq 'HASH' && !blessed($record);
    _validate_record($record);
    confess "preceding validation run did not succeed\n"
        unless $record->{run_class} eq 'validation'
            && $record->{run_ordinal} == 0
            && $record->{outcome} eq 'accepted';
    confess "preceding validation workload identity changed\n"
        unless $record->{workload_identity}
            eq $construction->{workload_identity};
    confess "preceding validation workload specification changed\n"
        unless _canonical_json($record->{workload_specification})
            eq _canonical_json($construction->{specification});
    confess "Git revision changed after validation\n"
        unless $record->{git_revision} eq $git->{revision};
    confess "Git dirty state changed after validation\n"
        unless _canonical_json($record->{dirty_state})
            eq _canonical_json($git->{dirty_state});
    confess "host profile changed after validation\n"
        unless _canonical_json($record->{host_profile})
            eq _canonical_json($host);
}

sub _effective_timeout($stage, $backend) {
    confess "measurement stage is unknown\n"
        unless defined($stage) && !ref($stage)
            && exists $OUTER_TIMEOUT_SECONDS{$stage};
    if (defined $backend) {
        confess "backend_timeout_seconds must be a positive integer or null\n"
            unless !ref($backend)
                && $backend =~ /\A[1-9][0-9]*\z/;
        $backend = 0 + $backend;
    }
    my $outer = $OUTER_TIMEOUT_SECONDS{$stage};
    my $effective = defined($backend) && $backend < $outer
        ? $backend : $outer;
    return {
        outer_seconds => $outer,
        backend_seconds => $backend,
        effective_seconds => $effective,
        authority => defined($backend) && $backend < $outer
            ? 'qualified_backend' : 'architecture_scale_outer',
    };
}

sub _resource_guard($run_class) {
    my $active = ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    if ($active) {
        confess "active RAM guard host threshold is invalid\n"
            unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
                && $host <= 88;
        confess "active RAM guard descendant threshold is invalid\n"
            unless defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
                && $rss <= 4096;
    }
    return {
        active => $active ? JSON::PP::true : JSON::PP::false,
        enforcement => $active
            ? 'repository_ram_guard' : 'validation_unmeasured_only',
        host_max_percent => $active ? 0 + $host : 88,
        single_descendant_max_mib => $active ? 0 + $rss : 4096,
        sampler_interval_ns => $SAMPLER_INTERVAL_NS,
    };
}

sub _foundation_tool_profile() {
    return {
        applicability => 'fsmgen_owned_foundation_only',
        logical_name => 'in_process_perl_worker',
        reported_version => "$]",
        build => $Config::Config{archname},
        provider_identity => 'repository_runtime',
        arguments => [],
        thread_count => 1,
        job_count => 1,
        external_verification_tool => JSON::PP::false,
    };
}

sub _selected_tool_profile($specification, $supplied) {
    my $selected = $specification->{tool_profile};
    if (!defined $selected) {
        confess "foundation-only measurement cannot accept a supplied tool profile\n"
            if defined $supplied;
        return _foundation_tool_profile();
    }
    confess "runtime measurement requires one closed selected tool profile\n"
        unless ref($supplied) eq 'HASH' && !blessed($supplied);
    _validate_tool_profile($supplied);
    my $expected = $selected eq 'verilator_5_046'
        ? {
            applicability => 'qualified_runtime',
            logical_name => 'verilator',
            reported_version =>
                'Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228',
            build => '5.046',
            provider_identity => 'qualified_verilator_5_046',
            arguments => [qw(
                --binary --timing --assert --threads 1 -j 1
                --x-initial 0 --x-assign 0
            )],
            thread_count => 1,
            job_count => 1,
            external_verification_tool => JSON::PP::true,
        }
        : undef;
    confess "selected runtime tool profile is not implemented by the common controller\n"
        unless defined $expected;
    confess "supplied runtime tool profile differs from repository authority\n"
        unless _canonical_json($supplied) eq _canonical_json($expected);
    return _clone($expected);
}

sub _git_profile($repo_root) {
    my ($revision_ok, $revision) = _capture_command(
        'git', '-C', $repo_root, 'rev-parse', 'HEAD',
    );
    confess "cannot derive measurement Git revision\n" unless $revision_ok;
    $revision =~ s/\s+\z//;
    confess "measurement Git revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my ($status_ok, $status) = _capture_command(
        'git', '-C', $repo_root, 'status', '--porcelain=v1',
        '--untracked-files=normal',
    );
    confess "cannot derive measurement Git dirty state\n" unless $status_ok;
    return {
        revision => $revision,
        dirty_state => length($status)
            ? JSON::PP::true : JSON::PP::false,
    };
}

sub _host_profile($repo_root) {
    my ($system, undef, $release, undef, $machine) = uname();
    confess "host uname profile is unavailable\n"
        unless defined($system) && defined($release) && defined($machine);
    my ($cpu_model, $logical_cores, $physical_memory, $filesystem_type);
    if ($^O eq 'darwin') {
        $cpu_model = _command_scalar('sysctl', '-n', 'machdep.cpu.brand_string');
        $cpu_model //= _command_scalar('sysctl', '-n', 'hw.model');
        $logical_cores = _command_uint('sysctl', '-n', 'hw.logicalcpu');
        $physical_memory = _command_uint('sysctl', '-n', 'hw.memsize');
        $filesystem_type = _darwin_filesystem_type($repo_root);
    }
    elsif ($^O eq 'linux') {
        $cpu_model = _linux_cpu_model();
        $logical_cores = _linux_logical_cores();
        $physical_memory = _linux_physical_memory();
        $filesystem_type = _linux_filesystem_type($repo_root);
    }
    confess "host CPU model is unavailable\n" unless defined $cpu_model;
    confess "host logical-core count is unavailable\n"
        unless defined $logical_cores;
    confess "host physical memory is unavailable\n"
        unless defined $physical_memory;
    confess "host filesystem type is unavailable\n"
        unless defined $filesystem_type;
    return {
        os_name => $system,
        os_version => $release,
        architecture => $machine,
        cpu_model => $cpu_model,
        logical_core_count => $logical_cores,
        physical_memory_bytes => $physical_memory,
        filesystem_type => $filesystem_type,
        measurement_implementation => $IMPLEMENTATION,
    };
}

sub _process_sample($worker_pid, $started, $ordinal, $unsupported) {
    my ($ok, $output) = _capture_command(
        'ps', '-axo', 'pid=,ppid=,rss=,utime=,stime=',
    );
    my $offset = _seconds_to_ns(
        clock_gettime(CLOCK_MONOTONIC) - $started,
    );
    if (!$ok) {
        push @$unsupported, 'process_tree_ps_unavailable';
        return {
            ordinal => $ordinal,
            monotonic_offset_ns => $offset,
            controller_rss_bytes => undef,
            descendant_tree_rss_bytes => undef,
            process_tree_rss_bytes => undef,
            single_descendant_rss_bytes => undef,
            live_descendant_count => undef,
            descendant_user_cpu_ns => undef,
            descendant_system_cpu_ns => undef,
            unsupported_reason => 'process_tree_ps_unavailable',
        };
    }
    my (%row, %children);
    for my $line (split /\n/, $output) {
        next unless $line =~ /^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)\s*$/;
        my ($pid, $ppid, $rss_kib, $user, $system) = ($1, $2, $3, $4, $5);
        my $user_ns = _ps_time_ns($user);
        my $system_ns = _ps_time_ns($system);
        next unless defined($user_ns) && defined($system_ns);
        $row{$pid} = {
            ppid => 0 + $ppid,
            rss_bytes => 0 + $rss_kib * 1024,
            user_cpu_ns => $user_ns,
            system_cpu_ns => $system_ns,
        };
        push @{$children{$ppid}}, 0 + $pid;
    }
    my @queue = ($worker_pid);
    my (%seen, @descendants);
    while (@queue) {
        my $pid = shift @queue;
        next if $seen{$pid}++;
        if (exists $row{$pid}) {
            push @descendants, $pid;
            push @queue, @{$children{$pid} // []};
        }
    }
    my $controller = $row{$$};
    if (!defined($controller) || !@descendants) {
        push @$unsupported, 'process_tree_root_not_observed';
        return {
            ordinal => $ordinal,
            monotonic_offset_ns => $offset,
            controller_rss_bytes => defined($controller)
                ? $controller->{rss_bytes} : undef,
            descendant_tree_rss_bytes => undef,
            process_tree_rss_bytes => undef,
            single_descendant_rss_bytes => undef,
            live_descendant_count => 0,
            descendant_user_cpu_ns => undef,
            descendant_system_cpu_ns => undef,
            unsupported_reason => 'process_tree_root_not_observed',
        };
    }
    my ($tree_rss, $single_rss, $user_ns, $system_ns) = (0, 0, 0, 0);
    for my $pid (@descendants) {
        my $entry = $row{$pid};
        $tree_rss += $entry->{rss_bytes};
        $single_rss = $entry->{rss_bytes}
            if $entry->{rss_bytes} > $single_rss;
        $user_ns += $entry->{user_cpu_ns};
        $system_ns += $entry->{system_cpu_ns};
    }
    return {
        ordinal => $ordinal,
        monotonic_offset_ns => $offset,
        controller_rss_bytes => $controller->{rss_bytes},
        descendant_tree_rss_bytes => $tree_rss,
        process_tree_rss_bytes => $controller->{rss_bytes} + $tree_rss,
        single_descendant_rss_bytes => $single_rss,
        live_descendant_count => scalar(@descendants),
        descendant_user_cpu_ns => $user_ns,
        descendant_system_cpu_ns => $system_ns,
        unsupported_reason => undef,
    };
}

sub _measured_metrics($started, $finished, $before, $after, $samples, $unsupported) {
    my @supported = grep { !defined($_->{unsupported_reason}) } @$samples;
    my $last = @supported ? $supported[-1] : undef;
    my $peak_tree = @supported
        ? _maximum(map { $_->{process_tree_rss_bytes} } @supported) : undef;
    my $peak_single = @supported
        ? _maximum(map { $_->{single_descendant_rss_bytes} } @supported)
        : undef;
    my %unsupported = map { $_ => 1 } @$unsupported;
    $unsupported{short_lived_process_undercount_possible} = 1;
    return {
        wall_time_ns => _seconds_to_ns($finished - $started),
        controller_cpu => {
            user_ns => _seconds_to_ns($after->[0] - $before->[0]),
            system_ns => _seconds_to_ns($after->[1] - $before->[1]),
            unsupported_reason => undef,
        },
        descendant_cpu => {
            user_ns => defined($last) ? $last->{descendant_user_cpu_ns} : undef,
            system_ns => defined($last)
                ? $last->{descendant_system_cpu_ns} : undef,
            unsupported_reason => defined($last)
                ? 'short_lived_process_undercount_possible'
                : 'process_tree_cpu_unavailable',
        },
        rss => {
            peak_process_tree_bytes => $peak_tree,
            peak_single_descendant_bytes => $peak_single,
            unsupported_reason => defined($peak_tree)
                ? undef : 'process_tree_rss_unavailable',
        },
        raw_samples => _clone($samples),
        unsupported_counters => [sort keys %unsupported],
    };
}

sub _unmeasured_metrics() {
    return {
        wall_time_ns => undef,
        controller_cpu => {
            user_ns => undef,
            system_ns => undef,
            unsupported_reason => 'validation_run_is_unmeasured',
        },
        descendant_cpu => {
            user_ns => undef,
            system_ns => undef,
            unsupported_reason => 'validation_run_is_unmeasured',
        },
        rss => {
            peak_process_tree_bytes => undef,
            peak_single_descendant_bytes => undef,
            unsupported_reason => 'validation_run_is_unmeasured',
        },
        raw_samples => [],
        unsupported_counters => ['validation_run_is_unmeasured'],
    };
}

sub _cleanup_measurement($raw) {
    my $measured = $raw->{run_class} ne 'validation';
    my $metrics = $measured
        ? {
            wall_time_ns => _seconds_to_ns($raw->{finished} - $raw->{started}),
            controller_cpu => {
                user_ns => _seconds_to_ns(
                    $raw->{times_after}[0] - $raw->{times_before}[0],
                ),
                system_ns => _seconds_to_ns(
                    $raw->{times_after}[1] - $raw->{times_before}[1],
                ),
                unsupported_reason => undef,
            },
        }
        : {
            wall_time_ns => undef,
            controller_cpu => {
                user_ns => undef,
                system_ns => undef,
                unsupported_reason => 'validation_run_is_unmeasured',
            },
        };
    return {
        stage => 'cleanup',
        status => $measured
            ? ($raw->{ok} ? 'measured' : 'measured_rejected')
            : ($raw->{ok} ? 'validated_unmeasured' : 'validation_rejected'),
        worker_status => $raw->{ok} ? 'cleanup_completed' : 'cleanup_failed',
        classification => 'fsmgen_owned',
        not_run_reason => undef,
        timeout => _effective_timeout('cleanup', undef),
        wall_time_ns => $metrics->{wall_time_ns},
        controller_cpu => $metrics->{controller_cpu},
        descendant_cpu => {
            user_ns => undef,
            system_ns => undef,
            unsupported_reason => 'no_descendant_cleanup_process',
        },
        rss => {
            peak_process_tree_bytes => undef,
            peak_single_descendant_bytes => undef,
            unsupported_reason => 'cleanup_is_controller_local',
        },
        input_counts => _zero_counts(),
        output_counts => _zero_counts(),
        semantic_object_counts => {},
        command_identity => {
            logical_name => 'repository_owned_cleanup',
            arguments => [],
            thread_count => 1,
            job_count => 1,
        },
        process => {
            exit_code => $raw->{ok} ? 0 : 1,
            signal => 0,
            timed_out => JSON::PP::false,
        },
        raw_samples => [],
        unsupported_counters => [
            $measured ? 'cleanup_is_controller_local'
                : 'validation_run_is_unmeasured',
        ],
        correctness_oracle_ids => [$raw->{oracle_id}],
    };
}

sub _not_run_stage($stage, $reason) {
    return {
        stage => $stage,
        status => 'not_run',
        worker_status => undef,
        classification => 'not_applicable',
        not_run_reason => $reason,
        timeout => _effective_timeout($stage, undef),
        wall_time_ns => undef,
        controller_cpu => {
            user_ns => undef,
            system_ns => undef,
            unsupported_reason => 'stage_not_run',
        },
        descendant_cpu => {
            user_ns => undef,
            system_ns => undef,
            unsupported_reason => 'stage_not_run',
        },
        rss => {
            peak_process_tree_bytes => undef,
            peak_single_descendant_bytes => undef,
            unsupported_reason => 'stage_not_run',
        },
        input_counts => _zero_counts(),
        output_counts => _zero_counts(),
        semantic_object_counts => {},
        command_identity => undef,
        process => {
            exit_code => undef,
            signal => undef,
            timed_out => JSON::PP::false,
        },
        raw_samples => [],
        unsupported_counters => ['stage_not_run'],
        correctness_oracle_ids => [],
    };
}

sub _validated_worker_oracles($stage, $raw) {
    confess "worker correctness_oracles must be a non-empty array\n"
        unless ref($raw) eq 'ARRAY' && @$raw;
    my (@out, %seen);
    for my $index (0 .. $#$raw) {
        my $oracle = $raw->[$index];
        confess "worker oracle $index must be one unblessed hash\n"
            unless ref($oracle) eq 'HASH' && !blessed($oracle);
        _exact_keys($oracle, \@WORKER_ORACLE_KEYS, "worker oracle $index");
        my $id = $oracle->{oracle_id};
        confess "worker oracle $index id is invalid\n"
            unless _safe_token($id);
        confess "duplicate worker oracle '$id'\n" if $seen{$id}++;
        _require_json_value($oracle->{evidence}, "worker oracle $index evidence");
        my $ok = _json_boolean($oracle->{ok}, "worker oracle $index ok");
        my $evidence = _clone($oracle->{evidence});
        push @out, {
            stage => $stage,
            oracle_id => $id,
            ok => $ok,
            evidence_identity => sha256_hex(_canonical_json($evidence)),
            evidence => $evidence,
        };
    }
    return \@out;
}

sub _validated_worker_artifacts($stage_abs, $stage, $raw) {
    confess "worker artifacts must be an array\n"
        unless ref($raw) eq 'ARRAY';
    my (@out, %expected);
    for my $index (0 .. $#$raw) {
        my $artifact = $raw->[$index];
        confess "worker artifact $index must be one unblessed hash\n"
            unless ref($artifact) eq 'HASH' && !blessed($artifact);
        _exact_keys(
            $artifact, \@WORKER_ARTIFACT_KEYS, "worker artifact $index",
        );
        my $relative = $artifact->{relative_path};
        confess "worker artifact $index path is unsafe\n"
            unless _safe_relative_path($relative);
        confess "worker artifact $index must remain below its stage output root\n"
            unless $relative =~ m{\Aoutputs/\Q$stage\E/};
        confess "duplicate worker artifact '$relative'\n"
            if $expected{$relative}++;
        my $path = File::Spec->catfile($stage_abs, split m{/}, $relative);
        my @stat = lstat($path);
        confess "worker artifact '$relative' is absent or not a regular file\n"
            unless @stat && -f _ && !-l _;
        open my $fh, '<:raw', $path
            or confess "cannot read worker artifact '$relative'\n";
        local $/;
        my $content = <$fh>;
        close $fh or confess "cannot close worker artifact '$relative'\n";
        my $bytes = bytes::length($content);
        my $lines = () = $content =~ /\n/g;
        confess "worker artifact '$relative' byte count changed\n"
            unless _nonnegative_integer($artifact->{bytes})
                && $artifact->{bytes} == $bytes;
        confess "worker artifact '$relative' line count changed\n"
            unless _nonnegative_integer($artifact->{lines})
                && $artifact->{lines} == $lines;
        confess "worker artifact '$relative' digest changed\n"
            unless defined($artifact->{sha256}) && !ref($artifact->{sha256})
                && $artifact->{sha256} eq sha256_hex($content);
        confess "worker artifact '$relative' kind is invalid\n"
            unless _safe_token($artifact->{kind});
        push @out, {stage => $stage, %{_clone($artifact)}};
    }
    my $stage_output_abs = File::Spec->catdir(
        $stage_abs, 'outputs', $stage,
    );
    my @actual = -d($stage_output_abs)
        ? map { "outputs/$stage/$_" } _tree_files($stage_output_abs)
        : ();
    my @expected = sort keys %expected;
    confess "worker output tree contains unreported files\n"
        unless _canonical_json(\@actual) eq _canonical_json(\@expected);
    return \@out;
}

sub _validate_owned_artifact_census($stage_abs, $artifacts) {
    my (%expected, %stage);
    for my $index (0 .. $#$artifacts) {
        my $artifact = $artifacts->[$index];
        confess "measurement artifact $index is not stage-owned\n"
            unless ref($artifact) eq 'HASH'
                && exists($artifact->{stage})
                && exists($artifact->{relative_path});
        my $relative = $artifact->{relative_path};
        confess "duplicate measurement artifact '$relative'\n"
            if $expected{$relative}++;
        $stage{$artifact->{stage}}++;
    }
    my @actual = _tree_files($stage_abs);
    my @expected = sort keys %expected;
    confess "measurement staging contains unreported or missing artifacts\n"
        unless _canonical_json(\@actual) eq _canonical_json(\@expected);
    return 1;
}

sub _validate_output_counts($counts, $artifacts) {
    _validated_counts($counts, 'stage output counts');
    my $files = scalar @$artifacts;
    my $lines = 0;
    my $bytes = 0;
    $lines += $_->{lines} for @$artifacts;
    $bytes += $_->{bytes} for @$artifacts;
    confess "stage output file count does not match artifacts\n"
        unless $counts->{files} == $files;
    confess "stage output line count does not match artifacts\n"
        unless $counts->{lines} == $lines;
    confess "stage output byte count does not match artifacts\n"
        unless $counts->{bytes} == $bytes;
}

sub _validated_counts($counts, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($counts) eq 'HASH' && !blessed($counts);
    _exact_keys($counts, \@COUNT_KEYS, $label);
    confess "$label contains a non-integer value\n"
        if grep { !_nonnegative_integer($counts->{$_}) } @COUNT_KEYS;
}

sub _validate_semantic_counts($counts) {
    confess "semantic object counts must be one unblessed hash\n"
        unless ref($counts) eq 'HASH' && !blessed($counts);
    for my $key (keys %$counts) {
        confess "semantic object-count key '$key' is invalid\n"
            unless _safe_token($key);
        confess "semantic object count '$key' must be a nonnegative integer\n"
            unless _nonnegative_integer($counts->{$key});
    }
}

sub _validated_command_identity($raw) {
    confess "command identity must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    _exact_keys($raw, \@COMMAND_KEYS, 'command identity');
    confess "command logical name is invalid\n"
        unless _safe_token($raw->{logical_name});
    confess "command arguments must be an array\n"
        unless ref($raw->{arguments}) eq 'ARRAY';
    for my $argument (@{$raw->{arguments}}) {
        confess "command argument must be one safe scalar\n"
            unless defined($argument) && !ref($argument)
                && $argument !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    }
    for my $key (qw(thread_count job_count)) {
        confess "command $key must be a positive integer\n"
            unless _nonnegative_integer($raw->{$key}) && $raw->{$key} >= 1;
    }
}

sub _decode_worker_result($buffer, $stage) {
    return (undef, _diagnostic(
        'VIAL_SCALE_MEASUREMENT_WORKER_RESULT_ERROR',
        'worker returned no result', "/stage_measurements/$stage",
    )) unless length $buffer;
    return (undef, _diagnostic(
        'VIAL_SCALE_MEASUREMENT_WORKER_RESULT_ERROR',
        'worker result exceeded the bounded envelope',
        "/stage_measurements/$stage",
    )) if bytes::length($buffer) > $MAX_WORKER_RESULT_BYTES;
    my $decoded = eval { JSON::PP->new->utf8(1)->decode($buffer) };
    return (undef, _diagnostic(
        'VIAL_SCALE_MEASUREMENT_WORKER_RESULT_ERROR',
        'worker result is not valid JSON', "/stage_measurements/$stage",
    )) unless defined $decoded;
    return (undef, _diagnostic(
        'VIAL_SCALE_MEASUREMENT_WORKER_RESULT_ERROR',
        'worker result must be one closed object',
        "/stage_measurements/$stage",
    )) unless ref($decoded) eq 'HASH' && !blessed($decoded);
    my $ok = eval {
        _exact_keys($decoded, \@WORKER_RESULT_KEYS, 'worker result');
        _json_boolean($decoded->{ok}, 'worker result ok');
        confess "worker result status is invalid\n"
            unless _safe_token($decoded->{status});
        _validated_counts($decoded->{output_counts}, 'worker output counts');
        _validate_semantic_counts($decoded->{semantic_object_counts});
        confess "worker correctness_oracles must be an array\n"
            unless ref($decoded->{correctness_oracles}) eq 'ARRAY';
        confess "worker artifacts must be an array\n"
            unless ref($decoded->{artifacts}) eq 'ARRAY';
        if (defined $decoded->{diagnostic}) {
            _validate_diagnostic($decoded->{diagnostic}, 'worker diagnostic');
        }
        confess "successful worker result retained a diagnostic\n"
            if $decoded->{ok} && defined($decoded->{diagnostic});
        1;
    };
    return (undef, _diagnostic(
        'VIAL_SCALE_MEASUREMENT_WORKER_RESULT_ERROR',
        _sanitize_exception($@), "/stage_measurements/$stage",
    )) unless $ok;
    return ($decoded, undef);
}

sub _publish_record($raw) {
    my ($repo_root, $root_device) =
        _validated_repository_root($raw->{repository_root});
    confess "measurement contract_version must be 'v1'\n"
        unless defined($raw->{contract_version})
            && !ref($raw->{contract_version})
            && $raw->{contract_version} eq 'v1';
    confess "measurement publication profile_id is invalid\n"
        unless _safe_token($raw->{profile_id});
    confess "measurement publication requires the active repository RAM guard\n"
        unless _resource_guard('gate_measurement')->{active};
    _validate_record($raw->{record});
    my $record = _clone($raw->{record});
    confess "measurement publication requires one accepted measured record\n"
        unless $record->{outcome} eq 'accepted'
            && $record->{run_class} ne 'validation';
    my ($workload_digest) = $record->{workload_identity}
        =~ m{\Aworkload/([0-9a-f]{64})\z};
    my ($measurement_digest) = $record->{measurement_identity}
        =~ m{\Ameasurement/([0-9a-f]{64})\z};
    confess "measurement publication identities are invalid\n"
        unless defined($workload_digest) && defined($measurement_digest);
    my $target_rel = join(
        '/', $PUBLICATION_BASE, $raw->{contract_version}, $raw->{profile_id},
    );
    my $artifact_rel = "$target_rel/measurement.json";
    my $stage_rel = join(
        '/', $STAGING_BASE, $workload_digest, $record->{run_class},
        sprintf('%02d', $record->{run_ordinal}),
        "publication-$measurement_digest",
    );
    my $target_abs = _safe_destination(
        $repo_root, $root_device, $target_rel,
    );
    my $encoded = _canonical_json($record) . "\n";
    if (-e $target_abs || -l $target_abs) {
        if (_published_record_is_identical($target_abs, $encoded)) {
            return _publication_result({
                ok => JSON::PP::true,
                status => 'unchanged',
                schema => $PUBLICATION_SCHEMA,
                schema_version => 1,
                measurement_identity => $record->{measurement_identity},
                publication_identity => $target_rel,
                artifact_relative_path => $artifact_rel,
                same_volume => JSON::PP::true,
                atomic => JSON::PP::true,
                diagnostics => [],
            });
        }
        return _publication_failure(
            $record->{measurement_identity}, $target_rel, $artifact_rel,
            'VIAL_SCALE_MEASUREMENT_PUBLICATION_COLLISION',
            "publication root '$target_rel' already exists with different bytes",
            '/publication_identity',
        );
    }
    my ($stage_abs, $created) = eval {
        _create_owned_stage($repo_root, $root_device, $stage_rel);
    };
    if (!defined $stage_abs) {
        return _publication_failure(
            $record->{measurement_identity}, $target_rel, $artifact_rel,
            'VIAL_SCALE_MEASUREMENT_PUBLICATION_ERROR',
            _sanitize_exception($@), '/publication_identity',
        );
    }
    my @publication_created;
    my $published = eval {
        my $path = File::Spec->catfile($stage_abs, 'measurement.json');
        _write_publication($path, $encoded);
        my $parent = dirname($target_abs);
        _ensure_publication_parent(
            $repo_root, $root_device, $parent, dirname($target_rel),
            \@publication_created,
        );
        confess "measurement publication target appeared during commit\n"
            if -e $target_abs || -l $target_abs;
        _atomic_publish($stage_abs, $target_abs);
        1;
    };
    my $error = $@;
    if (!$published) {
        _remove_owned_stage($stage_abs, $stage_rel, $created);
        _remove_empty_created_directories(\@publication_created, undef);
        return _publication_failure(
            $record->{measurement_identity}, $target_rel, $artifact_rel,
            'VIAL_SCALE_MEASUREMENT_PUBLICATION_ERROR',
            _sanitize_exception($error), '/publication_identity',
        );
    }
    _remove_empty_created_directories($created, $stage_abs);
    return _publication_result({
        ok => JSON::PP::true,
        status => 'published',
        schema => $PUBLICATION_SCHEMA,
        schema_version => 1,
        measurement_identity => $record->{measurement_identity},
        publication_identity => $target_rel,
        artifact_relative_path => $artifact_rel,
        same_volume => JSON::PP::true,
        atomic => JSON::PP::true,
        diagnostics => [],
    });
}

sub _write_publication($path, $encoded) {
    open my $fh, '>:raw', $path
        or confess "cannot create measurement publication file\n";
    print {$fh} $encoded
        or confess "cannot write measurement publication file\n";
    close $fh or confess "cannot close measurement publication file\n";
}

sub _atomic_publish($source, $target) {
    rename($source, $target)
        or confess "cannot atomically publish measurement record\n";
}

sub _published_record_is_identical($target_abs, $encoded) {
    return 0 unless -d $target_abs && !-l $target_abs;
    opendir my $dh, $target_abs or return 0;
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or return 0;
    return 0 unless @entries == 1 && $entries[0] eq 'measurement.json';
    my $path = File::Spec->catfile($target_abs, 'measurement.json');
    return 0 unless -f $path && !-l $path;
    open my $fh, '<:raw', $path or return 0;
    local $/;
    my $content = <$fh>;
    close $fh or return 0;
    return defined($content) && $content eq $encoded;
}

sub _validate_record($record) {
    confess "measurement record must be one unblessed hash\n"
        unless ref($record) eq 'HASH' && !blessed($record);
    _exact_keys($record, \@RECORD_KEYS, 'measurement record');
    confess "measurement record schema is invalid\n"
        unless ($record->{schema} // '') eq $SCHEMA
            && ($record->{schema_version} // 0) == 1;
    confess "measurement workload identity is invalid\n"
        unless ($record->{workload_identity} // '')
            =~ m{\Aworkload/[0-9a-f]{64}\z};
    _require_json_value(
        $record->{workload_specification},
        'measurement workload specification',
    );
    _validated_run($record->{run_class}, $record->{run_ordinal});
    confess "measurement Git revision is invalid\n"
        unless ($record->{git_revision} // '') =~ /\A[0-9a-f]{40}\z/;
    _json_boolean($record->{dirty_state}, 'measurement dirty_state');
    _validate_host_profile($record->{host_profile});
    _validate_tool_profile($record->{tool_profile});
    my $expected_tool = _selected_tool_profile(
        $record->{workload_specification},
        defined($record->{workload_specification}{tool_profile})
            ? $record->{tool_profile} : undef,
    );
    confess "measurement tool profile changed from workload authority\n"
        unless _canonical_json($record->{tool_profile})
            eq _canonical_json($expected_tool);
    _validate_resource_guard($record->{resource_guard}, $record->{run_class});
    confess "measurement stage array is invalid\n"
        unless ref($record->{stage_measurements}) eq 'ARRAY'
            && @{$record->{stage_measurements}} == @STAGES;
    my @actual_stages;
    my %oracle_ids;
    for my $index (0 .. $#STAGES) {
        my $stage = $record->{stage_measurements}[$index];
        confess "measurement stage $index must be one closed hash\n"
            unless ref($stage) eq 'HASH' && !blessed($stage);
        _exact_keys($stage, \@STAGE_KEYS, "measurement stage $index");
        push @actual_stages, $stage->{stage};
        _validate_stage_measurement($stage, $record->{run_class});
        confess "external-tool stage lacks an external selected tool profile\n"
            if ($stage->{classification} // '') eq 'external_tool'
                && !$record->{tool_profile}{external_verification_tool};
        for my $oracle_id (@{$stage->{correctness_oracle_ids}}) {
            confess "measurement oracle '$oracle_id' is referenced twice\n"
                if exists $oracle_ids{$oracle_id};
            $oracle_ids{$oracle_id} = $stage->{stage};
        }
    }
    confess "measurement stage order changed\n"
        unless _canonical_json(\@actual_stages) eq _canonical_json(\@STAGES);
    confess "measurement correctness_oracles must be an array\n"
        unless ref($record->{correctness_oracles}) eq 'ARRAY';
    my %record_oracles;
    for my $oracle (@{$record->{correctness_oracles}}) {
        confess "measurement oracle must be one closed hash\n"
            unless ref($oracle) eq 'HASH' && !blessed($oracle);
        _exact_keys(
            $oracle,
            [qw(stage oracle_id ok evidence_identity evidence)],
            'measurement oracle',
        );
        confess "measurement oracle stage is invalid\n"
            unless exists $STAGE_INDEX{$oracle->{stage}};
        confess "measurement oracle id is invalid\n"
            unless _safe_token($oracle->{oracle_id});
        _json_boolean($oracle->{ok}, 'measurement oracle ok');
        _require_json_value($oracle->{evidence}, 'measurement oracle evidence');
        confess "measurement oracle evidence identity changed\n"
            unless ($oracle->{evidence_identity} // '')
                eq sha256_hex(_canonical_json($oracle->{evidence}));
        confess "measurement oracle '$oracle->{oracle_id}' is duplicated\n"
            if exists $record_oracles{$oracle->{oracle_id}};
        $record_oracles{$oracle->{oracle_id}} = $oracle->{stage};
    }
    confess "measurement stage/oracle membership changed\n"
        unless _canonical_json(\%oracle_ids)
            eq _canonical_json(\%record_oracles);
    _validate_record_artifacts($record);
    confess "measurement explicit nonclaims changed\n"
        unless _canonical_json($record->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "measurement cleanup is not closed\n"
        unless ref($record->{cleanup}) eq 'HASH'
            && !blessed($record->{cleanup});
    _exact_keys(
        $record->{cleanup},
        [qw(staging_identity ephemeral_removed residue)],
        'measurement cleanup',
    );
    _json_boolean(
        $record->{cleanup}{ephemeral_removed},
        'measurement cleanup ephemeral_removed',
    );
    confess "measurement cleanup staging identity changed\n"
        unless ($record->{cleanup}{staging_identity} // '')
            eq ($record->{artifacts}{staging_identity} // '');
    confess "measurement cleanup residue must be an array\n"
        unless ref($record->{cleanup}{residue}) eq 'ARRAY';
    my %residue;
    for my $relative (@{$record->{cleanup}{residue}}) {
        confess "measurement cleanup residue identity is unsafe\n"
            unless _safe_relative_path($relative)
                && !$residue{$relative}++;
    }
    confess "successful cleanup retained residue\n"
        if $record->{cleanup}{ephemeral_removed}
            && @{$record->{cleanup}{residue}};
    confess "failed cleanup omitted residue evidence\n"
        if !$record->{cleanup}{ephemeral_removed}
            && !@{$record->{cleanup}{residue}};
    confess "measurement outcome is invalid\n"
        unless ($record->{outcome} // '') =~ /\A(?:
            accepted|stage_failure|correctness_failure|cleanup_failure
        )\z/x;
    if ($record->{outcome} eq 'accepted') {
        confess "accepted measurement retained a diagnostic\n"
            if defined $record->{diagnostic};
    }
    else {
        _validate_diagnostic(
            $record->{diagnostic}, 'measurement outcome diagnostic',
        );
    }
    confess "accepted measurement did not remove ephemeral staging\n"
        if $record->{outcome} eq 'accepted'
            && !$record->{cleanup}{ephemeral_removed};
    confess "measurement identity changed\n"
        unless ($record->{measurement_identity} // '')
            eq _measurement_identity($record);
    my $machine_path_location = _machine_path_location($record, '');
    confess "measurement record contains a machine-local path at '$machine_path_location'\n"
        if defined $machine_path_location;
    return 1;
}

sub _validate_stage_measurement($stage, $run_class) {
    confess "measurement stage name is invalid\n"
        unless exists $STAGE_INDEX{$stage->{stage}};
    confess "measurement stage status is invalid\n"
        unless ($stage->{status} // '') =~ /\A(?:
            not_run|validated_unmeasured|validation_rejected|
            measured|measured_rejected
        )\z/x;
    my $not_run = $stage->{status} eq 'not_run';
    if ($not_run) {
        confess "not-run stage retained worker status\n"
            if defined $stage->{worker_status};
        confess "not-run stage classification changed\n"
            unless ($stage->{classification} // '') eq 'not_applicable';
        confess "not-run stage has no safe reason\n"
            unless _safe_token($stage->{not_run_reason});
    }
    else {
        confess "executed stage worker status is invalid\n"
            unless _safe_token($stage->{worker_status});
        confess "executed stage classification changed\n"
            unless ($stage->{classification} // '')
                =~ /\A(?:fsmgen_owned|external_tool)\z/;
        confess "executed stage retained a not-run reason\n"
            if defined $stage->{not_run_reason};
    }
    confess "validation stage has a measured status\n"
        if $run_class eq 'validation'
            && $stage->{status} =~ /\Ameasured/;
    confess "measured run has a validation status\n"
        if $run_class ne 'validation'
            && $stage->{status} =~ /\Avalidation/;
    confess "measurement stage timeout is not closed\n"
        unless ref($stage->{timeout}) eq 'HASH'
            && !blessed($stage->{timeout});
    _exact_keys($stage->{timeout}, \@TIMEOUT_KEYS, 'measurement stage timeout');
    my $expected_timeout = _effective_timeout(
        $stage->{stage}, $stage->{timeout}{backend_seconds},
    );
    confess "measurement stage timeout authority changed\n"
        unless _canonical_json($stage->{timeout})
            eq _canonical_json($expected_timeout);
    _validated_counts($stage->{input_counts}, 'measurement stage input counts');
    _validated_counts($stage->{output_counts}, 'measurement stage output counts');
    _validate_semantic_counts($stage->{semantic_object_counts});
    if (defined $stage->{command_identity}) {
        _validated_command_identity($stage->{command_identity});
    }
    confess "executed stage omitted command identity\n"
        if !$not_run && !defined($stage->{command_identity});
    confess "not-run stage retained command identity\n"
        if $not_run && defined($stage->{command_identity});
    _validate_cpu_counter($stage->{controller_cpu}, 'controller CPU');
    _validate_cpu_counter($stage->{descendant_cpu}, 'descendant CPU');
    _validate_rss_counter($stage->{rss});
    confess "measurement process result is not closed\n"
        unless ref($stage->{process}) eq 'HASH'
            && !blessed($stage->{process});
    _exact_keys($stage->{process}, \@PROCESS_KEYS, 'measurement process result');
    for my $key (qw(exit_code signal)) {
        confess "measurement process $key is invalid\n"
            unless !defined($stage->{process}{$key})
                || _nonnegative_integer($stage->{process}{$key});
    }
    _json_boolean($stage->{process}{timed_out}, 'measurement process timed_out');
    confess "measurement raw_samples must be an array\n"
        unless ref($stage->{raw_samples}) eq 'ARRAY';
    my $last_offset = -1;
    for my $index (0 .. $#{$stage->{raw_samples}}) {
        my $sample = $stage->{raw_samples}[$index];
        confess "measurement sample $index must be one closed hash\n"
            unless ref($sample) eq 'HASH' && !blessed($sample);
        _exact_keys($sample, \@SAMPLE_KEYS, "measurement sample $index");
        confess "measurement sample ordinal changed\n"
            unless _nonnegative_integer($sample->{ordinal})
                && $sample->{ordinal} == $index;
        confess "measurement sample offset is invalid\n"
            unless _nonnegative_integer($sample->{monotonic_offset_ns});
        confess "measurement sample offsets are not monotonic\n"
            unless $sample->{monotonic_offset_ns} >= $last_offset;
        $last_offset = $sample->{monotonic_offset_ns};
        for my $key (qw(
            controller_rss_bytes descendant_tree_rss_bytes
            process_tree_rss_bytes single_descendant_rss_bytes
            live_descendant_count descendant_user_cpu_ns
            descendant_system_cpu_ns
        )) {
            confess "measurement sample $index $key is invalid\n"
                unless !defined($sample->{$key})
                    || _nonnegative_integer($sample->{$key});
        }
        my $unsupported = grep {
            !defined $sample->{$_}
        } qw(
            descendant_tree_rss_bytes process_tree_rss_bytes
            single_descendant_rss_bytes live_descendant_count
            descendant_user_cpu_ns descendant_system_cpu_ns
        );
        confess "measurement sample $index unsupported reason is invalid\n"
            unless $unsupported
                ? _safe_token($sample->{unsupported_reason})
                : !defined($sample->{unsupported_reason});
    }
    confess "measurement unsupported_counters must be an array\n"
        unless ref($stage->{unsupported_counters}) eq 'ARRAY';
    _validate_sorted_tokens(
        $stage->{unsupported_counters}, 'measurement unsupported counter',
    );
    confess "measurement correctness_oracle_ids must be an array\n"
        unless ref($stage->{correctness_oracle_ids}) eq 'ARRAY';
    _validate_unique_tokens(
        $stage->{correctness_oracle_ids}, 'measurement correctness oracle id',
    );
    if ($run_class eq 'validation' && $stage->{status} ne 'not_run') {
        confess "validation stage retained performance measurements\n"
            if defined($stage->{wall_time_ns}) || @{$stage->{raw_samples}};
    }
    if ($stage->{status} =~ /\Ameasured/) {
        confess "measured stage has no wall measurement\n"
            unless _nonnegative_integer($stage->{wall_time_ns});
        confess "measured stage wall time precedes its final sample\n"
            if @{$stage->{raw_samples}}
                && $stage->{wall_time_ns} < $last_offset;
    }
    if ($stage->{status} =~ /\Avalidation/ || $not_run) {
        confess "unmeasured stage retained wall time or raw samples\n"
            if defined($stage->{wall_time_ns}) || @{$stage->{raw_samples}};
    }
    if (@{$stage->{raw_samples}}) {
        my @supported = grep {
            !defined($_->{unsupported_reason})
        } @{$stage->{raw_samples}};
        my $peak_tree = @supported
            ? _maximum(map { $_->{process_tree_rss_bytes} } @supported)
            : undef;
        my $peak_single = @supported
            ? _maximum(map { $_->{single_descendant_rss_bytes} } @supported)
            : undef;
        confess "measurement process-tree RSS peak changed\n"
            unless _same_nullable_number(
                $stage->{rss}{peak_process_tree_bytes}, $peak_tree,
            );
        confess "measurement descendant RSS peak changed\n"
            unless _same_nullable_number(
                $stage->{rss}{peak_single_descendant_bytes}, $peak_single,
            );
    }
}

sub _validate_host_profile($profile) {
    confess "measurement host profile must be one closed hash\n"
        unless ref($profile) eq 'HASH' && !blessed($profile);
    _exact_keys($profile, \@HOST_KEYS, 'measurement host profile');
    for my $key (qw(
        os_name os_version architecture cpu_model filesystem_type
    )) {
        confess "measurement host $key is invalid\n"
            unless _nonempty_scalar($profile->{$key});
    }
    for my $key (qw(logical_core_count physical_memory_bytes)) {
        confess "measurement host $key is invalid\n"
            unless _nonnegative_integer($profile->{$key})
                && $profile->{$key} >= 1;
    }
    confess "measurement implementation changed\n"
        unless ($profile->{measurement_implementation} // '')
            eq $IMPLEMENTATION;
}

sub _validate_tool_profile($profile) {
    confess "measurement tool profile must be one closed hash\n"
        unless ref($profile) eq 'HASH' && !blessed($profile);
    _exact_keys($profile, \@TOOL_KEYS, 'measurement tool profile');
    for my $key (qw(applicability logical_name provider_identity)) {
        confess "measurement tool $key is invalid\n"
            unless _safe_token($profile->{$key});
    }
    for my $key (qw(reported_version build)) {
        confess "measurement tool $key is invalid\n"
            unless _nonempty_scalar($profile->{$key});
    }
    confess "measurement tool arguments must be an array\n"
        unless ref($profile->{arguments}) eq 'ARRAY';
    for my $argument (@{$profile->{arguments}}) {
        confess "measurement tool argument is invalid\n"
            unless _nonempty_scalar($argument)
                && !_contains_machine_path($argument);
    }
    for my $key (qw(thread_count job_count)) {
        confess "measurement tool $key is invalid\n"
            unless _nonnegative_integer($profile->{$key})
                && $profile->{$key} >= 1;
    }
    _json_boolean(
        $profile->{external_verification_tool},
        'measurement external_verification_tool',
    );
}

sub _validate_resource_guard($guard, $run_class) {
    confess "measurement resource guard must be one closed hash\n"
        unless ref($guard) eq 'HASH' && !blessed($guard);
    _exact_keys($guard, \@GUARD_KEYS, 'measurement resource guard');
    my $active = _json_boolean($guard->{active}, 'measurement guard active');
    confess "measured record lacks active guard evidence\n"
        if $run_class ne 'validation' && !$active;
    confess "measurement guard enforcement is inconsistent\n"
        unless ($guard->{enforcement} // '') eq (
            $active ? 'repository_ram_guard' : 'validation_unmeasured_only'
        );
    confess "measurement host guard exceeds the selected ceiling\n"
        unless _nonnegative_number($guard->{host_max_percent})
            && $guard->{host_max_percent} > 0
            && $guard->{host_max_percent} <= 88;
    confess "measurement descendant guard exceeds the selected ceiling\n"
        unless _nonnegative_number($guard->{single_descendant_max_mib})
            && $guard->{single_descendant_max_mib} > 0
            && $guard->{single_descendant_max_mib} <= 4096;
    confess "measurement sampler interval changed\n"
        unless _nonnegative_integer($guard->{sampler_interval_ns})
            && $guard->{sampler_interval_ns} == $SAMPLER_INTERVAL_NS;
}

sub _validate_record_artifacts($record) {
    my $artifacts = $record->{artifacts};
    confess "measurement artifacts must be one closed hash\n"
        unless ref($artifacts) eq 'HASH' && !blessed($artifacts);
    _exact_keys(
        $artifacts, [qw(staging_identity published_identity records)],
        'measurement artifacts',
    );
    my ($digest) = $record->{workload_identity}
        =~ m{\Aworkload/([0-9a-f]{64})\z};
    my $expected_staging = join(
        '/', $STAGING_BASE, $digest, $record->{run_class},
        sprintf('%02d', $record->{run_ordinal}),
    );
    confess "measurement staging identity changed\n"
        unless ($artifacts->{staging_identity} // '') eq $expected_staging;
    confess "measurement published identity is unsafe\n"
        unless !defined($artifacts->{published_identity})
            || _safe_relative_path($artifacts->{published_identity});
    confess "measurement artifact records must be an array\n"
        unless ref($artifacts->{records}) eq 'ARRAY';
    my (%seen, %by_stage);
    for my $index (0 .. $#{$artifacts->{records}}) {
        my $artifact = $artifacts->{records}[$index];
        confess "measurement artifact $index must be one closed hash\n"
            unless ref($artifact) eq 'HASH' && !blessed($artifact);
        _exact_keys(
            $artifact, \@RECORD_ARTIFACT_KEYS,
            "measurement artifact $index",
        );
        confess "measurement artifact $index stage is invalid\n"
            unless exists($STAGE_INDEX{$artifact->{stage}})
                && $artifact->{stage} ne 'cleanup';
        confess "measurement artifact $index path is unsafe or misowned\n"
            unless _safe_relative_path($artifact->{relative_path})
                && $artifact->{relative_path}
                    =~ m{\Aoutputs/\Q$artifact->{stage}\E/};
        confess "measurement artifact path is duplicated\n"
            if $seen{$artifact->{relative_path}}++;
        confess "measurement artifact $index kind is invalid\n"
            unless _safe_token($artifact->{kind});
        for my $key (qw(bytes lines)) {
            confess "measurement artifact $index $key is invalid\n"
                unless _nonnegative_integer($artifact->{$key});
        }
        confess "measurement artifact $index digest is invalid\n"
            unless ($artifact->{sha256} // '') =~ /\A[0-9a-f]{64}\z/;
        push @{$by_stage{$artifact->{stage}}}, $artifact;
    }
    for my $stage (@{$record->{stage_measurements}}) {
        my $owned = $by_stage{$stage->{stage}} // [];
        _validate_output_counts($stage->{output_counts}, $owned);
    }
}

sub _validate_cpu_counter($counter, $label) {
    confess "measurement $label must be one closed hash\n"
        unless ref($counter) eq 'HASH' && !blessed($counter);
    _exact_keys($counter, \@CPU_KEYS, "measurement $label");
    for my $key (qw(user_ns system_ns)) {
        confess "measurement $label $key is invalid\n"
            unless !defined($counter->{$key})
                || _nonnegative_integer($counter->{$key});
    }
    my $missing = !defined($counter->{user_ns})
        || !defined($counter->{system_ns});
    confess "measurement $label unsupported reason is invalid\n"
        unless $missing
            ? _safe_token($counter->{unsupported_reason})
            : (!defined($counter->{unsupported_reason})
                || _safe_token($counter->{unsupported_reason}));
}

sub _validate_rss_counter($counter) {
    confess "measurement RSS must be one closed hash\n"
        unless ref($counter) eq 'HASH' && !blessed($counter);
    _exact_keys($counter, \@RSS_KEYS, 'measurement RSS');
    for my $key (qw(
        peak_process_tree_bytes peak_single_descendant_bytes
    )) {
        confess "measurement RSS $key is invalid\n"
            unless !defined($counter->{$key})
                || _nonnegative_integer($counter->{$key});
    }
    my $missing = !defined($counter->{peak_process_tree_bytes})
        || !defined($counter->{peak_single_descendant_bytes});
    confess "measurement RSS unsupported reason is invalid\n"
        unless $missing
            ? _safe_token($counter->{unsupported_reason})
            : !defined($counter->{unsupported_reason});
}

sub _validate_diagnostic($diagnostic, $label) {
    confess "$label must be one closed hash\n"
        unless ref($diagnostic) eq 'HASH' && !blessed($diagnostic);
    _exact_keys($diagnostic, \@DIAGNOSTIC_KEYS, $label);
    confess "$label code is invalid\n"
        unless ($diagnostic->{code} // '')
            =~ /\A[A-Z][A-Z0-9_]*\z/;
    confess "$label severity is invalid\n"
        unless ($diagnostic->{severity} // '') eq 'error';
    confess "$label message is invalid\n"
        unless _nonempty_scalar($diagnostic->{message});
    confess "$label semantic path is invalid\n"
        unless defined($diagnostic->{semantic_path})
            && !ref($diagnostic->{semantic_path})
            && $diagnostic->{semantic_path}
                =~ m{\A/(?:[A-Za-z0-9_.-]+/?)*\z};
    for my $key (qw(source_locations related notes hints)) {
        confess "$label $key must be an array\n"
            unless ref($diagnostic->{$key}) eq 'ARRAY';
        _require_json_value($diagnostic->{$key}, "$label $key");
    }
    confess "$label contains a machine-local path\n"
        if _contains_machine_path($diagnostic);
}

sub _validate_unique_tokens($values, $label) {
    my %seen;
    for my $value (@$values) {
        confess "$label is invalid\n" unless _safe_token($value);
        confess "$label is duplicated\n" if $seen{$value}++;
    }
}

sub _validate_sorted_tokens($values, $label) {
    _validate_unique_tokens($values, $label);
    my @sorted = sort @$values;
    confess "$label list is not canonical\n"
        unless _canonical_json($values) eq _canonical_json(\@sorted);
}

sub _same_nullable_number($left, $right) {
    return 1 if !defined($left) && !defined($right);
    return 0 unless defined($left) && defined($right);
    return $left == $right;
}

sub _measurement_identity($record) {
    my $projection = _clone($record);
    $projection->{measurement_identity} = undef;
    return 'measurement/' . sha256_hex(_canonical_json($projection));
}

sub _acquire_stage_lock($repo_root, $root_device, $stage_rel) {
    confess "measurement lock staging identity is unsafe\n"
        unless _safe_relative_path($stage_rel)
            && $stage_rel =~ m{\A\Q$STAGING_BASE\E/};
    my $lock_rel = join(
        '/', $LOCK_BASE, sha256_hex($stage_rel) . '.lock',
    );
    my $lock_abs = File::Spec->catfile(
        $repo_root, split m{/}, $lock_rel,
    );
    _ensure_lock_parent(
        $repo_root, $root_device, dirname($lock_abs), dirname($lock_rel),
    );

    sysopen(my $lock, $lock_abs, O_RDWR | O_CREAT | O_NOFOLLOW, 0600)
        or confess "cannot open measurement stage lock\n";
    my @path_stat = lstat($lock_abs);
    my @handle_stat = stat($lock);
    if (!@path_stat || !@handle_stat
            || -l $lock_abs || !-f $lock
            || $path_stat[0] != $root_device
            || $handle_stat[0] != $root_device
            || $path_stat[0] != $handle_stat[0]
            || $path_stat[1] != $handle_stat[1]
            || $handle_stat[3] != 1
            || $handle_stat[4] != $>
            || $handle_stat[7] != 0) {
        close $lock;
        confess "measurement stage lock identity is invalid\n";
    }
    my $descriptor_flags = fcntl($lock, F_GETFD, 0);
    if (!defined($descriptor_flags)
            || !fcntl(
                $lock, F_SETFD, $descriptor_flags | FD_CLOEXEC,
            )) {
        close $lock;
        confess "cannot secure measurement stage lock descriptor\n";
    }
    if (!flock($lock, LOCK_EX | LOCK_NB)) {
        my $contended = $! == EAGAIN || $! == EWOULDBLOCK;
        close $lock;
        confess $contended
            ? "measurement staging identity is concurrently owned\n"
            : "cannot acquire measurement stage lock\n";
    }
    return $lock;
}

sub _ensure_lock_parent(
    $repo_root, $root_device, $parent_abs, $parent_rel,
) {
    confess "measurement lock parent identity is unsafe\n"
        unless _safe_relative_path($parent_rel)
            && $parent_rel =~ m{\A\Q$LOCK_BASE\E(?:/|\z)};
    my $path = $repo_root;
    for my $part (split m{/}, $parent_rel) {
        $path = File::Spec->catdir($path, $part);
        if (!-e $path && !-l $path) {
            mkdir($path) or do {
                confess "cannot create measurement lock directory\n"
                    unless $! == EEXIST;
            };
        }
        my @stat = lstat($path);
        confess "measurement lock directory is not a real directory\n"
            unless @stat && !-l _ && -d _;
        confess "measurement lock directory crossed repository volume\n"
            unless $stat[0] == $root_device;
    }
    confess "measurement lock parent mismatch\n" unless $path eq $parent_abs;
    return 1;
}

sub _recover_interrupted_stage($repo_root, $root_device, $stage_rel) {
    my $stage_abs = File::Spec->catdir(
        $repo_root, split m{/}, $stage_rel,
    );
    return 0 unless -e $stage_abs || -l $stage_abs;
    _validate_recoverable_stage($stage_abs, $root_device);
    my $errors;
    remove_tree($stage_abs, {error => \$errors});
    confess "cannot reclaim interrupted measurement staging root\n"
        if $errors && @$errors;
    confess "interrupted measurement staging root remains after recovery\n"
        if -e $stage_abs || -l $stage_abs;
    _prune_recovered_stage_parents($repo_root, dirname($stage_abs));
    return 1;
}

sub _validate_recoverable_stage($path, $root_device) {
    my @stat = lstat($path);
    confess "interrupted measurement staging root is not a real directory\n"
        unless @stat && !-l _ && -d _;
    confess "interrupted measurement staging crossed repository volume\n"
        unless $stat[0] == $root_device;
    opendir my $dh, $path
        or confess "cannot inventory interrupted measurement staging\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close interrupted measurement staging directory\n";
    for my $name (@entries) {
        my $entry = File::Spec->catfile($path, $name);
        my @entry_stat = lstat($entry);
        confess "interrupted measurement staging contains an unsafe entry\n"
            unless @entry_stat && !-l _ && (-d _ || -f _);
        confess "interrupted measurement staging crossed repository volume\n"
            unless $entry_stat[0] == $root_device;
        confess "interrupted measurement staging contains a hard-linked file\n"
            if -f _ && $entry_stat[3] != 1;
        _validate_recoverable_stage($entry, $root_device) if -d _;
    }
    return 1;
}

sub _prune_recovered_stage_parents($repo_root, $path) {
    my $stop = File::Spec->catdir($repo_root, '.artifacts', 'tmp');
    while ($path eq $stop
            || index($path, "$stop/") == 0) {
        last unless rmdir $path;
        last if $path eq $stop;
        $path = dirname($path);
    }
}

sub _create_owned_stage($repo_root, $root_device, $stage_rel) {
    my @parts = split m{/}, $stage_rel;
    my $path = $repo_root;
    my @created;
    my $ok = eval {
        for my $index (0 .. $#parts) {
            my $part = $parts[$index];
            $path = File::Spec->catdir($path, $part);
            if (-e $path || -l $path) {
                confess "measurement staging traverses a symlink\n" if -l $path;
                confess "measurement staging component is not a directory\n"
                    unless -d $path;
                confess "measurement staging root already exists\n"
                    if $index == $#parts;
            }
            else {
                mkdir($path)
                    or confess "cannot create measurement staging directory\n";
                push @created, $path;
            }
            my @stat = stat($path);
            confess "measurement staging filesystem identity is unavailable\n"
                unless @stat;
            confess "measurement staging crossed repository volume\n"
                unless $stat[0] == $root_device;
        }
        1;
    };
    if (!$ok) {
        my $error = $@;
        _remove_empty_created_directories(\@created, undef);
        die $error;
    }
    return ($path, \@created);
}

sub _remove_owned_stage($stage_abs, $stage_rel, $created) {
    if (-e $stage_abs || -l $stage_abs) {
        return "owned staging root '$stage_rel' is not a real directory"
            unless -d $stage_abs && !-l $stage_abs;
        my $errors;
        remove_tree($stage_abs, {error => \$errors});
        return "cannot remove owned staging root '$stage_rel'"
            if $errors && @$errors;
    }
    return "owned staging root '$stage_rel' remains after cleanup"
        if -e $stage_abs || -l $stage_abs;
    _remove_empty_created_directories($created, $stage_abs);
    return undef;
}

sub _cleanup_residue($stage_abs, $stage_rel) {
    return [] unless -e $stage_abs || -l $stage_abs;
    return [$stage_rel] unless -d $stage_abs && !-l $stage_abs;
    my @files = eval { _tree_files($stage_abs) };
    return [$stage_rel] if $@ || !@files;
    return [map { "$stage_rel/$_" } @files];
}

sub _remove_empty_created_directories($created, $skip) {
    for my $path (reverse @$created) {
        next if defined($skip) && $path eq $skip;
        next unless -d $path && !-l $path;
        rmdir $path;
    }
}

sub _safe_destination($repo_root, $root_device, $relative) {
    confess "measurement destination is unsafe\n"
        unless _safe_relative_path($relative);
    my $path = $repo_root;
    my $existing = $repo_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            confess "measurement destination traverses a symlink\n" if -l $path;
            $existing = $path;
        }
    }
    my @stat = stat($existing);
    confess "measurement destination filesystem identity is unavailable\n"
        unless @stat;
    confess "measurement destination crossed repository volume\n"
        unless $stat[0] == $root_device;
    return $path;
}

sub _ensure_publication_parent(
    $repo_root, $root_device, $parent, $relative, $created,
) {
    my $path = $repo_root;
    for my $part (split m{/}, $relative) {
        next if $part eq '.';
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            confess "measurement publication parent traverses a symlink\n"
                if -l $path;
            confess "measurement publication parent is not a directory\n"
                unless -d $path;
        }
        else {
            mkdir($path)
                or confess "cannot create measurement publication parent\n";
            push @$created, $path;
        }
        my @stat = stat($path);
        confess "measurement publication parent crossed repository volume\n"
            unless @stat && $stat[0] == $root_device;
    }
    confess "measurement publication parent mismatch\n"
        unless $path eq $parent;
    return 1;
}

sub _validated_repository_root($raw) {
    confess "repository_root must be one scalar directory path\n"
        unless defined($raw) && !ref($raw);
    require Cwd;
    my $repo_root = Cwd::abs_path($raw);
    confess "repository root is not a readable directory\n"
        unless defined($repo_root) && -d $repo_root;
    my $git = File::Spec->catfile($repo_root, '.git');
    confess "repository root has no regular Git identity\n"
        unless (-d $git || -f $git) && !-l $git;
    my @stat = stat($repo_root);
    confess "repository filesystem identity is unavailable\n" unless @stat;
    return ($repo_root, $stat[0]);
}

sub _tree_files($root) {
    my @files;
    _walk_tree($root, '', \@files);
    return sort @files;
}

sub _walk_tree($root, $relative, $files) {
    my $path = length($relative)
        ? File::Spec->catdir($root, split m{/}, $relative) : $root;
    opendir my $dh, $path or confess "cannot inventory measurement staging\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or confess "cannot close measurement staging directory\n";
    for my $name (@entries) {
        my $rel = length($relative) ? "$relative/$name" : $name;
        my $entry = File::Spec->catfile($path, $name);
        my @stat = lstat($entry);
        confess "measurement staging contains a symlink or special file\n"
            unless @stat && !-l _ && (-d _ || -f _);
        if (-d _) {
            _walk_tree($root, $rel, $files);
        }
        else {
            push @$files, $rel;
        }
    }
}

sub _drain_pipe($reader, $buffer_ref, $finish = 0) {
    while (1) {
        my $chunk = '';
        my $read = sysread($reader, $chunk, 65_536);
        if (defined $read) {
            last if $read == 0;
            my $remaining = $MAX_WORKER_RESULT_BYTES + 1
                - bytes::length($$buffer_ref);
            $$buffer_ref .= substr($chunk, 0, $remaining)
                if $remaining > 0;
            next;
        }
        last if $! == EAGAIN || $! == EWOULDBLOCK;
        last;
    }
    return unless $finish;
}

sub _terminate_process_group($pid) {
    kill 'TERM', -$pid;
    kill 'TERM', $pid;
    sleep(0.1);
    if (kill(0, $pid)) {
        kill 'KILL', -$pid;
        kill 'KILL', $pid;
    }
}

sub _capture_command(@command) {
    open my $fh, '-|', @command or return (0, '');
    local $/;
    my $output = <$fh> // '';
    my $ok = close $fh;
    return ($ok ? 1 : 0, $output);
}

sub _command_scalar(@command) {
    my ($ok, $output) = _capture_command(@command);
    return undef unless $ok;
    $output =~ s/^\s+|\s+$//g;
    return length($output) ? $output : undef;
}

sub _command_uint(@command) {
    my $value = _command_scalar(@command);
    return undef unless defined($value) && $value =~ /\A[1-9][0-9]*\z/;
    return 0 + $value;
}

sub _darwin_filesystem_type($repo_root) {
    my ($ok, $output) = _capture_command('mount');
    return undef unless $ok;
    my ($best, $type) = ('', undef);
    for my $line (split /\n/, $output) {
        next unless $line =~ / on (.+) \(([^,()]+)(?:,|\))/;
        my ($mountpoint, $candidate) = ($1, $2);
        next unless $mountpoint eq '/'
            || $repo_root eq $mountpoint
            || index($repo_root, "$mountpoint/") == 0;
        if (length($mountpoint) > length($best)) {
            ($best, $type) = ($mountpoint, $candidate);
        }
    }
    return $type;
}

sub _linux_cpu_model() {
    open my $fh, '<', '/proc/cpuinfo' or return undef;
    while (my $line = <$fh>) {
        if ($line =~ /^(?:model name|Hardware)\s*:\s*(.+?)\s*$/) {
            close $fh;
            return $1;
        }
    }
    close $fh;
    return undef;
}

sub _linux_logical_cores() {
    my $value = eval {
        require POSIX;
        POSIX::sysconf(POSIX::_SC_NPROCESSORS_ONLN());
    };
    return defined($value) && $value > 0 ? 0 + $value : undef;
}

sub _linux_physical_memory() {
    open my $fh, '<', '/proc/meminfo' or return undef;
    while (my $line = <$fh>) {
        if ($line =~ /^MemTotal:\s+(\d+)\s+kB\s*$/) {
            close $fh;
            return 0 + $1 * 1024;
        }
    }
    close $fh;
    return undef;
}

sub _linux_filesystem_type($repo_root) {
    open my $fh, '<', '/proc/self/mountinfo' or return undef;
    my ($best, $type) = ('', undef);
    while (my $line = <$fh>) {
        my ($before, $after) = split / - /, $line, 2;
        next unless defined $after;
        my @left = split / /, $before;
        my @right = split / /, $after;
        next unless @left >= 5 && @right >= 1;
        my $mountpoint = $left[4];
        $mountpoint =~ s/\\040/ /g;
        next unless $mountpoint eq '/'
            || $repo_root eq $mountpoint
            || index($repo_root, "$mountpoint/") == 0;
        if (length($mountpoint) > length($best)) {
            ($best, $type) = ($mountpoint, $right[0]);
        }
    }
    close $fh;
    return $type;
}

sub _ps_time_ns($value) {
    return undef unless defined($value) && !ref($value);
    my @parts = split /:/, $value;
    return undef unless @parts == 2 || @parts == 3;
    my $seconds = pop @parts;
    return undef unless $seconds =~ /\A[0-9]+(?:[.][0-9]+)?\z/;
    my $minutes = pop @parts;
    return undef unless $minutes =~ /\A[0-9]+\z/;
    my $hours = @parts ? pop @parts : 0;
    return undef unless $hours =~ /\A[0-9]+\z/;
    return _seconds_to_ns($hours * 3600 + $minutes * 60 + $seconds);
}

sub _seconds_to_ns($seconds) {
    return int($seconds * 1_000_000_000 + 0.5);
}

sub _maximum(@values) {
    my $maximum = shift @values;
    for my $value (@values) {
        $maximum = $value if $value > $maximum;
    }
    return $maximum;
}

sub _zero_counts() {
    return {files => 0, lines => 0, bytes => 0, objects => 0};
}

sub _diagnostic($code, $message, $path) {
    return {
        code => $code,
        severity => 'error',
        message => $message,
        source_locations => [],
        semantic_path => $path,
        related => [],
        notes => [],
        hints => [],
    };
}

sub _publication_failure($measurement, $publication, $artifact, $code, $message, $path) {
    return _publication_result({
        ok => JSON::PP::false,
        status => 'error',
        schema => $PUBLICATION_SCHEMA,
        schema_version => 1,
        measurement_identity => $measurement,
        publication_identity => $publication,
        artifact_relative_path => $artifact,
        same_volume => JSON::PP::true,
        atomic => JSON::PP::false,
        diagnostics => [_diagnostic($code, $message, $path)],
    });
}

sub _publication_result($result) {
    _exact_keys($result, \@PUBLICATION_KEYS, 'measurement publication result');
    confess "measurement publication result schema is invalid\n"
        unless ($result->{schema} // '') eq $PUBLICATION_SCHEMA
            && ($result->{schema_version} // 0) == 1;
    my $ok = _json_boolean($result->{ok}, 'measurement publication ok');
    _json_boolean(
        $result->{same_volume}, 'measurement publication same_volume',
    );
    _json_boolean($result->{atomic}, 'measurement publication atomic');
    confess "measurement publication status is invalid\n"
        unless ($result->{status} // '')
            =~ /\A(?:published|unchanged|error)\z/;
    confess "measurement publication status and outcome disagree\n"
        unless $ok
            ? $result->{status} ne 'error'
            : $result->{status} eq 'error';
    confess "measurement publication identity is invalid\n"
        unless ($result->{measurement_identity} // '')
            =~ m{\Ameasurement/[0-9a-f]{64}\z};
    for my $key (qw(publication_identity artifact_relative_path)) {
        confess "measurement publication $key is unsafe\n"
            unless _safe_relative_path($result->{$key});
    }
    confess "measurement publication diagnostics must be an array\n"
        unless ref($result->{diagnostics}) eq 'ARRAY';
    if ($ok) {
        confess "successful publication retained diagnostics\n"
            if @{$result->{diagnostics}};
    }
    else {
        confess "failed publication omitted diagnostics\n"
            unless @{$result->{diagnostics}};
        _validate_diagnostic($_, 'measurement publication diagnostic')
            for @{$result->{diagnostics}};
    }
    return _clone($result);
}

sub _json_boolean($value, $label) {
    confess "$label must be a JSON boolean\n"
        unless blessed($value) && $value->isa('JSON::PP::Boolean');
    return $value ? JSON::PP::true : JSON::PP::false;
}

sub _require_json_value($value, $label) {
    my $ok = eval { _canonical_json($value); 1 };
    confess "$label must be JSON-safe\n" unless $ok;
}

sub _contains_machine_path($value) {
    return defined _machine_path_location($value, '');
}

sub _machine_path_location($value, $path) {
    if (!ref($value)) {
        return undef unless defined $value;
        return $path
            if $value =~ m{(?:\A/|\A~(?:/|\z)|\A[A-Za-z]:[\\/]|://|\\)};
        return undef;
    }
    return undef if blessed($value) && $value->isa('JSON::PP::Boolean');
    if (ref($value) eq 'ARRAY') {
        for my $index (0 .. $#$value) {
            my $found = _machine_path_location(
                $value->[$index], "$path/$index",
            );
            return $found if defined $found;
        }
        return undef;
    }
    if (ref($value) eq 'HASH') {
        for my $key (sort keys %$value) {
            next if $key eq 'semantic_path'
                && defined($value->{$key}) && !ref($value->{$key})
                && $value->{$key} =~ m{\A/(?:[A-Za-z0-9_.-]+/?)*\z};
            my $found = _machine_path_location(
                $value->{$key}, "$path/$key",
            );
            return $found if defined $found;
        }
        return undef;
    }
    return $path;
}

sub _safe_relative_path($value) {
    return 0 unless defined($value) && !ref($value) && length($value);
    return 0 if $value =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    return 0 if grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
        split(m{/}, $value, -1);
    return 1;
}

sub _safe_token($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A[a-z][a-z0-9_.-]*\z/;
}

sub _nonnegative_integer($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
}

sub _nonnegative_number($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A(?:0|[1-9][0-9]*)(?:[.][0-9]+)?\z/;
}

sub _nonempty_scalar($value) {
    return defined($value) && !ref($value) && length($value)
        && $value !~ /[\x00\r\n]/;
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _sanitize_exception($exception) {
    my $text = "$exception";
    $text =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $text =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+}{<path>}g;
    $text =~ s/[\r\n]+/ /g;
    $text =~ s/^\s+|\s+$//g;
    return length($text) ? $text : 'measurement operation failed';
}

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->utf8(1)->allow_nonref(1)->encode($value);
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess "measurement value contains an unsupported reference\n" if ref($value);
    return $value;
}

1;
