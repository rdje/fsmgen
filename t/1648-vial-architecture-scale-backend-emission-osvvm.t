#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::Backend::OSVVM2026_05Materialization;

my $class = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $provider_class = 'FSM::VIAL::Backend::OSVVM2026_05Materialization';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path(
    'ppif', 'ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(repo_path(
    'vial', 'ahb_subordinate_base_output_arbitration.vial'));

my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1 limit_v1
    over_limit_v1
);
my @artifact_relpaths = qw(
    backends/vhdl_osvvm_qualified/backend-manifest.json
    backends/vhdl_osvvm_qualified/backend-source-map.json
    backends/vhdl_osvvm_qualified/evidence/advanced-mapping-matrix.json
    backends/vhdl_osvvm_qualified/evidence/provider-materialization.json
    backends/vhdl_osvvm_qualified/evidence/qualification-reference.json
    backends/vhdl_osvvm_qualified/evidence/semantic-preservation.json
    backends/vhdl_osvvm_qualified/evidence/source-order.json
    backends/vhdl_osvvm_qualified/evidence/static-validation.json
    backends/vhdl_osvvm_qualified/evidence/tool-profile.json
    backends/vhdl_osvvm_qualified/src/fsmgen_vial_osvvm_adapter_pkg.vhd
    backends/vhdl_osvvm_qualified/src/portable/base_output_arbitration_metadata_pkg.vhd
    backends/vhdl_osvvm_qualified/src/portable/base_output_arbitration_probe_adapter.vhd
    backends/vhdl_osvvm_qualified/src/portable/base_output_arbitration_tb.vhd
    backends/vhdl_osvvm_qualified/src/portable/dut/ahb_lite_subordinate.vhd
    backends/vhdl_osvvm_qualified/src/portable/fsmgen_vial_runtime_pkg.vhd
    backends/vhdl_osvvm_qualified/src/portable/fsmgen_vial_types_pkg.vhd
);
my @source_relpaths = @artifact_relpaths[9 .. 15];
my @static_checks = qw(
    one_adapter exact_recursive_provider_identity adapter_provider_context
    adapter_randomization adapter_coverage adapter_scoreboard adapter_reporting
    adapter_synchronization adapter_data_structure
    adapter_verification_component closed_mapping_matrix
    portable_semantic_authority
);
my @mapping_ids = qw(
    advanced_coverage advanced_data_structure advanced_randomization
    advanced_reporting advanced_scoreboard advanced_synchronization
    verification_component_adapter
);
my %expected = (
    reference_v1 => {
        operations => 21, source_bytes => 120_911, source_maps => 66,
        metadata_bytes => 15_323,
        metadata_sha256 =>
            '59a4f9e1f8a2c9da6b8c5dd36f255ee1edb0b2bce57264906ab916a9141ba8bc',
    },
    gate_candidate_v1 => {
        operations => 128, source_bytes => 179_280, source_maps => 173,
        metadata_bytes => 73_692,
        metadata_sha256 =>
            '922e1ab962d20c12cf24cdd8222a19b3f39fe958e934bcfb93b6a03974e0c9c9',
    },
    qualification_candidate_v1 => {
        operations => 512, source_bytes => 391_248, source_maps => 557,
        metadata_bytes => 285_660,
        metadata_sha256 =>
            '9c77af56b8241f94c4ca2d9fc23ec73c6ad5582ae709dcb1318d0e6716502d7a',
    },
    limit_v1 => {
        operations => 29_508, source_bytes => 16_781_090,
        source_maps => 29_553, metadata_bytes => 16_675_502,
        metadata_sha256 =>
            'b678833b74279814a3c5b008116546fe0353362296de32daa487352091a7ee06',
    },
    over_limit_v1 => {operations => 29_509},
);

sub construction {
    my ($level) = @_;
    return $class->construct({
        backend_profile => 'vhdl_osvvm_qualified',
        level => $level,
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
    });
}

