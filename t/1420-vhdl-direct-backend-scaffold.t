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

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'direct VHDL scaffold emits deterministic entity architecture and concat lowering' => sub {
    my $hdl = generate_vhdl('t/corpus/direct_rhs_concat_pack.fsm');

    like($hdl, qr/^-- Flattened Decision Tree FSM: direct_rhs_concat_pack/m, 'VHDL scaffold emits deterministic direct header');
    like($hdl, qr/\blibrary\s+ieee;\s+use\s+ieee\.std_logic_1164\.all;\s+use\s+ieee\.numeric_std\.all;/s, 'VHDL scaffold emits IEEE library imports');
    like($hdl, qr/\bentity\s+direct_rhs_concat_pack\s+is\b/s, 'VHDL scaffold emits entity');
    like($hdl, qr/\barchitecture\s+rtl\s+of\s+direct_rhs_concat_pack\s+is\b/s, 'VHDL scaffold emits rtl architecture');

    like($hdl, qr/\bHI\s+:\s+in\s+std_logic_vector\(3\s+downto\s+0\);/s, 'VHDL scaffold emits vector input port');
    like($hdl, qr/\bCOND\s+:\s+in\s+std_logic;/s, 'VHDL scaffold emits scalar input port');
    like($hdl, qr/\bsignal\s+OUT\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'VHDL scaffold emits vector internal signal');
    like($hdl, qr/\bsignal\s+idle_en\s+:\s+std_logic;/s, 'VHDL scaffold emits scalar enable signal');

    like($hdl, qr/\bidle_en\s+<=\s+'1'\s+when\s+current_state\s+=\s+IDLE\s+else\s+'0';/s, 'state enable equality lowers to VHDL conditional signal assignment');
    like($hdl, qr/\bidle_out_hi_mid_lo_en\s+<=\s+idle_en\s+and\s+COND;/s, 'boolean enable expression lowers to VHDL and expression');
    like($hdl, qr/\bOUT\s+<=\s+\(HI\s+&\s+MID\s+&\s+LO\);/s, 'flat concat lowers to VHDL concatenation');
    like($hdl, qr/\bOUT_NESTED\s+<=\s+\(HI\s+&\s+\(MID\s+&\s+LO\)\);/s, 'nested concat lowers to nested VHDL concatenation');

    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\b|\breg\b|\bwire\b/s, 'VHDL scaffold does not leak SystemVerilog syntax');
};

subtest 'direct VHDL scaffold preserves sync and async reset process shapes' => sub {
    my $sync_hdl = generate_vhdl('t/corpus/direct_sreset_active_high.fsm');
    like($sync_hdl, qr/\bprocess\(clk\)\s+begin\s+if\s+rising_edge\(clk\)\s+then\s+if\s+reset\s+=\s+'1'\s+then/s, 'sync-reset direct fixture emits clocked process with active-high reset branch');
    like($sync_hdl, qr/\bDONE_q\s+<=\s+'0';\s+else\s+DONE_q\s+<=\s+DONE;/s, 'sync-reset direct fixture emits reset and clock data assignments');

    my $async_hdl = generate_vhdl('t/corpus/direct_areset_active_low.fsm');
    like($async_hdl, qr/\bprocess\(clk,\s+rst_n\)\s+begin\s+if\s+rst_n\s+=\s+'0'\s+then/s, 'async-reset direct fixture emits reset-sensitive process');
    like($async_hdl, qr/\belsif\s+rising_edge\(clk\)\s+then\s+current_state\s+<=\s+next_state;/s, 'async-reset direct fixture emits clock branch after active-low reset');
};

