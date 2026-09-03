use v5.20;
use strict;
use warnings;

use lib 'perl';
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use POSIX ();
use Test::More;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile;
use FSM::VIAL::ArchitectureScaleRegressionPromotionQualification;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile';
my $revision = 'a' x 40;
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $repo = tempdir(CLEANUP => 1);
make_path(File::Spec->catdir($repo, '.git'));
my $marker = File::Spec->catfile($repo, 'adapter-markers');

sub canonical($value) {
    return $json->encode($value);
}

sub clone($value) {
    return $json->decode($json->encode($value));
}

sub bool($value) {
    return $value ? JSON::PP::true : JSON::PP::false;
}

sub environment($common, $provider) {
    my $value = {
        environment_identity => undef,
        host_profile => clone($common->{host_profile}),
        tool_profile => clone($common->{tool_profile}),
        resource_guard => clone($common->{resource_guard}),
        provider_status => clone($provider),
    };
    $value->{environment_identity} = 'regression-promotion-environment/'
        . sha256_hex(canonical($value));
    return $value;
}

sub provider_not_applicable() {
    return {
        kind => 'not_applicable',
        external_verification_tool => bool(0),
        logical_name => undef,
        provider_identity => undef,
        tool_profile_identity => undef,
    };
}

our $common = {
    git_revision => $revision,
    dirty_state => bool(0),
    host_profile => {host_identity => 'synthetic-host'},
    tool_profile => {
        applicability => 'fsmgen_owned_foundation_only',
        logical_name => 'in_process_perl_worker',
        provider_identity => 'repository_runtime',
        external_verification_tool => bool(0),
    },
    resource_guard => {
        active => bool(1),
        host_max_percent => 80,
        single_descendant_max_mib => 1024,
    },
};
my $provider = provider_not_applicable();
my $workload_identity = 'workload/' . ('1' x 64);
my $correctness_identity;
our $qualified_correctness_projection;
our $current_correctness_projection;
our $report;
my $observation;
my $contract;
my $availability;
our $adapter_mode = 'ok';

