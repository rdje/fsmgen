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
    my ($source, $fsm_name) = @_;
    my $actor  = FSM::Adapter::ISF->new()->parse_source($source, 'extract-inline.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

sub lower_rejected {
    my ($source, $fsm_name) = @_;
    my $ok = eval {
        lower_source($source, $fsm_name);
        1;
    };
    return ($ok, $@);
}

subtest 'assemble target and exact extract field slices use the as-form' => sub {
    my $source = <<'ISF';
(actor extract_exact
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input packet (width 16))
    (input header (width 4))
    (input payload (width 8))
    (input crc (width 4))
    (output done)
    (output out_packet (width 16))
    (output out_header (width 4))
    (output out_payload (width 8))
    (output out_crc (width 4)))
  (transaction main
    (on start)
    (assemble header payload crc as out_packet)
    (extract packet as out_header out_payload out_crc)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'extract_exact.fsm');

    like(
        $fsm,
        qr/\(<- \(out_packet> \(concat header payload crc\)\)\)/,
        'assemble assigns the target after as',
    );
    unlike($fsm, qr/\(<- \(as /, 'assemble does not treat as as the target');

    like($fsm, qr/\(<= \(out_header> \(slice packet 15 12\)\)\)/, 'header slice is exact');
    like($fsm, qr/\(<= \(out_payload> \(slice packet 11 4\)\)\)/, 'payload slice is exact');
    like($fsm, qr/\(<= \(out_crc> \(slice packet 3 0\)\)\)/,      'crc slice is exact');
    unlike($fsm, qr/HIGH|LOW/, 'known-width extract does not emit placeholder slice bounds');
};

subtest 'extract can use assemble-inferred word width' => sub {
    my $source = <<'ISF';
(actor extract_from_assembled
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input header (width 4))
    (input payload (width 8))
    (input crc (width 4))
    (output done)
    (output out_header (width 4))
    (output out_payload (width 8))
    (output out_crc (width 4)))
  (transaction main
    (on start)
    (assemble header payload crc as packet)
    (extract packet as out_header out_payload out_crc)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'extract_from_assembled.fsm');

    like($fsm, qr/\(<= \(out_header> \(slice packet 15 12\)\)\)/, 'assembled word width drives first slice');
    like($fsm, qr/\(<= \(out_payload> \(slice packet 11 4\)\)\)/, 'assembled word width drives middle slice');
    like($fsm, qr/\(<= \(out_crc> \(slice packet 3 0\)\)\)/,      'assembled word width drives final slice');
    unlike($fsm, qr/HIGH|LOW/, 'assemble-inferred extract does not emit placeholder slice bounds');
};

subtest 'extract infers one missing field width from known source and siblings' => sub {
    my $source = <<'ISF';
(actor extract_single_unknown
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input packet (width 16))
    (input bit_in)
    (output done)
    (output header (width 4))
    (output crc (width 4)))
  (transaction main
    (on start)
    (extract packet as header payload crc)
    (shift_right payload bit_in)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'extract_single_unknown.fsm');

    like($fsm, qr/\(<= \(header> \(slice packet 15 12\)\)\)/, 'known leading field slice remains exact');
    like($fsm, qr/\(<= \(payload \(slice packet 11 4\)\)\)/, 'single unknown middle field width is inferred');
    like($fsm, qr/\(<= \(crc> \(slice packet 3 0\)\)\)/, 'known trailing field slice remains exact');
    like($fsm, qr/\(<- \(payload \(\| \(>> payload 1\) \(<< bit_in 7\)\)\)\)/,
        'later shift_right uses the inferred payload width');
    unlike($fsm, qr/HIGH|LOW|WIDTH/, 'single unknown field inference emits no placeholders');
};

subtest 'extract inference can use assemble-inferred source width' => sub {
    my $source = <<'ISF';
(actor extract_single_unknown_from_assembled
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input header (width 4))
    (input payload_in (width 8))
    (input crc (width 4))
    (input bit_in)
    (output done)
    (output out_header (width 4))
    (output out_crc (width 4)))
  (transaction main
    (on start)
    (assemble header payload_in crc as packet)
    (extract packet as out_header out_payload out_crc)
    (shift_right out_payload bit_in)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'extract_single_unknown_from_assembled.fsm');

    like($fsm, qr/\(<= \(out_header> \(slice packet 15 12\)\)\)/, 'assembled source drives known leading slice');
    like($fsm, qr/\(<= \(out_payload \(slice packet 11 4\)\)\)/, 'single unknown field is inferred from assembled source');
    like($fsm, qr/\(<= \(out_crc> \(slice packet 3 0\)\)\)/, 'assembled source drives known trailing slice');
    like($fsm, qr/\(<- \(out_payload \(\| \(>> out_payload 1\) \(<< bit_in 7\)\)\)\)/,
        'inferred width remains available after assembled-source extraction');
    unlike($fsm, qr/HIGH|LOW|WIDTH/, 'assembled-source inference emits no placeholders');
};

subtest 'extract keeps multiple unknown fields ambiguous' => sub {
    my $source = <<'ISF';
(actor extract_multiple_unknowns
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input packet (width 16))
    (output done)
    (output header (width 4)))
  (transaction main
    (on start)
    (extract packet as header payload crc)
    (complete done)))
ISF

    my ($ok, $diagnostic) = lower_rejected($source, 'extract_multiple_unknowns.fsm');

    ok(!$ok, 'multiple unknown extract fields remain rejected');
    like(
        $diagnostic,
        qr/\Aextract width for 'payload' is unknown; add an interface width or '\(widths \.\.\.\)' option/,
        'multiple unknown fields keep the existing targeted diagnostic',
    );
};

subtest 'extract rejects non-positive inferred field width' => sub {
    my $source = <<'ISF';
(actor extract_no_remaining_width
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input packet (width 8))
    (output done)
    (output header (width 4))
    (output crc (width 4)))
  (transaction main
    (on start)
    (extract packet as header payload crc)
    (complete done)))
ISF

    my ($ok, $diagnostic) = lower_rejected($source, 'extract_no_remaining_width.fsm');

    ok(!$ok, 'single unknown extract field with no remaining width is rejected');
    like(
        $diagnostic,
        qr/\Aextract known field widths sum 8 leaves no positive width for 'payload' in known width 8 source 'packet'/,
        'non-positive inferred field width diagnostic is targeted',
    );
};

subtest 'unknown extract widths fail closed instead of preserving placeholders' => sub {
    my $source = <<'ISF';
(actor extract_unknown
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (extract packet as header payload)
    (complete done)))
ISF

    my ($ok, $diagnostic) = lower_rejected($source, 'extract_unknown.fsm');

    ok(!$ok, 'unknown extract widths are rejected');
    like(
        $diagnostic,
        qr/\Aextract width for 'header' is unknown; add an interface width or '\(widths \.\.\.\)' option/,
        'unknown field width diagnostic is targeted',
    );
};

subtest 'extract rejects known source and field width disagreement' => sub {
    my $source = <<'ISF';
(actor extract_width_mismatch
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input packet (width 16))
    (output done)
    (output header (width 4))
    (output payload (width 8)))
  (transaction main
    (on start)
    (extract packet as header payload)
    (complete done)))
ISF

    my ($ok, $diagnostic) = lower_rejected($source, 'extract_width_mismatch.fsm');

    ok(!$ok, 'source/field width disagreement is rejected');
    like(
        $diagnostic,
        qr/\Aextract field widths sum 12 conflicts with known width 16 for 'packet'/,
        'source width mismatch diagnostic is targeted',
    );
};

done_testing();
