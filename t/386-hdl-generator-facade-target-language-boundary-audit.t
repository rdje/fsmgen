#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_public_constructor_option_names
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'facade contract advertises target_language as a public constructor option' => sub {
    my $contract = build_hdl_generator_facade_contract();

    is(
        $contract->{default_target_language},
        'systemverilog',
        'facade contract records the default target language',
    );
    ok(
        contains_value(
            $contract->{public_constructor_option_names},
            'target_language',
        ),
        'emitted facade contract includes target_language in public constructor options',
    );
    ok(
        contains_value(
            hdl_generator_facade_public_constructor_option_names(),
            'target_language',
        ),
        'builder-owned public constructor list includes target_language',
    );
    ok(
        contains_value(
            $contract->{constructor_option_family_map}{core_constructor_option_names},
            'target_language',
        ),
        'grouped core constructor family includes target_language',
    );
};

subtest 'facade target_language option keeps package roots import-only' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $package_path = File::Spec->catfile($tempdir, 'facade_package_root_no_direct_hdl.fsm');
    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared
  (+constants
    (WIDTH 8)
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $error;
    my $ok = eval {
        $vhdl_pipeline->generate_hdl_from_file($package_path);
        1;
    };
    $error = $@;

    ok(
        !$ok,
        'explicit VHDL facade generation rejects package roots',
    );
    like(
        $error,
        qr/Package source '\?pkg:shared' does not generate HDL directly.*not as standalone HDL-generation roots/s,
        'explicit VHDL facade rejection names the import-only package-root boundary',
    );
};

subtest 'facade target_language option rejects declared aggregate structural VHDL types' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_declared_aggregate_structural_type_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_declared_aggregate_structural_type_top
  (+types
    (type frame_t (record (tag (bits 4)) (flag bit)))
  )
  (?ports:public_io
    in_frame<frame_t
  )
  (?rtl:sink)
  (?wiring:wiring
    /in_frame.tag,payload/sink.data_in/
  )
)

(?rtlif:sink
  data_in<8:data
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $error;
    my $ok = eval {
        $vhdl_pipeline->generate_hdl_from_file($composition_path);
        1;
    };
    $error = $@;

    ok(
        !$ok,
        'explicit VHDL facade generation rejects declared aggregate structural types',
    );
    like(
        $error,
        qr/declared aggregate structural VHDL types are outside the first structural-top leaf/s,
        'explicit VHDL facade rejection names the aggregate record/array boundary',
    );
};

subtest 'facade target_language option routes direct generated-module backend behavior' => sub {
    my $direct_path = repo_file('t/corpus/direct_sreset_active_high.fsm');

    my $default_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
    );
    my $default_result = $default_pipeline->generate_hdl_from_file($direct_path);

    like(
        $default_result->{hdl_code},
        qr/\bmodule\s+direct_sreset_active_high\b/s,
        'default facade generation emits the expected direct module',
    );
    like(
        $default_result->{hdl_code},
        qr/\balways_ff\s*@\(posedge\s+clk\)/s,
        'default facade generation uses the SystemVerilog sequential block form',
    );
    like(
        $default_result->{hdl_code},
        qr/\balways_comb\s+begin/s,
        'default facade generation uses the SystemVerilog combinational block form',
    );

    my $verilog_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'verilog',
        quiet => 1,
    );
    my $verilog_result = $verilog_pipeline->generate_hdl_from_file($direct_path);

    like(
        $verilog_result->{hdl_code},
        qr/\bmodule\s+direct_sreset_active_high\b/s,
        'explicit Verilog facade generation emits the same direct module',
    );
    like(
        $verilog_result->{hdl_code},
        qr/\balways\s*@\(posedge\s+clk\)\s+begin/s,
        'explicit Verilog facade generation uses the Verilog sequential block form',
    );
    like(
        $verilog_result->{hdl_code},
        qr/\balways\s*@\*\s+begin/s,
        'explicit Verilog facade generation uses the Verilog combinational block form',
    );
    unlike(
        $verilog_result->{hdl_code},
        qr/\balways_(?:ff|comb)\b/s,
        'explicit Verilog facade generation does not leak SystemVerilog always_* forms',
    );
};

subtest 'facade target_language option routes direct VHDL scaffold behavior' => sub {
    my $direct_path = repo_file('t/corpus/direct_sreset_active_high.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+direct_sreset_active_high\s+is\b/s,
        'explicit VHDL facade generation emits the expected direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\barchitecture\s+rtl\s+of\s+direct_sreset_active_high\s+is\b/s,
        'explicit VHDL facade generation emits the direct architecture',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bprocess\(clk\)\s+begin\s+if\s+rising_edge\(clk\)\s+then/s,
        'explicit VHDL facade generation emits the synchronous state process',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL facade generation does not leak SystemVerilog module or always_* forms',
    );
};

subtest 'facade target_language option routes direct VHDL two-state vector bit declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_two_state_vector_bit.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_two_state_vector_bit
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (two_state (bits 8)))
  )
  (+size
    (OUT byte_t)
  )
  (idle
    (= (OUT 8'hA5))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_two_state_vector_bit\s+is\b/s,
        'explicit VHDL facade generation emits the two-state vector bit direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bsignal\s+OUT\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s,
        'explicit VHDL facade generation lowers generated vector bit declarations',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT\s+<=\s+"10100101";/s,
        'explicit VHDL facade generation lowers two-state vector bit literals',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\bbit\s+\[7:0\]\s+OUT\b/s,
        'explicit VHDL two-state vector bit facade generation does not leak SystemVerilog declarations',
    );
};

subtest 'facade target_language option routes direct VHDL two-state bit input ports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_two_state_bit_inputs.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_two_state_bit_inputs
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (two_state (bits 8)))
    (type flag_t (two_state (bits 1)))
  )
  (+size
    (BYTE_IN byte_t)
    (FLAG_IN flag_t)
    (OUT byte_t)
  )
  (idle
    (<FLAG_IN
      (= (OUT BYTE_IN))
    )
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_two_state_bit_inputs\s+is\b/s,
        'explicit VHDL facade generation emits the two-state bit input direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bBYTE_IN\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);/s,
        'explicit VHDL facade generation lowers generated vector bit input ports',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bFLAG_IN\s+:\s+in\s+std_logic;?/s,
        'explicit VHDL facade generation lowers generated scalar bit input ports',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\binput\s+bit\b/s,
        'explicit VHDL two-state bit input facade generation does not leak SystemVerilog port syntax',
    );
};

subtest 'facade target_language option routes direct VHDL four-state logic input ports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_four_state_logic_inputs.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_four_state_logic_inputs
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (four_state (bits 8)))
    (type flag_t (four_state (bits 1)))
  )
  (+size
    (BYTE_IN byte_t)
    (FLAG_IN flag_t)
    (OUT byte_t)
  )
  (idle
    (<FLAG_IN
      (= (OUT BYTE_IN))
    )
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_four_state_logic_inputs\s+is\b/s,
        'explicit VHDL facade generation emits the four-state logic input direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bBYTE_IN\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);/s,
        'explicit VHDL facade generation lowers generated vector logic input ports',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bFLAG_IN\s+:\s+in\s+std_logic;?/s,
        'explicit VHDL facade generation lowers generated scalar logic input ports',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\binput\s+logic\b/s,
        'explicit VHDL four-state logic input facade generation does not leak SystemVerilog port syntax',
    );
};

subtest 'facade target_language option routes bounded composition VHDL structural top behavior' => sub {
    my $composition_path = repo_file('t/corpus/composition_intent_integer_literals.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+composition_intent_integer_literals\s+is\b/s,
        'explicit VHDL facade generation emits the bounded composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bdecimal_out\s+:\s+out\s+std_logic_vector\(4\s+downto\s+0\);/s,
        'explicit VHDL facade generation emits structural vector output ports',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bdecimal_out\s+<=\s+"10111";/s,
        'explicit VHDL facade generation emits concurrent literal assignments',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bpacked_out\s+<=\s+"10111"\s+&\s+"11110110"\s+&\s+"00000000000000000001";/s,
        'explicit VHDL facade generation emits concurrent concat assignments',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\buart_tx\s+:\s+entity\s+work\.uart_tx\s+port\s+map\s*\(\s*decimal_in\s+=>\s+"10111",\s*negative_in\s+=>\s+"11110110",\s*packed_in\s+=>\s+"10111"\s+&\s+"11110110"\s+&\s+"00000000000000000001"\s*\);/s,
        'explicit VHDL facade generation emits the external RTL entity port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL facade generation does not leak SystemVerilog structural syntax',
    );
};

subtest 'facade target_language option routes bounded composition VHDL scalar generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_scalar_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_scalar_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_scalar_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the scalar generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16,\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
        'explicit VHDL facade generation emits scalar integer and sized bitstring generic maps before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|8'hA5/s,
        'explicit VHDL scalar generic-map facade generation does not leak SystemVerilog syntax or generic literals',
    );
};

subtest 'facade target_language option routes bounded composition VHDL one-bit generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_one_bit_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_one_bit_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_one_bit_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the one-bit generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
        'explicit VHDL facade generation emits one-bit generic maps before the external RTL port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|1'b1/s,
        'explicit VHDL one-bit generic-map facade generation does not leak SystemVerilog syntax or generic literals',
    );
};

subtest 'facade target_language option routes bounded composition VHDL package-backed generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_package_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_package_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_package_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the package-backed generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16,\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
        'explicit VHDL facade generation emits resolved package-backed scalar integer and sized bitstring generic maps before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|8'hA5|\bparam_pkg\b/s,
        'explicit VHDL package-backed generic-map facade generation does not leak SystemVerilog syntax, raw literals, or package tokens',
    );
};

subtest 'facade target_language option routes bounded composition VHDL scalar expression generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_expression_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_expression_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_expression_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the scalar expression generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*EXPR_WIDTH\s+=>\s+\(16\s+\+\s+1\)\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
        'explicit VHDL facade generation emits resolved scalar expression generic maps before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(/s,
        'explicit VHDL scalar expression generic-map facade generation does not leak SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes bounded composition VHDL aggregate generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_aggregate_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_aggregate_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_aggregate_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the aggregate generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*LANES\s+=>\s+"1010010100111100",\s*FRAME\s+=>\s+"101"\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
        'explicit VHDL facade generation emits resolved aggregate generic maps before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|16'b1010010100111100|3'b101/s,
        'explicit VHDL aggregate generic-map facade generation does not leak SystemVerilog syntax or packed literal tokens',
    );
};

