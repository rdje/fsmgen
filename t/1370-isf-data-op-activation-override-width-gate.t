#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'mismatched data-op width parameter activation overrides fail closed' => sub {
    assert_lower_rejected(
        <<'ISF',
(actor shift_left_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input bit_in)
    (output done)
    (output reg_out (width 8)))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (W 16)))
    (complete done))
  (transaction worker
    (params
      (W 8))
    (shift_left reg_out bit_in (width W))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides static-width parameter 'W' on child 'worker'; activation-site parameter override-specialized data-op widths remain deferred/,
        'spawn override that changes a shift_left width parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor shift_right_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input bit_in)
    (output done)
    (output reg_out (width 8)))
  (transaction parent
    (on start)
    (do worker
      (params
        (W 16)))
    (complete done))
  (transaction worker
    (params
      (W 8))
    (shift_right reg_out bit_in (width W))
    (complete done)))
ISF
        qr/Transaction 'parent': do instance 'parent_worker_do_0' overrides static-width parameter 'W' on child 'worker'; activation-site parameter override-specialized data-op widths remain deferred/,
        'generated do override that changes a shift_right width parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor assemble_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (input hi (width 4))
    (input lo (width 4))
    (output done)
    (output word (width 8)))
  (transaction worker
    (params
      (HI 4)
      (LO 4))
    (assemble hi lo as word (widths HI LO))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (HI 6)))))
ISF
        qr/Rule 'launch': trigger instance 'launch_worker_trigger_0' overrides static-width parameter 'HI' on child 'worker'; activation-site parameter override-specialized data-op widths remain deferred/,
        'rule trigger override that changes an assemble width parameter is rejected',
    );

    assert_lower_rejected(
        <<'ISF',
(actor extract_override_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input word (width 8))
    (output done)
    (output hi (width 4))
    (output lo (width 4)))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (HI 6)
        (LO 4)))
    (complete done))
  (transaction worker
    (params
      (HI 4)
      (LO 4))
    (extract word as hi lo (widths HI LO))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides static-width parameter 'HI' on child 'worker'; activation-site parameter override-specialized data-op widths remain deferred/,
        'spawn override that changes an extract width parameter is rejected',
    );
};

subtest 'same-value data-op width parameter overrides remain accepted' => sub {
    my $shift_left_lowered = lower_source(<<'ISF');
(actor shift_left_same_value
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input bit_in)
    (output done)
    (output reg_out (width 8)))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (W 8)))
    (complete done))
  (transaction worker
    (params
      (W 8))
    (shift_left reg_out bit_in (width W))
    (complete done)))
ISF
    ok($shift_left_lowered,
        'same-value spawn override for a shift_left width parameter remains accepted');

    my $shift_right_lowered = lower_source(<<'ISF');
(actor shift_right_same_value
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input bit_in)
    (output done)
    (output reg_out (width 8)))
  (transaction parent
    (on start)
    (do worker
      (params
        (W 8)))
    (complete done))
  (transaction worker
    (params
      (W 8))
    (shift_right reg_out bit_in (width W))
    (complete done)))
ISF
    ok($shift_right_lowered,
        'same-value generated do override for a shift_right width parameter remains accepted');

    my $assemble_lowered = lower_source(<<'ISF');
(actor assemble_same_value
  (clock clk)
  (reset rst_n)
  (interface
    (input fire)
    (input hi (width 4))
    (input lo (width 4))
    (output done)
    (output word (width 8)))
  (transaction worker
    (params
      (HI 4)
      (LO 4))
    (assemble hi lo as word (widths HI LO))
    (complete done))
  (rule launch fire
    (trigger worker
      (params
        (HI 4)))))
ISF
    ok($assemble_lowered,
        'same-value rule trigger override for an assemble width parameter remains accepted');

    my $extract_lowered = lower_source(<<'ISF');
(actor extract_same_value
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input word (width 8))
    (output done)
    (output hi (width 4))
    (output lo (width 4)))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (HI 4)
        (LO 4)))
    (complete done))
  (transaction worker
    (params
      (HI 4)
      (LO 4))
    (extract word as hi lo (widths HI LO))
    (complete done)))
ISF
    ok($extract_lowered,
        'same-value spawn override for an extract width parameter remains accepted');
};

subtest 'unrelated overrides and existing timing/contract precedence are preserved' => sub {
    my $unrelated_lowered = lower_source(<<'ISF');
(actor unrelated_param_override
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input bit_in)
    (output done)
    (output reg_out (width 8)))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (UNRELATED 16)))
    (complete done))
  (transaction worker
    (params
      (W 8)
      (UNRELATED 4))
    (shift_left reg_out bit_in (width W))
    (complete done)))
ISF
    ok($unrelated_lowered,
        'override on a parameter not used by any data-op width remains accepted even with mismatched value');

    assert_lower_rejected(
        <<'ISF',
(actor timing_precedence_probe
  (clock clk)
  (reset rst_n)
  (interface
    (input start)
    (input bit_in)
    (output done)
    (output reg_out (width 8)))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (DELAY 2)))
    (complete done))
  (transaction worker
    (params
      (DELAY 4))
    (wait DELAY)
    (shift_left reg_out bit_in (width DELAY))
    (complete done)))
ISF
        qr/Transaction 'parent': spawn instance 'w0' overrides static-timing parameter 'DELAY' on child 'worker'; activation-site parameter override-specialized static timing remains deferred/,
        'static-timing diagnostic takes precedence when the same parameter backs both a wait count and a data-op width',
    );
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source(
        $source,
        'data-op-activation-override-width-gate.isf',
    );
}

sub lower_source {
    my ($source) = @_;
    my $actor = parse_source($source);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_lower_rejected {
    my ($source, $pattern, $label) = @_;
    my $ok = eval {
        lower_source($source);
        1;
    };

    ok(!$ok, $label);
    like($@, $pattern, "$label diagnostic");
}