subtest 'direct VHDL scaffold lowers delayed-pulse clock-branch nested if shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_delayed_pulse_vhdl.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_delayed_pulse_vhdl.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_delayed_pulse_vhdl
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (GO 1)
    (PULSE 1)
  )
  (idle
    (<GO
      (<1 (PULSE 1))
    )
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_delayed_pulse_vhdl\s+is\b/s, 'delayed-pulse fixture emits direct VHDL entity');
    like($hdl, qr/\bsignal\s+PULSE_pulse_delay_pipe\s+:\s+std_logic;/s, 'delayed-pulse fixture emits scalar delay pipe signal');
    like(
        $hdl,
        qr/\bPULSE\s+<=\s+'0';\s+if\s+PULSE_pulse_delay_pipe\s+=\s+'1'\s+then\s+PULSE\s+<=\s+'1';\s+end if;\s+PULSE_pulse_delay_pipe\s+<=\s+\w+;/s,
        'delayed-pulse fixture lowers the generated clock-branch nested if to VHDL sequential if syntax',
    );
    unlike($hdl, qr/\balways_(?:ff|comb)\b|\bif\s*\(/s, 'delayed-pulse VHDL output does not leak SystemVerilog block syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the delayed-pulse scaffold fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes direct delayed-pulse VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bPULSE_pulse_delay_pipe\s+<=\s+\w+;/s, 'CLI delayed-pulse VHDL output shifts the delay pipe');
    unlike($cli_hdl, qr/\balways_(?:ff|comb)\b|\bif\s*\(/s, 'CLI delayed-pulse VHDL output remains VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers same-width vector addition RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $output_path = File::Spec->catfile($tempdir, 'direct_assignment_pair_form.vhd');

    my $hdl = generate_vhdl('t/corpus/direct_assignment_pair_form.fsm');
    like($hdl, qr/\bentity\s+direct_assignment_pair_form\s+is\b/s, 'addition fixture emits direct VHDL entity');
    like(
        $hdl,
        qr/\bSUM\s+<=\s+std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(B\)\);/s,
        'same-width vector addition lowers through numeric_std unsigned casts',
    );
    like(
        $hdl,
        qr/\bPULSE\s+<=\s+'0';\s+if\s+PULSE_pulse_delay_pipe\s+=\s+'1'\s+then\s+PULSE\s+<=\s+'1';\s+end if;/s,
        'addition fixture still lowers delayed-pulse sequential if syntax',
    );
    unlike($hdl, qr/\balways_(?:ff|comb)\b|\bif\s*\(/s, 'addition fixture VHDL output does not leak SystemVerilog block syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, repo_file('t/corpus/direct_assignment_pair_form.fsm')],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the same-width vector addition fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes direct addition VHDL output file');

    my $cli_hdl = read_file($output_path);
    like(
        $cli_hdl,
        qr/\bSUM\s+<=\s+std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(B\)\);/s,
        'CLI addition VHDL output uses numeric_std unsigned casts',
    );
    unlike($cli_hdl, qr/\balways_(?:ff|comb)\b|\bmodule\b/s, 'CLI addition VHDL output remains VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers same-width vector addition RHS chains' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_addition_chain.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_addition_chain.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_addition_chain
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

    my $hdl = generate_vhdl($fsm_path);
    like(
        $hdl,
        qr/\bSUM\s+<=\s+std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(B\)\s+\+\s+unsigned\(C\)\s+\+\s+unsigned\(D\)\);/s,
        'same-width vector addition chains lower through numeric_std unsigned casts',
    );
    unlike($hdl, qr/\balways_(?:ff|comb)\b|\bmodule\b/s, 'addition-chain VHDL output remains VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the same-width vector addition-chain fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes direct addition-chain VHDL output file');

    my $cli_hdl = read_file($output_path);
    like(
        $cli_hdl,
        qr/\bSUM\s+<=\s+std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(B\)\s+\+\s+unsigned\(C\)\s+\+\s+unsigned\(D\)\);/s,
        'CLI addition-chain VHDL output uses numeric_std unsigned casts',
    );
};

subtest 'direct VHDL scaffold lowers same-width vector subtraction RHS chains' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_subtraction_chain.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_subtraction_chain.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_subtraction_chain
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

    my $hdl = generate_vhdl($fsm_path);
    like(
        $hdl,
        qr/\bDIFF\s+<=\s+std_logic_vector\(unsigned\(A\)\s+-\s+unsigned\(B\)\s+-\s+unsigned\(C\)\s+-\s+unsigned\(D\)\);/s,
        'same-width vector subtraction chains lower through numeric_std unsigned casts',
    );
    unlike($hdl, qr/\balways_(?:ff|comb)\b|\bmodule\b/s, 'subtraction-chain VHDL output remains VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the same-width vector subtraction-chain fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes direct subtraction-chain VHDL output file');

    my $cli_hdl = read_file($output_path);
    like(
        $cli_hdl,
        qr/\bDIFF\s+<=\s+std_logic_vector\(unsigned\(A\)\s+-\s+unsigned\(B\)\s+-\s+unsigned\(C\)\s+-\s+unsigned\(D\)\);/s,
        'CLI subtraction-chain VHDL output uses numeric_std unsigned casts',
    );
};

