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
use FSM::Composition::TopSymbols;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    bit_vector_literal_expr
    concat_expr
    repeat_expr
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
                        source => "header_bus,status_bus[0],=2'sb1_0,=3'so2,=4'shA,=8'sd-1,payload_bus[2:0]",
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
                port('data_in', 'input', 23, undef),
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
            bit_vector_literal_expr('1010'),
            bit_vector_literal_expr('11111111'),
            slice_expr('payload_bus', 2, 0),
        ),
        'top concat source becomes a typed concat binding expression, including signed binary, octal, hex, and decimal literal operands',
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
    /header_bus,status_bus[0],=2'sb1_0,=3'so2,=4'shA,=8'sd-1,payload_bus[2:0]/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<23:data
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
            bit_vector_literal_expr('1010'),
            bit_vector_literal_expr('11111111'),
            slice_expr('payload_bus', 2, 0),
        ),
        'pipeline preserves the typed concat binding in the realized composition plan, including signed binary, octal, hex, and decimal literal operands',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{header_bus,\s*status_bus\[0\],\s*2'b10,\s*3'b010,\s*4'b1010,\s*8'b11111111,\s*payload_bus\[2:0\]\}\)/,
        'generated HDL emits the top concat directly on the child port, including the normalized signed binary, octal, hex, and decimal literal operands',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for pure top-concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for explicit top-concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for explicit top-concat toplinks');
};

subtest 'linked plan builder preserves named actual concat operands from composition-root symbols' => sub {
    my @ports = (
        port('header_bus', 'input', 2, undef),
        port('serial_out', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('named_symbol_concat_top'),
        top => FSM::Composition::Top->new(
            name => 'named_symbol_concat_top',
            top_symbols => FSM::Composition::TopSymbols->new(
                constants => {
                    HEADER_NIBBLE => "4'hA",
                },
                enums => {
                    mode => {
                        BUSY => '1',
                    },
                },
            ),
        ),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => 'header_bus,=HEADER_NIBBLE,=mode.BUSY',
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
                port('data_in', 'input', 7, undef),
                port('serial_out', 'output', 1, undef),
            ),
        ],
        fsm_file => 'named_symbol_concat_top.fsm',
        header => 'named_symbol_concat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for named actual concat operands');
    is(scalar(@{$plan->nets}), 0, 'named actual concat operands do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            bit_vector_literal_expr('1010'),
            bit_vector_literal_expr('1'),
        ),
        'composition-root constants and enums become typed concat literal operands',
    );
};

subtest 'pipeline and CLI emit named actual concat operands from composition-root symbols' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'named_symbol_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'named_symbol_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:named_symbol_concat_top
  (+constants
    (HEADER_NIBBLE 4'hA)
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
  (?ports:public_io
    header_bus<7
    serial_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /header_bus[6:5],=HEADER_NIBBLE,=mode.BUSY/uart_tx.header_bus/
    /uart_tx.serial_out/serial_out/
  )
)

(?rtlif:uart_tx
  header_bus<7:data
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

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{header_bus}{connection_expr},
        concat_expr(
            slice_expr('header_bus', 6, 5),
            bit_vector_literal_expr('1010'),
            bit_vector_literal_expr('1'),
        ),
        'pipeline preserves named actual concat operands on the typed concat path',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.header_bus\(\{header_bus\[6:5\],\s*4'b1010,\s*1'b1\}\)/,
        'generated HDL emits composition-root named actual concat operands directly on the child port',
    );

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for composition-root named actual concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for composition-root named actual concat toplinks');
};

