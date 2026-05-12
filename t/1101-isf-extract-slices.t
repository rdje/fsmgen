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
        qr/\(<- \(out_packet \(concat header payload crc\)\)\)/,
        'assemble assigns the target after as',
    );
    unlike($fsm, qr/\(<- \(as /, 'assemble does not treat as as the target');

    like($fsm, qr/\(<= \(out_header \(slice packet 15 12\)\)\)/,  'header slice is exact');
    like($fsm, qr/\(<= \(out_payload \(slice packet 11 4\)\)\)/,  'payload slice is exact');
    like($fsm, qr/\(<= \(out_crc \(slice packet 3 0\)\)\)/,       'crc slice is exact');
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

    like($fsm, qr/\(<= \(out_header \(slice packet 15 12\)\)\)/, 'assembled word width drives first slice');
    like($fsm, qr/\(<= \(out_payload \(slice packet 11 4\)\)\)/, 'assembled word width drives middle slice');
    like($fsm, qr/\(<= \(out_crc \(slice packet 3 0\)\)\)/,      'assembled word width drives final slice');
    unlike($fsm, qr/HIGH|LOW/, 'assemble-inferred extract does not emit placeholder slice bounds');
};

subtest 'unknown extract widths preserve placeholder slice bounds' => sub {
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

    my $fsm = lower_source($source, 'extract_unknown.fsm');

    like(
        $fsm,
        qr/\(<= \(header \(slice packet header HIGH header LOW\)\)\)/,
        'unknown first field keeps placeholder slice bounds',
    );
    like(
        $fsm,
        qr/\(<= \(payload \(slice packet payload HIGH payload LOW\)\)\)/,
        'unknown later field keeps placeholder slice bounds',
    );
};

done_testing();
