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

subtest 'adapter accepts selected AHB aggregate HBURST byte-lane SEQ .ahb profile aliases' => sub {
    for my $case (alias_cases()) {
        ok(-f $case->{alias_path}, "tracked runnable $case->{label} .ahb alias sample exists");

        my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file($case->{alias_path});
        my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file($case->{ppif_path});

        is($alias->{layer}, 'IAL2', "$case->{label} .ahb parser result stays IAL2");
        is($alias->{kind}, 'protocol_intent.ahb_interconnect', "$case->{label} .ahb keeps interconnect kind");
        is($alias->{mode}, 'requester-subordinate-interconnect', "$case->{label} .ahb keeps aggregate mode");
        is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', "$case->{label} .ahb report keeps schema");
        is($alias->{report}{source_object}{id}, $case->{source_id}, "$case->{label} .ahb preserves source object id");
        is($alias->{report}{source_object}{intent_name}, $case->{intent_name}, "$case->{label} .ahb preserves intent name");
        is($alias->{report}{target_protocol}{profile}, 'ahb', "$case->{label} .ahb preserves explicit AHB profile");
        is($alias->{report}{target_protocol}{object}, 'ahb-interconnect', "$case->{label} .ahb preserves interconnect object");
        is($alias->{report}{composition}{topology}, $case->{topology}, "$case->{label} .ahb preserves topology");
        is($alias->{report}{composition}{child_instance_count}, $case->{child_count}, "$case->{label} .ahb preserves child count");

        is_deeply(
            [map { $_->{name} } @{$alias->{generated_ial1}{items}}],
            $case->{generated_isf},
            "$case->{label} .ahb exposes generated IAL1 review artifacts",
        );
        is_deeply(
            [map { $_->{entry_artifact} } @{$alias->{generated_ial0}{items}}],
            $case->{generated_fsm},
            "$case->{label} .ahb exposes generated IAL0 review artifacts in lowering order",
        );
        is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, "$case->{label} .ahb mirrors generic PPIF IAL1 artifacts");
        is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, "$case->{label} .ahb mirrors generic PPIF IAL0 files");

        assert_byte_lane_propagation(
            $alias->{report}{composition}{byte_lane_propagation},
            $case->{byte_lane_objects},
            $case->{local_address_signals},
            "$case->{label} .ahb",
        );
        assert_hburst_seq_policy_propagation(
            $alias->{report}{composition}{seq_policy_propagation},
            $case->{byte_lane_objects},
            $case->{local_address_signals},
            $case->{burst_signals},
            "$case->{label} .ahb",
        );

        for my $child_index (@{$case->{child_indices}}) {
            is(
                $alias->{report}{children}[$child_index]{transfer}{seq_policy}{mode},
                'hburst_in_word_progressive',
                "$case->{label} .ahb child $child_index report propagates child HBURST SEQ policy",
            );
            is(
                $alias->{report}{children}[$child_index]{bindings}{bus}{burst}{width},
                3,
                "$case->{label} .ahb child $child_index report keeps child-local HBURST width",
            );
            is(
                $alias->{report}{children}[$child_index]{narrow_transfer_policy}{narrow_read}{policy},
                'zero-fill-inactive-lanes',
                "$case->{label} .ahb child $child_index report propagates child narrow-read policy",
            );
        }

        my %alias_residue_detail = map { $_->{id} => $_->{detail} } @{$alias->{report}{unsupported_residue}};
        my %alias_residue = map { $_ => 1 } keys %alias_residue_detail;
        ok(!$alias_residue{ahb_aggregate_profile_alias_deferred}, "$case->{label} .ahb removes aggregate profile-alias residue");
        ok(!residue_id_occurs($alias->{report}, 'ahb_aggregate_profile_alias_deferred'), "$case->{label} .ahb removes aggregate profile-alias residue from nested reports");
        ok(!residue_id_occurs($alias->{report}, 'ahb_profile_alias_deferred'), "$case->{label} .ahb removes requester profile-alias residue from nested reports");
        ok(!residue_id_occurs($alias->{report}, 'ahb_subordinate_profile_alias_deferred'), "$case->{label} .ahb removes subordinate profile-alias residue from nested reports");
        ok(!detail_pattern_occurs($alias->{report}, qr/\.ahb alias exposure/), "$case->{label} .ahb removes alias-exposure residue wording from aggregate and child reports");
        ok($alias_residue{$case->{topology_residue}}, "$case->{label} .ahb keeps topology residue");
        ok($alias_residue{ahb_optional_signal_residue}, "$case->{label} .ahb keeps optional-signal residue");
        ok($alias_residue{ahb_burst_seq_support_deferred}, "$case->{label} .ahb keeps remaining burst/SEQ residue");
        ok($alias_residue{ahb_direct_backend_deferred}, "$case->{label} .ahb keeps direct-backend residue");
        ok($alias_residue{ahb_verification_output_deferred}, "$case->{label} .ahb keeps verification/backend residue");
        if ($case->{child_count} == 4) {
            like($alias_residue_detail{ahb_broader_interconnect_decode_deferred}, qr/BUSY-in-burst continuation/, "$case->{label} .ahb broader topology residue still defers BUSY continuation");
            unlike($alias_residue_detail{ahb_broader_interconnect_decode_deferred}, qr/with BUSY-in-burst parking/, "$case->{label} .ahb broader topology residue does not claim unselected BUSY parking");
        }

        my %ppif_residue = map { $_->{id} => 1 } @{$ppif->{report}{unsupported_residue}};
        ok($ppif_residue{ahb_aggregate_profile_alias_deferred}, "$case->{label} generic PPIF keeps aggregate profile-alias residue");
        ok(residue_id_occurs($ppif->{report}, 'ahb_profile_alias_deferred'), "$case->{label} generic PPIF keeps requester profile-alias residue");
        ok(residue_id_occurs($ppif->{report}, 'ahb_subordinate_profile_alias_deferred'), "$case->{label} generic PPIF keeps subordinate profile-alias residue");
        ok(detail_pattern_occurs($ppif->{report}, qr/\.ahb alias exposure/), "$case->{label} generic PPIF keeps child alias-exposure residue wording");
    }
};

