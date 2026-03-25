#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::GeneratedChildRealizer;
use FSM::Composition::RealizedInstance;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'generated child realizer owns embedded ?fsmc realization' => sub {
    my $composition_path = write_fsm('generated_child_realizer_fsmc_top.fsm', <<'FSM');
(?top:generated_child_realizer_fsmc_top
  (?ports:public_io
    clk
    rst_n
    trigger
    data_out>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (-idle
    (<trigger
      (data_out> <= 8'1)
    )
    (<!trigger
      (data_out> <= 8'0)
    )
  )
  (+size
    (data_out 8)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $raw_ast = $pipeline->parse_fsm_file($composition_path);
    my $source_info = $pipeline->classify_source_ast($raw_ast);
    my $composition_spec = $pipeline->parse_composition_source($raw_ast);
    my $instance = $composition_spec->top->instances->[0];
    my $realized = FSM::Composition::GeneratedChildRealizer->realize_fsmc_child_instance(
        pipeline => $pipeline,
        instance => $instance,
        composition_spec => $composition_spec,
        fsm_file => $composition_path,
        header => $source_info->{header},
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $planned_instance = $result->{composition_plan}->instances->[0];

    isa_ok($realized, 'FSM::Composition::RealizedInstance');
    is($realized->kind, 'fsmc', 'realizer keeps the fsmc kind');
    is($realized->instance_name, $planned_instance->instance_name, 'realizer keeps the declared child instance name');
    is($realized->module_name, $planned_instance->module_name, 'realizer keeps the generated child module name');
    is($realized->source_name, $planned_instance->source_name, 'realizer keeps the child source name');
    is($realized->module_info->{shared_datapath_source_export_count}, $planned_instance->module_info->{shared_datapath_source_export_count}, 'realizer owns shared-datapath source-export count for realized fsmc children');
    is_deeply($realized->module_info->{shared_datapath_source_exports}, $planned_instance->module_info->{shared_datapath_source_exports}, 'realizer owns shared-datapath source-export metadata for realized fsmc children');
    is_deeply($realized->module_info->{structural_rtl_ir}, $planned_instance->module_info->{structural_rtl_ir}, 'realizer preserves the generated child structural rtl ir surface');
    like($realized->hdl_code, qr/\bmodule\s+child_src\b/s, 'realizer emits the expected fsm child module name');
    like($realized->hdl_code, qr/shared_dp_export_data_out_8_d0_en/s, 'realizer augments generated fsm child hdl with shared-datapath export ports');
    like($realized->hdl_code, qr/assign shared_dp_export_data_out_8_d1_en = data_out__8_d1_en;/s, 'realizer augments generated fsm child hdl with shared-datapath export assignments');
};

subtest 'generated child realizer owns external ?dtc realization' => sub {
    my $libdir = tempdir(CLEANUP => 1);
    my $composition_path = write_fsm('generated_child_realizer_dtc_top.fsm', <<'FSM');
(?top:generated_child_realizer_dtc_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:router route_src)
)
FSM

    write_file(
        File::Spec->catfile($libdir, 'route_src.fsm'),
        <<'FSM'
(?dt:route_src
  (-route
    (result_data> = data_in)
  )
  (+size
    (data_in 8)
    (result_data 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        source_search_paths => [$libdir],
    );

    my $raw_ast = $pipeline->parse_fsm_file($composition_path);
    my $source_info = $pipeline->classify_source_ast($raw_ast);
    my $composition_spec = $pipeline->parse_composition_source($raw_ast);
    my $instance = $composition_spec->top->instances->[0];
    my $realized = FSM::Composition::GeneratedChildRealizer->realize_dtc_child_instance(
        pipeline => $pipeline,
        instance => $instance,
        composition_spec => $composition_spec,
        fsm_file => $composition_path,
        header => $source_info->{header},
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $planned_instance = $result->{composition_plan}->instances->[0];

    isa_ok($realized, 'FSM::Composition::RealizedInstance');
    is($realized->kind, 'dtc', 'realizer keeps the dtc kind');
    is($realized->instance_name, $planned_instance->instance_name, 'realizer keeps the declared dt child instance name');
    is($realized->module_name, $planned_instance->module_name, 'realizer keeps the realized dt child module name');
    is($realized->source_name, $planned_instance->source_name, 'realizer keeps the dt child source name');
    is_deeply(
        [ map { $_->name } @{$realized->interface_ports || []} ],
        [ map { $_->name } @{$planned_instance->interface_ports || []} ],
        'realizer owns the realized dt child interface projection',
    );
    is_deeply($realized->module_info->{structural_rtl_ir}, $planned_instance->module_info->{structural_rtl_ir}, 'realizer preserves the realized dt child structural rtl ir surface');
    like($realized->hdl_code, qr/\bmodule\s+route_src\b/s, 'realizer emits the expected dt child module name');
    like($realized->hdl_code, qr/\bresult_data\b/s, 'realizer keeps the dt child data-path hdl payload');
};

done_testing();

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    write_file($path, $content);
    return $path;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
