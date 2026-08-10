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
my $scenario_suffix = '_4_mib';
my $endpoint_suffix = '_q';
my $scenario_name = 'sg' . $scenario_suffix;
my $fixture_id = 'architecture_scale_execution::fixture::qualify_plan';
my $scenario_id = "$fixture_id\::scenario\::$scenario_name";
my $domain_id = "$fixture_id\::domain\::b";
my $endpoint_id = "$fixture_id\::endpoint\::ready_out$endpoint_suffix";
my $coverpoint_id = "$fixture_id\::coverpoint\::ready_sampled";
my @fixed_map_paths = (
    '/bindings/domains/0',
    map("/bindings/endpoints/$_/relations/0", 0 .. 2),
    '/bindings/probes/0/relations/0',
    map("/bindings/transactions/0/fields/$_/relation", 0 .. 5),
    map("/bindings/events/$_", 0 .. 5),
);
my %expected = (
    plan_bytes => 4_194_304,
    operations => 12_166,
    scenarios => 1,
    fibers => 1,
    live_fibers => 1,
    source_maps => 12_183,
    bindings => 22,
    execution_events => 6,
    execution_types => 7,
    hial_bytes => 1_326,
    vial_bytes => 147_115,
    bridge_bytes => 508_968,
    workload_identity =>
        'workload/271ba9bda8b51d330b5200be1e8b98dcd75b85bb6437f4a7f6b6a6c64bd19fd7',
    hial_sha256 =>
        '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c',
    vial_sha256 =>
        '08bc48d3454d01c48c67bf6bf2bc10021a5bc417995317a88982de90a7a6766a',
    semantic_sha256 =>
        '8cc3962d2095fa4e63d536e9e2ba9efb4d2e8940faf3c39130c1b0c1a82ca168',
    bridge_sha256 =>
        'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca',
    plan_id =>
        'plan/63673374ece891a4234613c00c920ffe60cb4d6d73904ba0be2a2d5799f60d62',
    plan_sha256 =>
        'bc5d44cd8bdafcb50654c1a7c8c3e0ac7101b496b16084cad9535d901253d076',
);

sub construction {
    return $class->construct({
        primary_axis => 'serialized_plan_bytes',
        level => 'qualification_candidate_v1',
        reference_hial_text => $reference_hial,
    });
}

