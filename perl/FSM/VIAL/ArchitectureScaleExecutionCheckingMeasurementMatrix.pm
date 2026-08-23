package FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use Errno qw(EAGAIN EINTR EWOULDBLOCK);
use Fcntl qw(
    FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL O_CREAT O_EXCL O_NONBLOCK
    O_WRONLY
);
use File::Basename qw(dirname);
use File::Path qw(remove_tree);
use File::Spec;
use IO::Handle ();
use JSON::PP ();
use POSIX qw(WEXITSTATUS WIFEXITED WIFSIGNALED WNOHANG WTERMSIG _exit);
use Scalar::Util qw(blessed);
use Time::HiRes qw(sleep);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleCheckingState;
use FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement;
use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ArchitectureScaleWorkload;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_execution_checking_matrix.v1';
my $COMPLETE_SCHEMA =
    'fsmgen.vial_architecture_scale_execution_checking_complete_matrix.v1';
my $PROFILE_PUBLICATION_SCHEMA =
    'fsmgen.vial_architecture_scale_execution_checking_profile_publication.v1';
my $PUBLICATION_BASE = '.artifacts/qualification/vial-scale/v1';
my $STAGING_BASE = '.artifacts/tmp/vial-scale/matrix-publication';
my $REPORT_FILENAME = 'measurement-publication.json';
my $MATRIX_FILENAME = 'matrix.json';
my $COMPLETE_FILENAME = 'complete-matrix.json';
my $PROFILE_WORKER_SCHEMA =
    'fsmgen.vial_architecture_scale_profile_worker.v1';
my $MAX_PROFILE_WORKER_RESULT_BYTES = 1_048_576;
my $MAX_PROFILE_WORKER_ERROR_BYTES = 4_096;
my $ADAPTER =
    'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement';

my @FAMILIES = qw(execution_graph_v1 checking_state_v1);
my %FAMILY_INDEX = map { $FAMILIES[$_] => $_ } 0 .. $#FAMILIES;
my %PRODUCER = (
    execution_graph_v1 => 'FSM::VIAL::ArchitectureScaleExecutionGraph',
    checking_state_v1 => 'FSM::VIAL::ArchitectureScaleCheckingState',
);
my %AXES = (
    execution_graph_v1 => [qw(
        bindings execution_types fibers_total operations_per_scenario
        operations_total random_attempts scenarios serialized_plan_bytes
        simultaneously_live_fibers source_map_records
    )],
    checking_state_v1 => [qw(
        bins_and_cross_tuples coverpoints faults model_instances
        random_occurrences scalar_model_state_cells scoreboard_capacity
        scoreboard_instances
    )],
);
my @LEVELS = qw(
    gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
);
my %REPORT_MODE_BY_LEVEL = (
    gate_candidate_v1 => 'gate_measurement',
    qualification_candidate_v1 => 'qualification_measurement',
    limit_v1 => 'validation',
    over_limit_v1 => 'validation',
);
my %EXPECTED_SAMPLES_BY_MODE = (
    gate_measurement => 3,
    qualification_measurement => 5,
);
my @AUTHORITY_STATUSES = qw(
    accepted expected_rejection preflight_dominated envelope_unconstructible
);
my %AUTHORITY_STATUS = map { $_ => 1 } @AUTHORITY_STATUSES;
my @INVENTORY_KEYS = qw(profile_id family primary_axis level mode);
my @PROFILE_PUBLICATION_KEYS = qw(
    schema schema_version publication_identity capture_identity report
);
my @MATRIX_KEYS = qw(
    schema schema_version matrix_identity family profile_count
    common_identity profiles dominance outcome diagnostics explicit_nonclaims
);
my @PROFILE_KEYS = qw(
    profile_id family primary_axis level mode authority_status
    report_identity workload_identity validation_identity
    controller_applicable controller_reason measurement_applicable
    measurement_reason measured_samples excluded_samples outcome diagnostics
    artifact_relative_path artifact_sha256 artifact_bytes
);
my @PROFILE_WORKER_ENVELOPE_KEYS = qw(
    schema schema_version ok payload error
);
my @PROFILE_WORKER_PAYLOAD_KEYS = qw(
    operation profile_id publication_status common_identity entry
);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @DOMINANCE_KEYS = qw(
    accepted_profiles expected_rejection_profiles preflight_dominated_profiles
    source_free_profiles controller_applicable_profiles
    controller_inapplicable_profiles applicable_measurement_profiles
    inapplicable_measurement_profiles raw_measurement_records
    excluded_measurement_records diagnostic_counts
);
my @DIAGNOSTIC_COUNT_KEYS = qw(code semantic_path profiles);
my @COMPLETE_KEYS = qw(
    schema schema_version matrix_identity family_manifests
    total_profile_count common_identity dominance outcome diagnostics
    explicit_nonclaims
);
my @FAMILY_MANIFEST_KEYS = qw(
    family matrix_identity profile_count artifact_relative_path
    artifact_sha256 artifact_bytes
);
my @NONCLAIMS = (
    @{$ADAPTER->explicit_nonclaims},
    qw(
        partial_matrix_completion mixed_revision_matrix mixed_host_matrix
        mixed_tool_matrix mixed_guard_matrix discarded_raw_sample
        mutable_measurement_publication source_free_controller_measurement
    ),
);

sub inventory($class) {
    _exact_invocant($class, 'inventory');
    return _clone(_inventory());
}

sub profile_keys($class) {
    _exact_invocant($class, 'profile_keys');
    return [@INVENTORY_KEYS];
}

