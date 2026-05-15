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
use FSM::Composition::WiringBlock;
use FSM::Composition::TopSymbols;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_vector_literal_expr
    open_expr
);
use FSM::Pipeline::HDLGenerator;

subtest 'linked plan builder preserves numeric and open wiring_blocks as typed actual bindings' => sub {
    my @ports = (
        port('core_clk', 'input', 1, 'clock'),
        port('rst_async_n', 'input', 1, 'reset'),
        port('default_data', 'output', 8, undef),
        port('one_data', 'output', 8, undef),
        port('decimal_data', 'output', 8, undef),
        port('signed_decimal_data', 'output', 8, undef),
        port('signed_literal_data', 'output', 8, undef),
        port('signed_binary_data', 'output', 8, undef),
        port('signed_octal_data', 'output', 8, undef),
        port('signed_hex_data', 'output', 8, undef),
        port('octal_data', 'output', 8, undef),
        port('hex_data', 'output', 8, undef),
        port('prefixed_binary_data', 'output', 8, undef),
        port('prefixed_decimal_data', 'output', 8, undef),
        port('prefixed_octal_data', 'output', 8, undef),
        port('prefixed_hex_data', 'output', 8, undef),
        port('sv_unsized_binary_data', 'output', 8, undef),
        port('sv_unsized_decimal_data', 'output', 8, undef),
        port('sv_unsized_signed_decimal_data', 'output', 8, undef),
        port('sv_unsized_octal_data', 'output', 8, undef),
        port('sv_unsized_hex_data', 'output', 8, undef),
        port('serial_out', 'output', 1, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
        lane => 'C3',
        composition_spec => composition_spec('structural_actual_top'),
        top => FSM::Composition::Top->new(name => 'structural_actual_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => "=8'b1010_0101", target => 'default_data'),
                    FSM::Composition::Link->new(source => '=1', target => 'one_data'),
                    FSM::Composition::Link->new(source => '=1_70', target => 'decimal_data'),
                    FSM::Composition::Link->new(source => '=-1', target => 'signed_decimal_data'),
                    FSM::Composition::Link->new(source => "=8'sd-1", target => 'signed_literal_data'),
                    FSM::Composition::Link->new(source => "=8'sb1010_0101", target => 'signed_binary_data'),
                    FSM::Composition::Link->new(source => "=8'so2_45", target => 'signed_octal_data'),
                    FSM::Composition::Link->new(source => "=8'shA_5", target => 'signed_hex_data'),
                    FSM::Composition::Link->new(source => "=8'o2_45", target => 'octal_data'),
                    FSM::Composition::Link->new(source => '=A_5', target => 'hex_data'),
                    FSM::Composition::Link->new(source => '=0b1010_0101', target => 'prefixed_binary_data'),
                    FSM::Composition::Link->new(source => '=0d1_70', target => 'prefixed_decimal_data'),
                    FSM::Composition::Link->new(source => '=0o2_45', target => 'prefixed_octal_data'),
                    FSM::Composition::Link->new(source => '=0xA_5', target => 'prefixed_hex_data'),
                    FSM::Composition::Link->new(source => "='b1010_0101", target => 'sv_unsized_binary_data'),
                    FSM::Composition::Link->new(source => "='d1_70", target => 'sv_unsized_decimal_data'),
                    FSM::Composition::Link->new(source => "='sd-1", target => 'sv_unsized_signed_decimal_data'),
                    FSM::Composition::Link->new(source => "='o2_45", target => 'sv_unsized_octal_data'),
                    FSM::Composition::Link->new(source => "='hA_5", target => 'sv_unsized_hex_data'),
                    FSM::Composition::Link->new(source => "=8'b1010_0101", target => 'uart_tx.data_in'),
                    FSM::Composition::Link->new(source => '=0', target => 'uart_tx.zero_data_in'),
                    FSM::Composition::Link->new(source => '=1', target => 'uart_tx.one_data_in'),
                    FSM::Composition::Link->new(source => '=1_70', target => 'uart_tx.unsized_decimal_data_in'),
                    FSM::Composition::Link->new(source => '=-1', target => 'uart_tx.signed_decimal_data_in'),
                    FSM::Composition::Link->new(source => "=8'sd-1", target => 'uart_tx.signed_literal_data_in'),
                    FSM::Composition::Link->new(source => "=8'sb1010_0101", target => 'uart_tx.signed_binary_data_in'),
                    FSM::Composition::Link->new(source => "=8'so2_45", target => 'uart_tx.signed_octal_data_in'),
                    FSM::Composition::Link->new(source => "=8'shA_5", target => 'uart_tx.signed_hex_data_in'),
                    FSM::Composition::Link->new(source => '=0o2_45', target => 'uart_tx.unsized_octal_data_in'),
                    FSM::Composition::Link->new(source => '=A_5', target => 'uart_tx.unsized_hex_data_in'),
                    FSM::Composition::Link->new(source => '=0b1010_0101', target => 'uart_tx.prefixed_binary_data_in'),
                    FSM::Composition::Link->new(source => '=0d1_70', target => 'uart_tx.prefixed_decimal_data_in'),
                    FSM::Composition::Link->new(source => '=0xA_5', target => 'uart_tx.prefixed_hex_data_in'),
                    FSM::Composition::Link->new(source => "='b1010_0101", target => 'uart_tx.sv_unsized_binary_data_in'),
                    FSM::Composition::Link->new(source => "='d1_70", target => 'uart_tx.sv_unsized_decimal_data_in'),
                    FSM::Composition::Link->new(source => "='sd-1", target => 'uart_tx.sv_unsized_signed_decimal_data_in'),
                    FSM::Composition::Link->new(source => "='o2_45", target => 'uart_tx.sv_unsized_octal_data_in'),
                    FSM::Composition::Link->new(source => "='hA_5", target => 'uart_tx.sv_unsized_hex_data_in'),
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
                port('signed_binary_data_in', 'input', 8, undef),
                port('signed_octal_data_in', 'input', 8, undef),
                port('signed_hex_data_in', 'input', 8, undef),
                port('unsized_octal_data_in', 'input', 8, undef),
                port('unsized_hex_data_in', 'input', 8, undef),
                port('prefixed_binary_data_in', 'input', 8, undef),
                port('prefixed_decimal_data_in', 'input', 8, undef),
                port('prefixed_hex_data_in', 'input', 8, undef),
                port('sv_unsized_binary_data_in', 'input', 8, undef),
                port('sv_unsized_decimal_data_in', 'input', 8, undef),
                port('sv_unsized_signed_decimal_data_in', 'input', 8, undef),
                port('sv_unsized_octal_data_in', 'input', 8, undef),
                port('sv_unsized_hex_data_in', 'input', 8, undef),
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
            "    assign signed_binary_data = 8'b10100101;",
            "    assign signed_octal_data = 8'b10100101;",
            "    assign signed_hex_data = 8'b10100101;",
            "    assign octal_data = 8'b10100101;",
            "    assign hex_data = 8'b10100101;",
            "    assign prefixed_binary_data = 8'b10100101;",
            "    assign prefixed_decimal_data = 8'b10101010;",
            "    assign prefixed_octal_data = 8'b10100101;",
            "    assign prefixed_hex_data = 8'b10100101;",
            "    assign sv_unsized_binary_data = 8'b10100101;",
            "    assign sv_unsized_decimal_data = 8'b10101010;",
            "    assign sv_unsized_signed_decimal_data = 8'b11111111;",
            "    assign sv_unsized_octal_data = 8'b10100101;",
            "    assign sv_unsized_hex_data = 8'b10100101;",
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
        'literal explicit wiring becomes a typed bit-vector actual binding',
    );
    is($bindings{zero_data_in}{signal_name} // '', '', 'scalar zero actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{zero_data_in}{connection_expr},
        bit_vector_literal_expr('00000000'),
        'scalar zero explicit wiring expands to the exact target width for child inputs',
    );
    is($bindings{one_data_in}{signal_name} // '', '', 'scalar one actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{one_data_in}{connection_expr},
        bit_vector_literal_expr('00000001'),
        'scalar one explicit wiring expands to the exact target width for child inputs',
    );
    is($bindings{unsized_decimal_data_in}{signal_name} // '', '', 'unsized decimal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{unsized_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10101010'),
        'unsized decimal explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{signed_decimal_data_in}{signal_name} // '', '', 'unsized signed decimal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{signed_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('11111111'),
        'unsized signed decimal explicit wiring lowers through exact-width two-complement bits for child inputs',
    );
    is($bindings{signed_literal_data_in}{signal_name} // '', '', 'signed decimal literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{signed_literal_data_in}{connection_expr},
        bit_vector_literal_expr('11111111'),
        'signed decimal literal explicit wiring becomes the same typed bit-vector actual binding',
    );
    is($bindings{signed_binary_data_in}{signal_name} // '', '', 'signed binary literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{signed_binary_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'signed binary literal explicit wiring becomes the same typed bit-vector actual binding',
    );
    is($bindings{signed_octal_data_in}{signal_name} // '', '', 'signed octal literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{signed_octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'signed octal literal explicit wiring becomes the same typed bit-vector actual binding',
    );
    is($bindings{signed_hex_data_in}{signal_name} // '', '', 'signed hex literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{signed_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'signed hex literal explicit wiring becomes the same typed bit-vector actual binding',
    );
    is($bindings{unsized_octal_data_in}{signal_name} // '', '', 'unsized octal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{unsized_octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'unsized octal explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{unsized_hex_data_in}{signal_name} // '', '', 'unsized hex actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{unsized_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'unsized hex explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{prefixed_binary_data_in}{signal_name} // '', '', 'prefixed binary actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{prefixed_binary_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'prefixed binary explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{prefixed_decimal_data_in}{signal_name} // '', '', 'prefixed decimal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{prefixed_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10101010'),
        'prefixed decimal explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{prefixed_hex_data_in}{signal_name} // '', '', 'prefixed hex actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{prefixed_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'prefixed hex explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{sv_unsized_binary_data_in}{signal_name} // '', '', 'SV unsized binary actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{sv_unsized_binary_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'SV unsized binary explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{sv_unsized_decimal_data_in}{signal_name} // '', '', 'SV unsized decimal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{sv_unsized_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10101010'),
        'SV unsized decimal explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{sv_unsized_signed_decimal_data_in}{signal_name} // '', '', 'SV unsized signed decimal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{sv_unsized_signed_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('11111111'),
        'SV unsized signed decimal explicit wiring lowers through exact-width two-complement bits for child inputs',
    );
    is($bindings{sv_unsized_octal_data_in}{signal_name} // '', '', 'SV unsized octal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{sv_unsized_octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'SV unsized octal explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{sv_unsized_hex_data_in}{signal_name} // '', '', 'SV unsized hex actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{sv_unsized_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'SV unsized hex explicit wiring widens to the exact target width for child inputs',
    );
    is($bindings{decimal_data_in}{signal_name} // '', '', 'decimal literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'decimal literal explicit wiring becomes the same typed bit-vector actual binding',
    );
    is($bindings{octal_data_in}{signal_name} // '', '', 'octal literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'octal literal explicit wiring becomes the same typed bit-vector actual binding',
    );
    is($bindings{hex_data_in}{signal_name} // '', '', 'hex literal actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'hex literal explicit wiring becomes the same typed bit-vector actual binding',
    );
    is($bindings{enable}{signal_name} // '', '', 'open actual binding does not invent a flat signal mirror');
    is_deeply(
        $bindings{enable}{connection_expr},
        open_expr(),
        'open explicit wiring becomes a typed open actual binding',
    );
};

subtest 'pipeline and CLI emit structural numeric and open actuals for explicit wiring_blocks' => sub {
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
        signed_binary_data>8
        signed_octal_data>8
        signed_hex_data>8
        octal_data>8
        hex_data>8
        prefixed_binary_data>8
        prefixed_decimal_data>8
        prefixed_octal_data>8
        prefixed_hex_data>8
        sv_unsized_binary_data>8
        sv_unsized_decimal_data>8
        sv_unsized_signed_decimal_data>8
        sv_unsized_octal_data>8
        sv_unsized_hex_data>8
        serial_out>
      )
      (?rtl:uart_tx)
      (?wiring:wiring
        /=8'b1010_0101/default_data/
        /=1/one_data/
        /=1_70/decimal_data/
        /=-1/signed_decimal_data/
        /=8'sd-1/signed_literal_data/
        /=8'sb1010_0101/signed_binary_data/
        /=8'so2_45/signed_octal_data/
        /=8'shA_5/signed_hex_data/
        /=8'o2_45/octal_data/
        /=A_5/hex_data/
        /=0b1010_0101/prefixed_binary_data/
        /=0d1_70/prefixed_decimal_data/
        /=0o2_45/prefixed_octal_data/
        /=0xA_5/prefixed_hex_data/
        /='b1010_0101/sv_unsized_binary_data/
        /='d1_70/sv_unsized_decimal_data/
        /='sd-1/sv_unsized_signed_decimal_data/
        /='o2_45/sv_unsized_octal_data/
        /='hA_5/sv_unsized_hex_data/
        /=8'b1010_0101/uart_tx.data_in/
        /=0/uart_tx.zero_data_in/
        /=1/uart_tx.one_data_in/
        /=1_70/uart_tx.unsized_decimal_data_in/
        /=-1/uart_tx.signed_decimal_data_in/
        /=8'sd-1/uart_tx.signed_literal_data_in/
        /=8'sb1010_0101/uart_tx.signed_binary_data_in/
        /=8'so2_45/uart_tx.signed_octal_data_in/
        /=8'shA_5/uart_tx.signed_hex_data_in/
        /=0o2_45/uart_tx.unsized_octal_data_in/
        /=A_5/uart_tx.unsized_hex_data_in/
        /=0b1010_0101/uart_tx.prefixed_binary_data_in/
        /=0d1_70/uart_tx.prefixed_decimal_data_in/
        /=0xA_5/uart_tx.prefixed_hex_data_in/
        /='b1010_0101/uart_tx.sv_unsized_binary_data_in/
        /='d1_70/uart_tx.sv_unsized_decimal_data_in/
        /='sd-1/uart_tx.sv_unsized_signed_decimal_data_in/
        /='o2_45/uart_tx.sv_unsized_octal_data_in/
        /='hA_5/uart_tx.sv_unsized_hex_data_in/
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
  signed_binary_data_in<8:data
  signed_octal_data_in<8:data
  signed_hex_data_in<8:data
  unsized_octal_data_in<8:data
  unsized_hex_data_in<8:data
  prefixed_binary_data_in<8:data
  prefixed_decimal_data_in<8:data
  prefixed_hex_data_in<8:data
  sv_unsized_binary_data_in<8:data
  sv_unsized_decimal_data_in<8:data
  sv_unsized_signed_decimal_data_in<8:data
  sv_unsized_octal_data_in<8:data
  sv_unsized_hex_data_in<8:data
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
    is($result->{composition_plan}->lane, 'C3', 'single rtl explicit actual wiring_blocks stay on the C3 lane');

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
        $bindings{signed_binary_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the typed signed binary literal actual binding in the realized composition plan',
    );
    is_deeply(
        $bindings{signed_octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the typed signed octal literal actual binding in the realized composition plan',
    );
    is_deeply(
        $bindings{signed_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the typed signed hex literal actual binding in the realized composition plan',
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
        $bindings{sv_unsized_binary_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the widened SV unsized binary binding in the realized composition plan',
    );
    is_deeply(
        $bindings{sv_unsized_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('10101010'),
        'pipeline preserves the widened SV unsized decimal binding in the realized composition plan',
    );
    is_deeply(
        $bindings{sv_unsized_signed_decimal_data_in}{connection_expr},
        bit_vector_literal_expr('11111111'),
        'pipeline preserves the widened SV unsized signed decimal binding in the realized composition plan',
    );
    is_deeply(
        $bindings{sv_unsized_octal_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the widened SV unsized octal binding in the realized composition plan',
    );
    is_deeply(
        $bindings{sv_unsized_hex_data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline preserves the widened SV unsized hex binding in the realized composition plan',
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
    like($hdl, qr/assign signed_binary_data = 8'b10100101;/, 'generated HDL emits the signed binary literal actual directly on the top output');
    like($hdl, qr/assign signed_octal_data = 8'b10100101;/, 'generated HDL emits the signed octal literal actual directly on the top output');
    like($hdl, qr/assign signed_hex_data = 8'b10100101;/, 'generated HDL emits the signed hex literal actual directly on the top output');
    like($hdl, qr/assign octal_data = 8'b10100101;/, 'generated HDL emits the octal literal actual directly on the top output');
    like($hdl, qr/assign hex_data = 8'b10100101;/, 'generated HDL emits the widened unsized hex actual directly on the top output');
    like($hdl, qr/assign prefixed_binary_data = 8'b10100101;/, 'generated HDL emits the widened prefixed binary actual directly on the top output');
    like($hdl, qr/assign prefixed_decimal_data = 8'b10101010;/, 'generated HDL emits the widened prefixed decimal actual directly on the top output');
    like($hdl, qr/assign prefixed_octal_data = 8'b10100101;/, 'generated HDL emits the widened prefixed octal actual directly on the top output');
    like($hdl, qr/assign prefixed_hex_data = 8'b10100101;/, 'generated HDL emits the widened prefixed hex actual directly on the top output');
    like($hdl, qr/assign sv_unsized_binary_data = 8'b10100101;/, 'generated HDL emits the widened SV unsized binary actual directly on the top output');
    like($hdl, qr/assign sv_unsized_decimal_data = 8'b10101010;/, 'generated HDL emits the widened SV unsized decimal actual directly on the top output');
    like($hdl, qr/assign sv_unsized_signed_decimal_data = 8'b11111111;/, 'generated HDL emits the widened SV unsized signed decimal actual directly on the top output');
    like($hdl, qr/assign sv_unsized_octal_data = 8'b10100101;/, 'generated HDL emits the widened SV unsized octal actual directly on the top output');
    like($hdl, qr/assign sv_unsized_hex_data = 8'b10100101;/, 'generated HDL emits the widened SV unsized hex actual directly on the top output');
    like($hdl, qr/\.data_in\(8'b10100101\)/, 'generated HDL emits the literal actual directly on the child port');
    like($hdl, qr/\.zero_data_in\(8'b00000000\)/, 'generated HDL emits the widened scalar zero actual directly on the child port');
    like($hdl, qr/\.one_data_in\(8'b00000001\)/, 'generated HDL emits the widened scalar one actual directly on the child port');
    like($hdl, qr/\.unsized_decimal_data_in\(8'b10101010\)/, 'generated HDL emits the widened unsized decimal actual directly on the child port');
    like($hdl, qr/\.signed_decimal_data_in\(8'b11111111\)/, 'generated HDL emits the widened unsized signed decimal actual directly on the child port');
    like($hdl, qr/\.signed_literal_data_in\(8'b11111111\)/, 'generated HDL emits the signed decimal literal actual directly on the child port');
    like($hdl, qr/\.signed_binary_data_in\(8'b10100101\)/, 'generated HDL emits the signed binary literal actual directly on the child port');
    like($hdl, qr/\.signed_octal_data_in\(8'b10100101\)/, 'generated HDL emits the signed octal literal actual directly on the child port');
    like($hdl, qr/\.signed_hex_data_in\(8'b10100101\)/, 'generated HDL emits the signed hex literal actual directly on the child port');
    like($hdl, qr/\.unsized_octal_data_in\(8'b10100101\)/, 'generated HDL emits the widened unsized octal actual directly on the child port');
    like($hdl, qr/\.unsized_hex_data_in\(8'b10100101\)/, 'generated HDL emits the widened unsized hex actual directly on the child port');
    like($hdl, qr/\.prefixed_binary_data_in\(8'b10100101\)/, 'generated HDL emits the widened prefixed binary actual directly on the child port');
    like($hdl, qr/\.prefixed_decimal_data_in\(8'b10101010\)/, 'generated HDL emits the widened prefixed decimal actual directly on the child port');
    like($hdl, qr/\.prefixed_hex_data_in\(8'b10100101\)/, 'generated HDL emits the widened prefixed hex actual directly on the child port');
    like($hdl, qr/\.sv_unsized_binary_data_in\(8'b10100101\)/, 'generated HDL emits the widened SV unsized binary actual directly on the child port');
    like($hdl, qr/\.sv_unsized_decimal_data_in\(8'b10101010\)/, 'generated HDL emits the widened SV unsized decimal actual directly on the child port');
    like($hdl, qr/\.sv_unsized_signed_decimal_data_in\(8'b11111111\)/, 'generated HDL emits the widened SV unsized signed decimal actual directly on the child port');
    like($hdl, qr/\.sv_unsized_octal_data_in\(8'b10100101\)/, 'generated HDL emits the widened SV unsized octal actual directly on the child port');
    like($hdl, qr/\.sv_unsized_hex_data_in\(8'b10100101\)/, 'generated HDL emits the widened SV unsized hex actual directly on the child port');
    like($hdl, qr/\.decimal_data_in\(8'b10100101\)/, 'generated HDL emits the decimal literal actual directly on the child port');
    like($hdl, qr/\.octal_data_in\(8'b10100101\)/, 'generated HDL emits the octal literal actual directly on the child port');
    like($hdl, qr/\.hex_data_in\(8'b10100101\)/, 'generated HDL emits the hex literal actual directly on the child port');
    like($hdl, qr/\.enable\(\)/, 'generated HDL emits the open actual directly on the child port');
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for pure actual bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for explicit structural-actual wiring_blocks');
    ok(-e $output_path, 'CLI writes HDL for explicit structural-actual wiring_blocks');
};

subtest 'pipeline and CLI emit intent-sized exact-width direct actuals for explicit wiring_blocks' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'intent_sized_actual_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'intent_sized_actual_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:intent_sized_actual_top
  (?ports:public_io
    decimal_out>5
    negative_decimal_out>8
    negative_binary_out>8
    x_alias_out>20
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    /=5'23/decimal_out/
    /=8'-10/negative_decimal_out/
    /=8'-0b1010/negative_binary_out/
    /=20'x1/x_alias_out/
    /=5'23/uart_tx.decimal_in/
    /=8'-0xA/uart_tx.negative_hex_in/
    /=20'x1/uart_tx.x_alias_in/
  )
)

(?rtlif:uart_tx
  decimal_in<5:data
  negative_hex_in<8:data
  x_alias_in<20:data
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
    is($result->{composition_plan}->lane, 'C3', 'single rtl intent-sized direct-actual wiring_blocks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{decimal_in}{connection_expr},
        bit_vector_literal_expr('10111'),
        'pipeline preserves the declared width for intent-sized decimal direct actual child bindings',
    );
    is_deeply(
        $bindings{negative_hex_in}{connection_expr},
        bit_vector_literal_expr('11110110'),
        'pipeline preserves normalized two-complement bits for intent-sized negative hex direct actual child bindings',
    );
    is_deeply(
        $bindings{x_alias_in}{connection_expr},
        bit_vector_literal_expr('00000000000000000001'),
        'pipeline preserves declared width for intent-sized radix-alias direct actual child bindings',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/assign\s+decimal_out\s*=\s*5'b10111\s*;/, 'generated HDL emits the intent-sized decimal direct actual on the top output');
    like($hdl, qr/assign\s+negative_decimal_out\s*=\s*8'b11110110\s*;/, 'generated HDL emits the intent-sized negative decimal direct actual on the top output');
    like($hdl, qr/assign\s+negative_binary_out\s*=\s*8'b11110110\s*;/, 'generated HDL emits the intent-sized negative binary direct actual on the top output');
    like($hdl, qr/assign\s+x_alias_out\s*=\s*20'b00000000000000000001\s*;/, 'generated HDL emits the intent-sized radix-alias direct actual on the top output');
    like($hdl, qr/\.decimal_in\(5'b10111\)/, 'generated HDL emits the intent-sized decimal direct actual on the child port');
    like($hdl, qr/\.negative_hex_in\(8'b11110110\)/, 'generated HDL emits the intent-sized negative hex direct actual on the child port');
    like($hdl, qr/\.x_alias_in\(20'b00000000000000000001\)/, 'generated HDL emits the intent-sized radix-alias direct actual on the child port');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for intent-sized direct-actual wiring_blocks');
    ok(-e $output_path, 'CLI writes HDL for intent-sized direct-actual wiring_blocks');
};

subtest 'linked plan builder preserves named actuals from composition-root symbols' => sub {
    my @ports = (
        port('symbol_flag', 'output', 1, undef),
        port('symbol_byte', 'output', 8, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
        lane => 'C3',
        composition_spec => composition_spec('symbol_actual_top'),
        top => FSM::Composition::Top->new(
            name => 'symbol_actual_top',
            top_symbols => FSM::Composition::TopSymbols->new(
                constants => {
                    RESET_BYTE => "8'hA5",
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
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => '=RESET_BYTE', target => 'uart_tx.data_in'),
                    FSM::Composition::Link->new(source => '=mode.BUSY', target => 'symbol_flag'),
                    FSM::Composition::Link->new(source => '=RESET_BYTE', target => 'symbol_byte'),
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
        fsm_file => 'symbol_actual_top.fsm',
        header => 'symbol_actual_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for composition-root named actuals');

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'composition-root constant actuals lower through the existing typed literal binding path',
    );
    is_deeply(
        $plan->auxiliary_assignments,
        [
            "    assign symbol_flag = 1'b1;",
            "    assign symbol_byte = 8'b10100101;",
        ],
        'composition-root enum and constant actuals also drive declared top outputs through direct assignments',
    );
};

subtest 'pipeline and CLI emit named actuals from composition-root symbols' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'symbol_actual_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'symbol_actual_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:symbol_actual_top
  (+constants
    (RESET_BYTE 8'165)
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
  (?ports:public_io
    symbol_flag>
    symbol_byte>8
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    /=RESET_BYTE/uart_tx.data_in/
    /=mode.BUSY/symbol_flag/
    /=RESET_BYTE/symbol_byte/
  )
)

(?rtlif:uart_tx
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
    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('RESET_BYTE'),
        "8'd165",
        'pipeline preserves canonicalized composition-root constant payloads on the typed composition spec',
    );
    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('mode.BUSY'),
        '1',
        'pipeline preserves canonicalized composition-root enum payloads on the typed composition spec',
    );

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{data_in}{connection_expr},
        bit_vector_literal_expr('10100101'),
        'pipeline resolves composition-root named actuals onto the existing typed literal binding path',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/assign\s+symbol_flag\s*=\s*1'b1\s*;/, 'generated HDL emits enum-backed named actual top-output assignments');
    like($hdl, qr/assign\s+symbol_byte\s*=\s*8'b10100101\s*;/, 'generated HDL emits constant-backed named actual top-output assignments');
    like($hdl, qr/\.data_in\(8'b10100101\)/, 'generated HDL emits constant-backed named actual child-input bindings');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for composition-root named actual wiring_blocks');
    ok(-e $output_path, 'CLI writes HDL for composition-root named actual wiring_blocks');
};

subtest 'linked plan builder preserves compatible whole aggregate actuals on typed direct targets' => sub {
    my $frame_spec = ordered_record_spec(
        [mode => bits_spec(2)],
        [flag => bit_spec()],
    );
    my @ports = (
        port('typed_status_out', 'output', 3, undef,
            declared_type_name => 'frame_t',
            declared_type_spec => $frame_spec,
        ),
    );

    my $top_symbols = FSM::Composition::TopSymbols->new();
    $top_symbols->store_constant('FRAME', {
        kind => 'map',
        member_order => ['mode', 'flag'],
        members => {
            mode => { kind => 'scalar', payload => "2'b10" },
            flag => { kind => 'scalar', payload => '1' },
        },
    });

    my $top = FSM::Composition::Top->new(
        name => 'typed_aggregate_actual_top',
        top_symbols => $top_symbols,
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
        lane => 'C3',
        composition_spec => FSM::Composition::Spec->new(top => $top),
        top => $top,
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => '=FRAME', target => 'typed_status_out'),
                    FSM::Composition::Link->new(source => '=FRAME', target => 'uart_tx.status_in'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'uart_tx',
                port('status_in', 'input', 3, undef,
                    declared_type_name => 'frame_t',
                    declared_type_spec => $frame_spec,
                ),
            ),
        ],
        fsm_file => 'typed_aggregate_actual_top.fsm',
        header => 'typed_aggregate_actual_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is_deeply(
        $plan->auxiliary_assignments,
        [
            "    assign typed_status_out = 3'b101;",
        ],
        'compatible whole aggregate actuals still drive typed top outputs directly',
    );

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{status_in}{connection_expr},
        bit_vector_literal_expr('101'),
        'compatible whole aggregate actuals still bind directly into typed child inputs',
    );
};

subtest 'linked plan builder rejects whole aggregate actuals across incompatible typed aggregate targets' => sub {
    my $top_symbols = FSM::Composition::TopSymbols->new();
    $top_symbols->store_constant('FRAME', {
        kind => 'map',
        member_order => ['mode', 'flag'],
        members => {
            mode => { kind => 'scalar', payload => "2'b10" },
            flag => { kind => 'scalar', payload => '1' },
        },
    });

    my $top = FSM::Composition::Top->new(
        name => 'blocked_typed_aggregate_actual_top',
        top_symbols => $top_symbols,
    );

    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => FSM::Composition::Spec->new(top => $top),
            top => $top,
            ports_block => FSM::Composition::PortsBlock->new(
                name => 'public_io',
                ports => [
                    port('typed_status_out', 'output', 3, undef,
                        declared_type_name => 'wrong_t',
                        declared_type_spec => list_spec(
                            bit_spec(),
                            bits_spec(2),
                        ),
                    ),
                ],
            ),
            ports => [
                port('typed_status_out', 'output', 3, undef,
                    declared_type_name => 'wrong_t',
                    declared_type_spec => list_spec(
                        bit_spec(),
                        bits_spec(2),
                    ),
                ),
            ],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => '=FRAME', target => 'typed_status_out'),
                    ],
                ),
            ],
            realized_instances => [
                realized_instance(
                    'rtl',
                    'uart_tx',
                    port('dummy', 'input', 1, undef),
                ),
            ],
            fsm_file => 'blocked_typed_aggregate_actual_top.fsm',
            header => 'blocked_typed_aggregate_actual_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual source '=FRAME' as an explicit link source, .*whole aggregate actual contract 'record\{mode:bits\[2\], flag:bit\}' does not match target declared type 'list<bit, bits\[2\]>' on 'typed_status_out'/s,
        'builder rejects width-equal whole aggregate actuals when the target preserves an incompatible aggregate declared type contract',
    );
};

subtest 'linked plan builder sign-extends SV unsized signed based direct actuals' => sub {
    my @ports = (
        port('sv_unsized_signed_binary_data', 'output', 8, undef),
        port('sv_unsized_signed_octal_data', 'output', 12, undef),
        port('sv_unsized_signed_hex_data', 'output', 12, undef),
    );

    my $plan = FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
        lane => 'C3',
        composition_spec => composition_spec('sv_unsized_signed_based_actual_top'),
        top => FSM::Composition::Top->new(name => 'sv_unsized_signed_based_actual_top'),
        ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => \@ports),
        ports => \@ports,
        wiring_blocks => [
            FSM::Composition::WiringBlock->new(
                name => 'wiring',
                links => [
                    FSM::Composition::Link->new(source => "='sb1010", target => 'sv_unsized_signed_binary_data'),
                    FSM::Composition::Link->new(source => "='so6_45", target => 'sv_unsized_signed_octal_data'),
                    FSM::Composition::Link->new(source => "='shA_5", target => 'sv_unsized_signed_hex_data'),
                    FSM::Composition::Link->new(source => "='sb1010", target => 'uart_tx.sv_unsized_signed_binary_data_in'),
                    FSM::Composition::Link->new(source => "='so6_45", target => 'uart_tx.sv_unsized_signed_octal_data_in'),
                    FSM::Composition::Link->new(source => "='shA_5", target => 'uart_tx.sv_unsized_signed_hex_data_in'),
                ],
            ),
        ],
        realized_instances => [
            realized_instance(
                'rtl',
                'uart_tx',
                port('sv_unsized_signed_binary_data_in', 'input', 8, undef),
                port('sv_unsized_signed_octal_data_in', 'input', 12, undef),
                port('sv_unsized_signed_hex_data_in', 'input', 12, undef),
            ),
        ],
        fsm_file => 'sv_unsized_signed_based_actual_top.fsm',
        header => 'sv_unsized_signed_based_actual_top',
    );

    isa_ok($plan, 'FSM::Composition::Plan');
    is($plan->lane, 'C3', 'builder records the active explicit-link lane for SV unsized signed based actuals');
    is(scalar(@{$plan->nets}), 0, 'SV unsized signed based actuals do not force synthetic carrier nets');
    is_deeply(
        $plan->auxiliary_assignments,
        [
            "    assign sv_unsized_signed_binary_data = 8'b11111010;",
            "    assign sv_unsized_signed_octal_data = 12'b111110100101;",
            "    assign sv_unsized_signed_hex_data = 12'b111110100101;",
        ],
        'SV unsized signed based top-output bindings sign-extend to the direct target width',
    );

    my %bindings = map { $_->{port_name} => $_ } @{$plan->instances->[0]->port_bindings};
    is_deeply(
        $bindings{sv_unsized_signed_binary_data_in}{connection_expr},
        bit_vector_literal_expr('11111010'),
        'SV unsized signed binary actuals sign-extend on direct child-input bindings',
    );
    is_deeply(
        $bindings{sv_unsized_signed_octal_data_in}{connection_expr},
        bit_vector_literal_expr('111110100101'),
        'SV unsized signed octal actuals sign-extend on direct child-input bindings',
    );
    is_deeply(
        $bindings{sv_unsized_signed_hex_data_in}{connection_expr},
        bit_vector_literal_expr('111110100101'),
        'SV unsized signed hex actuals sign-extend on direct child-input bindings',
    );
};

subtest 'pipeline and CLI emit sign-extended SV unsized signed based direct actuals' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'sv_unsized_signed_based_actual_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'sv_unsized_signed_based_actual_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:sv_unsized_signed_based_actual_top
  (?ports:public_io
    sv_unsized_signed_binary_data>8
    sv_unsized_signed_octal_data>12
    sv_unsized_signed_hex_data>12
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    /='sb1010/sv_unsized_signed_binary_data/
    /='so6_45/sv_unsized_signed_octal_data/
    /='shA_5/sv_unsized_signed_hex_data/
    /='sb1010/uart_tx.sv_unsized_signed_binary_data_in/
    /='so6_45/uart_tx.sv_unsized_signed_octal_data_in/
    /='shA_5/uart_tx.sv_unsized_signed_hex_data_in/
  )
)

(?rtlif:uart_tx
  sv_unsized_signed_binary_data_in<8:data
  sv_unsized_signed_octal_data_in<12:data
  sv_unsized_signed_hex_data_in<12:data
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
    is($result->{composition_plan}->lane, 'C3', 'SV unsized signed based direct-actual wiring_blocks stay on the C3 lane');

    my %bindings = map { $_->{port_name} => $_ } @{$result->{composition_plan}->instances->[0]->port_bindings};
    is_deeply(
        $bindings{sv_unsized_signed_binary_data_in}{connection_expr},
        bit_vector_literal_expr('11111010'),
        'pipeline preserves sign-extended SV unsized signed binary bindings',
    );
    is_deeply(
        $bindings{sv_unsized_signed_octal_data_in}{connection_expr},
        bit_vector_literal_expr('111110100101'),
        'pipeline preserves sign-extended SV unsized signed octal bindings',
    );
    is_deeply(
        $bindings{sv_unsized_signed_hex_data_in}{connection_expr},
        bit_vector_literal_expr('111110100101'),
        'pipeline preserves sign-extended SV unsized signed hex bindings',
    );

    my $hdl = $result->{hdl_code};
    like($hdl, qr/assign sv_unsized_signed_binary_data = 8'b11111010;/, 'generated HDL emits the sign-extended SV unsized signed binary actual directly on the top output');
    like($hdl, qr/assign sv_unsized_signed_octal_data = 12'b111110100101;/, 'generated HDL emits the sign-extended SV unsized signed octal actual directly on the top output');
    like($hdl, qr/assign sv_unsized_signed_hex_data = 12'b111110100101;/, 'generated HDL emits the sign-extended SV unsized signed hex actual directly on the top output');
    like($hdl, qr/\.sv_unsized_signed_binary_data_in\(8'b11111010\)/, 'generated HDL emits the sign-extended SV unsized signed binary actual directly on the child port');
    like($hdl, qr/\.sv_unsized_signed_octal_data_in\(12'b111110100101\)/, 'generated HDL emits the sign-extended SV unsized signed octal actual directly on the child port');
    like($hdl, qr/\.sv_unsized_signed_hex_data_in\(12'b111110100101\)/, 'generated HDL emits the sign-extended SV unsized signed hex actual directly on the child port');
    unlike($hdl, qr/\bwire\s+comp_link_/s, 'generated HDL does not invent synthetic carrier nets for SV unsized signed based actuals');

    my ($success) = run(
        command => ['./bin/fsmgen', '-o', $output_path, '--quiet', $composition_path],
    );

    ok($success, 'CLI succeeds for SV unsized signed based actual wiring_blocks');
    ok(-e $output_path, 'CLI writes HDL for SV unsized signed based actual wiring_blocks');
};

subtest 'linked plan builder rejects open actual sources that do not target realized child inputs' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_actual_source_top'),
            top => FSM::Composition::Top->new(name => 'blocked_actual_source_top'),
            ports_block => FSM::Composition::PortsBlock->new(
                name => 'public_io',
                ports => [port('serial_out', 'output', 1, undef)],
            ),
            ports => [port('serial_out', 'output', 1, undef)],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_actual_target_top'),
            top => FSM::Composition::Top->new(name => 'blocked_actual_target_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        qr/uses actual endpoint '=open' as an explicit link target, .*only allows '=open', scalar '=0'\/'=1', named literal actuals from composition-root '\+constants' \/ '\+enums' or imported packages like '=RESET_BYTE', '=mode\.BUSY', '=shared\.RESET_BYTE', or '=shared\.mode\.BUSY', unsized binary\/decimal\/octal\/hex direct actuals, unsized signed decimal direct actuals like '=-1', '=0d-1', or '='sd-1', unsized signed binary\/octal\/hex direct actuals like '='sb1010', '='so7', or '='shA', and exact-width binary\/decimal\/octal\/hex literal actuals in unsigned or signed form like '=8'b10100101', '=8'sb10100101', '=8'd165', '=8'sd-1', '=8'o245', '=8'so245', '=8'hA5', or '=8'shA5' as link sources into realized child input ports, plus literal actuals into declared top outputs/s,
        'builder blocks actual endpoints from appearing as explicit link targets',
    );
};

subtest 'linked plan builder rejects unsupported actual literal forms' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_actual_shape_top'),
            top => FSM::Composition::Top->new(name => 'blocked_actual_shape_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        qr/uses actual endpoint '=0q7', .*currently accepts only '=open', scalar '=0'\/'=1', named literal actuals from composition-root '\+constants' \/ '\+enums' or imported packages like '=RESET_BYTE', '=mode\.BUSY', '=shared\.RESET_BYTE', or '=shared\.mode\.BUSY', unsized binary\/decimal\/octal\/hex direct actual forms like '=0b10', '='b10', '=0d10', '='d10', '=0o7', '='o7', '=0xA', '='hA', '=170', or '=A5', unsized signed decimal direct actual forms like '=-1', '=0d-1', or '='sd-1', unsized signed binary\/octal\/hex direct actual forms like '='sb1010', '='so7', or '='shA', or exact-width binary\/decimal\/octal\/hex literal forms in unsigned or signed form like '=8'b10100101', '=8'sb10100101', '=8'd165', '=8'sd-1', '=8'o245', '=8'so245', '=8'hA5', or '=8'shA5'/s,
        'builder still blocks unsupported unsized literal spellings outside the widened direct unsized-numeric slice',
    );
};

subtest 'linked plan builder rejects ambiguous bare bitstring-like direct actuals explicitly' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_ambiguous_actual_top'),
            top => FSM::Composition::Top->new(name => 'blocked_ambiguous_actual_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => '=00001110', target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_ambiguous_actual_top.fsm',
            header => 'blocked_ambiguous_actual_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual endpoint '=00001110'.*ambiguous bare integer literal.*=0b00001110.*=N'b00001110.*=0d00001110/s,
        'builder rejects ambiguous bare direct actuals with an explicit remediation hint',
    );
};

subtest 'linked plan builder rejects unsized signed decimal actuals whose value exceeds the signed direct target width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_signed_decimal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_signed_decimal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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

subtest 'linked plan builder rejects unsized signed hex actuals whose value exceeds the signed direct target width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_signed_hex_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_signed_hex_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => "='shA_5", target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_unsized_signed_hex_actual_width_top.fsm',
            header => 'blocked_unsized_signed_hex_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '='shA_5', .*unsized signed hex actual value does not fit signed direct target width 7/s,
        'builder rejects unsized signed hex actuals whose numeric value does not fit the signed direct target width',
    );
};

subtest 'linked plan builder rejects unsized decimal actuals whose value exceeds the direct target width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_decimal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_decimal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_decimal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_decimal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_signed_decimal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_signed_decimal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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

subtest 'linked plan builder rejects signed hex actuals whose payload exceeds the declared width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_signed_hex_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_signed_hex_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
                    name => 'wiring',
                    links => [
                        FSM::Composition::Link->new(source => "=8'sh1FF", target => 'uart_tx.data_in'),
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
            fsm_file => 'blocked_signed_hex_actual_width_top.fsm',
            header => 'blocked_signed_hex_actual_width_top',
        );
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/uses actual literal '=8'sh1FF', .*declared signed hex width cannot represent the literal payload value/s,
        'builder rejects signed hex actuals whose payload exceeds the declared width',
    );
};

subtest 'linked plan builder rejects unsized hex actuals whose value exceeds the direct target width' => sub {
    my $exception = eval {
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_hex_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_hex_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_octal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_octal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_unsized_binary_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_unsized_binary_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_hex_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_hex_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
        FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
            lane => 'C3',
            composition_spec => composition_spec('blocked_octal_actual_width_top'),
            top => FSM::Composition::Top->new(name => 'blocked_octal_actual_width_top'),
            ports_block => FSM::Composition::PortsBlock->new(name => 'public_io', ports => []),
            ports => [],
            wiring_blocks => [
                FSM::Composition::WiringBlock->new(
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
    my ($name, $direction, $width, $type, %extra) = @_;
    return FSM::Composition::Port->new(
        name => $name,
        direction => $direction,
        width => $width,
        type => $type,
        %extra,
    );
}

sub bit_spec {
    return {
        kind => 'bit',
        width => 1,
        signed => 0,
    };
}

sub bits_spec {
    my ($width) = @_;
    return {
        kind => 'bits',
        width => $width,
        signed => 0,
    };
}

sub list_spec {
    my (@items) = @_;
    my $width = 0;
    $width += ($_->{width} // 0) for @items;
    return {
        kind => 'list',
        width => $width,
        signed => 0,
        items => [@items],
    };
}

sub ordered_record_spec {
    my (@entries) = @_;
    my %members;
    my @member_order;
    my $width = 0;
    for my $entry (@entries) {
        my ($member_name, $member_spec) = @$entry;
        $members{$member_name} = $member_spec;
        push @member_order, $member_name;
        $width += ($member_spec->{width} // 0);
    }
    return {
        kind => 'record',
        width => $width,
        signed => 0,
        member_order => \@member_order,
        members => \%members,
    };
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
