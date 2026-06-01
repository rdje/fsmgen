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

# CODEGEN-RESET-VALUE-HOLD.2
#
# A flopped register that carries a reset value must HOLD its value between writes — its
# combinational next-state default is the flop feedback (`<reg>_next = <reg>`), and the reset
# value belongs ONLY in the sequential reset branch (`<reg> <= <reset>`). A prior conflation
# used the reset literal as the comb default (`<reg>_next = <reset>`), which made the register
# revert to its reset value every cycle it was not written (simulation: a held write read back
# the reset value instead of the written value). This guards the fix at the generated-SV level.

my $tempdir = tempdir(CLEANUP => 1);

sub lower_fsm {
    my ($source, $name) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, "$name.isf");
    return FSM::Scheduler::ISF->new()->lower($actor)->{files}{"$name.fsm"};
}

sub fsm_to_hdl {
    my ($fsm_text, $name) = @_;
    my $path = File::Spec->catfile($tempdir, "$name.fsm");
    open my $fh, '>', $path or die "write $path: $!";
    print $fh $fsm_text; close $fh;
    my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
    return FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
}

subtest 'a reset-value register holds (comb default is feedback) and resets to its value' => sub {
    # x powers up at 200, is set to 5, then must retain 5 across a wait before being read out.
    my $hdl = fsm_to_hdl(lower_fsm(<<'ISF', 'hold'), 'hold');
(actor hold
  (interface (input start) (output done) (output o (width 8)))
  (transaction main
    (on start)
    (local x (width 8) (reset 200))
    (set x 5)
    (wait 3)
    (update o x)
    (complete done)))
ISF
    like($hdl, qr/\bx_next = x;/, 'comb default for x is the flop feedback (hold), not the reset literal');
    unlike($hdl, qr/\bx_next = (?:8'd)?200\b/, 'the reset literal is NOT used as the comb default');
    like($hdl, qr/\bx <= (?:8'd)?200\b/, 'the reset value still drives the sequential reset branch');
};

subtest 'a register without a reset value also holds its feedback default' => sub {
    my $hdl = fsm_to_hdl(lower_fsm(<<'ISF', 'plain'), 'plain');
(actor plain
  (interface (input start) (output done) (output o (width 8)))
  (transaction main
    (on start)
    (local y (width 8))
    (set y 7)
    (wait 2)
    (update o y)
    (complete done)))
ISF
    like($hdl, qr/\by_next = y;/, 'a no-reset register defaults to its own feedback (unchanged behavior)');
};

subtest 'a storage-var (CSR) reset value holds across a wait too' => sub {
    my $hdl = fsm_to_hdl(lower_fsm(<<'ISF', 'csr'), 'csr');
(actor csr
  (clock clk) (reset rst_n)
  (interface (input start) (input wval (width 8)) (output done) (output ctrl (width 8)))
  (storage (var mode (width 8) (reset 1)))
  (transaction main
    (on start)
    (set mode wval)
    (wait 2)
    (update ctrl mode)
    (complete done)))
ISF
    like($hdl, qr/\bmode_next = mode;/, 'storage-var mode holds its feedback between writes');
    unlike($hdl, qr/\bmode_next = (?:8'd)?1\b/, 'the storage-var reset value is not the comb default');
    like($hdl, qr/\bmode <= (?:8'd)?1\b/, 'storage-var mode still powers up at its reset value');
};

done_testing();
