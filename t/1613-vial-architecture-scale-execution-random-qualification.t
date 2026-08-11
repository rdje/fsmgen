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
    attempts => 262_144,
    accepted_attempt => 262_143,
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
    vial_bytes => 1_294,
    bridge_bytes => 508_968,
    generated_plan_bytes => 34_297,
    replayed_plan_bytes => 34_296,
    target_decimal => '68173369137783556',
    target_hex => '00f233516a996304',
    workload_identity =>
        'workload/f02196c7f68daa4bcdf5754e64db75f2f039338a780bdbc0d20c110ffb805d9c',
    hial_sha256 =>
        '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c',
    vial_sha256 =>
        '0e096b3b9b720a80bc5b33a564fb80d56647a749c9d09206fc11118996cd1816',
    semantic_sha256 =>
        'c3316e6a37a20a99ff7fcaa699f976632d75e51a7f2b17d9c32086adea79671d',
    bridge_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
    generated_plan_id =>
        'plan/1f01b357206cb9b768172be41b415084b0ee49ef5494131dd50df74d195d185e',
    generated_plan_sha256 =>
        '7ced418b2ec66fad22b8dec8d347037202562e8f9c5234e165db56057df0ad69',
    replayed_plan_id =>
        'plan/a6d4516c28989dccf67d0989d7a71d8e60cc6315451761947386d86a75123ba7',
    replayed_plan_sha256 =>
        '3a5fbe358a93ff09d6ce7979de716d9389445bbf62d0e43f3bbbdae13814dce7',
);

sub construction {
    return $class->construct({
        primary_axis => 'random_attempts',
        level => 'qualification_candidate_v1',
        reference_hial_text => $reference_hial,
    });
}

my $first = construction();
my $second = construction();
my ($generated, $replayed) = $first->{ok}
    ? FSM::VIAL::ArchitectureScaleExecutionGraph::_test_random_replay(
        clone_json($first))
    : (undef, undef);
my $evaluation = $first->{ok}
    ? $class->evaluate({construction => clone_json($first)})
    : undef;

subtest 'qualification construction is canonical checked-AHB source' => sub {
    ok($first->{ok}, 'qualification constructs through the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent qualification construction is byte-identical');
    is($first->{specification}{requested_counts}{random_attempts},
        $expected{attempts}, 'construction retains 262,144 attempts');
    is($first->{workload_identity}, $expected{workload_identity},
        'qualification construction identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is(bytes::length($input{hial_source}{content}), $expected{hial_bytes},
        'checked-AHB source byte count is frozen');
    is(sha256_hex($input{hial_source}{content}), $expected{hial_sha256},
        'checked-AHB source identity is frozen');
    is($input{vial_source}{relative_path},
        'generated/vial-scale/execution_graph/vial_architecture_scale.vial',
        'qualification reuses the canonical execution-scale source route');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated qualification VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated qualification VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content}
            =~ /\Q$expected{target_decimal}\E/g),
        2, 'attempt-262,143 candidate occurs only in constraint and expectation');
    like($input{vial_source}{content},
        qr{\(choice attempt_target \(u 64\).*\(uniform 0 18446744073709551615\).*\(constraints \(value_eq \(choice attempt_target\) \Q$expected{target_decimal}\E\)\)\)}s,
        'one full-range u64 equality constraint owns rejection sampling');
    like($input{vial_source}{content},
        qr{\(expect selected_random_attempt \(value_eq \(choice attempt_target\) \Q$expected{target_decimal}\E\)\)},
        'one real check operation references the qualified choice');
};

