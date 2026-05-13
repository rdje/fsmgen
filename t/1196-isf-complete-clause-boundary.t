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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'complete-clause-boundary.isf');
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

subtest 'valid complete clause lowers to delayed-pulse terminal assignment' => sub {
    my $result = lower_source(<<'ISF');
(actor complete_boundary
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (complete done)))
ISF

    my $fsm = $result->{files}{'complete_boundary.fsm'};
    like($fsm, qr/\(<1 \(done 1\)\)/, 'complete lowers to a delayed-pulse assignment');
    like($fsm, qr/\(-> main_idle_0\)/, 'complete terminal state returns to idle');
};

subtest 'malformed complete clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing complete target', qr/\ATransaction 'main': complete requires '\(complete port\)' in transaction body/);
(actor missing_complete_target
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete)))
ISF

    assert_lower_rejected(<<'ISF', 'nested complete target', qr/\ATransaction 'main': complete requires '\(complete port\)' in transaction body/);
(actor nested_complete_target
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete (done))))
ISF

    assert_lower_rejected(<<'ISF', 'extra complete operand', qr/\ATransaction 'main': complete requires '\(complete port\)' in transaction body/);
(actor extra_complete_operand
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (complete done now)))
ISF

    assert_lower_rejected(<<'ISF', 'malformed nested complete', qr/\ATransaction 'main': complete requires '\(complete port\)' in when body/);
(actor malformed_nested_complete
  (clock clk)
  (interface (input start) (input cond) (output done))
  (transaction main
    (on start)
    (when cond
      (complete))
    (complete done)))
ISF
};

done_testing();