subtest 'direct VHDL scaffold lowers same-width vector multiplication RHS chains' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_multiplication_chain.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_multiplication_chain.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_multiplication_chain
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

    my $hdl = generate_vhdl($fsm_path);
    like(
        $hdl,
        qr/\bPRODUCT\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+unsigned\(B\)\s+\*\s+unsigned\(C\)\s+\*\s+unsigned\(D\),\s+8\)\);/s,
        'same-width vector multiplication chains lower through target-width numeric_std resize',
    );
    unlike($hdl, qr/\balways_(?:ff|comb)\b|\bmodule\b/s, 'multiplication-chain VHDL output remains VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the same-width vector multiplication-chain fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes direct multiplication-chain VHDL output file');

    my $cli_hdl = read_file($output_path);
    like(
        $cli_hdl,
        qr/\bPRODUCT\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+unsigned\(B\)\s+\*\s+unsigned\(C\)\s+\*\s+unsigned\(D\),\s+8\)\);/s,
        'CLI multiplication-chain VHDL output uses target-width numeric_std resize',
    );
};

subtest 'direct VHDL scaffold lowers same-width bitwise XOR RHS chains' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $scalar_fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_xor_chain.fsm');
    my $vector_fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_xor_chain.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_xor_chain.vhd');
    write_file(
        $scalar_fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_xor_chain
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
    write_file(
        $vector_fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_xor_chain
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (MASK 8)
  )
  (idle
    (= (MASK (^ A B C)))
  )
)
FSM
    );

    my $scalar_hdl = generate_vhdl($scalar_fsm_path);
    like(
        $scalar_hdl,
        qr/\bintermediate_xor_X_Y_Z_1\s+<=\s+X\s+xor\s+Y\s+xor\s+Z;/s,
        'same-width scalar bitwise XOR chains lower to VHDL xor',
    );
    like(
        $scalar_hdl,
        qr/\bMASK\s+<=\s+intermediate_xor_X_Y_Z_1;/s,
        'same-width scalar bitwise XOR result drives the VHDL mux assignment',
    );
    unlike($scalar_hdl, qr/\balways_(?:ff|comb)\b|\bmodule\b/s, 'scalar XOR-chain VHDL output remains VHDL-shaped');

    my $vector_hdl = generate_vhdl($vector_fsm_path);
    like(
        $vector_hdl,
        qr/\bintermediate_xor_A_B_C_1\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s,
        'same-width vector bitwise XOR chains lower to VHDL xor',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $scalar_fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the same-width scalar XOR-chain fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes direct scalar XOR-chain VHDL output file');

    my $cli_hdl = read_file($output_path);
    like(
        $cli_hdl,
        qr/\bintermediate_xor_X_Y_Z_1\s+<=\s+X\s+xor\s+Y\s+xor\s+Z;/s,
        'CLI scalar XOR-chain VHDL output uses VHDL xor',
    );
};

subtest 'direct VHDL scaffold lowers same-width vector division/modulo RHS chains' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $output_path = File::Spec->catfile($tempdir, 'direct_runtime_div_mod.vhd');

    my $hdl = generate_vhdl('t/corpus/direct_runtime_div_mod.fsm');
    like(
        $hdl,
        qr/\bQUO\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(B\),\s+8\)\);/s,
        'same-width vector division lowers through target-width numeric_std resize',
    );
    like(
        $hdl,
        qr/\bREM\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(B\),\s+8\)\);/s,
        'same-width vector modulo lowers through target-width numeric_std resize',
    );
    like(
        $hdl,
        qr/\bQUO_ALIAS\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(B\),\s+8\)\);/s,
        'division aliases lower to the same VHDL division expression',
    );
    like(
        $hdl,
        qr/\bREM_ALIAS\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(B\),\s+8\)\);/s,
        'modulo aliases lower to the same VHDL mod expression',
    );
    like(
        $hdl,
        qr/\bQUO_CHAIN\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(B\)\s+\/\s+unsigned\(C\),\s+8\)\);/s,
        'same-width vector division chains lower through target-width numeric_std resize',
    );
    like(
        $hdl,
        qr/\bREM_CHAIN\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(B\)\s+mod\s+unsigned\(C\),\s+8\)\);/s,
        'same-width vector modulo chains lower through target-width numeric_std resize',
    );
    unlike($hdl, qr/\balways_(?:ff|comb)\b|\bmodule\b|\s%\s/s, 'division/modulo VHDL output remains VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, repo_file('t/corpus/direct_runtime_div_mod.fsm')],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the same-width vector division/modulo fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes direct division/modulo VHDL output file');

    my $cli_hdl = read_file($output_path);
    like(
        $cli_hdl,
        qr/\bQUO_CHAIN\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(B\)\s+\/\s+unsigned\(C\),\s+8\)\);/s,
        'CLI division/modulo VHDL output includes division-chain lowering',
    );
    like(
        $cli_hdl,
        qr/\bREM_CHAIN\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(B\)\s+mod\s+unsigned\(C\),\s+8\)\);/s,
        'CLI division/modulo VHDL output includes modulo-chain lowering',
    );
};

