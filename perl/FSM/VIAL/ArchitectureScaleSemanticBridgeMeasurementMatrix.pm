package FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurementMatrix;

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

use FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement;
use FSM::VIAL::ArchitectureScaleWorkload;

my $SCHEMA =
    'fsmgen.vial_architecture_scale_semantic_bridge_matrix.v1';
my $COMPLETE_SCHEMA =
    'fsmgen.vial_architecture_scale_semantic_bridge_complete_matrix.v1';
my $PUBLICATION_BASE = '.artifacts/qualification/vial-scale/v1';
my $STAGING_BASE = '.artifacts/tmp/vial-scale/matrix-publication';
my $REPORT_FILENAME = 'measurement-set.json';
my $MATRIX_FILENAME = 'matrix.json';
my $COMPLETE_FILENAME = 'complete-matrix.json';
my $ADAPTER = 'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement';

my @FAMILIES = qw(semantic_catalog_v1 bridge_fanout_v1);
my %FAMILY_INDEX = map { $FAMILIES[$_] => $_ } 0 .. $#FAMILIES;
my %AXES = (
    semantic_catalog_v1 => [qw(
        imports declarations fixtures actions parallel_depth
        fibers_per_parallel scalar_or_list_length record_fields
        aggregate_depth scoreboard_capacity coverage_bins
        literal_repeat_count source_bytes_per_source source_bytes_combined
    )],
    bridge_fanout_v1 => [qw(
        selected_units selected_domains configurations types endpoints
        transactions events observations probes backend_bindings
        retained_residue_records source_map_records serialized_manifest_bytes
    )],
);
my @LEVELS = qw(
    gate_candidate_v1 qualification_candidate_v1 limit_v1 over_limit_v1
);
my %MODE = (
    gate_candidate_v1 => 'gate',
    qualification_candidate_v1 => 'qualification',
    limit_v1 => 'validation',
    over_limit_v1 => 'validation',
);
my %EXPECTED_SAMPLES = (gate => 3, qualification => 5);
my @INVENTORY_KEYS = qw(profile_id family primary_axis level mode);
my @MATRIX_KEYS = qw(
    schema schema_version matrix_identity family profile_count
    common_identity profiles dominance outcome diagnostics explicit_nonclaims
);
my @PROFILE_KEYS = qw(
    profile_id family primary_axis level mode expected_outcome report_identity
    workload_identity validation_identity family_status
    measurement_applicable measurement_reason measured_samples excluded_samples
    outcome diagnostic artifact_relative_path artifact_sha256 artifact_bytes
);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @DOMINANCE_KEYS = qw(
    accepted_profiles expected_rejection_profiles
    applicable_measurement_profiles inapplicable_measurement_profiles
    raw_measurement_records excluded_measurement_records diagnostic_counts
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
        mutable_measurement_publication
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
    my $complete = _complete_manifest(\@manifests);
    my $publication = _publish_json({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => 'semantic-bridge-complete-matrix-v1',
        filename => $COMPLETE_FILENAME,
        value => $complete,
    });
    print STDERR "vial-scale-matrix: complete matrix $publication->{status}\n";
    return _validate_complete_publication($repo_root, $root_device);
}

sub validate_family_publication($class, @args) {
    _exact_invocant($class, 'validate_family_publication');
    my $raw = _request(
        'validate_family_publication', \@args,
        [qw(repository_root family)],
    );
    _selected_family($raw->{family});
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
        print STDERR "vial-scale-matrix: $family matrix resumed\n";
        return $existing;
    }

    my @profiles = grep { $_->{family} eq $family } @{_inventory()};
    my @captured;
    for my $index (0 .. $#profiles) {
        my $profile = $profiles[$index];
        my ($report, $publication);
        if (_publication_exists($repo_root, $profile->{profile_id})) {
            ($report, $publication) = _load_report_publication(
                $repo_root, $root_device, $profile,
            );
            _require_report_revision($report, $git_revision);
            $publication->{status} = 'resumed';
        }
        else {
            $report = $profile->{mode} eq 'validation'
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
            _require_report_revision($report, $git_revision);
            _require_acceptable_profile_report($profile, $report);
            $publication = _publish_json({
                repository_root => $repo_root,
                root_device => $root_device,
                profile_id => $profile->{profile_id},
                filename => $REPORT_FILENAME,
                value => $report,
            });
            my $publication_status = $publication->{status};
            ($report, $publication) = _load_report_publication(
                $repo_root, $root_device, $profile,
            );
            $publication->{status} = $publication_status;
        }
        push @captured, _profile_entry($profile, $report, $publication);
        my $ordinal = $index + 1;
        print STDERR join(' ',
            'vial-scale-matrix:', $family,
            "$ordinal/" . scalar(@profiles),
            "$profile->{primary_axis}/$profile->{level}",
            $publication->{status},
        ), "\n";
    }

    my $manifest = _family_manifest($family, \@captured);
    my $publication = _publish_json({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => $matrix_profile_id,
        filename => $MATRIX_FILENAME,
        value => $manifest,
    });
    print STDERR "vial-scale-matrix: $family matrix $publication->{status}\n";
    return _validate_family_publication($repo_root, $root_device, $family);
}

