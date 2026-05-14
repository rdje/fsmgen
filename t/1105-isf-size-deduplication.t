#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_fixture {
    my ($fixture, $fsm_name) = @_;
    my $path   = File::Spec->catfile($FindBin::Bin, '..', 'isf', $fixture);
    my $actor  = FSM::Adapter::ISF->new()->parse_file($path);
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

sub size_block {
    my ($fsm) = @_;
    my ($block) = ($fsm =~ /(  \(\+size\b.*?\n  \))/s);
    return $block // '';
}

subtest 'inferred storage does not duplicate declared interface ports in +size' => sub {
    my $fsm  = lower_fixture('apb_requester.isf', 'apb_requester.fsm');
    my $size = size_block($fsm);

    my @last_error_entries = ($size =~ /\(last_error 1\)/g);
    is(scalar(@last_error_entries), 1, 'declared last_error appears once in +size');
    like($size, qr/\(apb_transfer_wd 17\)/, 'watchdog counter is still emitted');
    like($size, qr/\(apb_transfer_cc 5\)/,  'latency counter is still emitted with max-bound width');
    like($fsm, qr/\(<- \(last_error> 1\)\)/, 'timeout assignment to last_error is preserved');
};

done_testing();
