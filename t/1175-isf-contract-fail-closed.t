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
    my ($source, $label, $expected) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };

    ok(!$ok, "$label is rejected during lowering");
    like(
        $@,
        $expected,
        "$label diagnostic is targeted",
    );
}

subtest 'unsupported top-level contract shapes fail closed' => sub {
    assert_contract_rejected(<<'ISF', 'top-level historical contract', qr/\ATransaction 'main': contract requires '\(contract name \(eventually signal \(within cycles\)\)\)' in transaction body/);
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
    my $nested_contract = qr/\ATransaction 'main': temporal '\(contract \.\.\.\)' clauses are supported only as top-level transaction clauses/;

    assert_contract_rejected(<<'ISF', 'when-body contract', $nested_contract);
(actor contract_when
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (when ready
      (contract ready_obligation (eventually ready (within 2))))
    (complete done)))
ISF

    assert_contract_rejected(<<'ISF', 'switch-branch contract', $nested_contract);
(actor contract_switch
  (clock clk)
  (interface
    (input start)
    (input opcode)
    (output done))
  (transaction main
    (on start)
    (switch opcode
      (0 (contract opcode_obligation (eventually opcode (within 2)))))
    (complete done)))
ISF

    assert_contract_rejected(<<'ISF', 'repeat-body contract', $nested_contract);
(actor contract_repeat
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (repeat 2
      (contract loop_obligation (eventually start (within 2))))
    (complete done)))
ISF
};

done_testing();
