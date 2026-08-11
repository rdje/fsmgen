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
    scenarios => 4_096,
    operations => 4_096,
    fibers => 4_096,
    live_fibers => 1,
    source_maps => 4_113,
    vial_bytes => 312_259,
    bridge_bytes => 508_968,
    plan_bytes => 3_779_103,
    workload_identity =>
        'workload/0398009d081f04e116a61c70a8946941c2d704f3a46476e16e9477a66b7abb7f',
    vial_sha256 =>
        'cd01d5467e14d761cd2b953e4714e7515a4c86af7be3c3189e9834eda1e30fa1',
    semantic_sha256 =>
        '91d0d42b946bda6e7b4a56df0133490481faf717e7210564ffc254e5a60f9267',
    bridge_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
    plan_id =>
        'plan/036742cfb80ab0f04cf7a7c8d9be1de833f310f5fde98ca3be9e47d331294cfc',
    plan_sha256 =>
        '0eefa683b36a6be1983b9730a80d9a9bd3e84c1f0a161aa816f72dedeabce6df',
);

sub construction {
    return $class->construct({
        primary_axis => 'scenarios',
        level => 'limit_v1',
        reference_hial_text => $reference_hial,
    });
}

my $first = construction();
my $second = construction();
my $built = $first->{ok} ? $class->build({construction => clone_json($first)}) : undef;
my $evaluation = $first->{ok}
    ? $class->evaluate({construction => clone_json($first)})
    : undef;

subtest '4,096-scenario construction is canonical checked-AHB source' => sub {
    ok($first->{ok}, 'limit construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent limit construction is byte-identical');
    is($first->{specification}{requested_counts}{scenarios},
        $expected{scenarios}, 'construction retains exactly 4,096 scenarios');
    is($first->{workload_identity}, $expected{workload_identity},
        'limit workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is($input{hial_source}{content}, $reference_hial,
        'construction retains every checked-AHB source byte');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated limit VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated limit VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content} =~ /\(scenario scenario_/g),
        $expected{scenarios}, 'source authors exactly 4,096 genuine scenarios');
};

subtest 'public binder accepts the exact scenario limit' => sub {
    ok($built && $built->{ok}, 'limit builds through the public binder');
    diag($json->encode($built->{diagnostics})) if $built && !$built->{ok};
    return unless $built && $built->{ok};
    my $ir = $built->{execution_ir}->as_hashref;
    is(scalar(@{$ir->{scenarios}}), $expected{scenarios},
        'execution IR reaches the exact scenario limit');
    is($ir->{operation_graph}{total_operation_count}, $expected{operations},
        'limit retains one genuine operation per scenario');
    is($ir->{operation_graph}{total_fiber_count}, $expected{fibers},
        'limit retains one root fiber per scenario');
    is($ir->{operation_graph}{maximum_simultaneous_live_fibers},
        $expected{live_fibers}, 'limit isolates simultaneous liveness');
    is($ir->{scenarios}[0]{name}, 'scenario_00000000',
        'first limit scenario name is exact');
    is($ir->{scenarios}[-1]{name}, 'scenario_00004095',
        'last limit scenario name is exact');
    ok(!scalar(grep { $_->{plan_summary}{operation_count} != 1 }
            @{$ir->{scenarios}}),
        'every limit scenario retains one operation');
    ok(!scalar(grep { $_->{kind} ne 'reset' || $_->{eligible_phase} ne 'drive' }
            @{$ir->{operation_graph}{operations}}),
        'every limit operation is a genuine drive-phase reset');
    is(scalar(@{$ir->{source_map}}), $expected{source_maps},
        'fixed and per-operation source maps are exact');

    my %operation_maps;
    for my $record (@{$ir->{source_map}}) {
        $operation_maps{$1}++ if $record->{plan_path}
            =~ m{\A/operation_graph/operations/([0-9]+)\z};
    }
    is_deeply(\%operation_maps,
        {map { $_ => 1 } 0 .. $expected{operations} - 1},
        'every limit operation has one unique global source map');

    my $plan_json = $json->encode($built->{plan});
    is(bytes::length($plan_json), $expected{plan_bytes},
        'limit plan byte count is exact');
    is(sha256_hex($plan_json), $expected{plan_sha256},
        'limit plan hash is exact');
    is($built->{plan}{plan_id}, $expected{plan_id},
        'limit plan identity is exact');
};

subtest '4,096-scenario evaluation freezes metrics and identities' => sub {
    ok($evaluation && $evaluation->{ok},
        'limit passes every closed evaluation oracle');
    diag($json->encode($evaluation->{diagnostics}))
        if $evaluation && !$evaluation->{ok};
    return unless $evaluation && $evaluation->{ok};
    is($evaluation->{metrics}{selected_scenarios}, $expected{scenarios},
        'evaluation freezes the exact scenario limit');
    is($evaluation->{metrics}{expanded_operations_per_scenario}, 1,
        'evaluation freezes per-scenario isolation');
    is($evaluation->{metrics}{expanded_operations_total}, $expected{operations},
        'evaluation freezes total operations');
    is($evaluation->{metrics}{total_fibers}, $expected{fibers},
        'evaluation freezes total fibers');
    is($evaluation->{metrics}{simultaneous_live_fibers}, $expected{live_fibers},
        'evaluation freezes simultaneous liveness');
    is($evaluation->{metrics}{source_map_records}, $expected{source_maps},
        'evaluation freezes source maps');
    is($evaluation->{metrics}{serialized_bridge_manifest_bytes},
        $expected{bridge_bytes}, 'evaluation freezes canonical bridge bytes');
    is($evaluation->{metrics}{serialized_plan_bytes}, $expected{plan_bytes},
        'evaluation freezes canonical plan bytes');
    is($evaluation->{semantic_ir_sha256}, $expected{semantic_sha256},
        'SemanticIR identity is exact');
    is($evaluation->{bridge_manifest_sha256}, $expected{bridge_sha256},
        'bridge identity is exact');
    is($evaluation->{plan_sha256}, $expected{plan_sha256},
        'plan identity is exact');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'limit has no selected contract discrepancy');
};

subtest 'scenario limit rejects source mutation and missing authority' => sub {
    my $forged = clone_json($first);
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({primary_axis => 'scenarios', level => 'limit_v1'});
        1;
    };
    ok(!$missing, 'limit requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');
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
