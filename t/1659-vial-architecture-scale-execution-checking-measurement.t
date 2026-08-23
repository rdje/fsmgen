#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleCheckingState;
use FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement;
use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ArchitectureScaleMeasurement;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement';
my $foundation = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my @report_keys = qw(
    schema schema_version report_identity family level primary_axis
    workload_identity mode requested_counts family_authority
    controller_applicability measurement_applicability canonical_evaluation
    validation_record measurement_records sample_exclusions outcome
    diagnostics cleanup explicit_nonclaims
);
my @nonclaims = (
    @{$foundation->explicit_nonclaims},
    qw(
        external_verification_tool backend_emission_measurement
        compile_run_trace_result family_performance_budget family_support
        family_capacity reached_boundary public_api_change
    ),
);

subtest 'authorities and report contracts are closed and defensive' => sub {
    is_deeply($class->report_keys, \@report_keys,
        'sample-set report has one exact closed schema');
    is_deeply($class->explicit_nonclaims, \@nonclaims,
        'adapter adds every later-owned or unsupported claim boundary');
    my $authorities = $class->family_authorities;
    is_deeply([sort keys %$authorities],
        [qw(checking_state_v1 execution_graph_v1)],
        'only the activated execution and checking families are admitted');
    for my $family (sort keys %$authorities) {
        is_deeply($authorities->{$family}{stage_order},
            [qw(construct parse_validate bridge bind_plan)],
            "$family has one complete canonical stage vocabulary");
        ok(!$authorities->{$family}{external_verification_tool},
            "$family is not reclassified as an external tool");
        like($authorities->{$family}{authority_identity},
            qr{\Afamily-authority/[0-9a-f]{64}\z},
            "$family authority is content-addressed");
    }
    is($authorities->{execution_graph_v1}{producer_class},
        'FSM::VIAL::ArchitectureScaleExecutionGraph',
        'execution authority names its canonical producer');
    is($authorities->{checking_state_v1}{producer_class},
        'FSM::VIAL::ArchitectureScaleCheckingState',
        'checking authority names its canonical producer');
    $authorities->{execution_graph_v1}{stage_order}[0] = 'forged';
    is($class->family_authorities->{execution_graph_v1}{stage_order}[0],
        'construct', 'authority callers receive defensive projections');
};

subtest 'construction is canonical, caller-sealed, and source-free when required' => sub {
    my $execution = $class->construct({
        repository_root => $repo_root,
        family => 'execution_graph_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'operations_total',
    });
    ok($execution->{ok}, 'execution gate constructs canonically');
    is_deeply([map { $_->{role} } @{$execution->{inputs}}],
        [qw(vial_source hial_source)],
        'execution construction has only canonical HIAL/VIAL inputs');

    my $checking = $class->construct({
        repository_root => $repo_root,
        family => 'checking_state_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'model_instances',
    });
    ok($checking->{ok}, 'checking gate constructs canonically');
    is($checking->{specification}{family}, 'checking_state_v1',
        'checking construction cannot escape its family');

    my $source_free = $class->construct({
        repository_root => $repo_root,
        family => 'execution_graph_v1',
        level => 'qualification_candidate_v1',
        primary_axis => 'bindings',
    });
    ok(!$source_free->{ok},
        'unreachable binding qualification remains unconstructible');
    is($source_free->{status}, 'error',
        'source-free authority retains its canonical construction status');
    ok(!defined($source_free->{workload_identity}),
        'source-free authority invents no workload identity');
    is_deeply($source_free->{inputs}, [],
        'source-free authority invents no workload input');

    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            family => 'semantic_catalog_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'imports',
        });
    }), qr/family is not selected/,
        'another adapter family fails before construction');
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root,
            family => 'execution_graph_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'operations_total',
            reference_hial_text => 'forged',
        });
    }), qr/unknown key 'reference_hial_text'/,
        'caller source injection cannot enter the adapter');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleExecutionGraph->_measurement_inputs({
            construction => $execution,
        });
    }), qr/private to the exact adapter/,
        'execution canonical-input seam rejects direct callers');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleCheckingState->_measurement_inputs({
            construction => $checking,
        });
    }), qr/private to the exact adapter/,
        'checking canonical-input seam rejects direct callers');
};