subtest 'aggregate HBURST byte-lane SEQ .ahb diagnostics stay fail-closed for malformed aliases' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.ahb');
    my $missing_profile_source = one_subordinate_alias_source();
    $missing_profile_source =~ s/^\s*\(profile ahb\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, 'aggregate HBURST byte-lane SEQ .ahb without explicit profile is rejected');
    like(
        $@,
        qr/\.ahb source '.*missing_profile\.ahb' is missing required \(profile \.\.\.\) clause/,
        'aggregate HBURST byte-lane SEQ .ahb missing-profile diagnostic is targeted',
    );

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.ahb');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, 'aggregate HBURST byte-lane SEQ .ahb with a non-AHB profile is rejected');
    like(
        $@,
        qr/profile 'valid-ready' does not match \.ahb profile alias; expected ahb/,
        'aggregate HBURST byte-lane SEQ .ahb suffix/profile mismatch diagnostic is targeted',
    );

    my $child_without_burst_path = File::Spec->catfile($tempdir, 'child_without_burst.ahb');
    my $child_without_burst_source = one_subordinate_alias_source();
    $child_without_burst_source =~ s/\n      \(burst HBURST_REGS width 3\)//;
    write_file($child_without_burst_path, $child_without_burst_source);
    my $child_without_burst_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($child_without_burst_path); 1 };
    ok(!$child_without_burst_ok, 'aggregate HBURST .ahb with a child missing its local burst binding is rejected');
    like(
        $@,
        qr/require every subordinate child to use transfer ahb_lite_byte_lane_hburst_seq_access with bus\.burst width 3/,
        'aggregate HBURST .ahb missing child-local burst diagnostic is targeted',
    );
};

subtest 'CLI JSON surfaces aggregate HBURST byte-lane SEQ .ahb source identity and support accounting' => sub {
    for my $case (alias_cases()) {
        my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', $case->{alias_path});
        ok($check->{success}, "--check --json succeeds for $case->{label} .ahb");
        is($check->{source}{resolved_path}, File::Spec->rel2abs($case->{alias_path}), "$case->{label} check JSON reports alias source path");
        is($check->{result}{module_name}, 'ahb_tb', "$case->{label} check JSON reports aggregate module name");
        is($check->{result}{composition_child_count}, $case->{child_count}, "$case->{label} check JSON reports child count");
        is($check->{support_accounting}{entry_id}, $case->{entry_id}, "$case->{label} check JSON support accounting names alias entry");
        is($check->{support_accounting}{source_kind}, 'ial2_profile_alias', "$case->{label} check JSON reports profile-alias source kind");
        is($check->{support_accounting}{coverage}, $case->{coverage}, "$case->{label} check JSON reports coverage key");

        my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', $case->{alias_path});
        ok($semantic->{success}, "--emit-semantic-json succeeds for $case->{label} .ahb");
        is($semantic->{source}{resolved_path}, File::Spec->rel2abs($case->{alias_path}), "$case->{label} semantic JSON reports alias source path");
        is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', "$case->{label} semantic JSON reports aggregate module");
        is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', "$case->{label} semantic JSON reports generated composition top");
        is($semantic->{generation_result_snapshot}{summary}{composition_child_count}, $case->{child_count}, "$case->{label} semantic JSON reports child count");
        is($semantic->{support_accounting}{entry_id}, $case->{entry_id}, "$case->{label} semantic JSON support accounting names alias entry");
        is($semantic->{support_accounting}{source_kind}, 'ial2_profile_alias', "$case->{label} semantic JSON reports profile-alias source kind");
    }
};

