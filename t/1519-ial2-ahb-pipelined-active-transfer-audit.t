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

subtest 'generated phase ownership requires a non-active release boundary' => sub {
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm'};

    like(
        $isf,
        qr/\(rule ahb_access_admit \(& \(! ahb_access_active_q\) HSEL HREADY \(\| \(== HTRANS 2'b10\) \(== HTRANS 2'b11\)\)\)\s+\(set ahb_access_active_q 1\)\s+\(set HREADYOUT 0\)\)/s,
        'IAL1 admits an active phase only while ownership is clear',
    );
    like(
        $isf,
        qr/\(rule ahb_access_release \(& ahb_access_active_q \(\| \(! HSEL\) \(== HTRANS 2'b00\) \(== HTRANS 2'b01\)\)\)\s+\(set ahb_access_active_q 0\)\)/s,
        'IAL1 releases ownership only at unselected, IDLE, or BUSY boundaries',
    );
    like(
        $isf,
        qr/\(when \(& \(! ahb_access_active_q\) HSEL HREADY \(\| \(== HTRANS 2'b10\) \(== HTRANS 2'b11\)\)\)\s+\(sample HADDR as addr_q\).*?\(sample HTRANS as trans_q\)/s,
        'IAL1 transaction sampling shares the ownership-clear admission predicate',
    );
    like(
        $fsm,
        qr/\(-ahb_access_admit <.*?\(<- \(ahb_access_active_q 1\)\).*?\(-ahb_access_release <.*?\(<- \(ahb_access_active_q 0\)\)/s,
        'IAL0 preserves the separate admit and boundary-release mutations',
    );
};

subtest 'generated HDL observes a dropped boundary-free SEQ phase' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'ahb_lite_subordinate.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public AHB subordinate emits generated HDL for the audit')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_pipelined_active_transfer_audit_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the boundary-free active-transfer audit harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_pipelined_active_transfer_audit_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL boundary-free audit completes deterministically')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    return unless $run_ok;

    my $stdout = join('', @{$run_stdout || []});
    like(
        $stdout,
        qr/OBSERVED_ACTIVE_PIPE bus_accepts=2 internal_admits=1 internal_completions=1 first_accept=\d+ second_accept=\d+ completion=\d+ ready_low_cycles=\d+ response_errors=0 captured_addr=00000000 captured_trans=10 storage=00000011/,
        'runtime proves the distinct SEQ phase is bus-accepted but neither captured nor completed',
    );
    unlike(
        $stdout,
        qr/storage=00002211/,
        'runtime does not apply the second byte-lane write',
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