subtest 'bind-plan payload reruns do not nest canonical producer reruns' => sub {
    my $construction = $class->construct({
        repository_root => $repo_root,
        family => 'execution_graph_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'random_attempts',
    });
    my $expected = FSM::VIAL::ArchitectureScaleExecutionGraph->evaluate({
        construction => clone($construction),
    });
    ok($expected->{ok}, 'random-attempt gate has accepted admission evidence');

    my $stage_payload =
        \&FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement::_stage_payload;
    my $evaluate = \&FSM::VIAL::ArchitectureScaleExecutionGraph::evaluate;
    my ($first, $second, $evaluation_calls);
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleExecutionGraph::evaluate = sub {
            $evaluation_calls++;
            return $evaluate->(@_);
        };
        $first = $stage_payload->($construction, $expected, 'bind_plan');
        $second = $stage_payload->($construction, $expected, 'bind_plan');
    }
    is($evaluation_calls, 2,
        'two stage-owned payload reruns invoke the producer exactly once each');
    is($json->encode($second), $json->encode($first),
        'the independent bind-plan payload rerun remains byte-identical');
    is($json->encode($first->{evidence}), $json->encode($expected),
        'each payload remains sealed to the admitted canonical evaluation');
};

subtest 'validation and measurement require the bounded real-run contract' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->validate_profile({
            repository_root => $repo_root,
            family => 'checking_state_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'model_instances',
        });
    }), qr/active repository RAM guard/,
        'correctness materialization cannot begin outside the guard');
    like(dies(sub {
        $class->measure_profile({
            repository_root => $repo_root,
            family => 'checking_state_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'model_instances',
        });
    }), qr/active repository RAM guard/,
        'performance measurement cannot begin outside the guard');
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => {},
        });
    }), qr/active repository RAM guard/,
        'independent regeneration cannot materialize scale work outside the guard');
    like(dies(sub {
        $class->measure_profile({
            repository_root => $repo_root,
            family => 'execution_graph_v1',
            level => 'limit_v1',
            primary_axis => 'operations_total',
        });
    }), qr/only gate_candidate_v1 and qualification_candidate_v1/,
        'limit conformance is never mislabeled as performance evidence');

    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 89;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;
    like(dies(sub {
        $class->validate_profile({
            repository_root => $repo_root,
            family => 'checking_state_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'model_instances',
        });
    }), qr/guard thresholds are invalid/,
        'an over-wide host threshold fails closed');
    $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
    $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4097;
    like(dies(sub {
        $class->validate_profile({
            repository_root => $repo_root,
            family => 'checking_state_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'model_instances',
        });
    }), qr/guard thresholds are invalid/,
        'an over-wide process threshold fails closed');
};

