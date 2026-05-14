#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'child-composition-clause-boundary.isf');
    return FSM::Scheduler::ISF->new()->lower($actor);
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

subtest 'valid do and spawn clauses lower child handshakes' => sub {
    my $result = lower_source(<<'ISF');
(actor child_composition_boundary
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction parent
    (on start)
    (do child)
    (spawn child as worker)
    (await_all done)
    (complete done))
  (transaction child
    (complete done)))
ISF

    my $fsm = $result->{files}{'child_composition_boundary.fsm'};
    like($fsm, qr/\(= \(child_start 1\)\)/, 'blocking do start is emitted');
    like($fsm, qr/\(= \(worker_start 1\)\)/, 'spawn instance start is emitted');
    ok($result->{files}{'child.fsm'}, 'spawned child file is emitted');
};

subtest 'malformed child composition clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing do target', qr/\ATransaction 'parent': do requires '\(do transaction\)' in transaction body/);
(actor do_missing_target
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (do)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested do target', qr/\ATransaction 'parent': do requires '\(do transaction\)' in transaction body/);
(actor do_nested_target
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (do (child))
    (complete done))
  (transaction child
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra do operand', qr/\ATransaction 'parent': do requires '\(do transaction\)' in transaction body/);
(actor do_extra_operand
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (do child twice)
    (complete done))
  (transaction child
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'missing spawn instance', qr/\ATransaction 'parent': spawn requires '\(spawn transaction as instance/);
(actor spawn_missing_instance
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn child)
    (complete done))
  (transaction child
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'wrong spawn separator', qr/\ATransaction 'parent': spawn requires '\(spawn transaction as instance/);
(actor spawn_wrong_separator
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn child with worker)
    (complete done))
  (transaction child
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested spawn instance', qr/\ATransaction 'parent': spawn requires '\(spawn transaction as instance/);
(actor spawn_nested_instance
  (clock clk)
  (interface (input start) (output done))
  (transaction parent
    (on start)
    (spawn child as (worker))
    (complete done))
  (transaction child
    (complete done)))
ISF
};

done_testing();
