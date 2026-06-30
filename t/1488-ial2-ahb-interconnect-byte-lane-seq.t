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

subtest 'adapter parses selected one-subordinate AHB aggregate byte-lane SEQ PPIF shape' => sub {
    ok(-f one_subordinate_seq_ppif_path(), 'tracked runnable one-subordinate AHB aggregate byte-lane SEQ PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_seq_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB aggregate byte-lane SEQ adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_interconnect', 'adapter returns the AHB interconnect kind');
    is($result->{mode}, 'requester-subordinate-interconnect', 'AHB aggregate byte-lane SEQ mode is explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'report schema stays the AHB interconnect schema');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-byte-lane-seq', 'source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect_byte_lane_seq', 'source intent name is preserved');
    is($result->{report}{composition}{topology}, 'one_requester_one_subordinate_static_window_interconnect', 'report keeps the selected one-subordinate topology');
    is($result->{report}{composition}{child_instance_count}, 3, 'report captures requester/interconnect/subordinate child count');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(amba_requester.isf ahb_lite_subordinate_byte_lane_seq.isf ahb_interconnect.isf)],
        'one-subordinate aggregate byte-lane SEQ source exposes requester, SEQ subordinate, and fabric IAL1 artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(ahb_interconnect.fsm ahb_lite_subordinate_byte_lane_seq.fsm ahb_tb.fsm amba_requester.fsm)],
        'one-subordinate aggregate byte-lane SEQ source exposes requester, SEQ subordinate, fabric, and top IAL0 artifacts',
    );

    my $top = $result->{generated_ial0}{files}{'ahb_tb.fsm'};
    like($top, qr/\(\?fsmc:regs ahb_lite_subordinate_byte_lane_seq\)/, 'generated top instantiates the byte-lane SEQ subordinate child');
    like($top, qr/\(interconnect\.HADDR_REGS regs\.HADDR_REGS\)/, 'generated top wires local address into byte-lane SEQ subordinate');
    like($top, qr/\(requester\.HSIZE regs\.HSIZE\)/, 'generated top forwards HSIZE into byte-lane SEQ subordinate');
    like($top, qr/\(requester\.HWRITE regs\.HWRITE\)/, 'generated top forwards HWRITE into byte-lane SEQ subordinate');
    like($top, qr/\(regs\.HRESP_REGS interconnect\.HRESP_REGS\)/, 'generated top wires subordinate-owned response into interconnect');

    my $subordinate_fsm = $result->{generated_ial0}{files}{'ahb_lite_subordinate_byte_lane_seq.fsm'};
    like($subordinate_fsm, qr/read_byte_lane3_hit_start/, 'embedded byte-lane SEQ subordinate keeps byte-lane read path');
    like($subordinate_fsm, qr/read_halfword_lane1_hit_start/, 'embedded byte-lane SEQ subordinate keeps halfword read path');
    like($subordinate_fsm, qr/seq_valid_q/, 'embedded byte-lane SEQ subordinate keeps SEQ validity state');
    like($subordinate_fsm, qr/seq_expected_addr_q/, 'embedded byte-lane SEQ subordinate keeps expected-address state');

    assert_byte_lane_propagation(
        $result->{report}{composition}{byte_lane_propagation},
        [qw(ahb_lite_subordinate_byte_lane_seq)],
        [qw(HADDR_REGS)],
        'one-subordinate',
    );
    assert_seq_policy_propagation(
        $result->{report}{composition}{seq_policy_propagation},
        [qw(ahb_lite_subordinate_byte_lane_seq)],
        [qw(HADDR_REGS)],
        'one-subordinate',
    );
    is($result->{report}{children}[2]{transfer}{seq_policy}{mode}, 'in_word_progressive', 'child report propagates child SEQ policy');
    is($result->{report}{children}[2]{narrow_transfer_policy}{narrow_read}{policy}, 'zero-fill-inactive-lanes', 'child report propagates child narrow-read policy');

    assert_aggregate_seq_residue($result->{report}, [2], 'one-subordinate aggregate byte-lane SEQ PPIF');
};

