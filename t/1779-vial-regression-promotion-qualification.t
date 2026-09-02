#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Digest::SHA qw(sha256_hex);
use FindBin;
use JSON::PP ();
use Test::More;

use lib "$FindBin::Bin/../perl";

use FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore;
use FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;
use FSM::VIAL::ArchitectureScaleRegressionPromotionQualification;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionQualification';
my $policy = 'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy';
my $corpus_store =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore';
my $profile_store =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $revision = '1' x 40;
my $policy_identity =
    'regression-promotion-policy/'
    . '19cf41056da86d95c266597e7db76eff3810ee29511a005e1051053009a65ece';

sub clone_value($value) {
    return $json->decode($json->encode($value));
}

sub dies($code) {
    my $error;
    eval { $code->(); 1 } or $error = $@;
    return $error // '';
}

sub content_identity($value, $key, $prefix) {
    my $copy = clone_value($value);
    $copy->{$key} = undef;
    return $prefix . sha256_hex($json->encode($copy));
}

sub host_profile() {
    return {
        architecture => 'test64',
        cpu_model => 'qualification-test',
        filesystem_type => 'fixture',
        logical_core_count => 4,
        measurement_implementation => 'fixture-sampler-v1',
        os_name => 'FixtureOS',
        os_version => '1',
        physical_memory_bytes => 8_589_934_592,
    };
}

sub tool_profile($ordinal) {
    return {
        applicability => 'fixture_exact',
        arguments => [],
        build => "fixture-$ordinal",
        external_verification_tool => JSON::PP::false,
        job_count => 1,
        logical_name => 'fixture-tool',
        provider_identity => 'fixture-provider',
        reported_version => '1.0',
        thread_count => 1,
    };
}

sub resource_guard() {
    return {
        active => JSON::PP::true,
        enforcement => 'repository_ram_guard',
        host_max_percent => 88,
        sampler_interval_ns => 250_000_000,
        single_descendant_max_mib => 4096,
    };
}

sub provider_status() {
    return {
        kind => 'not_applicable',
        external_verification_tool => JSON::PP::false,
        logical_name => undef,
        provider_identity => undef,
        tool_profile_identity => undef,
    };
}

sub stage($name, $measured, $wall, $cpu, $rss) {
    return {
        stage => $name,
        classification => $measured ? 'fsmgen_owned' : 'not_applicable',
        status => $measured ? 'measured' : 'not_run',
        command_identity => $measured ? {
            logical_name => 'fixture-stage',
            arguments => [$name],
            job_count => 1,
            thread_count => 1,
        } : undef,
        timeout => {
            authority => 'architecture_scale_outer',
            backend_seconds => undef,
            effective_seconds => 120,
            outer_seconds => 120,
        },
        wall_time_ns => $measured ? $wall : undef,
        controller_cpu => {
            user_ns => $measured ? $cpu : undef,
            system_ns => $measured ? 0 : undef,
            unsupported_reason => $measured ? undef : 'stage_not_run',
        },
        descendant_cpu => {
            user_ns => $measured ? 0 : undef,
            system_ns => $measured ? 0 : undef,
            unsupported_reason => $measured
                ? 'short_lived_process_undercount_possible' : 'stage_not_run',
        },
        rss => {
            peak_process_tree_bytes => $measured ? $rss : undef,
            peak_single_descendant_bytes => $measured ? $rss : undef,
            unsupported_reason => $measured ? undef : 'stage_not_run',
        },
        raw_samples => [],
        input_counts => {bytes => 10, files => 1, lines => 1, objects => 1},
        output_counts => {bytes => 20, files => 1, lines => 1, objects => 1},
        semantic_object_counts => {fixture_objects => 1},
        correctness_oracle_ids => $name eq 'construct'
            ? ['fixture_correct'] : [],
        process => {
            exit_code => $measured ? 0 : undef,
            signal => $measured ? 0 : undef,
            timed_out => JSON::PP::false,
        },
        worker_status => $measured ? 'completed' : undef,
        not_run_reason => $measured ? undef : 'not_applicable_to_invocation',
        unsupported_counters => $measured ? [] : ['stage_not_run'],
    };
}