sub _validate_family_publication($repo_root, $root_device, $family) {
    my @profiles = grep { $_->{family} eq $family } @{_inventory()};
    my @entries;
    for my $profile (@profiles) {
        my ($report, $publication) = _load_report_publication(
            $repo_root, $root_device, $profile,
        );
        _require_acceptable_profile_report($profile, $report);
        push @entries, _profile_entry($profile, $report, $publication);
    }
    my $expected = _family_manifest($family, \@entries);
    my ($actual) = _read_json_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => _matrix_profile_id($family),
        filename => $MATRIX_FILENAME,
    });
    _validate_family_manifest_shape($actual);
    confess "semantic/bridge family matrix publication is not canonical\n"
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
        profile_id => 'semantic-bridge-complete-matrix-v1',
        filename => $COMPLETE_FILENAME,
    });
    _validate_complete_manifest_shape($actual);
    confess "semantic/bridge complete matrix publication is not canonical\n"
        unless _canonical_json($actual) eq _canonical_json($expected);
    return $actual;
}

sub _inventory() {
    _assert_catalog_partition();
    my @profiles;
    for my $family (@FAMILIES) {
        for my $axis (@{$AXES{$family}}) {
            for my $level (@LEVELS) {
                push @profiles, {
                    profile_id => _profile_id($family, $axis, $level),
                    family => $family,
                    primary_axis => $axis,
                    level => $level,
                    mode => $MODE{$level},
                };
            }
        }
    }
    return \@profiles;
}

sub _assert_catalog_partition() {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog->{families};
    for my $family (@FAMILIES) {
        confess "semantic/bridge matrix family catalog is absent\n"
            unless ref($catalog->{$family}{axes}) eq 'HASH';
        my @actual_axes = sort keys %{$catalog->{$family}{axes}};
        my @expected_axes = sort @{$AXES{$family}};
        confess "semantic/bridge matrix axis partition changed\n"
            unless _canonical_json(\@actual_axes)
                eq _canonical_json(\@expected_axes);
        for my $axis (@{$AXES{$family}}) {
            my @actual_levels = sort keys %{
                $catalog->{$family}{axes}{$axis}{levels}
            };
            my @selected = sort ('reference_v1', @LEVELS);
            confess "semantic/bridge matrix level partition changed\n"
                unless _canonical_json(\@actual_levels)
                    eq _canonical_json(\@selected);
        }
    }
}

sub _profile_entry($profile, $report, $publication) {
    _require_acceptable_profile_report($profile, $report);
    my ($status, $diagnostic) = _family_status($report);
    return {
        profile_id => $profile->{profile_id},
        family => $profile->{family},
        primary_axis => $profile->{primary_axis},
        level => $profile->{level},
        mode => $profile->{mode},
        expected_outcome => _clone($report->{expected_outcome}),
        report_identity => $report->{report_identity},
        workload_identity => $report->{workload_identity},
        validation_identity =>
            $report->{validation_record}{measurement_identity},
        family_status => $status,
        measurement_applicable =>
            _clone($report->{measurement_applicability}{applicable}),
        measurement_reason =>
            $report->{measurement_applicability}{reason},
        measured_samples => scalar(@{$report->{measurement_records}}),
        excluded_samples => scalar(@{$report->{sample_exclusions}}),
        outcome => $report->{outcome},
        diagnostic => _clone($diagnostic),
        artifact_relative_path => $publication->{artifact_relative_path},
        artifact_sha256 => $publication->{sha256},
        artifact_bytes => $publication->{bytes},
        _common_identity => _profile_common_identity($report),
    };
}

