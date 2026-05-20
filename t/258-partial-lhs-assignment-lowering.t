#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'partial indexed and sliced writes assemble full-width combinational and sequential mux inputs' => sub {
    my $fsm_module = parse_fsm_module(
        'partial_lhs_assignment_lowering_contract',
        <<'FSM'
(?fsm:partial_lhs_assignment_lowering_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (COND 1)
    (HI 2)
    (MID 1)
    (LO 1)
    (OUT 4)
    (RO 4)
    (RI 4)
    (RIP 4)
    (RO_HOLD 4)
    (RI_HOLD 4)
    (RIP_HOLD 4)
  )
  (idle
    (<COND
      (OUT[3:2] = HI)
      (OUT[1] = MID)
      (OUT[0] = LO)
      (RO[3:2] <- HI)
      (RO[1] <- MID)
      (RO[0] <- LO)
      (RI[3:2] <= HI)
      (RI[1] <= MID)
      (RI[0] <= LO)
      (RIP[3:2] <=- HI)
      (RIP[1] <=- MID)
      (RIP[0] <=- LO)
      (RO_HOLD[0] <- LO)
      (RI_HOLD[0] <= LO)
      (RIP_HOLD[0] <=- LO)
    )
  )
)
FSM
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);

    like(
        $hdl,
        qr/\bOUT\s*=\s*\{HI,\s*MID,\s*LO\};/s,
        'partial combinational writes assemble one full-width mux input',
    );

    like(
        $hdl,
        qr/\bRO_next\s*=\s*\{HI,\s*MID,\s*LO\};/s,
        "partial '<-' writes assemble one full-width next-value expression",
    );

    like(
        $hdl,
        qr/\bRI\s*=\s*\{HI,\s*MID,\s*LO\};/s,
        "partial '<=' writes assemble one full-width D-input expression",
    );

    like(
        $hdl,
        qr/\bRIP\s*=\s*\{HI,\s*MID,\s*LO\};/s,
        "partial '<=-' writes assemble one full-width D-input expression",
    );

    like(
        $hdl,
        qr/\bRO_HOLD_next\s*=\s*\{RO_HOLD\[3:1\],\s*LO\};/s,
        "partial '<-' writes retain untouched register bits through Q feedback",
    );

    like(
        $hdl,
        qr/\bRI_HOLD\s*=\s*\{RI_HOLD_q\[3:1\],\s*LO\};/s,
        "partial '<=' writes retain untouched register bits through q feedback",
    );

    like(
        $hdl,
        qr/\bRIP_HOLD\s*=\s*\{RIP_HOLD_q\[3:1\],\s*LO\};/s,
        "partial '<=-' writes retain untouched register bits through q feedback",
    );
};

done_testing();

sub parse_fsm_module {
    my ($basename, $fsm_text) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$basename.fsm");

    write_file($fsm_path, $fsm_text);
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    return FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