sub synthetic_stable_projection($profile = 'osvvm') {
    die "unknown synthetic stable projection profile '$profile'\n"
        unless $profile eq 'osvvm'
            || $profile eq 'portable'
            || $profile eq 'portable_vhdl';
    my $portable = $profile eq 'portable';
    my $portable_vhdl = $profile eq 'portable_vhdl';
    my @stages = $portable
        ? qw(compile_analyze run trace_validate result_produce publish)
        : qw(compile_analyze elaborate run trace_validate result_produce publish);
    my @artifact_stages = @stages[0 .. $#stages - 1];
    my $prefix = $portable || $portable_vhdl
        ? 'portable_runtime' : 'osvvm_runtime';
    my @artifacts = map {
        my $stage = $_;
        ({
            bytes => 100,
            kind => "${prefix}_lifecycle_evidence",
            lines => 1,
            relative_path => "outputs/$stage/lifecycle-evidence.json",
            sha256 => '1' x 64,
            stage => $stage,
        }, {
            bytes => 50,
            kind => "${prefix}_lifecycle_handle",
            lines => 1,
            relative_path => "outputs/$stage/lifecycle-handle.json",
            sha256 => '2' x 64,
            stage => $stage,
        })
    } @artifact_stages;
    push @artifacts, {
        bytes => 200,
        kind => $portable_vhdl
            ? 'portable_vhdl_lifecycle_evidence'
            : "${prefix}_lifecycle_evidence",
        lines => 1,
        relative_path => 'outputs/publish/lifecycle-evidence.json',
        sha256 => '3' x 64,
        stage => 'publish',
    };
    return {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_correctness.v1',
        schema_version => 1,
        report_contract => {
            schema => $portable
                ? 'fsmgen.vial_architecture_scale_portable_runtime_measurement_set.v1'
                : $portable_vhdl
                    ? 'fsmgen.vial_architecture_scale_portable_vhdl_runtime_measurement_set.v1'
                    : 'fsmgen.vial_architecture_scale_osvvm_runtime_measurement_set.v1',
            family => 'runtime_stream_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'runtime_trace_records',
            backend_profile => $portable
                ? 'sv_portable_verilator'
                : $portable_vhdl
                    ? 'vhdl_portable_ghdl' : 'vhdl_osvvm_qualified',
        },
        record_projections => [map {
            my $ordinal = $_;
            +{
                run_class => $ordinal ? 'gate_measurement' : 'validation',
                run_ordinal => $ordinal,
                artifact_records => clone(\@artifacts),
                correctness_oracles => [map {
                    +{
                        stage => $_,
                        oracle_id => "${prefix}_${_}_lifecycle_canonical",
                        evidence_identity => '4' x 64,
                    }
                } @stages],
                stage_measurements => [map {
                    +{
                        stage => $_,
                        output_counts => {bytes => 300, objects => 2},
                    }
                } @stages],
            }
        } 0 .. 3],
    };
}

sub reset_fixture() {
    unlink $marker if -e $marker;
    $adapter_mode = 'ok';
    $qualified_correctness_projection = {
        schema => 'synthetic.correctness.v1',
        stable_value => 'qualified',
    };
    $current_correctness_projection =
        clone($qualified_correctness_projection);
    $correctness_identity = 'regression-promotion-correctness/'
        . sha256_hex(canonical($qualified_correctness_projection));
    $provider = provider_not_applicable();
    $common->{host_profile} = {host_identity => 'synthetic-host'};
    $common->{tool_profile} = {
        applicability => 'fsmgen_owned_foundation_only',
        logical_name => 'in_process_perl_worker',
        provider_identity => 'repository_runtime',
        external_verification_tool => bool(0),
    };
    $report = {
        schema => 'fsmgen.synthetic_gate_profile.v1',
        schema_version => 1,
        report_identity => 'synthetic-gate-profile/' . ('3' x 64),
        family => 'synthetic_family_v1',
        level => 'gate_candidate_v1',
        primary_axis => 'objects',
        mode => 'gate_measurement',
        controller_applicability => {
            applicable => bool(1), reason => undef,
        },
        measurement_applicability => {
            applicable => bool(1), reason => undef,
        },
        validation_record => {
            %{clone($common)},
            measurement_identity => 'measurement/' . ('4' x 64),
            run_class => 'validation',
            run_ordinal => 0,
            outcome => 'accepted',
        },
        measurement_records => [map {
            +{
                %{clone($common)},
                measurement_identity => 'measurement/' . ("$_" x 64),
                run_class => 'gate_measurement',
                run_ordinal => $_ - 4,
                outcome => 'accepted',
            }
        } 5 .. 7],
        sample_exclusions => [],
        outcome => 'accepted',
        diagnostics => [],
        cleanup => {
            records_total => 4,
            ephemeral_removed => bool(1),
            residue => [],
        },
    };
    $observation = {
        workload_identity => $workload_identity,
        validation_identity => 'measurement/' . ('4' x 64),
        raw_measurement_identities => [map {
            'measurement/' . ("$_" x 64)
        } 5 .. 7],
        accepted_run_totals => [
            {
                measurement_identity => 'measurement/' . ('5' x 64),
                run_ordinal => 1,
                wall_time_ns => 90,
                cpu_time_ns => 180,
                peak_tree_rss_bytes => 290,
            },
            {
                measurement_identity => 'measurement/' . ('6' x 64),
                run_ordinal => 2,
                wall_time_ns => 100,
                cpu_time_ns => 190,
                peak_tree_rss_bytes => 300,
            },
            {
                measurement_identity => 'measurement/' . ('7' x 64),
                run_ordinal => 3,
                wall_time_ns => 95,
                cpu_time_ns => 200,
                peak_tree_rss_bytes => 295,
            },
        ],
        observed_maximum => {
            wall_time_ns => 100,
            cpu_time_ns => 200,
            peak_tree_rss_bytes => 300,
        },
        correctness_projection_identity => $correctness_identity,
    };
    $contract = {
        contract_identity =>
            'regression-promotion-gate-contract/' . ('8' x 64),
        qualification_evidence => {
            qualification_identity =>
                'regression-promotion-qualification/' . ('9' x 64),
            publication_identity =>
                'regression-promotion-budget-qualification-publication/'
                . ('a' x 64),
            qualification_file_set_sha256 => 'b' x 64,
        },
        result_contract => {
            maximum_profile_report_bytes => 1_048_576,
            maximum_profile_ipc_bytes => 65_536,
            maximum_error_bytes => 4_096,
        },
        profiles => [{
            ordinal => 1,
            selection_key =>
                'synthetic|synthetic_family_v1|gate_candidate_v1|objects|-',
            adapter_class => 'Local::GateAdapter',
            adapter_method => 'measure_profile',
            adapter_arguments => {level => 'gate_candidate_v1'},
            report_coordinate_authority => {
                family => 'synthetic_family_v1',
                level => 'gate_candidate_v1',
                primary_axis => 'objects',
                backend_profile => undef,
            },
            provider_requirement => clone($provider),
            workload_identity => $workload_identity,
            correctness_projection_identity => $correctness_identity,
            performance_applicability_identity =>
                'regression-promotion-profile-applicability/' . ('c' x 64),
            environment_identity => environment($common, $provider),
            qualified_budget => {
                status => 'qualified_unpublished',
                formula_authority => 'decision-0056',
                wall_time_ns => 100,
                cpu_time_ns => 200,
                peak_tree_rss_bytes => 300,
            },
        }],
    };
    $availability = {
        availability => 'available',
        reason => undef,
        observed_tool_profile => undef,
    };
}

sub append_marker($kind) {
    open my $fh, '>>', $marker or die "cannot append test marker: $!";
    print {$fh} "$kind:$$\n" or die "cannot write test marker: $!";
    close $fh or die "cannot close test marker: $!";
}

sub marker_lines() {
    return [] unless -e $marker;
    open my $fh, '<', $marker or die "cannot read test marker: $!";
    my @lines = <$fh>;
    close $fh or die "cannot close test marker: $!";
    chomp @lines;
    return \@lines;
}

BEGIN {
    package Local::GateAdapter;
    use v5.20;
    use strict;
    use warnings;
    use POSIX ();

    sub measure_profile {
        main::append_marker('measure');
        die "synthetic\nworker\x{2603}exception\n"
            if $main::adapter_mode eq 'die';
        if ($main::adapter_mode eq 'timeout') {
            select undef, undef, undef, 0.25;
        }
        POSIX::_exit(42) if $main::adapter_mode eq 'exit';
        kill 9, $$ if $main::adapter_mode eq 'signal';
        if ($main::adapter_mode eq 'residue') {
            my $pid = fork();
            die "cannot fork residue fixture\n" unless defined $pid;
            if ($pid == 0) {
                select undef, undef, undef, 5;
                POSIX::_exit(0);
            }
        }
        return main::clone($main::report);
    }

    sub validate_report {
        main::append_marker('validate');
        my $value = main::clone($_[1]{report});
        $value->{outcome} = 'mutated'
            if $main::adapter_mode eq 'validator_mutation';
        return $value;
    }

    sub tool_profile {
        return main::clone($main::common->{tool_profile});
    }
}

BEGIN {
    package Borrowed::GateProfile;
    our @ISA = (
        'FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile'
    );
}

sub with_fixture($code) {
    no warnings 'redefine';
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 80;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 1024;
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract::derive =
        sub { return clone($contract) };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_require_clean_revision =
        sub { return $revision };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_require_unchanged_clean_revision =
        sub { return 1 };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_provider_availability =
        sub { return clone($availability) };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_observe_report =
        sub { return clone($observation) };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionQualification::_gate_correctness_projection =
        sub { return clone($current_correctness_projection) };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract::_qualified_correctness_projection =
        sub { return clone($qualified_correctness_projection) };
    return $code->();
}

sub captured_error($code) {
    my $ok = eval { $code->(); 1 };
    return '' if $ok;
    return $@;
}

reset_fixture();

is_deeply(
    $class->result_keys,
    [qw(
        schema schema_version profile_result_identity contract_identity
        qualification_identity qualification_publication_identity
        qualification_file_set_sha256 ordinal selection_key
        execution_revision report observation observed_environment provider
        performance outcome diagnostics cleanup explicit_nonclaims
    )],
    'profile result exposes one closed field set',
);
is_deeply(
    $class->profile_limits,
    {
        implementation_revision =>
            'regression_promotion_gate_profile_v1',
        maximum_report_bytes => 67_108_864,
        maximum_ipc_bytes => 65_536,
        maximum_error_bytes => 4_096,
        worker_timeout_seconds => 4_000,
        validation_records => 1,
        raw_measurement_records => 3,
        controller_invocations => 4,
    },
    'profile execution limits remain contract-derived and bounded',
);

subtest 'exact environment enforces inclusive maximum budgets' => sub {
    reset_fixture();
    my $result = with_fixture(sub {
        return $class->run({repository_root => $repo, ordinal => 1});
    });
    is($result->{performance}{classification}, 'pass',
        'inclusive equality passes');
    is_deeply($result->{performance}{observed_maximum}, {
        wall_time_ns => 100,
        cpu_time_ns => 200,
        peak_tree_rss_bytes => 300,
    }, 'maximum, not median, is the enforced reduction');
    ok($result->{performance}{comparisons}{wall_time_ns}{within_budget},
        'equal wall threshold is inclusive');
    is($result->{outcome}, 'accepted', 'pass is accepted');
    like($result->{profile_result_identity},
        qr{\Aregression-promotion-gate-profile-result/[0-9a-f]{64}\z},
        'result is content addressed');
    my $lines = marker_lines();
    my @measure = grep { /^measure:/ } @$lines;
    my @validate = grep { /^validate:/ } @$lines;
    is(scalar @measure, 1, 'canonical adapter is invoked exactly once');
    is(scalar @validate, 2, 'child and parent both validate the report');
    my ($worker_pid) = $measure[0] =~ /:(\d+)\z/;
    isnt($worker_pid, $$, 'producer runs in a fresh child');
    my @spools = glob(File::Spec->catfile(
        $repo, '.fsmgen-vial-gate-profile-*',
    ));
    is_deeply(\@spools, [], 'anonymous report spool leaves no path residue');

    $result->{performance}{classification} = 'forged';
    my $again = with_fixture(sub {
        return $class->run({repository_root => $repo, ordinal => 1});
    });
    is($again->{performance}{classification}, 'pass',
        'returned result is defensive');
};

subtest 'exact adjacent threshold fails after correctness' => sub {
    reset_fixture();
    $observation->{observed_maximum}{wall_time_ns} = 101;
    $observation->{accepted_run_totals}[1]{wall_time_ns} = 101;
    my $result = with_fixture(sub {
        return $class->run({repository_root => $repo, ordinal => 1});
    });
    is($result->{performance}{classification}, 'fail',
        'budget plus one fails');
    ok(!$result->{performance}{comparisons}{wall_time_ns}{within_budget},
        'failed metric is explicit');
    is($result->{outcome}, 'performance_failed',
        'performance failure is not reported as pass');
};

subtest 'unmatched environment remains informational' => sub {
    reset_fixture();
    $contract->{profiles}[0]{environment_identity}{host_profile}
        {host_identity} = 'qualified-other-host';
    $contract->{profiles}[0]{environment_identity}{environment_identity} =
        'regression-promotion-environment/' . ('d' x 64);
    $observation->{observed_maximum}{wall_time_ns} = 101;
    $observation->{accepted_run_totals}[1]{wall_time_ns} = 101;
    my $result = with_fixture(sub {
        return $class->run({repository_root => $repo, ordinal => 1});
    });
    is($result->{performance}{classification}, 'informational',
        'unmatched timing is informational even above budget');
    ok(!$result->{performance}{exact_environment},
        'environment mismatch is explicit');
    is($result->{outcome}, 'accepted_informational',
        'correct unmatched execution remains accepted informational');
};

subtest 'correctness rejects before timing' => sub {
    reset_fixture();
    $current_correctness_projection->{stable_value} = 'changed';
    $observation->{correctness_projection_identity} =
        'regression-promotion-correctness/'
        . sha256_hex(canonical($current_correctness_projection));
    $observation->{observed_maximum}{wall_time_ns} = 101;
    my $error = with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    });
    like($error, qr/correctness changed/,
        'correctness identity drift rejects');
    unlike($error, qr/budget|threshold/i,
        'performance is not classified after correctness drift');
};