subtest 'facade target_language option rejects external-RTL non-packed aggregate generic-map VHDL boundary' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_external_nonpacked_aggregate_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_external_nonpacked_aggregate_generic_map_top
  (?ports:public_io
    clk
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (LANES ((+ 6 1) (+ 7 1)))
    )
  )
  (?wiring:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (LANES ((+ 4 1) (+ 5 1)))
  )
  clk:clock
  data_in<16:data
  txd>:data
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $error;
    my $ok = eval {
        $vhdl_pipeline->generate_hdl_from_file($composition_path);
        1;
    };
    $error = $@;

    ok(
        !$ok,
        'explicit VHDL facade generation rejects external-RTL non-packed aggregate generic maps',
    );
    like(
        $error,
        qr/aggregate parameter\/generic values must lower to one packed literal before backend emission.*malformed_payload/s,
        'explicit VHDL facade rejection names the external-RTL non-packed aggregate packed-literal boundary',
    );
};

subtest 'facade target_language option routes bounded standalone-DT composition VHDL structural top behavior' => sub {
    my $composition_path = repo_file('t/corpus/standalone_dtc_explicit_system_autowire.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+standalone_route_src\s+is\b/s,
        'explicit VHDL facade generation emits the standalone-DT child entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+standalone_dtc_explicit_system_autowire\s+is\b/s,
        'explicit VHDL facade generation emits the standalone-DT composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*data_in\s+=>\s+data_in,\s*result_data\s+=>\s+result_data\s*\);/s,
        'explicit VHDL facade generation emits the standalone-DT passthrough port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL standalone-DT composition generation does not leak SystemVerilog structural syntax',
    );
};

subtest 'facade target_language option routes bounded standalone-DT scalar generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_standalone_dtc_scalar_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_standalone_dtc_scalar_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*WIDTH\s+:\s+integer\s*:=\s*8\s*\);\s+port\s*\(/s,
        'explicit VHDL facade generation emits the standalone-DT child scalar generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_standalone_dtc_scalar_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the standalone-DT scalar generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*data_in\s+=>\s+data_in,\s*result_data\s+=>\s+result_data\s*\);/s,
        'explicit VHDL facade generation emits standalone-DT scalar generic maps before the child port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.WIDTH\s*\(/s,
        'explicit VHDL standalone-DT scalar generic-map generation does not leak SystemVerilog generic syntax',
    );
};

subtest 'facade target_language option routes bounded standalone-DT scalar expression generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_standalone_dtc_expression_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_standalone_dtc_expression_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*EXPR_WIDTH\s+:\s+integer\s*:=\s*8\s*\);\s+port\s*\(/s,
        'explicit VHDL facade generation emits the standalone-DT child scalar expression generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*EXPR_WIDTH\s+=>\s+\(8\s+\+\s+1\)\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits standalone-DT scalar expression generic maps before the child port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.EXPR_WIDTH\s*\(/s,
        'explicit VHDL standalone-DT scalar expression generic-map generation does not leak SystemVerilog generic syntax',
    );
};

subtest 'facade target_language option routes bounded standalone-DT one-bit generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_standalone_dtc_one_bit_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_standalone_dtc_one_bit_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*ENABLE_DEFAULT\s+:\s+std_logic\s*:=\s*'0'\s*\);\s+port\s*\(/s,
        'explicit VHDL facade generation emits the standalone-DT child one-bit generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits standalone-DT one-bit generic maps before the child port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.ENABLE_DEFAULT\s*\(|1'b/s,
        'explicit VHDL standalone-DT one-bit generic-map generation does not leak SystemVerilog generic syntax or one-bit literals',
    );
};

subtest 'facade target_language option routes bounded standalone-DT multi-bit generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_standalone_dtc_bitstring_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_standalone_dtc_bitstring_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*RESET_VALUE\s+:\s+std_logic_vector\(7\s+downto\s+0\)\s*:=\s*"00000000"\s*\);\s+port\s*\(/s,
        'explicit VHDL facade generation emits the standalone-DT child multi-bit generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits standalone-DT multi-bit generic maps before the child port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.RESET_VALUE\s*\(|8'h/s,
        'explicit VHDL standalone-DT multi-bit generic-map generation does not leak SystemVerilog generic syntax or sized literals',
    );
};

subtest 'facade target_language option routes bounded standalone-DT packed-list generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_standalone_dtc_list_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_standalone_dtc_list_generic_map_top
  (?ports:public_io
    clk
    rst_n
    data_in<16
    result_data>16
  )
  (?dtc:router standalone_route_src
    (params
      (LANES (8'hA5 8'h3C))
    )
  )
)

(?dt:standalone_route_src
  (+params
    (LANES (8'h00 8'h00))
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*LANES\s+:\s+std_logic_vector\(15\s+downto\s+0\)\s*:=\s*"0000000000000000"\s*\);\s+port\s*\(/s,
        'explicit VHDL facade generation emits the standalone-DT child packed-list generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*LANES\s+=>\s+"1010010100111100"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits standalone-DT packed-list generic maps before the child port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.LANES\s*\(|16'b|8'h/s,
        'explicit VHDL standalone-DT packed-list generic-map generation does not leak SystemVerilog generic syntax or packed literals',
    );
};

subtest 'facade target_language option routes bounded standalone-DT packed-map generic-map behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_standalone_dtc_map_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_standalone_dtc_map_generic_map_top
  (?ports:public_io
    clk
    rst_n
    data_in<16
    result_data>16
  )
  (?dtc:router standalone_route_src
    (params
      (FRAME ((mode 2'b10) (flag 1)))
    )
  )
)

(?dt:standalone_route_src
  (+params
    (FRAME ((mode 2'b00) (flag 0)))
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+standalone_route_src\s+is\s+generic\s*\(\s*FRAME\s+:\s+std_logic_vector\(2\s+downto\s+0\)\s*:=\s*"000"\s*\);\s+port\s*\(/s,
        'explicit VHDL facade generation emits the standalone-DT child packed-map generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+generic\s+map\s*\(\s*FRAME\s+=>\s+"101"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits standalone-DT packed-map generic maps before the child port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.FRAME\s*\(|3'b|2'b/s,
        'explicit VHDL standalone-DT packed-map generic-map generation does not leak SystemVerilog generic syntax or packed literals',
    );
};

subtest 'facade target_language option rejects standalone-DT non-packed aggregate generic-map VHDL boundary' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_standalone_dtc_nonpacked_aggregate_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_standalone_dtc_nonpacked_aggregate_generic_map_top
  (?ports:public_io
    clk
    rst_n
    data_in<16
    result_data>16
  )
  (?dtc:router standalone_route_src
    (params
      (LANES ((+ 6 1) (+ 7 1)))
    )
  )
)

(?dt:standalone_route_src
  (+params
    (LANES ((+ 4 1) (+ 5 1)))
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $error;
    my $ok = eval {
        $vhdl_pipeline->generate_hdl_from_file($composition_path);
        1;
    };
    $error = $@;

    ok(
        !$ok,
        'explicit VHDL facade generation rejects standalone-DT non-packed aggregate generic maps',
    );
    like(
        $error,
        qr/aggregate parameter\/generic values must lower to one packed literal before backend emission.*malformed_payload/s,
        'explicit VHDL facade rejection names the standalone-DT non-packed aggregate packed-literal boundary',
    );
};

subtest 'facade target_language option routes bounded generated-FSM composition VHDL structural top behavior' => sub {
    my $composition_path = repo_file('t/corpus/implicit_composition_system_autowire.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+implicit_autowire_producer\s+is\b/s,
        'explicit VHDL facade generation emits the generated-FSM producer child entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bshared_dp_export_output_data_1_b1_en\s+:\s+out\s+std_logic\b/s,
        'explicit VHDL facade generation emits generated-FSM shared-datapath export ports',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+implicit_composition_system_autowire\s+is\b/s,
        'explicit VHDL facade generation emits the generated-FSM composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bsignal\s+comp_link_producer_output_data\s+:\s+std_logic;/s,
        'explicit VHDL facade generation emits scalar internal structural signals',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bconsumer\s+:\s+entity\s+work\.implicit_autowire_consumer\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*input_data\s+=>\s+comp_link_producer_output_data,\s*result_data\s+=>\s+result_data,\s*shared_dp_export_result_data_input_data_en\s+=>\s+shared_dp_unused_consumer_shared_dp_export_result_data_input_data_en\s*\);/s,
        'explicit VHDL facade generation emits the generated-FSM consumer port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL generated-FSM composition generation does not leak SystemVerilog structural syntax',
    );
};

subtest 'facade target_language option routes bounded generated-FSM scalar generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_generated_fsmc_scalar_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_generated_fsmc_scalar_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_generated_fsmc_scalar_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the generated-FSM scalar generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+implicit_autowire_producer\s+is\s+generic\s*\(\s*WIDTH\s+:\s+integer\s*:=\s*8\s*\);/s,
        'explicit VHDL facade generation emits the generated child generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the generated-FSM scalar generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.WIDTH\s*\(/s,
        'explicit VHDL generated-FSM scalar generic-map generation does not leak SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes bounded generated-FSM expression generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_generated_fsmc_expression_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_generated_fsmc_expression_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_generated_fsmc_expression_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the generated-FSM expression generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+implicit_autowire_producer\s+is\s+generic\s*\(\s*EXPR_WIDTH\s+:\s+integer\s*:=\s*8\s*\);/s,
        'explicit VHDL facade generation emits the generated child expression generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*EXPR_WIDTH\s+=>\s+\(16\s+\+\s+1\)\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the generated-FSM expression generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.EXPR_WIDTH\s*\(/s,
        'explicit VHDL generated-FSM expression generic-map generation does not leak SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes bounded generated-FSM bitstring generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_generated_fsmc_bitstring_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_generated_fsmc_bitstring_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_generated_fsmc_bitstring_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the generated-FSM bitstring generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+implicit_autowire_producer\s+is\s+generic\s*\(\s*RESET_VALUE\s+:\s+std_logic_vector\(7\s+downto\s+0\)\s*:=\s*"00000000"\s*\);/s,
        'explicit VHDL facade generation emits the generated child bitstring generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the generated-FSM bitstring generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.RESET_VALUE\s*\(|8'hA5/s,
        'explicit VHDL generated-FSM bitstring generic-map generation does not leak SystemVerilog syntax or bitstring literals',
    );
};

subtest 'facade target_language option routes bounded generated-FSM aggregate generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_generated_fsmc_aggregate_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_generated_fsmc_aggregate_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_generated_fsmc_aggregate_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the generated-FSM aggregate generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bLANES\s+:\s+std_logic_vector\(15\s+downto\s+0\)\s*:=\s*"0000000000000000"/s,
        'explicit VHDL facade generation emits the generated child packed-list generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bFRAME\s+:\s+std_logic_vector\(2\s+downto\s+0\)\s*:=\s*"000"/s,
        'explicit VHDL facade generation emits the generated child packed-map generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\([^)]*\bLANES\s+=>\s+"1010010100111100"[^)]*\bFRAME\s+=>\s+"101"[^)]*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the generated-FSM aggregate generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.LANES\s*\(|\.FRAME\s*\(|16'b|3'b/s,
        'explicit VHDL generated-FSM aggregate generic-map generation does not leak SystemVerilog syntax or packed literals',
    );
};

subtest 'facade target_language option rejects generated-FSM non-packed aggregate generic-map VHDL boundary' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_generated_fsmc_nonpacked_aggregate_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_generated_fsmc_nonpacked_aggregate_generic_map_top
  (?ports:public_io
    clk
    rst_n
    result_data>
  )
  (?fsmc:producer implicit_autowire_producer
    (params
      (LANES ((+ 6 1) (+ 7 1)))
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
    (LANES ((+ 4 1) (+ 5 1)))
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $error;
    my $ok = eval {
        $vhdl_pipeline->generate_hdl_from_file($composition_path);
        1;
    };
    $error = $@;

    ok(
        !$ok,
        'explicit VHDL facade generation rejects generated-FSM non-packed aggregate generic maps',
    );
    like(
        $error,
        qr/aggregate parameter\/generic values must lower to one packed literal before backend emission.*malformed_payload/s,
        'explicit VHDL facade rejection names the generated-FSM non-packed aggregate packed-literal boundary',
    );
};

subtest 'facade target_language option routes bounded generated-FSM one-bit generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_vhdl_generated_fsmc_one_bit_generic_map_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:facade_vhdl_generated_fsmc_one_bit_generic_map_top
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

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_vhdl_generated_fsmc_one_bit_generic_map_top\s+is\b/s,
        'explicit VHDL facade generation emits the generated-FSM one-bit generic-map composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bENABLE_DEFAULT\s+:\s+std_logic\s*:=\s*'0'/s,
        'explicit VHDL facade generation emits the generated child one-bit generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the generated-FSM one-bit generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.ENABLE_DEFAULT\s*\(|1'b/s,
        'explicit VHDL generated-FSM one-bit generic-map generation does not leak SystemVerilog syntax or one-bit literals',
    );
};

