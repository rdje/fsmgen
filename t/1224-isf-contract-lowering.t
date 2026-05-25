#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'contract-lowering.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub lower_rejected {
    my ($source) = @_;
    my $ok = eval {
        lower_source($source);
        1;
    };
    return ($ok, $@);
}

sub report_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'contract-lowering-report.isf');
    return JSON::PP->new->decode(FSM::Scheduler::ISF->new()->report($actor));
}

subtest 'top-level bounded eventual contract lowers to an arm state and monitor DT' => sub {
    my $lowered = lower_source(<<'ISF');
(actor contract_lowering
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within 3)))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'contract_lowering.fsm'};
    my $arm_state = <<'FSM';
  (main_contract_1
    (= (main_contract_1_arm 1))
    (-> main_done_2)
  )
FSM
    like($fsm, qr/\Q$arm_state\E/, 'contract arm state emits a one-cycle internal request');

    my $monitor = <<'FSM';
  (-main_contract_1_monitor
    (<- (main_contract_1_pending 1) <(& main_contract_1_arm (! main_contract_1_pending)))
    (<- (main_contract_1_pending 0) <(| (& main_contract_1_pending ack) (& main_contract_1_pending (! ack) (== main_contract_1_age 2))))
    (<- (main_contract_1_age 0) <(& main_contract_1_arm (! main_contract_1_pending)))
    (<- (main_contract_1_age (+ main_contract_1_age 1)) <(& main_contract_1_pending (! ack) (! (== main_contract_1_age 2))))
    (<- (main_contract_1_fail 1) <(| (& main_contract_1_arm main_contract_1_pending) (& main_contract_1_pending (! ack) (== main_contract_1_age 2))))
  )
FSM
    like($fsm, qr/\Q$monitor\E/, 'contract monitor owns pending, age, and sticky fail storage');

    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'contract_lowering.fsm');
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'scheduled .fsm with a contract monitor parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+contract_lowering\b/, 'contract lowering reaches SystemVerilog generation');
    like($hdl, qr/\bmain_contract_1_fail\b/, 'generated HDL carries the sticky fail signal');
};

subtest 'flat downstream bounded eventual contract is accepted by strict JSON check' => sub {
    my $source = <<'ISF';
(actor contract_flat_within
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack within 4))
    (complete done)))
ISF

    my $lowered = lower_source($source);
    like(
        $lowered->{files}{'contract_flat_within.fsm'},
        qr/\(<- \(main_contract_1_fail 1\) <\(\| \(& main_contract_1_arm main_contract_1_pending\) \(& main_contract_1_pending \(! ack\) \(== main_contract_1_age 3\)\)\)\)/,
        'flat within form lowers to the same bounded monitor semantics',
    );

    my $report = report_source($source);
    is($report->{temporal_contracts}[0]{within_cycles}, 4, 'flat within form preserves the cycle bound in schedule JSON');

    my $tempdir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($tempdir, 'contract_flat_within.isf');
    write_file($isf_path, $source);

    my ($success, undef, undef, $stdout, $stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $isf_path],
    );

    ok($success, 'strict JSON check accepts the flat downstream within form');
    is(join('', @{$stderr || []}), '', 'strict JSON check keeps stderr clean for the accepted flat within form');

    my $payload = JSON::PP->new->decode(join('', @{$stdout || []}));
    ok($payload->{success}, 'strict JSON payload reports success for the accepted flat within form');
};

subtest 'actor constants can name bounded eventual contract windows' => sub {
    my $nested_source = <<'ISF';
(actor contract_constant_window
  (clock clk)
  (reset rst_n)
  (constants
    (ACK_WINDOW 4))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF

    my $lowered = lower_source($nested_source);
    like(
        $lowered->{files}{'contract_constant_window.fsm'},
        qr/\(== main_contract_1_age 3\)/,
        'nested constant window resolves to the literal monitor expiry cycle',
    );

    my $report = report_source($nested_source);
    is($report->{temporal_contracts}[0]{within_cycles}, 4, 'nested constant window reports the resolved cycle bound');

    my $flat_source = <<'ISF';
(actor contract_flat_constant_window
  (clock clk)
  (reset rst_n)
  (constants
    (ACK_WINDOW 2))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack within ACK_WINDOW))
    (complete done)))
ISF

    my $flat_report = report_source($flat_source);
    is($flat_report->{temporal_contracts}[0]{within_cycles}, 2, 'flat constant window reports the resolved cycle bound');
};

