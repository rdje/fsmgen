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
    my ($source, $fsm_name) = @_;
    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'repeat-inline.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

subtest 'literal repeat counts use the minimum counter width that can hold the count' => sub {
    my $source = <<'ISF';
(actor repeat_literal
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat 8
      (drive tick))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'repeat_literal.fsm');

    like($fsm, qr/\(main_cnt 4\)/, 'repeat 8 counter can represent values through 8');
    like($fsm, qr/\(<= \(main_cnt 8\)\)/, 'repeat init still loads the literal count');
};

subtest 'named repeat counts reuse the sampled source width' => sub {
    my $source = <<'ISF';
(actor repeat_named
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input repeat_len (width 12))
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start
      (sample repeat_len as beats))
    (repeat beats
      (drive tick))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'repeat_named.fsm');

    like($fsm, qr/\(main_cnt 12\)/, 'sampled named repeat count drives counter width');
    like($fsm, qr/\(<= \(main_cnt beats\)\)/, 'repeat init loads the sampled count alias');
};

subtest 'actor constant repeat counts use the resolved constant width' => sub {
    my $source = <<'ISF';
(actor repeat_constant
  (clock clk)
  (reset (rst_n async active_low))
  (constants
    (COUNT 9))
  (interface
    (input start)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat COUNT
      (drive tick))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'repeat_constant.fsm');

    like($fsm, qr/\(main_cnt 4\)/, 'actor constant repeat count drives the resolved counter width');
    like($fsm, qr/\(<= \(main_cnt COUNT\)\)/, 'repeat init preserves the authored constant token');
};

subtest 'switch-nested repeats declare the shared transaction counter width' => sub {
    my $source = <<'ISF';
(actor repeat_nested
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input mode)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (switch mode
      (0 (repeat 7
           (drive tick)))
      (1 (repeat 8
           (drive tick))))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'repeat_nested.fsm');

    like($fsm, qr/\(main_cnt 4\)/, 'nested repeat declarations use the widest branch count');
    like($fsm, qr/main_repeat_init_/, 'nested repeat init states are emitted');
    like($fsm, qr/main_repeat_check_/, 'nested repeat check states are emitted');
};

done_testing();
