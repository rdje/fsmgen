#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;
use FSM::VIAL::Backend::GHDLLifecycle;

my $class =
    'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement';
my $materializer =
    'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMaterialization';
my $planner =
    'FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $json = JSON::PP->new->canonical(1);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);

is_deeply(
    $class->owned_shapes,
    [map {{
        backend_profile => 'vhdl_osvvm_qualified', level => $_,
    }} @levels],
    'measurement adapter owns exactly the five OSVVM runtime roles',
);

is_deeply(
    $class->tool_profile,
    {
        applicability => 'qualified_runtime',
        logical_name => 'ghdl',
        reported_version => join("\n",
            'GHDL 6.0.0 (6.0.0.r0.ge589c698c) [Dunoon edition]',
            ' Compiled with GNAT Version: 14.2.0',
            ' static elaboration, LLVM JIT code generator',
            'Written by Tristan Gingold.',
            '',
            'Copyright (C) 2003 - 2026 Tristan Gingold.',
            'GHDL is free software, covered by the GNU General Public License.  There is NO',
            'warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.'),
        build => '6.0.0-llvm-jit',
        provider_identity =>
            'qualified_osvvm_2026_05_ghdl_6_0_0_llvm_jit',
        arguments => [qw(
            --std=08 -Wno-library -Wno-hide --work=fsmgen_vial
            -P<lifecycle-library-root>
        )],
        thread_count => 1,
        job_count => 1,
        external_verification_tool => JSON::PP::true,
    },
    'adapter binds the exact provider-qualified OSVVM/GHDL profile',
);

is_deeply(
    $class->construct({
        repository_root => $repo_root,
        level => 'gate_candidate_v1',
    }),
    $materializer->construct({
        repository_root => $repo_root,
        level => 'gate_candidate_v1',
    }),
    'public construction is exactly the canonical OSVVM materializer',
);

subtest 'preflight-dominated shapes remain provider and tool free' => sub {
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleMeasurement::measure = sub {
        die "common controller must not execute for preflight shape\n";
    };
    local *FSM::VIAL::Backend::GHDLLifecycle::begin_session = sub {
        die "shared lifecycle must not execute for preflight shape\n";
    };
    for my $level (qw(limit_v1 over_limit_v1)) {
        my $report = $class->validate_profile({
            repository_root => $repo_root, level => $level,
        });
        is_deeply([sort keys %$report], [sort @{$class->report_keys}],
            "$level report schema is closed");
        is($report->{outcome}, 'preflight_dominated',
            "$level retains its byte-dominance outcome");
        ok(!$report->{controller_applicability}{applicable}
                && !$report->{measurement_applicability}{applicable},
            "$level admits neither controller nor tool work");
        ok(!defined($report->{execution_plan})
                && !defined($report->{validation_record})
                && @{$report->{measurement_records}} == 0,
            "$level retains no fabricated execution evidence");
        is($report->{cleanup}{records_total}, 0,
            "$level creates no ephemeral controller root");
        is($json->encode($class->validate_report({
            repository_root => $repo_root, report => $report,
        })), $json->encode($report),
            "$level report reloads canonically");
    }
};

subtest 'private seams, guard, selection, and schema fail closed' => sub {
    like(dies(sub {
        $materializer->_measurement_route_inputs({
            repository_root => $repo_root, level => 'reference_v1',
        });
    }), qr/private to the exact adapter/,
        'blessed route reconstruction rejects direct callers');
    like(dies(sub {
        $materializer->_measurement_inputs({
            repository_root => $repo_root, level => 'reference_v1',
            artifact_root => '.artifacts/tmp/vial-scale/' . ('a' x 64)
                . '/validation/00/outputs/emit/source-graph',
        });
    }), qr/private to the exact adapter/,
        'provider emission rejects direct callers');
    like(dies(sub {
        $planner->_measurement_plan({
            level => 'reference_v1', staging_identity => 'invalid',
            canonical_plan => {}, generated_source_set => [],
        });
    }), qr/caller-sealed/,
        'relocated provider plan rejects direct callers');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleMeasurement->measure({
            repository_root => $repo_root,
            construction => $materializer->construct({
                repository_root => $repo_root, level => 'reference_v1',
            }),
            run_class => 'validation', run_ordinal => 0,
            validation_record => undef, stage_plan => [],
            tool_profile => $class->tool_profile,
        });
    }), qr/private to the selected runtime adapter/,
        'generic callers cannot borrow external-tool controller admission');
    my $unsealed = FSM::VIAL::Backend::GHDLLifecycle->finish_session({});
    ok(!$unsealed->{ok}
            && $unsealed->{diagnostics}[0]{code}
                eq 'VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'generic callers cannot borrow the provider-aware finalizer');

    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->validate_profile({
            repository_root => $repo_root, level => 'reference_v1',
        });
    }), qr/active repository RAM guard/,
        'applicable correctness validation requires the active guard');
    like(dies(sub {
        $class->measure_profile({
            repository_root => $repo_root, level => 'gate_candidate_v1',
        });
    }), qr/active repository RAM guard/,
        'repeated measurement requires the active guard');
    like(dies(sub {
        $class->measure_profile({
            repository_root => $repo_root, level => 'reference_v1',
        });
    }), qr/only the OSVVM gate and qualification candidates/,
        'reference remains correctness-only');
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root, level => 'unknown_v1',
        });
    }), qr/level is not selected/,
        'unknown OSVVM runtime levels fail before construction');
};

