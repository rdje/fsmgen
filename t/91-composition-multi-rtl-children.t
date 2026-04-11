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
use FSM::Composition::Net;
use FSM::Composition::Plan;

subtest 'multi-rtl composition supports explicit C3 child-to-child wiring' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'rtl_bridge_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'rtl_bridge_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:rtl_bridge_top
  (?ports:public_io
    core_clk
    rst_async_n
    serial_in
    serial_out>
  )
  (?rtl:uart_rx)
  (?rtl:uart_tx)
  (?toplink:wiring
    /serial_in/uart_rx.rxd/
    /uart_rx.data_out/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?rtlif:uart_rx
  core_clk:clock
  rst_async_n:reset
  rxd<:data
  data_out>8:data
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
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'multi-rtl explicit-link composition uses the C3 lane');
    is(scalar(@{$result->{composition_plan}->instances}), 2, 'multi-rtl composition realizes two rtl children');
    is_deeply(
        [map { $_->kind } @{$result->{composition_plan}->instances}],
        ['rtl', 'rtl'],
        'multi-rtl composition keeps both realized children as rtl instances',
    );
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'multi-rtl composition materializes one deterministic internal net');
    isa_ok($result->{composition_plan}->nets->[0], 'FSM::Composition::Net');
    is($result->{composition_plan}->nets->[0]->name, 'comp_link_uart_rx_data_out', 'multi-rtl composition uses deterministic net naming');

    my %rx_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %tx_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($rx_bindings{core_clk}, 'core_clk', 'first rtl child clock is auto-wired');
    is($rx_bindings{rst_async_n}, 'rst_async_n', 'first rtl child reset is auto-wired');
    is($rx_bindings{rxd}, 'serial_in', 'first rtl child input is wired from the top input');
    is($rx_bindings{data_out}, 'comp_link_uart_rx_data_out', 'first rtl child output drives the deterministic carrier net');
    is($tx_bindings{core_clk}, 'core_clk', 'second rtl child clock is auto-wired');
    is($tx_bindings{rst_async_n}, 'rst_async_n', 'second rtl child reset is auto-wired');
    is($tx_bindings{data_in}, 'comp_link_uart_rx_data_out', 'second rtl child input is fed from the deterministic carrier net');
    is($tx_bindings{txd}, 'serial_out', 'second rtl child output is wired to the top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\buart_rx\s+uart_rx\s*\(/s, 'generated top instantiates the first rtl child');
    like($hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'generated top instantiates the second rtl child');
    unlike($hdl, qr/\bmodule\s+uart_rx\b/s, 'generated HDL does not regenerate the first rtl child');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL does not regenerate the second rtl child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for multi-rtl explicit-link composition');
    ok(-e $output_path, 'CLI writes HDL for multi-rtl explicit-link composition');
};

subtest 'mixed generated-child plus multiple rtl children supports explicit C3 wiring' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'dt_plus_two_rtl_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'dt_plus_two_rtl_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:dt_plus_two_rtl_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_in<8
    serial_out>
    echoed_out>8
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?rtl:payload_probe)
  (?toplink:wiring
    /payload_in/router.data_in/
    /router.route_data/uart_tx.data_in/
    /router.route_data/payload_probe.sample_in/
    /uart_tx.txd/serial_out/
    /payload_probe.sample_seen/echoed_out/
  )
)

