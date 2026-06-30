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

subtest 'adapter accepts selected AHB aggregate byte-lane .ahb profile aliases' => sub {
    my @cases = alias_cases();

    for my $case (@cases) {
        ok(-f $case->{alias_path}, "tracked runnable $case->{label} .ahb alias sample exists");

        my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file($case->{alias_path});
        my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file($case->{ppif_path});

        is($alias->{layer}, 'IAL2', "$case->{label} .ahb parser result stays IAL2");
        is($alias->{kind}, 'protocol_intent.ahb_interconnect', "$case->{label} .ahb keeps interconnect kind");
        is($alias->{mode}, 'requester-subordinate-interconnect', "$case->{label} .ahb keeps aggregate mode");
        is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', "$case->{label} .ahb report keeps schema");
        is($alias->{report}{source_object}{id}, $case->{source_id}, "$case->{label} .ahb preserves source object id");
        is($alias->{report}{source_object}{intent_name}, $case->{intent_name}, "$case->{label} .ahb preserves intent name");
        is($alias->{report}{target_protocol}{profile}, 'ahb', "$case->{label} .ahb preserves profile");
        is($alias->{report}{target_protocol}{object}, 'ahb-interconnect', "$case->{label} .ahb preserves interconnect object");
        is($alias->{report}{composition}{topology}, $case->{topology}, "$case->{label} .ahb preserves topology");
        is($alias->{report}{composition}{child_instance_count}, $case->{child_count}, "$case->{label} .ahb preserves child count");
        ok($alias->{report}{composition}{byte_lane_propagation}{selected}, "$case->{label} .ahb reports aggregate byte-lane propagation");

        is_deeply(
            [map { $_->{name} } @{$alias->{generated_ial1}{items}}],
            $case->{generated_isf},
            "$case->{label} .ahb exposes generated IAL1 review artifacts",
        );
        is_deeply(
            [map { $_->{entry_artifact} } @{$alias->{generated_ial0}{items}}],
            $case->{generated_fsm},
            "$case->{label} .ahb exposes generated IAL0 review artifacts",
        );
        is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, "$case->{label} .ahb mirrors generic PPIF IAL1 artifacts");
        is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, "$case->{label} .ahb mirrors generic PPIF IAL0 files");

        my $propagation = $alias->{report}{composition}{byte_lane_propagation};
        is($propagation->{mode}, 'subordinate_owned_narrow_transfer_policy', "$case->{label} .ahb keeps subordinate-owned propagation mode");
        is($propagation->{local_address_policy}, 'subtract_window_base_before_subordinate_lane_policy', "$case->{label} .ahb keeps local-address policy");
        is_deeply(
            [map { $_->{object_name} } @{$propagation->{subordinates}}],
            $case->{byte_lane_objects},
            "$case->{label} .ahb preserves propagated byte-lane subordinate order",
        );
        is_deeply(
            [map { $_->{local_address_signal}{name} } @{$propagation->{subordinates}}],
            $case->{local_address_signals},
            "$case->{label} .ahb preserves propagated local address signals",
        );
        for my $subordinate (@{$propagation->{subordinates}}) {
            is_deeply($subordinate->{supported_size}, [qw(byte halfword word)], "$case->{label} .ahb records byte/halfword/word support");
            is($subordinate->{narrow_transfer_policy}{narrow_write}{policy}, 'preserve-inactive-lanes', "$case->{label} .ahb carries narrow-write policy");
            is($subordinate->{narrow_transfer_policy}{narrow_read}{policy}, 'zero-fill-inactive-lanes', "$case->{label} .ahb carries narrow-read policy");
        }

        my %alias_residue = map { $_->{id} => 1 } @{$alias->{report}{unsupported_residue}};
        ok(!$alias_residue{ahb_aggregate_profile_alias_deferred}, "$case->{label} .ahb removes aggregate profile-alias residue");
        ok(!residue_id_occurs($alias->{report}, 'ahb_aggregate_profile_alias_deferred'), "$case->{label} .ahb removes aggregate profile-alias residue from nested reports");
        ok(!residue_id_occurs($alias->{report}, 'ahb_profile_alias_deferred'), "$case->{label} .ahb removes requester profile-alias residue from nested reports");
        ok(!residue_id_occurs($alias->{report}, 'ahb_subordinate_profile_alias_deferred'), "$case->{label} .ahb removes subordinate profile-alias residue from nested reports");
        ok($alias_residue{ahb_optional_signal_residue}, "$case->{label} .ahb keeps optional-signal residue");
        ok($alias_residue{ahb_burst_seq_support_deferred}, "$case->{label} .ahb keeps burst SEQ residue");
        ok($alias_residue{ahb_direct_backend_deferred}, "$case->{label} .ahb keeps direct-backend residue");
        ok($alias_residue{ahb_verification_output_deferred}, "$case->{label} .ahb keeps verification/backend residue");

        my %ppif_residue = map { $_->{id} => 1 } @{$ppif->{report}{unsupported_residue}};
        ok($ppif_residue{ahb_aggregate_profile_alias_deferred}, "$case->{label} generic PPIF keeps aggregate profile-alias residue");
        ok(residue_id_occurs($ppif->{report}, 'ahb_profile_alias_deferred'), "$case->{label} generic PPIF keeps requester profile-alias residue");
        ok(residue_id_occurs($ppif->{report}, 'ahb_subordinate_profile_alias_deferred'), "$case->{label} generic PPIF keeps subordinate profile-alias residue");
    }
};

