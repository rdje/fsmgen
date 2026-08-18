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
my %expected = (
    operations => 8_192,
    scenarios => 1,
    fibers => 1,
    live_fibers => 1,
    source_maps => 8_209,
    bindings => 22,
    execution_types => 7,
    vial_bytes => 115_716,
    bridge_bytes => 508_968,
    plan_bytes => 2_955_783,
    workload_identity =>
        'workload/14cb7f921bf64d640cd1aa99922fc5155b16a97a00704f484c8ad5584270d6c7',
    vial_sha256 =>
        'ed12c09f69221f56448d041649a888ebbec1bbe63a0257d7e98ab16977f18ab8',
    semantic_sha256 =>
        'd66f865e49ea70186adb5ed55a9b190102f551d41d305e25391f2b16b9e42380',
    bridge_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
    plan_id =>
        'plan/4c6733ea702479b4c603761d333d491f7a427e9eac24dc37238331aeb624f990',
    plan_sha256 =>
        '3d57c935b2916a8a883e457d6300ba3582216721dd3e5cf172e8474827660b6f',
);

sub construction {
    return $class->construct({
        primary_axis => 'operations_per_scenario',
        level => 'qualification_candidate_v1',
        reference_hial_text => $reference_hial,
    });
}

my $first = construction();
my $second = construction();
my $built = $first->{ok} ? $class->build({construction => clone_json($first)}) : undef;
my $evaluation = $first->{ok}
    ? $class->evaluate({construction => clone_json($first)})
    : undef;

subtest '8192-operation construction is canonical checked-AHB source' => sub {
    ok($first->{ok}, 'qualification construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent qualification construction is byte-identical');
    is($first->{specification}{requested_counts}{operations_per_scenario},
        $expected{operations},
        'construction retains exactly 8192 operations in one scenario');
    is($first->{workload_identity}, $expected{workload_identity},
        'qualification workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is($input{hial_source}{relative_path}, 'ppif/ahb_lite_subordinate.ppif',
        'construction retains the frozen checked-AHB source identity');
    is($input{hial_source}{content}, $reference_hial,
        'construction retains every checked-AHB source byte');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated qualification VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated qualification VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content} =~ /\(scenario scenario_/g),
        $expected{scenarios}, 'source authors exactly one genuine scenario');
    is(scalar(() = $input{vial_source}{content} =~ /\(reset /g),
        $expected{operations},
        'source authors exactly 8192 genuine reset operations');
};

subtest 'public binder concentrates 8192 operations in one scenario' => sub {
    ok($built && $built->{ok}, 'qualification builds through the public binder');
    diag($json->encode($built->{diagnostics})) if $built && !$built->{ok};
    return unless $built && $built->{ok};
    my $ir = $built->{execution_ir}->as_hashref;
    is(scalar(@{$ir->{scenarios}}), $expected{scenarios},
        'execution IR contains exactly one selected scenario');
    is($ir->{scenarios}[0]{name}, 'scenario_00000000',
        'the single scenario name is exact');
    is($ir->{scenarios}[0]{plan_summary}{operation_count}, $expected{operations},
        'the single scenario owns every requested operation');
    is($ir->{operation_graph}{total_operation_count}, $expected{operations},
        'operation depth rather than scenario fanout carries the axis');
    is($ir->{operation_graph}{total_fiber_count}, $expected{fibers},
        'one scenario still owns exactly one root fiber');
    is($ir->{operation_graph}{maximum_simultaneous_live_fibers},
        $expected{live_fibers},
        'sequential operation depth does not inflate live width');
    ok(!scalar(grep { $_->{kind} ne 'reset' || $_->{eligible_phase} ne 'drive' }
            @{$ir->{operation_graph}{operations}}),
        'every operation is a genuine drive-phase reset');
    is(scalar(@{$ir->{source_map}}), $expected{source_maps},
        'fixed and per-operation source maps are exact');

    my %operation_maps;
    my %semantic_paths;
    for my $record (@{$ir->{source_map}}) {
        next unless $record->{plan_path}
            =~ m{\A/operation_graph/operations/([0-9]+)\z};
        $operation_maps{$1}++;
        $semantic_paths{$1} = $record->{semantic_path};
    }
    is_deeply(\%operation_maps,
        {map { $_ => 1 } 0 .. $expected{operations} - 1},
        'every global operation index has one unique source map');
    is_deeply(\%semantic_paths,
        {map { $_ => "/packages/0/fixtures/0/scenarios/0/actions/$_" }
            0 .. $expected{operations} - 1},
        'each operation maps back to its own authored scenario action');

    my %capability = map { $_->{capability_id} => $_ }
        @{$built->{plan}{capability_ledger}};
    ok($capability{'hial_vial.bridge_protocol.ahb_subordinate_v1'},
        'qualification retains the public checked-AHB bridge capability');
    ok(!$capability{'hial_vial.bridge_qualification.architecture_scale_v1'},
        'qualification does not use the private binding capability');

    my $plan_json = $json->encode($built->{plan});
    is(bytes::length($plan_json), $expected{plan_bytes},
        'qualification plan byte count is exact and below the 16-MiB cap');
    is(sha256_hex($plan_json), $expected{plan_sha256},
        'qualification plan hash is exact');
    is($built->{plan}{plan_id}, $expected{plan_id},
        'qualification plan identity is exact');
};

