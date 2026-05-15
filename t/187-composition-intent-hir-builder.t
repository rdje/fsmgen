#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::ChildExportBuilder;
use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::HDLGenerator;

subtest 'intent hir builder rebuilds the bounded composition-top semantic surface from explicit inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_intent_hir_builder_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_intent_hir_builder_top
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
    my $composition_child_exports = FSM::Composition::ChildExportBuilder->build_child_exports(
        composition_plan => $result->{composition_plan},
        structural_rtl_ir => $result->{structural_rtl_ir},
        target_language => 'systemverilog',
    );
    my $generated_child_exports = FSM::Composition::ChildExportBuilder->build_generated_child_exports(
        composition_child_exports => $composition_child_exports,
    );
    my $standalone_dt_child_exports = FSM::Composition::ChildExportBuilder->build_standalone_dt_child_exports(
        composition_child_exports => $composition_child_exports,
    );
    my $rebuilt_intent_hir = FSM::IR::IntentHIRBuilder->build_from_composition_plan(
        composition_plan => $result->{composition_plan},
        composition_child_exports => $composition_child_exports,
        generated_child_exports => $generated_child_exports,
        standalone_dt_child_exports => $standalone_dt_child_exports,
        structural_rtl_ir => $result->{structural_rtl_ir},
        target_language => 'systemverilog',
    );

    is_deeply(
        $rebuilt_intent_hir->as_hashref,
        $result->{intent_hir},
        'builder rebuilds the same bounded composition-top intent_hir surface from explicit inputs',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
