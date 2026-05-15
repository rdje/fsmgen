#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source, $label) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
    my $scheduler = FSM::Scheduler::ISF->new();
    return (
        $scheduler->lower($actor),
        decode_json($scheduler->report($actor)),
    );
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source, $label);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub state_block {
    my ($fsm, $state_name) = @_;
    my ($block) = ($fsm =~ /(  \(\Q$state_name\E\b.*?\n  \))/s);
    return $block // '';
}

subtest 'positive literal wait lowers to exact review states and report metadata' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'wait-boundary');
(actor wait_boundary
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (wait 2)
    (drive tick)
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'wait_boundary.fsm'};
    like(state_block($fsm, 'main_wait_1'), qr/\(-> main_wait_2\)/, 'first wait state advances to the second wait cycle');
    like(state_block($fsm, 'main_wait_2'), qr/\(-> main_drive_3\)/, 'second wait state exits to the following transaction clause');
    unlike($fsm, qr/\bmain_wait_cnt\b/, 'literal wait does not introduce hidden counter storage');
    like($fsm, qr/\(= \(tick_start 1\)\)/, 'post-wait drive still lowers normally');

    is_deeply(
        $report->{transaction_waits},
        [
            {
                transaction    => 'main',
                cycles         => 2,
                count_kind     => 'static',
                count_source   => '2',
                entry_state    => 'main_wait_1',
                exit_state     => 'main_drive_3',
                counter_signal => undef,
                counter_width  => undef,
            },
        ],
        'schedule report exposes bounded wait provenance',
    );
    is_deeply(
        $report->{transactions}[0]{states},
        [qw(main_idle_0 main_wait_1 main_wait_2 main_drive_3 main_done_4)],
        'transaction state summary includes wait states in emitted order',
    );

    assert_fsm_reaches_hdl($fsm, 'wait_boundary');
};

