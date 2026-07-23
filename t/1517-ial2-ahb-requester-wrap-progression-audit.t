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

subtest 'generated and direct requester paths increment then wrap safely' => sub {
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'amba_requester.fsm'};
    my $direct_fsm = slurp(direct_seed_path());

    like(
        $isf,
        qr/\(when wrap_mode_q\s+\(set addr_q \(\+ addr_q addr_step_q\)\)\s+\(when \(== addr_q wrap_high_q\) \(set addr_q wrap_base_q\)\)\)/s,
        'generated IAL1 increments first and wraps the incremented boundary value',
    );
    unlike(
        $isf,
        qr/\(when \(== \(\+ addr_q addr_step_q\) wrap_high_q\).*?\(when \(! \(== \(\+ addr_q addr_step_q\) wrap_high_q\)\)/s,
        'generated IAL1 no longer mutates then re-tests the old boundary predicate',
    );
    like(
        $fsm,
        qr/\(ahb_request_set_\d+\s+\(<- \(addr_q \(\+ addr_q addr_step_q\)\)\).*?\(ahb_request_when_\d+\s+\(\?\(== addr_q wrap_high_q\).*?\(ahb_request_set_\d+\s+\(<- \(addr_q wrap_base_q\)\)/s,
        'generated IAL0 schedules increment before the boundary comparison and wrap',
    );
    my @direct_repairs = $direct_fsm =~ /\(<wrap_mode_q\s+\(<- \(addr_q \(\+ addr_q addr_step_q\)\)\)\s+\(<\(== addr_q wrap_high_q\)\s+\(<- \(addr_q wrap_base_q\)\)/sg;
    is(scalar(@direct_repairs), 2, 'both direct requester successful-response paths use increment-then-wrap');
    unlike(
        $direct_fsm,
        qr/<\(== \(\+ addr_q addr_step_q\) wrap_high_q\).*?<\!\(== \(\+ addr_q addr_step_q\) wrap_high_q\)/s,
        'direct requester seed no longer carries the mutation/retest pair',
    );
};

subtest 'generated HDL wraps fixed bursts to base for representative sizes' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public AHB requester emits repaired generated HDL')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_requester_wrap_progression_audit_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the requester fixed-wrap harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_requester_wrap_progression_audit_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL fixed-wrap commands complete with exact addresses')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    return unless $run_ok;

    my $stdout = join('', @{$run_stdout || []});
    like(
        $stdout,
        qr/PASS_WRAP4_BYTE addresses=00000003,00000000,00000001,00000002/,
        'WRAP4 byte progression reaches base before incrementing',
    );
    like(
        $stdout,
        qr/PASS_WRAP4_HALFWORD addresses=00000006,00000000,00000002,00000004/,
        'WRAP4 halfword progression uses a two-byte step and wraps to base',
    );
    like(
        $stdout,
        qr/PASS_WRAP4_WORD addresses=0000000c,00000000,00000004,00000008/,
        'WRAP4 word progression uses a four-byte step and wraps to base',
    );
    like(
        $stdout,
        qr/PASS_WRAP8_BYTE addresses=00000007,00000000,00000001,00000002,00000003,00000004,00000005,00000006/,
        'WRAP8 byte progression wraps once and completes eight beats',
    );
    like(
        $stdout,
        qr/PASS_WRAP16_BYTE addresses=0000000f,00000000,00000001,00000002,00000003,00000004,00000005,00000006,00000007,00000008,00000009,0000000a,0000000b,0000000c,0000000d,0000000e/,
        'WRAP16 byte progression wraps once and completes sixteen beats',
    );
};

done_testing();

sub sample_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ppif');
}

sub direct_seed_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'amba_requester.fsm');
}

sub testbench_path {
    return File::Spec->catfile($FindBin::Bin, 'data', 'ahb_requester_wrap_progression_audit_tb.svt');
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
