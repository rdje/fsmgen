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

subtest 'await_all emits nested guards for every collected spawned done signal' => sub {
    my $source = <<'ISF';
(actor await_all_parent
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done)
    (output out))
  (drive (out val) (out val))
  (transaction worker
    (on start)
    (drive out 1)
    (complete done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (spawn worker as w1)
    (spawn worker as w2)
    (await_all done)
    (complete done)))
ISF

    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'await-all-inline.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm    = $result->{files}{'await_all_parent.fsm'};
    my $block  = state_block($fsm, 'parent_await_all_4');

    like($block, qr/\(<w2_done\s+\(<w1_done\s+\(<w0_done\s+\(-> parent_done_5\)/s,
        'await_all nests all collected done guards before advancing');
    like($block, qr/\(-> parent_done_5\)\n    \)\n    \)\n    \)/,
        'await_all nested guard closings are emitted one per line');
    for my $done_port (qw(w0_done w1_done w2_done)) {
        like($block, qr/<$done_port\b/, "await_all includes $done_port");
    }

    my @targets = ($block =~ /\(-> parent_done_5\)/g);
    is(scalar(@targets), 1, 'await_all advances through one all-guards transition');
};

done_testing();