subtest 'adapter parses selected two-subordinate AHB aggregate byte-lane SEQ PPIF shape' => sub {
    ok(-f two_subordinate_seq_ppif_path(), 'tracked runnable two-subordinate AHB aggregate byte-lane SEQ PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(two_subordinate_seq_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB two-subordinate aggregate byte-lane SEQ adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_interconnect', 'adapter returns the AHB interconnect kind');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-interconnect-two-subordinate-byte-lane-seq', 'source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_interconnect_two_subordinate_byte_lane_seq', 'source intent name is preserved');
    is($result->{report}{composition}{topology}, 'one_requester_two_subordinate_static_window_interconnect', 'report keeps the selected two-subordinate topology');
    is($result->{report}{composition}{child_instance_count}, 4, 'report captures requester/interconnect/two-subordinate child count');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(amba_requester.isf ahb_status_subordinate_byte_lane_seq.isf ahb_control_subordinate_byte_lane_seq.isf ahb_interconnect.isf)],
        'two-subordinate aggregate byte-lane SEQ source exposes requester, both SEQ subordinates, and fabric IAL1 artifacts',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(ahb_control_subordinate_byte_lane_seq.fsm ahb_interconnect.fsm ahb_status_subordinate_byte_lane_seq.fsm ahb_tb.fsm amba_requester.fsm)],
        'two-subordinate aggregate byte-lane SEQ source exposes all generated IAL0 files',
    );

    my $top = $result->{generated_ial0}{files}{'ahb_tb.fsm'};
    like($top, qr/\(\?fsmc:status ahb_status_subordinate_byte_lane_seq\)/, 'generated top instantiates status byte-lane SEQ subordinate');
    like($top, qr/\(\?fsmc:control ahb_control_subordinate_byte_lane_seq\)/, 'generated top instantiates control byte-lane SEQ subordinate');
    like($top, qr/\(requester\.HSIZE status\.HSIZE\)/, 'generated top forwards HSIZE into status subordinate');
    like($top, qr/\(requester\.HSIZE control\.HSIZE\)/, 'generated top forwards HSIZE into control subordinate');
    like($top, qr/\(status\.HRESP_STATUS interconnect\.HRESP_STATUS\)/, 'generated top wires status subordinate response into interconnect');
    like($top, qr/\(control\.HRESP_CONTROL interconnect\.HRESP_CONTROL\)/, 'generated top wires control subordinate response into interconnect');

    my $interconnect_fsm = $result->{generated_ial0}{files}{'ahb_interconnect.fsm'};
    like($interconnect_fsm, qr/\(= \(HADDR_STATUS> HADDR\)\)/, 'generated interconnect emits zero-base status local address');
    like($interconnect_fsm, qr/\(= \(HADDR_CONTROL> \(- HADDR 4\)\)\)/, 'generated interconnect subtracts control base before byte-lane SEQ policy');

    for my $artifact (qw(ahb_status_subordinate_byte_lane_seq.fsm ahb_control_subordinate_byte_lane_seq.fsm)) {
        my $subordinate_fsm = $result->{generated_ial0}{files}{$artifact};
        like($subordinate_fsm, qr/read_halfword_lane1_hit_start/, "$artifact keeps halfword read path");
        like($subordinate_fsm, qr/seq_expected_addr_q/, "$artifact keeps expected-address state");
    }

    assert_byte_lane_propagation(
        $result->{report}{composition}{byte_lane_propagation},
        [qw(ahb_status_subordinate_byte_lane_seq ahb_control_subordinate_byte_lane_seq)],
        [qw(HADDR_STATUS HADDR_CONTROL)],
        'two-subordinate',
    );
    assert_seq_policy_propagation(
        $result->{report}{composition}{seq_policy_propagation},
        [qw(ahb_status_subordinate_byte_lane_seq ahb_control_subordinate_byte_lane_seq)],
        [qw(HADDR_STATUS HADDR_CONTROL)],
        'two-subordinate',
    );
    is($result->{report}{children}[2]{transfer}{seq_policy}{mode}, 'in_word_progressive', 'status child report propagates child SEQ policy');
    is($result->{report}{children}[3]{narrow_transfer_policy}{narrow_write}{policy}, 'preserve-inactive-lanes', 'control child report propagates narrow-write policy');

    assert_aggregate_seq_residue($result->{report}, [2, 3], 'two-subordinate aggregate byte-lane SEQ PPIF');
};

