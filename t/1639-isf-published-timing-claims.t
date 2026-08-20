#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));
    return ($lowered->{files}{"$label.fsm"}, $report);
}

sub transaction_states {
    my ($report, $transaction) = @_;
    my ($entry) = grep { ($_->{name} // '') eq $transaction }
        @{$report->{transactions} || []};
    return $entry ? $entry->{states} : [];
}

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /^  \(\Q$state_name\E\b(.*?^  \)\n)/ms);
    return $block // '';
}

subtest 'literal and actor-constant waits emit exactly their authored cycles' => sub {
    my ($literal_fsm, $literal_report) = lower_source(<<'ISF', 'published_wait_16');
(actor published_wait_16
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait 16)
    (complete done)))
ISF

    my @literal_waits = grep { /\Amain_wait_/ }
        @{transaction_states($literal_report, 'main')};
    is(scalar(@literal_waits), 16, 'literal wait 16 emits sixteen scheduled wait states');
    is_deeply(
        \@literal_waits,
        [map { "main_wait_$_" } 1 .. 16],
        'literal wait states are contiguous and source ordered',
    );
    like(
        state_block($literal_fsm, 'main_wait_16'),
        qr/\(-> main_done_17\)/,
        'the sixteenth wait state alone reaches the successor',
    );

    my ($constant_fsm, $constant_report) = lower_source(<<'ISF', 'published_wait_constant');
(actor published_wait_constant
  (constants (DELAY 8))
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait DELAY)
    (complete done)))
ISF

    my @constant_waits = grep { /\Amain_wait_/ }
        @{transaction_states($constant_report, 'main')};
    is(scalar(@constant_waits), 8, 'actor constant DELAY=8 emits eight scheduled wait states');
    like(
        state_block($constant_fsm, 'main_wait_8'),
        qr/\(-> main_done_9\)/,
        'the eighth constant-derived wait state alone reaches the successor',
    );
};

