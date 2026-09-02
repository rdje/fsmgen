package FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore;

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

use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

my $PLAN = 'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $PROFILE_CAPTURE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture';
my $PROFILE_STORE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $REPORT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1';
my $MANIFEST_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus_manifest.v1';
my $ARTIFACT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus_artifact.v1';
my $PROFILE_RESULT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_capture.v1';
my $PROFILE_ARTIFACT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_artifact.v1';
my $PUBLICATION_REVISION = 'regression_promotion_corpus_store_v1';
my $REPORT_FILENAME = 'regression-promotion-corpus.json';
my $MANIFEST_FILENAME = 'corpus-manifest.json';
my $STAGING_BASE =
    '.artifacts/tmp/vial-scale/regression-promotion-corpus-publication/v1';
my $MAX_REPORT_BYTES = 1_048_576;
my $MAX_MANIFEST_BYTES = 65_536;
my $PROFILE_COUNT = 11;
my $VALIDATION_RECORDS = 11;
my $RAW_MEASUREMENT_RECORDS = 33;
my $CONTROLLER_INVOCATIONS = 44;

my @REPORT_KEYS = qw(
    schema schema_version corpus_identity plan_identity policy_identity
    publication_id publication_schema common_identity summary profiles
    explicit_nonclaims
);
my @MANIFEST_KEYS = qw(
    schema schema_version publication_identity corpus_identity
    plan_identity policy_identity publication_id report_artifact summary
    outcome explicit_nonclaims
);
my @PROFILE_KEYS = qw(
    ordinal selection_key report_identity common_identity provider_status
    applicability_status artifact
);
my @PROFILE_ARTIFACT_KEYS = qw(
    ordinal selection_key relative_path sha256 bytes same_volume atomic
);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @CORPUS_COMMON_KEYS = qw(
    git_revision dirty_state host_profile resource_guard
);
my @PROVIDER_KEYS = qw(
    kind external_verification_tool logical_name provider_identity
    tool_profile_identity
);
my @APPLICABILITY_KEYS = qw(
    required predicate controller_applicable measurement_applicable
    validation_records raw_measurement_records sample_exclusions outcome
);
my @SUMMARY_KEYS = qw(
    profile_count validation_records raw_measurement_records
    controller_invocations sample_exclusions
);
my @REPORT_ARTIFACT_KEYS = qw(relative_path sha256 bytes);
my @ARTIFACT_KEYS = qw(
    schema schema_version status publication_relative_path
    report_artifact manifest_artifact file_set_sha256 same_volume atomic
);
my @LOAD_RESULT_KEYS = qw(report manifest artifact);
my @NONCLAIMS = qw(
    producer_execution
    provider_execution
    simulator_execution
    measurement_controller_execution
    profile_capture_or_resume
    performance_budget_promotion
    support_promotion
    architecture_scale_capacity
    historical_artifact_reuse
);
my $EXPECTED_SUMMARY = {
    profile_count => $PROFILE_COUNT,
    validation_records => $VALIDATION_RECORDS,
    raw_measurement_records => $RAW_MEASUREMENT_RECORDS,
    controller_invocations => $CONTROLLER_INVOCATIONS,
    sample_exclusions => 0,
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

sub profile_keys($class) {
    _exact_invocant($class, 'profile_keys');
    return [@PROFILE_KEYS];
}

sub profile_artifact_keys($class) {
    _exact_invocant($class, 'profile_artifact_keys');
    return [@PROFILE_ARTIFACT_KEYS];
}

sub artifact_keys($class) {
    _exact_invocant($class, 'artifact_keys');
    return [@ARTIFACT_KEYS];
}

sub load_result_keys($class) {
    _exact_invocant($class, 'load_result_keys');
    return [@LOAD_RESULT_KEYS];
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
    my $request = _request(
        'publish', \@args, [qw(repository_root profiles)],
    );
    confess "regression-promotion corpus profiles must be one array\n"
        unless ref($request->{profiles}) eq 'ARRAY';
    my ($repo_root, $root_device) =
        _repository_root($request->{repository_root});
    my $plan = $PLAN->derive({repository_root => $repo_root});
    my ($report, $manifest, $report_bytes, $manifest_bytes) =
        _publication_value({
            repository_root => $repo_root,
            root_device => $root_device,
            plan => $plan,
            profiles => $request->{profiles},
        });
    return _clone(_publish({
        repository_root => $repo_root,
        root_device => $root_device,
        plan => $plan,
        report => $report,
        manifest => $manifest,
        report_bytes => $report_bytes,
        manifest_bytes => $manifest_bytes,
    }));
}

sub load($class, @args) {
    _exact_invocant($class, 'load');
    my $request = _request('load', \@args, [qw(repository_root)]);
    my ($repo_root, $root_device) =
        _repository_root($request->{repository_root});
    confess "regression-promotion corpus retained staging residue\n"
        if _staging_candidates({
            repository_root => $repo_root,
            root_device => $root_device,
        });
    my $profile_bundle = $PROFILE_STORE->load_all({
        repository_root => $repo_root,
    });
    _validate_profile_load_bundle($profile_bundle);
    my $plan = $profile_bundle->{plan};
    my ($report, $manifest, $artifact) = _read_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        plan => $plan,
        profile_loads => $profile_bundle->{profiles},
    }, 1);
    return _clone({
        report => $report,
        manifest => $manifest,
        artifact => $artifact,
    });
}

