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
    my $child_expr_context = FSM::Composition::ProvenanceReportBuilder->endpoint_context(
        composition_plan => $result->{composition_plan},
        endpoint => 'producer.serial_payload[7:0]',
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );

    is($top_context->{kind}, 'top_port', 'builder projects top-port provenance context directly');
    is($top_context->{direction}, 'output', 'top-port context keeps structural direction metadata');
    is($child_context->{kind}, 'child_endpoint', 'builder projects child-endpoint provenance context directly');
    is($child_context->{source_root_kind}, 'dt', 'child-endpoint context keeps recovered source-root kind');
    is($child_context->{width}, 8, 'child-endpoint context keeps structural width metadata');
    is($child_expr_context->{kind}, 'child_expression', 'builder projects child-expression provenance context directly');
    is($child_expr_context->{width}, 8, 'child-expression context keeps the projected structural width');
    is($child_expr_context->{base_endpoint}, 'producer.serial_payload', 'child-expression context keeps the base child endpoint');
};

subtest 'provenance report builder projects typed aggregate expression widths' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_provenance_builder_aggregate_context_top.fsm');
    my $rtl_metadata_path = File::Spec->catfile($tempdir, 'sink.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_provenance_builder_aggregate_context_top
  (+types
    (type pair_t (list bit (bits 4) bit))
    (type frame_t (record (tag (bits 4)) (flag bit) (payload pair_t)))
  )
  (?ports:public_io
    in_frame<frame_t
    tag_out>4
  )
  (?dtc:producer producer_src)
  (?rtl:sink)
  (?toplink:wiring
    /in_frame.tag/tag_out/
    /in_frame.payload[1]/sink.top_nibble/
    /producer.OUT_FRAME.payload[1]/sink.child_nibble/
    /producer.OUT_FRAME.flag/sink.child_flag/
  )
)

(?dt:producer_src
  (+types
    (type pair_t (list bit (bits 4) bit))
    (type frame_t (record (tag (bits 4)) (flag bit) (payload pair_t)))
  )
  (+size
    (OUT_FRAME frame_t)
  )
  (-pass
    (OUT_FRAME = 11'b10100111100)
  )
)
FSM
    );

    write_file(
        $rtl_metadata_path,
        <<'RTLIF'
(?rtlif:sink
  top_nibble<4:data
  child_nibble<4:data
  child_flag<1:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $top_member_context = FSM::Composition::ProvenanceReportBuilder->endpoint_context(
        composition_plan => $result->{composition_plan},
        endpoint => 'in_frame.tag',
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );
    my $top_list_item_context = FSM::Composition::ProvenanceReportBuilder->endpoint_context(
        composition_plan => $result->{composition_plan},
        endpoint => 'in_frame.payload[1]',
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );
    my $child_list_item_context = FSM::Composition::ProvenanceReportBuilder->endpoint_context(
        composition_plan => $result->{composition_plan},
        endpoint => 'producer.OUT_FRAME.payload[1]',
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );
    my $child_flag_context = FSM::Composition::ProvenanceReportBuilder->endpoint_context(
        composition_plan => $result->{composition_plan},
        endpoint => 'producer.OUT_FRAME.flag',
        structural_rtl_ir => $result->{structural_rtl_ir},
        intent_hir => $result->{intent_hir},
        target_language => 'systemverilog',
    );

    is($top_member_context->{kind}, 'top_expression', 'builder classifies top aggregate member access as a top expression');
    is($top_member_context->{width}, 4, 'top aggregate record member context keeps resolved leaf width');
    is($top_member_context->{expression_type_spec}{width}, 4, 'top aggregate record member context keeps resolved leaf type');
    is($top_list_item_context->{width}, 4, 'top aggregate list item context keeps resolved item width');
    is($top_list_item_context->{expression_type_spec}{kind}, 'bits', 'top aggregate list item context keeps resolved item type');
    is($child_list_item_context->{kind}, 'child_expression', 'builder classifies child aggregate item access as a child expression');
    is($child_list_item_context->{base_endpoint}, 'producer.OUT_FRAME', 'child aggregate item context keeps the base endpoint');
    is($child_list_item_context->{width}, 4, 'child aggregate list item context keeps resolved item width');
    is($child_list_item_context->{expression_type_spec}{width}, 4, 'child aggregate list item context keeps resolved item type');
    is($child_flag_context->{width}, 1, 'child aggregate record member context keeps resolved one-bit leaf width');
    is($child_flag_context->{expression_type_spec}{kind}, 'bit', 'child aggregate record member context keeps resolved bit leaf type');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
