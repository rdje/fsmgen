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
my %expected = (
    types => 512,
    bindings => 514,
    endpoints => 512,
    bridge_endpoints => 514,
    source_maps => 514,
    bridge_bytes => 8_237_394,
    plan_bytes => 735_488,
    hial_bytes => 17_901,
    vial_bytes => 63_780,
    hial_sha256 =>
        'a1bdbce8cab26e5c6aefd9a167d15c46278e0c523d45507e1a2c8a5c00bfcf39',
    vial_sha256 =>
        '86ec08dfe775503c87cf81a731feabb380c46b17dc0ac3e931f8c3ebf4db9168',
    semantic_sha256 =>
        '5e513f32c85bf8e8c47e7b89dd75afc4e8bfc24ec3a362adfdbd8035aa61bbc6',
    bridge_sha256 =>
        '8fe33ac4b688ddaad851214f755e4a22642e1ce235e329188f08627fcbf20076',
    plan_sha256 =>
        'fdb756014a0e8e9289ca2d897baa46b689c4c8a0c3050d6ab888a93398d9da9b',
);

sub construction {
    return $class->construct({
        primary_axis => 'execution_types',
        level => 'gate_candidate_v1',
    });
}

subtest 'type construction is canonical ordinary source' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'execution-type gate constructs through the workload contract');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($json->encode($second), $json->encode($first),
        'independent type construction is byte-identical');
    is($first->{specification}{requested_counts}{execution_types},
        $expected{types}, 'construction retains the selected type request');
    is_deeply([sort map { $_->{role} } @{$first->{inputs}}],
        [qw(hial_source vial_source)],
        'construction contains only generated HIAL and VIAL source');

    my %input = map { $_->{role} => $_ } @{$first->{inputs}};
    is(length($input{hial_source}{content}), $expected{hial_bytes},
        'ordinary IAL1 source byte count is exact');
    is(length($input{vial_source}{content}), $expected{vial_bytes},
        'VIAL source byte count is exact');
    is(sha256_hex($input{hial_source}{content}), $expected{hial_sha256},
        'ordinary IAL1 source identity is frozen');
    is(sha256_hex($input{vial_source}{content}), $expected{vial_sha256},
        'VIAL source identity is frozen');
    unlike($input{hial_source}{content}, qr/verification-bridge/,
        'ordinary IAL1 source has no private bridge annotation');
};

subtest 'public binder materializes one exact relation per width' => sub {
    my $built = $class->build({construction => construction()});
    ok($built->{ok}, 'execution-type gate builds through the public binder');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    my $ir = $built->{execution_ir}->as_hashref;
    is(scalar(@{$ir->{type_table}}), $expected{types},
        'type table reaches exactly 512 entries');
    is_deeply(
        [map { $_->{semantic_type}{width} } @{$ir->{type_table}}],
        [1 .. $expected{types}],
        'type table preserves the exact ascending width family',
    );
    ok(!scalar(grep {
        $_->{semantic_type}{kind} ne 'scalar'
            || $_->{semantic_type}{family} ne 'logic'
            || $_->{semantic_type}{state_domain} ne 'four_state'
            || $_->{semantic_type}{signed}
            || @{$_->{semantic_ids}} != 1
            || @{$_->{carrier_type_ids}} != 1
    } @{$ir->{type_table}}),
        'every entry is one unsigned four-state logic shape with exact identities');

    is(scalar(@{$ir->{bindings}{endpoints}}), $expected{endpoints},
        'every authored type is used by one public endpoint binding');
    is($ir->{resource_summary}{bindings}, $expected{bindings},
        'resource summary includes only unit, domain, and typed endpoints');
    is_deeply($ir->{bindings}{probes}, [], 'type gate has no verification probes');
    is_deeply($ir->{bindings}{transactions}, [], 'type gate has no transactions');
    is_deeply($ir->{bindings}{events}, [], 'type gate has no events');
    ok(!scalar(grep {
        @{$_->{relations}} != 1 || $_->{relations}[0]{direction} ne 'drive'
    } @{$ir->{bindings}{endpoints}}),
        'every typed input has one exact drive relation');
};

