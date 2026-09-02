#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy;

my $class = 'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $source_path = File::Spec->catfile(
    $repo_root, split m{/}, join('/', qw(
        .artifacts qualification vial-scale v1 calibration-closure-v1
        calibration-closure.json
    )),
);

subtest 'policy exposes one caller-sealed promotion contract' => sub {
    is_deeply([sort @{$class->report_keys}], [sort qw(
        schema schema_version policy_identity source_evidence selected_strategy
        alternative_strategy scope_comparison selected_profiles
        capture_contract enforcement_contract explicit_nonclaims
    )], 'promotion policy report has one closed schema');
    is_deeply([sort @{$class->selected_profile_keys}], [sort qw(
        ordinal selection_key authority family level primary_axis
        backend_profile historical_profile_id historical_raw_records
        historical_raw_wall_time_ns historical_maximum_wall_time_ns
        historical_maximum_tree_rss_bytes
    )], 'selected profile rows have one closed schema');
    my $nonclaims = $class->explicit_nonclaims;
    ok((grep { $_ eq 'historical_candidate_budget_is_promoted' } @$nonclaims),
        'historical candidate budgets remain an explicit nonclaim');
    ok((grep { $_ eq 'unavailable_provider_pass' } @$nonclaims),
        'an unavailable exact provider cannot masquerade as a passing gate');

    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->derive({repository_root => $repo_root});
    }), qr/active repository RAM guard/,
        'public derivation requires the repository RAM guard');
    like(dies(sub {
        $class->derive({repository_root => $repo_root, report => {}});
    }), qr/unknown key 'report'/,
        'callers cannot inject historical or current evidence');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy::report_keys(
            'borrowed');
    }), qr/requires the exact class invocant/,
        'borrowed class invocants fail closed');
};

subtest 'performance applicability separates provenance from enforcement' => sub {
    is_deeply([sort @{$class->performance_applicability_keys}], [sort qw(
        schema schema_version applicability_identity refines_policy_schema
        evidence_revision_role exact_environment_fields
        exact_deterministic_fields matching_later_revision
        deterministic_mismatch environment_mismatch unavailable_exact_provider
        recalibration
    )], 'performance applicability has one closed schema');
    my $contract = $class->performance_applicability_contract;
    is($contract->{evidence_revision_role},
        'immutable_qualification_provenance_only',
        'capture revision remains evidence rather than a runtime match field');
    is_deeply($contract->{exact_environment_fields}, [qw(
        host_profile tool_profile resource_guard provider_status
    )], 'host, tool, guard, and provider remain exact');
    is_deeply($contract->{exact_deterministic_fields}, [qw(
        selection_key workload_identity correctness_projection_identity
    )], 'workload and correctness behavior remain exact');
    is($contract->{matching_later_revision},
        'performance_enforcement_eligible_after_correctness',
        'a later revision with identical behavior and environment stays eligible');
    is($contract->{deterministic_mismatch},
        'correctness_rejects_before_performance',
        'deterministic drift rejects rather than borrowing the budget');
    is($contract->{environment_mismatch},
        'correctness_required_performance_informational',
        'environment drift retains correctness with informational performance');
    like($contract->{applicability_identity},
        qr{\Aregression-promotion-performance-applicability/[0-9a-f]{64}\z},
        'the applicability contract is content-addressed');
    like(dies(sub {
        $class->performance_applicability_contract({git_revision => 'forged'});
    }), qr/accepts no caller input/,
        'callers cannot select a weaker applicability identity');

    $contract->{evidence_revision_role} = 'runtime_match_required';
    $contract->{applicability_identity} = undef;
    $contract->{applicability_identity} =
        'regression-promotion-performance-applicability/'
        . sha256_hex($json->encode($contract));
    my $validate = $class->can(
        '_validate_performance_applicability_contract');
    like(dies(sub { $validate->($contract) }),
        qr/evidence revision became an enforcement dimension/,
        'a rehashed revision-match contract still rejects');

    my $fresh = $class->performance_applicability_contract;
    is($fresh->{evidence_revision_role},
        'immutable_qualification_provenance_only',
        'returned applicability data is defensive');
};

