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
    assert_lower_rejected(<<'ISF', 'removed assign keyword', qr/\ATransaction 'main': unsupported '\(assign \.\.\.\)' clause in transaction body/);
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
    assert_lower_rejected(<<'ISF', 'unsupported when-body keyword', qr/\ATransaction 'main': unsupported '\(assign \.\.\.\)' clause in when body/);
(actor unknown_when
  (clock clk)
  (interface (input start) (input cond) (output done))
  (transaction main
    (on start)
    (when cond
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
    assert_lower_rejected(<<'ISF', 'contract remains specific', qr/\ATransaction 'main': temporal '\(contract \.\.\.\)' clauses are parsed but not implemented by ISF lowering/);
(actor deferred_contract
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (contract eventually_done)
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