subtest 'provider-aware lifecycle mapping and boundaries are exact' => sub {
    my $report = $class->validate_profile({
        repository_root => $repo_root, level => 'limit_v1',
    });
    is($report->{lifecycle_contract}{schema_version}, 2,
        'measurement binds the provider-aware lifecycle-v2 schema');
    is($report->{lifecycle_contract}{storage_mode},
        'osvvm_architecture_scale_measurement',
        'measurement has its own exact lifecycle storage role');
    is_deeply($report->{lifecycle_contract}{state_order}, [qw(
        admitted prepared tool_verified analyzed elaborated ran
        trace_validated result_produced assembled cleaned
    )], 'forward-only lifecycle order is exact');
    is_deeply($report->{lifecycle_contract}{stage_mapping}, {
        emit => ['admitted'],
        compile_analyze => [qw(prepared tool_verified analyzed)],
        elaborate => ['elaborated'], run => ['ran'],
        trace_validate => ['trace_validated'],
        result_produce => ['result_produced'],
        publish => [qw(assembled cleaned)],
    }, 'common stages map exactly onto provider-aware lifecycle work');
    is($report->{lifecycle_contract}
            {provider_analysis_timeout_seconds_per_source}, 120,
        'every provider analysis retains its exact deadline');
    is($report->{lifecycle_contract}{fixture_capture_bytes}, 67_108_864,
        'fixture output retains the exact bounded capture');
    ok((grep { $_ eq 'promoted_performance_budget' }
            @{$report->{explicit_nonclaims}}),
        'measurement does not promote a performance budget');
    ok((grep { $_ eq 'backend_support' }
            @{$report->{explicit_nonclaims}}),
        'measurement does not promote backend support');
};

subtest 'lifecycle rejection evidence remains bounded and durable' => sub {
    my $failure =
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_lifecycle_failure(
            'run', {
                ok => JSON::PP::false,
                lifecycle_identity => 'lifecycle/' . ('a' x 64),
                stage_evidence => [{
                    state => 'ran', ordinal => 5,
                    evidence => {provider_captures => [{
                        timed_out => JSON::PP::true,
                        timeout_seconds => 30,
                    }]},
                }],
                diagnostics => [{
                    code => 'VIAL_GHDL_LIFECYCLE_TIMEOUT',
                    message => 'provider probe exceeded its deadline',
                }],
                cleanup => {removed => JSON::PP::true, residue => []},
            },
        );
    ok(!$failure->{ok}, 'lifecycle rejection is one failed worker result');
    is($failure->{diagnostic}{code}, 'VIAL_GHDL_LIFECYCLE_TIMEOUT',
        'lifecycle rejection preserves the stable diagnostic');
    is(scalar(@{$failure->{diagnostic}{notes}}), 3,
        'failure retains identity, stage evidence, and cleanup notes');
    like($failure->{diagnostic}{notes}[1], qr/"timeout_seconds":30/,
        'failure durably retains exact capture evidence');
    like($failure->{diagnostic}{notes}[2], qr/"removed":true/,
        'failure durably retains exact cleanup evidence');
};

subtest 'guarded reference, gate, and qualification records are exact' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_OSVVM_RUNTIME_MEASUREMENT_EXACT=1 under scripts/run_with_ram_guard.sh'
        unless $ENV{FSMGEN_VIAL_OSVVM_RUNTIME_MEASUREMENT_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'exact OSVVM measurement runs below active guard enforcement');

    my $reference = $class->validate_profile({
        repository_root => $repo_root, level => 'reference_v1',
    });
    if (is($reference->{outcome}, 'accepted_validation',
            'checked reference passes one correctness-only lifecycle')) {
        verify_records($reference, 0, 77);
    }
    else {
        diag($json->pretty->encode($reference->{diagnostics}));
    }

    my $gate = $class->measure_profile({
        repository_root => $repo_root, level => 'gate_candidate_v1',
    });
    if (is($gate->{outcome}, 'accepted',
            '10,000-record gate repetitions are accepted')) {
        verify_records($gate, 3, 10_000);
    }
    else {
        diag($json->pretty->encode($gate->{diagnostics}));
    }

    my $qualification = $class->measure_profile({
        repository_root => $repo_root,
        level => 'qualification_candidate_v1',
    });
    if (is($qualification->{outcome}, 'accepted',
            '100,000-record qualification repetitions are accepted')) {
        verify_records($qualification, 5, 100_000);
    }
    else {
        diag($json->pretty->encode($qualification->{diagnostics}));
    }
};

