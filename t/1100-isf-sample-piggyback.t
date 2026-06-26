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

    my $done_phase = state_block($fsm, '-done_phase');
    unlike($done_phase, qr/\(done 1\)/, 'APB done_phase does not drive transaction done');

    my $complete = state_block($fsm, 'apb_transfer_done_5');
    like($complete, qr/\(<1 \(done> 1\)\)/, 'complete emits a one-cycle delayed done pulse');

    my $timeout = state_block($fsm, 'apb_transfer_timeout');
    like($timeout, qr/\(<1 \(done> 1\)\)/, 'timeout emits a one-cycle delayed done pulse');

    unlike($fsm, qr/\bapb_transfer_sample_6\b/, 'post-terminal sample state is not emitted');
};

subtest 'scalar entry sample guard rendering is preserved' => sub {
    my $source = <<'ISF';
(actor scalar_entry_sample
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input din (width 8))
    (output done))
  (transaction main
    (on start
      (sample din as hold))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'scalar_entry_sample.fsm');
    my $idle = state_block($fsm, 'main_idle_0');

    like($idle, qr/\Q(<= (hold din) <start)\E/, 'scalar entry samples still use the scalar start guard');
    like($idle, qr/\Q(<start\E/, 'scalar entry transition still uses the scalar guard block');
    unlike($fsm, qr/ARRAY\(/, 'scalar entry guard never stringifies a Perl array reference');
};

subtest 'expression entry sample guard renders valid fsm expression text' => sub {
    my $source = <<'ISF';
(actor expression_entry_sample
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input go)
    (input busy)
    (input din (width 8))
    (output done))
  (transaction main
    (when (& go (! busy))
      (sample din as hold))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'expression_entry_sample.fsm');
    my $idle = state_block($fsm, 'main_idle_0');

    like($idle, qr/\Q(<= (hold din) <(& go (! busy)))\E/, 'expression entry sample uses rendered .fsm guard text');
    like($idle, qr/\Q(-> main_done_1 <(& go (! busy)))\E/, 'expression entry transition uses rendered .fsm guard text');
    unlike($fsm, qr/ARRAY\(/, 'expression entry guard never stringifies a Perl array reference');
};

subtest 'APB-shaped expression entry guard renders on every setup sample and transition' => sub {
    my $source = <<'ISF';
(actor apb_entry_sample
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input PSEL)
    (input PENABLE)
    (input PADDR (width 32))
    (input PWRITE)
    (input PWDATA (width 32))
    (input wait_cycles (width 4))
    (output done))
  (transaction apb_complete
    (when (& PSEL (! PENABLE))
      (sample PADDR as addr)
      (sample PWRITE as write_q)
      (sample PWDATA as wdata_q)
      (sample wait_cycles as wait_n))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'apb_entry_sample.fsm');
    my $idle = state_block($fsm, 'apb_complete_idle_0');
    my $guard = '(& PSEL (! PENABLE))';

    like($idle, qr/\Q(<= (addr PADDR) <$guard)\E/, 'APB address setup sample uses rendered expression guard');
    like($idle, qr/\Q(<= (write_q PWRITE) <$guard)\E/, 'APB write flag setup sample uses rendered expression guard');
    like($idle, qr/\Q(<= (wdata_q PWDATA) <$guard)\E/, 'APB write data setup sample uses rendered expression guard');
    like($idle, qr/\Q(<= (wait_n wait_cycles) <$guard)\E/, 'APB wait count setup sample uses rendered expression guard');
    like($idle, qr/\Q(-> apb_complete_done_1 <$guard)\E/, 'APB setup transition uses rendered expression guard');
    unlike($fsm, qr/ARRAY\(/, 'APB-shaped expression entry guard never stringifies a Perl array reference');
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
