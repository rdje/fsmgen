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

subtest 'multiple generated children plus rtl children support declared connect-by-name' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'generated_and_rtl_by_name_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'generated_and_rtl_by_name_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:generated_and_rtl_by_name_top
  (?ports:public_io
    clk
    rst_n
    =serial_out>
    =sampled_out>8
  )
  (?fsmc:producer producer_src)
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?rtl:payload_probe)
  (?toplink:wiring
    /producer.output_data/router.data_in/
    /router.route_data/uart_tx.data_in/
    /router.route_data/payload_probe.sample_in/
  )
)

(?fsm:producer_src
  (state0
    (output_data> <= 8'3)
  )
  (+size
    (output_data 8)
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
  clk
  rst_n
  data_in<8
  serial_out>
)

(?rtlif:payload_probe
  clk
  rst_n
  sample_in<8
  sampled_out>8
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
    is($result->{composition_plan}->lane, 'C4', 'multiple generated plus rtl by-name composition uses the C4 lane');
    is(scalar(@{$result->{composition_plan}->instances}), 4, 'composition realizes two generated children and two rtl children');
    is_deeply(
        [map { $_->kind } @{$result->{composition_plan}->instances}],
        ['fsmc', 'dtc', 'rtl', 'rtl'],
        'composition preserves the mixed child kinds in deterministic order',
    );
    is(scalar(@{$result->{composition_plan}->links}), 5, 'mixed by-name plan preserves explicit links and declared by-name links together');

    my @nets = @{$result->{composition_plan}->nets};
    is(scalar(@nets), 2, 'mixed by-name plan still materializes the expected deterministic internal nets');
    isa_ok($nets[0], 'FSM::Composition::Net');
    isa_ok($nets[1], 'FSM::Composition::Net');
    is_deeply(
        [map { $_->name } @nets],
        ['comp_link_producer_output_data', 'comp_link_router_route_data'],
        'mixed by-name plan keeps deterministic carrier naming across generated and rtl children',
    );

    my %producer_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[0]->port_bindings};
    my %router_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[1]->port_bindings};
    my %uart_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[2]->port_bindings};
    my %probe_bindings = map { $_->{port_name} => $_->{signal_name} } @{$result->{composition_plan}->instances->[3]->port_bindings};

    is($producer_bindings{clk}, 'clk', 'producer FSM clock is auto-wired');
    is($producer_bindings{rst_n}, 'rst_n', 'producer FSM reset is auto-wired');
    is($producer_bindings{output_data}, 'comp_link_producer_output_data', 'producer FSM output drives the first deterministic carrier net');

    is($router_bindings{data_in}, 'comp_link_producer_output_data', 'dt child input is fed from the producer carrier net');
    is($router_bindings{route_data}, 'comp_link_router_route_data', 'dt child output drives the second deterministic carrier net');

    is($uart_bindings{clk}, 'clk', 'first rtl child clock is auto-wired');
    is($uart_bindings{rst_n}, 'rst_n', 'first rtl child reset is auto-wired');
    is($uart_bindings{data_in}, 'comp_link_router_route_data', 'first rtl child input is driven from the routed carrier net');
    is($uart_bindings{serial_out}, 'serial_out', 'first rtl child output is wired through declared connect-by-name');

    is($probe_bindings{clk}, 'clk', 'second rtl child clock is auto-wired');
    is($probe_bindings{rst_n}, 'rst_n', 'second rtl child reset is auto-wired');
    is($probe_bindings{sample_in}, 'comp_link_router_route_data', 'second rtl child input is also driven from the routed carrier net');
    is($probe_bindings{sampled_out}, 'sampled_out', 'second rtl child output is wired through declared connect-by-name');

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bmodule\s+producer_src\b/s, 'generated HDL includes the embedded FSM child module');
    like($hdl, qr/\bmodule\s+route_src\b/s, 'generated HDL includes the embedded standalone DT child module');
    like($hdl, qr/\buart_tx\s+uart_tx\s*\(/s, 'generated top instantiates the first rtl child');
    like($hdl, qr/\bpayload_probe\s+payload_probe\s*\(/s, 'generated top instantiates the second rtl child');
    like($hdl, qr/\.serial_out\(serial_out\)/s, 'generated HDL wires the first rtl output directly through by-name exposure');
    like($hdl, qr/\.sampled_out\(sampled_out\)/s, 'generated HDL wires the second rtl output directly through by-name exposure');
    unlike($hdl, qr/\bmodule\s+uart_tx\b/s, 'generated HDL does not regenerate the first rtl child');
    unlike($hdl, qr/\bmodule\s+payload_probe\b/s, 'generated HDL does not regenerate the second rtl child');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for multiple generated plus rtl declared connect-by-name composition');
    ok(-e $output_path, 'CLI writes HDL for multiple generated plus rtl declared connect-by-name composition');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
