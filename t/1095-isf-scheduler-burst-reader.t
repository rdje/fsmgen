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

    # Repeat init: single transition to the check state (no runtime zero-branch).
    like($fsm, qr/\(read_burst_repeat_init_3\b[^)]*\)?\s*\(= \(read_burst_inc 1\)\)\s*\(<= \(read_burst_cnt beats\)\)\s*\(-> read_burst_repeat_check_6\)/s,
        'repeat init loads counter and transitions straight to the check state');

    # Repeat check: check-first decrement and loop.
    like($fsm, qr/read_burst_repeat_check/, 'has repeat check state');
    like($fsm, qr/\(-- read_burst_cnt\)/, 'counter decremented with --');
    like($fsm, qr/\(\?read_burst_cnt/, 'decision tree on counter');
    like($fsm, qr/\(=0 \(-> read_burst_drive/, 'exit when counter zero');
    like($fsm, qr/\(!=0 \(-> read_burst_await_4\)\)/, 'loop back to the first body state when counter nonzero');

    # Await keeps timeout and decrement as same-cycle selector branches.
    unlike($fsm, qr/read_burst_await_\d+\s*\n\s*\(-- read_burst_wd\)/, 'await has no unconditional watchdog decrement');
    like(
        $fsm,
        qr/\(\?read_burst_wd\s+\(=0 \(-> read_burst_timeout\)\)\s+\(>0 \(-- read_burst_wd\)\)\s+\)/s,
        'await tests watchdog zero and decrements only on the nonzero branch',
    );

    note("Generated burst_reader.fsm:\n$fsm");
};

done_testing();
