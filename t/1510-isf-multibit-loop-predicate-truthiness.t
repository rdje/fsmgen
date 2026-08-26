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
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Test::ProjectDataLocality;
use FSM::Test::VerilatorRuntime qw(
    darwin_verilator_runtime_qualified
    darwin_verilator_runtime_skip_reason
    run_generated_binary
    run_verilator_compile
);

plan skip_all => darwin_verilator_runtime_skip_reason()
    unless darwin_verilator_runtime_qualified();

use FSM::Adapter::IAL2::PPIF;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'known-width bare multi-bit loops lower through explicit nonzero predicates' => sub {
    my $actor = FSM::Adapter::ISF->new()->parse_source(direct_source(), 'multibit-loop.isf');
    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));
    my $fsm = $lowered->{files}{'isf_multibit_loop_predicate_truthiness.fsm'};

    is(
        scalar(() = $fsm =~ /\(\?\(!= while_count_q 3'd0\)/g),
        2,
        'while entry and retest both compare the three-bit condition with zero',
    );
    is(
        scalar(() = $fsm =~ /\(\?\(!= until_count_q 3'd0\)/g),
        1,
        'until check compares the three-bit condition with zero',
    );
    unlike(
        $fsm,
        qr/\?while_count_q\s+\(=1|\?until_count_q\s+\(=1/,
        'multi-bit loop decisions no longer select on an exact-one raw condition',
    );
    is_deeply(
        [map { $_->{condition} } @{$report->{transaction_loops}}],
        [qw(while_count_q until_count_q)],
        'schedule reporting preserves the authored loop conditions',
    );
};

subtest 'generated HDL treats every three-bit value with nonzero truthiness' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $source = File::Spec->catfile($tempdir, 'isf_multibit_loop_predicate_truthiness.isf');
    my $hdl = File::Spec->catfile($tempdir, 'isf_multibit_loop_predicate_truthiness.sv');
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    write_file($source, direct_source());

    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => [
            './bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir,
            '--output', $hdl, $source,
        ],
    );
    ok($generate_ok, 'direct ISF fixture emits generated HDL')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my $testbench = File::Spec->catfile(
        $FindBin::Bin,
        'data',
        'isf_multibit_loop_predicate_truthiness_tb.svt',
    );
    my $compile_result = run_verilator_compile([
        'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
        '-j', '1', '--top-module', 'isf_multibit_loop_predicate_truthiness_tb',
        '--Mdir', $objdir, $hdl, $testbench,
    ]);
    my $compile_ok = $compile_result->{ok};
    my $compile_stdout = [$compile_result->{stdout}];
    my $compile_stderr = [
        $compile_result->{stderr},
        $compile_result->{ok} ? () :
            "$compile_result->{status}: $compile_result->{diagnostic}\n",
    ];
    ok($compile_ok, 'Verilator builds the direct multi-bit loop harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Visf_multibit_loop_predicate_truthiness_tb');
    my $run_result = run_generated_binary([$binary]);
    my $run_ok = $run_result->{ok};
    my $run_stdout = [$run_result->{stdout}];
    my $run_stderr = [
        $run_result->{stderr},
        $run_result->{ok} ? () :
            "$run_result->{status}: $run_result->{diagnostic}\n",
    ];
    ok($run_ok, 'direct generated-HDL loop truthiness behavior passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS seeds=8/,
        'zero and every nonzero three-bit value pass while entry/retest and until checks',
    );
};

subtest 'the shipped requester advances beyond its former INCR4 loop-entry stall' => sub {
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(ahb_requester_path());
    my $fsm = $result->{generated_ial0}{files}{'amba_requester.fsm'};
    like(
        $fsm,
        qr/\(\?\(!= beats_remaining_q 5'd0\)/,
        'AHB requester loop uses five-bit nonzero truthiness',
    );

    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, ahb_requester_path()],
    );
    ok($generate_ok, 'public AHB requester emits generated HDL')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my $testbench = File::Spec->catfile(
        $FindBin::Bin,
        'data',
        'ahb_requester_loop_entry_truthiness_tb.svt',
    );
    my $compile_result = run_verilator_compile([
        'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
        '-j', '1', '--top-module', 'ahb_requester_loop_entry_truthiness_tb',
        '--Mdir', $objdir, $hdl, $testbench,
    ]);
    my $compile_ok = $compile_result->{ok};
    my $compile_stdout = [$compile_result->{stdout}];
    my $compile_stderr = [
        $compile_result->{stderr},
        $compile_result->{ok} ? () :
            "$compile_result->{status}: $compile_result->{diagnostic}\n",
    ];
    ok($compile_ok, 'Verilator builds the AHB loop-entry harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_requester_loop_entry_truthiness_tb');
    my $run_result = run_generated_binary([$binary]);
    my $run_ok = $run_result->{ok};
    my $run_stdout = [$run_result->{stdout}];
    my $run_stderr = [
        $run_result->{stderr},
        $run_result->{ok} ? () :
            "$run_result->{status}: $run_result->{diagnostic}\n",
    ];
    ok($run_ok, 'AHB requester advances from remaining count four to three')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS remaining=3 index=1/,
        'runtime proof crosses the exact former beats_remaining_q=4 stall',
    );
};

done_testing();

sub direct_source {
    return <<'ISF';
(actor isf_multibit_loop_predicate_truthiness
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input seed (width 3))
    (output done))
  (storage
    (var while_count_q (width 3) (reset 0))
    (var until_count_q (width 3) (reset 0))
    (var until_pass_q (width 2) (reset 0)))
  (transaction main
    (on start)
    (set while_count_q seed)
    (set until_count_q seed)
    (set until_pass_q 0)
    (while while_count_q
      (set while_count_q (- while_count_q 1)))
    (until until_count_q
      (when (!= until_pass_q 0)
        (set until_count_q 1))
      (set until_pass_q (+ until_pass_q 1)))
    (complete done)))
ISF
}

sub ahb_requester_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ppif');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
