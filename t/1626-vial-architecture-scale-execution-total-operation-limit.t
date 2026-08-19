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
my $bridge_sha256 =
    'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca';
my $source_cap = 1_048_576;
my $plan_cap = 16_777_216;
my $scenario_fanout = 32;

my %limit = (
    operations => 1_000_000,
    vial_bytes => 4_003,
    vial_sha256 =>
        '1b7b67a8892782bf6cee513f661dc0fefd6dd27546fe087a62628af23c7ea6dd',
    workload_identity =>
        'workload/d9c0715623f767c713c60c03317f189ee6748638b280d5448bdc239364993248',
    semantic_sha256 =>
        '84b4e5a0a7f1257dfdb8153c5120172f34663ab1207b6d6e4748497ad6912eab',
    repeat_count => 31_249,
    action_counts => [(31_250) x 32],
);
my %over = (
    operations => 1_000_001,
    vial_bytes => 4_003,
    vial_sha256 =>
        'ee4aca00a3ef1690ac3bbc54065476f1010b84b7e47b0b2c83d7fc58c6a657ed',
    workload_identity =>
        'workload/3aaec35cea156aa908161ea4e929143414708c6fa6867fc013927bd914d1ce30',
    semantic_sha256 =>
        'f43e81e5e9d9ef9dfb19e11bf26989f36a9663d288faa7aac1b6663b117b41c2',
    action_counts => [(31_250) x 31, 31_251],
);
my $operation_diagnostic = {
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_EXECUTION_LIMIT_ERROR',
    phase => 'limit',
    message => 'expanded_operations_total exceeds the limit 1000000',
    semantic_path => '/operation_graph/operations',
    source_location => undef,
    bridge_fact_paths => [],
    related => [],
};
my $repair_owner = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4';

sub construction {
    my ($level) = @_;
    return $class->construct({
        primary_axis => 'operations_total',
        level => $level,
        reference_hial_text => $reference_hial,
    });
}

subtest 'the literal 32-scenario recipe cannot author either level' => sub {
    my $literal = $class->_test_render_literal($limit{operations});
    cmp_ok(bytes::length($literal), '>', $source_cap,
        'a literal 1,000,000-operation source exceeds the VIAL source cap');
    is(bytes::length($literal), 14_003_075,
        'the literal limit source is exactly 14,003,075 bytes');

    my $indivisible = eval { $class->_test_render_literal($over{operations}); 1 };
    ok(!$indivisible,
        'the literal recipe cannot even shape 1,000,001 over its fixed fanout');
    like($@, qr/not divisible by its scenario fanout/,
        'the literal rejection names the fixed 32-scenario fanout');

    my $largest = 74_656;
    cmp_ok(bytes::length($class->_test_render_literal($largest)), '<=',
        $source_cap, 'the literal recipe still fits at 74,656 operations');
    cmp_ok(
        bytes::length($class->_test_render_literal($largest + $scenario_fanout)),
        '>', $source_cap,
        'one further literal operation per scenario crosses the cap');
};

subtest 'the compact recipe reaches each exact operation count' => sub {
    for my $case (\%limit, \%over) {
        my @blocks = $class->_test_repeat_recipe($case->{operations});
        is(scalar(@blocks), $scenario_fanout,
            "compact blocks keep the axis fanout at $scenario_fanout scenarios");
        is_deeply([map { $_->{actions} } @blocks], $case->{action_counts},
            'each scenario declares its exact expanded-action count');
        my $total = 0;
        $total += $_->{actions} for @blocks;
        is($total, $case->{operations},
            "compact blocks sum to exactly $case->{operations} operations");
        is_deeply([grep { $_->{actions} > 65_536 } @blocks], [],
            'no scenario approaches the 65,536 expanded-action semantic cap');
        is_deeply(
            [grep { $_->{actions} != $_->{repeat_count} + 1 } @blocks], [],
            'one repeat operation joins every expanded body');
    }
};

subtest 'the 1,000,000 limit level is authored compactly and identically' => sub {
    my $first = construction('limit_v1');
    my $second = construction('limit_v1');
    ok($first->{ok}, 'limit construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent limit construction is byte-identical');
    is($first->{specification}{requested_counts}{operations_total},
        $limit{operations}, 'construction retains exactly 1,000,000 operations');
    is($first->{workload_identity}, $limit{workload_identity},
        'limit workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is($input{hial_source}{content}, $reference_hial,
        'construction retains every checked-AHB source byte');
    is(bytes::length($input{vial_source}{content}), $limit{vial_bytes},
        'the compact limit source is four orders of magnitude below the literal form');
    is(sha256_hex($input{vial_source}{content}), $limit{vial_sha256},
        'generated limit VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content} =~ /\(repeat /g), $scenario_fanout,
        'the source authors one repeat form per scenario');
    like($input{vial_source}{content},
        qr/\(repeat \Q$limit{repeat_count}\E \(reset bus 1\)\)/,
        'each repeat form drives a genuine one-cycle bus reset');

    my $inputs = $class->_test_canonical_inputs(clone_json(construction('limit_v1')));
    is($inputs->{semantic_rejection}, undef,
        'the ordinary semantic stage accepts the compact limit source');
    my $semantic = $inputs->{semantic_ir}->as_hashref;
    is(sha256_hex($json->encode($semantic)), $limit{semantic_sha256},
        'ordinary parser produces the exact limit SemanticIR identity');
    is_deeply(
        [map { $_->{action_count} } @{$semantic->{packages}[0]{fixtures}[0]{scenarios}}],
        $limit{action_counts},
        'the parser expands each repeat form to its exact action count');
    is(sha256_hex($json->encode($inputs->{bridge_manifest}->as_hashref)),
        $bridge_sha256,
        'the canonical checked-AHB bridge is unchanged by the compact source');
};

