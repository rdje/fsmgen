#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP ();

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'schedule JSON transaction summaries include control and data states' => sub {
    my $source = <<'ISF';
(actor transaction_state_report
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cond)
    (input mode)
    (input payload (width 8))
    (output done)
    (output flag))
  (drive pulse
    (flag 1))
  (transaction main_flow
    (on start
      (sample payload as word))
    (when cond
      (update word payload))
    (switch mode
      (0 (drive pulse))
      (1 (shift_left word cond)))
    (complete done)))
ISF

    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'transaction-state-report.isf');
    my $json   = FSM::Scheduler::ISF->new()->report($actor);
    my $report = JSON::PP->new->decode($json);

    my ($tx) = grep { $_->{name} eq 'main_flow' } @{$report->{transactions}};
    ok($tx, 'main_flow transaction summary exists');
    is($tx->{count}, 7, 'control and data states are counted');
    is_deeply(
        $tx->{states},
        [qw(
          main_flow_idle_0
          main_flow_when_1
          main_flow_update_2
          main_flow_switch_5
          main_flow_drive_3
          main_flow_shift_4
          main_flow_done_6
        )],
        'transaction state list includes when, switch, update, and shift states in IR order',
    );
};

done_testing();
