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

# IAL2-FEATURE-COMPLETENESS-FRONTIER.784: matching aggregate AHB BUSY-park
# HBURST-aware byte-lane SEQ .ahb profile aliases. Each alias is a byte-identical
# mirror of the .782 generic BUSY-park .ppif source; the shared suffix-keyed
# residue suppression removes the profile-alias residue while preserving the
# child parks_on=[busy]/BUSY-free clears_on report.

subtest 'aliases are byte-identical mirrors of the generic BUSY-park sources' => sub {
    for my $case (alias_cases()) {
        ok(-f $case->{alias_path}, "tracked runnable $case->{label} .ahb alias sample exists");
        is(slurp($case->{alias_path}), slurp($case->{ppif_path}), "$case->{label} .ahb is a byte-identical mirror of the generic .ppif source");
    }
};

subtest 'adapter accepts selected aggregate BUSY-park .ahb profile aliases and parks BUSY' => sub {
    for my $case (alias_cases()) {
        my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file($case->{alias_path});
        my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file($case->{ppif_path});

        is($alias->{layer}, 'IAL2', "$case->{label} .ahb parser result stays IAL2");
        is($alias->{kind}, 'protocol_intent.ahb_interconnect', "$case->{label} .ahb keeps interconnect kind");
        is($alias->{report}{source_object}{id}, $case->{source_id}, "$case->{label} .ahb preserves source object id");
        is($alias->{report}{source_object}{intent_name}, $case->{intent_name}, "$case->{label} .ahb preserves intent name");
        is($alias->{report}{target_protocol}{profile}, 'ahb', "$case->{label} .ahb preserves explicit AHB profile");
        is($alias->{report}{composition}{child_instance_count}, $case->{child_count}, "$case->{label} .ahb preserves child count");

        is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, "$case->{label} .ahb mirrors generic PPIF IAL1 artifacts");
        is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, "$case->{label} .ahb mirrors generic PPIF IAL0 files");

        assert_busy_park_seq_policy_propagation(
            $alias->{report}{composition}{seq_policy_propagation},
            $case->{byte_lane_objects},
            $case->{burst_signals},
            "$case->{label} .ahb",
        );

        for my $child_index (@{$case->{child_indices}}) {
            my $child = $alias->{report}{children}[$child_index];
            is($child->{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', "$case->{label} .ahb child $child_index keeps HBURST SEQ policy");
            is_deeply($child->{transfer}{seq_policy}{parks_on}, [qw(busy)], "$case->{label} .ahb child $child_index parks BUSY");
            is_deeply($child->{transfer}{seq_policy}{clears_on}, [qw(reset idle error new_nonseq final_beat)], "$case->{label} .ahb child $child_index drops BUSY from clears_on");
        }

        my %alias_residue_detail = map { $_->{id} => $_->{detail} } @{$alias->{report}{unsupported_residue}};
        my %alias_residue = map { $_ => 1 } keys %alias_residue_detail;
        ok(!$alias_residue{ahb_aggregate_profile_alias_deferred}, "$case->{label} .ahb removes aggregate profile-alias residue");
        ok(!residue_id_occurs($alias->{report}, 'ahb_aggregate_profile_alias_deferred'), "$case->{label} .ahb removes aggregate profile-alias residue from nested reports");
        ok(!residue_id_occurs($alias->{report}, 'ahb_subordinate_profile_alias_deferred'), "$case->{label} .ahb removes subordinate profile-alias residue from nested reports");
        ok(!detail_pattern_occurs($alias->{report}, qr/\.ahb alias exposure/), "$case->{label} .ahb removes alias-exposure residue wording");
        ok($alias_residue{$case->{topology_residue}}, "$case->{label} .ahb keeps topology residue");
        ok($alias_residue{ahb_burst_seq_support_deferred}, "$case->{label} .ahb keeps remaining burst/SEQ residue");
        like($alias_residue{ahb_burst_seq_support_deferred} ? residue_detail($alias->{report}, 'ahb_burst_seq_support_deferred') : '', qr/with BUSY-in-burst parking/, "$case->{label} .ahb top residue records shipped BUSY-in-burst parking");
        if ($case->{child_count} == 4) {
            like($alias_residue_detail{ahb_broader_interconnect_decode_deferred}, qr/byte-only HBURST WRAP4\/INCR4 in-word SEQ propagation with BUSY-in-burst parking/, "$case->{label} .ahb broader topology residue records shipped BUSY parking");
            unlike($alias_residue_detail{ahb_broader_interconnect_decode_deferred}, qr/BUSY-in-burst continuation/, "$case->{label} .ahb broader topology residue no longer defers BUSY continuation");
        }

        my %ppif_residue = map { $_->{id} => 1 } @{$ppif->{report}{unsupported_residue}};
        ok($ppif_residue{ahb_aggregate_profile_alias_deferred}, "$case->{label} generic PPIF keeps aggregate profile-alias residue");
        ok(residue_id_occurs($ppif->{report}, 'ahb_subordinate_profile_alias_deferred'), "$case->{label} generic PPIF keeps subordinate profile-alias residue");
    }
};

