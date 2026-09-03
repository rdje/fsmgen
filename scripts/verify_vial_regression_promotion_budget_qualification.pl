#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use File::Find qw(find);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);

my $ROOT = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $PUBLICATION_RELATIVE = join '/', qw(
    .artifacts qualification vial-scale v2
    regression-promotion-budget-qualification-v1 current
);
my $CORPUS_RELATIVE = join '/', qw(
    .artifacts qualification vial-scale v2 regression-promotion-corpus-v1
);
my $STAGING_RELATIVE = join '/', qw(
    .artifacts tmp vial-scale
    regression-promotion-budget-qualification-publication v1
);
my $SOURCE_VERIFIER_RELATIVE =
    'scripts/verify_vial_regression_promotion_current_corpus.pl';
my $REPORT_FILENAME = 'regression-promotion-budget-qualification.json';
my $MANIFEST_FILENAME = 'qualification-manifest.json';
my $REPORT_BYTES = 764_010;
my $MANIFEST_BYTES = 28_148;
my $REPORT_SHA256 =
    '524fad657f5f1b5d3bc6eb0287d86729af2d8ae9e725838a8305bd09f696a3fd';
my $MANIFEST_SHA256 =
    '5eebce24d05ef5493a4b42ab90c0114e45a49c2a169e22cb46c6af336ef69c62';
my $FILE_SET_SHA256 =
    '28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095';
my $CORPUS_FILE_SET_SHA256 =
    'dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f';
my $PUBLICATION_REPORT_IDENTITY =
    'regression-promotion-budget-qualification-report/'
    . '0da2324912a8ffcaa0c167e75a5ecac87911eb3bc44f6d8c2b128d07e869622c';
my $PUBLICATION_IDENTITY =
    'regression-promotion-budget-qualification-publication/'
    . '1c2a3832b2b4163e1a6a8124feff2b452f8522c2929098447f3903115ad2945f';
my $QUALIFICATION_IDENTITY =
    'regression-promotion-qualification/'
    . 'd8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97';
my $APPLICABILITY_IDENTITY =
    'regression-promotion-performance-applicability/'
    . 'b5976719c47be42095c2bf90e93c2f0bd5e68fff93bb7cd07adbf1172dba8018';
my $PUBLISHER_REVISION = '8667f766cfb5721600c466568b432ac4432255f7';
my $MAX_RESULT_BYTES = 262_144;
my $MAX_SOURCE_RESULT_BYTES = 65_536;
my $MAX_SAFE_INTEGER = 9_007_199_254_740_991;

my @STAGES = qw(
    construct parse_validate bridge bind_plan emit compile_analyze elaborate
    run trace_validate result_produce publish cleanup
);
my @REPORT_KEYS = qw(
    schema schema_version publication_report_identity publisher_revision
    qualification publication_contract outcome diagnostics explicit_nonclaims
);
my @MANIFEST_KEYS = qw(
    schema schema_version publication_identity publication_report_identity
    qualification_identity publisher_revision source_evidence formula_authority
    profile_bindings publication_contract report_artifact summary outcome
    explicit_nonclaims
);
my @QUALIFICATION_KEYS = qw(
    schema schema_version qualification_identity source_evidence formula
    performance_applicability summary profiles outcome diagnostics
    explicit_nonclaims
);
my @SOURCE_KEYS = qw(
    corpus_identity publication_identity file_set_sha256 plan_identity
    policy_identity publication_id publication_schema capture_revision
    dirty_state
);
my @FORMULA_KEYS = qw(authority wall_time_ns cpu_time_ns peak_tree_rss_bytes);
my @FORMULA_METRIC_KEYS = qw(
    floor multiplier_numerator multiplier_denominator quantum
);
my @SUMMARY_KEYS = qw(
    profile_count validation_records raw_measurement_records
    controller_invocations sample_exclusions qualified_profiles
);
my @PROFILE_KEYS = qw(
    ordinal selection_key profile_qualification_identity source_report_identity
    workload_identity evidence_revision environment_identity
    correctness_projection_identity correctness_projection
    performance_applicability_identity validation_identity
    raw_measurement_identities accepted_run_totals aggregate_statistics
    qualified_budget provider_status outcome
);
my @ENVIRONMENT_KEYS = qw(
    environment_identity host_profile tool_profile resource_guard provider_status
);
my @RUN_TOTAL_KEYS = qw(
    measurement_identity run_ordinal wall_time_ns cpu_time_ns
    peak_tree_rss_bytes
);
my @AGGREGATE_KEYS = qw(wall_time_ns cpu_time_ns peak_tree_rss_bytes);
my @STATISTIC_KEYS = qw(
    sample_count minimum median maximum median_absolute_deviation
);
my @BUDGET_KEYS = qw(
    status formula_authority wall_time_ns cpu_time_ns peak_tree_rss_bytes
);
my @PROFILE_BINDING_KEYS = qw(
    ordinal selection_key profile_qualification_identity source_report_identity
    workload_identity evidence_revision environment_identity
    correctness_projection_identity performance_applicability_identity
    qualified_budget provider_status
);
my @PUBLICATION_CONTRACT_KEYS = qw(
    schema schema_version predecessor replacement_policy recalibration rollback
    enforcement_state
);
my @PERFORMANCE_APPLICABILITY_KEYS = qw(
    schema schema_version applicability_identity refines_policy_schema
    evidence_revision_role exact_environment_fields exact_deterministic_fields
    matching_later_revision deterministic_mismatch environment_mismatch
    unavailable_exact_provider recalibration
);
my @MEASUREMENT_KEYS = qw(
    schema schema_version measurement_identity workload_identity
    workload_specification git_revision dirty_state host_profile tool_profile
    run_class run_ordinal stage_measurements correctness_oracles resource_guard
    artifacts outcome diagnostic cleanup explicit_nonclaims
);
my @STAGE_KEYS = qw(
    stage classification status command_identity timeout wall_time_ns
    controller_cpu descendant_cpu rss raw_samples input_counts output_counts
    semantic_object_counts correctness_oracle_ids process worker_status
    not_run_reason unsupported_counters
);
my @CORRECTNESS_PROJECTION_KEYS = qw(
    schema schema_version report_contract record_projections
);
my @CORRECTNESS_RECORD_KEYS = qw(
    schema schema_version workload_identity workload_specification run_class
    run_ordinal stage_measurements correctness_oracles artifact_records
    published_identity outcome diagnostic cleanup explicit_nonclaims
);
my @CORRECTNESS_STAGE_KEYS = qw(
    stage classification status input_counts output_counts
    semantic_object_counts correctness_oracle_ids process worker_status
    not_run_reason unsupported_counters
);
my @CORRECTNESS_ORACLE_KEYS = qw(stage oracle_id ok evidence_identity);
my @ORACLE_KEYS = qw(stage oracle_id ok evidence_identity evidence);
my @ARTIFACT_KEYS = qw(stage kind relative_path bytes lines sha256);
my @PROFILE_PUBLICATION_KEYS = qw(
    schema schema_version publication_identity plan_identity policy_identity
    publication_id publication_schema profile report
);
my @CORPUS_KEYS = qw(
    schema schema_version corpus_identity plan_identity policy_identity
    publication_id publication_schema common_identity summary profiles
    explicit_nonclaims
);
my @CORPUS_PROFILE_KEYS = qw(
    ordinal selection_key report_identity common_identity provider_status
    applicability_status artifact
);
my @CORPUS_ARTIFACT_KEYS = qw(
    ordinal selection_key relative_path sha256 bytes same_volume atomic
);