sub record($ordinal, $run_ordinal, $workload_identity, $common) {
    my $validation = $run_ordinal == 0;
    my @stages = map {
        $_ eq 'construct'
            ? stage(
                $_, !$validation,
                2_000_000_001 + 100_000_000 * $run_ordinal,
                1_000_000_001 + 10_000_000 * $run_ordinal,
                268_435_457 + 1_000_000 * $run_ordinal,
            )
            : stage($_, 0, 0, 0, 0)
    } qw(
        construct parse_validate bridge bind_plan emit compile_analyze
        elaborate run trace_validate result_produce publish cleanup
    );
    $stages[0]{status} = 'validated_unmeasured' if $validation;
    $stages[0]{classification} = 'fsmgen_owned' if $validation;
    return {
        schema => 'fsmgen.vial_architecture_scale_measurement.v1',
        schema_version => 1,
        measurement_identity => 'measurement/' . sha256_hex(
            "fixture-$ordinal-$run_ordinal",
        ),
        workload_identity => $workload_identity,
        workload_specification => {
            schema => 'fsmgen.vial_architecture_scale_workload.v1',
            schema_version => 1,
            family => 'fixture_family_v1',
            level => 'gate_candidate_v1',
            requested_counts => {fixture_objects => $ordinal},
        },
        git_revision => $common->{git_revision},
        dirty_state => clone_value($common->{dirty_state}),
        host_profile => clone_value($common->{host_profile}),
        tool_profile => clone_value($common->{tool_profile}),
        run_class => $validation ? 'validation' : 'gate_measurement',
        run_ordinal => $run_ordinal,
        stage_measurements => \@stages,
        correctness_oracles => [{
            oracle_id => 'fixture_correct',
            stage => 'construct',
            ok => JSON::PP::true,
            evidence_identity => sha256_hex(
                $json->encode({fixture_objects => $ordinal}),
            ),
            evidence => {fixture_objects => $ordinal},
        }],
        resource_guard => clone_value($common->{resource_guard}),
        artifacts => {
            published_identity => undef,
            records => [{
                stage => 'construct',
                kind => 'fixture_evidence',
                relative_path => 'outputs/construct/fixture.json',
                bytes => 20,
                lines => 1,
                sha256 => sha256_hex("artifact-$ordinal-$run_ordinal"),
            }],
            staging_identity => ".artifacts/tmp/fixture/$ordinal/$run_ordinal",
        },
        outcome => 'accepted',
        diagnostic => undef,
        cleanup => {
            ephemeral_removed => JSON::PP::true,
            residue => [],
            staging_identity => ".artifacts/tmp/fixture/$ordinal/$run_ordinal",
        },
        explicit_nonclaims => ['public_performance_budget'],
    };
}

