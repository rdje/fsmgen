#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALArchitectureScaleRegressionContract qw(
    build_vial_architecture_scale_regression_contract
    vial_architecture_scale_regression_contract_keys
    vial_architecture_scale_regression_contract_source
);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::LanguageSurfaceContract qw(
    language_surface_vial_tooling_keys
);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::Support::VIALVHDLEmissionContract qw(
    build_vial_vhdl_emission_contract
);
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract;
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore;
use FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy;
use FSM::VIAL::ArchitectureScaleRegressionPromotionQualification;
use FSM::VIAL::Tool qw(vial_tool_capabilities);

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $bundle = File::Spec->catdir(
    $repo_root, qw(vial qualification regression_promotion_gate evidence-v1),
);
my $transport = read_json('transport-manifest.json');
my $qualification_publication = read_json(
    qw(payload regression-promotion-budget-qualification-v1 current
        regression-promotion-budget-qualification.json),
);
my $qualification = $qualification_publication->{qualification};
my $contract = build_vial_architecture_scale_regression_contract();

subtest 'bounded discovery surface is explicit and defensive' => sub {
    is_deeply(
        [sort keys %{$contract}],
        [sort @{vial_architecture_scale_regression_contract_keys()}],
        'architecture-scale regression contract has exactly the public keys',
    );
    is(
        $contract->{contract_source},
        vial_architecture_scale_regression_contract_source(),
        'contract names its support owner',
    );
    is(
        $contract->{capability},
        'vial.architecture_scale.regression_gate.v1',
        'public discovery names the bounded architecture-scale regression gate',
    );
    is($contract->{status}, 'shipped_bounded_regression_gate',
        'status claims the gate rather than general capacity');
    like(
        dies(sub {
            build_vial_architecture_scale_regression_contract({});
        }),
        qr/accepts no arguments/,
        'callers cannot inject evidence into the discovery snapshot',
    );

    my $fresh = build_vial_architecture_scale_regression_contract();
    $contract->{profiles}[0]{qualified_budget}{wall_time_ns} = 0;
    $contract->{evidence}{qualification_identity} = 'mutated';
    is_deeply(
        build_vial_architecture_scale_regression_contract(),
        $fresh,
        'repeated builds return independent contract graphs',
    );
    $contract = $fresh;
};

subtest 'tracked immutable evidence owns every profile and budget' => sub {
    my $corpus = $transport->{source_seals}{corpus};
    my $qualification_seal = $transport->{source_seals}{qualification};
    is($contract->{schemas}{evidence_transport}, $transport->{schema},
        'transport schema joins the tracked bundle');
    is($contract->{evidence}{transport_identity},
        $transport->{bundle_identity}, 'transport identity joins');
    is($contract->{evidence}{corpus_identity},
        $corpus->{corpus_identity}, 'corpus identity joins');
    is($contract->{evidence}{corpus_publication_identity},
        $corpus->{publication_identity}, 'corpus publication joins');
    is($contract->{evidence}{corpus_file_set_sha256},
        $corpus->{file_set_sha256}, 'corpus file set joins');
    is($contract->{evidence}{qualification_identity},
        $qualification_seal->{qualification_identity},
        'qualification identity joins');
    is($contract->{evidence}{qualification_publication_identity},
        $qualification_seal->{publication_identity},
        'qualification publication joins');
    is($contract->{evidence}{qualification_file_set_sha256},
        $qualification_seal->{file_set_sha256},
        'qualification file set joins');
    is($contract->{evidence}{qualification_report_identity},
        $qualification_publication->{publication_report_identity},
        'qualification report identity joins');
    is($contract->{evidence}{capture_revision},
        $qualification->{source_evidence}{capture_revision},
        'capture revision joins');
    is($contract->{evidence}{qualification_publisher_revision},
        $qualification_publication->{publisher_revision},
        'qualification publisher revision joins');

    my @expected_profiles = map {
        {
            ordinal => $_->{ordinal},
            selection_key => $_->{selection_key},
            workload_identity => $_->{workload_identity},
            correctness_projection_identity =>
                $_->{correctness_projection_identity},
            environment_identity =>
                $_->{environment_identity}{environment_identity},
            provider_requirement => $_->{provider_status},
            qualified_budget => $_->{qualified_budget},
        }
    } @{$qualification->{profiles}};
    is_deeply($contract->{profiles}, \@expected_profiles,
        'all eleven public rows exactly project immutable qualification');
    is_deeply(
        [map { $_->{ordinal} } @{$contract->{profiles}}],
        [1 .. 11],
        'profile order is complete and unique',
    );
    is_deeply(
        $contract->{topology},
        {
            profile_workers => 11,
            validation_records_per_profile => 1,
            raw_measurement_records_per_profile => 3,
            controller_invocations_per_profile => 4,
            total_validation_records => 11,
            total_raw_measurement_records => 33,
            total_controller_invocations => 44,
            sample_exclusions => 0,
        },
        'public topology keeps the qualified 11/33/44 contract',
    );
    is_deeply(
        $qualification->{summary},
        {
            profile_count => $contract->{topology}{profile_workers},
            qualified_profiles => $contract->{topology}{profile_workers},
            validation_records =>
                $contract->{topology}{total_validation_records},
            raw_measurement_records =>
                $contract->{topology}{total_raw_measurement_records},
            controller_invocations =>
                $contract->{topology}{total_controller_invocations},
            sample_exclusions => $contract->{topology}{sample_exclusions},
        },
        'topology independently joins the qualification summary',
    );
};