subtest 'schedule JSON and outdir expose aggregate HBURST byte-lane SEQ .ahb review artifacts' => sub {
    for my $case (alias_cases()) {
        my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', $case->{alias_path});
        is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', "$case->{label} schedule JSON reports interconnect schema");
        is($schedule->{source_object}{id}, $case->{source_id}, "$case->{label} schedule JSON preserves source id");
        is($schedule->{source_object}{intent_name}, $case->{intent_name}, "$case->{label} schedule JSON preserves intent name");
        is($schedule->{composition}{topology}, $case->{topology}, "$case->{label} schedule JSON reports topology");
        is($schedule->{composition}{child_instance_count}, $case->{child_count}, "$case->{label} schedule JSON reports child count");
        ok($schedule->{composition}{byte_lane_propagation}{selected}, "$case->{label} schedule JSON exposes byte-lane propagation");
        ok($schedule->{composition}{seq_policy_propagation}{selected}, "$case->{label} schedule JSON exposes SEQ policy propagation");
        is($schedule->{composition}{seq_policy_propagation}{mode}, 'subordinate_owned_hburst_in_word_seq_policy', "$case->{label} schedule JSON exposes aggregate HBURST SEQ mode");
        is($schedule->{composition}{seq_policy_propagation}{length_source}, 'HBURST', "$case->{label} schedule JSON records global HBURST length source");
        is_deeply($schedule->{composition}{seq_policy_propagation}{request_forwarding}{burst}{child_names}, $case->{burst_signals}, "$case->{label} schedule JSON records child HBURST fanout");
        is_deeply(
            $schedule->{generated_artifacts}{hdl_entry}{child_artifacts},
            $case->{hdl_child_artifacts},
            "$case->{label} schedule JSON exposes child artifacts under HDL entry",
        );
        for my $child_index (@{$case->{child_indices}}) {
            is($schedule->{children}[$child_index]{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', "$case->{label} schedule JSON exposes child HBURST SEQ policy for child $child_index");
            is($schedule->{children}[$child_index]{narrow_transfer_policy}{narrow_write}{policy}, 'preserve-inactive-lanes', "$case->{label} schedule JSON exposes child narrow-write policy for child $child_index");
        }
        my %schedule_residue = map { $_->{id} => 1 } @{$schedule->{unsupported_residue}};
        ok(!$schedule_residue{ahb_aggregate_profile_alias_deferred}, "$case->{label} schedule JSON removes aggregate profile-alias residue");
        ok(!residue_id_occurs($schedule, 'ahb_aggregate_profile_alias_deferred'), "$case->{label} schedule JSON removes nested aggregate profile-alias residue");
        ok(!residue_id_occurs($schedule, 'ahb_profile_alias_deferred'), "$case->{label} schedule JSON removes nested requester profile-alias residue");
        ok(!residue_id_occurs($schedule, 'ahb_subordinate_profile_alias_deferred'), "$case->{label} schedule JSON removes nested subordinate profile-alias residue");
        ok(!detail_pattern_occurs($schedule, qr/\.ahb alias exposure/), "$case->{label} schedule JSON removes alias-exposure residue wording");
        ok($schedule_residue{$case->{topology_residue}}, "$case->{label} schedule JSON keeps topology residue");
        ok($schedule_residue{ahb_optional_signal_residue}, "$case->{label} schedule JSON keeps optional-signal residue");
        ok($schedule_residue{ahb_burst_seq_support_deferred}, "$case->{label} schedule JSON keeps burst/SEQ residue");

        my $tempdir = tempdir(CLEANUP => 1);
        my $outdir = File::Spec->catdir($tempdir, 'out');
        my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
        my ($success, undef, undef, undef, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $case->{alias_path}],
        );

        ok($success, "$case->{label} .ahb generation succeeds");
        is(join('', @{$stderr_buf || []}), '', "$case->{label} .ahb generation keeps stderr clean");
        for my $artifact (@{$case->{generated_isf}}, @{$case->{generated_fsm}}) {
            ok(-f File::Spec->catfile($outdir, $artifact), "$case->{label} outdir contains generated $artifact");
        }
        ok(-f $hdl, "$case->{label} generation writes selected HDL output");
        like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, "$case->{label} generated HDL contains aggregate module");
        like(slurp(File::Spec->catfile($outdir, $case->{byte_lane_fsm})), qr/seq_hburst_q/, "$case->{label} generated HBURST SEQ subordinate keeps HBURST stability state");
        like(slurp(File::Spec->catfile($outdir, $case->{byte_lane_fsm})), qr/seq_beats_remaining_q/, "$case->{label} generated HBURST SEQ subordinate keeps four-beat state");
    }
};