sub fixtures() {
    my $host = host_profile();
    my $guard = resource_guard();
    my $corpus_common = {
        git_revision => $revision,
        dirty_state => JSON::PP::false,
        host_profile => clone_value($host),
        resource_guard => clone_value($guard),
    };
    my (@source_profiles, @profile_loads, @entries);
    for my $ordinal (1 .. 11) {
        my $selection_key = "fixture|family|gate_candidate_v1|axis$ordinal|-";
        my $workload_identity = 'workload/' . sha256_hex("workload-$ordinal");
        my $common = {
            %$corpus_common,
            dirty_state => JSON::PP::false,
            host_profile => clone_value($host),
            resource_guard => clone_value($guard),
            tool_profile => tool_profile($ordinal),
        };
        my $report_identity = 'fixture-report/' . sha256_hex("report-$ordinal");
        my $measurement_set = {
            schema => 'fsmgen.vial_architecture_scale_fixture_measurement_set.v1',
            schema_version => 1,
            family => 'fixture_family_v1',
            level => 'gate_candidate_v1',
            mode => 'gate_measurement',
            primary_axis => "axis$ordinal",
            report_identity => $report_identity,
            workload_identity => $workload_identity,
            measurement_applicability => {
                applicable => JSON::PP::true,
                reason => undef,
            },
            validation_record => record(
                $ordinal, 0, $workload_identity, $common,
            ),
            measurement_records => [map {
                record($ordinal, $_, $workload_identity, $common)
            } 1 .. 3],
            sample_exclusions => [],
            requested_counts => {fixture_objects => $ordinal},
            canonical_evaluation => {
                ok => JSON::PP::true,
                metrics => {
                    fixture_objects => $ordinal,
                    serialized_fixture_bytes => 100 + $ordinal,
                },
            },
            cleanup => {ephemeral_removed => JSON::PP::true, residue => []},
            outcome => 'accepted',
            diagnostics => [],
            explicit_nonclaims => ['public_performance_budget'],
        };
        my $entry = {
            ordinal => $ordinal,
            selection_key => $selection_key,
        };
        my $relative = sprintf(
            '.artifacts/qualification/vial-scale/v2/fixture/%02d/measurement-report.json',
            $ordinal,
        );
        my $sha = sha256_hex($json->encode($measurement_set));
        my $bytes = length($json->encode($measurement_set));
        my $profile_artifact = {
            schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_profile_artifact.v1',
            schema_version => 1,
            status => 'loaded',
            ordinal => $ordinal,
            selection_key => $selection_key,
            artifact_relative_path => $relative,
            artifact_sha256 => $sha,
            artifact_bytes => $bytes,
            same_volume => JSON::PP::true,
            atomic => JSON::PP::true,
        };
        push @entries, $entry;
        push @source_profiles, {
            ordinal => $ordinal,
            selection_key => $selection_key,
            report_identity => $report_identity,
            common_identity => $common,
            provider_status => provider_status(),
            applicability_status => {
                required => JSON::PP::true,
                predicate => 'accepted_validation_and_family_evaluation',
                controller_applicable => JSON::PP::true,
                measurement_applicable => JSON::PP::true,
                validation_records => 1,
                raw_measurement_records => 3,
                sample_exclusions => 0,
                outcome => 'accepted',
            },
            artifact => {
                ordinal => $ordinal,
                selection_key => $selection_key,
                relative_path => $relative,
                sha256 => $sha,
                bytes => $bytes,
                same_volume => JSON::PP::true,
                atomic => JSON::PP::true,
            },
        };
        push @profile_loads, {
            publication => {
                schema =>
                    'fsmgen.vial_architecture_scale_regression_promotion_profile_publication.v1',
                schema_version => 1,
                publication_identity =>
                    'regression-promotion-profile-publication/'
                    . sha256_hex("publication-$ordinal"),
                plan_identity => 'regression-promotion-capture-plan/' . ('2' x 64),
                policy_identity => $policy_identity,
                publication_id => 'regression-promotion-corpus-v1',
                publication_schema =>
                    'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1',
                profile => clone_value($entry),
                report => $measurement_set,
            },
            artifact => $profile_artifact,
        };
    }
    my $summary = {
        profile_count => 11,
        validation_records => 11,
        raw_measurement_records => 33,
        controller_invocations => 44,
        sample_exclusions => 0,
    };
    my $source_nonclaims = [qw(
        producer_execution provider_execution simulator_execution
        measurement_controller_execution profile_capture_or_resume
        performance_budget_promotion support_promotion
        architecture_scale_capacity historical_artifact_reuse
    )];
    my $report = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1',
        schema_version => 1,
        corpus_identity => 'regression-promotion-corpus/' . ('3' x 64),
        plan_identity => 'regression-promotion-capture-plan/' . ('2' x 64),
        policy_identity => $policy_identity,
        publication_id => 'regression-promotion-corpus-v1',
        publication_schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1',
        common_identity => $corpus_common,
        summary => $summary,
        profiles => \@source_profiles,
        explicit_nonclaims => $source_nonclaims,
    };
    my $manifest = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_corpus_manifest.v1',
        schema_version => 1,
        publication_identity =>
            'regression-promotion-corpus-publication/' . ('4' x 64),
        corpus_identity => $report->{corpus_identity},
        plan_identity => $report->{plan_identity},
        policy_identity => $report->{policy_identity},
        publication_id => $report->{publication_id},
        report_artifact => {
            relative_path => '.artifacts/qualification/vial-scale/v2/fixture/report.json',
            sha256 => '5' x 64,
            bytes => 1234,
        },
        summary => clone_value($summary),
        outcome => 'accepted',
        explicit_nonclaims => clone_value($source_nonclaims),
    };
    my $artifact = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_corpus_artifact.v1',
        schema_version => 1,
        status => 'loaded',
        publication_relative_path =>
            '.artifacts/qualification/vial-scale/v2/fixture',
        report_artifact => clone_value($manifest->{report_artifact}),
        manifest_artifact => {
            relative_path => '.artifacts/qualification/vial-scale/v2/fixture/manifest.json',
            sha256 => '6' x 64,
            bytes => 567,
        },
        file_set_sha256 => '7' x 64,
        same_volume => JSON::PP::true,
        atomic => JSON::PP::true,
    };
    return (
        {report => $report, manifest => $manifest, artifact => $artifact},
        {
            plan => {
                plan_identity => $report->{plan_identity},
                policy_identity => $report->{policy_identity},
                publication_id => $report->{publication_id},
                publication_schema => $report->{publication_schema},
                entries => \@entries,
            },
            profiles => \@profile_loads,
        },
    );
}

