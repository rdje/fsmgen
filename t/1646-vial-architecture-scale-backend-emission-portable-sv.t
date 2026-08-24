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
    backends/sv_portable_verilator/backend-manifest.json
    backends/sv_portable_verilator/backend-source-map.json
    backends/sv_portable_verilator/commands/compile-command.json
    backends/sv_portable_verilator/commands/run-command.json
    backends/sv_portable_verilator/evidence/tool-profile.json
    backends/sv_portable_verilator/src/base_output_arbitration_tb.sv
    backends/sv_portable_verilator/src/dut/ahb-lite-subordinate.sv
    backends/sv_portable_verilator/src/fsmgen_vial_runtime_pkg.sv
);
my @source_relpaths = @artifact_relpaths[5 .. 7];
my %expected = (
    reference_v1 => {
        operations => 21, source_bytes => 164_507, source_maps => 54,
        fixture_bytes => 106_181,
        fixture_sha256 =>
            '1839aae7d65c3394442a4b26538b9ea73ab35ae142ca32e29177775919d0f730',
    },
    gate_candidate_v1 => {
        operations => 1_024, source_bytes => 2_803_857, source_maps => 1_057,
        fixture_bytes => 2_745_531,
        fixture_sha256 =>
            'ec5a91968cea2bb5f88994188517cc8b506bf49d6a4ec984fc6b0ad4ee367481',
    },
    qualification_candidate_v1 => {
        operations => 4_096, source_bytes => 10_910_865,
        source_maps => 4_129, fixture_bytes => 10_852_539,
        fixture_sha256 =>
            'd7087673e824dc18e6a91d7a41f819483428650049fc92a0bd28e3a1737065e8',
    },
    limit_v1 => {
        operations => 6_318, source_bytes => 16_774_723,
        source_maps => 6_351, fixture_bytes => 16_716_397,
        fixture_sha256 =>
            'f05f90e1a730b187e2eb6f2f15925c92b1a5f4a6dd12268d705297410dc7eb21',
    },
    over_limit_v1 => {operations => 6_319},
);

sub construction {
    my ($level) = @_;
    return $class->construct({
        backend_profile => 'sv_portable_verilator',
        level => $level,
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
    });
}

subtest 'portable-SystemVerilog owns exactly its selected five-level ladder' => sub {
    my $owned = $class->owned_shapes;
    is_deeply([grep {
        $_->{backend_profile} eq 'sv_portable_verilator'
    } @$owned], [map {{
        backend_profile => 'sv_portable_verilator', level => $_,
    }} qw(
        reference_v1 gate_candidate_v1 qualification_candidate_v1
        limit_v1 over_limit_v1
    )], 'the exact portable-SystemVerilog ladder is publicly owned');
    is(scalar(@$owned), 20,
        'the shared registry also retains fifteen activated sibling shapes');
    my $profile_class =
        'FSM::VIAL::ArchitectureScaleBackendEmission::PortableSV';
    my $direct = eval { $profile_class->evaluate({}); 1 };
    ok(!$direct, 'caller cannot bypass the shared foundation with forged IR');
    like($@, qr/profile evaluation is caller-sealed/,
        'profile helper rejects external evaluation before inspecting inputs');
};

for my $level (qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
)) {
    subtest "$level follows the canonical portable-SystemVerilog route" => sub {
        my $construction = construction($level);
        ok($construction->{ok}, 'public construction accepts the owned shape');
        is($construction->{specification}{backend_profile},
            'sv_portable_verilator', 'construction retains the exact profile');
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

        my $oracle = $evaluation->{artifact_oracle}{portable_sv};
        is($evaluation->{artifact_oracle}{oracle},
            'portable_sv_artifact_graph_v2',
            'shared report selects the revision-2 portable oracle');
        is($oracle->{schema},
            'fsmgen.vial_architecture_scale_backend_emission_portable_sv_oracle.v2',
            'portable oracle publishes its revision-2 schema');
        is($oracle->{schema_version}, 2,
            'portable oracle publishes schema version 2');
        is($oracle->{backend_profile}, 'sv_portable_verilator',
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
            is($oracle->{artifact_count}, 0,
                'adjacent rejection contains zero artifacts');
            is($oracle->{source_artifact_count}, 0,
                'adjacent rejection contains zero sources');
            is($oracle->{source_bytes}, 0,
                'adjacent rejection contains zero generated bytes');
            is($oracle->{source_map_entries}, 0,
                'adjacent rejection contains zero source maps');
            ok($oracle->{atomic_rejection},
                'adjacent rejection is explicitly atomic');
            is_deeply($oracle->{diagnostics}, [{
                code => 'VIAL_BACKEND_LIMIT_EXCEEDED',
                severity => 'error',
                message =>
                    'generated SystemVerilog exceeds the 16 MiB backend cap',
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
                'ordered eight-artifact inventory is exact');
            is($oracle->{artifact_count}, 8,
                'total artifact inventory is exact');
            is($oracle->{source_artifact_count}, 3,
                'source artifact inventory is exact');
            is($oracle->{source_bytes}, $expected{$level}{source_bytes},
                'three-source byte total is exact');
            is($oracle->{source_map_entries},
                $expected{$level}{source_maps},
                'complete source-map count is exact');
            is($oracle->{mapped_operation_count},
                $expected{$level}{operations},
                'every canonical operation is source-mapped');
            is($oracle->{source_artifact_map_count}, 3,
                'source-map header covers every generated source');
            is($oracle->{maximum_generated_identifier_bytes}, 113,
                'maximum generated identifier size is frozen');
            is($oracle->{generated_identifier_limit_bytes}, 255,
                'generated identifiers retain the separate backend bound');
            like($oracle->{artifact_graph_sha256}, qr{\A[0-9a-f]{64}\z},
                'complete artifact graph has one content digest');
            ok(!$oracle->{atomic_rejection},
                'accepted graph is not mislabeled as a rejection');
            is_deeply($oracle->{diagnostics}, [],
                'accepted graph has no emitter diagnostic');
            is_deeply($oracle->{source_identities}, [
                {
                    relpath => $source_relpaths[0],
                    bytes => $expected{$level}{fixture_bytes},
                    sha256 => $expected{$level}{fixture_sha256},
                },
                {
                    relpath => $source_relpaths[1], bytes => 57_531,
                    sha256 =>
                        'eeaa8a687a3a1ce010446f848ca6785538dd907e4c567a91ee6049cc4e079f82',
                },
                {
                    relpath => $source_relpaths[2], bytes => 795,
                    sha256 =>
                        '9ceb9f62a768cf36785674752d10fc9505a3ab20798041eed76dbb53c6203903',
                },
            ], 'all three generated source identities are exact');
        }

        if ($level eq 'reference_v1') {
            my $validated = $class->validate_evaluation({
                construction => $construction,
                evaluation => $evaluation,
            });
            is($json->encode($validated), $json->encode($evaluation),
                'canonical report validates byte-for-byte');
            $evaluation->{artifact_oracle}{portable_sv}{source_bytes}++;
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
        consumer => sub { die "intentional portable-SV consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure remains visible');
    ok(!-e $stage_abs && !-l $stage_abs,
        'consumer failure leaves no content-addressed residue');
};

done_testing;

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
