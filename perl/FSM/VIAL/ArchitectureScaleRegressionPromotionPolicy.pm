package FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy;

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
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleCalibrationClosurePublication;

my $PUBLICATION =
    'FSM::VIAL::ArchitectureScaleCalibrationClosurePublication';
my $SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_policy.v1';
my $SOURCE_REPORT = join '/', qw(
    .artifacts qualification vial-scale v1 calibration-closure-v1
    calibration-closure.json
);
my $CURRENT_PUBLICATION_BASE =
    '.artifacts/qualification/vial-scale/v2';
my $CURRENT_PUBLICATION_ID = 'regression-promotion-corpus-v1';
my $CURRENT_PUBLICATION_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1';
my $MAX_REPORT_BYTES = 2_097_152;
my $PERFORMANCE_APPLICABILITY_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_performance_applicability.v1';

my @REPORT_KEYS = qw(
    schema schema_version policy_identity source_evidence selected_strategy
    alternative_strategy scope_comparison selected_profiles capture_contract
    enforcement_contract explicit_nonclaims
);
my @SELECTED_PROFILE_KEYS = qw(
    ordinal selection_key authority family level primary_axis backend_profile
    historical_profile_id historical_raw_records historical_raw_wall_time_ns
    historical_maximum_wall_time_ns historical_maximum_tree_rss_bytes
);
my @PERFORMANCE_APPLICABILITY_KEYS = qw(
    schema schema_version applicability_identity refines_policy_schema
    evidence_revision_role exact_environment_fields
    exact_deterministic_fields matching_later_revision
    deterministic_mismatch environment_mismatch unavailable_exact_provider
    recalibration
);
my @EXACT_ENVIRONMENT_FIELDS = qw(
    host_profile tool_profile resource_guard provider_status
);
my @EXACT_DETERMINISTIC_FIELDS = qw(
    selection_key workload_identity correctness_projection_identity
);
my @NONCLAIMS = qw(
    historical_measurement_is_current
    historical_candidate_budget_is_promoted
    complete_current_closure
    qualification_candidate_promotion
    architecture_scale_capacity
    whole_product_big
    whole_product_really_big
    multi_unit
    multi_domain
    mixed_language
    native_uvm_runtime
    full_language
    synthesis
    arbitrary_tool_capacity
    general_cross_backend_parity
    unmatched_host_performance_enforcement
    unavailable_provider_pass
    ordinary_slice_full_ci
);

my @SELECTIONS = (
    {
        authority => 'semantic_bridge',
        family => 'semantic_catalog_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'actions',
        backend_profile => undef,
    },
    {
        authority => 'semantic_bridge',
        family => 'bridge_fanout_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'backend_bindings',
        backend_profile => undef,
    },
    {
        authority => 'execution_checking',
        family => 'execution_graph_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'bindings',
        backend_profile => undef,
    },
    {
        authority => 'execution_checking',
        family => 'checking_state_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'random_occurrences',
        backend_profile => undef,
    },
    {
        authority => 'backend_emission',
        family => 'backend_emission_v1',
        level => 'gate_candidate_v1',
        primary_axis => undef,
        backend_profile => 'sv_portable_verilator',
    },
    {
        authority => 'backend_emission',
        family => 'backend_emission_v1',
        level => 'gate_candidate_v1',
        primary_axis => undef,
        backend_profile => 'vhdl_portable_ghdl',
    },
    {
        authority => 'backend_emission',
        family => 'backend_emission_v1',
        level => 'gate_candidate_v1',
        primary_axis => undef,
        backend_profile => 'vhdl_osvvm_qualified',
    },
    {
        authority => 'portable_runtime',
        family => 'runtime_stream_v1',
        level => 'gate_candidate_v1',
        primary_axis => undef,
        backend_profile => 'sv_portable_verilator',
    },
    {
        authority => 'portable_vhdl_runtime',
        family => 'runtime_stream_v1',
        level => 'gate_candidate_v1',
        primary_axis => undef,
        backend_profile => 'vhdl_portable_ghdl',
    },
    {
        authority => 'osvvm_runtime',
        family => 'runtime_stream_v1',
        level => 'gate_candidate_v1',
        primary_axis => undef,
        backend_profile => 'vhdl_osvvm_qualified',
    },
    {
        authority => 'balanced_portable',
        family => 'balanced_portable_v1',
        level => 'gate_candidate_v1',
        primary_axis => undef,
        backend_profile => 'sv_portable_verilator',
    },
);

