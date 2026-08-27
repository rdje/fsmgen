#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmission;

my $class = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path(
    'ppif', 'ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(repo_path(
    'vial', 'ahb_subordinate_base_output_arbitration.vial'));

my @artifact_relpaths = qw(
    backends/vhdl_portable_ghdl/backend-manifest.json
    backends/vhdl_portable_ghdl/backend-source-map.json
    backends/vhdl_portable_ghdl/commands/analyze-command.json
    backends/vhdl_portable_ghdl/commands/elaborate-command.json
    backends/vhdl_portable_ghdl/commands/run-command.json
    backends/vhdl_portable_ghdl/evidence/migration-proof.json
    backends/vhdl_portable_ghdl/evidence/review-workflow.json
    backends/vhdl_portable_ghdl/evidence/selected-mapping-matrix.json
    backends/vhdl_portable_ghdl/evidence/source-order.json
    backends/vhdl_portable_ghdl/evidence/static-validation.json
    backends/vhdl_portable_ghdl/evidence/tool-profile.json
    backends/vhdl_portable_ghdl/src/base_output_arbitration_metadata_pkg.vhd
    backends/vhdl_portable_ghdl/src/base_output_arbitration_probe_adapter.vhd
    backends/vhdl_portable_ghdl/src/base_output_arbitration_tb.vhd
    backends/vhdl_portable_ghdl/src/dut/ahb_lite_subordinate.vhd
    backends/vhdl_portable_ghdl/src/fsmgen_vial_runtime_pkg.vhd
    backends/vhdl_portable_ghdl/src/fsmgen_vial_types_pkg.vhd
);
my @source_relpaths = @artifact_relpaths[11 .. 16];
my @static_checks = qw(
    closed_safe_vhdl_source_graph
    required_vhdl_source_roles
    bounded_static_input
    deterministic_vhdl_text_shape
    simulator_and_methodology_neutral_vhdl
    selected_vhdl_portable_semantic_shape
    closed_std_logic_normalization
    typed_four_state_drivers_and_samplers
    single_inactive_edge_semantic_authority
    stable_sample_react_check_drive_order
    complete_rank_scenario_and_fiber_metadata
    deterministic_model_state_and_updates
    declared_source_mapped_probe_adapters
    bounded_scoreboard_queues_and_comparisons
    portable_coverage_counters
    bounded_substitution_fault_seam
    procedural_property_checks_without_psl
    bounded_diagnostics_and_unknown_evidence
    closed_trace_projection
    one_catalogued_snapshot_per_sample_barrier
    normalized_result_manifest_projection
);
my %expected = (
    reference_v1 => {
        operations => 21, source_bytes => 118_064, source_maps => 59,
        metadata_bytes => 15_323,
        metadata_sha256 =>
            '59a4f9e1f8a2c9da6b8c5dd36f255ee1edb0b2bce57264906ab916a9141ba8bc',
    },
    gate_candidate_v1 => {
        operations => 128, source_bytes => 176_433, source_maps => 166,
        metadata_bytes => 73_692,
        metadata_sha256 =>
            '922e1ab962d20c12cf24cdd8222a19b3f39fe958e934bcfb93b6a03974e0c9c9',
    },
    qualification_candidate_v1 => {
        operations => 512, source_bytes => 388_401, source_maps => 550,
        metadata_bytes => 285_660,
        metadata_sha256 =>
            '9c77af56b8241f94c4ca2d9fc23ec73c6ad5582ae709dcb1318d0e6716502d7a',
    },
    limit_v1 => {
        operations => 29_506, source_bytes => 16_777_107,
        source_maps => 29_544, metadata_bytes => 16_674_366,
        metadata_sha256 =>
            '321d67b4d78c8ff4c7921b709d8d156787b442f2a4334754860c80a07c7cb167',
    },
    over_limit_v1 => {operations => 29_507},
);

sub construction {
    my ($level) = @_;
    return $class->construct({
        backend_profile => 'vhdl_portable_ghdl',
        level => $level,
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
    });
}

subtest 'portable-VHDL owns exactly the second selected five-level ladder' => sub {
    my @expected_shapes = (
        map({{backend_profile => 'sv_portable_verilator', level => $_}}
            qw(reference_v1 gate_candidate_v1 qualification_candidate_v1
                limit_v1 over_limit_v1)),
        map({{backend_profile => 'vhdl_portable_ghdl', level => $_}}
            qw(reference_v1 gate_candidate_v1 qualification_candidate_v1
                limit_v1 over_limit_v1)),
        map({{backend_profile => 'vhdl_osvvm_qualified', level => $_}}
            qw(reference_v1 gate_candidate_v1 qualification_candidate_v1
                limit_v1 over_limit_v1)),
        map({{backend_profile => 'sv_uvm_emit.accellera_2020_3_1', level => $_}}
            qw(reference_v1 gate_candidate_v1 qualification_candidate_v1
                limit_v1 over_limit_v1)),
    );
    is_deeply($class->owned_shapes, \@expected_shapes,
        'shared foundation owns only the four completed partitions');
    my $profile_class =
        'FSM::VIAL::ArchitectureScaleBackendEmission::PortableVHDL';
    my $direct = eval { $profile_class->evaluate({}); 1 };
    ok(!$direct, 'caller cannot bypass the shared foundation with forged IR');
    like($@, qr/profile evaluation is caller-sealed/,
        'profile helper rejects external evaluation before inspecting inputs');
};