subtest 'aggregate BUSY-park .ahb diagnostics stay fail-closed for malformed aliases' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.ahb');
    my $missing_profile_source = one_subordinate_alias_source();
    $missing_profile_source =~ s/^\s*\(profile ahb\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, 'aggregate BUSY-park .ahb without explicit profile is rejected');
    like($@, qr/\.ahb source '.*missing_profile\.ahb' is missing required \(profile \.\.\.\) clause/, 'missing-profile diagnostic is targeted');

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.ahb');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, 'aggregate BUSY-park .ahb with a non-AHB profile is rejected');
    like($@, qr/profile 'valid-ready' does not match \.ahb profile alias; expected ahb/, 'suffix/profile mismatch diagnostic is targeted');

    my $parked_without_policy_path = File::Spec->catfile($tempdir, 'parked_without_policy.ahb');
    my $parked_without_policy_source = one_subordinate_alias_source();
    $parked_without_policy_source =~ s/\n      \(seq-policy hburst-in-word-progressive\)//;
    $parked_without_policy_source =~ s/\n      \(burst HBURST_REGS width 3\)//;
    write_file($parked_without_policy_path, $parked_without_policy_source);
    my $parked_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($parked_without_policy_path); 1 };
    ok(!$parked_ok, 'aggregate BUSY-park .ahb with a parked-busy child lacking the HBURST SEQ policy is rejected');
    like($@, qr/parked-transfer busy requires transfer\.seq_policy hburst-in-word-progressive/, 'parked-busy fail-closed diagnostic is targeted');
};

subtest 'CLI JSON surfaces aggregate BUSY-park .ahb source identity and support accounting' => sub {
    for my $case (alias_cases()) {
        my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', $case->{alias_path});
        ok($check->{success}, "--check --json succeeds for $case->{label} .ahb");
        is($check->{result}{module_name}, 'ahb_tb', "$case->{label} check JSON reports aggregate module name");
        is($check->{result}{composition_child_count}, $case->{child_count}, "$case->{label} check JSON reports child count");
        is($check->{support_accounting}{entry_id}, $case->{entry_id}, "$case->{label} check JSON support accounting names alias entry");
        is($check->{support_accounting}{source_kind}, 'ial2_profile_alias', "$case->{label} check JSON reports profile-alias source kind");
        is($check->{support_accounting}{coverage}, $case->{coverage}, "$case->{label} check JSON reports coverage key");

        my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', $case->{alias_path});
        is($schedule->{source_object}{id}, $case->{source_id}, "$case->{label} schedule JSON preserves source id");
        is($schedule->{composition}{seq_policy_propagation}{mode}, 'subordinate_owned_hburst_in_word_seq_policy', "$case->{label} schedule JSON exposes aggregate HBURST SEQ mode");
        for my $child_index (@{$case->{child_indices}}) {
            is_deeply($schedule->{children}[$child_index]{transfer}{seq_policy}{parks_on}, [qw(busy)], "$case->{label} schedule JSON exposes child parks_on for child $child_index");
        }
        my %schedule_residue = map { $_->{id} => 1 } @{$schedule->{unsupported_residue}};
        ok(!$schedule_residue{ahb_aggregate_profile_alias_deferred}, "$case->{label} schedule JSON removes aggregate profile-alias residue");

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
        like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, "$case->{label} generated HDL contains aggregate module");
        like(slurp(File::Spec->catfile($outdir, $case->{byte_lane_fsm})), qr/seq_hburst_q/, "$case->{label} generated HBURST SEQ subordinate keeps HBURST state");
    }
};

subtest 'existing aggregate HBURST and endpoint BUSY-park boundaries stay unchanged' => sub {
    my $hburst_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(one_subordinate_hburst_seq_alias_path());
    my %hres = map { $_->{id} => $_->{detail} } @{$hburst_alias->{report}{unsupported_residue}};
    like($hres{ahb_burst_seq_support_deferred}, qr/BUSY-in-burst handling/, 'non-park aggregate HBURST .ahb still defers BUSY-in-burst handling');
    ok(!exists $hburst_alias->{report}{children}[2]{transfer}{seq_policy}{parks_on}, 'non-park aggregate HBURST .ahb child has no parks_on');

    my $endpoint_alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(endpoint_busy_park_alias_path());
    is_deeply($endpoint_alias->{report}{transfer}{seq_policy}{parks_on}, [qw(busy)], 'endpoint BUSY-park .ahb still parks BUSY');
    ok(!exists $endpoint_alias->{report}{composition}, 'endpoint BUSY-park .ahb does not gain aggregate composition report');
};