subtest 'existing AHB aggregate and endpoint boundaries stay unchanged' => sub {
    my $seq_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_seq_alias_path());
    is($seq_alias->{report}{composition}{seq_policy_propagation}{mode}, 'subordinate_owned_in_word_seq_policy', 'existing aggregate byte-lane SEQ .ahb keeps in-word aggregate mode');
    ok(!exists $seq_alias->{report}{composition}{seq_policy_propagation}{request_forwarding}{burst}, 'existing aggregate byte-lane SEQ .ahb does not gain HBURST forwarding');

    my $hburst_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_hburst_seq_ppif_path());
    my %hburst_ppif_residue = map { $_->{id} => 1 } @{$hburst_ppif->{report}{unsupported_residue}};
    ok($hburst_ppif_residue{ahb_aggregate_profile_alias_deferred}, 'generic aggregate HBURST SEQ PPIF keeps alias-deferred residue');
    ok(residue_id_occurs($hburst_ppif->{report}, 'ahb_subordinate_profile_alias_deferred'), 'generic aggregate HBURST SEQ PPIF keeps subordinate profile-alias residue');
    ok(detail_pattern_occurs($hburst_ppif->{report}, qr/\.ahb alias exposure/), 'generic aggregate HBURST SEQ PPIF keeps child alias-exposure residue wording');

    my $endpoint_hburst_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(endpoint_hburst_seq_alias_path());
    is($endpoint_hburst_alias->{report}{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'endpoint HBURST SEQ .ahb keeps endpoint policy');
    ok(!exists $endpoint_hburst_alias->{report}{composition}, 'endpoint HBURST SEQ .ahb does not gain aggregate composition report');
};

done_testing();