subtest 'symbolic actor constants lower through the literal wait contract' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'wait-symbolic');
(actor wait_symbolic
  (clock clk)
  (reset (rst_n async active_low))
  (constants
    (WAIT_ZERO 0)
    (WAIT_TWO 2)
    (WAIT_ONE 4'd1))
  (interface
    (input start)
    (input din (width 8))
    (output done)
    (output out (width 8)))
  (drive (out val)
    (out val))
  (transaction main
    (on start)
    (sample din as hold)
    (wait WAIT_ZERO)
    (wait WAIT_TWO)
    (drive out hold)
    (wait WAIT_ONE)
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'wait_symbolic.fsm'};
    like($fsm, qr/\(\+constants[\s\S]*\(WAIT_ZERO 0\)[\s\S]*\(WAIT_TWO 2\)[\s\S]*\(WAIT_ONE 4'd1\)/, 'scheduled .fsm preserves actor constant declarations');
    like(state_block($fsm, 'main_wait_1'), qr/\(<= \(hold din\)\)/, 'pending sample survives symbolic zero wait and piggybacks onto first positive wait');
    like(state_block($fsm, 'main_wait_1'), qr/\(-> main_wait_2\)/, 'WAIT_TWO first generated wait state advances');
    like(state_block($fsm, 'main_wait_2'), qr/\(-> main_drive_3\)/, 'WAIT_TWO second generated wait state exits to following clause');
    like(state_block($fsm, 'main_wait_4'), qr/\(-> main_done_5\)/, 'exact-width WAIT_ONE emits one wait state');
    unlike($fsm, qr/\bmain_wait_0\b/, 'symbolic zero wait emits no hidden wait state');

    is_deeply(
        $report->{actor_constants},
        [
            { name => 'WAIT_ZERO', value => '0' },
            { name => 'WAIT_TWO',  value => '2' },
            { name => 'WAIT_ONE',  value => "4'd1" },
        ],
        'schedule report exposes actor constants as bounded provenance',
    );
    is_deeply(
        [map { $_->{cycles} } @{$report->{transaction_waits}}],
        [2, 1],
        'symbolic constants resolve to exact static wait counts',
    );
    is_deeply(
        [map { $_->{count_kind} } @{$report->{transaction_waits}}],
        [qw(static static)],
        'symbolic constants remain static waits in report metadata',
    );
    is_deeply(
        [map { $_->{count_source} } @{$report->{transaction_waits}}],
        [qw(WAIT_TWO WAIT_ONE)],
        'symbolic wait report entries preserve their source constant names',
    );
    is_deeply(
        $report->{transactions}[0]{states},
        [qw(main_idle_0 main_wait_1 main_wait_2 main_drive_3 main_wait_4 main_done_5)],
        'symbolic zero wait creates no state gap and positive constants keep emitted order',
    );

    assert_fsm_reaches_hdl($fsm, 'wait_symbolic');
};

subtest 'wait clauses lower in existing inline body contexts' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'wait-nested');
(actor wait_nested
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cond)
    (input mode)
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (when cond
      (wait 1)
      (drive tick))
    (switch mode
      (0 (wait 1)
         (drive tick))
      (default (drive tick)))
    (repeat 2
      (wait 1)
      (drive tick))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'wait_nested.fsm'};
    like($fsm, qr/\bmain_wait_2\b/, 'when body contains a wait state');
    like($fsm, qr/\bmain_wait_4\b/, 'switch branch contains a wait state');
    like($fsm, qr/\bmain_wait_9\b/, 'repeat body contains a wait state');
    is(scalar(@{$report->{transaction_waits}}), 3, 'schedule report records every wait clause');
    is_deeply([map { $_->{cycles} } @{$report->{transaction_waits}}], [1, 1, 1], 'nested waits keep exact one-cycle counts');
};

subtest 'zero wait is a transparent no-op that preserves pending samples' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'wait-zero');
(actor wait_zero
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input din (width 8))
    (output done)
    (output out (width 8)))
  (drive (out val)
    (out val))
  (transaction main
    (on start)
    (sample din as hold)
    (wait 0)
    (drive out hold)
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'wait_zero.fsm'};
    unlike($fsm, qr/\bmain_wait_/, 'zero wait emits no generated wait states');

    my $drive = state_block($fsm, 'main_drive_1');
    like($drive, qr/\(<= \(hold din\)\)/, 'pending sample survives the zero wait and piggybacks onto the following state');
    like($drive, qr/\(= \(out_start 1\)\)/, 'following drive still executes immediately after the entry state');
    like($drive, qr/\(= \(out_val hold\)\)/, 'following drive still receives the sampled value');

    is_deeply($report->{transaction_waits}, [], 'zero wait does not create a wait report entry');
    is_deeply(
        $report->{transactions}[0]{states},
        [qw(main_idle_0 main_drive_1 main_done_2)],
        'transaction state summary has no zero-wait state gap',
    );

    assert_fsm_reaches_hdl($fsm, 'wait_zero');

    ($lowered, $report) = lower_source(<<'ISF', 'wait-zero-inline');
(actor wait_zero_inline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cond)
    (input din (width 8))
    (output done)
    (output out (width 8)))
  (drive (out val)
    (out val))
  (transaction main
    (on start)
    (when cond
      (sample din as hold)
      (wait 0)
      (drive out hold))
    (complete done)))
ISF

    $fsm = $lowered->{files}{'wait_zero_inline.fsm'};
    unlike($fsm, qr/\bmain_wait_/, 'inline zero wait emits no generated wait states');

    my $inline_drive = state_block($fsm, 'main_drive_2');
    like($inline_drive, qr/\(<= \(hold din\)\)/, 'inline pending sample survives the zero wait');
    like($inline_drive, qr/\(= \(out_start 1\)\)/, 'inline following drive remains the first body state');
    is_deeply($report->{transaction_waits}, [], 'inline zero wait does not create a wait report entry');

    assert_fsm_reaches_hdl($fsm, 'wait_zero_inline');
};

