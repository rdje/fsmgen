#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(
    repo_path('vial/ahb_subordinate_base_output_arbitration.vial'),
);
my @profiles = qw(
    sv_portable_verilator
    vhdl_portable_ghdl
    vhdl_osvvm_qualified
    sv_uvm_emit.accellera_2020_3_1
);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);

sub candidate {
    my (%override) = @_;
    return FSM::VIAL::ArchitectureScaleBackendEmission::_test_construct_candidate({
        backend_profile => 'sv_portable_verilator',
        level => 'reference_v1',
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
        %override,
    });
}

sub foundation_evaluation {
    my ($construction) = @_;
    return FSM::VIAL::ArchitectureScaleBackendEmission::_test_evaluate_foundation_candidate(
        {construction => $construction},
    );
}

sub validate_foundation_evaluation {
    my ($construction, $evaluation) = @_;
    return FSM::VIAL::ArchitectureScaleBackendEmission::_test_validate_foundation_candidate({
            construction => $construction,
            evaluation => $evaluation,
        });
}

subtest 'foundation admits only shapes owned by completed child slices' => sub {
    is_deeply($class->owned_shapes, [
        map({{
            backend_profile => 'sv_portable_verilator', level => $_,
        }} @levels),
        map({{
            backend_profile => 'vhdl_portable_ghdl', level => $_,
        }} @levels),
        map({{
            backend_profile => 'vhdl_osvvm_qualified', level => $_,
        }} @levels),
    ], 'the three completed children own exactly fifteen shapes');

    my @accepted;
    for my $profile (@profiles) {
        for my $level (@levels) {
            my $ok = eval {
                $class->construct({
                    backend_profile => $profile,
                    level => $level,
                    reference_hial_text => $reference_hial,
                    reference_vial_text => $reference_vial,
                });
                1;
            };
            push @accepted, "$profile/$level" if $ok;
            like($@, qr/active slices do not own the requested backend shape/,
                "$profile/$level names the zero-owned boundary") unless $ok;
        }
    }
    is_deeply(\@accepted, [
        map({"sv_portable_verilator/$_"} @levels),
        map({"vhdl_portable_ghdl/$_"} @levels),
        map({"vhdl_osvvm_qualified/$_"} @levels),
    ], 'only the fifteen completed profile shapes are admitted');

    my $unknown_profile = eval {
        $class->construct({
            backend_profile => 'sv_unbounded',
            level => 'reference_v1',
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
        });
        1;
    };
    ok(!$unknown_profile, 'unknown profile fails closed');
    like($@, qr/unknown backend-emission profile 'sv_unbounded'/,
        'unknown-profile diagnostic is exact');

    my $unknown_level = eval {
        $class->construct({
            backend_profile => 'sv_portable_verilator',
            level => 'unbounded_v1',
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
        });
        1;
    };
    ok(!$unknown_level, 'unknown level fails closed');
    like($@, qr/unknown backend-emission level 'unbounded_v1'/,
        'unknown-level diagnostic is exact');

    my $injected = eval {
        $class->construct({
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
            execution_ir => {},
        });
        1;
    };
    ok(!$injected, 'caller-created ExecutionIR cannot enter construction');
    like($@, qr/unknown key 'execution_ir'/,
        'closed construction identifies injected ExecutionIR');
};