subtest 'OSVVM process telemetry drift admits only stable correctness' => sub {
    reset_fixture();
    $qualified_correctness_projection = synthetic_stable_projection();
    $current_correctness_projection =
        clone($qualified_correctness_projection);
    ++$current_correctness_projection->{record_projections}[0]
        {artifact_records}[0]{bytes};
    $current_correctness_projection->{record_projections}[0]
        {artifact_records}[0]{sha256} = '5' x 64;
    $current_correctness_projection->{record_projections}[0]
        {correctness_oracles}[0]{evidence_identity} = '6' x 64;
    ++$current_correctness_projection->{record_projections}[0]
        {stage_measurements}[0]{output_counts}{bytes};
    my $qualified_identity = 'regression-promotion-correctness/'
        . sha256_hex(canonical($qualified_correctness_projection));
    my $current_identity = 'regression-promotion-correctness/'
        . sha256_hex(canonical($current_correctness_projection));
    $contract->{profiles}[0]{correctness_projection_identity} =
        $qualified_identity;
    $observation->{correctness_projection_identity} = $current_identity;
    my $result = with_fixture(sub {
        return $class->run({repository_root => $repo, ordinal => 1});
    });
    is(
        $result->{observation}{correctness_projection_identity},
        $qualified_identity,
        'accepted result remains bound to immutable qualified identity',
    );
    is($result->{outcome}, 'accepted',
        'telemetry-only projection drift is accepted before timing');

    ++$current_correctness_projection->{record_projections}[0]
        {stage_measurements}[0]{output_counts}{objects};
    $observation->{correctness_projection_identity} =
        'regression-promotion-correctness/'
        . sha256_hex(canonical($current_correctness_projection));
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/correctness changed after stable projection.*ordinal 1.*synthetic/s,
        'adjacent semantic drift rejects with the profile coordinate');
};