subtest '8192-operation evaluation freezes metrics and identities' => sub {
    ok($evaluation && $evaluation->{ok},
        'qualification passes every closed evaluation oracle');
    diag($json->encode($evaluation->{diagnostics}))
        if $evaluation && !$evaluation->{ok};
    return unless $evaluation && $evaluation->{ok};
    is($evaluation->{metrics}{expanded_operations_per_scenario},
        $expected{operations}, 'evaluation freezes per-scenario operations');
    is($evaluation->{metrics}{expanded_operations_total}, $expected{operations},
        'evaluation freezes total operations');
    is($evaluation->{metrics}{selected_scenarios}, $expected{scenarios},
        'evaluation freezes the isolated scenario count');
    is($evaluation->{metrics}{total_fibers}, $expected{fibers},
        'evaluation freezes total fibers');
    is($evaluation->{metrics}{simultaneous_live_fibers},
        $expected{live_fibers}, 'evaluation freezes simultaneous liveness');
    is($evaluation->{metrics}{source_map_records}, $expected{source_maps},
        'evaluation freezes source maps');
    is($evaluation->{metrics}{bindings}, $expected{bindings},
        'evaluation freezes the checked-AHB binding count');
    is($evaluation->{metrics}{execution_types}, $expected{execution_types},
        'evaluation freezes the normalized execution types');
    is($evaluation->{metrics}{random_attempts}, 0,
        'operation depth introduces no random decision');
    is($evaluation->{metrics}{serialized_bridge_manifest_bytes},
        $expected{bridge_bytes}, 'evaluation freezes canonical bridge bytes');
    is($evaluation->{metrics}{serialized_plan_bytes}, $expected{plan_bytes},
        'evaluation freezes canonical plan bytes');
    is($evaluation->{semantic_ir_sha256}, $expected{semantic_sha256},
        'SemanticIR identity is exact');
    is($evaluation->{bridge_manifest_sha256}, $expected{bridge_sha256},
        'bridge identity is the frozen AHB manifest');
    is($evaluation->{plan_sha256}, $expected{plan_sha256},
        'plan identity is exact');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'qualification has no selected contract discrepancy');
};

subtest 'qualification rejects source mutation and missing authority' => sub {
    my $forged = clone_json($first);
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'operations_per_scenario',
            level => 'qualification_candidate_v1',
        });
        1;
    };
    ok(!$missing, 'qualification requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');

    my $unowned = eval {
        $class->construct({
            primary_axis => 'operations_per_scenario',
            level => 'limit_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unowned, 'the unimplemented operation limit level stays unowned');
    like($@, qr/does not own the requested shape/,
        'unowned level rejection names the generator slice boundary');
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