subtest 'private reference construction is caller-sealed and content-addressed' => sub {
    my $direct = eval {
        $class->_construct_candidate({
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
        });
        1;
    };
    ok(!$direct, 'external caller cannot invoke candidate construction');
    like($@, qr/candidate construction is private/,
        'candidate caller-seal rejection is exact');

    my $direct_internal = eval {
        FSM::VIAL::ArchitectureScaleBackendEmission::_construct_candidate_internal({
            backend_profile => 'sv_portable_verilator',
            level => 'reference_v1',
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
        });
        1;
    };
    ok(!$direct_internal, 'external caller cannot bypass the candidate wrapper');
    like($@, qr/candidate internals are private/,
        'internal caller seal rejects a fully-qualified invocation');

    my $first = candidate();
    my $second = candidate();
    ok($first->{ok}, 'same-package candidate reaches the common workload contract');
    is($json->encode($second), $json->encode($first),
        'independent construction is byte-identical');
    like($first->{workload_identity}, qr{\Aworkload/[0-9a-f]{64}\z},
        'construction carries one content address');
    is($first->{workload_identity},
        'workload/b739891ca3e9382be7c6877b185c67a439e45cc3aa477769d56711ca56e43421',
        'checked-AHB backend-emission workload identity is frozen');
    like($first->{staging_identity},
        qr{\A\.artifacts/tmp/vial-scale/[0-9a-f]{64}\z},
        'construction owns one repository-relative content-addressed stage');
    is($first->{specification}{family}, 'backend_emission_v1',
        'candidate cannot escape the backend-emission family');
    is($first->{specification}{primary_axis}, 'artifact_graph',
        'candidate cannot escape the sole structural axis');
    is($first->{specification}{backend_profile}, 'sv_portable_verilator',
        'candidate retains the selected backend profile');
    is($first->{specification}{level}, 'reference_v1',
        'foundation uses only the checked reference catalog shape');
    ok(!defined($first->{specification}{tool_profile}),
        'emission construction has no runtime tool profile');
    is_deeply(
        $first->{specification}{requested_counts}{backend_authority},
        {
            generated_source_artifacts => 3,
            total_artifacts => 8,
            generated_source_bytes => 16_777_216,
            source_map_entries => 1_000_000,
        },
        'construction derives exact portable-SV authority from the shared catalog',
    );
    is_deeply(
        [map { [$_->{relative_path}, $_->{role}] } @{$first->{inputs}}],
        [
            ['ppif/ahb_lite_subordinate.ppif', 'hial_source'],
            ['vial/ahb_subordinate_base_output_arbitration.vial', 'vial_source'],
        ],
        'construction contains only the exact checked-AHB source pair',
    );
    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is(sha256_hex($input{hial_source}{content}),
        '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c',
        'HIAL input retains the frozen checked-AHB identity');
    is(sha256_hex($input{vial_source}{content}),
        '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd',
        'VIAL input retains the frozen checked-AHB identity');

    my $altered_hial = $reference_hial;
    substr($altered_hial, 0, 1, substr($altered_hial, 0, 1) eq '(' ? ' ' : '(');
    my $forged_hial = eval {
        candidate(reference_hial_text => $altered_hial);
        1;
    };
    ok(!$forged_hial, 'changed checked-AHB HIAL bytes fail before construction');
    like($@, qr/checked-AHB HIAL identity changed/,
        'HIAL mutation rejection names the frozen identity');

    my $altered_vial = $reference_vial . "\n";
    my $forged_vial = eval {
        candidate(reference_vial_text => $altered_vial);
        1;
    };
    ok(!$forged_vial, 'changed checked-AHB VIAL bytes fail before construction');
    like($@, qr/checked-AHB VIAL byte length changed/,
        'VIAL mutation rejection names the frozen length');
};

