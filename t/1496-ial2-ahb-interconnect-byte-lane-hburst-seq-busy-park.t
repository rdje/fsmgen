#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;

# IAL2-FEATURE-COMPLETENESS-FRONTIER.782: bounded aggregate AHB interconnect
# BUSY-in-burst parking. Two new additive stems copy the shipped aggregate
# HBURST-aware byte-lane SEQ sources and declare (parked-transfer busy) in place
# of (ignored-transfer busy) on every inlined child subordinate, so each child
# parks BUSY through the shipped endpoint machinery and the interconnect composes
# it verbatim. Only the aggregate HBURST residue narrows; no interconnect parser,
# generator, or report code path changes.

subtest 'adapter parses the one-subordinate aggregate BUSY-park PPIF and parks BUSY' => sub {
    ok(-f one_subordinate_busy_park_path(), 'tracked runnable one-subordinate aggregate BUSY-park PPIF sample exists');
    like(slurp(one_subordinate_busy_park_path()), qr/\(seq-policy hburst-in-word-progressive\)/, 'sample keeps the HBURST SEQ policy clause');
    like(slurp(one_subordinate_busy_park_path()), qr/\(ignored-transfer idle\)/, 'sample still ignores IDLE');
    like(slurp(one_subordinate_busy_park_path()), qr/\(parked-transfer busy\)/, 'sample parks BUSY instead of ignoring it');
    unlike(slurp(one_subordinate_busy_park_path()), qr/\(ignored-transfer busy\)/, 'sample no longer ignores BUSY');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_busy_park_path());
    is($result->{layer}, 'IAL2', 'aggregate BUSY-park adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_interconnect', 'adapter returns the AHB interconnect kind');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-byte-lane-hburst-seq-busy-park', 'one-subordinate source object id is selected');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect_byte_lane_hburst_seq_busy_park', 'one-subordinate source intent name is selected');
    is($result->{report}{composition}{child_instance_count}, 3, 'one-subordinate aggregate child count is preserved');

    # The generated IAL0 topology is byte-for-byte the shipped aggregate HBURST
    # SEQ topology (the delta is the child clear-on-BUSY vs park-on-BUSY policy).
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(ahb_interconnect.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_tb.fsm amba_requester.fsm)],
        'one-subordinate source exposes requester, HBURST SEQ subordinate, fabric, and top IAL0 artifacts',
    );

    my $child = $result->{report}{children}[2];
    is($child->{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'child report keeps the HBURST SEQ policy mode');
    is_deeply($child->{transfer}{seq_policy}{parks_on}, [qw(busy)], 'child report records BUSY as a parked (held) transfer');
    is_deeply($child->{transfer}{seq_policy}{clears_on}, [qw(reset idle error new_nonseq final_beat)], 'child report drops BUSY from clears_on');

    assert_aggregate_busy_park_propagation(
        $result->{report}{composition}{seq_policy_propagation},
        [qw(ahb_lite_subordinate_byte_lane_hburst_seq)],
        'one-subordinate',
    );
    assert_aggregate_busy_park_residue($result->{report}, [2], 'one-subordinate aggregate BUSY-park PPIF');
};