subtest 'portable process telemetry drift admits only stable correctness' => sub {
    reset_fixture();
    $qualified_correctness_projection = synthetic_stable_projection('portable');
    $current_correctness_projection =
        clone($qualified_correctness_projection);
    ++$current_correctness_projection->{record_projections}[0]
        {artifact_records}[0]{bytes};
    $current_correctness_projection->{record_projections}[0]
        {artifact_records}[0]{sha256} = '5' x 64;
    $current_correctness_projection->{record_projections}[0]
        {correctness_oracles}[0]{evidence_identity} = '6' x 64;
    ++$current_correctness_projection->{record_projections}[0]
        {stage_measurements}[0]{output_counts}{bytes};
    my $qualified_identity = 'regression-promotion-correctness/'
        . sha256_hex(canonical($qualified_correctness_projection));
    my $current_identity = 'regression-promotion-correctness/'
        . sha256_hex(canonical($current_correctness_projection));
    $contract->{profiles}[0]{correctness_projection_identity} =
        $qualified_identity;
    $observation->{correctness_projection_identity} = $current_identity;
    my $result = with_fixture(sub {
        return $class->run({repository_root => $repo, ordinal => 1});
    });
    is(
        $result->{observation}{correctness_projection_identity},
        $qualified_identity,
        'portable admission remains bound to immutable qualified identity',
    );
    is($result->{outcome}, 'accepted',
        'portable telemetry-only projection drift is accepted before timing');

    ++$current_correctness_projection->{record_projections}[0]
        {stage_measurements}[0]{output_counts}{objects};
    $observation->{correctness_projection_identity} =
        'regression-promotion-correctness/'
        . sha256_hex(canonical($current_correctness_projection));
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/correctness changed after stable projection.*ordinal 1.*synthetic/s,
        'portable adjacent semantic drift rejects with the profile coordinate');
};

