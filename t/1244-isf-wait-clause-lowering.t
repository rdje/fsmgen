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
                entry_state    => 'main_wait_1',
                exit_state     => 'main_drive_3',
                counter_signal => undef,
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

subtest 'malformed wait clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing wait count', qr/\ATransaction 'main': wait requires '\(wait non_negative_integer_literal\)' in transaction body/);
(actor wait_missing_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra wait operand', qr/\ATransaction 'main': wait requires '\(wait non_negative_integer_literal\)' in transaction body/);
(actor wait_extra_operand
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait 1 2)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'negative wait count', qr/\ATransaction 'main': wait requires '\(wait non_negative_integer_literal\)' in transaction body/);
(actor wait_negative_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (wait -1)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'dynamic wait count', qr/\ATransaction 'main': wait requires '\(wait non_negative_integer_literal\)' in transaction body/);
(actor wait_dynamic_count
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input cycles (width 4)) (output done))
  (transaction main
    (on start)
    (wait cycles)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested wait list count', qr/\ATransaction 'main': wait requires '\(wait non_negative_integer_literal\)' in when body/);
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