subtest 'adapter parses the two-subordinate aggregate BUSY-park PPIF and parks BUSY on every child' => sub {
    ok(-f two_subordinate_busy_park_path(), 'tracked runnable two-subordinate aggregate BUSY-park PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(two_subordinate_busy_park_path());
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq-busy-park', 'two-subordinate source object id is selected');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park', 'two-subordinate source intent name is selected');
    is($result->{report}{composition}{child_instance_count}, 4, 'two-subordinate aggregate child count is preserved');

    for my $child_index (2, 3) {
        my $child = $result->{report}{children}[$child_index];
        is($child->{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', "two-subordinate child $child_index keeps HBURST SEQ policy");
        is_deeply($child->{transfer}{seq_policy}{parks_on}, [qw(busy)], "two-subordinate child $child_index parks BUSY");
    }

    assert_aggregate_busy_park_propagation(
        $result->{report}{composition}{seq_policy_propagation},
        [qw(ahb_status_subordinate_byte_lane_hburst_seq ahb_control_subordinate_byte_lane_hburst_seq)],
        'two-subordinate',
    );
    assert_aggregate_busy_park_residue($result->{report}, [2, 3], 'two-subordinate aggregate BUSY-park PPIF');
};

subtest 'CLI checks, semantic export, schedule report, and outdir use aggregate BUSY-park public paths' => sub {
    my @cases = (
        {
            path => one_subordinate_busy_park_path(),
            id => 'intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park',
            coverage => 'ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli',
            child_count => 3,
            schedule_source_id => 'fsmgen-ahb-interconnect-byte-lane-hburst-seq-busy-park',
            generated_isf => [qw(amba_requester.isf ahb_lite_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            seq_fsm => 'ahb_lite_subordinate_byte_lane_hburst_seq.fsm',
            child_indices => [2],
        },
        {
            path => two_subordinate_busy_park_path(),
            id => 'intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park',
            coverage => 'ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli',
            child_count => 4,
            schedule_source_id => 'fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq-busy-park',
            generated_isf => [qw(amba_requester.isf ahb_status_subordinate_byte_lane_hburst_seq.isf ahb_control_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_status_subordinate_byte_lane_hburst_seq.fsm ahb_control_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            seq_fsm => 'ahb_control_subordinate_byte_lane_hburst_seq.fsm',
            child_indices => [2, 3],
        },
    );

    for my $case (@cases) {
        my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', $case->{path});
        ok($check->{success}, "strict check JSON succeeds for $case->{id}");
        is($check->{result}{module_name}, 'ahb_tb', "check JSON reports aggregate module for $case->{id}");
        is($check->{result}{composition_child_count}, $case->{child_count}, "check JSON reports expected child count for $case->{id}");
        is($check->{support_accounting}{entry_id}, $case->{id}, "check JSON matches support accounting for $case->{id}");
        is($check->{support_accounting}{source_kind}, 'ppif', "check JSON reports PPIF source kind for $case->{id}");
        is($check->{support_accounting}{coverage}, $case->{coverage}, "check JSON reports coverage key for $case->{id}");

        my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', $case->{path});
        ok($semantic->{success}, "strict semantic JSON succeeds for $case->{id}");
        is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', "semantic JSON reports aggregate module for $case->{id}");
        is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', "semantic JSON reports generated composition top for $case->{id}");
        is($semantic->{support_accounting}{entry_id}, $case->{id}, "semantic JSON matches support accounting for $case->{id}");

        my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', $case->{path});
        is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', "schedule/report JSON exposes AHB interconnect schema for $case->{id}");
        is($schedule->{source_object}{id}, $case->{schedule_source_id}, "schedule/report JSON preserves source id for $case->{id}");
        is($schedule->{composition}{child_instance_count}, $case->{child_count}, "schedule/report JSON exposes child count for $case->{id}");
        is($schedule->{composition}{seq_policy_propagation}{mode}, 'subordinate_owned_hburst_in_word_seq_policy', "schedule/report JSON exposes HBURST aggregate SEQ mode for $case->{id}");
        for my $child_index (@{$case->{child_indices}}) {
            is($schedule->{children}[$child_index]{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', "schedule/report JSON exposes child HBURST SEQ policy for $case->{id} child $child_index");
            is_deeply($schedule->{children}[$child_index]{transfer}{seq_policy}{parks_on}, [qw(busy)], "schedule/report JSON exposes child parks_on for $case->{id} child $child_index");
        }

        my $tempdir = tempdir(CLEANUP => 1);
        my $outdir = File::Spec->catdir($tempdir, 'out');
        my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
        my ($success, undef, undef, undef, $stderr) = run(
            command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $case->{path}],
        );
        ok($success, "aggregate BUSY-park PPIF emits HDL and review artifacts through --outdir for $case->{id}");
        is(join('', @{$stderr || []}), '', "outdir generation keeps stderr clean for $case->{id}");
        for my $artifact (@{$case->{generated_isf}}, @{$case->{generated_fsm}}) {
            ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains generated $artifact for $case->{id}");
        }
        like(slurp(File::Spec->catfile($outdir, $case->{seq_fsm})), qr/seq_hburst_q/, "outdir generated HBURST SEQ subordinate FSM keeps HBURST state for $case->{id}");
        like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, "generated HDL contains the AHB aggregate module for $case->{id}");
    }
};

subtest 'shipped aggregate HBURST SEQ and endpoint BUSY-park sources stay unchanged' => sub {
    my $shipped_aggregate = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_shipped_path());
    is($shipped_aggregate->{report}{source_object}{intent_name}, 'ahb_interconnect_byte_lane_hburst_seq', 'shipped aggregate HBURST SEQ intent name is unchanged');
    is_deeply($shipped_aggregate->{report}{children}[2]{transfer}{seq_policy}{clears_on}, [qw(reset idle busy error new_nonseq final_beat)], 'shipped aggregate HBURST SEQ child still clears on BUSY');
    ok(!exists $shipped_aggregate->{report}{children}[2]{transfer}{seq_policy}{parks_on}, 'shipped aggregate HBURST SEQ child has no parks_on field');
    my %shipped_residue = map { $_->{id} => $_->{detail} } @{$shipped_aggregate->{report}{unsupported_residue}};
    like($shipped_residue{ahb_burst_seq_support_deferred}, qr/BUSY-in-burst handling/, 'shipped aggregate HBURST SEQ still defers BUSY-in-burst handling');
    unlike($shipped_residue{ahb_burst_seq_support_deferred}, qr/with BUSY-in-burst parking/, 'shipped aggregate HBURST SEQ does not claim BUSY parking');

    my $endpoint = FSM::Adapter::IAL2::PPIF->new()->parse_file(endpoint_busy_park_path());
    is($endpoint->{report}{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'endpoint BUSY-park source keeps endpoint policy');
    is_deeply($endpoint->{report}{transfer}{seq_policy}{parks_on}, [qw(busy)], 'endpoint BUSY-park source still parks BUSY');
    ok(!exists $endpoint->{report}{composition}, 'endpoint BUSY-park source does not gain aggregate composition report');
};

subtest 'malformed aggregate BUSY-park sources fail closed' => sub {
    my @cases = (
        [
            'parked BUSY without the HBURST SEQ policy on a child',
            sub {
                my $source = slurp(one_subordinate_busy_park_path());
                $source =~ s/\n      \(seq-policy hburst-in-word-progressive\)//;
                $source =~ s/\n      \(burst HBURST_REGS width 3\)//;
                return $source;
            },
            qr/parked-transfer busy requires transfer\.seq_policy hburst-in-word-progressive/,
        ],
        [
            'both IDLE and BUSY ignored plus BUSY parked on a child',
            sub {
                my $source = slurp(one_subordinate_busy_park_path());
                $source =~ s/\(ignored-transfer idle\)/(ignored-transfer idle)\n      (ignored-transfer busy)/;
                return $source;
            },
            qr/must either ignore \{idle, busy\} or ignore \{idle\} and park \{busy\}/,
        ],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern) = @$case;
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), "$label.ppif");
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

done_testing();

sub assert_aggregate_busy_park_propagation {
    my ($propagation, $expected_objects, $label) = @_;
    ok($propagation->{selected}, "$label report selects aggregate HBURST SEQ propagation");
    is($propagation->{mode}, 'subordinate_owned_hburst_in_word_seq_policy', "$label report records subordinate-owned HBURST SEQ mode");
    is_deeply([map { $_->{object_name} } @{$propagation->{subordinates}}], $expected_objects, "$label report preserves subordinate order");
    for my $sub (@{$propagation->{subordinates}}) {
        is_deeply($sub->{seq_policy}{parks_on}, [qw(busy)], "$label report propagates the child parks_on=[busy]");
        is_deeply($sub->{seq_policy}{clears_on}, [qw(reset idle error new_nonseq final_beat)], "$label report propagates the BUSY-free clears_on");
    }
}

sub assert_aggregate_busy_park_residue {
    my ($report, $child_indices, $label) = @_;
    my %residue = map { $_->{id} => $_->{detail} } @{$report->{unsupported_residue}};
    ok($residue{ahb_burst_seq_support_deferred}, "$label keeps remaining burst/SEQ residue explicit");
    like($residue{ahb_burst_seq_support_deferred}, qr/byte-only HBURST WRAP4\/INCR4 in-word SEQ propagation with BUSY-in-burst parking/, "$label top residue records shipped BUSY-in-burst parking");
    unlike($residue{ahb_burst_seq_support_deferred}, qr/BUSY-in-burst handling/, "$label top residue no longer defers BUSY-in-burst handling");
    like($residue{ahb_burst_seq_support_deferred}, qr/halfword\/word burst SEQ/, "$label top residue keeps larger-size burst SEQ deferred");
    if (@$child_indices == 2) {
        like($residue{ahb_broader_interconnect_decode_deferred}, qr/byte-only HBURST WRAP4\/INCR4 in-word SEQ propagation with BUSY-in-burst parking/, "$label broader topology residue records shipped BUSY parking");
        unlike($residue{ahb_broader_interconnect_decode_deferred}, qr/BUSY-in-burst continuation/, "$label broader topology residue no longer defers BUSY continuation");
    }

    for my $child_index (@$child_indices) {
        my %child_residue = map { $_->{id} => $_->{detail} } @{$report->{children}[$child_index]{unsupported_residue}};
        like($child_residue{ahb_burst_seq_support_deferred}, qr/with BUSY-in-burst parking is shipped/, "$label child $child_index residue records shipped BUSY parking");
        unlike($child_residue{ahb_burst_seq_support_deferred}, qr/aggregate propagation/, "$label child $child_index residue no longer claims aggregate propagation is deferred");
        like($child_residue{ahb_burst_seq_support_deferred}, qr/\.ahb alias exposure/, "$label child $child_index generic residue keeps alias exposure deferred");
    }
}

sub one_subordinate_busy_park_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif');
}

sub two_subordinate_busy_park_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif');
}

sub one_subordinate_shipped_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_hburst_seq.ppif');
}

sub endpoint_busy_park_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif');
}

sub run_json_command {
    my @command = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => \@command);
    my $json = join('', @{$stdout || []});
    my $decoded = eval { decode_json($json) };
    ok($decoded, join(' ', @command) . ' emits decodable JSON')
        or do {
            diag($json);
            diag(join('', @{$stderr || []}));
            diag('command failed') unless $success;
            return {};
        };
    return $decoded;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}
