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

my $tempdir = tempdir(CLEANUP => 1);
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $bounded_composition_path = File::Spec->catfile(
    $repo_root,
    't/corpus/composition_intent_integer_literals.fsm',
);
my $standalone_dtc_composition_path = File::Spec->catfile(
    $repo_root,
    't/corpus/standalone_dtc_explicit_system_autowire.fsm',
);
my $generated_fsmc_composition_path = File::Spec->catfile(
    $repo_root,
    't/corpus/implicit_composition_system_autowire.fsm',
);
my $apb_c4_composition_path = File::Spec->catfile(
    $repo_root,
    'fsm/apb_tb.fsm',
);
my $bounded_output_path = File::Spec->catfile($tempdir, 'composition_intent_integer_literals.vhd');
my $standalone_dtc_output_path = File::Spec->catfile($tempdir, 'standalone_dtc_explicit_system_autowire.vhd');
my $standalone_dtc_scalar_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_standalone_dtc_scalar_generic_map_top.fsm');
my $standalone_dtc_scalar_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_standalone_dtc_scalar_generic_map_top.vhd');
my $standalone_dtc_expression_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_standalone_dtc_expression_generic_map_top.fsm');
my $standalone_dtc_expression_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_standalone_dtc_expression_generic_map_top.vhd');
my $standalone_dtc_one_bit_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_standalone_dtc_one_bit_generic_map_top.fsm');
my $standalone_dtc_one_bit_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_standalone_dtc_one_bit_generic_map_top.vhd');
my $standalone_dtc_bitstring_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_standalone_dtc_bitstring_generic_map_top.fsm');
my $standalone_dtc_bitstring_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_standalone_dtc_bitstring_generic_map_top.vhd');
my $generated_fsmc_output_path = File::Spec->catfile($tempdir, 'implicit_composition_system_autowire.vhd');
my $apb_c4_output_path = File::Spec->catfile($tempdir, 'apb_tb.vhd');
my $scalar_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_scalar_generic_map_top.fsm');
my $scalar_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_scalar_generic_map_top.vhd');
my $package_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_package_generic_map_top.fsm');
my $package_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_package_generic_map_top.vhd');
my $expression_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_expression_generic_map_deferred_top.fsm');
my $expression_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_expression_generic_map_top.vhd');
my $aggregate_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_aggregate_generic_map_top.fsm');
my $aggregate_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_aggregate_generic_map_top.vhd');
my $one_bit_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_one_bit_generic_map_top.fsm');
my $one_bit_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_one_bit_generic_map_top.vhd');
my $generated_fsmc_scalar_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_scalar_generic_map_top.fsm');
my $generated_fsmc_scalar_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_scalar_generic_map_top.vhd');
my $generated_fsmc_expression_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_expression_generic_map_top.fsm');
my $generated_fsmc_expression_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_expression_generic_map_top.vhd');
my $generated_fsmc_bitstring_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_bitstring_generic_map_top.fsm');
my $generated_fsmc_bitstring_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_bitstring_generic_map_top.vhd');
my $generated_fsmc_aggregate_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_aggregate_generic_map_top.fsm');
my $generated_fsmc_aggregate_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_aggregate_generic_map_top.vhd');
my $generated_fsmc_one_bit_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_one_bit_generic_map_top.fsm');
my $generated_fsmc_one_bit_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_generated_fsmc_one_bit_generic_map_top.vhd');
my $composition_path = File::Spec->catfile($tempdir, 'vhdl_composition_top.fsm');
my $output_path = File::Spec->catfile($tempdir, 'vhdl_composition_top.vhd');

