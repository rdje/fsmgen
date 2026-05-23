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

subtest 'valid assemble clause accepts explicit part widths' => sub {
    my $result = lower_source(<<'ISF');
(actor assemble_explicit_part_widths
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (assemble header payload as packet (widths 4 8))
    (shift_right packet bit_in)
    (complete done)))
ISF

    my $fsm = $result->{files}{'assemble_explicit_part_widths.fsm'};
    like($fsm, qr/\(<- \(packet \(concat header payload\)\)\)/, 'assemble lowers to concat assignment');
    like($fsm, qr/\(<- \(packet \(\| \(>> packet 1\) \(<< bit_in 11\)\)\)\)/, 'explicit part widths derive target width evidence');
};

subtest 'assemble rejects target width mismatch when part widths are known' => sub {
    assert_lower_rejected(<<'ISF', 'assemble target width mismatch', qr/assemble part widths sum 12 conflicts with known width 13 for 'packet'/);
(actor assemble_width_mismatch
  (clock clk)
  (interface
    (input start)
    (input header (width 4))
    (input payload (width 8))
    (output packet (width 13))
    (output done))
  (transaction main
    (on start)
    (assemble header payload as packet)
    (complete done)))
ISF
};

subtest 'assemble infers one missing part width from known target and siblings' => sub {
    my $result = lower_source(<<'ISF');
(actor assemble_single_unknown_part
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (input header (width 4))
    (input crc (width 4))
    (output packet (width 16))
    (output done))
  (transaction main
    (on start)
    (assemble header payload crc as packet)
    (shift_right payload bit_in)
    (complete done)))
ISF

    my $fsm = $result->{files}{'assemble_single_unknown_part.fsm'};
    like($fsm, qr/\(<- \(packet> \(concat header payload crc\)\)\)/,
        'assemble keeps the reviewable concat expression');
    like($fsm, qr/\(<- \(payload \(\| \(>> payload 1\) \(<< bit_in 7\)\)\)\)/,
        'later shift_right uses the inferred payload width');
    unlike($fsm, qr/WIDTH/, 'single unknown assemble part inference emits no width placeholder');
};

subtest 'assemble keeps multiple unknown parts as non-evidence concat operands' => sub {
    my $result = lower_source(<<'ISF');
(actor assemble_multiple_unknown_parts
  (clock clk)
  (interface
    (input start)
    (input header (width 4))
    (output packet (width 16))
    (output done))
  (transaction main
    (on start)
    (assemble header payload crc as packet)
    (complete done)))
ISF

    my $fsm = $result->{files}{'assemble_multiple_unknown_parts.fsm'};
    like($fsm, qr/\(<- \(packet> \(concat header payload crc\)\)\)/,
        'multiple unknown assemble parts still lower as reviewable concat operands');
};

subtest 'assemble rejects non-positive inferred part width' => sub {
    assert_lower_rejected(<<'ISF', 'assemble single unknown part with no remaining width', qr/assemble known part widths sum 8 leaves no positive width for 'payload' in known width 8 target 'packet'/);
(actor assemble_no_remaining_width
  (clock clk)
  (interface
    (input start)
    (input header (width 4))
    (input crc (width 4))
    (output packet (width 8))
    (output done))
  (transaction main
    (on start)
    (assemble header payload crc as packet)
    (complete done)))
ISF
};

subtest 'malformed assemble clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'assemble without parts', qr/\Aassemble requires '\(assemble part\.\.\. as target \[\(widths N\|PARAM\|CONST\.\.\.\)\]\)'/);
(actor assemble_without_parts
  (clock clk)
  (interface (input start) (output packet) (output done))
  (transaction main
    (on start)
    (assemble as packet)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'assemble without as keyword', qr/\Aassemble requires '\(assemble part\.\.\. as target \[\(widths N\|PARAM\|CONST\.\.\.\)\]\)'/);
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

    assert_lower_rejected(<<'ISF', 'extra assemble operand after target', qr/\Aassemble optional arguments must be '\(widths N\|PARAM\|CONST\.\.\.\)'/);
(actor extra_assemble_operand
  (clock clk)
  (interface (input start) (input header) (output packet) (output done))
  (transaction main
    (on start)
    (assemble header as packet extra)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'assemble widths count mismatch', qr/\Aassemble '\(widths \.\.\.\)' count must match the part count/);
(actor assemble_width_count_mismatch
  (clock clk)
  (interface (input start) (input header) (output packet) (output done))
  (transaction main
    (on start)
    (assemble header payload as packet (widths 4))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'assemble unknown option', qr/\Aassemble optional arguments must be '\(widths N\|PARAM\|CONST\.\.\.\)'/);
(actor assemble_unknown_option
  (clock clk)
  (interface (input start) (input header) (output packet) (output done))
  (transaction main
    (on start)
    (assemble header payload as packet (width 4 8))
    (complete done)))
ISF
};

done_testing();
