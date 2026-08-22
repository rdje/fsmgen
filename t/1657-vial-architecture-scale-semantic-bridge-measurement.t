#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement;

my $class = 'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement';
my $foundation = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my @report_keys = qw(
    schema schema_version report_identity family level primary_axis
    workload_identity mode expected_outcome family_authority
    measurement_applicability validation_record measurement_records
    sample_exclusions outcome diagnostics cleanup explicit_nonclaims
);
my @nonclaims = (
    @{$foundation->explicit_nonclaims},
    qw(
        external_verification_tool execution_graph_measurement
        checking_state_measurement backend_emission_measurement
        compile_run_trace_result family_performance_budget family_support
        family_capacity reached_boundary
    ),
);

subtest 'family authorities are closed, separate, and defensive' => sub {
    is_deeply($class->report_keys, \@report_keys,
        'sample-set report has one exact closed schema');
    is_deeply($class->explicit_nonclaims, \@nonclaims,
        'family measurement adds every later-owned nonclaim');
    my $authorities = $class->family_authorities;
    is_deeply([sort keys %$authorities],
        [qw(bridge_fanout_v1 semantic_catalog_v1)],
        'only the two activated provider-free families are admitted');
    is_deeply($authorities->{semantic_catalog_v1}{stage_order},
        [qw(construct parse_validate)],
        'semantic family owns construct and parse/validate only');
    is_deeply($authorities->{bridge_fanout_v1}{stage_order},
        [qw(construct parse_validate bridge)],
        'bridge family adds one independently measured bridge stage');
    is($authorities->{semantic_catalog_v1}{producer_class},
        'FSM::VIAL::ArchitectureScaleSemanticCatalog',
        'semantic authority names its canonical producer');
    is($authorities->{bridge_fanout_v1}{producer_class},
        'FSM::VIAL::ArchitectureScaleBridgeFanout',
        'bridge authority names its canonical producer');
    ok(!$authorities->{semantic_catalog_v1}{external_verification_tool}
            && !$authorities->{bridge_fanout_v1}{external_verification_tool},
        'neither family can be reclassified as an external tool');
    like($authorities->{semantic_catalog_v1}{authority_identity},
        qr{\Afamily-authority/[0-9a-f]{64}\z},
        'family authority is content-addressed');
    $authorities->{semantic_catalog_v1}{stage_order}[0] = 'forged';
    is($class->family_authorities
        ->{semantic_catalog_v1}{stage_order}[0], 'construct',
        'authority callers receive defensive projections');
};

subtest 'caller seal constructs only canonical family inputs' => sub {
    my $semantic = $class->construct({
        repository_root => $repo_root,
        family => 'semantic_catalog_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'record_fields',
    });
    ok($semantic->{ok}, 'semantic gate constructs canonically');
    is($semantic->{specification}{family}, 'semantic_catalog_v1',
        'semantic construction cannot escape its family');
    is(scalar(@{$semantic->{inputs}}), 1,
        'record-field gate has one canonical source');

    my $bridge = $class->construct({
        repository_root => $repo_root,
        family => 'bridge_fanout_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'events',
    });
    ok($bridge->{ok}, 'bridge gate constructs canonically');
    is_deeply([map { $_->{role} } @{$bridge->{inputs}}],
        [qw(hial_source vial_source)],
        'bridge construction contains only canonical HIAL/VIAL inputs');

    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            family => 'execution_graph_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'bindings',
        });
    }), qr/family is not selected/,
        'a later-owned family fails before construction');
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            family => 'semantic_catalog_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'record_fields',
            construction => $semantic,
        });
    }), qr/unknown key 'construction'/,
        'caller-created construction cannot enter the sealed adapter');
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            family => 'semantic_catalog_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'unknown_axis',
        });
    }), qr/primary axis is not selected/,
        'unknown axes fail against the immutable workload catalog');
};