my @QUALIFICATION_NONCLAIMS = qw(
    qualification_publication promoted_performance_gate
    observed_performance_result support_promotion architecture_scale_capacity
    historical_artifact_reuse producer_execution provider_execution
    simulator_execution measurement_controller_execution
);
my @PUBLICATION_NONCLAIMS = qw(
    promoted_performance_gate observed_performance_result support_promotion
    architecture_scale_capacity historical_artifact_reuse producer_execution
    provider_execution simulator_execution measurement_controller_execution
    profile_capture_or_resume
);
my $EXPECTED_SUMMARY = {
    profile_count => 11,
    validation_records => 11,
    raw_measurement_records => 33,
    controller_invocations => 44,
    sample_exclusions => 0,
    qualified_profiles => 11,
};
my $FORMULA = {
    authority => 'decision-0056',
    wall_time_ns => {
        floor => 2_000_000_000,
        multiplier_numerator => 3,
        multiplier_denominator => 2,
        quantum => 1_000_000,
    },
    cpu_time_ns => {
        floor => 2_000_000_000,
        multiplier_numerator => 3,
        multiplier_denominator => 2,
        quantum => 1_000_000,
    },
    peak_tree_rss_bytes => {
        floor => 268_435_456,
        multiplier_numerator => 5,
        multiplier_denominator => 4,
        quantum => 16_777_216,
    },
};
my $PUBLICATION_CONTRACT = {
    schema =>
        'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_publication_contract.v1',
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
        trigger => 'environment_or_deterministic_behavior_or_formula_change',
    },
    rollback => {
        authority =>
            'remove_consumers_and_gates_before_publication_retirement',
        publication_mutation => JSON::PP::false,
    },
    enforcement_state => 'not_activated',
};
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

@ARGV == 0 or die
    "usage: scripts/verify_vial_regression_promotion_budget_qualification.pl\n";

my $result = _verify();
my $encoded = _canonical($result) . "\n";
die "qualification verification result exceeds its bounded ceiling\n"
    if bytes::length($encoded) > $MAX_RESULT_BYTES;
print $encoded;

