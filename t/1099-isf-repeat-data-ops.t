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

subtest 'repeat body lowers parameterized drive calls and shift_right' => sub {
    my $fsm = lower_fixture('uart_tx.isf', 'uart_tx.fsm');

    like($fsm, qr/\(= \(tx_start 1\)\)/, 'repeat drive call asserts tx_start');
    like($fsm, qr/\(= \(tx_val byte_data\)\)/, 'repeat drive call binds byte_data actual');
    like(
        $fsm,
        qr/\(<- \(byte_data \(\| \(>> byte_data 1\) \(<< 0 7\)\)\)\)/,
        'repeat shift_right uses sampled 8-bit width',
    );
    unlike($fsm, qr/WIDTH/, 'known-width shift_right does not emit WIDTH placeholder');
};

subtest 'repeat body lowers shift_left data operation' => sub {
    my $fsm = lower_fixture('i2c_master.isf', 'i2c_master.fsm');

    like(
        $fsm,
        qr/\(<- \(rdata> \(\| \(<< rdata 1\) sda_in\)\)\)/,
        'repeat shift_left captures serial input into rdata',
    );
};

done_testing();