subtest 'aggregate byte-lane .ahb diagnostics stay fail-closed for malformed aliases' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.ahb');
    my $missing_profile_source = one_subordinate_alias_source();
    $missing_profile_source =~ s/^\s*\(profile ahb\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, 'aggregate byte-lane .ahb without explicit profile is rejected');
    like(
        $@,
        qr/\.ahb source '.*missing_profile\.ahb' is missing required \(profile \.\.\.\) clause/,
        'aggregate byte-lane .ahb missing-profile diagnostic is targeted',
    );

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.ahb');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, 'aggregate byte-lane .ahb with a non-AHB profile is rejected');
    like(
        $@,
        qr/profile 'valid-ready' does not match \.ahb profile alias; expected ahb/,
        'aggregate byte-lane .ahb suffix/profile mismatch diagnostic is targeted',
    );

    my $wrong_object_path = File::Spec->catfile($tempdir, 'wrong_object.ahb');
    my $wrong_object_source = slurp(sample_valid_ready_handshake_ppif_path());
    $wrong_object_source =~ s/\(profile valid-ready\)/(profile ahb)/;
    write_file($wrong_object_path, $wrong_object_source);
    my $wrong_object_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($wrong_object_path); 1 };
    ok(!$wrong_object_ok, '.ahb profile with unsupported object breadth is rejected');
    like(
        $@,
        qr/profile ahb requires exactly one \(ahb-requester \.\.\.\) object, exactly one \(ahb-subordinate \.\.\.\) object, the selected aggregate one-requester\/one-subordinate \(ahb-interconnect \.\.\.\) shape, or the selected aggregate one-requester\/two-subordinate \(ahb-interconnect \.\.\.\) shape in this slice/,
        '.ahb unsupported object diagnostic remains fail-closed',
    );

    my $scalar_wiring_path = File::Spec->catfile($tempdir, 'scalar_wiring.ahb');
    my $scalar_wiring_source = two_subordinate_alias_source();
    $scalar_wiring_source =~ s/\(lock HLOCK\)\n      \(write-data HWDATA width 32\)/(lock HLOCK)\n      (write-data HWDATA width 32)\n      (subordinate-select HSEL_STATUS)/;
    write_file($scalar_wiring_path, $scalar_wiring_source);
    my $scalar_wiring_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($scalar_wiring_path); 1 };
    ok(!$scalar_wiring_ok, 'two-subordinate aggregate byte-lane .ahb with scalar subordinate wiring is rejected');
    like(
        $@,
        qr/two-subordinate wiring must omit scalar bus.subordinate_select/,
        'two-subordinate aggregate byte-lane .ahb scalar wiring diagnostic is targeted',
    );
};

subtest 'CLI JSON surfaces aggregate byte-lane .ahb source identity and support accounting' => sub {
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

subtest 'schedule JSON and outdir expose aggregate byte-lane .ahb review artifacts' => sub {
    for my $case (alias_cases()) {
        my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', $case->{alias_path});
        is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', "$case->{label} schedule JSON reports interconnect schema");
        is($schedule->{source_object}{id}, $case->{source_id}, "$case->{label} schedule JSON preserves source id");
        is($schedule->{composition}{topology}, $case->{topology}, "$case->{label} schedule JSON reports topology");
        is($schedule->{composition}{child_instance_count}, $case->{child_count}, "$case->{label} schedule JSON reports child count");
        ok($schedule->{composition}{byte_lane_propagation}{selected}, "$case->{label} schedule JSON exposes byte-lane propagation");
        is_deeply(
            $schedule->{generated_artifacts}{hdl_entry}{child_artifacts},
            $case->{hdl_child_artifacts},
            "$case->{label} schedule JSON exposes child artifacts under HDL entry",
        );
        my %schedule_residue = map { $_->{id} => 1 } @{$schedule->{unsupported_residue}};
        ok(!$schedule_residue{ahb_aggregate_profile_alias_deferred}, "$case->{label} schedule JSON removes aggregate profile-alias residue");
        ok(!residue_id_occurs($schedule, 'ahb_aggregate_profile_alias_deferred'), "$case->{label} schedule JSON removes nested aggregate profile-alias residue");
        ok(!residue_id_occurs($schedule, 'ahb_profile_alias_deferred'), "$case->{label} schedule JSON removes nested requester profile-alias residue");
        ok(!residue_id_occurs($schedule, 'ahb_subordinate_profile_alias_deferred'), "$case->{label} schedule JSON removes nested subordinate profile-alias residue");
        ok($schedule_residue{$case->{topology_residue}}, "$case->{label} schedule JSON keeps topology residue");
        ok($schedule_residue{ahb_optional_signal_residue}, "$case->{label} schedule JSON keeps optional-signal residue");

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
        like(slurp(File::Spec->catfile($outdir, $case->{byte_lane_fsm})), qr/read_halfword_lane1_hit_start/, "$case->{label} generated byte-lane subordinate keeps halfword path");
    }
};

subtest 'existing AHB aggregate and endpoint boundaries stay unchanged' => sub {
    my $word_only_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(word_only_interconnect_alias_path());
    ok(!exists $word_only_alias->{report}{composition}{byte_lane_propagation}, 'word-only aggregate .ahb does not gain byte-lane propagation report');

    my $byte_lane_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_byte_lane_ppif_path());
    my %byte_lane_ppif_residue = map { $_->{id} => 1 } @{$byte_lane_ppif->{report}{unsupported_residue}};
    ok($byte_lane_ppif_residue{ahb_aggregate_profile_alias_deferred}, 'generic aggregate byte-lane PPIF keeps alias-deferred residue');
    ok(residue_id_occurs($byte_lane_ppif->{report}, 'ahb_profile_alias_deferred'), 'generic aggregate byte-lane PPIF keeps requester profile-alias residue');
    ok(residue_id_occurs($byte_lane_ppif->{report}, 'ahb_subordinate_profile_alias_deferred'), 'generic aggregate byte-lane PPIF keeps subordinate profile-alias residue');

    my $endpoint_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(endpoint_byte_lane_alias_path());
    is($endpoint_alias->{report}{narrow_transfer_policy}{narrow_read}{policy}, 'zero-fill-inactive-lanes', 'endpoint byte-lane .ahb keeps narrow-transfer policy');

    my $two_subordinate_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(word_only_two_subordinate_alias_path());
    ok(!exists $two_subordinate_alias->{report}{composition}{byte_lane_propagation}, 'word-only two-subordinate .ahb does not gain byte-lane propagation report');
};

