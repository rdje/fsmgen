#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub lower_source {
    my ($source, $fsm_name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'shift-left-width.isf');
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);

    return ($result->{files}{$fsm_name}, decode_json($scheduler->report($actor)));
}

sub assert_lower_rejected {
    my ($source, $fsm_name, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source, $fsm_name);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'shift_left accepts explicit width as otherwise missing register evidence' => sub {
    my $source = <<'ISF';
(actor shift_left_width
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in (width 8))
    (shift_right shreg bit_in)
    (complete done)))
ISF

    my ($fsm, $report) = lower_source($source, 'shift_left_width.fsm');

    like(
        $fsm,
        qr/\(<- \(shreg \(\| \(<< shreg 1\) bit_in\)\)\)/,
        'explicit-width shift_left keeps the ordinary left-shift expression',
    );
    like(
        $fsm,
        qr/\(<- \(shreg \(\| \(>> shreg 1\) \(<< bit_in 7\)\)\)\)/,
        'later shift_right consumes the width evidence from shift_left',
    );
    unlike($fsm, qr/WIDTH/, 'explicit-width shift_left path leaves no WIDTH placeholder');
    assert_storage($report, 'shreg', 'register', 'data_register', 8);
};

subtest 'plain shift_left remains accepted without width evidence' => sub {
    my $source = <<'ISF';
(actor shift_left_plain
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in)
    (complete done)))
ISF

    my ($fsm) = lower_source($source, 'shift_left_plain.fsm');

    like(
        $fsm,
        qr/\(<- \(shreg \(\| \(<< shreg 1\) bit_in\)\)\)/,
        'plain shift_left still lowers without requiring width evidence',
    );
};

subtest 'nested shift_left width evidence is available to later operations' => sub {
    my $source = <<'ISF';
(actor shift_left_width_nested
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (repeat 1
      (shift_left shreg bit_in (width 8)))
    (shift_right shreg bit_in)
    (complete done)))
ISF

    my ($fsm, $report) = lower_source($source, 'shift_left_width_nested.fsm');

    like(
        $fsm,
        qr/\(<- \(shreg \(\| \(<< shreg 1\) bit_in\)\)\)/,
        'nested explicit-width shift_left keeps the ordinary left-shift expression',
    );
    like(
        $fsm,
        qr/\(<- \(shreg \(\| \(>> shreg 1\) \(<< bit_in 7\)\)\)\)/,
        'later top-level shift_right consumes nested shift_left width evidence',
    );
    assert_storage($report, 'shreg', 'register', 'data_register', 8);
};

subtest 'shift_left explicit width must agree with known register width' => sub {
    assert_lower_rejected(<<'ISF', 'shift_left_width_conflict.fsm', 'conflicting explicit shift_left width', qr/shift_left explicit width 7 conflicts with known width 8 for 'shreg'/);
(actor shift_left_width_conflict
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output shreg (width 8))
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in (width 7))
    (complete done)))
ISF
};

subtest 'shift_left width option rejects malformed payloads' => sub {
    assert_lower_rejected(<<'ISF', 'bad_shift_left_zero_width.fsm', 'zero shift_left width', qr/shift_left width must be a positive integer/);
(actor bad_shift_left_zero_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in (width 0))
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'bad_shift_left_width_option.fsm', 'unknown shift_left width option', qr/shift_left optional arguments must be '\(width N\|TX_PARAM\|PARAM\|CONST\|PACKAGE\.CONSTANT\)'/);
(actor bad_shift_left_width_option
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_left shreg bit_in (bits 8))
    (complete done)))
ISF
};

done_testing();

sub assert_storage {
    my ($report, $name, $kind, $role, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "storage entry '$name' exists");
    return unless $entry;
    is($entry->{kind}, $kind, "storage entry '$name' kind");
    is($entry->{role}, $role, "storage entry '$name' role");
    is($entry->{width}, $width, "storage entry '$name' width");
}
