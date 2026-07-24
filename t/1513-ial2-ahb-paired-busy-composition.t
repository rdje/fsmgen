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

subtest 'adapter composes requester BUSY insertion with subordinate BUSY parking' => sub {
    ok(-f sample_path(), 'tracked paired BUSY aggregate PPIF sample exists');
    my $source = slurp(sample_path());
    like($source, qr/\(ahb-requester amba_requester_busy_insert\b/, 'sample selects the BUSY-inserting requester');
    like($source, qr/\(busy-before-beat 2\)/, 'sample inserts BUSY before beat index two');
    like($source, qr/\(parked-transfer busy\)/, 'sample selects subordinate BUSY parking');

    my $report = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_path());
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'adapter returns the AHB interconnect report schema');
    is(
        $report->{source_object}{id},
        'fsmgen-ahb-interconnect-requester-busy-insert-byte-lane-hburst-seq-busy-park',
        'paired source object id is selected',
    );
    is(
        $report->{source_object}{intent_name},
        'ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park',
        'paired source intent name is selected',
    );
    is($report->{composition}{child_instance_count}, 3, 'paired aggregate child count is preserved');
    is($report->{composition}{response_mux}{data_phase_owner}{mode}, 'one_hot_accepted_subordinate', 'paired fabric retains the accepted subordinate as data-phase response owner');
    is($report->{composition}{response_mux}{data_phase_owner}{same_edge_replacement}, 'completion_with_accepted_active_address_replaces_owner', 'paired fabric reports completion-edge owner replacement');

    is_deeply(
        [sort @{$report->{generated_artifacts}{ial0}{files}}],
        [qw(ahb_interconnect.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_tb.fsm amba_requester_busy_insert.fsm)],
        'paired source exposes requester, subordinate, fabric, and top IAL0 artifacts',
    );
    is_deeply(
        [sort map { $_->{name} } @{$report->{generated_artifacts}{ial1}{items}}],
        [qw(ahb_interconnect.isf ahb_lite_subordinate_byte_lane_hburst_seq.isf amba_requester_busy_insert.isf)],
        'paired source exposes the exact generated IAL1 artifacts',
    );
    is($report->{generated_artifacts}{hdl_entry}{module}, 'ahb_tb', 'paired source selects the aggregate HDL module');

    my $requester = $report->{children}[0];
    is($requester->{object_name}, 'amba_requester_busy_insert', 'requester child selects the BUSY-inserting object');
    is($requester->{transfer}{busy}, "2'b01", 'requester child report keeps HTRANS BUSY');
    is($requester->{transfer}{busy_before_beat}, 2, 'requester child report keeps the insertion index');
    is($requester->{busy_insertion}{generated_behavior}, 1, 'requester child exposes generated BUSY behavior');
    is($requester->{busy_insertion}{htrans_busy_encoding}, "2'b01", 'requester child exposes the BUSY encoding');
    is($requester->{busy_insertion}{before_beat}, 2, 'requester child exposes the BUSY insertion index');
    is($requester->{busy_insertion}{beats}, 'single', 'requester child bounds insertion to one presentation');
    my %requester_residue = map { $_->{id} => $_->{detail} } @{$requester->{unsupported_residue}};
    like($requester_residue{ahb_requester_busy_insert_support}, qr/one exact qualified requester HTRANS BUSY event/, 'requester child keeps bounded BUSY-insertion residue');

    my $subordinate = $report->{children}[2];
    is($subordinate->{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'subordinate child keeps HBURST SEQ progression');
    is_deeply($subordinate->{transfer}{seq_policy}{parks_on}, [qw(busy)], 'subordinate child parks BUSY');
    is_deeply($subordinate->{transfer}{seq_policy}{clears_on}, [qw(reset idle error new_nonseq final_beat)], 'subordinate child does not clear SEQ state on BUSY');
    is_deeply(
        $report->{composition}{seq_policy_propagation}{subordinates}[0]{seq_policy}{parks_on},
        [qw(busy)],
        'aggregate propagation exposes subordinate BUSY parking',
    );
    ok(!exists $report->{composition}{busy_flow}, 'paired proof does not duplicate child facts in a top busy-flow summary');
};

