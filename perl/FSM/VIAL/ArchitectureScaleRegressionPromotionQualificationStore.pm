package FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore;

use v5.20;
use strict;
use warnings;

use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use Errno qw(EINTR);
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_RDONLY O_WRONLY);
use File::Basename qw(dirname);
use File::Spec;
use IO::Handle ();
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionQualification;

my $QUALIFICATION =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualification';
my $QUALIFICATION_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_qualification.v1';
my $REPORT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_publication_report.v1';
my $MANIFEST_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_manifest.v1';
my $ARTIFACT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_artifact.v1';
my $CONTRACT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_publication_contract.v1';
my $PUBLICATION_RELATIVE = join '/', qw(
    .artifacts qualification vial-scale v2
    regression-promotion-budget-qualification-v1 current
);
my $STAGING_BASE = join '/', qw(
    .artifacts tmp vial-scale
    regression-promotion-budget-qualification-publication v1
);
my $REPORT_FILENAME =
    'regression-promotion-budget-qualification.json';
my $MANIFEST_FILENAME = 'qualification-manifest.json';
my $PUBLICATION_REVISION =
    'regression_promotion_budget_qualification_store_v1';
my $MAX_REPORT_BYTES = 1_048_576;
my $MAX_MANIFEST_BYTES = 65_536;
my $PROFILE_COUNT = 11;
my $VALIDATION_RECORDS = 11;
my $RAW_MEASUREMENT_RECORDS = 33;
my $CONTROLLER_INVOCATIONS = 44;

my @REPORT_KEYS = qw(
    schema schema_version publication_report_identity publisher_revision
    qualification publication_contract outcome diagnostics explicit_nonclaims
);
my @MANIFEST_KEYS = qw(
    schema schema_version publication_identity publication_report_identity
    qualification_identity publisher_revision source_evidence
    formula_authority profile_bindings publication_contract report_artifact
    summary outcome explicit_nonclaims
);
my @PROFILE_BINDING_KEYS = qw(
    ordinal selection_key profile_qualification_identity
    source_report_identity workload_identity evidence_revision
    environment_identity correctness_projection_identity
    performance_applicability_identity qualified_budget provider_status
);
my @CONTRACT_KEYS = qw(
    schema schema_version predecessor replacement_policy recalibration
    rollback enforcement_state
);
my @PREDECESSOR_KEYS = qw(status publication_identity);
my @REPLACEMENT_KEYS = qw(version overwrite);
my @RECALIBRATION_KEYS = qw(authority evidence trigger);
my @ROLLBACK_KEYS = qw(authority publication_mutation);
my @REPORT_ARTIFACT_KEYS = qw(relative_path sha256 bytes);
my @ARTIFACT_KEYS = qw(
    schema schema_version status publication_relative_path
    report_artifact manifest_artifact file_set_sha256 same_volume atomic
);
my @LOAD_RESULT_KEYS = qw(report manifest artifact);
my @SUMMARY_KEYS = qw(
    profile_count validation_records raw_measurement_records
    controller_invocations sample_exclusions qualified_profiles
);
my @NONCLAIMS = qw(
    promoted_performance_gate
    observed_performance_result
    support_promotion
    architecture_scale_capacity
    historical_artifact_reuse
    producer_execution
    provider_execution
    simulator_execution
    measurement_controller_execution
    profile_capture_or_resume
);
my $EXPECTED_SUMMARY = {
    profile_count => $PROFILE_COUNT,
    validation_records => $VALIDATION_RECORDS,
    raw_measurement_records => $RAW_MEASUREMENT_RECORDS,
    controller_invocations => $CONTROLLER_INVOCATIONS,
    sample_exclusions => 0,
    qualified_profiles => $PROFILE_COUNT,
};
my $PUBLICATION_CONTRACT = {
    schema => $CONTRACT_SCHEMA,
    schema_version => 1,
    predecessor => {
        status => 'none_initial_version',
        publication_identity => undef,
    },
    replacement_policy => {
        version => 'immutable_new_version_only',
        overwrite => JSON::PP::false,
    },
    recalibration => {
        authority => 'separately_owned_task_tree_leaf',
        evidence => 'old_and_new_current_corpus_qualifications',
        trigger =>
            'environment_or_deterministic_behavior_or_formula_change',
    },
    rollback => {
        authority =>
            'remove_consumers_and_gates_before_publication_retirement',
        publication_mutation => JSON::PP::false,
    },
    enforcement_state => 'not_activated',
};
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub manifest_keys($class) {
    _exact_invocant($class, 'manifest_keys');
    return [@MANIFEST_KEYS];
}

sub profile_binding_keys($class) {
    _exact_invocant($class, 'profile_binding_keys');
    return [@PROFILE_BINDING_KEYS];
}

sub artifact_keys($class) {
    _exact_invocant($class, 'artifact_keys');
    return [@ARTIFACT_KEYS];
}

sub load_result_keys($class) {
    _exact_invocant($class, 'load_result_keys');
    return [@LOAD_RESULT_KEYS];
}