sub _publication_value($raw) {
    confess "regression-promotion corpus profiles must be one array\n"
        unless ref($raw->{profiles}) eq 'ARRAY';
    confess "regression-promotion corpus requires exactly $PROFILE_COUNT profiles\n"
        unless @{$raw->{profiles}} == $PROFILE_COUNT
            && @{$raw->{plan}{entries}} == $PROFILE_COUNT;
    my @profiles;
    my $common;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $entry = $raw->{plan}{entries}[$index];
        my $profile = _profile_from_result(
            $raw, $raw->{profiles}[$index], $entry,
        );
        my $candidate = _corpus_common($profile->{common_identity});
        if (!defined $common) {
            $common = $candidate;
        }
        else {
            confess "regression-promotion corpus profile common identity changed\n"
                unless _canonical_json($candidate) eq
                    _canonical_json($common);
        }
        push @profiles, $profile;
    }
    my $report = {
        schema => $REPORT_SCHEMA,
        schema_version => 1,
        corpus_identity => undef,
        plan_identity => $raw->{plan}{plan_identity},
        policy_identity => $raw->{plan}{policy_identity},
        publication_id => $raw->{plan}{publication_id},
        publication_schema => $raw->{plan}{publication_schema},
        common_identity => $common,
        summary => _clone($EXPECTED_SUMMARY),
        profiles => \@profiles,
        explicit_nonclaims => [@NONCLAIMS],
    };
    $report->{corpus_identity} = 'regression-promotion-corpus/'
        . sha256_hex(_canonical_json($report));
    _validate_report($report, $raw, 1);
    my $report_bytes = _canonical_json($report) . "\n";
    _require_bounded_bytes($report_bytes, $MAX_REPORT_BYTES, 'report');

    my ($target_rel) = _target_directory($raw);
    my $manifest = {
        schema => $MANIFEST_SCHEMA,
        schema_version => 1,
        publication_identity => undef,
        corpus_identity => $report->{corpus_identity},
        plan_identity => $report->{plan_identity},
        policy_identity => $report->{policy_identity},
        publication_id => $report->{publication_id},
        report_artifact => {
            relative_path => "$target_rel/$REPORT_FILENAME",
            sha256 => sha256_hex($report_bytes),
            bytes => bytes::length($report_bytes),
        },
        summary => _clone($report->{summary}),
        outcome => 'accepted',
        explicit_nonclaims => [@NONCLAIMS],
    };
    $manifest->{publication_identity} =
        'regression-promotion-corpus-publication/'
        . sha256_hex(_canonical_json($manifest));
    _validate_manifest($manifest, $report, $report_bytes, $target_rel);
    my $manifest_bytes = _canonical_json($manifest) . "\n";
    _require_bounded_bytes(
        $manifest_bytes, $MAX_MANIFEST_BYTES, 'manifest',
    );
    return (
        _clone($report), _clone($manifest),
        $report_bytes, $manifest_bytes,
    );
}

