use v5.20;
use strict;
use warnings;

use lib 'perl';
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use Test::More;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator;
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator';
my $profile_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile';
my $revision = 'a' x 40;
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $repo = tempdir(CLEANUP => 1);
make_path(File::Spec->catdir($repo, '.git'));

sub canonical($value) {
    return $json->encode($value);
}

sub clone($value) {
    return $json->decode($json->encode($value));
}

sub bool($value) {
    return $value ? JSON::PP::true : JSON::PP::false;
}

sub hex_id($label) {
    return sha256_hex($label);
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

sub exact_provider($ordinal) {
    my $tool = {
        logical_name => "synthetic-tool-$ordinal",
        provider_identity => "synthetic-provider-$ordinal",
        reported_version => "synthetic $ordinal",
        external_verification_tool => bool(1),
    };
    return ({
        kind => 'exact_tool_profile',
        external_verification_tool => bool(1),
        logical_name => $tool->{logical_name},
        provider_identity => $tool->{provider_identity},
        tool_profile_identity =>
            'tool-profile/' . sha256_hex(canonical($tool)),
    }, $tool);
}

sub observed_common($ordinal, $tool_override = undef) {
    my $tool = defined($tool_override) ? clone($tool_override) : {
        applicability => 'fsmgen_owned_foundation_only',
        logical_name => "synthetic-worker-$ordinal",
        provider_identity => 'repository_runtime',
        external_verification_tool => bool(0),
    };
    return {
        host_profile => {host_identity => 'synthetic-host'},
        tool_profile => $tool,
        resource_guard => {
            active => bool(1),
            host_max_percent => 80,
            single_descendant_max_mib => 1024,
        },
    };
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

sub fixture($requested = undef) {
    $requested //= {};
    my (@profiles, @results);
    for my $ordinal (1 .. 11) {
        my $classification = $requested->{$ordinal} // 'pass';
        my ($provider, $tool) = $classification eq 'unavailable'
            ? exact_provider($ordinal)
            : (provider_not_applicable(), undef);
        my $common = observed_common($ordinal, $tool);
        my $observed_provider = $classification eq 'unavailable'
            ? undef : $provider;
        my $observed_environment = $classification eq 'unavailable'
            ? undef : environment($common, $observed_provider);
        my $qualified_environment = $classification eq 'informational'
            ? environment({
                %{clone($common)},
                host_profile => {host_identity => 'qualified-other-host'},
            }, $provider)
            : clone($observed_environment);
        my $budget = {
            status => 'qualified_unpublished',
            formula_authority => 'decision-0056',
            wall_time_ns => 100,
            cpu_time_ns => 200,
            peak_tree_rss_bytes => 300,
        };
        my $selection_key = "synthetic-profile-$ordinal";
        my $workload_identity =
            'workload/' . hex_id("workload-$ordinal");
        my $correctness_identity =
            'regression-promotion-correctness/'
            . hex_id("correctness-$ordinal");
        push @profiles, {
            ordinal => $ordinal,
            selection_key => $selection_key,
            adapter_class => 'Local::ForbiddenProducer',
            adapter_method => 'measure_profile',
            adapter_arguments => {ordinal => $ordinal},
            provider_requirement => clone($provider),
            workload_identity => $workload_identity,
            correctness_projection_identity => $correctness_identity,
            environment_identity => $qualified_environment,
            qualified_budget => clone($budget),
        };
        push @results, profile_result({
            ordinal => $ordinal,
            selection_key => $selection_key,
            classification => $classification,
            provider => $provider,
            common => $common,
            observed_environment => $observed_environment,
            budget => $budget,
            workload_identity => $workload_identity,
            correctness_identity => $correctness_identity,
        });
    }
    my $contract = {
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
        execution_contract => {
            profile_count => 11,
            total_validation_records => 11,
            total_raw_measurement_records => 33,
            total_controller_invocations => 44,
        },
        result_contract => {
            schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1',
            profile_schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_gate_profile_result.v1',
            identity_prefix => 'regression-promotion-gate-result/',
            maximum_result_bytes => 1_048_576,
            maximum_profile_report_bytes => 67_108_864,
            maximum_profile_ipc_bytes => 65_536,
            maximum_error_bytes => 4_096,
        },
        profiles => \@profiles,
    };
    for my $index (0 .. $#results) {
        $results[$index]{contract_identity} = $contract->{contract_identity};
        $results[$index]{qualification_identity} =
            $contract->{qualification_evidence}{qualification_identity};
        $results[$index]{qualification_publication_identity} =
            $contract->{qualification_evidence}{publication_identity};
        $results[$index]{qualification_file_set_sha256} =
            $contract->{qualification_evidence}
                {qualification_file_set_sha256};
        rehash_profile($results[$index]);
    }
    return ($contract, \@results);
}

sub profile_result($args) {
    my $classification = $args->{classification};
    my $ordinal = $args->{ordinal};
    my $provider = $args->{provider};
    my $budget = clone($args->{budget});
    my $result = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_gate_profile_result.v1',
        schema_version => 1,
        profile_result_identity => undef,
        contract_identity => undef,
        qualification_identity => undef,
        qualification_publication_identity => undef,
        qualification_file_set_sha256 => undef,
        ordinal => $ordinal,
        selection_key => $args->{selection_key},
        execution_revision => $revision,
        report => undef,
        observation => undef,
        observed_environment => clone($args->{observed_environment}),
        provider => undef,
        performance => undef,
        outcome => undef,
        diagnostics => [],
        cleanup => {
            anonymous_report_spool_removed => bool(1),
            worker_process_residue => bool(0),
        },
        explicit_nonclaims => [qw(
            qualification_evidence qualification_recalibration
            qualification_overwrite historical_artifact_reuse
            support_promotion architecture_scale_capacity
            whole_product_capacity
        )],
    };
    if ($classification eq 'unavailable') {
        my %comparison = map {
            ($_ => {
                observed => undef,
                budget => 0 + $budget->{$_},
                within_budget => undef,
            })
        } qw(wall_time_ns cpu_time_ns peak_tree_rss_bytes);
        $result->{report} = {identity => undef, sha256 => undef, bytes => 0};
        $result->{observation} = {
            validation_records => 0,
            raw_measurement_records => 0,
            controller_invocations => 0,
            sample_exclusions => 0,
            validation_identity => undef,
            raw_measurement_identities => [],
            accepted_run_totals => [],
            observed_maximum => {
                wall_time_ns => undef,
                cpu_time_ns => undef,
                peak_tree_rss_bytes => undef,
            },
            workload_identity => $args->{workload_identity},
            correctness_projection_identity => undef,
        };
        $result->{provider} = {
            requirement => clone($provider),
            availability => 'unavailable',
            reason => 'exact_provider_executable_unavailable',
            observed_tool_profile => undef,
        };
        $result->{performance} = {
            classification => 'unavailable',
            reason => 'exact_provider_unavailable',
            exact_environment => bool(0),
            qualified_budget => $budget,
            observed_maximum => {
                wall_time_ns => undef,
                cpu_time_ns => undef,
                peak_tree_rss_bytes => undef,
            },
            comparisons => \%comparison,
        };
        $result->{outcome} = 'unavailable';
        return $result;
    }
    my $wall = $classification eq 'pass' ? 100 : 101;
    my @identities = map {
        'measurement/' . hex_id("measurement-$ordinal-$_")
    } 1 .. 3;
    my @totals = map {
        +{
            measurement_identity => $identities[$_ - 1],
            run_ordinal => $_,
            wall_time_ns => $_ == 2 ? $wall : 90 + $_,
            cpu_time_ns => 180 + $_,
            peak_tree_rss_bytes => 280 + $_,
        }
    } 1 .. 3;
    my $maximum = {
        wall_time_ns => $wall,
        cpu_time_ns => 183,
        peak_tree_rss_bytes => 283,
    };
    my %comparison = map {
        my $metric = $_;
        my $within = $maximum->{$metric} <= $budget->{$metric};
        ($metric => {
            observed => $maximum->{$metric},
            budget => 0 + $budget->{$metric},
            within_budget => bool($within),
        })
    } qw(wall_time_ns cpu_time_ns peak_tree_rss_bytes);
    $result->{report} = {
        identity => 'synthetic-report/' . hex_id("report-$ordinal"),
        sha256 => hex_id("report-bytes-$ordinal"),
        bytes => 100 + $ordinal,
    };
    $result->{observation} = {
        validation_records => 1,
        raw_measurement_records => 3,
        controller_invocations => 4,
        sample_exclusions => 0,
        validation_identity =>
            'measurement/' . hex_id("validation-$ordinal"),
        raw_measurement_identities => \@identities,
        accepted_run_totals => \@totals,
        observed_maximum => clone($maximum),
        workload_identity => $args->{workload_identity},
        correctness_projection_identity => $args->{correctness_identity},
    };
    $result->{provider} = {
        requirement => clone($provider),
        availability => 'available',
        reason => undef,
        observed_tool_profile =>
            clone($args->{common}{tool_profile}),
    };
    $result->{performance} = {
        classification => $classification,
        reason => $classification eq 'informational'
            ? 'environment_identity_mismatch'
            : $classification eq 'fail'
                ? 'exceeded_qualified_budget'
                : 'within_inclusive_qualified_budget',
        exact_environment => $classification eq 'informational'
            ? bool(0) : bool(1),
        qualified_budget => $budget,
        observed_maximum => clone($maximum),
        comparisons => \%comparison,
    };
    $result->{outcome} = $classification eq 'fail'
        ? 'performance_failed'
        : $classification eq 'informational'
            ? 'accepted_informational' : 'accepted';
    return $result;
}

sub rehash_profile($profile) {
    $profile->{profile_result_identity} = undef;
    $profile->{profile_result_identity} =
        'regression-promotion-gate-profile-result/'
        . sha256_hex(canonical($profile));
    return $profile;
}

sub captured_error($code) {
    my $ok = eval { $code->(); 1 };
    return '' if $ok;
    return $@;
}

sub run_fixture($contract, $results, $options = undef) {
    $options //= {};
    my @ordinals;
    my $contract_calls = 0;
    my $unchanged_calls = 0;
    no warnings 'redefine';
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 80;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 1024;
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract::derive =
        sub { ++$contract_calls; return clone($contract) };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator::_require_clean_revision =
        sub { return $revision };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator::_require_unchanged_clean_revision =
        sub {
            ++$unchanged_calls;
            die "synthetic repository mutation\n"
                if defined($options->{mutation_check})
                    && $unchanged_calls == $options->{mutation_check};
            return 1;
        };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_run_for_coordinator =
        sub {
            my ($invocant, $request) = @_;
            die "synthetic child failure\n"
                if defined($options->{child_failure})
                    && $request->{ordinal} == $options->{child_failure};
            push @ordinals, $request->{ordinal};
            if ($options->{contract_mutation}
                    && $request->{ordinal} == 2) {
                $request->{contract}{contract_identity} =
                    'regression-promotion-gate-contract/' . ('f' x 64);
            }
            if ($options->{post_worker_mutation}
                    && $request->{ordinal} == 2) {
                $results->[0]{outcome} = 'mutated-after-admission';
            }
            return $options->{malformed}
                && $request->{ordinal} == 1
                    ? []
                    : $options->{oversized}
                        && $request->{ordinal} == 1
                        ? {
                            %{clone($results->[0])},
                            oversized => 'x' x 65_536,
                        }
                        : $results->[$request->{ordinal} - 1];
        };
    my $result = $class->run({repository_root => $repo});
    return ($result, \@ordinals, $contract_calls);
}

BEGIN {
    package Borrowed::GateCoordinator;
    our @ISA = (
        'FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator'
    );
}

BEGIN {
    package FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator;
    sub _test_profile_execution_seam {
        return FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile
            ->_run_for_coordinator($_[0]);
    }
}

is_deeply($class->result_keys, [qw(
    schema schema_version gate_result_identity contract_identity
    qualification_identity qualification_publication_identity
    qualification_file_set_sha256 execution_revision coordinator_revision
    summary profiles classification outcome diagnostics cleanup
    explicit_nonclaims
)], 'aggregate result exposes one closed field set');
is_deeply($class->coordination_limits, {
    implementation_revision => 'regression_promotion_gate_coordinator_v1',
    maximum_result_bytes => 1_048_576,
    maximum_profile_ipc_bytes => 65_536,
    profile_count => 11,
    validation_records => 11,
    raw_measurement_records => 33,
    controller_invocations => 44,
    sample_exclusions => 0,
}, 'coordination limits retain the complete frozen workload');

subtest 'public API is root-only, guarded, and caller-sealed' => sub {
    my ($contract, $results) = fixture();
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    like(captured_error(sub {
        $class->run({repository_root => $repo});
    }), qr/requires the active repository RAM guard/,
        'public coordination requires the active guard');
    like(captured_error(sub {
        $class->run({repository_root => $repo, contract => {}});
    }), qr/unknown key 'contract'/,
        'callers cannot inject a contract');
    like(captured_error(sub {
        Borrowed::GateCoordinator->run({repository_root => $repo});
    }), qr/requires the exact class invocant/,
        'borrowed coordinator invocants reject');
    like(captured_error(sub {
        $profile_class->_run_for_coordinator({});
    }), qr/coordinator execution is caller-sealed/,
        'profile execution seam rejects direct callers');
    like(captured_error(sub {
        $profile_class->_admit_for_coordinator({});
    }), qr/coordinator admission is caller-sealed/,
        'profile admission seam rejects direct callers');

    my $authorized_calls = 0;
    no warnings 'redefine';
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 80;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 1024;
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_require_unchanged_clean_revision =
        sub { return 1 };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateProfile::_run_authorized =
        sub { ++$authorized_calls; return clone($results->[0]) };
    my $profile =
        FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator::_test_profile_execution_seam({
                repository_root => $repo,
                ordinal => 1,
                contract => $contract,
                execution_revision => $revision,
            });
    is($authorized_calls, 1,
        'the exact coordinator reaches the shared authorized worker path');
    is($profile->{ordinal}, 1,
        'the coordinator seam returns the selected defensive result');
};

subtest 'eleven ordered workers yield one complete in-memory pass' => sub {
    my ($contract, $results) = fixture();
    my ($result, $ordinals, $contract_calls) =
        run_fixture($contract, $results);
    is($contract_calls, 1, 'the authenticated contract is derived once');
    is_deeply($ordinals, [1 .. 11],
        'each ordinal is delegated exactly once in plan order');
    is_deeply(
        [@{$result->{summary}}{qw(
            profile_count observed_validation_records
            observed_raw_measurement_records
            observed_controller_invocations sample_exclusions
            passed_profiles failed_profiles informational_profiles
            unavailable_profiles
        )}],
        [11, 11, 33, 44, 0, 11, 0, 0, 0],
        'complete evidence and classification counts are exact',
    );
    ok($result->{summary}{complete_observation},
        'all required observations are complete');
    is($result->{classification}, 'pass',
        'eleven passing profiles aggregate to pass');
    is($result->{outcome}, 'accepted', 'pass is accepted');
    like($result->{gate_result_identity},
        qr{\Aregression-promotion-gate-result/[0-9a-f]{64}\z},
        'aggregate is content addressed');
    cmp_ok(length(canonical($result)), '<=', 1_048_576,
        'aggregate stays inside the result ceiling');
    ok(!-e File::Spec->catdir($repo, '.artifacts'),
        'coordination publishes no result or calibration evidence');

    $result->{classification} = 'forged';
    my ($again) = run_fixture($contract, $results);
    is($again->{classification}, 'pass',
        'returned aggregate state is defensive');
};

subtest 'aggregate precedence is fail then unavailable then informational' => sub {
    my @cases = (
        [{3 => 'informational'}, 'informational', 11, 33, 44],
        [{2 => 'unavailable', 3 => 'informational'},
            'unavailable', 10, 30, 40],
        [{1 => 'fail', 2 => 'unavailable', 3 => 'informational'},
            'fail', 10, 30, 40],
    );
    for my $case (@cases) {
        my ($requested, $expected, $validations, $measurements, $invocations) =
            @$case;
        my ($contract, $results) = fixture($requested);
        my ($result) = run_fixture($contract, $results);
        is($result->{classification}, $expected,
            "$expected has exact aggregate precedence");
        is_deeply(
            [@{$result->{summary}}{qw(
                observed_validation_records
                observed_raw_measurement_records
                observed_controller_invocations
            )}],
            [$validations, $measurements, $invocations],
            "$expected retains honest observed counts",
        );
        is_deeply(
            [@{$result->{summary}}{qw(
                required_validation_records
                required_raw_measurement_records
                required_controller_invocations
            )}],
            [11, 33, 44],
            "$expected retains the complete required workload",
        );
    }
};

subtest 'profile order, identity, environment, and classification reject' => sub {
    my @mutations = (
        ['reordered profile', sub {
            @{$_[1]}[0, 1] = @{$_[1]}[1, 0];
        }, qr/result dispatch changed|profile order changed/],
        ['duplicate profile', sub {
            $_[1][1] = clone($_[1][0]);
        }, qr/result dispatch changed|identity is duplicated/],
        ['mixed contract', sub {
            $_[1][4]{contract_identity} =
                'regression-promotion-gate-contract/' . ('f' x 64);
            rehash_profile($_[1][4]);
        }, qr/evidence identity changed/],
        ['mixed qualification', sub {
            $_[1][4]{qualification_identity} =
                'regression-promotion-qualification/' . ('f' x 64);
            rehash_profile($_[1][4]);
        }, qr/evidence identity changed/],
        ['mixed qualification file set', sub {
            $_[1][4]{qualification_file_set_sha256} = 'f' x 64;
            rehash_profile($_[1][4]);
        }, qr/evidence identity changed/],
        ['mixed revision', sub {
            $_[1][4]{execution_revision} = 'f' x 40;
            rehash_profile($_[1][4]);
        }, qr/result dispatch changed/],
        ['mixed host', sub {
            $_[1][4]{observed_environment}{host_profile}{host_identity} =
                'other-observed-host';
            $_[1][4]{observed_environment}{environment_identity} = undef;
            $_[1][4]{observed_environment}{environment_identity} =
                'regression-promotion-environment/'
                . sha256_hex(canonical(
                    $_[1][4]{observed_environment},
                ));
            $_[0]{profiles}[4]{environment_identity} =
                clone($_[1][4]{observed_environment});
            rehash_profile($_[1][4]);
        }, qr/mixed host or guard state/],
        ['provider forgery', sub {
            $_[1][4]{provider}{availability} = 'unavailable';
            rehash_profile($_[1][4]);
        }, qr/profile result changed|available profile result changed/],
        ['classification forgery', sub {
            $_[1][4]{performance}{classification} = 'fail';
            $_[1][4]{outcome} = 'performance_failed';
            rehash_profile($_[1][4]);
        }, qr/performance classification changed/],
        ['threshold forgery', sub {
            $_[1][4]{performance}{comparisons}{wall_time_ns}
                {within_budget} = bool(0);
            rehash_profile($_[1][4]);
        }, qr/performance classification changed/],
        ['sample exclusion', sub {
            $_[1][4]{observation}{sample_exclusions} = 1;
            rehash_profile($_[1][4]);
        }, qr/available profile result changed/],
        ['worker residue', sub {
            $_[1][4]{cleanup}{worker_process_residue} = bool(1);
            rehash_profile($_[1][4]);
        }, qr/profile cleanup changed/],
    );
    for my $mutation (@mutations) {
        my ($name, $change, $expected) = @$mutation;
        my ($contract, $results) = fixture();
        $change->($contract, $results);
        like(captured_error(sub {
            run_fixture($contract, $results);
        }), $expected, "$name rejects");
    }
};

subtest 'malformed, oversized, failed, mutated, and dirty workers reject' => sub {
    my ($contract, $results) = fixture();
    like(captured_error(sub {
        run_fixture($contract, $results, {malformed => 1});
    }), qr/worker result is malformed/,
        'malformed worker result rejects');

    ($contract, $results) = fixture();
    like(captured_error(sub {
        run_fixture($contract, $results, {oversized => 1});
    }), qr/worker result exceeds its bound/,
        'oversized worker result rejects before admission');

    ($contract, $results) = fixture();
    pop @$results;
    like(captured_error(sub {
        run_fixture($contract, $results);
    }), qr/worker result is malformed/,
        'missing worker profile rejects');

    ($contract, $results) = fixture();
    like(captured_error(sub {
        run_fixture($contract, $results, {child_failure => 6});
    }), qr/synthetic child failure/,
        'profile child failure rejects the aggregate');

    ($contract, $results) = fixture();
    like(captured_error(sub {
        run_fixture($contract, $results, {post_worker_mutation => 1});
    }), qr/worker evidence mutated/,
        'post-admission worker evidence mutation rejects');

    ($contract, $results) = fixture();
    like(captured_error(sub {
        run_fixture($contract, $results, {contract_mutation => 1});
    }), qr/contract mutated during worker execution/,
        'worker-side contract mutation rejects immediately');

    ($contract, $results) = fixture();
    like(captured_error(sub {
        run_fixture($contract, $results, {mutation_check => 4});
    }), qr/synthetic repository mutation/,
        'repository mutation rejects between profile workers');

    ($contract, $results) = fixture();
    push @{$contract->{profiles}}, clone($contract->{profiles}[10]);
    like(captured_error(sub {
        run_fixture($contract, $results);
    }), qr/contract workload changed/,
        'extra contract profile rejects before worker execution');
};

done_testing;
