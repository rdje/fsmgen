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
use FSM::VIAL::ArchitectureScaleWorkload;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my %expected = (
    operations => 65_536,
    scenarios => 32,
    operations_per_scenario => 2_048,
    vial_bytes => 920_547,
    workload_identity =>
        'workload/133663d3c9fbee1e164a3acc2b53fc7b2773d73fe012b4de7d626dcfe12d65a8',
    vial_sha256 =>
        '8f9f1fe34005022f03328459f6b3e806baceb36a9d292e01679e3f2b59fbe688',
    semantic_sha256 =>
        '3235975f912e56b78fef27836f8db252f99f2ff5d43e3d3fe5ceb95c15109a82',
    bridge_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
);
my $expected_diagnostic = {
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_EXECUTION_LIMIT_ERROR',
    phase => 'limit',
    message => 'serialized_plan_bytes exceeds the limit 16777216',
    semantic_path => '/plan',
    source_location => undef,
    bridge_fact_paths => [],
    related => [],
};
my $expected_discrepancy = {
    code => 'VIAL_SCALE_LIMIT_INTERACTION',
    message => 'the 16777216-byte serialized-plan cap precedes the selected'
        . ' 65536-operation total qualification level, so this axis'
        . ' has no nominal operating point above its 1024-operation gate',
    path => '/requested_counts/operations_total',
    repair_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4',
};

sub construction {
    return $class->construct({
        primary_axis => 'operations_total',
        level => 'qualification_candidate_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest '65,536-total-operation construction fans out over 32 scenarios' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'qualification construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent qualification construction is byte-identical');
    is($first->{specification}{requested_counts}{operations_total},
        $expected{operations},
        'construction retains exactly 65,536 total operations');
    is($first->{workload_identity}, $expected{workload_identity},
        'total-operation qualification workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is($input{hial_source}{relative_path}, 'ppif/ahb_lite_subordinate.ppif',
        'construction retains the frozen checked-AHB source identity');
    is($input{hial_source}{content}, $reference_hial,
        'construction retains every checked-AHB source byte');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated total-operation VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated total-operation VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content} =~ /\(scenario scenario_/g),
        $expected{scenarios},
        'source authors exactly 32 genuine scenarios');
    is(scalar(() = $input{vial_source}{content} =~ /\(reset bus 1\)/g),
        $expected{operations},
        'source authors exactly 65,536 genuine reset operations');
};

subtest 'ordinary semantic and bridge stages accept the whole fanned-out total' => sub {
    my $inputs =
        FSM::VIAL::ArchitectureScaleExecutionGraph::_test_execution_inputs(
            clone_json(construction()));
    is($inputs->{semantic_rejection}, undef,
        'no scenario approaches the 65,536 expanded-action semantic cap');
    is(sha256_hex($json->encode($inputs->{semantic_ir}->as_hashref)),
        $expected{semantic_sha256},
        'ordinary parser produces the exact total-operation SemanticIR identity');
    is(sha256_hex($json->encode($inputs->{bridge_manifest}->as_hashref)),
        $expected{bridge_sha256},
        'ordinary checked-AHB bridge identity remains frozen');

    my $fixture = $inputs->{semantic_ir}->as_hashref->{packages}[0]{fixtures}[0];
    is(scalar(@{$fixture->{scenarios}}), $expected{scenarios},
        'SemanticIR retains exactly 32 authored scenarios');
    my @counts = map { $_->{action_count} } @{$fixture->{scenarios}};
    is_deeply([grep { $_ != $expected{operations_per_scenario} } @counts], [],
        'every scenario expands to exactly 2,048 actions');
    my $total = 0;
    $total += $_ for @counts;
    is($total, $expected{operations},
        'expanded actions sum to exactly 65,536 total operations');
};

subtest 'public builder rejects at the serialized-plan cap without partial output' => sub {
    my $first = $class->build({construction => construction()});
    my $second = $class->build({construction => construction()});
    ok(!$first->{ok},
        'the nominal total-operation qualification level is rejected by plan bytes');
    is($json->encode($second), $json->encode($first),
        'independent total-operation rejection is byte-identical');
    is($first->{execution_ir}, undef,
        'plan-cap rejection exposes no partial execution IR');
    is($first->{plan}, undef, 'plan-cap rejection exposes no partial plan');
    is_deeply($first->{diagnostics}, [$expected_diagnostic],
        'builder returns the one exact authoritative plan-byte diagnostic');
};

subtest 'evaluation records an unreachable qualification level' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'qualification evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies the dominated qualification level as expected');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the rejected outcome');
    is_deeply($evaluation->{diagnostics}, [$expected_diagnostic],
        'evaluation preserves the exact builder diagnostic');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is_deeply($evaluation->{contract_discrepancies}, [$expected_discrepancy],
        'evaluation names the earlier plan authority, the absent nominal'
            . ' operating point, and the repair owner');

    my $forged = clone_json(construction());
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'operations_total',
            level => 'qualification_candidate_v1',
        });
        1;
    };
    ok(!$missing, 'qualification construction requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');
};

# The two higher total-operation levels are owned by their own slice and frozen
# by t/1626; this file keeps proving where the generator still stops.
subtest 'the still-unowned execution axes stay unowned' => sub {
    # The owned frontier is published by the generator, so this proves the
    # boundary by deriving it from the catalog instead of restating a list that
    # goes stale the moment the next level lands.
    my %owned;
    $owned{"$_->{primary_axis}/$_->{level}"} = 1
        for @{$class->owned_shapes};
    my $axes = FSM::VIAL::ArchitectureScaleWorkload->catalog
        ->{families}{execution_graph_v1}{axes};
    my @unowned;
    for my $axis (sort keys %{$axes}) {
        for my $level (sort keys %{$axes->{$axis}{levels}}) {
            push @unowned, [$axis, $level] unless $owned{"$axis/$level"};
        }
    }
    cmp_ok(scalar(@unowned), '>', 0,
        'the caller-sealed generator still has an unowned frontier');

    my (@accepted, %reason);
    for my $shape (@unowned) {
        my ($axis, $level) = @{$shape};
        if (eval { $class->construct({primary_axis => $axis, level => $level}); 1 }) {
            push @accepted, "$axis/$level";
            next;
        }
        $reason{"$axis/$level"} = $@;
    }
    is_deeply(\@accepted, [],
        'every catalog shape outside the published owned frontier fails closed');
    is_deeply(
        [grep { $reason{$_} !~ /does not own the requested shape/ } sort keys %reason],
        [],
        'each unowned rejection names the caller-sealed generator boundary');
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

sub _test_execution_inputs {
    my ($construction) = @_;
    return _canonical_inputs($construction);
}
