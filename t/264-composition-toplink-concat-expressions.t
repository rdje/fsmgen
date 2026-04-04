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
                        source => "header_bus,status_bus[0],=2'b1_0,=3'o2,=2'h2,payload_bus[2:0]",
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
                port('data_in', 'input', 13, undef),
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
            bit_vector_literal_expr('010'),
            bit_vector_literal_expr('10'),
            slice_expr('payload_bus', 2, 0),
        ),
        'top concat source becomes a typed concat binding expression, including separated binary plus octal and hex literal operands',
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
    /header_bus,status_bus[0],=2'b1_0,=3'o2,=2'h2,payload_bus[2:0]/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<13:data
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
            bit_vector_literal_expr('010'),
            bit_vector_literal_expr('10'),
            slice_expr('payload_bus', 2, 0),
        ),
        'pipeline preserves the typed concat binding in the realized composition plan, including separated binary plus octal and hex literal operands',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{header_bus,\s*status_bus\[0\],\s*2'b10,\s*3'b010,\s*2'b10,\s*payload_bus\[2:0\]\}\)/,
        'generated HDL emits the top concat directly on the child port, including the normalized separated binary plus octal and hex literal operands',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for pure top-concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for explicit top-concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for explicit top-concat toplinks');
};

subtest 'linked plan builder preserves intrinsic-width unsized numeric concat operands' => sub {
    my @ports = (
        port('header_bus', 'input', 2, undef),
        port('payload_bus', 'input', 3, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('unsized_numeric_concat_top'),
        top => FSM::Composition::Top->new(name => 'unsized_numeric_concat_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => 'header_bus,=0b1_0,=0o2,=0xA,=A,payload_bus[2:0]',
                        target => 'uart_tx.data_in',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'uart_tx',
                port('data_in', 'input', 18, undef),
            ),
        ],
        fsm_file => 'unsized_numeric_concat_top.fsm',
        header => 'unsized_numeric_concat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for intrinsic-width unsized concat operands');
    is(scalar(@{$plan->nets}), 0, 'intrinsic-width unsized concat operands do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            bit_vector_literal_expr('10'),
            bit_vector_literal_expr('010'),
            bit_vector_literal_expr('1010'),
            bit_vector_literal_expr('1010'),
            slice_expr('payload_bus', 2, 0),
        ),
        'intrinsic-width unsized binary, octal, prefixed-hex, and bare-hex operands become typed concat literal expressions',
    );
};

subtest 'pipeline and CLI emit intrinsic-width unsized numeric concat operands' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unsized_numeric_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'unsized_numeric_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unsized_numeric_concat_top
  (?ports:public_io
    header_bus<2
    payload_bus<3
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /header_bus,=0b1_0,=0o2,=0xA,=A,payload_bus[2:0]/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  data_in<18:data
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
    is($result->{composition_plan}->lane, 'C3', 'intrinsic-width unsized concat toplinks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            bit_vector_literal_expr('10'),
            bit_vector_literal_expr('010'),
            bit_vector_literal_expr('1010'),
            bit_vector_literal_expr('1010'),
            slice_expr('payload_bus', 2, 0),
        ),
        'pipeline preserves the typed intrinsic-width unsized concat binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{header_bus,\s*2'b10,\s*3'b010,\s*4'b1010,\s*4'b1010,\s*payload_bus\[2:0\]\}\)/,
        'generated HDL emits intrinsic-width unsized concat operands directly on the child port',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for intrinsic-width unsized concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for intrinsic-width unsized concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for intrinsic-width unsized concat toplinks');
};