sub derive_fixture() {
    my ($corpus, $profiles) = fixtures();
    my $derive = $class->can('_derive_from_evidence');
    return $derive->($corpus, $profiles);
}

subtest 'closed public surface and exact formula are defensive' => sub {
    is_deeply([sort @{$class->report_keys}], [sort qw(
        schema schema_version qualification_identity source_evidence formula
        performance_applicability summary profiles outcome diagnostics
        explicit_nonclaims
    )], 'qualification report has one closed surface');
    is_deeply([sort @{$class->profile_keys}], [sort qw(
        ordinal selection_key profile_qualification_identity
        source_report_identity workload_identity evidence_revision
        environment_identity correctness_projection_identity
        correctness_projection performance_applicability_identity
        validation_identity raw_measurement_identities accepted_run_totals
        aggregate_statistics qualified_budget provider_status outcome
    )], 'qualified profiles have one closed surface');
    my $formula = $class->formula;
    is($formula->{wall_time_ns}{multiplier_numerator}, 3,
        'wall budget numerator is exact');
    $formula->{wall_time_ns}{multiplier_numerator} = 99;
    is($class->formula->{wall_time_ns}{multiplier_numerator}, 3,
        'formula returns defensively');
    like(dies(sub { $class->derive({repository_root => '.', evidence => {}}) }),
        qr/unknown key 'evidence'/, 'caller evidence rejects');
    {
        local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
        local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
        local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
        like(dies(sub { $class->derive({repository_root => '.'}) }),
            qr/requires the active repository RAM guard/,
            'unguarded public qualification rejects before loading evidence');
    }
    my $report_keys = $class->can('report_keys');
    like(dies(sub { $report_keys->('Borrowed') }), qr/exact class invocant/,
        'borrowed class invocants reject');
};