subtest 'facade target_language option routes bounded APB/C4 composition VHDL structural top behavior' => sub {
    my $composition_path = repo_file('fsm/apb_tb.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+apb_requester\s+is\b/s,
        'explicit VHDL facade generation emits the APB requester child entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+apb_tb\s+is\b/s,
        'explicit VHDL facade generation emits the APB/C4 composition entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bsignal\s+comp_link_requester_PADDR\s+:\s+std_logic_vector\(31\s+downto\s+0\);/s,
        'explicit VHDL facade generation emits APB vector structural signals',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brequester\s+:\s+entity\s+work\.apb_requester\b/s,
        'explicit VHDL facade generation emits the APB requester port map',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\b/s,
        'explicit VHDL facade generation emits the APB completer port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL APB/C4 composition generation does not leak SystemVerilog structural syntax',
    );
};

subtest 'facade target_language option routes bounded APB/C4 scalar generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_apb_c4_scalar_generic_map_top.fsm');
    write_apb_c4_scalar_generic_map_fixture($repo_root, $tempdir, $composition_path);

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+apb_requester\s+is\s+generic\s*\(\s*TIMEOUT_CYCLES\s+:\s+integer\s*:=\s*4\s*\);/s,
        'explicit VHDL facade generation emits the APB requester scalar generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+apb_completer\s+is\s+generic\s*\(\s*TIMEOUT_CYCLES\s+:\s+integer\s*:=\s*4\s*\);/s,
        'explicit VHDL facade generation emits the APB completer scalar generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brequester\s+:\s+entity\s+work\.apb_requester\s+generic\s+map\s*\(\s*TIMEOUT_CYCLES\s+=>\s+8\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB requester scalar generic map before the port map',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\s+generic\s+map\s*\(\s*TIMEOUT_CYCLES\s+=>\s+6\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB completer scalar generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.TIMEOUT_CYCLES\s*\(/s,
        'explicit VHDL APB/C4 scalar generic-map generation does not leak SystemVerilog generic syntax',
    );
};

subtest 'facade target_language option routes bounded APB/C4 scalar expression generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_apb_c4_expression_generic_map_top.fsm');
    write_apb_c4_scalar_generic_map_fixture(
        $repo_root,
        $tempdir,
        $composition_path,
        requester_value => '(+ 4 1)',
        completer_value => '(+ 3 3)',
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+apb_requester\s+is\s+generic\s*\(\s*TIMEOUT_CYCLES\s+:\s+integer\s*:=\s*4\s*\);/s,
        'explicit VHDL facade generation emits the APB requester scalar expression generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brequester\s+:\s+entity\s+work\.apb_requester\s+generic\s+map\s*\(\s*TIMEOUT_CYCLES\s+=>\s+\(4\s+\+\s+1\)\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB requester scalar expression generic map before the port map',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\s+generic\s+map\s*\(\s*TIMEOUT_CYCLES\s+=>\s+\(3\s+\+\s+3\)\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB completer scalar expression generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.TIMEOUT_CYCLES\s*\(/s,
        'explicit VHDL APB/C4 scalar expression generic-map generation does not leak SystemVerilog generic syntax',
    );
};

subtest 'facade target_language option routes bounded APB/C4 one-bit generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_apb_c4_one_bit_generic_map_top.fsm');
    write_apb_c4_one_bit_generic_map_fixture($repo_root, $tempdir, $composition_path);

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+apb_requester\s+is\s+generic\s*\(\s*ENABLE_DEFAULT\s+:\s+std_logic\s*:=\s*'0'\s*\);/s,
        'explicit VHDL facade generation emits the APB requester one-bit generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+apb_completer\s+is\s+generic\s*\(\s*ENABLE_DEFAULT\s+:\s+std_logic\s*:=\s*'0'\s*\);/s,
        'explicit VHDL facade generation emits the APB completer one-bit generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brequester\s+:\s+entity\s+work\.apb_requester\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB requester one-bit generic map before the port map',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\s+generic\s+map\s*\(\s*ENABLE_DEFAULT\s+=>\s+'1'\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB completer one-bit generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.ENABLE_DEFAULT\s*\(|1'b/s,
        'explicit VHDL APB/C4 one-bit generic-map generation does not leak SystemVerilog generic syntax or one-bit literals',
    );
};

subtest 'facade target_language option routes bounded APB/C4 multi-bit generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_apb_c4_bitstring_generic_map_top.fsm');
    write_apb_c4_bitstring_generic_map_fixture($repo_root, $tempdir, $composition_path);

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+apb_requester\s+is\s+generic\s*\(\s*RESET_VALUE\s+:\s+std_logic_vector\(7\s+downto\s+0\)\s*:=\s*"00000000"\s*\);/s,
        'explicit VHDL facade generation emits the APB requester multi-bit generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+apb_completer\s+is\s+generic\s*\(\s*RESET_VALUE\s+:\s+std_logic_vector\(7\s+downto\s+0\)\s*:=\s*"00000000"\s*\);/s,
        'explicit VHDL facade generation emits the APB completer multi-bit generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brequester\s+:\s+entity\s+work\.apb_requester\s+generic\s+map\s*\(\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB requester multi-bit generic map before the port map',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\s+generic\s+map\s*\(\s*RESET_VALUE\s+=>\s+"00111100"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB completer multi-bit generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.RESET_VALUE\s*\(|8'h/s,
        'explicit VHDL APB/C4 multi-bit generic-map generation does not leak SystemVerilog generic syntax or sized literals',
    );
};

subtest 'facade target_language option routes bounded APB/C4 aggregate generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_apb_c4_aggregate_generic_map_top.fsm');
    write_apb_c4_aggregate_generic_map_fixture($repo_root, $tempdir, $composition_path);

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bLANES\s+:\s+std_logic_vector\(15\s+downto\s+0\)\s*:=\s*"1010010100111100"/s,
        'explicit VHDL facade generation emits the APB packed-list generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bFRAME\s+:\s+std_logic_vector\(2\s+downto\s+0\)\s*:=\s*"000"/s,
        'explicit VHDL facade generation emits the APB packed-map generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brequester\s+:\s+entity\s+work\.apb_requester\s+generic\s+map\s*\(\s*LANES\s+=>\s+"0011110010100101",\s*FRAME\s+=>\s+"101"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB requester aggregate generic map before the port map',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\s+generic\s+map\s*\(\s*LANES\s+=>\s+"0011110010100101",\s*FRAME\s+=>\s+"101"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB completer aggregate generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.LANES\s*\(|\.FRAME\s*\(|16'b|3'b|8'h|2'b/s,
        'explicit VHDL APB/C4 aggregate generic-map generation does not leak SystemVerilog generic syntax or packed literals',
    );
};

subtest 'facade target_language option rejects APB/C4 non-packed aggregate generic-map VHDL boundary' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_apb_c4_nonpacked_aggregate_generic_map_top.fsm');
    write_apb_c4_nonpacked_aggregate_generic_map_fixture($repo_root, $tempdir, $composition_path);

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $error;
    my $ok = eval {
        $vhdl_pipeline->generate_hdl_from_file($composition_path);
        1;
    };
    $error = $@;

    ok(
        !$ok,
        'explicit VHDL facade generation rejects APB/C4 non-packed aggregate generic maps',
    );
    like(
        $error,
        qr/aggregate parameter\/generic values must lower to one packed literal before backend emission.*malformed_payload/s,
        'explicit VHDL facade rejection names the APB/C4 non-packed aggregate packed-literal boundary',
    );
};