sub matrix_keys($class) {
    _exact_invocant($class, 'matrix_keys');
    return [@MATRIX_KEYS];
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub capture_family($class, @args) {
    _exact_invocant($class, 'capture_family');
    my $raw = _request(
        'capture_family', \@args, [qw(repository_root family)],
    );
    _selected_family($raw->{family});
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    my $git_revision = _require_clean_revision($repo_root);
    return _clone(_capture_family(
        $repo_root, $root_device, $raw->{family}, $git_revision,
    ));
}

sub capture_all($class, @args) {
    _exact_invocant($class, 'capture_all');
    my $raw = _request('capture_all', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    my $git_revision = _require_clean_revision($repo_root);
    my @manifests = map {
        _capture_family($repo_root, $root_device, $_, $git_revision)
    } @FAMILIES;
    _require_unchanged_clean_revision($repo_root, $git_revision);
    my $complete = _complete_manifest(\@manifests);
    my $publication = _publish_json({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => 'execution-checking-complete-matrix-v1',
        filename => $COMPLETE_FILENAME,
        value => $complete,
    });
    print STDERR
        "vial-scale-execution-checking-matrix: complete matrix $publication->{status}\n";
    return _validate_complete_publication($repo_root, $root_device);
}

sub validate_family_publication($class, @args) {
    _exact_invocant($class, 'validate_family_publication');
    my $raw = _request(
        'validate_family_publication', \@args,
        [qw(repository_root family)],
    );
    _selected_family($raw->{family});
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    return _clone(_validate_family_publication(
        $repo_root, $root_device, $raw->{family},
    ));
}

sub validate_complete_publication($class, @args) {
    _exact_invocant($class, 'validate_complete_publication');
    my $raw = _request(
        'validate_complete_publication', \@args, [qw(repository_root)],
    );
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    return _clone(_validate_complete_publication($repo_root, $root_device));
}

sub _capture_family($repo_root, $root_device, $family, $git_revision) {
    my $matrix_profile_id = _matrix_profile_id($family);
    if (_publication_exists($repo_root, $matrix_profile_id)) {
        my $existing = _validate_family_publication(
            $repo_root, $root_device, $family,
        );
        _require_manifest_revision($existing, $git_revision);
        print STDERR
            "vial-scale-execution-checking-matrix: $family matrix resumed\n";
        return $existing;
    }

    my @profiles = grep { $_->{family} eq $family } @{_inventory()};
    my (@captured, $common_identity);
    for my $index (0 .. $#profiles) {
        my $profile = $profiles[$index];
        my $result = _run_profile_process({
            repository_root => $repo_root,
            root_device => $root_device,
            profile => $profile,
            operation => 'capture_or_resume',
            git_revision => $git_revision,
            expected_common_identity => $common_identity,
        });
        my $loaded_common = $result->{common_identity};
        _require_common_match($common_identity, $loaded_common)
            if defined $common_identity;
        $common_identity //= _clone($loaded_common);
        my $entry = _clone($result->{entry});
        $entry->{_common_identity} = _clone($loaded_common);
        push @captured, $entry;
        my $ordinal = $index + 1;
        print STDERR join(' ',
            'vial-scale-execution-checking-matrix:', $family,
            "$ordinal/" . scalar(@profiles),
            "$profile->{primary_axis}/$profile->{level}",
            $result->{publication_status},
        ), "\n";
    }

    confess "execution/checking family matrix has no common identity\n"
        unless defined $common_identity;
    _require_unchanged_clean_revision($repo_root, $git_revision);
    my $manifest = _family_manifest($family, \@captured);
    my $publication = _publish_json({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => $matrix_profile_id,
        filename => $MATRIX_FILENAME,
        value => $manifest,
    });
    print STDERR
        "vial-scale-execution-checking-matrix: $family matrix $publication->{status}\n";
    return _validate_family_publication($repo_root, $root_device, $family);
}

sub _validate_family_publication($repo_root, $root_device, $family) {
    my @profiles = grep { $_->{family} eq $family } @{_inventory()};
    my (@entries, $common_identity);
    for my $profile (@profiles) {
        my $result = _run_profile_process({
            repository_root => $repo_root,
            root_device => $root_device,
            profile => $profile,
            operation => 'validate_publication',
            git_revision => undef,
            expected_common_identity => $common_identity,
        });
        my $loaded_common = $result->{common_identity};
        _require_common_match($common_identity, $loaded_common)
            if defined $common_identity;
        $common_identity //= _clone($loaded_common);
        my $entry = _clone($result->{entry});
        $entry->{_common_identity} = _clone($loaded_common);
        push @entries, $entry;
    }
    my $expected = _family_manifest($family, \@entries);
    my ($actual) = _read_json_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => _matrix_profile_id($family),
        filename => $MATRIX_FILENAME,
    });
    _validate_family_manifest_shape($actual);
    confess "execution/checking family matrix publication is not canonical\n"
        unless _canonical_json($actual) eq _canonical_json($expected);
    return $actual;
}

sub _validate_complete_publication($repo_root, $root_device) {
    my @manifests = map {
        _validate_family_publication($repo_root, $root_device, $_)
    } @FAMILIES;
    my $expected = _complete_manifest(\@manifests);
    my ($actual) = _read_json_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => 'execution-checking-complete-matrix-v1',
        filename => $COMPLETE_FILENAME,
    });
    _validate_complete_manifest_shape($actual);
    confess "execution/checking complete matrix publication is not canonical\n"
        unless _canonical_json($actual) eq _canonical_json($expected);
    return $actual;
}

sub _inventory() {
    _assert_owned_partition();
    my @profiles;
    for my $family (@FAMILIES) {
        for my $axis (@{$AXES{$family}}) {
            for my $level (@LEVELS) {
                push @profiles, {
                    profile_id => _profile_id($family, $axis, $level),
                    family => $family,
                    primary_axis => $axis,
                    level => $level,
                    mode => $REPORT_MODE_BY_LEVEL{$level},
                };
            }
        }
    }
    return \@profiles;
}

sub _assert_owned_partition() {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog->{families};
    for my $family (@FAMILIES) {
        confess "execution/checking matrix family catalog is absent\n"
            unless ref($catalog->{$family}{axes}) eq 'HASH';
        my @expected = map {
            my $axis = $_;
            map { "$axis/$_" } @LEVELS
        } @{$AXES{$family}};
        my @actual = map {
            "$_->{primary_axis}/$_->{level}"
        } @{$PRODUCER{$family}->owned_shapes};
        confess "execution/checking matrix owned-shape partition changed\n"
            unless _canonical_json(\@actual) eq _canonical_json(\@expected);
        for my $axis (@{$AXES{$family}}) {
            confess "execution/checking matrix owned axis left the catalog\n"
                unless ref($catalog->{$family}{axes}{$axis}{levels}) eq 'HASH';
            for my $level (@LEVELS) {
                confess "execution/checking matrix owned level left the catalog\n"
                    unless exists $catalog->{$family}{axes}{$axis}{levels}{$level};
            }
        }
    }
}

