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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'assemble-clause-boundary.isf');
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

subtest 'valid assemble clause lowers to a concat assignment' => sub {
    my $result = lower_source(<<'ISF');
(actor assemble_boundary
  (clock clk)
  (interface
    (input start)
    (input header (width 4))
    (input payload (width 8))
    (output packet (width 12))
    (output done))
  (transaction main
    (on start)
    (assemble header payload as packet)
    (complete done)))
ISF

    my $fsm = $result->{files}{'assemble_boundary.fsm'};
    like($fsm, qr/\(<- \(packet> \(concat header payload\)\)\)/, 'assemble lowers to concat assignment');
};

subtest 'malformed assemble clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'assemble without parts', qr/\Aassemble requires '\(assemble part\.\.\. as target\)'/);
(actor assemble_without_parts
  (clock clk)
  (interface (input start) (output packet) (output done))
  (transaction main
    (on start)
    (assemble as packet)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'assemble without as keyword', qr/\Aassemble requires '\(assemble part\.\.\. as target\)'/);
(actor assemble_without_as
  (clock clk)
  (interface (input start) (input header) (output packet) (output done))
  (transaction main
    (on start)
    (assemble header packet)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested assemble part', qr/\Aassemble parts must be scalar names/);
(actor nested_assemble_part
  (clock clk)
  (interface (input start) (input header) (output packet) (output done))
  (transaction main
    (on start)
    (assemble (header) as packet)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested assemble target', qr/\Aassemble target must be a scalar name/);
(actor nested_assemble_target
  (clock clk)
  (interface (input start) (input header) (output packet) (output done))
  (transaction main
    (on start)
    (assemble header as (packet))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'extra assemble operand after target', qr/\Aassemble requires '\(assemble part\.\.\. as target\)'/);
(actor extra_assemble_operand
  (clock clk)
  (interface (input start) (input header) (output packet) (output done))
  (transaction main
    (on start)
    (assemble header as packet extra)
    (complete done)))
ISF
};

done_testing();
