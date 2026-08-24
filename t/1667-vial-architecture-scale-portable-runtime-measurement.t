#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScalePortableRuntimeMaterialization;
use FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement;

my $class =
    'FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement';
my $materializer =
    'FSM::VIAL::ArchitectureScalePortableRuntimeMaterialization';
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
        backend_profile => 'sv_portable_verilator', level => $_,
    }} @levels],
    'measurement adapter owns exactly the five portable runtime roles',
);

is_deeply(
    $class->tool_profile,
    {
        applicability => 'qualified_runtime',
        logical_name => 'verilator',
        reported_version =>
            'Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228',
        build => '5.046',
        provider_identity => 'qualified_verilator_5_046',
        arguments => [qw(
            --binary --timing --assert --threads 1 -j 1
            --x-initial 0 --x-assign 0
        )],
        thread_count => 1,
        job_count => 1,
        external_verification_tool => JSON::PP::true,
    },
    'adapter binds the exact repository-qualified Verilator profile',
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
    'public construction is exactly the canonical materializer authority',
);

subtest 'preflight-dominated shapes remain tool-free and closed' => sub {
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleMeasurement::measure = sub {
        die "common controller must not execute for preflight shape\n";
    };
    local *FSM::VIAL::Backend::VerilatorLifecycle::begin_session = sub {
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
        ok(!defined($report->{validation_record})
                && @{$report->{measurement_records}} == 0,
            "$level retains no fabricated runtime record");
        is($report->{cleanup}{records_total}, 0,
            "$level creates no ephemeral controller root");
        is($json->encode($class->validate_report({
            repository_root => $repo_root, report => $report,
        })), $json->encode($report),
            "$level report reloads canonically");

        my $mutated = clone($report);
        $mutated->{controller_applicability}{applicable} = JSON::PP::true;
        like(dies(sub {
            $class->validate_report({
                repository_root => $repo_root, report => $mutated,
            });
        }), qr/controller applicability changed/,
            "$level cannot forge external-tool applicability");
    }
};

subtest 'private authority, guard, selection, and schema fail closed' => sub {
    like(dies(sub {
        $materializer->_measurement_inputs({
            repository_root => $repo_root,
            level => 'reference_v1',
            artifact_root => '.artifacts/tmp/vial-scale/' . ('a' x 64)
                . '/validation/00/lifecycle',
        });
    }), qr/private to the exact adapter/,
        'canonical blessed route and emission reject direct callers');

    like(dies(sub {
        FSM::VIAL::ArchitectureScaleMeasurement->measure({
            repository_root => $repo_root,
            construction => $materializer->construct({
                repository_root => $repo_root,
                level => 'reference_v1',
            }),
            run_class => 'validation',
            run_ordinal => 0,
            validation_record => undef,
            stage_plan => [],
            tool_profile => $class->tool_profile,
        });
    }), qr/private to the selected runtime adapter/,
        'generic callers cannot borrow external-tool controller admission');

    my $unsealed = FSM::VIAL::Backend::VerilatorLifecycle
        ->finish_measurement_session({});
    ok(!$unsealed->{ok}
            && $unsealed->{diagnostics}[0]{code}
                eq 'VIAL_LIFECYCLE_INVOCATION_ERROR',
        'generic callers cannot borrow the compact measurement finalizer');

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
    }), qr/only the portable gate and qualification candidates/,
        'reference remains correctness-only');
    like(dies(sub {
        $class->construct({
            repository_root => $repo_root, level => 'unknown_v1',
        });
    }), qr/level is not selected/,
        'unknown portable runtime levels fail before construction');
    like(dies(sub {
        $class->validate_profile({
            repository_root => $repo_root,
            level => 'limit_v1',
            extra => 1,
        });
    }), qr/unknown key 'extra'/,
        'adapter entrypoints reject open request objects');
};

subtest 'shared lifecycle mapping retains exact private boundaries' => sub {
    my $report = $class->validate_profile({
        repository_root => $repo_root, level => 'limit_v1',
    });
    is_deeply(
        $report->{lifecycle_contract}{state_order},
        [qw(
            admitted prepared tool_verified compiled ran trace_validated
            result_produced assembled cleaned
        )],
        'report binds the sole forward-only lifecycle state order',
    );
    is_deeply(
        $report->{lifecycle_contract}{stage_mapping},
        {
            emit => ['admitted'],
            compile_analyze => [qw(prepared tool_verified compiled)],
            elaborate => ['not_run_integrated_into_binary'],
            run => ['ran'],
            trace_validate => ['trace_validated'],
            result_produce => ['result_produced'],
            publish => [qw(assembled cleaned)],
        },
        'common stages map exactly onto shared lifecycle work',
    );
    is($report->{lifecycle_contract}{compile_timeout_seconds}, 120,
        'compile retains the qualified 120-second lifecycle ceiling');
    is($report->{lifecycle_contract}{run_timeout_seconds}, 30,
        'run retains the qualified 30-second lifecycle ceiling');
    is($report->{lifecycle_contract}{run_capture_bytes}, 67_108_864,
        'runtime retains the qualified bounded capture');
    ok(grep { $_ eq 'promoted_performance_budget' }
            @{$report->{explicit_nonclaims}},
        'measurement does not promote a performance budget');
    ok(grep { $_ eq 'reached_record_boundary' }
            @{$report->{explicit_nonclaims}},
        'preflight dominance does not claim a reached record boundary');
    ok(grep { $_ eq 'public_api_change' }
            @{$report->{explicit_nonclaims}},
        'private adapter creates no public API claim');
};

