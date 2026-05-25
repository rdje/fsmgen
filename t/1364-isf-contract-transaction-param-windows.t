#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

subtest 'same-transaction scalar parameters are valid static contract windows' => sub {
    my $nested_source = <<'ISF';
(actor contract_transaction_parameter_window
  (clock clk)
  (reset rst_n)
  (params
    (ACTOR_WINDOW 8))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (ACK_WINDOW 4)
      (FLAT_WINDOW 3'd2)
      (DERIVED_WINDOW ACK_WINDOW))
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF

    my $actor = parse_source($nested_source);
    my ($child_shell) = grep { ($_->{name} // '') eq 'child' } @{$actor->{transactions}};
    is(
        $child_shell->{clauses}[0][1][1],
        4,
        'actor shell preserves the authored transaction parameter default',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'child.fsm'};
    like(
        $fsm,
        qr/\(== child_contract_0_age 3\)/,
        'nested child transaction parameter window resolves before monitor expiry emission',
    );
    like(
        $fsm,
        qr/\(\+params[\s\S]*\(ACK_WINDOW 4\)[\s\S]*\(FLAT_WINDOW 3'd2\)[\s\S]*\(DERIVED_WINDOW ACK_WINDOW\)/,
        'authored transaction parameters remain visible in scheduled .fsm',
    );

    assert_fsm_reaches_hdl($fsm, 'child');

    my $flat_source = <<'ISF';
(actor contract_flat_transaction_parameter_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (ACK_WINDOW 4)
      (FLAT_WINDOW 3'd2))
    (contract ack_seen (eventually ack within FLAT_WINDOW))
    (complete done)))
ISF

    my $flat_lowered = lower_source($flat_source);
    like(
        $flat_lowered->{files}{'child.fsm'},
        qr/\(== child_contract_0_age 1\)/,
        'flat child transaction parameter window resolves before monitor expiry emission',
    );
};

subtest 'transaction parameter windows use transaction-local scope' => sub {
    my $source = <<'ISF';
(actor contract_transaction_parameter_shadow
  (clock clk)
  (reset rst_n)
  (constants
    (ACK_WINDOW 9))
  (params
    (ACTOR_WINDOW 7))
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (ACK_WINDOW 4)
      (ACTOR_WINDOW 5))
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (contract actor_shadow (eventually ack (within ACTOR_WINDOW)))
    (complete done)))
ISF

    my $child_fsm = lower_source($source)->{files}{'child.fsm'};
    like(
        $child_fsm,
        qr/\(== child_contract_0_age 3\)/,
        'transaction parameter shadows an actor constant of the same name',
    );
    like(
        $child_fsm,
        qr/\(== child_contract_1_age 4\)/,
        'transaction parameter shadows an actor parameter of the same name',
    );
};

subtest 'transaction parameter contract-window diagnostics fail closed' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor zero_transaction_parameter_contract_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (ACK_WINDOW 0))
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF
        qr/Transaction 'child': contract 'ack_seen' within transaction parameter 'ACK_WINDOW' must resolve to a positive cycle count in transaction body/,
        'zero-valued transaction parameters keep the positive contract-window policy',
    );

    assert_lower_rejected(
        <<'ISF',
(actor aggregate_transaction_parameter_contract_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (ACK_WINDOW (2 3)))
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF
        qr/Transaction 'child': contract 'ack_seen' within transaction parameter 'ACK_WINDOW' must resolve to a positive cycle count in transaction body/,
        'aggregate/list transaction parameters remain deferred as contract windows',
    );

    assert_lower_rejected(
        <<'ISF',
(actor expression_transaction_parameter_contract_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (spawn child as c0)
    (complete done))
  (transaction child
    (params
      (ACK_WINDOW 4))
    (contract ack_seen (eventually ack (within (+ ACK_WINDOW 1))))
    (complete done)))
ISF
        qr/Transaction 'child': contract 'ack_seen' supports only '\(eventually signal within cycles\)' or '\(eventually signal \(within cycles\)\)'/,
        'transaction parameters inside contract-window expressions remain deferred',
    );

    assert_lower_rejected(
        <<'ISF',
(actor other_transaction_parameter_contract_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction parent
    (on start)
    (spawn helper as h0)
    (spawn child as c0)
    (complete done))
  (transaction helper
    (params
      (ACK_WINDOW 4))
    (complete done))
  (transaction child
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF
        qr/Transaction 'child': contract 'ack_seen' within token 'ACK_WINDOW' is not a same-transaction scalar parameter, declared actor constant, actor scalar parameter, or qualified package scalar constant in transaction body/,
        'transaction parameters from other transactions are not visible',
    );
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'contract-transaction-param-window.isf',
    );
}

sub lower_source {
    my ($source) = @_;
    my $actor = parse_source($source);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $pattern, $label) = @_;
    my $ok = eval {
        lower_source($source);
        1;
    };

    ok(!$ok, $label);
    like($@, $pattern, "$label diagnostic");
}

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name) = @_;
    my $dir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($dir, "$module_name.fsm");
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'scheduled .fsm with a transaction-parameter contract window parses');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'contract window reaches SystemVerilog');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