subtest 'complete current evidence derives one bounded qualification' => sub {
    my $report = derive_fixture();
    like($report->{qualification_identity},
        qr{\Aregression-promotion-qualification/[0-9a-f]{64}\z},
        'qualification is content-addressed');
    is_deeply($report->{summary}, {
        profile_count => 11,
        validation_records => 11,
        raw_measurement_records => 33,
        controller_invocations => 44,
        sample_exclusions => 0,
        qualified_profiles => 11,
    }, 'all validation and raw records are independently recounted');
    is(scalar(@{$report->{profiles}}), 11,
        'all eleven profiles qualify in plan order');
    is($report->{profiles}[0]{aggregate_statistics}{wall_time_ns}{maximum},
        2_300_000_001, 'run totals drive the exact maximum');
    is($report->{profiles}[0]{qualified_budget}{wall_time_ns},
        3_451_000_000, 'wall formula scales and rounds upward to 1 ms');
    is($report->{profiles}[0]{qualified_budget}{cpu_time_ns},
        2_000_000_000, 'CPU formula retains its 2-second floor');
    is($report->{profiles}[0]{qualified_budget}{peak_tree_rss_bytes},
        352_321_536, 'RSS formula scales and rounds upward to 16 MiB');
    is($report->{profiles}[0]{evidence_revision}, $revision,
        'capture revision remains immutable profile provenance');
    isnt($report->{profiles}[0]{performance_applicability_identity},
        $report->{profiles}[1]{performance_applicability_identity},
        'behavior and environment produce profile-specific applicability');
    my $correctness = $report->{profiles}[0]{correctness_projection};
    is(scalar(@{$correctness->{record_projections}}), 4,
        'correctness projection retains validation plus all measured runs');
    is($correctness->{record_projections}[1]{stage_measurements}[0]
        {semantic_object_counts}{fixture_objects}, 1,
        'correctness projection retains exact deterministic counts');
    like($correctness->{record_projections}[1]{artifact_records}[0]{sha256},
        qr/\A[0-9a-f]{64}\z/,
        'correctness projection retains exact artifact identities');
    cmp_ok(length($json->encode($report)), '<=',
        $class->qualification_limits->{maximum_report_bytes},
        'qualification stays within its in-memory bound');
};

subtest 'public derivation reads only authenticated stores and returns defensively' => sub {
    my ($corpus, $profiles) = fixtures();
    my ($corpus_calls, $profile_calls) = (0, 0);
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore::load = sub {
        $corpus_calls++;
        return clone_value($corpus);
    };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore::load_all = sub {
        $profile_calls++;
        return clone_value($profiles);
    };
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;
    my $first = $class->derive({repository_root => "$FindBin::Bin/.."});
    is_deeply([$corpus_calls, $profile_calls], [1, 1],
        'qualification invokes only the two authenticated evidence stores');
    $first->{profiles}[0]{qualified_budget}{wall_time_ns} = 0;
    my $second = $class->derive({repository_root => "$FindBin::Bin/.."});
    is($second->{profiles}[0]{qualified_budget}{wall_time_ns}, 3_451_000_000,
        'returned qualification state is defensive');
};

