#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Pipeline::HDLGenerator;
use FSM::Composition::Plan;
use FSM::Composition::Net;
use FSM::Test::CompositionNets qw(assert_only_carrier_and_shared_dp_sink_nets);

subtest 'mixed fsmc plus rtl composition supports declared connect-by-name on top ports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'mixed_fsmc_rtl_by_name_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'mixed_fsmc_rtl_by_name_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:mixed_fsmc_rtl_by_name_top
  (?ports:public_io
    clk
    rstn
    =start
    =txd>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?wiring:wiring
    /producer.output_data/uart_tx.data_in/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (? start
      (=1 (output_data> <= 8'3))
      (=0 (output_data> <= 8'0))
    )
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:uart_tx
  clk
  rstn
  data_in<8
  txd>
)
RTLIF
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C4', 'mixed fsmc plus rtl by-name composition uses C4 lane');
    is(scalar(@{$result->{composition_plan}->links}), 3, 'mixed by-name plan preserves one explicit link plus two by-name links');
my ($carrier_nets) = assert_only_carrier_and_shared_dp_sink_nets(
    $result->{composition_plan}->nets,
    ['comp_link_producer_output_data'],
    'mixed fsmc plus rtl by-name plan',
);
isa_ok($carrier_nets->[0], 'FSM::Composition::Net');

    my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($producer_bindings{clk}, 'clk', 'fsm child keeps shared clock binding');
    is($producer_bindings{rstn}, 'rstn', 'fsm child keeps shared reset binding');
    is($producer_bindings{start}, 'start', 'fsm child input is connected through declared connect-by-name');
    is($producer_bindings{output_data}, 'comp_link_producer_output_data', 'fsm child output still drives deterministic mixed-lane net');
    is($rtl_bindings{clk}, 'clk', 'rtl child keeps shared clock binding');
    is($rtl_bindings{rstn}, 'rstn', 'rtl child keeps shared reset binding');
    is($rtl_bindings{data_in}, 'comp_link_producer_output_data', 'rtl child input is driven from the deterministic mixed-lane net');
    is($rtl_bindings{txd}, 'txd', 'rtl child output is connected through declared connect-by-name');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+mixed_fsmc_rtl_by_name_top\b/s, 'generated HDL includes the mixed fsmc plus rtl by-name top');
    like($hdl, qr/\.start\(start\)/s, 'generated HDL wires the by-name FSM input directly');
    like($hdl, qr/\.txd\(txd\)/s, 'generated HDL wires the by-name RTL output directly');
    unlike($hdl, qr/\bcomp_link_producer_start\b/s, 'by-name FSM input does not create a synthetic carrier net');
    unlike($hdl, qr/\bcomp_link_uart_tx_txd\b/s, 'by-name RTL output does not create a synthetic carrier net');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for mixed fsmc plus rtl by-name composition');
    ok(-e $output_path, 'CLI writes HDL for mixed fsmc plus rtl by-name composition');
};

subtest 'mixed dtc plus rtl composition supports declared connect-by-name on top ports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'mixed_dtc_rtl_by_name_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
    my $output_path = File::Spec->catfile($tempdir, 'mixed_dtc_rtl_by_name_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:mixed_dtc_rtl_by_name_top
  (?ports:public_io
    clk
    rst_n
    =payload_in<8
    =txd>
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?wiring:wiring
    /router.route_data/uart_tx.data_in/
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
FSM
    );

    write_file(
        $metadata_path,
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
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C4', 'mixed dtc plus rtl by-name composition uses C4 lane');
    is(scalar(@{$result->{composition_plan}->links}), 3, 'mixed dtc by-name plan preserves one explicit link plus two by-name links');
    is(scalar(@{$result->{composition_plan}->nets}), 1, 'mixed dtc by-name plan still creates one deterministic internal net');
    isa_ok($result->{composition_plan}->nets->[0], 'FSM::Composition::Net');
    is_deeply(
        [map { $_->name } @{$result->{composition_plan}->instances->[0]->interface_ports}],
        ['payload_in', 'route_data'],
        'combinational dt child keeps an honest non-system interface in mixed by-name composition',
    );

    my %dt_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %rtl_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};

    is($dt_bindings{payload_in}, 'payload_in', 'dt child input is connected through declared connect-by-name');
    is($dt_bindings{route_data}, 'comp_link_router_route_data', 'dt child output still drives deterministic mixed-lane net');
    is($rtl_bindings{clk}, 'clk', 'rtl child clock is auto-wired from the shared top system input');
    is($rtl_bindings{rst_n}, 'rst_n', 'rtl child reset is auto-wired from the shared top system input');
    is($rtl_bindings{data_in}, 'comp_link_router_route_data', 'rtl child input is driven from the deterministic dt net');
    is($rtl_bindings{txd}, 'txd', 'rtl child output is connected through declared connect-by-name');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+mixed_dtc_rtl_by_name_top\b/s, 'generated HDL includes the mixed dtc plus rtl by-name top');
    like($hdl, qr/\.payload_in\(payload_in\)/s, 'generated HDL wires the by-name dt input directly');
    like($hdl, qr/\.txd\(txd\)/s, 'generated HDL wires the by-name RTL output directly');
    unlike($hdl, qr/\binput\s+clk\b[\s\S]*\bmodule\s+route_src\b/s, 'dt child module itself does not grow fake clk ports in mixed by-name composition');
    unlike($hdl, qr/\bcomp_link_router_data_in\b/s, 'by-name dt input does not create a synthetic carrier net');
    unlike($hdl, qr/\bcomp_link_uart_tx_txd\b/s, 'by-name RTL output does not create a synthetic carrier net');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for mixed dtc plus rtl by-name composition');
    ok(-e $output_path, 'CLI writes HDL for mixed dtc plus rtl by-name composition');
};

subtest 'mixed generated-child plus rtl by-name composition rejects ambiguous same-name matches across child kinds' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'mixed_by_name_ambiguous_top.fsm');
    my $metadata_path = File::Spec->catfile($tempdir, 'status_probe.rtlif');

    write_file(
        $composition_path,
        <<'FSM'
(?top:mixed_by_name_ambiguous_top
  (?ports:public_io
    clk
    rstn
    =shared_status>8
  )
  (?fsmc:producer producer_src)
  (?rtl:status_probe)
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (shared_status> <= 8'1)
  )
  (+size
    (shared_status 8)
  )
)
FSM
    );

    write_file(
        $metadata_path,
        <<'RTLIF'
(?rtlif:status_probe
  clk
  rstn
  shared_status>8
)
RTLIF
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
        qr/declared connect-by-name, .*resolves ambiguously to multiple compatible child endpoints: producer\.shared_status, status_probe\.shared_status/s,
        'mixed by-name composition rejects ambiguous same-name matches across generated and rtl child kinds',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
