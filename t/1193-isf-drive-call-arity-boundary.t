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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'drive-call-arity-boundary.isf');
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

subtest 'named drive calls bind exactly one actual per declared parameter' => sub {
    my $result = lower_source(<<'ISF');
(actor drive_call_arity
  (clock clk)
  (interface
    (input start)
    (output out)
    (output done))
  (drive (set_out val)
    (out val))
  (transaction main
    (on start)
    (drive set_out 1)
    (complete done)))
ISF

    my $fsm = $result->{files}{'drive_call_arity.fsm'};
    like($fsm, qr/\(= \(set_out_start 1\)\)/, 'drive call asserts the named drive start');
    like($fsm, qr/\(= \(set_out_val 1\)\)/, 'drive call binds the declared parameter actual');
};

subtest 'malformed named drive call arity fails closed' => sub {
    assert_lower_rejected(<<'ISF', 'missing parameterized-drive actual', qr/\ATransaction 'main': drive 'set_out' missing actual for 'val'/);
(actor missing_drive_actual
  (clock clk)
  (interface
    (input start)
    (output out)
    (output done))
  (drive (set_out val)
    (out val))
  (transaction main
    (on start)
    (drive set_out)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra parameterized-drive actual', qr/\ATransaction 'main': drive 'set_out' expects 1 actual\(s\), got 2/);
(actor extra_drive_actual
  (clock clk)
  (interface
    (input start)
    (output out)
    (output done))
  (drive (set_out val)
    (out val))
  (transaction main
    (on start)
    (drive set_out 1 0)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra simple-drive actual', qr/\ATransaction 'main': drive 'pulse' expects 0 actual\(s\), got 1/);
(actor extra_simple_drive_actual
  (clock clk)
  (interface
    (input start)
    (output out)
    (output done))
  (drive pulse
    (out 1))
  (transaction main
    (on start)
    (drive pulse 1)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested extra drive actual', qr/\ATransaction 'main': drive 'set_out' expects 1 actual\(s\), got 2/);
(actor nested_extra_drive_actual
  (clock clk)
  (interface
    (input start)
    (output out)
    (output done))
  (drive (set_out val)
    (out val))
  (transaction main
    (on start)
    (repeat 2
      (drive set_out 1 0))
    (complete done)))
ISF
};

done_testing();