subtest 'pipeline and CLI emit intent-sized exact-width concat operands' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'intent_sized_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'intent_sized_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:intent_sized_concat_top
  (?ports:public_io
    packed_out>33
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=5'23,=8'-0xA,=20'x1/packed_out/
    /=5'23,=8'-10,=20'x1/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  data_in<33:data
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
    is($result->{composition_plan}->lane, 'C3', 'intent-sized exact-width concat toplinks stay on the C3 lane');
    is(scalar(@{$result->{composition_plan}->nets}), 0, 'intent-sized exact-width concat toplinks do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            bit_vector_literal_expr('10111'),
            bit_vector_literal_expr('11110110'),
            bit_vector_literal_expr('00000000000000000001'),
        ),
        'pipeline preserves the declared widths and normalized bits for intent-sized concat operands',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/assign\s+packed_out\s*=\s*\{5'b10111,\s*8'b11110110,\s*20'b00000000000000000001\}\s*;/,
        'generated HDL emits intent-sized exact-width concat operands directly on the top output',
    );
    like(
        $hdl,
        qr/\.data_in\(\{5'b10111,\s*8'b11110110,\s*20'b00000000000000000001\}\)/,
        'generated HDL emits intent-sized exact-width concat operands directly on the child port',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for pure intent-sized concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for intent-sized exact-width concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for intent-sized exact-width concat toplinks');
};

subtest 'linked plan builder preserves intrinsic-width SV-style unsized numeric concat operands' => sub {
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
                        source => "header_bus,='b1_0,='o2,='d10,='hA,payload_bus[2:0]",
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
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for intrinsic-width SV-style unsized concat operands');
    is(scalar(@{$plan->nets}), 0, 'intrinsic-width SV-style unsized concat operands do not force synthetic carrier nets');

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
        'intrinsic-width SV-style unsized binary, octal, decimal, and hex operands become typed concat literal expressions',
    );
};

subtest 'pipeline and CLI emit intrinsic-width SV-style unsized numeric concat operands' => sub {
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
    /header_bus,='b1_0,='o2,='d10,='hA,payload_bus[2:0]/uart_tx.data_in/
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
    is($result->{composition_plan}->lane, 'C3', 'intrinsic-width SV-style unsized concat toplinks stay on the C3 lane');

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
        'pipeline preserves the typed intrinsic-width SV-style unsized concat binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{header_bus,\s*2'b10,\s*3'b010,\s*4'b1010,\s*4'b1010,\s*payload_bus\[2:0\]\}\)/,
        'generated HDL emits intrinsic-width SV-style unsized concat operands directly on the child port',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for intrinsic-width SV-style unsized concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for intrinsic-width SV-style unsized concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for intrinsic-width SV-style unsized concat toplinks');
};

subtest 'linked plan builder preserves intrinsic-width SV-style unsized signed based concat operands' => sub {
    my @ports = (
        port('header_bus', 'input', 2, undef),
        port('payload_bus', 'input', 3, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('signed_unsized_numeric_concat_top'),
        top => FSM::Composition::Top->new(name => 'signed_unsized_numeric_concat_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => "header_bus,='sb1010,='so7,='shA,payload_bus[2:0]",
                        target => 'uart_tx.data_in',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'uart_tx',
                port('data_in', 'input', 16, undef),
            ),
        ],
        fsm_file => 'signed_unsized_numeric_concat_top.fsm',
        header => 'signed_unsized_numeric_concat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for intrinsic-width SV-style unsized signed concat operands');
    is(scalar(@{$plan->nets}), 0, 'intrinsic-width SV-style unsized signed concat operands do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            bit_vector_literal_expr('1010'),
            bit_vector_literal_expr('111'),
            bit_vector_literal_expr('1010'),
            slice_expr('payload_bus', 2, 0),
        ),
        'intrinsic-width SV-style unsized signed binary, octal, and hex operands become typed concat literal expressions',
    );
};

subtest 'pipeline and CLI emit intrinsic-width SV-style unsized signed based concat operands' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'signed_unsized_numeric_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'signed_unsized_numeric_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:signed_unsized_numeric_concat_top
  (?ports:public_io
    header_bus<2
    payload_bus<3
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /header_bus,='sb1010,='so7,='shA,payload_bus[2:0]/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  data_in<16:data
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
    is($result->{composition_plan}->lane, 'C3', 'intrinsic-width SV-style unsized signed concat toplinks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            bit_vector_literal_expr('1010'),
            bit_vector_literal_expr('111'),
            bit_vector_literal_expr('1010'),
            slice_expr('payload_bus', 2, 0),
        ),
        'pipeline preserves the typed intrinsic-width SV-style unsized signed concat binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{header_bus,\s*4'b1010,\s*3'b111,\s*4'b1010,\s*payload_bus\[2:0\]\}\)/,
        'generated HDL emits intrinsic-width SV-style unsized signed concat operands directly on the child port',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for intrinsic-width SV-style unsized signed concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for intrinsic-width SV-style unsized signed concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for intrinsic-width SV-style unsized signed concat toplinks');
};