subtest 'runtime scalar wait uses predecessor bypass and sampled counter' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'wait-dynamic');
(actor wait_dynamic
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cycles (width 4))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (wait cycles)
    (drive tick)
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'wait_dynamic.fsm'};
    my $idle = state_block($fsm, 'main_idle_0');
    like($idle, qr/\(<- \(main_wait_1_cnt cycles\) <\(& start cycles\)\)/,
        'predecessor edge snapshots the runtime count only on the positive-count path');
    like($idle, qr/\(-> main_wait_1 <\(& start cycles\)\)/,
        'positive runtime count enters the generated wait state');
    like($idle, qr/\(-> main_drive_2 <\(& start \(== cycles 0\)\)\)/,
        'zero runtime count bypasses the generated wait state');

    my $wait = state_block($fsm, 'main_wait_1');
    like($wait, qr/\(-- main_wait_1_cnt\)/, 'dynamic wait decrements the sampled counter while active');
    like($wait, qr/\?main_wait_1_cnt[\s\S]*\(=1 \(-> main_drive_2\)\)/,
        'sampled count of one exits after one active wait cycle');
    like($wait, qr/\?main_wait_1_cnt[\s\S]*\(>1 \(-> main_wait_1\)\)/,
        'sampled counts greater than one loop in the wait state');

    is_deeply(
        $report->{transaction_waits},
        [
            {
                transaction    => 'main',
                cycles         => undef,
                count_kind     => 'runtime_scalar',
                count_source   => 'cycles',
                entry_state    => 'main_wait_1',
                exit_state     => 'main_drive_2',
                counter_signal => 'main_wait_1_cnt',
                counter_width  => 4,
            },
        ],
        'dynamic wait report exposes runtime count and counter provenance',
    );

    assert_fsm_reaches_hdl($fsm, 'wait_dynamic');
};

subtest 'consecutive runtime scalar waits split load and bypass edges' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'wait-dynamic-pair');
(actor wait_dynamic_pair
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input first_cycles (width 4))
    (input second_cycles (width 3))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (wait first_cycles)
    (wait second_cycles)
    (drive tick)
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'wait_dynamic_pair.fsm'};
    my $idle = state_block($fsm, 'main_idle_0');
    like($idle, qr/\(<- \(main_wait_1_cnt first_cycles\) <\(& start first_cycles\)\)/,
        'first wait positive path samples the first runtime count at activation');
    like($idle, qr/\(-> main_wait_1 <\(& start first_cycles\)\)/,
        'first wait positive path enters the first generated wait state');
    like($idle, qr/\(<- \(main_wait_2_cnt second_cycles\) <\(& start \(== first_cycles 0\) second_cycles\)\)/,
        'first wait zero-bypass samples the second runtime count without an active first wait cycle');
    like($idle, qr/\(-> main_wait_2 <\(& start \(== first_cycles 0\) second_cycles\)\)/,
        'first wait zero-bypass can enter the second wait directly');
    like($idle, qr/\(-> main_drive_3 <\(& start \(== first_cycles 0\) \(== second_cycles 0\)\)\)/,
        'both zero counts bypass both generated wait states on the activation edge');

    my $first_wait = state_block($fsm, 'main_wait_1');
    like($first_wait, qr/\(-- main_wait_1_cnt\)/,
        'first wait decrements only its sampled counter while active');
    like($first_wait, qr/\(<- \(main_wait_2_cnt second_cycles\) <\(& \(== main_wait_1_cnt 1\) second_cycles\)\)/,
        'first wait final cycle samples the second runtime count on the positive second-count path');
    like($first_wait, qr/\(-> main_wait_2 <\(& \(== main_wait_1_cnt 1\) second_cycles\)\)/,
        'first wait final cycle can enter the second wait without rereading the first count source');
    like($first_wait, qr/\(-> main_drive_3 <\(& \(== main_wait_1_cnt 1\) \(== second_cycles 0\)\)\)/,
        'first wait final cycle can bypass a zero second count');
    like($first_wait, qr/\?main_wait_1_cnt[\s\S]*\(>1 \(-> main_wait_1\)\)/,
        'first wait still loops while its sampled counter is greater than one');

    my $second_wait = state_block($fsm, 'main_wait_2');
    like($second_wait, qr/\(-- main_wait_2_cnt\)/,
        'second wait decrements its sampled counter while active');
    like($second_wait, qr/\?main_wait_2_cnt[\s\S]*\(=1 \(-> main_drive_3\)\)/,
        'second sampled count of one exits to the following transaction clause');
    like($second_wait, qr/\?main_wait_2_cnt[\s\S]*\(>1 \(-> main_wait_2\)\)/,
        'second sampled counts greater than one loop in the second wait state');

    is_deeply(
        $report->{transaction_waits},
        [
            {
                transaction    => 'main',
                cycles         => undef,
                count_kind     => 'runtime_scalar',
                count_source   => 'first_cycles',
                entry_state    => 'main_wait_1',
                exit_state     => 'main_wait_2',
                counter_signal => 'main_wait_1_cnt',
                counter_width  => 4,
            },
            {
                transaction    => 'main',
                cycles         => undef,
                count_kind     => 'runtime_scalar',
                count_source   => 'second_cycles',
                entry_state    => 'main_wait_2',
                exit_state     => 'main_drive_3',
                counter_signal => 'main_wait_2_cnt',
                counter_width  => 3,
            },
        ],
        'dynamic wait report exposes both consecutive runtime waits',
    );
    is_deeply(
        $report->{transactions}[0]{states},
        [qw(main_idle_0 main_wait_1 main_wait_2 main_drive_3 main_done_4)],
        'transaction state summary keeps consecutive runtime wait states in emitted order',
    );

    assert_fsm_reaches_hdl($fsm, 'wait_dynamic_pair');
};

