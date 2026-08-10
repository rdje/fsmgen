#!/usr/bin/env perl

use strict;
use warnings;

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
my @fixed_map_paths = (
    '/bindings/domains/0',
    map("/bindings/endpoints/$_/relations/0", 0 .. 2),
    '/bindings/probes/0/relations/0',
    map("/bindings/transactions/0/fields/$_/relation", 0 .. 5),
    map("/bindings/events/$_", 0 .. 5),
);
my %expected = (
    source_maps => 8_192,
    fixed_source_maps => 17,
    operations => 8_175,
    scenarios => 1,
    fibers => 1,
    live_fibers => 1,
    bindings => 22,
    execution_events => 6,
    execution_types => 7,
    hial_bytes => 1_326,
    vial_bytes => 115_478,
    bridge_bytes => 508_968,
    plan_bytes => 2_949_646,
    workload_identity =>
        'workload/1488a96cb6ae5e4d2ac17cf46a1a96573cc23ae63a97bffc6f57ff1a74703722',
    hial_sha256 =>
        '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c',
    vial_sha256 =>
        'eab7a8cfa97de863d22ba4296e35c666823615c48c050aba894239f7eca38a22',
    semantic_sha256 =>
        '0213cc9ce8da72e3d2369cd70fbd191b6ad5bab2a7aa95907ff11c69d5ec052b',
    bridge_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
    plan_sha256 =>
        'f96e8e05ca7ad7d3fc3bb2a08994555ddd01e45d28a72149686305e6325b3cba',
);