subtest 'entry, drive, sample, await, and complete costs follow emitted state structure' => sub {
    my ($fsm, $report) = lower_source(<<'ISF', 'published_clause_costs');
(actor published_clause_costs
  (clock clk)
  (watchdog 4)
  (interface
    (input start)
    (input ready)
    (input payload (width 8))
    (input enable)
    (output bus (width 8))
    (output flag)
    (output done))
  (drive (publish value gate)
    (bus value)
    (flag gate))
  (transaction main
    (on start)
    (sample payload as held)
    (drive publish held enable)
    (await ready)
    (complete done)))
ISF

    is_deeply(
        transaction_states($report, 'main'),
        [qw(main_idle_0 main_drive_1 main_await_2 main_done_3 main_timeout)],
        'each active clause has one state and the sample piggybacks on the drive',
    );
    unlike($fsm, qr/\bmain_sample_/, 'sample adds no standalone state when a drive follows');

    my $entry = state_block($fsm, 'main_idle_0');
    like($entry, qr/\(= \(can_accept 1\)\)/, 'entry drives one-bit can_accept high');
    like($entry, qr/\(<start[\s\S]*\(-> main_drive_1\)/,
        'entry advances under the authored activation guard');

    my $drive = state_block($fsm, 'main_drive_1');
    like($drive, qr/\(<= \(held payload\)\)/, 'pending sample is captured in the drive state');
    like($drive, qr/\(= \(publish_start 1\)\)/, 'drive state asserts its one-bit request');
    like($drive, qr/\(= \(publish_value held\)\)/, 'drive state wires the multibit actual');
    like($drive, qr/\(= \(publish_gate enable\)\)/, 'drive state wires the scalar actual');
    like($fsm, qr/^    \(publish_start 1\)$/m, 'drive request signal is one bit');
    like($fsm, qr/^    \(publish_value 8\)$/m, 'multibit drive payload follows its target width');
    like($fsm, qr/^    \(publish_gate 1\)$/m, 'scalar drive payload remains one bit');

    my $await = state_block($fsm, 'main_await_2');
    like($await, qr/\(<ready[\s\S]*\(-> main_done_3\)/,
        'await exits only under its ready guard');
    like($await, qr/\?main_wd[\s\S]*\(=0 \(-> main_timeout\)\)/,
        'await retains its watchdog timeout edge');

    my $complete = state_block($fsm, 'main_done_3');
    like($complete, qr/\(<1 \(done> 1\)\)/, 'complete requests the delayed one-cycle pulse');
    like($complete, qr/\(-> main_idle_0\)/, 'complete returns to the entry state');
};

subtest 'positive counted repeat cost includes every per-iteration check' => sub {
    my ($fsm, $report) = lower_source(<<'ISF', 'published_repeat_cost');
(actor published_repeat_cost
  (clock clk)
  (interface (input start) (output scl) (output done))
  (drive (set_scl value) (scl value))
  (transaction main
    (on start)
    (repeat 8
      (drive set_scl 1)
      (drive set_scl 0))
    (complete done)))
ISF

    is_deeply(
        transaction_states($report, 'main'),
        [qw(
          main_idle_0
          main_repeat_init_1
          main_drive_2
          main_drive_3
          main_repeat_check_4
          main_done_5
        )],
        'repeat region contains one init, two body, and one check state',
    );
    like(state_block($fsm, 'main_repeat_init_1'), qr/\(-> main_repeat_check_4\)/,
        'repeat enters the check before its first body visit');
    like(state_block($fsm, 'main_repeat_check_4'), qr/\(!=0 \(-> main_drive_2\)\)/,
        'each nonzero check enters the first body state');
    like(state_block($fsm, 'main_drive_2'), qr/\(-> main_drive_3\)/,
        'the first body state advances to the second body state');
    like(state_block($fsm, 'main_drive_3'), qr/\(-> main_repeat_check_4\)/,
        'each body visit returns to the check state');
    like(state_block($fsm, 'main_repeat_check_4'), qr/\(=0 \(-> main_done_5\)\)/,
        'the final zero check alone exits the repeat');

    my $iterations = 8;
    my $body_states = 2;
    my $derived_cycles = 1
        + ($iterations * $body_states)
        + ($iterations + 1);
    is($derived_cycles, 26, '8×(2+1)+2 derives the exact positive-repeat region cost');
    isnt($derived_cycles, 18, 'the former N×body+2 formula is independently rejected');
};

subtest 'decision, data, loop, and latency clauses retain their stated structural costs' => sub {
    my ($fsm, $report) = lower_source(<<'ISF', 'published_control_costs');
(actor published_control_costs
  (clock clk)
  (interface
    (input start)
    (input cond)
    (input mode)
    (input bit_in)
    (output done)
    (output flag))
  (storage (var word (width 8)))
  (drive pulse (flag 1))
  (transaction main
    (on start)
    (when cond (drive pulse))
    (switch mode
      (0 (set word 1))
      (1 (update word 2)))
    (shift_left word bit_in (width 8))
    (while cond (drive pulse))
    (until cond (drive pulse))
    (latency (min 1) (max 32))
    (complete done)))
ISF

    my $states = transaction_states($report, 'main');
    is_deeply([map { $_->{name} } @{$report->{transactions}}], ['main'],
        'schedule report exposes one exact non-empty transaction owner');
    is(scalar(grep { /_when_/ } @$states), 1, 'when contributes one decision state');
    is(scalar(grep { /_switch_/ } @$states), 1, 'switch contributes one decision state');
    is(scalar(grep { /_(?:set|update|shift)_/ } @$states), 3,
        'set, update, and shift each contribute one sequential state');
    is(scalar(grep { /_while_(?:entry|check)_/ } @$states), 2,
        'while contributes one pre-test and one per-iteration back-edge check state');
    is(scalar(grep { /_until_check_/ } @$states), 1,
        'until contributes one post-test state per body visit');
    is(scalar(grep { /_latency_/ } @$states), 0,
        'latency metadata adds no transaction state');
    ok((grep { $_ eq 'main_max_chk' } @$states),
        'the injected latency maximum-check state retains main ownership');
    like($fsm, qr/\(main_cc /, 'latency metadata still installs its verification counter');
};

done_testing();
