#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::BackendEmissionAuthority qw(
    backend_emission_profile_authorities
);

my $class = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path(
    'ppif', 'ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(repo_path(
    'vial', 'ahb_subordinate_base_output_arbitration.vial'));
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my @applicable_oracles = qw(
    construct semantic bridge plan emit failure
);
my @oracle_slots = qw(portable_sv portable_vhdl osvvm native_uvm);
my %profile = (
    sv_portable_verilator => {
        slot => 'portable_sv',
        oracle => 'portable_sv_artifact_graph_v1',
        emitted => [@levels[0 .. 3]],
        rejected => ['over_limit_v1'],
        adjacent => 'over_limit_v1',
        adjacent_operations => 6_320,
        rejection_outcome => 'backend_limit_rejected',
        rejection_code => 'VIAL_BACKEND_LIMIT_EXCEEDED',
        rejection_path => '/artifacts',
        reference => {
            artifact_count => 8,
            source_artifact_count => 3,
            source_bytes => 164_093,
            source_map_entries => 54,
            mapped_operation_count => 21,
            maximum_generated_identifier_bytes => 113,
            observed_outcome => 'backend_emitted',
        },
    },
    vhdl_portable_ghdl => {
        slot => 'portable_vhdl',
        oracle => 'portable_vhdl_artifact_graph_v1',
        emitted => [@levels[0 .. 3]],
        rejected => ['over_limit_v1'],
        adjacent => 'over_limit_v1',
        adjacent_operations => 29_509,
        rejection_outcome => 'backend_limit_rejected',
        rejection_code => 'VIAL_VHDL_BACKEND_LIMIT_EXCEEDED',
        rejection_path => '/artifacts',
        reference => {
            artifact_count => 17,
            source_artifact_count => 6,
            source_bytes => 116_560,
            source_map_entries => 59,
            mapped_operation_count => 21,
            static_validation_checks => 20,
            maximum_generated_identifier_bytes => 37,
            observed_outcome => 'backend_emitted',
        },
    },
    vhdl_osvvm_qualified => {
        slot => 'osvvm',
        oracle => 'vhdl_osvvm_qualified_artifact_graph_v1',
        emitted => [@levels[0 .. 3]],
        rejected => ['over_limit_v1'],
        adjacent => 'over_limit_v1',
        adjacent_operations => 29_509,
        rejection_outcome => 'portable_foundation_limit_rejected',
        rejection_code => 'VIAL_OSVVM_PORTABLE_FOUNDATION_ERROR',
        rejection_path => '/portable_foundation',
        reference => {
            artifact_count => 16,
            source_artifact_count => 7,
            source_bytes => 120_911,
            source_map_entries => 66,
            mapped_operation_count => 21,
            static_validation_checks => 12,
            maximum_generated_identifier_bytes => 37,
            observed_outcome => 'backend_emitted',
        },
    },
    'sv_uvm_emit.accellera_2020_3_1' => {
        slot => 'native_uvm',
        oracle => 'native_uvm_selected_review_artifact_graph_v1',
        emitted => ['reference_v1'],
        rejected => [@levels[1 .. 4]],
        adjacent => 'gate_candidate_v1',
        adjacent_operations => 22,
        rejection_outcome => 'backend_negotiation_rejected',
        rejection_code => 'VIAL_UVM_BACKEND_UNSUPPORTED',
        rejection_path => '/negotiation',
        reference => {
            artifact_count => 16,
            source_artifact_count => 10,
            source_bytes => 138_345,
            source_map_entries => 75,
            mapped_operation_count => 6,
            static_validation_checks => 14,
            maximum_generated_identifier_bytes => 49,
            observed_outcome => 'backend_emitted_review_only',
        },
    },
);
my @profiles = qw(
    sv_portable_verilator
    vhdl_portable_ghdl
    vhdl_osvvm_qualified
    sv_uvm_emit.accellera_2020_3_1
);
my %reference_construction;
my %reference_evaluation;
my %adjacent_construction;

sub construction {
    my ($backend_profile, $level) = @_;
    return $class->construct({
        backend_profile => $backend_profile,
        level => $level,
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
    });
}

