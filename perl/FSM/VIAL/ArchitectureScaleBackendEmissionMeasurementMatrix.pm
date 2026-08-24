package FSM::VIAL::ArchitectureScaleBackendEmissionMeasurementMatrix;

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

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_matrix.v1';
my $COMPLETE_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_complete_matrix.v1';
my $PROFILE_PUBLICATION_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_profile_publication.v1';
my $PROFILE_WORKER_SCHEMA =
    'fsmgen.vial_architecture_scale_backend_emission_profile_worker.v1';
my $FAMILY = 'backend_emission_v1';
my $PUBLICATION_BASE = '.artifacts/qualification/vial-scale/v1';
my $STAGING_BASE =
    '.artifacts/tmp/vial-scale/backend-emission-matrix-publication';
my $REPORT_FILENAME = 'measurement-publication.json';
my $MATRIX_FILENAME = 'matrix.json';
my $COMPLETE_FILENAME = 'complete-matrix.json';

# The largest independently captured canonical report measured 334,757 bytes.
# A 512-KiB file ceiling leaves 56.6% headroom without making the envelope an
# accidental performance or backend-capacity claim. Workers return only the
# compact manifest entry and therefore use a separate 64-KiB IPC ceiling.
my $MAX_PUBLICATION_BYTES = 524_288;
my $MAX_PROFILE_WORKER_RESULT_BYTES = 65_536;
my $MAX_PROFILE_WORKER_ERROR_BYTES = 4_096;
my $ADAPTER = 'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement';
my $PRODUCER = 'FSM::VIAL::ArchitectureScaleBackendEmission';

my %MODE_BY_LEVEL = (
    reference_v1 => 'validation',
    gate_candidate_v1 => 'gate_measurement',
    qualification_candidate_v1 => 'qualification_measurement',
    limit_v1 => 'validation',
    over_limit_v1 => 'validation',
);
my %SAMPLES_BY_MODE = (
    gate_measurement => 3,
    qualification_measurement => 5,
);
my @INVENTORY_KEYS = qw(
    profile_id family backend_profile level mode
);
my @PROFILE_PUBLICATION_KEYS = qw(
    schema schema_version publication_identity capture_identity report
);
my @PROFILE_KEYS = qw(
    profile_id family backend_profile level mode observed_outcome
    artifacts_emitted preflight_dominated report_identity workload_identity
    evaluation_identity validation_identity controller_applicable
    measurement_applicable measurement_reason measured_samples
    excluded_samples provider_applicable provider_included provider_read_only
    provider_external_tool provider_classification outcome diagnostics
    artifact_relative_path artifact_sha256 artifact_bytes
);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @DOMINANCE_KEYS = qw(
    emitted_profiles authoritative_non_emission_profiles
    preflight_dominated_profiles validation_profiles
    measurement_candidate_profiles applicable_measurement_profiles
    inapplicable_measurement_profiles raw_measurement_records
    excluded_measurement_records provider_verification_profiles
    diagnostic_counts
);
my @DIAGNOSTIC_COUNT_KEYS = qw(code semantic_path profiles);
my @MATRIX_KEYS = qw(
    schema schema_version matrix_identity family profile_count common_identity
    profiles dominance outcome diagnostics explicit_nonclaims
);
my @COMPLETE_KEYS = qw(
    schema schema_version matrix_identity family_manifest total_profile_count
    common_identity dominance outcome diagnostics explicit_nonclaims
);
my @FAMILY_MANIFEST_KEYS = qw(
    family matrix_identity profile_count artifact_relative_path
    artifact_sha256 artifact_bytes
);
my @PROFILE_WORKER_ENVELOPE_KEYS = qw(
    schema schema_version ok payload error
);
my @PROFILE_WORKER_PAYLOAD_KEYS = qw(
    operation profile_id publication_status common_identity entry
);
my @NONCLAIMS = (
    @{$ADAPTER->explicit_nonclaims},
    qw(
        partial_matrix_completion mixed_revision_matrix mixed_host_matrix
        mixed_tool_matrix mixed_guard_matrix discarded_raw_sample
        mutable_measurement_publication backend_execution backend_compilation
        simulator_execution iasim_execution performance_capacity
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

sub publication_limits($class) {
    _exact_invocant($class, 'publication_limits');
    return {
        calibrated_canonical_report_bytes => 334_757,
        maximum_publication_bytes => $MAX_PUBLICATION_BYTES,
        maximum_worker_result_bytes => $MAX_PROFILE_WORKER_RESULT_BYTES,
        maximum_worker_error_bytes => $MAX_PROFILE_WORKER_ERROR_BYTES,
    };
}

sub capture_all($class, @args) {
    _exact_invocant($class, 'capture_all');
    my $raw = _request('capture_all', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    my $git_revision = _require_clean_revision($repo_root);
    if (_publication_exists($repo_root, _complete_profile_id())) {
        my $existing = _validate_complete_publication(
            $repo_root, $root_device,
        );
        _require_capture_revision(
            $existing->{common_identity}, $git_revision,
        );
        return _clone($existing);
    }
    my $family = _capture_family(
        $repo_root, $root_device, $git_revision,
    );
    _require_unchanged_clean_revision($repo_root, $git_revision);
    my $complete = _complete_manifest($family);
    my $publication = _publish_json({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => _complete_profile_id(),
        filename => $COMPLETE_FILENAME,
        value => $complete,
    });
    print STDERR
        "vial-scale-backend-emission-matrix: complete matrix $publication->{status}\n";
    return _clone(_validate_complete_publication(
        $repo_root, $root_device,
    ));
}

sub capture_family($class, @args) {
    _exact_invocant($class, 'capture_family');
    my $raw = _request('capture_family', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    my $git_revision = _require_clean_revision($repo_root);
    return _clone(_capture_family(
        $repo_root, $root_device, $git_revision,
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
    return _clone(_validate_complete_publication(
        $repo_root, $root_device,
    ));
}

sub validate_family_publication($class, @args) {
    _exact_invocant($class, 'validate_family_publication');
    my $raw = _request(
        'validate_family_publication', \@args, [qw(repository_root)],
    );
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    return _clone(_validate_family_publication(
        $repo_root, $root_device,
    ));
}

sub _capture_family($repo_root, $root_device, $git_revision) {
    if (_publication_exists($repo_root, _matrix_profile_id())) {
        my $existing = _validate_family_publication(
            $repo_root, $root_device,
        );
        _require_capture_revision(
            $existing->{common_identity}, $git_revision,
        );
        print STDERR
            "vial-scale-backend-emission-matrix: family matrix resumed\n";
        return $existing;
    }

    my @profiles = @{_inventory()};
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
        _require_common_match(
            $common_identity, $result->{common_identity},
        ) if defined $common_identity;
        $common_identity //= _clone($result->{common_identity});
        my $entry = _clone($result->{entry});
        $entry->{_common_identity} = _clone($result->{common_identity});
        push @captured, $entry;
        print STDERR join(' ',
            'vial-scale-backend-emission-matrix:',
            ($index + 1) . '/' . scalar(@profiles),
            "$profile->{backend_profile}/$profile->{level}",
            $result->{publication_status},
        ), "\n";
    }
    _require_unchanged_clean_revision($repo_root, $git_revision);
    my $manifest = _family_manifest(\@captured);
    my $publication = _publish_json({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => _matrix_profile_id(),
        filename => $MATRIX_FILENAME,
        value => $manifest,
    });
    print STDERR
        "vial-scale-backend-emission-matrix: family matrix $publication->{status}\n";
    return _validate_family_publication($repo_root, $root_device);
}

sub _validate_family_publication($repo_root, $root_device) {
    my @profiles = @{_inventory()};
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
        _require_common_match(
            $common_identity, $result->{common_identity},
        ) if defined $common_identity;
        $common_identity //= _clone($result->{common_identity});
        my $entry = _clone($result->{entry});
        $entry->{_common_identity} = _clone($result->{common_identity});
        push @entries, $entry;
    }
    my $expected = _family_manifest(\@entries);
    my ($actual) = _read_json_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => _matrix_profile_id(),
        filename => $MATRIX_FILENAME,
    });
    _validate_family_manifest_shape($actual);
    confess "backend-emission family matrix publication is not canonical\n"
        unless _canonical_json($actual) eq _canonical_json($expected);
    return $actual;
}

sub _validate_complete_publication($repo_root, $root_device) {
    my $family = _validate_family_publication($repo_root, $root_device);
    my $expected = _complete_manifest($family);
    my ($actual) = _read_json_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => _complete_profile_id(),
        filename => $COMPLETE_FILENAME,
    });
    _validate_complete_manifest_shape($actual);
    confess "backend-emission complete matrix publication is not canonical\n"
        unless _canonical_json($actual) eq _canonical_json($expected);
    return $actual;
}

