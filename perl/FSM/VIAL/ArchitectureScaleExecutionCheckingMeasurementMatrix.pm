package FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use File::Basename qw(dirname);
use File::Path qw(remove_tree);
use File::Spec;
use IO::Handle ();
use JSON::PP ();
use Scalar::Util qw(blessed);
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
        my ($publication_set, $publication);
        if (_publication_exists($repo_root, $profile->{profile_id})) {
            ($publication_set, $publication) = _load_report_publication(
                $repo_root, $root_device, $profile,
            );
            _require_capture_revision(
                $publication_set->{capture_identity}, $git_revision,
            );
            $publication->{status} = 'resumed';
        }
        else {
            my $report = $profile->{mode} eq 'validation'
                ? $ADAPTER->validate_profile({
                    repository_root => $repo_root,
                    family => $family,
                    level => $profile->{level},
                    primary_axis => $profile->{primary_axis},
                })
                : $ADAPTER->measure_profile({
                    repository_root => $repo_root,
                    family => $family,
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
                $common_identity //= $report_common;
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
        $common_identity //= _clone($loaded_common);
        push @captured, _profile_entry(
            $profile, $publication_set->{report}, $publication,
            $loaded_common,
        );
        my $ordinal = $index + 1;
        print STDERR join(' ',
            'vial-scale-execution-checking-matrix:', $family,
            "$ordinal/" . scalar(@profiles),
            "$profile->{primary_axis}/$profile->{level}",
            $publication->{status},
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
    my @entries;
    for my $profile (@profiles) {
        my ($publication_set, $publication) = _load_report_publication(
            $repo_root, $root_device, $profile,
        );
        push @entries, _profile_entry(
            $profile, $publication_set->{report}, $publication,
            $publication_set->{capture_identity},
        );
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