subtest 'actor scalar parameters can name bounded eventual contract windows' => sub {
    my $nested_source = <<'ISF';
(actor contract_parameter_window
  (clock clk)
  (reset rst_n)
  (params
    (ACK_WINDOW 4)
    (FLAT_WINDOW 3'd2))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF

    my $lowered = lower_source($nested_source);
    like(
        $lowered->{files}{'contract_parameter_window.fsm'},
        qr/\(== main_contract_1_age 3\)/,
        'nested parameter window resolves to the literal monitor expiry cycle',
    );
    like(
        $lowered->{files}{'contract_parameter_window.fsm'},
        qr/\(\+params[\s\S]*\(ACK_WINDOW 4\)[\s\S]*\(FLAT_WINDOW 3'd2\)/,
        'authored actor parameters remain visible',
    );

    my $report = report_source($nested_source);
    is($report->{temporal_contracts}[0]{within_cycles}, 4, 'nested parameter window reports the resolved cycle bound');

    my $flat_source = <<'ISF';
(actor contract_flat_parameter_window
  (clock clk)
  (reset rst_n)
  (params
    (ACK_WINDOW 4)
    (FLAT_WINDOW 3'd2))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack within FLAT_WINDOW))
    (complete done)))
ISF

    my $flat_report = report_source($flat_source);
    is($flat_report->{temporal_contracts}[0]{within_cycles}, 2, 'flat parameter window reports the resolved cycle bound');
};

subtest 'unsupported symbolic bounded eventual contract windows fail closed' => sub {
    my ($ok_zero, $zero_diag) = lower_rejected(<<'ISF');
(actor contract_zero_constant_window
  (clock clk)
  (reset rst_n)
  (constants
    (ACK_WINDOW 0))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF

    ok(!$ok_zero, 'zero-valued actor constant window is rejected');
    like(
        $zero_diag,
        qr/\ATransaction 'main': contract 'ack_seen' within constant 'ACK_WINDOW' must resolve to a positive cycle count in transaction body/,
        'zero-valued actor constant diagnostic is targeted',
    );

    my ($ok_param_zero, $param_zero_diag) = lower_rejected(<<'ISF');
(actor contract_zero_parameter_window
  (clock clk)
  (reset rst_n)
  (params
    (ACK_WINDOW 0))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF

    ok(!$ok_param_zero, 'zero-valued actor parameter window is rejected');
    like(
        $param_zero_diag,
        qr/\ATransaction 'main': contract 'ack_seen' within parameter 'ACK_WINDOW' must resolve to a positive cycle count in transaction body/,
        'zero-valued actor parameter diagnostic is targeted',
    );

    my ($ok_param_nonscalar, $param_nonscalar_diag) = lower_rejected(<<'ISF');
(actor contract_nonscalar_parameter_window
  (clock clk)
  (reset rst_n)
  (params
    (ACK_WINDOW (2 3)))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF

    ok(!$ok_param_nonscalar, 'non-scalar actor parameter window is rejected');
    like(
        $param_nonscalar_diag,
        qr/\ATransaction 'main': contract 'ack_seen' within parameter 'ACK_WINDOW' must resolve to a positive cycle count in transaction body/,
        'non-scalar actor parameter diagnostic is targeted',
    );

    my ($ok_runtime, $runtime_diag) = lower_rejected(<<'ISF');
(actor contract_runtime_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (input delay)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within delay)))
    (complete done)))
ISF

    ok(!$ok_runtime, 'runtime interface window is rejected');
    like(
        $runtime_diag,
        qr/\ATransaction 'main': contract 'ack_seen' within token 'delay' is a runtime interface signal; temporal contract windows accept positive integer literals, same-transaction scalar parameters, actor constants, actor scalar parameters, or qualified package scalar constants only in transaction body/,
        'runtime interface diagnostic is targeted',
    );

    my ($ok_unknown, $unknown_diag) = lower_rejected(<<'ISF');
(actor contract_unknown_symbol_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF

    ok(!$ok_unknown, 'unknown symbolic window is rejected');
    like(
        $unknown_diag,
        qr/\ATransaction 'main': contract 'ack_seen' within token 'ACK_WINDOW' is not a same-transaction scalar parameter, declared actor constant, actor scalar parameter, or qualified package scalar constant in transaction body/,
        'unknown symbolic window diagnostic is targeted',
    );
};

subtest 'single-cycle bounded eventual contract omits unreachable age increment' => sub {
    my $lowered = lower_source(<<'ISF');
(actor contract_single_cycle
  (clock clk)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within 1)))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'contract_single_cycle.fsm'};
    like(
        $fsm,
        qr/\(<- \(main_contract_1_fail 1\) <\(\| \(& main_contract_1_arm main_contract_1_pending\) \(& main_contract_1_pending \(! ack\) \(== main_contract_1_age 0\)\)\)\)/,
        'within-1 contract expires on the first checked cycle',
    );
    unlike($fsm, qr/main_contract_1_age \(\+ main_contract_1_age 1\)/, 'within-1 contract has no age increment path');
};

subtest 'SystemVerilog generation projects sticky fail bit as verification assertion' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($tempdir, 'contract_assertion_projection.isf');
    my $sv_path = File::Spec->catfile($tempdir, 'contract_assertion_projection.sv');
    my $v_path = File::Spec->catfile($tempdir, 'contract_assertion_projection.v');
    write_file($isf_path, <<'ISF');
(actor contract_assertion_projection
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within 3)))
    (complete done)))