sub construction {
    return $class->construct({
        primary_axis => 'source_map_records',
        level => 'gate_candidate_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest 'source-map construction is canonical checked-AHB source' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'source-map gate constructs through the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent source-map construction is byte-identical');
    is($first->{specification}{requested_counts}{source_map_records},
        $expected{source_maps}, 'construction retains the selected map request');
    is($first->{workload_identity}, $expected{workload_identity},
        'construction identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is(length($input{hial_source}{content}), $expected{hial_bytes},
        'checked-AHB source byte count is frozen');
    is(sha256_hex($input{hial_source}{content}), $expected{hial_sha256},
        'checked-AHB source identity is frozen');
    is(length($input{vial_source}{content}), $expected{vial_bytes},
        'generated VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated VIAL identity is frozen');
    my $reset_count = () = $input{vial_source}{content} =~ /\(reset bus 1\)/g;
    is($reset_count, $expected{operations},
        '8,175 genuine resets leave room for 17 fixed checked-AHB maps');
};

subtest 'public binder closes every map, span, and reset-chain edge' => sub {
    my $built = $class->build({construction => construction()});
    ok($built->{ok}, 'source-map gate builds through the public binder');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    my $ir = $built->{execution_ir}->as_hashref;
    my $graph = $ir->{operation_graph};
    is(scalar(@{$ir->{source_map}}), $expected{source_maps},
        'execution IR reaches exactly 8,192 source maps');
    is($graph->{total_operation_count}, $expected{operations},
        'map gate contains exactly 8,175 operations');
    is(scalar(@{$ir->{scenarios}}), $expected{scenarios},
        'map gate isolates one scenario');
    is($graph->{total_fiber_count}, $expected{fibers},
        'map gate contains one root fiber');
    is($graph->{maximum_simultaneous_live_fibers}, $expected{live_fibers},
        'map gate holds maximum liveness to one');

    my %by_plan_path;
    push @{$by_plan_path{$_->{plan_path}}}, $_ for @{$ir->{source_map}};
    is(scalar(keys %by_plan_path), $expected{source_maps},
        'every source map owns one unique plan path');
    my @observed_fixed = sort grep {
        $_ !~ m{\A/operation_graph/operations/[0-9]+\z}
    } keys %by_plan_path;
    is_deeply(\@observed_fixed, [sort @fixed_map_paths],
        '17 fixed domain, binding, field, and event map paths are exact');
    ok(!scalar(grep {
        @{$by_plan_path{$_}} != 1
            || !@{$by_plan_path{$_}[0]{bridge_fact_paths}}
    } @fixed_map_paths), 'every fixed map resolves exactly one bridge-backed record');

    my @operation_records;
    for my $index (0 .. $expected{operations} - 1) {
        my $plan_path = "/operation_graph/operations/$index";
        my $records = $by_plan_path{$plan_path} || [];
        push @operation_records, $records->[0] if @$records == 1;
    }
    is(scalar(@operation_records), $expected{operations},
        'every global operation index has exactly one map');
    is_deeply(
        [map { $_->{semantic_path} } @operation_records],
        [map { "/packages/0/fixtures/0/scenarios/0/actions/$_" }
            0 .. $expected{operations} - 1],
        'operation maps retain the complete ordered semantic-action family',
    );
    ok(!scalar(grep { @{$_->{bridge_fact_paths}} } @operation_records),
        'operation maps need no fabricated bridge facts');
    ok(!scalar(grep {
        @{$_->{source_locations}} != 1
            || $_->{source_locations}[0]{source_name}
                ne 'generated/vial-scale/execution_graph/vial_architecture_scale.vial'
    } @operation_records),
        'every operation map retains one generated-source location');
    my $last_start_byte = -1;
    my $ordered_spans = 1;
    for my $record (@operation_records) {
        my $location = $record->{source_locations}[0];
        $ordered_spans = 0 unless $location->{start_byte} > $last_start_byte
            && $location->{end_byte_exclusive} > $location->{start_byte};
        $last_start_byte = $location->{start_byte};
    }
    ok($ordered_spans, 'operation maps have ordered non-empty byte spans');
    ok(!scalar(grep {
        $_->{kind} ne 'reset' || $_->{eligible_phase} ne 'drive'
    } @{$graph->{operations}}),
        'all 8,175 operations are genuine drive-phase resets');
    is_deeply([map { $_->{static_rank} } @{$graph->{operations}}],
        [0 .. $expected{operations} - 1],
        'operation static ranks are complete and contiguous');
    my $successors_closed = 1;
    for my $index (0 .. $expected{operations} - 1) {
        my @expected_successors = $index == $expected{operations} - 1
            ? () : ($graph->{operations}[$index + 1]{operation_id});
        $successors_closed = 0
            unless join("\0", @{$graph->{operations}[$index]{successor_ids}})
                eq join("\0", @expected_successors);
    }
    ok($successors_closed, 'every reset has the exact next-operation edge');

    my %capability = map { $_->{capability_id} => $_ }
        @{$built->{plan}{capability_ledger}};
    ok($capability{'hial_vial.bridge_protocol.ahb_subordinate_v1'},
        'plan retains the public checked-AHB capability');
    ok(!$capability{'hial_vial.bridge_qualification.architecture_scale_v1'},
        'plan does not admit the private scale capability');
};

subtest 'source-map evaluation freezes exact metrics and identities' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'source-map gate passes every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{metrics}{source_map_records}, $expected{source_maps},
        'evaluation freezes exact source-map count');
    is($evaluation->{metrics}{expanded_operations_total}, $expected{operations},
        'evaluation freezes exact operation count');
    is($evaluation->{metrics}{selected_scenarios}, $expected{scenarios},
        'evaluation freezes scenario isolation');
    is($evaluation->{metrics}{total_fibers}, $expected{fibers},
        'evaluation freezes total fibers');
    is($evaluation->{metrics}{simultaneous_live_fibers}, $expected{live_fibers},
        'evaluation freezes simultaneous liveness');
    is($evaluation->{metrics}{bindings}, $expected{bindings},
        'evaluation freezes public binding count');
    is($evaluation->{metrics}{execution_events}, $expected{execution_events},
        'evaluation freezes checked-AHB events');
    is($evaluation->{metrics}{execution_types}, $expected{execution_types},
        'evaluation freezes checked-AHB types');
    is($evaluation->{metrics}{serialized_bridge_manifest_bytes},
        $expected{bridge_bytes}, 'evaluation freezes canonical bridge bytes');
    is($evaluation->{metrics}{serialized_plan_bytes}, $expected{plan_bytes},
        'evaluation freezes canonical plan bytes');
    is($evaluation->{semantic_ir_sha256}, $expected{semantic_sha256},
        'semantic identity is exact');
    is($evaluation->{bridge_manifest_sha256}, $expected{bridge_sha256},
        'bridge identity is the frozen checked-AHB manifest');
    is($evaluation->{plan_sha256}, $expected{plan_sha256},
        'plan identity is exact');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'source-map gate has no selected contract discrepancy');
};

subtest 'source-map gate rejects mutation and unfinished levels' => sub {
    my $forged = $json->decode($json->encode(construction()));
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity generated-VIAL mutation fails closed');
    like($@, qr/construction is not canonical/,
        'post-identity rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'source_map_records',
            level => 'gate_candidate_v1',
        });
        1;
    };
    ok(!$missing, 'source-map gate requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');

    my $unfinished = eval {
        $class->construct({
            primary_axis => 'source_map_records',
            level => 'qualification_candidate_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unfinished, 'qualification map level cannot enter the gate slice');
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
