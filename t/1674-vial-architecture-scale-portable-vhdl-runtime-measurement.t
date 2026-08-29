#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization;
use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement;
use FSM::VIAL::Backend::VHDLPortableGHDLQualification;

my $class =
    'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement';
my $materializer =
    'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMaterialization';
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
        backend_profile => 'vhdl_portable_ghdl', level => $_,
    }} @levels],
    'measurement adapter owns exactly the five portable runtime roles',
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
        provider_identity => 'qualified_ghdl_6_0_0_llvm_jit',
        arguments => [qw(--std=08 --work=fsmgen_vial)],
        thread_count => 1,
        job_count => 1,
        external_verification_tool => JSON::PP::true,
    },
    'adapter binds the exact repository-qualified GHDL profile',
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
        FSM::VIAL::Backend::VHDLPortableGHDLQualification
            ->_measurement_provider_authority;
    }), qr/private to the exact measurement adapter/,
        'provider authority rejects generic callers');

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

    my $unsealed = FSM::VIAL::Backend::GHDLLifecycle->finish_session({});
    ok(!$unsealed->{ok}
            && $unsealed->{diagnostics}[0]{code}
                eq 'VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'generic callers cannot borrow the GHDL lifecycle finalizer');

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
            admitted prepared tool_verified analyzed elaborated ran
            trace_validated result_produced assembled cleaned
        )],
        'report binds the sole forward-only lifecycle state order',
    );
    is_deeply(
        $report->{lifecycle_contract}{stage_mapping},
        {
            emit => ['admitted'],
            compile_analyze => [qw(prepared tool_verified analyzed)],
            elaborate => ['elaborated'],
            run => ['ran'],
            trace_validate => ['trace_validated'],
            result_produce => ['result_produced'],
            publish => [qw(assembled cleaned)],
        },
        'common stages map exactly onto shared lifecycle work',
    );
    is($report->{lifecycle_contract}{analysis_timeout_seconds}, 120,
        'analysis retains the qualified 120-second lifecycle ceiling');
    is($report->{lifecycle_contract}{elaboration_timeout_seconds}, 60,
        'elaboration retains the qualified 60-second lifecycle ceiling');
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
        FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement::_lifecycle_failure(
            'run', {
                ok => JSON::PP::false,
                lifecycle_identity => 'lifecycle/' . ('a' x 64),
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
    is(scalar(@{$failure->{diagnostic}{notes}}), 3,
        'failure diagnostic retains three closed identity/evidence notes');
    like($failure->{diagnostic}{notes}[1],
        qr/"timeout_seconds":30/,
        'failure diagnostic durably retains exact lifecycle capture evidence');
    like($failure->{diagnostic}{notes}[2],
        qr/"removed":true/,
        'failure diagnostic durably retains exact cleanup evidence');
};

subtest 'guarded reference, gate, and qualification repetitions are exact' => sub {
    plan skip_all =>
        'set FSMGEN_VIAL_PORTABLE_VHDL_RUNTIME_MEASUREMENT_EXACT=1 under scripts/run_with_ram_guard.sh'
        unless $ENV{FSMGEN_VIAL_PORTABLE_VHDL_RUNTIME_MEASUREMENT_EXACT};
    is($ENV{FSMGEN_RAM_GUARD_ACTIVE}, 1,
        'exact runtime measurement runs below active guard enforcement');

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
        is($stage{elaborate}{classification}, 'external_tool',
            "$report->{level} elaboration is externally classified");
        is($stage{compile_analyze}{classification}, 'external_tool',
            "$report->{level} compile is externally classified");
        is($stage{run}{classification}, 'external_tool',
            "$report->{level} run is externally classified");
        is($stage{compile_analyze}{timeout}{outer_seconds}, 900,
            "$report->{level} compile worker retains controller outer bound");
        ok(!defined($stage{compile_analyze}{timeout}{backend_seconds}),
            "$report->{level} compile tool deadline is lifecycle-owned");
        is($stage{elaborate}{timeout}{outer_seconds}, 60,
            "$report->{level} elaboration retains controller outer bound");
        ok(!defined($stage{elaborate}{timeout}{backend_seconds}),
            "$report->{level} elaboration deadline is lifecycle-owned");
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
                compile_analyze elaborate run trace_validate result_produce
                publish
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
        is($publish->{evidence}{artifact_identity}
                {emission_artifact_count}, 17,
            "$report->{level} retains the exact emitted artifact graph");
        is(scalar(keys %{$publish->{evidence}{command_identities}}), 4,
            "$report->{level} retains four exact GHDL command identities");
        is(scalar(keys %{$publish->{evidence}{transcript_identities}}), 4,
            "$report->{level} retains four exact transcript identities");
        is($publish->{evidence}{trace_record_count}, $records,
            "$report->{level} validated trace count is exact");
        is_deeply($publish->{evidence}{state_order}, [qw(
            admitted prepared tool_verified analyzed elaborated ran
            trace_validated result_produced assembled
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