for my $level (qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
)) {
    subtest "$level follows the canonical portable-VHDL route" => sub {
        my $construction = construction($level);
        ok($construction->{ok}, 'public construction accepts the owned shape');
        is($construction->{specification}{backend_profile},
            'vhdl_portable_ghdl', 'construction retains the exact profile');
        is($construction->{specification}{level}, $level,
            'construction retains the exact level');

        my $built = $class->build({construction => $construction});
        ok($built->{ok}, 'ordinary parser and PlanBuilder accept the route');
        diag($json->encode($built->{diagnostics})) unless $built->{ok};
        is($built->{execution_ir}->as_hashref
                ->{operation_graph}{total_operation_count},
            $expected{$level}{operations},
            'canonical ExecutionIR has the selected operation total');

        my $evaluation = $class->evaluate({construction => $construction});
        ok($evaluation->{ok}, 'the expected backend outcome validates');
        diag($json->encode($evaluation->{diagnostics}))
            unless $evaluation->{ok};
        is_deeply([sort keys %$evaluation],
            [sort @{$class->evaluation_keys}],
            'evaluation remains one closed shared-foundation projection');
        is($evaluation->{status}, 'profile_validated',
            'status records qualification rather than product support');
        is($evaluation->{route_metrics}{operations_total},
            $expected{$level}{operations},
            'report retains the canonical route operation total');
        ok($evaluation->{outcome_contract}{backend_negotiation_executed},
            'the backend negotiation gate executed');
        ok($evaluation->{outcome_contract}{backend_shape_owned},
            'the child slice owns this exact shape');
        ok(!$evaluation->{claims}{capability_claimed}
                && !$evaluation->{claims}{support_claimed}
                && !$evaluation->{claims}{performance_claimed}
                && !$evaluation->{claims}{capacity_claimed}
                && !$evaluation->{claims}{external_runtime_executed},
            'product, performance, capacity, and runtime claims remain false');
        ok(!defined($evaluation->{artifact_oracle}{portable_sv})
                && !defined($evaluation->{artifact_oracle}{osvvm})
                && !defined($evaluation->{artifact_oracle}{native_uvm}),
            'portable-VHDL evaluation cannot claim a sibling profile');

        my $oracle = $evaluation->{artifact_oracle}{portable_vhdl};
        is($oracle->{backend_profile}, 'vhdl_portable_ghdl',
            'portable oracle names the exact backend');
        is($oracle->{level}, $level, 'portable oracle names the exact level');
        is($oracle->{requested_operation_total},
            $expected{$level}{operations},
            'portable oracle names the anchored T value');
        ok($oracle->{byte_equal_rerun},
            'independent backend emissions are byte-identical');
        ok($oracle->{in_memory_only},
            'emission remains a pure in-memory artifact graph');

        if ($level eq 'over_limit_v1') {
            is($evaluation->{observed_outcome}, 'backend_limit_rejected',
                'adjacent shape records the selected earliest rejection');
            ok(!$evaluation->{outcome_contract}{artifacts_emitted},
                'adjacent rejection emits no artifact graph');
            ok(!$evaluation->{claims}{artifact_graph_claimed},
                'adjacent rejection claims no artifact graph');
            is_deeply($oracle->{artifact_relpaths}, [],
                'adjacent rejection contains no artifact path');
            is_deeply($oracle->{source_identities}, [],
                'adjacent rejection contains no source identity');
            is_deeply($oracle->{static_check_identities}, [],
                'adjacent rejection contains no static-check evidence');
            is($oracle->{artifact_count}, 0,
                'adjacent rejection contains zero artifacts');
            is($oracle->{source_artifact_count}, 0,
                'adjacent rejection contains zero sources');
            is($oracle->{source_bytes}, 0,
                'adjacent rejection contains zero generated bytes');
            is($oracle->{source_map_entries}, 0,
                'adjacent rejection contains zero source maps');
            is($oracle->{static_validation_checks}, 0,
                'adjacent rejection contains zero static checks');
            ok($oracle->{atomic_rejection},
                'adjacent rejection is explicitly atomic');
            is_deeply($oracle->{diagnostics}, [{
                code => 'VIAL_VHDL_BACKEND_LIMIT_EXCEEDED',
                severity => 'error',
                message => 'generated VHDL exceeds the 16 MiB backend cap',
                path => '/artifacts',
            }], 'adjacent rejection preserves the exact earliest diagnostic');
        }
        else {
            is($evaluation->{observed_outcome}, 'backend_emitted',
                'accepted shape records successful emission');
            ok($evaluation->{outcome_contract}{artifacts_emitted},
                'accepted shape emits one complete graph');
            ok($evaluation->{claims}{artifact_graph_claimed},
                'qualification claims only the observed artifact graph');
            is_deeply($oracle->{artifact_relpaths}, \@artifact_relpaths,
                'ordered seventeen-artifact inventory is exact');
            is($oracle->{artifact_count}, 17,
                'total artifact inventory is exact');
            is($oracle->{source_artifact_count}, 6,
                'source artifact inventory is exact');
            is($oracle->{source_bytes}, $expected{$level}{source_bytes},
                'six-source byte total is exact');
            is($oracle->{source_map_entries},
                $expected{$level}{source_maps},
                'complete source-map count is exact');
            is($oracle->{mapped_operation_count},
                $expected{$level}{operations},
                'every canonical operation is source-mapped');
            is($oracle->{source_artifact_map_count}, 6,
                'source-map header covers every generated source');
            is($oracle->{static_validation_checks}, 21,
                'twenty-one exact static checks are retained');
            is($oracle->{passed_static_validation_checks}, 21,
                'all twenty-one static checks pass');
            is_deeply($oracle->{static_check_identities}, \@static_checks,
                'static-check identity and order are exact');
            is($oracle->{maximum_generated_identifier_bytes}, 37,
                'maximum generated identifier size is frozen');
            is($oracle->{generated_identifier_limit_bytes}, 255,
                'generated identifiers retain the separate backend bound');
            like($oracle->{artifact_graph_sha256}, qr{\A[0-9a-f]{64}\z},
                'complete artifact graph has one content digest');
            ok(!$oracle->{atomic_rejection},
                'accepted graph is not mislabeled as a rejection');
            is_deeply($oracle->{diagnostics}, [],
                'accepted graph has no emitter diagnostic');
            is_deeply($oracle->{source_identities},
                expected_sources($expected{$level}),
                'all six generated source identities are exact');
        }

        if ($level eq 'reference_v1') {
            my $validated = $class->validate_evaluation({
                construction => $construction,
                evaluation => $evaluation,
            });
            is($json->encode($validated), $json->encode($evaluation),
                'canonical report validates byte-for-byte');
            $evaluation->{artifact_oracle}{portable_vhdl}{source_bytes}++;
            my $mutation = eval {
                $class->validate_evaluation({
                    construction => $construction,
                    evaluation => $evaluation,
                });
                1;
            };
            ok(!$mutation, 'post-identity oracle mutation fails closed');
            like($@, qr/evaluation is not canonical/,
                'oracle mutation rejection names canonical regeneration');
        }
    };
}

