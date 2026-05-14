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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'update-clause-boundary.isf');
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

subtest 'valid scalar and expression updates lower as single flopped assignments' => sub {
    my $result = lower_source(<<'ISF');
(actor update_boundary
  (clock clk)
  (interface
    (input start)
    (input payload)
    (output out)
    (output done))
  (transaction main
    (on start)
    (update out payload)
    (update out (+ payload 1))
    (complete done)))
ISF

    my $fsm = $result->{files}{'update_boundary.fsm'};
    like($fsm, qr/\(<- \(out> payload\)\)/, 'scalar update lowers as a flopped assignment');
    like($fsm, qr/\(<- \(out> \(\+ payload 1\)\)\)/, 'expression update is formatted as a single RHS expression');
};

subtest 'malformed update clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing update rhs', qr/\ATransaction 'main': update requires '\(update var expr\)' in transaction body/);
(actor missing_update_rhs
  (clock clk)
  (interface (input start) (output out) (output done))
  (transaction main
    (on start)
    (update out)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested update target', qr/\ATransaction 'main': update requires '\(update var expr\)' in transaction body/);
(actor nested_update_target
  (clock clk)
  (interface (input start) (output out) (output done))
  (transaction main
    (on start)
    (update (out) 1)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra update operand', qr/\ATransaction 'main': update requires '\(update var expr\)' in transaction body/);
(actor extra_update_operand
  (clock clk)
  (interface (input start) (output out) (output done))
  (transaction main
    (on start)
    (update out payload extra)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'malformed nested update', qr/\ATransaction 'main': update requires '\(update var expr\)' in when body/);
(actor malformed_nested_update
  (clock clk)
  (interface (input start) (input cond) (output out) (output done))
  (transaction main
    (on start)
    (when cond
      (update out))
    (complete done)))
ISF
};

done_testing();
