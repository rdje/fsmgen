#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'unsupported-transaction-clause.isf');
    my $ok = eval {
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected by lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'unsupported top-level transaction clauses fail closed' => sub {
    assert_lower_rejected(<<'ISF', 'removed assign keyword', qr/\ATransaction 'main': removed '\(assign \.\.\.\)' clause is unsupported in transaction body; use '\(update var expr\)' for transaction-local flopped updates, '\(drive \.\.\.\)' for protocol\/output drives, rule '\(port expr\)' actions for rule-driven assignments, or '\(complete port\)' for completion pulses/);
(actor removed_assign
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (assign done 1)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'future unknown keyword', qr/\ATransaction 'main': unsupported '\(future_op \.\.\.\)' clause in transaction body/);
(actor unknown_top
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (future_op done)
    (complete done)))
ISF
};

subtest 'unsupported nested transaction clauses fail closed by context' => sub {
    assert_lower_rejected(<<'ISF', 'unsupported when-body keyword', qr/\ATransaction 'main': removed '\(assign \.\.\.\)' clause is unsupported in when body; use '\(update var expr\)' for transaction-local flopped updates, '\(drive \.\.\.\)' for protocol\/output drives, rule '\(port expr\)' actions for rule-driven assignments, or '\(complete port\)' for completion pulses/);
(actor unknown_when
  (clock clk)
  (interface (input start) (input cond) (output done))
  (transaction main
    (on start)
    (when cond
      (assign done 1))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'removed assign in switch branch', qr/\ATransaction 'main': removed '\(assign \.\.\.\)' clause is unsupported in switch branch; use '\(update var expr\)' for transaction-local flopped updates, '\(drive \.\.\.\)' for protocol\/output drives, rule '\(port expr\)' actions for rule-driven assignments, or '\(complete port\)' for completion pulses/);
(actor assign_switch
  (clock clk)
  (interface (input start) (input mode) (output done))
  (transaction main
    (on start)
    (switch mode
      (0 (assign done 1)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'removed assign in repeat body', qr/\ATransaction 'main': removed '\(assign \.\.\.\)' clause is unsupported in repeat body; use '\(update var expr\)' for transaction-local flopped updates, '\(drive \.\.\.\)' for protocol\/output drives, rule '\(port expr\)' actions for rule-driven assignments, or '\(complete port\)' for completion pulses/);
(actor assign_repeat
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat 2
      (assign done 1))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unsupported switch-branch completion', qr/\ATransaction 'main': unsupported '\(complete \.\.\.\)' clause in switch branch/);
(actor unknown_switch
  (clock clk)
  (interface (input start) (input mode) (output done))
  (transaction main
    (on start)
    (switch mode
      (0 (complete done)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unsupported repeat-body branch', qr/\ATransaction 'main': unsupported '\(when \.\.\.\)' clause in repeat body/);
(actor unknown_repeat
  (clock clk)
  (interface (input start) (input cond) (output done))
  (drive pulse (done 1))
  (transaction main
    (on start)
    (repeat 2
      (when cond
        (drive pulse)))
    (complete done)))
ISF
};

subtest 'deferred transaction clauses keep their specific diagnostics' => sub {
    assert_lower_rejected(<<'ISF', 'unsupported contract remains specific', qr/\ATransaction 'main': contract 'eventually_done' supports only '\(eventually signal \(within cycles\)\)'/);
(actor deferred_contract
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (contract eventually_done (always done))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unsupported stage remains specific', qr/\ATransaction 'main': stage 'pipe' has unsupported subclause 'compute'/);
(actor deferred_stage
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (stage pipe (input start) (output done) (compute done))
    (complete done)))
ISF
};

done_testing();