subtest 'catalog and authority close the exact twenty-outcome partition' => sub {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my $authorities = backend_emission_profile_authorities();
    is_deeply([sort keys %{$catalog->{backend_profiles}}],
        [sort @profiles], 'catalog contains exactly the four selected profiles');
    is_deeply($catalog->{levels}, \@levels,
        'catalog contains the exact five-level ladder');

    my @expected_owned = map {
        my $backend_profile = $_;
        map {{backend_profile => $backend_profile, level => $_}} @levels;
    } @profiles;
    is_deeply($class->owned_shapes, \@expected_owned,
        'shared ownership is exactly four profiles by five levels');

    my (@emitted, @rejected);
    for my $backend_profile (@profiles) {
        my $contract = $profile{$backend_profile};
        push @emitted,
            map { "$backend_profile/$_" } @{$contract->{emitted}};
        push @rejected,
            map { "$backend_profile/$_" } @{$contract->{rejected}};
        for my $level (@levels) {
            my $first = construction($backend_profile, $level);
            my $second = construction($backend_profile, $level);
            ok($first->{ok}, "$backend_profile/$level constructs");
            is($json->encode($second), $json->encode($first),
                "$backend_profile/$level construction is byte-identical");
            is($first->{specification}{family}, 'backend_emission_v1',
                "$backend_profile/$level remains in the exact family");
            is($first->{specification}{primary_axis}, 'artifact_graph',
                "$backend_profile/$level remains on the exact axis");
            is_deeply($first->{specification}{applicable_oracles},
                \@applicable_oracles,
                "$backend_profile/$level retains the complete oracle route");
            is_deeply(
                $first->{specification}{requested_counts}{backend_authority},
                $authorities->{$backend_profile},
                "$backend_profile/$level derives the exact shared authority",
            );
        }
    }
    is_deeply(\@emitted, [
        map({"sv_portable_verilator/$_"} @levels[0 .. 3]),
        map({"vhdl_portable_ghdl/$_"} @levels[0 .. 3]),
        map({"vhdl_osvvm_qualified/$_"} @levels[0 .. 3]),
        'sv_uvm_emit.accellera_2020_3_1/reference_v1',
    ], 'family contract selects exactly thirteen emitted outcomes');
    is_deeply(\@rejected, [
        'sv_portable_verilator/over_limit_v1',
        'vhdl_portable_ghdl/over_limit_v1',
        'vhdl_osvvm_qualified/over_limit_v1',
        map({"sv_uvm_emit.accellera_2020_3_1/$_"} @levels[1 .. 4]),
    ], 'family contract selects exactly seven atomic rejections');
};

subtest 'each profile independently proves reference and adjacent outcomes' => sub {
    for my $backend_profile (@profiles) {
        subtest $backend_profile => sub {
            my $contract = $profile{$backend_profile};
            for my $case (
                ['reference_v1', $contract->{reference}{observed_outcome}, 1],
                [$contract->{adjacent}, $contract->{rejection_outcome}, 0],
            ) {
                my ($level, $outcome, $emitted) = @$case;
                my $constructed = construction($backend_profile, $level);
                my $evaluation = $class->evaluate({
                    construction => $constructed,
                });
                ok($evaluation->{ok}, "$level validates the expected outcome");
                diag($json->encode($evaluation->{diagnostics}))
                    unless $evaluation->{ok};
                is($evaluation->{status}, 'profile_validated',
                    "$level remains qualification-only");
                is($evaluation->{observed_outcome}, $outcome,
                    "$level retains its profile-local outcome");
                like($evaluation->{evaluation_identity},
                    qr{\Abackend-emission-evaluation/[0-9a-f]{64}\z},
                    "$level has one content-addressed evaluation");
                like($evaluation->{rerun_identity},
                    qr{\Arerun/[0-9a-f]{64}\z},
                    "$level has one independent route-rerun identity");
                is_deeply(
                    $evaluation->{requested_counts}{backend_authority},
                    backend_emission_profile_authorities()
                        ->{$backend_profile},
                    "$level evaluation retains exact authority",
                );
                is($evaluation->{artifact_oracle}{oracle},
                    $contract->{oracle}, "$level selects one exact oracle");
                my $oracle = $evaluation->{artifact_oracle}
                    {$contract->{slot}};
                ok(defined($oracle), "$level publishes its profile oracle");
                for my $slot (@oracle_slots) {
                    next if $slot eq $contract->{slot};
                    is($evaluation->{artifact_oracle}{$slot}, undef,
                        "$level cannot claim sibling oracle $slot");
                }
                ok($oracle->{byte_equal_rerun},
                    "$level independent emissions are byte-identical");
                ok($oracle->{in_memory_only},
                    "$level remains a pure in-memory emission outcome");
                ok($evaluation->{outcome_contract}
                        {backend_negotiation_executed}
                    && $evaluation->{outcome_contract}{backend_shape_owned},
                    "$level traverses negotiation under owned shape authority");
                is($evaluation->{outcome_contract}{artifacts_emitted} ? 1 : 0,
                    $emitted, "$level artifact-publication state is exact");
                ok($evaluation->{claims}{qualification_only}
                        && $evaluation->{claims}{backend_shape_owned}
                        && !$evaluation->{claims}{capability_claimed}
                        && !$evaluation->{claims}{support_claimed}
                        && !$evaluation->{claims}{performance_claimed}
                        && !$evaluation->{claims}{capacity_claimed}
                        && !$evaluation->{claims}{external_runtime_executed},
                    "$level retains every family nonclaim");
                is_deeply($evaluation->{explicit_nonclaims},
                    FSM::VIAL::ArchitectureScaleWorkload->catalog
                        ->{explicit_nonclaims},
                    "$level retains the closed catalog nonclaim set");

                if ($emitted) {
                    for my $field (sort keys %{$contract->{reference}}) {
                        next if $field eq 'observed_outcome';
                        is($oracle->{$field},
                            $contract->{reference}{$field},
                            "$level freezes reference $field");
                    }
                    ok(!$oracle->{atomic_rejection},
                        "$level is not mislabeled as rejected");
                    is_deeply($oracle->{diagnostics}, [],
                        "$level has no backend diagnostic");
                    $reference_construction{$backend_profile} = $constructed;
                    $reference_evaluation{$backend_profile} = $evaluation;
                }
                else {
                    is($evaluation->{route_metrics}{operations_total},
                        $contract->{adjacent_operations},
                        "$level reaches the exact adjacent operation total");
                    ok($oracle->{atomic_rejection},
                        "$level rejection is explicitly atomic");
                    ok(!$evaluation->{claims}{artifact_graph_claimed},
                        "$level claims no artifact graph");
                    for my $field (qw(
                        artifact_count source_artifact_count source_bytes
                        source_map_entries mapped_operation_count
                        maximum_generated_identifier_bytes
                    )) {
                        is($oracle->{$field}, 0,
                            "$level rejection retains zero $field");
                    }
                    is($oracle->{diagnostics}[0]{code},
                        $contract->{rejection_code},
                        "$level retains the exact rejection code");
                    is($oracle->{diagnostics}[0]{path},
                        $contract->{rejection_path},
                        "$level retains the earliest rejection path");
                    $adjacent_construction{$backend_profile} = $constructed;
                }
            }
        };
    }
};