ISF

    my ($sv_success, $sv_error, $sv_full, $sv_stdout, $sv_stderr) = run(
        command => [
            './bin/fsmgen', '--quiet', '--language', 'systemverilog',
            '--output', $sv_path, $isf_path,
        ],
    );
    ok($sv_success, 'SystemVerilog generation succeeds for a bounded eventual contract');
    is(join('', @{$sv_stderr || []}), '', 'SystemVerilog generation keeps stderr clean');

    my $sv = read_file($sv_path);
    like(
        $sv,
        qr/`ifndef SYNTHESIS\s+always_ff @\(posedge clk\) begin\s+if \(rst_n\) begin\s+assert \(!main_contract_1_fail\) else \$error\("temporal contract failed: main\.ack_seen"\);\s+end\s+end\s+`endif/s,
        'SystemVerilog HDL checks the sticky fail bit under synthesis guard and reset release',
    );

    my ($v_success, $v_error, $v_full, $v_stdout, $v_stderr) = run(
        command => [
            './bin/fsmgen', '--quiet', '--language', 'verilog',
            '--output', $v_path, $isf_path,
        ],
    );
    ok($v_success, 'Verilog generation succeeds for the same bounded eventual contract');
    is(join('', @{$v_stderr || []}), '', 'Verilog generation keeps stderr clean');

    my $verilog = read_file($v_path);
    unlike($verilog, qr/temporal contract failed/, 'Verilog output omits temporal assertion message text');
    unlike($verilog, qr/\bassert\s*\(/, 'Verilog output omits SystemVerilog assertion syntax');
};

subtest 'contract monitor storage is reported without exposing arm as storage' => sub {
    my $report = report_source(<<'ISF');
(actor contract_storage_report
  (clock clk)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within 3)))
    (complete done)))
ISF

    my %storage = map { $_->{name} => $_ } @{$report->{inferred_storage} || []};
    ok(!exists $storage{main_contract_1_arm}, 'combinational arm request is not reported as storage');
    is($storage{main_contract_1_pending}{kind}, 'register', 'pending bit is reported as register storage');
    is($storage{main_contract_1_fail}{kind}, 'register', 'sticky fail bit is reported as register storage');
    is($storage{main_contract_1_age}{kind}, 'counter', 'age is reported as counter storage');
    is($storage{main_contract_1_age}{width}, 2, 'age counter width covers the final checked cycle');
};

subtest 'unsupported contract positions and endpoint bindings fail closed' => sub {
    my ($ok_nested, $nested_diag) = lower_rejected(<<'ISF');
(actor nested_contract
  (clock clk)
  (interface
    (input start)
    (input ready)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (when ready
      (contract ack_seen (eventually ack (within 2))))
    (complete done)))
ISF

    ok(!$ok_nested, 'nested contract is rejected');
    like(
        $nested_diag,
        qr/\ATransaction 'main': temporal '\(contract \.\.\.\)' clauses are supported only as top-level transaction clauses/,
        'nested contract diagnostic is targeted',
    );

    my ($ok_shape, $shape_diag) = lower_rejected(<<'ISF');
(actor bad_contract_shape
  (clock clk)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (always ack))
    (complete done)))
ISF

    ok(!$ok_shape, 'unsupported contract body is rejected');
    like(
        $shape_diag,
        qr/\ATransaction 'main': contract 'ack_seen' supports only '\(eventually signal within cycles\)' or '\(eventually signal \(within cycles\)\)'/,
        'unsupported body diagnostic is targeted',
    );

    my ($ok_signal, $signal_diag) = lower_rejected(<<'ISF');
(actor bad_contract_signal
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within 2)))
    (complete done)))
ISF

    ok(!$ok_signal, 'contract signal must be an actor interface signal');
    like(
        $signal_diag,
        qr/\ATransaction 'main': contract 'ack_seen' signal 'ack' is not an actor interface signal/,
        'interface signal diagnostic is targeted',
    );

    my ($ok_duplicate, $duplicate_diag) = lower_rejected(<<'ISF');
(actor duplicate_contract
  (clock clk)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within 2)))
    (contract ack_seen (eventually ack (within 2)))
    (complete done)))
ISF

    ok(!$ok_duplicate, 'duplicate contract name is rejected');
    like(
        $duplicate_diag,
        qr/\ATransaction 'main': duplicate contract 'ack_seen'/,
        'duplicate contract diagnostic is targeted',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path for read: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Cannot close $path: $!";
    return $content;
}
