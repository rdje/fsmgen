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
    bit_vector_literal_expr
    open_expr
);
use FSM::Pipeline::HDLGenerator;

subtest 'linked plan builder preserves literal and open toplinks as typed actual bindings' => sub {
    my @ports = (
        port('core_clk', 'input', 1, 'clock'),
        port('rst_async_n', 'input', 1, 'reset'),
        port('serial_out', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('structural_actual_top'),
        top => FSM::Composition::Top->new(name => 'structural_actual_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => "=8'b10100101", target => 'uart_tx.data_in'),
                    FSM::Composition::Link->new(source => "=8'd165", target => 'uart_tx.decimal_data_in'),
                    FSM::Composition::Link->new(source => "=8'hA5", target => 'uart_tx.hex_data_in'),
                    FSM::Composition::Link->new(source => '=open', target => 'uart_tx.enable'),
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
                port('decimal_data_in', 'input', 8, undef),
                port('hex_data_in', 'input', 8, undef),
                port('enable', 'input', 1, undef),
                port('serial_out', 'output', 1, undef),
            ),
        ],
        fsm_file => 'structural_actual_top.fsm',
        header => 'structural_actual_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane');
    is(scalar(@{$plan->nets}), 0, 'actual-bound child inputs do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};

    is($bindings{core_clk}{signal_name}, 'core_clk', 'typed clock binding still auto-wires by name');
    is($bindings{rst_async_n}{signal_name}, 'rst_async_n', 'typed reset binding still auto-wires by name');
    is($bindings{serial_out}{signal_name}, 'serial_out', 'child output still rebinds directly to the top output');
    is($bindings{data_in}{signal_name} // '', '', 'literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'literal explicit toplink becomes a typed bit-vector actual binding',
    );
    is($bindings{decimal_data_in}{signal_name} // '', '', 'decimal literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'decimal literal explicit toplink becomes the same typed bit-vector actual binding',
    );
    is($bindings{hex_data_in}{signal_name} // '', '', 'hex literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'hex literal explicit toplink becomes the same typed bit-vector actual binding',
    );
    is($bindings{enable}{signal_name} // '', '', 'open actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{enable}{connection_expr},
        open_expr(),
        'open explicit toplink becomes a typed open actual binding',
    );
};

subtest 'pipeline and CLI emit structural literal and open actuals for explicit toplinks' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'structural_actual_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'structural_actual_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:structural_actual_top
  (?ports:public_io
    core_clk
    rst_async_n
    serial_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=8'b10100101/uart_tx.data_in/
    /=8'd165/uart_tx.decimal_data_in/
    /=8'hA5/uart_tx.hex_data_in/
    /=open/uart_tx.enable/
    /uart_tx.serial_out/serial_out/
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  decimal_data_in<8:data
  hex_data_in<8:data
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
    is($result->{composition_plan}->lane, 'C3', 'single rtl explicit actual toplinks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the typed literal actual binding in the realized composition plan',
    );
    is_deeply(
        $bindings{decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the typed decimal literal actual binding in the realized composition plan',
    );
    is_deeply(
        $bindings{hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the typed hex literal actual binding in the realized composition plan',
    );
    is_deeply(
        $bindings{enable}{connection_expr},
        open_expr(),
        'pipeline preserves the typed open actual binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\.data_in\(8'b10100101\)/, 'generated HDL emits the literal actual directly on the child port');
    like($hdl, qr/\.decimal_data_in\(8'b10100101\)/, 'generated HDL emits the decimal literal actual directly on the child port');
    like($hdl, qr/\.hex_data_in\(8'b10100101\)/, 'generated HDL emits the hex literal actual directly on the child port');
    like($hdl, qr/\.enable\(\)/, 'generated HDL emits the open actual directly on the child port');
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for pure actual bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for explicit structural-actual toplinks');
    ok(-e $output_path, 'CLI writes HDL for explicit structural-actual toplinks');
};

subtest 'linked plan builder rejects actual sources that do not target realized child inputs' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_actual_source_top'),
            top => FSM::Composition::Top->new(name => 'blocked_actual_source_top'),
            ports_block => FSM::Composition::PortsBlock->new(
                name => 'public_io',
                ports => [port('serial_out', 'output', 1, undef)],
            ),
            ports => [port('serial_out', 'output', 1, undef)],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => '=1', target => 'serial_out'),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('serial_out', 'output', 1, undef),
                ),
            ],
            fsm_file => 'blocked_actual_source_top.fsm',
            header => 'blocked_actual_source_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual source '=1' as an explicit link source, .*only allows actual sources to target realized child input ports/s,
        'builder blocks literal actuals from driving non-child-input targets',
    );
};

subtest 'linked plan builder rejects actual endpoints as explicit link targets' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_actual_target_top'),
            top => FSM::Composition::Top->new(name => 'blocked_actual_target_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => 'uart_tx.serial_out', target => '=open'),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('serial_out', 'output', 1, undef),
                ),
            ],
            fsm_file => 'blocked_actual_target_top.fsm',
            header => 'blocked_actual_target_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual endpoint '=open' as an explicit link target, .*only allows '=open' and exact-width binary, decimal, or hex literal actuals as link sources into realized child input ports/s,
        'builder blocks actual endpoints from appearing as explicit link targets',
    );
};

subtest 'linked plan builder rejects unsupported actual literal forms' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_actual_shape_top'),
            top => FSM::Composition::Top->new(name => 'blocked_actual_shape_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => '=170', target => 'uart_tx.data_in'),
                ],
            ),
        ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('data_in', 'input', 8, undef),
                ),
            ],
            fsm_file => 'blocked_actual_shape_top.fsm',
            header => 'blocked_actual_shape_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual endpoint '=170', .*currently accepts only '=open', '=0', '=1', or exact-width binary\/decimal\/hex literal forms like '=8'b10100101', '=8'd165', or '=8'hA5'/s,
        'builder keeps the first structural-actual slice limited to open and bounded binary/decimal/hex literal sources',
    );
};

subtest 'linked plan builder rejects decimal actuals whose value exceeds the declared width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_decimal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_decimal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => "=8'd256", target => 'uart_tx.data_in'),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('data_in', 'input', 8, undef),
                ),
            ],
            fsm_file => 'blocked_decimal_actual_width_top.fsm',
            header => 'blocked_decimal_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=8'd256', .*declared decimal width cannot represent the literal payload value/s,
        'builder rejects decimal actuals whose numeric value does not fit the declared width',
    );
};

subtest 'linked plan builder rejects hex actuals whose value exceeds the declared width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_hex_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_hex_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => "=8'h1FF", target => 'uart_tx.data_in'),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('data_in', 'input', 8, undef),
                ),
            ],
            fsm_file => 'blocked_hex_actual_width_top.fsm',
            header => 'blocked_hex_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=8'h1FF', .*declared hex width cannot represent the literal payload value/s,
        'builder rejects hex actuals whose numeric value does not fit the declared width',
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
        hdl_code => undef,
    );
}

sub port {
    my ($name, $direction, $width, $type) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => $direction,
        width => $width,
        type => $type,
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