subtest 'hostile callers and mutations cannot cross family boundaries' => sub {
    my %profile_class = (
        sv_portable_verilator =>
            'FSM::VIAL::ArchitectureScaleBackendEmission::PortableSV',
        vhdl_portable_ghdl =>
            'FSM::VIAL::ArchitectureScaleBackendEmission::PortableVHDL',
        vhdl_osvvm_qualified =>
            'FSM::VIAL::ArchitectureScaleBackendEmission::OSVVM',
        'sv_uvm_emit.accellera_2020_3_1' =>
            'FSM::VIAL::ArchitectureScaleBackendEmission::NativeUVM',
    );
    for my $backend_profile (@profiles) {
        my $direct = eval { $profile_class{$backend_profile}->evaluate({}); 1 };
        ok(!$direct, "$backend_profile helper is caller-sealed");
        like($@, qr/(?:profile|OSVVM|native-UVM) evaluation is caller-sealed/,
            "$backend_profile helper rejects direct family bypass");
    }

    my $unknown = eval {
        $class->construct({
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
            family_report => {},
        });
        1;
    };
    ok(!$unknown, 'caller-created family evidence cannot enter construction');
    like($@, qr/unknown key 'family_report'/,
        'closed construction names hostile family evidence');

    my $forged_construction = clone_json(
        $reference_construction{sv_portable_verilator});
    my ($vial) = grep { $_->{role} eq 'vial_source' }
        @{$forged_construction->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval {
        $class->evaluate({construction => $forged_construction});
        1;
    };
    ok(!$accepted, 'post-identity source mutation fails closed');
    like($@, qr/construction is not canonical/,
        'source mutation rejection names canonical regeneration');

    my $forged_evaluation = clone_json(
        $reference_evaluation{sv_portable_verilator});
    $forged_evaluation->{claims}{support_claimed} = JSON::PP::true;
    my $validated = eval {
        $class->validate_evaluation({
            construction =>
                $reference_construction{sv_portable_verilator},
            evaluation => $forged_evaluation,
        });
        1;
    };
    ok(!$validated, 'post-identity support mutation fails closed');
    like($@, qr/evaluation is not canonical/,
        'report mutation rejection names canonical regeneration');
};

subtest 'same-volume staging cleans every profile and consumer failure' => sub {
    for my $backend_profile (@profiles) {
        for my $constructed (
            $reference_construction{$backend_profile},
            $adjacent_construction{$backend_profile},
        ) {
            my $level = $constructed->{specification}{level};
            my $stage_abs = repo_path(split m{/},
                $constructed->{staging_identity});
            ok(!-e $stage_abs && !-l $stage_abs,
                "$backend_profile/$level stage begins absent");
            my $staged = $class->with_staging({
                repository_root => $repo_root,
                construction => $constructed,
                consumer => sub {
                    my ($context) = @_;
                    ok(-d $context->{staging_root},
                        "$backend_profile/$level consumer sees the stage");
                },
            });
            ok($staged->{ok} && $staged->{same_volume}
                    && $staged->{removed},
                "$backend_profile/$level stage is same-volume and removed");
            ok(!-e $stage_abs && !-l $stage_abs,
                "$backend_profile/$level leaves no staging residue");
        }
    }

    my $constructed =
        $reference_construction{'sv_uvm_emit.accellera_2020_3_1'};
    my $stage_abs = repo_path(split m{/},
        $constructed->{staging_identity});
    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $constructed,
        consumer => sub { die "intentional family consumer failure\n" },
    });
    ok(!$failed->{ok}, 'family consumer failure remains visible');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure retains its stable diagnostic');
    ok(!-e $stage_abs && !-l $stage_abs,
        'consumer failure leaves no repository-volume residue');
};

done_testing;

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub repo_path {
    return File::Spec->catfile($repo_root, @_);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}