subtest 'the limit level is established by preflight and never materialized' => sub {
    my $evaluation = $class->evaluate({construction => construction('limit_v1')});
    ok($evaluation->{ok}, 'limit evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'preflight_dominated',
        'decision 0061 clause 8 decides this level without a run');
    is($evaluation->{observed_outcome}, 'not_materialized',
        'the evaluation never claims to have observed an outcome');
    is_deeply($evaluation->{metrics}, {},
        'an unmaterialized level reports no measurement');
    is_deeply(
        [$evaluation->{semantic_ir_sha256}, $evaluation->{bridge_manifest_sha256},
            $evaluation->{plan_sha256}],
        [undef, undef, undef],
        'no stage identity is claimed for a level that was not built');
    is_deeply($evaluation->{diagnostics}, [],
        'no builder diagnostic is invented for an unrun level');

    is(scalar(@{$evaluation->{contract_discrepancies}}), 2,
        'the preflight-dominated limit records both of its facts');
    is_deeply([map { $_->{code} } @{$evaluation->{contract_discrepancies}}],
        ['VIAL_SCALE_LIMIT_INTERACTION', 'VIAL_SCALE_PREFLIGHT_DOMINANCE'],
        'the earlier authority and the preflight method are recorded separately');
    is_deeply([map { $_->{path} } @{$evaluation->{contract_discrepancies}}],
        [('/requested_counts/operations_total') x 2],
        'both records name this axis');
    is_deeply([map { $_->{repair_owner} } @{$evaluation->{contract_discrepancies}}],
        [($repair_owner) x 2],
        'limit-policy repair stays routed to .17.4');
    like($evaluation->{contract_discrepancies}[0]{message}, qr/\b$plan_cap\b/,
        'the interaction names the serialized-plan cap that would decide');
    like($evaluation->{contract_discrepancies}[1]{message}, qr/\b21511563\b/,
        'the preflight record names the measured witness plan size');
    like($evaluation->{contract_discrepancies}[1]{message}, qr/\b65536\b/,
        'the preflight record names the witness level that already dominates');

    my $materialized = eval { $class->build({construction => construction('limit_v1')}); 1 };
    ok(!$materialized, 'the raw builder refuses a preflight-dominated level');
    like($@, qr/preflight-dominated level is established without materialization/,
        'the refusal names the preflight, not a resource failure');
};

subtest 'one further operation is authored and parsed exactly' => sub {
    my $first = construction('over_limit_v1');
    ok($first->{ok}, 'over-limit construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($first->{specification}{requested_counts}{operations_total},
        $over{operations}, 'construction retains exactly 1,000,001 operations');
    is($first->{workload_identity}, $over{workload_identity},
        'over-limit workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is(bytes::length($input{vial_source}{content}), $over{vial_bytes},
        'generated over-limit VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $over{vial_sha256},
        'generated over-limit VIAL identity is frozen');
    isnt($input{vial_source}{content}, do {
        my %limit_input = map { $_->{role} => $_ } @{construction('limit_v1')->{inputs}};
        $limit_input{vial_source}{content};
    }, 'the one-operation boundary changes the authored source');

    my $inputs = $class->_test_canonical_inputs(clone_json(construction('over_limit_v1')));
    is($inputs->{semantic_rejection}, undef,
        'the ordinary semantic stage accepts the over-limit source');
    my $semantic = $inputs->{semantic_ir}->as_hashref;
    is(sha256_hex($json->encode($semantic)), $over{semantic_sha256},
        'ordinary parser produces the exact over-limit SemanticIR identity');
    is_deeply(
        [map { $_->{action_count} } @{$semantic->{packages}[0]{fixtures}[0]{scenarios}}],
        $over{action_counts},
        'the trailing scenario carries the single remainder operation');
    is(sha256_hex($json->encode($inputs->{bridge_manifest}->as_hashref)),
        $bridge_sha256,
        'the canonical checked-AHB bridge is built before the rejection');
};

subtest 'the total-operation ladder still fails closed on mutation and unowned shapes' => sub {
    my $forged = clone_json(construction('limit_v1'));
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->evaluate({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({primary_axis => 'operations_total', level => 'limit_v1'});
        1;
    };
    ok(!$missing, 'limit construction requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');

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

subtest 'exact over-limit rejection is explicit and RAM-guarded' => sub {
    plan skip_all => 'set FSMGEN_VIAL_SCALE_EXACT=1 under'
        . ' scripts/run_with_ram_guard.sh --process-max-rss-mb 6144'
        . ' for exact total-operation excess proof'
        unless $ENV{FSMGEN_VIAL_SCALE_EXACT};

    my $evaluation = $class->evaluate({construction => construction('over_limit_v1')});
    ok($evaluation->{ok}, 'over-limit evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies the boundary rejection as expected');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the observed rejected outcome');
    is_deeply($evaluation->{diagnostics}, [$operation_diagnostic],
        'the axis own total-operation cap is the one authority');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'the axis own cap is the authority here, so nothing is routed to .17.4');
    is($evaluation->{diagnostics}[0]{semantic_path}, '/operation_graph/operations',
        'the rejection is decided while the operation graph is built');
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
    my ($class, $construction) = @_;
    return _canonical_inputs($construction);
}

sub _test_repeat_recipe {
    my ($class, $requested) = @_;
    return _total_operation_repeat_recipe($requested);
}

# The literal recipe is what the two owned levels can no longer use; rendering
# it under the already-owned qualification level keeps that comparison honest.
sub _test_render_literal {
    my ($class, $requested) = @_;
    return _render_ahb_vial('operations_total', 'qualification_candidate_v1', $requested);
}
