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
