#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

subtest 'spawn parameter bindings preserve instance overrides and child defaults' => sub {
    my $source = <<'ISF';
(actor spawn_parameter_binding
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH 16)
        (LANES (8'hA5 8'h3C))))
    (spawn worker as w1)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8)
      (LANES (8'h00 8'h00)))
    (complete done)))
ISF

    my $actor = parse_source($source);
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);

    is_deeply(
        $ir->{spawn_instances},
        [
            {
                child => 'worker',
                instance => 'w0',
                drive_handoffs => [],
                parameter_overrides => [
                    { name => 'WIDTH', value => '16' },
                    { name => 'LANES', value => ["8'hA5", "8'h3C"] },
                ],
            },
            {
                child => 'worker',
                instance => 'w1',
                drive_handoffs => [],
                parameter_overrides => [],
            },
        ],
        'parent IR preserves per-instance spawn parameter override metadata',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $parent_fsm = $lowered->{files}{'spawn_parameter_binding.fsm'};
    my $child_fsm = $lowered->{files}{'worker.fsm'};
    my $top_fsm = $lowered->{files}{'spawn_parameter_binding_top.fsm'};

    ok(defined($parent_fsm), 'parent scheduled .fsm is emitted');
    ok(defined($child_fsm), 'spawned child scheduled .fsm is emitted');
    ok(defined($top_fsm), 'generated top .fsm is emitted');
    like($parent_fsm, qr/\(= \(w0_start> 1\)\)/, 'parent exposes the first spawn instance start');
    like($parent_fsm, qr/\(= \(w1_start> 1\)\)/, 'parent exposes the second spawn instance start');
    like($child_fsm, qr/\(\+params\s+\(WIDTH 8\)\s+\(LANES \(8'h00 8'h00\)\)\s+\)/s, 'child .fsm emits transaction parameter defaults');
    like($top_fsm, qr/\(\?fsmc:w0 worker\s+\(params\s+\(WIDTH 16\)\s+\(LANES \(8'hA5 8'h3C\)\)\s+\)\s+\)/s, 'generated top applies per-instance spawn parameter overrides');
};

subtest 'spawn parameter bindings fail closed for unsupported or ambiguous shapes' => sub {
    assert_lower_rejected(<<'ISF', 'duplicate spawn instance name', qr/duplicate spawn instance 'w0'/);
(actor duplicate_spawn_instance
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'unknown spawn override name', qr/overrides unknown parameter 'MODE'/);
(actor unknown_spawn_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (MODE 1)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'aggregate override scalar mismatch', qr/shape does not match child 'worker' declaration/);
(actor aggregate_scalar_mismatch
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (LANES 3)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (LANES (1 2)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'aggregate override length mismatch', qr/shape does not match child 'worker' declaration/);
(actor aggregate_length_mismatch
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (LANES (3 4 5))))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (LANES (1 2)))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'duplicate transaction parameter declaration', qr/duplicate parameter 'WIDTH'/);
(actor duplicate_transaction_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8)
      (WIDTH 16))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'invalid transaction parameter name', qr/parameter names must be scalar HDL identifiers/);
(actor invalid_transaction_parameter_name
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (1WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'duplicate spawn parameter override', qr/duplicate parameter override 'WIDTH'/);
(actor duplicate_spawn_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH 16)
        (WIDTH 32)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'invalid spawn parameter override name', qr/spawn parameter override names must be scalar HDL identifiers/);
(actor invalid_spawn_parameter_name
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (1WIDTH 16)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'symbolic spawn parameter override', qr/unsupported parameter value 'TOP_WIDTH'/);
(actor symbolic_spawn_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH TOP_WIDTH)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'multiple spawn parameter blocks', qr/spawn has duplicate 'params' subclause/);
(actor multiple_spawn_parameter_blocks
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0
      (params
        (WIDTH 16))
      (params
        (WIDTH 32)))
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'multiple transaction parameter blocks', qr/transaction parameters allow at most one '\(params \.\.\.\)' clause/);
(actor multiple_transaction_parameter_blocks
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn worker as w0)
    (await_all done)
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (params
      (LANES 2))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'non-spawned transaction parameter declaration', qr/params are supported only on spawned child transactions/);
(actor non_spawned_transaction_parameter
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (params
      (WIDTH 8))
    (on start)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'parameterized do remains unsupported', qr/activation supports only '\(bind \.\.\.\)' subclauses/);
(actor parameterized_do
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (do worker
      (params
        (WIDTH 16)))
    (complete done))
  (transaction worker
    (params
      (WIDTH 8))
    (complete done)))
ISF
};

done_testing();

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'spawn-parameter-binding.isf');
}

sub lower_source {
    my ($source) = @_;
    return FSM::Scheduler::ISF->new()->lower(parse_source($source));
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}