subtest 'qualified generation and strict replay preserve the exact decision' => sub {
    ok($generated && $generated->{ok},
        'qualified decision builds through the public binder');
    diag($json->encode($generated->{diagnostics}))
        if $generated && !$generated->{ok};
    ok($replayed && $replayed->{ok},
        'strict replay builds through the same public binder');
    diag($json->encode($replayed->{diagnostics}))
        if $replayed && !$replayed->{ok};
    return unless $generated && $generated->{ok} && $replayed && $replayed->{ok};

    my $ir = $generated->{execution_ir}->as_hashref;
    my $decision = $generated->{plan}{random_decisions}[0];
    my $replay_decision = $replayed->{plan}{random_decisions}[0];
    is(scalar(@{$generated->{plan}{random_decisions}}),
        $expected{occurrences}, 'plan contains one random occurrence');
    is($decision->{occurrence_id}, $occurrence_id,
        'decision occurrence identity is exact');
    is($decision->{attempt}, $expected{accepted_attempt},
        'decision accepts exactly at zero-based attempt 262,143');
    is($decision->{value}{value_hex}, $expected{target_hex},
        'decision retains the exact 64-bit candidate');
    is($decision->{origin}, 'generated', 'generated origin is exact');
    is($replay_decision->{origin}, 'replayed', 'replayed origin is exact');

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
        'replayed plan changes only origin and derived plan identity');

    is($ir->{operation_graph}{total_operation_count}, $expected{operations},
        'qualification contains one genuine check operation');
    is($ir->{operation_graph}{total_fiber_count}, $expected{fibers},
        'qualification contains one root fiber');
    is($ir->{operation_graph}{maximum_simultaneous_live_fibers},
        $expected{live_fibers}, 'qualification isolates live width to one');
    is(scalar(@{$ir->{source_map}}), $expected{source_maps},
        'fixed, operation, and decision source maps are exact');

    my $generated_json = $json->encode($generated->{plan});
    my $replayed_json = $json->encode($replayed->{plan});
    is(bytes::length($generated_json), $expected{generated_plan_bytes},
        'generated qualification plan byte count is exact');
    is(sha256_hex($generated_json), $expected{generated_plan_sha256},
        'generated qualification plan hash is exact');
    is($generated->{plan}{plan_id}, $expected{generated_plan_id},
        'generated qualification plan identity is exact');
    is(bytes::length($replayed_json), $expected{replayed_plan_bytes},
        'replayed qualification plan byte count is exact');
    is(sha256_hex($replayed_json), $expected{replayed_plan_sha256},
        'replayed qualification plan hash is exact');
    is($replayed->{plan}{plan_id}, $expected{replayed_plan_id},
        'replayed qualification plan identity is exact');
};

subtest 'qualification evaluation freezes metrics and identities' => sub {
    ok($evaluation && $evaluation->{ok},
        'qualification passes every closed evaluation oracle');
    diag($json->encode($evaluation->{diagnostics}))
        if $evaluation && !$evaluation->{ok};
    return unless $evaluation && $evaluation->{ok};
    is($evaluation->{metrics}{random_attempts}, $expected{attempts},
        'evaluation freezes the exact attempted proposal count');
    is($evaluation->{metrics}{random_occurrences}, $expected{occurrences},
        'evaluation freezes occurrence isolation');
    is($evaluation->{metrics}{expanded_operations_total}, $expected{operations},
        'evaluation freezes operation isolation');
    is($evaluation->{metrics}{selected_scenarios}, $expected{scenarios},
        'evaluation freezes scenario isolation');
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
        'qualification has no selected contract discrepancy');
};

subtest 'qualification rejects replay mutation and unowned levels' => sub {
    my $tampered = {
        ok => JSON::PP::true,
        plan => clone_json($replayed->{plan}),
    };
    $tampered->{plan}{random_decisions}[0]{attempt} = 0;
    my @errors =
        FSM::VIAL::ArchitectureScaleExecutionGraph::_random_attempt_oracle_errors(
            $generated->{execution_ir}->as_hashref,
            $generated->{plan},
            $tampered,
            $expected{attempts},
        );
    is_deeply(
        [map { $_->{code} }
            grep { $_->{code} eq 'VIAL_SCALE_EXECUTION_REPLAY_ERROR' } @errors],
        ['VIAL_SCALE_EXECUTION_REPLAY_ERROR'],
        'replay-attempt mutation emits the stable replay diagnostic once',
    );

    my $missing = eval {
        $class->construct({
            primary_axis => 'random_attempts',
            level => 'qualification_candidate_v1',
        });
        1;
    };
    ok(!$missing, 'qualification requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');

    my $unfinished = eval {
        $class->construct({
            primary_axis => 'random_attempts',
            level => 'limit_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unfinished, 'one-million-attempt level remains outside this slice');
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