subtest 'host, guard, provider, and variability policy stay exact' => sub {
    my $first_environment =
        $qualification->{profiles}[0]{environment_identity};
    for my $profile (@{$qualification->{profiles}}) {
        is_deeply(
            $profile->{environment_identity}{host_profile},
            $first_environment->{host_profile},
            "profile $profile->{ordinal} uses the common pinned host",
        );
        is_deeply(
            $profile->{environment_identity}{resource_guard},
            $first_environment->{resource_guard},
            "profile $profile->{ordinal} uses the common pinned guard",
        );
    }
    is_deeply(
        $contract->{qualified_reference_environment}{host_profile},
        $first_environment->{host_profile},
        'public host envelope is the exact qualified host',
    );
    is_deeply(
        $contract->{qualified_reference_environment}{resource_guard},
        $first_environment->{resource_guard},
        'public guard envelope is the exact qualified guard',
    );

    my $policy_class =
        'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy';
    my $applicability = $policy_class->performance_applicability_contract;
    is_deeply(
        $qualification->{performance_applicability},
        $applicability,
        'tracked qualification embeds the executable variability policy',
    );
    for my $key (keys %{$applicability}) {
        is_deeply(
            $contract->{performance_applicability}{$key},
            $applicability->{$key},
            "public variability field $key joins executable policy",
        );
    }
    is($contract->{performance_applicability}{exact_environment},
        'maximum_each_metric_inclusive_qualified_budget_pass_or_fail',
        'exact environments enforce every maximum inclusively');
    is($contract->{performance_applicability}{present_provider_drift},
        'fail', 'present but wrong providers reject');

    my $qualification_class =
        'FSM::VIAL::ArchitectureScaleRegressionPromotionQualification';
    is(
        $qualification_class->formula->{authority},
        $contract->{profiles}[0]{qualified_budget}{formula_authority},
        'every public budget names the executable formula authority',
    );
    my $vhdl = build_vial_vhdl_emission_contract();
    my %providers = map {
        $_->{provider_identity} => $_
    } @{$contract->{qualified_reference_environment}{provider_profiles}};
    is(
        $providers{external_exact_osvvm_2026_05}{revision},
        $vhdl->{library_materialization}{root_commit},
        'OSVVM provider revision joins the capability authority',
    );
    for my $ordinal (8 .. 10) {
        my $requirement =
            $qualification->{profiles}[$ordinal - 1]{provider_status};
        is_deeply(
            $providers{$requirement->{provider_identity}}
                {tool_profile_identity},
            $requirement->{tool_profile_identity},
            "runtime profile $ordinal exposes its exact tool identity",
        );
    }
};

