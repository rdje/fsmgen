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
    scenarios => {
        requested => 32,
        scenarios => 32,
        per_scenario => 1,
        operations => 32,
        fibers => 32,
        source_maps => 49,
        plan_bytes => 59_907,
        semantic_sha256 => 'a28356d20a1386b863b56752d82b2cf700b65927359b4f7f3a8c532c47bc06e0',
        plan_sha256 => 'e5aa18d76d46e9435b3e97e3adb45dec6306f4b672c2ffde690684e33d1d9663',
    },
    operations_per_scenario => {
        requested => 256,
        scenarios => 1,
        per_scenario => 256,
        operations => 256,
        fibers => 1,
        source_maps => 273,
        plan_bytes => 121_163,
        semantic_sha256 => 'f0707d6e7ef2d179c4ef0352d1f204991a09e67f54c023f3419775958cc30868',
        plan_sha256 => '729b806c8d2e3fd44f22df602b4bfcfb784d47a19d2438a5fdcc206f1a266279',
    },
    operations_total => {
        requested => 1_024,
        scenarios => 32,
        per_scenario => 32,
        operations => 1_024,
        fibers => 32,
        source_maps => 1_041,
        plan_bytes => 409_363,
        semantic_sha256 => '65c1d91d7c06bb93c34dd2fe51562f9fb76c527e9f185c71ca98ecc01f4c8951',
        plan_sha256 => '4ab01baee6a589c00a4f9137d6830b885d4e13e1e7a90a02aa4afa64d872c155',
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

subtest 'checked-AHB topology constructions are closed and byte-deterministic' => sub {
    for my $axis (sort keys %expected) {
        my $first = construction($axis);
        my $second = construction($axis);
        ok($first->{ok}, "$axis gate constructs from ordinary source");
        diag($json->encode($first->{diagnostics})) unless $first->{ok};
        is($json->encode($second), $json->encode($first),
            "$axis independent construction is byte-identical");
        is($first->{specification}{requested_counts}{$axis},
            $expected{$axis}{requested}, "$axis retains the selected request");
        is_deeply([sort map { $_->{role} } @{$first->{inputs}}],
            [qw(hial_source vial_source)],
            "$axis contains the exact checked-HIAL/generated-VIAL inputs");
        my ($hial) = grep { $_->{role} eq 'hial_source' } @{$first->{inputs}};
        is($hial->{relative_path}, 'ppif/ahb_lite_subordinate.ppif',
            "$axis retains the frozen checked-AHB source identity");
        is($hial->{content}, $reference_hial,
            "$axis retains every frozen checked-AHB source byte");
    }

    my $missing = eval {
        $class->construct({
            primary_axis => 'scenarios', level => 'gate_candidate_v1',
        });
        1;
    };
    ok(!$missing, 'checked-AHB gates reject absent reference source');
    like($@, qr/checked-AHB reference text is required/,
        'absent reference rejection names the source authority');

    my $altered = $reference_hial;
    substr($altered, 0, 1, substr($altered, 0, 1) eq 'x' ? 'y' : 'x');
    my $forged = eval {
        $class->construct({
            primary_axis => 'scenarios', level => 'gate_candidate_v1',
            reference_hial_text => $altered,
        });
        1;
    };
    ok(!$forged, 'byte-preserving checked-AHB source mutation fails closed');
    like($@, qr/checked-AHB reference identity changed/,
        'mutated reference rejection names the frozen identity');
};

subtest 'scenario and operation gates preserve exact topology and global maps' => sub {
    for my $axis (sort keys %expected) {
        my $construction = construction($axis);
        my $built = $class->build({construction => $construction});
        ok($built->{ok}, "$axis builds through the public checked-AHB binder");
        diag($json->encode($built->{diagnostics})) unless $built->{ok};
        my $ir = $built->{execution_ir}->as_hashref;
        is(scalar(@{$ir->{scenarios}}), $expected{$axis}{scenarios},
            "$axis has the isolated scenario count");
        is($ir->{operation_graph}{total_operation_count},
            $expected{$axis}{operations}, "$axis has the exact operation total");
        is($ir->{operation_graph}{total_fiber_count}, $expected{$axis}{fibers},
            "$axis creates only one root fiber per scenario");
        is($ir->{operation_graph}{maximum_simultaneous_live_fibers}, 1,
            "$axis does not inflate simultaneous liveness");
        is_deeply(
            [map { $_->{plan_summary}{operation_count} } @{$ir->{scenarios}}],
            [($expected{$axis}{per_scenario}) x $expected{$axis}{scenarios}],
            "$axis preserves the exact per-scenario operation recipe",
        );
        ok(!scalar(grep {
            $_->{kind} ne 'reset' || $_->{eligible_phase} ne 'drive'
        } @{$ir->{operation_graph}{operations}}),
            "$axis uses only genuine drive-phase reset operations");

        my %operation_map_count;
        for my $record (@{$ir->{source_map}}) {
            $operation_map_count{$1}++
                if $record->{plan_path}
                    =~ m{\A/operation_graph/operations/([0-9]+)\z};
        }
        is_deeply(
            \%operation_map_count,
            {map { $_ => 1 } 0 .. $expected{$axis}{operations} - 1},
            "$axis maps every global operation index exactly once",
        );

        my %capability = map { $_->{capability_id} => $_ }
            @{$built->{plan}{capability_ledger}};
        ok($capability{'hial_vial.bridge_protocol.ahb_subordinate_v1'},
            "$axis retains the public checked-AHB bridge capability");
        ok(!$capability{'hial_vial.bridge_qualification.architecture_scale_v1'},
            "$axis does not use the private binding qualification capability");

        my $evaluation = $class->evaluate({construction => $construction});
        ok($evaluation->{ok}, "$axis passes every topology oracle");
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{metrics}{selected_scenarios},
            $expected{$axis}{scenarios}, "$axis evaluation freezes scenarios");
        is($evaluation->{metrics}{expanded_operations_per_scenario},
            $expected{$axis}{per_scenario}, "$axis evaluation freezes per-scenario operations");
        is($evaluation->{metrics}{expanded_operations_total},
            $expected{$axis}{operations}, "$axis evaluation freezes total operations");
        is($evaluation->{metrics}{source_map_records},
            $expected{$axis}{source_maps}, "$axis evaluation freezes source-map count");
        is($evaluation->{metrics}{serialized_plan_bytes},
            $expected{$axis}{plan_bytes}, "$axis evaluation freezes canonical plan bytes");
        is($evaluation->{semantic_ir_sha256},
            $expected{$axis}{semantic_sha256}, "$axis semantic identity is exact");
        is($evaluation->{bridge_manifest_sha256}, $bridge_sha256,
            "$axis bridge identity is the frozen AHB manifest");
        is($evaluation->{plan_sha256}, $expected{$axis}{plan_sha256},
            "$axis plan identity is exact");
        is_deeply($evaluation->{contract_discrepancies}, [],
            "$axis has no selected contract discrepancy");
    }
};

subtest 'post-identity topology mutation and unfinished levels fail closed' => sub {
    my $construction = construction('scenarios');
    my $forged = $json->decode($json->encode($construction));
    my ($forged_vial) = grep { $_->{role} eq 'vial_source' } @{$forged->{inputs}};
    $forged_vial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity generated-VIAL mutation fails closed');
    like($@, qr/construction is not canonical/,
        'post-identity mutation rejection names canonical regeneration');

    my $unfinished = eval {
        $class->construct({
            primary_axis => 'scenarios', level => 'qualification_candidate_v1',
            reference_hial_text => $reference_hial,
        });
        1;
    };
    ok(!$unfinished, 'qualification topology level cannot enter the gate slice');
    like($@, qr/execution-graph gate slice does not own the requested shape/,
        'unfinished-level rejection names the bounded implementation frontier');
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
