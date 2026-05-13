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

done_testing();