subtest 'linked plan builder preserves nested concat source groups' => sub {
    my @ports = (
        port('header_bus', 'input', 3, undef),
        port('status_bus', 'input', 2, undef),
        port('payload_bus', 'input', 4, undef),
        port('serial_out', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('nested_concat_top'),
        top => FSM::Composition::Top->new(name => 'nested_concat_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => 'header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}',
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
                port('data_in', 'input', 10, undef),
                port('serial_out', 'output', 1, undef),
            ),
        ],
        fsm_file => 'nested_concat_top.fsm',
        header => 'nested_concat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for nested concat groups');
    is(scalar(@{$plan->nets}), 0, 'nested top-concat child inputs do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            concat_expr(
                bit_select_expr('status_bus', 0),
                bit_vector_literal_expr('10'),
            ),
            concat_expr(
                slice_expr('payload_bus', 3, 2),
                slice_expr('payload_bus', 1, 0),
            ),
        ),
        'nested brace-group concat sources become nested typed concat binding expressions',
    );
    is($bindings{serial_out}{signal_name}, 'serial_out', 'child output still rebinds directly to the top output');
};

subtest 'pipeline and CLI emit nested concat source groups for explicit toplinks' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'nested_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'nested_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:nested_concat_top
  (?ports:public_io
    header_bus<3
    status_bus<2
    payload_bus<4
    serial_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?rtlif:uart_tx
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
    is($result->{composition_plan}->lane, 'C3', 'nested explicit top-concat toplinks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            concat_expr(
                bit_select_expr('status_bus', 0),
                bit_vector_literal_expr('10'),
            ),
            concat_expr(
                slice_expr('payload_bus', 3, 2),
                slice_expr('payload_bus', 1, 0),
            ),
        ),
        'pipeline preserves the typed nested concat binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{header_bus,\s*\{status_bus\[0\],\s*2'b10\},\s*\{payload_bus\[3:2\],\s*payload_bus\[1:0\]\}\}\)/,
        'generated HDL emits the nested concat groups directly on the child port',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for nested top-concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for nested explicit top-concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for nested explicit top-concat toplinks');
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
        qr/uses top expression 'payload_bus\[3:0\],=open', .*concat operands currently accept only top-port names, top-port bit\/slice forms, scalar '=0'\/'=1' actuals, intrinsic-width unsized binary\/decimal\/octal\/hex actuals like '=0b1010', '=170', '=0d170', '=0o7', '=0xA5', or '=A5', and exact-width literal actuals like '=4'b1010', '=4'd10', '=3'o7', or '=4'hA'/s,
        'builder blocks unsupported concat operands through the top-expression boundary',
    );
};

subtest 'linked plan builder preserves intrinsic-width unsized decimal concat operands' => sub {
    my @ports = (
        port('payload_bus', 'input', 4, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('unsized_decimal_concat_top'),
        top => FSM::Composition::Top->new(name => 'unsized_decimal_concat_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => 'payload_bus[3:0],=170,=0d170',
                        target => 'uart_tx.data_in',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'uart_tx',
                port('data_in', 'input', 20, undef),
            ),
        ],
        fsm_file => 'unsized_decimal_concat_top.fsm',
        header => 'unsized_decimal_concat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for intrinsic-width unsized decimal concat operands');
    is(scalar(@{$plan->nets}), 0, 'intrinsic-width unsized decimal concat operands do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            slice_expr('payload_bus', 3, 0),
            bit_vector_literal_expr('10101010'),
            bit_vector_literal_expr('10101010'),
        ),
        'unsized decimal and prefixed unsized decimal operands become typed concat literal expressions with intrinsic value width',
    );
};

subtest 'pipeline and CLI emit intrinsic-width unsized decimal concat operands' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'unsized_decimal_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'unsized_decimal_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:unsized_decimal_concat_top
  (?ports:public_io
    payload_bus<4
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /payload_bus[3:0],=170,=0d170/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  data_in<20:data
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
    is($result->{composition_plan}->lane, 'C3', 'intrinsic-width unsized decimal concat toplinks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            slice_expr('payload_bus', 3, 0),
            bit_vector_literal_expr('10101010'),
            bit_vector_literal_expr('10101010'),
        ),
        'pipeline preserves the typed intrinsic-width unsized decimal concat binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{payload_bus\[3:0\],\s*8'b10101010,\s*8'b10101010\}\)/,
        'generated HDL emits intrinsic-width unsized decimal concat operands directly on the child port',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for intrinsic-width unsized decimal concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for intrinsic-width unsized decimal concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for intrinsic-width unsized decimal concat toplinks');
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
