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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'repeat-clause-boundary.isf');
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

subtest 'valid repeat clause lowers counter init, body, and check states' => sub {
    my $result = lower_source(<<'ISF');
(actor repeat_boundary
  (clock clk)
  (interface
    (input start)
    (output flag)
    (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat 3
      (drive tick))
    (complete done)))
ISF

    my $fsm = $result->{files}{'repeat_boundary.fsm'};
    like($fsm, qr/\(main_repeat_init_1\n\s+\(<= \(main_cnt 3\)\)/, 'repeat init loads scalar count');
    like($fsm, qr/\(= \(tick_start 1\)\)/, 'repeat body drive is emitted');
    like($fsm, qr/\(main_repeat_check_3\n\s+\(<- \(main_cnt \(- main_cnt 1\)\)\)/, 'repeat check decrements the counter');
};

subtest 'malformed repeat clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing repeat count', qr/\ATransaction 'main': repeat requires '\(repeat count body\.\.\.\)' in transaction body/);
(actor repeat_missing_count
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'missing repeat body', qr/\ATransaction 'main': repeat requires '\(repeat count body\.\.\.\)' in transaction body/);
(actor repeat_missing_body
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat 2)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested repeat count', qr/\ATransaction 'main': repeat requires '\(repeat count body\.\.\.\)' in transaction body/);
(actor repeat_nested_count
  (clock clk)
  (interface (input start) (output flag) (output done))
  (drive tick
    (flag 1))
  (transaction main
    (on start)
    (repeat (beats)
      (drive tick))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'scalar repeat body', qr/\ATransaction 'main': transaction clauses must be list forms in repeat body/);
(actor repeat_scalar_body
  (clock clk)
  (interface (input start) (output done))
  (transaction main
    (on start)
    (repeat 2 drive)
    (complete done)))
ISF
};

done_testing();
