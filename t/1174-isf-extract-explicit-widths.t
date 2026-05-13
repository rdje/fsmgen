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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'extract-widths.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
}

subtest 'extract accepts explicit widths for otherwise unknown fields' => sub {
    my $source = <<'ISF';
(actor extract_widths
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (extract packet as header payload crc (widths 4 8 4))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'extract_widths.fsm');

    like($fsm, qr/\(<= \(header \(slice packet 15 12\)\)\)/, 'explicit widths drive first slice');
    like($fsm, qr/\(<= \(payload \(slice packet 11 4\)\)\)/, 'explicit widths drive middle slice');
    like($fsm, qr/\(<= \(crc \(slice packet 3 0\)\)\)/, 'explicit widths drive final slice');
    unlike($fsm, qr/HIGH|LOW/, 'explicit extract widths avoid placeholder slice bounds');
};

subtest 'extract width option rejects count mismatches' => sub {
    my $source = <<'ISF';
(actor bad_extract_width_count
  (clock clk)
  (interface
    (input start)
    (output done))
  (transaction main
    (on start)
    (extract packet as header payload crc (widths 4 8))
    (complete done)))
ISF

    my $ok = eval {
        lower_source($source, 'bad_extract_width_count.fsm');
        1;
    };
    ok(!$ok, 'width count mismatch is rejected during lowering');
    like($@, qr/extract '\(widths \.\.\.\)' count must match the field count/, 'count diagnostic is targeted');
};

subtest 'extract width option rejects conflicts with declared field widths' => sub {
    my $source = <<'ISF';
(actor bad_extract_width_conflict
  (clock clk)
  (interface
    (input start)
    (output done)
    (output header (width 5))
    (output payload (width 8)))
  (transaction main
    (on start)
    (extract packet as header payload (widths 4 8))
    (complete done)))
ISF

    my $ok = eval {
        lower_source($source, 'bad_extract_width_conflict.fsm');
        1;
    };
    ok(!$ok, 'declared field width conflicts are rejected during lowering');
    like($@, qr/extract explicit width for 'header' conflicts with known width/, 'conflict diagnostic is targeted');
};

done_testing();
