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

subtest 'generated IAL1 and IAL0 preserve the sequential WRAP mutation shape' => sub {
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'amba_requester.fsm'};

    like(
        $isf,
        qr/\(when wrap_mode_q\s+\(when \(== \(\+ addr_q addr_step_q\) wrap_high_q\) \(set addr_q wrap_base_q\)\)\s+\(when \(! \(== \(\+ addr_q addr_step_q\) wrap_high_q\)\) \(set addr_q \(\+ addr_q addr_step_q\)\)\)\)/s,
        'generated IAL1 carries sequential wrap-to-base then negated increment clauses',
    );
    like(
        $fsm,
        qr/\(ahb_request_when_\d+\s+\(\?\(== \(\+ addr_q addr_step_q\) wrap_high_q\).*?\(ahb_request_set_\d+\s+\(<- \(addr_q wrap_base_q\)\).*?\(ahb_request_when_\d+\s+\(\?\(! \(== \(\+ addr_q addr_step_q\) wrap_high_q\)\).*?\(ahb_request_set_\d+\s+\(<- \(addr_q \(\+ addr_q addr_step_q\)\)\)/s,
        'generated IAL0 schedules the same sequential mutation and retest',
    );
};

subtest 'generated HDL reproduces the WRAP4 boundary skip' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public AHB requester emits generated HDL for the audit')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_requester_wrap_progression_audit_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the requester WRAP4 audit harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_requester_wrap_progression_audit_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL WRAP4 audit completes four transfers cleanly')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    return unless $run_ok;

    my $stdout = join('', @{$run_stdout || []});
    like(
        $stdout,
        qr/OBSERVED_WRAP4 addresses=00000003,00000001,00000002,00000003/,
        'runtime reproduces wrap-to-base being overwritten by base-plus-step',
    );
    unlike(
        $stdout,
        qr/OBSERVED_WRAP4 addresses=00000003,00000000,00000001,00000002/,
        'runtime does not produce the required WRAP4 boundary sequence',
    );
};

done_testing();

sub sample_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ppif');
}

sub testbench_path {
    return File::Spec->catfile($FindBin::Bin, 'data', 'ahb_requester_wrap_progression_audit_tb.svt');
}
