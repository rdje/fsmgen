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

subtest 'direct same-transaction scalar parameters are valid static contract windows' => sub {
    my $nested_source = <<'ISF';
(actor direct_contract_transaction_parameter_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (params
      (ACK_WINDOW 5)
      (FLAT_WINDOW 3'd2)
      (DERIVED_WINDOW ACK_WINDOW))
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (contract flat_seen (eventually ack within FLAT_WINDOW))
    (complete done)))
ISF

    my $actor = parse_source($nested_source);
    my ($main_shell) = grep { ($_->{name} // '') eq 'main' } @{$actor->{transactions}};
    is(
        $main_shell->{clauses}[0][1][1],
        5,
        'actor shell preserves the authored direct transaction parameter default',
    );

    my $fsm = lower_source($nested_source)->{files}{'direct_contract_transaction_parameter_window.fsm'};
    like(
        $fsm,
        qr/\(== main_contract_1_age 4\)/,
        'nested direct transaction parameter window resolves before monitor expiry emission',
    );
    like(
        $fsm,
        qr/\(== main_contract_2_age 1\)/,
        'flat direct transaction parameter window resolves before monitor expiry emission',
    );
    unlike(
        $fsm,
        qr/\(\+params\b/,
        'direct transaction parameters are local lowering inputs, not actor-level .fsm parameters',
    );

    assert_fsm_reaches_hdl($fsm, 'direct_contract_transaction_parameter_window');
};

subtest 'direct transaction parameter windows use transaction-local scope' => sub {
    my $source = <<'ISF';
(actor direct_contract_transaction_parameter_shadow
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
  (transaction main
    (params
      (ACK_WINDOW 4)
      (ACTOR_WINDOW 5))
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (contract actor_shadow (eventually ack (within ACTOR_WINDOW)))
    (complete done)))
ISF

    my $fsm = lower_source($source)->{files}{'direct_contract_transaction_parameter_shadow.fsm'};
    like(
        $fsm,
        qr/\(== main_contract_1_age 3\)/,
        'direct transaction parameter shadows an actor constant of the same name',
    );
    like(
        $fsm,
        qr/\(== main_contract_2_age 4\)/,
        'direct transaction parameter shadows an actor parameter of the same name',
    );
};

subtest 'direct transaction parameter contract-window diagnostics fail closed' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor unused_direct_transaction_parameter
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (output done))
  (transaction main
    (params
      (ACK_WINDOW 4))
    (on start)
    (complete done)))
ISF
        qr/Transaction 'main': params are supported only on generated child transactions, same-transaction temporal contract windows, same-transaction data-operation width evidence, same-transaction transaction-port width evidence, same-transaction repeat counts, same-transaction wait counts, same-transaction latency bounds, or same-transaction top-level await-local watchdog limits/,
        'unused direct transaction parameters remain outside the supported surface',
    );

    assert_lower_rejected(
        <<'ISF',
(actor zero_direct_transaction_parameter_contract_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (params
      (ACK_WINDOW 0))
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' within transaction parameter 'ACK_WINDOW' must resolve to a positive cycle count in transaction body/,
        'zero-valued direct transaction parameters keep the positive contract-window policy',
    );

    assert_lower_rejected(
        <<'ISF',
(actor aggregate_direct_transaction_parameter_contract_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (params
      (ACK_WINDOW (2 3)))
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' within transaction parameter 'ACK_WINDOW' must resolve to a positive cycle count in transaction body/,
        'aggregate/list direct transaction parameters remain deferred as contract windows',
    );

    assert_lower_rejected(
        <<'ISF',
(actor expression_direct_transaction_parameter_contract_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction main
    (params
      (ACK_WINDOW 4))
    (on start)
    (contract ack_seen (eventually ack (within (+ ACK_WINDOW 1))))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' supports only '\(eventually signal within cycles\)' or '\(eventually signal \(within cycles\)\)'/,
        'direct transaction parameters inside contract-window expressions remain deferred',
    );

    assert_lower_rejected(
        <<'ISF',
(actor other_direct_transaction_parameter_contract_window
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input ack)
    (output done))
  (transaction helper
    (params
      (ACK_WINDOW 4))
    (on start)
    (contract helper_ack (eventually ack (within ACK_WINDOW)))
    (complete done))
  (transaction main
    (on start)
    (contract ack_seen (eventually ack (within ACK_WINDOW)))
    (complete done)))
ISF
        qr/Transaction 'main': contract 'ack_seen' within token 'ACK_WINDOW' is not a same-transaction scalar parameter, declared actor constant, actor scalar parameter, or qualified package scalar constant in transaction body/,
        'direct transaction parameters from other transactions are not visible',
    );

};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'contract-direct-transaction-param-window.isf',
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
    ok($fsm_module, 'scheduled .fsm with a direct transaction-parameter contract window parses');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'direct contract window reaches SystemVerilog');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
