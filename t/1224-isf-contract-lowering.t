#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
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
        qr/\ATransaction 'main': contract 'ack_seen' supports only '\(eventually signal \(within cycles\)\)'/,
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