sub publication_contract($class) {
    _exact_invocant($class, 'publication_contract');
    return _clone($PUBLICATION_CONTRACT);
}

sub publication_limits($class) {
    _exact_invocant($class, 'publication_limits');
    return {
        publication_revision => $PUBLICATION_REVISION,
        report_filename => $REPORT_FILENAME,
        manifest_filename => $MANIFEST_FILENAME,
        maximum_report_bytes => $MAX_REPORT_BYTES,
        maximum_manifest_bytes => $MAX_MANIFEST_BYTES,
        maximum_recovery_entries => 1,
        profile_count => $PROFILE_COUNT,
        validation_records => $VALIDATION_RECORDS,
        raw_measurement_records => $RAW_MEASUREMENT_RECORDS,
        controller_invocations => $CONTROLLER_INVOCATIONS,
    };
}

sub publish($class, @args) {
    _exact_invocant($class, 'publish');
    my $request = _request('publish', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repository_root, $root_device) =
        _repository_root($request->{repository_root});
    my $publisher_revision = _require_clean_revision($repository_root);
    my @staging = _staging_candidates({
        repository_root => $repository_root,
        root_device => $root_device,
    });
    my (undef, $target_abs) = _target_directory({
        repository_root => $repository_root,
        root_device => $root_device,
    });
    if ((-e $target_abs || -l $target_abs) && !@staging) {
        my $qualification = _derive_qualification($repository_root);
        my (undef, undef, $artifact) = _read_publication({
            repository_root => $repository_root,
            root_device => $root_device,
            qualification => $qualification,
        });
        _require_unchanged_clean_revision(
            $repository_root, $publisher_revision,
        );
        $artifact->{status} = 'unchanged';
        return _clone($artifact);
    }
    my $qualification = _derive_qualification($repository_root);
    my ($report, $manifest, $report_bytes, $manifest_bytes) =
        _publication_value({
            qualification => $qualification,
            publisher_revision => $publisher_revision,
        });
    _require_unchanged_clean_revision($repository_root, $publisher_revision);
    my $artifact = _publish({
        repository_root => $repository_root,
        root_device => $root_device,
        qualification => $qualification,
        report => $report,
        manifest => $manifest,
        report_bytes => $report_bytes,
        manifest_bytes => $manifest_bytes,
    });
    _require_unchanged_clean_revision($repository_root, $publisher_revision);
    return _clone($artifact);
}

sub load($class, @args) {
    _exact_invocant($class, 'load');
    my $request = _request('load', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repository_root, $root_device) =
        _repository_root($request->{repository_root});
    confess "regression-promotion qualification retained staging residue\n"
        if _staging_candidates({
            repository_root => $repository_root,
            root_device => $root_device,
        });
    my $qualification = _derive_qualification($repository_root);
    my ($report, $manifest, $artifact) = _read_publication({
        repository_root => $repository_root,
        root_device => $root_device,
        qualification => $qualification,
    });
    return _clone({
        report => $report,
        manifest => $manifest,
        artifact => $artifact,
    });
}

sub _derive_qualification($repository_root) {
    my $qualification = $QUALIFICATION->derive({
        repository_root => $repository_root,
    });
    _validate_qualification($qualification);
    return $qualification;
}

sub _publication_value($raw) {
    _validate_qualification($raw->{qualification});
    confess "regression-promotion qualification publisher revision is invalid\n"
        unless defined($raw->{publisher_revision})
            && !ref($raw->{publisher_revision})
            && $raw->{publisher_revision} =~ /\A[0-9a-f]{40}\z/;
    my $report = {
        schema => $REPORT_SCHEMA,
        schema_version => 1,
        publication_report_identity => undef,
        publisher_revision => $raw->{publisher_revision},
        qualification => _clone($raw->{qualification}),
        publication_contract => _clone($PUBLICATION_CONTRACT),
        outcome => 'accepted_published_qualification',
        diagnostics => [],
        explicit_nonclaims => [@NONCLAIMS],
    };
    $report->{publication_report_identity} =
        'regression-promotion-budget-qualification-report/'
        . sha256_hex(_canonical_json($report));
    _validate_report($report, $raw->{qualification});
    my $report_bytes = _canonical_json($report) . "\n";
    _require_bounded_bytes($report_bytes, $MAX_REPORT_BYTES, 'report');

    my $manifest = {
        schema => $MANIFEST_SCHEMA,
        schema_version => 1,
        publication_identity => undef,
        publication_report_identity =>
            $report->{publication_report_identity},
        qualification_identity =>
            $raw->{qualification}{qualification_identity},
        publisher_revision => $raw->{publisher_revision},
        source_evidence => _clone(
            $raw->{qualification}{source_evidence},
        ),
        formula_authority =>
            $raw->{qualification}{formula}{authority},
        profile_bindings =>
            _profile_bindings($raw->{qualification}{profiles}),
        publication_contract => _clone($PUBLICATION_CONTRACT),
        report_artifact => {
            relative_path => "$PUBLICATION_RELATIVE/$REPORT_FILENAME",
            sha256 => sha256_hex($report_bytes),
            bytes => bytes::length($report_bytes),
        },
        summary => _clone($raw->{qualification}{summary}),
        outcome => 'accepted_published_qualification',
        explicit_nonclaims => [@NONCLAIMS],
    };
    $manifest->{publication_identity} =
        'regression-promotion-budget-qualification-publication/'
        . sha256_hex(_canonical_json($manifest));
    _validate_manifest(
        $manifest, $report, $raw->{qualification}, $report_bytes,
    );
    my $manifest_bytes = _canonical_json($manifest) . "\n";
    _require_bounded_bytes(
        $manifest_bytes, $MAX_MANIFEST_BYTES, 'manifest',
    );
    return (
        _clone($report), _clone($manifest),
        $report_bytes, $manifest_bytes,
    );
}

