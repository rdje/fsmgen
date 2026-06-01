#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

# ISF-REGISTER-RESET-VALUES.4
#
# Register-map / CSR support: an actor-owned storage var may carry a hardware reset value
# `(storage (var NAME (width N) (reset V)))`, so a control/status register powers up at V.
# This emits the `+size` carrier `(NAME N (reset V))` (ISF-REGISTER-RESET-VALUES.2/.3) and
# flows to the HDL reset block. Unspecified -> all-0s (unchanged). Per-element bank reset
# values and over-width reset values fail closed.

sub lower_fsm {
    my ($source, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$name.isf");
    return FSM::Scheduler::ISF->new()->lower($actor)->{files}{"$name.fsm"};
}

sub parse_error {
    my ($source) = @_;
    my $ok = eval { FSM::Adapter::ISF->new()->parse_source($source, 'e.isf'); 1 };
    return $ok ? '' : $@;
}

my $tempdir = tempdir(CLEANUP => 1);
sub fsm_to_hdl {
    my ($fsm_text, $name) = @_;
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $fsm_text; close $fh;
    my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
    return FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
}

subtest 'storage var (reset V) emits the +size carrier and powers the register up at V' => sub {
    my $fsm = lower_fsm(<<'ISF', 'csr');
(actor csr
  (clock clk) (reset rst_n)
  (interface (input start) (input wval (width 8)) (output done) (output ctrl (width 8)) (output stat (width 8)))
  (storage
    (var mode (width 8) (reset 1))
    (var flags (width 8) (reset 255))
    (var scratch (width 8)))
  (transaction main
    (on start)
    (set mode wval)
    (set flags wval)
    (set scratch wval)
    (update ctrl mode)
    (update stat flags)
    (update stat scratch)
    (complete done)))
ISF
    like($fsm, qr/\(mode 8 \(reset 1\)\)/, 'mode carries (reset 1) in +size');
    like($fsm, qr/\(flags 8 \(reset 255\)\)/, 'flags carries (reset 255) in +size');
    like($fsm, qr/\(scratch 8\)/, 'scratch (no reset) has no carrier');

    my $hdl = fsm_to_hdl($fsm, 'csr');
    # the reset-literal rendering (bare `255` vs width-qualified `8'd1`) is the HDL backend's;
    # the values are what matter, so accept either spelling.
    like($hdl, qr/\bmode <= (?:8'd)?1\b/, 'mode powers up at 1');
    like($hdl, qr/\bflags <= (?:8'd)?255\b/, 'flags powers up at 255');
    like($hdl, qr/\bscratch <= (?:8'b0+|8'd0|8'h0+)\b/, 'scratch (unspecified) resets to all-0s');
};

subtest 'a per-element bank reset value fails closed' => sub {
    my $err = parse_error(
        "(actor t (clock clk) (reset rst_n) (interface (input start) (output done)) "
        . "(storage (bank b (width 8) (depth 4) (reset 1))) "
        . "(transaction main (on start) (complete done)))");
    like($err, qr/storage bank 'b' does not accept '\(reset V\)'/, 'a bank (reset V) is rejected');
};

subtest 'an over-width or non-integer storage reset value fails closed' => sub {
    my $over = parse_error(
        "(actor t (clock clk) (reset rst_n) (interface (input start) (output done)) "
        . "(storage (var v (width 4) (reset 99))) "
        . "(transaction main (on start) (complete done)))");
    like($over, qr/storage var 'v' reset value 99 does not fit in 4 bit/, 'an over-width reset value is rejected');

    my $nonint = parse_error(
        "(actor t (clock clk) (reset rst_n) (interface (input start) (output done)) "
        . "(storage (var v (width 8) (reset foo))) "
        . "(transaction main (on start) (complete done)))");
    like($nonint, qr/storage 'v' reset requires '\(reset V\)' with a non-negative integer literal/,
        'a non-integer reset value is rejected');
};

done_testing();
