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
    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'when-body-ops.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /(  \(\Q$state_name\E\b.*?\n  \))/s);
    return $block // '';
}

subtest 'when body lowers data operations and repeat bodies' => sub {
    my $source = <<'ISF';
(actor when_body_ops
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cond)
    (input bit_in)
    (input count_in (width 4))
    (input payload (width 8))
    (output done)
    (output flag))
  (drive pulse
    (flag 1))
  (transaction main
    (on start
      (sample count_in as beats)
      (sample payload as word))
    (when cond
      (update word payload)
      (shift_right word 0)
      (repeat beats
        (drive pulse)
        (shift_left word bit_in)))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'when_body_ops.fsm');

    my $when = state_block($fsm, 'main_when_1');
    like($when, qr/\(=1 \(-> main_update_2\)\)/, 'true path enters the first when body state');
    like($when, qr/\(=0 \(-> main_done_8\)\)/,   'false path skips data and repeat body states');

    like($fsm, qr/\(main_update_2\n\s+\(<- \(word payload\)\)/, 'update inside when lowers');
    like(
        $fsm,
        qr/\(<- \(word \(\| \(>> word 1\) \(<< 0 7\)\)\)\)/,
        'known-width shift_right inside when uses the sampled word width',
    );
    like($fsm, qr/\(main_repeat_init_4\n\s+\(<= \(main_cnt beats\)\)/, 'repeat inside when loads sampled count');
    like($fsm, qr/\(= \(pulse_start 1\)\)/, 'repeat body drive inside when asserts the named drive start');
    like($fsm, qr/\(<- \(word \(\| \(<< word 1\) bit_in\)\)\)/, 'repeat body shift_left inside when lowers');
    like($fsm, qr/\(main_cnt 4\)/, 'when-nested repeat registers the inferred counter width');

    my $repeat_check = state_block($fsm, 'main_repeat_check_7');
    like($repeat_check, qr/\(=0 \(-> main_done_8\)\)/, 'repeat completion exits to the post-when state');
};

done_testing();
