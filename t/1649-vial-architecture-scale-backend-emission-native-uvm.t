#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $class = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $profile_class =
    'FSM::VIAL::ArchitectureScaleBackendEmission::NativeUVM';
my $backend_class = 'FSM::VIAL::Backend::SVUVMAccellera2020_3_1';
my $profile = 'sv_uvm_emit.accellera_2020_3_1';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1 limit_v1
    over_limit_v1
);
my $reference_hial = slurp_raw(repo_path(
    'ppif', 'ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(repo_path(
    'vial', 'ahb_subordinate_base_output_arbitration.vial'));
my @artifact_relpaths = qw(
    backends/sv_uvm_emit.accellera_2020_3_1/backend-manifest.json
    backends/sv_uvm_emit.accellera_2020_3_1/backend-source-map.json
    backends/sv_uvm_emit.accellera_2020_3_1/evidence/methodology-profile.json
    backends/sv_uvm_emit.accellera_2020_3_1/evidence/review-workflow.json
    backends/sv_uvm_emit.accellera_2020_3_1/evidence/selected-mapping-matrix.json
    backends/sv_uvm_emit.accellera_2020_3_1/evidence/static-validation.json
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_checking_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_if.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_notifications_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_services_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_sva_checker.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/base_output_arbitration_tb.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/dut/ahb-lite-subordinate.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/fsmgen_vial_uvm_components_pkg.sv
    backends/sv_uvm_emit.accellera_2020_3_1/src/fsmgen_vial_uvm_types_pkg.sv
);
my @static_checks = qw(
    closed_safe_artifact_graph required_source_roles bounded_input
    deterministic_text_shape simulator_neutral_source
    balanced_generated_constructs selected_uvm_foundation_shape
    selected_notification_interception_shape
    selected_lifecycle_topology_shape selected_stimulus_service_shape
    selected_checking_result_shape selected_bound_sva_shape
    selected_tlm_factory_config_ral_wiring root_owned_objection_policy
);
my @mapping_ids = qw(
    mapping/active-agent-driver mapping/analysis-tlm
    mapping/bound-sva-properties mapping/bounded-scoreboard
    mapping/complete-component-topology mapping/component-bases
    mapping/constrained-decision-replay mapping/declared-fault-interception
    mapping/dut-binding mapping/event-models mapping/fixture-config
    mapping/fixture-environment mapping/fixture-test
    mapping/functional-coverage mapping/lifecycle-execution
    mapping/notification-interception mapping/ral-preview
    mapping/result-collection mapping/scenario-sequences
    mapping/scoped-factory-configuration mapping/structured-diagnostics
    mapping/timed-interface mapping/top mapping/transaction-items
    mapping/typed-context
);
my @workflow_stages = qw(
    regenerate byte_compare static_shape visual_review defect_capture
    experimental_compile qualified_runtime
);
my @source_identities = (
    identity($artifact_relpaths[6], 12_061,
        '95d357b400fdc0de288127c21b4fa5e6aa6f7705ca25fb1d7bd98dffcad6ecd1'),
    identity($artifact_relpaths[7], 920,
        'ff0c9a77f2d4b523b6a39befd99fbac47fbec7670a2c355058ba1352373cfa28'),
    identity($artifact_relpaths[8], 17_020,
        'b8d7c392e91728bce5003c7dfc59cf71bc52c79151ca2ef3cd7f40bad5008000'),
    identity($artifact_relpaths[9], 34_481,
        'b8106068cc4e575fc54c42a69fb14a28c3853c68e023a87aa26616079c22de67'),
    identity($artifact_relpaths[10], 9_999,
        '085f636d502a8d9941252d1280c91add416861e6473582b97117faa6bf7ef98e'),
    identity($artifact_relpaths[11], 920,
        '28897c83fcc8d6ff2472958c828f032de761a2b756921e409d0938b8c3e2a0f7'),
    identity($artifact_relpaths[12], 1_099,
        'b7bd24c204605d88c4a75a6ae1debecdf4b80e5c3f51b00bca975becb98f5bdf'),
    identity($artifact_relpaths[13], 57_531,
        'eeaa8a687a3a1ce010446f848ca6785538dd907e4c567a91ee6049cc4e079f82'),
    identity($artifact_relpaths[14], 1_759,
        'bcc02c2564ed999e7e42eb29c0d72ad48162a261e41495bed7ab5e7a61c08e42'),
    identity($artifact_relpaths[15], 2_555,
        '38adc9b28875bc5b1d27a8118cb7460c0792609b6af41eee7ec32a4b7f6e61b4'),
);

