#!/usr/bin/env perl

use strict;
use warnings;

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
    fibers_total => {
        requested => 128,
        operations => 132,
        fibers => 128,
        live_fibers => 32,
        parallel_operations => 5,
        reset_operations => 127,
        child_groups => [31, 31, 31, 31, 3],
        source_maps => 149,
        plan_bytes => 79_987,
        semantic_sha256 =>
            'd4b7e972ee6f977cb1b6fc12685b7e6c532a93408915f03e78839b6cbe9082da',
        plan_sha256 =>
            '0f4b18c48451f8cf46eb71427c61f6f308010f5dfb2c09c2f8a6cb62ff7b16e7',
    },
    simultaneously_live_fibers => {
        requested => 32,
        operations => 32,
        fibers => 32,
        live_fibers => 32,
        parallel_operations => 2,
        reset_operations => 30,
        child_groups => [2, 29],
        source_maps => 49,
        plan_bytes => 43_811,
        semantic_sha256 =>
            'da5e7c01b8a34160a00342d74d6f69497f9d3dfd9928ec193828ca0cd1645294',
        plan_sha256 =>
            '9be6a6e4899bb699d1a7ecd283db54e8f83f851a7decd8e9ecd6b78abff10830',
    },
);
my $bridge_sha256 =
    'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca';