subtest 'four-MiB construction is canonical referenced source' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'qualification construction satisfies the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent qualification construction is byte-identical');
    is($first->{specification}{requested_counts}{serialized_plan_bytes},
        $expected{plan_bytes}, 'construction retains the exact four-MiB request');
    is($first->{workload_identity}, $expected{workload_identity},
        'qualification construction identity is exact');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is_deeply([sort keys %input], [qw(hial_source vial_source)],
        'construction contains only checked HIAL and generated VIAL source');
    is(bytes::length($input{hial_source}{content}), $expected{hial_bytes},
        'checked-AHB source byte count is frozen');
    is(sha256_hex($input{hial_source}{content}), $expected{hial_sha256},
        'checked-AHB source identity is frozen');
    is($input{vial_source}{relative_path},
        'generated/vial-scale/execution_graph/plan_4m.vial',
        'generated source uses the qualification route');
    is(bytes::length($input{vial_source}{content}), $expected{vial_bytes},
        'generated qualification VIAL byte count is exact');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'generated qualification VIAL identity is frozen');
    is(scalar(() = $input{vial_source}{content} =~ /\(reset b 1\)/g),
        $expected{operations}, 'source contains exactly 12,166 real resets');
    is(length($scenario_suffix), 6,
        'scenario identifier has the selected six-character semantic suffix');
    is(length($endpoint_suffix), 2,
        'endpoint identifier has the selected two-character semantic suffix');
    is(scalar(() = $input{vial_source}{content} =~ /\Q$scenario_name\E/g), 1,
        'scenario suffix occurs only on the selected scenario identifier');
    like($input{vial_source}{content},
        qr{\(endpoint ready_out_q "endpoint/HREADYOUT" \(logic 1\) public_port\)},
        'qualification endpoint alias binds the genuine checked-AHB carrier');
    like($input{vial_source}{content},
        qr{\(coverpoint ready_sampled \(sample b\) \(expr \(sample ready_out_q\)\) \(bins \(bin asserted normal \(value #b1\)\)\)\)},
        'one genuine coverpoint references the qualification endpoint alias');
    is(scalar(() = $input{vial_source}{content} =~ /\n/g), 1,
        'source is one semantic form plus its terminating newline');
    unlike($input{vial_source}{content}, qr/\n\n|\/\*|\*\/|;/,
        'source contains no blank-data or comment padding');
};

subtest 'public binder closes the four-MiB semantic boundary' => sub {
    my $built = $class->build({construction => construction()});
    ok($built->{ok}, 'four-MiB plan builds through the public binder');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    my $ir = $built->{execution_ir}->as_hashref;
    my $graph = $ir->{operation_graph};
    my $scenario = $ir->{scenarios}[0];
    my $coverpoint = $ir->{coverage}{coverpoints}[0];
    my $plan_json = $json->encode($built->{plan});

    is(bytes::length($plan_json), $expected{plan_bytes},
        'canonical serialized plan is exactly 4,194,304 bytes');
    is(sha256_hex($plan_json), $expected{plan_sha256},
        'canonical qualification plan hash is exact');
    is($built->{plan}{plan_id}, $expected{plan_id},
        'content-derived qualification plan identity is exact');
    is($graph->{total_operation_count}, $expected{operations},
        'plan contains exactly 12,166 genuine operations');
    is($graph->{total_fiber_count}, $expected{fibers},
        'plan contains one root fiber');
    is($graph->{maximum_simultaneous_live_fibers}, $expected{live_fibers},
        'plan isolates simultaneous liveness to one');
    is(scalar(@{$ir->{scenarios}}), $expected{scenarios},
        'plan contains one scenario');
    is($scenario->{scenario_id}, $scenario_id,
        'scenario retains the qualification semantic identifier');
    is($scenario->{domain_id}, $domain_id,
        'scenario retains the compact checked-AHB domain alias');
    is_deeply($scenario->{plan_summary}{coverpoint_ids}, [$coverpoint_id],
        'scenario references the exact qualification coverpoint');
    is($coverpoint->{semantic_id}, $coverpoint_id,
        'coverpoint identity is exact');
    is($coverpoint->{expression}{semantic_id}, $endpoint_id,
        'coverpoint expression references the exact endpoint alias');
    is($coverpoint->{expression}{binding_id},
        "binding/$fixture_id/endpoint/HREADYOUT",
        'coverpoint reference resolves the real HREADYOUT binding');
    is($coverpoint->{bins}[0]{name}, 'asserted',
        'coverpoint retains the meaningful asserted bin name');
    is_deeply(
        $coverpoint->{bins}[0]{matcher}{value},
        {
            kind => 'logic_vector', known_mask => '1', signed => 0,
            value_bits => '1', width => 1, z_mask => '0',
        },
        'coverpoint retains one genuine asserted-value bin',
    );
    ok(!scalar(grep {
        $_->{kind} ne 'reset' || $_->{eligible_phase} ne 'drive'
    } @{$graph->{operations}}),
        'all operations are genuine drive-phase resets');
    my $successors_closed = 1;
    for my $index (0 .. $expected{operations} - 1) {
        my @wanted = $index == $expected{operations} - 1
            ? () : ($graph->{operations}[$index + 1]{operation_id});
        $successors_closed = 0
            unless join("\0", @{$graph->{operations}[$index]{successor_ids}})
                eq join("\0", @wanted);
    }
    ok($successors_closed, 'every reset has the exact next-operation edge');

    my %by_plan_path;
    push @{$by_plan_path{$_->{plan_path}}}, $_ for @{$ir->{source_map}};
    is(scalar(@{$ir->{source_map}}), $expected{source_maps},
        '12,166 operation maps plus 17 checked-AHB maps are exact');
    is(scalar(keys %by_plan_path), $expected{source_maps},
        'every source map owns one unique plan path');
    my @observed_fixed = sort grep {
        $_ !~ m{\A/operation_graph/operations/[0-9]+\z}
    } keys %by_plan_path;
    is_deeply(\@observed_fixed, [sort @fixed_map_paths],
        'fixed checked-AHB map family is unchanged');
    ok(!scalar(grep {
        @{$_->{source_locations}} != 1
            || $_->{source_locations}[0]{source_name}
                ne 'generated/vial-scale/execution_graph/plan_4m.vial'
    } @{$ir->{source_map}}),
        'every semantic record resolves the qualification source path');

    my %capability = map { $_->{capability_id} => $_ }
        @{$built->{plan}{capability_ledger}};
    ok($capability{'hial_vial.bridge_protocol.ahb_subordinate_v1'},
        'plan retains the public checked-AHB capability');
    ok(!$capability{'hial_vial.bridge_qualification.architecture_scale_v1'},
        'plan does not admit private scale capability');
    unlike($plan_json,
        qr/(?:systemverilog|\buvm\b|\bvhdl\b|target_name|build_phase|objection)/i,
        'exact qualification plan remains target-neutral');
};

subtest 'four-MiB evaluation freezes exact metrics and identities' => sub {
    my $evaluation = $class->evaluate({construction => construction()});
    ok($evaluation->{ok}, 'four-MiB qualification passes every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{metrics}{serialized_plan_bytes}, $expected{plan_bytes},
        'evaluation freezes the exact four-MiB boundary');
    is($evaluation->{metrics}{expanded_operations_per_scenario},
        $expected{operations}, 'evaluation freezes per-scenario operations');
    is($evaluation->{metrics}{expanded_operations_total}, $expected{operations},
        'evaluation freezes total operations');
    is($evaluation->{metrics}{selected_scenarios}, $expected{scenarios},
        'evaluation freezes scenario isolation');
    is($evaluation->{metrics}{total_fibers}, $expected{fibers},
        'evaluation freezes total fibers');
    is($evaluation->{metrics}{simultaneous_live_fibers},
        $expected{live_fibers}, 'evaluation freezes simultaneous liveness');
    is($evaluation->{metrics}{source_map_records}, $expected{source_maps},
        'evaluation freezes exact source-map count');
    is($evaluation->{metrics}{bindings}, $expected{bindings},
        'evaluation freezes public binding count');
    is($evaluation->{metrics}{execution_events}, $expected{execution_events},
        'evaluation freezes checked-AHB events');
    is($evaluation->{metrics}{execution_types}, $expected{execution_types},
        'evaluation freezes checked-AHB types');
    is($evaluation->{metrics}{random_occurrences}, 0,
        'qualification recipe adds no random occurrence');
    is($evaluation->{metrics}{serialized_bridge_manifest_bytes},
        $expected{bridge_bytes}, 'evaluation freezes canonical bridge bytes');
    is($evaluation->{semantic_ir_sha256}, $expected{semantic_sha256},
        'semantic identity is exact');
    is($evaluation->{bridge_manifest_sha256}, $expected{bridge_sha256},
        'bridge identity is the frozen checked-AHB manifest');
    is($evaluation->{plan_sha256}, $expected{plan_sha256},
        'plan identity is exact');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'qualification has no selected contract discrepancy');
};

subtest 'four-MiB qualification rejects mutation and unfinished levels' => sub {
    my $forged = clone_json(construction());
    my ($vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity source padding fails closed');
    like($@, qr/construction is not canonical/,
        'padding rejection names canonical regeneration');

    my $unreferenced = clone_json(construction());
    my ($unreferenced_vial) = grep {
        $_->{role} eq 'vial_source'
    } @{$unreferenced->{inputs}};
    $unreferenced_vial->{content}
        =~ s/\(expr \(sample ready_out_q\)\)/(expr #b1)/;
    my $referenced = eval { $class->build({construction => $unreferenced}); 1 };
    ok(!$referenced, 'removing the endpoint reference fails closed');
    like($@, qr/construction is not canonical/,
        'reference mutation rejection names canonical regeneration');

    my $missing = eval {
        $class->construct({
            primary_axis => 'serialized_plan_bytes',
            level => 'qualification_candidate_v1',
        });
        1;
    };
    ok(!$missing, 'qualification requires the frozen checked-AHB source');
    like($@, qr/checked-AHB reference text is required/,
        'missing-source rejection names checked-AHB authority');

    my $unfinished = eval {
        $class->construct({
            primary_axis => 'serialized_plan_bytes',
            level => 'over_limit_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unfinished, 'over-limit plan level cannot enter the implemented slice');
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

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}
