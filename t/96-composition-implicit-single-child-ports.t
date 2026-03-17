#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Composition::Plan;
use FSM::Composition::Port;

my $tempdir = tempdir(CLEANUP => 1);
my $fsmc_path = File::Spec->catfile($tempdir, 'single_child_inferred_top.fsm');
my $fsmc_out_path = File::Spec->catfile($tempdir, 'single_child_inferred_top.sv');
my $rtl_path = File::Spec->catfile($tempdir, 'single_rtl_inferred_top.fsm');
my $rtl_out_path = File::Spec->catfile($tempdir, 'single_rtl_inferred_top.sv');

write_file(
    $fsmc_path,
    <<'FSM'
(?top:single_child_inferred_top
  (?fsmc:child_ctrl child_ctrl_src)
)

(?fsm:child_ctrl_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
);

write_file(
    $rtl_path,
    <<'FSM'
(?top:single_rtl_inferred_top
  (?ports)
  (?rtl:uart_tx)
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8
  txd>
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'single generated child infers top ports when ?ports is omitted' => sub {
    my $result = $pipeline->generate_hdl_from_file($fsmc_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C1', 'omitted ?ports still lands in the single-child passthrough lane');
    is(scalar(@{$result->{composition_plan}->ports}), 3, 'top ports are inferred from the realized child interface');
    isa_ok($result->{composition_plan}->ports->[0], 'FSM::Composition::Port');
    is($result->{composition_plan}->ports->[0]->name, 'clk', 'inferred top ports preserve the child clock port');
    is($result->{composition_plan}->ports->[1]->name, 'rstn', 'inferred top ports preserve the child reset port');
    is($result->{composition_plan}->ports->[2]->name, 'output_data', 'inferred top ports preserve the child data port');
    is($result->{composition_plan}->ports->[2]->direction, 'output', 'inferred top output preserves child direction');
    is($result->{composition_plan}->ports->[2]->width, 8, 'inferred top output preserves child width');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+single_child_inferred_top\s*\(/s, 'generated HDL includes the inferred top module');
    like($hdl, qr/\binput\s+clk\b/s, 'generated HDL infers clk as a top input');
    like($hdl, qr/\binput\s+rstn\b/s, 'generated HDL infers rstn as a top input');
    like($hdl, qr/\boutput\s+\[7:0\]\s+output_data\b/s, 'generated HDL infers output_data as a top output');
    like($hdl, qr/\.clk\(clk\)/s, 'generated HDL wires the child clock to the inferred top port');
    like($hdl, qr/\.rstn\(rstn\)/s, 'generated HDL wires the child reset to the inferred top port');
    like($hdl, qr/\.output_data\(output_data\)/s, 'generated HDL wires the child output to the inferred top port');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $fsmc_out_path, '--quiet', $fsmc_path],
    );
    ok($success, 'CLI succeeds when single-child passthrough infers the top interface');
    ok(-e $fsmc_out_path, 'CLI writes HDL output for omitted ?ports passthrough');
};

subtest 'single external RTL child infers top ports when ?ports is empty' => sub {
    my $result = $pipeline->generate_hdl_from_file($rtl_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C1', 'empty ?ports still lands in the single-child passthrough lane');
    is(scalar(@{$result->{composition_plan}->ports}), 4, 'top ports are inferred from the external RTL interface');
    is($result->{composition_plan}->ports->[0]->name, 'core_clk', 'inferred top ports preserve typed RTL clock name');
    is($result->{composition_plan}->ports->[1]->name, 'rst_async_n', 'inferred top ports preserve typed RTL reset name');
    is($result->{composition_plan}->ports->[2]->name, 'data_in', 'inferred top ports preserve RTL input data port');
    is($result->{composition_plan}->ports->[3]->name, 'txd', 'inferred top ports preserve RTL output data port');
    is($result->{composition_plan}->ports->[2]->direction, 'input', 'inferred RTL input preserves direction');
    is($result->{composition_plan}->ports->[2]->width, 8, 'inferred RTL input preserves width');
    is($result->{composition_plan}->ports->[3]->direction, 'output', 'inferred RTL output preserves direction');

    my $hdl = $result->{hdl_code};
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL does not regenerate the external RTL child');
    like($hdl, qr/\bmodule\s+single_rtl_inferred_top\s*\(/s, 'generated HDL includes the inferred RTL top module');
    like($hdl, qr/\binput\s+core_clk\b/s, 'generated HDL infers the typed RTL clock port');
    like($hdl, qr/\binput\s+rst_async_n\b/s, 'generated HDL infers the typed RTL reset port');
    like($hdl, qr/\binput\s+\[7:0\]\s+data_in\b/s, 'generated HDL infers the RTL data input width');
    like($hdl, qr/\boutput\s+txd\b/s, 'generated HDL infers the RTL output port');
    like($hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'generated HDL instantiates the external RTL child');
    like($hdl, qr/\.core_clk\(core_clk\)/s, 'generated HDL wires the inferred clock port deterministically');
    like($hdl, qr/\.rst_async_n\(rst_async_n\)/s, 'generated HDL wires the inferred reset port deterministically');
    like($hdl, qr/\.data_in\(data_in\)/s, 'generated HDL wires the inferred data input deterministically');
    like($hdl, qr/\.txd\(txd\)/s, 'generated HDL wires the inferred output deterministically');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $rtl_out_path, '--quiet', $rtl_path],
    );
    ok($success, 'CLI succeeds when an empty ?ports block requests inferred single-child passthrough');
    ok(-e $rtl_out_path, 'CLI writes HDL output for empty ?ports passthrough');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