subtest 'reference validation retains complete family evidence without metrics' => sub {
    my $report = $class->validate_profile({
        repository_root => $repo_root,
        family => 'semantic_catalog_v1',
        level => 'reference_v1',
        primary_axis => 'imports',
    });
    is_deeply([sort keys %$report], [sort @report_keys],
        'reference validation report is closed');
    is($report->{schema},
        'fsmgen.vial_architecture_scale_semantic_bridge_measurement_set.v1',
        'family report uses the selected sample-set schema');
    is($report->{mode}, 'validation',
        'reference execution is explicitly correctness-only');
    is($report->{outcome}, 'accepted_validation',
        'canonical reference validation succeeds');
    ok(!$report->{measurement_applicability}{applicable},
        'validation-only report cannot masquerade as performance evidence');
    is($report->{measurement_applicability}{reason},
        'correctness_only_requested',
        'non-measurement reason is stable');
    is_deeply($report->{measurement_records}, [],
        'validation retains no measured samples');
    is_deeply($report->{sample_exclusions}, [],
        'no sample is invented or discarded');
    is($report->{validation_record}{run_class}, 'validation',
        'embedded foundation record retains its run class');
    is($report->{validation_record}{outcome}, 'accepted',
        'embedded foundation record passes correctness');
    ok(!defined($report->{validation_record}
        {stage_measurements}[0]{wall_time_ns}),
        'validation stage retains no wall timing');
    is($report->{validation_record}
        {stage_measurements}[0]{status}, 'validated_unmeasured',
        'construct stage is correctness-only');
    is($report->{validation_record}
        {stage_measurements}[1]{status}, 'validated_unmeasured',
        'parse/validate stage is correctness-only');
    is($report->{validation_record}
        {stage_measurements}[2]{status}, 'not_run',
        'semantic family does not borrow the bridge stage');
    my ($semantic_oracle) = grep {
        $_->{oracle_id} eq
            'semantic_catalog_v1_parse_validate_canonical'
    } @{$report->{validation_record}{correctness_oracles}};
    ok($semantic_oracle->{ok},
        'complete canonical semantic evaluation is embedded as an oracle');
    is($semantic_oracle->{evidence}{status}, 'accepted',
        'semantic reference reaches its authoritative accepted outcome');
    unlike($json->encode($semantic_oracle->{evidence}),
        qr/"path":"\//,
        'measurement evidence contains no ambiguous slash-leading path key');
    like($semantic_oracle->{evidence}{semantic_projection_sha256},
        qr/\A[0-9a-f]{64}\z/,
        'semantic projection identity is retained');
    is(scalar(@{$report->{validation_record}{artifacts}{records}}), 3,
        'construction, source, and semantic evaluation artifacts are censused');
    ok($report->{cleanup}{ephemeral_removed}
            && !-e repo_path('.artifacts/tmp/vial-scale'),
        'reference validation removes exact family staging');
    is($json->encode($class->validate_report({
        repository_root => $repo_root,
        report => $report,
    })), $json->encode($report),
        'report validation independently regenerates family evidence');

    my $mutated = clone($report);
    $mutated->{family_authority}{stage_order}[0] = 'forged';
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $mutated,
        });
    }), qr/family authority changed/,
        'mutated family authority fails before report identity');
    my $mutated_evidence = clone($report);
    my ($evidence) = grep {
        $_->{oracle_id} eq
            'semantic_catalog_v1_parse_validate_canonical'
    } @{$mutated_evidence->{validation_record}{correctness_oracles}};
    $evidence->{evidence}{metrics}{semantic_ids}++;
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $mutated_evidence,
        });
    }), qr/(?:evidence identity changed|measurement identity changed)/,
        'mutated embedded oracle fails the foundation identity gate');

    my $malformed_records = clone($report);
    $malformed_records->{measurement_records} = {};
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $malformed_records,
        });
    }), qr/measurement records must be one array/,
        'malformed sample storage fails at the adapter schema boundary');
};

subtest 'measurement and non-reference validation require the real guard boundary' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->measure_profile({
            repository_root => $repo_root,
            family => 'semantic_catalog_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'record_fields',
        });
    }), qr/active repository RAM guard/,
        'measured family report cannot begin outside the guard');
    like(dies(sub {
        $class->validate_profile({
            repository_root => $repo_root,
            family => 'bridge_fanout_v1',
            level => 'over_limit_v1',
            primary_axis => 'selected_units',
        });
    }), qr/active repository RAM guard/,
        'boundary validation also cannot materialize unguarded scale work');
    like(dies(sub {
        $class->measure_profile({
            repository_root => $repo_root,
            family => 'semantic_catalog_v1',
            level => 'limit_v1',
            primary_axis => 'record_fields',
        });
    }), qr/only gate_candidate_v1 and qualification_candidate_v1/,
        'limit conformance is never mislabeled as a performance sample');
};

subtest 'adapter preserves a foundation-owned stage failure without successful rederivation' => sub {
    my $original = \&FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement::_stage_payload;
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement::_stage_payload = sub {
        my ($construction, $stage) = @_;
        die "forced parse/validate worker failure\n"
            if $stage eq 'parse_validate';
        return $original->($construction, $stage);
    };
    my $report = $class->validate_profile({
        repository_root => $repo_root,
        family => 'semantic_catalog_v1',
        level => 'reference_v1',
        primary_axis => 'imports',
    });
    is($report->{outcome}, 'rejected',
        'foundation stage failure remains a rejected family report');
    is($report->{diagnostics}[0]{code},
        'VIAL_SCALE_MEASUREMENT_WORKER_ERROR',
        'adapter preserves the original foundation diagnostic family');
    is($report->{diagnostics}[0]{semantic_path},
        '/stage_measurements/parse_validate',
        'adapter preserves the exact failed-stage diagnostic path');
    my $failed = $report->{validation_record}{stage_measurements}[1];
    is($failed->{status}, 'validation_rejected',
        'failed family stage remains explicitly rejected');
    is_deeply($failed->{output_counts},
        {files => 0, lines => 0, bytes => 0, objects => 0},
        'failed stage retains truthful zero output evidence');
    is_deeply($failed->{correctness_oracle_ids}, [],
        'failed stage invents no successful family oracle');
    ok($report->{cleanup}{ephemeral_removed}
            && !-e repo_path('.artifacts/tmp/vial-scale'),
        'failed family report still removes exact staging');
    is($json->encode($class->validate_report({
        repository_root => $repo_root,
        report => $report,
    })), $json->encode($report),
        'independent validation preserves rather than masks the failure');
};

