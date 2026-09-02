package FSM::VIAL::ArchitectureScaleCalibrationDisposition;

use v5.20;
use strict;
use warnings;
use bytes ();

use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);

use FSM::VIAL::ArchitectureScaleCalibrationClosure;
use FSM::VIAL::ArchitectureScaleCalibrationClosurePublication;
use FSM::VIAL::ArchitectureScaleCapConsistency;
use FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;
use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement;
use FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement;

my $CLOSURE = 'FSM::VIAL::ArchitectureScaleCalibrationClosure';
my $PUBLICATION =
    'FSM::VIAL::ArchitectureScaleCalibrationClosurePublication';
my $CONSISTENCY = 'FSM::VIAL::ArchitectureScaleCapConsistency';
my $BACKEND_EMISSION =
    'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement';
my $PORTABLE_VHDL =
    'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement';
my $OSVVM = 'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement';
my $SEMANTIC_BRIDGE =
    'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement';
my $SCHEMA = 'fsmgen.vial_architecture_scale_calibration_disposition.v1';
my $STORE_ROOT = '.artifacts/qualification/vial-scale/v1';
my $CLOSURE_REPORT = join('/', $STORE_ROOT,
    'calibration-closure-v1', 'calibration-closure.json');
my $CLOSURE_MANIFEST = join('/', $STORE_ROOT,
    'calibration-closure-v1', 'closure-manifest.json');
my $LEGACY_COMPLETE = join('/', $STORE_ROOT,
    'backend-emission-complete-matrix-v1', 'complete-matrix.json');
my $LEGACY_MATRIX = join('/', $STORE_ROOT,
    'backend-emission-matrix-v1', 'matrix.json');
my $LEGACY_COMPLETE_SHA256 =
    '6c0fbc21d62f2034fb0e2718a3b015b4d335dc2d691bce28dc13b4464124878a';
my $LEGACY_MATRIX_SHA256 =
    'fc9e43c11e7be14c8f1bc0c4163c8c2ca4c7ed96280662eb3331e2857bc72ea3';
my $LEGACY_COMPLETE_IDENTITY =
    'backend-emission-matrix/a5bb05a5f4be7fb364fbf52c6750b10e04417d53732f364158e6f143bc71f735';
my $LEGACY_MATRIX_IDENTITY =
    'backend-emission-matrix/c65bf73b6587f47ca498fb8bf1807eec84915b1639ccf048aa02f051c2501583';
my $SUPERSESSION_REVISION =
    '0601fa8aa4f2bbcba8dd1b56d8c3f3aceb8b3088';
my $CURRENT_CLOSURE_IDENTITY =
    'calibration-closure/92ef0a203e18ce8de8b17cf819f36b73fe0889f00fdcb4def8b2b0e9eeb9dcc5';
my $CURRENT_PUBLICATION_IDENTITY =
    'calibration-closure-publication/1316d11a6dfa008515fcb23aa132e30a72e7961d9e9e6eeba82ae0bf42546ac8';
my $CURRENT_PUBLISHER_REVISION =
    'b66de5ce630b2a37ddb8614e6fb1bf5a290642ba';
my $CAP_DECISION =
    'docs/decisions/0093-architecture-scale-caps-are-component-ceilings-with-explicit-route-authority.md';
my $DRIFT_REVISION =
    '4834873a887e742c76157faa2d50c3fd1375a38a';
my $VHDL_CYCLE_REVISION =
    '460df366e929c98d6e5bd6636e58e7659f595646';
my $VHDL_BOUNDARY_REVISION =
    '0b6e8397923289fc655aae381a14d240335b4bb5';
my $BACKEND_VHDL_REFERENCE_PROFILE =
    'backend-emission-profile-e799776ad0dd1b2cf597119eb94aef6406a74d478943585cc3fd9530b9af3585';
my $PORTABLE_VHDL_REFERENCE_PROFILE =
    'portable-vhdl-runtime-profile-8433aec08120f004fa4b423c1106888204298124d6bbe7ff45682ea45eefcbf5';
my $OSVVM_REFERENCE_PROFILE =
    'osvvm-runtime-profile-d929241970719834206a74d2f321f2b27d763df980d8eedec7cb1c3bd202bd64';
my $MAX_ARTIFACT_BYTES = 67_108_864;
my @REPORT_KEYS = qw(
    schema schema_version disposition_identity cap_consistency
    selected_lineage legacy_lineage closure_publication drift
    vhdl_lineage_drift
    immutable_store measurement_disposition explicit_nonclaims
);
my @EVIDENCE_KEYS = qw(relative_path sha256 bytes);
my @NONCLAIMS = @{$CLOSURE->explicit_nonclaims};
my @EXPECTED_DRIFT = (
    {
        profile_id => 'bridge-fanout-v1.configurations.limit-v1',
        primary_axis => 'configurations', level => 'limit_v1',
        historical_count => 114_909,
        historical_bytes => 1_230, current_bytes => 1_229,
    },
    {
        profile_id =>
            'bridge-fanout-v1.types.qualification-candidate-v1',
        primary_axis => 'types', level => 'qualification_candidate_v1',
        historical_count => 78_007,
        historical_bytes => 1_228, current_bytes => 1_228,
    },
    {
        profile_id => 'bridge-fanout-v1.types.limit-v1',
        primary_axis => 'types', level => 'limit_v1',
        historical_count => 155_831,
        historical_bytes => 1_212, current_bytes => 1_211,
    },
    {
        profile_id => 'bridge-fanout-v1.endpoints.limit-v1',
        primary_axis => 'endpoints', level => 'limit_v1',
        historical_count => 106_613,
        historical_bytes => 1_220, current_bytes => 1_219,
    },
    {
        profile_id =>
            'bridge-fanout-v1.backend-bindings.qualification-candidate-v1',
        primary_axis => 'backend_bindings',
        level => 'qualification_candidate_v1',
        historical_count => 163_901,
        historical_bytes => 1_253, current_bytes => 1_252,
    },
    {
        profile_id => 'bridge-fanout-v1.backend-bindings.limit-v1',
        primary_axis => 'backend_bindings', level => 'limit_v1',
        historical_count => 221_245,
        historical_bytes => 1_235, current_bytes => 1_234,
    },
);

sub report_keys {
    my ($class, @args) = @_;
    _exact_invocant($class, 'report_keys');
    confess __PACKAGE__ . "->report_keys requires no arguments\n" if @args;
    return [@REPORT_KEYS];
}

sub explicit_nonclaims {
    my ($class, @args) = @_;
    _exact_invocant($class, 'explicit_nonclaims');
    confess __PACKAGE__ . "->explicit_nonclaims requires no arguments\n"
        if @args;
    return [@NONCLAIMS];
}

sub derive {
    my ($class, @args) = @_;
    _exact_invocant($class, 'derive');
    my $raw = _request('derive', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});

    my $run = $PUBLICATION->can('_run_isolated_worker');
    confess "calibration disposition isolation seam is unavailable\n"
        unless defined $run;
    return $run->({
        operation => 'calibration-disposition',
        worker => sub {
            return _derive_in_worker($repo_root, $root_device);
        },
        validate_payload => sub {
            _assert_report($_[0]);
        },
    });
}

