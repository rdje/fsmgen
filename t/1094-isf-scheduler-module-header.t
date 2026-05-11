#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'scheduler produces valid .fsm header from APB requester ISF' => sub {
    my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');

    # Parse
    my $adapter   = FSM::Adapter::ISF->new();
    my $actor     = $adapter->parse_file($isf_file);

    # Lower
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result    = $scheduler->lower($actor);
    my $fsm       = $result->{files}{"apb_requester.fsm"};

    ok(length($fsm) > 0, 'produces non-empty .fsm output');

    # Verify structure
    like($fsm, qr/^\Q(?fsm:apb_requester\E/, 'opens with (?fsm:apb_requester');
    like($fsm, qr/\)\s*\z/, 'closes with )');

    # System section
    like($fsm, qr/\(\+system/,            'has +system section');
    like($fsm, qr/\(clock clk\)/,         'clock declaration');
    like($fsm, qr/\(areset rst_n\)/,      'reset mapped to async active-low areset');

    # Ports section
    like($fsm, qr/\(\+size/,              'has +size section');

    # Input ports
    like($fsm, qr/\(start 1\)/,           'input start width 1');
    like($fsm, qr/\(req_addr 32\)/,       'input req_addr width 32');
    like($fsm, qr/\(req_wdata 32\)/,      'input req_wdata width 32');
    like($fsm, qr/\(PREADY 1\)/,          'input PREADY width 1');
    like($fsm, qr/\(PRDATA 32\)/,         'input PRDATA width 32');
    like($fsm, qr/\(PSLVERR 1\)/,         'input PSLVERR width 1');

    # Output ports
    like($fsm, qr/\(done 1\)/,            'output done width 1');
    like($fsm, qr/\(last_read_data 32\)/, 'output last_read_data width 32');
    like($fsm, qr/\(last_error 1\)/,      'output last_error width 1');
    like($fsm, qr/\(PADDR 32\)/,          'output PADDR width 32');
    like($fsm, qr/\(PWRITE 1\)/,          'output PWRITE width 1');
    like($fsm, qr/\(PWDATA 32\)/,         'output PWDATA width 32');
    like($fsm, qr/\(PSEL 1\)/,            'output PSEL width 1');
    like($fsm, qr/\(PENABLE 1\)/,         'output PENABLE width 1');

    # Placeholder for state machines
    like($fsm, qr/apb_transfer_idle/, 'has idle state');
    like($fsm, qr/apb_transfer_drive/, 'has drive states');
    like($fsm, qr/apb_transfer_await/, 'has await state');
    like($fsm, qr/apb_transfer_done/, 'has done state');

    note("Generated .fsm header + states:\n$fsm");
};

done_testing();