subtest 'CLI checks, semantic export, schedule report, and outdir use the aggregate byte-lane SEQ public paths' => sub {
    my @cases = (
        {
            path => one_subordinate_seq_ppif_path(),
            id => 'intent.ppif_ahb_interconnect_byte_lane_seq',
            coverage => 'ial2_ppif_ahb_interconnect_byte_lane_seq_pipeline_cli',
            child_count => 3,
            schedule_source_id => 'fsmgen-ahb-interconnect-byte-lane-seq',
            generated_isf => [qw(amba_requester.isf ahb_lite_subordinate_byte_lane_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_lite_subordinate_byte_lane_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            seq_fsm => 'ahb_lite_subordinate_byte_lane_seq.fsm',
            child_indices => [2],
        },
        {
            path => two_subordinate_seq_ppif_path(),
            id => 'intent.ppif_ahb_interconnect_two_subordinate_byte_lane_seq',
            coverage => 'ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_seq_pipeline_cli',
            child_count => 4,
            schedule_source_id => 'fsmgen-ahb-interconnect-two-subordinate-byte-lane-seq',
            generated_isf => [qw(amba_requester.isf ahb_status_subordinate_byte_lane_seq.isf ahb_control_subordinate_byte_lane_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_status_subordinate_byte_lane_seq.fsm ahb_control_subordinate_byte_lane_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            seq_fsm => 'ahb_control_subordinate_byte_lane_seq.fsm',
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
        ok($schedule->{composition}{byte_lane_propagation}{selected}, "schedule/report JSON exposes aggregate byte-lane propagation for $case->{id}");
        ok($schedule->{composition}{seq_policy_propagation}{selected}, "schedule/report JSON exposes aggregate SEQ policy propagation for $case->{id}");
        for my $child_index (@{$case->{child_indices}}) {
            is($schedule->{children}[$child_index]{transfer}{seq_policy}{mode}, 'in_word_progressive', "schedule/report JSON exposes child SEQ policy for $case->{id} child $child_index");
            is($schedule->{children}[$child_index]{narrow_transfer_policy}{narrow_read}{policy}, 'zero-fill-inactive-lanes', "schedule/report JSON exposes child narrow-read policy for $case->{id} child $child_index");
        }

        my $tempdir = tempdir(CLEANUP => 1);
        my $outdir = File::Spec->catdir($tempdir, 'out');
        my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
        my ($success, undef, undef, undef, $stderr) = run(
            command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $case->{path}],
        );
        ok($success, "aggregate byte-lane SEQ PPIF emits HDL and review artifacts through --outdir for $case->{id}");
        is(join('', @{$stderr || []}), '', "outdir generation keeps stderr clean for $case->{id}");
        for my $artifact (@{$case->{generated_isf}}, @{$case->{generated_fsm}}) {
            ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains generated $artifact for $case->{id}");
        }
        ok(-f $hdl, "outdir command emits selected aggregate HDL output for $case->{id}");
        like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, "generated HDL contains the AHB aggregate module for $case->{id}");
        like(slurp(File::Spec->catfile($outdir, $case->{seq_fsm})), qr/seq_expected_addr_q/, "outdir generated SEQ subordinate FSM keeps expected-address state for $case->{id}");
    }
};

subtest 'existing AHB aggregate and endpoint boundaries stay unchanged' => sub {
    my $word_only_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(word_only_interconnect_ppif_path());
    ok(!exists $word_only_ppif->{report}{composition}{byte_lane_propagation}, 'word-only aggregate PPIF does not gain aggregate byte-lane report');
    ok(!exists $word_only_ppif->{report}{composition}{seq_policy_propagation}, 'word-only aggregate PPIF does not gain aggregate SEQ report');

    my $byte_lane_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(byte_lane_interconnect_ppif_path());
    ok($byte_lane_ppif->{report}{composition}{byte_lane_propagation}{selected}, 'existing aggregate byte-lane PPIF keeps byte-lane propagation');
    ok(!exists $byte_lane_ppif->{report}{composition}{seq_policy_propagation}, 'existing aggregate byte-lane PPIF does not gain aggregate SEQ report');

    my $byte_lane_alias = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', byte_lane_interconnect_alias_path());
    ok($byte_lane_alias->{composition}{byte_lane_propagation}{selected}, 'existing aggregate byte-lane .ahb alias keeps byte-lane propagation');
    ok(!exists $byte_lane_alias->{composition}{seq_policy_propagation}, 'existing aggregate byte-lane .ahb alias does not gain aggregate SEQ report');

    my $endpoint_seq_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(endpoint_seq_ppif_path());
    is($endpoint_seq_ppif->{report}{transfer}{seq_policy}{mode}, 'in_word_progressive', 'endpoint byte-lane SEQ PPIF keeps endpoint SEQ report');
    ok(!exists $endpoint_seq_ppif->{report}{composition}, 'endpoint byte-lane SEQ PPIF does not gain aggregate composition report');

    ok(!-e one_subordinate_seq_alias_path(), 'matching one-subordinate aggregate byte-lane SEQ .ahb alias remains unshipped');
    ok(!-e two_subordinate_seq_alias_path(), 'matching two-subordinate aggregate byte-lane SEQ .ahb alias remains unshipped');
};

done_testing();

sub assert_byte_lane_propagation {
    my ($propagation, $expected_objects, $expected_local_addresses, $label) = @_;
    ok($propagation->{selected}, "$label report selects aggregate byte-lane propagation");
    is($propagation->{mode}, 'subordinate_owned_narrow_transfer_policy', "$label report records subordinate-owned narrow-transfer policy");
    is($propagation->{local_address_policy}, 'subtract_window_base_before_subordinate_lane_policy', "$label report records local-address policy before byte-lane selection");
    is($propagation->{mapped_hit_owner}, 'selected_subordinate', "$label report records selected subordinate ownership for mapped-hit errors");
    is($propagation->{unmapped_error_owner}, 'interconnect', "$label report records interconnect ownership for unmapped errors");
    is_deeply([map { $_->{object_name} } @{$propagation->{subordinates}}], $expected_objects, "$label report preserves byte-lane subordinate order");
    is_deeply([map { $_->{local_address_signal}{name} } @{$propagation->{subordinates}}], $expected_local_addresses, "$label report identifies local address signals");
    is_deeply($propagation->{subordinates}[0]{supported_size}, [qw(byte halfword word)], "$label report carries supported byte-lane sizes");
    is($propagation->{subordinates}[0]{narrow_transfer_policy}{narrow_write}{policy}, 'preserve-inactive-lanes', "$label report carries child narrow-write policy");
}

sub assert_seq_policy_propagation {
    my ($propagation, $expected_objects, $expected_local_addresses, $label) = @_;
    ok($propagation->{selected}, "$label report selects aggregate SEQ policy propagation");
    is($propagation->{mode}, 'subordinate_owned_in_word_seq_policy', "$label report records subordinate-owned in-word SEQ policy");
    is($propagation->{local_address_policy}, 'subtract_window_base_before_subordinate_seq_policy', "$label report records local-address policy before SEQ policy");
    is($propagation->{mapped_hit_owner}, 'selected_subordinate', "$label report records selected subordinate ownership for mapped-hit SEQ errors");
    is($propagation->{unmapped_error_owner}, 'interconnect', "$label report records interconnect ownership for unmapped errors");
    is_deeply([map { $_->{object_name} } @{$propagation->{subordinates}}], $expected_objects, "$label report preserves SEQ subordinate order");
    is_deeply([map { $_->{local_address_signal}{name} } @{$propagation->{subordinates}}], $expected_local_addresses, "$label report identifies SEQ local address signals");
    is_deeply($propagation->{subordinates}[0]{supported_size}, [qw(byte halfword word)], "$label report carries byte-lane supported sizes");
    is_deeply($propagation->{subordinates}[0]{supported_seq_size}, [qw(byte halfword)], "$label report carries supported SEQ sizes");
    is($propagation->{subordinates}[0]{seq_policy}{mode}, 'in_word_progressive', "$label report carries child SEQ policy");
}

sub assert_aggregate_seq_residue {
    my ($report, $child_indices, $label) = @_;
    my %residue = map { $_->{id} => $_->{detail} } @{$report->{unsupported_residue}};
    ok($residue{ahb_aggregate_profile_alias_deferred}, "$label keeps aggregate .ahb alias residue explicit");
    ok($residue{ahb_burst_seq_support_deferred}, "$label keeps remaining burst/SEQ residue explicit");
    unlike($residue{ahb_burst_seq_support_deferred}, qr/aggregate propagation/, "$label top residue no longer claims aggregate SEQ propagation is deferred");
    like($residue{ahb_burst_seq_support_deferred}, qr/HBURST-driven length\/wrap semantics/, "$label top residue keeps HBURST length/wrap residue");
    like($residue{ahb_burst_seq_support_deferred}, qr/BUSY-in-burst/, "$label top residue keeps BUSY-in-burst residue");
    like($residue{ahb_burst_seq_support_deferred}, qr/multi-word\/register-bank/, "$label top residue keeps multi-word/register-bank residue");

    for my $child_index (@$child_indices) {
        my %child_residue = map { $_->{id} => $_->{detail} } @{$report->{children}[$child_index]{unsupported_residue}};
        unlike($child_residue{ahb_burst_seq_support_deferred}, qr/aggregate propagation/, "$label child $child_index residue no longer claims aggregate propagation is deferred");
        like($child_residue{ahb_burst_seq_support_deferred}, qr/\.ahb alias exposure/, "$label child $child_index generic residue keeps endpoint alias exposure deferred");
        like($child_residue{ahb_burst_seq_support_deferred}, qr/HBURST-driven length\/wrap semantics/, "$label child $child_index residue keeps HBURST length/wrap deferred");
    }
}

sub one_subordinate_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_seq.ppif');
}

sub two_subordinate_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane_seq.ppif');
}

sub word_only_interconnect_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect.ppif');
}

sub byte_lane_interconnect_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane.ppif');
}

sub byte_lane_interconnect_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane.ahb');
}

sub endpoint_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_seq.ppif');
}

sub one_subordinate_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_seq.ahb');
}

sub two_subordinate_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane_seq.ahb');
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
