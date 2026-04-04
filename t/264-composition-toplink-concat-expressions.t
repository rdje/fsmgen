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
    bit_vector_literal_expr
    concat_expr
    signal_ref_expr
    slice_expr
);
use FSM::Pipeline::HDLGenerator;

subtest 'linked plan builder preserves top concat sources as typed bindings' => sub {
    my @ports = (
        port('core_clk', 'input', 1, 'clock'),
        port('rst_async_n', 'input', 1, 'reset'),
        port('header_bus', 'input', 2, undef),
        port('status_bus', 'input', 1, undef),
        port('payload_bus', 'input', 3, undef),
        port('serial_out', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('top_concat_top'),
        top => FSM::Composition::Top->new(name => 'top_concat_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => "header_bus,status_bus[0],=2'd2,=2'h2,payload_bus[2:0]",
                        target => 'uart_tx.data_in',
                    ),
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
                port('data_in', 'input', 10, undef),
                port('serial_out', 'output', 1, undef),
            ),
        ],
        fsm_file => 'top_concat_top.fsm',
        header => 'top_concat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane');
    is(scalar(@{$plan->nets}), 0, 'top concat child inputs do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};

    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            bit_select_expr('status_bus', 0),
            bit_vector_literal_expr('10'),
            bit_vector_literal_expr('10'),
            slice_expr('payload_bus', 2, 0),
        ),
        'top concat source becomes a typed concat binding expression, including decimal and hex literal operands',
    );
    is($bindings{serial_out}{signal_name}, 'serial_out', 'child output still rebinds directly to the top output');
};

subtest 'pipeline and CLI emit top concat sources for explicit toplinks' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'top_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'top_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:top_concat_top
  (?ports:public_io
    core_clk
    rst_async_n
    header_bus<2
    status_bus
    payload_bus<3
    serial_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /header_bus,status_bus[0],=2'd2,=2'h2,payload_bus[2:0]/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<10:data
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
    is($result->{composition_plan}->lane, 'C3', 'single rtl explicit top-concat toplinks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            bit_select_expr('status_bus', 0),
            bit_vector_literal_expr('10'),
            bit_vector_literal_expr('10'),
            slice_expr('payload_bus', 2, 0),
        ),
        'pipeline preserves the typed concat binding in the realized composition plan, including decimal and hex literal operands',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{header_bus,\s*status_bus\[0\],\s*2'b10,\s*2'b10,\s*payload_bus\[2:0\]\}\)/,
        'generated HDL emits the top concat directly on the child port, including the normalized decimal and hex literal operands',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for pure top-concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for explicit top-concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for explicit top-concat toplinks');
};

subtest 'linked plan builder rejects unsupported concat operands' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_top_concat_top'),
            top => FSM::Composition::Top->new(name => 'blocked_top_concat_top'),
            ports_block => FSM::Composition::PortsBlock->new(
                name => 'public_io',
                ports => [port('payload_bus', 'input', 4, undef)],
            ),
            ports => [port('payload_bus', 'input', 4, undef)],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(
                            source => 'payload_bus[3:0],=open',
                            target => 'uart_tx.data_in',
                        ),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('data_in', 'input', 5, undef),
                ),
            ],
            fsm_file => 'blocked_top_concat_top.fsm',
            header => 'blocked_top_concat_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses top expression 'payload_bus\[3:0\],=open', .*concat operands currently accept only top-port names, top-port bit\/slice forms, scalar '=0'\/'=1' actuals, and exact-width literal actuals like '=4'b1010', '=4'd10', or '=4'hA'/s,
        'builder blocks unsupported concat operands through the top-expression boundary',
    );
};

subtest 'linked plan builder still rejects unsized numeric concat operands' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_numeric_concat_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_numeric_concat_top'),
            ports_block => FSM::Composition::PortsBlock->new(
                name => 'public_io',
                ports => [port('payload_bus', 'input', 4, undef)],
            ),
            ports => [port('payload_bus', 'input', 4, undef)],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(
                            source => 'payload_bus[3:0],=170',
                            target => 'uart_tx.data_in',
                        ),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('data_in', 'input', 12, undef),
                ),
            ],
            fsm_file => 'blocked_unsized_numeric_concat_top.fsm',
            header => 'blocked_unsized_numeric_concat_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses top expression 'payload_bus\[3:0\],=170', .*concat operands currently accept only top-port names, top-port bit\/slice forms, scalar '=0'\/'=1' actuals, and exact-width literal actuals like '=4'b1010', '=4'd10', or '=4'hA'/s,
        'builder keeps unsized numeric actual widening on the direct-binding path instead of silently enabling it inside concat operands',
    );
};

subtest 'linked plan builder still rejects prefixed unsized numeric concat operands' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_prefixed_unsized_numeric_concat_top'),
            top => FSM::Composition::Top->new(name => 'blocked_prefixed_unsized_numeric_concat_top'),
            ports_block => FSM::Composition::PortsBlock->new(
                name => 'public_io',
                ports => [port('payload_bus', 'input', 4, undef)],
            ),
            ports => [port('payload_bus', 'input', 4, undef)],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(
                            source => 'payload_bus[3:0],=0xA5',
                            target => 'uart_tx.data_in',
                        ),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('data_in', 'input', 12, undef),
                ),
            ],
            fsm_file => 'blocked_prefixed_unsized_numeric_concat_top.fsm',
            header => 'blocked_prefixed_unsized_numeric_concat_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses top expression 'payload_bus\[3:0\],=0xA5', .*concat operands currently accept only top-port names, top-port bit\/slice forms, scalar '=0'\/'=1' actuals, and exact-width literal actuals like '=4'b1010', '=4'd10', or '=4'hA'/s,
        'builder keeps prefixed unsized numeric actual widening on the direct-binding path instead of silently enabling it inside concat operands',
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