subtest 'runtime scalar waits split additional top-level predecessor kinds' => sub {
    my ($lowered) = lower_source(<<'ISF', 'wait-dynamic-after-await');
(actor wait_dynamic_after_await
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ready)
    (input cycles (width 4))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (await ready)
    (wait cycles)
    (drive tick)
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'wait_dynamic_after_await.fsm'};
    my $await = state_block($fsm, 'main_await_1');
    like($await, qr/\(<- \(main_wait_2_cnt cycles\) <\(& ready cycles\)\)/,
        'await ready edge samples the runtime count on the positive path');
    like($await, qr/\(-> main_wait_2 <\(& ready cycles\)\)/,
        'await ready edge enters the dynamic wait on a positive count');
    like($await, qr/\(-> main_drive_3 <\(& ready \(== cycles 0\)\)\)/,
        'await ready edge bypasses the dynamic wait on zero');
    like($await, qr/\?main_wd[\s\S]*\(=0 \(-> main_timeout\)\)/,
        'await watchdog timeout transition is preserved');
    assert_fsm_reaches_hdl($fsm, 'wait_dynamic_after_await');

    ($lowered) = lower_source(<<'ISF', 'wait-dynamic-after-stage');
(actor wait_dynamic_after_stage
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ready)
    (input cycles (width 4))
    (output valid)
    (output done))
  (transaction main
    (on start)
    (stage accept (input ready) (output valid))
    (wait cycles)
    (complete done)))
ISF

    $fsm = $lowered->{files}{'wait_dynamic_after_stage.fsm'};
    my $stage = state_block($fsm, 'main_stage_1');
    like($stage, qr/\(= \(valid> 1\)\)/, 'stage still drives valid while waiting for ready');
    like($stage, qr/\(<- \(main_wait_2_cnt cycles\) <\(& ready cycles\)\)/,
        'stage ready edge samples the runtime count on the positive path');
    like($stage, qr/\(-> main_done_3 <\(& ready \(== cycles 0\)\)\)/,
        'stage ready edge bypasses to the post-wait state on zero');
    assert_fsm_reaches_hdl($fsm, 'wait_dynamic_after_stage');

    ($lowered) = lower_source(<<'ISF', 'wait-dynamic-after-repeat');
(actor wait_dynamic_after_repeat
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cycles (width 4))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat 1
      (drive tick))
    (wait cycles)
    (complete done)))
ISF

    $fsm = $lowered->{files}{'wait_dynamic_after_repeat.fsm'};
    my $repeat_check = state_block($fsm, 'main_repeat_check_3');
    like($repeat_check, qr/\(<- \(main_wait_4_cnt cycles\) <\(& \(== main_cnt 0\) cycles\)\)/,
        'repeat exit edge samples the runtime count on the positive path');
    like($repeat_check, qr/\?main_cnt[\s\S]*\(=1 \(-> main_repeat_init_1\)\)/,
        'repeat loop-back edge is preserved');
    like($repeat_check, qr/\(-> main_done_5 <\(& \(== main_cnt 0\) \(== cycles 0\)\)\)/,
        'repeat exit edge bypasses the dynamic wait on zero');
    assert_fsm_reaches_hdl($fsm, 'wait_dynamic_after_repeat');

    ($lowered) = lower_source(<<'ISF', 'wait-dynamic-after-sync-all');