my $EXPECTED_SOURCE_SUMMARY = {
    authority_count => 7,
    family_count => 9,
    profile_count => 216,
    raw_measurement_records => 356,
    excluded_measurement_records => 0,
    candidate_profiles => 92,
    noncandidate_profiles => 124,
};
my $EXPECTED_SOURCE_METRICS = {
    raw_measurement_records => 356,
    raw_wall_time_ns => 6_806_844_563_000,
    maximum_tree_rss_bytes => 2_764_865_536,
};
my $EXPECTED_SELECTED_METRICS = {
    profile_count => 11,
    raw_measurement_records => 33,
    raw_wall_time_ns => 2_135_252_066_000,
    maximum_tree_rss_bytes => 1_925_595_136,
};

my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub selected_profile_keys($class) {
    _exact_invocant($class, 'selected_profile_keys');
    return [@SELECTED_PROFILE_KEYS];
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub performance_applicability_keys($class) {
    _exact_invocant($class, 'performance_applicability_keys');
    return [@PERFORMANCE_APPLICABILITY_KEYS];
}

sub performance_applicability_contract($class, @args) {
    _exact_invocant($class, 'performance_applicability_contract');
    confess __PACKAGE__
        . "->performance_applicability_contract accepts no caller input\n"
        if @args;
    my $contract = {
        schema => $PERFORMANCE_APPLICABILITY_SCHEMA,
        schema_version => 1,
        applicability_identity => undef,
        refines_policy_schema => $SCHEMA,
        evidence_revision_role => 'immutable_qualification_provenance_only',
        exact_environment_fields => [@EXACT_ENVIRONMENT_FIELDS],
        exact_deterministic_fields => [@EXACT_DETERMINISTIC_FIELDS],
        matching_later_revision =>
            'performance_enforcement_eligible_after_correctness',
        deterministic_mismatch => 'correctness_rejects_before_performance',
        environment_mismatch =>
            'correctness_required_performance_informational',
        unavailable_exact_provider => 'unavailable_not_pass',
        recalibration => 'owned_version_replacement_with_old_new_evidence',
    };
    $contract->{applicability_identity} =
        'regression-promotion-performance-applicability/'
        . sha256_hex(_canonical_json($contract));
    _validate_performance_applicability_contract($contract);
    return _clone($contract);
}

sub derive($class, @args) {
    _exact_invocant($class, 'derive');
    my $raw = _request('derive', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    my $manifest = $PUBLICATION->validate_complete_publication({
        repository_root => $repo_root,
    });
    my $report = _load_authenticated_report(
        $repo_root, $root_device, $manifest,
    );
    return _clone(_derive_from_report($report, $manifest));
}

sub _derive_from_report($report, $manifest = undef) {
    _validate_source_report($report);
    if (defined $manifest) {
        confess "promotion policy manifest must be a hash\n"
            unless ref($manifest) eq 'HASH' && !blessed($manifest);
        confess "promotion policy source publication identity changed\n"
            unless ($manifest->{publication_identity} // '') eq
                'calibration-closure-publication/'
                . '1316d11a6dfa008515fcb23aa132e30a72e7961d9e9e6eeba82ae0bf42546ac8';
        confess "promotion policy source closure identity changed\n"
            unless ($manifest->{closure_identity} // '') eq
                ($report->{closure_identity} // '');
        confess "promotion policy source summary changed\n"
            unless _canonical_json($manifest->{summary}) eq
                _canonical_json($report->{summary});
    }

    my $source_metrics = _source_metrics($report->{profiles});
    confess "promotion policy source metrics changed\n"
        unless _canonical_json($source_metrics) eq
            _canonical_json($EXPECTED_SOURCE_METRICS);

    my @selected;
    my %selected_profile_ids;
    for my $ordinal (1 .. scalar @SELECTIONS) {
        my $selection = $SELECTIONS[$ordinal - 1];
        my @matches = grep {
            _profile_matches($_, $selection)
        } @{$report->{profiles}};
        confess "promotion policy selection must resolve exactly once\n"
            unless @matches == 1;
        my $profile = $matches[0];
        _validate_selected_profile($profile);
        my $profile_id = $profile->{coordinates}{profile_id};
        confess "promotion policy selected duplicate profile identity\n"
            if $selected_profile_ids{$profile_id}++;
        push @selected, _selected_projection(
            $ordinal, $selection, $profile,
        );
    }

    my $selected_metrics = _selected_metrics(\@selected);
    confess "promotion policy selected metrics changed\n"
        unless _canonical_json($selected_metrics) eq
            _canonical_json($EXPECTED_SELECTED_METRICS);

    my $report_out = {
        schema => $SCHEMA,
        schema_version => 1,
        policy_identity => undef,
        source_evidence => {
            publication_identity =>
                'calibration-closure-publication/'
                . '1316d11a6dfa008515fcb23aa132e30a72e7961d9e9e6eeba82ae0bf42546ac8',
            closure_identity => $report->{closure_identity},
            disposition => 'explicitly_versioned_historical',
            evidence_role => 'historical_measurement_only',
            candidate_budget_status => 'candidate_only',
            current_performance_eligible => JSON::PP::false,
        },
        selected_strategy => {
            strategy => 'representative_current_promotion_corpus',
            reason => 'promote only current representative gate profiles',
            current_capture_required => JSON::PP::true,
            historical_sample_reuse_allowed => JSON::PP::false,
        },
        alternative_strategy => {
            strategy => 'complete_current_closure_recapture',
            status => 'not_selected_for_regression_promotion',
            remains_available_for => 'complete_current_research_closure',
            reason => 'promotion does not require every nonpromoted profile',
        },
        scope_comparison => {
            historical_complete => {
                profile_count => $report->{summary}{profile_count},
                candidate_profile_count =>
                    $report->{summary}{candidate_profiles},
                raw_measurement_records =>
                    $source_metrics->{raw_measurement_records},
                raw_wall_time_ns => $source_metrics->{raw_wall_time_ns},
                maximum_tree_rss_bytes =>
                    $source_metrics->{maximum_tree_rss_bytes},
            },
            representative_current => {
                profile_count => $selected_metrics->{profile_count},
                raw_measurement_records =>
                    $selected_metrics->{raw_measurement_records},
                raw_wall_time_ns_historical_comparator =>
                    $selected_metrics->{raw_wall_time_ns},
                maximum_tree_rss_bytes_historical_comparator =>
                    $selected_metrics->{maximum_tree_rss_bytes},
                fresh_validation_records_required => 11,
                fresh_raw_measurement_records_required => 33,
                fresh_total_invocations_required => 44,
            },
            historical_profile_reduction => 205,
            historical_raw_record_reduction => 323,
            historical_raw_wall_time_ns_reduction => 4_671_592_497_000,
            comparator_is_not_a_budget => JSON::PP::true,
        },
        selected_profiles => \@selected,
        capture_contract => {
            publication_base => $CURRENT_PUBLICATION_BASE,
            publication_id => $CURRENT_PUBLICATION_ID,
            schema => $CURRENT_PUBLICATION_SCHEMA,
            profile_count => 11,
            validation_records_per_profile => 1,
            raw_measurement_records_per_profile => 3,
            sample_exclusions_allowed => 0,
            current_revision_required => JSON::PP::true,
            fresh_common_identity_required => JSON::PP::true,
            exact_qualified_tool_required_when_applicable => JSON::PP::true,
            atomic_publication_required => JSON::PP::true,
            same_volume_cleanup_required => JSON::PP::true,
            historical_artifact_substitution_allowed => JSON::PP::false,
        },
        enforcement_contract => {
            performance_budget_source => 'new_current_corpus_only',
            performance_enforcement => 'exact_common_identity_only',
            unmatched_common_identity =>
                'correctness_required_performance_informational',
            unavailable_exact_provider => 'unavailable_not_pass',
            ordinary_slice_ci => 'contract_and_focused_correctness_only',
            full_pre_push_gate => 'guarded_current_corpus_and_regression_gate',
            hosted_ci_performance => 'informational_only',
            recalibration => 'owned_version_replacement_with_old_new_evidence',
        },
        explicit_nonclaims => [@NONCLAIMS],
    };
    $report_out->{policy_identity} = 'regression-promotion-policy/'
        . sha256_hex(_canonical_json($report_out));
    _validate_policy_report($report_out);
    return $report_out;
}

sub _load_authenticated_report($repo_root, $root_device, $manifest) {
    confess "promotion policy manifest report artifact is missing\n"
        unless ref($manifest->{report_artifact}) eq 'HASH';
    my $artifact = $manifest->{report_artifact};
    confess "promotion policy manifest report path changed\n"
        unless ($artifact->{artifact_relative_path} // '') eq $SOURCE_REPORT;
    confess "promotion policy manifest report size is invalid\n"
        unless _positive_integer($artifact->{bytes})
            && $artifact->{bytes} <= $MAX_REPORT_BYTES;
    confess "promotion policy manifest report digest is invalid\n"
        unless ($artifact->{sha256} // '') =~ /\A[0-9a-f]{64}\z/;

    my $path = File::Spec->catfile(
        $repo_root, split m{/}, $SOURCE_REPORT,
    );
    my @lstat = lstat($path);
    confess "promotion policy source report is missing\n" unless @lstat;
    confess "promotion policy source report must be a regular file\n"
        unless -f _ && !-l _;
    confess "promotion policy source report left the repository volume\n"
        unless $lstat[0] == $root_device;
    confess "promotion policy source report byte count changed\n"
        unless $lstat[7] == $artifact->{bytes};

    open my $fh, '<:raw', $path
        or confess "cannot read promotion policy source report\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or confess "cannot close promotion policy source report\n";
    confess "promotion policy source report changed while reading\n"
        unless bytes::length($bytes) == $artifact->{bytes};
    confess "promotion policy source report digest changed\n"
        unless sha256_hex($bytes) eq $artifact->{sha256};
    my $report = eval { $JSON->decode($bytes) };
    confess "promotion policy source report is not canonical JSON\n"
        if $@ || !defined($report) || ref($report) ne 'HASH'
            || _canonical_json($report) . "\n" ne $bytes;
    return $report;
}

sub _validate_source_report($report) {
    confess "promotion policy source report must be a hash\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    confess "promotion policy source report schema changed\n"
        unless ($report->{schema} // '') eq
            'fsmgen.vial_architecture_scale_calibration_closure.v1'
            && ($report->{schema_version} // 0) == 1
            && ($report->{outcome} // '') eq 'accepted';
    confess "promotion policy source closure identity changed\n"
        unless ($report->{closure_identity} // '') eq
            'calibration-closure/'
            . '92ef0a203e18ce8de8b17cf819f36b73fe0889f00fdcb4def8b2b0e9eeb9dcc5';
    confess "promotion policy source summary changed\n"
        unless _canonical_json($report->{summary}) eq
            _canonical_json($EXPECTED_SOURCE_SUMMARY);
    confess "promotion policy source profiles are invalid\n"
        unless ref($report->{profiles}) eq 'ARRAY'
            && @{$report->{profiles}} ==
                $EXPECTED_SOURCE_SUMMARY->{profile_count};
    confess "promotion policy source candidate formula changed\n"
        unless ref($report->{candidate_formula}) eq 'HASH'
            && ($report->{candidate_formula}{status} // '') eq
                'candidate_only'
            && ($report->{candidate_formula}{authority} // '') eq
                'decision-0056';
}

sub _source_metrics($profiles) {
    my ($raw_records, $raw_wall, $maximum_rss) = (0, 0, 0);
    my %profile_ids;
    for my $profile (@{$profiles}) {
        confess "promotion policy source profile must be a hash\n"
            unless ref($profile) eq 'HASH' && !blessed($profile);
        confess "promotion policy source profile coordinates are invalid\n"
            unless ref($profile->{coordinates}) eq 'HASH';
        my $profile_id = $profile->{coordinates}{profile_id};
        confess "promotion policy source profile ID is invalid\n"
            unless defined($profile_id) && !ref($profile_id)
                && length($profile_id);
        confess "promotion policy source profile ID is duplicated\n"
            if $profile_ids{$profile_id}++;
        my $runs = $profile->{accepted_run_totals};
        confess "promotion policy source run totals are invalid\n"
            unless ref($runs) eq 'ARRAY';
        for my $run (@{$runs}) {
            confess "promotion policy source run total is invalid\n"
                unless ref($run) eq 'HASH'
                    && _nonnegative_integer($run->{wall_time_ns});
            $raw_records++;
            $raw_wall += $run->{wall_time_ns};
        }
        next unless @{$runs};
        my $rss = $profile->{aggregate_statistics}{peak_tree_rss_bytes}{maximum};
        confess "promotion policy source maximum RSS is invalid\n"
            unless _nonnegative_integer($rss);
        $maximum_rss = $rss if $rss > $maximum_rss;
    }
    return {
        raw_measurement_records => $raw_records,
        raw_wall_time_ns => $raw_wall,
        maximum_tree_rss_bytes => $maximum_rss,
    };
}

sub _profile_matches($profile, $selection) {
    return 0 unless ref($profile) eq 'HASH'
        && ref($profile->{coordinates}) eq 'HASH';
    my $coordinates = $profile->{coordinates};
    return 0 unless ($profile->{authority} // '') eq $selection->{authority};
    return 0 unless ($coordinates->{family} // '') eq $selection->{family};
    return 0 unless ($coordinates->{level} // '') eq $selection->{level};
    for my $key (qw(primary_axis backend_profile)) {
        my $actual = $coordinates->{$key};
        my $expected = $selection->{$key};
        return 0 if defined($actual) != defined($expected);
        return 0 if defined($expected) && $actual ne $expected;
    }
    return 1;
}

sub _validate_selected_profile($profile) {
    confess "promotion policy selected profile is not an accepted candidate\n"
        unless ($profile->{matrix_profile}{outcome} // '') eq 'accepted'
            && ($profile->{candidate_budget}{status} // '') eq 'candidate_only'
            && ($profile->{candidate_budget}{formula_authority} // '') eq
                'decision-0056';
    confess "promotion policy selected profile applicability changed\n"
        unless $profile->{measurement_applicability}{applicable};
    confess "promotion policy selected profile raw evidence changed\n"
        unless ref($profile->{accepted_run_totals}) eq 'ARRAY'
            && @{$profile->{accepted_run_totals}} == 3
            && ref($profile->{raw_measurement_identities}) eq 'ARRAY'
            && @{$profile->{raw_measurement_identities}} == 3
            && ref($profile->{sample_exclusions}) eq 'ARRAY'
            && @{$profile->{sample_exclusions}} == 0;
    confess "promotion policy selected profile cleanup changed\n"
        unless $profile->{cleanup}{ephemeral_removed}
            && ref($profile->{cleanup}{residue}) eq 'ARRAY'
            && @{$profile->{cleanup}{residue}} == 0;
    for my $run (@{$profile->{accepted_run_totals}}) {
        confess "promotion policy selected run total is invalid\n"
            unless _nonnegative_integer($run->{wall_time_ns})
                && _nonnegative_integer($run->{cpu_time_ns})
                && _nonnegative_integer($run->{peak_tree_rss_bytes});
    }
}

sub _selected_projection($ordinal, $selection, $profile) {
    my $raw_wall = 0;
    $raw_wall += $_->{wall_time_ns}
        for @{$profile->{accepted_run_totals}};
    my $selection_key = join '|', map { defined($_) ? $_ : '-' } (
        $selection->{authority}, $selection->{family},
        $selection->{level}, $selection->{primary_axis},
        $selection->{backend_profile},
    );
    return {
        ordinal => $ordinal,
        selection_key => $selection_key,
        authority => $selection->{authority},
        family => $selection->{family},
        level => $selection->{level},
        primary_axis => $selection->{primary_axis},
        backend_profile => $selection->{backend_profile},
        historical_profile_id => $profile->{coordinates}{profile_id},
        historical_raw_records => scalar @{$profile->{accepted_run_totals}},
        historical_raw_wall_time_ns => $raw_wall,
        historical_maximum_wall_time_ns =>
            $profile->{aggregate_statistics}{wall_time_ns}{maximum},
        historical_maximum_tree_rss_bytes =>
            $profile->{aggregate_statistics}{peak_tree_rss_bytes}{maximum},
    };
}

sub _selected_metrics($selected) {
    my ($records, $wall, $maximum_rss) = (0, 0, 0);
    for my $profile (@{$selected}) {
        $records += $profile->{historical_raw_records};
        $wall += $profile->{historical_raw_wall_time_ns};
        my $rss = $profile->{historical_maximum_tree_rss_bytes};
        $maximum_rss = $rss if $rss > $maximum_rss;
    }
    return {
        profile_count => scalar @{$selected},
        raw_measurement_records => $records,
        raw_wall_time_ns => $wall,
        maximum_tree_rss_bytes => $maximum_rss,
    };
}

sub _validate_policy_report($report) {
    _exact_keys($report, \@REPORT_KEYS, 'promotion policy report');
    confess "promotion policy report schema is invalid\n"
        unless ($report->{schema} // '') eq $SCHEMA
            && ($report->{schema_version} // 0) == 1;
    confess "promotion policy report identity is invalid\n"
        unless ($report->{policy_identity} // '') =~
            /\Aregression-promotion-policy\/[0-9a-f]{64}\z/;
    my $projection = _clone($report);
    $projection->{policy_identity} = undef;
    confess "promotion policy report identity changed\n"
        unless $report->{policy_identity} eq
            'regression-promotion-policy/'
            . sha256_hex(_canonical_json($projection));
    confess "promotion policy selected profile count changed\n"
        unless ref($report->{selected_profiles}) eq 'ARRAY'
            && @{$report->{selected_profiles}} == @SELECTIONS;
    my $expected_ordinal = 1;
    my %selection_keys;
    for my $profile (@{$report->{selected_profiles}}) {
        _exact_keys(
            $profile, \@SELECTED_PROFILE_KEYS,
            'promotion policy selected profile',
        );
        confess "promotion policy selected profile order changed\n"
            unless $profile->{ordinal} == $expected_ordinal++;
        confess "promotion policy selection key is invalid\n"
            unless defined($profile->{selection_key})
                && !ref($profile->{selection_key})
                && length($profile->{selection_key});
        confess "promotion policy selection key is duplicated\n"
            if $selection_keys{$profile->{selection_key}}++;
    }
    confess "promotion policy nonclaims changed\n"
        unless _canonical_json($report->{explicit_nonclaims}) eq
            _canonical_json(\@NONCLAIMS);
}

sub _validate_performance_applicability_contract($contract) {
    _exact_keys(
        $contract, \@PERFORMANCE_APPLICABILITY_KEYS,
        'promotion performance-applicability contract',
    );
    confess "promotion performance-applicability schema is invalid\n"
        unless ($contract->{schema} // '') eq $PERFORMANCE_APPLICABILITY_SCHEMA
            && _json_integer_equals($contract->{schema_version}, 1);
    my $projection = _clone($contract);
    my $identity = $projection->{applicability_identity};
    $projection->{applicability_identity} = undef;
    confess "promotion performance-applicability identity changed\n"
        unless defined($identity) && !ref($identity)
            && $identity eq
                'regression-promotion-performance-applicability/'
                . sha256_hex(_canonical_json($projection));
    confess "promotion performance-applicability policy binding changed\n"
        unless ($contract->{refines_policy_schema} // '') eq $SCHEMA;
    confess "promotion evidence revision became an enforcement dimension\n"
        unless ($contract->{evidence_revision_role} // '') eq
            'immutable_qualification_provenance_only';
    confess "promotion exact environment identity changed\n"
        unless _canonical_json($contract->{exact_environment_fields}) eq
            _canonical_json(\@EXACT_ENVIRONMENT_FIELDS);
    confess "promotion exact deterministic identity changed\n"
        unless _canonical_json($contract->{exact_deterministic_fields}) eq
            _canonical_json(\@EXACT_DETERMINISTIC_FIELDS);
    confess "promotion performance-applicability behavior changed\n"
        unless ($contract->{matching_later_revision} // '') eq
                'performance_enforcement_eligible_after_correctness'
            && ($contract->{deterministic_mismatch} // '') eq
                'correctness_rejects_before_performance'
            && ($contract->{environment_mismatch} // '') eq
                'correctness_required_performance_informational'
            && ($contract->{unavailable_exact_provider} // '') eq
                'unavailable_not_pass'
            && ($contract->{recalibration} // '') eq
                'owned_version_replacement_with_old_new_evidence';
    return 1;
}

sub _repository_root($value) {
    confess "promotion policy repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "promotion policy repository root is unavailable\n"
        unless defined($root) && -d $root
            && -d File::Spec->catdir($root, '.git');
    my @stat = stat($root);
    confess "promotion policy repository root cannot be inspected\n"
        unless @stat;
    return ($root, $stat[0]);
}

sub _require_active_guard() {
    confess "regression promotion policy requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "regression promotion policy guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss <= 4096;
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

sub _positive_integer($value) {
    return _nonnegative_integer($value) && $value > 0;
}

sub _json_integer_equals($value, $expected) {
    return defined($value) && !ref($value)
        && _canonical_json($value) eq "$expected";
}

sub _nonnegative_integer($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