write_file(
    $composition_path,
    <<'FSM'
(?top:vhdl_composition_top
  (?ports:public_io
    clk
    rstn
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
);
write_file(
    $scalar_generic_map_path,
    <<'FSM'
(?top:vhdl_scalar_generic_map_top
  (?ports:public_io
    clk
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (WIDTH 16)
      (RESET_VALUE 8'hA5)
    )
  )
  (?wiring:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH 8)
    (RESET_VALUE 8'h00)
  )
  clk:clock
  data_in<16:data
  txd>:data
)
FSM
);
write_file(
    $standalone_dtc_scalar_generic_map_path,
    <<'FSM'
(?top:vhdl_standalone_dtc_scalar_generic_map_top
  (?ports:public_io
    clk
    rst_n
    data_in<16
    result_data>16
  )
  (?dtc:router standalone_route_src
    (params
      (WIDTH 16)
    )
  )
)

(?dt:standalone_route_src
  (+params
    (WIDTH 8)
  )
  (+system
    (clock clk)
    (areset rst_n)
  )
  (+size
    (data_in 16)
    (result_data 16)
  )
  (:= (result_data 16'0))
  (-capture
    (<= (result_data data_in))
  )
)
FSM
);
write_file(
    $standalone_dtc_expression_generic_map_path,
    <<'FSM'
(?top:vhdl_standalone_dtc_expression_generic_map_top
  (?ports:public_io
    clk
    rst_n
    data_in<16
    result_data>16
  )
  (?dtc:router standalone_route_src
    (params
      (EXPR_WIDTH (+ 8 1))
    )
  )
)

(?dt:standalone_route_src
  (+params
    (EXPR_WIDTH 8)
  )
  (+system
    (clock clk)
    (areset rst_n)
  )
  (+size
    (data_in 16)
    (result_data 16)
  )
  (:= (result_data 16'0))
  (-capture
    (<= (result_data data_in))
  )
)
FSM
);
write_file(
    $standalone_dtc_one_bit_generic_map_path,
    <<'FSM'
(?top:vhdl_standalone_dtc_one_bit_generic_map_top
  (?ports:public_io
    clk
    rst_n
    data_in<16
    result_data>16
  )
  (?dtc:router standalone_route_src
    (params
      (ENABLE_DEFAULT 1'b1)
    )
  )
)

(?dt:standalone_route_src
  (+params
    (ENABLE_DEFAULT 1'b0)
  )
  (+system
    (clock clk)
    (areset rst_n)
  )
  (+size
    (data_in 16)
    (result_data 16)
  )
  (:= (result_data 16'0))
  (-capture
    (<= (result_data data_in))
  )
)
FSM
);
write_file(
    $standalone_dtc_bitstring_generic_map_path,
    <<'FSM'
(?top:vhdl_standalone_dtc_bitstring_generic_map_top
  (?ports:public_io
    clk
    rst_n
    data_in<16
    result_data>16
  )
  (?dtc:router standalone_route_src
    (params
      (RESET_VALUE 8'hA5)
    )
  )
)

(?dt:standalone_route_src
  (+params
    (RESET_VALUE 8'h00)
  )
  (+system
    (clock clk)
    (areset rst_n)
  )
  (+size
    (data_in 16)
    (result_data 16)
  )
  (:= (result_data 16'0))
  (-capture
    (<= (result_data data_in))
  )
)
FSM
);
write_file(
    $package_generic_map_path,
    <<'FSM'
(?top:vhdl_package_generic_map_top
  (+import param_pkg)
  (?ports:public_io
    clk
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (WIDTH param_pkg.WIDTH_16)
      (RESET_VALUE param_pkg.RESET_A5)
    )
  )
  (?wiring:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH 8)
    (RESET_VALUE 8'h00)
  )
  clk:clock
  data_in<16:data
  txd>:data
)

(?pkg:param_pkg
  (+constants
    (WIDTH_16 16)
    (RESET_A5 8'hA5)
  )
)
FSM
);
write_file(
    $expression_generic_map_path,
    <<'FSM'
(?top:vhdl_expression_generic_map_deferred_top
  (+constants
    (BASE_WIDTH 16)
  )
  (?ports:public_io
    clk
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (EXPR_WIDTH (+ BASE_WIDTH 1))
    )
  )
  (?wiring:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (EXPR_WIDTH 8)
  )
  clk:clock
  data_in<16:data
  txd>:data
)
FSM
);
write_file(
    $aggregate_generic_map_path,
    <<'FSM'
(?top:vhdl_aggregate_generic_map_top
  (+constants
    (LOCAL_LANES (8'hA5 8'h3C))
  )
  (+enums
    (frame_mode
      (RUN 2'b10)
    )
  )
  (?ports:public_io
    clk
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (LANES LOCAL_LANES)
      (FRAME ((mode frame_mode.RUN) (flag 1)))
    )
  )
  (?wiring:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (LANES (8'h00 8'h00))
    (FRAME ((mode 2'b00) (flag 0)))
  )
  clk:clock
  data_in<16:data
  txd>:data
)
FSM
);
write_file(
    $one_bit_generic_map_path,
    <<'FSM'
(?top:vhdl_one_bit_generic_map_top
  (?ports:public_io
    clk
    payload_in
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (ENABLE_DEFAULT 1'b1)
    )
  )
  (?wiring:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (ENABLE_DEFAULT 1'b0)
  )
  clk:clock
  data_in:data
  txd>:data
)
FSM
);
write_file(
    $generated_fsmc_scalar_generic_map_path,
    <<'FSM'
(?top:vhdl_generated_fsmc_scalar_generic_map_top
  (+constants
    (OVERRIDE_WIDTH 16)
  )
  (?ports:public_io
    clk
    rst_n
    result_data>
  )
  (?fsmc:producer implicit_autowire_producer
    (params
      (WIDTH OVERRIDE_WIDTH)
    )
  )
  (?fsmc:consumer implicit_autowire_consumer)
  (?wiring:wiring
    (producer.output_data consumer.input_data)
    (consumer.result_data result_data)
  )
)

(?fsm:implicit_autowire_producer
  (+params
    (WIDTH 8)
  )
  (+size
    (output_data 1)
  )

  (-drive_outputs
    (= (output_data> 1'b1))
  )
)

(?fsm:implicit_autowire_consumer
  (+size
    (input_data 1)
    (result_data 1)
  )

  (-drive_outputs
    (= (result_data> input_data))
  )
)
FSM
);
write_file(
    $generated_fsmc_expression_generic_map_path,
    <<'FSM'
(?top:vhdl_generated_fsmc_expression_generic_map_top
  (+constants
    (OVERRIDE_WIDTH 16)
  )
  (?ports:public_io
    clk
    rst_n
    result_data>
  )
  (?fsmc:producer implicit_autowire_producer
    (params
      (EXPR_WIDTH (+ OVERRIDE_WIDTH 1))
    )
  )
  (?fsmc:consumer implicit_autowire_consumer)
  (?wiring:wiring
    (producer.output_data consumer.input_data)
    (consumer.result_data result_data)
  )
)

(?fsm:implicit_autowire_producer
  (+params
    (EXPR_WIDTH 8)
  )
  (+size
    (output_data 1)
  )

  (-drive_outputs
    (= (output_data> 1'b1))
  )
)

(?fsm:implicit_autowire_consumer
  (+size
    (input_data 1)
    (result_data 1)
  )

  (-drive_outputs
    (= (result_data> input_data))
  )
)
FSM
);
write_file(
    $generated_fsmc_bitstring_generic_map_path,
    <<'FSM'
(?top:vhdl_generated_fsmc_bitstring_generic_map_top
  (?ports:public_io
    clk
    rst_n
    result_data>
  )
  (?fsmc:producer implicit_autowire_producer
    (params
      (RESET_VALUE 8'hA5)
    )
  )
  (?fsmc:consumer implicit_autowire_consumer)
  (?wiring:wiring
    (producer.output_data consumer.input_data)
    (consumer.result_data result_data)
  )
)

(?fsm:implicit_autowire_producer
  (+params
    (RESET_VALUE 8'h00)
  )
  (+size
    (output_data 1)
  )

  (-drive_outputs
    (= (output_data> 1'b1))
  )
)

(?fsm:implicit_autowire_consumer
  (+size
    (input_data 1)
    (result_data 1)
  )

  (-drive_outputs
    (= (result_data> input_data))
  )
)
FSM
);
write_file(
    $generated_fsmc_aggregate_generic_map_path,
    <<'FSM'
(?top:vhdl_generated_fsmc_aggregate_generic_map_top
  (+constants
    (LOCAL_LANES (8'hA5 8'h3C))
    (LOCAL_FRAME ((mode 2'b10) (flag 1)))
  )
  (?ports:public_io
    clk
    rst_n
    result_data>
  )
  (?fsmc:producer implicit_autowire_producer
    (params
      (LANES LOCAL_LANES)
      (FRAME LOCAL_FRAME)
    )
  )
  (?fsmc:consumer implicit_autowire_consumer)
  (?wiring:wiring
    (producer.output_data consumer.input_data)
    (consumer.result_data result_data)
  )
)

(?fsm:implicit_autowire_producer
  (+params
    (LANES (8'h00 8'h00))
    (FRAME ((mode 2'b00) (flag 0)))
  )
  (+size
    (output_data 1)
  )

  (-drive_outputs
    (= (output_data> 1'b1))
  )
)

(?fsm:implicit_autowire_consumer
  (+size
    (input_data 1)
    (result_data 1)
  )

  (-drive_outputs
    (= (result_data> input_data))
  )
)
FSM
);
write_file(
    $generated_fsmc_one_bit_generic_map_path,
    <<'FSM'
(?top:vhdl_generated_fsmc_one_bit_generic_map_top
  (?ports:public_io
    clk
    rst_n
    result_data>
  )
  (?fsmc:producer implicit_autowire_producer
    (params
      (ENABLE_DEFAULT 1'b1)
    )
  )
  (?fsmc:consumer implicit_autowire_consumer)
  (?wiring:wiring
    (producer.output_data consumer.input_data)
    (consumer.result_data result_data)
  )
)

(?fsm:implicit_autowire_producer
  (+params
    (ENABLE_DEFAULT 1'b0)
  )
  (+size
    (output_data 1)
  )

  (-drive_outputs
    (= (output_data> 1'b1))
  )
)

(?fsm:implicit_autowire_consumer
  (+size
    (input_data 1)
    (result_data 1)
  )

  (-drive_outputs
    (= (result_data> input_data))
  )
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'vhdl',
    quiet => 1,
);

my $bounded_result = $pipeline->generate_hdl_from_file($bounded_composition_path);
like(
    $bounded_result->{hdl_code},
    qr/\bentity\s+composition_intent_integer_literals\s+is\b/s,
    'pipeline emits the bounded C3 external-RTL composition VHDL entity',
);
like(
    $bounded_result->{hdl_code},
    qr/\bdecimal_out\s+:\s+out\s+std_logic_vector\(4\s+downto\s+0\);/s,
    'pipeline emits VHDL structural top vector output ports',
);
like(
    $bounded_result->{hdl_code},
    qr/\bdecimal_out\s+<=\s+"10111";/s,
    'pipeline emits VHDL concurrent literal assignment',
);
like(
    $bounded_result->{hdl_code},
    qr/\bpacked_out\s+<=\s+"10111"\s+&\s+"11110110"\s+&\s+"00000000000000000001";/s,
    'pipeline emits VHDL concurrent concat assignment',
);
like(
    $bounded_result->{hdl_code},
    qr/\buart_tx\s+:\s+entity\s+work\.uart_tx\s+port\s+map\s*\(\s*decimal_in\s+=>\s+"10111",\s*negative_in\s+=>\s+"11110110",\s*packed_in\s+=>\s+"10111"\s+&\s+"11110110"\s+&\s+"00000000000000000001"\s*\);/s,
    'pipeline emits VHDL external-RTL entity port map with literal and concat actuals',
);
unlike(
    $bounded_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'pipeline bounded composition VHDL output does not leak SystemVerilog syntax',
);

my $scalar_generic_map_result = $pipeline->generate_hdl_from_file($scalar_generic_map_path);
like(
    $scalar_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_scalar_generic_map_top\s+is\b/s,
    'pipeline emits the scalar generic-map VHDL composition entity',
);
like(
    $scalar_generic_map_result->{hdl_code},
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16,\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'pipeline emits scalar integer and sized bitstring VHDL generic maps before the external RTL port map',
);
unlike(
    $scalar_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|8'hA5/s,
    'pipeline scalar generic-map VHDL output does not leak SystemVerilog structural syntax or generic literals',
);

my $package_generic_map_result = $pipeline->generate_hdl_from_file($package_generic_map_path);
like(
    $package_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_package_generic_map_top\s+is\b/s,
    'pipeline emits the package-backed generic-map VHDL composition entity',
);
like(
    $package_generic_map_result->{hdl_code},
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16,\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'pipeline emits resolved package-backed scalar integer and sized bitstring VHDL generic maps before the port map',
);
unlike(
    $package_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|8'hA5|\bparam_pkg\b/s,
    'pipeline package-backed generic-map VHDL output does not leak SystemVerilog syntax, raw literals, or package tokens',
);

like(
    $pipeline->generate_hdl_from_file($expression_generic_map_path)->{hdl_code},
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*EXPR_WIDTH\s+=>\s+\(16\s+\+\s+1\)\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'pipeline emits resolved scalar expression VHDL generic maps before the external RTL port map',
);

my $one_bit_generic_map_result = $pipeline->generate_hdl_from_file($one_bit_generic_map_path);
my $one_bit_generic_map_override = $one_bit_generic_map_result->{composition_plan}->instances->[0]->parameter_overrides->[0];
is(
    $one_bit_generic_map_override->{declaration_default_value_kind},
    'scalar',
    'pipeline one-bit generic-map override records scalar declaration default metadata',
);
is(
    $one_bit_generic_map_override->{declaration_default_value_width},
    1,
    'pipeline one-bit generic-map override records one-bit declaration default width',
);
is(
    $one_bit_generic_map_override->{value_width},
    1,
    'pipeline one-bit generic-map override records one-bit actual width',
);
like(
    $one_bit_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_one_bit_generic_map_top\s+is\b/s,
    'pipeline emits the one-bit generic-map VHDL composition entity',
);
like(
    $one_bit_generic_map_result->{hdl_code},
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'pipeline emits metadata-backed one-bit VHDL generic maps before the external RTL port map',
);
unlike(
    $one_bit_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|1'b1/s,
    'pipeline one-bit generic-map VHDL output does not leak SystemVerilog syntax or one-bit literals',
);

my $aggregate_generic_map_result = $pipeline->generate_hdl_from_file($aggregate_generic_map_path);
like(
    $aggregate_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_aggregate_generic_map_top\s+is\b/s,
    'pipeline emits the aggregate generic-map VHDL composition entity',
);
like(
    $aggregate_generic_map_result->{hdl_code},
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*LANES\s+=>\s+"1010010100111100",\s*FRAME\s+=>\s+"101"\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'pipeline emits resolved list and record-like aggregate VHDL generic maps before the port map',
);
unlike(
    $aggregate_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|16'b1010010100111100|3'b101/s,
    'pipeline aggregate generic-map VHDL output does not leak SystemVerilog syntax or packed literal tokens',
);

my $standalone_dtc_result = $pipeline->generate_hdl_from_file($standalone_dtc_composition_path);
like(
    $standalone_dtc_result->{hdl_code},
    qr/\bentity\s+standalone_route_src\s+is\b/s,
    'pipeline emits the standalone-DT child VHDL entity',
);
like(
    $standalone_dtc_result->{hdl_code},
    qr/\bentity\s+standalone_dtc_explicit_system_autowire\s+is\b/s,
    'pipeline emits the bounded C1 standalone-DT composition VHDL entity',
);
like(
    $standalone_dtc_result->{hdl_code},
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*data_in\s+=>\s+data_in,\s*result_data\s+=>\s+result_data\s*\);/s,
    'pipeline emits the standalone-DT child VHDL entity port map',
);
unlike(
    $standalone_dtc_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'pipeline standalone-DT composition VHDL output does not leak SystemVerilog syntax',
);

my $standalone_dtc_scalar_generic_map_result = $pipeline->generate_hdl_from_file($standalone_dtc_scalar_generic_map_path);
like(
    $standalone_dtc_scalar_generic_map_result->{hdl_code},
    qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*WIDTH\s+:\s+integer\s*:=\s*8\s*\);\s+port\s*\(/s,
    'pipeline emits the standalone-DT child VHDL scalar generic declaration',
);
like(
    $standalone_dtc_scalar_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_standalone_dtc_scalar_generic_map_top\s+is\b/s,
    'pipeline emits the standalone-DT scalar generic-map VHDL composition entity',
);
like(
    $standalone_dtc_scalar_generic_map_result->{hdl_code},
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*data_in\s+=>\s+data_in,\s*result_data\s+=>\s+result_data\s*\);/s,
    'pipeline emits standalone-DT scalar generic maps before the child port map',
);
unlike(
    $standalone_dtc_scalar_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.WIDTH\s*\(/s,
    'pipeline standalone-DT scalar generic-map VHDL output does not leak SystemVerilog generic syntax',
);

my $standalone_dtc_expression_generic_map_result = $pipeline->generate_hdl_from_file($standalone_dtc_expression_generic_map_path);
like(
    $standalone_dtc_expression_generic_map_result->{hdl_code},
    qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*EXPR_WIDTH\s+:\s+integer\s*:=\s*8\s*\);\s+port\s*\(/s,
    'pipeline emits the standalone-DT child VHDL scalar expression generic declaration',
);
like(
    $standalone_dtc_expression_generic_map_result->{hdl_code},
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*EXPR_WIDTH\s+=>\s+\(8\s+\+\s+1\)\s*\)\s+port\s+map\s*\(/s,
    'pipeline emits standalone-DT scalar expression generic maps before the child port map',
);
unlike(
    $standalone_dtc_expression_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.EXPR_WIDTH\s*\(/s,
    'pipeline standalone-DT scalar expression generic-map VHDL output does not leak SystemVerilog generic syntax',
);

my $standalone_dtc_one_bit_generic_map_result = $pipeline->generate_hdl_from_file($standalone_dtc_one_bit_generic_map_path);
like(
    $standalone_dtc_one_bit_generic_map_result->{hdl_code},
    qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*ENABLE_DEFAULT\s+:\s+std_logic\s*:=\s*'0'\s*\);\s+port\s*\(/s,
    'pipeline emits the standalone-DT child one-bit generic declaration',
);
like(
    $standalone_dtc_one_bit_generic_map_result->{hdl_code},
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(/s,
    'pipeline emits standalone-DT one-bit generic maps before the child port map',
);
unlike(
    $standalone_dtc_one_bit_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.ENABLE_DEFAULT\s*\(|1'b/s,
    'pipeline standalone-DT one-bit generic-map VHDL output does not leak SystemVerilog generic syntax or one-bit literals',
);

my $standalone_dtc_bitstring_generic_map_result = $pipeline->generate_hdl_from_file($standalone_dtc_bitstring_generic_map_path);
like(
    $standalone_dtc_bitstring_generic_map_result->{hdl_code},
    qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*RESET_VALUE\s+:\s+std_logic_vector\(7\s+downto\s+0\)\s*:=\s*"00000000"\s*\);\s+port\s*\(/s,
    'pipeline emits the standalone-DT child multi-bit generic declaration',
);
like(
    $standalone_dtc_bitstring_generic_map_result->{hdl_code},
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(/s,
    'pipeline emits standalone-DT multi-bit generic maps before the child port map',
);
unlike(
    $standalone_dtc_bitstring_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.RESET_VALUE\s*\(|8'h/s,
    'pipeline standalone-DT multi-bit generic-map VHDL output does not leak SystemVerilog generic syntax or sized literals',
);

my $generated_fsmc_result = $pipeline->generate_hdl_from_file($generated_fsmc_composition_path);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bentity\s+implicit_autowire_producer\s+is\b/s,
    'pipeline emits the generated-FSM producer child VHDL entity',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bshared_dp_export_output_data_1_b1_en\s+:\s+out\s+std_logic\b/s,
    'pipeline emits VHDL shared-datapath export ports on generated-FSM children',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bentity\s+implicit_composition_system_autowire\s+is\b/s,
    'pipeline emits the bounded C2 generated-FSM composition VHDL entity',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bsignal\s+comp_link_producer_output_data\s+:\s+std_logic;/s,
    'pipeline emits VHDL scalar internal structural signals',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*output_data\s+=>\s+comp_link_producer_output_data,\s*shared_dp_export_output_data_1_b1_en\s+=>\s+shared_dp_unused_producer_shared_dp_export_output_data_1_b1_en\s*\);/s,
    'pipeline emits the generated-FSM producer VHDL entity port map',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bconsumer\s+:\s+entity\s+work\.implicit_autowire_consumer\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*input_data\s+=>\s+comp_link_producer_output_data,\s*result_data\s+=>\s+result_data,\s*shared_dp_export_result_data_input_data_en\s+=>\s+shared_dp_unused_consumer_shared_dp_export_result_data_input_data_en\s*\);/s,
    'pipeline emits the generated-FSM consumer VHDL entity port map',
);
unlike(
    $generated_fsmc_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'pipeline generated-FSM composition VHDL output does not leak SystemVerilog syntax',
);

my $generated_fsmc_scalar_generic_map_result = $pipeline->generate_hdl_from_file($generated_fsmc_scalar_generic_map_path);
like(
    $generated_fsmc_scalar_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_generated_fsmc_scalar_generic_map_top\s+is\b/s,
    'pipeline emits the generated-FSM scalar generic-map VHDL composition entity',
);
like(
    $generated_fsmc_scalar_generic_map_result->{hdl_code},
    qr/\bentity\s+implicit_autowire_producer\s+is\s+generic\s*\(\s*WIDTH\s+:\s+integer\s*:=\s*8\s*\);\s+port\s*\(/s,
    'pipeline emits the generated child VHDL generic declaration',
);
like(
    $generated_fsmc_scalar_generic_map_result->{hdl_code},
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*output_data\s+=>\s+comp_link_producer_output_data,\s*shared_dp_export_output_data_1_b1_en\s+=>\s+shared_dp_unused_producer_shared_dp_export_output_data_1_b1_en\s*\);/s,
    'pipeline emits scalar integer VHDL generic maps before the generated-FSM port map',
);
unlike(
    $generated_fsmc_scalar_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.WIDTH\s*\(/s,
    'pipeline generated-FSM scalar generic-map VHDL output does not leak SystemVerilog generic syntax',
);

my $generated_fsmc_expression_generic_map_result = $pipeline->generate_hdl_from_file($generated_fsmc_expression_generic_map_path);
like(
    $generated_fsmc_expression_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_generated_fsmc_expression_generic_map_top\s+is\b/s,
    'pipeline emits the generated-FSM expression generic-map VHDL composition entity',
);
like(
    $generated_fsmc_expression_generic_map_result->{hdl_code},
    qr/\bentity\s+implicit_autowire_producer\s+is\s+generic\s*\(\s*EXPR_WIDTH\s+:\s+integer\s*:=\s*8\s*\);\s+port\s*\(/s,
    'pipeline emits the generated child VHDL integer generic declaration for expression overrides',
);
like(
    $generated_fsmc_expression_generic_map_result->{hdl_code},
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*EXPR_WIDTH\s+=>\s+\(16\s+\+\s+1\)\s*\)\s+port\s+map\s*\(/s,
    'pipeline emits scalar expression VHDL generic maps before the generated-FSM port map',
);
unlike(
    $generated_fsmc_expression_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.EXPR_WIDTH\s*\(/s,
    'pipeline generated-FSM expression generic-map VHDL output does not leak SystemVerilog generic syntax',
);

my $generated_fsmc_bitstring_generic_map_result = $pipeline->generate_hdl_from_file($generated_fsmc_bitstring_generic_map_path);
like(
    $generated_fsmc_bitstring_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_generated_fsmc_bitstring_generic_map_top\s+is\b/s,
    'pipeline emits the generated-FSM bitstring generic-map VHDL composition entity',
);
like(
    $generated_fsmc_bitstring_generic_map_result->{hdl_code},
    qr/\bentity\s+implicit_autowire_producer\s+is\s+generic\s*\(\s*RESET_VALUE\s+:\s+std_logic_vector\(7\s+downto\s+0\)\s*:=\s*"00000000"\s*\);\s+port\s*\(/s,
    'pipeline emits the generated child VHDL bitstring generic declaration',
);
like(
    $generated_fsmc_bitstring_generic_map_result->{hdl_code},
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(/s,
    'pipeline emits multi-bit sized bitstring VHDL generic maps before the generated-FSM port map',
);
unlike(
    $generated_fsmc_bitstring_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.RESET_VALUE\s*\(|8'hA5/s,
    'pipeline generated-FSM bitstring generic-map VHDL output does not leak SystemVerilog generic syntax or bitstring literals',
);

my $generated_fsmc_aggregate_generic_map_result = $pipeline->generate_hdl_from_file($generated_fsmc_aggregate_generic_map_path);
like(
    $generated_fsmc_aggregate_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_generated_fsmc_aggregate_generic_map_top\s+is\b/s,
    'pipeline emits the generated-FSM aggregate generic-map VHDL composition entity',
);
like(
    $generated_fsmc_aggregate_generic_map_result->{hdl_code},
    qr/\bLANES\s+:\s+std_logic_vector\(15\s+downto\s+0\)\s*:=\s*"0000000000000000"/s,
    'pipeline emits the generated child VHDL packed-list generic declaration',
);
like(
    $generated_fsmc_aggregate_generic_map_result->{hdl_code},
    qr/\bFRAME\s+:\s+std_logic_vector\(2\s+downto\s+0\)\s*:=\s*"000"/s,
    'pipeline emits the generated child VHDL packed-map generic declaration',
);
like(
    $generated_fsmc_aggregate_generic_map_result->{hdl_code},
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\([^)]*\bLANES\s+=>\s+"1010010100111100"[^)]*\bFRAME\s+=>\s+"101"[^)]*\)\s+port\s+map\s*\(/s,
    'pipeline emits resolved packed aggregate VHDL generic maps before the generated-FSM port map',
);
unlike(
    $generated_fsmc_aggregate_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.LANES\s*\(|\.FRAME\s*\(|16'b|3'b/s,
    'pipeline generated-FSM aggregate generic-map VHDL output does not leak SystemVerilog generic syntax or packed literals',
);

my $generated_fsmc_one_bit_generic_map_result = $pipeline->generate_hdl_from_file($generated_fsmc_one_bit_generic_map_path);
like(
    $generated_fsmc_one_bit_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_generated_fsmc_one_bit_generic_map_top\s+is\b/s,
    'pipeline emits the generated-FSM one-bit generic-map VHDL composition entity',
);
like(
    $generated_fsmc_one_bit_generic_map_result->{hdl_code},
    qr/\bENABLE_DEFAULT\s+:\s+std_logic\s*:=\s*'0'/s,
    'pipeline emits the generated child VHDL one-bit generic declaration',
);
like(
    $generated_fsmc_one_bit_generic_map_result->{hdl_code},
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(/s,
    'pipeline emits one-bit sized bitstring VHDL generic maps before the generated-FSM port map',
);
unlike(
    $generated_fsmc_one_bit_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.ENABLE_DEFAULT\s*\(|1'b/s,
    'pipeline generated-FSM one-bit generic-map VHDL output does not leak SystemVerilog generic syntax or one-bit literals',
);

my $apb_c4_result = $pipeline->generate_hdl_from_file($apb_c4_composition_path);
like(
    $apb_c4_result->{hdl_code},
    qr/\bentity\s+apb_requester\s+is\b/s,
    'pipeline emits the APB requester child VHDL entity',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bshared_dp_export_paddr_32_h0_en\s+:\s+out\s+std_logic\b/s,
    'pipeline emits APB requester shared-datapath export ports',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bentity\s+apb_completer\s+is\b/s,
    'pipeline emits the APB completer child VHDL entity',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bentity\s+apb_tb\s+is\b/s,
    'pipeline emits the bounded APB/C4 composition VHDL entity',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\breq_addr\s+:\s+in\s+std_logic_vector\(31\s+downto\s+0\);/s,
    'pipeline emits APB vector top input ports',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bwait_cycles\s+:\s+in\s+std_logic_vector\(3\s+downto\s+0\);/s,
    'pipeline emits APB wait-cycle vector top input port',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bsignal\s+comp_link_requester_PADDR\s+:\s+std_logic_vector\(31\s+downto\s+0\);/s,
    'pipeline emits APB vector internal structural signals',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\brequester\s+:\s+entity\s+work\.apb_requester\b/s,
    'pipeline emits the APB requester VHDL entity port map',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bPADDR\s+=>\s+comp_link_requester_PADDR,/s,
    'pipeline maps requester APB address output to the structural link signal',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\b/s,
    'pipeline emits the APB completer VHDL entity port map',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bPRDATA\s+=>\s+comp_link_completer_PRDATA,/s,
    'pipeline maps completer APB read-data output to the structural link signal',
);
unlike(
    $apb_c4_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'pipeline APB/C4 composition VHDL output does not leak SystemVerilog syntax',
);

my ($bounded_success, $bounded_error_message, $bounded_full_buf, $bounded_stdout_buf, $bounded_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $bounded_output_path, $bounded_composition_path],
);

my $bounded_combined_output = join(
    '',
    @{ $bounded_stdout_buf || [] },
    @{ $bounded_stderr_buf || [] },
    ($bounded_error_message || ''),
);

ok($bounded_success, 'CLI accepts bounded composition --language vhdl for the C3 external-RTL literal/concat fixture')
    or diag($bounded_combined_output);
ok(-e $bounded_output_path, 'CLI writes bounded composition VHDL output');

my $bounded_cli_hdl = read_file($bounded_output_path);
like(
    $bounded_cli_hdl,
    qr/\bentity\s+composition_intent_integer_literals\s+is\b/s,
    'CLI bounded composition VHDL output includes the entity',
);
like(
    $bounded_cli_hdl,
    qr/\buart_tx\s+:\s+entity\s+work\.uart_tx\b/s,
    'CLI bounded composition VHDL output includes the external instance',
);
unlike(
    $bounded_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'CLI bounded composition VHDL output does not leak SystemVerilog syntax',
);

my ($scalar_generic_map_success, $scalar_generic_map_error_message, $scalar_generic_map_full_buf, $scalar_generic_map_stdout_buf, $scalar_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $scalar_generic_map_output_path, $scalar_generic_map_path],
);

my $scalar_generic_map_combined_output = join(
    '',
    @{ $scalar_generic_map_stdout_buf || [] },
    @{ $scalar_generic_map_stderr_buf || [] },
    ($scalar_generic_map_error_message || ''),
);

ok($scalar_generic_map_success, 'CLI accepts bounded composition --language vhdl for the scalar generic-map external-RTL fixture')
    or diag($scalar_generic_map_combined_output);
ok(-e $scalar_generic_map_output_path, 'CLI writes scalar generic-map composition VHDL output');

my $scalar_generic_map_cli_hdl = read_file($scalar_generic_map_output_path);
like(
    $scalar_generic_map_cli_hdl,
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16,\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'CLI scalar generic-map composition VHDL output includes the generic map',
);
unlike(
    $scalar_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|8'hA5/s,
    'CLI scalar generic-map composition VHDL output does not leak SystemVerilog syntax or generic literals',
);

my ($package_generic_map_success, $package_generic_map_error_message, $package_generic_map_full_buf, $package_generic_map_stdout_buf, $package_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $package_generic_map_output_path, $package_generic_map_path],
);

my $package_generic_map_combined_output = join(
    '',
    @{ $package_generic_map_stdout_buf || [] },
    @{ $package_generic_map_stderr_buf || [] },
    ($package_generic_map_error_message || ''),
);

ok($package_generic_map_success, 'CLI accepts bounded composition --language vhdl for the package-backed generic-map external-RTL fixture')
    or diag($package_generic_map_combined_output);
ok(-e $package_generic_map_output_path, 'CLI writes package-backed generic-map composition VHDL output');

my $package_generic_map_cli_hdl = read_file($package_generic_map_output_path);
like(
    $package_generic_map_cli_hdl,
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16,\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'CLI package-backed generic-map composition VHDL output includes resolved literal generic actuals',
);
unlike(
    $package_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|8'hA5|\bparam_pkg\b/s,
    'CLI package-backed generic-map composition VHDL output does not leak SystemVerilog syntax, raw literals, or package tokens',
);

my ($expression_generic_map_success, $expression_generic_map_error_message, $expression_generic_map_full_buf, $expression_generic_map_stdout_buf, $expression_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $expression_generic_map_output_path, $expression_generic_map_path],
);

my $expression_generic_map_combined_output = join(
    '',
    @{ $expression_generic_map_stdout_buf || [] },
    @{ $expression_generic_map_stderr_buf || [] },
    ($expression_generic_map_error_message || ''),
);

ok($expression_generic_map_success, 'CLI accepts bounded composition --language vhdl for the scalar expression generic-map external-RTL fixture')
    or diag($expression_generic_map_combined_output);
ok(-e $expression_generic_map_output_path, 'CLI writes scalar expression generic-map composition VHDL output');

my $expression_generic_map_cli_hdl = read_file($expression_generic_map_output_path);
like(
    $expression_generic_map_cli_hdl,
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*EXPR_WIDTH\s+=>\s+\(16\s+\+\s+1\)\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'CLI scalar expression generic-map composition VHDL output includes the resolved expression generic actual',
);
unlike(
    $expression_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(/s,
    'CLI scalar expression generic-map composition VHDL output does not leak SystemVerilog structural syntax',
);

my ($one_bit_generic_map_success, $one_bit_generic_map_error_message, $one_bit_generic_map_full_buf, $one_bit_generic_map_stdout_buf, $one_bit_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $one_bit_generic_map_output_path, $one_bit_generic_map_path],
);

my $one_bit_generic_map_combined_output = join(
    '',
    @{ $one_bit_generic_map_stdout_buf || [] },
    @{ $one_bit_generic_map_stderr_buf || [] },
    ($one_bit_generic_map_error_message || ''),
);

ok($one_bit_generic_map_success, 'CLI accepts bounded composition --language vhdl for the one-bit generic-map external-RTL fixture')
    or diag($one_bit_generic_map_combined_output);
ok(-e $one_bit_generic_map_output_path, 'CLI writes one-bit generic-map composition VHDL output');

my $one_bit_generic_map_cli_hdl = read_file($one_bit_generic_map_output_path);
like(
    $one_bit_generic_map_cli_hdl,
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'CLI one-bit generic-map composition VHDL output includes the metadata-backed generic actual',
);
unlike(
    $one_bit_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|1'b1/s,
    'CLI one-bit generic-map composition VHDL output does not leak SystemVerilog structural syntax or one-bit literals',
);

my ($aggregate_generic_map_success, $aggregate_generic_map_error_message, $aggregate_generic_map_full_buf, $aggregate_generic_map_stdout_buf, $aggregate_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $aggregate_generic_map_output_path, $aggregate_generic_map_path],
);

my $aggregate_generic_map_combined_output = join(
    '',
    @{ $aggregate_generic_map_stdout_buf || [] },
    @{ $aggregate_generic_map_stderr_buf || [] },
    ($aggregate_generic_map_error_message || ''),
);

ok($aggregate_generic_map_success, 'CLI accepts bounded composition --language vhdl for the aggregate generic-map external-RTL fixture')
    or diag($aggregate_generic_map_combined_output);
ok(-e $aggregate_generic_map_output_path, 'CLI writes aggregate generic-map composition VHDL output');

my $aggregate_generic_map_cli_hdl = read_file($aggregate_generic_map_output_path);
like(
    $aggregate_generic_map_cli_hdl,
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*LANES\s+=>\s+"1010010100111100",\s*FRAME\s+=>\s+"101"\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'CLI aggregate generic-map composition VHDL output includes the resolved aggregate generic actuals',
);
unlike(
    $aggregate_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|16'b1010010100111100|3'b101/s,
    'CLI aggregate generic-map composition VHDL output does not leak SystemVerilog syntax or packed literal tokens',
);

my ($standalone_dtc_success, $standalone_dtc_error_message, $standalone_dtc_full_buf, $standalone_dtc_stdout_buf, $standalone_dtc_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $standalone_dtc_output_path, $standalone_dtc_composition_path],
);

my $standalone_dtc_combined_output = join(
    '',
    @{ $standalone_dtc_stdout_buf || [] },
    @{ $standalone_dtc_stderr_buf || [] },
    ($standalone_dtc_error_message || ''),
);

ok($standalone_dtc_success, 'CLI accepts bounded composition --language vhdl for the C1 standalone-DT fixture')
    or diag($standalone_dtc_combined_output);
ok(-e $standalone_dtc_output_path, 'CLI writes bounded standalone-DT composition VHDL output');

my $standalone_dtc_cli_hdl = read_file($standalone_dtc_output_path);
like(
    $standalone_dtc_cli_hdl,
    qr/\bentity\s+standalone_route_src\s+is\b/s,
    'CLI standalone-DT composition VHDL output includes the child entity',
);
like(
    $standalone_dtc_cli_hdl,
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\b/s,
    'CLI standalone-DT composition VHDL output includes the child instance',
);
unlike(
    $standalone_dtc_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'CLI standalone-DT composition VHDL output does not leak SystemVerilog syntax',
);

my ($standalone_dtc_scalar_generic_map_success, $standalone_dtc_scalar_generic_map_error_message, $standalone_dtc_scalar_generic_map_full_buf, $standalone_dtc_scalar_generic_map_stdout_buf, $standalone_dtc_scalar_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $standalone_dtc_scalar_generic_map_output_path, $standalone_dtc_scalar_generic_map_path],
);

my $standalone_dtc_scalar_generic_map_combined_output = join(
    '',
    @{ $standalone_dtc_scalar_generic_map_stdout_buf || [] },
    @{ $standalone_dtc_scalar_generic_map_stderr_buf || [] },
    ($standalone_dtc_scalar_generic_map_error_message || ''),
);

ok($standalone_dtc_scalar_generic_map_success, 'CLI accepts bounded composition --language vhdl for the C1 standalone-DT scalar generic-map fixture')
    or diag($standalone_dtc_scalar_generic_map_combined_output);
ok(-e $standalone_dtc_scalar_generic_map_output_path, 'CLI writes bounded standalone-DT scalar generic-map composition VHDL output');

my $standalone_dtc_scalar_generic_map_cli_hdl = read_file($standalone_dtc_scalar_generic_map_output_path);
like(
    $standalone_dtc_scalar_generic_map_cli_hdl,
    qr/\bWIDTH\s+:\s+integer\s*:=\s*8\b/s,
    'CLI standalone-DT scalar generic-map output includes the child generic declaration',
);
like(
    $standalone_dtc_scalar_generic_map_cli_hdl,
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16\s*\)\s+port\s+map\s*\(/s,
    'CLI standalone-DT scalar generic-map output includes the child generic map',
);
unlike(
    $standalone_dtc_scalar_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.WIDTH\s*\(/s,
    'CLI standalone-DT scalar generic-map VHDL output does not leak SystemVerilog generic syntax',
);

my ($standalone_dtc_expression_generic_map_success, $standalone_dtc_expression_generic_map_error_message, $standalone_dtc_expression_generic_map_full_buf, $standalone_dtc_expression_generic_map_stdout_buf, $standalone_dtc_expression_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $standalone_dtc_expression_generic_map_output_path, $standalone_dtc_expression_generic_map_path],
);

my $standalone_dtc_expression_generic_map_combined_output = join(
    '',
    @{ $standalone_dtc_expression_generic_map_stdout_buf || [] },
    @{ $standalone_dtc_expression_generic_map_stderr_buf || [] },
    ($standalone_dtc_expression_generic_map_error_message || ''),
);

ok($standalone_dtc_expression_generic_map_success, 'CLI accepts standalone-DT scalar expression generic maps for VHDL')
    or diag($standalone_dtc_expression_generic_map_combined_output);
ok(-e $standalone_dtc_expression_generic_map_output_path, 'CLI writes standalone-DT expression generic-map VHDL output');

my $standalone_dtc_expression_generic_map_cli_hdl = read_file($standalone_dtc_expression_generic_map_output_path);
like(
    $standalone_dtc_expression_generic_map_cli_hdl,
    qr/\bEXPR_WIDTH\s+:\s+integer\s*:=\s*8\b/s,
    'CLI standalone-DT scalar expression generic-map output includes the child generic declaration',
);
like(
    $standalone_dtc_expression_generic_map_cli_hdl,
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*EXPR_WIDTH\s+=>\s+\(8\s+\+\s+1\)\s*\)\s+port\s+map\s*\(/s,
    'CLI standalone-DT scalar expression generic-map output includes the child generic map',
);
unlike(
    $standalone_dtc_expression_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.EXPR_WIDTH\s*\(/s,
    'CLI standalone-DT scalar expression generic-map VHDL output does not leak SystemVerilog generic syntax',
);

my ($standalone_dtc_one_bit_generic_map_success, $standalone_dtc_one_bit_generic_map_error_message, $standalone_dtc_one_bit_generic_map_full_buf, $standalone_dtc_one_bit_generic_map_stdout_buf, $standalone_dtc_one_bit_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $standalone_dtc_one_bit_generic_map_output_path, $standalone_dtc_one_bit_generic_map_path],
);

my $standalone_dtc_one_bit_generic_map_combined_output = join(
    '',
    @{ $standalone_dtc_one_bit_generic_map_stdout_buf || [] },
    @{ $standalone_dtc_one_bit_generic_map_stderr_buf || [] },
    ($standalone_dtc_one_bit_generic_map_error_message || ''),
);

ok($standalone_dtc_one_bit_generic_map_success, 'CLI accepts standalone-DT one-bit generic maps for VHDL')
    or diag($standalone_dtc_one_bit_generic_map_combined_output);
ok(-e $standalone_dtc_one_bit_generic_map_output_path, 'CLI writes standalone-DT one-bit generic-map VHDL output');

my $standalone_dtc_one_bit_generic_map_cli_hdl = read_file($standalone_dtc_one_bit_generic_map_output_path);
like(
    $standalone_dtc_one_bit_generic_map_cli_hdl,
    qr/\bENABLE_DEFAULT\s+:\s+std_logic\s*:=\s*'0'/s,
    'CLI standalone-DT one-bit generic-map output includes the child generic declaration',
);
like(
    $standalone_dtc_one_bit_generic_map_cli_hdl,
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(/s,
    'CLI standalone-DT one-bit generic-map output includes the child generic map',
);
unlike(
    $standalone_dtc_one_bit_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.ENABLE_DEFAULT\s*\(|1'b/s,
    'CLI standalone-DT one-bit generic-map VHDL output does not leak SystemVerilog generic syntax or one-bit literals',
);

my ($standalone_dtc_bitstring_generic_map_success, $standalone_dtc_bitstring_generic_map_error_message, $standalone_dtc_bitstring_generic_map_full_buf, $standalone_dtc_bitstring_generic_map_stdout_buf, $standalone_dtc_bitstring_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $standalone_dtc_bitstring_generic_map_output_path, $standalone_dtc_bitstring_generic_map_path],
);

my $standalone_dtc_bitstring_generic_map_combined_output = join(
    '',
    @{ $standalone_dtc_bitstring_generic_map_stdout_buf || [] },
    @{ $standalone_dtc_bitstring_generic_map_stderr_buf || [] },
    ($standalone_dtc_bitstring_generic_map_error_message || ''),
);

ok($standalone_dtc_bitstring_generic_map_success, 'CLI accepts standalone-DT multi-bit generic maps for VHDL')
    or diag($standalone_dtc_bitstring_generic_map_combined_output);
ok(-e $standalone_dtc_bitstring_generic_map_output_path, 'CLI writes standalone-DT multi-bit generic-map VHDL output');

my $standalone_dtc_bitstring_generic_map_cli_hdl = read_file($standalone_dtc_bitstring_generic_map_output_path);
like(
    $standalone_dtc_bitstring_generic_map_cli_hdl,
    qr/\bRESET_VALUE\s+:\s+std_logic_vector\(7\s+downto\s+0\)\s*:=\s*"00000000"/s,
    'CLI standalone-DT multi-bit generic-map output includes the child generic declaration',
);
like(
    $standalone_dtc_bitstring_generic_map_cli_hdl,
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(/s,
    'CLI standalone-DT multi-bit generic-map output includes the child generic map',
);
unlike(
    $standalone_dtc_bitstring_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.RESET_VALUE\s*\(|8'h/s,
    'CLI standalone-DT multi-bit generic-map VHDL output does not leak SystemVerilog generic syntax or sized literals',
);

my ($generated_fsmc_success, $generated_fsmc_error_message, $generated_fsmc_full_buf, $generated_fsmc_stdout_buf, $generated_fsmc_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $generated_fsmc_output_path, $generated_fsmc_composition_path],
);

my $generated_fsmc_combined_output = join(
    '',
    @{ $generated_fsmc_stdout_buf || [] },
    @{ $generated_fsmc_stderr_buf || [] },
    ($generated_fsmc_error_message || ''),
);

ok($generated_fsmc_success, 'CLI accepts bounded composition --language vhdl for the C2 generated-FSM fixture')
    or diag($generated_fsmc_combined_output);
ok(-e $generated_fsmc_output_path, 'CLI writes bounded generated-FSM composition VHDL output');

my $generated_fsmc_cli_hdl = read_file($generated_fsmc_output_path);
like(
    $generated_fsmc_cli_hdl,
    qr/\bentity\s+implicit_autowire_producer\s+is\b/s,
    'CLI generated-FSM composition VHDL output includes the producer child entity',
);
like(
    $generated_fsmc_cli_hdl,
    qr/\bsignal\s+comp_link_producer_output_data\s+:\s+std_logic;/s,
    'CLI generated-FSM composition VHDL output includes scalar structural signals',
);
like(
    $generated_fsmc_cli_hdl,
    qr/\bconsumer\s+:\s+entity\s+work\.implicit_autowire_consumer\b/s,
    'CLI generated-FSM composition VHDL output includes the consumer child instance',
);
unlike(
    $generated_fsmc_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'CLI generated-FSM composition VHDL output does not leak SystemVerilog syntax',
);

my ($generated_fsmc_scalar_generic_map_success, $generated_fsmc_scalar_generic_map_error_message, $generated_fsmc_scalar_generic_map_full_buf, $generated_fsmc_scalar_generic_map_stdout_buf, $generated_fsmc_scalar_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $generated_fsmc_scalar_generic_map_output_path, $generated_fsmc_scalar_generic_map_path],
);

my $generated_fsmc_scalar_generic_map_combined_output = join(
    '',
    @{ $generated_fsmc_scalar_generic_map_stdout_buf || [] },
    @{ $generated_fsmc_scalar_generic_map_stderr_buf || [] },
    ($generated_fsmc_scalar_generic_map_error_message || ''),
);

ok($generated_fsmc_scalar_generic_map_success, 'CLI accepts bounded composition --language vhdl for the C2 generated-FSM scalar generic-map fixture')
    or diag($generated_fsmc_scalar_generic_map_combined_output);
ok(-e $generated_fsmc_scalar_generic_map_output_path, 'CLI writes bounded generated-FSM scalar generic-map composition VHDL output');

my $generated_fsmc_scalar_generic_map_cli_hdl = read_file($generated_fsmc_scalar_generic_map_output_path);
like(
    $generated_fsmc_scalar_generic_map_cli_hdl,
    qr/\bentity\s+implicit_autowire_producer\s+is\s+generic\s*\(\s*WIDTH\s+:\s+integer\s*:=\s*8\s*\);/s,
    'CLI generated-FSM scalar generic-map composition VHDL output includes the child generic declaration',
);
like(
    $generated_fsmc_scalar_generic_map_cli_hdl,
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16\s*\)\s+port\s+map\s*\(/s,
    'CLI generated-FSM scalar generic-map composition VHDL output includes the child generic map',
);
unlike(
    $generated_fsmc_scalar_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.WIDTH\s*\(/s,
    'CLI generated-FSM scalar generic-map composition VHDL output does not leak SystemVerilog syntax',
);

my ($generated_fsmc_expression_generic_map_success, $generated_fsmc_expression_generic_map_error_message, $generated_fsmc_expression_generic_map_full_buf, $generated_fsmc_expression_generic_map_stdout_buf, $generated_fsmc_expression_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $generated_fsmc_expression_generic_map_output_path, $generated_fsmc_expression_generic_map_path],
);

my $generated_fsmc_expression_generic_map_combined_output = join(
    '',
    @{ $generated_fsmc_expression_generic_map_stdout_buf || [] },
    @{ $generated_fsmc_expression_generic_map_stderr_buf || [] },
    ($generated_fsmc_expression_generic_map_error_message || ''),
);

ok($generated_fsmc_expression_generic_map_success, 'CLI accepts bounded composition --language vhdl for the C2 generated-FSM expression generic-map fixture')
    or diag($generated_fsmc_expression_generic_map_combined_output);
ok(-e $generated_fsmc_expression_generic_map_output_path, 'CLI writes bounded generated-FSM expression generic-map composition VHDL output');

my $generated_fsmc_expression_generic_map_cli_hdl = read_file($generated_fsmc_expression_generic_map_output_path);
like(
    $generated_fsmc_expression_generic_map_cli_hdl,
    qr/\bentity\s+implicit_autowire_producer\s+is\s+generic\s*\(\s*EXPR_WIDTH\s+:\s+integer\s*:=\s*8\s*\);/s,
    'CLI generated-FSM expression generic-map composition VHDL output includes the child generic declaration',
);
like(
    $generated_fsmc_expression_generic_map_cli_hdl,
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*EXPR_WIDTH\s+=>\s+\(16\s+\+\s+1\)\s*\)\s+port\s+map\s*\(/s,
    'CLI generated-FSM expression generic-map composition VHDL output includes the child generic map',
);
unlike(
    $generated_fsmc_expression_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.EXPR_WIDTH\s*\(/s,
    'CLI generated-FSM expression generic-map composition VHDL output does not leak SystemVerilog syntax',
);

my ($generated_fsmc_bitstring_generic_map_success, $generated_fsmc_bitstring_generic_map_error_message, $generated_fsmc_bitstring_generic_map_full_buf, $generated_fsmc_bitstring_generic_map_stdout_buf, $generated_fsmc_bitstring_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $generated_fsmc_bitstring_generic_map_output_path, $generated_fsmc_bitstring_generic_map_path],
);

my $generated_fsmc_bitstring_generic_map_combined_output = join(
    '',
    @{ $generated_fsmc_bitstring_generic_map_stdout_buf || [] },
    @{ $generated_fsmc_bitstring_generic_map_stderr_buf || [] },
    ($generated_fsmc_bitstring_generic_map_error_message || ''),
);

ok($generated_fsmc_bitstring_generic_map_success, 'CLI accepts bounded composition --language vhdl for the C2 generated-FSM bitstring generic-map fixture')
    or diag($generated_fsmc_bitstring_generic_map_combined_output);
ok(-e $generated_fsmc_bitstring_generic_map_output_path, 'CLI writes bounded generated-FSM bitstring generic-map composition VHDL output');

my $generated_fsmc_bitstring_generic_map_cli_hdl = read_file($generated_fsmc_bitstring_generic_map_output_path);
like(
    $generated_fsmc_bitstring_generic_map_cli_hdl,
    qr/\bentity\s+implicit_autowire_producer\s+is\s+generic\s*\(\s*RESET_VALUE\s+:\s+std_logic_vector\(7\s+downto\s+0\)\s*:=\s*"00000000"\s*\);/s,
    'CLI generated-FSM bitstring generic-map composition VHDL output includes the child generic declaration',
);
like(
    $generated_fsmc_bitstring_generic_map_cli_hdl,
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(/s,
    'CLI generated-FSM bitstring generic-map composition VHDL output includes the child generic map',
);
unlike(
    $generated_fsmc_bitstring_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.RESET_VALUE\s*\(|8'hA5/s,
    'CLI generated-FSM bitstring generic-map composition VHDL output does not leak SystemVerilog syntax or bitstring literals',
);

my ($generated_fsmc_aggregate_generic_map_success, $generated_fsmc_aggregate_generic_map_error_message, $generated_fsmc_aggregate_generic_map_full_buf, $generated_fsmc_aggregate_generic_map_stdout_buf, $generated_fsmc_aggregate_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $generated_fsmc_aggregate_generic_map_output_path, $generated_fsmc_aggregate_generic_map_path],
);

my $generated_fsmc_aggregate_generic_map_combined_output = join(
    '',
    @{ $generated_fsmc_aggregate_generic_map_stdout_buf || [] },
    @{ $generated_fsmc_aggregate_generic_map_stderr_buf || [] },
    ($generated_fsmc_aggregate_generic_map_error_message || ''),
);

ok($generated_fsmc_aggregate_generic_map_success, 'CLI accepts bounded composition --language vhdl for the C2 generated-FSM aggregate generic-map fixture')
    or diag($generated_fsmc_aggregate_generic_map_combined_output);
ok(-e $generated_fsmc_aggregate_generic_map_output_path, 'CLI writes bounded generated-FSM aggregate generic-map composition VHDL output');

my $generated_fsmc_aggregate_generic_map_cli_hdl = read_file($generated_fsmc_aggregate_generic_map_output_path);
like(
    $generated_fsmc_aggregate_generic_map_cli_hdl,
    qr/\bLANES\s+:\s+std_logic_vector\(15\s+downto\s+0\)\s*:=\s*"0000000000000000"/s,
    'CLI generated-FSM aggregate generic-map composition VHDL output includes the packed-list generic declaration',
);
like(
    $generated_fsmc_aggregate_generic_map_cli_hdl,
    qr/\bFRAME\s+:\s+std_logic_vector\(2\s+downto\s+0\)\s*:=\s*"000"/s,
    'CLI generated-FSM aggregate generic-map composition VHDL output includes the packed-map generic declaration',
);
like(
    $generated_fsmc_aggregate_generic_map_cli_hdl,
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\([^)]*\bLANES\s+=>\s+"1010010100111100"[^)]*\bFRAME\s+=>\s+"101"[^)]*\)\s+port\s+map\s*\(/s,
    'CLI generated-FSM aggregate generic-map composition VHDL output includes the child aggregate generic map',
);
unlike(
    $generated_fsmc_aggregate_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.LANES\s*\(|\.FRAME\s*\(|16'b|3'b/s,
    'CLI generated-FSM aggregate generic-map composition VHDL output does not leak SystemVerilog syntax or packed literals',
);

my ($generated_fsmc_one_bit_generic_map_success, $generated_fsmc_one_bit_generic_map_error_message, $generated_fsmc_one_bit_generic_map_full_buf, $generated_fsmc_one_bit_generic_map_stdout_buf, $generated_fsmc_one_bit_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $generated_fsmc_one_bit_generic_map_output_path, $generated_fsmc_one_bit_generic_map_path],
);

my $generated_fsmc_one_bit_generic_map_combined_output = join(
    '',
    @{ $generated_fsmc_one_bit_generic_map_stdout_buf || [] },
    @{ $generated_fsmc_one_bit_generic_map_stderr_buf || [] },
    ($generated_fsmc_one_bit_generic_map_error_message || ''),
);

ok($generated_fsmc_one_bit_generic_map_success, 'CLI accepts bounded composition --language vhdl for the C2 generated-FSM one-bit generic-map fixture')
    or diag($generated_fsmc_one_bit_generic_map_combined_output);
ok(-e $generated_fsmc_one_bit_generic_map_output_path, 'CLI writes bounded generated-FSM one-bit generic-map composition VHDL output');

my $generated_fsmc_one_bit_generic_map_cli_hdl = read_file($generated_fsmc_one_bit_generic_map_output_path);
like(
    $generated_fsmc_one_bit_generic_map_cli_hdl,
    qr/\bENABLE_DEFAULT\s+:\s+std_logic\s*:=\s*'0'/s,
    'CLI generated-FSM one-bit generic-map composition VHDL output includes the one-bit generic declaration',
);
like(
    $generated_fsmc_one_bit_generic_map_cli_hdl,
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(/s,
    'CLI generated-FSM one-bit generic-map composition VHDL output includes the child one-bit generic map',
);
unlike(
    $generated_fsmc_one_bit_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.ENABLE_DEFAULT\s*\(|1'b/s,
    'CLI generated-FSM one-bit generic-map composition VHDL output does not leak SystemVerilog syntax or one-bit literals',
);

my ($apb_c4_success, $apb_c4_error_message, $apb_c4_full_buf, $apb_c4_stdout_buf, $apb_c4_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $apb_c4_output_path, $apb_c4_composition_path],
);

my $apb_c4_combined_output = join(
    '',
    @{ $apb_c4_stdout_buf || [] },
    @{ $apb_c4_stderr_buf || [] },
    ($apb_c4_error_message || ''),
);

ok($apb_c4_success, 'CLI accepts bounded composition --language vhdl for the APB/C4 fixture')
    or diag($apb_c4_combined_output);
ok(-e $apb_c4_output_path, 'CLI writes bounded APB/C4 composition VHDL output');

my $apb_c4_cli_hdl = read_file($apb_c4_output_path);
like(
    $apb_c4_cli_hdl,
    qr/\bentity\s+apb_tb\s+is\b/s,
    'CLI APB/C4 composition VHDL output includes the top entity',
);
like(
    $apb_c4_cli_hdl,
    qr/\bsignal\s+comp_link_requester_PWDATA\s+:\s+std_logic_vector\(31\s+downto\s+0\);/s,
    'CLI APB/C4 composition VHDL output includes vector structural signals',
);
like(
    $apb_c4_cli_hdl,
    qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\b/s,
    'CLI APB/C4 composition VHDL output includes the completer child instance',
);
unlike(
    $apb_c4_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'CLI APB/C4 composition VHDL output does not leak SystemVerilog syntax',
);

my $exception = eval {
    $pipeline->generate_hdl_from_file($composition_path);
    undef;
};
$exception = $@;

like(
    $exception,
    qr/recognized and parsed into typed composition IR, .*composition target support is blocked because the current active VHDL composition leaves only emit the bounded C3 external-RTL literal\/concat structural top, C1 standalone-DT passthrough structural top, C2 generated-FSM scalar-autowire\/scalar-bitstring-one-bit-aggregate-generic structural top, and APB\/C4 generated-FSM structural top.*Target language 'vhdl' is not implemented for this composition shape yet: generated-child composition VHDL is outside the bounded C2 scalar-autowire\/scalar-bitstring-one-bit-aggregate-generic and APB\/C4 generated-FSM structural-top leaves/s,
    'pipeline now says composition target support is blocked for unsupported composition backends',
);
like(
    $exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'pipeline target-support diagnostic points to the scoped composition doc',
);
like(
    $exception,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'pipeline target-support diagnostic points to the legacy mapping note',
);
like(
    $exception,
    qr/Target language 'vhdl' is not implemented for this composition shape yet/s,
    'pipeline target-support diagnostic names the unsupported VHDL composition target',
);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $composition_path],
);

ok(!$success, 'CLI rejects unsupported composition backend targets');
ok(!-e $output_path, 'CLI does not emit output for unsupported composition backend targets');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/recognized and parsed into typed composition IR, .*composition target support is blocked because the current active VHDL composition leaves only emit the bounded C3 external-RTL literal\/concat structural top, C1 standalone-DT passthrough structural top, C2 generated-FSM scalar-autowire\/scalar-bitstring-one-bit-aggregate-generic structural top, and APB\/C4 generated-FSM structural top.*Target language 'vhdl' is not implemented for this composition shape yet: generated-child composition VHDL is outside the bounded C2 scalar-autowire\/scalar-bitstring-one-bit-aggregate-generic and APB\/C4 generated-FSM structural-top leaves/s,
    'CLI surfaces the blocked composition target-support diagnostic',
);
like(
    $combined_output,
    qr/Target language 'vhdl' is not implemented for this composition shape yet/s,
    'CLI target-support diagnostic names the unsupported VHDL composition target',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path for read: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