sub _profile_bindings($profiles) {
    confess "regression-promotion qualification profiles changed\n"
        unless ref($profiles) eq 'ARRAY' && @$profiles == $PROFILE_COUNT;
    my @bindings;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $profile = $profiles->[$index];
        confess "regression-promotion qualification profile binding is invalid\n"
            unless ref($profile) eq 'HASH'
                && !blessed($profile)
                && _json_integer_equals($profile->{ordinal}, $index + 1);
        my $binding = {
            ordinal => $profile->{ordinal},
            selection_key => $profile->{selection_key},
            profile_qualification_identity =>
                $profile->{profile_qualification_identity},
            source_report_identity => $profile->{source_report_identity},
            workload_identity => $profile->{workload_identity},
            evidence_revision => $profile->{evidence_revision},
            environment_identity => $profile->{environment_identity},
            correctness_projection_identity =>
                $profile->{correctness_projection_identity},
            performance_applicability_identity =>
                $profile->{performance_applicability_identity},
            qualified_budget => _clone($profile->{qualified_budget}),
            provider_status => _clone($profile->{provider_status}),
        };
        _exact_keys(
            $binding, \@PROFILE_BINDING_KEYS,
            'regression-promotion qualification profile binding',
        );
        push @bindings, $binding;
    }
    return \@bindings;
}

