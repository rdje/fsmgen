#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::ProvenanceReportBuilder;
use FSM::Pipeline::HDLGenerator;

subtest 'provenance report builder rebuilds the bounded composition report from forward IR inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_provenance_builder_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_provenance_builder_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
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
    my $rebuilt_report = FSM::Composition::ProvenanceReportBuilder->build_report(
        composition_plan => $result->{composition_plan},
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );

    is_deeply(
        $rebuilt_report,
        $result->{composition_report},
        'builder rebuilds the same bounded provenance report surface from explicit forward IR inputs',
    );
};

subtest 'provenance report builder projects endpoint context directly from explicit IR inputs' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_provenance_builder_context_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_provenance_builder_context_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.serial_payload/uart_tx.data_in/
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
    my $top_context = FSM::Composition::ProvenanceReportBuilder->endpoint_context(
        composition_plan => $result->{composition_plan},
        endpoint => 'serial_out',
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );
    my $child_context = FSM::Composition::ProvenanceReportBuilder->endpoint_context(
        composition_plan => $result->{composition_plan},
        endpoint => 'producer.serial_payload',
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );

    is($top_context->{kind}, 'top_port', 'builder projects top-port provenance context directly');
    is($top_context->{direction}, 'output', 'top-port context keeps structural direction metadata');
    is($child_context->{kind}, 'child_endpoint', 'builder projects child-endpoint provenance context directly');
    is($child_context->{source_root_kind}, 'dt', 'child-endpoint context keeps recovered source-root kind');
    is($child_context->{width}, 8, 'child-endpoint context keeps structural width metadata');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