subtest 'guarded gate, qualification, and dominant rejection are exact' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_SEMANTIC_BRIDGE_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_SEMANTIC_BRIDGE_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'exact family measurement executes below the repository guard');

    my $semantic = $class->measure_profile({
        repository_root => $repo_root,
        family => 'semantic_catalog_v1',
        level => 'qualification_candidate_v1',
        primary_axis => 'parallel_depth',
    });
    is($semantic->{outcome}, 'accepted',
        'semantic qualification sample set is complete');
    ok($semantic->{measurement_applicability}{applicable},
        'accepted semantic oracle admits performance samples');
    is(scalar(@{$semantic->{measurement_records}}), 5,
        'qualification retains all five raw measured records');
    is_deeply(
        [map { $_->{run_ordinal} } @{$semantic->{measurement_records}}],
        [1 .. 5],
        'qualification ordinals are contiguous and complete',
    );
    check_measured_records($semantic, [qw(construct parse_validate)]);

    my $bridge = $class->measure_profile({
        repository_root => $repo_root,
        family => 'bridge_fanout_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'selected_units',
    });
    is($bridge->{outcome}, 'accepted',
        'bridge gate sample set is complete');
    is(scalar(@{$bridge->{measurement_records}}), 3,
        'gate retains all three raw measured records');
    is_deeply(
        [map { $_->{run_ordinal} } @{$bridge->{measurement_records}}],
        [1 .. 3],
        'gate ordinals are contiguous and complete',
    );
    check_measured_records($bridge, [qw(construct parse_validate bridge)]);

    my $boundary = $class->validate_profile({
        repository_root => $repo_root,
        family => 'bridge_fanout_v1',
        level => 'over_limit_v1',
        primary_axis => 'selected_units',
    });
    is($boundary->{outcome}, 'accepted_validation',
        'authoritative over-limit rejection is valid correctness evidence');
    my ($bridge_oracle) = grep {
        $_->{oracle_id} eq 'bridge_fanout_v1_bridge_canonical'
    } @{$boundary->{validation_record}{correctness_oracles}};
    is($bridge_oracle->{evidence}{status}, 'expected_rejection',
        'boundary report preserves earliest authoritative rejection');
    is($bridge_oracle->{evidence}{diagnostics}[0]{code},
        'HIAL_VIAL_BRIDGE_CAPABILITY_ERROR',
        'two-unit excess retains the stable capability diagnostic');
    is($bridge_oracle->{evidence}{diagnostics}[0]{semantic_path},
        '/actor/actor_network',
        'canonical diagnostic path is projected into an explicit semantic path');
    ok(!exists($bridge_oracle->{evidence}{diagnostics}[0]{path}),
        'ambiguous canonical path key cannot cross the measurement boundary');
    is_deeply($boundary->{measurement_records}, [],
        'over-limit correctness proof retains no timing samples');

    for my $report ($semantic, $bridge, $boundary) {
        is($json->encode($class->validate_report({
            repository_root => $repo_root,
            report => $report,
        })), $json->encode($report),
            'complete report independently revalidates');
    }
    ok(!-e repo_path('.artifacts/tmp/vial-scale'),
        'all guarded sample sets leave no family staging residue');
};

done_testing;

sub check_measured_records {
    my ($report, $planned) = @_;
    is_deeply($report->{sample_exclusions}, [],
        'accepted sample set discards no raw record');
    ok($report->{cleanup}{ephemeral_removed},
        'aggregate sample-set cleanup is exact');
    my %planned = map { $_ => 1 } @$planned;
    my %identity;
    for my $record (@{$report->{measurement_records}}) {
        ok($record->{resource_guard}{active},
            'raw measured record retains active guard evidence');
        is($record->{resource_guard}{host_max_percent}, 88,
            'raw record retains the effective host threshold');
        is($record->{resource_guard}{single_descendant_max_mib}, 4096,
            'raw record retains the effective descendant threshold');
        ok(!$identity{$record->{measurement_identity}}++,
            'each raw record has a distinct complete identity');
        for my $stage (@{$record->{stage_measurements}}) {
            if ($planned{$stage->{stage}}) {
                is($stage->{status}, 'measured',
                    "$stage->{stage} is measured independently");
                ok(defined($stage->{wall_time_ns}),
                    "$stage->{stage} retains monotonic wall time");
                cmp_ok(scalar(@{$stage->{raw_samples}}), '>=', 1,
                    "$stage->{stage} retains raw process-tree samples");
            }
        }
        ok($record->{cleanup}{ephemeral_removed},
            'each raw record removes its exact staging root');
    }
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