(actor wait_dynamic_after_sync_all
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cycles (width 4))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction worker
    (on start)
    (drive tick)
    (complete done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (spawn worker as w1)
    (await_all done)
    (wait cycles)
    (complete done)))
ISF

    $fsm = $lowered->{files}{'wait_dynamic_after_sync_all.fsm'};
    my $sync_all = state_block($fsm, 'parent_await_all_3');
    like($sync_all, qr/\(<- \(parent_wait_4_cnt cycles\) <\(& w0_done w1_done cycles\)\)/,
        'await_all all-done edge samples the runtime count on the positive path');
    like($sync_all, qr/\(-> parent_wait_4 <\(& w0_done w1_done cycles\)\)/,
        'await_all all-done edge enters the dynamic wait on a positive count');
    like($sync_all, qr/\(-> parent_done_5 <\(& w0_done w1_done \(== cycles 0\)\)\)/,
        'await_all all-done edge bypasses the dynamic wait on zero');
    assert_fsm_reaches_hdl($fsm, 'wait_dynamic_after_sync_all');

    ($lowered) = lower_source(<<'ISF', 'wait-dynamic-after-sync-any');
(actor wait_dynamic_after_sync_any
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cycles (width 4))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction worker
    (on start)
    (drive tick)
    (complete done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (spawn worker as w1)
    (await_any done)
    (wait cycles)
    (complete done)))
ISF

    $fsm = $lowered->{files}{'wait_dynamic_after_sync_any.fsm'};
    my $sync_any = state_block($fsm, 'parent_await_any_3');
    like($sync_any, qr/\(<- \(parent_wait_4_cnt cycles\) <\(& \(\| w0_done w1_done\) cycles\)\)/,
        'await_any any-done edge samples the runtime count on the positive path');
    like($sync_any, qr/\(-> parent_wait_4 <\(& \(\| w0_done w1_done\) cycles\)\)/,
        'await_any any-done edge enters the dynamic wait on a positive count');
    like($sync_any, qr/\(-> parent_done_5 <\(& \(\| w0_done w1_done\) \(== cycles 0\)\)\)/,
        'await_any any-done edge bypasses the dynamic wait on zero');
    assert_fsm_reaches_hdl($fsm, 'wait_dynamic_after_sync_any');
};

subtest 'runtime scalar waits lower inside when bodies' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'wait-dynamic-when');
(actor wait_dynamic_when
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input cond)
    (input cycles (width 4))
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (when cond
      (wait cycles)
      (drive tick))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'wait_dynamic_when.fsm'};
    my $branch = state_block($fsm, 'main_when_1');
    like($branch, qr/\(<- \(main_wait_2_cnt cycles\) <\(& cond cycles\)\)/,
        'when true edge samples the runtime count on the positive path');
    like($branch, qr/\(-> main_wait_2 <\(& cond cycles\)\)/,
        'when true edge enters the dynamic wait on a positive count');
    like($branch, qr/\(-> main_drive_3 <\(& cond \(== cycles 0\)\)\)/,
        'when true edge bypasses the dynamic wait on zero');
    like($branch, qr/\(-> main_done_4 <\(! cond\)\)/,
        'when false edge still skips the whole body');

    my $wait = state_block($fsm, 'main_wait_2');
    like($wait, qr/\(-- main_wait_2_cnt\)/, 'when-body dynamic wait decrements its sampled counter');
    like($wait, qr/\?main_wait_2_cnt[\s\S]*\(=1 \(-> main_drive_3\)\)/,
        'when-body sampled count of one exits to the following body state');
    like($wait, qr/\?main_wait_2_cnt[\s\S]*\(>1 \(-> main_wait_2\)\)/,
        'when-body sampled counts greater than one loop in the wait state');

    is_deeply(
        $report->{transaction_waits},
        [
            {
                transaction    => 'main',
                cycles         => undef,
                count_kind     => 'runtime_scalar',
                count_source   => 'cycles',
                entry_state    => 'main_wait_2',
                exit_state     => 'main_drive_3',
                counter_signal => 'main_wait_2_cnt',
                counter_width  => 4,
            },
        ],
        'when-body dynamic wait report exposes runtime count metadata',
    );

    assert_fsm_reaches_hdl($fsm, 'wait_dynamic_when');
};