subtest 'linked plan builder preserves intrinsic-width unsized signed decimal concat operands' => sub {
    my @ports = (
        port('payload_bus', 'input', 3, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('signed_decimal_concat_top'),
        top => FSM::Composition::Top->new(name => 'signed_decimal_concat_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => "payload_bus[2:0],=-1,=0d-2,='sd-3",
                        target => 'uart_tx.data_in',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'uart_tx',
                port('data_in', 'input', 9, undef),
            ),
        ],
        fsm_file => 'signed_decimal_concat_top.fsm',
        header => 'signed_decimal_concat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for intrinsic-width unsized signed decimal concat operands');
    is(scalar(@{$plan->nets}), 0, 'intrinsic-width unsized signed decimal concat operands do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            slice_expr('payload_bus', 2, 0),
            bit_vector_literal_expr('1'),
            bit_vector_literal_expr('10'),
            bit_vector_literal_expr('101'),
        ),
        'unsized signed decimal operands become typed concat literal expressions with intrinsic signed width',
    );
};

subtest 'pipeline and CLI emit intrinsic-width unsized signed decimal concat operands' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'signed_decimal_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'signed_decimal_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:signed_decimal_concat_top
  (?ports:public_io
    payload_bus<3
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /payload_bus[2:0],=-1,=0d-2,='sd-3/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  data_in<9:data
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
    is($result->{composition_plan}->lane, 'C3', 'intrinsic-width unsized signed decimal concat toplinks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            slice_expr('payload_bus', 2, 0),
            bit_vector_literal_expr('1'),
            bit_vector_literal_expr('10'),
            bit_vector_literal_expr('101'),
        ),
        'pipeline preserves the typed intrinsic-width unsized signed decimal concat binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{payload_bus\[2:0\],\s*1'b1,\s*2'b10,\s*3'b101\}\)/,
        'generated HDL emits intrinsic-width unsized signed decimal concat operands directly on the child port',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for intrinsic-width unsized signed decimal concat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for intrinsic-width unsized signed decimal concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for intrinsic-width unsized signed decimal concat toplinks');
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

subtest 'linked plan builder preserves bounded repeat source groups' => sub {
    my @ports = (
        port('header_bus', 'input', 2, undef),
        port('status_bus', 'input', 1, undef),
        port('payload_bus', 'input', 2, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('repeat_concat_top'),
        top => FSM::Composition::Top->new(name => 'repeat_concat_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => 'header_bus,{3{status_bus[0]}},payload_bus[1:0]',
                        target => 'uart_tx.data_in',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'uart_tx',
                port('data_in', 'input', 7, undef),
            ),
        ],
        fsm_file => 'repeat_concat_top.fsm',
        header => 'repeat_concat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for repeat source groups');
    is(scalar(@{$plan->nets}), 0, 'repeat source groups over top operands do not force synthetic carrier nets');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            repeat_expr(3, bit_select_expr('status_bus', 0)),
            slice_expr('payload_bus', 1, 0),
        ),
        'repeat source groups become typed repeat expressions inside the concat binding tree',
    );
};

subtest 'pipeline and CLI emit bounded repeat source groups for explicit toplinks' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'repeat_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'repeat_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:repeat_concat_top
  (?ports:public_io
    header_bus<2
    status_bus
    payload_bus<2
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /header_bus,{3{status_bus[0]}},payload_bus[1:0]/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  data_in<7:data
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
    is($result->{composition_plan}->lane, 'C3', 'repeat explicit top-concat toplinks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        concat_expr(
            signal_ref_expr('header_bus'),
            repeat_expr(3, bit_select_expr('status_bus', 0)),
            slice_expr('payload_bus', 1, 0),
        ),
        'pipeline preserves the typed repeat binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like(
        $hdl,
        qr/\.data_in\(\{header_bus,\s*\{3\{status_bus\[0\]\}\},\s*payload_bus\[1:0\]\}\)/,
        'generated HDL emits the bounded repeat group directly on the child port',
    );
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for top-only repeat bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for bounded repeat explicit toplinks');
    ok(-e $output_path, 'CLI writes HDL for bounded repeat explicit toplinks');
};