subtest 'direct VHDL scaffold lowers generated parameterized direct headers to generics' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $output_path = File::Spec->catfile($tempdir, 'direct_size_expression_widths.vhd');

    my $hdl = generate_vhdl('t/corpus/direct_size_expression_widths.fsm');
    like($hdl, qr/\bentity\s+direct_size_expression_widths\s+is\b/s, 'generic-bearing fixture emits direct VHDL entity');
    like(
        $hdl,
        qr/\bgeneric\s*\(\s+PARAM_DEC_W\s+:\s+integer\s+:=\s+\(10\s+-\s+2\);\s+PARAM_W\s+:\s+integer\s+:=\s+\(2\s+\+\s+1\)\s+\);\s+port\s*\(/s,
        'generated SV parameter block lowers to a VHDL integer generic block before ports',
    );
    like($hdl, qr/\bclk\s+:\s+in\s+std_logic;\s+reset\s+:\s+in\s+std_logic\b/s, 'generic-bearing fixture keeps direct clock/reset ports');
    like($hdl, qr/\bsignal\s+A\s+:\s+std_logic_vector\(2\s+downto\s+0\);/s, 'resolved symbolic width A lowers to concrete VHDL range');
    like($hdl, qr/\bsignal\s+B\s+:\s+std_logic_vector\(3\s+downto\s+0\);/s, 'resolved parameter-plus-enum width B lowers to concrete VHDL range');
    like($hdl, qr/\bsignal\s+C\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'resolved aggregate-index width C lowers to concrete VHDL range');
    like($hdl, qr/\bsignal\s+H\s+:\s+std_logic_vector\(8\s+downto\s+0\);/s, 'resolved unsized-hex width H lowers to concrete VHDL range');
    like($hdl, qr/\bH\s+<=\s+"100000001";/s, 'wide hex literal assignment lowers to exact VHDL bit string');
    unlike($hdl, qr/\bmodule\b|#\s*\(|\bparameter\b|\balways_(?:ff|comb)\b/s, 'generic-bearing VHDL output does not leak SystemVerilog module syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, repo_file('t/corpus/direct_size_expression_widths.fsm')],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the generic-bearing direct fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes generic-bearing direct VHDL output file');

    my $cli_hdl = read_file($output_path);
    like(
        $cli_hdl,
        qr/\bgeneric\s*\(\s+PARAM_DEC_W\s+:\s+integer\s+:=\s+\(10\s+-\s+2\);\s+PARAM_W\s+:\s+integer\s+:=\s+\(2\s+\+\s+1\)\s+\);/s,
        'CLI generic-bearing VHDL output includes the integer generic block',
    );
    unlike($cli_hdl, qr/\bmodule\b|#\s*\(|\bparameter\b|\balways_(?:ff|comb)\b/s, 'CLI generic-bearing VHDL output remains VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers generated sized-literal parameter defaults to typed generics' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $output_path = File::Spec->catfile($tempdir, 'params_aggregate_comparison.vhd');

    my $hdl = generate_vhdl('t/corpus/params_aggregate_comparison.fsm');
    like($hdl, qr/\bentity\s+params_aggregate_comparison\s+is\b/s, 'sized-literal generic fixture emits direct VHDL entity');
    like(
        $hdl,
        qr/\bgeneric\s*\(\s+P_EQ_LIST\s+:\s+std_logic\s+:=\s+'1';\s+P_EQ_RECORD\s+:\s+std_logic\s+:=\s+'1';\s+P_EQ_RECORD_FALSE\s+:\s+std_logic\s+:=\s+'0';\s+P_NE_LIST\s+:\s+std_logic\s+:=\s+'1';\s+P_NE_LIST_FALSE\s+:\s+std_logic\s+:=\s+'0';\s+P_NE_RECORD\s+:\s+std_logic\s+:=\s+'1'\s+\);/s,
        'generated one-bit literal parameter defaults lower to std_logic generics',
    );
    like($hdl, qr/\bOUT_EQ_LIST\s+<=\s+P_EQ_LIST;/s, 'std_logic generic drives scalar VHDL assignment without integer conversion');
    unlike($hdl, qr/\bmodule\b|#\s*\(|\bparameter\b|\b1'b[01]\b|\balways_(?:ff|comb)\b/s, 'sized-literal generic VHDL output does not leak SystemVerilog parameter syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, repo_file('t/corpus/params_aggregate_comparison.fsm')],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for sized-literal generic defaults')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes sized-literal generic VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bP_NE_LIST_FALSE\s+:\s+std_logic\s+:=\s+'0';/s, 'CLI sized-literal generic VHDL output includes zero-valued std_logic default');
    unlike($cli_hdl, qr/\bmodule\b|#\s*\(|\bparameter\b|\b1'b[01]\b|\balways_(?:ff|comb)\b/s, 'CLI sized-literal generic VHDL output remains VHDL-shaped');

    my $vector_output_path = File::Spec->catfile($tempdir, 'params_aggregate_unary_complement.vhd');
    my $vector_hdl = generate_vhdl('t/corpus/params_aggregate_unary_complement.fsm');
    like($vector_hdl, qr/\bentity\s+params_aggregate_unary_complement\s+is\b/s, 'vector generic fixture emits direct VHDL entity');
    like(
        $vector_hdl,
        qr/\bgeneric\s*\(\s+P_NOT_LIST\s+:\s+std_logic_vector\(15\s+downto\s+0\)\s+:=\s+"0101101011000011";\s+P_NOT_RECORD\s+:\s+std_logic_vector\(2\s+downto\s+0\)\s+:=\s+"010"\s+\);/s,
        'generated multi-bit literal parameter defaults lower to std_logic_vector generics',
    );
    like($vector_hdl, qr/\bOUT_LIST\s+<=\s+P_NOT_LIST;/s, 'std_logic_vector generic drives the list-width VHDL assignment');
    like($vector_hdl, qr/\bOUT_RECORD\s+<=\s+P_NOT_RECORD;/s, 'std_logic_vector generic drives the record-width VHDL assignment');
    unlike($vector_hdl, qr/\bmodule\b|#\s*\(|\bparameter\b|\b(?:3|8|16)'[bdhBDH]|\balways_(?:ff|comb)\b/s, 'vector sized-literal generic VHDL output does not leak SystemVerilog parameter syntax');

    my ($vector_success, $vector_error_message, $vector_full_buf, $vector_stdout_buf, $vector_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $vector_output_path, repo_file('t/corpus/params_aggregate_unary_complement.fsm')],
    );

    my $vector_combined_output = join('', @{ $vector_stdout_buf || [] }, @{ $vector_stderr_buf || [] }, ($vector_error_message || ''));
    ok($vector_success, 'CLI accepts direct --language vhdl for vector sized-literal generic defaults')
        or diag($vector_combined_output);
    ok(-e $vector_output_path, 'CLI writes vector sized-literal generic VHDL output file');

    my $vector_cli_hdl = read_file($vector_output_path);
    like($vector_cli_hdl, qr/\bP_NOT_LIST\s+:\s+std_logic_vector\(15\s+downto\s+0\)\s+:=\s+"0101101011000011";/s, 'CLI vector sized-literal generic VHDL output includes the list-width default');
    like($vector_cli_hdl, qr/\bP_NOT_RECORD\s+:\s+std_logic_vector\(2\s+downto\s+0\)\s+:=\s+"010"/s, 'CLI vector sized-literal generic VHDL output includes the record-width default');
    unlike($vector_cli_hdl, qr/\bmodule\b|#\s*\(|\bparameter\b|\b(?:3|8|16)'[bdhBDH]|\balways_(?:ff|comb)\b/s, 'CLI vector sized-literal generic VHDL output remains VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers binary scalar addition RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_addition.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_addition.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_addition
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_scalar_addition\s+is\b/s, 'scalar-addition fixture emits direct VHDL entity');
    like($hdl, qr/\bA\s+:\s+in\s+std_logic;\s+B\s+:\s+in\s+std_logic\b/s, 'scalar-addition fixture keeps scalar input ports');
    like(
        $hdl,
        qr/\bSUM\s+<=\s+A\s+xor\s+B;/s,
        'binary scalar addition lowers to one-bit truncated VHDL xor semantics',
    );
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'scalar-addition VHDL output remains scalar and VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the binary scalar-addition fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes binary scalar-addition VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bSUM\s+<=\s+A\s+xor\s+B;/s, 'CLI scalar-addition VHDL output uses one-bit xor lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'CLI scalar-addition VHDL output remains scalar and VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers scalar addition RHS chains' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_addition_chain.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_addition_chain.vhd');
    my $scalar_subtraction_chain_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_subtraction_chain_deferred.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_addition_chain
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
    write_file(
        $scalar_subtraction_chain_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_subtraction_chain_deferred
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_scalar_addition_chain\s+is\b/s, 'scalar-addition-chain fixture emits direct VHDL entity');
    like(
        $hdl,
        qr/\bSUM\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s,
        'scalar addition chains lower to one-bit truncated VHDL xor semantics',
    );
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'scalar-addition-chain VHDL output remains scalar and VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the scalar-addition-chain fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes scalar-addition-chain VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bSUM\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s, 'CLI scalar-addition-chain VHDL output uses one-bit xor-chain lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'CLI scalar-addition-chain VHDL output remains scalar and VHDL-shaped');

    my $scalar_subtraction_chain_error = capture_exception(sub {
        generate_vhdl($scalar_subtraction_chain_path);
    });
    like(
        $scalar_subtraction_chain_error,
        qr/arithmetic expression 'A - B - C' is outside the direct VHDL scaffold/s,
        'scalar subtraction chains remain outside the direct VHDL scaffold boundary',
    );
};

subtest 'direct VHDL scaffold lowers binary scalar subtraction RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_subtraction.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_subtraction.vhd');
    my $scalar_division_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_division_deferred.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_subtraction
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
    write_file(
        $scalar_division_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_division_deferred
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 1)
    (B 1)
    (QUOTIENT 1)
  )
  (idle
    (= (QUOTIENT (/ A B)))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_scalar_subtraction\s+is\b/s, 'scalar-subtraction fixture emits direct VHDL entity');
    like(
        $hdl,
        qr/\bDIFF\s+<=\s+A\s+xor\s+B;/s,
        'binary scalar subtraction lowers to one-bit truncated VHDL xor semantics',
    );
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'scalar-subtraction VHDL output remains scalar and VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the binary scalar-subtraction fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes binary scalar-subtraction VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bDIFF\s+<=\s+A\s+xor\s+B;/s, 'CLI scalar-subtraction VHDL output uses one-bit xor lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'CLI scalar-subtraction VHDL output remains scalar and VHDL-shaped');

    my $scalar_division_error = capture_exception(sub {
        generate_vhdl($scalar_division_path);
    });
    like(
        $scalar_division_error,
        qr/arithmetic expression 'A \/ B' is outside the direct VHDL scaffold/s,
        'scalar division remains outside the direct VHDL scaffold boundary',
    );
};