sub _verify {
    my @root_stat = lstat($ROOT);
    die "cannot stat repository root\n"
        unless @root_stat && -d _ && !-l _;
    my ($root_device, $root_owner) = @root_stat[0, 4];
    my $staging = _root_path($STAGING_RELATIVE);
    die "qualification publication retained staging residue\n"
        if -e($staging) || -l($staging);

    my $source_verification = _verify_source_corpus();
    my ($report_bytes, $manifest_bytes, $files) =
        _read_publication($root_device, $root_owner);
    my $report = _decode_canonical($report_bytes, 'qualification report');
    my $manifest = _decode_canonical(
        $manifest_bytes, 'qualification manifest',
    );
    _validate_publication_envelope(
        $report, $manifest, $report_bytes, $manifest_bytes,
    );

    my $qualification = $report->{qualification};
    my $corpus = _load_source_corpus(
        $source_verification, $root_device, $root_owner,
    );
    my @reconstructed;
    for my $index (0 .. 10) {
        push @reconstructed, _reconstruct_profile(
            $qualification->{profiles}[$index],
            $corpus->{profiles}[$index],
            $qualification->{performance_applicability},
            $qualification->{source_evidence},
            $root_device,
            $root_owner,
        );
    }

    my $qualification_projection = _clone($qualification);
    my $qualification_identity =
        $qualification_projection->{qualification_identity};
    $qualification_projection->{qualification_identity} = undef;
    die "qualification content identity changed\n"
        unless ($qualification_identity // '') eq $QUALIFICATION_IDENTITY
            && $qualification_identity eq
                'regression-promotion-qualification/'
                . sha256_hex(_canonical($qualification_projection));

    return {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_verification.v1',
        schema_version => 1,
        active_relative_path => $PUBLICATION_RELATIVE,
        publication_report_identity => $report->{publication_report_identity},
        publication_identity => $manifest->{publication_identity},
        qualification_identity => $qualification_identity,
        publisher_revision => $report->{publisher_revision},
        file_set_sha256 => sha256_hex(join "\0",
            bytes::length($report_bytes), $report_bytes,
            bytes::length($manifest_bytes), $manifest_bytes,
        ),
        source_verification => {
            corpus_identity => $source_verification->{corpus_identity},
            publication_identity => $source_verification->{publication_identity},
            file_set_sha256 => $source_verification->{file_set_sha256},
            inventory_sha256 => $source_verification->{inventory_sha256},
            capture_revision => $source_verification->{capture_revision},
        },
        performance_applicability_identity =>
            $qualification->{performance_applicability}
                {applicability_identity},
        formula => _clone($FORMULA),
        summary => {
            publication_file_count => scalar(@$files),
            publication_total_bytes =>
                bytes::length($report_bytes) + bytes::length($manifest_bytes),
            %{$qualification->{summary}},
            reconstructed_profiles => scalar(@reconstructed),
            reconstructed_run_totals => 3 * scalar(@reconstructed),
            reconstructed_correctness_projections => scalar(@reconstructed),
            reconstructed_environment_identities => scalar(@reconstructed),
            reconstructed_applicability_identities => scalar(@reconstructed),
            reconstructed_budgets => 3 * scalar(@reconstructed),
        },
        profiles => \@reconstructed,
        files => $files,
        explicit_nonclaims => [qw(
            production_implementation_reuse publication_mutation
            producer_execution provider_execution simulator_execution
            measurement_controller_execution performance_enforcement
        )],
    };
}

sub _verify_source_corpus {
    my $script = _root_path($SOURCE_VERIFIER_RELATIVE);
    my $error = gensym;
    my $pid = open3(my $input, my $output, $error, $^X, $script);
    close $input;
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close $output;
    close $error;
    waitpid($pid, 0) == $pid
        or die "cannot wait for independent source verifier\n";
    die "independent source corpus verification failed\n"
        unless $? == 0 && $stderr eq '' && length($stdout)
            && bytes::length($stdout) <= $MAX_SOURCE_RESULT_BYTES;
    my $result = _decode_canonical(
        $stdout, 'independent source verification result',
    );
    die "independent source verification contract changed\n"
        unless ($result->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_current_corpus_verification.v1'
            && _integer_equals($result->{schema_version}, 1)
            && ($result->{file_set_sha256} // '') eq
                $CORPUS_FILE_SET_SHA256
            && _integer_equals($result->{summary}{profile_count}, 11)
            && _integer_equals($result->{summary}{file_count}, 13);
    return $result;
}

sub _read_publication {
    my ($root_device, $root_owner) = @_;
    my $active = _root_path($PUBLICATION_RELATIVE);
    _safe_node($active, $root_device, $root_owner, 'directory');
    my (%files, %directories);
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            die "qualification publication contains a symlink\n" if -l $path;
            my $relative = File::Spec->abs2rel($path, $active);
            $relative = '' if $relative eq '.';
            $relative =~ s{\\}{/}g;
            if (-d _) {
                _safe_node($path, $root_device, $root_owner, 'directory');
                $directories{$relative} = 1;
                return;
            }
            die "qualification publication contains a non-regular node\n"
                unless -f _;
            my @stat = _safe_node(
                $path, $root_device, $root_owner, 'single-link-file',
            );
            $files{$relative} = {path => $path, bytes => $stat[7]};
        },
    }, $active);
    die "qualification publication directory census changed\n"
        unless _same([sort keys %directories], ['']);
    die "qualification publication file census changed\n"
        unless _same(
            [sort keys %files],
            [sort ($REPORT_FILENAME, $MANIFEST_FILENAME)],
        );

    my $report_bytes = _read_exact(
        $files{$REPORT_FILENAME}{path}, $REPORT_BYTES,
    );
    my $manifest_bytes = _read_exact(
        $files{$MANIFEST_FILENAME}{path}, $MANIFEST_BYTES,
    );
    die "qualification report hash changed\n"
        unless sha256_hex($report_bytes) eq $REPORT_SHA256;
    die "qualification manifest hash changed\n"
        unless sha256_hex($manifest_bytes) eq $MANIFEST_SHA256;
    my $file_set_sha256 = sha256_hex(join "\0",
        bytes::length($report_bytes), $report_bytes,
        bytes::length($manifest_bytes), $manifest_bytes,
    );
    die "qualification file-set identity changed\n"
        unless $file_set_sha256 eq $FILE_SET_SHA256;
    my $inventory = [
        {
            relative_path => $MANIFEST_FILENAME,
            bytes => bytes::length($manifest_bytes),
            sha256 => sha256_hex($manifest_bytes),
        },
        {
            relative_path => $REPORT_FILENAME,
            bytes => bytes::length($report_bytes),
            sha256 => sha256_hex($report_bytes),
        },
    ];
    return ($report_bytes, $manifest_bytes, $inventory);
}

