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
my $bridge_sha256 =
    'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca';
my $source_cap = 1_048_576;
my $plan_cap = 16_777_216;

my %limit = (
    fibers => 65_536,
    vial_bytes => 3_199,
    vial_sha256 =>
        '56d8401f4abfac0fbb6399642f3653ae0402d66c4e1b568721035c850f920a29',
    workload_identity =>
        'workload/46eaae27edfeac4c31d4634bd48de8d6957fa9eb207ed7bba955f7bb4bb97936',
    semantic_sha256 =>
        '1fece44378b38940eadd3ae7ba2c45bc8f6a59f629440aeaf569923f945d79c5',
    action_counts => [33_825, 33_825],
);
my %over = (
    fibers => 65_537,
    vial_bytes => 4_270,
    vial_sha256 =>
        'd7423970b5ce916d59723a0e71682387fc4ada270a7970e58de707164ef5db93',
    workload_identity =>
        'workload/f62a90dac9a381123b3c1b122aadbf79e7230bf7ba66176ed236f7cd5edbb2a8',
    semantic_sha256 =>
        'd4c73a6fd755b3b217a4c9f5b1f43d2c137b2f79c82a4ad08c39fb68ead9135b',
    action_counts => [33_793, 33_858],
);
my $plan_diagnostic = {
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
my $fiber_diagnostic = {
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_EXECUTION_LIMIT_ERROR',
    phase => 'limit',
    message => 'total_fibers exceeds the limit 65536',
    semantic_path => '/operation_graph/fibers',
    source_location => undef,
    bridge_fact_paths => [],
    related => [],
};

sub construction {
    my ($level) = @_;
    return $class->construct({
        primary_axis => 'fibers_total',
        level => $level,
        reference_hial_text => $reference_hial,
    });
}

subtest 'the literal one-record recipe cannot author either level' => sub {
    for my $requested ($limit{fibers}, $over{fibers}) {
        my $literal = $class->_test_render_literal($requested);
        cmp_ok(bytes::length($literal), '>', $source_cap,
            "a literal $requested-fiber source exceeds the VIAL source cap");
    }

    my $largest = 22_536;
    cmp_ok(bytes::length($class->_test_render_literal($largest)), '<=',
        $source_cap, 'the literal recipe still fits at 22,536 fibers');
    cmp_ok(bytes::length($class->_test_render_literal($largest + 1)), '>',
        $source_cap, 'one further literal fiber record crosses the cap');
};

subtest 'the compact recipe reaches each exact fiber count' => sub {
    for my $case (\%limit, \%over) {
        my @blocks = $class->_test_repeat_recipe($case->{fibers});
        my $total = 0;
        $total += $_->{fibers} for @blocks;
        is($total, $case->{fibers},
            "compact blocks sum to exactly $case->{fibers} total fibers");
        is_deeply([map { $_->{actions} } @blocks], $case->{action_counts},
            'each block declares its exact expanded-action count');
        for my $block (@blocks) {
            cmp_ok($block->{actions}, '<=', 65_536,
                'no block exceeds the 65,536 expanded-action semantic cap');
            is($block->{width}, 31,
                'group width holds the live-fiber gate value, keeping the axes orthogonal');
        }
    }
};

subtest 'the 65,536 total-fiber limit is reached and rejected by the plan cap' => sub {
    my $first = construction('limit_v1');
    my $second = construction('limit_v1');
    ok($first->{ok}, 'limit construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent limit construction is byte-identical');
    is($first->{specification}{requested_counts}{fibers_total}, $limit{fibers},
        'construction retains exactly 65,536 total fibers');
    is($first->{workload_identity}, $limit{workload_identity},
        'limit workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is($input{hial_source}{content}, $reference_hial,
        'construction retains every checked-AHB source byte');
    is(bytes::length($input{vial_source}{content}), $limit{vial_bytes},
        'the compact limit source is three orders of magnitude below the literal form');
    is(sha256_hex($input{vial_source}{content}), $limit{vial_sha256},
        'generated limit VIAL identity is frozen');

    my $inputs = $class->_test_canonical_inputs(clone_json(construction('limit_v1')));
    is($inputs->{semantic_rejection}, undef,
        'the ordinary semantic stage accepts the compact limit source');
    my $semantic = $inputs->{semantic_ir}->as_hashref;
    is(sha256_hex($json->encode($semantic)), $limit{semantic_sha256},
        'ordinary parser produces the exact limit SemanticIR identity');
    is_deeply(
        [map { $_->{action_count} } @{$semantic->{packages}[0]{fixtures}[0]{scenarios}}],
        $limit{action_counts},
        'the parser expands each repeat block to its exact action count');
    is(sha256_hex($json->encode($inputs->{bridge_manifest}->as_hashref)),
        $bridge_sha256,
        'the canonical checked-AHB bridge is built before the rejection');

    my $built = $class->build({construction => construction('limit_v1')});
    ok(!$built->{ok}, 'the public builder rejects the limit workload');
    is($built->{execution_ir}, undef, 'rejection exposes no partial execution IR');
    is($built->{plan}, undef, 'rejection exposes no partial plan');
    is_deeply($built->{diagnostics}, [$plan_diagnostic],
        'the authority is the serialized-plan cap, not the fiber cap');

    my $evaluation = $class->evaluate({construction => construction('limit_v1')});
    ok($evaluation->{ok}, 'limit evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'the selected limit outcome is a rejection at a later authority');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the rejected outcome');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is(scalar(@{$evaluation->{contract_discrepancies}}), 1,
        'the pre-empted limit records exactly one interaction');
    is($evaluation->{contract_discrepancies}[0]{code},
        'VIAL_SCALE_LIMIT_INTERACTION', 'the interaction code is exact');
    is($evaluation->{contract_discrepancies}[0]{path},
        '/requested_counts/fibers_total', 'the interaction names its own axis');
    is($evaluation->{contract_discrepancies}[0]{repair_owner},
        'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4',
        'limit-policy repair stays routed to .17.4');
};

subtest 'one further fiber is rejected by the axis own structural cap' => sub {
    my $first = construction('over_limit_v1');
    ok($first->{ok}, 'over-limit construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($first->{specification}{requested_counts}{fibers_total}, $over{fibers},
        'construction retains exactly 65,537 total fibers');
    is($first->{workload_identity}, $over{workload_identity},
        'over-limit workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is(bytes::length($input{vial_source}{content}), $over{vial_bytes},
        'generated over-limit VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $over{vial_sha256},
        'generated over-limit VIAL identity is frozen');

    my $inputs = $class->_test_canonical_inputs(clone_json(construction('over_limit_v1')));
    is($inputs->{semantic_rejection}, undef,
        'the ordinary semantic stage accepts the over-limit source');
    is(sha256_hex($json->encode($inputs->{semantic_ir}->as_hashref)),
        $over{semantic_sha256},
        'ordinary parser produces the exact over-limit SemanticIR identity');
    is(sha256_hex($json->encode($inputs->{bridge_manifest}->as_hashref)),
        $bridge_sha256,
        'the canonical checked-AHB bridge is built before the rejection');

    my $built = $class->build({construction => construction('over_limit_v1')});
    my $again = $class->build({construction => construction('over_limit_v1')});
    ok(!$built->{ok}, 'the public builder rejects one fiber above the cap');
    is($json->encode($again), $json->encode($built),
        'independent over-limit rejection is byte-identical');
    is($built->{execution_ir}, undef, 'rejection exposes no partial execution IR');
    is($built->{plan}, undef, 'rejection exposes no partial plan');
    is_deeply($built->{diagnostics}, [$fiber_diagnostic],
        'builder returns the one exact authoritative total-fiber diagnostic');

    my $evaluation = $class->evaluate({construction => construction('over_limit_v1')});
    ok($evaluation->{ok}, 'over-limit evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies the boundary rejection as expected');
    is_deeply($evaluation->{diagnostics}, [$fiber_diagnostic],
        'evaluation preserves the exact builder diagnostic');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'the axis own cap is the authority here, so nothing is routed to .17.4');
};

