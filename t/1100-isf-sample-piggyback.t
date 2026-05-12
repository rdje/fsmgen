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
    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'sample-piggyback-inline.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /^  \(\Q$state_name\E\n(.*?^  \)\n)/ms);
    return $block // '';
}

subtest 'APB entry and named drive samples lower into their scheduled states' => sub {
    my $fsm = lower_file('apb_requester.isf', 'apb_requester.fsm');

    my $idle = state_block($fsm, 'apb_transfer_idle_0');
    like($idle, qr/\(<= \(addr req_addr\) <start\)/,      'entry captures address sample under start');
    like($idle, qr/\(<= \(is_write req_write\) <start\)/, 'entry captures write flag sample under start');
    like($idle, qr/\(<= \(wdata req_wdata\) <start\)/,    'entry captures write data sample under start');

    my $done_drive = state_block($fsm, 'apb_transfer_drive_4');
    like($done_drive, qr/\(<= \(rdata PRDATA\)\)/,      'done drive captures read data');
    like($done_drive, qr/\(<= \(slverr PSLVERR\)\)/,    'done drive captures error sample');
    like($done_drive, qr/\(= \(done_phase_start 1\)\)/, 'done drive still asserts named drive start');

    unlike($fsm, qr/\bapb_transfer_sample_6\b/, 'post-terminal sample state is not emitted');
};

subtest 'pending samples piggyback onto awaits' => sub {
    my $source = <<'ISF';
(actor sample_await
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ready)
    (input din)
    (output done)
    (output out))
  (drive (out val) (out val))
  (transaction main
    (on start)
    (sample din as hold)
    (await ready)
    (drive out hold)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'sample_await.fsm');
    my $await = state_block($fsm, 'main_await_1');

    like($await, qr/\(<= \(hold din\)\)/, 'await state carries the pending sample');
    unlike($fsm, qr/\bmain_sample_/, 'await piggyback does not create a trailing sample state');
};

subtest 'control-flow named drives consume local pending samples' => sub {
    my $source = <<'ISF';
(actor sample_control
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input mode)
    (input din)
    (output done)
    (output out))
  (drive (out val) (out val))
  (transaction main
    (on start)
    (when mode
      (sample din as hold)
      (drive out hold))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'sample_control.fsm');
    my $drive = state_block($fsm, 'main_drive_2');

    like($drive, qr/\(<= \(hold din\)\)/,     'when-body drive captures local sample');
    like($drive, qr/\(= \(out_start 1\)\)/,   'when-body drive still asserts start');
    like($drive, qr/\(= \(out_val hold\)\)/,  'when-body drive still binds argument');
    unlike($fsm, qr/\bmain_sample_/, 'control-flow piggyback does not leave a sample state');
};

done_testing();