sub _validate_publication_envelope {
    my ($report, $manifest, $report_bytes, $manifest_bytes) = @_;
    _exact_keys($report, \@REPORT_KEYS, 'qualification publication report');
    _exact_keys($manifest, \@MANIFEST_KEYS, 'qualification manifest');
    die "qualification publication report schema changed\n"
        unless ($report->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_publication_report.v1'
            && _integer_equals($report->{schema_version}, 1)
            && ($report->{publisher_revision} // '') eq $PUBLISHER_REVISION
            && ($report->{outcome} // '') eq
                'accepted_published_qualification'
            && ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}}
            && _same($report->{explicit_nonclaims}, \@PUBLICATION_NONCLAIMS);
    my $report_projection = _clone($report);
    my $report_identity = $report_projection->{publication_report_identity};
    $report_projection->{publication_report_identity} = undef;
    die "qualification publication report identity changed\n"
        unless ($report_identity // '') eq $PUBLICATION_REPORT_IDENTITY
            && $report_identity eq
                'regression-promotion-budget-qualification-report/'
                . sha256_hex(_canonical($report_projection));

    die "qualification manifest schema changed\n"
        unless ($manifest->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_manifest.v1'
            && _integer_equals($manifest->{schema_version}, 1)
            && ($manifest->{publisher_revision} // '') eq $PUBLISHER_REVISION
            && ($manifest->{outcome} // '') eq
                'accepted_published_qualification'
            && _same($manifest->{explicit_nonclaims}, \@PUBLICATION_NONCLAIMS);
    my $manifest_projection = _clone($manifest);
    my $publication_identity = $manifest_projection->{publication_identity};
    $manifest_projection->{publication_identity} = undef;
    die "qualification publication identity changed\n"
        unless ($publication_identity // '') eq $PUBLICATION_IDENTITY
            && $publication_identity eq
                'regression-promotion-budget-qualification-publication/'
                . sha256_hex(_canonical($manifest_projection));

    die "qualification publication contract changed\n"
        unless _same($report->{publication_contract}, $PUBLICATION_CONTRACT)
            && _same($manifest->{publication_contract}, $PUBLICATION_CONTRACT);
    _validate_publication_contract($report->{publication_contract});
    _validate_qualification($report->{qualification});
    my $qualification = $report->{qualification};
    die "qualification manifest envelope binding changed\n"
        unless ($manifest->{publication_report_identity} // '') eq
                $report_identity
            && ($manifest->{qualification_identity} // '') eq
                $qualification->{qualification_identity}
            && _same($manifest->{source_evidence},
                $qualification->{source_evidence})
            && ($manifest->{formula_authority} // '') eq 'decision-0056'
            && _same($manifest->{summary}, $qualification->{summary})
            && _same($manifest->{profile_bindings},
                _profile_bindings($qualification->{profiles}));
    _exact_keys(
        $manifest->{report_artifact}, [qw(relative_path sha256 bytes)],
        'qualification manifest report artifact',
    );
    die "qualification report artifact binding changed\n"
        unless ($manifest->{report_artifact}{relative_path} // '') eq
                "$PUBLICATION_RELATIVE/$REPORT_FILENAME"
            && ($manifest->{report_artifact}{sha256} // '') eq
                sha256_hex($report_bytes)
            && _integer_equals(
                $manifest->{report_artifact}{bytes},
                bytes::length($report_bytes),
            );
    die "qualification manifest byte bound changed\n"
        unless bytes::length($manifest_bytes) == $MANIFEST_BYTES;
}

sub _validate_publication_contract {
    my ($contract) = @_;
    _exact_keys(
        $contract, \@PUBLICATION_CONTRACT_KEYS,
        'qualification publication contract',
    );
    _exact_keys($contract->{predecessor},
        [qw(status publication_identity)], 'publication predecessor');
    _exact_keys($contract->{replacement_policy},
        [qw(version overwrite)], 'publication replacement policy');
    _exact_keys($contract->{recalibration},
        [qw(authority evidence trigger)], 'publication recalibration');
    _exact_keys($contract->{rollback},
        [qw(authority publication_mutation)], 'publication rollback');
}

sub _validate_qualification {
    my ($qualification) = @_;
    _exact_keys(
        $qualification, \@QUALIFICATION_KEYS, 'embedded qualification',
    );
    die "embedded qualification schema changed\n"
        unless ($qualification->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_qualification.v1'
            && _integer_equals($qualification->{schema_version}, 1)
            && ($qualification->{outcome} // '') eq
                'accepted_qualified_unpublished'
            && ref($qualification->{diagnostics}) eq 'ARRAY'
            && !@{$qualification->{diagnostics}}
            && _same($qualification->{explicit_nonclaims},
                \@QUALIFICATION_NONCLAIMS);
    _exact_keys(
        $qualification->{source_evidence}, \@SOURCE_KEYS,
        'qualification source evidence',
    );
    _exact_keys($qualification->{formula}, \@FORMULA_KEYS,
        'qualification formula');
    for my $metric (@AGGREGATE_KEYS) {
        _exact_keys(
            $qualification->{formula}{$metric}, \@FORMULA_METRIC_KEYS,
            "qualification $metric formula",
        );
    }
    die "qualification formula changed\n"
        unless _same($qualification->{formula}, $FORMULA);
    _exact_keys($qualification->{summary}, \@SUMMARY_KEYS,
        'qualification summary');
    die "qualification summary changed\n"
        unless _same($qualification->{summary}, $EXPECTED_SUMMARY);
    _validate_performance_applicability(
        $qualification->{performance_applicability},
    );
    die "qualification profile count changed\n"
        unless ref($qualification->{profiles}) eq 'ARRAY'
            && @{$qualification->{profiles}} == 11;
    for my $index (0 .. 10) {
        _validate_qualified_profile_shape(
            $qualification->{profiles}[$index], $index + 1,
        );
    }
}

sub _validate_performance_applicability {
    my ($contract) = @_;
    _exact_keys(
        $contract, \@PERFORMANCE_APPLICABILITY_KEYS,
        'performance applicability contract',
    );
    my $projection = _clone($contract);
    my $identity = $projection->{applicability_identity};
    $projection->{applicability_identity} = undef;
    die "performance applicability identity changed\n"
        unless ($identity // '') eq $APPLICABILITY_IDENTITY
            && $identity eq
                'regression-promotion-performance-applicability/'
                . sha256_hex(_canonical($projection));
}

sub _validate_qualified_profile_shape {
    my ($profile, $ordinal) = @_;
    _exact_keys($profile, \@PROFILE_KEYS,
        "qualification profile $ordinal");
    die "qualification profile ordinal changed\n"
        unless _integer_equals($profile->{ordinal}, $ordinal)
            && ($profile->{outcome} // '') eq
                'accepted_qualified_unpublished';
    _exact_keys($profile->{environment_identity}, \@ENVIRONMENT_KEYS,
        "qualification profile $ordinal environment");
    _exact_keys($profile->{qualified_budget}, \@BUDGET_KEYS,
        "qualification profile $ordinal budget");
    die "qualification profile run totals changed\n"
        unless ref($profile->{accepted_run_totals}) eq 'ARRAY'
            && @{$profile->{accepted_run_totals}} == 3;
    for my $total (@{$profile->{accepted_run_totals}}) {
        _exact_keys($total, \@RUN_TOTAL_KEYS,
            "qualification profile $ordinal run total");
    }
    _exact_keys($profile->{aggregate_statistics}, \@AGGREGATE_KEYS,
        "qualification profile $ordinal aggregate");
    for my $metric (@AGGREGATE_KEYS) {
        _exact_keys(
            $profile->{aggregate_statistics}{$metric}, \@STATISTIC_KEYS,
            "qualification profile $ordinal $metric statistic",
        );
    }
    _validate_correctness_projection(
        $profile->{correctness_projection}, $ordinal,
    );
}

sub _validate_correctness_projection {
    my ($projection, $ordinal) = @_;
    _exact_keys(
        $projection, \@CORRECTNESS_PROJECTION_KEYS,
        "qualification profile $ordinal correctness projection",
    );
    die "qualification correctness projection schema changed\n"
        unless ($projection->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_correctness.v1'
            && _integer_equals($projection->{schema_version}, 1)
            && ref($projection->{report_contract}) eq 'HASH'
            && ref($projection->{record_projections}) eq 'ARRAY'
            && @{$projection->{record_projections}} == 4;
    for my $index (0 .. 3) {
        my $record = $projection->{record_projections}[$index];
        _exact_keys($record, \@CORRECTNESS_RECORD_KEYS,
            "qualification correctness record $ordinal/$index");
        die "qualification correctness record coordinate changed\n"
            unless ($record->{run_class} // '') eq
                    ($index ? 'gate_measurement' : 'validation')
                && _integer_equals($record->{run_ordinal}, $index)
                && ref($record->{stage_measurements}) eq 'ARRAY'
                && @{$record->{stage_measurements}} == @STAGES;
        for my $stage_index (0 .. $#STAGES) {
            my $stage = $record->{stage_measurements}[$stage_index];
            _exact_keys($stage, \@CORRECTNESS_STAGE_KEYS,
                "qualification correctness stage $ordinal/$index");
            die "qualification correctness stage order changed\n"
                unless ($stage->{stage} // '') eq $STAGES[$stage_index];
        }
        die "qualification correctness oracles changed\n"
            unless ref($record->{correctness_oracles}) eq 'ARRAY'
                && @{$record->{correctness_oracles}};
        for my $oracle (@{$record->{correctness_oracles}}) {
            _exact_keys($oracle, \@CORRECTNESS_ORACLE_KEYS,
                "qualification correctness oracle $ordinal/$index");
        }
        die "qualification correctness artifacts changed\n"
            unless ref($record->{artifact_records}) eq 'ARRAY';
        for my $artifact (@{$record->{artifact_records}}) {
            _exact_keys($artifact, \@ARTIFACT_KEYS,
                "qualification correctness artifact $ordinal/$index");
        }
        _exact_keys($record->{cleanup}, [qw(ephemeral_removed residue)],
            "qualification correctness cleanup $ordinal/$index");
    }
}

sub _load_source_corpus {
    my ($source_verification, $root_device, $root_owner) = @_;
    my $path = _root_path("$CORPUS_RELATIVE/complete/regression-promotion-corpus.json");
    my ($entry) = grep {
        $_->{relative_path} eq 'complete/regression-promotion-corpus.json'
    } @{$source_verification->{files}};
    die "authenticated source report inventory is missing\n"
        unless ref($entry) eq 'HASH';
    _safe_node($path, $root_device, $root_owner, 'single-link-file');
    my $bytes = _read_exact($path, $entry->{bytes});
    die "authenticated source report hash changed during verification\n"
        unless sha256_hex($bytes) eq $entry->{sha256};
    my $corpus = _decode_canonical($bytes, 'authenticated source corpus');
    _exact_keys($corpus, \@CORPUS_KEYS, 'authenticated source corpus');
    die "authenticated source corpus binding changed\n"
        unless ($corpus->{corpus_identity} // '') eq
                $source_verification->{corpus_identity}
            && ref($corpus->{profiles}) eq 'ARRAY'
            && @{$corpus->{profiles}} == 11;
    return $corpus;
}

sub _reconstruct_profile {
    my (
        $published, $source, $applicability, $source_evidence,
        $root_device, $root_owner,
    ) = @_;
    my $ordinal = $published->{ordinal};
    _exact_keys($source, \@CORPUS_PROFILE_KEYS,
        "source corpus profile $ordinal");
    _exact_keys($source->{artifact}, \@CORPUS_ARTIFACT_KEYS,
        "source corpus profile $ordinal artifact");
    die "qualification source profile coordinate changed\n"
        unless _integer_equals($source->{ordinal}, $ordinal)
            && ($source->{selection_key} // '') eq
                ($published->{selection_key} // '')
            && ($source->{report_identity} // '') eq
                ($published->{source_report_identity} // '');

    my $relative = $source->{artifact}{relative_path};
    die "qualification source artifact path changed\n"
        unless defined($relative) && !ref($relative)
            && index($relative, "$CORPUS_RELATIVE/profiles/") == 0
            && $relative !~ m{(?:\A|/)[.][.](?:/|\z)};
    my $path = _root_path($relative);
    _safe_node($path, $root_device, $root_owner, 'single-link-file');
    my $bytes = _read_exact($path, $source->{artifact}{bytes});
    die "qualification source profile hash changed during verification\n"
        unless sha256_hex($bytes) eq $source->{artifact}{sha256};
    my $publication = _decode_canonical(
        $bytes, "authenticated source profile $ordinal",
    );
    _exact_keys($publication, \@PROFILE_PUBLICATION_KEYS,
        "authenticated source profile $ordinal publication");
    my $measurement_set = $publication->{report};
    die "qualification source report binding changed\n"
        unless ref($measurement_set) eq 'HASH'
            && ($measurement_set->{report_identity} // '') eq
                $published->{source_report_identity}
            && ($measurement_set->{workload_identity} // '') eq
                $published->{workload_identity}
            && ($measurement_set->{outcome} // '') eq 'accepted'
            && ref($measurement_set->{sample_exclusions}) eq 'ARRAY'
            && !@{$measurement_set->{sample_exclusions}}
            && ref($measurement_set->{measurement_records}) eq 'ARRAY'
            && @{$measurement_set->{measurement_records}} == 3;

    my @records = (
        $measurement_set->{validation_record},
        @{$measurement_set->{measurement_records}},
    );
    my @totals;
    my @measurement_identities;
    for my $index (0 .. 3) {
        my $record = $records[$index];
        my $total = _validate_measurement_record(
            $record, $source->{common_identity}, $index,
        );
        next unless $index;
        push @measurement_identities, $record->{measurement_identity};
        push @totals, {
            measurement_identity => $record->{measurement_identity},
            run_ordinal => $index,
            %$total,
        };
    }
    my %aggregate;
    for my $metric (@AGGREGATE_KEYS) {
        $aggregate{$metric} = _statistics([
            map { $_->{$metric} } @totals
        ]);
    }
    my $aggregate = \%aggregate;
    my $budget = _budget($aggregate);
    my $correctness = _correctness_projection($measurement_set, \@records);
    my $correctness_identity = 'regression-promotion-correctness/'
        . sha256_hex(_canonical($correctness));
    my $environment = {
        environment_identity => undef,
        host_profile => _clone($source->{common_identity}{host_profile}),
        tool_profile => _clone($source->{common_identity}{tool_profile}),
        resource_guard => _clone($source->{common_identity}{resource_guard}),
        provider_status => _clone($source->{provider_status}),
    };
    $environment->{environment_identity} =
        'regression-promotion-environment/'
        . sha256_hex(_canonical($environment));
    my $applicability_projection = {
        contract_identity => $applicability->{applicability_identity},
        exact_environment => $environment,
        exact_deterministic => {
            selection_key => $source->{selection_key},
            workload_identity => $measurement_set->{workload_identity},
            correctness_projection_identity => $correctness_identity,
        },
    };
    my $profile_applicability =
        'regression-promotion-profile-applicability/'
        . sha256_hex(_canonical($applicability_projection));

    die "qualification reconstructed run totals changed\n"
        unless _same(\@totals, $published->{accepted_run_totals});
    die "qualification reconstructed aggregate statistics changed\n"
        unless _same($aggregate, $published->{aggregate_statistics});
    die "qualification reconstructed budget changed\n"
        unless _same($budget, $published->{qualified_budget});
    die "qualification reconstructed correctness projection changed\n"
        unless _same($correctness, $published->{correctness_projection})
            && $correctness_identity eq
                $published->{correctness_projection_identity};
    die "qualification reconstructed environment changed\n"
        unless _same($environment, $published->{environment_identity})
            && _same($source->{provider_status},
                $published->{provider_status});
    die "qualification reconstructed applicability changed\n"
        unless $profile_applicability eq
            $published->{performance_applicability_identity};
    die "qualification reconstructed measurement identities changed\n"
        unless ($records[0]{measurement_identity} // '') eq
                $published->{validation_identity}
            && _same(\@measurement_identities,
                $published->{raw_measurement_identities});
    die "qualification evidence revision binding changed\n"
        unless ($published->{evidence_revision} // '') eq
                ($source_evidence->{capture_revision} // '')
            && ($source->{common_identity}{git_revision} // '') eq
                $published->{evidence_revision};

    my $profile_projection = _clone($published);
    my $profile_identity = $profile_projection->{profile_qualification_identity};
    $profile_projection->{profile_qualification_identity} = undef;
    die "qualification reconstructed profile identity changed\n"
        unless ($profile_identity // '') eq
            'regression-promotion-profile-qualification/'
            . sha256_hex(_canonical($profile_projection));

    return {
        ordinal => 0 + $ordinal,
        selection_key => $published->{selection_key},
        profile_qualification_identity => $profile_identity,
        source_report_identity => $published->{source_report_identity},
        workload_identity => $published->{workload_identity},
        evidence_revision => $published->{evidence_revision},
        environment_identity =>
            $environment->{environment_identity},
        correctness_projection_identity => $correctness_identity,
        performance_applicability_identity => $profile_applicability,
        validation_identity => $published->{validation_identity},
        raw_measurement_identities => _clone(\@measurement_identities),
        accepted_run_totals => _clone(\@totals),
        aggregate_statistics => _clone($aggregate),
        qualified_budget => _clone($budget),
        provider_status => _clone($published->{provider_status}),
    };
}

sub _validate_measurement_record {
    my ($record, $common, $index) = @_;
    _exact_keys($record, \@MEASUREMENT_KEYS,
        "qualification source measurement record $index");
    die "qualification source measurement coordinate changed\n"
        unless ($record->{run_class} // '') eq
                ($index ? 'gate_measurement' : 'validation')
            && _integer_equals($record->{run_ordinal}, $index)
            && ($record->{measurement_identity} // '') =~
                m{\Ameasurement/[0-9a-f]{64}\z}
            && ($record->{outcome} // '') eq 'accepted'
            && !defined($record->{diagnostic})
            && _false($record->{dirty_state});
    my $identity_projection = _clone($record);
    my $measurement_identity = $identity_projection->{measurement_identity};
    $identity_projection->{measurement_identity} = undef;
    die "qualification source measurement identity changed\n"
        unless ($measurement_identity // '') eq
            'measurement/' . sha256_hex(_canonical($identity_projection));
    my $record_common = {
        git_revision => $record->{git_revision},
        dirty_state => _clone($record->{dirty_state}),
        host_profile => _clone($record->{host_profile}),
        tool_profile => _clone($record->{tool_profile}),
        resource_guard => _clone($record->{resource_guard}),
    };
    die "qualification source measurement environment changed\n"
        unless _same($record_common, $common);
    die "qualification source stage vector changed\n"
        unless ref($record->{stage_measurements}) eq 'ARRAY'
            && @{$record->{stage_measurements}} == @STAGES;
    my ($wall, $cpu, $rss, $measured) = (0, 0, undef, 0);
    for my $stage_index (0 .. $#STAGES) {
        my $stage = $record->{stage_measurements}[$stage_index];
        _exact_keys($stage, \@STAGE_KEYS,
            "qualification source measurement stage $index/$stage_index");
        die "qualification source stage order changed\n"
            unless ($stage->{stage} // '') eq $STAGES[$stage_index];
        _validate_stage_determinism($stage);
        next unless $index && ($stage->{status} // '') eq 'measured';
        $wall = _checked_add($wall,
            _nonnegative_integer($stage->{wall_time_ns}), 'run wall time');
        $cpu = _checked_add($cpu, _stage_cpu($stage), 'run CPU time');
        my $stage_rss = $stage->{rss}{peak_process_tree_bytes};
        die "qualification measured stage RSS changed\n"
            unless defined($stage_rss)
                ? _nonnegative_integer($stage_rss) >= 0
                : $stage->{stage} eq 'cleanup'
                    && ($stage->{rss}{unsupported_reason} // '') eq
                        'cleanup_is_controller_local';
        die "qualification measured stage process failed\n"
            unless _integer_equals($stage->{process}{exit_code}, 0)
                && _integer_equals($stage->{process}{signal}, 0)
                && _false($stage->{process}{timed_out});
        $rss = $stage_rss
            if defined($stage_rss) && (!defined($rss) || $stage_rss > $rss);
        $measured++;
    }
    _validate_record_correctness($record);
    _validate_record_artifacts($record);
    return undef unless $index;
    die "qualification measurement record has no measured stage\n"
        unless $measured && defined($rss);
    return {
        wall_time_ns => $wall,
        cpu_time_ns => $cpu,
        peak_tree_rss_bytes => $rss,
    };
}

sub _validate_stage_determinism {
    my ($stage) = @_;
    for my $name (qw(input_counts output_counts)) {
        _exact_keys($stage->{$name}, [qw(bytes files lines objects)],
            "qualification source stage $name");
        _nonnegative_integer($stage->{$name}{$_})
            for qw(bytes files lines objects);
    }
    die "qualification source semantic counts changed\n"
        unless ref($stage->{semantic_object_counts}) eq 'HASH';
    _nonnegative_integer($_)
        for values %{$stage->{semantic_object_counts}};
    die "qualification source stage oracles changed\n"
        unless ref($stage->{correctness_oracle_ids}) eq 'ARRAY';
}

sub _validate_record_correctness {
    my ($record) = @_;
    die "qualification source correctness oracles changed\n"
        unless ref($record->{correctness_oracles}) eq 'ARRAY'
            && @{$record->{correctness_oracles}};
    my (%oracle_seen, %record_oracles);
    for my $oracle (@{$record->{correctness_oracles}}) {
        _exact_keys($oracle, \@ORACLE_KEYS,
            'qualification source correctness oracle');
        die "qualification source correctness oracle failed\n"
            unless _true($oracle->{ok})
                && ($oracle->{oracle_id} // '') =~ /\A[A-Za-z0-9_.-]+\z/
                && !$oracle_seen{$oracle->{oracle_id}}++
                && ($oracle->{evidence_identity} // '') eq
                    sha256_hex(_canonical($oracle->{evidence}));
        $record_oracles{$oracle->{oracle_id}} = $oracle->{stage};
    }
    my %stage_oracles;
    for my $stage (@{$record->{stage_measurements}}) {
        for my $id (@{$stage->{correctness_oracle_ids}}) {
            die "qualification source stage oracle is duplicated\n"
                if exists($stage_oracles{$id});
            $stage_oracles{$id} = $stage->{stage};
        }
    }
    die "qualification source stage/oracle membership changed\n"
        unless _same(\%stage_oracles, \%record_oracles);
    die "qualification source cleanup changed\n"
        unless ref($record->{cleanup}) eq 'HASH'
            && _true($record->{cleanup}{ephemeral_removed})
            && ref($record->{cleanup}{residue}) eq 'ARRAY'
            && !@{$record->{cleanup}{residue}};
}

sub _validate_record_artifacts {
    my ($record) = @_;
    _exact_keys($record->{artifacts},
        [qw(published_identity records staging_identity)],
        'qualification source record artifacts');
    die "qualification source artifact records changed\n"
        unless ref($record->{artifacts}{records}) eq 'ARRAY';
    for my $artifact (@{$record->{artifacts}{records}}) {
        _exact_keys($artifact, \@ARTIFACT_KEYS,
            'qualification source artifact record');
        die "qualification source artifact identity changed\n"
            unless ($artifact->{relative_path} // '') =~ m{\Aoutputs/}
                && ($artifact->{sha256} // '') =~ /\A[0-9a-f]{64}\z/;
        _nonnegative_integer($artifact->{bytes});
        _nonnegative_integer($artifact->{lines});
    }
}

sub _correctness_projection {
    my ($measurement_set, $records) = @_;
    my $report_contract = _clone($measurement_set);
    delete @{$report_contract}{qw(
        report_identity validation_record measurement_records
        sample_exclusions cleanup
    )};
    return {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_correctness.v1',
        schema_version => 1,
        report_contract => $report_contract,
        record_projections => [map {
            _record_correctness_projection($_)
        } @$records],
    };
}

sub _record_correctness_projection {
    my ($record) = @_;
    return {
        schema => $record->{schema},
        schema_version => $record->{schema_version},
        workload_identity => $record->{workload_identity},
        workload_specification => _clone($record->{workload_specification}),
        run_class => $record->{run_class},
        run_ordinal => $record->{run_ordinal},
        stage_measurements => [map {
            my $stage = $_;
            +{map { $_ => _clone($stage->{$_}) }
                @CORRECTNESS_STAGE_KEYS}
        } @{$record->{stage_measurements}}],
        correctness_oracles => [map {
            my $oracle = $_;
            +{map { $_ => _clone($oracle->{$_}) }
                @CORRECTNESS_ORACLE_KEYS}
        } @{$record->{correctness_oracles}}],
        artifact_records => _clone($record->{artifacts}{records}),
        published_identity => _clone($record->{artifacts}{published_identity}),
        outcome => $record->{outcome},
        diagnostic => _clone($record->{diagnostic}),
        cleanup => {
            ephemeral_removed => _clone($record->{cleanup}{ephemeral_removed}),
            residue => _clone($record->{cleanup}{residue}),
        },
        explicit_nonclaims => _clone($record->{explicit_nonclaims}),
    };
}

sub _stage_cpu {
    my ($stage) = @_;
    my $total = 0;
    for my $kind (qw(controller_cpu descendant_cpu)) {
        die "qualification measured stage CPU counters changed\n"
            unless ref($stage->{$kind}) eq 'HASH';
        for my $field (qw(user_ns system_ns)) {
            my $value = $stage->{$kind}{$field};
            if (defined($value)) {
                $total = _checked_add(
                    $total, _nonnegative_integer($value), 'stage CPU time',
                );
                next;
            }
            die "qualification measured stage CPU counter is unsupported\n"
                unless $kind eq 'descendant_cpu'
                    && $stage->{stage} eq 'cleanup'
                    && ($stage->{$kind}{unsupported_reason} // '') eq
                        'no_descendant_cleanup_process';
        }
    }
    return $total;
}

sub _statistics {
    my ($values) = @_;
    die "qualification statistics require three samples\n"
        unless ref($values) eq 'ARRAY' && @$values == 3;
    my @sorted = sort { $a <=> $b } map {
        _nonnegative_integer($_)
    } @$values;
    my $median = $sorted[1];
    my @deviations = sort { $a <=> $b } map {
        $_ >= $median ? $_ - $median : $median - $_
    } @sorted;
    return {
        sample_count => 3,
        minimum => $sorted[0],
        median => $median,
        maximum => $sorted[2],
        median_absolute_deviation => $deviations[1],
    };
}

sub _budget {
    my ($aggregate) = @_;
    return {
        status => 'qualified_unpublished',
        formula_authority => 'decision-0056',
        map {
            $_ => _rounded_budget(
                $aggregate->{$_}{maximum}, $FORMULA->{$_},
            )
        } @AGGREGATE_KEYS
    };
}

sub _rounded_budget {
    my ($maximum, $formula) = @_;
    my $product = _checked_multiply(
        $maximum, $formula->{multiplier_numerator}, 'budget multiplier',
    );
    my $scaled = _ceil_divide(
        $product, $formula->{multiplier_denominator},
    );
    $scaled = $formula->{floor} if $scaled < $formula->{floor};
    my $quanta = _ceil_divide($scaled, $formula->{quantum});
    return _checked_multiply(
        $quanta, $formula->{quantum}, 'rounded budget',
    );
}

sub _profile_bindings {
    my ($profiles) = @_;
    my @bindings;
    for my $profile (@$profiles) {
        my $binding = {
            map { $_ => _clone($profile->{$_}) } @PROFILE_BINDING_KEYS
        };
        _exact_keys($binding, \@PROFILE_BINDING_KEYS,
            'qualification manifest profile binding');
        push @bindings, $binding;
    }
    return \@bindings;
}

sub _decode_canonical {
    my ($bytes, $label) = @_;
    my $value = eval { $JSON->decode($bytes) };
    die "$label JSON is invalid\n"
        if $@ || ref($value) ne 'HASH';
    die "$label is not canonical newline JSON\n"
        unless $bytes eq _canonical($value) . "\n";
    return $value;
}

sub _read_exact {
    my ($path, $expected) = @_;
    die "qualification file size is invalid\n"
        unless defined($expected) && !ref($expected)
            && _canonical($expected) =~ /\A[1-9][0-9]*\z/
            && $expected <= 8_388_608;
    open my $fh, '<:raw', $path
        or die "cannot read qualification file\n";
    my $bytes = '';
    while (bytes::length($bytes) <= $expected) {
        my $read = read(
            $fh, my $chunk, $expected + 1 - bytes::length($bytes),
        );
        die "cannot read qualification file\n" unless defined($read);
        last if $read == 0;
        $bytes .= $chunk;
    }
    close $fh or die "cannot close qualification file\n";
    die "qualification file byte count changed\n"
        unless bytes::length($bytes) == $expected;
    return $bytes;
}

sub _root_path {
    my ($relative) = @_;
    die "repository-relative qualification path is unsafe\n"
        if !defined($relative) || ref($relative)
            || $relative =~ m{(?:\A|/)[.][.](?:/|\z)};
    return File::Spec->catfile($ROOT, split m{/}, $relative);
}

sub _safe_node {
    my ($path, $device, $owner, $shape) = @_;
    my @stat = lstat($path);
    die "qualification publication path is missing\n" unless @stat;
    die "qualification publication path is a symlink\n" if -l _;
    die "qualification publication path changed device or owner\n"
        unless $stat[0] == $device && $stat[4] == $owner;
    die "qualification publication directory shape changed\n"
        if $shape eq 'directory' && !-d _;
    die "qualification publication file shape changed\n"
        if $shape eq 'single-link-file' && (!-f _ || $stat[3] != 1);
    return @stat;
}

sub _exact_keys {
    my ($value, $keys, $label) = @_;
    die "$label must be a JSON object\n" unless ref($value) eq 'HASH';
    die "$label keys changed\n"
        unless _same([sort keys %$value], [sort @$keys]);
}

sub _integer_equals {
    my ($value, $expected) = @_;
    return defined($value) && !ref($value)
        && _canonical($value) eq "$expected";
}

sub _nonnegative_integer {
    my ($value) = @_;
    die "qualification integer is invalid\n"
        unless defined($value) && !ref($value)
            && _canonical($value) =~ /\A(?:0|[1-9][0-9]*)\z/
            && $value <= $MAX_SAFE_INTEGER;
    return 0 + $value;
}

sub _checked_add {
    my ($left, $right, $label) = @_;
    die "qualification $label exceeds the safe integer range\n"
        if $left > $MAX_SAFE_INTEGER - $right;
    return $left + $right;
}

sub _checked_multiply {
    my ($left, $right, $label) = @_;
    die "qualification $label exceeds the safe integer range\n"
        if $left && $right > int($MAX_SAFE_INTEGER / $left);
    return $left * $right;
}

sub _ceil_divide {
    my ($numerator, $denominator) = @_;
    die "qualification divisor is invalid\n"
        unless $denominator > 0;
    return int($numerator / $denominator)
        + ($numerator % $denominator ? 1 : 0);
}

sub _true {
    my ($value) = @_;
    return defined($value) && ref($value) eq 'JSON::PP::Boolean'
        && _canonical($value) eq 'true';
}

sub _false {
    my ($value) = @_;
    return defined($value) && ref($value) eq 'JSON::PP::Boolean'
        && _canonical($value) eq 'false';
}

sub _same {
    my ($left, $right) = @_;
    return _canonical($left) eq _canonical($right);
}

sub _canonical {
    my ($value) = @_;
    return $JSON->encode($value);
}

sub _clone {
    my ($value) = @_;
    return $JSON->decode(_canonical($value));
}