subtest 'direct VHDL scaffold lowers binary scalar multiplication RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_multiplication.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_multiplication.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_multiplication
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_scalar_multiplication\s+is\b/s, 'scalar-multiplication fixture emits direct VHDL entity');
    like(
        $hdl,
        qr/\bPROD\s+<=\s+A\s+and\s+B;/s,
        'binary scalar multiplication lowers to one-bit VHDL and semantics',
    );
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'scalar-multiplication VHDL output remains scalar and VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the binary scalar-multiplication fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes binary scalar-multiplication VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bPROD\s+<=\s+A\s+and\s+B;/s, 'CLI scalar-multiplication VHDL output uses one-bit and lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'CLI scalar-multiplication VHDL output remains scalar and VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers scalar multiplication RHS chains' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_multiplication_chain.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_multiplication_chain.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_multiplication_chain
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_scalar_multiplication_chain\s+is\b/s, 'scalar-multiplication-chain fixture emits direct VHDL entity');
    like(
        $hdl,
        qr/\bPROD\s+<=\s+A\s+and\s+B\s+and\s+C;/s,
        'scalar multiplication chains lower to one-bit VHDL and semantics',
    );
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'scalar-multiplication-chain VHDL output remains scalar and VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the scalar-multiplication-chain fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes scalar-multiplication-chain VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bPROD\s+<=\s+A\s+and\s+B\s+and\s+C;/s, 'CLI scalar-multiplication-chain VHDL output uses one-bit and-chain lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'CLI scalar-multiplication-chain VHDL output remains scalar and VHDL-shaped');
};

