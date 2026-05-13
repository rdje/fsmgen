#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /(  \(\Q$state_name\E\b.*?\n  \))/s);
    return $block // '';
}

subtest 'do child entry rewires to first non-drive child state' => sub {
    my $source = <<'ISF';
(actor do_update_child
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input payload (width 8))
    (output done)
    (output out (width 8)))
  (transaction child
    (on start)
    (update out payload)
    (complete done))
  (transaction parent
    (on start)
    (do child)
    (complete done)))
ISF

    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'do-update-child.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm    = $result->{files}{'do_update_child.fsm'};

    my $child_idle = state_block($fsm, 'child_idle_0');
    like($child_idle, qr/<child_start\s+\(-> child_update_1\)/, 'child idle enters first update state');
    unlike($child_idle, qr/<start\b/, 'child idle no longer watches the top-level start port');

    my $child_done = state_block($fsm, 'child_done_2');
    like($child_done, qr/\(<1 \(child_done 1\)\)/, 'child terminal signals child_done as a one-cycle pulse');
    unlike($child_done, qr/\(<- \(child_done 1\)\)/, 'child terminal no longer signals child_done as a sticky flopped set');

    my $parent_do = state_block($fsm, 'parent_do_1');
    like($parent_do, qr/\(= \(child_start 1\)\)/, 'parent do state asserts child_start');
    like($parent_do, qr/<child_done\s+\(-> parent_done_2\)/, 'parent do state awaits child_done');
};

done_testing();