subtest 'portable VHDL process telemetry drift admits only stable correctness' => sub {
    reset_fixture();
    $qualified_correctness_projection =
        synthetic_stable_projection('portable_vhdl');
    $current_correctness_projection =
        clone($qualified_correctness_projection);
    ++$current_correctness_projection->{record_projections}[0]
        {artifact_records}[0]{bytes};
    $current_correctness_projection->{record_projections}[0]
        {artifact_records}[0]{sha256} = '5' x 64;
    $current_correctness_projection->{record_projections}[0]
        {correctness_oracles}[0]{evidence_identity} = '6' x 64;
    ++$current_correctness_projection->{record_projections}[0]
        {stage_measurements}[0]{output_counts}{bytes};
    my $qualified_identity = 'regression-promotion-correctness/'
        . sha256_hex(canonical($qualified_correctness_projection));
    my $current_identity = 'regression-promotion-correctness/'
        . sha256_hex(canonical($current_correctness_projection));
    $contract->{profiles}[0]{correctness_projection_identity} =
        $qualified_identity;
    $observation->{correctness_projection_identity} = $current_identity;
    my $result = with_fixture(sub {
        return $class->run({repository_root => $repo, ordinal => 1});
    });
    is(
        $result->{observation}{correctness_projection_identity},
        $qualified_identity,
        'portable VHDL admission remains bound to immutable qualified identity',
    );
    is($result->{outcome}, 'accepted',
        'portable VHDL telemetry-only drift is accepted before timing');

    ++$current_correctness_projection->{record_projections}[0]
        {stage_measurements}[0]{output_counts}{objects};
    $observation->{correctness_projection_identity} =
        'regression-promotion-correctness/'
        . sha256_hex(canonical($current_correctness_projection));
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/correctness changed after stable projection.*ordinal 1.*synthetic/s,
        'portable VHDL semantic drift rejects with the profile coordinate');
};