subtest 'direct VHDL scaffold keeps mismatched-width arithmetic expression parity fail-closed' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_mismatched_division_deferred.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_mismatched_division_deferred
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 8)
    (B 4)
    (QUOTIENT 8)
  )
  (idle
    (= (QUOTIENT (/ A B)))
  )
)
FSM
    );

    my $error = capture_exception(sub {
        generate_vhdl($fsm_path);
    });

    like($error, qr/arithmetic expression 'A \/ B' is outside the direct VHDL scaffold/s, 'mismatched-width division remains outside the direct VHDL scaffold boundary');

    my $corpus_hdl = generate_vhdl('t/corpus/arithmetic_xor_operator_variants.fsm');

    like($corpus_hdl, qr/\bsum\s+<=\s+std_logic_vector\(unsigned\(a\)\s+\+\s+unsigned\(b\)\s+\+\s+unsigned\(c\)\s+\+\s+unsigned\(d\)\);/s, 'arithmetic corpus lowers the same-width addition chain');
    like($corpus_hdl, qr/\bdiff\s+<=\s+std_logic_vector\(unsigned\(a\)\s+-\s+unsigned\(b\)\s+-\s+unsigned\(c\)\s+-\s+unsigned\(d\)\);/s, 'arithmetic corpus lowers the same-width subtraction chain');
    like($corpus_hdl, qr/\bprod\s+<=\s+std_logic_vector\(resize\(unsigned\(a\)\s+\*\s+unsigned\(b\)\s+\*\s+unsigned\(c\)\s+\*\s+unsigned\(d\),\s+8\)\);/s, 'arithmetic corpus lowers the same-width multiplication chain');
    like($corpus_hdl, qr/\bintermediate_xor_x_y_z_1\s+<=\s+x\s+xor\s+y\s+xor\s+z;/s, 'arithmetic corpus lowers the same-width scalar XOR chain');
};