sub _derive_in_worker {
    my ($repo_root, $root_device) = @_;
    my $cap_consistency = _require_complete_cap_consistency(
        $CONSISTENCY->build,
    );

    my $load = $PUBLICATION->can('_load_publication');
    confess "calibration disposition publication reload seam is unavailable\n"
        unless defined $load;
    my ($immutable, $manifest) = $load->($repo_root, $root_device);
    my $selected = _selected_lineage_evidence($immutable);
    my $drift = _derive_expected_drift(
        $repo_root, $root_device, $immutable,
    );
    my $vhdl_lineage_drift = _derive_vhdl_lineage_drift(
        $repo_root, $root_device, $immutable,
    );
    my ($legacy, $legacy_authority) =
        _legacy_lineage_evidence($repo_root, $root_device);
    my $closure = _closure_publication_evidence(
        $repo_root, $root_device, $manifest,
    );
    my $store = _census_tree(
        $repo_root, $root_device, $STORE_ROOT,
    );
    my $topology = _partition_topology({
        selected => $selected,
        legacy => $legacy,
        closure => $closure,
        store => $store,
    });

    my $report = {
        schema => $SCHEMA,
        schema_version => 1,
        disposition_identity => undef,
        cap_consistency => $cap_consistency,
        selected_lineage => {
            status => 'explicitly_versioned_historical',
            version => 'calibration-closure-v1',
            current_revalidation =>
                'rejected_expected_post_publication_drift',
            closure_identity => $immutable->{closure_identity},
            publication_identity => $manifest->{publication_identity},
            publisher_revision => $manifest->{publisher_revision},
            file_count => scalar(@{$selected}),
            bytes => _evidence_bytes($selected),
            aggregate_identity => _aggregate_identity($selected),
        },
        legacy_lineage => {
            status => 'explicitly_versioned_superseded',
            version => 'backend-emission-v1',
            superseded_by => 'backend-emission-v2',
            supersession_revision => $SUPERSESSION_REVISION,
            complete_matrix_identity =>
                $legacy_authority->{complete_matrix_identity},
            family_matrix_identity =>
                $legacy_authority->{family_matrix_identity},
            file_count => scalar(@{$legacy}),
            bytes => _evidence_bytes($legacy),
            aggregate_identity => _aggregate_identity($legacy),
        },
        closure_publication => {
            status => 'authentic_superseded_publication',
            publication_identity => $manifest->{publication_identity},
            closure_identity => $manifest->{closure_identity},
            file_count => scalar(@{$closure}),
            bytes => _evidence_bytes($closure),
            aggregate_identity => _aggregate_identity($closure),
        },
        drift => $drift,
        vhdl_lineage_drift => $vhdl_lineage_drift,
        immutable_store => $topology,
        measurement_disposition => {
            status => 'superseded_after_expected_current_drift',
            evidence_role => 'historical_measurement_only',
            candidate_budget_status => 'candidate_only',
            cap_implementation_status => 'prohibited',
            support_status => 'not_established',
            capacity_status => 'not_established',
            recapture_requirement =>
                'required_before_current_performance_use',
            cap_closeout_dependency => 'none',
        },
        explicit_nonclaims => [@NONCLAIMS],
    };
    $report->{disposition_identity} = _disposition_identity($report);
    _assert_report($report);
    return $report;
}

