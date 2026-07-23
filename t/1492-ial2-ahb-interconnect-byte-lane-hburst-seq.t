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

subtest 'adapter parses selected one-subordinate AHB aggregate HBURST SEQ PPIF shape' => sub {
    ok(-f one_subordinate_hburst_seq_ppif_path(), 'tracked runnable one-subordinate AHB aggregate HBURST SEQ PPIF sample exists');
    like(slurp(one_subordinate_hburst_seq_ppif_path()), qr/\(burst HBURST_REGS width 3\)/, 'one-subordinate sample carries child-local HBURST');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_hburst_seq_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB aggregate HBURST SEQ adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_interconnect', 'adapter returns the AHB interconnect kind');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-byte-lane-hburst-seq', 'source object id is selected');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect_byte_lane_hburst_seq', 'source intent name is selected');
    is($result->{report}{composition}{child_instance_count}, 3, 'one-subordinate aggregate child count is selected');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(amba_requester.isf ahb_lite_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
        'one-subordinate source exposes requester, HBURST SEQ subordinate, and fabric IAL1 artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(ahb_interconnect.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_tb.fsm amba_requester.fsm)],
        'one-subordinate source exposes requester, HBURST SEQ subordinate, fabric, and top IAL0 artifacts',
    );

    my $top = $result->{generated_ial0}{files}{'ahb_tb.fsm'};
    like($top, qr/\(\?fsmc:regs ahb_lite_subordinate_byte_lane_hburst_seq\)/, 'generated top instantiates the HBURST SEQ subordinate child');
    like($top, qr/\(requester\.HBURST regs\.HBURST_REGS\)/, 'generated top fans requester HBURST into child-local HBURST_REGS');
    like($top, qr/\(requester\.HTRANS regs\.HTRANS\)/, 'generated top preserves requester HTRANS fanout');

    my $subordinate_fsm = $result->{generated_ial0}{files}{'ahb_lite_subordinate_byte_lane_hburst_seq.fsm'};
    like($subordinate_fsm, qr/seq_hburst_q/, 'embedded HBURST SEQ subordinate keeps HBURST stability state');
    like($subordinate_fsm, qr/seq_beats_remaining_q/, 'embedded HBURST SEQ subordinate keeps four-beat state');

    is($result->{report}{children}[2]{bindings}{bus}{burst}{name}, 'HBURST_REGS', 'child report exposes local HBURST_REGS binding');
    is($result->{report}{children}[2]{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'child report propagates HBURST SEQ policy');

    assert_hburst_seq_policy_propagation(
        $result->{report}{composition}{seq_policy_propagation},
        [qw(ahb_lite_subordinate_byte_lane_hburst_seq)],
        [qw(HADDR_REGS)],
        [qw(HBURST_REGS)],
        'one-subordinate',
    );
    assert_aggregate_hburst_seq_residue($result->{report}, [2], 'one-subordinate aggregate HBURST SEQ PPIF');
};

