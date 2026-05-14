#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_file {
    my ($fixture, $fsm_name) = @_;
    my $path   = File::Spec->catfile($FindBin::Bin, '..', 'isf', $fixture);
    my $actor  = FSM::Adapter::ISF->new()->parse_file($path);
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

sub lower_source {
    my ($source, $fsm_name) = @_;
    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'inline-test.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

subtest 'spawn start states assert per-instance start signals' => sub {
    my $fsm = lower_file('spawn_parent.isf', 'spawn_parent.fsm');

    like($fsm, qr/\(w0_start 1\)/, 'declares w0_start');
    like($fsm, qr/\(w1_start 1\)/, 'declares w1_start');
    like($fsm, qr/\(w2_start 1\)/, 'declares w2_start');

    like($fsm, qr/\(= \(w0_start> 1\)\)/, 'first spawn asserts w0_start');
    like($fsm, qr/\(= \(w1_start> 1\)\)/, 'second spawn asserts w1_start');
    like($fsm, qr/\(= \(w2_start> 1\)\)/, 'third spawn asserts w2_start');
    unlike($fsm, qr/\(_start\b/, 'spawn lowering does not emit anonymous _start');
};

subtest 'do start state asserts the named child start signal' => sub {
    my $source = <<'ISF';
(actor do_binding
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done)
    (output out))
  (drive (out val) (out val))
  (transaction child
    (on start)
    (drive out 1)
    (complete done))
  (transaction parent
    (on start)
    (do child)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'do_binding.fsm');

    like($fsm, qr/\(child_start 1\)/, 'declares child_start');
    like($fsm, qr/\(child_done 1\)/,  'declares child_done');
    like($fsm, qr/\(= \(child_start 1\)\)/, 'parent do state asserts child_start');
    like($fsm, qr/<child_done/, 'parent do state awaits child_done');
    like($fsm, qr/<child_start\s+\(-> child_drive_1\)/, 'child idle watches child_start');
    unlike($fsm, qr/\(_start\b/, 'do lowering does not emit anonymous _start');
};

subtest 'named drive calls inside control flow assert drive start signals' => sub {
    my $when_fsm  = lower_file('when_test.isf',  'when_test.fsm');
    my $switch_fsm = lower_file('switch_test.isf', 'switch_test.fsm');

    like($when_fsm, qr/\(= \(result_start 1\)\)/, 'when body asserts result_start');
    unlike($when_fsm, qr/\(= \(done_start 1\)\)/, 'when body does not drive transaction done through a drive');
    unlike($when_fsm, qr/\(_start\b/, 'when lowering does not emit anonymous _start');

    like($switch_fsm, qr/\(= \(write_res_start 1\)\)/, 'switch branch asserts write_res_start');
    like($switch_fsm, qr/\(= \(read_res_start 1\)\)/,  'switch branch asserts read_res_start');
    like($switch_fsm, qr/\(= \(err_res_start 1\)\)/,   'switch branch asserts err_res_start');
    unlike($switch_fsm, qr/\(_start\b/, 'switch lowering does not emit anonymous _start');
};

done_testing();