subtest 'child-output repeat groups share deterministic carriers and direct top-output assignments' => sub {
    my @ports = (
        port('packed_out', 'output', 4, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('child_repeat_top'),
        top => FSM::Composition::Top->new(name => 'child_repeat_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => '{2{producer.serial_lo}}',
                        target => 'consumer.data_in',
                    ),
                    FSM::Composition::Link->new(
                        source => '{2{producer.serial_lo}}',
                        target => 'packed_out',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'producer',
                port('serial_lo', 'output', 2, undef),
            ),
            realized_instance(
                'rtl',
                'consumer',
                port('data_in', 'input', 4, undef),
            ),
        ],
        fsm_file => 'child_repeat_top.fsm',
        header => 'child_repeat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for child-output repeat groups');
    is_deeply(
        [map { $_->name } @{$plan->nets}],
        ['comp_link_producer_serial_lo'],
        'child-output repeat groups allocate one deterministic base carrier per repeated child-output family',
    );

    my %bindings_by_instance = map { $_->instance_name => $_ } @{$plan->instances};
    my %producer_bindings = map { $_->{port_name} => $_ } @{$bindings_by_instance{producer}->port_bindings};
    my %consumer_bindings = map { $_->{port_name} => $_ } @{$bindings_by_instance{consumer}->port_bindings};

    is($producer_bindings{serial_lo}{signal_name}, 'comp_link_producer_serial_lo', 'repeated child output still binds once to its shared base carrier');
    is_deeply(
        $consumer_bindings{data_in}{connection_expr},
        repeat_expr(2, signal_ref_expr('comp_link_producer_serial_lo')),
        'child-output repeat groups become typed repeat bindings over the shared base carrier',
    );
    is_deeply(
        $plan->auxiliary_assignments,
        [
            '    assign packed_out = {2{comp_link_producer_serial_lo}};',
        ],
        'child-output repeat groups also drive declared top outputs through direct assignments over that carrier',
    );
};

subtest 'pipeline and CLI emit child-output repeat groups through shared carriers' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'child_repeat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'child_repeat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:child_repeat_top
  (?ports:public_io
    packed_out>4
  )
  (?rtl:producer)
  (?rtl:consumer)
  (?toplink:wiring
    /{2{producer.serial_lo}}/consumer.data_in/
    /{2{producer.serial_lo}}/packed_out/
  )
)

(?rtlif:producer
  serial_lo>2:data
)