subtest 'representative corpus is exact, current-only, and narrower' => sub {
    my $report = read_json($source_path);
    my $derive = $class->can('_derive_from_report');
    my $policy = $derive->($report);

    is($policy->{schema},
        'fsmgen.vial_architecture_scale_regression_promotion_policy.v1',
        'policy schema is versioned');
    like($policy->{policy_identity},
        qr{\Aregression-promotion-policy/[0-9a-f]{64}\z},
        'policy identity is content-addressed');
    is($policy->{policy_identity},
        'regression-promotion-policy/'
        . '19cf41056da86d95c266597e7db76eff3810ee29511a005e1051053009a65ece',
        'the immutable current-corpus capture policy identity is unchanged');
    is($policy->{selected_strategy}{strategy},
        'representative_current_promotion_corpus',
        'representative current corpus is selected');
    ok(!$policy->{selected_strategy}{historical_sample_reuse_allowed},
        'historical samples cannot enter current promotion');
    is($policy->{alternative_strategy}{status},
        'not_selected_for_regression_promotion',
        'complete current recapture remains outside promotion scope');

    is(scalar @{$policy->{selected_profiles}}, 11,
        'eleven exact gate profiles cover the selected routes');
    is_deeply(
        [map { $_->{selection_key} } @{$policy->{selected_profiles}}],
        [
            'semantic_bridge|semantic_catalog_v1|gate_candidate_v1|actions|-',
            'semantic_bridge|bridge_fanout_v1|gate_candidate_v1|backend_bindings|-',
            'execution_checking|execution_graph_v1|gate_candidate_v1|bindings|-',
            'execution_checking|checking_state_v1|gate_candidate_v1|random_occurrences|-',
            'backend_emission|backend_emission_v1|gate_candidate_v1|-|sv_portable_verilator',
            'backend_emission|backend_emission_v1|gate_candidate_v1|-|vhdl_portable_ghdl',
            'backend_emission|backend_emission_v1|gate_candidate_v1|-|vhdl_osvvm_qualified',
            'portable_runtime|runtime_stream_v1|gate_candidate_v1|-|sv_portable_verilator',
            'portable_vhdl_runtime|runtime_stream_v1|gate_candidate_v1|-|vhdl_portable_ghdl',
            'osvvm_runtime|runtime_stream_v1|gate_candidate_v1|-|vhdl_osvvm_qualified',
            'balanced_portable|balanced_portable_v1|gate_candidate_v1|-|sv_portable_verilator',
        ],
        'selection fixes semantic, bridge, execution, checking, backend, runtime, and balanced routes',
    );
    is($policy->{scope_comparison}{historical_complete}
        {raw_measurement_records}, 356,
        'historical complete closure retains all raw records');
    is($policy->{scope_comparison}{representative_current}
        {fresh_raw_measurement_records_required}, 33,
        'current corpus requires three fresh records per selected profile');
    is($policy->{scope_comparison}{representative_current}
        {fresh_total_invocations_required}, 44,
        'current corpus requires validation plus three measurements per profile');
    is($policy->{scope_comparison}{historical_raw_wall_time_ns_reduction},
        4_671_592_497_000,
        'historical comparator records the exact avoided raw wall time');
    ok($policy->{scope_comparison}{comparator_is_not_a_budget},
        'historical timing comparison cannot become a budget');
    is($policy->{capture_contract}{publication_base},
        '.artifacts/qualification/vial-scale/v2',
        'current evidence uses a non-colliding v2 publication base');
    is($policy->{enforcement_contract}{unmatched_common_identity},
        'correctness_required_performance_informational',
        'unmatched hosts retain correctness without enforcing pinned timing');
    is($policy->{enforcement_contract}{unavailable_exact_provider},
        'unavailable_not_pass',
        'provider absence remains explicit instead of passing');

    $policy->{selected_profiles}[0]{authority} = 'mutated';
    my $fresh = $derive->($report);
    is($fresh->{selected_profiles}[0]{authority}, 'semantic_bridge',
        'returned policy data is defensive');
};

subtest 'source and selection mutations fail closed' => sub {
    my $derive = $class->can('_derive_from_report');

    my $changed_timing = read_json($source_path);
    $changed_timing->{profiles}[0]{accepted_run_totals}[0]{wall_time_ns}++;
    like(dies(sub { $derive->($changed_timing) }),
        qr/source metrics changed/,
        'changed historical raw timing invalidates the comparison');

    my $changed_candidate = read_json($source_path);
    my ($actions) = grep {
        ($_->{coordinates}{profile_id} // '') eq
            'semantic-catalog-v1.actions.gate-candidate-v1'
    } @{$changed_candidate->{profiles}};
    $actions->{candidate_budget}{status} = 'promoted';
    like(dies(sub { $derive->($changed_candidate) }),
        qr/not an accepted candidate/,
        'pre-promoted historical evidence is rejected');

    my $duplicate_route = read_json($source_path);
    my ($other) = grep {
        ($_->{coordinates}{profile_id} // '') eq
            'semantic-catalog-v1.imports.gate-candidate-v1'
    } @{$duplicate_route->{profiles}};
    $other->{coordinates}{primary_axis} = 'actions';
    like(dies(sub { $derive->($duplicate_route) }),
        qr/selection must resolve exactly once/,
        'ambiguous route selection is rejected');

    my $missing_route = read_json($source_path);
    my ($binding) = grep {
        ($_->{coordinates}{profile_id} // '') eq
            'execution-graph-v1.bindings.gate-candidate-v1'
    } @{$missing_route->{profiles}};
    $binding->{coordinates}{primary_axis} = 'bindings_changed';
    like(dies(sub { $derive->($missing_route) }),
        qr/selection must resolve exactly once/,
        'missing selected route is rejected');
};

SKIP: {
    skip 'exact guarded publication authentication is opt-in', 5
        unless $ENV{FSMGEN_VIAL_SCALE_PROMOTION_POLICY_EXACT};
    my $policy = $class->derive({repository_root => $repo_root});
    is($policy->{source_evidence}{disposition},
        'explicitly_versioned_historical',
        'exact derivation retains the historical disposition');
    is($policy->{source_evidence}{current_performance_eligible}, 0,
        'historical closure is not current performance evidence');
    is(scalar @{$policy->{selected_profiles}}, 11,
        'exact authenticated derivation returns all selected profiles');
    is($policy->{capture_contract}{profile_count}, 11,
        'capture contract agrees with the selected profile count');
    like($policy->{policy_identity},
        qr{\Aregression-promotion-policy/[0-9a-f]{64}\z},
        'exact authenticated policy remains content-addressed');
}

done_testing;

sub read_json {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $json->decode($bytes);
}

sub dies {
    my ($code) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    return defined($error) ? $error : '';
}