subtest 'guarded canonical outcomes and measured sample sets are exact' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_EXECUTION_CHECKING_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_EXECUTION_CHECKING_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'exact adapter proof executes below the repository guard');

    my $checking_gate = $class->measure_profile({
        repository_root => $repo_root,
        family => 'checking_state_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'model_instances',
    });
    is($checking_gate->{outcome}, 'accepted',
        'checking gate sample set is complete');
    is(scalar(@{$checking_gate->{measurement_records}}), 3,
        'checking gate retains all three raw records');
    check_measured_records($checking_gate,
        [qw(construct parse_validate bridge bind_plan)]);

    my $checking_qualification = $class->measure_profile({
        repository_root => $repo_root,
        family => 'checking_state_v1',
        level => 'qualification_candidate_v1',
        primary_axis => 'faults',
    });
    is($checking_qualification->{outcome}, 'accepted',
        'checking qualification sample set is complete');
    is(scalar(@{$checking_qualification->{measurement_records}}), 5,
        'checking qualification retains all five raw records');
    check_measured_records($checking_qualification,
        [qw(construct parse_validate bridge bind_plan)]);

    my $parser_rejection = $class->measure_profile({
        repository_root => $repo_root,
        family => 'execution_graph_v1',
        level => 'qualification_candidate_v1',
        primary_axis => 'execution_types',
    });
    is($parser_rejection->{outcome}, 'validated_not_measured',
        'authoritative parser rejection is not timed');
    is($parser_rejection->{canonical_evaluation}{status},
        'expected_rejection', 'parser rejection remains the family outcome');
    is_deeply($parser_rejection->{measurement_records}, [],
        'parser rejection invents no performance samples');
    check_stage_statuses($parser_rejection->{validation_record}, {
        construct => 'validated_unmeasured',
        parse_validate => 'validated_unmeasured',
        bridge => 'not_run',
        bind_plan => 'not_run',
    });

    my $preflight = $class->validate_profile({
        repository_root => $repo_root,
        family => 'execution_graph_v1',
        level => 'limit_v1',
        primary_axis => 'operations_total',
    });
    is($preflight->{outcome}, 'accepted_validation',
        'dominant preflight outcome is valid correctness evidence');
    is($preflight->{canonical_evaluation}{status}, 'preflight_dominated',
        'preflight authority is preserved exactly');
    check_stage_statuses($preflight->{validation_record}, {
        construct => 'validated_unmeasured',
        parse_validate => 'not_run',
        bridge => 'not_run',
        bind_plan => 'validated_unmeasured',
    });

    my $source_free = $class->measure_profile({
        repository_root => $repo_root,
        family => 'execution_graph_v1',
        level => 'qualification_candidate_v1',
        primary_axis => 'bindings',
    });
    is($source_free->{outcome}, 'validated_not_measured',
        'source-free envelope remains validated but unmeasured');
    ok(!$source_free->{controller_applicability}{applicable},
        'source-free outcome cannot enter the common controller');
    is($source_free->{controller_applicability}{reason},
        'source_free_construction', 'controller boundary names the reason');
    ok(!defined($source_free->{workload_identity}),
        'source-free report invents no workload identity');
    ok(!defined($source_free->{validation_record}),
        'source-free report invents no controller record');
    is_deeply($source_free->{measurement_records}, [],
        'source-free report invents no timing records');

    for my $report (
        $checking_gate, $checking_qualification, $parser_rejection,
        $preflight, $source_free,
    ) {
        is($json->encode($class->validate_report({
            repository_root => $repo_root,
            report => $report,
        })), $json->encode($report),
            'complete report independently regenerates exactly');
    }

    my $authority_mutation = clone($checking_gate);
    $authority_mutation->{family_authority}{stage_order}[0] = 'forged';
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $authority_mutation,
        });
    }), qr/family authority changed/,
        'authority mutation fails before the report identity boundary');

    my $evidence_mutation = clone($checking_gate);
    my ($metric) = sort keys
        %{$evidence_mutation->{canonical_evaluation}{metrics}};
    $evidence_mutation->{canonical_evaluation}{metrics}{$metric}++;
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $evidence_mutation,
        });
    }), qr/canonical execution\/checking evaluation changed/,
        'canonical evaluation mutation fails independent regeneration');

    my $borrowed_identity = clone($source_free);
    $borrowed_identity->{workload_identity} =
        $checking_gate->{workload_identity};
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root,
            report => $borrowed_identity,
        });
    }), qr/workload identity changed/,
        'source-free evidence cannot borrow another workload identity');

    ok(!-e repo_path('.artifacts/tmp/vial-scale'),
        'all exact sample sets leave no staging residue');
};