(?rtlif:consumer
  data_in<4:data
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
    is($result->{composition_plan}->lane, 'C3', 'child-output repeat toplinks stay on the C3 lane');

    my %instances = map { $_->instance_name => $_ } @{$result->{composition_plan}->instances};
    my %consumer_bindings = map { $_->{port_name} => $_ } @{$instances{consumer}->port_bindings};
    is_deeply(
        $consumer_bindings{data_in}{connection_expr},
        repeat_expr(2, signal_ref_expr('comp_link_producer_serial_lo')),
        'pipeline preserves the typed child-output repeat binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bwire\s+\[1:0\]\s+comp_link_producer_serial_lo\s*;/s, 'generated HDL emits the shared carrier wire for the repeated child-output family');
    like($hdl, qr/\.serial_lo\(comp_link_producer_serial_lo\)/, 'generated HDL binds the producer output to its shared repeat carrier');
    like($hdl, qr/\.data_in\(\{2\{comp_link_producer_serial_lo\}\}\)/, 'generated HDL emits the child-output repeat directly on the consumer input');
    like($hdl, qr/assign packed_out = \{2\{comp_link_producer_serial_lo\}\};/, 'generated HDL emits the child-output repeat directly on the top output assignment');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for child-output repeat toplinks');
    ok(-e $output_path, 'CLI writes HDL for child-output repeat toplinks');
};

subtest 'child-output concat operands share deterministic carriers and direct top-output assignments' => sub {
    my @ports = (
        port('header_bus', 'input', 2, undef),
        port('packed_out', 'output', 8, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
        lane => 'C3',
        composition_spec => composition_spec('child_concat_top'),
        top => FSM::Composition::Top->new(name => 'child_concat_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        toplinks => [
            FSM::Composition::TopLink->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(
                        source => 'producer.serial_hi[3:0],header_bus,producer.serial_lo',
                        target => 'consumer.data_in',
                    ),
                    FSM::Composition::Link->new(
                        source => 'producer.serial_hi[3:0],header_bus,producer.serial_lo',
                        target => 'packed_out',
                    ),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'producer',
                port('serial_hi', 'output', 4, undef),
                port('serial_lo', 'output', 2, undef),
            ),
            realized_instance(
                'rtl',
                'consumer',
                port('data_in', 'input', 8, undef),
            ),
        ],
        fsm_file => 'child_concat_top.fsm',
        header => 'child_concat_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for child-output concat operands');
    is_deeply(
        [map { $_->name } @{$plan->nets}],
        ['comp_link_producer_serial_hi', 'comp_link_producer_serial_lo'],
        'child-output concat operands allocate one deterministic base carrier per child-output family',
    );

    my %bindings_by_instance = map { $_->instance_name => $_ } @{$plan->instances};
    my %producer_bindings = map { $_->{port_name} => $_ } @{$bindings_by_instance{producer}->port_bindings};
    my %consumer_bindings = map { $_->{port_name} => $_ } @{$bindings_by_instance{consumer}->port_bindings};

    is($producer_bindings{serial_hi}{signal_name}, 'comp_link_producer_serial_hi', 'high child output binds once to its shared base carrier');
    is($producer_bindings{serial_lo}{signal_name}, 'comp_link_producer_serial_lo', 'low child output binds once to its shared base carrier');
    is_deeply(
        $consumer_bindings{data_in}{connection_expr},
        concat_expr(
            slice_expr('comp_link_producer_serial_hi', 3, 0),
            signal_ref_expr('header_bus'),
            signal_ref_expr('comp_link_producer_serial_lo'),
        ),
        'child-output concat operands become a typed concat binding over base carriers and top-port refs',
    );
    is_deeply(
        $plan->auxiliary_assignments,
        [
            '    assign packed_out = {comp_link_producer_serial_hi[3:0], header_bus, comp_link_producer_serial_lo};',
        ],
        'child-output concat operands also drive declared top outputs through direct assignments over those carriers',
    );
};

subtest 'pipeline and CLI emit child-output concat operands through shared carriers' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'child_concat_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'child_concat_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:child_concat_top
  (?ports:public_io
    header_bus<2
    packed_out>8
  )
  (?rtl:producer)
  (?rtl:consumer)
  (?toplink:wiring
    /producer.serial_hi[3:0],header_bus,producer.serial_lo/consumer.data_in/
    /producer.serial_hi[3:0],header_bus,producer.serial_lo/packed_out/
  )
)

(?rtlif:producer
  serial_hi>4:data
  serial_lo>2:data
)