sub construction {
    my ($axis) = @_;
    return $class->construct({
        primary_axis => $axis,
        level => 'gate_candidate_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest 'fiber constructions are canonical checked-AHB inputs' => sub {
    for my $axis (sort keys %expected) {
        my $first = construction($axis);
        my $second = construction($axis);
        ok($first->{ok}, "$axis gate constructs through the workload contract");
        diag($json->encode($first->{diagnostics})) unless $first->{ok};
        is($json->encode($second), $json->encode($first),
            "$axis independent construction is byte-identical");
        is($first->{specification}{requested_counts}{$axis},
            $expected{$axis}{requested}, "$axis retains the selected request");
        is_deeply([sort map { $_->{role} } @{$first->{inputs}}],
            [qw(hial_source vial_source)],
            "$axis contains only checked-HIAL and generated-VIAL inputs");
        my ($hial) = grep { $_->{role} eq 'hial_source' } @{$first->{inputs}};
        is($hial->{relative_path}, 'ppif/ahb_lite_subordinate.ppif',
            "$axis retains the frozen checked-AHB path");
        is($hial->{content}, $reference_hial,
            "$axis retains every frozen checked-AHB byte");
    }
};

subtest 'total-fiber gate uses sequential width-bounded parallel groups' => sub {
    my $built = $class->build({construction => construction('fibers_total')});
    ok($built->{ok}, 'total-fiber gate builds through the public binder');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    my $ir = $built->{execution_ir}->as_hashref;
    my $graph = $ir->{operation_graph};
    my @parallel = grep { $_->{kind} eq 'parallel' } @{$graph->{operations}};
    my @reset = grep { $_->{kind} eq 'reset' } @{$graph->{operations}};
    is(scalar(@{$ir->{scenarios}}), 1, 'total-fiber gate isolates one scenario');
    is($graph->{total_operation_count}, $expected{fibers_total}{operations},
        'total-fiber gate has the exact operation count');
    is($graph->{total_fiber_count}, $expected{fibers_total}{fibers},
        'total-fiber gate reaches exactly 128 fibers');
    is($graph->{maximum_simultaneous_live_fibers},
        $expected{fibers_total}{live_fibers},
        'sequential grouping holds simultaneous liveness to 32');
    is(scalar(@parallel), $expected{fibers_total}{parallel_operations},
        'total-fiber gate has five sequential parallel operations');
    is(scalar(@reset), $expected{fibers_total}{reset_operations},
        'every child fiber contains one genuine reset');
    is_deeply(
        [map { scalar(@{$_->{effects}[0]{child_root_operation_ids}}) } @parallel],
        $expected{fibers_total}{child_groups},
        'parallel child groups are exactly 31/31/31/31/3',
    );
    ok(!scalar(grep { $_->{effects}[0]{join} ne 'all' } @parallel),
        'every total-fiber group has exact all-join semantics');

    my $scenario = $ir->{scenarios}[0];
    my ($root) = grep { !defined($_->{parent_fiber_id}) } @{$scenario->{fibers}};
    ok($root, 'total-fiber topology has one explicit root');
    is(scalar(grep {
        defined($_->{parent_fiber_id})
            && $_->{parent_fiber_id} eq $root->{fiber_id}
    } @{$scenario->{fibers}}), 127,
        'all 127 generated fibers are direct children of the root');
    my @root_operations = grep {
        $_->{fiber_id} eq $root->{fiber_id}
    } @{$graph->{operations}};
    for my $index (0 .. $#root_operations) {
        my @expected_successors = $index == $#root_operations
            ? ()
            : ($root_operations[$index + 1]{operation_id});
        is_deeply($root_operations[$index]{successor_ids}, \@expected_successors,
            "total-fiber group $index precedes only the next group");
    }
};

subtest 'live-fiber gate uses one exact bounded depth-two tree' => sub {
    my $built = $class->build({
        construction => construction('simultaneously_live_fibers'),
    });
    ok($built->{ok}, 'live-fiber gate builds through the public binder');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    my $ir = $built->{execution_ir}->as_hashref;
    my $graph = $ir->{operation_graph};
    my @parallel = grep { $_->{kind} eq 'parallel' } @{$graph->{operations}};
    my @reset = grep { $_->{kind} eq 'reset' } @{$graph->{operations}};
    is($graph->{total_operation_count}, $expected{simultaneously_live_fibers}{operations},
        'live-fiber gate has the exact operation count');
    is($graph->{total_fiber_count}, $expected{simultaneously_live_fibers}{fibers},
        'live-fiber gate has exactly 32 total fibers');
    is($graph->{maximum_simultaneous_live_fibers},
        $expected{simultaneously_live_fibers}{live_fibers},
        'depth-two tree reaches exactly 32 simultaneously live fibers');
    is(scalar(@parallel),
        $expected{simultaneously_live_fibers}{parallel_operations},
        'live-fiber gate has exactly outer and nested parallel operations');
    is(scalar(@reset), $expected{simultaneously_live_fibers}{reset_operations},
        'all 30 leaf fibers contain genuine resets');
    is_deeply(
        [sort { $a <=> $b } map {
            scalar(@{$_->{effects}[0]{child_root_operation_ids}})
        } @parallel],
        $expected{simultaneously_live_fibers}{child_groups},
        'outer and nested parallel fanouts are exactly 2 and 29',
    );
    ok(!scalar(grep { $_->{effects}[0]{join} ne 'all' } @parallel),
        'both live-fiber levels have exact all-join semantics');

    my $scenario = $ir->{scenarios}[0];
    my %children;
    push @{$children{$_->{parent_fiber_id}}}, $_
        for grep { defined($_->{parent_fiber_id}) } @{$scenario->{fibers}};
    my ($root) = grep { !defined($_->{parent_fiber_id}) } @{$scenario->{fibers}};
    is(scalar(@{$children{$root->{fiber_id}}}), 2,
        'root has exactly two outer fibers');
    my ($nested_parent) = grep {
        my $fiber_id = $_->{fiber_id};
        scalar(grep {
            $_->{fiber_id} eq $fiber_id && $_->{kind} eq 'parallel'
        } @{$graph->{operations}})
    } @{$children{$root->{fiber_id}}};
    ok($nested_parent, 'one outer fiber owns the nested parallel');
    is(scalar(@{$children{$nested_parent->{fiber_id}}}), 29,
        'nested parallel has exactly 29 leaf fibers');
};

subtest 'fiber evaluations freeze exact identities and complete source maps' => sub {
    for my $axis (sort keys %expected) {
        my $construction = construction($axis);
        my $built = $class->build({construction => $construction});
        my $ir = $built->{execution_ir}->as_hashref;
        my %operation_map_count;
        for my $record (@{$ir->{source_map}}) {
            $operation_map_count{$1}++
                if $record->{plan_path}
                    =~ m{\A/operation_graph/operations/([0-9]+)\z};
        }
        is_deeply(
            \%operation_map_count,
            {map { $_ => 1 } 0 .. $expected{$axis}{operations} - 1},
            "$axis maps every operation index exactly once",
        );

        my %capability = map { $_->{capability_id} => $_ }
            @{$built->{plan}{capability_ledger}};
        ok($capability{'hial_vial.bridge_protocol.ahb_subordinate_v1'},
            "$axis retains the public checked-AHB capability");
        ok(!$capability{'hial_vial.bridge_qualification.architecture_scale_v1'},
            "$axis never admits the private binding-scale capability");

        my $evaluation = $class->evaluate({construction => $construction});
        ok($evaluation->{ok}, "$axis passes every fiber oracle");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{metrics}{expanded_operations_total},
            $expected{$axis}{operations}, "$axis freezes total operations");
        is($evaluation->{metrics}{total_fibers}, $expected{$axis}{fibers},
            "$axis freezes total fibers");
        is($evaluation->{metrics}{simultaneous_live_fibers},
            $expected{$axis}{live_fibers}, "$axis freezes maximum liveness");
        is($evaluation->{metrics}{source_map_records},
            $expected{$axis}{source_maps}, "$axis freezes source-map count");
        is($evaluation->{metrics}{serialized_plan_bytes},
            $expected{$axis}{plan_bytes}, "$axis freezes canonical plan bytes");
        is($evaluation->{semantic_ir_sha256}, $expected{$axis}{semantic_sha256},
            "$axis semantic identity is exact");
        is($evaluation->{bridge_manifest_sha256}, $bridge_sha256,
            "$axis bridge identity is the frozen AHB manifest");
        is($evaluation->{plan_sha256}, $expected{$axis}{plan_sha256},
            "$axis plan identity is exact");
        is_deeply($evaluation->{contract_discrepancies}, [],
            "$axis has no selected contract discrepancy");
    }
};

subtest 'fiber gates reject post-identity mutation and unfinished levels' => sub {
    my $construction = construction('fibers_total');
    my $forged = $json->decode($json->encode($construction));
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity generated-VIAL mutation fails closed');
    like($@, qr/construction is not canonical/,
        'post-identity rejection names canonical regeneration');

    my $unfinished = eval {
        $class->construct({
            primary_axis => 'fibers_total',
            level => 'qualification_candidate_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unfinished, 'qualification fiber level cannot enter the gate slice');
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
