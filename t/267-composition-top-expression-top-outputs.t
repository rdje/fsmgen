#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    bit_vector_literal_expr
    concat_expr
    signal_ref_expr
    slice_expr
);
use FSM::Pipeline::HDLGenerator;

subtest 'pipeline and CLI emit top-expression direct top-output assignments' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_expr_top_output_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'top_expr_top_output_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_expr_top_output_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_bus<16
    status_bus<4
    serial_hi>8
    serial_flag>
    packed_status>8
    serial_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /payload_bus[15:8]/serial_hi/
    /status_bus[0]/serial_flag/
    /payload_bus[3:0],status_bus[0],status_bus[1],=2'b10/packed_status/
    /payload_bus[15:8]/uart_tx.data_in/
    /status_bus[0]/uart_tx.enable/
    /uart_tx.serial_out/serial_out/
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  enable:data
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

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'top-expression top-output wiring stays on the explicit-link C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        slice_expr('payload_bus', 15, 8),
        'pipeline preserves the typed slice binding in the realized composition plan',
    );
    is_deeply(
        $bindings{enable}{connection_expr},
        bit_select_expr('status_bus', 0),
        'pipeline preserves the typed bit-select binding in the realized composition plan',
    );

    is_deeply(
        $result->{composition_plan}->auxiliary_assignments,
        [
            '    assign serial_hi = payload_bus[15:8];',
            '    assign serial_flag = status_bus[0];',
            "    assign packed_status = {payload_bus[3:0], status_bus[0], status_bus[1], 2'b10};",
        ],
        'pipeline preserves direct top-output assignments from typed top expressions',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/assign serial_hi = payload_bus\[15:8\];/, 'generated HDL emits the direct slice-to-top-output assignment');
    like($hdl, qr/assign serial_flag = status_bus\[0\];/, 'generated HDL emits the direct bit-select-to-top-output assignment');
    like($hdl, qr/assign packed_status = \{payload_bus\[3:0\], status_bus\[0\], status_bus\[1\], 2'b10\};/, 'generated HDL emits the direct concat-to-top-output assignment');
    like($hdl, qr/\.data_in\(payload_bus\[15:8\]\)/, 'generated HDL still emits the top slice directly on the child port');
    like($hdl, qr/\.enable\(status_bus\[0\]\)/, 'generated HDL still emits the top bit-select directly on the child port');
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for pure top-expression top-output bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for direct top-expression top-output assignments');
    ok(-e $output_path, 'CLI writes HDL for direct top-expression top-output assignments');
};

subtest 'pipeline and CLI emit nested concat top-expression top-output assignments' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'nested_top_expr_top_output_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'nested_top_expr_top_output_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:nested_top_expr_top_output_top
  (?ports:public_io
    header_bus<3
    status_bus<2
    payload_bus<4
    packed_status>10
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/packed_status/
    /header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  data_in<10:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'nested top-expression top-output wiring stays on the explicit-link C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            concat_expr(
                bit_select_expr('status_bus', 0),
                bit_vector_literal_expr('10'),
            ),
            concat_expr(
                slice_expr('payload_bus', 3, 2),
                slice_expr('payload_bus', 1, 0),
            ),
        ),
        'pipeline preserves the typed nested concat binding for the child input',
    );

    is_deeply(
        $result->{composition_plan}->auxiliary_assignments,
        [
            "    assign packed_status = {header_bus, {status_bus[0], 2'b10}, {payload_bus[3:2], payload_bus[1:0]}};",
        ],
        'pipeline preserves direct top-output assignments from nested typed top expressions',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/assign packed_status = \{header_bus, \{status_bus\[0\], 2'b10\}, \{payload_bus\[3:2\], payload_bus\[1:0\]\}\};/, 'generated HDL emits the nested concat directly on the top output');
    like($hdl, qr/\.data_in\(\{header_bus, \{status_bus\[0\], 2'b10\}, \{payload_bus\[3:2\], payload_bus\[1:0\]\}\}\)/, 'generated HDL emits the nested concat directly on the child port too');
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for nested top-expression top-output bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for nested top-expression top-output assignments');
    ok(-e $output_path, 'CLI writes HDL for nested top-expression top-output assignments');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
