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
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'shift-right-width.isf');
    my $result = FSM::Scheduler::ISF->new()->lower($actor);
    return $result->{files}{$fsm_name};
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

subtest 'shift_right accepts explicit width for otherwise unknown register' => sub {
    my $source = <<'ISF';
(actor shift_right_width
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width 8))
    (complete done)))
ISF

    my $fsm = lower_source($source, 'shift_right_width.fsm');

    like(
        $fsm,
        qr/\(<- \(shreg \(\| \(>> shreg 1\) \(<< bit_in 7\)\)\)\)/,
        'explicit shift_right width selects the inserted MSB position',
    );
    unlike($fsm, qr/WIDTH/, 'explicit shift_right width avoids WIDTH placeholder fallback');
};

subtest 'shift_right uses known register width without explicit option' => sub {
    my $source = <<'ISF';
(actor shift_right_known_width
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input bit_in)
    (output shreg (width 8))
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in)
    (complete done)))
ISF

    my $fsm = lower_source($source, 'shift_right_known_width.fsm');

    like(
        $fsm,
        qr/\(<- \(shreg> \(\| \(>> shreg 1\) \(<< bit_in 7\)\)\)\)/,
        'known register width selects the inserted MSB position',
    );
    unlike($fsm, qr/WIDTH/, 'known-width shift_right avoids WIDTH placeholder fallback');
};

subtest 'shift_right width option rejects malformed width payloads' => sub {
    my $source = <<'ISF';
(actor bad_shift_right_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width 0))
    (complete done)))
ISF

    my $ok = eval {
        lower_source($source, 'bad_shift_right_width.fsm');
        1;
    };
    ok(!$ok, 'zero shift_right width is rejected during lowering');
    like($@, qr/shift_right width must be a positive integer/, 'malformed width diagnostic is targeted');
};

subtest 'shift_right explicit width is an assertion' => sub {
    assert_lower_rejected(<<'ISF', 'shift_right_width_conflict.fsm', 'conflicting explicit shift_right width', qr/shift_right explicit width 7 conflicts with known width 8 for 'shreg'/);
(actor shift_right_width_conflict
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output shreg (width 8))
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in (width 7))
    (complete done)))
ISF
};

subtest 'shift_right without width evidence fails closed' => sub {
    assert_lower_rejected(<<'ISF', 'shift_right_unknown_width.fsm', 'unknown shift_right width', qr/shift_right width for 'shreg' is unknown; add an interface width or '\(width N\|PARAM\|CONST\)' option/);
(actor shift_right_unknown_width
  (clock clk)
  (interface
    (input start)
    (input bit_in)
    (output done))
  (transaction main
    (on start)
    (shift_right shreg bit_in)
    (complete done)))
ISF
};

done_testing();