subtest 'malformed wait clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing wait count', qr/\ATransaction 'main': wait requires '\(wait non_negative_integer_literal_or_constant_or_runtime_scalar\)' in transaction body/);
(actor wait_missing_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra wait operand', qr/\ATransaction 'main': wait requires '\(wait non_negative_integer_literal_or_constant_or_runtime_scalar\)' in transaction body/);
(actor wait_extra_operand
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait 1 2)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'negative wait count', qr/\ATransaction 'main': wait requires '\(wait non_negative_integer_literal_or_constant_or_runtime_scalar\)' in transaction body/);
(actor wait_negative_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait -1)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unknown dynamic wait count', qr/\ATransaction 'main': wait count 'cycles' is neither a declared actor constant nor a known-width runtime scalar in transaction body/);
(actor wait_unknown_dynamic_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait cycles)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'pending sample before when dynamic wait', qr/\ATransaction 'main': runtime dynamic wait count 'cycles' in when body cannot follow pending samples yet/);
(actor wait_when_dynamic_after_sample
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input cond) (input cycles (width 4)) (input din (width 8)) (output done))
  (transaction main
    (on start)
    (when cond
      (sample din as hold)
      (wait cycles))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'switch dynamic wait count', qr/\ATransaction 'main': runtime dynamic wait count 'cycles' is not supported in switch body in the current dynamic-wait slice/);
(actor wait_switch_dynamic_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input sel) (input cycles (width 4)) (output done))
  (transaction main
    (on start)
    (switch sel
      (0 (wait cycles)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'repeat dynamic wait count', qr/\ATransaction 'main': runtime dynamic wait count 'cycles' is not supported in repeat body in the current dynamic-wait slice/);
(actor wait_repeat_dynamic_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input cycles (width 4)) (output done))
  (transaction main
    (on start)
    (repeat 1
      (wait cycles))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'while dynamic wait count', qr/\ATransaction 'main': runtime dynamic wait count 'cycles' is not supported in while body in the current dynamic-wait slice/);
(actor wait_while_dynamic_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input cond) (input cycles (width 4)) (output done))
  (transaction main
    (on start)
    (while cond
      (wait cycles))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'until dynamic wait count', qr/\ATransaction 'main': runtime dynamic wait count 'cycles' is not supported in until body in the current dynamic-wait slice/);
(actor wait_until_dynamic_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input cond) (input cycles (width 4)) (output done))
  (transaction main
    (on start)
    (until cond
      (wait cycles))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'pending sample before dynamic wait', qr/\ATransaction 'main': runtime dynamic wait count 'cycles' in transaction body cannot follow pending samples yet/);
(actor wait_dynamic_after_sample
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input cycles (width 4)) (input din (width 8)) (output done))
  (transaction main
    (on start)
    (sample din as hold)
    (wait cycles)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'dynamic wait after loop decision', qr/\ATransaction 'main': runtime dynamic wait count 'cycles' cannot follow state 'main_while_check_3' of kind 'loop_while' in the current dynamic-wait slice/);
(actor wait_dynamic_after_loop
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input cond) (input cycles (width 4)) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (while cond
      (drive tick))
    (wait cycles)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested wait list count', qr/\ATransaction 'main': wait requires '\(wait non_negative_integer_literal_or_constant_or_runtime_scalar\)' in when body/);
(actor wait_nested_list_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input cond) (output done))
  (transaction main
    (on start)
    (when cond
      (wait (cycles)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'negative actor constant', qr/\AError: actor 'wait_bad_constant' constant 'BAD_WAIT' requires a non-negative integer literal value/);
(actor wait_bad_constant
  (clock clk)
  (reset (rst_n async active_low))
  (constants
    (BAD_WAIT -1))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait BAD_WAIT)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'rule wait action', qr/\AError: rule 'bad' action cannot use control-flow form 'wait'/);
(actor wait_rule_action
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input ready) (output wait) (output done))
  (transaction main
    (on start)
    (complete done))
  (rule bad ready
    (wait 1)))
ISF
};

done_testing();

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file    => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast     => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'wait scheduled .fsm parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'wait scheduled .fsm reaches SystemVerilog generation');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