subtest 'gate storage, cadence, and claims expose no capacity shortcut' => sub {
    my $gate_contract =
        'FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract';
    my $gate_store =
        'FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore';
    my $limits = $gate_contract->contract_limits;
    my $store = $gate_store->publication_limits;
    is($contract->{latest_result}{maximum_bytes},
        $limits->{maximum_result_bytes},
        'latest-result ceiling joins the executable gate contract');
    is($contract->{latest_result}{maximum_bytes},
        $store->{maximum_result_bytes},
        'latest-result ceiling joins the executable store');
    is($contract->{latest_result}{publication_relative_path},
        $store->{publication_relative_path},
        'latest-result path joins the executable store');
    ok(!$contract->{latest_result}{qualification_evidence},
        'replaceable results cannot become qualification evidence');
    is($contract->{cadence}{performance_override}, 'none',
        'discovery exposes no performance bypass');
    ok(!$contract->{supported_claim}{support_promotion},
        'regression capability does not promote product support');
    ok(!$contract->{supported_claim}{capacity_claim},
        'regression capability does not claim capacity');

    my %nonclaim = map { $_ => 1 } @{$contract->{explicit_nonclaims}};
    for my $required (qw(
        architecture_scale_capacity whole_product_big
        whole_product_really_big multi_unit multi_domain mixed_language
        native_uvm_runtime full_language synthesis arbitrary_tool_capacity
        support_promotion general_cross_backend_parity
    )) {
        ok($nonclaim{$required}, "$required remains an explicit nonclaim");
    }
};

subtest 'both capability entrypoints publish the exact aggregate record' => sub {
    my $tooling = build_vial_tooling_contract();
    is_deeply($tooling->{architecture_scale_regression}, $contract,
        'VIAL capabilities embed the canonical regression contract');
    is_deeply(vial_tool_capabilities(), $tooling,
        'public VIAL API publishes the complete tooling contract');
    ok(scalar(grep {
        $_ eq 'vial.architecture_scale.regression_gate.v1'
    } @{$tooling->{capabilities}}), 'VIAL capability list names the gate');
    ok(!scalar(grep { $_ eq 'scale' } @{$tooling->{explicit_nonclaims}}),
        'ambiguous aggregate scale nonclaim is removed');
    ok(scalar(grep { $_ eq 'architecture_scale_capacity' }
        @{$tooling->{explicit_nonclaims}}),
        'aggregate capabilities deny architecture-scale capacity precisely');
    ok(scalar(grep { $_ eq 'architecture_scale_regression' }
        @{language_surface_vial_tooling_keys()}),
        'language-surface schema owns the nested regression record');
    is_deeply(
        build_capability_manifest()
            ->{language_surface}{vial_tooling}
            {architecture_scale_regression},
        $contract,
        'complete capability manifest embeds the same public record',
    );

    my @vial_entries = grep {
        ($_->{source_kind} // '') eq 'vial'
    } regression_corpus_entries();
    ok(@vial_entries >= 6, 'existing VIAL support entries remain present');
    for my $entry (@vial_entries) {
        ok(scalar(grep { $_ eq 'scale' }
            @{$entry->{explicit_nonclaims} || []}),
            "$entry->{id} keeps its narrower fixture scale nonclaim");
    }
};

done_testing();

sub read_json {
    my (@relative) = @_;
    my $path = File::Spec->catfile($bundle, @relative);
    open my $handle, '<:raw', $path
        or die "cannot open $path: $!\n";
    local $/;
    my $bytes = <$handle>;
    close $handle or die "cannot close $path: $!\n";
    return JSON::PP->new->utf8(1)->decode($bytes);
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return '' if $ok;
    return $@;
}