subtest 'CLI routes direct --language vhdl through the scaffold' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $output_path = File::Spec->catfile($tempdir, 'direct_rhs_concat_pack.vhd');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, repo_file('t/corpus/direct_rhs_concat_pack.fsm')],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the scaffold fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes direct VHDL output file');

    my $hdl = read_file($output_path);
    like($hdl, qr/\bentity\s+direct_rhs_concat_pack\s+is\b/s, 'CLI output contains direct VHDL entity');
    unlike($hdl, qr/\balways_(?:ff|comb)\b|\bmodule\b/s, 'CLI output is VHDL-shaped');
};

subtest 'direct VHDL scaffold leaves aggregate outputs fail-closed' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );

    my $error = capture_exception(sub {
        $pipeline->generate_hdl_from_file(repo_file('t/corpus/direct_rhs_concat_target_autogrowth.fsm'));
    });

    like($error, qr/Source file:\s+'.*direct_rhs_concat_target_autogrowth\.fsm'/s, 'aggregate-output VHDL failure keeps source-file context');
    like($error, qr/aggregate struct outputs are outside the direct VHDL scaffold/s, 'aggregate-output VHDL remains outside the scaffold boundary');
};

done_testing();

sub generate_vhdl {
    my ($relpath) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file(repo_file($relpath));
    return $result->{hdl_code};
}

sub repo_file {
    my ($relpath) = @_;
    return $relpath if File::Spec->file_name_is_absolute($relpath);
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path for read: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub capture_exception {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };

    return '' if $ok;
    return $@ || 'unknown error';
}