sub _run_profile_process($raw) {
    _exact_keys(
        $raw,
        [qw(repository_root root_device profile operation git_revision
            expected_common_identity)],
        'isolated profile process invocation',
    );
    my $profile = $raw->{profile};
    _exact_keys(
        $profile, \@INVENTORY_KEYS, 'isolated profile process profile',
    );
    confess "isolated profile process operation is invalid\n"
        unless ($raw->{operation} // '') eq 'capture_or_resume'
            || ($raw->{operation} // '') eq 'validate_publication';
    confess "isolated profile process repository identity is invalid\n"
        unless defined($raw->{repository_root})
            && !ref($raw->{repository_root})
            && -d $raw->{repository_root}
            && _nonnegative_integer($raw->{root_device});
    if (defined $raw->{git_revision}) {
        confess "isolated profile process Git revision is invalid\n"
            unless $raw->{operation} eq 'capture_or_resume'
                && !ref($raw->{git_revision})
                && $raw->{git_revision} =~ /\A[0-9a-f]{40}\z/;
    }
    elsif ($raw->{operation} eq 'capture_or_resume') {
        confess "isolated profile capture omitted its Git revision\n";
    }
    _validate_common_identity($raw->{expected_common_identity})
        if defined $raw->{expected_common_identity};
    my $payload = _run_isolated_profile_worker({
        profile_id => $profile->{profile_id},
        worker => sub { _profile_worker_payload($raw) },
        validate_payload => sub($candidate) {
            _validate_profile_worker_payload($candidate, $raw);
        },
    });
    return $payload;
}

sub _profile_worker_payload($raw) {
    my $repo_root = $raw->{repository_root};
    my $root_device = $raw->{root_device};
    my $profile = $raw->{profile};
    my $operation = $raw->{operation};
    my $git_revision = $raw->{git_revision};
    my $common_identity = defined($raw->{expected_common_identity})
        ? _clone($raw->{expected_common_identity}) : undef;
    my ($publication_set, $publication);

    if (_publication_exists($repo_root, $profile->{profile_id})) {
        ($publication_set, $publication) = _load_report_publication(
            $repo_root, $root_device, $profile,
        );
        $publication->{status} = $operation eq 'capture_or_resume'
            ? 'resumed' : 'loaded';
    }
    else {
        confess "execution/checking profile publication is absent\n"
            unless $operation eq 'capture_or_resume';
        my $report = $profile->{mode} eq 'validation'
            ? $ADAPTER->validate_profile({
                repository_root => $repo_root,
                family => $profile->{family},
                level => $profile->{level},
                primary_axis => $profile->{primary_axis},
            })
            : $ADAPTER->measure_profile({
                repository_root => $repo_root,
                family => $profile->{family},
                level => $profile->{level},
                primary_axis => $profile->{primary_axis},
            });
        $ADAPTER->validate_report({
            repository_root => $repo_root,
            report => $report,
        });
        _require_acceptable_profile_report($profile, $report);
        my $report_common = _report_common_identity($report);
        if (defined $report_common) {
            _require_common_match($common_identity, $report_common)
                if defined $common_identity;
            $common_identity //= _clone($report_common);
        }
        confess "source-free matrix profile cannot establish capture identity\n"
            unless defined $common_identity;
        _require_capture_revision($common_identity, $git_revision);
        $publication_set = _profile_publication(
            $common_identity, $report,
        );
        $publication = _publish_json({
            repository_root => $repo_root,
            root_device => $root_device,
            profile_id => $profile->{profile_id},
            filename => $REPORT_FILENAME,
            value => $publication_set,
        });
        my $publication_status = $publication->{status};
        ($publication_set, $publication) = _load_report_publication(
            $repo_root, $root_device, $profile,
        );
        $publication->{status} = $publication_status;
    }

    my $loaded_common = $publication_set->{capture_identity};
    _require_common_match($common_identity, $loaded_common)
        if defined $common_identity;
    _require_capture_revision($loaded_common, $git_revision)
        if defined $git_revision;
    my $entry = _profile_entry(
        $profile, $publication_set->{report}, $publication, $loaded_common,
    );
    delete $entry->{_common_identity};
    return {
        operation => $operation,
        profile_id => $profile->{profile_id},
        publication_status => $publication->{status},
        common_identity => _clone($loaded_common),
        entry => $entry,
    };
}

sub _run_isolated_profile_worker($raw) {
    _exact_keys(
        $raw, [qw(profile_id worker validate_payload)],
        'isolated profile worker invocation',
    );
    confess "isolated profile worker profile ID is invalid\n"
        unless _safe_token($raw->{profile_id});
    confess "isolated profile worker callback is invalid\n"
        unless ref($raw->{worker}) eq 'CODE'
            && ref($raw->{validate_payload}) eq 'CODE';

    pipe(my $reader, my $writer)
        or confess "cannot create isolated profile worker pipe\n";
    my $descriptor_ok = eval {
        _set_close_on_exec($reader, 'reader');
        _set_close_on_exec($writer, 'writer');
        my $flags = fcntl($reader, F_GETFL, 0);
        confess "cannot inspect isolated profile worker reader flags\n"
            unless defined $flags;
        confess "cannot make isolated profile worker reader nonblocking\n"
            unless fcntl($reader, F_SETFL, $flags | O_NONBLOCK);
        1;
    };
    if (!$descriptor_ok) {
        my $error = $@;
        close $reader;
        close $writer;
        die $error;
    }

    my $pid = fork();
    if (!defined $pid) {
        close $reader;
        close $writer;
        confess "cannot fork isolated profile worker\n";
    }
    if ($pid == 0) {
        close $reader;
        my ($payload, $worker_error);
        {
            local $@;
            my $ok = eval {
                $payload = $raw->{worker}->();
                1;
            };
            $worker_error = $@ unless $ok;
        }
        my $envelope = defined($worker_error)
            ? _profile_worker_failure_envelope($worker_error)
            : {
                schema => $PROFILE_WORKER_SCHEMA,
                schema_version => 1,
                ok => JSON::PP::true,
                payload => $payload,
                error => undef,
            };
        my $encoded = eval { _canonical_json($envelope) };
        my $exit_code = defined($worker_error) ? 70 : 0;
        if (!defined($encoded)
                || bytes::length($encoded)
                    > $MAX_PROFILE_WORKER_RESULT_BYTES) {
            $envelope = _profile_worker_failure_envelope(
                'isolated profile worker result exceeded the bounded envelope',
            );
            $encoded = _canonical_json($envelope);
            $exit_code = 75;
        }
        my $written = _write_profile_worker_result($writer, $encoded);
        close $writer;
        _exit($written ? $exit_code : 74);
    }

    close $writer;
    my ($buffer, $read_error, $wait_status, $done) = ('', undef, undef, 0);
    while (!$done) {
        $read_error //= _drain_profile_worker_pipe($reader, \$buffer);
        if (defined $read_error) {
            kill 'TERM', $pid;
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
            $read_error = 'cannot wait for isolated profile worker';
            $done = 1;
        }
        else {
            sleep(0.01);
        }
    }
    $read_error //= _drain_profile_worker_pipe($reader, \$buffer);
    close $reader
        or $read_error //= 'cannot close isolated profile worker reader';
    confess "$read_error\n" if defined $read_error;

    my $signal = defined($wait_status) && WIFSIGNALED($wait_status)
        ? WTERMSIG($wait_status) : 0;
    confess "isolated profile worker '$raw->{profile_id}' terminated by signal $signal\n"
        if $signal;
    my ($envelope, $decode_error) =
        _decode_profile_worker_envelope($buffer);
    my $exit_code = defined($wait_status) && WIFEXITED($wait_status)
        ? WEXITSTATUS($wait_status) : undef;
    if (defined $decode_error) {
        my $status = defined($exit_code)
            ? " with exit status $exit_code" : '';
        confess "isolated profile worker '$raw->{profile_id}' $decode_error$status\n";
    }
    if (!$envelope->{ok}) {
        confess "isolated profile worker '$raw->{profile_id}' failed: "
            . "$envelope->{error}\n";
    }
    confess "isolated profile worker '$raw->{profile_id}' exited with status "
        . "$exit_code\n"
        unless defined($exit_code) && $exit_code == 0;
    my $payload_ok = eval {
        $raw->{validate_payload}->($envelope->{payload});
        1;
    };
    confess "isolated profile worker '$raw->{profile_id}' payload is invalid: $@"
        unless $payload_ok;
    return _clone($envelope->{payload});
}

sub _validate_profile_worker_payload($payload, $raw) {
    _exact_keys(
        $payload, \@PROFILE_WORKER_PAYLOAD_KEYS,
        'isolated profile worker payload',
    );
    confess "isolated profile worker operation changed\n"
        unless ($payload->{operation} // '') eq $raw->{operation};
    confess "isolated profile worker profile changed\n"
        unless ($payload->{profile_id} // '')
            eq $raw->{profile}{profile_id};
    my %allowed_status = $raw->{operation} eq 'capture_or_resume'
        ? map { $_ => 1 } qw(published recovered unchanged resumed)
        : (loaded => 1);
    confess "isolated profile worker publication status is invalid\n"
        unless $allowed_status{$payload->{publication_status} // ''};
    _validate_common_identity($payload->{common_identity});
    _require_common_match(
        $raw->{expected_common_identity}, $payload->{common_identity},
    ) if defined $raw->{expected_common_identity};
    _require_capture_revision(
        $payload->{common_identity}, $raw->{git_revision},
    ) if defined $raw->{git_revision};
    _validate_profile_entry($payload->{entry}, $raw->{profile});
}

sub _validate_profile_entry($entry, $profile) {
    _exact_keys(
        $entry, \@PROFILE_KEYS, 'isolated profile worker profile entry',
    );
    for my $key (qw(profile_id family primary_axis level mode)) {
        confess "isolated profile worker entry $key changed\n"
            unless ($entry->{$key} // '') eq ($profile->{$key} // '');
    }
    confess "isolated profile worker authority status is invalid\n"
        unless $AUTHORITY_STATUS{$entry->{authority_status} // ''};
    confess "isolated profile worker sample counts are invalid\n"
        unless _nonnegative_integer($entry->{measured_samples})
            && _nonnegative_integer($entry->{excluded_samples});
    confess "isolated profile worker retained excluded samples\n"
        if $entry->{excluded_samples};
    my $expected_path = join('/',
        $PUBLICATION_BASE, $profile->{profile_id}, $REPORT_FILENAME,
    );
    confess "isolated profile worker artifact path changed\n"
        unless ($entry->{artifact_relative_path} // '') eq $expected_path;
    confess "isolated profile worker artifact digest is invalid\n"
        unless ($entry->{artifact_sha256} // '') =~ /\A[0-9a-f]{64}\z/;
    confess "isolated profile worker artifact size is invalid\n"
        unless _nonnegative_integer($entry->{artifact_bytes})
            && $entry->{artifact_bytes} > 0;
    confess "isolated profile worker diagnostics are invalid\n"
        unless ref($entry->{diagnostics}) eq 'ARRAY';
}

sub _profile_worker_failure_envelope($error) {
    return {
        schema => $PROFILE_WORKER_SCHEMA,
        schema_version => 1,
        ok => JSON::PP::false,
        payload => undef,
        error => _bounded_profile_worker_error($error),
    };
}

sub _bounded_profile_worker_error($error) {
    $error = 'isolated profile worker failed without an exception'
        unless defined($error) && !ref($error) && length($error);
    $error =~ s/[^\x20-\x7e]+/ /g;
    $error =~ s/\s+/ /g;
    $error =~ s/\A\s+|\s+\z//g;
    return substr($error, 0, $MAX_PROFILE_WORKER_ERROR_BYTES);
}

sub _decode_profile_worker_envelope($buffer) {
    return (undef, 'returned no result') unless length $buffer;
    return (undef, 'result exceeded the bounded envelope')
        if bytes::length($buffer) > $MAX_PROFILE_WORKER_RESULT_BYTES;
    my $decoded = eval { JSON::PP->new->utf8(1)->decode($buffer) };
    return (undef, 'result is not valid JSON') unless defined $decoded;
    return (undef, 'result is not canonical JSON')
        unless _canonical_json($decoded) eq $buffer;
    my $valid = eval {
        _exact_keys(
            $decoded, \@PROFILE_WORKER_ENVELOPE_KEYS,
            'isolated profile worker envelope',
        );
        confess "isolated profile worker envelope schema is invalid\n"
            unless ($decoded->{schema} // '') eq $PROFILE_WORKER_SCHEMA
                && ($decoded->{schema_version} // 0) == 1;
        _json_boolean($decoded->{ok}, 'isolated profile worker envelope ok');
        if ($decoded->{ok}) {
            confess "successful isolated profile worker retained an error\n"
                if defined $decoded->{error};
        }
        else {
            confess "failed isolated profile worker retained a payload\n"
                if defined $decoded->{payload};
            confess "failed isolated profile worker error is invalid\n"
                unless defined($decoded->{error})
                    && !ref($decoded->{error})
                    && length($decoded->{error})
                    && bytes::length($decoded->{error})
                        <= $MAX_PROFILE_WORKER_ERROR_BYTES;
        }
        1;
    };
    return (undef, _bounded_profile_worker_error($@)) unless $valid;
    return ($decoded, undef);
}

sub _set_close_on_exec($handle, $label) {
    my $flags = fcntl($handle, F_GETFD, 0);
    confess "cannot inspect isolated profile worker $label descriptor\n"
        unless defined $flags;
    confess "cannot protect isolated profile worker $label descriptor\n"
        unless fcntl($handle, F_SETFD, $flags | FD_CLOEXEC);
}

sub _write_profile_worker_result($writer, $encoded) {
    my $offset = 0;
    while ($offset < bytes::length($encoded)) {
        my $written = syswrite(
            $writer, $encoded, bytes::length($encoded) - $offset, $offset,
        );
        if (!defined $written) {
            next if $! == EINTR;
            return 0;
        }
        return 0 if $written == 0;
        $offset += $written;
    }
    return 1;
}

sub _drain_profile_worker_pipe($reader, $buffer_ref) {
    while (1) {
        my $chunk = '';
        my $read = sysread($reader, $chunk, 65_536);
        if (defined $read) {
            return undef if $read == 0;
            my $remaining = $MAX_PROFILE_WORKER_RESULT_BYTES + 1
                - bytes::length($$buffer_ref);
            $$buffer_ref .= substr($chunk, 0, $remaining)
                if $remaining > 0;
            next;
        }
        next if $! == EINTR;
        return undef if $! == EAGAIN || $! == EWOULDBLOCK;
        return 'cannot read isolated profile worker result';
    }
}

sub _json_boolean($value, $label) {
    confess "$label must be a JSON boolean\n"
        unless blessed($value) && $value->isa('JSON::PP::Boolean');
    return $value ? JSON::PP::true : JSON::PP::false;
}

sub _profile_publication($common, $report) {
    _validate_common_identity($common);
    my $report_common = _report_common_identity($report);
    _require_common_match($common, $report_common)
        if defined $report_common;
    my $publication = {
        schema => $PROFILE_PUBLICATION_SCHEMA,
        schema_version => 1,
        publication_identity => undef,
        capture_identity => _clone($common),
        report => _clone($report),
    };
    $publication->{publication_identity} =
        _profile_publication_identity($publication);
    return $publication;
}

sub _validate_profile_publication($publication, $profile) {
    _exact_keys(
        $publication, \@PROFILE_PUBLICATION_KEYS,
        'execution/checking profile publication',
    );
    confess "execution/checking profile publication schema is invalid\n"
        unless ($publication->{schema} // '') eq $PROFILE_PUBLICATION_SCHEMA
            && ($publication->{schema_version} // 0) == 1;
    _validate_common_identity($publication->{capture_identity});
    $ADAPTER->validate_report({
        repository_root => $profile->{_repository_root},
        report => $publication->{report},
    });
    _require_acceptable_profile_report($profile, $publication->{report});
    my $report_common = _report_common_identity($publication->{report});
    _require_common_match($publication->{capture_identity}, $report_common)
        if defined $report_common;
    confess "execution/checking profile publication identity changed\n"
        unless ($publication->{publication_identity} // '')
            eq _profile_publication_identity($publication);
}

sub _profile_entry($profile, $report, $publication, $common) {
    _require_acceptable_profile_report($profile, $report);
    my $evaluation = $report->{canonical_evaluation};
    return {
        profile_id => $profile->{profile_id},
        family => $profile->{family},
        primary_axis => $profile->{primary_axis},
        level => $profile->{level},
        mode => $profile->{mode},
        authority_status => $evaluation->{status},
        report_identity => $report->{report_identity},
        workload_identity => $report->{workload_identity},
        validation_identity => defined($report->{validation_record})
            ? $report->{validation_record}{measurement_identity} : undef,
        controller_applicable =>
            _clone($report->{controller_applicability}{applicable}),
        controller_reason => $report->{controller_applicability}{reason},
        measurement_applicable =>
            _clone($report->{measurement_applicability}{applicable}),
        measurement_reason =>
            $report->{measurement_applicability}{reason},
        measured_samples => scalar(@{$report->{measurement_records}}),
        excluded_samples => scalar(@{$report->{sample_exclusions}}),
        outcome => $report->{outcome},
        diagnostics => _clone($evaluation->{diagnostics}),
        artifact_relative_path => $publication->{artifact_relative_path},
        artifact_sha256 => $publication->{sha256},
        artifact_bytes => $publication->{bytes},
        _common_identity => _clone($common),
    };
}

sub _require_acceptable_profile_report($profile, $report) {
    confess "execution/checking matrix report profile changed\n"
        unless ($report->{family} // '') eq $profile->{family}
            && ($report->{primary_axis} // '') eq $profile->{primary_axis}
            && ($report->{level} // '') eq $profile->{level}
            && ($report->{mode} // '') eq $profile->{mode};
    my $status = $report->{canonical_evaluation}{status} // '';
    confess "execution/checking matrix authority status is invalid\n"
        unless $AUTHORITY_STATUS{$status};
    my $controller =
        $report->{controller_applicability}{applicable} ? 1 : 0;
    my $applicable =
        $report->{measurement_applicability}{applicable} ? 1 : 0;
    my $measured = scalar @{$report->{measurement_records}};
    my $excluded = scalar @{$report->{sample_exclusions}};
    confess "execution/checking matrix cannot seal an excluded sample\n"
        if $excluded;
    if ($status eq 'envelope_unconstructible') {
        confess "source-free matrix report entered the controller\n"
            if $controller || defined($report->{validation_record})
                || defined($report->{workload_identity});
    }
    else {
        confess "constructible matrix report bypassed the controller\n"
            unless $controller && defined($report->{validation_record});
        confess "matrix correctness validation did not accept\n"
            unless $report->{validation_record}{outcome} eq 'accepted';
    }
    if ($profile->{mode} eq 'validation') {
        confess "boundary validation retained measurement samples\n"
            if $measured;
        my $expected = $controller
            ? 'accepted_validation' : 'accepted_source_free_validation';
        confess "boundary validation has the wrong matrix outcome\n"
            unless $report->{outcome} eq $expected;
    }
    elsif ($status eq 'accepted') {
        confess "accepted family measurement is inapplicable\n"
            unless $controller && $applicable;
        confess "accepted family measurement has incomplete raw samples\n"
            unless $measured
                == $EXPECTED_SAMPLES_BY_MODE{$profile->{mode}};
        confess "accepted family measurement has the wrong outcome\n"
            unless $report->{outcome} eq 'accepted';
    }
    else {
        confess "authoritative non-applicability was measured\n" if $measured;
        confess "authoritative non-applicability is marked applicable\n"
            if $applicable;
        confess "authoritative non-applicability has the wrong outcome\n"
            unless $report->{outcome} eq 'validated_not_measured';
    }
}

sub _family_manifest($family, $profiles) {
    confess "execution/checking family matrix profile count changed\n"
        unless @$profiles == @{$AXES{$family}} * @LEVELS;
    my $common = _common_identity_from_profiles($profiles);
    my $manifest = {
        schema => $SCHEMA,
        schema_version => 1,
        matrix_identity => undef,
        family => $family,
        profile_count => scalar(@$profiles),
        common_identity => $common,
        profiles => _clone($profiles),
        dominance => _dominance($profiles),
        outcome => 'accepted',
        diagnostics => [],
        explicit_nonclaims => [@NONCLAIMS],
    };
    $manifest->{matrix_identity} = _matrix_identity($manifest);
    _validate_family_manifest_shape($manifest);
    return $manifest;
}

sub _complete_manifest($manifests) {
    confess "execution/checking complete matrix requires both families\n"
        unless @$manifests == @FAMILIES;
    for my $index (0 .. $#FAMILIES) {
        confess "execution/checking complete matrix family order changed\n"
            unless $manifests->[$index]{family} eq $FAMILIES[$index];
        _validate_family_manifest_shape($manifests->[$index]);
    }
    my $common = _clone($manifests->[0]{common_identity});
    _require_common_match($common, $manifests->[1]{common_identity});
    my @family_entries;
    for my $manifest (@$manifests) {
        push @family_entries, {
            family => $manifest->{family},
            matrix_identity => $manifest->{matrix_identity},
            profile_count => $manifest->{profile_count},
            artifact_relative_path => join('/',
                $PUBLICATION_BASE, _matrix_profile_id($manifest->{family}),
                $MATRIX_FILENAME,
            ),
            artifact_sha256 => sha256_hex(
                _canonical_json($manifest) . "\n",
            ),
            artifact_bytes => bytes::length(
                _canonical_json($manifest) . "\n",
            ),
        };
    }
    my @profiles = map { @{$_->{profiles}} } @$manifests;
    my $complete = {
        schema => $COMPLETE_SCHEMA,
        schema_version => 1,
        matrix_identity => undef,
        family_manifests => \@family_entries,
        total_profile_count => scalar(@profiles),
        common_identity => $common,
        dominance => _dominance(\@profiles),
        outcome => 'accepted',
        diagnostics => [],
        explicit_nonclaims => [@NONCLAIMS],
    };
    $complete->{matrix_identity} = _matrix_identity($complete);
    _validate_complete_manifest_shape($complete);
    return $complete;
}

sub _common_identity_from_profiles($profiles) {
    confess "execution/checking matrix has no profiles\n" unless @$profiles;
    my $first = $profiles->[0]{_common_identity};
    _validate_common_identity($first);
    for my $profile (@$profiles) {
        _require_common_match($first, $profile->{_common_identity});
    }
    delete $_->{_common_identity} for @$profiles;
    return _clone($first);
}

sub _dominance($profiles) {
    my %status = map { $_ => 0 } @AUTHORITY_STATUSES;
    my %diagnostics;
    my ($controller, $controller_inapplicable) = (0, 0);
    my ($applicable, $inapplicable, $raw, $excluded) = (0, 0, 0, 0);
    for my $profile (@$profiles) {
        $status{$profile->{authority_status}}++;
        if ($profile->{controller_applicable}) {
            $controller++;
        }
        else {
            $controller_inapplicable++;
        }
        if ($profile->{measurement_applicable}) {
            $applicable++;
        }
        elsif ($profile->{mode} ne 'validation') {
            $inapplicable++;
        }
        $raw += $profile->{measured_samples};
        $excluded += $profile->{excluded_samples};
        for my $diagnostic (@{$profile->{diagnostics}}) {
            next unless ref($diagnostic) eq 'HASH';
            my $code = $diagnostic->{code};
            my $path = $diagnostic->{semantic_path};
            next unless defined($code) && defined($path);
            my $key = "$code\0$path";
            $diagnostics{$key} //= {
                code => $code,
                semantic_path => $path,
                profiles => 0,
            };
            $diagnostics{$key}{profiles}++;
        }
    }
    return {
        accepted_profiles => $status{accepted},
        expected_rejection_profiles => $status{expected_rejection},
        preflight_dominated_profiles => $status{preflight_dominated},
        source_free_profiles => $status{envelope_unconstructible},
        controller_applicable_profiles => $controller,
        controller_inapplicable_profiles => $controller_inapplicable,
        applicable_measurement_profiles => $applicable,
        inapplicable_measurement_profiles => $inapplicable,
        raw_measurement_records => $raw,
        excluded_measurement_records => $excluded,
        diagnostic_counts => [
            map { $diagnostics{$_} } sort keys %diagnostics
        ],
    };
}

sub _load_report_publication($repo_root, $root_device, $profile) {
    my ($publication_set, $publication) = _read_json_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => $profile->{profile_id},
        filename => $REPORT_FILENAME,
    });
    my %validation_profile = (%$profile, _repository_root => $repo_root);
    _validate_profile_publication($publication_set, \%validation_profile);
    return ($publication_set, $publication);
}

sub _report_common_identity($report) {
    my @records = (
        defined($report->{validation_record})
            ? ($report->{validation_record}) : (),
        @{$report->{measurement_records}},
    );
    return undef unless @records;
    my $first = _record_common_identity($records[0]);
    for my $record (@records) {
        _require_common_match($first, _record_common_identity($record));
    }
    return $first;
}

sub _record_common_identity($record) {
    return {
        git_revision => $record->{git_revision},
        dirty_state => _clone($record->{dirty_state}),
        host_profile => _clone($record->{host_profile}),
        tool_profile => _clone($record->{tool_profile}),
        resource_guard => _clone($record->{resource_guard}),
    };
}

sub _require_common_match($expected, $actual) {
    confess "execution/checking matrix mixed common identities\n"
        unless defined($expected) && defined($actual)
            && _canonical_json($expected) eq _canonical_json($actual);
}

sub _require_capture_revision($common, $git_revision) {
    confess "execution/checking matrix capture Git revision changed\n"
        unless ($common->{git_revision} // '') eq $git_revision;
    confess "execution/checking matrix capture is dirty\n"
        if $common->{dirty_state};
}

sub _require_manifest_revision($manifest, $git_revision) {
    _require_capture_revision($manifest->{common_identity}, $git_revision);
}

sub _publish_json($raw) {
    my $encoded = _canonical_json($raw->{value}) . "\n";
    my $digest = sha256_hex($encoded);
    my $target_rel = join('/',
        $PUBLICATION_BASE, $raw->{profile_id},
    );
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $target_rel,
    );
    if (-e $target_abs || -l $target_abs) {
        my $publication = _publication_metadata({
            repository_root => $raw->{repository_root},
            root_device => $raw->{root_device},
            profile_id => $raw->{profile_id},
            filename => $raw->{filename},
        });
        confess "execution/checking matrix publication collision\n"
            unless $publication->{sha256} eq $digest
                && $publication->{bytes} == bytes::length($encoded);
        $publication->{status} = 'unchanged';
        return $publication;
    }

    my $stage_rel = join('/',
        $STAGING_BASE, "$raw->{profile_id}-$digest",
    );
    my $stage_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $stage_rel,
    );
    if (-e $stage_abs || -l $stage_abs) {
        confess "execution/checking matrix staging is not recoverable\n"
            unless _exact_directory_content(
                $stage_abs, $raw->{filename}, $encoded,
            );
        my @created;
        _ensure_publication_parent(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel), \@created,
        );
        my $recovered = rename($stage_abs, $target_abs);
        if (!$recovered) {
            _remove_empty_directories(\@created);
            confess "cannot recover execution/checking matrix publication\n";
        }
        _remove_empty_parent_chain($stage_abs, $raw->{repository_root});
        my $publication = _publication_metadata({
            repository_root => $raw->{repository_root},
            root_device => $raw->{root_device},
            profile_id => $raw->{profile_id},
            filename => $raw->{filename},
        });
        $publication->{status} = 'recovered';
        return $publication;
    }

    my ($created_stage, $created_publication) = ([], []);
    my $ok = eval {
        ($stage_abs, $created_stage) = _create_owned_stage(
            $raw->{repository_root}, $raw->{root_device}, $stage_rel,
        );
        my $artifact_abs = File::Spec->catfile(
            $stage_abs, $raw->{filename},
        );
        sysopen(my $fh, $artifact_abs, O_WRONLY | O_CREAT | O_EXCL)
            or confess "cannot create execution/checking matrix publication\n";
        binmode($fh, ':raw')
            or confess "cannot set matrix publication byte mode\n";
        print {$fh} $encoded
            or confess "cannot write execution/checking matrix publication\n";
        $fh->flush
            or confess "cannot flush execution/checking matrix publication\n";
        $fh->sync
            or confess "cannot sync execution/checking matrix publication\n";
        close $fh
            or confess "cannot close execution/checking matrix publication\n";
        _ensure_publication_parent(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel), $created_publication,
        );
        confess "execution/checking matrix publication target appeared\n"
            if -e $target_abs || -l $target_abs;
        rename($stage_abs, $target_abs)
            or confess "cannot atomically publish execution/checking matrix\n";
        1;
    };
    if (!$ok) {
        my $error = $@;
        _remove_owned_stage($stage_abs, $created_stage)
            if defined($stage_abs) && @$created_stage;
        _remove_empty_directories($created_publication);
        die $error;
    }
    _remove_empty_directories($created_stage);
    my $publication = _publication_metadata({
        repository_root => $raw->{repository_root},
        root_device => $raw->{root_device},
        profile_id => $raw->{profile_id},
        filename => $raw->{filename},
    });
    confess "execution/checking matrix publication identity changed\n"
        unless $publication->{sha256} eq $digest
            && $publication->{bytes} == bytes::length($encoded);
    $publication->{status} = 'published';
    return $publication;
}

sub _read_json_publication($raw) {
    my $publication = _publication_metadata($raw);
    my @parts = split m{/}, $publication->{artifact_relative_path};
    my $path = File::Spec->catfile($raw->{repository_root}, @parts);
    open my $fh, '<:raw', $path
        or confess "cannot read execution/checking matrix publication\n";
    local $/;
    my $encoded = <$fh>;
    close $fh
        or confess "cannot close execution/checking matrix publication\n";
    my $value = eval { JSON::PP->new->utf8(1)->decode($encoded) };
    confess "execution/checking matrix publication JSON is invalid\n" if $@;
    return ($value, $publication);
}

sub _publication_metadata($raw) {
    confess "execution/checking matrix publication profile ID is invalid\n"
        unless _safe_token($raw->{profile_id});
    confess "execution/checking matrix publication filename is invalid\n"
        unless defined($raw->{filename}) && !ref($raw->{filename})
            && $raw->{filename} =~ /\A[a-z][a-z0-9-]*[.]json\z/;
    my $target_rel = join('/',
        $PUBLICATION_BASE, $raw->{profile_id},
    );
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $target_rel,
    );
    confess "execution/checking matrix publication root is absent\n"
        unless -d $target_abs && !-l $target_abs;
    opendir my $dh, $target_abs
        or confess "cannot inspect execution/checking matrix publication\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close execution/checking matrix publication\n";
    confess "execution/checking matrix publication census changed\n"
        unless @entries == 1 && $entries[0] eq $raw->{filename};
    my $artifact_abs = File::Spec->catfile($target_abs, $raw->{filename});
    confess "execution/checking matrix publication artifact is invalid\n"
        unless -f $artifact_abs && !-l $artifact_abs;
    my @stat = stat($artifact_abs);
    confess "execution/checking matrix publication crossed repository volume\n"
        unless @stat && $stat[0] == $raw->{root_device};
    open my $fh, '<:raw', $artifact_abs
        or confess "cannot read execution/checking matrix artifact\n";
    local $/;
    my $content = <$fh>;
    close $fh
        or confess "cannot close execution/checking matrix artifact\n";
    return {
        status => 'loaded',
        artifact_relative_path => "$target_rel/$raw->{filename}",
        sha256 => sha256_hex($content),
        bytes => bytes::length($content),
    };
}

sub _publication_exists($repo_root, $profile_id) {
    my $relative = join('/', $PUBLICATION_BASE, $profile_id);
    my $path = File::Spec->catdir($repo_root, split m{/}, $relative);
    return -e $path || -l $path;
}

sub _exact_directory_content($root, $filename, $expected) {
    return 0 unless -d $root && !-l $root;
    opendir my $dh, $root or return 0;
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or return 0;
    return 0 unless @entries == 1 && $entries[0] eq $filename;
    my $path = File::Spec->catfile($root, $filename);
    return 0 unless -f $path && !-l $path;
    open my $fh, '<:raw', $path or return 0;
    local $/;
    my $content = <$fh>;
    close $fh or return 0;
    return defined($content) && $content eq $expected;
}

sub _create_owned_stage($repo_root, $root_device, $relative) {
    my $path = $repo_root;
    my @created;
    my $ok = eval {
        my @parts = split m{/}, _safe_relative_path($relative);
        for my $index (0 .. $#parts) {
            $path = File::Spec->catdir($path, $parts[$index]);
            if (-e $path || -l $path) {
                confess "matrix staging traverses a symlink\n" if -l $path;
                confess "matrix staging component is not a directory\n"
                    unless -d $path;
                confess "matrix staging root already exists\n"
                    if $index == $#parts;
            }
            else {
                mkdir($path)
                    or confess "cannot create matrix staging directory\n";
                push @created, $path;
            }
            my @stat = stat($path);
            confess "matrix staging crossed repository volume\n"
                unless @stat && $stat[0] == $root_device;
        }
        1;
    };
    if (!$ok) {
        my $error = $@;
        _remove_empty_directories(\@created);
        die $error;
    }
    return ($path, \@created);
}

sub _remove_owned_stage($stage_abs, $created) {
    if (-e $stage_abs || -l $stage_abs) {
        confess "matrix staging cleanup target is invalid\n"
            unless -d $stage_abs && !-l $stage_abs;
        my $errors;
        remove_tree($stage_abs, {error => \$errors});
        confess "cannot remove matrix publication staging\n"
            if $errors && @$errors;
    }
    confess "matrix publication staging remains after cleanup\n"
        if -e $stage_abs || -l $stage_abs;
    _remove_empty_directories($created);
}

sub _remove_empty_directories($paths) {
    for my $path (reverse @$paths) {
        next unless -d $path && !-l $path;
        rmdir $path;
    }
}

sub _remove_empty_parent_chain($path, $repo_root) {
    my $parent = dirname($path);
    while (index($parent, "$repo_root/") == 0 && $parent ne $repo_root) {
        last unless -d $parent && !-l $parent && rmdir($parent);
        $parent = dirname($parent);
    }
}

sub _safe_destination($repo_root, $root_device, $relative) {
    _safe_relative_path($relative);
    my $path = $repo_root;
    my $existing = $repo_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            confess "matrix destination traverses a symlink\n" if -l $path;
            $existing = $path;
        }
    }
    my @stat = stat($existing);
    confess "matrix destination filesystem identity is unavailable\n"
        unless @stat;
    confess "matrix destination crossed repository volume\n"
        unless $stat[0] == $root_device;
    return $path;
}

sub _ensure_publication_parent(
    $repo_root, $root_device, $parent, $relative, $created,
) {
    my $path = $repo_root;
    for my $part (split m{/}, _safe_relative_path($relative)) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            confess "matrix publication parent traverses a symlink\n"
                if -l $path;
            confess "matrix publication parent is not a directory\n"
                unless -d $path;
        }
        else {
            mkdir($path)
                or confess "cannot create matrix publication parent\n";
            push @$created, $path;
        }
        my @stat = stat($path);
        confess "matrix publication parent crossed repository volume\n"
            unless @stat && $stat[0] == $root_device;
    }
    confess "matrix publication parent mismatch\n" unless $path eq $parent;
}

sub _validate_family_manifest_shape($manifest) {
    confess "execution/checking family matrix must be one unblessed hash\n"
        unless ref($manifest) eq 'HASH' && !blessed($manifest);
    _exact_keys($manifest, \@MATRIX_KEYS, 'execution/checking family matrix');
    confess "execution/checking family matrix schema is invalid\n"
        unless ($manifest->{schema} // '') eq $SCHEMA
            && ($manifest->{schema_version} // 0) == 1;
    _selected_family($manifest->{family});
    confess "execution/checking family matrix profiles must be an array\n"
        unless ref($manifest->{profiles}) eq 'ARRAY';
    confess "execution/checking family matrix profile count changed\n"
        unless $manifest->{profile_count} == @{$manifest->{profiles}};
    _exact_keys($_, \@PROFILE_KEYS, 'execution/checking matrix profile')
        for @{$manifest->{profiles}};
    _validate_common_identity($manifest->{common_identity});
    _validate_dominance($manifest->{dominance});
    confess "execution/checking family matrix outcome changed\n"
        unless ($manifest->{outcome} // '') eq 'accepted';
    confess "execution/checking family matrix diagnostics changed\n"
        unless ref($manifest->{diagnostics}) eq 'ARRAY'
            && !@{$manifest->{diagnostics}};
    confess "execution/checking family matrix nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "execution/checking family matrix identity changed\n"
        unless ($manifest->{matrix_identity} // '')
            eq _matrix_identity($manifest);
}

sub _validate_complete_manifest_shape($manifest) {
    confess "execution/checking complete matrix must be one unblessed hash\n"
        unless ref($manifest) eq 'HASH' && !blessed($manifest);
    _exact_keys(
        $manifest, \@COMPLETE_KEYS, 'execution/checking complete matrix',
    );
    confess "execution/checking complete matrix schema is invalid\n"
        unless ($manifest->{schema} // '') eq $COMPLETE_SCHEMA
            && ($manifest->{schema_version} // 0) == 1;
    confess "execution/checking complete matrix family manifests changed\n"
        unless ref($manifest->{family_manifests}) eq 'ARRAY'
            && @{$manifest->{family_manifests}} == @FAMILIES;
    _exact_keys($_, \@FAMILY_MANIFEST_KEYS,
        'execution/checking complete family manifest')
        for @{$manifest->{family_manifests}};
    confess "execution/checking complete matrix profile count changed\n"
        unless $manifest->{total_profile_count} == @{_inventory()};
    _validate_common_identity($manifest->{common_identity});
    _validate_dominance($manifest->{dominance});
    confess "execution/checking complete matrix outcome changed\n"
        unless ($manifest->{outcome} // '') eq 'accepted';
    confess "execution/checking complete matrix diagnostics changed\n"
        unless ref($manifest->{diagnostics}) eq 'ARRAY'
            && !@{$manifest->{diagnostics}};
    confess "execution/checking complete matrix nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "execution/checking complete matrix identity changed\n"
        unless ($manifest->{matrix_identity} // '')
            eq _matrix_identity($manifest);
}

sub _validate_common_identity($common) {
    _exact_keys(
        $common, \@COMMON_KEYS, 'execution/checking matrix common identity',
    );
    confess "execution/checking matrix Git revision is invalid\n"
        unless ($common->{git_revision} // '') =~ /\A[0-9a-f]{40}\z/;
    confess "execution/checking matrix common identity is dirty\n"
        if $common->{dirty_state};
    confess "execution/checking matrix host/tool/guard identity is invalid\n"
        unless ref($common->{host_profile}) eq 'HASH'
            && ref($common->{tool_profile}) eq 'HASH'
            && ref($common->{resource_guard}) eq 'HASH'
            && $common->{resource_guard}{active};
}

sub _validate_dominance($dominance) {
    _exact_keys(
        $dominance, \@DOMINANCE_KEYS,
        'execution/checking matrix dominance',
    );
    for my $key (grep { $_ ne 'diagnostic_counts' } @DOMINANCE_KEYS) {
        confess "execution/checking matrix dominance count is invalid\n"
            unless _nonnegative_integer($dominance->{$key});
    }
    confess "execution/checking matrix diagnostic counts must be an array\n"
        unless ref($dominance->{diagnostic_counts}) eq 'ARRAY';
    for my $item (@{$dominance->{diagnostic_counts}}) {
        _exact_keys(
            $item, \@DIAGNOSTIC_COUNT_KEYS,
            'execution/checking matrix diagnostic count',
        );
        confess "execution/checking matrix diagnostic count is invalid\n"
            unless ($item->{code} // '') =~ /\A[A-Z][A-Z0-9_]*\z/
                && ($item->{semantic_path} // '') =~ m{\A/}
                && _nonnegative_integer($item->{profiles})
                && $item->{profiles} > 0;
    }
}

sub _profile_publication_identity($publication) {
    my $projection = _clone($publication);
    $projection->{publication_identity} = undef;
    return 'execution-checking-profile-publication/'
        . sha256_hex(_canonical_json($projection));
}

sub _matrix_identity($manifest) {
    my $projection = _clone($manifest);
    $projection->{matrix_identity} = undef;
    return 'execution-checking-matrix/'
        . sha256_hex(_canonical_json($projection));
}

sub _profile_id($family, $axis, $level) {
    my $value = join('.', $family, $axis, $level);
    $value =~ tr/_/-/;
    confess "execution/checking matrix profile ID is invalid\n"
        unless _safe_token($value);
    return $value;
}

sub _matrix_profile_id($family) {
    my $value = "$family.matrix.v1";
    $value =~ tr/_/-/;
    return $value;
}

sub _selected_family($family) {
    confess "execution/checking matrix family is not selected\n"
        unless defined($family) && !ref($family)
            && exists($FAMILY_INDEX{$family});
    return $family;
}

sub _require_active_guard() {
    confess "execution/checking matrix requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "execution/checking matrix guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss <= 4096;
}

sub _repository_root($raw) {
    confess "repository_root must name one scalar directory path\n"
        unless defined($raw) && !ref($raw);
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

sub _require_clean_revision($repo_root) {
    my ($revision_ok, $revision) = _capture_command(
        'git', '-C', $repo_root, 'rev-parse', 'HEAD',
    );
    confess "cannot derive matrix Git revision\n" unless $revision_ok;
    $revision =~ s/\s+\z//;
    confess "matrix Git revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my ($status_ok, $status) = _capture_command(
        'git', '-C', $repo_root, 'status', '--porcelain=v1',
        '--untracked-files=normal',
    );
    confess "cannot derive matrix Git state\n" unless $status_ok;
    confess "execution/checking matrix requires a clean Git revision\n"
        if length($status);
    return $revision;
}

sub _require_unchanged_clean_revision($repo_root, $expected) {
    my $actual = _require_clean_revision($repo_root);
    confess "execution/checking matrix Git revision changed during capture\n"
        unless $actual eq $expected;
}

sub _capture_command(@command) {
    open my $fh, '-|', @command or return (0, '');
    local $/;
    my $output = <$fh> // '';
    my $ok = close $fh;
    return ($ok ? 1 : 0, $output);
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @$args == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "$method invocation");
    return $args->[0];
}

sub _safe_relative_path($value) {
    confess "execution/checking matrix path must be repository-relative\n"
        unless defined($value) && !ref($value) && length($value)
            && $value !~ m{\A/}
            && $value !~ m{\A[A-Za-z]:[\\/]}
            && $value !~ m{(?:\A|/)\.\.(?:/|\z)}
            && $value !~ m{//}
            && $value !~ /[\x00-\x1f\x7f]/
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split(m{/}, $value, -1);
    return $value;
}

sub _safe_token($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A[a-z][a-z0-9_.-]*\z/;
}

sub _nonnegative_integer($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->utf8(1)->encode($value);
}

sub _clone($value) {
    return JSON::PP->new->utf8(1)->decode(_canonical_json($value));
}

1;
