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

my %limit = (
    fibers => 16_384,
    vial_bytes => 738_151,
    vial_sha256 =>
        'd01cd85db1e17b4ad744131e9835d7f3585a9ef37cd0b4aad860eb7addb6c16d',
    workload_identity =>
        'workload/b9a2cb7b7df416d3b3f1625fbdf4582924621391eeb9ae44edc366c03d8030a9',
    semantic_sha256 =>
        'a9ae7d2e01ed702932f11852c02526658567d0bc945ef4749ae5ae51e8c578fc',
    plan_sha256 =>
        'c58feb7f65d39c308a9e7bdcacf8b31b28388ddedf0e89f50ecb047c2c515cdf',
    operations => 16_384,
    source_maps => 16_401,
    plan_bytes => 6_553_464,
);
my %over = (
    fibers => 16_385,
    vial_bytes => 738_196,
    vial_sha256 =>
        '2588bfc616c47635580568f6db49ed0b09429a38cc36ce7a144ea56574be97ad',
    workload_identity =>
        'workload/54e387679e36976e8319e7d4eecd36125dadfee92a8c292683f9e6145332e29a',
    semantic_sha256 =>
        '3441b80a95c4c680447d5a36a81d1add124cdbc4a151ed50950c3ef4b6bbfada',
);
my $expected_diagnostic = {
    schema_version => 1,
    severity => 'error',
    code => 'VIAL_EXECUTION_LIMIT_ERROR',
    phase => 'limit',
    message => 'simultaneous_live_fibers exceeds the limit 16384',
    semantic_path => '/operation_graph/maximum_simultaneous_live_fibers',
    source_location => undef,
    bridge_fact_paths => [],
    related => [],
};

sub construction {
    my ($level) = @_;
    return $class->construct({
        primary_axis => 'simultaneously_live_fibers',
        level => $level,
        reference_hial_text => $reference_hial,
    });
}

subtest 'the 16,384 live-fiber limit is reached exactly' => sub {
    my $first = construction('limit_v1');
    my $second = construction('limit_v1');
    ok($first->{ok}, 'limit construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent limit construction is byte-identical');
    is($first->{specification}{requested_counts}{simultaneously_live_fibers},
        $limit{fibers}, 'construction retains exactly 16,384 live fibers');
    is($first->{workload_identity}, $limit{workload_identity},
        'limit workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is($input{hial_source}{content}, $reference_hial,
        'construction retains every checked-AHB source byte');
    is(bytes::length($input{vial_source}{content}), $limit{vial_bytes},
        'generated limit VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $limit{vial_sha256},
        'generated limit VIAL identity is frozen');

    my $evaluation = $class->evaluate({construction => construction('limit_v1')});
    ok($evaluation->{ok}, 'limit evaluation satisfies every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{status}, 'accepted',
        'the nominal live-fiber limit is genuinely reachable');
    is_deeply($evaluation->{diagnostics}, [], 'an accepted limit reports no diagnostic');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'the axis reaches its own cap, so no limit interaction is recorded');
    is($evaluation->{semantic_ir_sha256}, $limit{semantic_sha256},
        'ordinary parser produces the exact limit SemanticIR identity');
    is($evaluation->{bridge_manifest_sha256}, $bridge_sha256,
        'ordinary checked-AHB bridge identity remains frozen');
    is($evaluation->{plan_sha256}, $limit{plan_sha256},
        'limit plan identity is frozen');

    my $metrics = $evaluation->{metrics};
    is($metrics->{simultaneous_live_fibers}, $limit{fibers},
        'plan reports exactly 16,384 simultaneously live fibers');
    is($metrics->{total_fibers}, $limit{fibers},
        'every fiber is live at the same instant');
    is($metrics->{expanded_operations_total}, $limit{operations},
        'plan reports the exact expanded operation total');
    is($metrics->{source_map_records}, $limit{source_maps},
        'plan reports one source map per global operation index');
    is($metrics->{serialized_plan_bytes}, $limit{plan_bytes},
        'serialized plan byte count is exact');
    cmp_ok($metrics->{serialized_plan_bytes}, '<', 16_777_216,
        'the plan cap does not pre-empt this axis, so the cap reached is its own');
};