subtest 'facade target_language option routes bounded APB/C4 package-backed generic-map VHDL behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'facade_apb_c4_package_generic_map_top.fsm');
    write_apb_c4_package_generic_map_fixture($repo_root, $tempdir, $composition_path);

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($composition_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bTIMEOUT_CYCLES\s+:\s+integer\s*:=\s*4\b/s,
        'explicit VHDL facade generation emits the APB package-backed scalar generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bRESET_VALUE\s+:\s+std_logic_vector\(7\s+downto\s+0\)\s*:=\s*"00000000"/s,
        'explicit VHDL facade generation emits the APB package-backed multi-bit generic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\brequester\s+:\s+entity\s+work\.apb_requester\s+generic\s+map\s*\(\s*TIMEOUT_CYCLES\s+=>\s+8,\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB requester package-backed generic map before the port map',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\s+generic\s+map\s*\(\s*TIMEOUT_CYCLES\s+=>\s+8,\s*RESET_VALUE\s+=>\s+"10100101"\s*\)\s+port\s+map\s*\(/s,
        'explicit VHDL facade generation emits the APB completer package-backed generic map before the port map',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(|\.TIMEOUT_CYCLES\s*\(|\.RESET_VALUE\s*\(|8'hA5|\bparam_pkg\b/s,
        'explicit VHDL APB/C4 package-backed generic-map generation does not leak SystemVerilog generic syntax, raw literals, or package tokens',
    );
};

subtest 'facade target_language option routes direct VHDL delayed-pulse scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_delayed_pulse_vhdl.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_delayed_pulse_vhdl
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (GO 1)
    (DONE 1)
  )
  (idle
    (<GO
      (<1 (DONE 1))
    )
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_delayed_pulse_vhdl\s+is\b/s,
        'explicit VHDL facade generation emits the delayed-pulse direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bDONE\s+<=\s+'0';\s+if\s+DONE_pulse_delay_pipe\s+=\s+'1'\s+then\s+DONE\s+<=\s+'1';\s+end if;/s,
        'explicit VHDL facade generation lowers delayed-pulse nested clock-branch if syntax',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\balways_(?:ff|comb)\b|\bif\s*\(/s,
        'explicit VHDL delayed-pulse facade generation does not leak SystemVerilog block syntax',
    );
};

subtest 'facade target_language option routes direct VHDL arithmetic scaffold behavior' => sub {
    my $direct_path = repo_file('t/corpus/direct_assignment_pair_form.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+direct_assignment_pair_form\s+is\b/s,
        'explicit VHDL facade generation emits the arithmetic direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bSUM\s+<=\s+std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(B\)\);/s,
        'explicit VHDL facade generation lowers same-width vector addition through numeric_std casts',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL arithmetic facade generation does not leak SystemVerilog module or always_* forms',
    );
};

subtest 'facade target_language option routes direct VHDL numeric-literal arithmetic scaffold behavior' => sub {
    my $direct_path = repo_file('t/corpus/compound_update_variants.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+compound_update_variants\s+is\b/s,
        'explicit VHDL facade generation emits the numeric-literal arithmetic direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bACC_next\s+<=\s+std_logic_vector\(unsigned\(SRC\)\s+\+\s+to_unsigned\(2,\s+8\)\);/s,
        'explicit VHDL facade generation lowers vector plus literal through numeric_std',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bCOMB\s+<=\s+std_logic_vector\(unsigned\(SRC\)\s+-\s+to_unsigned\(1,\s+8\)\);/s,
        'explicit VHDL facade generation lowers vector minus literal through numeric_std',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\bSRC\s+\+\s+2\b/s,
        'explicit VHDL numeric-literal arithmetic facade generation does not leak SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes direct VHDL signed negative numeric-literal arithmetic behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_negative_literal_add.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_negative_literal_add
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (SUM signed_byte_t)
  )
  (idle
    (SUM = (+ A -1))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_negative_literal_add\s+is\b/s,
        'explicit VHDL facade generation emits the signed negative literal arithmetic direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s,
        'explicit VHDL facade generation lowers signed negative literal arithmetic input port',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bSUM\s+<=\s+A\s+\+\s+to_signed\(-1,\s+8\);/s,
        'explicit VHDL facade generation lowers signed vector plus negative literal through numeric_std',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|std_logic_vector\(unsigned\(A\)\s+\+\s+to_unsigned\(-1,\s+8\)\)|to_unsigned\(-1,\s+8\)|arithmetic expression 'A \+ -1'/s,
        'explicit VHDL signed negative literal arithmetic facade generation avoids SystemVerilog syntax, unsigned casts, and the prior guard',
    );
};

subtest 'facade target_language option routes direct VHDL vector output decimal literal behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_vector_output_decimal_literal.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_vector_output_decimal_literal
  (+system
    (clock clk)
    (sreset reset)
  )
  (+interface
    (output OUT)
  )
  (+size
    (OUT 8)
  )
  (idle
    (<- (OUT> 165))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_vector_output_decimal_literal\s+is\b/s,
        'explicit VHDL facade generation emits the vector output decimal direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT\s+:\s+out\s+std_logic_vector\(7\s+downto\s+0\);?/s,
        'explicit VHDL facade generation lowers the vector output port',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT_next\s+<=\s+std_logic_vector\(to_unsigned\(165,\s+8\)\);/s,
        'explicit VHDL facade generation lowers vector output decimal literals through numeric_std',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bOUT_next\s+<=\s+165;|\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL vector output decimal facade generation avoids raw integer assignments and SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes direct VHDL vector output negative decimal literal behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_vector_output_negative_decimal_literal.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_vector_output_negative_decimal_literal
  (+system
    (clock clk)
    (sreset reset)
  )
  (+interface
    (output OUT)
  )
  (+size
    (OUT 8)
  )
  (idle
    (<- (OUT> -1))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_vector_output_negative_decimal_literal\s+is\b/s,
        'explicit VHDL facade generation emits the vector output negative decimal direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT\s+:\s+out\s+std_logic_vector\(7\s+downto\s+0\);?/s,
        'explicit VHDL facade generation lowers the vector output negative decimal port',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT_next\s+<=\s+std_logic_vector\(to_signed\(-1,\s+8\)\);/s,
        'explicit VHDL facade generation lowers vector output negative decimal literals through numeric_std',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bOUT_next\s+<=\s+-1;|to_unsigned\(-1,\s+8\)|\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL vector output negative decimal facade generation avoids raw integer assignments, unsigned casts, and SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes direct VHDL signed vector output decimal literal behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_vector_output_decimal_literal.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_vector_output_decimal_literal
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+interface
    (output OUT)
  )
  (+size
    (OUT signed_byte_t)
  )
  (idle
    (<- (OUT> 5))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_vector_output_decimal_literal\s+is\b/s,
        'explicit VHDL facade generation emits the signed vector output decimal direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT\s+:\s+out\s+signed\(7\s+downto\s+0\);?/s,
        'explicit VHDL facade generation lowers the signed vector output port',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT_next\s+<=\s+to_signed\(5,\s+8\);/s,
        'explicit VHDL facade generation lowers signed vector output decimal literals through numeric_std',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bOUT_next\s+<=\s+5;|to_unsigned\(5,\s+8\)|\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL signed vector output decimal facade generation avoids raw integer assignments, unsigned casts, and SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes direct VHDL signed vector output negative decimal literal behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_vector_output_negative_decimal_literal.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_vector_output_negative_decimal_literal
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+interface
    (output OUT)
  )
  (+size
    (OUT signed_byte_t)
  )
  (idle
    (<- (OUT> -1))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_vector_output_negative_decimal_literal\s+is\b/s,
        'explicit VHDL facade generation emits the signed vector output negative decimal direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT\s+:\s+out\s+signed\(7\s+downto\s+0\);?/s,
        'explicit VHDL facade generation lowers the signed vector output negative decimal port',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT_next\s+<=\s+to_signed\(-1,\s+8\);/s,
        'explicit VHDL facade generation lowers signed vector output negative decimal literals through numeric_std',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bOUT_next\s+<=\s+-1;|to_unsigned\(-1,\s+8\)|\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL signed vector output negative decimal facade generation avoids raw integer assignments, unsigned casts, and SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes direct VHDL scalar output decimal literal behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $scalar_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_scalar_output_decimal_literal.fsm');
    my $signed_scalar_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_scalar_output_decimal_literal.fsm');
    write_file(
        $scalar_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_scalar_output_decimal_literal
  (+system
    (clock clk)
    (sreset reset)
  )
  (+interface
    (output FLAG)
  )
  (+size
    (FLAG 1)
  )
  (idle
    (<- (FLAG> 2))
  )
)
FSM
    );

    write_file(
        $signed_scalar_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_scalar_output_decimal_literal
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_bit_t (four_state (signed (bits 1))))
  )
  (+interface
    (output FLAG)
  )
  (+size
    (FLAG signed_bit_t)
  )
  (idle
    (<- (FLAG> 3))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $scalar_result = $vhdl_pipeline->generate_hdl_from_file($scalar_path);
    my $signed_scalar_result = $vhdl_pipeline->generate_hdl_from_file($signed_scalar_path);

    like(
        $scalar_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_scalar_output_decimal_literal\s+is\b/s,
        'explicit VHDL facade generation emits the scalar output decimal direct entity',
    );
    like(
        $scalar_result->{hdl_code},
        qr/\bFLAG\s+:\s+out\s+std_logic;?/s,
        'explicit VHDL facade generation lowers the scalar output port',
    );
    like(
        $scalar_result->{hdl_code},
        qr/\bFLAG_next\s+<=\s+'0';/s,
        'explicit VHDL facade generation lowers even scalar output decimal literals to std_logic zero',
    );
    unlike(
        $scalar_result->{hdl_code},
        qr/\bFLAG_next\s+<=\s+2;|to_unsigned\(2,\s+1\)|to_signed\(2,\s+1\)|\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL scalar output decimal facade generation avoids raw integer assignments, vector casts, and SystemVerilog syntax',
    );

    like(
        $signed_scalar_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_scalar_output_decimal_literal\s+is\b/s,
        'explicit VHDL facade generation emits the signed scalar output decimal direct entity',
    );
    like(
        $signed_scalar_result->{hdl_code},
        qr/\bFLAG\s+:\s+out\s+std_logic;?/s,
        'explicit VHDL facade generation lowers the signed scalar output port',
    );
    like(
        $signed_scalar_result->{hdl_code},
        qr/\bFLAG_next\s+<=\s+'1';/s,
        'explicit VHDL facade generation lowers odd signed scalar output decimal literals to std_logic one',
    );
    unlike(
        $signed_scalar_result->{hdl_code},
        qr/\bFLAG_next\s+<=\s+3;|to_unsigned\(3,\s+1\)|to_signed\(3,\s+1\)|\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL signed scalar output decimal facade generation avoids raw integer assignments, vector casts, and SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes direct VHDL scalar output negative decimal literal behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $scalar_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_scalar_output_negative_decimal_literal.fsm');
    my $signed_scalar_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_scalar_output_negative_decimal_literal.fsm');
    write_file(
        $scalar_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_scalar_output_negative_decimal_literal
  (+system
    (clock clk)
    (sreset reset)
  )
  (+interface
    (output FLAG)
  )
  (+size
    (FLAG 1)
  )
  (idle
    (<- (FLAG> -1))
  )
)
FSM
    );

    write_file(
        $signed_scalar_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_scalar_output_negative_decimal_literal
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_bit_t (four_state (signed (bits 1))))
  )
  (+interface
    (output FLAG)
  )
  (+size
    (FLAG signed_bit_t)
  )
  (idle
    (<- (FLAG> -2))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $scalar_result = $vhdl_pipeline->generate_hdl_from_file($scalar_path);
    my $signed_scalar_result = $vhdl_pipeline->generate_hdl_from_file($signed_scalar_path);

    like(
        $scalar_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_scalar_output_negative_decimal_literal\s+is\b/s,
        'explicit VHDL facade generation emits the scalar output negative decimal direct entity',
    );
    like(
        $scalar_result->{hdl_code},
        qr/\bFLAG\s+:\s+out\s+std_logic;?/s,
        'explicit VHDL facade generation lowers the scalar output negative decimal port',
    );
    like(
        $scalar_result->{hdl_code},
        qr/\bFLAG_next\s+<=\s+'1';/s,
        'explicit VHDL facade generation lowers odd scalar output negative decimal literals to std_logic one',
    );
    unlike(
        $scalar_result->{hdl_code},
        qr/\bFLAG_next\s+<=\s+-1;|to_unsigned\(-1,\s+1\)|to_signed\(-1,\s+1\)|\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL scalar output negative decimal facade generation avoids raw integer assignments, vector casts, and SystemVerilog syntax',
    );

    like(
        $signed_scalar_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_scalar_output_negative_decimal_literal\s+is\b/s,
        'explicit VHDL facade generation emits the signed scalar output negative decimal direct entity',
    );
    like(
        $signed_scalar_result->{hdl_code},
        qr/\bFLAG\s+:\s+out\s+std_logic;?/s,
        'explicit VHDL facade generation lowers the signed scalar output negative decimal port',
    );
    like(
        $signed_scalar_result->{hdl_code},
        qr/\bFLAG_next\s+<=\s+'0';/s,
        'explicit VHDL facade generation lowers even signed scalar output negative decimal literals to std_logic zero',
    );
    unlike(
        $signed_scalar_result->{hdl_code},
        qr/\bFLAG_next\s+<=\s+-2;|to_unsigned\(-2,\s+1\)|to_signed\(-2,\s+1\)|\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL signed scalar output negative decimal facade generation avoids raw integer assignments, vector casts, and SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes direct VHDL AMBA wrap arithmetic scaffold behavior' => sub {
    my $direct_path = repo_file('fsm/amba_requester.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+amba_requester\s+is\b/s,
        'explicit VHDL facade generation emits the AMBA requester direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bwrap_span_q_next\s+<=\s+std_logic_vector\(resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\);/s,
        'explicit VHDL facade generation lowers AMBA wrap span product',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bwrap_base_q_next\s+<=\s+std_logic_vector\(unsigned\(addr_q\)\s+-\s+\(unsigned\(addr_q\)\s+mod\s+resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\)\);/s,
        'explicit VHDL facade generation lowers AMBA wrap base arithmetic',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bwrap_high_q_next\s+<=\s+std_logic_vector\(unsigned\(addr_q\)\s+-\s+\(unsigned\(addr_q\)\s+mod\s+resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\)\s+\+\s+resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\);/s,
        'explicit VHDL facade generation lowers AMBA wrap high arithmetic',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\baddr_q\s*-\s*addr_q\s*%/s,
        'explicit VHDL AMBA requester facade generation does not leak SystemVerilog arithmetic syntax',
    );
};

subtest 'facade target_language option routes direct VHDL scalar bit and signed declaration behavior' => sub {
    my $direct_path = repo_file('t/corpus/declarative_bits_symbol_widths.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+declarative_bits_symbol_widths\s+is\b/s,
        'explicit VHDL facade generation emits the declarative bits direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bsignal\s+FLAG\s+:\s+std_logic;/s,
        'explicit VHDL facade generation lowers scalar bit declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bsignal\s+NIB\s+:\s+signed\(3\s+downto\s+0\);/s,
        'explicit VHDL facade generation lowers signed vector declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bFLAG\s+<=\s+'0';\s+if\s+flag_1_en\s+=\s+'1'\s+then\s+FLAG\s+<=\s+'1';/s,
        'explicit VHDL facade generation lowers scalar bit literal assignments',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\breg\s+signed\b|\bbit\s+FLAG\b/s,
        'explicit VHDL scalar bit and signed declaration facade generation does not leak SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes direct VHDL four-state logic declaration behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_cfg.fsm');
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_four_state_logic.fsm');
    my $signed_direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_logic.fsm');
    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_cfg
  (+types
    (type imported_byte (four_state (bits BYTE_W)))
    (type imported_flag (four_state (bits FLAG_W)))
  )
  (+constants
    (BYTE_W 8)
    (FLAG_W 1)
  )
)
FSM
    );
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_four_state_logic
  (+import shared_cfg)
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t shared_cfg.imported_byte)
    (type flag_t shared_cfg.imported_flag)
  )
  (+size
    (OUT byte_t)
    (ISYM byte_t)
    (LFLAG flag_t)
  )
  (idle
    (OUT = 8'hA5)
    (ISYM = OUT)
    (LFLAG = 1)
  )
)
FSM
    );
    write_file(
        $signed_direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_logic
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (IN signed_byte_t)
    (OUT signed_byte_t)
  )
  (idle
    (OUT = IN)
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
        source_search_paths => [$libdir],
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_four_state_logic\s+is\b/s,
        'explicit VHDL facade generation emits the four-state logic direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bsignal\s+ISYM\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s,
        'explicit VHDL facade generation lowers vector logic declaration',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bsignal\s+LFLAG\s+:\s+std_logic;/s,
        'explicit VHDL facade generation lowers scalar logic declaration',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\b/s,
        'explicit VHDL four-state logic facade generation does not leak SystemVerilog syntax',
    );

    my $signed_vhdl_result = $vhdl_pipeline->generate_hdl_from_file($signed_direct_path);

    like(
        $signed_vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_logic\s+is\b/s,
        'explicit VHDL facade generation emits the signed four-state logic direct entity',
    );
    like(
        $signed_vhdl_result->{hdl_code},
        qr/\bIN\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s,
        'explicit VHDL facade generation lowers signed vector input port',
    );
    like(
        $signed_vhdl_result->{hdl_code},
        qr/\bsignal\s+OUT\s+:\s+signed\(7\s+downto\s+0\);/s,
        'explicit VHDL facade generation lowers signed vector logic declaration',
    );
    unlike(
        $signed_vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\s+signed\b/s,
        'explicit VHDL signed logic facade generation does not leak SystemVerilog syntax',
    );
};

