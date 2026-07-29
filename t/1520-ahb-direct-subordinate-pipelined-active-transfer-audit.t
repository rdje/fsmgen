#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

subtest 'direct seed uses exclusive outputs and Q-named completion-edge phase dispatch' => sub {
    my $seed = slurp(seed_path());
    my ($idle) = $seed =~ /\n  \(idle\n(.*?)\n  \)\n\n  \(access/s;
    my ($access) = $seed =~ /\n  \(access\n(.*?)\n  \)\n\n  \(unsupported/s;
    my ($unsupported) = $seed =~ /\n  \(unsupported\n(.*?)\n  \)\n\n  \(error_complete/s;
    my ($error_complete) = $seed =~ /\n  \(error_complete\n(.*?)\n  \)\n\)/s;

    ok(defined($idle), 'direct seed exposes the idle state for audit');
    ok(defined($access), 'direct seed exposes the access state for audit');
    ok(defined($unsupported), 'direct seed exposes the unsupported state for audit');
    ok(defined($error_complete), 'direct seed exposes the final ERROR state for audit');
    like(
        $idle // '',
        qr/\(= \(HREADYOUT> 1\)\).*?\(= \(HRESP> 0\)\).*?\(= \(HRDATA> 32'h00000000\)\)/s,
        'idle keeps explicit ready, OKAY, and zero-data ownership',
    );
    unlike(
        $access // '',
        qr/\(= \((?:HREADYOUT|HRESP)> 0\)\)|\(= \(HRDATA> 32'h00000000\)\)/,
        'access removes exactly its redundant ready, response, and data zero owners',
    );
    like(
        $access // '',
        qr/\(= \(HRESP> 1\)\).*?\(= \(HRESP> 1\)\).*?\(= \(HREADYOUT> 1\)\).*?\(= \(HRDATA> reg_data_q\)\)/s,
        'access retains conditional ERROR, completion-ready, and read-data owners',
    );
    like(
        $unsupported // '',
        qr/\(= \(HREADYOUT> 0\)\).*?\(= \(HRDATA> 32'h00000000\)\).*?\(= \(HRESP> 1\)\)/s,
        'unsupported retains exclusive not-ready and zero-data owners plus conditional ERROR',
    );
    unlike(
        $unsupported // '',
        qr/\(= \(HRESP> 0\)\)/,
        'unsupported removes only its redundant response-zero owner',
    );
    like(
        $error_complete // '',
        qr/\(= \(HREADYOUT> 1\)\).*?\(= \(HRESP> 1\)\).*?\(= \(HRDATA> 32'h00000000\)\)/s,
        'final ERROR keeps explicit ready, ERROR, and zero-data ownership',
    );
    like(
        $seed,
        qr/\(idle.*?\(<HSEL\s+\(<HREADY\s+\(\?HTRANS.*?\(=2'b10\s+\(<- \(addr_q HADDR\)\).*?\(-> access\).*?\(=2'b11\s+\(<- \(wait_ctr wait_cycles\)\)\s+\(-> unsupported\)/s,
        'direct seed admits NONSEQ or unsupported SEQ with Q-named loads in idle',
    );
    like(
        $access // '',
        completion_dispatch_re(),
        'successful completion atomically captures and dispatches the next active phase',
    );
    like(
        $error_complete // '',
        completion_dispatch_re(),
        'final ERROR atomically captures and dispatches the next active phase',
    );
    unlike(
        $seed,
        qr/\(<=\s+\((?:addr_q|write_q|size_q|wait_ctr|reg_data_q)\b/,
        'persistent direct state has no D-input-named assignment',
    );
    unlike(
        $seed,
        qr/\((?:relaunch|next_addr_q|next_write_q|next_size_q|next_wait_ctr|next_seq_q)\b/,
        'selected repair adds no pending bank or relaunch state',
    );
};

subtest 'direct generated HDL retains active phases accepted on completion edges' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'ahb_lite_subordinate.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, seed_path()],
    );
    ok($generate_ok, 'direct AHB subordinate seed emits HDL for the assertion-clean arbitration audit')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my $emitted = slurp($hdl);
    like(
        $emitted,
        qr/always_comb begin\s+HRDATA = 32'b0+;/,
        'emitted HRDATA mux retains its implicit zero baseline',
    );
    like(
        $emitted,
        qr/always_comb begin\s+HREADYOUT = 1'b0;/,
        'emitted HREADYOUT mux retains its implicit zero baseline',
    );
    like(
        $emitted,
        qr/always_comb begin\s+HRESP = 1'b0;/,
        'emitted HRESP mux retains its implicit OKAY baseline',
    );
    unlike(
        $emitted,
        qr/assign access_(?:hreadyout_0|hresp_0|hrdata__32_h0)_en\b|assign unsupported_hresp_0_en\b/,
        'emitted selector set has no removed access-zero or unsupported-response-zero owner',
    );
    like(
        $emitted,
        qr/assign unsupported_hreadyout_0_en\b/,
        'emitted selector set retains the unsupported not-ready owner',
    );
    like(
        $emitted,
        qr/assign unsupported_hrdata__32_h0_en\b/,
        'emitted selector set retains the unsupported zero-data owner',
    );
    for my $output (qw(HRDATA HREADYOUT HRESP)) {
        like(
            $emitted,
            qr/selector multi-value conflict: \Q$output\E/,
            "emitted HDL retains the generic $output multi-value assertion",
        );
    }
    like(
        $emitted,
        qr/assign access_reg_data_q_hwdata_en = access_en & .*write_q;/,
        'current write completion reads registered write_q',
    );
    like(
        $emitted,
        qr/Unified flop with mux for: write_q \(register_out assignment\).*?always_comb begin\s+write_q_next = write_q;.*?if \(write_q_hwrite_en\) begin\s+write_q_next = HWRITE;/s,
        'write_q capture writes a separate next-value mux while predicates read Q',
    );
    unlike(
        $emitted,
        qr/localparam\s+RELAUNCH|next_(?:addr|write|size|wait|seq)_q/,
        'emitted repair retains four states with no pending bank',
    );

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_direct_subordinate_pipelined_active_transfer_audit_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the direct-seed active-transfer audit harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;
    unlike(
        join('', @{$compile_stdout || []}, @{$compile_stderr || []}),
        qr/UNOPTFLAT/,
        'selected Q-named repair emits no combinational-loop warning',
    );

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
        qr/DIRECT_SUCCESS_ACTIVE_REPAIRED bus_accepts=2 internal_captures=2 internal_completions=2 ready_low_cycles=4 response_error_cycles=0 second_write=0 sampled_write=0 storage=11111111/,
        'success completion captures and completes the distinct next NONSEQ read exactly once',
    );
    like(
        $stdout,
        qr/DIRECT_ERROR_ACTIVE_REPAIRED bus_accepts=2 internal_captures=2 internal_completions=2 response_error_cycles=2 storage=aaaaaaaa/,
        'final ERROR captures and completes the next NONSEQ write after exactly two ERROR cycles',
    );
    like(
        $stdout,
        qr/DIRECT_SUCCESS_SEQ_REPAIRED bus_accepts=2 internal_captures=2 internal_completions=2 response_error_cycles=2 storage=55555555/,
        'success completion captures accepted SEQ for an independent two-cycle ERROR',
    );
    like(
        $stdout,
        qr/DIRECT_ERROR_IDLE_CANCEL bus_accepts=1 internal_captures=1 internal_completions=1 response_error_cycles=2 storage=00000000/,
        'final ERROR followed by IDLE cancels without a phantom continuation',
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

sub completion_dispatch_re {
    return qr/
        <HSEL
        .*?<HREADY
        .*?\?HTRANS
        .*?=2'b00\s+\(->\s+idle\)
        .*?=2'b01\s+\(->\s+idle\)
        .*?=2'b10
        .*?<-\s+\(addr_q\s+HADDR\)
        .*?<-\s+\(write_q\s+HWRITE\)
        .*?<-\s+\(size_q\s+HSIZE\)
        .*?<-\s+\(wait_ctr\s+wait_cycles\)
        .*?->\s+access
        .*?=2'b11
        .*?<-\s+\(wait_ctr\s+wait_cycles\)
        .*?->\s+unsupported
    /sx;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
