#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionGraph;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my $occurrence_id = join('/',
    'decision',
    'architecture_scale_execution::fixture::execution_gate',
    'architecture_scale_execution::fixture::execution_gate::scenario::scenario_00000000',
    'scale.random_attempt',
    0,
);
my %expected = (
    attempts => 8_192,
    accepted_attempt => 8_191,
    occurrences => 1,
    operations => 1,
    scenarios => 1,
    fibers => 1,
    live_fibers => 1,
    source_maps => 19,
    bindings => 22,
    execution_events => 6,
    execution_types => 8,
    hial_bytes => 1_326,
    vial_bytes => 1_298,
    bridge_bytes => 508_968,
    generated_plan_bytes => 34_295,
    replayed_plan_bytes => 34_294,
    target_decimal => '9053010565424434193',
    target_hex => '7da2c124f3fb4c11',
    workload_identity =>
        'workload/3cb7d1faee8cb642e54ca939aa5b38c53e65928fc8c7bdf352dc7da5c9b1d2e8',
    hial_sha256 =>
        '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c',
    vial_sha256 =>
        'cd2a62f4393e9b952f6bb269f3b6ed12c59f44c9eb4a66aca6ab734c099896fa',
    semantic_sha256 =>
        '8ac7407dbe26a71a2b152fc362c82d3fdd455d89b65709821ec61f666641726c',
    bridge_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
    generated_plan_id =>
        'plan/d9c93dcdb2b80cf42ff83506c7166ac837ac428a30b7e2d4bcdd58596d72ccac',
    generated_plan_sha256 =>
        'ae580360ba83d18ef6992bf239a3ce27dac95af6291e01d6309ba3b3be31d2cd',
    replayed_plan_id =>
        'plan/a14e332024cd500270e5b5c758faa4651cf2427f111d578787fcf14df0404365',
    replayed_plan_sha256 =>
        '9ea034e1d4e32cd95849af0b5da13ab2182030c0711b795b9bfdfda8e84c850b',
);

sub construction {
    return $class->construct({
        primary_axis => 'random_attempts',
        level => 'gate_candidate_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest 'random-attempt construction is canonical checked-AHB source' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'random-attempt gate constructs through the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent random-attempt construction is byte-identical');
    is($first->{specification}{requested_counts}{random_attempts},
        $expected{attempts}, 'construction retains the selected attempt request');
    is($first->{workload_identity}, $expected{workload_identity},
        'construction identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is(bytes::length($input{hial_source}{content}), $expected{hial_bytes},
        'checked-AHB source byte count is frozen');
    is(sha256_hex($input{hial_source}{content}), $expected{hial_sha256},
        'checked-AHB source identity is frozen');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated random VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated random VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content}
            =~ /\Q$expected{target_decimal}\E/g),
        2, 'candidate at attempt 8,191 appears only in constraint and expectation');
    like($input{vial_source}{content},
        qr{\(choice attempt_target \(u 64\).*\(uniform 0 18446744073709551615\).*\(constraints \(value_eq \(choice attempt_target\) \Q$expected{target_decimal}\E\)\)\)}s,
        'one genuine u64 equality constraint owns deterministic rejection sampling');
    like($input{vial_source}{content},
        qr{\(expect selected_random_attempt \(value_eq \(choice attempt_target\) \Q$expected{target_decimal}\E\)\)},
        'one genuine check operation references the selected choice');
};

