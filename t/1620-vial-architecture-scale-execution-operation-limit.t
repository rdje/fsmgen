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
    operations => 65_536,
    scenarios => 1,
    vial_bytes => 918_533,
    workload_identity =>
        'workload/e12891837682502f4e31dc4bb0fd8970002f2c32ae6842b63f69cc1ae20761ca',
    vial_sha256 =>
        '1c1b5be3178746ffadfed69bfa3ef8427569f79aec4c9b6b246d6cec690fd25f',
    semantic_sha256 =>
        'fb82ce2ca33527481c9a6b67d9eb0f33fc47767ab25dfcd426769caefef8ec0f',
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
        . ' 65536-operation execution limit',
    path => '/requested_counts/operations_per_scenario',
    repair_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4',
};

sub construction {
    return $class->construct({
        primary_axis => 'operations_per_scenario',
        level => 'limit_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest '65,536-operation construction is canonical checked-AHB source' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'limit construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent limit construction is byte-identical');
    is($first->{specification}{requested_counts}{operations_per_scenario},
        $expected{operations},
        'construction retains exactly 65,536 operations in one scenario');
    is($first->{workload_identity}, $expected{workload_identity},
        'limit workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is($input{hial_source}{relative_path}, 'ppif/ahb_lite_subordinate.ppif',
        'construction retains the frozen checked-AHB source identity');
    is($input{hial_source}{content}, $reference_hial,
        'construction retains every checked-AHB source byte');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated limit VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated limit VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content} =~ /\(scenario scenario_/g),
        $expected{scenarios}, 'source authors exactly one genuine scenario');
    is(scalar(() = $input{vial_source}{content} =~ /\(reset bus 1\)/g),
        $expected{operations},
        'source authors exactly 65,536 genuine reset operations');
};

subtest 'ordinary semantic and bridge stages accept the nominal operation cap' => sub {
    my $inputs =
        FSM::VIAL::ArchitectureScaleExecutionGraph::_test_execution_inputs(
            clone_json(construction()));
    is($inputs->{semantic_rejection}, undef,
        'the 65,536-action scenario stays inside the semantic expanded-action cap');
    is(sha256_hex($json->encode($inputs->{semantic_ir}->as_hashref)),
        $expected{semantic_sha256},
        'ordinary parser produces the exact limit SemanticIR identity');
    is(sha256_hex($json->encode($inputs->{bridge_manifest}->as_hashref)),
        $expected{bridge_sha256},
        'ordinary checked-AHB bridge identity remains frozen');
    my $fixture = $inputs->{semantic_ir}->as_hashref->{packages}[0]{fixtures}[0];
    is(scalar(@{$fixture->{scenarios}}), $expected{scenarios},
        'SemanticIR retains exactly one authored scenario');
    is($fixture->{scenarios}[0]{action_count}, $expected{operations},
        'SemanticIR retains all 65,536 expanded actions');
    is(scalar(@{$fixture->{scenarios}[0]{actions}}), $expected{operations},
        'every expanded action is one authored scenario step');
};

subtest 'public builder rejects at the serialized-plan cap without partial output' => sub {
    my $first = $class->build({construction => construction()});
    my $second = $class->build({construction => construction()});
    ok(!$first->{ok}, 'the nominal operation limit is rejected by plan bytes');
    is($json->encode($second), $json->encode($first),
        'independent operation-limit rejection is byte-identical');
    is($first->{execution_ir}, undef,
        'plan-cap rejection exposes no partial execution IR');
    is($first->{plan}, undef, 'plan-cap rejection exposes no partial plan');
    is_deeply($first->{diagnostics}, [$expected_diagnostic],
        'builder returns the one exact authoritative plan-byte diagnostic');
};

subtest 'evaluation records the selected plan-cap dominance' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'limit evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies the dominated operation limit as expected');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the rejected outcome');
    is_deeply($evaluation->{diagnostics}, [$expected_diagnostic],
        'evaluation preserves the exact builder diagnostic');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is_deeply($evaluation->{contract_discrepancies}, [$expected_discrepancy],
        'evaluation names the earlier serialized-plan authority and its repair owner');

    my $forged = clone_json(construction());
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'operations_per_scenario',
            level => 'limit_v1',
        });
        1;
    };
    ok(!$missing, 'limit construction requires the frozen checked-AHB source');
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

package FSM::VIAL::ArchitectureScaleExecutionGraph;

sub _test_execution_inputs {
    my ($construction) = @_;
    return _canonical_inputs($construction);
}