done_testing();

sub alias_cases {
    return (
        {
            label => 'one-subordinate aggregate byte-lane',
            alias_path => one_subordinate_byte_lane_alias_path(),
            ppif_path => one_subordinate_byte_lane_ppif_path(),
            entry_id => 'intent.ahb_profile_alias_interconnect_byte_lane',
            coverage => 'ial2_ahb_profile_alias_interconnect_byte_lane_pipeline_cli',
            source_id => 'fsmgen-ahb-interconnect-byte-lane',
            intent_name => 'ahb_interconnect_byte_lane',
            topology => 'one_requester_one_subordinate_static_window_interconnect',
            topology_residue => 'ahb_multi_subordinate_decode_deferred',
            child_count => 3,
            generated_isf => [qw(amba_requester.isf ahb_lite_subordinate_byte_lane.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_lite_subordinate_byte_lane.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            hdl_child_artifacts => [qw(amba_requester.fsm ahb_interconnect.fsm ahb_lite_subordinate_byte_lane.fsm)],
            byte_lane_objects => [qw(ahb_lite_subordinate_byte_lane)],
            local_address_signals => [qw(HADDR_REGS)],
            byte_lane_fsm => 'ahb_lite_subordinate_byte_lane.fsm',
        },
        {
            label => 'two-subordinate aggregate byte-lane',
            alias_path => two_subordinate_byte_lane_alias_path(),
            ppif_path => two_subordinate_byte_lane_ppif_path(),
            entry_id => 'intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane',
            coverage => 'ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_pipeline_cli',
            source_id => 'fsmgen-ahb-interconnect-two-subordinate-byte-lane',
            intent_name => 'ahb_interconnect_two_subordinate_byte_lane',
            topology => 'one_requester_two_subordinate_static_window_interconnect',
            topology_residue => 'ahb_broader_interconnect_decode_deferred',
            child_count => 4,
            generated_isf => [qw(amba_requester.isf ahb_status_subordinate_byte_lane.isf ahb_control_subordinate_byte_lane.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_status_subordinate_byte_lane.fsm ahb_control_subordinate_byte_lane.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            hdl_child_artifacts => [qw(amba_requester.fsm ahb_interconnect.fsm ahb_status_subordinate_byte_lane.fsm ahb_control_subordinate_byte_lane.fsm)],
            byte_lane_objects => [qw(ahb_status_subordinate_byte_lane ahb_control_subordinate_byte_lane)],
            local_address_signals => [qw(HADDR_STATUS HADDR_CONTROL)],
            byte_lane_fsm => 'ahb_control_subordinate_byte_lane.fsm',
        },
    );
}

sub one_subordinate_byte_lane_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane.ahb');
}

sub two_subordinate_byte_lane_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane.ahb');
}

sub one_subordinate_byte_lane_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane.ppif');
}

sub two_subordinate_byte_lane_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane.ppif');
}

sub word_only_interconnect_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect.ahb');
}

sub word_only_two_subordinate_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate.ahb');
}

sub endpoint_byte_lane_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane.ahb');
}

sub sample_valid_ready_handshake_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
}

sub one_subordinate_alias_source {
    return slurp(one_subordinate_byte_lane_alias_path());
}

sub two_subordinate_alias_source {
    return slurp(two_subordinate_byte_lane_alias_path());
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