subtest 'hostile evidence and arithmetic fail closed' => sub {
    my @cases = (
        ['historical policy', sub {
            $_[0]{report}{policy_identity} = 'regression-promotion-policy/' . ('0' x 64);
            $_[0]{manifest}{policy_identity} = $_[0]{report}{policy_identity};
            $_[1]{plan}{policy_identity} = $_[0]{report}{policy_identity};
            $_->{publication}{policy_identity} = $_[0]{report}{policy_identity}
                for @{$_[1]{profiles}};
        }, qr/source is not current/],
        ['missing profile', sub { pop @{$_[1]{profiles}} },
            qr/profile loads are invalid/],
        ['reordered profile', sub {
            @{
                $_[1]{profiles}
            }[0, 1] = @{$_[1]{profiles}}[1, 0];
        }, qr/profile order changed/],
        ['string schema version', sub {
            $_[0]{report}{schema_version} = sprintf('%d', 1);
        }, qr/source schema changed/],
        ['sample exclusion', sub {
            $_[1]{profiles}[0]{publication}{report}{sample_exclusions} = [
                {reason => 'forged'},
            ];
        }, qr/exclusions are invalid/],
        ['failed correctness', sub {
            $_[1]{profiles}[0]{publication}{report}
                {measurement_records}[0]{correctness_oracles}[0]{ok} =
                    JSON::PP::false;
        }, qr/correctness oracle failed/],
        ['rewritten correctness evidence', sub {
            $_[1]{profiles}[0]{publication}{report}
                {measurement_records}[0]{correctness_oracles}[0]
                {evidence}{fixture_objects} = 2;
        }, qr/correctness oracle failed/],
        ['string deterministic count', sub {
            $_[1]{profiles}[0]{publication}{report}
                {measurement_records}[0]{stage_measurements}[0]
                {semantic_object_counts}{fixture_objects} = sprintf('%d', 1);
        }, qr/not a safe JSON integer/],
        ['string artifact bytes', sub {
            $_[1]{profiles}[0]{publication}{report}
                {measurement_records}[0]{artifacts}{records}[0]{bytes} =
                    sprintf('%d', 20);
        }, qr/not a safe JSON integer/],
        ['mixed host', sub {
            $_[1]{profiles}[0]{publication}{report}
                {measurement_records}[0]{host_profile}{cpu_model} = 'foreign';
        }, qr/record identity changed/],
        ['string run ordinal', sub {
            $_[1]{profiles}[0]{publication}{report}
                {measurement_records}[0]{run_ordinal} = sprintf('%d', 1);
        }, qr/record coordinate changed/],
        ['unsafe integer', sub {
            $_[1]{profiles}[0]{publication}{report}
                {measurement_records}[0]{stage_measurements}[0]
                {wall_time_ns} = 9_007_199_254_740_992;
        }, qr/not a safe JSON integer/],
        ['addition overflow', sub {
            my $record = $_[1]{profiles}[0]{publication}{report}
                {measurement_records}[0];
            $record->{stage_measurements}[0]{wall_time_ns} =
                9_007_199_254_740_991;
            $record->{stage_measurements}[1] = clone_value(
                $record->{stage_measurements}[0],
            );
            $record->{stage_measurements}[1]{stage} = 'parse_validate';
        }, qr/run wall time exceeds the safe integer range/],
    );
    my $derive = $class->can('_derive_from_evidence');
    for my $case (@cases) {
        my ($corpus, $profiles) = fixtures();
        $case->[1]->($corpus, $profiles);
        like(dies(sub { $derive->($corpus, $profiles) }), $case->[2],
            "$case->[0] rejects");
    }
};

subtest 'rehashed output mutations cannot rewrite budgets or applicability' => sub {
    my $validate = $class->can('_validate_qualification_report');
    my $report = derive_fixture();
    $report->{profiles}[0]{qualified_budget}{wall_time_ns} = 1;
    $report->{profiles}[0]{profile_qualification_identity} = content_identity(
        $report->{profiles}[0], 'profile_qualification_identity',
        'regression-promotion-profile-qualification/',
    );
    $report->{qualification_identity} = content_identity(
        $report, 'qualification_identity',
        'regression-promotion-qualification/',
    );
    like(dies(sub { $validate->($report) }), qr/budget arithmetic changed/,
        'a rehashed budget rewrite rejects');

    $report = derive_fixture();
    $report->{profiles}[0]{performance_applicability_identity} =
        'regression-promotion-profile-applicability/' . ('0' x 64);
    $report->{profiles}[0]{profile_qualification_identity} = content_identity(
        $report->{profiles}[0], 'profile_qualification_identity',
        'regression-promotion-profile-qualification/',
    );
    $report->{qualification_identity} = content_identity(
        $report, 'qualification_identity',
        'regression-promotion-qualification/',
    );
    like(dies(sub { $validate->($report) }), qr/applicability identity changed/,
        'a rehashed applicability rewrite rejects');
};

subtest 'applicability schema rejects numeric-looking JSON strings' => sub {
    my $contract = $policy->performance_applicability_contract;
    $contract->{schema_version} = sprintf('%d', 1);
    $contract->{applicability_identity} = content_identity(
        $contract, 'applicability_identity',
        'regression-promotion-performance-applicability/',
    );
    my $validate = $policy->can(
        '_validate_performance_applicability_contract');
    like(dies(sub { $validate->($contract) }), qr/schema is invalid/,
        'a rehashed string schema version cannot impersonate JSON number 1');
};

done_testing();
