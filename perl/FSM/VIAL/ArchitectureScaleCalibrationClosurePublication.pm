package FSM::VIAL::ArchitectureScaleCalibrationClosurePublication;

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

use FSM::VIAL::ArchitectureScaleCalibrationClosure;

my $CLOSURE = 'FSM::VIAL::ArchitectureScaleCalibrationClosure';
my $SCHEMA =
    'fsmgen.vial_architecture_scale_calibration_closure_publication.v1';
my $WORKER_SCHEMA =
    'fsmgen.vial_architecture_scale_calibration_closure_worker.v1';
my $CLOSURE_SCHEMA =
    'fsmgen.vial_architecture_scale_calibration_closure.v1';
my $PUBLICATION_BASE = '.artifacts/qualification/vial-scale/v1';
my $STAGING_BASE =
    '.artifacts/tmp/vial-scale/calibration-closure-publication';
my $PUBLICATION_ID = 'calibration-closure-v1';
my $REPORT_FILENAME = 'calibration-closure.json';
my $MANIFEST_FILENAME = 'closure-manifest.json';
my $MAX_REPORT_BYTES = 2_097_152;
my $MAX_MANIFEST_BYTES = 65_536;
my $MAX_WORKER_RESULT_BYTES = 65_536;
my $MAX_WORKER_ERROR_BYTES = 4_096;

my @MANIFEST_KEYS = qw(
    schema schema_version publication_identity closure_identity
    publisher_revision report_artifact summary candidate_formula outcome
    diagnostics explicit_nonclaims
);
my @REPORT_ARTIFACT_KEYS = qw(artifact_relative_path sha256 bytes);
my @SUMMARY_KEYS = qw(
    authority_count family_count profile_count raw_measurement_records
    excluded_measurement_records candidate_profiles noncandidate_profiles
);
my @REPORT_KEYS = @{$CLOSURE->report_keys};
my @AUTHORITY_KEYS = qw(
    authority matrix_class adapter_class matrix_identity profile_count
    applicability_identity common_identity complete_artifact family_artifacts
    dominance outcome diagnostics explicit_nonclaims
);
my @FAMILY_ARTIFACT_KEYS = qw(
    family matrix_identity profile_count artifact
);
my @ARTIFACT_KEYS = qw(relative_path sha256 bytes);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @PROFILE_KEYS = qw(
    authority ordinal coordinates matrix_profile raw_evidence
    applicability_identity measurement_applicability validation_identity
    raw_measurement_identities sample_exclusions accepted_run_totals
    aggregate_statistics stage_statistics cost_statistics candidate_budget
    dominance cleanup explicit_nonclaims
);
my @RUN_TOTAL_KEYS = qw(
    measurement_identity wall_time_ns cpu_time_ns peak_tree_rss_bytes
);
my @STATISTIC_KEYS = qw(
    sample_count minimum median maximum median_absolute_deviation
);
my @AGGREGATE_KEYS = qw(
    wall_time_ns cpu_time_ns peak_tree_rss_bytes
);
my @COST_CLASSES = qw(fsmgen external_tool artifact);
my @CANDIDATE_KEYS = qw(
    status formula_authority wall_time_ns cpu_time_ns peak_tree_rss_bytes
);
my @WORKER_ENVELOPE_KEYS = qw(
    schema schema_version ok payload error
);
my @WORKER_PAYLOAD_KEYS = qw(
    operation publication_status manifest
);
my @AUTHORITIES = qw(
    semantic_bridge execution_checking backend_emission portable_runtime
    portable_vhdl_runtime osvvm_runtime balanced_portable
);
my @NONCLAIMS = @{$CLOSURE->explicit_nonclaims};
my $CANDIDATE_FORMULA = {
    authority => 'decision-0056',
    status => 'candidate_only',
    wall_time_ns => {
        floor => 2_000_000_000,
        multiplier_numerator => 3,
        multiplier_denominator => 2,
        rounding_quantum => 1_000_000,
    },
    cpu_time_ns => {
        floor => 2_000_000_000,
        multiplier_numerator => 3,
        multiplier_denominator => 2,
        rounding_quantum => 1_000_000,
    },
    peak_tree_rss_bytes => {
        floor => 268_435_456,
        multiplier_numerator => 5,
        multiplier_denominator => 4,
        rounding_quantum => 16_777_216,
    },
};
my $EXPECTED_SUMMARY = {
    authority_count => 7,
    family_count => 9,
    profile_count => 216,
    raw_measurement_records => 356,
    excluded_measurement_records => 0,
    candidate_profiles => 92,
    noncandidate_profiles => 124,
};

