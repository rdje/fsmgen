#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'scheduler lowers burst_reader.isf — repeat with counter inference' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'burst_reader.isf');

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm    = $result->{files}{"burst_reader.fsm"};

    ok(length($fsm) > 0, 'produces non-empty output');

    # Counter inferred from (repeat beats ...)
    like($fsm, qr/\(read_burst_cnt 8\)/, 'counter declared in +size');

    # Repeat init: load counter
    like($fsm, qr/read_burst_repeat_init/, 'has repeat init state');
    like($fsm, qr/\(<= \(read_burst_cnt beats\)\)/, 'counter loaded from bound name');

    # Repeat check: decrement and loop
    like($fsm, qr/read_burst_repeat_check/, 'has repeat check state');
    like($fsm, qr/\(<- \(read_burst_cnt \(- read_burst_cnt 1\)\)\)/, 'counter decremented with <-');
    like($fsm, qr/\(\?read_burst_cnt/, 'decision tree on counter');
    like($fsm, qr/\(=0 \(-> read_burst_drive/, 'exit when counter zero');
    like($fsm, qr/\(=1 \(-> read_burst_repeat_init/, 'loop back when counter nonzero');

    # Await uses shorthand
    like($fsm, qr/\(-- read_burst_wd\)/, 'await has watchdog decrement');
    like($fsm, qr/\(=0 \(-> read_burst_timeout\)\)/, 'timeout at watchdog zero');

    note("Generated burst_reader.fsm:\n$fsm");
};

done_testing();
