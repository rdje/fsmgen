#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;
use FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $policy_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionPolicy';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $source_path = File::Spec->catfile(
    $repo_root, split m{/}, join('/', qw(
        .artifacts qualification vial-scale v1 calibration-closure-v1
        calibration-closure.json
    )),
);

subtest 'plan exposes one caller-sealed metadata-only contract' => sub {
    is_deeply([sort @{$class->report_keys}], [sort qw(
        schema schema_version plan_identity policy_identity publication_base
        publication_id publication_schema worker_count
        controller_invocations_per_worker total_validation_records
        total_raw_measurement_records total_controller_invocations entries
        explicit_nonclaims
    )], 'capture plan has one closed report schema');
    is_deeply([sort @{$class->entry_keys}], [sort qw(
        ordinal selection_key coordinates worker_ordinal adapter_class
        adapter_method repository_root_binding adapter_arguments
        producer_authority producer_authority_identity provider_requirement
        report_coordinate_authority applicability_requirement
        validation_records raw_measurement_records controller_invocations
        publication_relative_path
    )], 'dispatch entries have one closed schema');
    my $nonclaims = $class->explicit_nonclaims;
    ok((grep { $_ eq 'simulator_execution' } @{$nonclaims}),
        'simulator execution is an explicit nonclaim');
    ok((grep { $_ eq 'publication_transaction' } @{$nonclaims}),
        'publication remains outside dispatch derivation');

    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->derive({repository_root => $repo_root});
    }), qr/active repository RAM guard/,
        'public derivation inherits guarded policy authentication');
    like(dies(sub {
        $class->derive({repository_root => $repo_root, policy => {}});
    }), qr/unknown key 'policy'/,
        'callers cannot inject policy or evidence');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan::report_keys(
            'borrowed');
    }), qr/requires the exact class invocant/,
        'borrowed class invocants fail closed');
};

