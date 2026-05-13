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
    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'when-inline.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /(  \(\Q$state_name\E\b.*?\n  \))/s);
    return $block // '';
}

subtest 'top-level when false path skips the whole body' => sub {
    my $source = <<'ISF';
(actor when_exit
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cond)
    (output done)
    (output flag))
  (drive first
    (flag 1))
  (drive second
    (flag 0))
  (drive after
    (flag 1))
  (transaction main
    (on start)
    (when cond
      (drive first)
      (drive second))
    (drive after)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'when_exit.fsm');

    my $when      = state_block($fsm, 'main_when_1');
    my $body_tail = state_block($fsm, 'main_drive_3');

    like($when, qr/\(=1 \(-> main_drive_2\)\)/, 'true path enters the when body');
    like($when, qr/\(=0 \(-> main_drive_4\)\)/, 'false path skips all when body states');
    like($body_tail, qr/\(-> main_drive_4\)/, 'body tail exits to the post-when state');
};

subtest 'switch-nested when false path exits the selected branch' => sub {
    my $source = <<'ISF';
(actor when_in_switch_exit
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input mode)
    (input cond)
    (output done)
    (output flag))
  (drive first
    (flag 1))
  (drive second
    (flag 0))
  (drive alt
    (flag mode))
  (drive after
    (flag 1))
  (transaction main
    (on start)
    (switch mode
      (0 (when cond
           (drive first)
           (drive second)))
      (1 (drive alt)))
    (drive after)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'when_in_switch_exit.fsm');

    my $when      = state_block($fsm, 'main_when_1');
    my $body_tail = state_block($fsm, 'main_drive_3');

    like($when, qr/\(=1 \(-> main_drive_2\)\)/, 'nested true path enters the when body');
    like($when, qr/\(=0 \(-> main_drive_6\)\)/, 'nested false path exits after the whole switch');
    unlike($when, qr/\(=0 \(-> main_drive_4\)\)/, 'nested false path does not fall into the next switch branch');
    like($body_tail, qr/\(-> main_drive_6\)/, 'nested when body tail exits after the whole switch');
};

done_testing();