done_testing();

sub alias_cases {
    return (
        {
            label => 'one-subordinate aggregate BUSY-park',
            alias_path => alias_path('ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb'),
            ppif_path => alias_path('ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif'),
            entry_id => 'intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park',
            coverage => 'ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli',
            source_id => 'fsmgen-ahb-interconnect-byte-lane-hburst-seq-busy-park',
            intent_name => 'ahb_interconnect_byte_lane_hburst_seq_busy_park',
            topology_residue => 'ahb_multi_subordinate_decode_deferred',
            child_count => 3,
            child_indices => [2],
            generated_isf => [qw(amba_requester.isf ahb_lite_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            byte_lane_objects => [qw(ahb_lite_subordinate_byte_lane_hburst_seq)],
            burst_signals => [qw(HBURST_REGS)],
            byte_lane_fsm => 'ahb_lite_subordinate_byte_lane_hburst_seq.fsm',
        },
        {
            label => 'two-subordinate aggregate BUSY-park',
            alias_path => alias_path('ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb'),
            ppif_path => alias_path('ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif'),
            entry_id => 'intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park',
            coverage => 'ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli',
            source_id => 'fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq-busy-park',
            intent_name => 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park',
            topology_residue => 'ahb_broader_interconnect_decode_deferred',
            child_count => 4,
            child_indices => [2, 3],
            generated_isf => [qw(amba_requester.isf ahb_status_subordinate_byte_lane_hburst_seq.isf ahb_control_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
            generated_fsm => [qw(amba_requester.fsm ahb_status_subordinate_byte_lane_hburst_seq.fsm ahb_control_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_tb.fsm)],
            byte_lane_objects => [qw(ahb_status_subordinate_byte_lane_hburst_seq ahb_control_subordinate_byte_lane_hburst_seq)],
            burst_signals => [qw(HBURST_STATUS HBURST_CONTROL)],
            byte_lane_fsm => 'ahb_control_subordinate_byte_lane_hburst_seq.fsm',
        },
    );
}

sub assert_busy_park_seq_policy_propagation {
    my ($propagation, $expected_objects, $expected_bursts, $label) = @_;
    ok($propagation->{selected}, "$label report selects aggregate HBURST SEQ propagation");
    is($propagation->{mode}, 'subordinate_owned_hburst_in_word_seq_policy', "$label report records subordinate-owned HBURST SEQ mode");
    is($propagation->{length_source}, 'HBURST', "$label report records global HBURST length source");
    is_deeply([map { $_->{object_name} } @{$propagation->{subordinates}}], $expected_objects, "$label report preserves subordinate order");
    is_deeply($propagation->{request_forwarding}{burst}{child_names}, $expected_bursts, "$label report records child-local HBURST fanout names");
    for my $subordinate (@{$propagation->{subordinates}}) {
        is($subordinate->{seq_policy}{mode}, 'hburst_in_word_progressive', "$label report carries child HBURST SEQ policy");
        is_deeply($subordinate->{seq_policy}{parks_on}, [qw(busy)], "$label report propagates the child parks_on=[busy]");
        is_deeply($subordinate->{seq_policy}{clears_on}, [qw(reset idle error new_nonseq final_beat)], "$label report propagates the BUSY-free clears_on");
    }
}

sub alias_path {
    my ($name) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', $name);
}

sub one_subordinate_hburst_seq_alias_path {
    return alias_path('ahb_interconnect_byte_lane_hburst_seq.ahb');
}

sub endpoint_busy_park_alias_path {
    return alias_path('ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb');
}

sub sample_valid_ready_handshake_ppif_path {
    return alias_path('valid_ready_handshake.ppif');
}

sub one_subordinate_alias_source {
    return slurp(alias_path('ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb'));
}

sub residue_detail {
    my ($report, $id) = @_;
    for my $entry (@{$report->{unsupported_residue}}) {
        return $entry->{detail} if ref($entry) eq 'HASH' && ($entry->{id} // '') eq $id;
    }
    return '';
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
                return 1 if ref($entry) eq 'HASH' && defined($entry->{id}) && $entry->{id} eq $residue_id;
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
