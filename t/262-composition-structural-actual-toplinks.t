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

subtest 'linked plan builder preserves numeric and open toplinks as typed actual bindings' => sub {
    my @ports = (
        port('core_clk', 'input', 1, 'clock'),
        port('rst_async_n', 'input', 1, 'reset'),
        port('default_data', 'output', 8, undef),
        port('one_data', 'output', 8, undef),
        port('decimal_data', 'output', 8, undef),
        port('signed_decimal_data', 'output', 8, undef),
        port('signed_literal_data', 'output', 8, undef),
        port('octal_data', 'output', 8, undef),
        port('hex_data', 'output', 8, undef),
        port('prefixed_binary_data', 'output', 8, undef),
        port('prefixed_decimal_data', 'output', 8, undef),
        port('prefixed_octal_data', 'output', 8, undef),
        port('prefixed_hex_data', 'output', 8, undef),
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
                    FSM::Composition::Link->new(source => "=8'b1010_0101", target => 'default_data'),
                    FSM::Composition::Link->new(source => '=1', target => 'one_data'),
                    FSM::Composition::Link->new(source => '=1_70', target => 'decimal_data'),
                    FSM::Composition::Link->new(source => '=-1', target => 'signed_decimal_data'),
                    FSM::Composition::Link->new(source => "=8'sd-1", target => 'signed_literal_data'),
                    FSM::Composition::Link->new(source => "=8'o2_45", target => 'octal_data'),
                    FSM::Composition::Link->new(source => '=A_5', target => 'hex_data'),
                    FSM::Composition::Link->new(source => '=0b1010_0101', target => 'prefixed_binary_data'),
                    FSM::Composition::Link->new(source => '=0d1_70', target => 'prefixed_decimal_data'),
                    FSM::Composition::Link->new(source => '=0o2_45', target => 'prefixed_octal_data'),
                    FSM::Composition::Link->new(source => '=0xA_5', target => 'prefixed_hex_data'),
                    FSM::Composition::Link->new(source => "=8'b1010_0101", target => 'uart_tx.data_in'),
                    FSM::Composition::Link->new(source => '=0', target => 'uart_tx.zero_data_in'),
                    FSM::Composition::Link->new(source => '=1', target => 'uart_tx.one_data_in'),
                    FSM::Composition::Link->new(source => '=1_70', target => 'uart_tx.unsized_decimal_data_in'),
                    FSM::Composition::Link->new(source => '=-1', target => 'uart_tx.signed_decimal_data_in'),
                    FSM::Composition::Link->new(source => "=8'sd-1", target => 'uart_tx.signed_literal_data_in'),
                    FSM::Composition::Link->new(source => '=0o2_45', target => 'uart_tx.unsized_octal_data_in'),
                    FSM::Composition::Link->new(source => '=A_5', target => 'uart_tx.unsized_hex_data_in'),
                    FSM::Composition::Link->new(source => '=0b1010_0101', target => 'uart_tx.prefixed_binary_data_in'),
                    FSM::Composition::Link->new(source => '=0d1_70', target => 'uart_tx.prefixed_decimal_data_in'),
                    FSM::Composition::Link->new(source => '=0xA_5', target => 'uart_tx.prefixed_hex_data_in'),
                    FSM::Composition::Link->new(source => "=8'd1_65", target => 'uart_tx.decimal_data_in'),
                    FSM::Composition::Link->new(source => "=8'o2_45", target => 'uart_tx.octal_data_in'),
                    FSM::Composition::Link->new(source => "=8'hA_5", target => 'uart_tx.hex_data_in'),
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
                port('zero_data_in', 'input', 8, undef),
                port('one_data_in', 'input', 8, undef),
                port('unsized_decimal_data_in', 'input', 8, undef),
                port('signed_decimal_data_in', 'input', 8, undef),
                port('signed_literal_data_in', 'input', 8, undef),
                port('unsized_octal_data_in', 'input', 8, undef),
                port('unsized_hex_data_in', 'input', 8, undef),
                port('prefixed_binary_data_in', 'input', 8, undef),
                port('prefixed_decimal_data_in', 'input', 8, undef),
                port('prefixed_hex_data_in', 'input', 8, undef),
                port('decimal_data_in', 'input', 8, undef),
                port('octal_data_in', 'input', 8, undef),
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
    is_deeply(
        $plan->auxiliary_assignments,
        [
            "    assign default_data = 8'b10100101;",
            "    assign one_data = 8'b00000001;",
            "    assign decimal_data = 8'b10101010;",
            "    assign signed_decimal_data = 8'b11111111;",
            "    assign signed_literal_data = 8'b11111111;",
            "    assign octal_data = 8'b10100101;",
            "    assign hex_data = 8'b10100101;",
            "    assign prefixed_binary_data = 8'b10100101;",
            "    assign prefixed_decimal_data = 8'b10101010;",
            "    assign prefixed_octal_data = 8'b10100101;",
            "    assign prefixed_hex_data = 8'b10100101;",
        ],
        'direct numeric actual top-output bindings become direct auxiliary assignments',
    );

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
    is($bindings{zero_data_in}{signal_name} // '', '', 'scalar zero actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{zero_data_in}{connection_expr},
        bit_vector_literal_expr('00000000'),
        'scalar zero explicit toplink expands to the exact target width for child inputs',
    );
    is($bindings{one_data_in}{signal_name} // '', '', 'scalar one actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{one_data_in}{connection_expr},
        bit_vector_literal_expr('00000001'),
        'scalar one explicit toplink expands to the exact target width for child inputs',
    );
    is($bindings{unsized_decimal_data_in}{signal_name} // '', '', 'unsized decimal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{unsized_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10101010'),
        'unsized decimal explicit toplink widens to the exact target width for child inputs',
    );
    is($bindings{signed_decimal_data_in}{signal_name} // '', '', 'unsized signed decimal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{signed_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('11111111'),
        'unsized signed decimal explicit toplink lowers through exact-width two-complement bits for child inputs',
    );
    is($bindings{signed_literal_data_in}{signal_name} // '', '', 'signed decimal literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{signed_literal_data_in}{connection_expr},
        bit_vector_literal_expr('11111111'),
        'signed decimal literal explicit toplink becomes the same typed bit-vector actual binding',
    );
    is($bindings{unsized_octal_data_in}{signal_name} // '', '', 'unsized octal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{unsized_octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'unsized octal explicit toplink widens to the exact target width for child inputs',
    );
    is($bindings{unsized_hex_data_in}{signal_name} // '', '', 'unsized hex actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{unsized_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'unsized hex explicit toplink widens to the exact target width for child inputs',
    );
    is($bindings{prefixed_binary_data_in}{signal_name} // '', '', 'prefixed binary actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{prefixed_binary_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'prefixed binary explicit toplink widens to the exact target width for child inputs',
    );
    is($bindings{prefixed_decimal_data_in}{signal_name} // '', '', 'prefixed decimal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{prefixed_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10101010'),
        'prefixed decimal explicit toplink widens to the exact target width for child inputs',
    );
    is($bindings{prefixed_hex_data_in}{signal_name} // '', '', 'prefixed hex actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{prefixed_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'prefixed hex explicit toplink widens to the exact target width for child inputs',
    );
    is($bindings{decimal_data_in}{signal_name} // '', '', 'decimal literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'decimal literal explicit toplink becomes the same typed bit-vector actual binding',
    );
    is($bindings{octal_data_in}{signal_name} // '', '', 'octal literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'octal literal explicit toplink becomes the same typed bit-vector actual binding',
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

subtest 'pipeline and CLI emit structural numeric and open actuals for explicit toplinks' => sub {
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
        default_data>8
        one_data>8
        decimal_data>8
        signed_decimal_data>8
        signed_literal_data>8
        octal_data>8
        hex_data>8
        prefixed_binary_data>8
        prefixed_decimal_data>8
        prefixed_octal_data>8
        prefixed_hex_data>8
        serial_out>
      )
      (?rtl:uart_tx)
      (?toplink:wiring
        /=8'b1010_0101/default_data/
        /=1/one_data/
        /=1_70/decimal_data/
        /=-1/signed_decimal_data/
        /=8'sd-1/signed_literal_data/
        /=8'o2_45/octal_data/
        /=A_5/hex_data/
        /=0b1010_0101/prefixed_binary_data/
        /=0d1_70/prefixed_decimal_data/
        /=0o2_45/prefixed_octal_data/
        /=0xA_5/prefixed_hex_data/
        /=8'b1010_0101/uart_tx.data_in/
        /=0/uart_tx.zero_data_in/
        /=1/uart_tx.one_data_in/
        /=1_70/uart_tx.unsized_decimal_data_in/
        /=-1/uart_tx.signed_decimal_data_in/
        /=8'sd-1/uart_tx.signed_literal_data_in/
        /=0o2_45/uart_tx.unsized_octal_data_in/
        /=A_5/uart_tx.unsized_hex_data_in/
        /=0b1010_0101/uart_tx.prefixed_binary_data_in/
        /=0d1_70/uart_tx.prefixed_decimal_data_in/
        /=0xA_5/uart_tx.prefixed_hex_data_in/
        /=8'd1_65/uart_tx.decimal_data_in/
        /=8'o2_45/uart_tx.octal_data_in/
        /=8'hA_5/uart_tx.hex_data_in/
        /=open/uart_tx.enable/
    /uart_tx.serial_out/serial_out/
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  zero_data_in<8:data
  one_data_in<8:data
  unsized_decimal_data_in<8:data
  signed_decimal_data_in<8:data
  signed_literal_data_in<8:data
  unsized_octal_data_in<8:data
  unsized_hex_data_in<8:data
  prefixed_binary_data_in<8:data
  prefixed_decimal_data_in<8:data
  prefixed_hex_data_in<8:data
  decimal_data_in<8:data
  octal_data_in<8:data
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
        $bindings{zero_data_in}{connection_expr},
        bit_vector_literal_expr('00000000'),
        'pipeline preserves the widened scalar zero binding in the realized composition plan',
    );
    is_deeply(
        $bindings{one_data_in}{connection_expr},
        bit_vector_literal_expr('00000001'),
        'pipeline preserves the widened scalar one binding in the realized composition plan',
    );
    is_deeply(
        $bindings{unsized_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10101010'),
        'pipeline preserves the widened unsized decimal binding in the realized composition plan',
    );
    is_deeply(
        $bindings{signed_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('11111111'),
        'pipeline preserves the widened unsized signed decimal binding in the realized composition plan',
    );
    is_deeply(
        $bindings{signed_literal_data_in}{connection_expr},
        bit_vector_literal_expr('11111111'),
        'pipeline preserves the typed signed decimal literal actual binding in the realized composition plan',
    );
    is_deeply(
        $bindings{unsized_octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the widened unsized octal binding in the realized composition plan',
    );
    is_deeply(
        $bindings{unsized_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the widened unsized hex binding in the realized composition plan',
    );
    is_deeply(
        $bindings{prefixed_binary_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the widened prefixed binary binding in the realized composition plan',
    );
    is_deeply(
        $bindings{prefixed_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10101010'),
        'pipeline preserves the widened prefixed decimal binding in the realized composition plan',
    );
    is_deeply(
        $bindings{prefixed_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the widened prefixed hex binding in the realized composition plan',
    );
    is_deeply(
        $bindings{decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the typed decimal literal actual binding in the realized composition plan',
    );
    is_deeply(
        $bindings{octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the typed octal literal actual binding in the realized composition plan',
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
    like($hdl, qr/assign default_data = 8'b10100101;/, 'generated HDL emits the literal actual directly on the top output');
    like($hdl, qr/assign one_data = 8'b00000001;/, 'generated HDL emits the widened scalar one actual directly on the top output');
    like($hdl, qr/assign decimal_data = 8'b10101010;/, 'generated HDL emits the widened unsized decimal actual directly on the top output');
    like($hdl, qr/assign signed_decimal_data = 8'b11111111;/, 'generated HDL emits the widened unsized signed decimal actual directly on the top output');
    like($hdl, qr/assign signed_literal_data = 8'b11111111;/, 'generated HDL emits the signed decimal literal actual directly on the top output');
    like($hdl, qr/assign octal_data = 8'b10100101;/, 'generated HDL emits the octal literal actual directly on the top output');
    like($hdl, qr/assign hex_data = 8'b10100101;/, 'generated HDL emits the widened unsized hex actual directly on the top output');
    like($hdl, qr/assign prefixed_binary_data = 8'b10100101;/, 'generated HDL emits the widened prefixed binary actual directly on the top output');
    like($hdl, qr/assign prefixed_decimal_data = 8'b10101010;/, 'generated HDL emits the widened prefixed decimal actual directly on the top output');
    like($hdl, qr/assign prefixed_octal_data = 8'b10100101;/, 'generated HDL emits the widened prefixed octal actual directly on the top output');
    like($hdl, qr/assign prefixed_hex_data = 8'b10100101;/, 'generated HDL emits the widened prefixed hex actual directly on the top output');
    like($hdl, qr/\.data_in\(8'b10100101\)/, 'generated HDL emits the literal actual directly on the child port');
    like($hdl, qr/\.zero_data_in\(8'b00000000\)/, 'generated HDL emits the widened scalar zero actual directly on the child port');
    like($hdl, qr/\.one_data_in\(8'b00000001\)/, 'generated HDL emits the widened scalar one actual directly on the child port');
    like($hdl, qr/\.unsized_decimal_data_in\(8'b10101010\)/, 'generated HDL emits the widened unsized decimal actual directly on the child port');
    like($hdl, qr/\.signed_decimal_data_in\(8'b11111111\)/, 'generated HDL emits the widened unsized signed decimal actual directly on the child port');
    like($hdl, qr/\.signed_literal_data_in\(8'b11111111\)/, 'generated HDL emits the signed decimal literal actual directly on the child port');
    like($hdl, qr/\.unsized_octal_data_in\(8'b10100101\)/, 'generated HDL emits the widened unsized octal actual directly on the child port');
    like($hdl, qr/\.unsized_hex_data_in\(8'b10100101\)/, 'generated HDL emits the widened unsized hex actual directly on the child port');
    like($hdl, qr/\.prefixed_binary_data_in\(8'b10100101\)/, 'generated HDL emits the widened prefixed binary actual directly on the child port');
    like($hdl, qr/\.prefixed_decimal_data_in\(8'b10101010\)/, 'generated HDL emits the widened prefixed decimal actual directly on the child port');
    like($hdl, qr/\.prefixed_hex_data_in\(8'b10100101\)/, 'generated HDL emits the widened prefixed hex actual directly on the child port');
    like($hdl, qr/\.decimal_data_in\(8'b10100101\)/, 'generated HDL emits the decimal literal actual directly on the child port');
    like($hdl, qr/\.octal_data_in\(8'b10100101\)/, 'generated HDL emits the octal literal actual directly on the child port');
    like($hdl, qr/\.hex_data_in\(8'b10100101\)/, 'generated HDL emits the hex literal actual directly on the child port');
    like($hdl, qr/\.enable\(\)/, 'generated HDL emits the open actual directly on the child port');
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for pure actual bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for explicit structural-actual toplinks');
    ok(-e $output_path, 'CLI writes HDL for explicit structural-actual toplinks');
};

subtest 'linked plan builder rejects open actual sources that do not target realized child inputs' => sub {
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
                        FSM::Composition::Link->new(source => '=open', target => 'serial_out'),
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
        qr/uses actual source '=open' as an explicit link source, .*'=open' currently targets only realized child input ports, not declared top outputs/s,
        'builder still blocks open actuals from driving declared top outputs',
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
        qr/uses actual endpoint '=open' as an explicit link target, .*only allows '=open', scalar '=0'\/'=1', unsized binary\/decimal\/octal\/hex direct actuals, unsized signed decimal direct actuals like '=-1' or '=0d-1', and exact-width binary\/decimal\/octal\/hex literal actuals plus exact-width signed decimal literal actuals like '=8'sd-1' as link sources into realized child input ports, plus literal actuals into declared top outputs/s,
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
                    FSM::Composition::Link->new(source => '=0q7', target => 'uart_tx.data_in'),
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
        qr/uses actual endpoint '=0q7', .*currently accepts only '=open', scalar '=0'\/'=1', unsized binary\/decimal\/octal\/hex direct actual forms like '=0b10', '=0d10', '=0o7', '=0xA', '=170', or '=A5', unsized signed decimal direct actual forms like '=-1' or '=0d-1', or exact-width binary\/decimal\/octal\/hex literal forms like '=8'b10100101', '=8'd165', '=8'o245', or '=8'hA5' plus exact-width signed decimal literal forms like '=8'sd-1'/s,
        'builder still blocks unsupported unsized literal spellings outside the widened direct unsized-numeric slice',
    );
};

subtest 'linked plan builder rejects unsized signed decimal actuals whose value exceeds the signed direct target width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_signed_decimal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_signed_decimal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => '=-129', target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_unsized_signed_decimal_actual_width_top.fsm',
            header => 'blocked_unsized_signed_decimal_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=-129', .*unsized signed decimal actual value does not fit signed direct target width 8/s,
        'builder rejects unsized signed decimal actuals whose numeric value does not fit the signed direct target width',
    );
};

subtest 'linked plan builder rejects unsized decimal actuals whose value exceeds the direct target width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_decimal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_decimal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => '=256', target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_unsized_decimal_actual_width_top.fsm',
            header => 'blocked_unsized_decimal_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=256', .*unsized decimal actual value does not fit direct target width 8/s,
        'builder rejects unsized decimal actuals whose numeric value does not fit the direct target width',
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

subtest 'linked plan builder rejects signed decimal actuals whose value exceeds the declared signed width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_signed_decimal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_signed_decimal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => "=8'sd128", target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_signed_decimal_actual_width_top.fsm',
            header => 'blocked_signed_decimal_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=8'sd128', .*declared signed decimal width cannot represent the literal payload value/s,
        'builder rejects signed decimal actuals whose numeric value does not fit the declared signed width',
    );
};

subtest 'linked plan builder rejects unsized hex actuals whose value exceeds the direct target width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_hex_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_hex_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => '=0x1FF', target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_unsized_hex_actual_width_top.fsm',
            header => 'blocked_unsized_hex_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=0x1FF', .*unsized hex actual value does not fit direct target width 8/s,
        'builder rejects unsized hex actuals whose numeric value does not fit the direct target width',
    );
};

subtest 'linked plan builder rejects unsized octal actuals whose value exceeds the direct target width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_octal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_octal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => '=0o400', target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_unsized_octal_actual_width_top.fsm',
            header => 'blocked_unsized_octal_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=0o400', .*unsized octal actual value does not fit direct target width 8/s,
        'builder rejects unsized octal actuals whose numeric value does not fit the direct target width',
    );
};

subtest 'linked plan builder rejects unsized binary actuals whose value exceeds the direct target width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_binary_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_binary_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => '=0b100000000', target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_unsized_binary_actual_width_top.fsm',
            header => 'blocked_unsized_binary_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=0b100000000', .*unsized binary actual value does not fit direct target width 8/s,
        'builder rejects unsized binary actuals whose numeric value does not fit the direct target width',
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

subtest 'linked plan builder rejects octal actuals whose value exceeds the declared width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_toplinks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_octal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_octal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            toplinks => [
                FSM::Composition::TopLink->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => "=8'o400", target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_octal_actual_width_top.fsm',
            header => 'blocked_octal_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=8'o400', .*declared octal width cannot represent the literal payload value/s,
        'builder rejects octal actuals whose numeric value does not fit the declared width',
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