subtest 'facade target_language option routes direct VHDL signed-addition behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_addition.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_addition
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (B signed_byte_t)
    (SUM signed_byte_t)
  )
  (idle
    (SUM = (+ A B))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_addition\s+is\b/s,
        'explicit VHDL facade generation emits the signed addition direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bSUM\s+<=\s+A\s+\+\s+B;/s,
        'explicit VHDL facade generation lowers signed vector addition',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(B\)\)/s,
        'explicit VHDL signed addition facade generation does not use unsigned casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-subtraction behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_subtraction.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_subtraction
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (B signed_byte_t)
    (DIFF signed_byte_t)
  )
  (idle
    (DIFF = (- A B))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_subtraction\s+is\b/s,
        'explicit VHDL facade generation emits the signed subtraction direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bDIFF\s+<=\s+A\s+-\s+B;/s,
        'explicit VHDL facade generation lowers signed vector subtraction',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/std_logic_vector\(unsigned\(A\)\s+-\s+unsigned\(B\)\)/s,
        'explicit VHDL signed subtraction facade generation does not use unsigned casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-multiplication behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_multiplication.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_multiplication
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (B signed_byte_t)
    (PROD signed_byte_t)
  )
  (idle
    (PROD = (* A B))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_multiplication\s+is\b/s,
        'explicit VHDL facade generation emits the signed multiplication direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bPROD\s+<=\s+resize\(A\s+\*\s+B,\s+8\);/s,
        'explicit VHDL facade generation lowers signed vector multiplication',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+unsigned\(B\),\s+8\)\)/s,
        'explicit VHDL signed multiplication facade generation does not use unsigned casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-division behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_division.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_division
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (B signed_byte_t)
    (QUOT signed_byte_t)
  )
  (idle
    (QUOT = (/ A B))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_division\s+is\b/s,
        'explicit VHDL facade generation emits the signed division direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bQUOT\s+<=\s+resize\(A\s+\/\s+B,\s+8\);/s,
        'explicit VHDL facade generation lowers signed vector division',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(B\),\s+8\)\)/s,
        'explicit VHDL signed division facade generation does not use unsigned casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-modulo behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_modulo.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_modulo
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (B signed_byte_t)
    (REM signed_byte_t)
  )
  (idle
    (REM = (% A B))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_modulo\s+is\b/s,
        'explicit VHDL facade generation emits the signed modulo direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bREM\s+<=\s+resize\(A\s+mod\s+B,\s+8\);/s,
        'explicit VHDL facade generation lowers signed vector modulo',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(B\),\s+8\)\)/s,
        'explicit VHDL signed modulo facade generation does not use unsigned casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-literal-addition behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_literal_add.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_literal_add
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (SUM signed_byte_t)
  )
  (idle
    (SUM = (+ A 1))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_literal_add\s+is\b/s,
        'explicit VHDL facade generation emits the signed literal addition direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bSUM\s+<=\s+A\s+\+\s+to_signed\(1,\s+8\);/s,
        'explicit VHDL facade generation lowers signed literal addition',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/to_unsigned\(1,\s+8\)/s,
        'explicit VHDL signed literal addition facade generation does not use unsigned literal casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-literal-subtraction behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_literal_sub.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_literal_sub
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (DIFF signed_byte_t)
  )
  (idle
    (DIFF = (- A 1))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_literal_sub\s+is\b/s,
        'explicit VHDL facade generation emits the signed literal subtraction direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bDIFF\s+<=\s+A\s+-\s+to_signed\(1,\s+8\);/s,
        'explicit VHDL facade generation lowers signed literal subtraction',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/to_unsigned\(1,\s+8\)/s,
        'explicit VHDL signed literal subtraction facade generation does not use unsigned literal casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-literal-multiplication behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_literal_mul.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_literal_mul
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (PROD signed_byte_t)
  )
  (idle
    (PROD = (* A 2))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_literal_mul\s+is\b/s,
        'explicit VHDL facade generation emits the signed literal multiplication direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bPROD\s+<=\s+resize\(A\s+\*\s+to_signed\(2,\s+8\),\s+8\);/s,
        'explicit VHDL facade generation lowers signed literal multiplication',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(2,\s+8\)/s,
        'explicit VHDL signed literal multiplication facade generation does not use unsigned literal casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-literal-division behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_literal_div.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_literal_div
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (QUOT signed_byte_t)
  )
  (idle
    (QUOT = (/ A 2))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_literal_div\s+is\b/s,
        'explicit VHDL facade generation emits the signed literal division direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bQUOT\s+<=\s+resize\(A\s+\/\s+to_signed\(2,\s+8\),\s+8\);/s,
        'explicit VHDL facade generation lowers signed literal division',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(2,\s+8\)/s,
        'explicit VHDL signed literal division facade generation does not use unsigned literal casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-literal-modulo behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_literal_mod.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_literal_mod
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (REM signed_byte_t)
  )
  (idle
    (REM = (% A 2))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_literal_mod\s+is\b/s,
        'explicit VHDL facade generation emits the signed literal modulo direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bREM\s+<=\s+resize\(A\s+mod\s+to_signed\(2,\s+8\),\s+8\);/s,
        'explicit VHDL facade generation lowers signed literal modulo',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(2,\s+8\)/s,
        'explicit VHDL signed literal modulo facade generation does not use unsigned literal casts',
    );
};