(?rtlif:consumer
  data_in<8:data
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
    is($result->{composition_plan}->lane, 'C3', 'child-output concat toplinks stay on the C3 lane');

    my %instances = map { $_->instance_name => $_ } @{$result->{composition_plan}->instances};
    my %consumer_bindings = map { $_->{port_name} => $_ } @{$instances{consumer}->port_bindings};
    is_deeply(
        $consumer_bindings{data_in}{connection_expr},
        concat_expr(
            slice_expr('comp_link_producer_serial_hi', 3, 0),
            signal_ref_expr('header_bus'),
            signal_ref_expr('comp_link_producer_serial_lo'),
        ),
        'pipeline preserves the typed child-output concat binding in the realized composition plan',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/\bwire\s+\[3:0\]\s+comp_link_producer_serial_hi\s*;/s, 'generated HDL emits the shared carrier wire for the first child-output concat operand');
    like($hdl, qr/\bwire\s+\[1:0\]\s+comp_link_producer_serial_lo\s*;/s, 'generated HDL emits the shared carrier wire for the second child-output concat operand');
    like($hdl, qr/\.serial_hi\(comp_link_producer_serial_hi\)/, 'generated HDL binds the first producer output to its shared carrier');
    like($hdl, qr/\.serial_lo\(comp_link_producer_serial_lo\)/, 'generated HDL binds the second producer output to its shared carrier');
    like($hdl, qr/\.data_in\(\{comp_link_producer_serial_hi\[3:0\],\s*header_bus,\s*comp_link_producer_serial_lo\}\)/, 'generated HDL emits the child-output concat directly on the consumer input');
    like($hdl, qr/assign packed_out = \{comp_link_producer_serial_hi\[3:0\],\s*header_bus,\s*comp_link_producer_serial_lo\};/, 'generated HDL emits the child-output concat directly on the top output assignment');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for child-output concat toplinks');
    ok(-e $output_path, 'CLI writes HDL for child-output concat toplinks');
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
        qr/uses top expression 'payload_bus\[3:0\],=open', .*concat operands currently accept only top-port names, top-port bit\/slice forms, child endpoints like 'producer\.payload', child-output bit\/slice forms like 'producer\.payload\[3\]' or 'producer\.payload\[7:4\]', repeat groups like '\{4\{status_bus\[0\]\}\}', scalar '=0'\/'=1' actuals, named literal actuals from composition-root '\+constants' \/ '\+enums' or imported packages like '=RESET_BYTE', '=mode\.BUSY', '=shared\.RESET_BYTE', or '=shared\.mode\.BUSY', intrinsic-width unsized binary\/decimal\/octal\/hex actuals like '=0b1010', '='b1010', '=170', '=0d170', '='d170', '=0o7', '='o7', '=0xA5', '='hA5', or '=A5', intrinsic-width unsized signed decimal actuals like '=-1', '=0d-1', or '='sd-1', intrinsic-width unsized signed binary\/octal\/hex actuals like '='sb1010', '='so7', or '='shA5', and exact-width literal actuals like '=4'b1010', '=4'sb1010', '=4'd10', '=8'sd-1', '=3'o7', '=3'so7', '=4'hA', or '=4'shA'/s,
        'builder blocks unsupported concat operands through the top-expression boundary',
    );
};

subtest 'linked plan builder rejects ambiguous bare bitstring-like concat actuals explicitly' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_ambiguous_concat_actual_top'),
            top => FSM::Composition::Top->new(name => 'blocked_ambiguous_concat_actual_top'),
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
                            source => 'payload_bus[3:0],=00001110',
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
            fsm_file => 'blocked_ambiguous_concat_actual_top.fsm',
            header => 'blocked_ambiguous_concat_actual_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses literal actual '=00001110' inside a top expression.*ambiguous bare integer literal.*=0b00001110.*=N'b00001110.*=0d00001110/s,
        'builder rejects ambiguous bare concat actuals with an explicit remediation hint',
    );
};

subtest 'linked plan builder rejects out-of-range child-output concat operands' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_child_concat_top'),
            top => FSM::Composition::Top->new(name => 'blocked_child_concat_top'),
            ports_block => FSM::Composition::PortsBlock->new(
                name => 'public_io',
                ports => [port('header_bus', 'input', 2, undef)],
            ),
            ports => [port('header_bus', 'input', 2, undef)],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(
                            source => 'producer.payload[8],header_bus',
                            target => 'consumer.data_in',
                        ),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'producer',
                    port('payload', 'output', 8, undef),
                ),
                realized_instance(
                    'rtl',
                    'consumer',
                    port('data_in', 'input', 3, undef),
                ),
            ],
            fsm_file => 'blocked_child_concat_top.fsm',
            header => 'blocked_child_concat_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses child expression 'producer\.payload\[8\]', .*bit index 8 falls outside declared width 8 of child endpoint 'producer\.payload'/s,
        'builder blocks out-of-range child-output concat operands through child-expression diagnostics',
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