subtest 'generated and replayed decisions close through the public binder' => sub {
    my ($generated, $replayed) =
        FSM::VIAL::ArchitectureScaleExecutionGraph::_test_random_replay(
            construction());
    ok($generated->{ok}, 'generated plan builds through the public binder');
    diag($json->encode($generated->{diagnostics})) unless $generated->{ok};
    ok($replayed->{ok}, 'strict replay plan builds through the same public binder');
    diag($json->encode($replayed->{diagnostics})) unless $replayed->{ok};

    my $ir = $generated->{execution_ir}->as_hashref;
    my $graph = $ir->{operation_graph};
    my $decision = $generated->{plan}{random_decisions}[0];
    my $replay_decision = $replayed->{plan}{random_decisions}[0];
    is(scalar(@{$generated->{plan}{random_decisions}}), $expected{occurrences},
        'plan contains one scenario-scoped random occurrence');
    is($decision->{occurrence_id}, $occurrence_id,
        'decision occurrence identity is exact');
    is($decision->{algorithm}, 'sha256_counter_rejection_v1',
        'decision retains the selected random algorithm');
    is($decision->{attempt}, $expected{accepted_attempt},
        'generated decision accepts exactly at zero-based attempt 8,191');
    is($decision->{value}{value_hex}, $expected{target_hex},
        'generated decision retains the exact 64-bit candidate');
    is($decision->{origin}, 'generated', 'generated decision origin is exact');
    is($replay_decision->{origin}, 'replayed', 'replayed decision origin is exact');

    my $generated_without_origin = clone_json($decision);
    my $replayed_without_origin = clone_json($replay_decision);
    delete $generated_without_origin->{origin};
    delete $replayed_without_origin->{origin};
    is_deeply($replayed_without_origin, $generated_without_origin,
        'replay preserves every keyed value and attempt except origin');

    my $generated_plan = clone_json($generated->{plan});
    my $replayed_plan = clone_json($replayed->{plan});
    delete $generated_plan->{plan_id};
    delete $replayed_plan->{plan_id};
    $generated_plan->{random_decisions}[0]{origin} = 'replayed';
    is_deeply($replayed_plan, $generated_plan,
        'replayed plan changes only decision origin and derived plan identity');

    is($graph->{total_operation_count}, $expected{operations},
        'random gate contains one genuine operation');
    is($graph->{total_fiber_count}, $expected{fibers},
        'random gate contains one root fiber');
    is($graph->{maximum_simultaneous_live_fibers}, $expected{live_fibers},
        'random gate isolates simultaneous liveness to one');
    is($graph->{operations}[0]{kind}, 'expect',
        'choice is referenced by one genuine expectation');
    is($graph->{operations}[0]{eligible_phase}, 'check',
        'choice reference executes in the portable check phase');
    is_deeply($decision->{reference_operation_ids},
        [$graph->{operations}[0]{operation_id}],
        'decision points to its exact referencing operation');
    is(scalar(@{$ir->{source_map}}), $expected{source_maps},
        '17 fixed maps plus operation and decision maps are exact');
    my @decision_map = grep {
        $_->{plan_path} eq '/random_decisions/0'
    } @{$ir->{source_map}};
    is(scalar(@decision_map), 1, 'decision has one unique source-map record');
    is($decision_map[0]{semantic_path},
        '/packages/0/fixtures/0/randomness/choices/0',
        'decision map resolves the authored choice declaration');
    is_deeply($decision_map[0]{bridge_fact_paths}, [],
        'decision map needs no fabricated bridge fact');
    is_deeply(
        [map { $_->{capability_id} }
            grep { $_->{capability_id} =~ /architecture_scale/ }
            @{$generated->{plan}{capability_ledger}}],
        [], 'public random gate does not admit private scale capability');

    my $generated_json = $json->encode($generated->{plan});
    my $replayed_json = $json->encode($replayed->{plan});
    is(bytes::length($generated_json), $expected{generated_plan_bytes},
        'generated plan byte count is exact');
    is(sha256_hex($generated_json), $expected{generated_plan_sha256},
        'generated plan hash is exact');
    is($generated->{plan}{plan_id}, $expected{generated_plan_id},
        'generated plan content identity is exact');
    is(bytes::length($replayed_json), $expected{replayed_plan_bytes},
        'replayed plan byte count is exact');
    is(sha256_hex($replayed_json), $expected{replayed_plan_sha256},
        'replayed plan hash is exact');
    is($replayed->{plan}{plan_id}, $expected{replayed_plan_id},
        'replayed plan content identity is exact');
};

