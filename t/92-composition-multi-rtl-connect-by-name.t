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

subtest 'multiple rtl children support declared connect-by-name with explicit child-to-child wiring' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'multi_rtl_by_name_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'multi_rtl_by_name_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:multi_rtl_by_name_top
  (?ports:public_io
    core_clk
    rst_async_n
    serial_in
    =data_out>8
    =sample_seen>8
  )
  (?rtl:uart_rx)
  (?rtl:payload_probe)
  (?toplink:wiring
    /serial_in/uart_rx.rxd/
    /uart_rx.data_out/payload_probe.sample_in/
  )
)

(?rtlif:uart_rx
  core_clk:clock
  rst_async_n:reset
  rxd<:data
  data_out>8:data
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
    is($result->{composition_plan}->lane, 'C4', 'multiple rtl by-name composition uses the C4 lane');
    is(scalar(@{$result->{composition_plan}->links}), 4, 'multiple rtl by-name plan keeps explicit and by-name links together');
    is(scalar(@{$result->{composition_plan}->nets}), 0, 'multiple rtl by-name plan avoids synthetic nets when top outputs can carry the signal');

    my %rx_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %probe_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($rx_bindings{core_clk}, 'core_clk', 'first rtl child clock is auto-wired');
    is($rx_bindings{rst_async_n}, 'rst_async_n', 'first rtl child reset is auto-wired');
    is($rx_bindings{rxd}, 'serial_in', 'first rtl child input is driven by the explicit top input link');
    is($rx_bindings{data_out}, 'data_out', 'first rtl child output is carried directly by the by-name top output');
    is($probe_bindings{core_clk}, 'core_clk', 'second rtl child clock is auto-wired');
    is($probe_bindings{rst_async_n}, 'rst_async_n', 'second rtl child reset is auto-wired');
    is($probe_bindings{sample_in}, 'data_out', 'second rtl child input is fed from the first child output carrier');
    is($probe_bindings{sample_seen}, 'sample_seen', 'second rtl child output is carried directly by the by-name top output');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\buart_rx\s+uart_rx\s*\(/s, 'generated HDL instantiates the first rtl child');
    like($hdl, qr/\bpayload_probe\s+payload_probe\s*\(/s, 'generated HDL instantiates the second rtl child');
    like($hdl, qr/\.data_out\(data_out\)/s, 'generated HDL wires the by-name first rtl output directly');
    like($hdl, qr/\.sample_in\(data_out\)/s, 'generated HDL reuses the top-output carrier for the child-to-child link');
    like($hdl, qr/\.sample_seen\(sample_seen\)/s, 'generated HDL wires the by-name second rtl output directly');
    unlike($hdl, qr/\bcomp_link_uart_rx_data_out\b/s, 'no synthetic carrier net is created for the first rtl output');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for multiple rtl by-name composition');
    ok(-e $output_path, 'CLI writes HDL for multiple rtl by-name composition');
};

subtest 'one generated child plus multiple rtl children support declared connect-by-name' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'generated_plus_multi_rtl_by_name_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'generated_plus_multi_rtl_by_name_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:generated_plus_multi_rtl_by_name_top
  (?ports:public_io
    core_clk
    rst_async_n
    =payload_in<8
    =txd>
    =sample_seen>8
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?rtl:payload_probe)
  (?toplink:wiring
    /router.route_data/uart_tx.data_in/
    /router.route_data/payload_probe.sample_in/
  )
)

(?dt:route_src
  (-route
    (route_data> = payload_in)
  )
  (+size
    (payload_in 8)
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
    is($result->{composition_plan}->lane, 'C4', 'one generated plus multiple rtl by-name composition uses the C4 lane');
    is(scalar(@{$result->{composition_plan}->links}), 5, 'mixed by-name plan preserves explicit and by-name links together');
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'mixed by-name plan still creates one deterministic shared net');
    is($result->{composition_plan}->nets->[0]->name, 'comp_link_router_route_data', 'mixed by-name plan uses deterministic carrier naming');

    my %router_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %uart_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};
    my %probe_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[2]->port_bindings};

    is($router_bindings{payload_in}, 'payload_in', 'generated child input is wired through declared connect-by-name');
    is($router_bindings{route_data}, 'comp_link_router_route_data', 'generated child output drives the deterministic carrier net');
    is($uart_bindings{core_clk}, 'core_clk', 'first rtl child clock is auto-wired');
    is($uart_bindings{rst_async_n}, 'rst_async_n', 'first rtl child reset is auto-wired');
    is($uart_bindings{data_in}, 'comp_link_router_route_data', 'first rtl child input is driven from the generated carrier net');
    is($uart_bindings{txd}, 'txd', 'first rtl child output is wired through declared connect-by-name');
    is($probe_bindings{core_clk}, 'core_clk', 'second rtl child clock is auto-wired');
    is($probe_bindings{rst_async_n}, 'rst_async_n', 'second rtl child reset is auto-wired');
    is($probe_bindings{sample_in}, 'comp_link_router_route_data', 'second rtl child input is also driven from the generated carrier net');
    is($probe_bindings{sample_seen}, 'sample_seen', 'second rtl child output is wired through declared connect-by-name');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+route_src\b/s, 'generated HDL includes the dt child module');
    like($hdl, qr/\.payload_in\(payload_in\)/s, 'generated HDL wires the by-name generated-child input directly');
    like($hdl, qr/\.txd\(txd\)/s, 'generated HDL wires the by-name first rtl output directly');
    like($hdl, qr/\.sample_seen\(sample_seen\)/s, 'generated HDL wires the by-name second rtl output directly');
    like($hdl, qr/\bwire\s+\[7:0\]\s+comp_link_router_route_data;/s, 'generated HDL emits the deterministic shared carrier net');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for one generated plus multiple rtl by-name composition');
    ok(-e $output_path, 'CLI writes HDL for one generated plus multiple rtl by-name composition');
};

subtest 'multiple rtl children reject ambiguous declared connect-by-name matches' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'multi_rtl_by_name_ambiguous_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:multi_rtl_by_name_ambiguous_top
  (?ports:public_io
    core_clk
    rst_async_n
    =shared_status>8
  )
  (?rtl:status_probe_a)
  (?rtl:status_probe_b)
)

(?rtlif:status_probe_a
  core_clk:clock
  rst_async_n:reset
  shared_status>8:data
)

(?rtlif:status_probe_b
  core_clk:clock
  rst_async_n:reset
  shared_status>8:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declared connect-by-name, .*resolves ambiguously to multiple compatible child endpoints: status_probe_a\.shared_status, status_probe_b\.shared_status/s,
        'multiple rtl by-name composition rejects ambiguous same-name outputs',
    );
    like(
        $exception,
        qr/docs\/COMPOSITION_SCOPE\.md/s,
        'ambiguous multiple-rtl by-name diagnostics point to the scoped composition doc',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