subtest 'canonical producers yield deterministic caller-sealed ExecutionIR' => sub {
    my $construction = candidate();
    my $built = $class->build({construction => $construction});
    ok($built->{ok}, 'foundation builds through the ordinary canonical route');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    is(ref($built->{semantic_ir}), 'FSM::VIAL::SemanticIR',
        'build returns exact canonical SemanticIR');
    is(ref($built->{bridge_manifest}), 'FSM::HIAL::VIALBridge::Manifest',
        'build returns exact canonical bridge manifest');
    is(ref($built->{execution_ir}), 'FSM::VIAL::ExecutionIR',
        'build returns exact canonical ExecutionIR');
    is(ref($built->{backend_inputs}), 'HASH',
        'build retains only canonical backend inputs derived from HIAL');
    is($built->{plan}{schema}, 'fsmgen.vial_plan.v1',
        'build returns the target-neutral plan projection');

    my $evaluation = foundation_evaluation($construction);
    ok($evaluation->{ok}, 'independent complete-route rerun is byte-deterministic');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is_deeply([sort keys %$evaluation], [sort @{$class->evaluation_keys}],
        'evaluation is one closed projection');
    is($evaluation->{status}, 'foundation_validated',
        'foundation status does not claim backend emission');
    is($evaluation->{observed_outcome},
        'execution_ir_accepted_emission_not_evaluated',
        'outcome distinguishes canonical planning from emission');
    like($evaluation->{evaluation_identity},
        qr{\Abackend-emission-evaluation/[0-9a-f]{64}\z},
        'evaluation is content-addressed');
    is($evaluation->{evaluation_identity},
        'backend-emission-evaluation/e7d9a4e1696edbd9a02c01182637518751315b418ab1886849c7b56907fe24fa',
        'foundation evaluation identity is frozen');
    like($evaluation->{rerun_identity}, qr{\Arerun/[0-9a-f]{64}\z},
        'independent route tuple has its own identity');
    is($evaluation->{rerun_identity},
        'rerun/172c041973987cd89b82de60ca0311d850f505a8bf5ebfa172123f52fa2dcbf1',
        'independent canonical rerun identity is frozen');
    for my $stage (qw(
        semantic_ir_sha256 bridge_manifest_sha256 execution_ir_sha256
        backend_inputs_sha256 plan_sha256
    )) {
        like($evaluation->{stage_identities}{$stage}, qr/\A[0-9a-f]{64}\z/,
            "$stage is an exact canonical digest");
    }
    is_deeply($evaluation->{stage_identities}, {
        semantic_ir_sha256 =>
            'a83dbb89ecf5113168db2bd92a80697c0a3bf181771cbc7a0f564a6afd0f8750',
        bridge_manifest_sha256 =>
            'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
        execution_ir_sha256 =>
            '7d54be68bc691e3c05c4c94405f0ad278b9206032f8b9cde5dc3d7bf13714509',
        backend_inputs_sha256 =>
            '0b826052e52df3d59d08fb49f4a4ff18a228b7ce8e7282af0e56b2121b9e8452',
        plan_sha256 =>
            'eaa8cc70fa25a4382921f40112c0f3f50aec4045caccff2e6a8f98cfbc1c0942',
    }, 'all canonical stage identities are frozen together');
    is($evaluation->{route_metrics}{scenarios}, 2,
        'foundation observes both checked-AHB scenarios');
    is($evaluation->{route_metrics}{operations_total}, 21,
        'foundation observes the exact reference operation count');
    is($evaluation->{route_metrics}{fibers_total}, 4,
        'foundation observes the exact reference fiber count');
    is($evaluation->{route_metrics}{simultaneously_live_fibers}, 3,
        'foundation observes the exact reference live-fiber width');
    is($evaluation->{route_metrics}{source_map_entries}, 39,
        'foundation observes the complete reference plan source map');
    is($evaluation->{route_metrics}{serialized_plan_bytes}, 44_101,
        'foundation freezes the genuine serialized plan size');
    is($evaluation->{route_metrics}{backend_input_artifacts}, 2,
        'foundation freezes canonical backend input inventory without emitting');

    ok(!$evaluation->{outcome_contract}{backend_negotiation_executed},
        'foundation performs no backend negotiation');
    ok(!$evaluation->{outcome_contract}{artifacts_emitted},
        'foundation emits no artifacts');
    ok(!$evaluation->{outcome_contract}{backend_shape_owned},
        'foundation claims no profile-level ownership');
    is_deeply($evaluation->{outcome_contract}{canonical_stages_completed},
        [qw(semantic bridge backend_inputs execution_ir plan)],
        'outcome records the exact completed canonical stages');
    is($evaluation->{artifact_oracle}{oracle}, 'none',
        'foundation carries no profile artifact oracle');
    ok(!scalar(grep { defined $evaluation->{artifact_oracle}{$_} }
        qw(portable_sv portable_vhdl osvvm native_uvm)),
        'every future profile-oracle compartment begins null');
    ok($evaluation->{claims}{qualification_only},
        'foundation is explicitly qualification-only');
    for my $claim (qw(
        backend_shape_owned artifact_graph_claimed capability_claimed
        support_claimed performance_claimed capacity_claimed
        external_runtime_executed
    )) {
        ok(!$evaluation->{claims}{$claim}, "$claim remains false");
    }
    is_deeply($evaluation->{explicit_nonclaims},
        $construction->{specification}{explicit_nonclaims},
        'evaluation preserves every common workload nonclaim');
    my @host_fragments = map { File::Spec->catdir('', @$_) . '/' } (
        ['Volumes'], ['private', 'tmp'], ['tmp'],
    );
    ok(!scalar(grep { index($json->encode($evaluation), $_) >= 0 }
        @host_fragments),
        'durable evaluation contains no absolute host or off-volume path');
};