sub alias_cases {
    return (
        {
            label => 'one-subordinate aggregate HBURST byte-lane SEQ',
            alias_path => one_subordinate_hburst_seq_alias_path(),
            ppif_path => one_subordinate_hburst_seq_ppif_path(),
            entry_id => 'intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq',
            coverage => 'ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_pipeline_cli',
            source_id => 'fsmgen-ahb-interconnect-byte-lane-hburst-seq',
            intent_name => 'ahb_interconnect_byte_lane_hburst_seq',
            topology => 'one_requester_one_subordinate_static_window_interconnect',
            topology_residue => 'ahb_multi_subordinate_decode_deferred',
            child_count => 3,
            child_indices => [2],
            generated_isf => [qw(amba_requester.isf ahb_lite_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            hdl_child_artifacts => [qw(amba_requester.fsm ahb_interconnect.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm)],
            byte_lane_objects => [qw(ahb_lite_subordinate_byte_lane_hburst_seq)],
            local_address_signals => [qw(HADDR_REGS)],
            burst_signals => [qw(HBURST_REGS)],
            byte_lane_fsm => 'ahb_lite_subordinate_byte_lane_hburst_seq.fsm',
        },
        {
            label => 'two-subordinate aggregate HBURST byte-lane SEQ',
            alias_path => two_subordinate_hburst_seq_alias_path(),
            ppif_path => two_subordinate_hburst_seq_ppif_path(),
            entry_id => 'intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq',
            coverage => 'ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli',
            source_id => 'fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq',
            intent_name => 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq',
            topology => 'one_requester_two_subordinate_static_window_interconnect',
            topology_residue => 'ahb_broader_interconnect_decode_deferred',
            child_count => 4,
            child_indices => [2, 3],
            generated_isf => [qw(amba_requester.isf ahb_status_subordinate_byte_lane_hburst_seq.isf ahb_control_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_status_subordinate_byte_lane_hburst_seq.fsm ahb_control_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            hdl_child_artifacts => [qw(amba_requester.fsm ahb_interconnect.fsm ahb_status_subordinate_byte_lane_hburst_seq.fsm ahb_control_subordinate_byte_lane_hburst_seq.fsm)],
            byte_lane_objects => [qw(ahb_status_subordinate_byte_lane_hburst_seq ahb_control_subordinate_byte_lane_hburst_seq)],
            local_address_signals => [qw(HADDR_STATUS HADDR_CONTROL)],
            burst_signals => [qw(HBURST_STATUS HBURST_CONTROL)],
            byte_lane_fsm => 'ahb_control_subordinate_byte_lane_hburst_seq.fsm',
        },
    );
}

sub assert_byte_lane_propagation {
    my ($propagation, $expected_objects, $expected_local_addresses, $label) = @_;
    ok($propagation->{selected}, "$label report selects aggregate byte-lane propagation");
    is($propagation->{mode}, 'subordinate_owned_narrow_transfer_policy', "$label report records subordinate-owned narrow-transfer policy");
    is($propagation->{local_address_policy}, 'subtract_window_base_before_subordinate_lane_policy', "$label report records local-address policy before byte-lane selection");
    is_deeply([map { $_->{object_name} } @{$propagation->{subordinates}}], $expected_objects, "$label report preserves byte-lane subordinate order");
    is_deeply([map { $_->{local_address_signal}{name} } @{$propagation->{subordinates}}], $expected_local_addresses, "$label report identifies byte-lane local address signals");
    for my $subordinate (@{$propagation->{subordinates}}) {
        is_deeply($subordinate->{supported_size}, [qw(byte halfword word)], "$label report carries byte/halfword/word support");
        is($subordinate->{narrow_transfer_policy}{narrow_write}{policy}, 'preserve-inactive-lanes', "$label report carries narrow-write policy");
        is($subordinate->{narrow_transfer_policy}{narrow_read}{policy}, 'zero-fill-inactive-lanes', "$label report carries narrow-read policy");
    }
}

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
    for my $subordinate (@{$propagation->{subordinates}}) {
        is_deeply($subordinate->{supported_seq_size}, [qw(byte)], "$label report narrows supported HBURST SEQ size to byte");
        is_deeply($subordinate->{supported_hburst_modes}, [qw(WRAP4 INCR4)], "$label report carries supported HBURST modes");
        is($subordinate->{seq_policy}{mode}, 'hburst_in_word_progressive', "$label report carries child HBURST SEQ policy");
    }
}

sub one_subordinate_hburst_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_hburst_seq.ahb');
}

sub two_subordinate_hburst_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb');
}

sub one_subordinate_hburst_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_hburst_seq.ppif');
}

sub two_subordinate_hburst_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif');
}

sub one_subordinate_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_seq.ahb');
}

sub endpoint_hburst_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_hburst_seq.ahb');
}

sub sample_valid_ready_handshake_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
}

sub one_subordinate_alias_source {
    return slurp(one_subordinate_hburst_seq_alias_path());
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

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $text;
    close $fh or die "close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}

sub residue_id_occurs {
    my ($node, $residue_id) = @_;
    return 0 unless ref($node);

    if (ref($node) eq 'HASH') {
        if (ref($node->{unsupported_residue}) eq 'ARRAY') {
            for my $entry (@{$node->{unsupported_residue}}) {
                return 1 if ref($entry) eq 'HASH'
                    && defined($entry->{id})
                    && $entry->{id} eq $residue_id;
            }
        }
        for my $value (values %$node) {
            return 1 if residue_id_occurs($value, $residue_id);
        }
        return 0;
    }

    if (ref($node) eq 'ARRAY') {
        for my $value (@$node) {
            return 1 if residue_id_occurs($value, $residue_id);
        }
    }

    return 0;
}

sub detail_pattern_occurs {
    my ($node, $pattern) = @_;
    return 0 unless ref($node);

    if (ref($node) eq 'HASH') {
        return 1 if defined($node->{detail}) && $node->{detail} =~ $pattern;
        for my $value (values %$node) {
            return 1 if detail_pattern_occurs($value, $pattern);
        }
        return 0;
    }

    if (ref($node) eq 'ARRAY') {
        for my $value (@$node) {
            return 1 if detail_pattern_occurs($value, $pattern);
        }
    }

    return 0;
}
