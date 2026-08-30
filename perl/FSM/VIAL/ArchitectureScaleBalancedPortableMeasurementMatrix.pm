package FSM::VIAL::ArchitectureScaleBalancedPortableMeasurementMatrix;

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

use FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_balanced_portable_matrix.v1';
my $COMPLETE_SCHEMA =
    'fsmgen.vial_architecture_scale_balanced_portable_complete_matrix.v1';
my $PROFILE_PUBLICATION_SCHEMA =
    'fsmgen.vial_architecture_scale_balanced_portable_profile_publication.v1';
my $PROFILE_WORKER_SCHEMA =
    'fsmgen.vial_architecture_scale_balanced_portable_profile_worker.v1';
my $FAMILY = 'balanced_portable_v1';
my $PUBLICATION_BASE = '.artifacts/qualification/vial-scale/v1';
my $STAGING_BASE =
    '.artifacts/tmp/vial-scale/balanced-portable-matrix-publication';
my $REPORT_FILENAME = 'measurement-publication.json';
my $MATRIX_FILENAME = 'matrix.json';
my $COMPLETE_FILENAME = 'complete-matrix.json';

# The newest immutable measurement publishers already enforce a 64-MiB
# storage envelope.  Retain that conservative containment envelope until the
# first guarded balanced capture records the real canonical size.  Compact
# child IPC remains independently bounded to 64 KiB, so full raw reports can
# never cross the coordinator pipe.  Neither limit is a performance, capacity,
# or support claim.
my $PROVISIONAL_PUBLICATION_BYTES = 67_108_864;
my $MEASURED_RECORDS = 3;
my $BINDING_COUNT = 2_048;
my $OPERATION_COUNT = 1_024;
my $EMISSION_ARTIFACT_COUNT = 8;
my $SOURCE_ARTIFACT_COUNT = 3;
my $SOURCE_BYTES = 503_279;
my $SOURCE_MAP_ENTRIES = 3_605;
my $MAX_PUBLICATION_BYTES = $PROVISIONAL_PUBLICATION_BYTES;
my $MAX_PROFILE_WORKER_RESULT_BYTES = 65_536;
my $MAX_PROFILE_WORKER_ERROR_BYTES = 4_096;
my $ADAPTER = 'FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement';
my $PRODUCER = 'FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement';

my %MODE_BY_LEVEL = (
    gate_candidate_v1 => 'gate_measurement',
);
my %SAMPLES_BY_MODE = (
    gate_measurement => $MEASURED_RECORDS,
);
my @INVENTORY_KEYS = qw(
    profile_id family backend_profile level mode
);
my @PROFILE_PUBLICATION_KEYS = qw(
    schema schema_version publication_identity capture_identity report
);
my @PROFILE_KEYS = qw(
    profile_id family backend_profile level mode primary_axis report_identity
    workload_identity authority_identity composition_identity
    emission_identity controller_applicable measurement_applicable
    execution_applicable execution_reason validation_identity
    measurement_identities measured_samples excluded_measurement_identities
    excluded_samples cleanup_records cleanup_removed residue_count
    binding_count operation_count emission_artifact_count
    source_artifact_count source_bytes source_map_entries outcome diagnostics
    artifact_relative_path artifact_sha256 artifact_bytes
);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @DOMINANCE_KEYS = qw(
    controller_applicable_profiles controller_inapplicable_profiles
    measurement_applicable_profiles measurement_inapplicable_profiles
    execution_applicable_profiles execution_inapplicable_profiles
    validation_records raw_measurement_records excluded_measurement_records
    cleaned_records residue_records diagnostic_counts
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
        mutable_measurement_publication retry_after_failure external_execution
        cross_backend_parity performance_budget architecture_capacity
        reached_record_boundary backend_support public_api_change
        revision_1_public_bridge
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
        provisional_publication_bytes => $PROVISIONAL_PUBLICATION_BYTES,
        measured_records => $MEASURED_RECORDS,
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
        "vial-scale-balanced-portable-matrix: complete matrix $publication->{status}\n";
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
            "vial-scale-balanced-portable-matrix: family matrix resumed\n";
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
            'vial-scale-balanced-portable-matrix:',
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
        "vial-scale-balanced-portable-matrix: family matrix $publication->{status}\n";
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
    confess "balanced-portable family matrix publication is not canonical\n"
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
    confess "balanced-portable complete matrix publication is not canonical\n"
        unless _canonical_json($actual) eq _canonical_json($expected);
    return $actual;
}

