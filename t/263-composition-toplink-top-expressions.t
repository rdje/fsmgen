#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::Link;
use FSM::Composition::LinkedPlanBuilder;
use FSM::Composition::Plan;
use FSM::Composition::Port;
use FSM::Composition::PortsBlock;
use FSM::Composition::RealizedInstance;
use FSM::Composition::Spec;
use FSM::Composition::Top;
use FSM::Composition::TopLink;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    slice_expr
);
use FSM::Pipeline::HDLGenerator;

subtest 'linked plan builder preserves top bit-select and slice sources as typed bindings' => sub {
    my @ports = (
        port('core_clk', 'input', 1, 'clock'),
        port('rst_async_n', 'input', 1, 'reset'),
        port('payload_bus', 'input', 16, undef),
        port('status_bus', 'input', 4, undef),
        port('serial_out', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('top_expr_top'),
        top => FSM::Composition::Top->new(name => 'top_expr_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => 'payload_bus[15:8]', target => 'uart_tx.data_in'),
                    FSM::Composition::Link->new(source => 'status_bus[0]', target => 'uart_tx.enable'),
                    FSM::Composition::Link->new(source => 'uart_tx.serial_out', target => 'serial_out'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'uart_tx',
                port('core_clk', 'input', 1, 'clock'),
                port('rst_async_n', 'input', 1, 'reset'),
                port('data_in', 'input', 8, undef),
                port('enable', 'input', 1, undef),
                port('serial_out', 'output', 1, undef),
            ),
        ],
        fsm_file => 'top_expr_top.fsm',
        header => 'top_expr_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane');
    is(scalar(@{$plan->nets}), 0, 'top-expression child inputs do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};

    is_deeply(
        $bindings{data_in}{connection_expr},
        slice_expr('payload_bus', 15, 8),
        'top slice source becomes a typed slice binding expression',
    );
    is_deeply(
        $bindings{enable}{connection_expr},
        bit_select_expr('status_bus', 0),
        'top bit-select source becomes a typed bit-select binding expression',
    );
    is($bindings{serial_out}{signal_name}, 'serial_out', 'child output still rebinds directly to the top output');
};

subtest 'pipeline and CLI emit top bit-select and slice sources for explicit toplinks' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_expr_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'top_expr_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_expr_top
  (?ports:public_io
    core_clk
    rst_async_n
    payload_bus<16
    status_bus<4
    serial_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
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
    is($result->{composition_plan}->lane, 'C3', 'single rtl explicit top-expression toplinks stay on the C3 lane');

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

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\.data_in\(payload_bus\[15:8\]\)/, 'generated HDL emits the top slice directly on the child port');
    like($hdl, qr/\.enable\(status_bus\[0\]\)/, 'generated HDL emits the top bit-select directly on the child port');
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for pure top-expression bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for explicit top-expression toplinks');
    ok(-e $output_path, 'CLI writes HDL for explicit top-expression toplinks');
};

subtest 'linked plan builder preserves top-expression sources for direct top-output assignments too' => sub {
    my @ports = (
        port('core_clk', 'input', 1, 'clock'),
        port('rst_async_n', 'input', 1, 'reset'),
        port('payload_bus', 'input', 16, undef),
        port('status_bus', 'input', 4, undef),
        port('serial_hi', 'output', 8, undef),
        port('serial_flag', 'output', 1, undef),
        port('packed_status', 'output', 8, undef),
        port('serial_out', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('top_expr_top_output_top'),
        top => FSM::Composition::Top->new(name => 'top_expr_top_output_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => 'payload_bus[15:8]', target => 'serial_hi'),
                    FSM::Composition::Link->new(source => 'status_bus[0]', target => 'serial_flag'),
                    FSM::Composition::Link->new(source => "payload_bus[3:0],status_bus[0],status_bus[1],=2'b10", target => 'packed_status'),
                    FSM::Composition::Link->new(source => 'payload_bus[15:8]', target => 'uart_tx.data_in'),
                    FSM::Composition::Link->new(source => 'status_bus[0]', target => 'uart_tx.enable'),
                    FSM::Composition::Link->new(source => 'uart_tx.serial_out', target => 'serial_out'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'uart_tx',
                port('core_clk', 'input', 1, 'clock'),
                port('rst_async_n', 'input', 1, 'reset'),
                port('data_in', 'input', 8, undef),
                port('enable', 'input', 1, undef),
                port('serial_out', 'output', 1, undef),
            ),
        ],
        fsm_file => 'top_expr_top_output_top.fsm',
        header => 'top_expr_top_output_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for top-expression top-output wiring');
    is(scalar(@{$plan->nets}), 0, 'top-expression top-output wiring does not invent synthetic carrier nets');
    is_deeply(
        $plan->auxiliary_assignments,
        [
            '    assign serial_hi = payload_bus[15:8];',
            '    assign serial_flag = status_bus[0];',
            "    assign packed_status = {payload_bus[3:0], status_bus[0], status_bus[1], 2'b10};",
        ],
        'builder emits direct top-output assignments from typed top-expression sources',
    );

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        slice_expr('payload_bus', 15, 8),
        'top slice source still becomes a typed child-input binding expression',
    );
    is_deeply(
        $bindings{enable}{connection_expr},
        bit_select_expr('status_bus', 0),
        'top bit-select source still becomes a typed child-input binding expression',
    );
    is($bindings{serial_out}{signal_name}, 'serial_out', 'child output still rebinds directly to the top output');
};

subtest 'linked plan builder rejects out-of-range top expressions' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_top_expr_top'),
            top => FSM::Composition::Top->new(name => 'blocked_top_expr_top'),
            ports_block => FSM::Composition::PortsBlock->new(
                name => 'public_io',
                ports => [port('payload_bus', 'input', 8, undef)],
            ),
            ports => [port('payload_bus', 'input', 8, undef)],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => 'payload_bus[8]', target => 'uart_tx.enable'),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('enable', 'input', 1, undef),
                ),
            ],
            fsm_file => 'blocked_top_expr_top.fsm',
            header => 'blocked_top_expr_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses top expression 'payload_bus\[8\]', .*bit index 8 falls outside declared width 8 of top port 'payload_bus'/s,
        'builder blocks top bit-select expressions that exceed the declared top-port width',
    );
};

done_testing();

sub composition_spec {
    my ($top_name) = @_;
    return FSM::Composition::Spec->new(
        top => FSM::Composition::Top->new(name => $top_name),
    );
}

sub realized_instance {
    my ($kind, $instance_name, @ports) = @_;

    return FSM::Composition::RealizedInstance->new(
        kind => $kind,
        instance_name => $instance_name,
        module_name => $instance_name.'_mod',
        source_name => $instance_name.'_src',
        interface_ports => \@ports,
        port_bindings => [],
        module_info => {},
    );
}

sub port {
    my ($name, $direction, $width, $type) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => $direction,
        width => $width,
        type => $type,
        binding_mode => 'explicit',
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