subtest 'random/replay evaluation freezes exact metrics and identities' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'random/replay gate passes every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{metrics}{random_attempts}, $expected{attempts},
        'evaluation freezes the exact attempted proposal count');
    is($evaluation->{metrics}{random_occurrences}, $expected{occurrences},
        'evaluation freezes occurrence isolation');
    is($evaluation->{metrics}{expanded_operations_total}, $expected{operations},
        'evaluation freezes operation isolation');
    is($evaluation->{metrics}{selected_scenarios}, $expected{scenarios},
        'evaluation freezes scenario isolation');
    is($evaluation->{metrics}{total_fibers}, $expected{fibers},
        'evaluation freezes total fibers');
    is($evaluation->{metrics}{simultaneous_live_fibers}, $expected{live_fibers},
        'evaluation freezes simultaneous liveness');
    is($evaluation->{metrics}{source_map_records}, $expected{source_maps},
        'evaluation freezes exact source-map count');
    is($evaluation->{metrics}{bindings}, $expected{bindings},
        'evaluation freezes public binding count');
    is($evaluation->{metrics}{execution_events}, $expected{execution_events},
        'evaluation freezes checked-AHB events');
    is($evaluation->{metrics}{execution_types}, $expected{execution_types},
        'evaluation freezes the added u64 execution type');
    is($evaluation->{metrics}{serialized_bridge_manifest_bytes},
        $expected{bridge_bytes}, 'evaluation freezes canonical bridge bytes');
    is($evaluation->{metrics}{serialized_plan_bytes},
        $expected{generated_plan_bytes}, 'evaluation freezes generated plan bytes');
    is($evaluation->{semantic_ir_sha256}, $expected{semantic_sha256},
        'semantic identity is exact');
    is($evaluation->{bridge_manifest_sha256}, $expected{bridge_sha256},
        'bridge identity is the frozen checked-AHB manifest');
    is($evaluation->{plan_sha256}, $expected{generated_plan_sha256},
        'generated plan identity is exact');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'random/replay gate has no selected contract discrepancy');
};

subtest 'random/replay gate rejects mutation and unfinished levels' => sub {
    my $original = \&FSM::VIAL::ArchitectureScaleExecutionGraph::_build_replay_execution;
    my $tampered;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleExecutionGraph::_build_replay_execution = sub {
            my $result = $original->(@_);
            $result->{plan}{random_decisions}[0]{attempt} = 0;
            return $result;
        };
        $tampered = $class->evaluate({construction => construction()});
    }
    ok(!$tampered->{ok}, 'replay-attempt mutation fails the evaluation oracle');
    is_deeply(
        [map { $_->{code} }
            grep { $_->{code} eq 'VIAL_SCALE_EXECUTION_REPLAY_ERROR' }
            @{$tampered->{diagnostics}}],
        ['VIAL_SCALE_EXECUTION_REPLAY_ERROR'],
        'replay mutation emits the stable replay oracle diagnostic once',
    );

    my $forged = clone_json(construction());
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} =~ s/9053010565424434193/0/;
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity random target mutation fails closed');
    like($@, qr/construction is not canonical/,
        'post-identity rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'random_attempts',
            level => 'gate_candidate_v1',
        });
        1;
    };
    ok(!$missing, 'random gate requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');

    my $unfinished = eval {
        $class->construct({
            primary_axis => 'random_attempts',
            level => 'qualification_candidate_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unfinished, 'qualification random level cannot enter the gate slice');
    like($@, qr/execution-graph gate slice does not own the requested shape/,
        'unfinished-level rejection names the bounded frontier');
};

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleExecutionGraph;

sub _test_random_replay {
    my ($construction) = @_;
    my $inputs = _canonical_inputs($construction);
    my $generated = _build_execution($inputs);
    return ($generated, _build_replay_execution($inputs, $generated->{plan}));
}
