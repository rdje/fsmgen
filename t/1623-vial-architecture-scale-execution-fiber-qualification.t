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

my %case = (
    simultaneously_live_fibers => {
        requested => 1_024,
        vial_bytes => 47_070,
        vial_sha256 =>
            'd2fccbb98374cfb4ee0a9077f1a9abed5ecd056da5381b87bde45d33808f11c7',
        workload_identity =>
            'workload/d49d41bbae67472062d6e79e9057b0f87cd656dba61f5ab5a4373d10b37c4faf',
        semantic_sha256 =>
            'a1b8c3c3095dcbc8958dfdca541b3d5f5b0ec69521ebee7d8f3fdb2c8fedcdca',
        plan_sha256 =>
            '97efa27d5820ae467de77a64872f27d0a3c01535b61951539700ff53ea0d6dfe',
        total_fibers => 1_024,
        live_fibers => 1_024,
        operations => 1_024,
        source_maps => 1_041,
        plan_bytes => 432_528,
    },
    fibers_total => {
        requested => 8_192,
        vial_bytes => 381_789,
        vial_sha256 =>
            '0d6d9c6c13c4f7d8f9b3bc54e04cb86bdfc1416648deef77f6a0c1bad8f76a5f',
        workload_identity =>
            'workload/21e7543c6c8b46024b0ae3b7a9a08b520bc9f2cb07469ff7d5291f2cfc73fb52',
        semantic_sha256 =>
            '8e4ac4cd49d59b352362a48ab4b060eb26644b00dccfc646ed3c49203a5bd22b',
        plan_sha256 =>
            'ec7afcce7d2fd04477a4911de55361f4b8b02dfb530e12f3fba424f8354f64f9',
        total_fibers => 8_192,
        live_fibers => 32,
        operations => 8_456,
        source_maps => 8_473,
        plan_bytes => 3_222_659,
    },
);
my $bridge_sha256 =
    'a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca';

sub construction {
    my ($axis) = @_;
    return $class->construct({
        primary_axis => $axis,
        level => 'qualification_candidate_v1',
        reference_hial_text => $reference_hial,
    });
}

for my $axis (sort keys %case) {
    my $want = $case{$axis};

    subtest "$axis qualification source is canonical and deterministic" => sub {
        my $first = construction($axis);
        my $second = construction($axis);
        ok($first->{ok}, 'qualification construction satisfies the workload contract');
        diag($json->encode($first->{diagnostics})) unless $first->{ok};
        is($json->encode($second), $json->encode($first),
            'independent construction is byte-identical');
        is($first->{specification}{requested_counts}{$axis}, $want->{requested},
            'construction retains the exact requested fiber count');
        is($first->{workload_identity}, $want->{workload_identity},
            'qualification workload identity is exact');

        my %input = map { $_->{role} => $_ } @{$first->{inputs}};
        is_deeply([sort keys %input], [qw(hial_source vial_source)],
            'construction contains only checked HIAL and generated VIAL source');
        is($input{hial_source}{content}, $reference_hial,
            'construction retains every checked-AHB source byte');
        is(bytes::length($input{vial_source}{content}), $want->{vial_bytes},
            'generated qualification VIAL byte count is exact');
        is(sha256_hex($input{vial_source}{content}), $want->{vial_sha256},
            'generated qualification VIAL identity is frozen');
    };

    subtest "$axis qualification plan freezes its measurements" => sub {
        my $evaluation = $class->evaluate({construction => construction($axis)});
        ok($evaluation->{ok}, 'qualification evaluation satisfies every closed oracle');
        diag($json->encode($evaluation->{diagnostics})) unless $evaluation->{ok};
        is($evaluation->{status}, 'accepted', 'qualification level is reachable');
        is($evaluation->{observed_outcome}, 'accepted',
            'evaluation records the accepted outcome');
        is_deeply($evaluation->{diagnostics}, [],
            'an accepted qualification reports no diagnostic');
        is_deeply($evaluation->{contract_discrepancies}, [],
            'a reachable level records no limit interaction');

        is($evaluation->{semantic_ir_sha256}, $want->{semantic_sha256},
            'ordinary parser produces the exact qualification SemanticIR identity');
        is($evaluation->{bridge_manifest_sha256}, $bridge_sha256,
            'ordinary checked-AHB bridge identity remains frozen');
        is($evaluation->{plan_sha256}, $want->{plan_sha256},
            'qualification plan identity is frozen');

        my $metrics = $evaluation->{metrics};
        is($metrics->{total_fibers}, $want->{total_fibers},
            'plan reports the exact total fiber count');
        is($metrics->{simultaneous_live_fibers}, $want->{live_fibers},
            'plan reports the exact maximum simultaneously live width');
        is($metrics->{expanded_operations_total}, $want->{operations},
            'plan reports the exact expanded operation total');
        is($metrics->{source_map_records}, $want->{source_maps},
            'plan reports one source map per global operation index');
        is($metrics->{serialized_plan_bytes}, $want->{plan_bytes},
            'serialized plan byte count is exact');
        cmp_ok($metrics->{serialized_plan_bytes}, '<', 16_777_216,
            'the qualification plan stays below the independent 16-MiB cap');
        is($metrics->{random_attempts}, 0,
            'a fiber qualification workload makes no random decision');
    };
}

subtest 'the two fiber axes stay orthogonal at qualification scale' => sub {
    my $live = $class->evaluate({
        construction => construction('simultaneously_live_fibers'),
    });
    my $total = $class->evaluate({construction => construction('fibers_total')});
    is($live->{metrics}{total_fibers}, $live->{metrics}{simultaneous_live_fibers},
        'the live-width workload keeps every fiber live at once');
    is($total->{metrics}{simultaneous_live_fibers},
        $case{fibers_total}{live_fibers},
        'the total-fiber workload holds its live width at the gate value');
    cmp_ok($total->{metrics}{total_fibers}, '>',
        $total->{metrics}{simultaneous_live_fibers},
        'sequential groups raise total fibers without raising live width');
};

subtest 'higher fiber levels stay unowned' => sub {
    for my $axis (sort keys %case) {
        for my $level (qw(limit_v1 over_limit_v1)) {
            my $owned = eval {
                $class->construct({
                    primary_axis => $axis,
                    level => $level,
                    reference_hial_text => $reference_hial,
                });
                1;
            };
            ok(!$owned, "$axis $level remains unowned by this slice");
            like($@, qr/does not own the requested shape/,
                "unowned $axis $level names the caller-sealed generator");
        }
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
