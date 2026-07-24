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

subtest 'source is the exact selected two-subordinate paired BUSY transform' => sub {
    ok(-f sample_path(), 'tracked two-subordinate paired BUSY PPIF sample exists');
    is(slurp(sample_path()), frozen_expected_source(), 'sample differs from the shipped two-subordinate BUSY-park source only by the frozen identity/requester delta');

    my $report = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'schedule JSON keeps AHB interconnect schema');
    is($report->{source_object}{id}, source_object_id(), 'schedule JSON selects source object id');
    is($report->{source_object}{intent_name}, source_intent(), 'schedule JSON selects source intent');
    is($report->{composition}{child_instance_count}, 4, 'schedule JSON reports four children');
    is($report->{composition}{response_mux}{data_phase_owner}{mode}, 'one_hot_accepted_subordinate', 'schedule JSON reports retained one-hot data-phase response ownership');
    is($report->{composition}{response_mux}{data_phase_owner}{retire_event}, 'retained_owner_ready_out', 'schedule JSON reports response-owner retirement on completion');

    is_deeply(
        [map { $_->{name} } @{$report->{generated_artifacts}{ial1}{items}}],
        [qw(amba_requester_busy_insert.isf ahb_status_subordinate_byte_lane_hburst_seq.isf ahb_control_subordinate_byte_lane_hburst_seq.isf ahb_interconnect.isf)],
        'schedule JSON exposes exact IAL1 artifacts in lowering order',
    );
    is_deeply(
        [sort @{$report->{generated_artifacts}{ial0}{files}}],
        [qw(ahb_control_subordinate_byte_lane_hburst_seq.fsm ahb_interconnect.fsm ahb_status_subordinate_byte_lane_hburst_seq.fsm ahb_tb.fsm amba_requester_busy_insert.fsm)],
        'schedule JSON exposes exact IAL0 artifacts',
    );
    is($report->{generated_artifacts}{hdl_entry}{module}, 'ahb_tb', 'schedule JSON selects ahb_tb HDL entry');

    my $requester = $report->{children}[0];
    is($requester->{object_name}, 'amba_requester_busy_insert', 'requester child selects shipped BUSY requester');
    is($requester->{transfer}{busy}, "2'b01", 'requester child reports BUSY encoding');
    is($requester->{transfer}{busy_before_beat}, 2, 'requester child reports BUSY insertion index');
    is($requester->{busy_insertion}{generated_behavior}, 1, 'requester child reports generated BUSY behavior');
    is($requester->{busy_insertion}{beats}, 'single', 'requester child bounds BUSY to one presentation');

    for my $child_index (2, 3) {
        is_deeply($report->{children}[$child_index]{transfer}{seq_policy}{parks_on}, [qw(busy)], "child $child_index parks BUSY");
        is_deeply(
            $report->{children}[$child_index]{transfer}{seq_policy}{clears_on},
            [qw(reset idle error new_nonseq final_beat)],
            "child $child_index keeps BUSY out of clears_on",
        );
    }
    is_deeply(
        [map { $_->{object_name} } @{$report->{composition}{seq_policy_propagation}{subordinates}}],
        [qw(ahb_status_subordinate_byte_lane_hburst_seq ahb_control_subordinate_byte_lane_hburst_seq)],
        'aggregate propagation preserves status/control subordinate order',
    );
    for my $propagated (@{$report->{composition}{seq_policy_propagation}{subordinates}}) {
        is_deeply($propagated->{seq_policy}{parks_on}, [qw(busy)], 'aggregate propagation keeps each child BUSY park');
    }

    my $windows = $report->{composition}{address_map}{windows};
    is_deeply([map { $_->{name} } @$windows], [qw(status control)], 'address map preserves status/control window order');
    is_deeply([map { $_->{base}{default} } @$windows], [0, 4], 'address map preserves status/control bases');
    is_deeply([map { $_->{size}{default} } @$windows], [4, 4], 'address map preserves status/control sizes');
    is_deeply([map { $_->{limit} } @$windows], [4, 8], 'address map preserves status/control limits');

    my $broader = residue_detail($report, 'ahb_broader_interconnect_decode_deferred');
    like($broader, qr/with BUSY-in-burst parking/, 'broader residue reports shipped BUSY parking');
    unlike($broader, qr/BUSY-in-burst continuation/, 'broader residue no longer defers BUSY continuation');
    like(residue_detail($report, 'ahb_burst_seq_support_deferred'), qr/with BUSY-in-burst parking/, 'burst residue reports shipped BUSY parking');
    ok(residue_id_occurs($report, 'ahb_requester_busy_insert_support'), 'requester child keeps bounded BUSY support residue');
    ok(residue_id_occurs($report, 'ahb_aggregate_profile_alias_deferred'), 'generic source keeps aggregate alias residue');
    ok(!exists $report->{composition}{busy_flow}, 'report adds no duplicate top busy_flow summary');
};

