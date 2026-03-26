#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::RTLChildRealizer;
use FSM::Composition::RealizedInstance;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

subtest 'rtl child realizer owns embedded ?rtlif realization' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'rtl_child_realizer_embedded_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:rtl_child_realizer_embedded_top
  (?ports:public_io
    core_clk
    rst_async_n
    data_in<8
    txd>
  )
  (?rtl:uart_tx)
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  txd>:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $composition_path,
        debug_level => 0,
    );
    my $composition_spec = FSM::Pipeline::SourceFrontend->parse_composition_source(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
    my $instance = $composition_spec->top->instances->[0];
    my $realized = FSM::Composition::RTLChildRealizer->realize_rtl_child_instance(
        rtl_interface_loader => $pipeline->{rtl_interface_loader},
        instance => $instance,
        composition_spec => $composition_spec,
        fsm_file => $composition_path,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $planned_instance = $result->{composition_plan}->instances->[0];

    isa_ok($realized, 'FSM::Composition::RealizedInstance');
    is($realized->kind, 'rtl', 'realizer keeps the rtl kind');
    is($realized->instance_name, $planned_instance->instance_name, 'realizer keeps the rtl instance name');
    is($realized->module_name, $planned_instance->module_name, 'realizer keeps the rtl module name');
    is($realized->module_info->{metadata_path}, "$composition_path:?rtlif:uart_tx", 'realizer preserves embedded ?rtlif provenance');
    is($realized->module_info->{metadata_path}, $planned_instance->module_info->{metadata_path}, 'realizer matches the planned embedded metadata provenance');
    is($realized->module_info->{interface_kind}, 'rtl_external', 'realizer preserves the rtl interface kind');
    is_deeply(port_snapshot($realized), port_snapshot($planned_instance), 'realizer owns the embedded rtl interface projection');
    is($realized->hdl_code, undef, 'realizer does not invent child HDL for external rtl modules');
};

subtest 'rtl child realizer owns sidecar .rtlif realization' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'rtl_child_realizer_sidecar_top.fsm');
    my $sidecar_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:rtl_child_realizer_sidecar_top
  (?ports:public_io
    clk
    rst_n
    data_in<8
    txd>
  )
  (?rtl:uart_tx)
)
FSM
    );

    write_file(
        $sidecar_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rst_n:reset
  data_in<8:data
  txd>:data
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $composition_path,
        debug_level => 0,
    );
    my $composition_spec = FSM::Pipeline::SourceFrontend->parse_composition_source(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
    my $instance = $composition_spec->top->instances->[0];
    my $realized = FSM::Composition::RTLChildRealizer->realize_rtl_child_instance(
        rtl_interface_loader => $pipeline->{rtl_interface_loader},
        instance => $instance,
        composition_spec => $composition_spec,
        fsm_file => $composition_path,
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $planned_instance = $result->{composition_plan}->instances->[0];

    isa_ok($realized, 'FSM::Composition::RealizedInstance');
    is($realized->kind, 'rtl', 'realizer keeps the sidecar rtl kind');
    is($realized->instance_name, $planned_instance->instance_name, 'realizer keeps the sidecar rtl instance name');
    is($realized->module_name, $planned_instance->module_name, 'realizer keeps the sidecar rtl module name');
    is($realized->module_info->{metadata_path}, $sidecar_path, 'realizer preserves sidecar .rtlif provenance');
    is($realized->module_info->{metadata_path}, $planned_instance->module_info->{metadata_path}, 'realizer matches the planned sidecar metadata provenance');
    is($realized->module_info->{interface_kind}, 'rtl_external', 'realizer preserves the sidecar rtl interface kind');
    is_deeply(port_snapshot($realized), port_snapshot($planned_instance), 'realizer owns the sidecar rtl interface projection');
    is($realized->hdl_code, undef, 'realizer does not invent sidecar child HDL for external rtl modules');
};

done_testing();

sub port_snapshot {
    my ($instance) = @_;
    return [
        map {
            {
                name => $_->name,
                direction => $_->direction,
                width => $_->width,
                type => $_->type,
            }
        } @{$instance->interface_ports || []}
    ];
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