subtest 'eleven selected profiles map to exact public dispatch' => sub {
    plan skip_all => 'ignored calibration closure is absent on a fresh checkout'
        unless -f $source_path;
    my $plan = derive_plan();
    is($plan->{schema},
        'fsmgen.vial_architecture_scale_regression_promotion_capture_plan.v2',
        'capture plan schema is versioned');
    is($plan->{schema_version}, 2,
        'the mandatory report-coordinate authority advances the schema');
    like($plan->{plan_identity},
        qr{\Aregression-promotion-capture-plan/[0-9a-f]{64}\z},
        'capture plan identity is content-addressed');
    is($plan->{publication_base},
        '.artifacts/qualification/vial-scale/v2',
        'publication stays below the independent v2 base');
    is($plan->{publication_id}, 'regression-promotion-corpus-v1',
        'publication identity is exact');
    is($plan->{worker_count}, 11,
        'one guard-visible worker owns each selected profile');
    is($plan->{controller_invocations_per_worker}, 4,
        'each worker owns validation plus three measurements');
    is($plan->{total_validation_records}, 11,
        'plan requires eleven validations');
    is($plan->{total_raw_measurement_records}, 33,
        'plan requires 33 raw measurement records');
    is($plan->{total_controller_invocations}, 44,
        'plan requires 44 common-controller invocations');

    my @expected_dispatch = (
        [qw(FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement measure_profile)],
        [qw(FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement measure_member)],
    );
    is_deeply(
        [map { [@{$_}{qw(adapter_class adapter_method)}] }
            @{$plan->{entries}}],
        \@expected_dispatch,
        'all seven current adapters use only their public measurement methods',
    );
    is_deeply(
        [map { $_->{adapter_arguments} } @{$plan->{entries}}],
        [
            {family => 'semantic_catalog_v1', level => 'gate_candidate_v1',
                primary_axis => 'actions'},
            {family => 'bridge_fanout_v1', level => 'gate_candidate_v1',
                primary_axis => 'backend_bindings'},
            {family => 'execution_graph_v1', level => 'gate_candidate_v1',
                primary_axis => 'bindings'},
            {family => 'checking_state_v1', level => 'gate_candidate_v1',
                primary_axis => 'random_occurrences'},
            {backend_profile => 'sv_portable_verilator',
                level => 'gate_candidate_v1'},
            {backend_profile => 'vhdl_portable_ghdl',
                level => 'gate_candidate_v1'},
            {backend_profile => 'vhdl_osvvm_qualified',
                level => 'gate_candidate_v1'},
            {level => 'gate_candidate_v1'},
            {level => 'gate_candidate_v1'},
            {level => 'gate_candidate_v1'},
            {},
        ],
        'every adapter receives one exact closed non-root argument set',
    );
    my @expected_report_coordinates = (
        {family => 'semantic_catalog_v1', level => 'gate_candidate_v1',
            primary_axis => 'actions', backend_profile => undef},
        {family => 'bridge_fanout_v1', level => 'gate_candidate_v1',
            primary_axis => 'backend_bindings', backend_profile => undef},
        {family => 'execution_graph_v1', level => 'gate_candidate_v1',
            primary_axis => 'bindings', backend_profile => undef},
        {family => 'checking_state_v1', level => 'gate_candidate_v1',
            primary_axis => 'random_occurrences', backend_profile => undef},
        {family => 'backend_emission_v1', level => 'gate_candidate_v1',
            primary_axis => 'artifact_graph',
            backend_profile => 'sv_portable_verilator'},
        {family => 'backend_emission_v1', level => 'gate_candidate_v1',
            primary_axis => 'artifact_graph',
            backend_profile => 'vhdl_portable_ghdl'},
        {family => 'backend_emission_v1', level => 'gate_candidate_v1',
            primary_axis => 'artifact_graph',
            backend_profile => 'vhdl_osvvm_qualified'},
        {family => 'runtime_stream_v1', level => 'gate_candidate_v1',
            primary_axis => 'runtime_trace_records',
            backend_profile => 'sv_portable_verilator'},
        {family => 'runtime_stream_v1', level => 'gate_candidate_v1',
            primary_axis => 'runtime_trace_records',
            backend_profile => 'vhdl_portable_ghdl'},
        {family => 'runtime_stream_v1', level => 'gate_candidate_v1',
            primary_axis => 'runtime_trace_records',
            backend_profile => 'vhdl_osvvm_qualified'},
        {family => 'balanced_portable_v1', level => 'gate_candidate_v1',
            primary_axis => 'interaction_profile',
            backend_profile => 'sv_portable_verilator'},
    );
    is_deeply(
        [map {
            my $authority = $_->{report_coordinate_authority};
            +{map { $_ => $authority->{$_} }
                qw(family level primary_axis backend_profile)}
        } @{$plan->{entries}}],
        \@expected_report_coordinates,
        'producer-owned report coordinates preserve all eleven real axes',
    );
    for my $entry (@{$plan->{entries}}) {
        is_deeply(
            [sort keys %{$entry->{report_coordinate_authority}}],
            [sort qw(
                authority_identity family level primary_axis backend_profile
            )],
            "route $entry->{ordinal} report-coordinate authority is closed",
        );
        like($entry->{report_coordinate_authority}{authority_identity},
            qr{\Areport-coordinate-authority/[0-9a-f]{64}\z},
            "route $entry->{ordinal} report-coordinate authority is authenticated",
        );
    }
    is_deeply(
        [map { $_->{repository_root_binding} } @{$plan->{entries}}],
        [('validated_capture_repository_root') x 11],
        'the coordinator root is bound symbolically rather than persisted',
    );
    is_deeply(
        [map { $_->{ordinal} } @{$plan->{entries}}],
        [1 .. 11],
        'dispatch order is exact and contiguous',
    );
    is_deeply(
        [map { $_->{worker_ordinal} } @{$plan->{entries}}],
        [1 .. 11],
        'worker order equals policy order',
    );
    is(scalar(grep {
        $_->{provider_requirement}{kind} eq 'exact_tool_profile'
    } @{$plan->{entries}}), 3,
        'three runtime routes require exact external tool profiles');
    is_deeply(
        [map { $_->{provider_requirement}{provider_identity} }
            grep { $_->{provider_requirement}{kind} eq 'exact_tool_profile' }
            @{$plan->{entries}}],
        [qw(
            qualified_verilator_5_046
            qualified_ghdl_6_0_0_llvm_jit
            qualified_osvvm_2026_05_ghdl_6_0_0_llvm_jit
        )],
        'runtime prerequisites bind all three exact provider identities',
    );
    is(scalar(grep {
        $_->{provider_requirement}{kind} eq 'repository_materialization'
    } @{$plan->{entries}}), 1,
        'the structural OSVVM route binds its repository materialization');
    is(scalar(grep {
        $_->{provider_requirement}{kind} eq 'not_applicable'
    } @{$plan->{entries}}), 7,
        'seven provider-free routes remain explicit');
    ok(!scalar(grep {
        $_->{publication_relative_path} !~
            m{\A[.]artifacts/qualification/vial-scale/v2/}
            || $_->{publication_relative_path} =~ m{/v1/}
    } @{$plan->{entries}}),
        'every publication coordinate is repository-relative v2 state');
};