subtest 'one further live fiber is rejected by the axis own cap' => sub {
    my $first = construction('over_limit_v1');
    ok($first->{ok}, 'over-limit construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($first->{specification}{requested_counts}{simultaneously_live_fibers},
        $over{fibers}, 'construction retains exactly 16,385 live fibers');
    is($first->{workload_identity}, $over{workload_identity},
        'over-limit workload identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is(bytes::length($input{vial_source}{content}), $over{vial_bytes},
        'generated over-limit VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $over{vial_sha256},
        'generated over-limit VIAL identity is frozen');
    is($over{vial_bytes} - $limit{vial_bytes}, 45,
        'the over-limit source adds exactly one 45-byte nested fiber record');

    my $inputs =
        FSM::VIAL::ArchitectureScaleExecutionGraph::_test_execution_inputs(
            clone_json(construction('over_limit_v1')));
    is($inputs->{semantic_rejection}, undef,
        'the ordinary semantic stage accepts the over-limit source');
    is(sha256_hex($json->encode($inputs->{semantic_ir}->as_hashref)),
        $over{semantic_sha256},
        'ordinary parser produces the exact over-limit SemanticIR identity');
    is(sha256_hex($json->encode($inputs->{bridge_manifest}->as_hashref)),
        $bridge_sha256,
        'the canonical checked-AHB bridge is built before the rejection');
    is($inputs->{semantic_ir}->as_hashref->{packages}[0]{fixtures}[0]
            {scenarios}[0]{action_count},
        $over{fibers}, 'SemanticIR retains all 16,385 expanded actions');
};

subtest 'the over-limit rejection is exact and leaves no partial output' => sub {
    my $first = $class->build({construction => construction('over_limit_v1')});
    my $second = $class->build({construction => construction('over_limit_v1')});
    ok(!$first->{ok}, 'the public builder rejects one fiber above the cap');
    is($json->encode($second), $json->encode($first),
        'independent over-limit rejection is byte-identical');
    is($first->{execution_ir}, undef,
        'live-fiber rejection exposes no partial execution IR');
    is($first->{plan}, undef, 'live-fiber rejection exposes no partial plan');
    is_deeply($first->{diagnostics}, [$expected_diagnostic],
        'builder returns the one exact authoritative live-fiber diagnostic');

    my $evaluation = $class->evaluate({construction => construction('over_limit_v1')});
    ok($evaluation->{ok}, 'over-limit evaluation satisfies every closed oracle');
    is($evaluation->{status}, 'expected_rejection',
        'evaluation classifies the boundary rejection as expected');
    is($evaluation->{observed_outcome}, 'rejected',
        'evaluation records the rejected outcome');
    is_deeply($evaluation->{diagnostics}, [$expected_diagnostic],
        'evaluation preserves the exact builder diagnostic');
    is_deeply($evaluation->{metrics}, {},
        'rejection reports no measurements from a partial plan');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'no earlier authority pre-empts this cap, so nothing is routed to .17.4');
};

subtest 'the live-fiber ladder still fails closed on mutation and unowned shapes' => sub {
    my $forged = clone_json(construction('limit_v1'));
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'simultaneously_live_fibers',
            level => 'limit_v1',
        });
        1;
    };
    ok(!$missing, 'limit construction requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');

    for my $level (qw(limit_v1 over_limit_v1)) {
        my $owned = eval {
            $class->construct({
                primary_axis => 'fibers_total',
                level => $level,
                reference_hial_text => $reference_hial,
            });
            1;
        };
        ok(!$owned, "total-fiber $level remains unowned by this slice");
        like($@, qr/does not own the requested shape/,
            "unowned total-fiber $level names the caller-sealed generator");
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

sub _test_execution_inputs {
    my ($construction) = @_;
    return _canonical_inputs($construction);
}