subtest 'construction and evaluation mutation are rejected defensively' => sub {
    my $construction = candidate();
    my $evaluation = foundation_evaluation($construction);
    my $validated = validate_foundation_evaluation(
        $construction, $evaluation,
    );
    is($json->encode($validated), $json->encode($evaluation),
        'canonical evaluation validates byte-for-byte');

    my $mutated_construction = clone($construction);
    $mutated_construction->{inputs}[0]{content} .= ' ';
    my $built_mutation = eval {
        $class->build({construction => $mutated_construction});
        1;
    };
    ok(!$built_mutation, 'post-identity source mutation fails closed');
    like($@, qr/construction is not canonical|checked-AHB HIAL identity changed/,
        'construction mutation rejection names canonical source authority');

    my $injected_route = eval {
        $class->build({construction => $construction, execution_ir => {}});
        1;
    };
    ok(!$injected_route, 'build cannot consume caller-created ExecutionIR');
    like($@, qr/unknown key 'execution_ir'/,
        'build projection identifies injected ExecutionIR');

    my $mutated_evaluation = clone($evaluation);
    $mutated_evaluation->{route_metrics}{operations_total}++;
    my $evaluation_mutation = eval {
        validate_foundation_evaluation(
            $construction, $mutated_evaluation,
        );
        1;
    };
    ok(!$evaluation_mutation, 'post-identity evaluation mutation fails closed');
    like($@, qr/evaluation is not canonical/,
        'evaluation mutation rejection names canonical regeneration');

    my $unknown_projection = clone($evaluation);
    $unknown_projection->{backend_result} = {};
    my $unknown = eval {
        validate_foundation_evaluation(
            $construction, $unknown_projection,
        );
        1;
    };
    ok(!$unknown, 'backend result cannot enter the foundation projection');
    like($@, qr/unknown key 'backend_result'/,
        'evaluation schema identifies unknown provider data');

    $evaluation->{route_metrics}{operations_total} = 999;
    my $fresh = foundation_evaluation(candidate());
    is($fresh->{route_metrics}{operations_total}, 21,
        'returned evaluation shares no mutable storage with reruns');
};

subtest 'repository-volume staging cleans success and failure exactly' => sub {
    my $construction = candidate();
    my $stage_abs = repo_path($construction->{staging_identity});
    ok(!-e $stage_abs && !-l $stage_abs,
        'deterministic backend-emission stage begins absent');
    my ($seen_stage, @seen_paths);
    my $success = $class->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub {
            my ($context) = @_;
            $seen_stage = $context->{staging_identity};
            @seen_paths = sort map { $_->{relative_path} } @{$context->{inputs}};
            ok(-d $context->{staging_root},
                'consumer sees one repository-local staging directory');
        },
    });
    ok($success->{ok}, 'successful staging reports success');
    ok($success->{same_volume}, 'successful staging proves same-volume identity');
    ok($success->{removed}, 'successful staging reports exact cleanup');
    is($seen_stage, $construction->{staging_identity},
        'consumer sees the content-addressed repository-relative stage');
    is_deeply(\@seen_paths, [
        'ppif/ahb_lite_subordinate.ppif',
        'vial/ahb_subordinate_base_output_arbitration.vial',
    ], 'consumer sees only the exact canonical source pair');
    ok(!-e $stage_abs && !-l $stage_abs,
        'successful staging leaves no content-addressed residue');

    my $failed = $class->with_staging({
        repository_root => $repo_root,
        construction => $construction,
        consumer => sub { die "intentional backend-emission consumer failure\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure uses the stable workload diagnostic family');
    ok(!-e $stage_abs && !-l $stage_abs,
        'failed staging also leaves no content-addressed residue');
};

done_testing;

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleBackendEmission;

sub _test_construct_candidate {
    my ($args) = @_;
    return __PACKAGE__->_construct_candidate($args);
}

sub _test_evaluate_foundation_candidate {
    my ($args) = @_;
    return __PACKAGE__->_evaluate_foundation_candidate($args);
}

sub _test_validate_foundation_candidate {
    my ($args) = @_;
    return __PACKAGE__->_validate_foundation_candidate($args);
}