done_testing;

sub verify_records {
    my ($report, $samples, $records) = @_;
    is(scalar(@{$report->{measurement_records}}), $samples,
        "$report->{level} retains every selected measured repetition");
    is_deeply($report->{sample_exclusions}, [],
        "$report->{level} excludes no accepted sample");
    my @all = ($report->{validation_record},
        @{$report->{measurement_records}});
    for my $record (@all) {
        is($record->{outcome}, 'accepted',
            "$report->{level} controller record is accepted");
        ok($record->{cleanup}{ephemeral_removed}
                && @{$record->{cleanup}{residue}} == 0,
            "$report->{level} controller and lifecycle roots are absent");
        my %stage = map { $_->{stage} => $_ }
            @{$record->{stage_measurements}};
        is($stage{compile_analyze}{classification}, 'external_tool',
            "$report->{level} provider/generated analysis is external");
        is($stage{elaborate}{classification}, 'external_tool',
            "$report->{level} dual elaboration is external");
        is($stage{run}{classification}, 'external_tool',
            "$report->{level} fixture/provider execution is external");
        ok(!defined($stage{compile_analyze}{timeout}{backend_seconds})
                && !defined($stage{elaborate}{timeout}{backend_seconds})
                && !defined($stage{run}{timeout}{backend_seconds}),
            "$report->{level} tool deadlines remain lifecycle-owned");
        if ($record->{run_class} eq 'validation') {
            is(scalar(grep { @{$_->{raw_samples}} }
                    @{$record->{stage_measurements}}), 0,
                "$report->{level} validation retains no timing sample");
        }
        else {
            for my $name (qw(
                construct parse_validate bridge bind_plan emit
                compile_analyze elaborate run trace_validate
                result_produce publish
            )) {
                cmp_ok(scalar(@{$stage{$name}{raw_samples}}), '>=', 1,
                    "$report->{level} $name retains raw samples");
            }
        }
        my ($publish) = grep {
            $_->{oracle_id} eq
                'osvvm_runtime_publish_lifecycle_canonical'
        } @{$record->{correctness_oracles}};
        ok(defined($publish) && $publish->{ok},
            "$report->{level} retains the terminal lifecycle oracle");
        my $evidence = $publish->{evidence};
        is(scalar(@{$evidence->{source_set}}), 68,
            "$report->{level} retains 68 provider/generated sources");
        is(scalar(keys %{$evidence->{command_identities}}), 7,
            "$report->{level} retains seven command families");
        is(scalar(@{$evidence->{provider_report_identities}}), 4,
            "$report->{level} retains four supplementary reports");
        my %state = map { $_->{state} => $_->{evidence} }
            @{$evidence->{stage_evidence}};
        is(scalar(@{$state{analyzed}{captures}}), 61,
            "$report->{level} retains every provider-analysis capture");
        is(scalar(@{$state{elaborated}{captures}}), 2,
            "$report->{level} retains fixture/probe elaboration captures");
        is(scalar(@{$state{ran}{fixture_captures}}), 1,
            "$report->{level} executes the fixture once per record");
        is(scalar(@{$state{ran}{provider_captures}}), 1,
            "$report->{level} executes the provider probe once per record");
        ok(!$state{ran}{deterministic},
            "$report->{level} does not claim intra-record rerun parity");
        is($evidence->{trace_record_count}, $records,
            "$report->{level} validated trace count is exact");
        is_deeply($evidence->{state_order}, [qw(
            admitted prepared tool_verified analyzed elaborated ran
            trace_validated result_produced assembled
        )], "$report->{level} lifecycle predecessor chain is complete");
        is($evidence->{provider_before_execution}{root_commit},
            $evidence->{provider_after_execution}{root_commit},
            "$report->{level} provider commit is stable across execution");
    }
    is($json->encode($class->validate_report({
        repository_root => $repo_root, report => $report,
    })), $json->encode($report),
        "$report->{level} complete report reloads canonically");

    my $mutated = clone($report);
    $mutated->{validation_record}{correctness_oracles}[0]{ok} =
        JSON::PP::false;
    like(dies(sub {
        $class->validate_report({
            repository_root => $repo_root, report => $mutated,
        });
    }), qr/(?:identity|oracle|record)/,
        "$report->{level} hostile oracle mutation fails closed");
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : $@;
}