subtest 'unavailable exact provider cannot pass' => sub {
    reset_fixture();
    my $tool = {
        logical_name => 'verilator',
        provider_identity => 'qualified_verilator_5_046',
        reported_version => 'synthetic',
        external_verification_tool => bool(1),
    };
    my $required = {
        kind => 'exact_tool_profile',
        external_verification_tool => bool(1),
        logical_name => 'verilator',
        provider_identity => 'qualified_verilator_5_046',
        tool_profile_identity =>
            'tool-profile/' . sha256_hex(canonical($tool)),
    };
    $contract->{profiles}[0]{provider_requirement} = clone($required);
    $availability = {
        availability => 'unavailable',
        reason => 'exact_provider_executable_unavailable',
        observed_tool_profile => undef,
    };
    my $result = with_fixture(sub {
        return $class->run({repository_root => $repo, ordinal => 1});
    });
    is($result->{performance}{classification}, 'unavailable',
        'provider absence is unavailable');
    isnt($result->{performance}{classification}, 'pass',
        'provider absence never passes');
    is($result->{observation}{controller_invocations}, 0,
        'provider absence does not fabricate measurements');
    is_deeply(marker_lines(), [],
        'provider absence invokes no producer or simulator');
};

subtest 'exact provider preflight distinguishes absence from drift' => sub {
    reset_fixture();
    my $tool = {
        logical_name => 'verilator',
        provider_identity => 'qualified_verilator_5_046',
        reported_version => 'Verilator synthetic exact',
        external_verification_tool => bool(1),
    };
    $common->{tool_profile} = clone($tool);
    my $required = {
        kind => 'exact_tool_profile',
        external_verification_tool => bool(1),
        logical_name => 'verilator',
        provider_identity => 'qualified_verilator_5_046',
        tool_profile_identity =>
            'tool-profile/' . sha256_hex(canonical($tool)),
    };
    $contract->{profiles}[0]{provider_requirement} = clone($required);
    no warnings 'redefine';
    local *FSM::VIAL::Backend::ProcessSupervisor::policy = sub { return {} };
    local *FSM::VIAL::Backend::ProcessSupervisor::capture = sub {
        return {
            ok => bool(1),
            exit_code => 0,
            signal => 0,
            output => "Verilator synthetic exact\n",
            timed_out => bool(0),
            output_limited => bool(0),
            exec_failed => bool(0),
        };
    };
    my $available = FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_provider_availability(
        $repo, $contract->{profiles}[0],
    );
    is($available->{availability}, 'available',
        'exact reported provider is available');
    is_deeply($available->{observed_tool_profile}, $tool,
        'exact provider profile is independently observed');

    local *FSM::VIAL::Backend::ProcessSupervisor::capture = sub {
        return {exec_failed => bool(1)};
    };
    my $missing = FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_provider_availability(
        $repo, $contract->{profiles}[0],
    );
    is($missing->{availability}, 'unavailable',
        'missing executable is unavailable');
    is($missing->{reason}, 'exact_provider_executable_unavailable',
        'missing executable has one stable reason');

    local *FSM::VIAL::Backend::ProcessSupervisor::capture = sub {
        return {
            ok => bool(1),
            exit_code => 0,
            signal => 0,
            output => "Verilator foreign\n",
            timed_out => bool(0),
            output_limited => bool(0),
            exec_failed => bool(0),
        };
    };
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_provider_availability(
            $repo, $contract->{profiles}[0],
        );
    }), qr/version identity drifted/,
        'present foreign provider rejects as drift rather than unavailable');

    my $ghdl_tool = {
        logical_name => 'ghdl',
        provider_identity => 'qualified_ghdl_6_0_0_llvm_jit',
        reported_version => 'GHDL synthetic exact',
        external_verification_tool => bool(1),
    };
    $common->{tool_profile} = clone($ghdl_tool);
    $contract->{profiles}[0]{provider_requirement} = {
        kind => 'exact_tool_profile',
        external_verification_tool => bool(1),
        logical_name => 'ghdl',
        provider_identity => 'qualified_ghdl_6_0_0_llvm_jit',
        tool_profile_identity =>
            'tool-profile/' . sha256_hex(canonical($ghdl_tool)),
    };
    my $unmaterialized = FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_provider_availability(
        $repo, $contract->{profiles}[0],
    );
    is($unmaterialized->{availability}, 'unavailable',
        'absent repository-local exact provider is unavailable');
    is($unmaterialized->{reason}, 'exact_provider_not_materialized',
        'unmaterialized provider has one stable reason');
};

