#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::LoweredRTLIRBuilder;
use FSM::Pipeline::HDLGenerator;

subtest 'lowered rtl ir builder rebuilds the bounded composition-top lowered surface from explicit inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_lowered_rtl_ir_builder_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_lowered_rtl_ir_builder_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?wiring:wiring
    /trigger/producer.trigger/
    /producer.serial_payload/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?dt:producer_src
  (-route
    (<trigger
      (serial_payload> = 8'1)
    )
    (<!trigger
      (serial_payload> = 8'0)
    )
  )
  (+size
    (trigger 1)
    (serial_payload 8)
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  serial_out>:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $rebuilt_lowered_rtl_ir = FSM::IR::LoweredRTLIRBuilder->build_from_composition_plan(
        composition_plan => $result->{composition_plan},
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );

    is_deeply(
        $rebuilt_lowered_rtl_ir->as_hashref,
        $result->{lowered_rtl_ir},
        'builder rebuilds the same bounded composition-top lowered_rtl_ir surface from explicit inputs',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