subtest 'repository-local staging cleans accepted and rejected routes exactly' => sub {
    for my $level (qw(limit_v1 over_limit_v1)) {
        my $construction = construction($level);
        my $stage_abs = repo_path(split m{/},
            $construction->{staging_identity});
        ok(!-e $stage_abs && !-l $stage_abs,
            "$level staging begins absent");
        my $staged = $class->with_staging({
            repository_root => $repo_root,
            construction => $construction,
            consumer => sub {
                my ($context) = @_;
                ok(-d $context->{staging_root},
                    "$level consumer sees one repository-local stage");
            },
        });
        ok($staged->{ok} && $staged->{same_volume} && $staged->{removed},
            "$level staging succeeds on-volume and reports cleanup");
        ok(!-e $stage_abs && !-l $stage_abs,
            "$level success leaves no content-addressed residue");
    }

    my $construction = construction('reference_v1');
    my $stage_abs = repo_path(split m{/},
        $construction->{staging_identity});
    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub { die "intentional portable-VHDL consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure remains visible');
    ok(!-e $stage_abs && !-l $stage_abs,
        'consumer failure leaves no content-addressed residue');
};

done_testing;

sub expected_sources {
    my ($level) = @_;
    return [
        {
            relpath => $source_relpaths[0], bytes => $level->{metadata_bytes},
            sha256 => $level->{metadata_sha256},
        },
        {
            relpath => $source_relpaths[1], bytes => 591,
            sha256 =>
                '7a7e3b4e81fd222e53e2098653fcf1131f1b58dbeba35698c1cfe67a4fab5b56',
        },
        {
            relpath => $source_relpaths[2], bytes => 46_264,
            sha256 =>
                'bc45987685e0e2fcf1adb5bbb0a20110dbdcc695ee1c556b1bee41c5b953f8d5',
        },
        {
            relpath => $source_relpaths[3], bytes => 47_670,
            sha256 =>
                '8d93b0ade4d9561d19fdd12ab10b4d8ba1a3dc06de9f911d1c0d8d1bf18518cf',
        },
        {
            relpath => $source_relpaths[4], bytes => 2_191,
            sha256 =>
                'de60b5cdbcf2bd2efd9e9ac28938782e3a0df22ca4d7a14183481700f687e1b2',
        },
        {
            relpath => $source_relpaths[5], bytes => 6_025,
            sha256 =>
                '3777706b911ce90c9a3b05107233ec925c1029b175932ed10f1b1a588fb3c08e',
        },
    ];
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
