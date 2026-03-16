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
use FSM::Composition::Net;

subtest 'single-child composition realizes embedded combinational dt child without fake system ports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'comb_dt_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'comb_dt_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:comb_dt_child_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:router route_src)
)

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
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C1', 'embedded combinational dt child uses C1 lane');
    is($result->{composition_plan}->instances->[0]->kind, 'dtc', 'realized child keeps dtc kind');
    is_deeply(
        [map { $_->name } @{$result->{composition_plan}->instances->[0]->interface_ports}],
        ['data_in', 'result_data'],
        'combinational dt child interface does not grow fake clk/rst_n ports',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+route_src\b/s, 'generated HDL includes embedded dt child module');
    like($hdl, qr/\bmodule\s+comb_dt_child_top\b/s, 'generated HDL includes top module');
    unlike($hdl, qr/\binput\s+clk\b/s, 'top module does not declare a fake clk input for combinational dt child');
    unlike($hdl, qr/\binput\s+rst_n\b/s, 'top module does not declare a fake rst_n input for combinational dt child');
    like($hdl, qr/\.data_in\(data_in\)/s, 'top wires dt child input directly');
    like($hdl, qr/\.result_data\(result_data\)/s, 'top wires dt child output directly');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for embedded combinational dt child composition');
    ok(-e $output_path, 'CLI writes HDL for embedded combinational dt child composition');
};

subtest 'multi-child composition supports mixed fsmc and dtc generated children' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'mixed_generated_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'mixed_generated_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:mixed_generated_child_top
  (?ports:public_io
    clk
    rst_n
    final_data>8
  )
  (?fsmc:producer producer_src)
  (?dtc:router route_src)
  (?toplink:wiring
    /producer.output_data/router.data_in/
    /router.final_data/final_data/
  )
)

(?fsm:producer_src
  (-state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
  )
)

(?dt:route_src
  (-route
    (final_data> = data_in)
  )
  (+size
    (data_in 8)
    (final_data 8)
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
    is($result->{composition_plan}->lane, 'C2', 'mixed fsmc + dtc composition uses C2 lane');
    is($result->{composition_plan}->instances->[0]->kind, 'fsmc', 'first realized child stays fsmc');
    is($result->{composition_plan}->instances->[1]->kind, 'dtc', 'second realized child is dtc');
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'mixed generated-child composition still materializes one deterministic net');
    isa_ok($result->{composition_plan}->nets->[0], 'FSM::Composition::Net');

    my %router_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};
    ok(!exists $router_bindings{clk}, 'combinational dt child does not receive a fake clk binding');
    ok(!exists $router_bindings{rst_n}, 'combinational dt child does not receive a fake rst_n binding');
    is($router_bindings{data_in}, 'comp_link_producer_output_data', 'dt child input is fed from the deterministic net');
    is($router_bindings{final_data}, 'final_data', 'dt child output is wired directly to the top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+producer_src\b/s, 'generated HDL includes producer FSM module');
    like($hdl, qr/\bmodule\s+route_src\b/s, 'generated HDL includes dt child module');
    like($hdl, qr/\bwire\s+\[7:0\]\s+comp_link_producer_output_data;/s, 'generated top includes deterministic link net');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for mixed fsmc + dtc composition');
    ok(-e $output_path, 'CLI writes HDL for mixed fsmc + dtc composition');
};

subtest 'mixed dtc plus rtl composition resolves external dt child through --path' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'dt_plus_rtl_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'dt_plus_rtl_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:dt_plus_rtl_top
  (?ports:public_io
    clk
    rst_n
    data_in<8
    serial_out>
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /data_in/router.data_in/
    /router.route_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)
FSM
    );

    write_file(
        File::Spec->catfile($libdir, 'route_src.fsm'),
        <<'FSM'
(?dt:route_src
  (-route
    (route_data> = data_in)
  )
  (+size
    (data_in 8)
    (route_data 8)
  )
)
FSM
    );

    write_file(
        File::Spec->catfile($libdir, 'uart_tx.rtlif'),
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rst_n
  data_in<8
  txd>
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        source_search_paths => [$libdir],
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'dtc plus rtl composition uses C3 lane');
    is($result->{composition_plan}->instances->[0]->kind, 'dtc', 'generated child is realized as dtc');
    is($result->{composition_plan}->instances->[1]->kind, 'rtl', 'second child remains rtl');
    is_deeply(
        [map { $_->name } @{$result->{composition_plan}->instances->[0]->interface_ports}],
        ['data_in', 'route_data'],
        'external combinational dt child resolved through --path keeps a non-system interface',
    );

    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};
    is($rtl_bindings{clk}, 'clk', 'rtl child keeps shared clock binding');
    is($rtl_bindings{rst_n}, 'rst_n', 'rtl child keeps shared reset binding');
    is($rtl_bindings{data_in}, 'comp_link_router_route_data', 'rtl child input is fed from deterministic dt net');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+route_src\b/s, 'generated HDL includes external dt child module');
    like($hdl, qr/\buart_tx\s+uart_tx\b/s, 'generated top instantiates rtl child');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL does not regenerate rtl child internals');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', '--path', $libdir, $composition_path],
    );

    ok($success, 'CLI succeeds for dtc plus rtl composition through --path');
    ok(-e $output_path, 'CLI writes HDL for dtc plus rtl composition through --path');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
