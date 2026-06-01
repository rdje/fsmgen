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
    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'switch-inline.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

sub lower_failure {
    my ($source) = @_;
    my $error = '';
    eval {
        my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'switch-inline.isf');
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    } or $error = $@ || 'unknown failure';
    return $error;
}

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /(  \(\Q$state_name\E\b.*?\n  \))/s);
    return $block // '';
}

subtest 'multi-state switch branches exit after the whole switch' => sub {
    my $source = <<'ISF';
(actor switch_exit
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input mode)
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
      (0 (drive first)
         (drive second))
      (1 (drive alt)))
    (drive after)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'switch_exit.fsm');

    my $branch_tail = state_block($fsm, 'main_drive_2');
    my $alt_tail    = state_block($fsm, 'main_drive_3');

    like($fsm, qr/\(\?mode\s+.*?\(default \(-> main_drive_5\)\)/s, 'implicit switch fallthrough emits a real default selector to the post-switch state');
    like($branch_tail, qr/\(-> main_drive_5\)/, 'first branch tail exits after all switch branches');
    unlike($branch_tail, qr/\(-> main_drive_3\)/, 'first branch tail does not fall into the next branch');
    like($alt_tail, qr/\(-> main_drive_5\)/, 'last branch tail also exits to the post-switch state');
};

subtest 'repeat checks in switch branches exit after the whole switch' => sub {
    my $source = <<'ISF';
(actor switch_repeat_exit
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input mode)
    (output done)
    (output flag))
  (drive tick
    (flag 1))
  (drive alt
    (flag 0))
  (drive after
    (flag 1))
  (transaction main
    (on start)
    (switch mode
      (0 (repeat 2
           (drive tick)))
      (1 (drive alt)))
    (drive after)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'switch_repeat_exit.fsm');

    my $repeat_check = state_block($fsm, 'main_repeat_check_3');
    my $alt_tail     = state_block($fsm, 'main_drive_4');

    like($repeat_check, qr/\(>0 \(-> main_drive_2\)\)/, 'repeat branch still loops to its first body state');
    like($repeat_check, qr/\(=0 \(-> main_drive_6\)\)/, 'repeat branch exits after all switch branches');
    unlike($repeat_check, qr/\(=0 \(-> main_drive_4\)\)/, 'repeat branch does not exit into the next branch');
    like($alt_tail, qr/\(-> main_drive_6\)/, 'non-repeat branch exits to the post-switch state');
};

subtest 'explicit default switch branches own the switch default path' => sub {
    my $source = <<'ISF';
(actor switch_default
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input mode)
    (output done)
    (output flag))
  (drive first
    (flag 1))
  (drive fallback
    (flag 0))
  (drive after
    (flag 1))
  (transaction main
    (on start)
    (switch mode
      (0 (drive first))
      (default (drive fallback)))
    (drive after)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'switch_default.fsm');

    like($fsm, qr/\(\?mode\s+.*?\(=0 \(-> main_drive_1\)\).*?\(default \(-> main_drive_2\)\)/s, 'explicit default switch branch emits as the switch default selector');
    unlike($fsm, qr/\(\?mode\s+.*?\(default \(-> main_drive_4\)\)/s, 'explicit default branch suppresses the implicit fallthrough default');

    my $default_tail = state_block($fsm, 'main_drive_2');
    like($default_tail, qr/\(-> main_drive_4\)/, 'explicit default branch tail exits to the post-switch state');
};

subtest 'underscore switch branch is an alias for explicit default' => sub {
    my $source = <<'ISF';
(actor switch_underscore_default
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input mode)
    (output done)
    (output flag))
  (drive first
    (flag 1))
  (drive fallback
    (flag 0))
  (transaction main
    (on start)
    (switch mode
      (0 (drive first))
      (_ (drive fallback)))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'switch_underscore_default.fsm');

    like($fsm, qr/\(\?mode\s+.*?\(=0 \(-> main_drive_1\)\).*?\(default \(-> main_drive_2\)\)/s, 'underscore switch branch emits as the canonical default selector');
};

subtest 'default and underscore switch branches are duplicate aliases' => sub {
    my $source = <<'ISF';
(actor switch_duplicate_default
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input mode)
    (output done)
    (output flag))
  (drive first
    (flag 1))
  (drive fallback
    (flag 0))
  (transaction main
    (on start)
    (switch mode
      (default (drive first))
      (_ (drive fallback)))
    (complete done)))
ISF

    my $error = lower_failure($source);
    like($error, qr/Switch 'main': duplicate value '_'/, 'ISF rejects default and underscore as duplicate switch selectors before .fsm emission');
};

done_testing();