sub _require_complete_cap_consistency {
    my ($report) = @_;
    confess "calibration disposition cap consistency is invalid\n"
        unless @_ == 1 && ref($report) eq 'HASH' && !blessed($report);
    my $dimensions = $report->{required_dimensions};
    my $groups = $report->{groups};
    confess "calibration disposition requires a closed dimension inventory\n"
        unless ref($dimensions) eq 'ARRAY' && @{$dimensions} == 7;
    confess "calibration disposition requires a closed group inventory\n"
        unless ref($groups) eq 'HASH' && !blessed($groups)
            && keys(%{$groups}) == 23;

    my $verified = 0;
    for my $group_name (sort keys %{$groups}) {
        my $records = $groups->{$group_name}{dimensions};
        confess "calibration disposition group '$group_name' is incomplete\n"
            unless ref($records) eq 'HASH' && !blessed($records);
        for my $dimension (@{$dimensions}) {
            my $record = $records->{$dimension};
            confess "calibration disposition group '$group_name/$dimension' is not verified\n"
                unless ref($record) eq 'HASH'
                    && ($record->{status} // '') eq 'verified'
                    && ref($record->{evidence}) eq 'ARRAY'
                    && @{$record->{evidence}};
            $verified++;
        }
    }
    my $calibration = $report->{calibration};
    confess "calibration disposition is not unlocked by current cap proof\n"
        unless ref($calibration) eq 'HASH'
            && ($calibration->{cap_proof_status} // '') eq 'complete'
            && ($calibration->{disposition} // '')
                eq 'eligible_for_explicit_revalidation'
            && ($calibration->{evidence_role} // '')
                eq 'historical_measurement_only'
            && ($calibration->{prohibited_relabel} // '')
                eq 'cap_implementation';
    confess "calibration disposition verified-dimension census changed\n"
        unless $verified == 161;

    return {
        schema => $report->{schema},
        decision => $report->{decision},
        group_count => scalar(keys %{$groups}),
        required_dimension_count => scalar(@{$dimensions}),
        verified_dimension_count => $verified,
        cap_proof_status => $calibration->{cap_proof_status},
        revalidation_eligibility => $calibration->{disposition},
        calibration_authority => $calibration->{authority},
        evidence_role => $calibration->{evidence_role},
        prohibited_relabel => $calibration->{prohibited_relabel},
    };
}

sub _require_same_closure {
    my ($immutable, $fresh) = @_;
    confess "calibration closure comparison requires two unblessed hashes\n"
        unless @_ == 2
            && ref($immutable) eq 'HASH' && !blessed($immutable)
            && ref($fresh) eq 'HASH' && !blessed($fresh);
    confess "current calibration derivation disagrees with immutable publication\n"
        unless _canonical_json($immutable) eq _canonical_json($fresh);
    return 1;
}

sub _selected_lineage_evidence {
    my ($report) = @_;
    my @evidence;
    for my $authority (@{$report->{authorities}}) {
        push @evidence, $authority->{complete_artifact};
        push @evidence, map { $_->{artifact} }
            @{$authority->{family_artifacts}};
    }
    push @evidence, map { $_->{raw_evidence} } @{$report->{profiles}};
    my $normalized = _normalize_evidence(\@evidence, 'selected lineage');
    confess "selected calibration lineage file census changed\n"
        unless @{$normalized} == 232;
    return $normalized;
}

sub _derive_expected_drift {
    my ($repo_root, $root_device, $immutable) = @_;
    my $construct = $SEMANTIC_BRIDGE->can('_canonical_construction');
    my $payload_for = $SEMANTIC_BRIDGE->can('_stage_payload');
    my $materialize = $SEMANTIC_BRIDGE->can('_materialized_projection');
    confess "calibration disposition semantic/bridge drift seams are unavailable\n"
        unless defined($construct) && defined($payload_for)
            && defined($materialize);
    my @selected_profiles = grep {
        ($_->{authority} // '') eq 'semantic_bridge'
    } @{$immutable->{profiles}};
    my %profiles = map {
        $_->{matrix_profile}{profile_id} => $_
    } @selected_profiles;
    confess "semantic/bridge calibration profile census changed\n"
        unless @selected_profiles == 108 && keys(%profiles) == 108;
    my %expected = map { $_->{profile_id} => $_ } @EXPECTED_DRIFT;
    my %matched = (
        semantic_catalog_v1 => 0,
        bridge_fanout_v1 => 0,
    );
    my %total = (
        semantic_catalog_v1 => 0,
        bridge_fanout_v1 => 0,
    );
    my %observed_drift;
    for my $profile (@selected_profiles) {
        my $profile_id = $profile->{matrix_profile}{profile_id};
        my $artifact = _load_json_evidence({
            repository_root => $repo_root,
            root_device => $root_device,
            relative_path => $profile->{raw_evidence}{relative_path},
            expected_sha256 => $profile->{raw_evidence}{sha256},
            expected_bytes => $profile->{raw_evidence}{bytes},
        });
        my $document = $artifact->{value};
        my $report = exists($document->{report})
            ? $document->{report} : $document;
        my $family = $report->{family};
        confess "semantic/bridge calibration family changed\n"
            unless exists $total{$family};
        $total{$family}++;
        my $valid = eval {
            $SEMANTIC_BRIDGE->validate_report({
                repository_root => $repo_root,
                report => $report,
            });
            1;
        };
        if ($valid) {
            confess "expected calibration drift profile now validates\n"
                if exists $expected{$profile_id};
            $matched{$family}++;
            next;
        }
        confess "unexpected semantic/bridge calibration drift at '$profile_id'\n"
            unless exists $expected{$profile_id};
        confess "expected calibration drift failure changed at '$profile_id'\n"
            unless defined($@) && length($@);
        $observed_drift{$profile_id} = 1;
    }
    confess "semantic/bridge calibration current-validation census changed\n"
        unless $total{semantic_catalog_v1} == 56
            && $matched{semantic_catalog_v1} == 56
            && $total{bridge_fanout_v1} == 52
            && $matched{bridge_fanout_v1} == 46
            && keys(%observed_drift) == @EXPECTED_DRIFT
            && !grep { !$observed_drift{$_->{profile_id}} } @EXPECTED_DRIFT;
    my @records;
    for my $expected (@EXPECTED_DRIFT) {
        my $profile = $profiles{$expected->{profile_id}};
        confess "expected calibration drift profile is absent\n"
            unless defined $profile;
        my $artifact = _load_json_evidence({
            repository_root => $repo_root,
            root_device => $root_device,
            relative_path => $profile->{raw_evidence}{relative_path},
            expected_sha256 => $profile->{raw_evidence}{sha256},
            expected_bytes => $profile->{raw_evidence}{bytes},
        });
        my $document = $artifact->{value};
        my $report = exists($document->{report})
            ? $document->{report} : $document;
        confess "expected calibration drift coordinates changed\n"
            unless ($report->{family} // '') eq 'bridge_fanout_v1'
                && ($report->{primary_axis} // '')
                    eq $expected->{primary_axis}
                && ($report->{level} // '') eq $expected->{level};
        my $record = $report->{validation_record};
        confess "expected calibration drift validation record changed\n"
            unless ref($record) eq 'HASH' && !blessed($record);
        my @stages = grep { ($_->{stage} // '') eq 'bridge' }
            @{$record->{stage_measurements}};
        my @oracles = grep {
            ($_->{oracle_id} // '')
                eq 'bridge_fanout_v1_bridge_canonical'
        } @{$record->{correctness_oracles}};
        confess "expected calibration drift evidence cardinality changed\n"
            unless @stages == 1 && @oracles == 1;

        my $historical_message = 'source_map count '
            . $expected->{historical_count} . ' exceeds limit 65536';
        my $current_message =
            'source_map count 65537 exceeds limit 65536';
        my $construction = $construct->(
            $repo_root, 'bridge_fanout_v1',
            $expected->{level}, $expected->{primary_axis},
        );
        my $payload = $payload_for->(
            $construction, 'bridge',
        );
        my $materialized = $materialize->('bridge', $payload);
        my $expected_historical_evidence = _clone($payload->{evidence});
        $expected_historical_evidence->{diagnostics}[0]{message} =
            $historical_message;
        confess "historical calibration drift is not the sealed one-field change\n"
            unless _canonical_json($oracles[0]{evidence})
                eq _canonical_json($expected_historical_evidence);
        my $expected_historical_counts =
            _clone($materialized->{output_counts});
        $expected_historical_counts->{bytes} =
            $expected->{historical_bytes};
        confess "historical calibration drift output counts changed\n"
            unless _canonical_json($stages[0]{output_counts})
                eq _canonical_json($expected_historical_counts);
        confess "current calibration drift diagnostic changed\n"
            unless ($payload->{evidence}{diagnostics}[0]{message} // '')
                    eq $current_message
                && ($materialized->{output_counts}{bytes} // -1)
                    == $expected->{current_bytes};
        push @records, {
            profile_id => $expected->{profile_id},
            artifact_relative_path =>
                $profile->{raw_evidence}{relative_path},
            field => '/diagnostics/0/message',
            historical_message => $historical_message,
            current_message => $current_message,
            historical_output_bytes => $expected->{historical_bytes},
            current_output_bytes => $expected->{current_bytes},
        };
    }
    return {
        status => 'expected_intentional_post_publication_drift',
        authority => 'semantic_bridge',
        family => 'bridge_fanout_v1',
        cause_revision => $DRIFT_REVISION,
        selected_profile_count => scalar(@selected_profiles),
        current_validator_match_count =>
            $matched{semantic_catalog_v1} + $matched{bridge_fanout_v1},
        semantic_profile_count => $total{semantic_catalog_v1},
        semantic_current_validator_match_count =>
            $matched{semantic_catalog_v1},
        bridge_profile_count => $total{bridge_fanout_v1},
        bridge_current_validator_match_count => $matched{bridge_fanout_v1},
        changed_profile_count => scalar(@records),
        records => \@records,
    };
}

sub _derive_vhdl_lineage_drift {
    my ($repo_root, $root_device, $immutable) = @_;
    my %profiles = map {
        join('/', $_->{authority}, $_->{matrix_profile}{profile_id}) => $_
    } @{$immutable->{profiles}};
    my $load_report = sub {
        my ($authority, $profile_id) = @_;
        my $profile = $profiles{"$authority/$profile_id"};
        confess "VHDL lineage drift profile is absent\n"
            unless defined $profile;
        my $artifact = _load_json_evidence({
            repository_root => $repo_root,
            root_device => $root_device,
            relative_path => $profile->{raw_evidence}{relative_path},
            expected_sha256 => $profile->{raw_evidence}{sha256},
            expected_bytes => $profile->{raw_evidence}{bytes},
        });
        my $document = $artifact->{value};
        return exists($document->{report})
            ? $document->{report} : $document;
    };

    my $historical_backend = $load_report->(
        'backend_emission', $BACKEND_VHDL_REFERENCE_PROFILE,
    );
    confess "historical VHDL backend reference coordinates changed\n"
        unless ($historical_backend->{backend_profile} // '')
                eq 'vhdl_portable_ghdl'
            && ($historical_backend->{level} // '') eq 'reference_v1';
    my $pair = $BACKEND_EMISSION->can('_canonical_pair');
    my $projection =
        $BACKEND_EMISSION->can('_measurement_evidence_projection');
    confess "VHDL backend drift derivation seams are unavailable\n"
        unless defined($pair) && defined($projection);
    my (undef, $current_evaluation) = $pair->(
        $repo_root, 'vhdl_portable_ghdl', 'reference_v1',
    );
    my $historical_evaluation = $historical_backend->{canonical_evaluation};
    my $current_projection = $projection->($current_evaluation);
    my $historical_oracle =
        $historical_evaluation->{artifact_oracle}{portable_vhdl};
    my $current_oracle =
        $current_projection->{artifact_oracle}{portable_vhdl};
    confess "VHDL backend drift oracle is unavailable\n"
        unless ref($historical_oracle) eq 'HASH'
            && ref($current_oracle) eq 'HASH';
    confess "VHDL backend drift source census changed\n"
        unless ref($historical_oracle->{source_identities}) eq 'ARRAY'
            && ref($current_oracle->{source_identities}) eq 'ARRAY'
            && @{$historical_oracle->{source_identities}} == 6
            && @{$current_oracle->{source_identities}} == 6;
    my @changed_sources;
    for my $index (0 .. 5) {
        my $historical = $historical_oracle->{source_identities}[$index];
        my $current = $current_oracle->{source_identities}[$index];
        next if _canonical_json($historical) eq _canonical_json($current);
        push @changed_sources, {
            relpath => $historical->{relpath},
            historical_bytes => $historical->{bytes},
            current_bytes => $current->{bytes},
            historical_sha256 => $historical->{sha256},
            current_sha256 => $current->{sha256},
        };
    }
    confess "VHDL backend drift changed more than its sealed source\n"
        unless @changed_sources == 1
            && $changed_sources[0]{relpath}
                eq 'backends/vhdl_portable_ghdl/src/base_output_arbitration_tb.vhd'
            && $changed_sources[0]{historical_bytes} == 46_264
            && $changed_sources[0]{current_bytes} == 46_503
            && $changed_sources[0]{historical_sha256}
                eq 'bc45987685e0e2fcf1adb5bbb0a20110dbdcc695ee1c556b1bee41c5b953f8d5'
            && $changed_sources[0]{current_sha256}
                eq '69e3cb8f5f19391b516f65fed0183b46d0bf920ea40ed5fb644aa38307531693';
    confess "VHDL backend aggregate drift changed\n"
        unless ($historical_oracle->{source_bytes} // -1) == 118_064
            && ($current_oracle->{source_bytes} // -1) == 118_303
            && ($historical_oracle->{source_map_entries} // -1) == 59
            && ($current_oracle->{source_map_entries} // -1) == 59
            && ($historical_oracle->{artifact_graph_sha256} // '')
                eq 'decfde42497a1826231769f8ead15c8d6ac38e2e2fe33ae8d0f6fb3d7d5377cd'
            && ($current_oracle->{artifact_graph_sha256} // '')
                eq '61fedc13286538c58e9658223f4507ee4cd691ea021e2cc3e79e6c9c740c2cab'
            && ($historical_evaluation->{evaluation_identity} // '')
                eq 'backend-emission-evaluation/990e7366018125d443ba2095a98eb07426c3224d7fd5364168463313b4dd15fc'
            && ($current_projection->{evaluation_identity} // '')
                eq 'backend-emission-evaluation/d8f425cb9a8b58f4687b9fd67116fa079e8f229430575fbd1a7a07b50384cdbc'
            && ($historical_evaluation->{rerun_identity} // '')
                eq 'rerun/bad6f8b30198c0159d43ba8d296729dc91ae63234de841a676aebb6c7fb8d413'
            && ($current_projection->{rerun_identity} // '')
                eq $historical_evaluation->{rerun_identity};

    my $historical_vhdl = $load_report->(
        'portable_vhdl_runtime', $PORTABLE_VHDL_REFERENCE_PROFILE,
    );
    my $current_vhdl = $PORTABLE_VHDL->validate_profile({
        repository_root => $repo_root,
        level => 'reference_v1',
    });
    my $historical_osvvm = $load_report->(
        'osvvm_runtime', $OSVVM_REFERENCE_PROFILE,
    );
    my $current_osvvm = $OSVVM->validate_profile({
        repository_root => $repo_root,
        level => 'reference_v1',
    });
    confess "VHDL runtime authored source identity changed\n"
        unless _canonical_json($historical_vhdl->{materialization}{source_identity})
                eq _canonical_json($current_vhdl->{materialization}{source_identity})
            && _canonical_json($historical_osvvm->{materialization}{source_identity})
                eq _canonical_json($current_osvvm->{materialization}{source_identity});

    my $report = {
        status => 'expected_vhdl_derived_identity_drift',
        cause_revisions => [
            {
                revision => $VHDL_CYCLE_REVISION,
                fixed_source_bytes_added => 127,
                role => 'scenario_cycle_projection_repair',
            },
            {
                revision => $VHDL_BOUNDARY_REVISION,
                fixed_source_bytes_added => 112,
                role => 'scenario_boundary_time_repair',
            },
        ],
        backend_emission => {
            profile_id => $BACKEND_VHDL_REFERENCE_PROFILE,
            source_bytes_historical => $historical_oracle->{source_bytes},
            source_bytes_current => $current_oracle->{source_bytes},
            fixed_source_bytes_added =>
                $current_oracle->{source_bytes}
                    - $historical_oracle->{source_bytes},
            source_map_entries_historical =>
                $historical_oracle->{source_map_entries},
            source_map_entries_current => $current_oracle->{source_map_entries},
            changed_source => $changed_sources[0],
            artifact_graph_sha256_historical =>
                $historical_oracle->{artifact_graph_sha256},
            artifact_graph_sha256_current =>
                $current_oracle->{artifact_graph_sha256},
            evaluation_identity_historical =>
                $historical_evaluation->{evaluation_identity},
            evaluation_identity_current =>
                $current_projection->{evaluation_identity},
            rerun_identity => $current_projection->{rerun_identity},
        },
        portable_vhdl_runtime => {
            profile_id => $PORTABLE_VHDL_REFERENCE_PROFILE,
            materialization_identity_historical =>
                $historical_vhdl->{materialization}{report_identity},
            materialization_identity_current =>
                $current_vhdl->{materialization}{report_identity},
        },
        osvvm_runtime => {
            profile_id => $OSVVM_REFERENCE_PROFILE,
            materialization_identity_historical =>
                $historical_osvvm->{materialization}{report_identity},
            materialization_identity_current =>
                $current_osvvm->{materialization}{report_identity},
        },
    };
    _assert_vhdl_lineage_drift($report);
    return $report;
}

sub _legacy_lineage_evidence {
    my ($repo_root, $root_device) = @_;
    my $complete = _load_json_evidence({
        repository_root => $repo_root,
        root_device => $root_device,
        relative_path => $LEGACY_COMPLETE,
        expected_sha256 => $LEGACY_COMPLETE_SHA256,
        expected_bytes => 2_535,
    });
    my $complete_value = $complete->{value};
    confess "legacy backend-emission complete schema changed\n"
        unless ($complete_value->{schema} // '')
                eq 'fsmgen.vial_architecture_scale_backend_emission_complete_matrix.v1'
            && ($complete_value->{schema_version} // 0) == 1;
    confess "legacy backend-emission complete identity changed\n"
        unless ($complete_value->{matrix_identity} // '')
            eq $LEGACY_COMPLETE_IDENTITY;
    confess "legacy backend-emission complete profile count changed\n"
        unless ($complete_value->{total_profile_count} // -1) == 20;
    my $family = $complete_value->{family_manifest};
    confess "legacy backend-emission family manifest changed\n"
        unless ref($family) eq 'HASH'
            && ($family->{artifact_relative_path} // '') eq $LEGACY_MATRIX
            && ($family->{artifact_sha256} // '') eq $LEGACY_MATRIX_SHA256
            && ($family->{artifact_bytes} // -1) == 30_203
            && ($family->{matrix_identity} // '') eq $LEGACY_MATRIX_IDENTITY
            && ($family->{profile_count} // -1) == 20;

    my $matrix = _load_json_evidence({
        repository_root => $repo_root,
        root_device => $root_device,
        relative_path => $LEGACY_MATRIX,
        expected_sha256 => $family->{artifact_sha256},
        expected_bytes => $family->{artifact_bytes},
    });
    my $matrix_value = $matrix->{value};
    confess "legacy backend-emission matrix schema changed\n"
        unless ($matrix_value->{schema} // '')
                eq 'fsmgen.vial_architecture_scale_backend_emission_matrix.v1'
            && ($matrix_value->{schema_version} // 0) == 1;
    confess "legacy backend-emission matrix identity changed\n"
        unless ($matrix_value->{matrix_identity} // '')
            eq $LEGACY_MATRIX_IDENTITY;
    confess "legacy backend-emission matrix family changed\n"
        unless ($matrix_value->{family} // '') eq 'backend_emission_v1';
    confess "legacy backend-emission matrix profiles changed\n"
        unless ref($matrix_value->{profiles}) eq 'ARRAY'
            && @{$matrix_value->{profiles}} == 20
            && ($matrix_value->{profile_count} // -1) == 20;

    my @evidence = ($complete->{evidence}, $matrix->{evidence});
    for my $profile (@{$matrix_value->{profiles}}) {
        confess "legacy backend-emission profile evidence changed\n"
            unless ref($profile) eq 'HASH'
                && defined($profile->{artifact_relative_path})
                && ($profile->{artifact_sha256} // '')
                    =~ /\A[0-9a-f]{64}\z/
                && _positive_integer($profile->{artifact_bytes});
        my $artifact = _load_json_evidence({
            repository_root => $repo_root,
            root_device => $root_device,
            relative_path => $profile->{artifact_relative_path},
            expected_sha256 => $profile->{artifact_sha256},
            expected_bytes => $profile->{artifact_bytes},
        });
        push @evidence, $artifact->{evidence};
    }
    my $normalized = _normalize_evidence(\@evidence, 'legacy lineage');
    confess "legacy backend-emission lineage file census changed\n"
        unless @{$normalized} == 22;
    return ($normalized, {
        complete_matrix_identity => $complete_value->{matrix_identity},
        family_matrix_identity => $matrix_value->{matrix_identity},
    });
}

sub _closure_publication_evidence {
    my ($repo_root, $root_device, $manifest) = @_;
    my $report = _file_evidence({
        repository_root => $repo_root,
        root_device => $root_device,
        relative_path => $CLOSURE_REPORT,
    });
    confess "closure publication report evidence changed\n"
        unless $report->{sha256} eq $manifest->{report_artifact}{sha256}
            && $report->{bytes} == $manifest->{report_artifact}{bytes}
            && $report->{relative_path}
                eq $manifest->{report_artifact}{artifact_relative_path};
    my $manifest_evidence = _file_evidence({
        repository_root => $repo_root,
        root_device => $root_device,
        relative_path => $CLOSURE_MANIFEST,
    });
    return _normalize_evidence(
        [$report, $manifest_evidence], 'closure publication',
    );
}

sub _partition_topology {
    my ($raw) = @_;
    _exact_keys($raw, [qw(selected legacy closure store)],
        'calibration topology invocation');
    my %sets = map {
        $_ => _normalize_evidence($raw->{$_}, "calibration topology $_")
    } qw(selected legacy closure store);

    my %owner;
    for my $name (qw(selected legacy closure)) {
        for my $entry (@{$sets{$name}}) {
            my $path = $entry->{relative_path};
            confess "calibration lineage sets overlap at '$path'\n"
                if exists $owner{$path};
            $owner{$path} = $name;
        }
    }
    my @union = sort {
        $a->{relative_path} cmp $b->{relative_path}
    } map { @{$sets{$_}} } qw(selected legacy closure);
    confess "calibration lineages do not exactly partition immutable store\n"
        unless _canonical_json(\@union) eq _canonical_json($sets{store});

    return {
        status => 'exact_partition',
        file_count => scalar(@{$sets{store}}),
        bytes => _evidence_bytes($sets{store}),
        aggregate_identity => _aggregate_identity($sets{store}),
        selected_legacy_overlap => 0,
        selected_closure_overlap => 0,
        legacy_closure_overlap => 0,
    };
}

sub _census_tree {
    my ($repo_root, $root_device, $relative_root) = @_;
    _safe_relative_path($relative_root);
    my @files;
    _census_directory(
        $repo_root, $root_device, $relative_root, \@files,
    );
    return _normalize_evidence(\@files, 'immutable calibration store');
}

sub _census_directory {
    my ($repo_root, $root_device, $relative, $files) = @_;
    my $path = _absolute_path($repo_root, $root_device, $relative, 'directory');
    opendir my $dh, $path
        or confess "cannot inspect immutable calibration store '$relative'\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close immutable calibration store '$relative'\n";
    for my $entry (@entries) {
        confess "immutable calibration store entry name is unsafe\n"
            if $entry =~ m{/} || $entry =~ /[\x00-\x1f\x7f]/;
        my $child = "$relative/$entry";
        my $child_path = File::Spec->catfile(
            $repo_root, split(m{/}, $child),
        );
        confess "immutable calibration store contains a symlink: $child\n"
            if -l $child_path;
        my @stat = stat($child_path);
        confess "immutable calibration store entry is unavailable: $child\n"
            unless @stat && $stat[0] == $root_device;
        if (-d $child_path) {
            _census_directory($repo_root, $root_device, $child, $files);
        }
        elsif (-f $child_path) {
            push @{$files}, _file_evidence({
                repository_root => $repo_root,
                root_device => $root_device,
                relative_path => $child,
            });
        }
        else {
            confess "immutable calibration store contains a special entry: $child\n";
        }
    }
}

sub _load_json_evidence {
    my ($raw) = @_;
    my $evidence = _file_evidence($raw);
    my $path = File::Spec->catfile(
        $raw->{repository_root}, split(m{/}, $raw->{relative_path}),
    );
    open my $fh, '<:raw', $path
        or confess "cannot read calibration disposition JSON artifact\n";
    local $/;
    my $bytes = <$fh>;
    close $fh
        or confess "cannot close calibration disposition JSON artifact\n";
    confess "calibration disposition JSON artifact changed while reading\n"
        unless defined($bytes) && bytes::length($bytes) == $evidence->{bytes}
            && sha256_hex($bytes) eq $evidence->{sha256};
    my $value = eval { JSON::PP->new->utf8(1)->decode($bytes) };
    confess "calibration disposition artifact is not valid JSON\n" if $@;
    confess "calibration disposition artifact is not canonical JSON\n"
        unless $bytes eq _canonical_json($value) . "\n";
    return {value => $value, evidence => $evidence};
}

sub _file_evidence {
    my ($raw) = @_;
    my $relative = $raw->{relative_path};
    my $path = _absolute_path(
        $raw->{repository_root}, $raw->{root_device}, $relative, 'file',
    );
    my @stat = stat($path);
    confess "calibration disposition artifact exceeds its read envelope: $relative\n"
        if $stat[7] > $MAX_ARTIFACT_BYTES;
    open my $fh, '<:raw', $path
        or confess "cannot read calibration disposition artifact: $relative\n";
    local $/;
    my $bytes = <$fh>;
    close $fh
        or confess "cannot close calibration disposition artifact: $relative\n";
    confess "calibration disposition artifact changed while reading: $relative\n"
        unless defined($bytes) && bytes::length($bytes) == $stat[7];
    my $evidence = {
        relative_path => $relative,
        sha256 => sha256_hex($bytes),
        bytes => $stat[7],
    };
    confess "calibration disposition artifact digest changed: $relative\n"
        if defined($raw->{expected_sha256})
            && $evidence->{sha256} ne $raw->{expected_sha256};
    confess "calibration disposition artifact bytes changed: $relative\n"
        if defined($raw->{expected_bytes})
            && $evidence->{bytes} != $raw->{expected_bytes};
    return $evidence;
}

sub _absolute_path {
    my ($repo_root, $root_device, $relative, $kind) = @_;
    _safe_relative_path($relative);
    my $cursor = $repo_root;
    my @parts = split m{/}, $relative;
    for my $index (0 .. $#parts) {
        $cursor = File::Spec->catfile($cursor, $parts[$index]);
        confess "calibration disposition path contains a symlink: $relative\n"
            if -l $cursor;
        my $last = $index == $#parts;
        confess "calibration disposition path is missing: $relative\n"
            unless $last
                ? ($kind eq 'file' ? -f $cursor : -d $cursor)
                : -d $cursor;
        my @stat = stat($cursor);
        confess "calibration disposition path crossed repository volume: $relative\n"
            unless @stat && $stat[0] == $root_device;
    }
    return $cursor;
}

sub _normalize_evidence {
    my ($raw, $label) = @_;
    confess "$label must be one evidence array\n"
        unless ref($raw) eq 'ARRAY';
    my (%seen, @normalized);
    for my $entry (@{$raw}) {
        _exact_keys($entry, \@EVIDENCE_KEYS, "$label member");
        _safe_relative_path($entry->{relative_path});
        confess "$label member digest is invalid\n"
            unless ($entry->{sha256} // '') =~ /\A[0-9a-f]{64}\z/;
        confess "$label member byte count is invalid\n"
            unless _positive_integer($entry->{bytes});
        confess "$label repeats '$entry->{relative_path}'\n"
            if $seen{$entry->{relative_path}}++;
        push @normalized, {
            relative_path => $entry->{relative_path},
            sha256 => $entry->{sha256},
            bytes => 0 + $entry->{bytes},
        };
    }
    @normalized = sort {
        $a->{relative_path} cmp $b->{relative_path}
    } @normalized;
    return \@normalized;
}

sub _evidence_bytes {
    my ($evidence) = @_;
    my $bytes = 0;
    $bytes += $_->{bytes} for @{$evidence};
    return $bytes;
}

sub _aggregate_identity {
    my ($evidence) = @_;
    my $normalized = _normalize_evidence($evidence, 'aggregate evidence');
    return 'calibration-artifact-set/'
        . sha256_hex(_canonical_json($normalized));
}

sub _assert_report {
    my ($report) = @_;
    _exact_keys($report, \@REPORT_KEYS, 'calibration disposition report');
    confess "calibration disposition schema is unsupported\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // 0) == 1;
    confess "calibration disposition identity is invalid\n"
        unless ($report->{disposition_identity} // '')
            =~ /\Acalibration-disposition\/[0-9a-f]{64}\z/;

    _exact_keys($report->{cap_consistency}, [qw(
        schema decision group_count required_dimension_count
        verified_dimension_count cap_proof_status revalidation_eligibility
        calibration_authority evidence_role prohibited_relabel
    )], 'calibration disposition cap consistency');
    my $cap = $report->{cap_consistency};
    confess "calibration disposition cap census changed\n"
        unless ($cap->{schema} // '')
                eq 'fsmgen.vial_architecture_scale_cap_consistency.v1'
            && ($cap->{decision} // '') eq $CAP_DECISION
            && ($cap->{group_count} // -1) == 23
            && ($cap->{required_dimension_count} // -1) == 7
            && ($cap->{verified_dimension_count} // -1) == 161
            && ($cap->{cap_proof_status} // '') eq 'complete'
            && ($cap->{revalidation_eligibility} // '')
                eq 'eligible_for_explicit_revalidation'
            && ($cap->{evidence_role} // '')
                eq 'historical_measurement_only'
            && ($cap->{prohibited_relabel} // '') eq 'cap_implementation'
            && ($cap->{calibration_authority} // '') eq $PUBLICATION;

    _assert_selected_lineage($report->{selected_lineage});
    _assert_legacy_lineage($report->{legacy_lineage});
    _assert_closure_publication($report->{closure_publication});
    _assert_drift($report->{drift});
    _assert_vhdl_lineage_drift($report->{vhdl_lineage_drift});
    _assert_immutable_store($report->{immutable_store});
    confess "calibration disposition lineage identities disagree\n"
        unless $report->{selected_lineage}{closure_identity}
                eq $report->{closure_publication}{closure_identity}
            && $report->{selected_lineage}{publication_identity}
                eq $report->{closure_publication}{publication_identity};
    confess "calibration disposition lineage census does not sum to store\n"
        unless $report->{immutable_store}{file_count}
                == $report->{selected_lineage}{file_count}
                    + $report->{legacy_lineage}{file_count}
                    + $report->{closure_publication}{file_count}
            && $report->{immutable_store}{bytes}
                == $report->{selected_lineage}{bytes}
                    + $report->{legacy_lineage}{bytes}
                    + $report->{closure_publication}{bytes};
    _exact_keys($report->{measurement_disposition}, [qw(
        status evidence_role candidate_budget_status
        cap_implementation_status support_status capacity_status
        recapture_requirement cap_closeout_dependency
    )], 'calibration measurement disposition');
    my $measurement = $report->{measurement_disposition};
    confess "calibration measurement disposition changed\n"
        unless ($measurement->{status} // '')
                eq 'superseded_after_expected_current_drift'
            && ($measurement->{evidence_role} // '')
                eq 'historical_measurement_only'
            && ($measurement->{candidate_budget_status} // '')
                eq 'candidate_only'
            && ($measurement->{cap_implementation_status} // '')
                eq 'prohibited'
            && ($measurement->{support_status} // '') eq 'not_established'
            && ($measurement->{capacity_status} // '') eq 'not_established'
            && ($measurement->{recapture_requirement} // '')
                eq 'required_before_current_performance_use'
            && ($measurement->{cap_closeout_dependency} // '') eq 'none';
    confess "calibration disposition nonclaims changed\n"
        unless _canonical_json($report->{explicit_nonclaims})
            eq _canonical_json(\@NONCLAIMS);
    confess "calibration disposition identity changed\n"
        unless $report->{disposition_identity}
            eq _disposition_identity($report);
    return 1;
}

sub _assert_selected_lineage {
    my ($selected) = @_;
    _exact_keys($selected, [qw(
        status version current_revalidation closure_identity
        publication_identity publisher_revision file_count bytes
        aggregate_identity
    )], 'selected calibration lineage');
    confess "selected calibration lineage disposition changed\n"
        unless ($selected->{status} // '')
                eq 'explicitly_versioned_historical'
            && ($selected->{version} // '') eq 'calibration-closure-v1'
            && ($selected->{current_revalidation} // '')
                eq 'rejected_expected_post_publication_drift'
            && ($selected->{closure_identity} // '')
                eq $CURRENT_CLOSURE_IDENTITY
            && ($selected->{publication_identity} // '')
                eq $CURRENT_PUBLICATION_IDENTITY
            && ($selected->{publisher_revision} // '')
                eq $CURRENT_PUBLISHER_REVISION
            && ($selected->{file_count} // -1) == 232
            && ($selected->{bytes} // -1) == 28_398_586;
    _assert_lineage_identities($selected);
}

sub _assert_legacy_lineage {
    my ($legacy) = @_;
    _exact_keys($legacy, [qw(
        status version superseded_by supersession_revision
        complete_matrix_identity family_matrix_identity file_count bytes
        aggregate_identity
    )], 'legacy calibration lineage');
    confess "legacy calibration lineage disposition changed\n"
        unless ($legacy->{status} // '')
                eq 'explicitly_versioned_superseded'
            && ($legacy->{version} // '') eq 'backend-emission-v1'
            && ($legacy->{superseded_by} // '') eq 'backend-emission-v2'
            && ($legacy->{supersession_revision} // '')
                eq $SUPERSESSION_REVISION
            && ($legacy->{complete_matrix_identity} // '')
                eq $LEGACY_COMPLETE_IDENTITY
            && ($legacy->{family_matrix_identity} // '')
                eq $LEGACY_MATRIX_IDENTITY
            && ($legacy->{file_count} // -1) == 22
            && ($legacy->{bytes} // -1) == 2_232_452;
    _assert_aggregate_identity($legacy->{aggregate_identity},
        'legacy calibration lineage');
}

sub _assert_closure_publication {
    my ($closure) = @_;
    _exact_keys($closure, [qw(
        status publication_identity closure_identity file_count bytes
        aggregate_identity
    )], 'closure publication disposition');
    confess "closure publication census changed\n"
        unless ($closure->{status} // '')
                eq 'authentic_superseded_publication'
            && ($closure->{closure_identity} // '')
                eq $CURRENT_CLOSURE_IDENTITY
            && ($closure->{publication_identity} // '')
                eq $CURRENT_PUBLICATION_IDENTITY
            && ($closure->{file_count} // -1) == 2
            && ($closure->{bytes} // -1) == 1_376_483;
    _assert_lineage_identities($closure);
}

sub _assert_drift {
    my ($drift) = @_;
    _exact_keys($drift, [qw(
        status authority family cause_revision selected_profile_count
        current_validator_match_count semantic_profile_count
        semantic_current_validator_match_count bridge_profile_count
        bridge_current_validator_match_count changed_profile_count records
    )], 'calibration disposition drift');
    confess "calibration disposition drift authority changed\n"
        unless ($drift->{status} // '')
                eq 'expected_intentional_post_publication_drift'
            && ($drift->{authority} // '') eq 'semantic_bridge'
            && ($drift->{family} // '') eq 'bridge_fanout_v1'
            && ($drift->{cause_revision} // '') eq $DRIFT_REVISION
            && ($drift->{selected_profile_count} // -1) == 108
            && ($drift->{current_validator_match_count} // -1) == 102
            && ($drift->{semantic_profile_count} // -1) == 56
            && ($drift->{semantic_current_validator_match_count} // -1) == 56
            && ($drift->{bridge_profile_count} // -1) == 52
            && ($drift->{bridge_current_validator_match_count} // -1) == 46
            && ($drift->{changed_profile_count} // -1)
                == @EXPECTED_DRIFT
            && ref($drift->{records}) eq 'ARRAY'
            && @{$drift->{records}} == @EXPECTED_DRIFT;
    for my $index (0 .. $#EXPECTED_DRIFT) {
        my $record = $drift->{records}[$index];
        my $expected = $EXPECTED_DRIFT[$index];
        _exact_keys($record, [qw(
            profile_id artifact_relative_path field historical_message
            current_message historical_output_bytes current_output_bytes
        )], 'calibration disposition drift record');
        my $historical_message = 'source_map count '
            . $expected->{historical_count} . ' exceeds limit 65536';
        confess "calibration disposition drift record changed\n"
            unless ($record->{profile_id} // '')
                    eq $expected->{profile_id}
                && ($record->{artifact_relative_path} // '')
                    eq join('/', $STORE_ROOT, $expected->{profile_id},
                        'measurement-set.json')
                && ($record->{field} // '') eq '/diagnostics/0/message'
                && ($record->{historical_message} // '')
                    eq $historical_message
                && ($record->{current_message} // '')
                    eq 'source_map count 65537 exceeds limit 65536'
                && ($record->{historical_output_bytes} // -1)
                    == $expected->{historical_bytes}
                && ($record->{current_output_bytes} // -1)
                    == $expected->{current_bytes};
    }
}

sub _assert_vhdl_lineage_drift {
    my ($drift) = @_;
    _exact_keys($drift, [qw(
        status cause_revisions backend_emission portable_vhdl_runtime
        osvvm_runtime
    )], 'VHDL lineage drift');
    confess "VHDL lineage drift status changed\n"
        unless ($drift->{status} // '')
            eq 'expected_vhdl_derived_identity_drift';
    confess "VHDL lineage drift cause census changed\n"
        unless ref($drift->{cause_revisions}) eq 'ARRAY'
            && @{$drift->{cause_revisions}} == 2;
    my @causes = (
        [$VHDL_CYCLE_REVISION, 127, 'scenario_cycle_projection_repair'],
        [$VHDL_BOUNDARY_REVISION, 112, 'scenario_boundary_time_repair'],
    );
    for my $index (0 .. $#causes) {
        my $cause = $drift->{cause_revisions}[$index];
        _exact_keys($cause, [qw(
            revision fixed_source_bytes_added role
        )], 'VHDL lineage drift cause');
        confess "VHDL lineage drift cause changed\n"
            unless ($cause->{revision} // '') eq $causes[$index][0]
                && ($cause->{fixed_source_bytes_added} // -1)
                    == $causes[$index][1]
                && ($cause->{role} // '') eq $causes[$index][2];
    }

    my $backend = $drift->{backend_emission};
    _exact_keys($backend, [qw(
        profile_id source_bytes_historical source_bytes_current
        fixed_source_bytes_added source_map_entries_historical
        source_map_entries_current changed_source
        artifact_graph_sha256_historical artifact_graph_sha256_current
        evaluation_identity_historical evaluation_identity_current
        rerun_identity
    )], 'VHDL backend-emission drift');
    confess "VHDL backend-emission drift changed\n"
        unless ($backend->{profile_id} // '')
                eq $BACKEND_VHDL_REFERENCE_PROFILE
            && ($backend->{source_bytes_historical} // -1) == 118_064
            && ($backend->{source_bytes_current} // -1) == 118_303
            && ($backend->{fixed_source_bytes_added} // -1) == 239
            && ($backend->{source_map_entries_historical} // -1) == 59
            && ($backend->{source_map_entries_current} // -1) == 59
            && ($backend->{artifact_graph_sha256_historical} // '')
                eq 'decfde42497a1826231769f8ead15c8d6ac38e2e2fe33ae8d0f6fb3d7d5377cd'
            && ($backend->{artifact_graph_sha256_current} // '')
                eq '61fedc13286538c58e9658223f4507ee4cd691ea021e2cc3e79e6c9c740c2cab'
            && ($backend->{evaluation_identity_historical} // '')
                eq 'backend-emission-evaluation/990e7366018125d443ba2095a98eb07426c3224d7fd5364168463313b4dd15fc'
            && ($backend->{evaluation_identity_current} // '')
                eq 'backend-emission-evaluation/d8f425cb9a8b58f4687b9fd67116fa079e8f229430575fbd1a7a07b50384cdbc'
            && ($backend->{rerun_identity} // '')
                eq 'rerun/bad6f8b30198c0159d43ba8d296729dc91ae63234de841a676aebb6c7fb8d413';
    my $changed = $backend->{changed_source};
    _exact_keys($changed, [qw(
        relpath historical_bytes current_bytes historical_sha256
        current_sha256
    )], 'VHDL backend changed source');
    confess "VHDL backend changed source drift changed\n"
        unless ($changed->{relpath} // '')
                eq 'backends/vhdl_portable_ghdl/src/base_output_arbitration_tb.vhd'
            && ($changed->{historical_bytes} // -1) == 46_264
            && ($changed->{current_bytes} // -1) == 46_503
            && ($changed->{historical_sha256} // '')
                eq 'bc45987685e0e2fcf1adb5bbb0a20110dbdcc695ee1c556b1bee41c5b953f8d5'
            && ($changed->{current_sha256} // '')
                eq '69e3cb8f5f19391b516f65fed0183b46d0bf920ea40ed5fb644aa38307531693';

    _assert_runtime_materialization_drift(
        $drift->{portable_vhdl_runtime},
        'portable VHDL runtime',
        $PORTABLE_VHDL_REFERENCE_PROFILE,
        'portable-vhdl-runtime-materialization/7c44198da04cdd158b19213980fc5ccd3cebbf3387a43f020a14e33921dcea15',
        'portable-vhdl-runtime-materialization/6f12ab75b1ea1e57d3446ef714669daecdc5d2b56f9ff58d6c7fe755147d83bb',
    );
    _assert_runtime_materialization_drift(
        $drift->{osvvm_runtime},
        'OSVVM runtime',
        $OSVVM_REFERENCE_PROFILE,
        'osvvm-runtime-materialization/6ce4f9a16327c11b18e82052d525b6a534b69494456c955ee8496a5356a8551e',
        'osvvm-runtime-materialization/5cef115ed1dda90e706af7e68ab8434a20623f893fc6f05e34736b296f2f12da',
    );
}

sub _assert_runtime_materialization_drift {
    my ($record, $label, $profile_id, $historical, $current) = @_;
    _exact_keys($record, [qw(
        profile_id materialization_identity_historical
        materialization_identity_current
    )], "$label materialization drift");
    confess "$label materialization drift changed\n"
        unless ($record->{profile_id} // '') eq $profile_id
            && ($record->{materialization_identity_historical} // '')
                eq $historical
            && ($record->{materialization_identity_current} // '')
                eq $current
            && $historical ne $current;
}

sub _assert_immutable_store {
    my ($store) = @_;
    _exact_keys($store, [qw(
        status file_count bytes aggregate_identity selected_legacy_overlap
        selected_closure_overlap legacy_closure_overlap
    )], 'immutable calibration store disposition');
    confess "immutable store census changed\n"
        unless ($store->{status} // '') eq 'exact_partition'
            && ($store->{file_count} // -1) == 256
            && ($store->{bytes} // -1) == 32_007_521
            && ($store->{selected_legacy_overlap} // -1) == 0
            && ($store->{selected_closure_overlap} // -1) == 0
            && ($store->{legacy_closure_overlap} // -1) == 0;
    _assert_aggregate_identity($store->{aggregate_identity},
        'immutable calibration store');
}

sub _assert_lineage_identities {
    my ($value) = @_;
    confess "calibration closure identity is invalid\n"
        unless ($value->{closure_identity} // '')
            =~ /\Acalibration-closure\/[0-9a-f]{64}\z/;
    confess "calibration publication identity is invalid\n"
        unless ($value->{publication_identity} // '')
            =~ /\Acalibration-closure-publication\/[0-9a-f]{64}\z/;
    confess "calibration publisher revision is invalid\n"
        if exists($value->{publisher_revision})
            && ($value->{publisher_revision} // '') !~ /\A[0-9a-f]{40}\z/;
    _assert_aggregate_identity($value->{aggregate_identity},
        'calibration lineage');
}

sub _assert_aggregate_identity {
    my ($identity, $label) = @_;
    confess "$label aggregate identity is invalid\n"
        unless ($identity // '')
            =~ /\Acalibration-artifact-set\/[0-9a-f]{64}\z/;
}

sub _disposition_identity {
    my ($report) = @_;
    my $projection = _clone($report);
    $projection->{disposition_identity} = undef;
    return 'calibration-disposition/'
        . sha256_hex(_canonical_json($projection));
}

sub _repository_root {
    my ($raw) = @_;
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

sub _require_active_guard {
    confess "calibration disposition requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "calibration disposition guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss <= 4096;
}

sub _request {
    my ($method, $args, $keys) = @_;
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

sub _safe_relative_path {
    my ($value) = @_;
    confess "calibration disposition path must be repository-relative\n"
        unless defined($value) && !ref($value) && length($value)
            && !File::Spec->file_name_is_absolute($value)
            && $value !~ m{\A[A-Za-z]:[\\/]}
            && $value !~ m{(?:\A|/)\.\.(?:/|\z)}
            && $value !~ m{//}
            && $value !~ /[\x00-\x1f\x7f]/
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split(m{/}, $value, -1);
    return $value;
}

sub _positive_integer {
    my ($value) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A[1-9][0-9]*\z/;
}

sub _exact_keys {
    my ($value, $keys, $label) = @_;
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @{$keys};
    my @unknown = sort grep { !$expected{$_} } keys %{$value};
    my @missing = grep { !exists($value->{$_}) } @{$keys};
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _exact_invocant {
    my ($class, $method) = @_;
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _canonical_json {
    my ($value) = @_;
    return JSON::PP->new->canonical(1)->utf8(1)->encode($value);
}

sub _clone {
    my ($value) = @_;
    return JSON::PP->new->utf8(1)->decode(_canonical_json($value));
}

1;
