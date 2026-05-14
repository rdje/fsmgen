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
    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'sample-before-data-op.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /(  \(\Q$state_name\E\b.*?\n  \))/s);
    return $block // '';
}

subtest 'top-level sample materializes before data operation' => sub {
    my $source = <<'ISF';
(actor top_sample_data
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input din (width 8))
    (output done)
    (output out (width 8)))
  (transaction main
    (on start)
    (sample din as hold)
    (update out hold)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'top_sample_data.fsm');

    like(state_block($fsm, 'main_sample_1'), qr/\(<= \(hold din\)\)/, 'sample state captures hold');
    like(state_block($fsm, 'main_sample_1'), qr/\(-> main_update_2\)/, 'sample state precedes update');
    like(state_block($fsm, 'main_update_2'), qr/\(<- \(out> hold\)\)/, 'update consumes sampled name after capture state');
};

subtest 'when-local sample materializes before data operation' => sub {
    my $source = <<'ISF';
(actor when_sample_data
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cond)
    (input din (width 8))
    (output done)
    (output out (width 8)))
  (transaction main
    (on start)
    (when cond
      (sample din as hold)
      (update out hold))
    (complete done)))
ISF

    my $fsm  = lower_source($source, 'when_sample_data.fsm');
    my $when = state_block($fsm, 'main_when_1');

    like($when, qr/\(=1 \(-> main_sample_2\)\)/, 'when true path enters sample before update');
    like($when, qr/\(=0 \(-> main_done_4\)\)/,   'when false path skips sample and update');
    like(state_block($fsm, 'main_sample_2'), qr/\(-> main_update_3\)/, 'when sample state precedes update');
    like(state_block($fsm, 'main_update_3'), qr/\(-> main_done_4\)/,   'when update exits after body');
};

subtest 'switch-local sample materializes before data operation' => sub {
    my $source = <<'ISF';
(actor switch_sample_data
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input mode)
    (input din (width 8))
    (output done)
    (output out (width 8)))
  (transaction main
    (on start)
    (switch mode
      (1 (sample din as hold)
         (update out hold)))
    (complete done)))
ISF

    my $fsm    = lower_source($source, 'switch_sample_data.fsm');
    my $switch = state_block($fsm, 'main_switch_3');

    like($switch, qr/\(=1 \(-> main_sample_1\)\)/, 'switch branch enters sample before update');
    like(state_block($fsm, 'main_sample_1'), qr/\(-> main_update_2\)/, 'switch sample state precedes update');
    like(state_block($fsm, 'main_update_2'), qr/\(-> main_done_4\)/,   'switch update exits after switch');
};

subtest 'repeat-local sample materializes before data operation' => sub {
    my $source = <<'ISF';
(actor repeat_sample_data
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input din (width 8))
    (output done)
    (output out (width 8)))
  (transaction main
    (on start)
    (repeat 2
      (sample din as hold)
      (update out hold))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'repeat_sample_data.fsm');

    like(state_block($fsm, 'main_repeat_init_1'), qr/\(-> main_sample_2\)/, 'repeat enters sample before update');
    like(state_block($fsm, 'main_sample_2'),      qr/\(-> main_update_3\)/, 'repeat sample state precedes update');
    like(state_block($fsm, 'main_update_3'),      qr/\(-> main_repeat_check_4\)/, 'repeat update enters repeat check');
};

done_testing();