sub _family_status($report) {
    my $oracle_id = $report->{family} eq 'semantic_catalog_v1'
        ? 'semantic_catalog_v1_parse_validate_canonical'
        : 'bridge_fanout_v1_bridge_canonical';
    my @oracles = grep { $_->{oracle_id} eq $oracle_id }
        @{$report->{validation_record}{correctness_oracles}};
    confess "semantic/bridge matrix family oracle is not unique\n"
        unless @oracles == 1;
    my $evidence = $oracles[0]{evidence};
    my $status = $evidence->{status};
    confess "semantic/bridge matrix family status is invalid\n"
        unless defined($status)
            && ($status eq 'accepted' || $status eq 'expected_rejection');
    my $diagnostics = $evidence->{diagnostics};
    confess "semantic/bridge matrix family diagnostics are invalid\n"
        unless ref($diagnostics) eq 'ARRAY';
    my $diagnostic = @$diagnostics ? $diagnostics->[0] : undef;
    confess "accepted semantic/bridge family retained a diagnostic\n"
        if $status eq 'accepted' && defined($diagnostic);
    confess "rejected semantic/bridge family has no diagnostic\n"
        if $status eq 'expected_rejection' && !defined($diagnostic);
    return ($status, $diagnostic);
}

sub _require_acceptable_profile_report($profile, $report) {
    confess "semantic/bridge matrix report profile changed\n"
        unless ($report->{family} // '') eq $profile->{family}
            && ($report->{primary_axis} // '') eq $profile->{primary_axis}
            && ($report->{level} // '') eq $profile->{level}
            && ($report->{mode} // '') eq $profile->{mode};
    my ($status) = _family_status($report);
    my $applicable = $report->{measurement_applicability}{applicable} ? 1 : 0;
    my $measured = scalar @{$report->{measurement_records}};
    my $excluded = scalar @{$report->{sample_exclusions}};
    confess "semantic/bridge matrix cannot seal an excluded sample\n"
        if $excluded;
    if ($profile->{mode} eq 'validation') {
        confess "boundary validation retained measurement samples\n"
            if $measured;
        confess "boundary validation has the wrong matrix outcome\n"
            unless $report->{outcome} eq 'accepted_validation';
    }
    elsif ($status eq 'accepted') {
        confess "accepted family measurement is inapplicable\n"
            unless $applicable;
        confess "accepted family measurement has incomplete raw samples\n"
            unless $measured == $EXPECTED_SAMPLES{$profile->{mode}};
        confess "accepted family measurement has the wrong outcome\n"
            unless $report->{outcome} eq 'accepted';
    }
    else {
        confess "dominant family rejection was measured\n" if $measured;
        confess "dominant family rejection is marked applicable\n"
            if $applicable;
        confess "dominant family rejection reason changed\n"
            unless ($report->{measurement_applicability}{reason} // '')
                eq 'authoritative_family_rejection';
        confess "dominant family rejection has the wrong outcome\n"
            unless $report->{outcome} eq 'validated_not_measured';
    }
}

sub _family_manifest($family, $profiles) {
    confess "semantic/bridge family matrix profile count changed\n"
        unless @$profiles == @{$AXES{$family}} * @LEVELS;
    my $common = _common_identity_from_profiles($profiles);
    my $dominance = _dominance($profiles);
    my $manifest = {
        schema => $SCHEMA,
        schema_version => 1,
        matrix_identity => undef,
        family => $family,
        profile_count => scalar(@$profiles),
        common_identity => $common,
        profiles => _clone($profiles),
        dominance => $dominance,
        outcome => 'accepted',
        diagnostics => [],
        explicit_nonclaims => [@NONCLAIMS],
    };
    $manifest->{matrix_identity} = _matrix_identity($manifest);
    _validate_family_manifest_shape($manifest);
    return $manifest;
}

sub _complete_manifest($manifests) {
    confess "semantic/bridge complete matrix requires both families\n"
        unless @$manifests == @FAMILIES;
    for my $index (0 .. $#FAMILIES) {
        confess "semantic/bridge complete matrix family order changed\n"
            unless $manifests->[$index]{family} eq $FAMILIES[$index];
        _validate_family_manifest_shape($manifests->[$index]);
    }
    my $common = _clone($manifests->[0]{common_identity});
    confess "semantic/bridge complete matrix mixed common identities\n"
        unless _canonical_json($manifests->[1]{common_identity})
            eq _canonical_json($common);
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
    confess "semantic/bridge matrix has no profiles\n" unless @$profiles;
    my $first_report_identity = $profiles->[0]{report_identity};
    confess "semantic/bridge matrix first report identity is invalid\n"
        unless $first_report_identity
            =~ m{\Asemantic-bridge-measurement/[0-9a-f]{64}\z};
    my $first = $profiles->[0]{_common_identity};
    confess "semantic/bridge internal common identity is absent\n"
        unless ref($first) eq 'HASH';
    for my $profile (@$profiles) {
        confess "semantic/bridge matrix mixed common identities\n"
            unless _canonical_json($profile->{_common_identity})
                eq _canonical_json($first);
    }
    delete $_->{_common_identity} for @$profiles;
    return _clone($first);
}

sub _dominance($profiles) {
    my %diagnostics;
    my $accepted = 0;
    my $rejected = 0;
    my $applicable = 0;
    my $inapplicable = 0;
    my $raw = 0;
    my $excluded = 0;
    for my $profile (@$profiles) {
        if ($profile->{family_status} eq 'accepted') {
            $accepted++;
        }
        else {
            $rejected++;
        }
        if ($profile->{measurement_applicable}) {
            $applicable++;
        }
        elsif ($profile->{mode} ne 'validation') {
            $inapplicable++;
        }
        $raw += $profile->{measured_samples};
        $excluded += $profile->{excluded_samples};
        next unless defined $profile->{diagnostic};
        my $code = $profile->{diagnostic}{code};
        my $path = $profile->{diagnostic}{semantic_path};
        my $key = "$code\0$path";
        $diagnostics{$key} //= {
            code => $code,
            semantic_path => $path,
            profiles => 0,
        };
        $diagnostics{$key}{profiles}++;
    }
    return {
        accepted_profiles => $accepted,
        expected_rejection_profiles => $rejected,
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
    my ($report, $publication) = _read_json_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        profile_id => $profile->{profile_id},
        filename => $REPORT_FILENAME,
    });
    $ADAPTER->validate_report({
        repository_root => $repo_root,
        report => $report,
    });
    _require_acceptable_profile_report($profile, $report);
    return ($report, $publication);
}

sub _require_report_revision($report, $git_revision) {
    my @records = (
        $report->{validation_record}, @{$report->{measurement_records}},
    );
    for my $record (@records) {
        confess "semantic/bridge matrix report Git revision changed\n"
            unless $record->{git_revision} eq $git_revision;
        confess "semantic/bridge matrix requires a clean Git revision\n"
            if $record->{dirty_state};
    }
}

sub _require_manifest_revision($manifest, $git_revision) {
    confess "semantic/bridge matrix manifest Git revision changed\n"
        unless $manifest->{common_identity}{git_revision} eq $git_revision;
    confess "semantic/bridge matrix manifest is dirty\n"
        if $manifest->{common_identity}{dirty_state};
}

sub _profile_common_identity($report) {
    my $record = $report->{validation_record};
    return {
        git_revision => $record->{git_revision},
        dirty_state => _clone($record->{dirty_state}),
        host_profile => _clone($record->{host_profile}),
        tool_profile => _clone($record->{tool_profile}),
        resource_guard => _clone($record->{resource_guard}),
    };
}

sub _publish_json($raw) {
    my $encoded = _canonical_json($raw->{value}) . "\n";
    my $digest = sha256_hex($encoded);
    my $target_rel = join('/',
        $PUBLICATION_BASE, $raw->{profile_id},
    );
    my $artifact_rel = "$target_rel/$raw->{filename}";
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
        confess "semantic/bridge matrix publication collision\n"
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
        confess "semantic/bridge matrix publication staging is not recoverable\n"
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
            confess "cannot recover semantic/bridge matrix publication\n";
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
            or confess "cannot create semantic/bridge matrix publication\n";
        binmode($fh, ':raw')
            or confess "cannot set matrix publication byte mode\n";
        print {$fh} $encoded
            or confess "cannot write semantic/bridge matrix publication\n";
        $fh->flush
            or confess "cannot flush semantic/bridge matrix publication\n";
        $fh->sync
            or confess "cannot sync semantic/bridge matrix publication\n";
        close $fh
            or confess "cannot close semantic/bridge matrix publication\n";
        _ensure_publication_parent(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel), $created_publication,
        );
        confess "semantic/bridge matrix publication target appeared\n"
            if -e $target_abs || -l $target_abs;
        rename($stage_abs, $target_abs)
            or confess "cannot atomically publish semantic/bridge matrix\n";
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
    confess "semantic/bridge matrix publication identity changed\n"
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
        or confess "cannot read semantic/bridge matrix publication\n";
    local $/;
    my $encoded = <$fh>;
    close $fh
        or confess "cannot close semantic/bridge matrix publication\n";
    my $value = eval { JSON::PP->new->utf8(1)->decode($encoded) };
    confess "semantic/bridge matrix publication JSON is invalid\n" if $@;
    return ($value, $publication);
}

sub _publication_metadata($raw) {
    confess "semantic/bridge matrix publication profile ID is invalid\n"
        unless _safe_token($raw->{profile_id});
    confess "semantic/bridge matrix publication filename is invalid\n"
        unless defined($raw->{filename}) && !ref($raw->{filename})
            && $raw->{filename} =~ /\A[a-z][a-z0-9-]*[.]json\z/;
    my $target_rel = join('/',
        $PUBLICATION_BASE, $raw->{profile_id},
    );
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $target_rel,
    );
    confess "semantic/bridge matrix publication root is absent\n"
        unless -d $target_abs && !-l $target_abs;
    opendir my $dh, $target_abs
        or confess "cannot inspect semantic/bridge matrix publication\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close semantic/bridge matrix publication\n";
    confess "semantic/bridge matrix publication census changed\n"
        unless @entries == 1 && $entries[0] eq $raw->{filename};
    my $artifact_abs = File::Spec->catfile($target_abs, $raw->{filename});
    confess "semantic/bridge matrix publication artifact is invalid\n"
        unless -f $artifact_abs && !-l $artifact_abs;
    my @stat = stat($artifact_abs);
    confess "semantic/bridge matrix publication crossed repository volume\n"
        unless @stat && $stat[0] == $raw->{root_device};
    open my $fh, '<:raw', $artifact_abs
        or confess "cannot read semantic/bridge matrix artifact\n";
    local $/;
    my $content = <$fh>;
    close $fh or confess "cannot close semantic/bridge matrix artifact\n";
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
    confess "semantic/bridge family matrix must be one unblessed hash\n"
        unless ref($manifest) eq 'HASH' && !blessed($manifest);
    _exact_keys($manifest, \@MATRIX_KEYS, 'semantic/bridge family matrix');
    confess "semantic/bridge family matrix schema is invalid\n"
        unless ($manifest->{schema} // '') eq $SCHEMA
            && ($manifest->{schema_version} // 0) == 1;
    _selected_family($manifest->{family});
    confess "semantic/bridge family matrix profiles must be an array\n"
        unless ref($manifest->{profiles}) eq 'ARRAY';
    confess "semantic/bridge family matrix profile count changed\n"
        unless $manifest->{profile_count} == @{$manifest->{profiles}};
    _exact_keys($_, \@PROFILE_KEYS, 'semantic/bridge matrix profile')
        for @{$manifest->{profiles}};
    _validate_common_identity($manifest->{common_identity});
    _validate_dominance($manifest->{dominance});
    confess "semantic/bridge family matrix outcome changed\n"
        unless ($manifest->{outcome} // '') eq 'accepted';
    confess "semantic/bridge family matrix diagnostics changed\n"
        unless ref($manifest->{diagnostics}) eq 'ARRAY'
            && !@{$manifest->{diagnostics}};
    confess "semantic/bridge family matrix nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "semantic/bridge family matrix identity changed\n"
        unless ($manifest->{matrix_identity} // '')
            eq _matrix_identity($manifest);
}

sub _validate_complete_manifest_shape($manifest) {
    confess "semantic/bridge complete matrix must be one unblessed hash\n"
        unless ref($manifest) eq 'HASH' && !blessed($manifest);
    _exact_keys($manifest, \@COMPLETE_KEYS, 'semantic/bridge complete matrix');
    confess "semantic/bridge complete matrix schema is invalid\n"
        unless ($manifest->{schema} // '') eq $COMPLETE_SCHEMA
            && ($manifest->{schema_version} // 0) == 1;
    confess "semantic/bridge complete matrix family manifests changed\n"
        unless ref($manifest->{family_manifests}) eq 'ARRAY'
            && @{$manifest->{family_manifests}} == @FAMILIES;
    _exact_keys($_, \@FAMILY_MANIFEST_KEYS,
        'semantic/bridge complete family manifest')
        for @{$manifest->{family_manifests}};
    confess "semantic/bridge complete matrix profile count changed\n"
        unless $manifest->{total_profile_count} == @{_inventory()};
    _validate_common_identity($manifest->{common_identity});
    _validate_dominance($manifest->{dominance});
    confess "semantic/bridge complete matrix outcome changed\n"
        unless ($manifest->{outcome} // '') eq 'accepted';
    confess "semantic/bridge complete matrix diagnostics changed\n"
        unless ref($manifest->{diagnostics}) eq 'ARRAY'
            && !@{$manifest->{diagnostics}};
    confess "semantic/bridge complete matrix nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "semantic/bridge complete matrix identity changed\n"
        unless ($manifest->{matrix_identity} // '')
            eq _matrix_identity($manifest);
}

sub _validate_common_identity($common) {
    _exact_keys($common, \@COMMON_KEYS,
        'semantic/bridge matrix common identity');
    confess "semantic/bridge matrix Git revision is invalid\n"
        unless ($common->{git_revision} // '') =~ /\A[0-9a-f]{40}\z/;
    confess "semantic/bridge matrix common identity is dirty\n"
        if $common->{dirty_state};
    confess "semantic/bridge matrix host/tool/guard identity is invalid\n"
        unless ref($common->{host_profile}) eq 'HASH'
            && ref($common->{tool_profile}) eq 'HASH'
            && ref($common->{resource_guard}) eq 'HASH'
            && $common->{resource_guard}{active};
}

sub _validate_dominance($dominance) {
    _exact_keys($dominance, \@DOMINANCE_KEYS,
        'semantic/bridge matrix dominance');
    for my $key (grep { $_ ne 'diagnostic_counts' } @DOMINANCE_KEYS) {
        confess "semantic/bridge matrix dominance count is invalid\n"
            unless _nonnegative_integer($dominance->{$key});
    }
    confess "semantic/bridge matrix diagnostic counts must be an array\n"
        unless ref($dominance->{diagnostic_counts}) eq 'ARRAY';
    for my $item (@{$dominance->{diagnostic_counts}}) {
        _exact_keys($item, \@DIAGNOSTIC_COUNT_KEYS,
            'semantic/bridge matrix diagnostic count');
        confess "semantic/bridge matrix diagnostic count is invalid\n"
            unless ($item->{code} // '') =~ /\A[A-Z][A-Z0-9_]*\z/
                && ($item->{semantic_path} // '') =~ m{\A/}
                && _nonnegative_integer($item->{profiles})
                && $item->{profiles} > 0;
    }
}

sub _matrix_identity($manifest) {
    my $projection = _clone($manifest);
    $projection->{matrix_identity} = undef;
    return 'semantic-bridge-matrix/'
        . sha256_hex(_canonical_json($projection));
}

sub _profile_id($family, $axis, $level) {
    my $value = join('.', $family, $axis, $level);
    $value =~ tr/_/-/;
    confess "semantic/bridge matrix profile ID is invalid\n"
        unless _safe_token($value);
    return $value;
}

sub _matrix_profile_id($family) {
    my $value = "$family.matrix.v1";
    $value =~ tr/_/-/;
    return $value;
}

sub _selected_family($family) {
    confess "semantic/bridge matrix family is not selected\n"
        unless defined($family) && !ref($family)
            && exists($FAMILY_INDEX{$family});
    return $family;
}

sub _require_active_guard() {
    confess "semantic/bridge matrix requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "semantic/bridge matrix guard thresholds are invalid\n"
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
    confess "semantic/bridge matrix requires a clean Git revision\n"
        if length($status);
    return $revision;
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
    confess "semantic/bridge matrix path must be repository-relative\n"
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
