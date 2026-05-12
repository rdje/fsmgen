#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'await_any emits a guard for every collected spawned done signal' => sub {
    my $source = <<'ISF';
(actor await_any_parent
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
    (await_any done)
    (complete done)))
ISF

    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'await-any-inline.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm    = $result->{files}{'await_any_parent.fsm'};

    like($fsm, qr/parent_await_any_4/, 'has await_any state');
    like($fsm, qr/<w0_done\s+\(-> parent_done_5\)/, 'await_any watches w0_done');
    like($fsm, qr/<w1_done\s+\(-> parent_done_5\)/, 'await_any watches w1_done');
    like($fsm, qr/<w2_done\s+\(-> parent_done_5\)/, 'await_any watches w2_done');
    unlike($fsm, qr/parent_await_any_4\s*\n\s*<w0_done\s+\(-> parent_done_5\)\s*\)/,
        'await_any is not limited to the first done port');
};

done_testing();