subtest 'adapter parses selected two-subordinate AHB aggregate HBURST SEQ PPIF shape' => sub {
    ok(-f two_subordinate_hburst_seq_ppif_path(), 'tracked runnable two-subordinate AHB aggregate HBURST SEQ PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(two_subordinate_hburst_seq_ppif_path());

    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq', 'two-subordinate source object id is selected');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq', 'two-subordinate source intent name is selected');
    is($result->{report}{composition}{child_instance_count}, 4, 'two-subordinate aggregate child count is selected');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(amba_requester.isf ahb_status_subordinate_byte_lane_hburst_seq.isf ahb_control_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
        'two-subordinate source exposes requester, both HBURST SEQ subordinates, and fabric IAL1 artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(ahb_control_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_status_subordinate_byte_lane_hburst_seq.fsm ahb_tb.fsm amba_requester.fsm)],
        'two-subordinate source exposes all generated IAL0 files',
    );

    my $top = $result->{generated_ial0}{files}{'ahb_tb.fsm'};
    like($top, qr/\(\?fsmc:status ahb_status_subordinate_byte_lane_hburst_seq\)/, 'generated top instantiates status HBURST SEQ subordinate');
    like($top, qr/\(\?fsmc:control ahb_control_subordinate_byte_lane_hburst_seq\)/, 'generated top instantiates control HBURST SEQ subordinate');
    like($top, qr/\(requester\.HBURST status\.HBURST_STATUS\)/, 'generated top fans requester HBURST into status child');
    like($top, qr/\(requester\.HBURST control\.HBURST_CONTROL\)/, 'generated top fans requester HBURST into control child');

    assert_hburst_seq_policy_propagation(
        $result->{report}{composition}{seq_policy_propagation},
        [qw(ahb_status_subordinate_byte_lane_hburst_seq ahb_control_subordinate_byte_lane_hburst_seq)],
        [qw(HADDR_STATUS HADDR_CONTROL)],
        [qw(HBURST_STATUS HBURST_CONTROL)],
        'two-subordinate',
    );
    is($result->{report}{children}[2]{bindings}{bus}{burst}{name}, 'HBURST_STATUS', 'status child report exposes local HBURST');
    is($result->{report}{children}[3]{bindings}{bus}{burst}{name}, 'HBURST_CONTROL', 'control child report exposes local HBURST');

    assert_aggregate_hburst_seq_residue($result->{report}, [2, 3], 'two-subordinate aggregate HBURST SEQ PPIF');
};