subtest 'facade target_language option routes direct VHDL signed-scalar-declaration behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_signed_scalar_logic.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_signed_scalar_logic
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_bit_t (four_state (signed (bits 1))))
  )
  (+size
    (IN signed_bit_t)
    (OUT signed_bit_t)
  )
  (idle
    (OUT = IN)
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_signed_scalar_logic\s+is\b/s,
        'explicit VHDL facade generation emits the signed scalar direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bIN\s+:\s+in\s+std_logic;?/s,
        'explicit VHDL facade generation lowers signed scalar input ports to std_logic',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bsignal\s+OUT\s+:\s+std_logic;/s,
        'explicit VHDL facade generation lowers signed scalar internal declarations to std_logic',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bOUT\s+<=\s+'0';\s+if\s+\w+\s+=\s+'1'\s+then\s+OUT\s+<=\s+IN;/s,
        'explicit VHDL facade generation lowers signed scalar pass-through assignments',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\s+signed\b/s,
        'explicit VHDL signed scalar facade generation does not leak SystemVerilog declarations',
    );

    my @signed_scalar_arithmetic_cases = (
        {
            name => 'facade_direct_vhdl_signed_scalar_add',
            expr => '(SUM = (+ A B))',
            output => 'SUM',
            expected => qr/\bSUM\s+<=\s+A\s+xor\s+B;/s,
        },
        {
            name => 'facade_direct_vhdl_signed_scalar_sub',
            expr => '(DIFF = (- A B))',
            output => 'DIFF',
            expected => qr/\bDIFF\s+<=\s+A\s+xor\s+B;/s,
        },
        {
            name => 'facade_direct_vhdl_signed_scalar_mul',
            expr => '(PROD = (* A B))',
            output => 'PROD',
            expected => qr/\bPROD\s+<=\s+A\s+and\s+B;/s,
        },
        {
            name => 'facade_direct_vhdl_signed_scalar_add_chain',
            expr => '(SUM = (+ A B C))',
            output => 'SUM',
            expected => qr/\bSUM\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s,
        },
    );

    for my $case (@signed_scalar_arithmetic_cases) {
        my $name = $case->{name};
        my $expr = $case->{expr};
        my $output = $case->{output};
        my $arithmetic_path = File::Spec->catfile($tempdir, "$name.fsm");
        write_file(
            $arithmetic_path,
            <<"FSM"
(?fsm:$name
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_bit_t (four_state (signed (bits 1))))
  )
  (+size
    (A signed_bit_t)
    (B signed_bit_t)
    (C signed_bit_t)
    ($output signed_bit_t)
  )
  (idle
    $expr
  )
)
FSM
        );

        my $arithmetic_result = $vhdl_pipeline->generate_hdl_from_file($arithmetic_path);

        like(
            $arithmetic_result->{hdl_code},
            qr/\bentity\s+\Q$name\E\s+is\b/s,
            "explicit VHDL facade generation emits the $name direct entity",
        );
        like(
            $arithmetic_result->{hdl_code},
            $case->{expected},
            "explicit VHDL facade generation lowers $name",
        );
        unlike(
            $arithmetic_result->{hdl_code},
            qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\s+signed\b/s,
            "explicit VHDL $name facade generation does not leak SystemVerilog declarations",
        );
    }

    my @fail_closed_arithmetic_cases = (
        {
            name => 'facade_direct_vhdl_signed_scalar_div_deferred',
            expr => '(QUOT = (/ A B))',
            output => 'QUOT',
            b_type => 'signed_bit_t',
            diagnostic => qr/arithmetic expression 'A \/ B' is outside the direct VHDL scaffold/s,
        },
        {
            name => 'facade_direct_vhdl_signed_scalar_mod_deferred',
            expr => '(REM = (% A B))',
            output => 'REM',
            b_type => 'signed_bit_t',
            diagnostic => qr/arithmetic expression 'A % B' is outside the direct VHDL scaffold/s,
        },
        {
            name => 'facade_direct_vhdl_signed_scalar_mixed_add_deferred',
            expr => '(SUM = (+ A B))',
            output => 'SUM',
            b_type => '1',
            diagnostic => qr/arithmetic expression 'A \+ B' is outside the direct VHDL scaffold/s,
        },
    );

    for my $case (@fail_closed_arithmetic_cases) {
        my $name = $case->{name};
        my $expr = $case->{expr};
        my $output = $case->{output};
        my $b_type = $case->{b_type};
        my $fail_closed_path = File::Spec->catfile($tempdir, "$name.fsm");
        write_file(
            $fail_closed_path,
            <<"FSM"
(?fsm:$name
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_bit_t (four_state (signed (bits 1))))
  )
  (+size
    (A signed_bit_t)
    (B $b_type)
    ($output signed_bit_t)
  )
  (idle
    $expr
  )
)
FSM
        );

        my $fail_closed_error = capture_exception(sub {
            $vhdl_pipeline->generate_hdl_from_file($fail_closed_path);
        });

        like(
            $fail_closed_error,
            $case->{diagnostic},
            "$name remains outside the explicit VHDL facade arithmetic scaffold",
        );
    }
};

subtest 'facade target_language option keeps direct VHDL mixed signed/unsigned vector arithmetic fail-closed' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my @cases = (
        {
            name => 'facade_direct_vhdl_mixed_signed_unsigned_signed_target_add',
            output => 'SUM',
            output_type => 'signed_byte_t',
            expr => '(SUM = (+ A B))',
        },
        {
            name => 'facade_direct_vhdl_mixed_signed_unsigned_unsigned_target_add',
            output => 'SUM',
            output_type => '8',
            expr => '(SUM = (+ A B))',
        },
    );

    for my $case (@cases) {
        my $name = $case->{name};
        my $output = $case->{output};
        my $output_type = $case->{output_type};
        my $expr = $case->{expr};
        my $direct_path = File::Spec->catfile($tempdir, "$name.fsm");
        write_file(
            $direct_path,
            <<"FSM"
(?fsm:$name
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type signed_byte_t (four_state (signed (bits 8))))
  )
  (+size
    (A signed_byte_t)
    (B 8)
    ($output $output_type)
  )
  (idle
    $expr
  )
)
FSM
        );

        my $error = capture_exception(sub {
            $vhdl_pipeline->generate_hdl_from_file($direct_path);
        });

        like(
            $error,
            qr/arithmetic expression 'A \+ B' is outside the direct VHDL scaffold/s,
            "$name remains outside the explicit VHDL facade arithmetic scaffold",
        );
    }
};

