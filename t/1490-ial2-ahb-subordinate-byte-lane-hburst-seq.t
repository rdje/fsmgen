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

subtest 'adapter parses selected AHB subordinate byte-lane HBURST SEQ PPIF shape' => sub {
    ok(-f sample_hburst_seq_ppif_path(), 'tracked runnable AHB byte-lane HBURST SEQ subordinate PPIF sample exists');
    like(sample_hburst_seq_ppif(), qr/\(burst HBURST width 3\)/, 'sample carries the selected HBURST bus binding');
    like(sample_hburst_seq_ppif(), qr/\(seq-policy hburst-in-word-progressive\)/, 'sample carries the selected HBURST SEQ policy clause');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_hburst_seq_ppif_path());

    is($result->{layer}, 'IAL2', 'AHB byte-lane HBURST SEQ subordinate adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_subordinate', 'adapter returns the AHB subordinate kind');
    is($result->{mode}, 'subordinate', 'AHB byte-lane HBURST SEQ subordinate mode is explicit');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-lite-subordinate-byte-lane-hburst-seq', 'source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq', 'source intent name is preserved');
    is($result->{report}{target_protocol}{transfer}, 'ahb_lite_byte_lane_hburst_seq_access', 'report names selected transfer');
    is($result->{report}{bindings}{bus}{burst}{name}, 'HBURST', 'report captures HBURST bus binding');
    is($result->{report}{bindings}{bus}{burst}{width}, 3, 'report captures HBURST width');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'ahb_lite_subordinate_byte_lane_hburst_seq.isf', 'generated IAL1 artifact is named');
    like($isf, qr/\A\(actor ahb_lite_subordinate_byte_lane_hburst_seq\b/, 'generated IAL1 names byte-lane HBURST SEQ subordinate actor');
    like($isf, qr/\(input HBURST \(width 3\)\)/, 'generated IAL1 exposes HBURST input');
    like($isf, qr/\(set next_burst_q HBURST\).*?\(sample next_burst_q as burst_q\)/s, 'generated IAL1 captures then relaunches HBURST alongside transfer controls');
    like($isf, qr/\(var seq_hburst_q \(width 3\) \(reset 0\)\)/, 'generated IAL1 stores the prior HBURST for control stability');
    like($isf, qr/\(var seq_beats_remaining_q \(width 2\) \(reset 0\)\)/, 'generated IAL1 stores bounded four-beat remaining count');
    like($isf, qr/\(rule ahb_phase_capture \(& \(! ahb_phase_pending_q\) HSEL HREADY \(\| \(== HTRANS 2'b10\) \(== HTRANS 2'b11\)\)\)/, 'generated IAL1 captures one ready active HBURST transfer phase at a time');
    like($isf, qr/\(rule ahb_seq_idle_clear \(& HSEL HREADY \(\| \(== HTRANS 2'b00\) \(== HTRANS 2'b01\)\)\)/s, 'generated IAL1 concurrently clears HBURST continuation history on accepted IDLE/BUSY');
    like($isf, qr/\(set seq_hburst_q 0\)\s+\(set seq_beats_remaining_q 0\)/s, 'generated IAL1 clear path resets HBURST continuation state');
    like($isf, qr/\(when \(& \(== trans_q 2'b10\) \(== burst_q 0\).*size_q 2.*write_q\)\s+\(set reg_data_q HWDATA\)\s+\(set seq_valid_q 0\)/s, 'HBURST SINGLE word access remains supported and clears history');
    like($isf, qr/\(when \(& \(== trans_q 2'b10\) \(== burst_q 2\).*32'h00000003.*write_q\)\s+\(set reg_data_q.*32'hff000000.*\)\s+\(set seq_valid_q 1\)\s+\(set seq_expected_addr_q 32'h00000000\).*?\(set seq_hburst_q burst_q\)\s+\(set seq_beats_remaining_q 3\)/s, 'WRAP4 NONSEQ byte lane 3 wraps expected address to lane 0');
    like($isf, qr/\(when \(& \(== trans_q 2'b10\) \(== burst_q 3\).*32'h00000000.*write_q\)\s+\(set reg_data_q.*32'h000000ff.*\)\s+\(set seq_valid_q 1\)\s+\(set seq_expected_addr_q 32'h00000001\).*?\(set seq_hburst_q burst_q\)\s+\(set seq_beats_remaining_q 3\)/s, 'INCR4 NONSEQ byte lane 0 arms byte address 1');
    unlike($isf, qr/^\s+\(when \(& \(== trans_q 2'b10\) \(== burst_q 3\).*32'h00000001.*write_q\)$/m, 'INCR4 NONSEQ byte lane 1 does not arm a burst');
    like($isf, qr/\(when \(& \(== trans_q 2'b11\).*seq_hburst_q.*seq_beats_remaining_q.*write_q\)\s+\(set reg_data_q.*32'h0000ff00.*\).*?\(when \(== seq_hburst_q 2\) \(set seq_expected_addr_q \(& \(\+ addr_q 1\) 32'h00000003\)\)\).*?\(when \(== seq_hburst_q 3\) \(set seq_expected_addr_q \(\+ addr_q 1\)\)\).*?\(set seq_beats_remaining_q \(- seq_beats_remaining_q 1\)\)/s, 'accepted SEQ byte beat advances WRAP4 or INCR4 address and decrements remaining count');
    like($isf, qr/\(when \(== seq_beats_remaining_q 1\)\s+\(set seq_valid_q 0\).*?\(set seq_hburst_q 0\)\s+\(set seq_beats_remaining_q 0\)\s+\)/s, 'fourth accepted beat clears continuation history');
    like($isf, qr/\(when \(& \(== trans_q 2'b11\) \(! \(& seq_valid_q .*?\(== burst_q seq_hburst_q\).*?\)\)\)\s+\(set seq_valid_q 0\).*?\(drive error_first\)\s+\(drive error_complete\)/s, 'standalone or mismatched SEQ transfers fail closed');

    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['ahb_lite_subordinate_byte_lane_hburst_seq.fsm'],
        'adapter exposes generated byte-lane HBURST SEQ AHB IAL0 .fsm file map',
    );
    my $fsm = $result->{generated_ial0}{files}{'ahb_lite_subordinate_byte_lane_hburst_seq.fsm'};
    like($fsm, qr/\(\?fsm:ahb_lite_subordinate_byte_lane_hburst_seq\b/, 'generated IAL0 names byte-lane HBURST SEQ subordinate FSM');
    like($fsm, qr/HBURST/, 'generated IAL0 carries HBURST input');
    like($fsm, qr/seq_hburst_q/, 'generated IAL0 carries HBURST stability state');
    like($fsm, qr/seq_beats_remaining_q/, 'generated IAL0 carries four-beat remaining state');

    is_deeply($result->{report}{transfer}{supported_size}, [qw(byte halfword word)], 'report keeps selected byte-lane supported sizes');
    is($result->{report}{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'report captures selected HBURST SEQ policy mode');
    is($result->{report}{transfer}{seq_policy}{base_policy}, 'in_word_progressive', 'report captures base in-word progression');
    is($result->{report}{transfer}{seq_policy}{length_source}, 'HBURST', 'report captures HBURST as burst-length source');
    is($result->{report}{transfer}{seq_policy}{requires_prior_transfer}, 'prior_okay_hburst_nonseq_or_seq', 'report captures prior-transfer requirement');
    is_deeply($result->{report}{transfer}{seq_policy}{supported_sizes}, [qw(byte)], 'report narrows HBURST SEQ policy to byte transfers');
    is_deeply($result->{report}{transfer}{seq_policy}{supported_hburst_modes}, [qw(WRAP4 INCR4)], 'report captures supported fixed four-beat HBURST modes');
    is_deeply($result->{report}{transfer}{seq_policy}{fail_closed_hburst_modes}, [qw(INCR WRAP8 INCR8 WRAP16 INCR16)], 'report captures fail-closed HBURST modes');
    is($result->{report}{transfer}{seq_policy}{single_policy}, 'nonseq_only_no_seq_history', 'report captures SINGLE policy');
    is($result->{report}{transfer}{seq_policy}{beats_per_burst}, 4, 'report captures four beats per supported burst');
    is($result->{report}{transfer}{seq_policy}{window_bytes}, 4, 'report captures one-word byte window');
    is($result->{report}{transfer}{seq_policy}{address_progression}, 'hburst_incr4_or_wrap4_within_word', 'report captures HBURST-driven address progression');
    is_deeply($result->{report}{transfer}{seq_policy}{control_stability}, [qw(HBURST HWRITE HSIZE)], 'report captures HBURST/HWRITE/HSIZE stability');
    is_deeply($result->{report}{transfer}{seq_policy}{clears_on}, [qw(reset idle busy error new_nonseq final_beat)], 'report captures continuation-history clear events');
    is($result->{report}{narrow_transfer_policy}{byte_lanes}[3]{mask}, "32'hff000000", 'report keeps byte-lane policy alongside HBURST SEQ policy');
    is($result->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'ahb_lite_subordinate_byte_lane_hburst_seq.fsm', 'report selects generated byte-lane HBURST SEQ subordinate .fsm as HDL entry');

    my %residue = map { $_->{id} => $_->{detail} } @{$result->{report}{unsupported_residue}};
    ok($residue{ahb_subordinate_profile_alias_deferred}, 'report keeps .ahb alias residue explicit for the new generic source');
    unlike($residue{ahb_subordinate_optional_signal_residue}, qr/\bHBURST\b/, 'optional-signal residue no longer lists HBURST for the HBURST-aware source');
    like($residue{ahb_burst_seq_support_deferred}, qr/Byte-only HBURST WRAP4\/INCR4 in-word SEQ is shipped/, 'report records shipped bounded HBURST byte SEQ behavior');
    like($residue{ahb_burst_seq_support_deferred}, qr/indefinite INCR, WRAP8\/INCR8\/WRAP16\/INCR16, halfword\/word burst SEQ/, 'report keeps unsupported burst modes and larger burst sizes deferred');
    like($residue{ahb_burst_seq_support_deferred}, qr/\.ahb alias exposure, aggregate propagation/, 'report keeps alias and aggregate HBURST SEQ propagation deferred');
};

subtest 'malformed byte-lane HBURST SEQ AHB subordinate PPIF sources fail closed' => sub {
    my @cases = (
        [
            'duplicate burst binding',
            sub {
                my $source = sample_hburst_seq_ppif();
                $source =~ s/\(burst HBURST width 3\)/(burst HBURST width 3)\n      (burst HBURST2 width 3)/;
                return $source;
            },
            qr/duplicate \(burst \.\.\.\) clause/,
        ],
        [
            'wrong burst width',
            sub {
                my $source = sample_hburst_seq_ppif();
                $source =~ s/\(burst HBURST width 3\)/(burst HBURST width 2)/;
                return $source;
            },
            qr/bus\.burst\.width must be 3/,
        ],
        [
            'hburst seq policy without burst binding',
            sub {
                my $source = sample_hburst_seq_ppif();
                $source =~ s/\n      \(burst HBURST width 3\)//;
                return $source;
            },
            qr/transfer\.seq_policy hburst-in-word-progressive requires bus\.burst/,
        ],
        [
            'unsupported seq policy',
            sub {
                my $source = sample_hburst_seq_ppif();
                $source =~ s/\(seq-policy hburst-in-word-progressive\)/(seq-policy full-burst)/;
                return $source;
            },
            qr/transfer\.seq_policy must be in-word-progressive or hburst-in-word-progressive/,
        ],
        [
            'seq policy without byte-lane size policy',
            sub {
                my $source = sample_hburst_seq_ppif();
                $source =~ s/\n      \(supported-size (?:byte|halfword|word)\)//g;
                $source =~ s/\n      \((?:lane-order|narrow-write|narrow-read|unaligned-access|crossing-access) [^)]+\)//g;
                return $source;
            },
            qr/transfer\.seq_policy requires the selected byte-lane size policy/,
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

subtest 'CLI checks, semantic export, schedule report, and outdir use the byte-lane HBURST SEQ path' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_hburst_seq_ppif_path());
    ok($check->{success}, 'strict check JSON succeeds for byte-lane HBURST SEQ AHB subordinate PPIF');
    is($check->{result}{module_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq', 'check JSON reports generated byte-lane HBURST SEQ subordinate module name');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq', 'check JSON matches byte-lane HBURST SEQ support accounting');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports PPIF source kind');
    is($check->{support_accounting}{coverage}, 'ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_pipeline_cli', 'check JSON reports selected coverage key');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_hburst_seq_ppif_path());
    ok($semantic->{success}, 'strict semantic JSON succeeds for byte-lane HBURST SEQ AHB subordinate PPIF');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq', 'semantic JSON reports generated module name');
    is($semantic->{support_accounting}{entry_id}, 'intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq', 'semantic JSON matches byte-lane HBURST SEQ support accounting');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_hburst_seq_ppif_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_subordinate.v1', 'schedule/report JSON exposes AHB subordinate schema');
    is($schedule->{generated_artifacts}{ial1}{name}, 'ahb_lite_subordinate_byte_lane_hburst_seq.isf', 'schedule/report JSON exposes generated IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['ahb_lite_subordinate_byte_lane_hburst_seq.fsm'], 'schedule/report JSON exposes generated IAL0 artifact');
    is($schedule->{bindings}{bus}{burst}{name}, 'HBURST', 'schedule/report JSON exposes HBURST bus binding');
    is($schedule->{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'schedule/report JSON exposes selected HBURST SEQ policy mode');
    is_deeply($schedule->{transfer}{seq_policy}{supported_hburst_modes}, [qw(WRAP4 INCR4)], 'schedule/report JSON exposes supported HBURST modes');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_lite_subordinate_byte_lane_hburst_seq.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_hburst_seq_ppif_path()],
    );
    ok($success, 'byte-lane HBURST SEQ AHB subordinate PPIF emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq.isf'), 'outdir contains generated byte-lane HBURST SEQ IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq.fsm'), 'outdir contains generated byte-lane HBURST SEQ IAL0 artifact');
    ok(-f $hdl, 'outdir command emits selected byte-lane HBURST SEQ subordinate HDL output');
    like(slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq.isf')), qr/seq_hburst_q/, 'outdir generated .isf keeps HBURST stability state');
    like(slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq.fsm')), qr/seq_beats_remaining_q/, 'outdir generated .fsm keeps four-beat remaining state');
    like(slurp($hdl), qr/\bmodule\s+ahb_lite_subordinate_byte_lane_hburst_seq\b/, 'generated HDL contains byte-lane HBURST SEQ AHB subordinate module');
    like(slurp($hdl), qr/\binput\s+wire\s+\[2:0\]\s+HBURST\b/, 'generated HDL exposes HBURST input');
};

subtest 'existing AHB subordinate sources, aliases, and aggregates stay unchanged at the public boundary' => sub {
    my $byte_lane_seq = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_byte_lane_seq_ppif_path());
    ok(!exists $byte_lane_seq->{report}{bindings}{bus}{burst}, 'existing byte-lane SEQ PPIF report does not gain HBURST binding');
    is($byte_lane_seq->{report}{transfer}{seq_policy}{mode}, 'in_word_progressive', 'existing byte-lane SEQ policy mode is unchanged');
    unlike($byte_lane_seq->{generated_ial1}{text}, qr/seq_hburst_q/, 'existing byte-lane SEQ generated IAL1 does not gain HBURST state');

    my $byte_lane = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_byte_lane_ppif_path());
    ok(!exists $byte_lane->{report}{bindings}{bus}{burst}, 'existing byte-lane PPIF report does not gain HBURST binding');
    ok(!exists $byte_lane->{report}{transfer}{seq_policy}, 'existing byte-lane PPIF report does not gain SEQ policy');

    my $alias_check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_byte_lane_seq_alias_path());
    ok($alias_check->{success}, 'existing byte-lane SEQ subordinate .ahb alias still checks successfully');
    is($alias_check->{result}{module_name}, 'ahb_lite_subordinate_byte_lane_seq', 'existing byte-lane SEQ subordinate .ahb alias keeps module name');
    is($alias_check->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_subordinate_byte_lane_seq', 'existing byte-lane SEQ subordinate .ahb alias keeps support identity');

    my $aggregate = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_aggregate_byte_lane_seq_ppif_path());
    is($aggregate->{report}{composition}{seq_policy_propagation}{selected}, JSON::PP::true, 'existing aggregate byte-lane SEQ propagation report remains selected');
    like(
        join("\n", map { $_->{detail} } @{$aggregate->{report}{unsupported_residue} || []}),
        qr/HBURST-driven length\/wrap/,
        'existing aggregate byte-lane SEQ report keeps HBURST propagation deferred',
    );
};

done_testing();

sub sample_hburst_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_hburst_seq.ppif');
}

sub sample_byte_lane_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_seq.ppif');
}

sub sample_byte_lane_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane.ppif');
}

sub sample_byte_lane_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_seq.ahb');
}

sub sample_aggregate_byte_lane_seq_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_seq.ppif');
}

sub sample_hburst_seq_ppif {
    return slurp(sample_hburst_seq_ppif_path());
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