sub _inventory() {
    my $authority = $PRODUCER->member_authority;
    confess "balanced-portable producer authority is invalid\n"
        unless ref($authority) eq 'HASH' && !blessed($authority);
    confess "balanced-portable producer authority changed\n"
        unless ($authority->{family} // '') eq $FAMILY
            && ($authority->{backend_profile} // '')
                eq 'sv_portable_verilator'
            && ($authority->{level} // '') eq 'gate_candidate_v1'
            && ($authority->{primary_axis} // '') eq 'interaction_profile';
    my $mode = $MODE_BY_LEVEL{$authority->{level}};
    confess "balanced-portable producer introduced an unrouted level\n"
        unless defined $mode;
    return [{
        profile_id => _profile_id(
            $authority->{backend_profile}, $authority->{level},
        ),
        family => $authority->{family},
        backend_profile => $authority->{backend_profile},
        level => $authority->{level},
        mode => $mode,
    }];
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
        confess "balanced-portable profile publication is absent\n"
            unless $operation eq 'capture_or_resume';
        my $request = {repository_root => $repo_root};
        my $report = _produce_profile_report($profile, $request);
        $ADAPTER->validate_report({
            repository_root => $repo_root,
            report => $report,
        });
        _require_acceptable_profile_report($profile, $report);
        $common_identity = _report_common_identity(
            $report, $raw->{expected_common_identity},
        );
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

sub _produce_profile_report($profile, $request) {
    my $mode = ref($profile) eq 'HASH' ? $profile->{mode} : undef;
    return $ADAPTER->measure_member($request)
        if defined($mode) && $mode eq 'gate_measurement';
    confess "balanced-portable profile mode has no producer route\n";
}

sub _run_isolated_profile_worker($raw) {
    _exact_keys(
        $raw, [qw(profile_id worker validate_payload)],
        'isolated balanced-portable profile worker invocation',
    );
    confess "isolated balanced-portable profile worker ID is invalid\n"
        unless _safe_token($raw->{profile_id});
    confess "isolated balanced-portable profile worker callback is invalid\n"
        unless ref($raw->{worker}) eq 'CODE'
            && ref($raw->{validate_payload}) eq 'CODE';
    pipe(my $reader, my $writer)
        or confess "cannot create balanced-portable worker pipe\n";
    my $descriptor_ok = eval {
        _set_close_on_exec($reader, 'reader');
        _set_close_on_exec($writer, 'writer');
        my $flags = fcntl($reader, F_GETFL, 0);
        confess "cannot inspect balanced-portable worker reader flags\n"
            unless defined $flags;
        confess "cannot make balanced-portable worker reader nonblocking\n"
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
        confess "cannot fork balanced-portable profile worker\n";
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
                'isolated balanced-portable profile worker result exceeded the bounded envelope',
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
            $read_error = 'cannot wait for balanced-portable profile worker';
            $done = 1;
        }
        else {
            sleep(0.01);
        }
    }
    $read_error //= _drain_profile_worker_pipe($reader, \$buffer);
    close $reader
        or $read_error //= 'cannot close balanced-portable worker reader';
    confess "$read_error\n" if defined $read_error;
    my $signal = defined($wait_status) && WIFSIGNALED($wait_status)
        ? WTERMSIG($wait_status) : 0;
    confess "isolated balanced-portable profile worker '$raw->{profile_id}' terminated by signal $signal\n"
        if $signal;
    my ($envelope, $decode_error) =
        _decode_profile_worker_envelope($buffer);
    my $exit_code = defined($wait_status) && WIFEXITED($wait_status)
        ? WEXITSTATUS($wait_status) : undef;
    if (defined $decode_error) {
        my $status = defined($exit_code)
            ? " with exit status $exit_code" : '';
        confess "isolated balanced-portable profile worker '$raw->{profile_id}' $decode_error$status\n";
    }
    confess "isolated balanced-portable profile worker '$raw->{profile_id}' failed: $envelope->{error}\n"
        unless $envelope->{ok};
    confess "isolated balanced-portable profile worker '$raw->{profile_id}' exited with status $exit_code\n"
        unless defined($exit_code) && $exit_code == 0;
    my $payload_ok = eval {
        $raw->{validate_payload}->($envelope->{payload});
        1;
    };
    confess "isolated balanced-portable profile worker '$raw->{profile_id}' payload is invalid: $@"
        unless $payload_ok;
    return _clone($envelope->{payload});
}

sub _validate_profile_worker_payload($payload, $raw) {
    _exact_keys(
        $payload, \@PROFILE_WORKER_PAYLOAD_KEYS,
        'isolated balanced-portable profile worker payload',
    );
    confess "balanced-portable worker operation changed\n"
        unless ($payload->{operation} // '') eq $raw->{operation};
    confess "balanced-portable worker profile changed\n"
        unless ($payload->{profile_id} // '')
            eq $raw->{profile}{profile_id};
    my %allowed = $raw->{operation} eq 'capture_or_resume'
        ? map { $_ => 1 } qw(published recovered unchanged resumed)
        : (loaded => 1);
    confess "balanced-portable worker publication status is invalid\n"
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
    $error = 'isolated balanced-portable profile worker failed without an exception'
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
            'isolated balanced-portable worker envelope',
        );
        confess "balanced-portable worker envelope schema is invalid\n"
            unless ($decoded->{schema} // '') eq $PROFILE_WORKER_SCHEMA
                && ($decoded->{schema_version} // 0) == 1;
        _json_boolean($decoded->{ok}, 'balanced-portable worker ok');
        if ($decoded->{ok}) {
            confess "successful balanced-portable worker retained an error\n"
                if defined $decoded->{error};
        }
        else {
            confess "failed balanced-portable worker retained a payload\n"
                if defined $decoded->{payload};
            confess "failed balanced-portable worker error is invalid\n"
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
    confess "cannot inspect balanced-portable worker $label descriptor\n"
        unless defined $flags;
    confess "cannot protect balanced-portable worker $label descriptor\n"
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
        return 'cannot read balanced-portable profile worker result';
    }
}

sub _profile_publication($common, $report) {
    _validate_common_identity($common);
    _require_common_match($common, _report_common_identity($report, $common));
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
        'balanced-portable profile publication',
    );
    confess "balanced-portable profile publication schema is invalid\n"
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
        _report_common_identity(
            $publication->{report}, $publication->{capture_identity},
        ),
    );
    confess "balanced-portable profile publication identity changed\n"
        unless ($publication->{publication_identity} // '')
            eq _profile_publication_identity($publication);
}

sub _profile_entry($profile, $report, $publication) {
    _require_acceptable_profile_report($profile, $report);
    my $emission = $report->{canonical_emission}{artifact_oracle};
    return {
        profile_id => $profile->{profile_id},
        family => $profile->{family},
        backend_profile => $profile->{backend_profile},
        level => $profile->{level},
        mode => $profile->{mode},
        primary_axis => $report->{primary_axis},
        report_identity => $report->{report_identity},
        workload_identity => $report->{workload_identity},
        authority_identity =>
            $report->{member_authority}{authority_identity},
        composition_identity =>
            $report->{canonical_composition}{report_identity},
        emission_identity =>
            $report->{canonical_emission}{report_identity},
        controller_applicable =>
            _clone($report->{controller_applicability}{applicable}),
        measurement_applicable =>
            _clone($report->{measurement_applicability}{applicable}),
        execution_applicable =>
            _clone($report->{execution_applicability}{applicable}),
        execution_reason => $report->{execution_applicability}{reason},
        validation_identity =>
            $report->{validation_record}{measurement_identity},
        measurement_identities => [map {
            $_->{measurement_identity}
        } @{$report->{measurement_records}}],
        measured_samples => scalar(@{$report->{measurement_records}}),
        excluded_measurement_identities => [map {
            $_->{measurement_identity}
        } @{$report->{sample_exclusions}}],
        excluded_samples => scalar(@{$report->{sample_exclusions}}),
        cleanup_records => $report->{cleanup}{records_total},
        cleanup_removed =>
            _clone($report->{cleanup}{ephemeral_removed}),
        residue_count => scalar(@{$report->{cleanup}{residue}}),
        binding_count => $emission->{mapped_binding_count},
        operation_count => $emission->{mapped_operation_count},
        emission_artifact_count => $emission->{artifact_count},
        source_artifact_count => $emission->{source_artifact_count},
        source_bytes => $emission->{source_bytes},
        source_map_entries => $emission->{source_map_entries},
        outcome => $report->{outcome},
        diagnostics => _clone($report->{diagnostics}),
        artifact_relative_path => $publication->{artifact_relative_path},
        artifact_sha256 => $publication->{sha256},
        artifact_bytes => $publication->{bytes},
    };
}

sub _require_acceptable_profile_report($profile, $report) {
    for my $key (qw(family backend_profile level mode)) {
        confess "balanced-portable matrix report $key changed\n"
            unless ($report->{$key} // '') eq ($profile->{$key} // '');
    }
    my $measured = scalar @{$report->{measurement_records}};
    my $excluded = scalar @{$report->{sample_exclusions}};
    confess "balanced-portable matrix cannot seal an excluded sample\n"
        if $excluded;
    confess "balanced-portable matrix controller became inapplicable\n"
        unless $report->{controller_applicability}{applicable};
    confess "balanced-portable matrix correctness validation did not accept\n"
        unless ($report->{validation_record}{outcome} // '') eq 'accepted';
    confess "balanced-portable measured profile is measurement-inapplicable\n"
        unless $report->{measurement_applicability}{applicable}
            && !defined($report->{measurement_applicability}{reason});
    confess "balanced-portable external execution became applicable\n"
        unless !$report->{execution_applicability}{applicable}
            && ($report->{execution_applicability}{reason} // '')
                eq 'no_qualified_private_revision_2_runtime_route';
    confess "balanced-portable measured profile sample count changed\n"
        unless $measured == $SAMPLES_BY_MODE{$profile->{mode}};
    confess "balanced-portable measured profile outcome changed\n"
        unless ($report->{outcome} // '') eq 'accepted';
    for my $record (
        $report->{validation_record}, @{$report->{measurement_records}},
    ) {
        confess "balanced-portable matrix record did not accept\n"
            unless ($record->{outcome} // '') eq 'accepted';
    }
    my $emission = $report->{canonical_emission}{artifact_oracle};
    confess "balanced-portable structural evidence changed\n"
        unless $emission->{mapped_binding_count} == $BINDING_COUNT
            && $emission->{mapped_operation_count} == $OPERATION_COUNT
            && $emission->{artifact_count} == $EMISSION_ARTIFACT_COUNT
            && $emission->{source_artifact_count} == $SOURCE_ARTIFACT_COUNT
            && $emission->{source_bytes} == $SOURCE_BYTES
            && $emission->{source_map_entries} == $SOURCE_MAP_ENTRIES;
    confess "balanced-portable matrix cleanup is incomplete\n"
        unless $report->{cleanup}{ephemeral_removed}
            && !@{$report->{cleanup}{residue}}
            && $report->{cleanup}{records_total} == 1 + $MEASURED_RECORDS;
}

sub _validate_profile_entry($entry, $profile) {
    _exact_keys(
        $entry, \@PROFILE_KEYS, 'balanced-portable matrix profile entry',
    );
    for my $key (qw(profile_id family backend_profile level mode)) {
        confess "balanced-portable profile entry $key changed\n"
            unless ($entry->{$key} // '') eq ($profile->{$key} // '');
    }
    for my $key (qw(
        controller_applicable measurement_applicable execution_applicable
        cleanup_removed
    )) {
        _json_boolean($entry->{$key}, "balanced-portable entry $key");
    }
    for my $key (qw(
        primary_axis report_identity workload_identity authority_identity
        composition_identity emission_identity validation_identity
    )) {
        confess "balanced-portable entry $key is invalid\n"
            unless defined($entry->{$key}) && !ref($entry->{$key})
                && length($entry->{$key});
    }
    confess "balanced-portable entry primary axis changed\n"
        unless $entry->{primary_axis} eq 'interaction_profile';
    confess "balanced-portable entry identity arrays are invalid\n"
        unless ref($entry->{measurement_identities}) eq 'ARRAY'
            && ref($entry->{excluded_measurement_identities}) eq 'ARRAY';
    for my $identity (
        @{$entry->{measurement_identities}},
        @{$entry->{excluded_measurement_identities}},
    ) {
        confess "balanced-portable entry measurement identity is invalid\n"
            unless defined($identity) && !ref($identity)
                && length($identity);
    }
    my %identity;
    for my $value (
        $entry->{validation_identity},
        @{$entry->{measurement_identities}},
        @{$entry->{excluded_measurement_identities}},
    ) {
        confess "balanced-portable entry repeated a measurement identity\n"
            if $identity{$value}++;
    }
    confess "balanced-portable entry sample counts are invalid\n"
        unless _nonnegative_integer($entry->{measured_samples})
            && _nonnegative_integer($entry->{excluded_samples})
            && $entry->{measured_samples}
                == @{$entry->{measurement_identities}}
            && $entry->{excluded_samples}
                == @{$entry->{excluded_measurement_identities}}
            && !$entry->{excluded_samples};
    confess "balanced-portable entry cleanup counts are invalid\n"
        unless _nonnegative_integer($entry->{cleanup_records})
            && _nonnegative_integer($entry->{residue_count})
            && !$entry->{residue_count} && $entry->{cleanup_removed};
    confess "balanced-portable entry applicability changed\n"
        unless $entry->{controller_applicable}
            && $entry->{measurement_applicable}
            && !$entry->{execution_applicable}
            && ($entry->{execution_reason} // '')
                eq 'no_qualified_private_revision_2_runtime_route';
    confess "balanced-portable measured entry sample count changed\n"
        unless $entry->{measured_samples}
                == $SAMPLES_BY_MODE{$profile->{mode}}
            && $entry->{cleanup_records} == 1 + $entry->{measured_samples};
    confess "balanced-portable entry structural counts changed\n"
        unless $entry->{binding_count} == $BINDING_COUNT
            && $entry->{operation_count} == $OPERATION_COUNT
            && $entry->{emission_artifact_count} == $EMISSION_ARTIFACT_COUNT
            && $entry->{source_artifact_count} == $SOURCE_ARTIFACT_COUNT
            && $entry->{source_bytes} == $SOURCE_BYTES
            && $entry->{source_map_entries} == $SOURCE_MAP_ENTRIES;
    confess "balanced-portable measured entry outcome changed\n"
        unless ($entry->{outcome} // '') eq 'accepted';
    confess "balanced-portable entry artifact path changed\n"
        unless $entry->{artifact_relative_path} eq join('/',
            $PUBLICATION_BASE, $profile->{profile_id}, $REPORT_FILENAME,
        );
    confess "balanced-portable entry artifact digest is invalid\n"
        unless ($entry->{artifact_sha256} // '') =~ /\A[0-9a-f]{64}\z/;
    confess "balanced-portable entry artifact size is invalid\n"
        unless _nonnegative_integer($entry->{artifact_bytes})
            && $entry->{artifact_bytes} > 0
            && $entry->{artifact_bytes} <= $MAX_PUBLICATION_BYTES;
    confess "balanced-portable entry diagnostics are invalid\n"
        unless ref($entry->{diagnostics}) eq 'ARRAY';
    confess "accepted balanced-portable entry retained diagnostics\n"
        if @{$entry->{diagnostics}};
}

sub _family_manifest($profiles) {
    confess "balanced-portable matrix profile count changed\n"
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
    confess "balanced-portable matrix has no profiles\n" unless @$profiles;
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
        $count{controller_applicable_profiles}++
            if $profile->{controller_applicable};
        $count{controller_inapplicable_profiles}++
            unless $profile->{controller_applicable};
        $count{measurement_applicable_profiles}++
            if $profile->{measurement_applicable};
        $count{measurement_inapplicable_profiles}++
            unless $profile->{measurement_applicable};
        $count{execution_applicable_profiles}++
            if $profile->{execution_applicable};
        $count{execution_inapplicable_profiles}++
            unless $profile->{execution_applicable};
        $count{validation_records}++
            if defined($profile->{validation_identity});
        $count{raw_measurement_records} += $profile->{measured_samples};
        $count{excluded_measurement_records} += $profile->{excluded_samples};
        $count{cleaned_records} += $profile->{cleanup_records};
        $count{residue_records} += $profile->{residue_count};
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

sub _report_common_identity($report, $expected = undef) {
    my @records = grep { defined $_ } (
        $report->{validation_record}, @{$report->{measurement_records}},
    );
    confess "balanced-portable report has no capture identity\n"
        unless @records;
    my $first = _record_common_identity($records[0]);
    for my $record (@records) {
        _require_common_match($first, _record_common_identity($record));
    }
    _require_common_match($expected, $first) if defined $expected;
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
    confess "balanced-portable matrix mixed common identities\n"
        unless defined($expected) && defined($actual)
            && _canonical_json($expected) eq _canonical_json($actual);
}

sub _require_capture_revision($common, $git_revision) {
    confess "balanced-portable matrix capture Git revision changed\n"
        unless defined($git_revision)
            && ($common->{git_revision} // '') eq $git_revision;
    confess "balanced-portable matrix capture is dirty\n"
        if $common->{dirty_state};
}

sub _publish_json($raw) {
    my $encoded = _canonical_json($raw->{value}) . "\n";
    my $encoded_bytes = bytes::length($encoded);
    confess "balanced-portable matrix publication exceeds its calibrated ceiling "
        . "(actual=$encoded_bytes bytes, maximum=$MAX_PUBLICATION_BYTES bytes)\n"
        if $encoded_bytes > $MAX_PUBLICATION_BYTES;
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
        confess "balanced-portable matrix publication collision\n"
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
        confess "balanced-portable matrix staging is not recoverable\n"
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
            confess "cannot recover balanced-portable matrix publication\n";
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
            or confess "cannot create balanced-portable matrix publication\n";
        binmode($fh, ':raw')
            or confess "cannot set balanced-portable publication byte mode\n";
        print {$fh} $encoded
            or confess "cannot write balanced-portable matrix publication\n";
        $fh->flush
            or confess "cannot flush balanced-portable matrix publication\n";
        $fh->sync
            or confess "cannot sync balanced-portable matrix publication\n";
        close $fh
            or confess "cannot close balanced-portable matrix publication\n";
        _ensure_publication_parent(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel),
            $created_publication,
        );
        confess "balanced-portable matrix publication target appeared\n"
            if -e $target_abs || -l $target_abs;
        rename($stage_abs, $target_abs)
            or confess "cannot atomically publish balanced-portable matrix\n";
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
    confess "balanced-portable matrix publication identity changed\n"
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
        or confess "cannot read balanced-portable matrix publication\n";
    local $/;
    my $encoded = <$fh>;
    close $fh
        or confess "cannot close balanced-portable matrix publication\n";
    confess "balanced-portable matrix publication is not newline-terminated\n"
        unless defined($encoded) && $encoded =~ /\n\z/;
    my $value = eval { JSON::PP->new->utf8(1)->decode($encoded) };
    confess "balanced-portable matrix publication JSON is invalid\n" if $@;
    confess "balanced-portable matrix publication JSON is not canonical\n"
        unless _canonical_json($value) . "\n" eq $encoded;
    return ($value, $publication);
}

sub _publication_metadata($raw) {
    confess "balanced-portable publication profile ID is invalid\n"
        unless _safe_token($raw->{profile_id});
    confess "balanced-portable publication filename is invalid\n"
        unless defined($raw->{filename}) && !ref($raw->{filename})
            && $raw->{filename} =~ /\A[a-z][a-z0-9-]*[.]json\z/;
    my $target_rel = join('/',
        $PUBLICATION_BASE, $raw->{profile_id},
    );
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $target_rel,
    );
    confess "balanced-portable publication root is absent\n"
        unless -d $target_abs && !-l $target_abs;
    opendir my $dh, $target_abs
        or confess "cannot inspect balanced-portable publication\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close balanced-portable publication directory\n";
    confess "balanced-portable publication census changed\n"
        unless @entries == 1 && $entries[0] eq $raw->{filename};
    my $artifact_abs = File::Spec->catfile(
        $target_abs, $raw->{filename},
    );
    confess "balanced-portable publication artifact is invalid\n"
        unless -f $artifact_abs && !-l $artifact_abs;
    my @stat = stat($artifact_abs);
    confess "balanced-portable publication crossed repository volume\n"
        unless @stat && $stat[0] == $raw->{root_device};
    confess "balanced-portable publication exceeds its calibrated ceiling "
        . "(actual=$stat[7] bytes, maximum=$MAX_PUBLICATION_BYTES bytes)\n"
        unless $stat[7] > 0 && $stat[7] <= $MAX_PUBLICATION_BYTES;
    open my $fh, '<:raw', $artifact_abs
        or confess "cannot read balanced-portable publication artifact\n";
    local $/;
    my $content = <$fh>;
    close $fh
        or confess "cannot close balanced-portable publication artifact\n";
    confess "balanced-portable publication size changed while reading\n"
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
                confess "balanced-portable staging traverses a symlink\n"
                    if -l $path;
                confess "balanced-portable staging component is not a directory\n"
                    unless -d $path;
                confess "balanced-portable staging root already exists\n"
                    if $index == $#parts;
            }
            else {
                mkdir($path)
                    or confess "cannot create balanced-portable staging directory\n";
                push @created, $path;
            }
            my @stat = stat($path);
            confess "balanced-portable staging crossed repository volume\n"
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
        confess "balanced-portable staging cleanup target is invalid\n"
            unless -d $stage_abs && !-l $stage_abs;
        my $errors;
        remove_tree($stage_abs, {error => \$errors});
        confess "cannot remove balanced-portable publication staging\n"
            if $errors && @$errors;
    }
    confess "balanced-portable publication staging remains after cleanup\n"
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
            confess "balanced-portable destination traverses a symlink\n"
                if -l $path;
            $existing = $path;
        }
    }
    my @stat = stat($existing);
    confess "balanced-portable destination filesystem identity is unavailable\n"
        unless @stat;
    confess "balanced-portable destination crossed repository volume\n"
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
            confess "balanced-portable publication parent traverses a symlink\n"
                if -l $path;
            confess "balanced-portable publication parent is not a directory\n"
                unless -d $path;
        }
        else {
            mkdir($path)
                or confess "cannot create balanced-portable publication parent\n";
            push @$created, $path;
        }
        my @stat = stat($path);
        confess "balanced-portable publication parent crossed repository volume\n"
            unless @stat && $stat[0] == $root_device;
    }
    confess "balanced-portable publication parent mismatch\n"
        unless $path eq $parent;
}

sub _validate_family_manifest_shape($manifest) {
    _exact_keys(
        $manifest, \@MATRIX_KEYS, 'balanced-portable family matrix',
    );
    confess "balanced-portable family matrix schema is invalid\n"
        unless ($manifest->{schema} // '') eq $SCHEMA
            && ($manifest->{schema_version} // 0) == 1;
    confess "balanced-portable family matrix family changed\n"
        unless ($manifest->{family} // '') eq $FAMILY;
    confess "balanced-portable family matrix profiles are invalid\n"
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
    confess "balanced-portable family matrix outcome changed\n"
        unless ($manifest->{outcome} // '') eq 'accepted';
    confess "balanced-portable family matrix diagnostics changed\n"
        unless ref($manifest->{diagnostics}) eq 'ARRAY'
            && !@{$manifest->{diagnostics}};
    confess "balanced-portable family matrix nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "balanced-portable family matrix identity changed\n"
        unless ($manifest->{matrix_identity} // '')
            eq _matrix_identity($manifest);
}

sub _validate_complete_manifest_shape($manifest) {
    _exact_keys(
        $manifest, \@COMPLETE_KEYS, 'balanced-portable complete matrix',
    );
    confess "balanced-portable complete matrix schema is invalid\n"
        unless ($manifest->{schema} // '') eq $COMPLETE_SCHEMA
            && ($manifest->{schema_version} // 0) == 1;
    _exact_keys(
        $manifest->{family_manifest}, \@FAMILY_MANIFEST_KEYS,
        'balanced-portable complete family manifest',
    );
    confess "balanced-portable complete matrix family changed\n"
        unless $manifest->{family_manifest}{family} eq $FAMILY;
    confess "balanced-portable complete family identity is invalid\n"
        unless ($manifest->{family_manifest}{matrix_identity} // '')
                =~ /\Abalanced-portable-matrix\/[0-9a-f]{64}\z/
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
    confess "balanced-portable complete matrix profile count changed\n"
        unless $manifest->{total_profile_count} == @{_inventory()}
            && $manifest->{family_manifest}{profile_count}
                == $manifest->{total_profile_count};
    _validate_common_identity($manifest->{common_identity});
    _validate_dominance($manifest->{dominance});
    confess "balanced-portable complete matrix outcome changed\n"
        unless ($manifest->{outcome} // '') eq 'accepted';
    confess "balanced-portable complete matrix diagnostics changed\n"
        unless ref($manifest->{diagnostics}) eq 'ARRAY'
            && !@{$manifest->{diagnostics}};
    confess "balanced-portable complete matrix nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "balanced-portable complete matrix identity changed\n"
        unless ($manifest->{matrix_identity} // '')
            eq _matrix_identity($manifest);
}

sub _validate_common_identity($common) {
    _exact_keys(
        $common, \@COMMON_KEYS,
        'balanced-portable matrix common identity',
    );
    confess "balanced-portable matrix Git revision is invalid\n"
        unless ($common->{git_revision} // '') =~ /\A[0-9a-f]{40}\z/;
    confess "balanced-portable matrix common identity is dirty\n"
        if $common->{dirty_state};
    confess "balanced-portable matrix host/tool/guard identity is invalid\n"
        unless ref($common->{host_profile}) eq 'HASH'
            && ref($common->{tool_profile}) eq 'HASH'
            && ref($common->{resource_guard}) eq 'HASH'
            && $common->{resource_guard}{active};
}

sub _validate_dominance($dominance) {
    _exact_keys(
        $dominance, \@DOMINANCE_KEYS,
        'balanced-portable matrix dominance',
    );
    for my $key (grep { $_ ne 'diagnostic_counts' } @DOMINANCE_KEYS) {
        confess "balanced-portable matrix dominance count is invalid\n"
            unless _nonnegative_integer($dominance->{$key});
    }
    confess "balanced-portable matrix diagnostic counts are invalid\n"
        unless ref($dominance->{diagnostic_counts}) eq 'ARRAY';
    for my $item (@{$dominance->{diagnostic_counts}}) {
        _exact_keys(
            $item, \@DIAGNOSTIC_COUNT_KEYS,
            'balanced-portable matrix diagnostic count',
        );
        confess "balanced-portable matrix diagnostic count is invalid\n"
            unless ($item->{code} // '') =~ /\A[A-Z][A-Z0-9_]*\z/
                && ($item->{semantic_path} // '') =~ m{\A/}
                && _nonnegative_integer($item->{profiles})
                && $item->{profiles} > 0;
    }
    my $profiles = @{_inventory()};
    confess "balanced-portable dominance controller partition changed\n"
        unless $dominance->{controller_applicable_profiles}
                + $dominance->{controller_inapplicable_profiles}
            == $profiles;
    confess "balanced-portable dominance applicability partition changed\n"
        unless $dominance->{measurement_applicable_profiles}
                + $dominance->{measurement_inapplicable_profiles}
            == $profiles;
    confess "balanced-portable dominance execution partition changed\n"
        unless $dominance->{execution_applicable_profiles}
                + $dominance->{execution_inapplicable_profiles}
            == $profiles;
    confess "balanced-portable dominance retained excluded evidence\n"
        if $dominance->{excluded_measurement_records};
    confess "balanced-portable dominance cleanup changed\n"
        unless !$dominance->{residue_records}
            && $dominance->{cleaned_records}
                == $dominance->{validation_records}
                    + $dominance->{raw_measurement_records};
    confess "balanced-portable dominance selected profile partition changed\n"
        unless $profiles == 1
            && $dominance->{controller_applicable_profiles} == 1
            && $dominance->{measurement_applicable_profiles} == 1
            && $dominance->{execution_inapplicable_profiles} == 1
            && $dominance->{validation_records} == 1
            && $dominance->{raw_measurement_records} == $MEASURED_RECORDS;
}

sub _profile_publication_identity($publication) {
    my $projection = _clone($publication);
    $projection->{publication_identity} = undef;
    return 'balanced-portable-profile-publication/'
        . sha256_hex(_canonical_json($projection));
}

sub _matrix_identity($manifest) {
    my $projection = _clone($manifest);
    $projection->{matrix_identity} = undef;
    return 'balanced-portable-matrix/'
        . sha256_hex(_canonical_json($projection));
}

sub _profile_id($profile, $level) {
    return 'balanced-portable-profile-'
        . sha256_hex(_canonical_json({
            backend_profile => $profile,
            level => $level,
        }));
}

sub _matrix_profile_id() {
    return 'balanced-portable-matrix-v1';
}

sub _complete_profile_id() {
    return 'balanced-portable-complete-matrix-v1';
}

sub _require_active_guard() {
    confess "balanced-portable matrix requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "balanced-portable matrix guard thresholds are invalid\n"
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
    confess "cannot derive balanced-portable matrix Git revision\n"
        unless $revision_ok;
    $revision =~ s/\s+\z//;
    confess "balanced-portable matrix Git revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my ($status_ok, $status) = _capture_command(
        'git', '-C', $repo_root, 'status', '--porcelain=v1',
        '--untracked-files=normal',
    );
    confess "cannot derive balanced-portable matrix Git state\n"
        unless $status_ok;
    confess "balanced-portable matrix requires a clean Git revision\n"
        if length($status);
    return $revision;
}

sub _require_unchanged_clean_revision($repo_root, $expected) {
    my $actual = _require_clean_revision($repo_root);
    confess "balanced-portable matrix Git revision changed during capture\n"
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
    confess "balanced-portable matrix path must be repository-relative\n"
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