subtest 'type evaluation freezes route, topology, maps, and identities' => sub {
    my $construction = construction();
    my $built = $class->build({construction => $construction});
    my $ir = $built->{execution_ir}->as_hashref;
    is(scalar(@{$ir->{scenarios}}), 1, 'type gate isolates one scenario');
    is($ir->{operation_graph}{total_operation_count}, 1,
        'type gate executes one genuine reset');
    is($ir->{operation_graph}{total_fiber_count}, 1,
        'type gate has one root fiber');
    is($ir->{operation_graph}{maximum_simultaneous_live_fibers}, 1,
        'type gate has one simultaneously live fiber');
    is(scalar(@{$ir->{source_map}}), $expected{source_maps},
        'domain, type relations, and reset have complete source maps');
    is(scalar(grep {
        $_->{plan_path} eq '/operation_graph/operations/0'
    } @{$ir->{source_map}}), 1,
        'reset operation has one unique globally indexed source map');

    my %capability = map { $_->{capability_id} => $_ }
        @{$built->{plan}{capability_ledger}};
    ok($capability{'hial_vial.bridge_source.ial1'},
        'plan retains the public direct-IAL1 source capability');
    ok(!$capability{'hial_vial.bridge_protocol.ahb_subordinate_v1'},
        'plan does not claim the checked-AHB protocol capability');
    ok(!$capability{'hial_vial.bridge_qualification.architecture_scale_v1'},
        'plan does not admit the private scale capability');

    my $evaluation = $class->evaluate({construction => $construction});
    ok($evaluation->{ok}, 'execution-type gate passes every closed oracle');
    diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
    is($evaluation->{metrics}{execution_types}, $expected{types},
        'evaluation freezes the exact execution-type count');
    is($evaluation->{metrics}{bindings}, $expected{bindings},
        'evaluation freezes the exact binding count');
    is($evaluation->{metrics}{source_map_records}, $expected{source_maps},
        'evaluation freezes the exact source-map count');
    is($evaluation->{metrics}{serialized_bridge_manifest_bytes},
        $expected{bridge_bytes},
        'evaluation reproduces the selected canonical bridge-report bytes');
    is($evaluation->{metrics}{serialized_plan_bytes}, $expected{plan_bytes},
        'evaluation freezes canonical plan bytes');
    is($evaluation->{semantic_ir_sha256}, $expected{semantic_sha256},
        'semantic identity is exact');
    is($evaluation->{bridge_manifest_sha256}, $expected{bridge_sha256},
        'ordinary direct-IAL1 bridge identity is exact');
    is($evaluation->{plan_sha256}, $expected{plan_sha256},
        'plan identity is exact');
    is_deeply($evaluation->{contract_discrepancies}, [],
        'type gate has no selected contract discrepancy');
};

subtest 'type gate rejects mutation, checked-source injection, and unfinished levels' => sub {
    my $construction = construction();
    my $forged = $json->decode($json->encode($construction));
    my ($hial) = grep { $_->{role} eq 'hial_source' } @{$forged->{inputs}};
    $hial->{content} .= ' ';
    my $accepted = eval { $class->build({construction => $forged}); 1 };
    ok(!$accepted, 'post-identity ordinary-IAL1 mutation fails closed');
    like($@, qr/construction is not canonical/,
        'post-identity rejection names canonical regeneration');

    my $injected = eval {
        $class->construct({
            primary_axis => 'execution_types',
            level => 'gate_candidate_v1',
            reference_hial_text => '(actor injected)',
        });
        1;
    };
    ok(!$injected, 'caller-supplied HIAL cannot replace the generated type actor');
    like($@, qr/reference_hial_text is accepted only for checked-AHB execution gates/,
        'source-injection rejection names the checked-AHB boundary');

    my $unfinished = eval {
        $class->construct({
            primary_axis => 'execution_types',
            level => 'qualification_candidate_v1',
        });
        1;
    };
    ok(!$unfinished, 'qualification type level cannot enter the gate slice');
    like($@, qr/execution-graph gate slice does not own the requested shape/,
        'unfinished-level rejection names the bounded frontier');
};

done_testing();
