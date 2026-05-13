#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'contract-fail-closed.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_contract_rejected {
    my ($source, $label) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };

    ok(!$ok, "$label is rejected during lowering");
    like(
        $@,
        qr/Transaction 'main': temporal '\(contract \.\.\.\)' clauses are parsed but not implemented by ISF lowering/,
        "$label diagnostic is targeted",
    );
}

subtest 'top-level contract clause fails closed' => sub {
    assert_contract_rejected(<<'ISF', 'top-level contract');
(actor contract_top
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (contract eventually_done)
    (complete done)))
ISF
};

subtest 'contract clauses inside transaction bodies fail closed' => sub {
    assert_contract_rejected(<<'ISF', 'when-body contract');
(actor contract_when
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (when ready
      (contract ready_obligation))
    (complete done)))
ISF

    assert_contract_rejected(<<'ISF', 'switch-branch contract');
(actor contract_switch
  (clock clk)
  (interface
    (input start)
    (input opcode)
    (output done))
  (transaction main
    (on start)
    (switch opcode
      (0 (contract opcode_obligation)))
    (complete done)))
ISF

    assert_contract_rejected(<<'ISF', 'repeat-body contract');
(actor contract_repeat
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (repeat 2
      (contract loop_obligation))
    (complete done)))
ISF
};

done_testing();
