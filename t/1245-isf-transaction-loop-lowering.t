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

subtest 'while and until lower to explicit scheduled loop regions' => sub {
    my ($lowered, $report) = lower_source(<<'ISF', 'loop-boundary');
(actor loop_boundary
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input keep)
    (input done_seen)
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (while keep
      (drive tick)
      (wait 1))
    (until done_seen
      (drive tick)
      (wait 1))
    (complete done)))
ISF

    my $fsm = $lowered->{files}{'loop_boundary.fsm'};
    my $while_entry = state_block($fsm, 'main_while_entry_1');
    my $while_back = state_block($fsm, 'main_while_check_4');
    my $until_check = state_block($fsm, 'main_until_check_7');

    like($while_entry, qr/\(\?keep\s+\(=1 \(-> main_drive_2\)\)\s+\(=0 \(-> main_drive_5\)\)\s+\)/s,
        'while entry samples the condition before the first possible iteration');
    like(state_block($fsm, 'main_wait_3'), qr/\(-> main_while_check_4\)/,
        'while body returns to the back-edge decision after its final body state');
    like($while_back, qr/\(\?keep\s+\(=1 \(-> main_drive_2\)\)\s+\(=0 \(-> main_drive_5\)\)\s+\)/s,
        'while back-edge decision samples the condition before each later iteration');
    like($until_check, qr/\(\?done_seen\s+\(=1 \(-> main_done_8\)\)\s+\(=0 \(-> main_drive_5\)\)\s+\)/s,
        'until check exits on true and loops back to the body on false');

    is_deeply(
        $report->{transaction_loops},
        [
            {
                transaction       => 'main',
                kind              => 'while',
                condition         => 'keep',
                entry_state       => 'main_while_entry_1',
                decision_states   => [qw(main_while_entry_1 main_while_check_4)],
                body_start        => 'main_drive_2',
                body_states       => [qw(main_drive_2 main_wait_3)],
                exit_state        => 'main_drive_5',
                body_clause_count => 2,
            },
            {
                transaction       => 'main',
                kind              => 'until',
                condition         => 'done_seen',
                entry_state       => 'main_drive_5',
                decision_states   => ['main_until_check_7'],
                body_start        => 'main_drive_5',
                body_states       => [qw(main_drive_5 main_wait_6)],
                exit_state        => 'main_done_8',
                body_clause_count => 2,
            },
        ],
        'schedule report exposes bounded loop provenance',
    );

    assert_fsm_reaches_hdl($fsm, 'loop_boundary');
};

subtest 'malformed and unsupported loop shapes fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing while condition', qr/\ATransaction 'main': while requires '\(while condition body\.\.\.\)' in transaction body/);
(actor loop_missing_condition
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (output done))
  (transaction main
    (on start)
    (while)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'missing until body', qr/\ATransaction 'main': until requires '\(until condition body\.\.\.\)' in transaction body/);
(actor loop_missing_body
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input done_seen) (output done))
  (transaction main
    (on start)
    (until done_seen)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'scalar loop body', qr/\ATransaction 'main': while body clauses must be non-empty list forms in transaction body/);
(actor loop_scalar_body
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input keep) (output done))
  (transaction main
    (on start)
    (while keep drive)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'empty loop body clause', qr/\ATransaction 'main': while body clauses must be non-empty list forms in transaction body/);
(actor loop_empty_body_clause
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input keep) (output done))
  (transaction main
    (on start)
    (while keep
      ())
    (complete done)))
ISF

    # A plain or bound local `(do child)` in a while body now lowers (conditional
    # one-shot activation, ISF-CONDITIONAL-CHILD-ACTIVATION; covered by t/1388). A
    # GENERATED conditional `(do child (params ...))` in a loop body is still
    # deferred.
    assert_lower_rejected(<<'ISF', 'generated child call loop body', qr/\ATransaction 'main': while body generated '\(do child \.\.\.\)' is not yet supported/);
(actor loop_child_call
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input keep) (input din (width 8)) (output done) (output cdone (width 8)))
  (transaction child
    (params (W 8))
    (on start)
    (ports (input data (width W)))
    (update cdone data)
    (complete cdone))
  (transaction main
    (on start)
    (while keep
      (do child
        (params (W 8))
        (bind (input data din))))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested loop body', qr/\ATransaction 'main': unsupported '\(until \.\.\.\)' clause in while body/);
(actor loop_nested_loop
  (clock clk)
  (reset (rst_n async active_low))
  (interface (input start) (input keep) (input done_seen) (output done))
  (transaction main
    (on start)
    (while keep
      (until done_seen
        (wait 1)))
    (complete done)))
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
    ok($fsm_module, 'loop scheduled .fsm parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'loop scheduled .fsm reaches SystemVerilog generation');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
