#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'drive-body-boundary.isf');
}

sub lower_source {
    my ($source) = @_;
    return FSM::Scheduler::ISF->new()->lower(parse_source($source));
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        parse_source($source);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected by the parser");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'valid drive body entries preserve parser shell and lower to a drive DT' => sub {
    my $source = <<'ISF';
(actor drive_body
  (clock clk)
  (interface
    (input start)
    (output out)
    (output expr_out)
    (output done))
  (drive (set_out val)
    (out val)
    (expr_out (+ val 1)))
  (transaction main
    (on start)
    (drive set_out 1)
    (complete done)))
ISF

    my $actor = parse_source($source);
    is_deeply(
        $actor->{drives}{set_out}{body},
        [['out', 'val'], ['expr_out', ['+', 'val', '1']]],
        'drive body assignments are preserved in the actor shell',
    );

    my $fsm = lower_source($source)->{files}{'drive_body.fsm'};
    like($fsm, qr/\(<- \(out> set_out_val\) <set_out_start\)/, 'drive body lowers through the parameter signal');
    like($fsm, qr/\(<- \(expr_out> \(\+ set_out_val 1\)\) <set_out_start\)/,
        'drive body expression lowers through recursive parameter substitution');
};

subtest 'malformed drive body entries fail before actor-shell return' => sub {
    assert_parse_rejected(<<'ISF', 'scalar drive body entry', qr/\AError: drive 'pulse' body entries must be list forms/);
(actor scalar_drive_body_entry
  (clock clk)
  (interface (output out))
  (drive pulse
    out))
ISF

    assert_parse_rejected(<<'ISF', 'nested drive body lhs', qr/\AError: drive 'pulse' body entry heads must be scalar/);
(actor nested_drive_body_lhs
  (clock clk)
  (interface (output out))
  (drive pulse
    ((out) 1)))
ISF

    assert_parse_rejected(<<'ISF', 'missing drive body value', qr/\AError: drive 'pulse' body assignments require '\(port value\)'/);
(actor missing_drive_body_value
  (clock clk)
  (interface (output out))
  (drive pulse
    (out)))
ISF

    assert_parse_rejected(<<'ISF', 'extra drive body operand', qr/\AError: drive 'pulse' body assignments require '\(port value\)'/);
(actor extra_drive_body_operand
  (clock clk)
  (interface (output out))
  (drive pulse
    (out 1 now)))
ISF

};

done_testing();