subtest 'base-requester aggregate reports remain structurally unchanged' => sub {
    my $base = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', base_path());
    ok(!exists $base->{children}[0]{busy_insertion}, 'base requester child has no optional busy_insertion block');
    ok(!exists $base->{children}[0]{transfer}{busy}, 'base requester child has no BUSY encoding');
    ok(!exists $base->{children}[0]{transfer}{busy_before_beat}, 'base requester child has no BUSY insertion index');
};

subtest 'CLI and review surfaces agree on the paired BUSY aggregate' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_path());
    ok($check->{success}, 'strict check succeeds for the paired BUSY source');
    is($check->{result}{module_name}, 'ahb_tb', 'check JSON reports the aggregate module');
    is($check->{result}{composition_child_count}, 3, 'check JSON reports the aggregate child count');
    is($check->{support_accounting}{entry_id}, support_id(), 'check JSON matches support accounting');
    is($check->{support_accounting}{coverage}, coverage_key(), 'check JSON reports paired BUSY coverage');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_path());
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', 'semantic JSON reports the aggregate module');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON reports the composition top');
    is($semantic->{support_accounting}{entry_id}, support_id(), 'semantic JSON matches support accounting');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'paired BUSY source emits HDL and review artifacts')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    for my $artifact (qw(
        amba_requester_busy_insert.isf
        ahb_lite_subordinate_byte_lane_hburst_seq.isf
        ahb_interconnect.isf
        amba_requester_busy_insert.fsm
        ahb_lite_subordinate_byte_lane_hburst_seq.fsm
        ahb_interconnect.fsm
        ahb_tb.fsm
    )) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains generated $artifact");
    }
    my $subordinate_isf = slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq.isf'));
    my $interconnect_fsm = slurp(File::Spec->catfile($outdir, 'ahb_interconnect.fsm'));
    like($subordinate_isf, qr/\(rule ahb_phase_capture \(& \(! ahb_phase_pending_q\)/, 'paired subordinate captures each ready active transfer once');
    like($subordinate_isf, qr/\(rule ahb_phase_hold ahb_phase_pending_q/, 'paired subordinate holds one accepted next phase');
    unlike($subordinate_isf, qr/\(transaction ahb_seq_idle_clear\b/, 'paired subordinate uses no competing idle-clear transaction');
    like($interconnect_fsm, qr/\(ahb_data_owner_0_q 1 \(reset 0\)\)/, 'paired fabric declares one reset-clean data-phase owner bit');
    like($interconnect_fsm, qr/\(<ahb_data_owner_0_q\s+\(= \(HREADY> HREADYOUT_REGS\)\).*?\(<HRESP_REGS/s, 'paired fabric muxes ready and response from the retained subordinate owner');
    like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, 'generated HDL contains the aggregate module');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--verify-hdl', sample_path()],
    );
    ok($verify_ok, 'public verify-hdl accepts the paired BUSY source')
        or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
};

subtest 'generated HDL pairs one requester BUSY presentation with subordinate parking' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public paired BUSY source emits generated HDL')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_paired_busy_composition_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the paired BUSY composition harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_paired_busy_composition_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL paired BUSY composition passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS transfers=5 beats=4 busy=1 qualified_busy=1 storage=44332211/,
        'runtime observes one qualified paired BUSY event, parking, and four byte writes',
    );
};

done_testing();

sub sample_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif');
}

sub base_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif');
}

sub testbench_path {
    return File::Spec->catfile($FindBin::Bin, 'data', 'ahb_paired_busy_composition_tb.svt');
}

sub support_id {
    return 'intent.ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park';
}

sub coverage_key {
    return 'ial2_ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli';
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
        };
    return $decoded || {};
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
