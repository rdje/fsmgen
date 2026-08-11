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
    scenarios => 4_097,
    vial_bytes => 312_335,
    workload_identity =>
        'workload/180f1d463b4c588d554fad4a8a67c0aa93e188becc6c6cbb8deea3f74d9ebed8',
    vial_sha256 =>
        '939681a3c097e5107c51008a417e898ff27e31303cf17f43fa3d715286b407bb',
    semantic_sha256 =>
        '9f71a505ef53f133af9e563a7a71358e71be891d5ba630b0cd12f070d0f0c638',
    bridge_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
);
my $expected_diagnostic = {
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_EXECUTION_LIMIT_ERROR',
    phase => 'limit',
    message => 'selected_scenarios exceeds the limit 4096',
    semantic_path => '/scenario_ids',
    source_location => undef,
    bridge_fact_paths => [],
    related => [],
};

sub construction {
    return $class->construct({
        primary_axis => 'scenarios',
        level => 'over_limit_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest '4,097-scenario construction targets the first excess' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'one-over construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent one-over construction is byte-identical');
    is($first->{specification}{requested_counts}{scenarios},
        $expected{scenarios}, 'construction retains exactly 4,097 scenarios');
    is($first->{workload_identity}, $expected{workload_identity},
        'one-over workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is($input{hial_source}{content}, $reference_hial,
        'construction retains every checked-AHB source byte');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated one-over VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated one-over VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content} =~ /\(scenario scenario_/g),
        $expected{scenarios}, 'source authors exactly 4,097 genuine scenarios');
    like($input{vial_source}{content}, qr/\(scenario scenario_00004096 /,
        'source ends with the adjacent first-excess scenario');
};

subtest 'ordinary semantic and bridge construction reaches scenario authority' => sub {
    my $inputs =
        FSM::VIAL::ArchitectureScaleExecutionGraph::_test_scenario_inputs(
            clone_json(construction()));
    is(sha256_hex($json->encode($inputs->{semantic_ir}->as_hashref)),
        $expected{semantic_sha256},
        'ordinary parser produces the exact one-over SemanticIR identity');
    is(sha256_hex($json->encode($inputs->{bridge_manifest}->as_hashref)),
        $expected{bridge_sha256},
        'ordinary checked-AHB bridge identity remains frozen');
    my $fixture = $inputs->{semantic_ir}->as_hashref->{packages}[0]{fixtures}[0];
    is(scalar(@{$fixture->{scenarios}}), $expected{scenarios},
        'SemanticIR retains all 4,097 authored scenarios');
    is($fixture->{scenarios}[-1]{name}, 'scenario_00004096',
        'SemanticIR retains the adjacent first-excess scenario name');
};

subtest 'public builder rejects scenario excess without partial output' => sub {
    my $first = $class->build({construction => construction()});
    my $second = $class->build({construction => construction()});
    ok(!$first->{ok}, 'the first scenario excess is rejected');
    is($json->encode($second), $json->encode($first),
        'independent scenario rejection is byte-identical');
    is($first->{execution_ir}, undef,
        'scenario rejection exposes no partial execution IR');
    is($first->{plan}, undef, 'scenario rejection exposes no partial plan');
    is_deeply($first->{diagnostics}, [$expected_diagnostic],
        'builder returns the one exact authoritative scenario diagnostic');
};

subtest 'evaluation recognizes exact scenario excess and rejects mutation' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'one-over evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies scenario excess as expected');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the rejected outcome');
    is_deeply($evaluation->{diagnostics}, [$expected_diagnostic],
        'evaluation preserves the exact builder diagnostic');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'selected scenario boundary has no earlier-stage discrepancy');

    my $forged = clone_json(construction());
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({primary_axis => 'scenarios', level => 'over_limit_v1'});
        1;
    };
    ok(!$missing, 'one-over construction requires frozen checked-AHB source');
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

sub _test_scenario_inputs {
    my ($construction) = @_;
    return _canonical_inputs($construction);
}