sub _validate_qualification($qualification) {
    _exact_keys(
        $qualification, $QUALIFICATION->report_keys,
        'regression-promotion qualification source report',
    );
    confess "regression-promotion qualification source schema changed\n"
        unless ($qualification->{schema} // '') eq $QUALIFICATION_SCHEMA
            && _json_integer_equals($qualification->{schema_version}, 1);
    my $validator = $QUALIFICATION->can('_validate_qualification_report')
        or confess "regression-promotion qualification validator is unavailable\n";
    $validator->($qualification);
    confess "regression-promotion qualification source identity is invalid\n"
        unless ($qualification->{qualification_identity} // '') =~
            m{\Aregression-promotion-qualification/[0-9a-f]{64}\z};
    confess "regression-promotion qualification source summary changed\n"
        unless _canonical_json($qualification->{summary}) eq
            _canonical_json($EXPECTED_SUMMARY);
    confess "regression-promotion qualification source formula authority changed\n"
        unless ($qualification->{formula}{authority} // '') eq
            'decision-0056';
    confess "regression-promotion qualification source outcome changed\n"
        unless ($qualification->{outcome} // '') eq
            'accepted_qualified_unpublished';
    _profile_bindings($qualification->{profiles});
    return 1;
}

sub _validate_report($report, $qualification) {
    _exact_keys(
        $report, \@REPORT_KEYS,
        'regression-promotion qualification publication report',
    );
    confess "regression-promotion qualification publication report schema is invalid\n"
        unless ($report->{schema} // '') eq $REPORT_SCHEMA
            && _json_integer_equals($report->{schema_version}, 1)
            && ($report->{publisher_revision} // '') =~
                /\A[0-9a-f]{40}\z/;
    my $projection = _clone($report);
    my $identity = $projection->{publication_report_identity};
    $projection->{publication_report_identity} = undef;
    confess "regression-promotion qualification publication report identity changed\n"
        unless defined($identity) && !ref($identity)
            && $identity eq
                'regression-promotion-budget-qualification-report/'
                . sha256_hex(_canonical_json($projection));
    _validate_qualification($report->{qualification});
    confess "regression-promotion current qualification changed\n"
        unless _canonical_json($report->{qualification}) eq
            _canonical_json($qualification);
    _validate_publication_contract($report->{publication_contract});
    confess "regression-promotion qualification publication outcome changed\n"
        unless ($report->{outcome} // '') eq
                'accepted_published_qualification'
            && ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}}
            && _canonical_json($report->{explicit_nonclaims}) eq
                _canonical_json(\@NONCLAIMS);
    return 1;
}

sub _validate_manifest(
    $manifest, $report, $qualification, $report_bytes,
) {
    _exact_keys(
        $manifest, \@MANIFEST_KEYS,
        'regression-promotion qualification manifest',
    );
    confess "regression-promotion qualification manifest schema is invalid\n"
        unless ($manifest->{schema} // '') eq $MANIFEST_SCHEMA
            && _json_integer_equals($manifest->{schema_version}, 1);
    my $projection = _clone($manifest);
    my $identity = $projection->{publication_identity};
    $projection->{publication_identity} = undef;
    confess "regression-promotion qualification manifest identity changed\n"
        unless defined($identity) && !ref($identity)
            && $identity eq
                'regression-promotion-budget-qualification-publication/'
                . sha256_hex(_canonical_json($projection));
    confess "regression-promotion qualification manifest binding changed\n"
        unless ($manifest->{publication_report_identity} // '') eq
                $report->{publication_report_identity}
            && ($manifest->{qualification_identity} // '') eq
                $qualification->{qualification_identity}
            && ($manifest->{publisher_revision} // '') eq
                $report->{publisher_revision}
            && ($manifest->{formula_authority} // '') eq 'decision-0056'
            && ($manifest->{outcome} // '') eq
                'accepted_published_qualification';
    confess "regression-promotion qualification source evidence binding changed\n"
        unless _canonical_json($manifest->{source_evidence}) eq
            _canonical_json($qualification->{source_evidence});
    confess "regression-promotion qualification profile bindings changed\n"
        unless _canonical_json($manifest->{profile_bindings}) eq
            _canonical_json(_profile_bindings($qualification->{profiles}));
    _validate_publication_contract($manifest->{publication_contract});
    _exact_keys(
        $manifest->{report_artifact}, \@REPORT_ARTIFACT_KEYS,
        'regression-promotion qualification manifest report artifact',
    );
    confess "regression-promotion qualification manifest report artifact changed\n"
        unless ($manifest->{report_artifact}{relative_path} // '') eq
                "$PUBLICATION_RELATIVE/$REPORT_FILENAME"
            && ($manifest->{report_artifact}{sha256} // '') eq
                sha256_hex($report_bytes)
            && _json_integer_equals(
                $manifest->{report_artifact}{bytes},
                bytes::length($report_bytes),
            );
    confess "regression-promotion qualification manifest summary changed\n"
        unless _canonical_json($manifest->{summary}) eq
                _canonical_json($qualification->{summary})
            && _canonical_json($manifest->{summary}) eq
                _canonical_json($EXPECTED_SUMMARY);
    confess "regression-promotion qualification manifest nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims}) eq
            _canonical_json(\@NONCLAIMS);
    return 1;
}

sub _validate_publication_contract($contract) {
    _exact_keys(
        $contract, \@CONTRACT_KEYS,
        'regression-promotion qualification publication contract',
    );
    _exact_keys(
        $contract->{predecessor}, \@PREDECESSOR_KEYS,
        'regression-promotion qualification predecessor contract',
    );
    _exact_keys(
        $contract->{replacement_policy}, \@REPLACEMENT_KEYS,
        'regression-promotion qualification replacement contract',
    );
    _exact_keys(
        $contract->{recalibration}, \@RECALIBRATION_KEYS,
        'regression-promotion qualification recalibration contract',
    );
    _exact_keys(
        $contract->{rollback}, \@ROLLBACK_KEYS,
        'regression-promotion qualification rollback contract',
    );
    confess "regression-promotion qualification publication contract changed\n"
        unless _canonical_json($contract) eq
            _canonical_json($PUBLICATION_CONTRACT);
    return 1;
}

sub _publish($raw) {
    my $file_set_digest = _file_set_digest(
        $raw->{report_bytes}, $raw->{manifest_bytes},
    );
    my ($target_rel, $target_abs) = _target_directory($raw);
    my ($stage_rel, $stage_abs) =
        _staging_directory($raw, $file_set_digest);
    my @candidates = _staging_candidates($raw);
    confess "regression-promotion qualification recovery state is ambiguous\n"
        if @candidates > 1
            || (@candidates == 1 && $candidates[0] ne $stage_rel);

    if (-e $target_abs || -l $target_abs) {
        confess "regression-promotion qualification retained staging residue\n"
            if @candidates;
        my (undef, undef, $artifact,
            $existing_report_bytes, $existing_manifest_bytes) =
            _read_publication($raw);
        confess "regression-promotion qualification publication collision\n"
            unless $existing_report_bytes eq $raw->{report_bytes}
                && $existing_manifest_bytes eq $raw->{manifest_bytes};
        $artifact->{status} = 'unchanged';
        return $artifact;
    }

    if (@candidates) {
        _require_exact_stage(
            $stage_abs, $raw->{root_device},
            $raw->{report_bytes}, $raw->{manifest_bytes},
        );
        my @created;
        _ensure_directory_path(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel), \@created,
        );
        _sync_directory(dirname($target_abs), $raw->{root_device});
        unless (rename($stage_abs, $target_abs)) {
            _remove_empty_directories(\@created);
            confess "cannot recover regression-promotion qualification publication\n";
        }
        _sync_directory(dirname($target_abs), $raw->{root_device});
        _prune_staging_parents(
            $raw->{repository_root}, dirname($stage_abs),
        );
        my (undef, undef, $artifact,
            $reloaded_report, $reloaded_manifest) =
            _read_publication($raw);
        confess "regression-promotion qualification recovery bytes changed\n"
            unless $reloaded_report eq $raw->{report_bytes}
                && $reloaded_manifest eq $raw->{manifest_bytes};
        $artifact->{status} = 'recovered';
        return $artifact;
    }

    my ($created_stage, $created_target, $stage_identity) = ([], [], undef);
    my $published = eval {
        ($stage_abs, $created_stage, $stage_identity) = _create_stage(
            $raw->{repository_root}, $raw->{root_device}, $stage_rel,
        );
        _write_synced_file(
            File::Spec->catfile($stage_abs, $REPORT_FILENAME),
            $raw->{root_device}, $raw->{report_bytes}, 'report',
        );
        _write_synced_file(
            File::Spec->catfile($stage_abs, $MANIFEST_FILENAME),
            $raw->{root_device}, $raw->{manifest_bytes}, 'manifest',
        );
        _require_exact_stage(
            $stage_abs, $raw->{root_device},
            $raw->{report_bytes}, $raw->{manifest_bytes},
        );
        _sync_directory($stage_abs, $raw->{root_device});
        _ensure_directory_path(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel), $created_target,
        );
        _sync_directory(dirname($target_abs), $raw->{root_device});
        confess "regression-promotion qualification publication target appeared\n"
            if -e $target_abs || -l $target_abs;
        rename($stage_abs, $target_abs)
            or confess "cannot atomically publish regression-promotion qualification\n";
        _sync_directory(dirname($target_abs), $raw->{root_device});
        1;
    };
    if (!$published) {
        my $error = $@;
        my $cleanup_error;
        if (defined($stage_identity)
                && (-e $stage_abs || -l $stage_abs)) {
            my $cleaned = eval {
                _remove_owned_stage(
                    $stage_abs, $raw->{root_device}, $stage_identity,
                );
                1;
            };
            $cleanup_error = $@ unless $cleaned;
        }
        _remove_empty_directories($created_stage);
        _remove_empty_directories($created_target);
        die $error unless defined($cleanup_error) && length($cleanup_error);
        die $error . "regression-promotion qualification cleanup residue: "
            . $cleanup_error;
    }
    _remove_empty_directories($created_stage);
    my (undef, undef, $artifact,
        $reloaded_report, $reloaded_manifest) = _read_publication($raw);
    confess "regression-promotion qualification publication bytes changed\n"
        unless $reloaded_report eq $raw->{report_bytes}
            && $reloaded_manifest eq $raw->{manifest_bytes};
    $artifact->{status} = 'published';
    return $artifact;
}

sub _read_publication($raw) {
    my ($target_rel, $target_abs) = _target_directory($raw);
    my ($report_bytes, $manifest_bytes, $report_stat, $manifest_stat) =
        _read_exact_file_set($target_abs, $raw->{root_device});
    my $report = _decode_canonical_json($report_bytes, 'report');
    my $manifest = _decode_canonical_json($manifest_bytes, 'manifest');
    _validate_report($report, $raw->{qualification});
    _validate_manifest(
        $manifest, $report, $raw->{qualification}, $report_bytes,
    );
    my $artifact = _artifact({
        status => 'loaded',
        target_rel => $target_rel,
        report_bytes => $report_bytes,
        manifest_bytes => $manifest_bytes,
        report_stat => $report_stat,
        manifest_stat => $manifest_stat,
    });
    return (
        $report, $manifest, $artifact, $report_bytes, $manifest_bytes,
    );
}

sub _decode_canonical_json($bytes, $label) {
    confess "regression-promotion qualification $label is not newline-terminated\n"
        unless $bytes =~ /\n\z/;
    my $value = eval { JSON::PP->new->utf8(1)->decode($bytes) };
    confess "regression-promotion qualification $label JSON is invalid\n"
        if $@ || !defined($value);
    confess "regression-promotion qualification $label JSON is not canonical\n"
        unless _canonical_json($value) . "\n" eq $bytes;
    return $value;
}

sub _artifact($raw) {
    my $artifact = {
        schema => $ARTIFACT_SCHEMA,
        schema_version => 1,
        status => $raw->{status},
        publication_relative_path => $raw->{target_rel},
        report_artifact => {
            relative_path => "$raw->{target_rel}/$REPORT_FILENAME",
            sha256 => sha256_hex($raw->{report_bytes}),
            bytes => $raw->{report_stat}[7],
        },
        manifest_artifact => {
            relative_path => "$raw->{target_rel}/$MANIFEST_FILENAME",
            sha256 => sha256_hex($raw->{manifest_bytes}),
            bytes => $raw->{manifest_stat}[7],
        },
        file_set_sha256 => _file_set_digest(
            $raw->{report_bytes}, $raw->{manifest_bytes},
        ),
        same_volume => JSON::PP::true,
        atomic => JSON::PP::true,
    };
    _exact_keys(
        $artifact, \@ARTIFACT_KEYS,
        'regression-promotion qualification artifact',
    );
    confess "regression-promotion qualification artifact status is invalid\n"
        unless $artifact->{status} =~
            /\A(?:loaded|published|recovered|unchanged)\z/;
    return $artifact;
}

sub _target_directory($raw) {
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device},
        $PUBLICATION_RELATIVE,
    );
    return ($PUBLICATION_RELATIVE, $target_abs);
}

sub _staging_directory($raw, $digest) {
    confess "regression-promotion qualification file-set digest is invalid\n"
        unless defined($digest) && !ref($digest)
            && $digest =~ /\A[0-9a-f]{64}\z/;
    my $stage_rel = "$STAGING_BASE/qualification-$digest";
    my $stage_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $stage_rel,
    );
    return ($stage_rel, $stage_abs);
}

sub _staging_candidates($raw) {
    my $base_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $STAGING_BASE,
    );
    return () unless -e $base_abs || -l $base_abs;
    _require_directory($base_abs, $raw->{root_device}, 'staging base');
    opendir my $dh, $base_abs
        or confess "cannot inspect regression-promotion qualification staging\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close regression-promotion qualification staging\n";
    confess "regression-promotion qualification staging entry is invalid\n"
        if grep { !/^qualification-[0-9a-f]{64}\z/ } @entries;
    return map { "$STAGING_BASE/$_" } @entries;
}

sub _read_exact_file_set($root, $root_device) {
    my $root_stat =
        _require_directory($root, $root_device, 'publication root');
    opendir my $dh, $root
        or confess "cannot inspect regression-promotion qualification publication\n";
    my @opened_stat = stat($dh);
    confess "regression-promotion qualification publication directory changed\n"
        unless @opened_stat && -d _
            && _same_identity($root_stat, \@opened_stat);
    my @expected = sort ($REPORT_FILENAME, $MANIFEST_FILENAME);
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    confess "regression-promotion qualification publication census changed\n"
        unless _canonical_json(\@entries) eq _canonical_json(\@expected);
    my ($report_bytes, $report_stat) = _read_exact_file(
        File::Spec->catfile($root, $REPORT_FILENAME),
        $root_device, $MAX_REPORT_BYTES, 'report',
    );
    my ($manifest_bytes, $manifest_stat) = _read_exact_file(
        File::Spec->catfile($root, $MANIFEST_FILENAME),
        $root_device, $MAX_MANIFEST_BYTES, 'manifest',
    );
    rewinddir $dh;
    my @final_entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    my @final_handle_stat = stat($dh);
    my @final_path_stat = lstat($root);
    closedir $dh
        or confess "cannot close regression-promotion qualification publication\n";
    confess "regression-promotion qualification publication census changed\n"
        unless _canonical_json(\@final_entries) eq
            _canonical_json(\@expected);
    confess "regression-promotion qualification publication directory changed\n"
        unless @final_handle_stat && @final_path_stat
            && !-l _ && -d _
            && _same_identity(\@opened_stat, \@final_handle_stat)
            && _same_identity(\@opened_stat, \@final_path_stat);
    return (
        $report_bytes, $manifest_bytes, $report_stat, $manifest_stat,
    );
}

sub _read_exact_file($path, $root_device, $maximum, $label) {
    my @path_stat = lstat($path);
    confess "regression-promotion qualification $label artifact is invalid\n"
        unless @path_stat && !-l _ && -f _;
    confess "regression-promotion qualification $label crossed repository volume\n"
        unless $path_stat[0] == $root_device;
    confess "regression-promotion qualification $label artifact owner changed\n"
        unless $path_stat[4] == $<;
    confess "regression-promotion qualification $label artifact is hard-linked\n"
        unless $path_stat[3] == 1;
    _require_bounded_size($path_stat[7], $maximum, $label);
    sysopen(my $fh, $path, O_RDONLY | O_NOFOLLOW)
        or confess "cannot open regression-promotion qualification $label artifact\n";
    binmode($fh, ':raw')
        or confess "cannot set regression-promotion qualification byte mode\n";
    my @handle_stat = stat($fh);
    confess "regression-promotion qualification $label artifact changed\n"
        unless @handle_stat && -f _
            && _same_identity(\@path_stat, \@handle_stat)
            && $handle_stat[3] == 1;
    my $encoded = '';
    while (bytes::length($encoded) <= $maximum) {
        my $remaining = $maximum + 1 - bytes::length($encoded);
        last if $remaining <= 0;
        my $chunk = '';
        my $read = sysread($fh, $chunk, $remaining);
        if (!defined $read) {
            next if $! == EINTR;
            confess "cannot read regression-promotion qualification $label artifact\n";
        }
        last if $read == 0;
        $encoded .= $chunk;
    }
    _require_bounded_bytes($encoded, $maximum, $label);
    my @final_handle_stat = stat($fh);
    close $fh
        or confess "cannot close regression-promotion qualification $label artifact\n";
    my @final_path_stat = lstat($path);
    confess "regression-promotion qualification $label artifact changed while reading\n"
        unless bytes::length($encoded) == $path_stat[7]
            && @final_handle_stat && @final_path_stat
            && _same_identity(\@path_stat, \@final_handle_stat)
            && _same_identity(\@path_stat, \@final_path_stat);
    return ($encoded, \@path_stat);
}

sub _require_exact_stage(
    $root, $root_device, $expected_report, $expected_manifest,
) {
    my ($report, $manifest) =
        _read_exact_file_set($root, $root_device);
    confess "regression-promotion qualification staging is not recoverable\n"
        unless $report eq $expected_report
            && $manifest eq $expected_manifest;
    return 1;
}

sub _create_stage($repository_root, $root_device, $relative) {
    my @created;
    my $path = $repository_root;
    my @parts = split m{/}, _safe_relative_path($relative);
    my $ok = eval {
        for my $index (0 .. $#parts) {
            $path = File::Spec->catdir($path, $parts[$index]);
            if (-e $path || -l $path) {
                _require_directory(
                    $path, $root_device, 'staging component',
                );
                confess "regression-promotion qualification staging root already exists\n"
                    if $index == $#parts;
            }
            else {
                mkdir($path, 0700)
                    or confess "cannot create regression-promotion qualification staging directory\n";
                push @created, $path;
                _require_directory(
                    $path, $root_device, 'staging component',
                );
            }
        }
        1;
    };
    if (!$ok) {
        my $error = $@;
        _remove_empty_directories(\@created);
        die $error;
    }
    my @stat = lstat($path);
    return ($path, \@created, [@stat[0, 1, 4]]);
}

sub _write_synced_file($path, $root_device, $encoded, $label) {
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
        or confess "cannot create regression-promotion qualification $label\n";
    binmode($fh, ':raw')
        or confess "cannot set regression-promotion qualification byte mode\n";
    print {$fh} $encoded
        or confess "cannot write regression-promotion qualification $label\n";
    $fh->flush
        or confess "cannot flush regression-promotion qualification $label\n";
    $fh->sync
        or confess "cannot sync regression-promotion qualification $label\n";
    my @stat = stat($fh);
    confess "regression-promotion qualification $label crossed repository volume\n"
        unless @stat && -f _ && $stat[0] == $root_device
            && $stat[3] == 1 && $stat[4] == $<;
    close $fh
        or confess "cannot close regression-promotion qualification $label\n";
    return 1;
}

sub _sync_directory($path, $root_device) {
    my $path_stat =
        _require_directory($path, $root_device, 'directory sync target');
    sysopen(my $fh, $path, O_RDONLY | O_NOFOLLOW)
        or confess "cannot open regression-promotion qualification directory for sync\n";
    my @stat = stat($fh);
    confess "regression-promotion qualification sync target is invalid\n"
        unless @stat && -d _ && $stat[0] == $root_device
            && _same_identity($path_stat, \@stat);
    $fh->sync
        or confess "cannot sync regression-promotion qualification directory\n";
    close $fh
        or confess "cannot close regression-promotion qualification directory\n";
    my @final_stat = lstat($path);
    confess "regression-promotion qualification sync target changed\n"
        unless @final_stat && !-l _ && -d _
            && _same_identity(\@stat, \@final_stat);
    return 1;
}

sub _remove_owned_stage($path, $root_device, $identity) {
    my @root_stat = lstat($path);
    confess "regression-promotion qualification staging cleanup identity changed\n"
        unless @root_stat && !-l _ && -d _
            && $root_stat[0] == $identity->[0]
            && $root_stat[1] == $identity->[1]
            && $root_stat[4] == $identity->[2]
            && $root_stat[0] == $root_device;
    opendir my $dh, $path
        or confess "cannot inspect regression-promotion qualification cleanup\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close regression-promotion qualification cleanup\n";
    my @allowed = sort ($REPORT_FILENAME, $MANIFEST_FILENAME);
    my %allowed = map { $_ => 1 } @allowed;
    confess "regression-promotion qualification cleanup census is unsafe\n"
        if @entries > @allowed || grep { !$allowed{$_} } @entries;
    for my $entry (@entries) {
        my $artifact = File::Spec->catfile($path, $entry);
        my @stat = lstat($artifact);
        confess "regression-promotion qualification cleanup artifact is unsafe\n"
            unless @stat && !-l _ && -f _
                && $stat[0] == $root_device
                && $stat[3] == 1 && $stat[4] == $<;
        unlink($artifact)
            or confess "cannot remove regression-promotion qualification cleanup artifact\n";
    }
    rmdir($path)
        or confess "cannot remove regression-promotion qualification staging root\n";
    confess "regression-promotion qualification staging remains after cleanup\n"
        if -e $path || -l $path;
    return 1;
}

sub _ensure_directory_path(
    $repository_root, $root_device, $absolute, $relative, $created,
) {
    my $path = $repository_root;
    for my $part (split m{/}, _safe_relative_path($relative)) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            _require_directory($path, $root_device, 'publication parent');
        }
        else {
            mkdir($path, 0700)
                or confess "cannot create regression-promotion qualification publication parent\n";
            push @$created, $path;
            _require_directory($path, $root_device, 'publication parent');
        }
    }
    confess "regression-promotion qualification publication parent mismatch\n"
        unless $path eq $absolute;
    return 1;
}

sub _require_directory($path, $root_device, $label) {
    my @stat = lstat($path);
    confess "regression-promotion qualification $label is not a real directory\n"
        unless @stat && !-l _ && -d _;
    confess "regression-promotion qualification $label crossed repository volume\n"
        unless $stat[0] == $root_device;
    confess "regression-promotion qualification $label owner changed\n"
        unless $stat[4] == $<;
    return \@stat;
}

sub _safe_destination($repository_root, $root_device, $relative) {
    _safe_relative_path($relative);
    my $path = $repository_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            _require_directory(
                $path, $root_device, 'destination component',
            );
        }
    }
    return $path;
}

sub _safe_relative_path($path) {
    confess "regression-promotion qualification path is unsafe\n"
        unless defined($path) && !ref($path) && length($path)
            && !File::Spec->file_name_is_absolute($path)
            && $path !~ m{(?:\A|/)[.][.](?:/|\z)}
            && $path !~ m{//}
            && $path !~ m{/\z};
    return $path;
}

sub _repository_root($value) {
    confess "regression-promotion qualification repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "regression-promotion qualification repository root is unavailable\n"
        unless defined($root) && -d $root && !-l $root;
    my $git = File::Spec->catfile($root, '.git');
    confess "regression-promotion qualification repository Git identity is invalid\n"
        unless (-d $git || -f $git) && !-l $git;
    my @stat = lstat($root);
    confess "regression-promotion qualification repository root cannot be inspected\n"
        unless @stat && !-l _ && -d _;
    confess "regression-promotion qualification repository root owner changed\n"
        unless $stat[4] == $<;
    return ($root, $stat[0]);
}

sub _require_active_guard() {
    confess "regression-promotion qualification publication requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1'
            && ($ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} // '') =~
                /\A[0-9]+\z/
            && ($ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} // '') =~
                /\A[0-9]+\z/;
    return 1;
}

sub _require_clean_revision($repository_root) {
    my $revision = _capture_command(
        'git', '-C', $repository_root, 'rev-parse', '--verify', 'HEAD',
    );
    $revision =~ s/\s+\z//;
    confess "regression-promotion qualification publisher revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my $status = _capture_command(
        'git', '-C', $repository_root, 'status', '--porcelain=v1',
        '--untracked-files=all',
    );
    confess "regression-promotion qualification publication requires a clean Git revision\n"
        if length($status);
    return $revision;
}

sub _require_unchanged_clean_revision($repository_root, $expected) {
    my $actual = _require_clean_revision($repository_root);
    confess "regression-promotion qualification publisher revision changed\n"
        unless $actual eq $expected;
    return 1;
}

sub _capture_command(@command) {
    open my $fh, '-|', @command
        or confess "cannot execute regression-promotion qualification Git probe\n";
    local $/;
    my $output = <$fh> // '';
    close $fh
        or confess "regression-promotion qualification Git probe failed\n";
    return $output;
}

sub _prune_staging_parents($repository_root, $path) {
    my $stop = File::Spec->catdir(
        $repository_root, split m{/}, '.artifacts/tmp',
    );
    while ($path ne $repository_root && index($path, "$stop/") == 0) {
        last unless -d $path && !-l $path && rmdir($path);
        $path = dirname($path);
    }
}

sub _remove_empty_directories($paths) {
    for my $path (reverse @{$paths // []}) {
        next unless -d $path && !-l $path;
        rmdir($path);
    }
}

sub _same_identity($left, $right) {
    for my $index (0, 1, 2, 3, 4, 7, 9, 10) {
        return 0 unless $left->[$index] == $right->[$index];
    }
    return 1;
}

sub _require_bounded_size($actual, $maximum, $label) {
    confess "regression-promotion qualification $label exceeds its bounded ceiling "
        . "(actual=$actual bytes, maximum=$maximum bytes)\n"
        unless defined($actual) && $actual > 0 && $actual <= $maximum;
    return 1;
}

sub _require_bounded_bytes($encoded, $maximum, $label) {
    _require_bounded_size(
        bytes::length($encoded), $maximum, $label,
    );
    return 1;
}

sub _file_set_digest($report_bytes, $manifest_bytes) {
    return sha256_hex(join "\0",
        bytes::length($report_bytes), $report_bytes,
        bytes::length($manifest_bytes), $manifest_bytes,
    );
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
            unless exists $args->[0]{$key};
    }
    return $args->[0];
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be a hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    for my $key (keys %$value) {
        confess "$label contains unknown key '$key'\n"
            unless $expected{$key};
    }
    for my $key (@$keys) {
        confess "$label is missing '$key'\n"
            unless exists $value->{$key};
    }
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _json_integer_equals($actual, $expected) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) eq "$expected";
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
