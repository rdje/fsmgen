#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;

subtest 'generated phase bank retains every ready active address phase' => sub {
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm'};

    like(
        $isf,
        qr/\(var ahb_phase_pending_q \(width 1\) \(reset 0\)\).*?\(var next_addr_q \(width 32\) \(reset 0\)\).*?\(var next_trans_q \(width 2\) \(reset 0\)\).*?\(var next_burst_q \(width 3\) \(reset 0\)\).*?\(var next_wait_n \(width 4\) \(reset 0\)\)/s,
        'IAL1 declares one accepted next address/control bank',
    );
    like(
        $isf,
        qr/\(priority ahb_phase_capture over ahb_error_retire\).*?\(priority ahb_phase_capture over ahb_phase_hold\).*?\(priority ahb_phase_hold over ahb_error_retire\).*?\(priority ahb_error_retire over ahb_lite_byte_lane_hburst_seq_access\).*?\(priority ahb_phase_hold over ahb_lite_byte_lane_hburst_seq_access\)/s,
        'IAL1 gives capture and hold output ownership priority over the transaction tail',
    );
    like(
        $isf,
        qr/\(rule ahb_phase_capture \(& \(! ahb_phase_pending_q\) HSEL HREADY \(\| \(== HTRANS 2'b10\) \(== HTRANS 2'b11\)\)\)\s+\(set ahb_phase_pending_q 1\)\s+\(set next_addr_q HADDR\)\s+\(set next_write_q HWRITE\)\s+\(set next_size_q HSIZE\)\s+\(set next_trans_q HTRANS\)\s+\(set next_burst_q HBURST\)\s+\(set next_wait_n wait_cycles\)\s+\(set HREADYOUT 0\)\s+\(set HRESP 1'b0\)\s+\(set HRDATA 0\)\)/s,
        'IAL1 captures one complete ready active address/control phase and stalls its data phase',
    );
    like(
        $isf,
        qr/\(rule ahb_phase_hold ahb_phase_pending_q\s+\(set HREADYOUT 0\)\s+\(set HRESP 1'b0\)\s+\(set HRDATA 0\)\)/s,
        'IAL1 holds the accepted phase not-ready until transaction relaunch',
    );
    like(
        $isf,
        qr/\(rule ahb_error_retire \(& HREADYOUT \(== HRESP 1'b1\)\)\s+\(set HREADYOUT 1\)\s+\(set HRESP 1'b0\)\s+\(set HRDATA 0\)\)/s,
        'IAL1 retires final ERROR to zero-wait IDLE OKAY while the transaction tail drains',
    );
    like(
        $isf,
        qr/\(when ahb_phase_pending_q\s+\(sample next_addr_q as addr_q\)\s+\(sample next_write_q as write_q\)\s+\(sample next_size_q as size_q\)\s+\(sample next_trans_q as trans_q\)\s+\(sample next_burst_q as burst_q\)\s+\(sample next_wait_n as wait_n\)\)\s+\(set ahb_phase_pending_q 0\)/s,
        'IAL1 relaunches the banked phase without a second bus acceptance',
    );
    unlike($isf, qr/\(sample HWDATA\b/, 'IAL1 does not address-phase capture data-phase HWDATA');
    like(
        $fsm,
        qr/\(-ahb_phase_capture <.*?\(<- \(ahb_phase_pending_q 1\)\).*?\(<- \(next_addr_q HADDR\)\).*?\(-ahb_phase_hold <ahb_phase_pending_q/s,
        'IAL0 preserves capture storage and the pending-phase output hold',
    );

    my $pipeline = $result->{report}{phase_pipeline};
    is($pipeline->{mode}, 'one_accepted_next_address_control', 'report names the selected one-next-phase mode');
    is($pipeline->{accepted_next_capacity}, 1, 'report bounds accepted next capacity to one');
    is_deeply(
        $pipeline->{captured_address_control},
        [qw(HADDR HTRANS HBURST HWRITE HSIZE wait_cycles)],
        'report lists the atomic captured address/control values',
    );
    is($pipeline->{write_data}{signal}, 'HWDATA', 'report names live write data');
    is($pipeline->{write_data}{policy}, 'live_data_phase_held_while_stalled', 'report keeps HWDATA in the data phase');
    is($pipeline->{overflow}, 'stall_before_another_acceptance', 'report states the depth-one backpressure policy');
};

subtest 'generated HDL retains success and ERROR completion-edge phases exactly once' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'ahb_lite_subordinate.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public AHB subordinate emits generated HDL for the repair proof')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_pipelined_active_transfer_audit_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the boundary-free active-transfer repair harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_pipelined_active_transfer_audit_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL boundary-free repair proof completes deterministically')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    return unless $run_ok;

    my $stdout = join('', @{$run_stdout || []});
    like(
        $stdout,
        qr/REPAIRED_ACTIVE_PIPE bus_accepts=2 internal_captures=2 internal_completions=2 first_accept=\d+ second_accept=\d+ first_completion=\d+ second_completion=\d+ ready_low_cycles=\d+ response_errors=0 captured_addr=00000001 captured_trans=11 pending=0 storage=00002211/,
        'runtime proves the distinct SEQ phase is accepted, captured, completed, and applied exactly once',
    );
    like(
        $stdout,
        qr/REPAIRED_ERROR_CONTINUE bus_accepts=2 internal_captures=2 internal_completions=2 response_error_cycles=2 pending=0 storage=000000aa/,
        'runtime captures an active NONSEQ on final ERROR and completes it independently',
    );
    like(
        $stdout,
        qr/REPAIRED_ERROR_CANCEL bus_accepts=1 internal_captures=1 internal_completions=1 response_error_cycles=2 pending=0 storage=00000000/,
        'runtime leaves final ERROR plus IDLE canceled with no manufactured phase',
    );
};

done_testing();

sub sample_path {
    return File::Spec->catfile(
        $FindBin::Bin,
        '..',
        'ppif',
        'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif',
    );
}

sub testbench_path {
    return File::Spec->catfile(
        $FindBin::Bin,
        'data',
        'ahb_pipelined_active_transfer_audit_tb.svt',
    );
}