subtest 'the boundary separates two different authorities' => sub {
    my %authority = map {
        my $level = $_;
        my $evaluation = $class->evaluate({construction => construction($level)});
        ($level => $evaluation->{diagnostics}[0]);
    } qw(limit_v1 over_limit_v1);

    is($authority{limit_v1}{semantic_path}, '/plan',
        'the limit level is decided after the plan is serialized');
    is($authority{over_limit_v1}{semantic_path}, '/operation_graph/fibers',
        'the over-limit level is decided while the operation graph is built');
    isnt($authority{limit_v1}{message}, $authority{over_limit_v1}{message},
        'one fiber changes which cap the workload meets first');
    like($authority{limit_v1}{message}, qr/\b$plan_cap\b/,
        'the limit authority names the serialized-plan cap');
    like($authority{over_limit_v1}{message}, qr/\b$limit{fibers}\b/,
        'the over-limit authority names the total-fiber cap the limit reached');
};

subtest 'the total-fiber ladder still fails closed on mutation and unowned shapes' => sub {
    my $forged = clone_json(construction('limit_v1'));
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({primary_axis => 'fibers_total', level => 'limit_v1'});
        1;
    };
    ok(!$missing, 'limit construction requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');

    for my $axis (qw(bindings execution_types source_map_records)) {
        my $owned = eval {
            $class->construct({
                primary_axis => $axis,
                level => 'qualification_candidate_v1',
                ($axis eq 'source_map_records'
                    ? (reference_hial_text => $reference_hial) : ()),
            });
            1;
        };
        ok(!$owned, "$axis qualification remains unowned by this slice");
        like($@, qr/does not own the requested shape/,
            "unowned $axis qualification names the caller-sealed generator");
    }
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
    return _total_fiber_repeat_recipe($requested);
}

# The literal recipe is what the two owned levels can no longer use; rendering
# it under an already-owned level keeps that comparison honest.
sub _test_render_literal {
    my ($class, $requested) = @_;
    return _render_ahb_vial('fibers_total', 'qualification_candidate_v1', $requested);
}