sub _inventory() {
    my $owned = $PRODUCER->owned_shapes;
    confess "backend-emission producer inventory must contain 20 shapes\n"
        unless ref($owned) eq 'ARRAY' && @$owned == 20;
    my @profiles;
    my %seen;
    for my $shape (@$owned) {
        _exact_keys(
            $shape, [qw(backend_profile level)],
            'backend-emission producer-owned shape',
        );
        my $mode = $MODE_BY_LEVEL{$shape->{level}};
        confess "backend-emission producer introduced an unrouted level\n"
            unless defined $mode;
        my $key = "$shape->{backend_profile}\0$shape->{level}";
        confess "backend-emission producer repeated an owned shape\n"
            if $seen{$key}++;
        push @profiles, {
            profile_id => _profile_id(
                $shape->{backend_profile}, $shape->{level},
            ),
            family => $FAMILY,
            backend_profile => $shape->{backend_profile},
            level => $shape->{level},
            mode => $mode,
        };
    }
    return \@profiles;
}

sub _run_profile_process($raw) {
    return _run_isolated_profile_worker({
        profile_id => $raw->{profile}{profile_id},
        worker => sub { _profile_worker_payload($raw) },
        validate_payload => sub {
            _validate_profile_worker_payload($_[0], $raw);
        },
    });
}

