#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Backend::GeneratedModuleEmitter;
use FSM::Composition::ChildExportBuilder;
use FSM::Composition::ResultMetadataBuilder;
use FSM::Pipeline::HDLGenerator;

subtest 'result metadata builder rebuilds composition module_info and statistics from explicit inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_result_metadata_builder_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_result_metadata_builder_top
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

    my $statistics_seed = FSM::Backend::GeneratedModuleEmitter->statistics_from_generator(undef);
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $composition_child_exports = FSM::Composition::ChildExportBuilder->build_child_exports(
        composition_plan => $result->{composition_plan},
        structural_rtl_ir => $result->{structural_rtl_ir},
        target_language => 'systemverilog',
    );
    my $rebuilt_module_info = FSM::Composition::ResultMetadataBuilder->build_module_info(
        composition_plan => $result->{composition_plan},
        composition_report => $result->{composition_report},
        composition_child_exports => $composition_child_exports,
        intent_hir => $result->{intent_hir},
        lowered_rtl_ir => $result->{lowered_rtl_ir},
        structural_rtl_ir => $result->{structural_rtl_ir},
    );
    my $rebuilt_statistics = FSM::Composition::ResultMetadataBuilder->build_statistics(
        composition_plan => $result->{composition_plan},
        composition_report => $result->{composition_report},
        intent_hir => $result->{intent_hir},
        lowered_rtl_ir => $result->{lowered_rtl_ir},
        structural_rtl_ir => $result->{structural_rtl_ir},
        statistics_seed => $statistics_seed,
    );

    is_deeply(
        $rebuilt_module_info,
        $result->{module_info},
        'builder rebuilds the same bounded composition module_info surface from explicit inputs',
    );
    is_deeply(
        $rebuilt_statistics,
        $result->{statistics},
        'builder rebuilds the same bounded composition statistics surface from explicit inputs',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