sub _profile_from_result($raw, $result, $entry) {
    _exact_keys(
        $result, $PROFILE_CAPTURE->result_keys,
        'regression-promotion corpus profile result',
    );
    confess "regression-promotion corpus profile result schema is invalid\n"
        unless ($result->{schema} // '') eq $PROFILE_RESULT_SCHEMA
            && _json_integer_equals($result->{schema_version}, 1);
    confess "regression-promotion corpus profile plan binding changed\n"
        unless ($result->{plan_identity} // '') eq
                $raw->{plan}{plan_identity}
            && ($result->{policy_identity} // '') eq
                $raw->{plan}{policy_identity};
    confess "regression-promotion corpus profile order changed\n"
        unless _json_integer_equals($result->{ordinal}, $entry->{ordinal})
            && ($result->{selection_key} // '') eq
                $entry->{selection_key};
    confess "regression-promotion corpus profile report identity is invalid\n"
        unless ($result->{report_identity} // '')
            =~ m{\A[A-Za-z0-9_.-]+/[0-9a-f]{64}\z};
    _validate_common_identity($result->{common_identity});
    _validate_provider($result->{provider_status}, $entry);
    _validate_applicability($result->{applicability_status}, $entry);
    my $artifact = _profile_artifact_from_result(
        $result->{artifact}, $entry,
    );
    my $loaded = $PROFILE_STORE->load({
        repository_root => $raw->{repository_root},
        ordinal => $entry->{ordinal},
    });
    _require_loaded_profile_match(
        $artifact, $loaded, $result->{report_identity}, $entry,
    );
    return {
        ordinal => $entry->{ordinal},
        selection_key => $entry->{selection_key},
        report_identity => $result->{report_identity},
        common_identity => _clone($result->{common_identity}),
        provider_status => _clone($result->{provider_status}),
        applicability_status => _clone($result->{applicability_status}),
        artifact => $artifact,
    };
}

sub _profile_artifact_from_result($artifact, $entry) {
    _exact_keys(
        $artifact, $PROFILE_STORE->artifact_keys,
        'regression-promotion corpus profile artifact result',
    );
    confess "regression-promotion corpus profile artifact schema is invalid\n"
        unless ($artifact->{schema} // '') eq $PROFILE_ARTIFACT_SCHEMA
            && _json_integer_equals($artifact->{schema_version}, 1)
            && ($artifact->{status} // '')
                =~ /\A(?:loaded|published|recovered|unchanged)\z/;
    confess "regression-promotion corpus profile artifact coordinate changed\n"
        unless _json_integer_equals($artifact->{ordinal}, $entry->{ordinal})
            && ($artifact->{selection_key} // '') eq
                $entry->{selection_key}
            && ($artifact->{artifact_relative_path} // '') eq
                $entry->{publication_relative_path};
    my $limits = $PROFILE_STORE->publication_limits;
    confess "regression-promotion corpus profile artifact identity is invalid\n"
        unless ($artifact->{artifact_sha256} // '') =~ /\A[0-9a-f]{64}\z/
            && _json_positive_integer($artifact->{artifact_bytes})
            && $artifact->{artifact_bytes} <=
                $limits->{maximum_publication_bytes}
            && _json_true($artifact->{same_volume})
            && _json_true($artifact->{atomic});
    return {
        ordinal => $entry->{ordinal},
        selection_key => $entry->{selection_key},
        relative_path => $artifact->{artifact_relative_path},
        sha256 => $artifact->{artifact_sha256},
        bytes => 0 + $artifact->{artifact_bytes},
        same_volume => JSON::PP::true,
        atomic => JSON::PP::true,
    };
}

sub _require_loaded_profile_match(
    $artifact, $loaded, $report_identity, $entry,
) {
    _exact_keys(
        $loaded, $PROFILE_STORE->load_result_keys,
        'regression-promotion corpus loaded profile',
    );
    my $actual = $loaded->{artifact};
    my %projection = (
        ordinal => $actual->{ordinal},
        selection_key => $actual->{selection_key},
        relative_path => $actual->{artifact_relative_path},
        sha256 => $actual->{artifact_sha256},
        bytes => $actual->{artifact_bytes},
        same_volume => $actual->{same_volume},
        atomic => $actual->{atomic},
    );
    confess "regression-promotion corpus profile artifact metadata changed\n"
        unless _canonical_json(\%projection) eq _canonical_json($artifact);
    confess "regression-promotion corpus profile report identity changed\n"
        unless ref($loaded->{publication}{report}) eq 'HASH'
            && ($loaded->{publication}{report}{report_identity} // '') eq
                $report_identity;
    confess "regression-promotion corpus profile dispatch changed\n"
        unless _json_integer_equals($actual->{ordinal}, $entry->{ordinal})
            && ($actual->{selection_key} // '') eq $entry->{selection_key};
    return 1;
}

sub _validate_profile_load_bundle($bundle) {
    _exact_keys(
        $bundle, $PROFILE_STORE->load_all_result_keys,
        'regression-promotion corpus loaded profile bundle',
    );
    _exact_keys(
        $bundle->{plan}, $PLAN->report_keys,
        'regression-promotion corpus loaded profile plan',
    );
    confess "regression-promotion corpus loaded profile bundle count changed\n"
        unless ref($bundle->{plan}{entries}) eq 'ARRAY'
            && @{$bundle->{plan}{entries}} == $PROFILE_COUNT
            && ref($bundle->{profiles}) eq 'ARRAY'
            && @{$bundle->{profiles}} == $PROFILE_COUNT;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $entry = $bundle->{plan}{entries}[$index];
        my $loaded = $bundle->{profiles}[$index];
        _exact_keys(
            $entry, $PLAN->entry_keys,
            'regression-promotion corpus loaded profile plan entry',
        );
        _exact_keys(
            $loaded, $PROFILE_STORE->load_result_keys,
            'regression-promotion corpus loaded profile',
        );
        _exact_keys(
            $loaded->{publication}, $PROFILE_STORE->publication_keys,
            'regression-promotion corpus loaded profile publication',
        );
        _exact_keys(
            $loaded->{artifact}, $PROFILE_STORE->artifact_keys,
            'regression-promotion corpus loaded profile artifact',
        );
        confess "regression-promotion corpus loaded profile order changed\n"
            unless _json_integer_equals($entry->{ordinal}, $index + 1)
                && _json_integer_equals(
                    $loaded->{artifact}{ordinal}, $entry->{ordinal},
                )
                && ($loaded->{artifact}{selection_key} // '') eq
                    $entry->{selection_key};
    }
    return 1;
}

sub _validate_report($report, $raw, $validate_profiles) {
    _exact_keys($report, \@REPORT_KEYS, 'regression-promotion corpus report');
    confess "regression-promotion corpus report schema is invalid\n"
        unless ($report->{schema} // '') eq $REPORT_SCHEMA
            && _json_integer_equals($report->{schema_version}, 1)
            && ($report->{publication_schema} // '') eq $REPORT_SCHEMA;
    confess "regression-promotion corpus report plan binding changed\n"
        unless ($report->{plan_identity} // '') eq
                $raw->{plan}{plan_identity}
            && ($report->{policy_identity} // '') eq
                $raw->{plan}{policy_identity}
            && ($report->{publication_id} // '') eq
                $raw->{plan}{publication_id};
    my $projection = _clone($report);
    my $identity = $projection->{corpus_identity};
    $projection->{corpus_identity} = undef;
    confess "regression-promotion corpus report identity changed\n"
        unless defined($identity) && !ref($identity)
            && $identity eq 'regression-promotion-corpus/'
                . sha256_hex(_canonical_json($projection));
    _exact_keys(
        $report->{common_identity}, \@CORPUS_COMMON_KEYS,
        'regression-promotion corpus common identity',
    );
    _validate_summary($report->{summary});
    confess "regression-promotion corpus report requires exactly $PROFILE_COUNT profiles\n"
        unless ref($report->{profiles}) eq 'ARRAY'
            && @{$report->{profiles}} == $PROFILE_COUNT;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $profile = $report->{profiles}[$index];
        my $entry = $raw->{plan}{entries}[$index];
        _validate_profile_value(
            $profile, $entry, $report->{common_identity}, $raw,
            $validate_profiles,
        );
    }
    confess "regression-promotion corpus nonclaims changed\n"
        unless _canonical_json($report->{explicit_nonclaims}) eq
            _canonical_json(\@NONCLAIMS);
    return 1;
}

sub _validate_profile_value(
    $profile, $entry, $corpus_common, $raw, $validate_reference,
) {
    _exact_keys(
        $profile, \@PROFILE_KEYS,
        'regression-promotion corpus profile',
    );
    confess "regression-promotion corpus profile order changed\n"
        unless _json_integer_equals($profile->{ordinal}, $entry->{ordinal})
            && ($profile->{selection_key} // '') eq $entry->{selection_key};
    confess "regression-promotion corpus profile report identity is invalid\n"
        unless ($profile->{report_identity} // '')
            =~ m{\A[A-Za-z0-9_.-]+/[0-9a-f]{64}\z};
    _validate_common_identity($profile->{common_identity});
    confess "regression-promotion corpus profile common identity changed\n"
        unless _canonical_json(_corpus_common($profile->{common_identity}))
            eq _canonical_json($corpus_common);
    _validate_provider($profile->{provider_status}, $entry);
    _validate_applicability($profile->{applicability_status}, $entry);
    _validate_profile_artifact($profile->{artifact}, $entry);
    if ($validate_reference) {
        my $loaded = exists($raw->{profile_loads})
            ? $raw->{profile_loads}[$entry->{ordinal} - 1]
            : $PROFILE_STORE->load({
                repository_root => $raw->{repository_root},
                ordinal => $entry->{ordinal},
            });
        _require_loaded_profile_match(
            $profile->{artifact}, $loaded,
            $profile->{report_identity}, $entry,
        );
    }
    return 1;
}

sub _validate_common_identity($common) {
    _exact_keys(
        $common, \@COMMON_KEYS,
        'regression-promotion corpus profile common identity',
    );
    confess "regression-promotion corpus profile Git revision is invalid\n"
        unless ($common->{git_revision} // '') =~ /\A[0-9a-f]{40}\z/;
    confess "regression-promotion corpus profile is dirty\n"
        if _json_true($common->{dirty_state});
    confess "regression-promotion corpus profile dirty state is invalid\n"
        unless _json_false($common->{dirty_state});
    confess "regression-promotion corpus profile host/tool/guard identity is invalid\n"
        unless ref($common->{host_profile}) eq 'HASH'
            && !blessed($common->{host_profile})
            && ref($common->{tool_profile}) eq 'HASH'
            && !blessed($common->{tool_profile})
            && ref($common->{resource_guard}) eq 'HASH'
            && !blessed($common->{resource_guard});
    confess "regression-promotion corpus profile resource guard is inactive\n"
        unless _json_true($common->{resource_guard}{active});
    return 1;
}

sub _corpus_common($common) {
    _validate_common_identity($common);
    return {
        git_revision => $common->{git_revision},
        dirty_state => JSON::PP::false,
        host_profile => _clone($common->{host_profile}),
        resource_guard => _clone($common->{resource_guard}),
    };
}

sub _validate_provider($provider, $entry) {
    _exact_keys(
        $provider, \@PROVIDER_KEYS,
        'regression-promotion corpus profile provider status',
    );
    confess "regression-promotion corpus profile provider status changed\n"
        unless _canonical_json($provider) eq
            _canonical_json($entry->{provider_requirement});
    return 1;
}

sub _validate_applicability($value, $entry) {
    _exact_keys(
        $value, \@APPLICABILITY_KEYS,
        'regression-promotion corpus profile applicability',
    );
    confess "regression-promotion corpus profile applicability changed\n"
        unless _json_true($value->{required})
            && ($value->{predicate} // '') eq
                $entry->{applicability_requirement}{predicate}
            && _json_true($value->{controller_applicable})
            && _json_true($value->{measurement_applicable})
            && _json_integer_equals($value->{validation_records}, 1)
            && _json_integer_equals($value->{raw_measurement_records}, 3)
            && _json_integer_equals($value->{sample_exclusions}, 0)
            && ($value->{outcome} // '') eq 'accepted';
    return 1;
}

sub _validate_profile_artifact($artifact, $entry) {
    _exact_keys(
        $artifact, \@PROFILE_ARTIFACT_KEYS,
        'regression-promotion corpus profile artifact',
    );
    confess "regression-promotion corpus profile artifact coordinate changed\n"
        unless _json_integer_equals($artifact->{ordinal}, $entry->{ordinal})
            && ($artifact->{selection_key} // '') eq $entry->{selection_key}
            && ($artifact->{relative_path} // '') eq
                $entry->{publication_relative_path};
    my $limits = $PROFILE_STORE->publication_limits;
    confess "regression-promotion corpus profile artifact identity is invalid\n"
        unless ($artifact->{sha256} // '') =~ /\A[0-9a-f]{64}\z/
            && _json_positive_integer($artifact->{bytes})
            && $artifact->{bytes} <= $limits->{maximum_publication_bytes}
            && _json_true($artifact->{same_volume})
            && _json_true($artifact->{atomic});
    return 1;
}

sub _validate_summary($summary) {
    _exact_keys(
        $summary, \@SUMMARY_KEYS,
        'regression-promotion corpus summary',
    );
    confess "regression-promotion corpus summary changed\n"
        unless _canonical_json($summary) eq
            _canonical_json($EXPECTED_SUMMARY);
    return 1;
}

sub _validate_manifest($manifest, $report, $report_bytes, $target_rel) {
    _exact_keys(
        $manifest, \@MANIFEST_KEYS,
        'regression-promotion corpus manifest',
    );
    confess "regression-promotion corpus manifest schema is invalid\n"
        unless ($manifest->{schema} // '') eq $MANIFEST_SCHEMA
            && _json_integer_equals($manifest->{schema_version}, 1);
    confess "regression-promotion corpus manifest binding changed\n"
        unless ($manifest->{corpus_identity} // '') eq
                $report->{corpus_identity}
            && ($manifest->{plan_identity} // '') eq
                $report->{plan_identity}
            && ($manifest->{policy_identity} // '') eq
                $report->{policy_identity}
            && ($manifest->{publication_id} // '') eq
                $report->{publication_id}
            && ($manifest->{outcome} // '') eq 'accepted';
    my $projection = _clone($manifest);
    my $identity = $projection->{publication_identity};
    $projection->{publication_identity} = undef;
    confess "regression-promotion corpus manifest identity changed\n"
        unless defined($identity) && !ref($identity)
            && $identity eq 'regression-promotion-corpus-publication/'
                . sha256_hex(_canonical_json($projection));
    _exact_keys(
        $manifest->{report_artifact}, \@REPORT_ARTIFACT_KEYS,
        'regression-promotion corpus manifest report artifact',
    );
    confess "regression-promotion corpus manifest report artifact changed\n"
        unless ($manifest->{report_artifact}{relative_path} // '') eq
                "$target_rel/$REPORT_FILENAME"
            && ($manifest->{report_artifact}{sha256} // '') eq
                sha256_hex($report_bytes)
            && _json_integer_equals(
                $manifest->{report_artifact}{bytes},
                bytes::length($report_bytes),
            );
    _validate_summary($manifest->{summary});
    confess "regression-promotion corpus manifest summary changed\n"
        unless _canonical_json($manifest->{summary}) eq
            _canonical_json($report->{summary});
    confess "regression-promotion corpus manifest nonclaims changed\n"
        unless _canonical_json($manifest->{explicit_nonclaims}) eq
            _canonical_json(\@NONCLAIMS);
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
    confess "regression-promotion corpus recovery state is ambiguous\n"
        if @candidates > 1
            || (@candidates == 1 && $candidates[0] ne $stage_rel);

    if (-e $target_abs || -l $target_abs) {
        confess "regression-promotion corpus retained staging residue\n"
            if @candidates;
        my ($report, $manifest, $artifact,
            $existing_report_bytes, $existing_manifest_bytes) =
            _read_publication($raw, 0);
        confess "regression-promotion corpus publication collision\n"
            unless $existing_report_bytes eq $raw->{report_bytes}
                && $existing_manifest_bytes eq $raw->{manifest_bytes};
        _validate_report($report, $raw, 1);
        _validate_manifest(
            $manifest, $report, $existing_report_bytes, $target_rel,
        );
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
            confess "cannot recover regression-promotion corpus publication\n";
        }
        _sync_directory(dirname($target_abs), $raw->{root_device});
        _prune_staging_parents(
            $raw->{repository_root}, dirname($stage_abs),
        );
        my (undef, undef, $artifact,
            $reloaded_report, $reloaded_manifest) =
            _read_publication($raw, 1);
        confess "regression-promotion corpus recovery bytes changed\n"
            unless $reloaded_report eq $raw->{report_bytes}
                && $reloaded_manifest eq $raw->{manifest_bytes};
        $artifact->{status} = 'recovered';
        return $artifact;
    }

    my ($created_stage, $created_target, $stage_identity) = ([], [], undef);
    my $published = eval {
        ($stage_abs, $created_stage, $stage_identity) =
            _create_stage(
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
        confess "regression-promotion corpus publication target appeared\n"
            if -e $target_abs || -l $target_abs;
        rename($stage_abs, $target_abs)
            or confess "cannot atomically publish regression-promotion corpus\n";
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
        die $error . "regression-promotion corpus cleanup residue: "
            . $cleanup_error;
    }
    _remove_empty_directories($created_stage);
    my (undef, undef, $artifact, $reloaded_report, $reloaded_manifest) =
        _read_publication($raw, 1);
    confess "regression-promotion corpus publication bytes changed\n"
        unless $reloaded_report eq $raw->{report_bytes}
            && $reloaded_manifest eq $raw->{manifest_bytes};
    $artifact->{status} = 'published';
    return $artifact;
}

sub _read_publication($raw, $validate_profiles = 1) {
    my ($target_rel, $target_abs) = _target_directory($raw);
    my ($report_bytes, $manifest_bytes, $report_stat, $manifest_stat) =
        _read_exact_file_set($target_abs, $raw->{root_device});
    my $report = _decode_canonical_json($report_bytes, 'report');
    my $manifest = _decode_canonical_json($manifest_bytes, 'manifest');
    _validate_report($report, $raw, $validate_profiles);
    _validate_manifest($manifest, $report, $report_bytes, $target_rel);
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
    confess "regression-promotion corpus $label is not newline-terminated\n"
        unless $bytes =~ /\n\z/;
    my $value = eval { JSON::PP->new->utf8(1)->decode($bytes) };
    confess "regression-promotion corpus $label JSON is invalid\n"
        if $@ || !defined($value);
    confess "regression-promotion corpus $label JSON is not canonical\n"
        unless _canonical_json($value) . "\n" eq $bytes;
    return $value;
}

sub _artifact($raw) {
    my $report_artifact = {
        relative_path => "$raw->{target_rel}/$REPORT_FILENAME",
        sha256 => sha256_hex($raw->{report_bytes}),
        bytes => $raw->{report_stat}[7],
    };
    my $manifest_artifact = {
        relative_path => "$raw->{target_rel}/$MANIFEST_FILENAME",
        sha256 => sha256_hex($raw->{manifest_bytes}),
        bytes => $raw->{manifest_stat}[7],
    };
    my $artifact = {
        schema => $ARTIFACT_SCHEMA,
        schema_version => 1,
        status => $raw->{status},
        publication_relative_path => $raw->{target_rel},
        report_artifact => $report_artifact,
        manifest_artifact => $manifest_artifact,
        file_set_sha256 => _file_set_digest(
            $raw->{report_bytes}, $raw->{manifest_bytes},
        ),
        same_volume => JSON::PP::true,
        atomic => JSON::PP::true,
    };
    _exact_keys(
        $artifact, \@ARTIFACT_KEYS,
        'regression-promotion corpus artifact',
    );
    confess "regression-promotion corpus artifact status is invalid\n"
        unless $artifact->{status}
            =~ /\A(?:loaded|published|recovered|unchanged)\z/;
    return $artifact;
}

sub _target_directory($raw) {
    my $plan = $raw->{plan};
    my $target_rel = join '/',
        $plan->{publication_base}, $plan->{publication_id}, 'complete';
    confess "regression-promotion corpus publication coordinate is invalid\n"
        unless $target_rel =~
            m{\A[.]artifacts/qualification/vial-scale/v2/
                regression-promotion-corpus-v1/complete\z}x
            && $target_rel !~ m{(?:\A|/)[.][.](?:/|\z)}
            && $target_rel !~ m{(?:\A|/)v1(?:/|\z)};
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $target_rel,
    );
    return ($target_rel, $target_abs);
}

sub _staging_directory($raw, $digest) {
    confess "regression-promotion corpus file-set digest is invalid\n"
        unless defined($digest) && !ref($digest)
            && $digest =~ /\A[0-9a-f]{64}\z/;
    my $stage_rel = "$STAGING_BASE/corpus-$digest";
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
        or confess "cannot inspect regression-promotion corpus staging\n";
    my @entries = sort grep {
        $_ ne '.' && $_ ne '..' && /^corpus-/
    } readdir $dh;
    closedir $dh
        or confess "cannot close regression-promotion corpus staging\n";
    return map { "$STAGING_BASE/$_" } @entries;
}

sub _read_exact_file_set($root, $root_device) {
    my $root_stat =
        _require_directory($root, $root_device, 'publication root');
    opendir my $dh, $root
        or confess "cannot inspect regression-promotion corpus publication\n";
    my @opened_stat = stat($dh);
    confess "regression-promotion corpus publication directory changed\n"
        unless @opened_stat && -d _
            && _same_identity($root_stat, \@opened_stat);
    my @expected = sort ($REPORT_FILENAME, $MANIFEST_FILENAME);
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    confess "regression-promotion corpus publication census changed\n"
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
        or confess "cannot close regression-promotion corpus publication\n";
    confess "regression-promotion corpus publication census changed\n"
        unless _canonical_json(\@final_entries) eq
            _canonical_json(\@expected);
    confess "regression-promotion corpus publication directory changed\n"
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
    confess "regression-promotion corpus $label artifact is invalid\n"
        unless @path_stat && !-l _ && -f _;
    confess "regression-promotion corpus $label crossed repository volume\n"
        unless $path_stat[0] == $root_device;
    confess "regression-promotion corpus $label artifact owner changed\n"
        unless $path_stat[4] == $<;
    confess "regression-promotion corpus $label artifact is hard-linked\n"
        unless $path_stat[3] == 1;
    _require_bounded_size($path_stat[7], $maximum, $label);
    sysopen(my $fh, $path, O_RDONLY | O_NOFOLLOW)
        or confess "cannot open regression-promotion corpus $label artifact\n";
    binmode($fh, ':raw')
        or confess "cannot set regression-promotion corpus byte mode\n";
    my @handle_stat = stat($fh);
    confess "regression-promotion corpus $label artifact changed\n"
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
            confess "cannot read regression-promotion corpus $label artifact\n";
        }
        last if $read == 0;
        $encoded .= $chunk;
    }
    _require_bounded_bytes($encoded, $maximum, $label);
    my @final_handle_stat = stat($fh);
    close $fh
        or confess "cannot close regression-promotion corpus $label artifact\n";
    my @final_path_stat = lstat($path);
    confess "regression-promotion corpus $label artifact changed while reading\n"
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
    confess "regression-promotion corpus staging is not recoverable\n"
        unless $report eq $expected_report
            && $manifest eq $expected_manifest;
    return 1;
}

sub _create_stage($repo_root, $root_device, $relative) {
    my @created;
    my $path = $repo_root;
    my @parts = split m{/}, _safe_relative_path($relative);
    my $ok = eval {
        for my $index (0 .. $#parts) {
            $path = File::Spec->catdir($path, $parts[$index]);
            if (-e $path || -l $path) {
                _require_directory($path, $root_device, 'staging component');
                confess "regression-promotion corpus staging root already exists\n"
                    if $index == $#parts;
            }
            else {
                mkdir($path, 0700)
                    or confess "cannot create regression-promotion corpus staging directory\n";
                push @created, $path;
                _require_directory($path, $root_device, 'staging component');
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
        or confess "cannot create regression-promotion corpus $label\n";
    binmode($fh, ':raw')
        or confess "cannot set regression-promotion corpus byte mode\n";
    print {$fh} $encoded
        or confess "cannot write regression-promotion corpus $label\n";
    $fh->flush
        or confess "cannot flush regression-promotion corpus $label\n";
    $fh->sync
        or confess "cannot sync regression-promotion corpus $label\n";
    my @stat = stat($fh);
    confess "regression-promotion corpus $label crossed repository volume\n"
        unless @stat && -f _ && $stat[0] == $root_device
            && $stat[3] == 1 && $stat[4] == $<;
    close $fh
        or confess "cannot close regression-promotion corpus $label\n";
    return 1;
}

sub _sync_directory($path, $root_device) {
    my $path_stat =
        _require_directory($path, $root_device, 'directory sync target');
    sysopen(my $fh, $path, O_RDONLY | O_NOFOLLOW)
        or confess "cannot open regression-promotion corpus directory for sync\n";
    my @stat = stat($fh);
    confess "regression-promotion corpus sync target is invalid\n"
        unless @stat && -d _ && $stat[0] == $root_device
            && _same_identity($path_stat, \@stat);
    $fh->sync
        or confess "cannot sync regression-promotion corpus directory\n";
    close $fh
        or confess "cannot close regression-promotion corpus directory\n";
    my @final_stat = lstat($path);
    confess "regression-promotion corpus sync target changed\n"
        unless @final_stat && !-l _ && -d _
            && _same_identity(\@stat, \@final_stat);
    return 1;
}

sub _remove_owned_stage($path, $root_device, $identity) {
    my @root_stat = lstat($path);
    confess "regression-promotion corpus staging cleanup identity changed\n"
        unless @root_stat && !-l _ && -d _
            && $root_stat[0] == $identity->[0]
            && $root_stat[1] == $identity->[1]
            && $root_stat[4] == $identity->[2]
            && $root_stat[0] == $root_device;
    opendir my $dh, $path
        or confess "cannot inspect regression-promotion corpus cleanup\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close regression-promotion corpus cleanup\n";
    my @allowed = sort ($REPORT_FILENAME, $MANIFEST_FILENAME);
    my %allowed = map { $_ => 1 } @allowed;
    confess "regression-promotion corpus cleanup census is unsafe\n"
        if @entries > @allowed || grep { !$allowed{$_} } @entries;
    for my $entry (@entries) {
        my $artifact = File::Spec->catfile($path, $entry);
        my @stat = lstat($artifact);
        confess "regression-promotion corpus cleanup artifact is unsafe\n"
            unless @stat && !-l _ && -f _
                && $stat[0] == $root_device
                && $stat[3] == 1 && $stat[4] == $<;
        unlink($artifact)
            or confess "cannot remove regression-promotion corpus cleanup artifact\n";
    }
    rmdir($path)
        or confess "cannot remove regression-promotion corpus staging root\n";
    confess "regression-promotion corpus staging remains after cleanup\n"
        if -e $path || -l $path;
    return 1;
}

sub _ensure_directory_path(
    $repo_root, $root_device, $absolute, $relative, $created,
) {
    my $path = $repo_root;
    for my $part (split m{/}, _safe_relative_path($relative)) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            _require_directory($path, $root_device, 'publication parent');
        }
        else {
            mkdir($path, 0700)
                or confess "cannot create regression-promotion corpus publication parent\n";
            push @$created, $path;
            _require_directory($path, $root_device, 'publication parent');
        }
    }
    confess "regression-promotion corpus publication parent mismatch\n"
        unless $path eq $absolute;
    return 1;
}

sub _require_directory($path, $root_device, $label) {
    my @stat = lstat($path);
    confess "regression-promotion corpus $label is not a real directory\n"
        unless @stat && !-l _ && -d _;
    confess "regression-promotion corpus $label crossed repository volume\n"
        unless $stat[0] == $root_device;
    confess "regression-promotion corpus $label owner changed\n"
        unless $stat[4] == $<;
    return \@stat;
}

sub _safe_destination($repo_root, $root_device, $relative) {
    _safe_relative_path($relative);
    my $path = $repo_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            _require_directory($path, $root_device, 'destination component');
        }
    }
    return $path;
}

sub _safe_relative_path($path) {
    confess "regression-promotion corpus path is unsafe\n"
        unless defined($path) && !ref($path) && length($path)
            && !File::Spec->file_name_is_absolute($path)
            && $path !~ m{(?:\A|/)[.][.](?:/|\z)}
            && $path !~ m{//}
            && $path !~ m{/\z};
    return $path;
}

sub _repository_root($value) {
    confess "regression-promotion corpus repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "regression-promotion corpus repository root is unavailable\n"
        unless defined($root) && -d $root && !-l $root;
    my $git = File::Spec->catfile($root, '.git');
    confess "regression-promotion corpus repository Git identity is invalid\n"
        unless (-d $git || -f $git) && !-l $git;
    my @stat = lstat($root);
    confess "regression-promotion corpus repository root cannot be inspected\n"
        unless @stat && !-l _ && -d _;
    confess "regression-promotion corpus repository root owner changed\n"
        unless $stat[4] == $<;
    return ($root, $stat[0]);
}

sub _prune_staging_parents($repo_root, $path) {
    my $stop = File::Spec->catdir(
        $repo_root, split m{/}, '.artifacts/tmp',
    );
    while ($path ne $repo_root && index($path, "$stop/") == 0) {
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
    confess "regression-promotion corpus $label exceeds its bounded ceiling "
        . "(actual=$actual bytes, maximum=$maximum bytes)\n"
        unless defined($actual) && $actual > 0 && $actual <= $maximum;
    return 1;
}

sub _require_bounded_bytes($encoded, $maximum, $label) {
    my $actual = bytes::length($encoded);
    _require_bounded_size($actual, $maximum, $label);
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
        unless @{$args} == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    my %allowed = map { $_ => 1 } @{$keys};
    for my $key (keys %{$args->[0]}) {
        confess "$method received unknown key '$key'\n"
            unless $allowed{$key};
    }
    for my $key (@{$keys}) {
        confess "$method is missing '$key'\n"
            unless exists $args->[0]{$key};
    }
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

sub _json_integer_equals($actual, $expected) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) eq "$expected";
}

sub _json_positive_integer($actual) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) =~ /\A[1-9][0-9]*\z/;
}

sub _json_true($actual) {
    return defined($actual) && ref($actual) eq 'JSON::PP::Boolean'
        && _canonical_json($actual) eq 'true';
}

sub _json_false($actual) {
    return defined($actual) && ref($actual) eq 'JSON::PP::Boolean'
        && _canonical_json($actual) eq 'false';
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