sub _profile_worker_payload($raw) {
    my ($repo_root, $root_device, $profile, $operation, $git_revision) =
        @{$raw}{qw(
            repository_root root_device profile operation git_revision
        )};
    my ($publication_set, $publication, $common_identity);
    if (_publication_exists($repo_root, $profile->{profile_id})) {
        ($publication_set, $publication) = _load_report_publication(
            $repo_root, $root_device, $profile,
        );
        $publication->{status} = $operation eq 'capture_or_resume'
            ? 'resumed' : 'loaded';
    }
    else {
        confess "backend-emission profile publication is absent\n"
            unless $operation eq 'capture_or_resume';
        my $request = {
            repository_root => $repo_root,
            backend_profile => $profile->{backend_profile},
            level => $profile->{level},
        };
        my $report = $profile->{mode} eq 'validation'
            ? $ADAPTER->validate_profile($request)
            : $ADAPTER->measure_profile($request);
        $ADAPTER->validate_report({
            repository_root => $repo_root,
            report => $report,
        });
        _require_acceptable_profile_report($profile, $report);
        $common_identity = _report_common_identity($report);
        _require_common_match(
            $raw->{expected_common_identity}, $common_identity,
        ) if defined $raw->{expected_common_identity};
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
        my $status = $publication->{status};
        ($publication_set, $publication) = _load_report_publication(
            $repo_root, $root_device, $profile,
        );
        $publication->{status} = $status;
    }
    my $loaded_common = $publication_set->{capture_identity};
    _require_common_match(
        $raw->{expected_common_identity}, $loaded_common,
    ) if defined $raw->{expected_common_identity};
    _require_capture_revision($loaded_common, $git_revision)
        if defined $git_revision;
    my $entry = _profile_entry(
        $profile, $publication_set->{report}, $publication,
    );
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
        'isolated backend-emission profile worker invocation',
    );
    confess "isolated backend-emission profile worker ID is invalid\n"
        unless _safe_token($raw->{profile_id});
    confess "isolated backend-emission profile worker callback is invalid\n"
        unless ref($raw->{worker}) eq 'CODE'
            && ref($raw->{validate_payload}) eq 'CODE';
    pipe(my $reader, my $writer)
        or confess "cannot create backend-emission worker pipe\n";
    my $descriptor_ok = eval {
        _set_close_on_exec($reader, 'reader');
        _set_close_on_exec($writer, 'writer');
        my $flags = fcntl($reader, F_GETFL, 0);
        confess "cannot inspect backend-emission worker reader flags\n"
            unless defined $flags;
        confess "cannot make backend-emission worker reader nonblocking\n"
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
        confess "cannot fork backend-emission profile worker\n";
    }
    if ($pid == 0) {
        close $reader;
        my ($payload, $worker_error);
        my $ok = eval {
            $payload = $raw->{worker}->();
            1;
        };
        $worker_error = $@ unless $ok;
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
                'isolated backend-emission profile worker result exceeded the bounded envelope',
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
            $read_error = 'cannot wait for backend-emission profile worker';
            $done = 1;
        }
        else {
            sleep(0.01);
        }
    }
    $read_error //= _drain_profile_worker_pipe($reader, \$buffer);
    close $reader
        or $read_error //= 'cannot close backend-emission worker reader';
    confess "$read_error\n" if defined $read_error;
    my $signal = defined($wait_status) && WIFSIGNALED($wait_status)
        ? WTERMSIG($wait_status) : 0;
    confess "isolated backend-emission profile worker '$raw->{profile_id}' terminated by signal $signal\n"
        if $signal;
    my ($envelope, $decode_error) =
        _decode_profile_worker_envelope($buffer);
    my $exit_code = defined($wait_status) && WIFEXITED($wait_status)
        ? WEXITSTATUS($wait_status) : undef;
    if (defined $decode_error) {
        my $status = defined($exit_code)
            ? " with exit status $exit_code" : '';
        confess "isolated backend-emission profile worker '$raw->{profile_id}' $decode_error$status\n";
    }
    confess "isolated backend-emission profile worker '$raw->{profile_id}' failed: $envelope->{error}\n"
        unless $envelope->{ok};
    confess "isolated backend-emission profile worker '$raw->{profile_id}' exited with status $exit_code\n"
        unless defined($exit_code) && $exit_code == 0;
    my $payload_ok = eval {
        $raw->{validate_payload}->($envelope->{payload});
        1;
    };
    confess "isolated backend-emission profile worker '$raw->{profile_id}' payload is invalid: $@"
        unless $payload_ok;
    return _clone($envelope->{payload});
}