subtest 'facade target_language option routes direct VHDL scalar-addition scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_scalar_addition.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_scalar_addition
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 1)
    (B 1)
    (SUM 1)
  )
  (idle
    (= (SUM (+ A B)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_scalar_addition\s+is\b/s,
        'explicit VHDL facade generation emits the scalar-addition direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bSUM\s+<=\s+A\s+xor\s+B;/s,
        'explicit VHDL facade generation lowers binary scalar addition to one-bit xor semantics',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s,
        'explicit VHDL scalar-addition facade generation does not leak SystemVerilog or vector arithmetic syntax',
    );
};

subtest 'facade target_language option routes direct VHDL scalar-addition-chain scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_scalar_addition_chain.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_scalar_addition_chain
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 1)
    (B 1)
    (C 1)
    (SUM 1)
  )
  (idle
    (= (SUM (+ A B C)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_scalar_addition_chain\s+is\b/s,
        'explicit VHDL facade generation emits the scalar-addition-chain direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bSUM\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s,
        'explicit VHDL facade generation lowers scalar addition chains to one-bit xor semantics',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s,
        'explicit VHDL scalar-addition-chain facade generation does not leak SystemVerilog or vector arithmetic syntax',
    );
};

subtest 'facade target_language option routes direct VHDL scalar-subtraction scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_scalar_subtraction.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_scalar_subtraction
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 1)
    (B 1)
    (DIFF 1)
  )
  (idle
    (= (DIFF (- A B)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_scalar_subtraction\s+is\b/s,
        'explicit VHDL facade generation emits the scalar-subtraction direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bDIFF\s+<=\s+A\s+xor\s+B;/s,
        'explicit VHDL facade generation lowers binary scalar subtraction to one-bit xor semantics',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s,
        'explicit VHDL scalar-subtraction facade generation does not leak SystemVerilog or vector arithmetic syntax',
    );
};

subtest 'facade target_language option routes direct VHDL scalar-subtraction-chain scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_scalar_subtraction_chain.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_scalar_subtraction_chain
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 1)
    (B 1)
    (C 1)
    (DIFF 1)
  )
  (idle
    (= (DIFF (- A B C)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_scalar_subtraction_chain\s+is\b/s,
        'explicit VHDL facade generation emits the scalar-subtraction-chain direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bDIFF\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s,
        'explicit VHDL facade generation lowers scalar subtraction chains to one-bit xor semantics',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s,
        'explicit VHDL scalar-subtraction-chain facade generation does not leak SystemVerilog or vector arithmetic syntax',
    );
};

subtest 'facade target_language option keeps direct VHDL scalar division and modulo fail-closed' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my @cases = (
        {
            filename => 'facade_direct_vhdl_scalar_division_deferred.fsm',
            fsm_name => 'facade_direct_vhdl_scalar_division_deferred',
            output => 'QUOTIENT',
            expression => '(/ A B)',
            diagnostic => qr/arithmetic expression 'A \/ B' is outside the direct VHDL scaffold/s,
            name => 'scalar division',
        },
        {
            filename => 'facade_direct_vhdl_scalar_modulo_deferred.fsm',
            fsm_name => 'facade_direct_vhdl_scalar_modulo_deferred',
            output => 'REMAINDER',
            expression => '(% A B)',
            diagnostic => qr/arithmetic expression 'A % B' is outside the direct VHDL scaffold/s,
            name => 'scalar modulo',
        },
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    for my $case (@cases) {
        my $direct_path = File::Spec->catfile($tempdir, $case->{filename});
        my $fsm_name = $case->{fsm_name};
        my $output = $case->{output};
        my $expression = $case->{expression};
        write_file(
            $direct_path,
            <<"FSM"
(?fsm:$fsm_name
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 1)
    (B 1)
    ($output 1)
  )
  (idle
    (= ($output $expression))
  )
)
FSM
        );

        my $error = capture_exception(sub {
            $vhdl_pipeline->generate_hdl_from_file($direct_path);
        });

        like(
            $error,
            $case->{diagnostic},
            "explicit VHDL facade generation keeps $case->{name} outside the direct scaffold boundary",
        );
    }
};

subtest 'facade target_language option routes direct VHDL scalar-multiplication scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_scalar_multiplication.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_scalar_multiplication
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 1)
    (B 1)
    (PROD 1)
  )
  (idle
    (= (PROD (* A B)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_scalar_multiplication\s+is\b/s,
        'explicit VHDL facade generation emits the scalar-multiplication direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bPROD\s+<=\s+A\s+and\s+B;/s,
        'explicit VHDL facade generation lowers binary scalar multiplication to one-bit and semantics',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s,
        'explicit VHDL scalar-multiplication facade generation does not leak SystemVerilog or vector arithmetic syntax',
    );
};

subtest 'facade target_language option routes direct VHDL scalar-multiplication-chain scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_scalar_multiplication_chain.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_scalar_multiplication_chain
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 1)
    (B 1)
    (C 1)
    (PROD 1)
  )
  (idle
    (= (PROD (* A B C)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+facade_direct_vhdl_scalar_multiplication_chain\s+is\b/s,
        'explicit VHDL facade generation emits the scalar-multiplication-chain direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bPROD\s+<=\s+A\s+and\s+B\s+and\s+C;/s,
        'explicit VHDL facade generation lowers scalar multiplication chains to one-bit and semantics',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s,
        'explicit VHDL scalar-multiplication-chain facade generation does not leak SystemVerilog or vector arithmetic syntax',
    );
};

subtest 'facade target_language option routes direct VHDL addition-chain scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_addition_chain.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_addition_chain
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (D 8)
    (SUM 8)
  )
  (idle
    (= (SUM (+ A B C D)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bSUM\s+<=\s+std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(B\)\s+\+\s+unsigned\(C\)\s+\+\s+unsigned\(D\)\);/s,
        'explicit VHDL facade generation lowers same-width vector addition chains through numeric_std casts',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL addition-chain facade generation does not leak SystemVerilog module or always_* forms',
    );
};

subtest 'facade target_language option routes direct VHDL subtraction-chain scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_subtraction_chain.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_subtraction_chain
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (D 8)
    (DIFF 8)
  )
  (idle
    (= (DIFF (- A B C D)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bDIFF\s+<=\s+std_logic_vector\(unsigned\(A\)\s+-\s+unsigned\(B\)\s+-\s+unsigned\(C\)\s+-\s+unsigned\(D\)\);/s,
        'explicit VHDL facade generation lowers same-width vector subtraction chains through numeric_std casts',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL subtraction-chain facade generation does not leak SystemVerilog module or always_* forms',
    );
};

subtest 'facade target_language option routes direct VHDL multiplication-chain scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_multiplication_chain.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_multiplication_chain
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (D 8)
    (PRODUCT 8)
  )
  (idle
    (= (PRODUCT (* A B C D)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bPRODUCT\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+unsigned\(B\)\s+\*\s+unsigned\(C\)\s+\*\s+unsigned\(D\),\s+8\)\);/s,
        'explicit VHDL facade generation lowers same-width vector multiplication chains through target-width numeric_std resize',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL multiplication-chain facade generation does not leak SystemVerilog module or always_* forms',
    );
};

subtest 'facade target_language option routes direct VHDL XOR-chain scaffold behavior' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'facade_direct_vhdl_xor_chain.fsm');
    write_file(
        $direct_path,
        <<'FSM'
(?fsm:facade_direct_vhdl_xor_chain
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (X 1)
    (Y 1)
    (Z 1)
    (MASK 1)
  )
  (idle
    (= (MASK (^ X Y Z)))
  )
)
FSM
    );

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bintermediate_xor_X_Y_Z_1\s+<=\s+X\s+xor\s+Y\s+xor\s+Z;/s,
        'explicit VHDL facade generation lowers same-width scalar XOR chains to VHDL xor',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL XOR-chain facade generation does not leak SystemVerilog module or always_* forms',
    );
};

subtest 'facade target_language option routes direct VHDL division/modulo scaffold behavior' => sub {
    my $direct_path = repo_file('t/corpus/direct_runtime_div_mod.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bQUO_CHAIN\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(B\)\s+\/\s+unsigned\(C\),\s+8\)\);/s,
        'explicit VHDL facade generation lowers same-width division chains through target-width numeric_std resize',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bREM_CHAIN\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(B\)\s+mod\s+unsigned\(C\),\s+8\)\);/s,
        'explicit VHDL facade generation lowers same-width modulo chains through target-width numeric_std resize',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|\balways_(?:ff|comb)\b|\s%\s/s,
        'explicit VHDL division/modulo facade generation does not leak SystemVerilog module, always_*, or percent-modulo forms',
    );
};

subtest 'facade target_language option routes direct VHDL generic-bearing scaffold behavior' => sub {
    my $direct_path = repo_file('t/corpus/direct_size_expression_widths.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+direct_size_expression_widths\s+is\b/s,
        'explicit VHDL facade generation emits the generic-bearing direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bgeneric\s*\(\s+PARAM_DEC_W\s+:\s+integer\s+:=\s+\(10\s+-\s+2\);\s+PARAM_W\s+:\s+integer\s+:=\s+\(2\s+\+\s+1\)\s+\);\s+port\s*\(/s,
        'explicit VHDL facade generation lowers direct parameters to integer generics',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|#\s*\(|\bparameter\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL generic-bearing facade generation does not leak SystemVerilog module syntax',
    );
};

subtest 'facade target_language option routes direct VHDL sized-literal generic defaults' => sub {
    my $direct_path = repo_file('t/corpus/params_aggregate_comparison.fsm');
    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $vhdl_result = $vhdl_pipeline->generate_hdl_from_file($direct_path);

    like(
        $vhdl_result->{hdl_code},
        qr/\bentity\s+params_aggregate_comparison\s+is\b/s,
        'explicit VHDL facade generation emits the sized-literal generic direct entity',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bP_EQ_LIST\s+:\s+std_logic\s+:=\s+'1';/s,
        'explicit VHDL facade generation lowers one-valued parameter defaults to std_logic generics',
    );
    like(
        $vhdl_result->{hdl_code},
        qr/\bP_EQ_RECORD_FALSE\s+:\s+std_logic\s+:=\s+'0';/s,
        'explicit VHDL facade generation lowers zero-valued parameter defaults to std_logic generics',
    );
    unlike(
        $vhdl_result->{hdl_code},
        qr/\bmodule\b|#\s*\(|\bparameter\b|\b1'b[01]\b|\balways_(?:ff|comb)\b/s,
        'explicit VHDL sized-literal generic facade generation does not leak SystemVerilog parameter syntax',
    );

    my $vector_direct_path = repo_file('t/corpus/params_aggregate_unary_complement.fsm');
    my $vector_vhdl_result = $vhdl_pipeline->generate_hdl_from_file($vector_direct_path);

    like(
        $vector_vhdl_result->{hdl_code},
        qr/\bentity\s+params_aggregate_unary_complement\s+is\b/s,
        'explicit VHDL facade generation emits the vector sized-literal generic direct entity',
    );
    like(
        $vector_vhdl_result->{hdl_code},
        qr/\bP_NOT_LIST\s+:\s+std_logic_vector\(15\s+downto\s+0\)\s+:=\s+"0101101011000011";/s,
        'explicit VHDL facade generation lowers list-width defaults to std_logic_vector generics',
    );
    like(
        $vector_vhdl_result->{hdl_code},
        qr/\bP_NOT_RECORD\s+:\s+std_logic_vector\(2\s+downto\s+0\)\s+:=\s+"010"/s,
        'explicit VHDL facade generation lowers record-width defaults to std_logic_vector generics',
    );
    like(
        $vector_vhdl_result->{hdl_code},
        qr/\bOUT_LIST\s+<=\s+P_NOT_LIST;/s,
        'explicit VHDL facade generation routes vector generics into vector assignments',
    );
    unlike(
        $vector_vhdl_result->{hdl_code},
        qr/\bmodule\b|#\s*\(|\bparameter\b|\b(?:3|8|16)'[bdhBDH]|\balways_(?:ff|comb)\b/s,
        'explicit VHDL vector sized-literal generic facade generation does not leak SystemVerilog parameter syntax',
    );
};

