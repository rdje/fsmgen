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

subtest 'standalone dt roots accept conventional explicit +system and keep rstn visible in generated HDL' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $dt_path = File::Spec->catfile($tempdir, 'explicit_system_dt_root.fsm');

    write_file(
        $dt_path,
        <<'FSM'
(?dt:explicit_system_dt_root
  (+system
    (clock clk)
    (asreset rstn)
  )
  (+size
    (data_in 8)
    (result_data 8)
  )
  (:= result_data=8'0)
  (-capture
    (result_data <- data_in)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($dt_path);

    is($result->{source_info}{kind}, 'dt', 'explicit-system standalone root stays a dt source');
    is($result->{fsm_module}->source_root_kind, 'dt', 'parsed module keeps dt source kind');
    ok($result->{fsm_module}->requires_implicit_system_ports, 'explicit system contract still causes system ports to be declared');
    is($result->{fsm_module}->effective_system_contract->{clock}, 'clk', 'explicit standalone dt root keeps clk');
    is($result->{fsm_module}->effective_system_contract->{reset}, 'rstn', 'explicit standalone dt root keeps rstn');
    ok(!$result->{fsm_module}->effective_system_contract->{implicit}, 'explicit standalone dt system contract is not marked implicit');
    is($result->{module_info}->{system_contract}->{reset}, 'rstn', 'module info keeps explicit rstn reset');
    ok($result->{module_info}->{system_contract}->{declare_ports}, 'module info still declares explicit system ports');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+explicit_system_dt_root\b/s, 'generated HDL includes the standalone dt module');
    like($hdl, qr/\binput\s+wire\s+clk\b/s, 'generated HDL exposes clk');
    like($hdl, qr/\binput\s+wire\s+rstn\b/s, 'generated HDL exposes explicit rstn');
    unlike($hdl, qr/\binput\s+wire\s+rst_n\b/s, 'generated HDL does not silently rename explicit rstn to rst_n');
    like($hdl, qr/always_ff\s*@\(posedge\s+clk\s+or\s+negedge\s+rstn\)/s, 'generated HDL uses explicit rstn in sequential logic');
    unlike($hdl, qr/\bcurrent_state\b/s, 'standalone dt root still does not synthesize current_state');
};

subtest 'composition auto-wires explicit standalone-dt system ports through dtc children' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'explicit_system_dt_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'explicit_system_dt_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:explicit_system_dt_child_top
  (?ports:public_io
    clk
    rstn
    data_in<8
    result_data>8
  )
  (?dtc:router route_src)
)

(?dt:route_src
  (+system
    (clock clk)
    (asreset rstn)
  )
  (+size
    (data_in 8)
    (result_data 8)
  )
  (:= result_data=8'0)
  (-capture
    (result_data <- data_in)
  )
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
    is($result->{composition_plan}->lane, 'C1', 'single-child explicit-system dt child still uses C1 lane');
    is($result->{composition_plan}->instances->[0]->kind, 'dtc', 'realized child stays dtc');
    is_deeply(
        [map { $_->name } @{$result->{composition_plan}->instances->[0]->interface_ports}],
        ['clk', 'rstn', 'data_in', 'result_data'],
        'explicit standalone dt child exposes clk/rstn beside its data interface',
    );

    my %router_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is($router_bindings{clk}, 'clk', 'dt child clock is auto-wired from the top system input');
    is($router_bindings{rstn}, 'rstn', 'dt child reset is auto-wired from the top system input');
    is($router_bindings{data_in}, 'data_in', 'dt child data input is wired directly');
    is($router_bindings{result_data}, 'result_data', 'dt child output is wired directly');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+route_src\b/s, 'generated HDL includes the dt child module');
    like($hdl, qr/\bmodule\s+explicit_system_dt_child_top\b/s, 'generated HDL includes the top module');
    like($hdl, qr/\binput\s+rstn\b/s, 'top module exposes rstn for the explicit-system dt child');
    unlike($hdl, qr/\binput\s+rst_n\b/s, 'top module does not invent rst_n beside explicit rstn');
    like($hdl, qr/\.clk\(clk\)/s, 'top wires clk to the dt child');
    like($hdl, qr/\.rstn\(rstn\)/s, 'top wires rstn to the dt child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for composition with an explicit-system dt child');
    ok(-e $output_path, 'CLI writes HDL for composition with an explicit-system dt child');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