sub manifest_keys($class) {
    _exact_invocant($class, 'manifest_keys');
    return [@MANIFEST_KEYS];
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub publication_limits($class) {
    _exact_invocant($class, 'publication_limits');
    return {
        maximum_report_bytes => $MAX_REPORT_BYTES,
        maximum_manifest_bytes => $MAX_MANIFEST_BYTES,
        maximum_worker_result_bytes => $MAX_WORKER_RESULT_BYTES,
        maximum_worker_error_bytes => $MAX_WORKER_ERROR_BYTES,
    };
}

sub capture_all($class, @args) {
    _exact_invocant($class, 'capture_all');
    my $raw = _request('capture_all', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    my $git_revision = _require_clean_revision($repo_root);

    if (_publication_exists($repo_root)) {
        my $loaded = _run_publication_worker({
            repository_root => $repo_root,
            root_device => $root_device,
            operation => 'validate_publication',
            publisher_revision => undef,
        });
        _require_capture_revision(
            $loaded->{manifest}{publisher_revision}, $git_revision,
        );
        return _clone($loaded->{manifest});
    }

    my $captured = _run_publication_worker({
        repository_root => $repo_root,
        root_device => $root_device,
        operation => 'capture_publication',
        publisher_revision => $git_revision,
    });
    _require_unchanged_clean_revision($repo_root, $git_revision);
    return _clone($captured->{manifest});
}

sub validate_complete_publication($class, @args) {
    _exact_invocant($class, 'validate_complete_publication');
    my $raw = _request(
        'validate_complete_publication', \@args, [qw(repository_root)],
    );
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    my $loaded = _run_publication_worker({
        repository_root => $repo_root,
        root_device => $root_device,
        operation => 'validate_publication',
        publisher_revision => undef,
    });
    return _clone($loaded->{manifest});
}

sub _run_publication_worker($raw) {
    return _run_isolated_worker({
        operation => $raw->{operation},
        worker => sub { _publication_worker_payload($raw) },
        validate_payload => sub {
            _validate_worker_payload($_[0], $raw->{operation});
        },
    });
}

sub _publication_worker_payload($raw) {
    if ($raw->{operation} eq 'capture_publication') {
        confess "calibration closure publication appeared before capture\n"
            if _publication_exists($raw->{repository_root});
        my $report = $CLOSURE->derive({
            repository_root => $raw->{repository_root},
        });
        _validate_sealed_report($report);
        my $manifest = _publication_manifest(
            $report, $raw->{publisher_revision},
        );
        _require_unchanged_clean_revision(
            $raw->{repository_root}, $raw->{publisher_revision},
        );
        my $published = _publish_file_set({
            repository_root => $raw->{repository_root},
            root_device => $raw->{root_device},
            publication_id => $PUBLICATION_ID,
            report_bytes => _canonical_json($report) . "\n",
            manifest_bytes => _canonical_json($manifest) . "\n",
        });
        my ($loaded_report, $loaded_manifest) = _load_publication(
            $raw->{repository_root}, $raw->{root_device},
        );
        confess "captured calibration report changed during publication\n"
            unless _canonical_json($loaded_report)
                eq _canonical_json($report);
        confess "captured calibration manifest changed during publication\n"
            unless _canonical_json($loaded_manifest)
                eq _canonical_json($manifest);
        return {
            operation => $raw->{operation},
            publication_status => $published->{status},
            manifest => $loaded_manifest,
        };
    }
    confess "unknown calibration publication worker operation\n"
        unless $raw->{operation} eq 'validate_publication';
    my (undef, $manifest) = _load_publication(
        $raw->{repository_root}, $raw->{root_device},
    );
    return {
        operation => $raw->{operation},
        publication_status => 'loaded',
        manifest => $manifest,
    };
}

sub _run_isolated_worker($raw) {
    _exact_keys(
        $raw, [qw(operation worker validate_payload)],
        'isolated calibration closure worker invocation',
    );
    confess "isolated calibration closure worker operation is invalid\n"
        unless _safe_token($raw->{operation});
    confess "isolated calibration closure worker callback is invalid\n"
        unless ref($raw->{worker}) eq 'CODE'
            && ref($raw->{validate_payload}) eq 'CODE';
    pipe(my $reader, my $writer)
        or confess "cannot create calibration closure worker pipe\n";
    my $descriptor_ok = eval {
        _set_close_on_exec($reader, 'reader');
        _set_close_on_exec($writer, 'writer');
        my $flags = fcntl($reader, F_GETFL, 0);
        confess "cannot inspect calibration closure worker reader flags\n"
            unless defined $flags;
        confess "cannot make calibration closure worker reader nonblocking\n"
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
        confess "cannot fork calibration closure worker\n";
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
            ? _worker_failure_envelope($worker_error)
            : {
                schema => $WORKER_SCHEMA,
                schema_version => 1,
                ok => JSON::PP::true,
                payload => $payload,
                error => undef,
            };
        my $encoded = eval { _canonical_json($envelope) };
        my $exit_code = defined($worker_error) ? 70 : 0;
        if (!defined($encoded)
                || bytes::length($encoded) > $MAX_WORKER_RESULT_BYTES) {
            $envelope = _worker_failure_envelope(
                'isolated calibration closure worker result exceeded the bounded envelope',
            );
            $encoded = _canonical_json($envelope);
            $exit_code = 75;
        }
        my $written = _write_worker_result($writer, $encoded);
        close $writer;
        _exit($written ? $exit_code : 74);
    }
    close $writer;
    my ($buffer, $read_error, $wait_status, $done) =
        ('', undef, undef, 0);
    while (!$done) {
        $read_error //= _drain_worker_pipe($reader, \$buffer);
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
            $read_error = 'cannot wait for calibration closure worker';
            $done = 1;
        }
        else {
            sleep(0.01);
        }
    }
    $read_error //= _drain_worker_pipe($reader, \$buffer);
    close $reader
        or $read_error //= 'cannot close calibration closure worker reader';
    confess "$read_error\n" if defined $read_error;
    my $signal = defined($wait_status) && WIFSIGNALED($wait_status)
        ? WTERMSIG($wait_status) : 0;
    confess "isolated calibration closure worker '$raw->{operation}' terminated by signal $signal\n"
        if $signal;
    my ($envelope, $decode_error) = _decode_worker_envelope($buffer);
    my $exit_code = defined($wait_status) && WIFEXITED($wait_status)
        ? WEXITSTATUS($wait_status) : undef;
    if (defined $decode_error) {
        my $status = defined($exit_code)
            ? " with exit status $exit_code" : '';
        confess "isolated calibration closure worker '$raw->{operation}' $decode_error$status\n";
    }
    confess "isolated calibration closure worker '$raw->{operation}' failed: $envelope->{error}\n"
        unless $envelope->{ok};
    confess "isolated calibration closure worker '$raw->{operation}' exited with status $exit_code\n"
        unless defined($exit_code) && $exit_code == 0;
    my $payload_ok = eval {
        $raw->{validate_payload}->($envelope->{payload});
        1;
    };
    confess "isolated calibration closure worker '$raw->{operation}' payload is invalid: $@"
        unless $payload_ok;
    return _clone($envelope->{payload});
}

sub _validate_worker_payload($payload, $operation) {
    _exact_keys(
        $payload, \@WORKER_PAYLOAD_KEYS,
        'isolated calibration closure worker payload',
    );
    confess "calibration closure worker operation changed\n"
        unless ($payload->{operation} // '') eq $operation;
    my %allowed = $operation eq 'capture_publication'
        ? map { $_ => 1 } qw(published recovered unchanged)
        : (loaded => 1);
    confess "calibration closure worker publication status is invalid\n"
        unless $allowed{$payload->{publication_status} // ''};
    _validate_manifest_shape($payload->{manifest});
}

sub _worker_failure_envelope($error) {
    return {
        schema => $WORKER_SCHEMA,
        schema_version => 1,
        ok => JSON::PP::false,
        payload => undef,
        error => _bounded_worker_error($error),
    };
}

sub _bounded_worker_error($error) {
    $error = 'isolated calibration closure worker failed without an exception'
        unless defined($error) && !ref($error) && length($error);
    $error =~ s/[^\x20-\x7e]+/ /g;
    $error =~ s/\s+/ /g;
    $error =~ s/\A\s+|\s+\z//g;
    return substr($error, 0, $MAX_WORKER_ERROR_BYTES);
}

sub _decode_worker_envelope($buffer) {
    return (undef, 'returned no result') unless length $buffer;
    return (undef, 'result exceeded the bounded envelope')
        if bytes::length($buffer) > $MAX_WORKER_RESULT_BYTES;
    my $decoded = eval { JSON::PP->new->utf8(1)->decode($buffer) };
    return (undef, 'result is not valid JSON') unless defined $decoded;
    return (undef, 'result is not canonical JSON')
        unless _canonical_json($decoded) eq $buffer;
    my $valid = eval {
        _exact_keys(
            $decoded, \@WORKER_ENVELOPE_KEYS,
            'isolated calibration closure worker envelope',
        );
        confess "calibration closure worker envelope schema is invalid\n"
            unless ($decoded->{schema} // '') eq $WORKER_SCHEMA
                && ($decoded->{schema_version} // 0) == 1;
        _json_boolean($decoded->{ok}, 'calibration closure worker ok');
        if ($decoded->{ok}) {
            confess "successful calibration closure worker retained an error\n"
                if defined $decoded->{error};
        }
        else {
            confess "failed calibration closure worker retained a payload\n"
                if defined $decoded->{payload};
            confess "failed calibration closure worker error is invalid\n"
                unless defined($decoded->{error})
                    && !ref($decoded->{error})
                    && length($decoded->{error})
                    && bytes::length($decoded->{error})
                        <= $MAX_WORKER_ERROR_BYTES;
        }
        1;
    };
    return (undef, _bounded_worker_error($@)) unless $valid;
    return ($decoded, undef);
}

sub _set_close_on_exec($handle, $label) {
    my $flags = fcntl($handle, F_GETFD, 0);
    confess "cannot inspect calibration closure worker $label descriptor\n"
        unless defined $flags;
    confess "cannot protect calibration closure worker $label descriptor\n"
        unless fcntl($handle, F_SETFD, $flags | FD_CLOEXEC);
}

sub _write_worker_result($writer, $encoded) {
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

sub _drain_worker_pipe($reader, $buffer_ref) {
    while (1) {
        my $chunk = '';
        my $read = sysread($reader, $chunk, 65_536);
        if (defined $read) {
            return undef if $read == 0;
            my $remaining = $MAX_WORKER_RESULT_BYTES + 1
                - bytes::length($$buffer_ref);
            $$buffer_ref .= substr($chunk, 0, $remaining)
                if $remaining > 0;
            next;
        }
        next if $! == EINTR;
        return undef if $! == EAGAIN || $! == EWOULDBLOCK;
        return 'cannot read calibration closure worker result';
    }
}

sub _publication_manifest($report, $publisher_revision) {
    confess "calibration closure publisher revision is invalid\n"
        unless defined($publisher_revision) && !ref($publisher_revision)
            && $publisher_revision =~ /\A[0-9a-f]{40}\z/;
    for my $key (qw(
        closure_identity summary candidate_formula outcome diagnostics
        explicit_nonclaims
    )) {
        confess "calibration closure report is missing '$key'\n"
            unless ref($report) eq 'HASH' && exists($report->{$key});
    }
    my $report_bytes = _canonical_json($report) . "\n";
    confess "calibration closure report exceeds its storage envelope\n"
        if bytes::length($report_bytes) > $MAX_REPORT_BYTES;
    my $manifest = {
        schema => $SCHEMA,
        schema_version => 1,
        publication_identity => undef,
        closure_identity => $report->{closure_identity},
        publisher_revision => $publisher_revision,
        report_artifact => {
            artifact_relative_path => join('/',
                $PUBLICATION_BASE, $PUBLICATION_ID, $REPORT_FILENAME,
            ),
            sha256 => sha256_hex($report_bytes),
            bytes => bytes::length($report_bytes),
        },
        summary => _clone($report->{summary}),
        candidate_formula => _clone($report->{candidate_formula}),
        outcome => $report->{outcome},
        diagnostics => _clone($report->{diagnostics}),
        explicit_nonclaims => _clone($report->{explicit_nonclaims}),
    };
    $manifest->{publication_identity} = _manifest_identity($manifest);
    _validate_manifest_shape($manifest);
    return $manifest;
}

sub _validate_manifest_shape($manifest) {
    _exact_keys(
        $manifest, \@MANIFEST_KEYS,
        'calibration closure publication manifest',
    );
    confess "calibration closure publication schema is invalid\n"
        unless ($manifest->{schema} // '') eq $SCHEMA
            && ($manifest->{schema_version} // 0) == 1;
    confess "calibration closure publication identity is invalid\n"
        unless ($manifest->{publication_identity} // '')
            =~ /\Acalibration-closure-publication\/[0-9a-f]{64}\z/;
    confess "calibration closure identity is invalid\n"
        unless ($manifest->{closure_identity} // '')
            =~ /\Acalibration-closure\/[0-9a-f]{64}\z/;
    confess "calibration closure publisher revision is invalid\n"
        unless ($manifest->{publisher_revision} // '')
            =~ /\A[0-9a-f]{40}\z/;
    _exact_keys(
        $manifest->{report_artifact}, \@REPORT_ARTIFACT_KEYS,
        'calibration closure report artifact',
    );
    confess "calibration closure report artifact path changed\n"
        unless ($manifest->{report_artifact}{artifact_relative_path} // '')
            eq join('/',
                $PUBLICATION_BASE, $PUBLICATION_ID, $REPORT_FILENAME,
            );
    confess "calibration closure report artifact digest is invalid\n"
        unless ($manifest->{report_artifact}{sha256} // '')
            =~ /\A[0-9a-f]{64}\z/;
    confess "calibration closure report artifact size is invalid\n"
        unless _nonnegative_integer($manifest->{report_artifact}{bytes})
            && $manifest->{report_artifact}{bytes} > 0
            && $manifest->{report_artifact}{bytes} <= $MAX_REPORT_BYTES;
    _validate_summary($manifest->{summary});
    confess "calibration closure candidate formula changed\n"
        unless _canonical_json($manifest->{candidate_formula})
            eq _canonical_json($CANDIDATE_FORMULA);
    confess "calibration closure publication outcome changed\n"
        unless ($manifest->{outcome} // '') eq 'accepted';
    confess "calibration closure publication diagnostics changed\n"
        unless ref($manifest->{diagnostics}) eq 'ARRAY'
            && !@{$manifest->{diagnostics}};
    confess "calibration closure publication nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "calibration closure publication identity changed\n"
        unless $manifest->{publication_identity}
            eq _manifest_identity($manifest);
}

sub _validate_sealed_report($report) {
    _exact_keys($report, \@REPORT_KEYS, 'sealed calibration closure report');
    confess "sealed calibration closure report schema is invalid\n"
        unless ($report->{schema} // '') eq $CLOSURE_SCHEMA
            && ($report->{schema_version} // 0) == 1;
    confess "sealed calibration closure report identity is invalid\n"
        unless ($report->{closure_identity} // '')
            =~ /\Acalibration-closure\/[0-9a-f]{64}\z/;
    confess "sealed calibration closure authorities are invalid\n"
        unless ref($report->{authorities}) eq 'ARRAY'
            && @{$report->{authorities}} == @AUTHORITIES;
    confess "sealed calibration closure profiles are invalid\n"
        unless ref($report->{profiles}) eq 'ARRAY'
            && @{$report->{profiles}} == $EXPECTED_SUMMARY->{profile_count};

    my (%authority_seen, %authority_profiles, %family_seen);
    for my $index (0 .. $#AUTHORITIES) {
        my $authority = $report->{authorities}[$index];
        _exact_keys(
            $authority, \@AUTHORITY_KEYS,
            'sealed calibration closure authority',
        );
        confess "sealed calibration closure authority order changed\n"
            unless ($authority->{authority} // '') eq $AUTHORITIES[$index];
        confess "sealed calibration closure authority repeated\n"
            if $authority_seen{$authority->{authority}}++;
        confess "sealed calibration closure authority class changed\n"
            unless ($authority->{matrix_class} // '')
                    =~ /\AFSM::VIAL::ArchitectureScale[A-Za-z0-9]+MeasurementMatrix\z/
                && ($authority->{adapter_class} // '')
                    =~ /\AFSM::VIAL::ArchitectureScale[A-Za-z0-9]+Measurement\z/;
        confess "sealed calibration closure matrix identity changed\n"
            unless ($authority->{matrix_identity} // '')
                =~ /\A[a-z][a-z0-9-]*\/[0-9a-f]{64}\z/;
        confess "sealed calibration applicability identity changed\n"
            unless ($authority->{applicability_identity} // '')
                =~ /\Acalibration-applicability\/[0-9a-f]{64}\z/;
        _validate_common_identity($authority->{common_identity});
        _validate_artifact(
            $authority->{complete_artifact}, 'complete calibration artifact',
        );
        confess "sealed calibration family artifacts are invalid\n"
            unless ref($authority->{family_artifacts}) eq 'ARRAY'
                && @{$authority->{family_artifacts}};
        my $authority_family_profiles = 0;
        for my $family (@{$authority->{family_artifacts}}) {
            _exact_keys(
                $family, \@FAMILY_ARTIFACT_KEYS,
                'sealed calibration family artifact',
            );
            confess "sealed calibration family name is invalid\n"
                unless _safe_token($family->{family});
            my $qualified_family = join('/',
                $authority->{authority}, $family->{family},
            );
            confess "sealed calibration family repeated within its authority\n"
                if $family_seen{$qualified_family}++;
            confess "sealed calibration family identity changed\n"
                unless ($family->{matrix_identity} // '')
                    =~ /\A[a-z][a-z0-9-]*\/[0-9a-f]{64}\z/;
            confess "sealed calibration family profile count is invalid\n"
                unless _nonnegative_integer($family->{profile_count})
                    && $family->{profile_count} > 0;
            _validate_artifact(
                $family->{artifact}, 'sealed calibration family artifact',
            );
            $authority_family_profiles += $family->{profile_count};
        }
        confess "sealed calibration authority profile count changed\n"
            unless _nonnegative_integer($authority->{profile_count})
                && $authority->{profile_count} == $authority_family_profiles;
        $authority_profiles{$authority->{authority}} =
            $authority->{profile_count};
        confess "sealed calibration authority outcome changed\n"
            unless ($authority->{outcome} // '') eq 'accepted';
        confess "sealed calibration authority diagnostics are invalid\n"
            unless ref($authority->{diagnostics}) eq 'ARRAY';
        confess "sealed calibration authority nonclaims are invalid\n"
            unless ref($authority->{explicit_nonclaims}) eq 'ARRAY';
    }
    confess "sealed calibration family count changed\n"
        unless keys(%family_seen) == $EXPECTED_SUMMARY->{family_count};

    my (%qualified_profiles, %raw_identities, %observed_profiles);
    my ($raw_records, $excluded_records, $candidates) = (0, 0, 0);
    for my $index (0 .. $#{$report->{profiles}}) {
        my $profile = $report->{profiles}[$index];
        _exact_keys(
            $profile, \@PROFILE_KEYS, 'sealed calibration profile',
        );
        confess "sealed calibration profile ordinal changed\n"
            unless ($profile->{ordinal} // 0) == $index + 1;
        confess "sealed calibration profile authority changed\n"
            unless $authority_seen{$profile->{authority} // ''};
        $observed_profiles{$profile->{authority}}++;
        confess "sealed calibration profile coordinates are invalid\n"
            unless ref($profile->{coordinates}) eq 'HASH'
                && ref($profile->{matrix_profile}) eq 'HASH';
        my $profile_id = $profile->{matrix_profile}{profile_id};
        confess "sealed calibration profile identity is invalid\n"
            unless _safe_token($profile_id);
        my $qualified = "$profile->{authority}/$profile_id";
        confess "sealed calibration profile repeated\n"
            if $qualified_profiles{$qualified}++;
        _validate_artifact(
            $profile->{raw_evidence}, 'sealed calibration raw evidence',
        );
        my $authority = $report->{authorities}[
            _authority_index($profile->{authority})
        ];
        confess "sealed calibration profile applicability identity changed\n"
            unless ($profile->{applicability_identity} // '')
                eq $authority->{applicability_identity};
        confess "sealed calibration measurement applicability is invalid\n"
            unless ref($profile->{measurement_applicability}) eq 'HASH'
                && exists($profile->{measurement_applicability}{applicable})
                && exists($profile->{measurement_applicability}{reason});
        confess "sealed calibration raw measurement identities are invalid\n"
            unless ref($profile->{raw_measurement_identities}) eq 'ARRAY';
        confess "sealed calibration exclusions are invalid\n"
            unless ref($profile->{sample_exclusions}) eq 'ARRAY';
        confess "sealed calibration accepted totals are invalid\n"
            unless ref($profile->{accepted_run_totals}) eq 'ARRAY'
                && @{$profile->{accepted_run_totals}}
                    == @{$profile->{raw_measurement_identities}};
        for my $run_index (0 .. $#{$profile->{accepted_run_totals}}) {
            my $identity = $profile->{raw_measurement_identities}[$run_index];
            confess "sealed calibration raw measurement identity is invalid\n"
                unless defined($identity) && !ref($identity) && length($identity);
            confess "sealed calibration raw measurement identity repeated\n"
                if $raw_identities{$identity}++;
            my $total = $profile->{accepted_run_totals}[$run_index];
            _exact_keys(
                $total, \@RUN_TOTAL_KEYS,
                'sealed calibration accepted run total',
            );
            confess "sealed calibration accepted run identity changed\n"
                unless ($total->{measurement_identity} // '') eq $identity;
            for my $metric (qw(
                wall_time_ns cpu_time_ns peak_tree_rss_bytes
            )) {
                confess "sealed calibration accepted run metric is invalid\n"
                    unless _nonnegative_integer($total->{$metric});
            }
        }
        $raw_records += @{$profile->{raw_measurement_identities}};
        $excluded_records += @{$profile->{sample_exclusions}};
        if (defined($profile->{candidate_budget})) {
            $candidates++;
            _validate_candidate_profile($profile);
        }
        else {
            confess "sealed noncandidate retained derived statistics\n"
                if defined($profile->{aggregate_statistics})
                    || defined($profile->{stage_statistics})
                    || defined($profile->{cost_statistics});
        }
        confess "sealed calibration profile dominance is invalid\n"
            unless ref($profile->{dominance}) eq 'HASH';
        confess "sealed calibration profile cleanup is invalid\n"
            unless ref($profile->{cleanup}) eq 'HASH';
        confess "sealed calibration profile nonclaims are invalid\n"
            unless ref($profile->{explicit_nonclaims}) eq 'ARRAY';
    }
    for my $authority (@AUTHORITIES) {
        confess "sealed calibration authority membership changed\n"
            unless ($observed_profiles{$authority} // 0)
                == $authority_profiles{$authority};
    }

    my $derived_summary = {
        authority_count => scalar(@{$report->{authorities}}),
        family_count => scalar(keys %family_seen),
        profile_count => scalar(@{$report->{profiles}}),
        raw_measurement_records => $raw_records,
        excluded_measurement_records => $excluded_records,
        candidate_profiles => $candidates,
        noncandidate_profiles => scalar(@{$report->{profiles}}) - $candidates,
    };
    _validate_summary($report->{summary});
    confess "sealed calibration summary disagrees with report members\n"
        unless _canonical_json($report->{summary})
            eq _canonical_json($derived_summary);
    confess "sealed calibration candidate formula changed\n"
        unless _canonical_json($report->{candidate_formula})
            eq _canonical_json($CANDIDATE_FORMULA);
    confess "sealed calibration outcome changed\n"
        unless ($report->{outcome} // '') eq 'accepted';
    confess "sealed calibration diagnostics changed\n"
        unless ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};
    confess "sealed calibration nonclaims changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    my $projection = _clone($report);
    delete $projection->{closure_identity};
    confess "sealed calibration closure identity changed\n"
        unless $report->{closure_identity} eq 'calibration-closure/'
            . sha256_hex(_canonical_json($projection));
}

sub _validate_candidate_profile($profile) {
    _exact_keys(
        $profile->{candidate_budget}, \@CANDIDATE_KEYS,
        'sealed calibration candidate budget',
    );
    confess "sealed calibration candidate status changed\n"
        unless ($profile->{candidate_budget}{status} // '')
                eq 'candidate_only'
            && ($profile->{candidate_budget}{formula_authority} // '')
                eq 'decision-0056';
    confess "sealed candidate aggregate statistics are invalid\n"
        unless ref($profile->{aggregate_statistics}) eq 'HASH';
    _exact_keys(
        $profile->{aggregate_statistics}, \@AGGREGATE_KEYS,
        'sealed candidate aggregate statistics',
    );
    for my $metric (@AGGREGATE_KEYS) {
        _validate_statistics($profile->{aggregate_statistics}{$metric});
    }
    confess "sealed candidate stage statistics are invalid\n"
        unless ref($profile->{stage_statistics}) eq 'ARRAY';
    confess "sealed candidate cost statistics are invalid\n"
        unless ref($profile->{cost_statistics}) eq 'HASH';
    _exact_keys(
        $profile->{cost_statistics}, \@COST_CLASSES,
        'sealed candidate cost statistics',
    );
    for my $metric (qw(wall_time_ns cpu_time_ns peak_tree_rss_bytes)) {
        confess "sealed calibration candidate metric is invalid\n"
            unless _nonnegative_integer($profile->{candidate_budget}{$metric});
    }
    confess "sealed calibration wall candidate rounding changed\n"
        unless $profile->{candidate_budget}{wall_time_ns} >= 2_000_000_000
            && $profile->{candidate_budget}{wall_time_ns} % 1_000_000 == 0;
    confess "sealed calibration CPU candidate rounding changed\n"
        unless $profile->{candidate_budget}{cpu_time_ns} >= 2_000_000_000
            && $profile->{candidate_budget}{cpu_time_ns} % 1_000_000 == 0;
    confess "sealed calibration RSS candidate rounding changed\n"
        unless $profile->{candidate_budget}{peak_tree_rss_bytes} >= 268_435_456
            && $profile->{candidate_budget}{peak_tree_rss_bytes}
                % 16_777_216 == 0;
}

sub _validate_statistics($statistics) {
    _exact_keys(
        $statistics, \@STATISTIC_KEYS,
        'sealed calibration statistic',
    );
    for my $key (@STATISTIC_KEYS) {
        confess "sealed calibration statistic value is invalid\n"
            unless _nonnegative_integer($statistics->{$key});
    }
    confess "sealed calibration statistic ordering changed\n"
        unless $statistics->{sample_count} > 0
            && $statistics->{minimum} <= $statistics->{median}
            && $statistics->{median} <= $statistics->{maximum};
}

sub _validate_summary($summary) {
    _exact_keys(
        $summary, \@SUMMARY_KEYS, 'calibration closure publication summary',
    );
    for my $key (@SUMMARY_KEYS) {
        confess "calibration closure summary value is invalid\n"
            unless _nonnegative_integer($summary->{$key});
    }
    confess "calibration closure publication summary changed\n"
        unless _canonical_json($summary)
            eq _canonical_json($EXPECTED_SUMMARY);
}

sub _validate_common_identity($identity) {
    _exact_keys(
        $identity, \@COMMON_KEYS,
        'sealed calibration common identity',
    );
    confess "sealed calibration Git revision is invalid\n"
        unless ($identity->{git_revision} // '') =~ /\A[0-9a-f]{40}\z/;
    confess "sealed calibration common identity is dirty\n"
        if $identity->{dirty_state};
    confess "sealed calibration host/tool/guard identity is invalid\n"
        unless ref($identity->{host_profile}) eq 'HASH'
            && ref($identity->{tool_profile}) eq 'HASH'
            && ref($identity->{resource_guard}) eq 'HASH';
}

sub _validate_artifact($artifact, $label) {
    _exact_keys($artifact, \@ARTIFACT_KEYS, $label);
    _safe_relative_path($artifact->{relative_path});
    confess "$label digest is invalid\n"
        unless ($artifact->{sha256} // '') =~ /\A[0-9a-f]{64}\z/;
    confess "$label byte count is invalid\n"
        unless _nonnegative_integer($artifact->{bytes})
            && $artifact->{bytes} > 0;
}

sub _authority_index($name) {
    for my $index (0 .. $#AUTHORITIES) {
        return $index if $AUTHORITIES[$index] eq $name;
    }
    confess "unknown sealed calibration authority\n";
}

sub _manifest_identity($manifest) {
    my $projection = _clone($manifest);
    $projection->{publication_identity} = undef;
    return 'calibration-closure-publication/'
        . sha256_hex(_canonical_json($projection));
}

sub _load_publication($repo_root, $root_device) {
    my $metadata = _publication_metadata(
        $repo_root, $root_device, $PUBLICATION_ID,
    );
    my $report_bytes = _read_bytes($metadata->{report_path});
    my $manifest_bytes = _read_bytes($metadata->{manifest_path});
    confess "calibration closure report size changed while reading\n"
        unless bytes::length($report_bytes) == $metadata->{report_bytes};
    confess "calibration closure manifest size changed while reading\n"
        unless bytes::length($manifest_bytes) == $metadata->{manifest_bytes};
    my $report = _decode_canonical_json(
        $report_bytes, 'calibration closure report publication',
    );
    my $manifest = _decode_canonical_json(
        $manifest_bytes, 'calibration closure manifest publication',
    );
    _validate_sealed_report($report);
    _validate_manifest_shape($manifest);
    confess "calibration closure report artifact bytes changed\n"
        unless $manifest->{report_artifact}{bytes}
            == bytes::length($report_bytes);
    confess "calibration closure report artifact digest changed\n"
        unless $manifest->{report_artifact}{sha256}
            eq sha256_hex($report_bytes);
    confess "calibration closure report identity disagrees with manifest\n"
        unless $manifest->{closure_identity}
            eq $report->{closure_identity};
    my $expected = _publication_manifest(
        $report, $manifest->{publisher_revision},
    );
    confess "calibration closure manifest disagrees with sealed report\n"
        unless _canonical_json($manifest) eq _canonical_json($expected);
    return (_clone($report), _clone($manifest));
}

sub _publish_file_set($raw) {
    _exact_keys(
        $raw, [qw(
            repository_root root_device publication_id report_bytes
            manifest_bytes
        )],
        'calibration closure file-set publication invocation',
    );
    confess "calibration closure publication ID is invalid\n"
        unless _safe_token($raw->{publication_id});
    confess "calibration closure report bytes are invalid\n"
        unless defined($raw->{report_bytes}) && !ref($raw->{report_bytes});
    confess "calibration closure manifest bytes are invalid\n"
        unless defined($raw->{manifest_bytes}) && !ref($raw->{manifest_bytes});
    confess "calibration closure report exceeds its storage envelope\n"
        if bytes::length($raw->{report_bytes}) > $MAX_REPORT_BYTES;
    confess "calibration closure manifest exceeds its storage envelope\n"
        if bytes::length($raw->{manifest_bytes}) > $MAX_MANIFEST_BYTES;
    _decode_canonical_json(
        $raw->{report_bytes}, 'calibration closure report bytes',
    );
    _decode_canonical_json(
        $raw->{manifest_bytes}, 'calibration closure manifest bytes',
    );

    my $digest = _file_set_digest(
        $raw->{report_bytes}, $raw->{manifest_bytes},
    );
    my $target_rel = join('/',
        $PUBLICATION_BASE, $raw->{publication_id},
    );
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $target_rel,
    );
    if (-e $target_abs || -l $target_abs) {
        confess "calibration closure publication collision\n"
            unless _exact_directory_content(
                $target_abs, $raw->{report_bytes}, $raw->{manifest_bytes},
            );
        return {status => 'unchanged', file_set_digest => $digest};
    }
    my $stage_rel = join('/',
        $STAGING_BASE, "$raw->{publication_id}-$digest",
    );
    my $stage_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $stage_rel,
    );
    if (-e $stage_abs || -l $stage_abs) {
        confess "calibration closure staging is not recoverable\n"
            unless _exact_directory_content(
                $stage_abs, $raw->{report_bytes}, $raw->{manifest_bytes},
            );
        my @created;
        _ensure_publication_parent(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel), \@created,
        );
        unless (rename($stage_abs, $target_abs)) {
            _remove_empty_directories(\@created);
            confess "cannot recover calibration closure publication\n";
        }
        _remove_empty_parent_chain($stage_abs, $raw->{repository_root});
        return {status => 'recovered', file_set_digest => $digest};
    }

    my ($created_stage, $created_publication) = ([], []);
    my $ok = eval {
        ($stage_abs, $created_stage) = _create_owned_stage(
            $raw->{repository_root}, $raw->{root_device}, $stage_rel,
        );
        _write_synced_file(
            File::Spec->catfile($stage_abs, $REPORT_FILENAME),
            $raw->{report_bytes},
        );
        _write_synced_file(
            File::Spec->catfile($stage_abs, $MANIFEST_FILENAME),
            $raw->{manifest_bytes},
        );
        _ensure_publication_parent(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel),
            $created_publication,
        );
        confess "calibration closure publication target appeared\n"
            if -e $target_abs || -l $target_abs;
        rename($stage_abs, $target_abs)
            or confess "cannot atomically publish calibration closure\n";
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
    confess "calibration closure publication changed after rename\n"
        unless _exact_directory_content(
            $target_abs, $raw->{report_bytes}, $raw->{manifest_bytes},
        );
    return {status => 'published', file_set_digest => $digest};
}

sub _file_set_digest($report_bytes, $manifest_bytes) {
    confess "calibration closure file-set digest input is invalid\n"
        unless defined($report_bytes) && !ref($report_bytes)
            && defined($manifest_bytes) && !ref($manifest_bytes);
    return sha256_hex(join("\0",
        $REPORT_FILENAME, bytes::length($report_bytes),
        sha256_hex($report_bytes),
        $MANIFEST_FILENAME, bytes::length($manifest_bytes),
        sha256_hex($manifest_bytes),
    ));
}

sub _publication_metadata($repo_root, $root_device, $publication_id) {
    confess "calibration closure publication ID is invalid\n"
        unless _safe_token($publication_id);
    my $target_rel = join('/', $PUBLICATION_BASE, $publication_id);
    my $target_abs = _safe_destination(
        $repo_root, $root_device, $target_rel,
    );
    confess "calibration closure publication root is absent\n"
        unless -d $target_abs && !-l $target_abs;
    opendir my $dh, $target_abs
        or confess "cannot inspect calibration closure publication\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close calibration closure publication directory\n";
    confess "calibration closure publication census changed\n"
        unless _canonical_json(\@entries)
            eq _canonical_json([$REPORT_FILENAME, $MANIFEST_FILENAME]);
    my $report_path = File::Spec->catfile(
        $target_abs, $REPORT_FILENAME,
    );
    my $manifest_path = File::Spec->catfile(
        $target_abs, $MANIFEST_FILENAME,
    );
    for my $path ($report_path, $manifest_path) {
        confess "calibration closure publication artifact is invalid\n"
            unless -f $path && !-l $path;
        my @stat = stat($path);
        confess "calibration closure publication crossed repository volume\n"
            unless @stat && $stat[0] == $root_device;
    }
    my @report_stat = stat($report_path);
    my @manifest_stat = stat($manifest_path);
    confess "calibration closure report exceeds its storage envelope\n"
        unless $report_stat[7] > 0
            && $report_stat[7] <= $MAX_REPORT_BYTES;
    confess "calibration closure manifest exceeds its storage envelope\n"
        unless $manifest_stat[7] > 0
            && $manifest_stat[7] <= $MAX_MANIFEST_BYTES;
    return {
        report_path => $report_path,
        report_bytes => $report_stat[7],
        manifest_path => $manifest_path,
        manifest_bytes => $manifest_stat[7],
    };
}

sub _publication_exists($repo_root) {
    my $path = File::Spec->catdir(
        $repo_root, split(m{/}, join('/',
            $PUBLICATION_BASE, $PUBLICATION_ID,
        )),
    );
    return -e $path || -l $path;
}

sub _exact_directory_content($root, $report_bytes, $manifest_bytes) {
    return 0 unless -d $root && !-l $root;
    opendir my $dh, $root or return 0;
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or return 0;
    return 0 unless _canonical_json(\@entries)
        eq _canonical_json([$REPORT_FILENAME, $MANIFEST_FILENAME]);
    my %expected = (
        $REPORT_FILENAME => $report_bytes,
        $MANIFEST_FILENAME => $manifest_bytes,
    );
    for my $filename ($REPORT_FILENAME, $MANIFEST_FILENAME) {
        my $path = File::Spec->catfile($root, $filename);
        return 0 unless -f $path && !-l $path;
        my $actual = eval { _read_bytes($path) };
        return 0 if $@ || !defined($actual)
            || $actual ne $expected{$filename};
    }
    return 1;
}

sub _create_owned_stage($repo_root, $root_device, $relative) {
    my $path = $repo_root;
    my @created;
    my $ok = eval {
        my @parts = split m{/}, _safe_relative_path($relative);
        for my $index (0 .. $#parts) {
            $path = File::Spec->catdir($path, $parts[$index]);
            if (-e $path || -l $path) {
                confess "calibration closure staging traverses a symlink\n"
                    if -l $path;
                confess "calibration closure staging component is not a directory\n"
                    unless -d $path;
                confess "calibration closure staging root already exists\n"
                    if $index == $#parts;
            }
            else {
                mkdir($path)
                    or confess "cannot create calibration closure staging directory\n";
                push @created, $path;
            }
            my @stat = stat($path);
            confess "calibration closure staging crossed repository volume\n"
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

sub _write_synced_file($path, $bytes) {
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL)
        or confess "cannot create calibration closure publication file\n";
    binmode($fh, ':raw')
        or confess "cannot set calibration closure publication byte mode\n";
    print {$fh} $bytes
        or confess "cannot write calibration closure publication file\n";
    $fh->flush
        or confess "cannot flush calibration closure publication file\n";
    $fh->sync
        or confess "cannot sync calibration closure publication file\n";
    close $fh
        or confess "cannot close calibration closure publication file\n";
}

sub _ensure_publication_parent(
    $repo_root, $root_device, $parent, $relative, $created,
) {
    my $path = $repo_root;
    for my $part (split m{/}, _safe_relative_path($relative)) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            confess "calibration closure publication parent traverses a symlink\n"
                if -l $path;
            confess "calibration closure publication parent is not a directory\n"
                unless -d $path;
        }
        else {
            mkdir($path)
                or confess "cannot create calibration closure publication parent\n";
            push @$created, $path;
        }
        my @stat = stat($path);
        confess "calibration closure publication parent crossed repository volume\n"
            unless @stat && $stat[0] == $root_device;
    }
    confess "calibration closure publication parent mismatch\n"
        unless $path eq $parent;
}

sub _safe_destination($repo_root, $root_device, $relative) {
    _safe_relative_path($relative);
    my $path = $repo_root;
    my $existing = $repo_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            confess "calibration closure destination traverses a symlink\n"
                if -l $path;
            $existing = $path;
        }
    }
    my @stat = stat($existing);
    confess "calibration closure destination filesystem identity is unavailable\n"
        unless @stat;
    confess "calibration closure destination crossed repository volume\n"
        unless $stat[0] == $root_device;
    return $path;
}

sub _remove_owned_stage($stage_abs, $created) {
    if (-e $stage_abs || -l $stage_abs) {
        confess "calibration closure staging cleanup target is invalid\n"
            unless -d $stage_abs && !-l $stage_abs;
        my $errors;
        remove_tree($stage_abs, {error => \$errors});
        confess "cannot remove calibration closure publication staging\n"
            if $errors && @$errors;
    }
    confess "calibration closure publication staging remains after cleanup\n"
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

sub _read_bytes($path) {
    open my $fh, '<:raw', $path
        or confess "cannot read calibration closure publication artifact\n";
    local $/;
    my $bytes = <$fh>;
    close $fh
        or confess "cannot close calibration closure publication artifact\n";
    return $bytes;
}

sub _decode_canonical_json($bytes, $label) {
    confess "$label is not newline-terminated\n"
        unless defined($bytes) && !ref($bytes) && $bytes =~ /\n\z/;
    my $value = eval { JSON::PP->new->utf8(1)->decode($bytes) };
    confess "$label is not valid JSON\n" if $@;
    confess "$label is not canonical JSON\n"
        unless _canonical_json($value) . "\n" eq $bytes;
    return $value;
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

sub _require_active_guard() {
    confess "calibration closure publication requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "calibration closure publication guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss <= 4096;
}

sub _require_clean_revision($repo_root) {
    my ($revision_ok, $revision) = _capture_command(
        'git', '-C', $repo_root, 'rev-parse', 'HEAD',
    );
    confess "cannot derive calibration closure publication Git revision\n"
        unless $revision_ok;
    $revision =~ s/\s+\z//;
    confess "calibration closure publication Git revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my ($status_ok, $status) = _capture_command(
        'git', '-C', $repo_root, 'status', '--porcelain=v1',
        '--untracked-files=normal',
    );
    confess "cannot derive calibration closure publication Git state\n"
        unless $status_ok;
    confess "calibration closure publication requires a clean Git revision\n"
        if length($status);
    return $revision;
}

sub _require_unchanged_clean_revision($repo_root, $expected) {
    my $actual = _require_clean_revision($repo_root);
    confess "calibration closure publication Git revision changed during capture\n"
        unless $actual eq $expected;
}

sub _require_capture_revision($actual, $expected) {
    confess "calibration closure publication capture revision changed\n"
        unless defined($actual) && defined($expected)
            && $actual eq $expected;
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
    my %allowed = map { $_ => 1 } @$keys;
    for my $key (keys %{$args->[0]}) {
        confess "$method received unknown key '$key'\n"
            unless $allowed{$key};
    }
    for my $key (@$keys) {
        confess "$method is missing '$key'\n"
            unless exists($args->[0]{$key});
    }
    return $args->[0];
}

sub _safe_relative_path($value) {
    confess "calibration closure publication path must be repository-relative\n"
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