subtest 'CLI checks, semantic export, schedule report, and outdir use aggregate HBURST SEQ public paths' => sub {
    my @cases = (
        {
            path => one_subordinate_hburst_seq_ppif_path(),
            id => 'intent.ppif_ahb_interconnect_byte_lane_hburst_seq',
            coverage => 'ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_pipeline_cli',
            child_count => 3,
            schedule_source_id => 'fsmgen-ahb-interconnect-byte-lane-hburst-seq',
            generated_isf => [qw(amba_requester.isf ahb_lite_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            seq_fsm => 'ahb_lite_subordinate_byte_lane_hburst_seq.fsm',
            child_indices => [2],
            child_bursts => [qw(HBURST_REGS)],
        },
        {
            path => two_subordinate_hburst_seq_ppif_path(),
            id => 'intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq',
            coverage => 'ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli',
            child_count => 4,
            schedule_source_id => 'fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq',
            generated_isf => [qw(amba_requester.isf ahb_status_subordinate_byte_lane_hburst_seq.isf ahb_control_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_status_subordinate_byte_lane_hburst_seq.fsm ahb_control_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            seq_fsm => 'ahb_control_subordinate_byte_lane_hburst_seq.fsm',
            child_indices => [2, 3],
            child_bursts => [qw(HBURST_STATUS HBURST_CONTROL)],
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
        is($schedule->{composition}{seq_policy_propagation}{length_source}, 'HBURST', "schedule/report JSON records global HBURST length source for $case->{id}");
        is_deeply($schedule->{composition}{seq_policy_propagation}{request_forwarding}{burst}{child_names}, $case->{child_bursts}, "schedule/report JSON records child HBURST fanout for $case->{id}");
        for my $child_index (@{$case->{child_indices}}) {
            is($schedule->{children}[$child_index]{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', "schedule/report JSON exposes child HBURST SEQ policy for $case->{id} child $child_index");
            is($schedule->{children}[$child_index]{bindings}{bus}{burst}{width}, 3, "schedule/report JSON exposes child HBURST width for $case->{id} child $child_index");
        }

        my $tempdir = tempdir(CLEANUP => 1);
        my $outdir = File::Spec->catdir($tempdir, 'out');
        my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
        my ($success, undef, undef, undef, $stderr) = run(
            command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $case->{path}],
        );
        ok($success, "aggregate HBURST SEQ PPIF emits HDL and review artifacts through --outdir for $case->{id}");
        is(join('', @{$stderr || []}), '', "outdir generation keeps stderr clean for $case->{id}");
        for my $artifact (@{$case->{generated_isf}}, @{$case->{generated_fsm}}) {
            ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains generated $artifact for $case->{id}");
        }
        like(slurp(File::Spec->catfile($outdir, $case->{seq_fsm})), qr/seq_hburst_q/, "outdir generated HBURST SEQ subordinate FSM keeps HBURST state for $case->{id}");
        like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, "generated HDL contains the AHB aggregate module for $case->{id}");
    }
};

subtest 'existing AHB aggregate boundaries stay unchanged and matching HBURST aliases are shipped' => sub {
    my $seq_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_seq_ppif_path());
    is($seq_ppif->{report}{composition}{seq_policy_propagation}{mode}, 'subordinate_owned_in_word_seq_policy', 'existing aggregate byte-lane SEQ PPIF keeps in-word aggregate mode');
    ok(!exists $seq_ppif->{report}{composition}{seq_policy_propagation}{request_forwarding}{burst}, 'existing aggregate byte-lane SEQ PPIF does not gain HBURST forwarding');
    ok(!exists $seq_ppif->{report}{children}[2]{bindings}{bus}{burst}, 'existing aggregate byte-lane SEQ child does not gain HBURST binding');

    my $endpoint_hburst = FSM::Adapter::IAL2::PPIF->new()->parse_file(endpoint_hburst_seq_ppif_path());
    is($endpoint_hburst->{report}{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'endpoint HBURST SEQ PPIF keeps endpoint policy');
    ok(!exists $endpoint_hburst->{report}{composition}, 'endpoint HBURST SEQ PPIF does not gain aggregate composition report');

    ok(-e one_subordinate_hburst_seq_alias_path(), 'matching one-subordinate aggregate HBURST SEQ .ahb alias is now shipped');
    ok(-e two_subordinate_hburst_seq_alias_path(), 'matching two-subordinate aggregate HBURST SEQ .ahb alias is now shipped');
};

subtest 'malformed aggregate HBURST SEQ sources fail closed' => sub {
    my @cases = (
        [
            'hburst seq child without local burst binding',
            sub {
                my $source = slurp(one_subordinate_hburst_seq_ppif_path());
                $source =~ s/\n      \(burst HBURST_REGS width 3\)//;
                return $source;
            },
            qr/require every subordinate child to use transfer ahb_lite_byte_lane_hburst_seq_access with bus\.burst width 3/,
        ],
        [
            'duplicate child burst names',
            sub {
                my $source = slurp(two_subordinate_hburst_seq_ppif_path());
                $source =~ s/\(burst HBURST_CONTROL width 3\)/(burst HBURST_STATUS width 3)/;
                return $source;
            },
            qr/duplicate subordinate local signal 'HBURST_STATUS'/,
        ],
        [
            'mixed in-word and hburst seq children',
            sub {
                my $source = slurp(two_subordinate_hburst_seq_ppif_path());
                $source =~ s/\n      \(burst HBURST_CONTROL width 3\)//;
                $source =~ s/\(transfer ahb_lite_byte_lane_hburst_seq_access\n((?:      .*\n)*?)      \(seq-policy hburst-in-word-progressive\)/"(transfer ahb_lite_byte_lane_seq_access\n$1      (seq-policy in-word-progressive)"/e;
                return $source;
            },
            qr/require every subordinate child to use transfer ahb_lite_byte_lane_hburst_seq_access with bus\.burst width 3/,
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

sub assert_hburst_seq_policy_propagation {
    my ($propagation, $expected_objects, $expected_local_addresses, $expected_bursts, $label) = @_;
    ok($propagation->{selected}, "$label report selects aggregate HBURST SEQ propagation");
    is($propagation->{mode}, 'subordinate_owned_hburst_in_word_seq_policy', "$label report records subordinate-owned HBURST SEQ mode");
    is($propagation->{policy}, 'hburst_in_word_progressive', "$label report records child HBURST SEQ policy");
    is($propagation->{base_policy}, 'in_word_progressive', "$label report records base in-word policy");
    is($propagation->{length_source}, 'HBURST', "$label report records global HBURST length source");
    is($propagation->{local_address_policy}, 'subtract_window_base_before_subordinate_hburst_seq_policy', "$label report records local-address policy before HBURST SEQ policy");
    is_deeply($propagation->{request_forwarding}{burst}{child_names}, $expected_bursts, "$label report records child-local HBURST fanout names");
    is_deeply([map { $_->{object_name} } @{$propagation->{subordinates}}], $expected_objects, "$label report preserves subordinate order");
    is_deeply([map { $_->{local_address_signal}{name} } @{$propagation->{subordinates}}], $expected_local_addresses, "$label report identifies local address signals");
    is_deeply([map { $_->{burst_signal}{name} } @{$propagation->{subordinates}}], $expected_bursts, "$label report identifies child-local burst signals");
    is_deeply($propagation->{subordinates}[0]{supported_seq_size}, [qw(byte)], "$label report narrows supported HBURST SEQ size to byte");
    is_deeply($propagation->{subordinates}[0]{supported_hburst_modes}, [qw(WRAP4 INCR4)], "$label report carries supported HBURST modes");
}

sub assert_aggregate_hburst_seq_residue {
    my ($report, $child_indices, $label) = @_;
    my %residue = map { $_->{id} => $_->{detail} } @{$report->{unsupported_residue}};
    ok($residue{ahb_aggregate_profile_alias_deferred}, "$label keeps aggregate .ahb alias residue explicit");
    ok($residue{ahb_burst_seq_support_deferred}, "$label keeps remaining burst/SEQ residue explicit");
    like($residue{ahb_burst_seq_support_deferred}, qr/byte-only HBURST WRAP4\/INCR4 in-word SEQ propagation/, "$label top residue records shipped aggregate HBURST propagation");
    unlike($residue{ahb_burst_seq_support_deferred}, qr/HBURST-driven length\/wrap semantics/, "$label top residue no longer says all HBURST length/wrap is deferred");
    like($residue{ahb_burst_seq_support_deferred}, qr/halfword\/word burst SEQ/, "$label top residue keeps larger-size burst SEQ deferred");
    like($residue{ahb_burst_seq_support_deferred}, qr/BUSY-in-burst/, "$label top residue keeps BUSY-in-burst residue");
    if (@$child_indices == 2) {
        like($residue{ahb_broader_interconnect_decode_deferred}, qr/BUSY-in-burst continuation/, "$label broader topology residue still defers BUSY continuation");
        unlike($residue{ahb_broader_interconnect_decode_deferred}, qr/with BUSY-in-burst parking/, "$label broader topology residue does not claim unselected BUSY parking");
    }

    for my $child_index (@$child_indices) {
        my %child_residue = map { $_->{id} => $_->{detail} } @{$report->{children}[$child_index]{unsupported_residue}};
        unlike($child_residue{ahb_burst_seq_support_deferred}, qr/aggregate propagation/, "$label child $child_index residue no longer claims aggregate propagation is deferred");
        like($child_residue{ahb_burst_seq_support_deferred}, qr/\.ahb alias exposure/, "$label child $child_index generic residue keeps alias exposure deferred");
        like($child_residue{ahb_burst_seq_support_deferred}, qr/halfword\/word burst SEQ/, "$label child $child_index keeps larger-size burst SEQ deferred");
    }
}

sub one_subordinate_hburst_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_hburst_seq.ppif');
}

sub two_subordinate_hburst_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif');
}

sub one_subordinate_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_seq.ppif');
}

sub endpoint_hburst_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_hburst_seq.ppif');
}

sub one_subordinate_hburst_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_hburst_seq.ahb');
}

sub two_subordinate_hburst_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb');
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
