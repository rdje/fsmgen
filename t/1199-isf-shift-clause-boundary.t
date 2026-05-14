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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'shift-clause-boundary.isf');
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

subtest 'valid shift clauses lower to explicit shift expressions' => sub {
    my $result = lower_source(<<'ISF');
(actor shift_boundary
  (clock clk)
  (interface
    (input start)
    (input din)
    (output reg_out (width 8))
    (output done))
  (transaction main
    (on start)
    (shift_left reg_out din)
    (shift_right reg_out din (width 8))
    (complete done)))
ISF

    my $fsm = $result->{files}{'shift_boundary.fsm'};
    like($fsm, qr/\(<- \(reg_out> \(\| \(<< reg_out 1\) din\)\)\)/, 'shift_left lowers with scalar register and bit');
    like($fsm, qr/\(<- \(reg_out> \(\| \(>> reg_out 1\) \(<< din 7\)\)\)\)/, 'shift_right lowers with explicit width');
};

subtest 'malformed shift clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing shift_left bit', qr/\ATransaction 'main': shift_left requires '\(shift_left reg bit\)' in transaction body/);
(actor missing_shift_left_bit
  (clock clk)
  (interface (input start) (input din) (output reg_out) (output done))
  (transaction main
    (on start)
    (shift_left reg_out)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested shift_left register', qr/\ATransaction 'main': shift_left requires '\(shift_left reg bit\)' in transaction body/);
(actor nested_shift_left_register
  (clock clk)
  (interface (input start) (input din) (output reg_out) (output done))
  (transaction main
    (on start)
    (shift_left (reg_out) din)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra shift_left operand', qr/\ATransaction 'main': shift_left requires '\(shift_left reg bit\)' in transaction body/);
(actor extra_shift_left_operand
  (clock clk)
  (interface (input start) (input din) (output reg_out) (output done))
  (transaction main
    (on start)
    (shift_left reg_out din extra)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'missing shift_right bit', qr/\ATransaction 'main': shift_right requires '\(shift_right reg bit \[\(width N\)\]\)' in transaction body/);
(actor missing_shift_right_bit
  (clock clk)
  (interface (input start) (input din) (output reg_out) (output done))
  (transaction main
    (on start)
    (shift_right reg_out)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested shift_right bit', qr/\ATransaction 'main': shift_right requires '\(shift_right reg bit \[\(width N\)\]\)' in transaction body/);
(actor nested_shift_right_bit
  (clock clk)
  (interface (input start) (input din) (output reg_out) (output done))
  (transaction main
    (on start)
    (shift_right reg_out (din))
    (complete done)))
ISF
};

done_testing();
