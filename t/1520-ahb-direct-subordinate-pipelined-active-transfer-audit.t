#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

subtest 'direct seed samples active address phases only in idle' => sub {
    my $seed = slurp(seed_path());
    my ($access) = $seed =~ /\n  \(access\n(.*?)\n  \)\n\n  \(unsupported/s;
    my ($error_complete) = $seed =~ /\n  \(error_complete\n(.*?)\n  \)\n\)/s;

    ok(defined($access), 'direct seed exposes the access state for audit');
    ok(defined($error_complete), 'direct seed exposes the final ERROR state for audit');
    like(
        $seed,
        qr/\(idle.*?\(<HSEL\s+\(<HREADY\s+\(\?HTRANS.*?\(=2'b10\s+\(<= \(addr_q HADDR\)\).*?\(-> access\).*?\(=2'b11\s+\(<= \(wait_ctr wait_cycles\)\)\s+\(-> unsupported\)/s,
        'direct seed accepts NONSEQ or unsupported SEQ only in idle',
    );
    unlike(
        $access // '',
        qr/\b(?:HSEL|HADDR|HTRANS)\b/,
        'successful completion state has no next-address capture path',
    );
    unlike(
        $error_complete // '',
        qr/\b(?:HSEL|HADDR|HTRANS)\b/,
        'final ERROR completion state has no next-address capture path',
    );
};

subtest 'direct generated HDL drops active phases accepted on completion edges' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'ahb_lite_subordinate.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, seed_path()],
    );
    ok($generate_ok, 'direct AHB subordinate seed emits HDL for the no-behavior audit')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my $emitted = slurp($hdl);
    like(
        $emitted,
        qr/assign access_reg_data_q_hwdata_en = access_en & .*write_q;/,
        'current write completion reads the register-input mux output',
    );
    like(
        $emitted,
        qr/always_comb begin\s+write_q = write_q_q;.*?if \(write_q_hwrite_en\) begin\s+write_q = HWRITE;/s,
        'write_q capture is a combinational register-input mux before its storage flop',
    );

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_direct_subordinate_pipelined_active_transfer_audit_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the direct-seed active-transfer audit harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile(
        $objdir,
        'Vahb_direct_subordinate_pipelined_active_transfer_audit_tb',
    );
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'direct-seed active-transfer audit completes deterministically')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    return unless $run_ok;

    my $stdout = join('', @{$run_stdout || []});
    like(
        $stdout,
        qr/DIRECT_SUCCESS_ACTIVE_DROP bus_accepts=2 internal_captures=1 internal_completions=1 ready_low_cycles=\d+ response_error_cycles=0 second_write=0 sampled_write=1 storage=11111111/,
        'success completion accepts but does not capture or complete the distinct next active phase',
    );
    like(
        $stdout,
        qr/DIRECT_ERROR_ACTIVE_DROP bus_accepts=2 internal_captures=1 internal_completions=1 response_error_cycles=2 storage=00000000/,
        'final ERROR accepts but does not capture or complete the next active phase',
    );
};

done_testing();

sub seed_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'ahb_lite_subordinate.fsm');
}

sub testbench_path {
    return File::Spec->catfile(
        $FindBin::Bin,
        'data',
        'ahb_direct_subordinate_pipelined_active_transfer_audit_tb.svt',
    );
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
