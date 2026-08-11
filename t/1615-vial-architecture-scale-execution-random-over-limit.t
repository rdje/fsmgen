#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Math::BigInt;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionGraph;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path('ppif/ahb_lite_subordinate.ppif'));
my %expected = (
    attempts => 1_000_001,
    hial_bytes => 1_326,
    vial_bytes => 1_300,
    target_decimal => '14879162739822221954',
    target_hex => 'ce7d67adbe54da82',
    workload_identity =>
        'workload/37fac0e17b2c92967108a50d01fae3517f54ab77833b89d9bb659ddf52ebf4e0',
    hial_sha256 =>
        '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c',
    vial_sha256 =>
        '28102c09f9025d6b4f3cb442c9f59a2aa5d5f196eccf499201220805cf8d1ac9',
    semantic_sha256 =>
        '9b43205592907fb69f1a9d68a2345a747ef4926f121ab81da8fa9734a56162e0',
    bridge_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
);
my $expected_diagnostic = {
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_RANDOM_EXHAUSTED',
    phase => 'random',
    message => "random choice 'scale.random_attempt' exhausted its attempt limit",
    semantic_path => '/packages/0/fixtures/0/randomness/choices/0',
    source_location => {
        source_name =>
            'generated/vial-scale/execution_graph/vial_architecture_scale.vial',
        start_line => 1,
        start_column => 947,
        start_byte => 946,
        end_line => 1,
        end_column => 1131,
        end_byte_exclusive => 1131,
    },
    bridge_fact_paths => [],
    related => [],
};

sub construction {
    return $class->construct({
        primary_axis => 'random_attempts',
        level => 'over_limit_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest 'one-over construction targets the first unreachable candidate' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'one-over construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent one-over construction is byte-identical');
    is($first->{specification}{requested_counts}{random_attempts},
        $expected{attempts}, 'construction retains exactly 1,000,001 attempts');
    is($first->{workload_identity}, $expected{workload_identity},
        'one-over construction identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is(bytes::length($input{hial_source}{content}), $expected{hial_bytes},
        'checked-AHB source byte count is frozen');
    is(sha256_hex($input{hial_source}{content}), $expected{hial_sha256},
        'checked-AHB source identity is frozen');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated one-over VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated one-over VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content}
            =~ /\Q$expected{target_decimal}\E/g),
        2, 'attempt-1,000,000 candidate occurs only in constraint and expectation');
    is(Math::BigInt->new($expected{target_decimal})->as_hex,
        '0x' . $expected{target_hex}, 'one-over target has the exact u64 spelling');
    like($input{vial_source}{content},
        qr{\(choice attempt_target \(u 64\).*\(uniform 0 18446744073709551615\).*\(constraints \(value_eq \(choice attempt_target\) \Q$expected{target_decimal}\E\)\)\)}s,
        'one full-range u64 equality constraint owns exhaustion');
};

subtest 'ordinary semantic and bridge construction reaches random authority' => sub {
    my $construction = construction();
    my $inputs =
        FSM::VIAL::ArchitectureScaleExecutionGraph::_test_canonical_inputs(
            clone_json($construction));
    is(sha256_hex($json->encode($inputs->{semantic_ir}->as_hashref)),
        $expected{semantic_sha256},
        'ordinary parser produces the exact one-over SemanticIR identity');
    is(sha256_hex($json->encode($inputs->{bridge_manifest}->as_hashref)),
        $expected{bridge_sha256},
        'ordinary checked-AHB bridge identity remains frozen');
    my $fixture = $inputs->{semantic_ir}->as_hashref->{packages}[0]{fixtures}[0];
    is($fixture->{randomness}{choices}[0]{decision_id}, 'scale.random_attempt',
        'SemanticIR retains the exact random decision identity');
    is($fixture->{scenarios}[0]{actions}[0]{name}, 'selected_random_attempt',
        'one real expectation retains the constrained choice');
};

subtest 'public builder exhausts deterministically without partial output' => sub {
    my $first = $class->build({construction => construction()});
    my $second = $class->build({construction => construction()});
    ok(!$first->{ok}, 'the first unreachable candidate is rejected');
    is($json->encode($second), $json->encode($first),
        'independent exhaustion is byte-identical');
    is($first->{execution_ir}, undef,
        'exhaustion exposes no partial execution IR');
    is($first->{plan}, undef, 'exhaustion exposes no partial plan');
    is_deeply($first->{diagnostics}, [$expected_diagnostic],
        'exhaustion returns the one exact authoritative random diagnostic');
};

subtest 'evaluation recognizes exact exhaustion and rejects mutation' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'one-over evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies random exhaustion as expected');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the rejected outcome');
    is_deeply($evaluation->{diagnostics}, [$expected_diagnostic],
        'evaluation preserves the exact builder diagnostic');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'selected random boundary has no earlier-stage discrepancy');

    my $forged = clone_json(construction());
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'random_attempts',
            level => 'over_limit_v1',
        });
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

sub _test_canonical_inputs {
    my ($construction) = @_;
    return _canonical_inputs($construction);
}
