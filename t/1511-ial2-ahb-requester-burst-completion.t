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

subtest 'requester terminal decrement is mutually exclusive in generated IAL1' => sub {
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_path());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'amba_requester.fsm'};

    like(
        $isf,
        qr/\(when \(== beats_remaining_q 1\)\s+\(set beats_remaining_q 0\).*?\(when \(> beats_remaining_q 1\)\s+\(set beats_remaining_q \(- beats_remaining_q 1\)\)/s,
        'terminal zeroing is followed by a strictly-greater-than-one decrement guard',
    );
    unlike(
        $isf,
        qr/\(when \(! \(== beats_remaining_q 1\)\)\s+\(set beats_remaining_q \(- beats_remaining_q 1\)\)/s,
        'the decrement path cannot become true after terminal zeroing',
    );
    like(
        $fsm,
        qr/\(\?\(> beats_remaining_q 1\)/,
        'scheduled FSM carries the strict non-terminal guard',
    );
};

subtest 'generated HDL completes SINGLE and exact four-beat INCR4 requests' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, sample_path()],
    );
    ok($generate_ok, 'public AHB requester emits generated HDL')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my $testbench = File::Spec->catfile(
        $FindBin::Bin,
        'data',
        'ahb_requester_burst_completion_tb.svt',
    );
    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_requester_burst_completion_tb',
            '--Mdir', $objdir, $hdl, $testbench,
        ],
    );
    ok($compile_ok, 'Verilator builds the requester burst-completion harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_requester_burst_completion_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL requester burst completion passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS single_beats=1 incr4_beats=4/,
        'single and INCR4 requests complete with exact beat cardinality',
    );
};

done_testing();

sub sample_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ppif');
}