sub _validate_profile_worker_payload($payload, $raw) {
    _exact_keys(
        $payload, \@PROFILE_WORKER_PAYLOAD_KEYS,
        'isolated backend-emission profile worker payload',
    );
    confess "backend-emission worker operation changed\n"
        unless ($payload->{operation} // '') eq $raw->{operation};
    confess "backend-emission worker profile changed\n"
        unless ($payload->{profile_id} // '')
            eq $raw->{profile}{profile_id};
    my %allowed = $raw->{operation} eq 'capture_or_resume'
        ? map { $_ => 1 } qw(published recovered unchanged resumed)
        : (loaded => 1);
    confess "backend-emission worker publication status is invalid\n"
        unless $allowed{$payload->{publication_status} // ''};
    _validate_common_identity($payload->{common_identity});
    _require_common_match(
        $raw->{expected_common_identity}, $payload->{common_identity},
    ) if defined $raw->{expected_common_identity};
    _require_capture_revision(
        $payload->{common_identity}, $raw->{git_revision},
    ) if defined $raw->{git_revision};
    _validate_profile_entry($payload->{entry}, $raw->{profile});
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
    $error = 'isolated backend-emission profile worker failed without an exception'
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
            'isolated backend-emission worker envelope',
        );
        confess "backend-emission worker envelope schema is invalid\n"
            unless ($decoded->{schema} // '') eq $PROFILE_WORKER_SCHEMA
                && ($decoded->{schema_version} // 0) == 1;
        _json_boolean($decoded->{ok}, 'backend-emission worker ok');
        if ($decoded->{ok}) {
            confess "successful backend-emission worker retained an error\n"
                if defined $decoded->{error};
        }
        else {
            confess "failed backend-emission worker retained a payload\n"
                if defined $decoded->{payload};
            confess "failed backend-emission worker error is invalid\n"
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
    confess "cannot inspect backend-emission worker $label descriptor\n"
        unless defined $flags;
    confess "cannot protect backend-emission worker $label descriptor\n"
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
        return 'cannot read backend-emission profile worker result';
    }
}

sub _profile_publication($common, $report) {
    _validate_common_identity($common);
    _require_common_match($common, _report_common_identity($report));
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
        'backend-emission profile publication',
    );
    confess "backend-emission profile publication schema is invalid\n"
        unless ($publication->{schema} // '')
                eq $PROFILE_PUBLICATION_SCHEMA
            && ($publication->{schema_version} // 0) == 1;
    _validate_common_identity($publication->{capture_identity});
    $ADAPTER->validate_report({
        repository_root => $profile->{_repository_root},
        report => $publication->{report},
    });
    _require_acceptable_profile_report(
        $profile, $publication->{report},
    );
    _require_common_match(
        $publication->{capture_identity},
        _report_common_identity($publication->{report}),
    );
    confess "backend-emission profile publication identity changed\n"
        unless ($publication->{publication_identity} // '')
            eq _profile_publication_identity($publication);
}

sub _profile_entry($profile, $report, $publication) {
    _require_acceptable_profile_report($profile, $report);
    my $evaluation = $report->{canonical_evaluation};
    my $provider = $report->{provider_verification};
    return {
        profile_id => $profile->{profile_id},
        family => $profile->{family},
        backend_profile => $profile->{backend_profile},
        level => $profile->{level},
        mode => $profile->{mode},
        observed_outcome => $evaluation->{observed_outcome},
        artifacts_emitted =>
            _clone($evaluation->{outcome_contract}{artifacts_emitted}),
        preflight_dominated =>
            $evaluation->{observed_outcome}
                    eq 'preflight_dominated_not_constructed'
                ? JSON::PP::true : JSON::PP::false,
        report_identity => $report->{report_identity},
        workload_identity => $report->{workload_identity},
        evaluation_identity => $evaluation->{evaluation_identity},
        validation_identity =>
            $report->{validation_record}{measurement_identity},
        controller_applicable =>
            _clone($report->{controller_applicability}{applicable}),
        measurement_applicable =>
            _clone($report->{measurement_applicability}{applicable}),
        measurement_reason =>
            $report->{measurement_applicability}{reason},
        measured_samples => scalar(@{$report->{measurement_records}}),
        excluded_samples => scalar(@{$report->{sample_exclusions}}),
        provider_applicable => _clone($provider->{applicable}),
        provider_included => _clone($provider->{included_in_emit}),
        provider_read_only => _clone($provider->{read_only}),
        provider_external_tool =>
            _clone($provider->{external_verification_tool}),
        provider_classification => $provider->{classification},
        outcome => $report->{outcome},
        diagnostics => _clone($report->{diagnostics}),
        artifact_relative_path => $publication->{artifact_relative_path},
        artifact_sha256 => $publication->{sha256},
        artifact_bytes => $publication->{bytes},
    };
}

sub _require_acceptable_profile_report($profile, $report) {
    for my $key (qw(family backend_profile level mode)) {
        confess "backend-emission matrix report $key changed\n"
            unless ($report->{$key} // '') eq ($profile->{$key} // '');
    }
    confess "backend-emission matrix controller became inapplicable\n"
        unless $report->{controller_applicability}{applicable};
    confess "backend-emission matrix correctness validation did not accept\n"
        unless $report->{validation_record}{outcome} eq 'accepted';
    my $emitted =
        $report->{canonical_evaluation}{outcome_contract}{artifacts_emitted}
            ? 1 : 0;
    my $applicable = $report->{measurement_applicability}{applicable}
        ? 1 : 0;
    my $measured = scalar @{$report->{measurement_records}};
    my $excluded = scalar @{$report->{sample_exclusions}};
    confess "backend-emission matrix cannot seal an excluded sample\n"
        if $excluded;
    if ($profile->{mode} eq 'validation') {
        confess "backend-emission validation retained timing samples\n"
            if $measured || $applicable;
        confess "backend-emission validation outcome changed\n"
            unless $report->{outcome} eq 'accepted_validation';
    }
    elsif ($emitted) {
        confess "emitted backend-emission profile is measurement-inapplicable\n"
            unless $applicable;
        confess "emitted backend-emission profile sample count changed\n"
            unless $measured == $SAMPLES_BY_MODE{$profile->{mode}};
        confess "emitted backend-emission profile outcome changed\n"
            unless $report->{outcome} eq 'accepted';
    }
    else {
        confess "authoritative backend non-emission was measured\n"
            if $applicable || $measured;
        confess "authoritative backend non-emission reason changed\n"
            unless ($report->{measurement_applicability}{reason} // '')
                eq 'authoritative_non_emission';
        confess "authoritative backend non-emission outcome changed\n"
            unless $report->{outcome} eq 'validated_not_measured';
    }
}

sub _validate_profile_entry($entry, $profile) {
    _exact_keys(
        $entry, \@PROFILE_KEYS, 'backend-emission matrix profile entry',
    );
    for my $key (qw(profile_id family backend_profile level mode)) {
        confess "backend-emission profile entry $key changed\n"
            unless ($entry->{$key} // '') eq ($profile->{$key} // '');
    }
    for my $key (qw(
        artifacts_emitted preflight_dominated controller_applicable
        measurement_applicable provider_applicable provider_included
        provider_read_only provider_external_tool
    )) {
        _json_boolean($entry->{$key}, "backend-emission entry $key");
    }
    confess "backend-emission preflight classification changed\n"
        unless ($entry->{preflight_dominated} ? 1 : 0)
            == ($entry->{observed_outcome}
                    eq 'preflight_dominated_not_constructed' ? 1 : 0);
    confess "backend-emission entry outcome identity is invalid\n"
        unless _safe_token($entry->{observed_outcome});
    for my $key (qw(
        report_identity workload_identity evaluation_identity
        validation_identity
    )) {
        confess "backend-emission entry $key is invalid\n"
            unless defined($entry->{$key}) && !ref($entry->{$key})
                && length($entry->{$key});
    }
    confess "backend-emission entry bypassed the common controller\n"
        unless $entry->{controller_applicable};
    confess "backend-emission entry sample counts are invalid\n"
        unless _nonnegative_integer($entry->{measured_samples})
            && _nonnegative_integer($entry->{excluded_samples})
            && !$entry->{excluded_samples};
    if ($profile->{mode} eq 'validation') {
        confess "backend-emission validation entry retained timing evidence\n"
            if $entry->{measurement_applicable}
                || $entry->{measured_samples};
        confess "backend-emission validation entry reason changed\n"
            unless ($entry->{measurement_reason} // '')
                eq 'correctness_only_requested';
        confess "backend-emission validation entry outcome changed\n"
            unless ($entry->{outcome} // '') eq 'accepted_validation';
    }
    elsif ($entry->{artifacts_emitted}) {
        confess "emitted backend-emission entry is measurement-inapplicable\n"
            unless $entry->{measurement_applicable}
                && !defined($entry->{measurement_reason});
        confess "emitted backend-emission entry sample count changed\n"
            unless $entry->{measured_samples}
                == $SAMPLES_BY_MODE{$profile->{mode}};
        confess "emitted backend-emission entry outcome changed\n"
            unless ($entry->{outcome} // '') eq 'accepted';
    }
    else {
        confess "authoritative backend non-emission entry was measured\n"
            if $entry->{measurement_applicable}
                || $entry->{measured_samples};
        confess "authoritative backend non-emission entry reason changed\n"
            unless ($entry->{measurement_reason} // '')
                eq 'authoritative_non_emission';
        confess "authoritative backend non-emission entry outcome changed\n"
            unless ($entry->{outcome} // '') eq 'validated_not_measured';
    }
    confess "preflight-dominated entry claims emitted artifacts\n"
        if $entry->{preflight_dominated} && $entry->{artifacts_emitted};
    my $is_osvvm =
        $profile->{backend_profile} eq 'vhdl_osvvm_qualified';
    my $provider_matches = $is_osvvm
        ? $entry->{provider_applicable}
            && $entry->{provider_included}
            && $entry->{provider_read_only}
            && !$entry->{provider_external_tool}
            && ($entry->{provider_classification} // '')
                eq 'sealed_osvvm_2026_05_provider_materialization'
        : !$entry->{provider_applicable}
            && !$entry->{provider_included}
            && !$entry->{provider_read_only}
            && !$entry->{provider_external_tool}
            && ($entry->{provider_classification} // '')
                eq 'not_applicable';
    confess "backend-emission entry provider classification changed\n"
        unless $provider_matches;
    confess "backend-emission entry artifact path changed\n"
        unless $entry->{artifact_relative_path} eq join('/',
            $PUBLICATION_BASE, $profile->{profile_id}, $REPORT_FILENAME,
        );
    confess "backend-emission entry artifact digest is invalid\n"
        unless ($entry->{artifact_sha256} // '') =~ /\A[0-9a-f]{64}\z/;
    confess "backend-emission entry artifact size is invalid\n"
        unless _nonnegative_integer($entry->{artifact_bytes})
            && $entry->{artifact_bytes} > 0
            && $entry->{artifact_bytes} <= $MAX_PUBLICATION_BYTES;
    confess "backend-emission entry diagnostics are invalid\n"
        unless ref($entry->{diagnostics}) eq 'ARRAY';
    confess "accepted backend-emission entry retained diagnostics\n"
        if @{$entry->{diagnostics}};
}

sub _family_manifest($profiles) {
    confess "backend-emission matrix profile count changed\n"
        unless @$profiles == @{_inventory()};
    my $common = _common_identity_from_profiles($profiles);
    my $manifest = {
        schema => $SCHEMA,
        schema_version => 1,
        matrix_identity => undef,
        family => $FAMILY,
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

sub _complete_manifest($family) {
    _validate_family_manifest_shape($family);
    my $encoded = _canonical_json($family) . "\n";
    my $complete = {
        schema => $COMPLETE_SCHEMA,
        schema_version => 1,
        matrix_identity => undef,
        family_manifest => {
            family => $FAMILY,
            matrix_identity => $family->{matrix_identity},
            profile_count => $family->{profile_count},
            artifact_relative_path => join('/',
                $PUBLICATION_BASE, _matrix_profile_id(), $MATRIX_FILENAME,
            ),
            artifact_sha256 => sha256_hex($encoded),
            artifact_bytes => bytes::length($encoded),
        },
        total_profile_count => $family->{profile_count},
        common_identity => _clone($family->{common_identity}),
        dominance => _clone($family->{dominance}),
        outcome => 'accepted',
        diagnostics => [],
        explicit_nonclaims => [@NONCLAIMS],
    };
    $complete->{matrix_identity} = _matrix_identity($complete);
    _validate_complete_manifest_shape($complete);
    return $complete;
}

sub _common_identity_from_profiles($profiles) {
    confess "backend-emission matrix has no profiles\n" unless @$profiles;
    my $first = $profiles->[0]{_common_identity};
    _validate_common_identity($first);
    for my $profile (@$profiles) {
        _require_common_match($first, $profile->{_common_identity});
    }
    delete $_->{_common_identity} for @$profiles;
    return _clone($first);
}

sub _dominance($profiles) {
    my %diagnostics;
    my %count = map { $_ => 0 } grep { $_ ne 'diagnostic_counts' }
        @DOMINANCE_KEYS;
    for my $profile (@$profiles) {
        $count{emitted_profiles}++ if $profile->{artifacts_emitted};
        $count{authoritative_non_emission_profiles}++
            unless $profile->{artifacts_emitted};
        $count{preflight_dominated_profiles}++
            if $profile->{preflight_dominated};
        if ($profile->{mode} eq 'validation') {
            $count{validation_profiles}++;
        }
        else {
            $count{measurement_candidate_profiles}++;
            if ($profile->{measurement_applicable}) {
                $count{applicable_measurement_profiles}++;
            }
            else {
                $count{inapplicable_measurement_profiles}++;
            }
        }
        $count{raw_measurement_records} += $profile->{measured_samples};
        $count{excluded_measurement_records} += $profile->{excluded_samples};
        $count{provider_verification_profiles}++
            if $profile->{provider_applicable}
                && $profile->{provider_included}
                && $profile->{provider_read_only}
                && !$profile->{provider_external_tool};
        for my $diagnostic (@{$profile->{diagnostics}}) {
            next unless ref($diagnostic) eq 'HASH';
            my ($code, $path) = @{$diagnostic}{qw(code semantic_path)};
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
        %count,
        diagnostic_counts => [
            map { $diagnostics{$_} } sort keys %diagnostics
        ],
    };
}

sub _load_report_publication($repo_root, $root_device, $profile) {
    my ($set, $publication) = _read_json_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => $profile->{profile_id},
        filename => $REPORT_FILENAME,
    });
    my %validation_profile = (
        %$profile, _repository_root => $repo_root,
    );
    _validate_profile_publication($set, \%validation_profile);
    return ($set, $publication);
}

sub _report_common_identity($report) {
    my @records = (
        $report->{validation_record}, @{$report->{measurement_records}},
    );
    confess "backend-emission matrix report has no records\n"
        unless @records;
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
    confess "backend-emission matrix mixed common identities\n"
        unless defined($expected) && defined($actual)
            && _canonical_json($expected) eq _canonical_json($actual);
}

sub _require_capture_revision($common, $git_revision) {
    confess "backend-emission matrix capture Git revision changed\n"
        unless defined($git_revision)
            && ($common->{git_revision} // '') eq $git_revision;
    confess "backend-emission matrix capture is dirty\n"
        if $common->{dirty_state};
}

sub _publish_json($raw) {
    my $encoded = _canonical_json($raw->{value}) . "\n";
    confess "backend-emission matrix publication exceeds its calibrated ceiling\n"
        if bytes::length($encoded) > $MAX_PUBLICATION_BYTES;
    my $digest = sha256_hex($encoded);
    my $target_rel = join('/',
        $PUBLICATION_BASE, $raw->{profile_id},
    );
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $target_rel,
    );
    if (-e $target_abs || -l $target_abs) {
        my $publication = _publication_metadata({
            %$raw,
        });
        confess "backend-emission matrix publication collision\n"
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
        confess "backend-emission matrix staging is not recoverable\n"
            unless _exact_directory_content(
                $stage_abs, $raw->{filename}, $encoded,
            );
        my @created;
        _ensure_publication_parent(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel), \@created,
        );
        unless (rename($stage_abs, $target_abs)) {
            _remove_empty_directories(\@created);
            confess "cannot recover backend-emission matrix publication\n";
        }
        _remove_empty_parent_chain($stage_abs, $raw->{repository_root});
        my $publication = _publication_metadata({%$raw});
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
            or confess "cannot create backend-emission matrix publication\n";
        binmode($fh, ':raw')
            or confess "cannot set backend-emission publication byte mode\n";
        print {$fh} $encoded
            or confess "cannot write backend-emission matrix publication\n";
        $fh->flush
            or confess "cannot flush backend-emission matrix publication\n";
        $fh->sync
            or confess "cannot sync backend-emission matrix publication\n";
        close $fh
            or confess "cannot close backend-emission matrix publication\n";
        _ensure_publication_parent(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel),
            $created_publication,
        );
        confess "backend-emission matrix publication target appeared\n"
            if -e $target_abs || -l $target_abs;
        rename($stage_abs, $target_abs)
            or confess "cannot atomically publish backend-emission matrix\n";
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
    my $publication = _publication_metadata({%$raw});
    confess "backend-emission matrix publication identity changed\n"
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
        or confess "cannot read backend-emission matrix publication\n";
    local $/;
    my $encoded = <$fh>;
    close $fh
        or confess "cannot close backend-emission matrix publication\n";
    confess "backend-emission matrix publication is not newline-terminated\n"
        unless defined($encoded) && $encoded =~ /\n\z/;
    my $value = eval { JSON::PP->new->utf8(1)->decode($encoded) };
    confess "backend-emission matrix publication JSON is invalid\n" if $@;
    confess "backend-emission matrix publication JSON is not canonical\n"
        unless _canonical_json($value) . "\n" eq $encoded;
    return ($value, $publication);
}

sub _publication_metadata($raw) {
    confess "backend-emission publication profile ID is invalid\n"
        unless _safe_token($raw->{profile_id});
    confess "backend-emission publication filename is invalid\n"
        unless defined($raw->{filename}) && !ref($raw->{filename})
            && $raw->{filename} =~ /\A[a-z][a-z0-9-]*[.]json\z/;
    my $target_rel = join('/',
        $PUBLICATION_BASE, $raw->{profile_id},
    );
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $target_rel,
    );
    confess "backend-emission publication root is absent\n"
        unless -d $target_abs && !-l $target_abs;
    opendir my $dh, $target_abs
        or confess "cannot inspect backend-emission publication\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close backend-emission publication directory\n";
    confess "backend-emission publication census changed\n"
        unless @entries == 1 && $entries[0] eq $raw->{filename};
    my $artifact_abs = File::Spec->catfile(
        $target_abs, $raw->{filename},
    );
    confess "backend-emission publication artifact is invalid\n"
        unless -f $artifact_abs && !-l $artifact_abs;
    my @stat = stat($artifact_abs);
    confess "backend-emission publication crossed repository volume\n"
        unless @stat && $stat[0] == $raw->{root_device};
    confess "backend-emission publication exceeds its calibrated ceiling\n"
        unless $stat[7] > 0 && $stat[7] <= $MAX_PUBLICATION_BYTES;
    open my $fh, '<:raw', $artifact_abs
        or confess "cannot read backend-emission publication artifact\n";
    local $/;
    my $content = <$fh>;
    close $fh
        or confess "cannot close backend-emission publication artifact\n";
    confess "backend-emission publication size changed while reading\n"
        unless bytes::length($content) == $stat[7];
    return {
        status => 'loaded',
        artifact_relative_path => "$target_rel/$raw->{filename}",
        sha256 => sha256_hex($content),
        bytes => bytes::length($content),
    };
}

sub _publication_exists($repo_root, $profile_id) {
    my $relative = join('/', $PUBLICATION_BASE, $profile_id);
    my $path = File::Spec->catdir(
        $repo_root, split(m{/}, $relative),
    );
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
                confess "backend-emission staging traverses a symlink\n"
                    if -l $path;
                confess "backend-emission staging component is not a directory\n"
                    unless -d $path;
                confess "backend-emission staging root already exists\n"
                    if $index == $#parts;
            }
            else {
                mkdir($path)
                    or confess "cannot create backend-emission staging directory\n";
                push @created, $path;
            }
            my @stat = stat($path);
            confess "backend-emission staging crossed repository volume\n"
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
        confess "backend-emission staging cleanup target is invalid\n"
            unless -d $stage_abs && !-l $stage_abs;
        my $errors;
        remove_tree($stage_abs, {error => \$errors});
        confess "cannot remove backend-emission publication staging\n"
            if $errors && @$errors;
    }
    confess "backend-emission publication staging remains after cleanup\n"
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
            confess "backend-emission destination traverses a symlink\n"
                if -l $path;
            $existing = $path;
        }
    }
    my @stat = stat($existing);
    confess "backend-emission destination filesystem identity is unavailable\n"
        unless @stat;
    confess "backend-emission destination crossed repository volume\n"
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
            confess "backend-emission publication parent traverses a symlink\n"
                if -l $path;
            confess "backend-emission publication parent is not a directory\n"
                unless -d $path;
        }
        else {
            mkdir($path)
                or confess "cannot create backend-emission publication parent\n";
            push @$created, $path;
        }
        my @stat = stat($path);
        confess "backend-emission publication parent crossed repository volume\n"
            unless @stat && $stat[0] == $root_device;
    }
    confess "backend-emission publication parent mismatch\n"
        unless $path eq $parent;
}

sub _validate_family_manifest_shape($manifest) {
    _exact_keys(
        $manifest, \@MATRIX_KEYS, 'backend-emission family matrix',
    );
    confess "backend-emission family matrix schema is invalid\n"
        unless ($manifest->{schema} // '') eq $SCHEMA
            && ($manifest->{schema_version} // 0) == 1;
    confess "backend-emission family matrix family changed\n"
        unless ($manifest->{family} // '') eq $FAMILY;
    confess "backend-emission family matrix profiles are invalid\n"
        unless ref($manifest->{profiles}) eq 'ARRAY'
            && $manifest->{profile_count} == @{$manifest->{profiles}}
            && $manifest->{profile_count} == @{_inventory()};
    my $inventory = _inventory();
    for my $index (0 .. $#$inventory) {
        _validate_profile_entry(
            $manifest->{profiles}[$index], $inventory->[$index],
        );
    }
    _validate_common_identity($manifest->{common_identity});
    _validate_dominance($manifest->{dominance});
    confess "backend-emission family matrix outcome changed\n"
        unless ($manifest->{outcome} // '') eq 'accepted';
    confess "backend-emission family matrix diagnostics changed\n"
        unless ref($manifest->{diagnostics}) eq 'ARRAY'
            && !@{$manifest->{diagnostics}};
    confess "backend-emission family matrix nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "backend-emission family matrix identity changed\n"
        unless ($manifest->{matrix_identity} // '')
            eq _matrix_identity($manifest);
}

sub _validate_complete_manifest_shape($manifest) {
    _exact_keys(
        $manifest, \@COMPLETE_KEYS, 'backend-emission complete matrix',
    );
    confess "backend-emission complete matrix schema is invalid\n"
        unless ($manifest->{schema} // '') eq $COMPLETE_SCHEMA
            && ($manifest->{schema_version} // 0) == 1;
    _exact_keys(
        $manifest->{family_manifest}, \@FAMILY_MANIFEST_KEYS,
        'backend-emission complete family manifest',
    );
    confess "backend-emission complete matrix family changed\n"
        unless $manifest->{family_manifest}{family} eq $FAMILY;
    confess "backend-emission complete family identity is invalid\n"
        unless ($manifest->{family_manifest}{matrix_identity} // '')
                =~ /\Abackend-emission-matrix\/[0-9a-f]{64}\z/
            && ($manifest->{family_manifest}{artifact_sha256} // '')
                =~ /\A[0-9a-f]{64}\z/
            && ($manifest->{family_manifest}{artifact_relative_path} // '')
                eq join('/', $PUBLICATION_BASE, _matrix_profile_id(),
                    $MATRIX_FILENAME)
            && _nonnegative_integer(
                $manifest->{family_manifest}{artifact_bytes},
            )
            && $manifest->{family_manifest}{artifact_bytes} > 0
            && $manifest->{family_manifest}{artifact_bytes}
                <= $MAX_PUBLICATION_BYTES;
    confess "backend-emission complete matrix profile count changed\n"
        unless $manifest->{total_profile_count} == @{_inventory()}
            && $manifest->{family_manifest}{profile_count}
                == $manifest->{total_profile_count};
    _validate_common_identity($manifest->{common_identity});
    _validate_dominance($manifest->{dominance});
    confess "backend-emission complete matrix outcome changed\n"
        unless ($manifest->{outcome} // '') eq 'accepted';
    confess "backend-emission complete matrix diagnostics changed\n"
        unless ref($manifest->{diagnostics}) eq 'ARRAY'
            && !@{$manifest->{diagnostics}};
    confess "backend-emission complete matrix nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "backend-emission complete matrix identity changed\n"
        unless ($manifest->{matrix_identity} // '')
            eq _matrix_identity($manifest);
}

sub _validate_common_identity($common) {
    _exact_keys(
        $common, \@COMMON_KEYS,
        'backend-emission matrix common identity',
    );
    confess "backend-emission matrix Git revision is invalid\n"
        unless ($common->{git_revision} // '') =~ /\A[0-9a-f]{40}\z/;
    confess "backend-emission matrix common identity is dirty\n"
        if $common->{dirty_state};
    confess "backend-emission matrix host/tool/guard identity is invalid\n"
        unless ref($common->{host_profile}) eq 'HASH'
            && ref($common->{tool_profile}) eq 'HASH'
            && ref($common->{resource_guard}) eq 'HASH'
            && $common->{resource_guard}{active};
}

sub _validate_dominance($dominance) {
    _exact_keys(
        $dominance, \@DOMINANCE_KEYS,
        'backend-emission matrix dominance',
    );
    for my $key (grep { $_ ne 'diagnostic_counts' } @DOMINANCE_KEYS) {
        confess "backend-emission matrix dominance count is invalid\n"
            unless _nonnegative_integer($dominance->{$key});
    }
    confess "backend-emission matrix diagnostic counts are invalid\n"
        unless ref($dominance->{diagnostic_counts}) eq 'ARRAY';
    for my $item (@{$dominance->{diagnostic_counts}}) {
        _exact_keys(
            $item, \@DIAGNOSTIC_COUNT_KEYS,
            'backend-emission matrix diagnostic count',
        );
        confess "backend-emission matrix diagnostic count is invalid\n"
            unless ($item->{code} // '') =~ /\A[A-Z][A-Z0-9_]*\z/
                && ($item->{semantic_path} // '') =~ m{\A/}
                && _nonnegative_integer($item->{profiles})
                && $item->{profiles} > 0;
    }
    my $profiles = @{_inventory()};
    confess "backend-emission dominance emission partition changed\n"
        unless $dominance->{emitted_profiles}
                + $dominance->{authoritative_non_emission_profiles}
            == $profiles;
    confess "backend-emission dominance mode partition changed\n"
        unless $dominance->{validation_profiles}
                + $dominance->{measurement_candidate_profiles}
            == $profiles;
    confess "backend-emission dominance applicability partition changed\n"
        unless $dominance->{applicable_measurement_profiles}
                + $dominance->{inapplicable_measurement_profiles}
            == $dominance->{measurement_candidate_profiles};
    confess "backend-emission dominance retained excluded evidence\n"
        if $dominance->{excluded_measurement_records};
    confess "backend-emission provider-verification partition changed\n"
        unless $dominance->{provider_verification_profiles} == 5;
}

sub _profile_publication_identity($publication) {
    my $projection = _clone($publication);
    $projection->{publication_identity} = undef;
    return 'backend-emission-profile-publication/'
        . sha256_hex(_canonical_json($projection));
}

sub _matrix_identity($manifest) {
    my $projection = _clone($manifest);
    $projection->{matrix_identity} = undef;
    return 'backend-emission-matrix/'
        . sha256_hex(_canonical_json($projection));
}

sub _profile_id($profile, $level) {
    return 'backend-emission-profile-'
        . sha256_hex(_canonical_json({
            backend_profile => $profile,
            level => $level,
        }));
}

sub _matrix_profile_id() {
    return 'backend-emission-matrix-v1';
}

sub _complete_profile_id() {
    return 'backend-emission-complete-matrix-v1';
}

sub _require_active_guard() {
    confess "backend-emission matrix requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "backend-emission matrix guard thresholds are invalid\n"
        unless defined($host)
            && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss)
            && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
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
    confess "cannot derive backend-emission matrix Git revision\n"
        unless $revision_ok;
    $revision =~ s/\s+\z//;
    confess "backend-emission matrix Git revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my ($status_ok, $status) = _capture_command(
        'git', '-C', $repo_root, 'status', '--porcelain=v1',
        '--untracked-files=normal',
    );
    confess "cannot derive backend-emission matrix Git state\n"
        unless $status_ok;
    confess "backend-emission matrix requires a clean Git revision\n"
        if length($status);
    return $revision;
}

sub _require_unchanged_clean_revision($repo_root, $expected) {
    my $actual = _require_clean_revision($repo_root);
    confess "backend-emission matrix Git revision changed during capture\n"
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
    confess "backend-emission matrix path must be repository-relative\n"
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

sub _json_boolean($value, $label) {
    confess "$label must be a JSON boolean\n"
        unless blessed($value)
            && ($value->isa('JSON::PP::Boolean')
                || $value->isa('JSON::PP::BooleanBase'));
    return $value ? JSON::PP::true : JSON::PP::false;
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