(?dt:route_src
  (-route
    (route_data> = data_in)
  )
  (+size
    (data_in 8)
    (route_data 8)
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  txd>:data
)

(?rtlif:payload_probe
  core_clk:clock
  rst_async_n:reset
  sample_in<8:data
  sample_seen>8:data
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
    is($result->{composition_plan}->lane, 'C3', 'generated-child plus multiple rtl composition uses the C3 lane');
    is_deeply(
        [map { $_->kind } @{$result->{composition_plan}->instances}],
        ['dtc', 'rtl', 'rtl'],
        'mixed multi-rtl composition realizes one dtc child and two rtl children',
    );
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'generated-child plus multiple rtl composition materializes one shared deterministic net');
    is($result->{composition_plan}->nets->[0]->name, 'comp_link_router_route_data', 'mixed multi-rtl composition uses deterministic net naming');

    my %router_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %uart_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};
    my %probe_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[2]->port_bindings};

    is($router_bindings{data_in}, 'payload_in', 'generated child input is wired from the top input');
    is($router_bindings{route_data}, 'comp_link_router_route_data', 'generated child output drives the deterministic carrier net');
    is($uart_bindings{core_clk}, 'core_clk', 'first rtl child clock is auto-wired in mixed multi-rtl composition');
    is($uart_bindings{rst_async_n}, 'rst_async_n', 'first rtl child reset is auto-wired in mixed multi-rtl composition');
    is($uart_bindings{data_in}, 'comp_link_router_route_data', 'first rtl child consumes the generated carrier net');
    is($uart_bindings{txd}, 'serial_out', 'first rtl child output is wired to the top output');
    is($probe_bindings{core_clk}, 'core_clk', 'second rtl child clock is auto-wired in mixed multi-rtl composition');
    is($probe_bindings{rst_async_n}, 'rst_async_n', 'second rtl child reset is auto-wired in mixed multi-rtl composition');
    is($probe_bindings{sample_in}, 'comp_link_router_route_data', 'second rtl child also consumes the generated carrier net');
    is($probe_bindings{sample_seen}, 'echoed_out', 'second rtl child output is wired to the top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+route_src\b/s, 'generated HDL includes the dt child module');
    like($hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'generated HDL instantiates the first rtl child');
    like($hdl, qr/\bpayload_probe\s+payload_probe\s*\(/s, 'generated HDL instantiates the second rtl child');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL does not regenerate the first rtl child');
    unlike($hdl, qr/\bmodule\s+payload_probe\b/s, 'generated HDL does not regenerate the second rtl child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for generated-child plus multiple rtl composition');
    ok(-e $output_path, 'CLI writes HDL for generated-child plus multiple rtl composition');
};

subtest 'one rtl interface can be instantiated several times with explicit instance aliases' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'aliased_reused_rtl_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'aliased_reused_rtl_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:aliased_reused_rtl_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_a<8
    payload_b<8
    serial_a>
    serial_b>
  )
  (?rtl:u_uart_a uart_tx)
  (?rtl:u_uart_b uart_tx)
  (?toplink:wiring
    /payload_a/u_uart_a.data_in/
    /u_uart_a.txd/serial_a/
    /payload_b/u_uart_b.data_in/
    /u_uart_b.txd/serial_b/
  )
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
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C3', 'aliased repeated rtl composition uses the C3 lane');
    is(scalar(@{$result->{composition_plan}->instances}), 2, 'aliased repeated rtl composition realizes two rtl children');
    is_deeply(
        [map { $_->instance_name } @{$result->{composition_plan}->instances}],
        ['u_uart_a', 'u_uart_b'],
        'aliased repeated rtl composition keeps distinct instance names',
    );
    is_deeply(
        [map { $_->module_name } @{$result->{composition_plan}->instances}],
        ['uart_tx', 'uart_tx'],
        'aliased repeated rtl composition reuses one rtl module/interface contract',
    );

    my %first_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %second_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($first_bindings{core_clk}, 'core_clk', 'first aliased rtl instance clock is auto-wired');
    is($first_bindings{rst_async_n}, 'rst_async_n', 'first aliased rtl instance reset is auto-wired');
    is($first_bindings{data_in}, 'payload_a', 'first aliased rtl instance uses its own input payload');
    is($first_bindings{txd}, 'serial_a', 'first aliased rtl instance drives its own top output');
    is($second_bindings{core_clk}, 'core_clk', 'second aliased rtl instance clock is auto-wired');
    is($second_bindings{rst_async_n}, 'rst_async_n', 'second aliased rtl instance reset is auto-wired');
    is($second_bindings{data_in}, 'payload_b', 'second aliased rtl instance uses its own input payload');
    is($second_bindings{txd}, 'serial_b', 'second aliased rtl instance drives its own top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\buart_tx\s+u_uart_a\s*\(/s, 'generated HDL instantiates the first aliased rtl child');
    like($hdl, qr/\buart_tx\s+u_uart_b\s*\(/s, 'generated HDL instantiates the second aliased rtl child');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL still does not regenerate the reused external rtl child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for aliased repeated rtl composition');
    ok(-e $output_path, 'CLI writes HDL for aliased repeated rtl composition');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