subtest 'strict CLI, semantic, review-artifact, and HDL surfaces agree' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check succeeds');
    is($check->{result}{module_name}, 'ahb_tb', 'check JSON reports ahb_tb');
    is($check->{result}{composition_child_count}, 4, 'check JSON reports four children');
    is($check->{result}{signal_count}, 29, 'check JSON reports 29 top signals');
    is($check->{result}{state_count}, 0, 'check JSON reports zero top-local states');
    is($check->{support_accounting}{entry_id}, support_id(), 'check JSON matches support id');
    is($check->{support_accounting}{coverage}, coverage_key(), 'check JSON matches coverage key');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports generic PPIF source kind');
    ok($check->{support_accounting}{strict_supported}, 'check JSON reports strict support');
    undef $check;

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', 'semantic JSON reports ahb_tb');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON reports top source root');
    is($semantic->{support_accounting}{entry_id}, support_id(), 'semantic JSON matches support id');
    undef $semantic;

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my ($generate_ok, undef, undef, $stdout, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'source emits HDL and review artifacts')
        or diag(join('', @{$stdout || []}), join('', @{$stderr || []}));
    is(join('', @{$stderr || []}), '', 'generation keeps stderr clean');

    for my $artifact (qw(
        amba_requester_busy_insert.isf
        ahb_status_subordinate_byte_lane_hburst_seq.isf
        ahb_control_subordinate_byte_lane_hburst_seq.isf
        ahb_interconnect.isf
        amba_requester_busy_insert.fsm
        ahb_status_subordinate_byte_lane_hburst_seq.fsm
        ahb_control_subordinate_byte_lane_hburst_seq.fsm
        ahb_interconnect.fsm
        ahb_tb.fsm
    )) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains $artifact");
    }
    like(slurp(File::Spec->catfile($outdir, 'amba_requester_busy_insert.isf')), qr/\(drive transfer_busy\b/, 'requester IAL1 keeps BUSY drive');
    like(slurp(File::Spec->catfile($outdir, 'ahb_status_subordinate_byte_lane_hburst_seq.isf')), qr/seq_valid_q/, 'status IAL1 keeps burst context');
    like(slurp(File::Spec->catfile($outdir, 'ahb_control_subordinate_byte_lane_hburst_seq.isf')), qr/seq_valid_q/, 'control IAL1 keeps burst context');
    my $interconnect_fsm = slurp(File::Spec->catfile($outdir, 'ahb_interconnect.fsm'));
    like($interconnect_fsm, qr/\(ahb_data_owner_0_q 1 \(reset 0\)\).*?\(ahb_data_owner_1_q 1 \(reset 0\)\)/s, 'two-window fabric declares one reset-clean owner bit per subordinate');
    like($interconnect_fsm, qr/\(<ahb_data_owner_0_q\s+\(= \(HREADY> HREADYOUT_STATUS\)\).*?\(<ahb_data_owner_1_q\s+\(= \(HREADY> HREADYOUT_CONTROL\)\)/s, 'two-window fabric muxes ready from the retained status or control owner');
    like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, 'generated HDL contains ahb_tb');
    like(slurp($hdl), qr/\bahb_interconnect\s+fabric\b/, 'generated HDL keeps legal fabric instance');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--verify-hdl', sample_path()],
    );
    ok($verify_ok, 'public verify-hdl accepts source')
        or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
};

subtest 'generated HDL pairs requester BUSY with both subordinate windows' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public source emits generated HDL for runtime proof')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_two_subordinate_paired_busy_composition_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds two-subordinate paired BUSY harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_two_subordinate_paired_busy_composition_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL two-window paired BUSY proof passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS commands=2 transfers=10 beats=8 busy=2 status=44332211 control=88776655/,
        'runtime proves both windows, held BUSY, and final storage',
    );
};

done_testing();

sub sample_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif');
}

sub base_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif');
}

sub testbench_path {
    return File::Spec->catfile($FindBin::Bin, 'data', 'ahb_two_subordinate_paired_busy_composition_tb.svt');
}

sub source_object_id {
    return 'fsmgen-ahb-interconnect-requester-busy-insert-two-subordinate-byte-lane-hburst-seq-busy-park';
}

sub source_intent {
    return 'ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park';
}

sub support_id {
    return 'intent.ppif_ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park';
}

sub coverage_key {
    return 'ial2_ppif_ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli';
}

sub frozen_expected_source {
    my $source = slurp(base_path());
    replace_once(\$source, '(protocol-platform-intent ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park', '(protocol-platform-intent ' . source_intent());
    replace_once(\$source, '(object fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq-busy-park)', '(object ' . source_object_id() . ')');
    replace_once(\$source, '(section bounded-ahb-interconnect-two-subordinate-byte-lane-hburst-seq-busy-park-propagation)', '(section bounded-ahb-interconnect-requester-busy-insert-two-subordinate-byte-lane-hburst-seq-busy-park)');
    replace_once(\$source, "(ahb-requester amba_requester\n", "(ahb-requester amba_requester_busy_insert\n");
    replace_once(\$source, "      (idle 2'b00)\n      (nonseq 2'b10)\n", "      (idle 2'b00)\n      (busy 2'b01)\n      (nonseq 2'b10)\n");
    replace_once(\$source, "      (later-beats seq)\n      (advance-on ready))\n", "      (later-beats seq)\n      (advance-on ready)\n      (busy-before-beat 2))\n");
    replace_once(\$source, "      (requester requester amba_requester)\n", "      (requester requester amba_requester_busy_insert)\n");
    return $source;
}

sub replace_once {
    my ($text_ref, $from, $to) = @_;
    my $offset = index($$text_ref, $from);
    die "frozen source fragment not found: $from" if $offset < 0;
    die "frozen source fragment repeated: $from" if index($$text_ref, $from, $offset + length($from)) >= 0;
    substr($$text_ref, $offset, length($from), $to);
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

sub residue_detail {
    my ($report, $id) = @_;
    for my $entry (@{$report->{unsupported_residue} || []}) {
        return $entry->{detail} if ref($entry) eq 'HASH' && ($entry->{id} // '') eq $id;
    }
    return '';
}

sub residue_id_occurs {
    my ($node, $id) = @_;
    return 0 unless ref($node);
    if (ref($node) eq 'ARRAY') {
        return scalar grep { residue_id_occurs($_, $id) } @$node;
    }
    return 0 unless ref($node) eq 'HASH';
    return 1 if exists($node->{id}) && ($node->{id} // '') eq $id;
    return scalar grep { residue_id_occurs($node->{$_}, $id) } keys %$node;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