subtest 'lifecycle rejection evidence remains bounded and durable' => sub {
    my $failure =
        FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::_lifecycle_failure(
            'run', {
                ok => JSON::PP::false,
                lifecycle_identity => 'lifecycle/' . ('a' x 64),
                operation_id => 'op-' . ('b' x 64),
                stage_evidence => [{
                    state => 'ran', ordinal => 4,
                    evidence => {capture => {
                        timed_out => JSON::PP::true,
                        timeout_seconds => 30,
                    }},
                }],
                diagnostics => [{
                    code => 'VIAL_RUN_RUNTIME_ERROR',
                    severity => 'error',
                    message => 'generated runtime exceeded its deadline',
                    path => '/run',
                }],
                cleanup => {
                    staging_identity =>
                        '.artifacts/tmp/vial-scale/' . ('c' x 64)
                            . '/validation/00/lifecycle',
                    removed => JSON::PP::true,
                    residue => [],
                },
            },
        );
    ok(!$failure->{ok}, 'lifecycle rejection remains a failed worker result');
    is($failure->{diagnostic}{code}, 'VIAL_RUN_RUNTIME_ERROR',
        'lifecycle rejection preserves the exact stable diagnostic');
    is(scalar(@{$failure->{diagnostic}{notes}}), 4,
        'failure diagnostic retains four closed identity/evidence notes');
    like($failure->{diagnostic}{notes}[2],
        qr/"timeout_seconds":30/,
        'failure diagnostic durably retains exact lifecycle capture evidence');
    like($failure->{diagnostic}{notes}[3],
        qr/"removed":true/,
        'failure diagnostic durably retains exact cleanup evidence');
};

subtest 'guarded reference, gate, and qualification repetitions are exact' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_PORTABLE_RUNTIME_MEASUREMENT_EXACT=1 under scripts/run_with_ram_guard.sh'
        unless $ENV{FSMGEN_VIAL_PORTABLE_RUNTIME_MEASUREMENT_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'exact runtime measurement runs below active guard enforcement');

    my $reference = $class->validate_profile({
        repository_root => $repo_root, level => 'reference_v1',
    });
    if (is($reference->{outcome}, 'accepted_validation',
            'checked reference passes one correctness-only lifecycle')) {
        verify_records($reference, 0, 274);
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
            '15,000-record qualification repetitions are accepted')) {
        verify_records($qualification, 5, 15_000);
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
        is($stage{elaborate}{status}, 'not_run',
            "$report->{level} records integrated elaboration honestly");
        is($stage{compile_analyze}{classification}, 'external_tool',
            "$report->{level} compile is externally classified");
        is($stage{run}{classification}, 'external_tool',
            "$report->{level} run is externally classified");
        is($stage{compile_analyze}{timeout}{outer_seconds}, 900,
            "$report->{level} compile worker retains controller outer bound");
        ok(!defined($stage{compile_analyze}{timeout}{backend_seconds}),
            "$report->{level} compile tool deadline is lifecycle-owned");
        is($stage{run}{timeout}{outer_seconds}, 300,
            "$report->{level} run worker retains controller outer bound");
        ok(!defined($stage{run}{timeout}{backend_seconds}),
            "$report->{level} run tool deadline is lifecycle-owned");
        if ($record->{run_class} eq 'validation') {
            is(scalar(grep { @{$_->{raw_samples}} }
                    @{$record->{stage_measurements}}), 0,
                "$report->{level} validation retains no performance sample");
        }
        else {
            for my $name (qw(
                construct parse_validate bridge bind_plan emit
                compile_analyze run trace_validate result_produce publish
            )) {
                cmp_ok(scalar(@{$stage{$name}{raw_samples}}), '>=', 1,
                    "$report->{level} $name retains raw measured samples");
            }
        }
        my ($publish) = grep {
            $_->{oracle_id} eq
                'portable_runtime_publish_lifecycle_canonical'
        } @{$record->{correctness_oracles}};
        ok(defined($publish) && $publish->{ok},
            "$report->{level} retains the terminal lifecycle oracle");
        is($publish->{evidence}{artifact_count}, 12,
            "$report->{level} returns the exact runtime artifact graph");
        like($publish->{evidence}{workspace_command_digests}{compile},
            qr{\Aworkspace-command/[0-9a-f]{64}\z},
            "$report->{level} compile identity is workspace-normalized");
        like($publish->{evidence}{workspace_command_digests}{run},
            qr{\Aworkspace-command/[0-9a-f]{64}\z},
            "$report->{level} run identity is workspace-normalized");
        is($publish->{evidence}{trace_record_count}, $records,
            "$report->{level} validated trace count is exact");
        is_deeply($publish->{evidence}{state_order}, [qw(
            admitted prepared tool_verified compiled ran trace_validated
            result_produced assembled
        )], "$report->{level} lifecycle predecessor chain is complete");
    }
    is($json->encode($class->validate_report({
        repository_root => $repo_root, report => $report,
    })), $json->encode($report),
        "$report->{level} complete report reloads canonically");
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