subtest 'derivation reads metadata but executes no work' => sub {
    plan skip_all => 'ignored calibration closure is absent on a fresh checkout'
        unless -f $source_path;
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement::measure_profile =
        sub { die "semantic producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement::measure_profile =
        sub { die "execution producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement::measure_profile =
        sub { die "backend producer executed\n" };
    local *FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::measure_profile =
        sub { die "portable runtime executed\n" };
    local *FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement::measure_profile =
        sub { die "portable VHDL runtime executed\n" };
    local *FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::measure_profile =
        sub { die "OSVVM runtime executed\n" };
    local *FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement::measure_member =
        sub { die "balanced producer executed\n" };
    local *FSM::VIAL::ArchitectureScaleMeasurement::measure =
        sub { die "measurement controller executed\n" };

    my $plan = derive_plan();
    is($plan->{worker_count}, 11,
        'pure metadata derivation succeeds while every work entry point dies');
};

subtest 'policy and adapter drift fail closed' => sub {
    plan skip_all => 'ignored calibration closure is absent on a fresh checkout'
        unless -f $source_path;
    my $derive = $class->can('_derive_from_policy');

    my $missing = derive_policy();
    pop @{$missing->{selected_profiles}};
    rehash_policy($missing);
    like(dies(sub { $derive->($missing) }),
        qr/selected profile inventory changed/,
        'a missing coordinate is rejected');

    my $duplicate = derive_policy();
    $duplicate->{selected_profiles}[1]{selection_key} =
        $duplicate->{selected_profiles}[0]{selection_key};
    rehash_policy($duplicate);
    like(dies(sub { $derive->($duplicate) }),
        qr/selected profile is duplicated/,
        'a duplicate coordinate is rejected');

    my $unknown = derive_policy();
    $unknown->{selected_profiles}[0]{authority} = 'unknown';
    $unknown->{selected_profiles}[0]{family} = 'unknown';
    $unknown->{selected_profiles}[0]{primary_axis} = undef;
    $unknown->{selected_profiles}[0]{selection_key} =
        'unknown|unknown|gate_candidate_v1|-|-';
    rehash_policy($unknown);
    like(dies(sub { $derive->($unknown) }),
        qr/selected profile order changed/,
        'an unsupported coordinate is rejected');

    my $inconsistent = derive_policy();
    $inconsistent->{selected_profiles}[0]{authority} = 'forged_authority';
    rehash_policy($inconsistent);
    like(dies(sub { $derive->($inconsistent) }),
        qr/key disagrees with coordinates/,
        'a rehashed inconsistent selection key is rejected');

    my $historical_path = derive_policy();
    $historical_path->{capture_contract}{publication_base} =
        '.artifacts/qualification/vial-scale/v1';
    rehash_policy($historical_path);
    like(dies(sub { $derive->($historical_path) }),
        qr/publication contract changed/,
        'a revision-1 publication path is rejected');

    {
        no warnings qw(once redefine);
        my $original =
            FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement
                ->family_authorities;
        $original->{semantic_catalog_v1}{stage_order} = [qw(construct)];
        local *FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement::family_authorities =
            sub { return $original };
        like(dies(sub { $derive->(derive_policy()) }),
            qr/producer authority changed/,
            'current producer-authority drift is rejected');
    }

    {
        no warnings 'redefine';
        my $original =
            FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement
                ->tool_profile;
        $original->{provider_identity} = 'forged-provider';
        local *FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::tool_profile =
            sub { return $original };
        like(dies(sub { $derive->(derive_policy()) }),
            qr/exact tool profile changed/,
            'exact provider drift is rejected');
    }

    for my $control (
        ['changed', {
            family => 'backend_emission_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'foreign_axis',
            backend_profile => 'sv_portable_verilator',
        }, qr/report coordinate authority changed/],
        ['missing', {
            family => 'backend_emission_v1',
            level => 'gate_candidate_v1',
            backend_profile => 'sv_portable_verilator',
        }, qr/report coordinates is missing 'primary_axis'/],
        ['extra', {
            family => 'backend_emission_v1',
            level => 'gate_candidate_v1',
            primary_axis => 'artifact_graph',
            backend_profile => 'sv_portable_verilator',
            caller_coordinate => 'forged',
        }, qr/report coordinates contains unknown key 'caller_coordinate'/],
    ) {
        my ($name, $coordinates, $expected) = @{$control};
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement::report_coordinates =
            sub { return $json->decode($json->encode($coordinates)) };
        like(dies(sub { $derive->(derive_policy()) }), $expected,
            "producer report-coordinate $name drift is rejected");
    }

    my $validate_plan = $class->can('_validate_plan');
    {
        my $forged = derive_plan();
        $forged->{entries}[4]{report_coordinate_authority}{primary_axis} =
            'foreign_axis';
        rehash_report_authority($forged->{entries}[4]);
        rehash_plan($forged);
        like(dies(sub { $validate_plan->($forged) }),
            qr/report-coordinate authority is invalid/,
            'a rehashed plan cannot forge producer report coordinates');
    }
    {
        my $forged = derive_plan();
        $forged->{entries}[4]{report_coordinate_authority}
            {authority_identity} =
                'report-coordinate-authority/' . ('0' x 64);
        rehash_plan($forged);
        like(dies(sub { $validate_plan->($forged) }),
            qr/report-coordinate authority is invalid/,
            'a rehashed plan cannot forge report-coordinate identity');
    }
    {
        my $aliased = derive_plan();
        ok(!defined($aliased->{entries}[4]{coordinates}{primary_axis}),
            'backend selection deliberately retains its nullable policy axis');
        is($aliased->{entries}[4]{report_coordinate_authority}{primary_axis},
            'artifact_graph',
            'the producer report axis is independently non-null');
    }
};

subtest 'returned plans are defensive and deterministic' => sub {
    plan skip_all => 'ignored calibration closure is absent on a fresh checkout'
        unless -f $source_path;
    my $first = derive_plan();
    my $identity = $first->{plan_identity};
    my $path = $first->{entries}[0]{publication_relative_path};
    $first->{entries}[0]{adapter_arguments}{family} = 'mutated';
    $first->{entries}[0]{report_coordinate_authority}{primary_axis} =
        'mutated';
    $first->{entries}[0]{publication_relative_path} = 'mutated';

    my $second = derive_plan();
    is($second->{plan_identity}, $identity,
        'repeated derivation has one stable identity');
    is($second->{entries}[0]{adapter_arguments}{family},
        'semantic_catalog_v1',
        'nested adapter arguments are defensive');
    is($second->{entries}[0]{report_coordinate_authority}{primary_axis},
        'actions', 'report-coordinate authority is defensive');
    is($second->{entries}[0]{publication_relative_path}, $path,
        'publication coordinates are defensive');
};

SKIP: {
    skip 'exact guarded publication authentication is opt-in', 5
        unless $ENV{FSMGEN_VIAL_SCALE_PROMOTION_CAPTURE_PLAN_EXACT};
    my $plan = $class->derive({repository_root => $repo_root});
    is($plan->{worker_count}, 11,
        'exact authenticated plan returns all workers');
    is($plan->{total_validation_records}, 11,
        'exact authenticated plan requires every validation');
    is($plan->{total_raw_measurement_records}, 33,
        'exact authenticated plan requires every raw measurement');
    is($plan->{total_controller_invocations}, 44,
        'exact authenticated plan requires every controller invocation');
    like($plan->{plan_identity},
        qr{\Aregression-promotion-capture-plan/[0-9a-f]{64}\z},
        'exact authenticated plan remains content-addressed');
}

done_testing;

sub derive_plan {
    my $derive = $class->can('_derive_from_policy');
    return $derive->(derive_policy());
}

sub derive_policy {
    die "cannot read $source_path: ignored calibration closure is absent\n"
        unless -f $source_path;
    my $report = read_json($source_path);
    my $derive = $policy_class->can('_derive_from_report');
    return $derive->($report);
}

sub rehash_policy {
    my ($policy) = @_;
    $policy->{policy_identity} = undef;
    $policy->{policy_identity} = 'regression-promotion-policy/'
        . sha256_hex($json->encode($policy));
}

sub rehash_report_authority {
    my ($entry) = @_;
    my $authority = $entry->{report_coordinate_authority};
    $authority->{authority_identity} = undef;
    $authority->{authority_identity} = 'report-coordinate-authority/'
        . sha256_hex($json->encode($authority));
}

sub rehash_plan {
    my ($plan) = @_;
    $plan->{plan_identity} = undef;
    $plan->{plan_identity} = 'regression-promotion-capture-plan/'
        . sha256_hex($json->encode($plan));
}

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