subtest 'native UVM owns the fourth selected route partition' => sub {
    my @expected_shapes = map {
        my $profile = $_;
        map {{backend_profile => $profile, level => $_}} @levels
    } qw(
        sv_portable_verilator
        vhdl_portable_ghdl
        vhdl_osvvm_qualified
        sv_uvm_emit.accellera_2020_3_1
    );
    is_deeply($class->owned_shapes, \@expected_shapes,
        'shared foundation owns the three completed ladders and native-UVM partition');

    my $construction = eval { $class->construct({
        backend_profile => 'sv_uvm_emit.accellera_2020_3_1',
        level => 'reference_v1',
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
    }) };
    ok(defined($construction) && $construction->{ok},
        'public construction admits the selected native-UVM reference shape');

    my $direct = eval { $profile_class->evaluate({}); 1 };
    ok(!$direct, 'caller cannot bypass the shared foundation with forged IR');
    like($@, qr/profile evaluation is caller-sealed/,
        'profile helper rejects external evaluation before inspecting inputs');
};

sub construction {
    my ($level) = @_;
    return $class->construct({
        backend_profile => $profile,
        level => $level,
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
    });
}

for my $level (@levels) {
    subtest "$level follows the canonical native-UVM route" => sub {
        my $construction = construction($level);
        ok($construction->{ok}, 'public construction accepts the owned route');
        is($construction->{specification}{backend_profile}, $profile,
            'construction retains the exact profile');
        is($construction->{specification}{level}, $level,
            'construction retains the exact level');

        my $built = $class->build({construction => $construction});
        ok($built->{ok}, 'ordinary parser and PlanBuilder accept the route');
        diag($json->encode($built->{diagnostics})) unless $built->{ok};
        my $operation_total = $level eq 'reference_v1' ? 21 : 22;
        is($built->{execution_ir}->as_hashref
                ->{operation_graph}{total_operation_count},
            $operation_total,
            'canonical ExecutionIR has the selected or adjacent total');

        my $evaluation = $class->evaluate({construction => $construction});
        ok($evaluation->{ok}, 'the expected backend outcome validates');
        diag($json->encode($evaluation->{diagnostics}))
            unless $evaluation->{ok};
        is_deeply([sort keys %$evaluation],
            [sort @{$class->evaluation_keys}],
            'evaluation remains one closed shared-foundation projection');
        is($evaluation->{status}, 'profile_validated',
            'status records structural qualification only');
        is($evaluation->{route_metrics}{operations_total}, $operation_total,
            'report retains the canonical route operation total');
        ok($evaluation->{outcome_contract}{backend_negotiation_executed},
            'the native-UVM negotiation gate executed');
        ok($evaluation->{outcome_contract}{backend_shape_owned},
            'the child owns this exact selected/rejection route');
        ok(!$evaluation->{claims}{capability_claimed}
                && !$evaluation->{claims}{support_claimed}
                && !$evaluation->{claims}{performance_claimed}
                && !$evaluation->{claims}{capacity_claimed}
                && !$evaluation->{claims}{external_runtime_executed},
            'product, performance, capacity, and runtime claims remain false');
        ok(!defined($evaluation->{artifact_oracle}{portable_sv})
                && !defined($evaluation->{artifact_oracle}{portable_vhdl})
                && !defined($evaluation->{artifact_oracle}{osvvm}),
            'native-UVM evaluation cannot claim a sibling profile');

        my $oracle = $evaluation->{artifact_oracle}{native_uvm};
        is($oracle->{backend_profile}, $profile,
            'native-UVM oracle names the exact backend');
        is($oracle->{level}, $level,
            'native-UVM oracle names the exact level');
        is($oracle->{requested_operation_total}, $operation_total,
            'native-UVM oracle names the anchored operation total');
        ok($oracle->{byte_equal_rerun},
            'independent native-UVM emissions are byte-identical');
        ok($oracle->{in_memory_only},
            'emission remains a pure in-memory artifact graph');
        ok(!$oracle->{preprocessing_executed}
                && !$oracle->{compile_executed}
                && !$oracle->{runtime_executed}
                && !$oracle->{result_produced}
                && !$oracle->{manual_review_complete},
            'parse, compile, runtime, result, and manual-review claims remain false');

        if ($level ne 'reference_v1') {
            my $expected_outcome = $level eq 'gate_candidate_v1'
                ? 'backend_negotiation_rejected'
                : 'preflight_dominated_not_constructed';
            is($evaluation->{observed_outcome}, $expected_outcome,
                'unsupported route retains its exact outcome partition');
            ok(!$evaluation->{outcome_contract}{artifacts_emitted},
                'unsupported route emits no artifact graph');
            ok(!$evaluation->{claims}{artifact_graph_claimed},
                'unsupported route claims no artifact graph');
            is_deeply($oracle->{artifact_relpaths}, [],
                'unsupported route publishes no artifact paths');
            is_deeply($oracle->{source_identities}, [],
                'unsupported route publishes no source identities');
            is_deeply($oracle->{static_check_identities}, [],
                'unsupported route publishes no static-check evidence');
            is_deeply($oracle->{selected_mapping_identities}, [],
                'unsupported route publishes no mapping evidence');
            is_deeply($oracle->{review_workflow_stage_identities}, [],
                'unsupported route publishes no workflow evidence');
            for my $field (qw(
                artifact_count source_artifact_count source_bytes
                source_map_entries mapped_operation_count
                source_artifact_map_count static_validation_checks
                passed_static_validation_checks selected_mapping_count
                review_workflow_stage_count review_workflow_check_count
                maximum_generated_identifier_bytes
            )) {
                is($oracle->{$field}, 0,
                    "unsupported route contains zero $field");
            }
            ok($oracle->{atomic_rejection},
                'unsupported route is explicitly atomic');
            is($oracle->{preflight_dominated},
                $level eq 'gate_candidate_v1' ? 0 : 1,
                'only later selected levels are adjacent-preflight dominated');
            is_deeply($oracle->{diagnostics}, [{
                code => 'VIAL_UVM_BACKEND_UNSUPPORTED',
                severity => 'error',
                message =>
                    'native UVM foundation negotiation rejected one or more requirements',
                path => '/negotiation',
            }], 'unsupported route preserves the exact negotiation diagnostic');
        }
        else {
            is($evaluation->{observed_outcome},
                'backend_emitted_review_only',
                'selected shape records review-only emission');
            ok($evaluation->{outcome_contract}{artifacts_emitted},
                'selected shape emits one complete graph');
            ok($evaluation->{claims}{artifact_graph_claimed},
                'qualification claims only the observed artifact graph');
            is_deeply($oracle->{artifact_relpaths}, \@artifact_relpaths,
                'ordered sixteen-artifact inventory is exact');
            is($oracle->{artifact_count}, 16,
                'total artifact inventory is exact');
            is($oracle->{source_artifact_count}, 10,
                'ten native-UVM SystemVerilog sources are exact');
            is($oracle->{source_bytes}, 138_345,
                'selected source byte total is exact');
            is($oracle->{source_map_entries}, 75,
                'selected source-map count is exact');
            is($oracle->{mapped_operation_count}, 6,
                'six intentionally associated operation identities are exact');
            is($oracle->{source_artifact_map_count}, 10,
                'source-map header covers all generated sources');
            is($oracle->{static_validation_checks}, 14,
                'fourteen exact structural checks are retained');
            is($oracle->{passed_static_validation_checks}, 14,
                'all structural checks pass');
            is_deeply($oracle->{static_check_identities}, \@static_checks,
                'structural-check identity and order are exact');
            is($oracle->{selected_mapping_count}, 25,
                'selected mapping-matrix cardinality is exact');
            is_deeply($oracle->{selected_mapping_identities}, \@mapping_ids,
                'selected mapping identities and order are exact');
            is($oracle->{review_workflow_stage_count}, 7,
                'seven review-workflow stages are exact');
            is_deeply($oracle->{review_workflow_stage_identities},
                \@workflow_stages,
                'review-workflow stage identities and order are exact');
            is($oracle->{review_workflow_check_count}, 5,
                'five review-closure checks are exact');
            is($oracle->{maximum_generated_identifier_bytes}, 49,
                'selected generated-symbol maximum is frozen');
            is($oracle->{generated_identifier_limit_bytes}, 255,
                'generated identifiers retain the separate backend bound');
            like($oracle->{artifact_graph_sha256}, qr{\A[0-9a-f]{64}\z},
                'complete artifact graph has one content digest');
            ok(!$oracle->{atomic_rejection} && !$oracle->{preflight_dominated},
                'selected graph is not mislabeled as a rejection');
            is_deeply($oracle->{diagnostics}, [],
                'selected graph has no emitter diagnostic');
            is_deeply($oracle->{source_identities}, \@source_identities,
                'all ten selected source identities are exact');

            my $validated = $class->validate_evaluation({
                construction => $construction,
                evaluation => $evaluation,
            });
            is($json->encode($validated), $json->encode($evaluation),
                'canonical report validates byte-for-byte');
            $evaluation->{artifact_oracle}{native_uvm}{source_bytes}++;
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

subtest 'larger and changed same-count shapes fail before artifacts' => sub {
    my @case = (
        [larger_128 => source_for_total(128)],
        [changed_21 => source_for_total(21, 'rename_selected_expectation')],
    );
    for my $case (@case) {
        my ($label, $source) = @$case;
        my $built = direct_build($source);
        ok($built->{ok}, "$label reaches native-UVM negotiation");
        my $emission = direct_emit($built, $label);
        ok(!$emission->{ok}, "$label fails closed");
        is_deeply($emission->{diagnostics}, [{
            code => 'VIAL_UVM_BACKEND_UNSUPPORTED',
            severity => 'error',
            message =>
                'native UVM foundation negotiation rejected one or more requirements',
            path => '/negotiation',
        }], "$label retains the exact negotiation diagnostic");
        is_deeply($emission->{artifacts}, [],
            "$label publishes no artifact graph");
        for my $field (qw(
            plan_id generated_top operation_id backend_manifest source_map
            static_validation mapping_matrix review_workflow
        )) {
            is($emission->{$field}, undef,
                "$label publishes no partial $field evidence");
        }
    }
};

subtest 'repository-local staging cleans selected and rejected routes exactly' => sub {
    for my $level (qw(reference_v1 gate_candidate_v1)) {
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
        consumer => sub { die "intentional native-UVM consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure remains visible');
    ok(!-e $stage_abs && !-l $stage_abs,
        'consumer failure leaves no content-addressed residue');
};

done_testing;

sub identity {
    my ($relpath, $bytes, $sha256) = @_;
    return {relpath => $relpath, bytes => $bytes, sha256 => $sha256};
}

sub direct_build {
    my ($source) = @_;
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $source,
        source_name =>
            'vial/ahb_subordinate_base_output_arbitration_1.vial',
        source_catalog => {},
    });
    return FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => 'ppif/ahb_lite_subordinate.ppif',
            text => $reference_hial,
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
}

sub direct_emit {
    my ($built, $label) = @_;
    return $backend_class->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => ".artifacts/tmp/vial-scale/falsify-$label",
        backend_profile => $profile,
    });
}

sub source_for_total {
    my ($total, $mutation) = @_;
    my $source = $reference_vial;
    my $needle = '              (scoreboard_check writes)))';
    my $offset = index($source, $needle);
    die "cannot locate the scoreboard-check insertion point\n" if $offset < 0;
    my $extra = join '', map {
        sprintf "              (expect scale_response_%08d"
            . " (same (sample response) #b0))\n", $_
    } 0 .. ($total - 22);
    substr($source, $offset, 0, $extra) if length($extra);
    if (defined($mutation) && $mutation eq 'rename_selected_expectation') {
        my $changed =
            ($source =~ s/\(expect response_ok /\(expect renamed_response_ok /);
        die "cannot rename the selected expectation\n" unless $changed == 1;
    }
    elsif (defined $mutation) {
        die "unknown source mutation '$mutation'\n";
    }
    return $source;
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($repo_root, @_);
}