subtest 'facade target_language option routes direct VHDL aggregate packed-vector behavior' => sub {
    my $concat_path = repo_file('t/corpus/direct_rhs_concat_target_autogrowth.fsm');
    my $constant_path = repo_file('t/corpus/direct_aggregate_constant_target_autogrowth.fsm');

    my $vhdl_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $concat_result = $vhdl_pipeline->generate_hdl_from_file($concat_path);
    like(
        $concat_result->{hdl_code},
        qr/\bentity\s+direct_rhs_concat_target_autogrowth\s+is\b/s,
        'explicit VHDL facade generation emits the aggregate concat direct entity',
    );
    like(
        $concat_result->{hdl_code},
        qr/\bNESTED\s+:\s+out\s+std_logic_vector\(6\s+downto\s+0\);/s,
        'explicit VHDL facade generation lowers nested aggregate output to packed vector',
    );
    like(
        $concat_result->{hdl_code},
        qr/\bOUT\s+<=\s+\(FLAG\s+&\s+DATA\);/s,
        'explicit VHDL facade generation lowers flat aggregate concat assignment',
    );

    my $constant_result = $vhdl_pipeline->generate_hdl_from_file($constant_path);
    like(
        $constant_result->{hdl_code},
        qr/\bentity\s+direct_aggregate_constant_target_autogrowth\s+is\b/s,
        'explicit VHDL facade generation emits the aggregate constant direct entity',
    );
    like(
        $constant_result->{hdl_code},
        qr/\bOUT_FRAME\s+:\s+out\s+std_logic_vector\(4\s+downto\s+0\);/s,
        'explicit VHDL facade generation lowers record-like aggregate output to packed vector',
    );
    like(
        $constant_result->{hdl_code},
        qr/\bOUT_LANES\s+<=\s+"10101";/s,
        'explicit VHDL facade generation lowers list-like aggregate constant assignment',
    );

    unlike(
        $concat_result->{hdl_code} . $constant_result->{hdl_code},
        qr/\btypedef\b|\bstruct\b|\bmodule\b|\balways_(?:ff|comb)\b|\brecord\b|\barray\b/s,
        'explicit VHDL aggregate facade generation stays in the packed-vector scaffold',
    );
};

done_testing();

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}

sub capture_exception {
    my ($code) = @_;
    my $error = '';
    eval { $code->(); 1 } or $error = $@ || 'unknown error';
    return $error;
}

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

sub write_apb_c4_scalar_generic_map_fixture {
    my ($repo_root, $fixture_dir, $top_path, %args) = @_;
    my $requester_value = $args{requester_value} // '8';
    my $completer_value = $args{completer_value} // '6';

    for my $module (qw(apb_requester apb_completer)) {
        my $source = read_file(File::Spec->catfile($repo_root, 'fsm', "$module.fsm"));
        $source =~ s/\(\?fsm:$module\n/(?fsm:$module\n  (+params\n    (TIMEOUT_CYCLES 4)\n  )\n/
            or die "Cannot add TIMEOUT_CYCLES to $module fixture";
        write_file(File::Spec->catfile($fixture_dir, "$module.fsm"), $source);
    }

    my $top = read_file(File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm'));
    $top =~ s/\(\?fsmc:requester apb_requester\)/(?fsmc:requester apb_requester\n    (params\n      (TIMEOUT_CYCLES $requester_value)\n    )\n  )/
        or die 'Cannot add requester TIMEOUT_CYCLES override';
    $top =~ s/\(\?fsmc:completer apb_completer\)/(?fsmc:completer apb_completer\n    (params\n      (TIMEOUT_CYCLES $completer_value)\n    )\n  )/
        or die 'Cannot add completer TIMEOUT_CYCLES override';
    write_file($top_path, $top);
}

sub write_apb_c4_one_bit_generic_map_fixture {
    my ($repo_root, $fixture_dir, $top_path) = @_;

    for my $module (qw(apb_requester apb_completer)) {
        my $source = read_file(File::Spec->catfile($repo_root, 'fsm', "$module.fsm"));
        $source =~ s/\(\?fsm:$module\n/(?fsm:$module\n  (+params\n    (ENABLE_DEFAULT 1'b0)\n  )\n/
            or die "Cannot add ENABLE_DEFAULT to $module fixture";
        write_file(File::Spec->catfile($fixture_dir, "$module.fsm"), $source);
    }

    my $top = read_file(File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm'));
    $top =~ s/\(\?fsmc:requester apb_requester\)/(?fsmc:requester apb_requester\n    (params\n      (ENABLE_DEFAULT 1'b1)\n    )\n  )/
        or die 'Cannot add requester ENABLE_DEFAULT override';
    $top =~ s/\(\?fsmc:completer apb_completer\)/(?fsmc:completer apb_completer\n    (params\n      (ENABLE_DEFAULT 1'b1)\n    )\n  )/
        or die 'Cannot add completer ENABLE_DEFAULT override';
    write_file($top_path, $top);
}

sub write_apb_c4_bitstring_generic_map_fixture {
    my ($repo_root, $fixture_dir, $top_path) = @_;

    for my $module (qw(apb_requester apb_completer)) {
        my $source = read_file(File::Spec->catfile($repo_root, 'fsm', "$module.fsm"));
        $source =~ s/\(\?fsm:$module\n/(?fsm:$module\n  (+params\n    (RESET_VALUE 8'h00)\n  )\n/
            or die "Cannot add RESET_VALUE to $module fixture";
        write_file(File::Spec->catfile($fixture_dir, "$module.fsm"), $source);
    }

    my $top = read_file(File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm'));
    $top =~ s/\(\?fsmc:requester apb_requester\)/(?fsmc:requester apb_requester\n    (params\n      (RESET_VALUE 8'hA5)\n    )\n  )/
        or die 'Cannot add requester RESET_VALUE override';
    $top =~ s/\(\?fsmc:completer apb_completer\)/(?fsmc:completer apb_completer\n    (params\n      (RESET_VALUE 8'h3C)\n    )\n  )/
        or die 'Cannot add completer RESET_VALUE override';
    write_file($top_path, $top);
}

sub write_apb_c4_aggregate_generic_map_fixture {
    my ($repo_root, $fixture_dir, $top_path) = @_;

    for my $module (qw(apb_requester apb_completer)) {
        my $source = read_file(File::Spec->catfile($repo_root, 'fsm', "$module.fsm"));
        $source =~ s/\(\?fsm:$module\n/(?fsm:$module\n  (+params\n    (LANES (8'hA5 8'h3C))\n    (FRAME ((mode 2'b00) (flag 0)))\n  )\n/
            or die "Cannot add aggregate params to $module fixture";
        write_file(File::Spec->catfile($fixture_dir, "$module.fsm"), $source);
    }

    my $top = read_file(File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm'));
    my $overrides = "    (params\n      (LANES (8'h3C 8'hA5))\n      (FRAME ((mode 2'b10) (flag 1)))\n    )\n";
    $top =~ s/\(\?fsmc:requester apb_requester\)/(?fsmc:requester apb_requester\n$overrides  )/
        or die 'Cannot add requester aggregate overrides';
    $top =~ s/\(\?fsmc:completer apb_completer\)/(?fsmc:completer apb_completer\n$overrides  )/
        or die 'Cannot add completer aggregate overrides';
    write_file($top_path, $top);
}

sub write_apb_c4_nonpacked_aggregate_generic_map_fixture {
    my ($repo_root, $fixture_dir, $top_path) = @_;

    for my $module (qw(apb_requester apb_completer)) {
        my $source = read_file(File::Spec->catfile($repo_root, 'fsm', "$module.fsm"));
        $source =~ s/\(\?fsm:$module\n/(?fsm:$module\n  (+params\n    (LANES ((+ 4 1) (+ 5 1)))\n  )\n/
            or die "Cannot add non-packed aggregate params to $module fixture";
        write_file(File::Spec->catfile($fixture_dir, "$module.fsm"), $source);
    }

    my $top = read_file(File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm'));
    my $overrides = "    (params\n      (LANES ((+ 6 1) (+ 7 1)))\n    )\n";
    $top =~ s/\(\?fsmc:requester apb_requester\)/(?fsmc:requester apb_requester\n$overrides  )/
        or die 'Cannot add requester non-packed aggregate overrides';
    $top =~ s/\(\?fsmc:completer apb_completer\)/(?fsmc:completer apb_completer\n$overrides  )/
        or die 'Cannot add completer non-packed aggregate overrides';
    write_file($top_path, $top);
}

sub write_apb_c4_package_generic_map_fixture {
    my ($repo_root, $fixture_dir, $top_path) = @_;

    for my $module (qw(apb_requester apb_completer)) {
        my $source = read_file(File::Spec->catfile($repo_root, 'fsm', "$module.fsm"));
        $source =~ s/\(\?fsm:$module\n/(?fsm:$module\n  (+params\n    (TIMEOUT_CYCLES 4)\n    (RESET_VALUE 8'h00)\n  )\n/
            or die "Cannot add package-backed params to $module fixture";
        write_file(File::Spec->catfile($fixture_dir, "$module.fsm"), $source);
    }

    my $top = read_file(File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm'));
    $top =~ s/\(\?top:apb_tb\n/(?top:apb_tb\n  (+import param_pkg)\n/
        or die 'Cannot add package import to APB fixture';
    my $overrides = "    (params\n      (TIMEOUT_CYCLES param_pkg.TIMEOUT_8)\n      (RESET_VALUE param_pkg.RESET_A5)\n    )\n";
    $top =~ s/\(\?fsmc:requester apb_requester\)/(?fsmc:requester apb_requester\n$overrides  )/
        or die 'Cannot add requester package-backed overrides';
    $top =~ s/\(\?fsmc:completer apb_completer\)/(?fsmc:completer apb_completer\n$overrides  )/
        or die 'Cannot add completer package-backed overrides';
    $top .= "\n(?pkg:param_pkg\n  (+constants\n    (TIMEOUT_8 8)\n    (RESET_A5 8'hA5)\n  )\n)\n";
    write_file($top_path, $top);
}