subtest 'guarded worker failure remains rejected without invented evidence' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_SCALE_EXECUTION_CHECKING_EXACT=1 under the RAM guard'
        unless $ENV{FSMGEN_VIAL_SCALE_EXECUTION_CHECKING_EXACT};
    my $original =
        \&FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement::_stage_payload;
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement::_stage_payload = sub {
        my ($construction, $evaluation, $stage) = @_;
        die "forced parse/validate worker failure\n"
            if $stage eq 'parse_validate';
        return $original->($construction, $evaluation, $stage);
    };
    my $report = $class->validate_profile({
        repository_root => $repo_root,
        family => 'checking_state_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'model_instances',
    });
    is($report->{outcome}, 'rejected',
        'foundation stage failure remains a rejected family report');
    is($report->{diagnostics}[0]{code},
        'VIAL_SCALE_MEASUREMENT_WORKER_ERROR',
        'adapter preserves the foundation diagnostic family');
    is($report->{diagnostics}[0]{semantic_path},
        '/stage_measurements/parse_validate',
        'adapter preserves the exact failed-stage path');
    check_stage_statuses($report->{validation_record}, {
        construct => 'validated_unmeasured',
        parse_validate => 'validation_rejected',
        bridge => 'not_run',
        bind_plan => 'not_run',
    });
    my ($failed) = grep { $_->{stage} eq 'parse_validate' }
        @{$report->{validation_record}{stage_measurements}};
    is_deeply($failed->{output_counts},
        {files => 0, lines => 0, bytes => 0, objects => 0},
        'failed stage retains truthful zero output evidence');
    is_deeply($failed->{correctness_oracle_ids}, [],
        'failed stage invents no successful oracle');
    is($json->encode($class->validate_report({
        repository_root => $repo_root,
        report => $report,
    })), $json->encode($report),
        'independent validation preserves the failure');
    ok(!-e repo_path('.artifacts/tmp/vial-scale'),
        'failed execution also removes exact staging');
};

done_testing;

sub check_measured_records {
    my ($report, $planned) = @_;
    is_deeply($report->{sample_exclusions}, [],
        'accepted sample set discards no raw record');
    ok($report->{measurement_applicability}{applicable},
        'accepted canonical outcome admits raw timing samples');
    ok($report->{cleanup}{ephemeral_removed},
        'aggregate sample-set cleanup is exact');
    my %planned = map { $_ => 1 } @$planned;
    my %identity;
    for my $record (@{$report->{measurement_records}}) {
        ok($record->{resource_guard}{active},
            'raw record retains active guard evidence');
        is($record->{resource_guard}{host_max_percent}, 88,
            'raw record retains the effective host threshold');
        is($record->{resource_guard}{single_descendant_max_mib}, 4096,
            'raw record retains the effective descendant threshold');
        ok(!$identity{$record->{measurement_identity}}++,
            'each raw record has a distinct complete identity');
        for my $stage (@{$record->{stage_measurements}}) {
            next unless $planned{$stage->{stage}};
            is($stage->{status}, 'measured',
                "$stage->{stage} is measured independently");
            ok(defined($stage->{wall_time_ns}),
                "$stage->{stage} retains monotonic wall time");
            cmp_ok(scalar(@{$stage->{raw_samples}}), '>=', 1,
                "$stage->{stage} retains raw process-tree samples");
        }
        ok($record->{cleanup}{ephemeral_removed},
            'each raw record removes its exact staging root');
    }
}

sub check_stage_statuses {
    my ($record, $expected) = @_;
    my %all = map { $_->{stage} => $_->{status} }
        @{$record->{stage_measurements}};
    my %actual = map { $_ => $all{$_} } sort keys %$expected;
    is_deeply(\%actual, $expected,
        'stage statuses preserve the selected canonical route');
    for my $stage (@{$foundation->stage_order}) {
        next if exists $expected->{$stage};
        my $status = $stage eq 'cleanup'
            ? 'validated_unmeasured' : 'not_run';
        is($all{$stage}, $status,
            $stage eq 'cleanup'
                ? 'foundation cleanup remains explicitly successful'
                : "$stage remains explicitly outside the family measurement");
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