subtest 'OSVVM owns exactly the third selected five-level ladder' => sub {
    my @expected_shapes = map {
        my $profile = $_;
        map {{backend_profile => $profile, level => $_}} @levels
    } qw(sv_portable_verilator vhdl_portable_ghdl vhdl_osvvm_qualified);
    is_deeply($class->owned_shapes, \@expected_shapes,
        'shared foundation owns only the three completed profile ladders');
    my $profile_class =
        'FSM::VIAL::ArchitectureScaleBackendEmission::OSVVM';
    my $direct = eval { $profile_class->evaluate({}); 1 };
    ok(!$direct, 'caller cannot bypass the shared foundation with forged IR');
    like($@, qr/profile evaluation is caller-sealed/,
        'profile helper rejects external evaluation before inspecting inputs');
};

for my $level (@levels) {
    subtest "$level follows the canonical OSVVM route" => sub {
        my $construction = construction($level);
        ok($construction->{ok}, 'public construction accepts the owned shape');
        is($construction->{specification}{backend_profile},
            'vhdl_osvvm_qualified', 'construction retains the exact profile');
        is($construction->{specification}{level}, $level,
            'construction retains the exact level');

        my $built = $class->build({construction => $construction});
        ok($built->{ok}, 'ordinary parser and PlanBuilder accept the route');
        diag($json->encode($built->{diagnostics})) unless $built->{ok};
        is($built->{execution_ir}->as_hashref
                ->{operation_graph}{total_operation_count},
            $expected{$level}{operations},
            'canonical ExecutionIR has the selected operation total');

        my $evaluation;
        if ($level eq 'reference_v1') {
            my $verify = $provider_class->can('verify');
            my $verify_count = 0;
            {
                no warnings 'redefine';
                local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify =
                    sub { ++$verify_count; return $verify->(@_) };
                $evaluation = $class->evaluate({construction => $construction});
            }
            is($verify_count, 1,
                'both emissions reuse one callback-scoped provider verification');
        }
        else {
            $evaluation = $class->evaluate({construction => $construction});
        }
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
                && !defined($evaluation->{artifact_oracle}{portable_vhdl})
                && !defined($evaluation->{artifact_oracle}{native_uvm}),
            'OSVVM evaluation cannot claim a sibling profile');

        my $oracle = $evaluation->{artifact_oracle}{osvvm};
        is($oracle->{backend_profile}, 'vhdl_osvvm_qualified',
            'OSVVM oracle names the exact backend');
        is($oracle->{level}, $level, 'OSVVM oracle names the exact level');
        is($oracle->{requested_operation_total},
            $expected{$level}{operations},
            'OSVVM oracle names the anchored T value');
        ok($oracle->{byte_equal_rerun},
            'callback-scoped backend emissions are byte-identical');
        ok($oracle->{provider_verification_reused},
            'oracle records provider-verification reuse');
        ok($oracle->{in_memory_only},
            'emission remains a pure in-memory artifact graph');

        if ($level eq 'over_limit_v1') {
            is($evaluation->{observed_outcome},
                'portable_foundation_limit_rejected',
                'adjacent shape records portable-foundation rejection');
            ok(!$evaluation->{outcome_contract}{artifacts_emitted},
                'adjacent rejection emits no artifact graph');
            ok(!$evaluation->{claims}{artifact_graph_claimed},
                'adjacent rejection claims no artifact graph');
            for my $field (qw(
                artifact_relpaths source_identities static_check_identities
                mapping_identities
            )) {
                is_deeply($oracle->{$field}, [],
                    "adjacent rejection contains no $field evidence");
            }
            for my $field (qw(
                artifact_count source_artifact_count source_bytes
                source_map_entries adapter_source_map_entries
                translated_portable_source_map_entries mapped_operation_count
                source_artifact_map_count static_validation_checks
                portable_foundation_static_validation_checks
                advanced_mapping_count semantic_preservation_source_count
                semantic_preservation_guard_count provider_repository_count
                provider_gitlink_count provider_license_count
                provider_notice_count
            )) {
                is($oracle->{$field}, 0,
                    "adjacent rejection contains zero $field");
            }
            ok($oracle->{atomic_rejection},
                'adjacent rejection is explicitly atomic');
            is_deeply($oracle->{diagnostics}, [{
                code => 'VIAL_OSVVM_PORTABLE_FOUNDATION_ERROR',
                message => 'generated VHDL exceeds the 16 MiB backend cap',
                path => '/portable_foundation',
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
                'ordered sixteen-artifact inventory is exact');
            is($oracle->{artifact_count}, 16,
                'total artifact inventory is exact');
            is($oracle->{source_artifact_count}, 7,
                'six portable sources plus one adapter are exact');
            is($oracle->{source_bytes}, $expected{$level}{source_bytes},
                'seven-source byte total is exact');
            is($oracle->{source_map_entries}, $expected{$level}{source_maps},
                'complete source-map count is exact');
            is($oracle->{adapter_source_map_entries}, 7,
                'seven adapter maps precede the portable translations');
            is($oracle->{translated_portable_source_map_entries},
                $expected{$level}{source_maps} - 7,
                'all portable source maps are translated');
            is($oracle->{mapped_operation_count},
                $expected{$level}{operations},
                'every canonical operation is source-mapped');
            is($oracle->{source_artifact_map_count}, 7,
                'source-map header covers every generated source');
            is($oracle->{static_validation_checks}, 12,
                'twelve exact OSVVM structural checks are retained');
            is($oracle->{passed_static_validation_checks}, 12,
                'all twelve OSVVM structural checks pass');
            is_deeply($oracle->{static_check_identities}, \@static_checks,
                'static-check identity and order are exact');
            is($oracle->{portable_foundation_static_validation_checks}, 20,
                'successful foundation retains twenty prerequisite checks');
            is($oracle->{advanced_mapping_count}, 7,
                'seven negotiated advanced mappings are exact');
            is_deeply($oracle->{mapping_identities}, \@mapping_ids,
                'advanced mapping identity and order are exact');
            is($oracle->{semantic_preservation_source_count}, 6,
                'all portable sources retain byte identity');
            is($oracle->{semantic_preservation_guard_count}, 6,
                'all portable semantic-authority guards remain true');
            is_deeply([
                @{$oracle}{qw(
                    provider_repository_count provider_gitlink_count
                    provider_license_count provider_notice_count
                )}
            ], [14, 13, 14, 0],
                'provider repository, gitlink, licence, and notice census is exact');
            is($oracle->{provider_manifest_sha256},
                '128e483049521c2d4882bac0a6ceb66d9d127ca3e33109961942662409e06f96',
                'provider manifest identity is frozen');
            is($oracle->{provider_root_commit},
                '2f7c391051dfb11890fa4bdbda9918d1db492250',
                'provider root commit is frozen');
            is($oracle->{provider_root_tree},
                'bd4fdc594f2c26d564cf8907ff599578b9a39e22',
                'provider root tree is frozen');
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
                'adapter and all six portable source identities are exact');
        }

        if ($level eq 'reference_v1') {
            my $validated = $class->validate_evaluation({
                construction => $construction,
                evaluation => $evaluation,
            });
            is($json->encode($validated), $json->encode($evaluation),
                'canonical report validates byte-for-byte');
            $evaluation->{artifact_oracle}{osvvm}{source_bytes}++;
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
        consumer => sub { die "intentional OSVVM consumer failure\n" },
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
            relpath => $source_relpaths[0], bytes => 4_351,
            sha256 =>
                '1a547b8de38c072600a76497778758affab25ccd479c0c1dfce7f0e0579c9e94',
        },
        {
            relpath => $source_relpaths[1], bytes => $level->{metadata_bytes},
            sha256 => $level->{metadata_sha256},
        },
        {
            relpath => $source_relpaths[2], bytes => 591,
            sha256 =>
                '7a7e3b4e81fd222e53e2098653fcf1131f1b58dbeba35698c1cfe67a4fab5b56',
        },
        {
            relpath => $source_relpaths[3], bytes => 44_760,
            sha256 =>
                '2570c6349752023e358785156e9739ce76a4dd14bc6d86ad71b1253783ca4b70',
        },
        {
            relpath => $source_relpaths[4], bytes => 47_670,
            sha256 =>
                '8d93b0ade4d9561d19fdd12ab10b4d8ba1a3dc06de9f911d1c0d8d1bf18518cf',
        },
        {
            relpath => $source_relpaths[5], bytes => 2_191,
            sha256 =>
                '82cb0d22e03a661ff88aecbf5b94b89f91381801576d1c683d749ac02e258017',
        },
        {
            relpath => $source_relpaths[6], bytes => 6_025,
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