subtest 'closed caller and record identities reject substitution' => sub {
    reset_fixture();
    my $guard_error;
    {
        local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
        $guard_error = captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }
    like($guard_error, qr/active repository RAM guard/,
        'absent guard rejects before contract derivation');
    like(captured_error(sub {
        $class->run({
            repository_root => $repo,
            ordinal => 1,
            qualification => {},
        });
    }), qr/unknown key 'qualification'/,
        'caller cannot inject qualification evidence');
    like(captured_error(sub {
        Borrowed::GateProfile->run({repository_root => $repo, ordinal => 1});
    }), qr/exact class invocant/,
        'borrowed invocant rejects');
    my $ordinal = '1';
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => $ordinal});
        });
    }), qr/ordinal is invalid/,
        'numeric-string ordinal rejects');

    $report->{measurement_records}[0]{run_ordinal} = '1';
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/record order changed/,
        'numeric-string record ordinal rejects');
    reset_fixture();
    @{$report->{measurement_records}} = reverse @{$report->{measurement_records}};
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/record order changed/,
        'reordered records reject');
    reset_fixture();
    $report->{measurement_records}[2]{git_revision} = 'f' x 40;
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/mixed host\/tool\/guard\/common identities/,
        'mixed execution revisions reject');
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionQualification
            ->_gate_observation({measurement_set => {}, common_identity => {}});
    }), qr/caller-sealed/,
        'qualification projection seam rejects direct callers');
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionQualification
            ->_gate_correctness_projection({measurement_set => {}});
    }), qr/caller-sealed/,
        'full current correctness seam rejects direct callers');
    like(captured_error(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract
            ->_qualified_correctness_projection({});
    }), qr/caller-sealed/,
        'full qualified correctness seam rejects direct callers');
};

subtest 'worker failures are bounded, sanitized, and contained' => sub {
    reset_fixture();
    $adapter_mode = 'die';
    my $error = with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    });
    like($error, qr/synthetic worker exception/,
        'worker exception is propagated in sanitized form');
    unlike($error, qr/\x{2603}|\nworker/,
        'worker exception removes non-ASCII and line breaks');

    reset_fixture();
    $adapter_mode = 'validator_mutation';
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/adapter changed the report/,
        'adapter report mutation rejects');

    reset_fixture();
    $adapter_mode = 'signal';
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/terminated by signal 9/,
        'worker signal is explicit');

    reset_fixture();
    $adapter_mode = 'exit';
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/returned no result with exit status 42/,
        'worker early exit is explicit');

    reset_fixture();
    $adapter_mode = 'timeout';
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_worker_timeout_seconds =
            sub { 0.02 };
        like(with_fixture(sub {
            return captured_error(sub {
                $class->run({repository_root => $repo, ordinal => 1});
            });
        }), qr/worker timed out/,
            'outer worker timeout is explicit');
    }

    reset_fixture();
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_encode_worker_envelope =
            sub { '{' };
        like(with_fixture(sub {
            return captured_error(sub {
                $class->run({repository_root => $repo, ordinal => 1});
            });
        }), qr/not valid JSON/,
            'malformed worker IPC rejects');
    }

    reset_fixture();
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_encode_worker_envelope =
            sub { 'x' x 65_537 };
        like(with_fixture(sub {
            return captured_error(sub {
                $class->run({repository_root => $repo, ordinal => 1});
            });
        }), qr/exceeded the bounded envelope/,
            'cap-plus-one worker IPC rejects');
    }

    reset_fixture();
    $contract->{result_contract}{maximum_profile_report_bytes} = 1;
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/report exceeds its byte bound/,
        'oversized report rejects before spool publication');

    reset_fixture();
    $adapter_mode = 'residue';
    like(with_fixture(sub {
        return captured_error(sub {
            $class->run({repository_root => $repo, ordinal => 1});
        });
    }), qr/process residue/,
        'worker process-group residue is killed and rejected');
};

done_testing;
