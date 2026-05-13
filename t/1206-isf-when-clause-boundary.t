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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'when-clause-boundary.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'valid scalar and expression when clauses lower branch states' => sub {
    my $result = lower_source(<<'ISF');
(actor when_boundary
  (clock clk)
  (interface
    (input start)
    (input cond)
    (input counter (width 4))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (when cond
      (drive tick))
    (when (> counter 0)
      (drive tick))
    (complete done)))
ISF

    my $fsm = $result->{files}{'when_boundary.fsm'};
    like($fsm, qr/main_when_1/, 'scalar-condition when branch is emitted');
    like($fsm, qr/main_when_3/, 'expression-condition when branch is emitted');
    like($fsm, qr/\(= \(tick_start 1\)\)/, 'when body drive is emitted');
};

subtest 'malformed when clauses fail before branch expansion' => sub {
    assert_lower_rejected(<<'ISF', 'missing when condition', qr/\ATransaction 'main': when requires '\(when condition body\.\.\.\)' in transaction body/);
(actor when_missing_condition
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (when)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'missing when body', qr/\ATransaction 'main': when requires '\(when condition body\.\.\.\)' in transaction body/);
(actor when_missing_body
  (clock clk)
  (interface (input start) (input cond) (output done))
  (transaction main
    (on start)
    (when cond)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'scalar when body', qr/\ATransaction 'main': when body clauses must be list forms in transaction body/);
(actor when_scalar_body
  (clock clk)
  (interface (input start) (input cond) (output done))
  (transaction main
    (on start)
    (when cond complete)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested when scalar body', qr/\ATransaction 'main': when body clauses must be list forms in when body/);
(actor nested_when_scalar_body
  (clock clk)
  (interface (input start) (input cond) (output done))
  (transaction main
    (on start)
    (when cond
      (when cond complete))
    (complete done)))
ISF
};

done_testing();
