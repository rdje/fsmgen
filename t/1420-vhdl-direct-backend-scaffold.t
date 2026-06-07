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

subtest 'direct VHDL scaffold lowers vector arithmetic with numeric literal operands' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $compound_output_path = File::Spec->catfile($tempdir, 'compound_update_variants.vhd');
    my $shorthand_output_path = File::Spec->catfile($tempdir, 'update_shorthand_variants.vhd');

    my $compound_hdl = generate_vhdl('t/corpus/compound_update_variants.fsm');
    like(
        $compound_hdl,
        qr/\bACC_next\s+<=\s+std_logic_vector\(unsigned\(SRC\)\s+\+\s+to_unsigned\(2,\s+8\)\);/s,
        'compound update register mux lowers vector plus literal through numeric_std',
    );
    like(
        $compound_hdl,
        qr/\bCOMB\s+<=\s+std_logic_vector\(unsigned\(SRC\)\s+-\s+to_unsigned\(1,\s+8\)\);/s,
        'compound update combinational mux lowers vector minus literal through numeric_std',
    );
    like(
        $compound_hdl,
        qr/\bbyte_count_next\s+<=\s+std_logic_vector\(unsigned\(byte_count\)\s+\+\s+to_unsigned\(4,\s+8\)\);/s,
        'compound update shorthand plus literal lowers through target-width to_unsigned',
    );
    unlike($compound_hdl, qr/\balways_(?:ff|comb)\b|\bmodule\b|\bSRC\s+\+\s+2\b/s, 'compound update VHDL output remains VHDL-shaped');

    my $shorthand_hdl = generate_vhdl('t/corpus/update_shorthand_variants.fsm');
    like(
        $shorthand_hdl,
        qr/\bremaining_next\s+<=\s+std_logic_vector\(unsigned\(remaining\)\s+-\s+to_unsigned\(3,\s+8\)\);/s,
        'update shorthand minus literal lowers through target-width to_unsigned',
    );
    like(
        $shorthand_hdl,
        qr/\bupdates_byte_count_byte_count_4_en\s+<=\s+updates_en\s+and\s+ENABLE;/s,
        'update shorthand VHDL keeps guarded enable lowering alongside literal arithmetic',
    );
    unlike($shorthand_hdl, qr/\balways_(?:ff|comb)\b|\bmodule\b|\bbyte_count\s+\+\s+4\b/s, 'update shorthand VHDL output remains VHDL-shaped');

    my ($compound_success, $compound_error_message, $compound_full_buf, $compound_stdout_buf, $compound_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $compound_output_path, repo_file('t/corpus/compound_update_variants.fsm')],
    );
    my $compound_combined_output = join('', @{ $compound_stdout_buf || [] }, @{ $compound_stderr_buf || [] }, ($compound_error_message || ''));
    ok($compound_success, 'CLI accepts direct --language vhdl for compound update numeric-literal arithmetic')
        or diag($compound_combined_output);
    ok(-e $compound_output_path, 'CLI writes compound update numeric-literal VHDL output file');
    my $compound_cli_hdl = read_file($compound_output_path);
    like(
        $compound_cli_hdl,
        qr/\bACC_next\s+<=\s+std_logic_vector\(unsigned\(SRC\)\s+\+\s+to_unsigned\(2,\s+8\)\);/s,
        'CLI compound update VHDL output includes plus literal lowering',
    );

    my ($shorthand_success, $shorthand_error_message, $shorthand_full_buf, $shorthand_stdout_buf, $shorthand_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $shorthand_output_path, repo_file('t/corpus/update_shorthand_variants.fsm')],
    );
    my $shorthand_combined_output = join('', @{ $shorthand_stdout_buf || [] }, @{ $shorthand_stderr_buf || [] }, ($shorthand_error_message || ''));
    ok($shorthand_success, 'CLI accepts direct --language vhdl for update shorthand numeric-literal arithmetic')
        or diag($shorthand_combined_output);
    ok(-e $shorthand_output_path, 'CLI writes update shorthand numeric-literal VHDL output file');
    my $shorthand_cli_hdl = read_file($shorthand_output_path);
    like(
        $shorthand_cli_hdl,
        qr/\bremaining_next\s+<=\s+std_logic_vector\(unsigned\(remaining\)\s+-\s+to_unsigned\(3,\s+8\)\);/s,
        'CLI update shorthand VHDL output includes minus literal lowering',
    );
};

subtest 'direct VHDL scaffold lowers non-signed vector negative numeric-literal addition RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_add.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_add.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_negative_literal_add
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (bits 8))
  )
  (+size
    (A byte_t)
    (SUM byte_t)
  )
  (idle
    (SUM = (+ A -1))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);?/s, 'vector negative literal addition fixture lowers non-signed input port A');
    like($hdl, qr/\bsignal\s+SUM\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'vector negative literal addition fixture lowers non-signed output signal');
    like($hdl, qr/\bSUM\s+<=\s+std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(to_signed\(-1,\s+8\)\)\);/s, 'non-signed vector negative literal addition lowers through unsigned two-complement literal arithmetic');
    unlike($hdl, qr/to_unsigned\(-1,\s+8\)|arithmetic expression 'A \+ -1'/s, 'non-signed vector negative literal addition avoids invalid to_unsigned and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for non-signed vector negative literal addition')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes non-signed vector negative literal addition VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bSUM\s+<=\s+std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(to_signed\(-1,\s+8\)\)\);/s, 'CLI VHDL output includes non-signed vector negative literal addition assignment');
    unlike($cli_hdl, qr/to_unsigned\(-1,\s+8\)|arithmetic expression 'A \+ -1'/s, 'CLI non-signed vector negative literal addition avoids invalid to_unsigned and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers non-signed vector negative numeric-literal subtraction RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_sub.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_sub.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_negative_literal_sub
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (bits 8))
  )
  (+size
    (A byte_t)
    (DIFF byte_t)
  )
  (idle
    (DIFF = (- A -1))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);?/s, 'vector negative literal subtraction fixture lowers non-signed input port A');
    like($hdl, qr/\bsignal\s+DIFF\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'vector negative literal subtraction fixture lowers non-signed output signal');
    like($hdl, qr/\bDIFF\s+<=\s+std_logic_vector\(unsigned\(A\)\s+-\s+unsigned\(to_signed\(-1,\s+8\)\)\);/s, 'non-signed vector negative literal subtraction lowers through unsigned two-complement literal arithmetic');
    unlike($hdl, qr/to_unsigned\(-1,\s+8\)|arithmetic expression 'A - -1'/s, 'non-signed vector negative literal subtraction avoids invalid to_unsigned and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for non-signed vector negative literal subtraction')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes non-signed vector negative literal subtraction VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bDIFF\s+<=\s+std_logic_vector\(unsigned\(A\)\s+-\s+unsigned\(to_signed\(-1,\s+8\)\)\);/s, 'CLI VHDL output includes non-signed vector negative literal subtraction assignment');
    unlike($cli_hdl, qr/to_unsigned\(-1,\s+8\)|arithmetic expression 'A - -1'/s, 'CLI non-signed vector negative literal subtraction avoids invalid to_unsigned and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers non-signed vector negative numeric-literal multiplication RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_mul.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_mul.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_negative_literal_mul
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (bits 8))
  )
  (+size
    (A byte_t)
    (PROD byte_t)
  )
  (idle
    (PROD = (* A -2))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);?/s, 'vector negative literal multiplication fixture lowers non-signed input port A');
    like($hdl, qr/\bsignal\s+PROD\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'vector negative literal multiplication fixture lowers non-signed output signal');
    like($hdl, qr/\bPROD\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+unsigned\(to_signed\(-2,\s+8\)\),\s+8\)\);/s, 'non-signed vector negative literal multiplication lowers through resized unsigned two-complement literal arithmetic');
    unlike($hdl, qr/to_unsigned\(-2,\s+8\)|arithmetic expression 'A \* -2'/s, 'non-signed vector negative literal multiplication avoids invalid to_unsigned and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for non-signed vector negative literal multiplication')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes non-signed vector negative literal multiplication VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bPROD\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+unsigned\(to_signed\(-2,\s+8\)\),\s+8\)\);/s, 'CLI VHDL output includes non-signed vector negative literal multiplication assignment');
    unlike($cli_hdl, qr/to_unsigned\(-2,\s+8\)|arithmetic expression 'A \* -2'/s, 'CLI non-signed vector negative literal multiplication avoids invalid to_unsigned and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers non-signed vector positive numeric-literal multiplication RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_positive_literal_mul.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_positive_literal_mul.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_positive_literal_mul
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (bits 8))
  )
  (+size
    (A byte_t)
    (PROD byte_t)
  )
  (idle
    (PROD = (* A 2))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);?/s, 'vector positive literal multiplication fixture lowers non-signed input port A');
    like($hdl, qr/\bsignal\s+PROD\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'vector positive literal multiplication fixture lowers non-signed output signal');
    like($hdl, qr/\bPROD\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+to_unsigned\(2,\s+8\),\s+8\)\);/s, 'non-signed vector positive literal multiplication lowers through resized to_unsigned arithmetic');
    unlike($hdl, qr/to_signed\(2,\s+8\)|arithmetic expression 'A \* 2'/s, 'non-signed vector positive literal multiplication avoids signed casts and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for non-signed vector positive literal multiplication')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes non-signed vector positive literal multiplication VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bPROD\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+to_unsigned\(2,\s+8\),\s+8\)\);/s, 'CLI VHDL output includes non-signed vector positive literal multiplication assignment');
    unlike($cli_hdl, qr/to_signed\(2,\s+8\)|arithmetic expression 'A \* 2'/s, 'CLI non-signed vector positive literal multiplication avoids signed casts and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers non-signed vector negative numeric-literal division RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_div.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_div.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_negative_literal_div
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (bits 8))
  )
  (+size
    (A byte_t)
    (QUOT byte_t)
  )
  (idle
    (QUOT = (/ A -2))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);?/s, 'vector negative literal division fixture lowers non-signed input port A');
    like($hdl, qr/\bsignal\s+QUOT\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'vector negative literal division fixture lowers non-signed output signal');
    like($hdl, qr/\bQUOT\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(to_signed\(-2,\s+8\)\),\s+8\)\);/s, 'non-signed vector negative literal division lowers through resized unsigned two-complement literal arithmetic');
    unlike($hdl, qr/to_unsigned\(-2,\s+8\)|arithmetic expression 'A \/ -2'/s, 'non-signed vector negative literal division avoids invalid to_unsigned and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for non-signed vector negative literal division')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes non-signed vector negative literal division VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bQUOT\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(to_signed\(-2,\s+8\)\),\s+8\)\);/s, 'CLI VHDL output includes non-signed vector negative literal division assignment');
    unlike($cli_hdl, qr/to_unsigned\(-2,\s+8\)|arithmetic expression 'A \/ -2'/s, 'CLI non-signed vector negative literal division avoids invalid to_unsigned and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers non-signed vector positive numeric-literal division RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_positive_literal_div.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_positive_literal_div.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_positive_literal_div
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (bits 8))
  )
  (+size
    (A byte_t)
    (QUOT byte_t)
  )
  (idle
    (QUOT = (/ A 2))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);?/s, 'vector positive literal division fixture lowers non-signed input port A');
    like($hdl, qr/\bsignal\s+QUOT\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'vector positive literal division fixture lowers non-signed output signal');
    like($hdl, qr/\bQUOT\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+to_unsigned\(2,\s+8\),\s+8\)\);/s, 'non-signed vector positive literal division lowers through resized to_unsigned arithmetic');
    unlike($hdl, qr/to_signed\(2,\s+8\)|arithmetic expression 'A \/ 2'/s, 'non-signed vector positive literal division avoids signed casts and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for non-signed vector positive literal division')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes non-signed vector positive literal division VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bQUOT\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+to_unsigned\(2,\s+8\),\s+8\)\);/s, 'CLI VHDL output includes non-signed vector positive literal division assignment');
    unlike($cli_hdl, qr/to_signed\(2,\s+8\)|arithmetic expression 'A \/ 2'/s, 'CLI non-signed vector positive literal division avoids signed casts and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers non-signed vector negative numeric-literal modulo RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_mod.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_negative_literal_mod.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_negative_literal_mod
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (bits 8))
  )
  (+size
    (A byte_t)
    (REM byte_t)
  )
  (idle
    (REM = (% A -2))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);?/s, 'vector negative literal modulo fixture lowers non-signed input port A');
    like($hdl, qr/\bsignal\s+REM\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'vector negative literal modulo fixture lowers non-signed output signal');
    like($hdl, qr/\bREM\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(to_signed\(-2,\s+8\)\),\s+8\)\);/s, 'non-signed vector negative literal modulo lowers through resized unsigned two-complement literal arithmetic');
    unlike($hdl, qr/to_unsigned\(-2,\s+8\)|arithmetic expression 'A % -2'/s, 'non-signed vector negative literal modulo avoids invalid to_unsigned and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for non-signed vector negative literal modulo')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes non-signed vector negative literal modulo VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bREM\s+<=\s+std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(to_signed\(-2,\s+8\)\),\s+8\)\);/s, 'CLI VHDL output includes non-signed vector negative literal modulo assignment');
    unlike($cli_hdl, qr/to_unsigned\(-2,\s+8\)|arithmetic expression 'A % -2'/s, 'CLI non-signed vector negative literal modulo avoids invalid to_unsigned and the prior arithmetic guard');
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

subtest 'direct VHDL scaffold lowers scalar subtraction RHS chains' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_subtraction_chain.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_subtraction_chain.vhd');
    my $scalar_modulo_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_modulo_deferred.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_subtraction_chain
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
    write_file(
        $scalar_modulo_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_modulo_deferred
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 1)
    (B 1)
    (REMAINDER 1)
  )
  (idle
    (= (REMAINDER (% A B)))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_scalar_subtraction_chain\s+is\b/s, 'scalar-subtraction-chain fixture emits direct VHDL entity');
    like(
        $hdl,
        qr/\bDIFF\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s,
        'scalar subtraction chains lower to one-bit truncated VHDL xor semantics',
    );
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'scalar-subtraction-chain VHDL output remains scalar and VHDL-shaped');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the scalar-subtraction-chain fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes scalar-subtraction-chain VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bDIFF\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s, 'CLI scalar-subtraction-chain VHDL output uses one-bit xor-chain lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bunsigned\(A\)/s, 'CLI scalar-subtraction-chain VHDL output remains scalar and VHDL-shaped');

    my $scalar_modulo_error = capture_exception(sub {
        generate_vhdl($scalar_modulo_path);
    });
    like(
        $scalar_modulo_error,
        qr/arithmetic expression 'A % B' is outside the direct VHDL scaffold/s,
        'scalar modulo remains outside the direct VHDL scaffold boundary',
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

subtest 'direct VHDL scaffold lowers scalar bit and signed vector internal declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $output_path = File::Spec->catfile($tempdir, 'declarative_bits_symbol_widths.vhd');

    my $hdl = generate_vhdl('t/corpus/declarative_bits_symbol_widths.fsm');
    like($hdl, qr/\bentity\s+declarative_bits_symbol_widths\s+is\b/s, 'declarative bits fixture emits direct VHDL entity');
    like($hdl, qr/\bsignal\s+FLAG\s+:\s+std_logic;/s, 'scalar SystemVerilog bit declaration lowers to std_logic signal');
    like($hdl, qr/\bsignal\s+NIB\s+:\s+signed\(3\s+downto\s+0\);/s, 'signed vector reg declaration lowers to numeric_std signed signal');
    like($hdl, qr/\bsignal\s+OUT\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'unsigned vector reg declaration remains std_logic_vector signal');
    like($hdl, qr/\bFLAG\s+<=\s+'0';\s+if\s+flag_1_en\s+=\s+'1'\s+then\s+FLAG\s+<=\s+'1';/s, 'scalar bit literal assignments lower to std_logic literals');
    like($hdl, qr/\bNIB\s+<=\s+"0000";\s+if\s+nib__4_h7_en\s+=\s+'1'\s+then\s+NIB\s+<=\s+"0111";/s, 'signed vector literal assignments lower to deterministic bit strings');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\breg\s+signed\b|\bbit\s+FLAG\b/s, 'declarative bits VHDL output does not leak SystemVerilog declaration syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, repo_file('t/corpus/declarative_bits_symbol_widths.fsm')],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for scalar bit and signed vector declarations')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes scalar bit and signed vector declaration VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bsignal\s+FLAG\s+:\s+std_logic;/s, 'CLI VHDL output includes scalar bit declaration lowering');
    like($cli_hdl, qr/\bsignal\s+NIB\s+:\s+signed\(3\s+downto\s+0\);/s, 'CLI VHDL output includes signed vector declaration lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\breg\s+signed\b|\bbit\s+FLAG\b/s, 'CLI declarative bits VHDL output remains VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers two-state vector bit internal declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_two_state_vector_bit.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_two_state_vector_bit.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_two_state_vector_bit
  (+system
    (clock clk)
    (sreset reset)
  )
  (+types
    (type byte_t (two_state (bits 8)))
    (type flag_t (two_state (bits 1)))
  )
  (+size
    (OUT byte_t)
    (FLAG flag_t)
  )
  (idle
    (= (OUT 8'hA5))
    (= (FLAG 1))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $hdl = $pipeline->generate_hdl_from_file($fsm_path)->{hdl_code};

    like($hdl, qr/\bentity\s+direct_vhdl_two_state_vector_bit\s+is\b/s, 'two-state vector bit fixture emits direct VHDL entity');
    like($hdl, qr/\bsignal\s+OUT\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'generated vector bit declaration lowers to std_logic_vector signal');
    like($hdl, qr/\bsignal\s+FLAG\s+:\s+std_logic;/s, 'generated scalar bit declaration still lowers to std_logic signal');
    like($hdl, qr/\bOUT\s+<=\s+"10100101";/s, 'two-state vector bit literal assignment lowers to deterministic bit string');
    like($hdl, qr/\bFLAG\s+<=\s+'1';/s, 'two-state scalar bit literal assignment remains std_logic-shaped');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bbit\s+\[7:0\]\s+OUT\b/s, 'two-state vector bit VHDL output does not leak SystemVerilog declaration syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for two-state vector bit declarations')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes two-state vector bit declaration VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bsignal\s+OUT\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'CLI VHDL output includes vector bit declaration lowering');
    like($cli_hdl, qr/\bOUT\s+<=\s+"10100101";/s, 'CLI VHDL output includes two-state vector literal lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\bbit\s+\[7:0\]\s+OUT\b/s, 'CLI two-state vector bit VHDL output remains VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers two-state bit input port declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_two_state_bit_inputs.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_two_state_bit_inputs.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_two_state_bit_inputs
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
    (FLAG_OUT flag_t)
  )
  (idle
    (<FLAG_IN
      (= (OUT BYTE_IN))
      (= (FLAG_OUT FLAG_IN))
    )
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $hdl = $pipeline->generate_hdl_from_file($fsm_path)->{hdl_code};

    like($hdl, qr/\bentity\s+direct_vhdl_two_state_bit_inputs\s+is\b/s, 'two-state bit input fixture emits direct VHDL entity');
    like($hdl, qr/\bBYTE_IN\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);/s, 'generated vector input bit declaration lowers to std_logic_vector port');
    like($hdl, qr/\bFLAG_IN\s+:\s+in\s+std_logic;?/s, 'generated scalar input bit declaration lowers to std_logic port');
    like($hdl, qr/\bsignal\s+OUT\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'assigned vector bit remains an internal std_logic_vector signal');
    like($hdl, qr/\bOUT\s+<=\s+BYTE_IN;/s, 'vector input bit assignment remains VHDL-shaped');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\binput\s+bit\b/s, 'two-state bit input VHDL output does not leak SystemVerilog port syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for two-state bit input ports')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes two-state bit input port VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bBYTE_IN\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);/s, 'CLI VHDL output includes vector input bit port lowering');
    like($cli_hdl, qr/\bFLAG_IN\s+:\s+in\s+std_logic;?/s, 'CLI VHDL output includes scalar input bit port lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\binput\s+bit\b/s, 'CLI two-state bit input VHDL output remains VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers four-state logic input port declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_four_state_logic_inputs.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_four_state_logic_inputs.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_four_state_logic_inputs
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
    (FLAG_OUT flag_t)
  )
  (idle
    (<FLAG_IN
      (= (OUT BYTE_IN))
      (= (FLAG_OUT FLAG_IN))
    )
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
    );
    my $hdl = $pipeline->generate_hdl_from_file($fsm_path)->{hdl_code};

    like($hdl, qr/\bentity\s+direct_vhdl_four_state_logic_inputs\s+is\b/s, 'four-state logic input fixture emits direct VHDL entity');
    like($hdl, qr/\bBYTE_IN\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);/s, 'generated vector input logic declaration lowers to std_logic_vector port');
    like($hdl, qr/\bFLAG_IN\s+:\s+in\s+std_logic;?/s, 'generated scalar input logic declaration lowers to std_logic port');
    like($hdl, qr/\bsignal\s+OUT\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'assigned vector logic remains an internal std_logic_vector signal');
    like($hdl, qr/\bOUT\s+<=\s+BYTE_IN;/s, 'vector input logic assignment remains VHDL-shaped');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\binput\s+logic\b/s, 'four-state logic input VHDL output does not leak SystemVerilog port syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for four-state logic input ports')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes four-state logic input port VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bBYTE_IN\s+:\s+in\s+std_logic_vector\(7\s+downto\s+0\);/s, 'CLI VHDL output includes vector input logic port lowering');
    like($cli_hdl, qr/\bFLAG_IN\s+:\s+in\s+std_logic;?/s, 'CLI VHDL output includes scalar input logic port lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\binput\s+logic\b/s, 'CLI four-state logic input VHDL output remains VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers four-state logic internal declarations' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_cfg.fsm');
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_four_state_logic.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_four_state_logic.vhd');
    my $signed_fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_logic.fsm');
    my $signed_output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_logic.vhd');
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
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_four_state_logic
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
        $signed_fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_logic
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

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
        source_search_paths => [$libdir],
    );
    my $hdl = $pipeline->generate_hdl_from_file($fsm_path)->{hdl_code};

    like($hdl, qr/\bentity\s+direct_vhdl_four_state_logic\s+is\b/s, 'four-state logic fixture emits direct VHDL entity');
    like($hdl, qr/\bsignal\s+ISYM\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'non-signed vector logic declaration lowers to std_logic_vector signal');
    like($hdl, qr/\bsignal\s+LFLAG\s+:\s+std_logic;/s, 'non-signed scalar logic declaration lowers to std_logic signal');
    like($hdl, qr/\bISYM\s+<=\s+"00000000";\s+if\s+\w+\s+=\s+'1'\s+then\s+ISYM\s+<=\s+OUT;/s, 'logic vector assignment lowering remains VHDL-shaped');
    like($hdl, qr/\bLFLAG\s+<=\s+'0';\s+if\s+\w+\s+=\s+'1'\s+then\s+LFLAG\s+<=\s+'1';/s, 'logic scalar assignment lowering uses std_logic literals');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\b/s, 'four-state logic VHDL output does not leak SystemVerilog declaration syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '--path', $libdir, '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for non-signed four-state logic declarations')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes non-signed four-state logic declaration VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bsignal\s+ISYM\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'CLI VHDL output includes vector logic declaration lowering');
    like($cli_hdl, qr/\bsignal\s+LFLAG\s+:\s+std_logic;/s, 'CLI VHDL output includes scalar logic declaration lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\b/s, 'CLI four-state logic VHDL output remains VHDL-shaped');

    my $signed_hdl = $pipeline->generate_hdl_from_file($signed_fsm_path)->{hdl_code};
    like(
        $signed_hdl,
        qr/\bIN\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s,
        'signed vector logic input port lowers to numeric_std signed port',
    );
    like(
        $signed_hdl,
        qr/\bsignal\s+OUT\s+:\s+signed\(7\s+downto\s+0\);/s,
        'signed vector logic declaration lowers to numeric_std signed signal',
    );
    like(
        $signed_hdl,
        qr/\bOUT\s+<=\s+"00000000";\s+if\s+\w+\s+=\s+'1'\s+then\s+OUT\s+<=\s+IN;/s,
        'signed vector logic input assignment lowering remains VHDL-shaped',
    );
    unlike($signed_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\s+signed\b/s, 'signed logic VHDL output does not leak SystemVerilog declaration syntax');

    my ($signed_success, $signed_error_message, $signed_full_buf, $signed_stdout_buf, $signed_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $signed_output_path, $signed_fsm_path],
    );
    my $signed_combined_output = join('', @{ $signed_stdout_buf || [] }, @{ $signed_stderr_buf || [] }, ($signed_error_message || ''));
    ok($signed_success, 'CLI accepts direct --language vhdl for signed four-state logic declarations')
        or diag($signed_combined_output);
    ok(-e $signed_output_path, 'CLI writes signed four-state logic declaration VHDL output file');

    my $signed_cli_hdl = read_file($signed_output_path);
    like(
        $signed_cli_hdl,
        qr/\bIN\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s,
        'CLI VHDL output includes signed vector input port lowering',
    );
    like(
        $signed_cli_hdl,
        qr/\bsignal\s+OUT\s+:\s+signed\(7\s+downto\s+0\);/s,
        'CLI VHDL output includes signed vector logic declaration lowering',
    );
    unlike($signed_cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\s+signed\b/s, 'CLI signed logic VHDL output remains VHDL-shaped');
};

subtest 'direct VHDL scaffold lowers signed scalar logic declaration shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_scalar_logic.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_scalar_logic.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_scalar_logic
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_signed_scalar_logic\s+is\b/s, 'signed scalar logic fixture emits direct VHDL entity');
    like($hdl, qr/\bIN\s+:\s+in\s+std_logic;?/s, 'signed scalar logic input port lowers to std_logic');
    like($hdl, qr/\bsignal\s+OUT\s+:\s+std_logic;/s, 'signed scalar logic declaration lowers to std_logic signal');
    like($hdl, qr/\bOUT\s+<=\s+'0';\s+if\s+\w+\s+=\s+'1'\s+then\s+OUT\s+<=\s+IN;/s, 'signed scalar logic assignment lowering remains VHDL-shaped');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\s+signed\b/s, 'signed scalar logic VHDL output does not leak SystemVerilog declaration syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed scalar logic declarations')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed scalar logic declaration VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bIN\s+:\s+in\s+std_logic;?/s, 'CLI VHDL output includes signed scalar input port lowering');
    like($cli_hdl, qr/\bsignal\s+OUT\s+:\s+std_logic;/s, 'CLI VHDL output includes signed scalar logic declaration lowering');
    unlike($cli_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\s+signed\b/s, 'CLI signed scalar logic VHDL output remains VHDL-shaped');

    my @signed_scalar_arithmetic_cases = (
        {
            name => 'direct_vhdl_signed_scalar_add',
            expr => '(SUM = (+ A B))',
            output => 'SUM',
            expected => qr/\bSUM\s+<=\s+A\s+xor\s+B;/s,
            cli => 1,
        },
        {
            name => 'direct_vhdl_signed_scalar_sub',
            expr => '(DIFF = (- A B))',
            output => 'DIFF',
            expected => qr/\bDIFF\s+<=\s+A\s+xor\s+B;/s,
            cli => 1,
        },
        {
            name => 'direct_vhdl_signed_scalar_mul',
            expr => '(PROD = (* A B))',
            output => 'PROD',
            expected => qr/\bPROD\s+<=\s+A\s+and\s+B;/s,
            cli => 1,
        },
        {
            name => 'direct_vhdl_signed_scalar_add_chain',
            expr => '(SUM = (+ A B C))',
            output => 'SUM',
            expected => qr/\bSUM\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s,
        },
        {
            name => 'direct_vhdl_signed_scalar_sub_chain',
            expr => '(DIFF = (- A B C))',
            output => 'DIFF',
            expected => qr/\bDIFF\s+<=\s+A\s+xor\s+B\s+xor\s+C;/s,
        },
        {
            name => 'direct_vhdl_signed_scalar_mul_chain',
            expr => '(PROD = (* A B C))',
            output => 'PROD',
            expected => qr/\bPROD\s+<=\s+A\s+and\s+B\s+and\s+C;/s,
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

        my $arithmetic_hdl = generate_vhdl($arithmetic_path);
        like($arithmetic_hdl, qr/\bentity\s+\Q$name\E\s+is\b/s, "$name emits direct VHDL entity");
        like($arithmetic_hdl, $case->{expected}, "$name lowers signed scalar arithmetic as std_logic bit-pattern logic");
        unlike(
            $arithmetic_hdl,
            qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\s+signed\b/s,
            "$name VHDL output does not leak SystemVerilog signed declarations",
        );

        next unless $case->{cli};
        my $cli_output_path = File::Spec->catfile($tempdir, "$name.vhd");
        my ($arith_success, $arith_error_message, $arith_full_buf, $arith_stdout_buf, $arith_stderr_buf) = run(
            command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $cli_output_path, $arithmetic_path],
        );
        my $arith_combined_output = join('', @{ $arith_stdout_buf || [] }, @{ $arith_stderr_buf || [] }, ($arith_error_message || ''));
        ok($arith_success, "CLI accepts direct --language vhdl for $name")
            or diag($arith_combined_output);
        ok(-e $cli_output_path, "CLI writes $name VHDL output file");
        my $arith_cli_hdl = read_file($cli_output_path);
        like($arith_cli_hdl, $case->{expected}, "CLI VHDL output lowers $name");
        unlike(
            $arith_cli_hdl,
            qr/\bmodule\b|\balways_(?:ff|comb)\b|\blogic\s+signed\b/s,
            "CLI $name VHDL output remains VHDL-shaped",
        );
    }

    my @fail_closed_arithmetic_cases = (
        {
            name => 'direct_vhdl_signed_scalar_div_deferred',
            expr => '(QUOT = (/ A B))',
            output => 'QUOT',
            b_type => 'signed_bit_t',
            diagnostic => qr/arithmetic expression 'A \/ B' is outside the direct VHDL scaffold/s,
        },
        {
            name => 'direct_vhdl_signed_scalar_mod_deferred',
            expr => '(REM = (% A B))',
            output => 'REM',
            b_type => 'signed_bit_t',
            diagnostic => qr/arithmetic expression 'A % B' is outside the direct VHDL scaffold/s,
        },
        {
            name => 'direct_vhdl_signed_scalar_mixed_add_deferred',
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
            generate_vhdl($fail_closed_path);
        });
        like($fail_closed_error, $case->{diagnostic}, "$name remains outside the direct VHDL scaffold boundary");
    }
};

subtest 'direct VHDL scaffold keeps mixed signed and unsigned vector arithmetic fail-closed' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my @cases = (
        {
            name => 'direct_vhdl_mixed_signed_unsigned_signed_target_add',
            output => 'SUM',
            output_type => 'signed_byte_t',
            expr => '(SUM = (+ A B))',
        },
        {
            name => 'direct_vhdl_mixed_signed_unsigned_unsigned_target_add',
            output => 'SUM',
            output_type => '8',
            expr => '(SUM = (+ A B))',
        },
        {
            name => 'direct_vhdl_mixed_signed_unsigned_unsigned_target_mul',
            output => 'PROD',
            output_type => '8',
            expr => '(PROD = (* A B))',
            diagnostic => qr/arithmetic expression 'A \* B' is outside the direct VHDL scaffold/s,
        },
    );

    my $cli_case_path;
    for my $case (@cases) {
        my $name = $case->{name};
        my $output = $case->{output};
        my $output_type = $case->{output_type};
        my $expr = $case->{expr};
        my $fsm_path = File::Spec->catfile($tempdir, "$name.fsm");
        my $diagnostic = $case->{diagnostic}
            || qr/arithmetic expression 'A \+ B' is outside the direct VHDL scaffold/s;
        write_file(
            $fsm_path,
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
            generate_vhdl($fsm_path);
        });
        like($error, $diagnostic, "$name remains outside the direct VHDL scaffold boundary");
        $cli_case_path = $fsm_path if $name eq 'direct_vhdl_mixed_signed_unsigned_unsigned_target_add';
    }

    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_mixed_signed_unsigned_unsigned_target_add.vhd');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $cli_case_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok(!$success, 'CLI rejects direct --language vhdl for mixed signed/unsigned vector arithmetic')
        or diag($combined_output);
    ok(!-e $output_path, 'CLI does not write mixed signed/unsigned vector arithmetic VHDL output');
    like($combined_output, qr/arithmetic expression 'A \+ B' is outside the direct VHDL scaffold/s, 'CLI reports the mixed signed/unsigned arithmetic boundary');
};

subtest 'direct VHDL scaffold lowers same-width signed vector addition RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_addition.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_addition.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_addition
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);/s, 'signed addition fixture lowers signed input port A');
    like($hdl, qr/\bB\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed addition fixture lowers signed input port B');
    like($hdl, qr/\bsignal\s+SUM\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed addition fixture lowers signed output signal');
    like($hdl, qr/\bSUM\s+<=\s+A\s+\+\s+B;/s, 'same-width signed vector addition lowers as signed VHDL arithmetic');
    unlike($hdl, qr/std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(B\)\)/s, 'signed addition does not use unsigned std_logic_vector casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector addition')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector addition VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bSUM\s+<=\s+A\s+\+\s+B;/s, 'CLI VHDL output includes signed addition assignment');
    unlike($cli_hdl, qr/std_logic_vector\(unsigned\(A\)\s+\+\s+unsigned\(B\)\)/s, 'CLI signed addition output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers same-width signed vector subtraction RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_subtraction.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_subtraction.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_subtraction
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);/s, 'signed subtraction fixture lowers signed input port A');
    like($hdl, qr/\bB\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed subtraction fixture lowers signed input port B');
    like($hdl, qr/\bsignal\s+DIFF\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed subtraction fixture lowers signed output signal');
    like($hdl, qr/\bDIFF\s+<=\s+A\s+-\s+B;/s, 'same-width signed vector subtraction lowers as signed VHDL arithmetic');
    unlike($hdl, qr/std_logic_vector\(unsigned\(A\)\s+-\s+unsigned\(B\)\)/s, 'signed subtraction does not use unsigned std_logic_vector casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector subtraction')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector subtraction VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bDIFF\s+<=\s+A\s+-\s+B;/s, 'CLI VHDL output includes signed subtraction assignment');
    unlike($cli_hdl, qr/std_logic_vector\(unsigned\(A\)\s+-\s+unsigned\(B\)\)/s, 'CLI signed subtraction output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers same-width signed vector multiplication RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_multiplication.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_multiplication.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_multiplication
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);/s, 'signed multiplication fixture lowers signed input port A');
    like($hdl, qr/\bB\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed multiplication fixture lowers signed input port B');
    like($hdl, qr/\bsignal\s+PROD\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed multiplication fixture lowers signed output signal');
    like($hdl, qr/\bPROD\s+<=\s+resize\(A\s+\*\s+B,\s+8\);/s, 'same-width signed vector multiplication lowers as resized signed VHDL arithmetic');
    unlike($hdl, qr/std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+unsigned\(B\),\s+8\)\)/s, 'signed multiplication does not use unsigned std_logic_vector casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector multiplication')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector multiplication VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bPROD\s+<=\s+resize\(A\s+\*\s+B,\s+8\);/s, 'CLI VHDL output includes signed multiplication assignment');
    unlike($cli_hdl, qr/std_logic_vector\(resize\(unsigned\(A\)\s+\*\s+unsigned\(B\),\s+8\)\)/s, 'CLI signed multiplication output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers same-width signed vector division RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_division.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_division.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_division
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);/s, 'signed division fixture lowers signed input port A');
    like($hdl, qr/\bB\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed division fixture lowers signed input port B');
    like($hdl, qr/\bsignal\s+QUOT\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed division fixture lowers signed output signal');
    like($hdl, qr/\bQUOT\s+<=\s+resize\(A\s+\/\s+B,\s+8\);/s, 'same-width signed vector division lowers as resized signed VHDL arithmetic');
    unlike($hdl, qr/std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(B\),\s+8\)\)/s, 'signed division does not use unsigned std_logic_vector casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector division')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector division VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bQUOT\s+<=\s+resize\(A\s+\/\s+B,\s+8\);/s, 'CLI VHDL output includes signed division assignment');
    unlike($cli_hdl, qr/std_logic_vector\(resize\(unsigned\(A\)\s+\/\s+unsigned\(B\),\s+8\)\)/s, 'CLI signed division output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers same-width signed vector modulo RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_modulo.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_modulo.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_modulo
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);/s, 'signed modulo fixture lowers signed input port A');
    like($hdl, qr/\bB\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed modulo fixture lowers signed input port B');
    like($hdl, qr/\bsignal\s+REM\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed modulo fixture lowers signed output signal');
    like($hdl, qr/\bREM\s+<=\s+resize\(A\s+mod\s+B,\s+8\);/s, 'same-width signed vector modulo lowers as resized signed VHDL arithmetic');
    unlike($hdl, qr/std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(B\),\s+8\)\)/s, 'signed modulo does not use unsigned std_logic_vector casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector modulo')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector modulo VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bREM\s+<=\s+resize\(A\s+mod\s+B,\s+8\);/s, 'CLI VHDL output includes signed modulo assignment');
    unlike($cli_hdl, qr/std_logic_vector\(resize\(unsigned\(A\)\s+mod\s+unsigned\(B\),\s+8\)\)/s, 'CLI signed modulo output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers signed vector numeric-literal addition RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_add.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_add.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_literal_add
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed literal addition fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+SUM\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed literal addition fixture lowers signed output signal');
    like($hdl, qr/\bSUM\s+<=\s+A\s+\+\s+to_signed\(1,\s+8\);/s, 'signed vector literal addition lowers through to_signed');
    unlike($hdl, qr/std_logic_vector\(unsigned\(A\)\s+\+\s+to_unsigned\(1,\s+8\)\)|to_unsigned\(1,\s+8\)/s, 'signed literal addition avoids unsigned casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector literal addition')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector literal addition VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bSUM\s+<=\s+A\s+\+\s+to_signed\(1,\s+8\);/s, 'CLI VHDL output includes signed literal addition assignment');
    unlike($cli_hdl, qr/std_logic_vector\(unsigned\(A\)\s+\+\s+to_unsigned\(1,\s+8\)\)|to_unsigned\(1,\s+8\)/s, 'CLI signed literal addition output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers signed vector negative numeric-literal addition RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_add.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_add.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_negative_literal_add
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed negative literal addition fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+SUM\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed negative literal addition fixture lowers signed output signal');
    like($hdl, qr/\bSUM\s+<=\s+A\s+\+\s+to_signed\(-1,\s+8\);/s, 'signed vector negative literal addition lowers through to_signed');
    unlike($hdl, qr/std_logic_vector\(unsigned\(A\)\s+\+\s+to_unsigned\(-1,\s+8\)\)|to_unsigned\(-1,\s+8\)|arithmetic expression 'A \+ -1'/s, 'signed negative literal addition avoids unsigned casts and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector negative literal addition')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector negative literal addition VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bSUM\s+<=\s+A\s+\+\s+to_signed\(-1,\s+8\);/s, 'CLI VHDL output includes signed negative literal addition assignment');
    unlike($cli_hdl, qr/std_logic_vector\(unsigned\(A\)\s+\+\s+to_unsigned\(-1,\s+8\)\)|to_unsigned\(-1,\s+8\)|arithmetic expression 'A \+ -1'/s, 'CLI signed negative literal addition output avoids unsigned casts and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers signed vector negative numeric-literal subtraction RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_sub.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_sub.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_negative_literal_sub
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
    (DIFF = (- A -1))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed negative literal subtraction fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+DIFF\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed negative literal subtraction fixture lowers signed output signal');
    like($hdl, qr/\bDIFF\s+<=\s+A\s+-\s+to_signed\(-1,\s+8\);/s, 'signed vector negative literal subtraction lowers through to_signed');
    unlike($hdl, qr/std_logic_vector\(unsigned\(A\)\s+-\s+to_unsigned\(-1,\s+8\)\)|to_unsigned\(-1,\s+8\)|arithmetic expression 'A - -1'/s, 'signed negative literal subtraction avoids unsigned casts and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector negative literal subtraction')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector negative literal subtraction VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bDIFF\s+<=\s+A\s+-\s+to_signed\(-1,\s+8\);/s, 'CLI VHDL output includes signed negative literal subtraction assignment');
    unlike($cli_hdl, qr/std_logic_vector\(unsigned\(A\)\s+-\s+to_unsigned\(-1,\s+8\)\)|to_unsigned\(-1,\s+8\)|arithmetic expression 'A - -1'/s, 'CLI signed negative literal subtraction output avoids unsigned casts and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers signed vector numeric-literal subtraction RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_sub.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_sub.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_literal_sub
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed literal subtraction fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+DIFF\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed literal subtraction fixture lowers signed output signal');
    like($hdl, qr/\bDIFF\s+<=\s+A\s+-\s+to_signed\(1,\s+8\);/s, 'signed vector literal subtraction lowers through to_signed');
    unlike($hdl, qr/std_logic_vector\(unsigned\(A\)\s+-\s+to_unsigned\(1,\s+8\)\)|to_unsigned\(1,\s+8\)/s, 'signed literal subtraction avoids unsigned casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector literal subtraction')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector literal subtraction VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bDIFF\s+<=\s+A\s+-\s+to_signed\(1,\s+8\);/s, 'CLI VHDL output includes signed literal subtraction assignment');
    unlike($cli_hdl, qr/std_logic_vector\(unsigned\(A\)\s+-\s+to_unsigned\(1,\s+8\)\)|to_unsigned\(1,\s+8\)/s, 'CLI signed literal subtraction output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers signed vector numeric-literal multiplication RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_mul.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_mul.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_literal_mul
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed literal multiplication fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+PROD\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed literal multiplication fixture lowers signed output signal');
    like($hdl, qr/\bPROD\s+<=\s+resize\(A\s+\*\s+to_signed\(2,\s+8\),\s+8\);/s, 'signed vector literal multiplication lowers through resized to_signed arithmetic');
    unlike($hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(2,\s+8\)/s, 'signed literal multiplication avoids unsigned casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector literal multiplication')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector literal multiplication VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bPROD\s+<=\s+resize\(A\s+\*\s+to_signed\(2,\s+8\),\s+8\);/s, 'CLI VHDL output includes signed literal multiplication assignment');
    unlike($cli_hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(2,\s+8\)/s, 'CLI signed literal multiplication output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers signed vector negative numeric-literal multiplication RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_mul.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_mul.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_negative_literal_mul
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
    (PROD = (* A -2))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed negative literal multiplication fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+PROD\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed negative literal multiplication fixture lowers signed output signal');
    like($hdl, qr/\bPROD\s+<=\s+resize\(A\s+\*\s+to_signed\(-2,\s+8\),\s+8\);/s, 'signed vector negative literal multiplication lowers through resized to_signed arithmetic');
    unlike($hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(-2,\s+8\)|arithmetic expression 'A \* -2'/s, 'signed negative literal multiplication avoids unsigned casts and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector negative literal multiplication')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector negative literal multiplication VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bPROD\s+<=\s+resize\(A\s+\*\s+to_signed\(-2,\s+8\),\s+8\);/s, 'CLI VHDL output includes signed negative literal multiplication assignment');
    unlike($cli_hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(-2,\s+8\)|arithmetic expression 'A \* -2'/s, 'CLI signed negative literal multiplication output avoids unsigned casts and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers signed vector numeric-literal division RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_div.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_div.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_literal_div
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed literal division fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+QUOT\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed literal division fixture lowers signed output signal');
    like($hdl, qr/\bQUOT\s+<=\s+resize\(A\s+\/\s+to_signed\(2,\s+8\),\s+8\);/s, 'signed vector literal division lowers through resized to_signed arithmetic');
    unlike($hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(2,\s+8\)/s, 'signed literal division avoids unsigned casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector literal division')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector literal division VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bQUOT\s+<=\s+resize\(A\s+\/\s+to_signed\(2,\s+8\),\s+8\);/s, 'CLI VHDL output includes signed literal division assignment');
    unlike($cli_hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(2,\s+8\)/s, 'CLI signed literal division output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers signed vector negative numeric-literal division RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_div.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_div.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_negative_literal_div
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
    (QUOT = (/ A -2))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed negative literal division fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+QUOT\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed negative literal division fixture lowers signed output signal');
    like($hdl, qr/\bQUOT\s+<=\s+resize\(A\s+\/\s+to_signed\(-2,\s+8\),\s+8\);/s, 'signed vector negative literal division lowers through resized to_signed arithmetic');
    unlike($hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(-2,\s+8\)|arithmetic expression 'A \/ -2'/s, 'signed negative literal division avoids unsigned casts and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector negative literal division')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector negative literal division VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bQUOT\s+<=\s+resize\(A\s+\/\s+to_signed\(-2,\s+8\),\s+8\);/s, 'CLI VHDL output includes signed negative literal division assignment');
    unlike($cli_hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(-2,\s+8\)|arithmetic expression 'A \/ -2'/s, 'CLI signed negative literal division output avoids unsigned casts and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers signed vector numeric-literal modulo RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_mod.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_literal_mod.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_literal_mod
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed literal modulo fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+REM\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed literal modulo fixture lowers signed output signal');
    like($hdl, qr/\bREM\s+<=\s+resize\(A\s+mod\s+to_signed\(2,\s+8\),\s+8\);/s, 'signed vector literal modulo lowers through resized to_signed arithmetic');
    unlike($hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(2,\s+8\)/s, 'signed literal modulo avoids unsigned casts');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector literal modulo')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector literal modulo VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bREM\s+<=\s+resize\(A\s+mod\s+to_signed\(2,\s+8\),\s+8\);/s, 'CLI VHDL output includes signed literal modulo assignment');
    unlike($cli_hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(2,\s+8\)/s, 'CLI signed literal modulo output avoids unsigned casts');
};

subtest 'direct VHDL scaffold lowers signed vector negative numeric-literal modulo RHS shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_mod.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_negative_literal_mod.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_negative_literal_mod
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
    (REM = (% A -2))
  )
)
FSM
    );

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bA\s+:\s+in\s+signed\(7\s+downto\s+0\);?/s, 'signed negative literal modulo fixture lowers signed input port A');
    like($hdl, qr/\bsignal\s+REM\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed negative literal modulo fixture lowers signed output signal');
    like($hdl, qr/\bREM\s+<=\s+resize\(A\s+mod\s+to_signed\(-2,\s+8\),\s+8\);/s, 'signed vector negative literal modulo lowers through resized to_signed arithmetic');
    unlike($hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(-2,\s+8\)|arithmetic expression 'A % -2'/s, 'signed negative literal modulo avoids unsigned casts and the prior arithmetic guard');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );
    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector negative literal modulo')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector negative literal modulo VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bREM\s+<=\s+resize\(A\s+mod\s+to_signed\(-2,\s+8\),\s+8\);/s, 'CLI VHDL output includes signed negative literal modulo assignment');
    unlike($cli_hdl, qr/std_logic_vector\(resize\(unsigned\(A\)|unsigned\(A\)|to_unsigned\(-2,\s+8\)|arithmetic expression 'A % -2'/s, 'CLI signed negative literal modulo output avoids unsigned casts and the prior arithmetic guard');
};

subtest 'direct VHDL scaffold lowers bounded AMBA wrap unsigned arithmetic shape' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $output_path = File::Spec->catfile($tempdir, 'amba_requester.vhd');

    my $hdl = generate_vhdl('fsm/amba_requester.fsm');

    like($hdl, qr/\bentity\s+amba_requester\s+is\b/s, 'AMBA requester fixture emits direct VHDL entity');
    like(
        $hdl,
        qr/\bwrap_span_q_next\s+<=\s+std_logic_vector\(resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\);/s,
        'AMBA wrap span lowers the bounded mixed-width product through target-width resize',
    );
    like(
        $hdl,
        qr/\bwrap_base_q_next\s+<=\s+std_logic_vector\(unsigned\(addr_q\)\s+-\s+\(unsigned\(addr_q\)\s+mod\s+resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\)\);/s,
        'AMBA wrap base lowers the bounded addr minus modulo product expression',
    );
    like(
        $hdl,
        qr/\bwrap_high_q_next\s+<=\s+std_logic_vector\(unsigned\(addr_q\)\s+-\s+\(unsigned\(addr_q\)\s+mod\s+resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\)\s+\+\s+resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\);/s,
        'AMBA wrap high lowers the bounded base plus product expression',
    );
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b|\baddr_q\s*-\s*addr_q\s*%/s, 'AMBA wrap VHDL output does not leak SystemVerilog arithmetic syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, repo_file('fsm/amba_requester.fsm')],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for the AMBA requester wrap arithmetic fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes AMBA requester VHDL output file');

    my $cli_hdl = read_file($output_path);
    like(
        $cli_hdl,
        qr/\bwrap_base_q_next\s+<=\s+std_logic_vector\(unsigned\(addr_q\)\s+-\s+\(unsigned\(addr_q\)\s+mod\s+resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\)\);/s,
        'CLI AMBA requester VHDL output includes bounded wrap-base arithmetic',
    );
    like(
        $cli_hdl,
        qr/\bwrap_high_q_next\s+<=\s+std_logic_vector\(unsigned\(addr_q\)\s+-\s+\(unsigned\(addr_q\)\s+mod\s+resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\)\s+\+\s+resize\(resize\(unsigned\(beats_total_q\),\s+32\)\s+\*\s+unsigned\(addr_step_q\),\s+32\)\);/s,
        'CLI AMBA requester VHDL output includes bounded wrap-high arithmetic',
    );
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

subtest 'direct VHDL scaffold lowers bounded aggregate outputs as packed vectors' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $concat_output_path = File::Spec->catfile($tempdir, 'direct_rhs_concat_target_autogrowth.vhd');
    my $constant_output_path = File::Spec->catfile($tempdir, 'direct_aggregate_constant_target_autogrowth.vhd');

    my $concat_hdl = generate_vhdl('t/corpus/direct_rhs_concat_target_autogrowth.fsm');
    like($concat_hdl, qr/\bentity\s+direct_rhs_concat_target_autogrowth\s+is\b/s, 'aggregate concat fixture emits direct VHDL entity');
    like($concat_hdl, qr/\bNESTED\s+:\s+out\s+std_logic_vector\(6\s+downto\s+0\);/s, 'nested aggregate output lowers to packed vector width');
    like($concat_hdl, qr/\bOUT\s+:\s+out\s+std_logic_vector\(2\s+downto\s+0\)/s, 'flat aggregate output lowers to packed vector width');
    like($concat_hdl, qr/\bNESTED\s+<=\s+\(\(FLAG\s+&\s+DATA\)\s+&\s+TAG\);/s, 'nested aggregate concat assignment lowers to VHDL concatenation');
    like($concat_hdl, qr/\bOUT\s+<=\s+\(FLAG\s+&\s+DATA\);/s, 'flat aggregate concat assignment lowers to VHDL concatenation');
    unlike($concat_hdl, qr/\btypedef\b|\bstruct\b|\bmodule\b|\balways_(?:ff|comb)\b|\brecord\b|\barray\b/s, 'aggregate concat VHDL output stays in the packed-vector scaffold');

    my $constant_hdl = generate_vhdl('t/corpus/direct_aggregate_constant_target_autogrowth.fsm');
    like($constant_hdl, qr/\bentity\s+direct_aggregate_constant_target_autogrowth\s+is\b/s, 'aggregate constant fixture emits direct VHDL entity');
    like($constant_hdl, qr/\bOUT_FRAME\s+:\s+out\s+std_logic_vector\(4\s+downto\s+0\);/s, 'record-like aggregate constant output lowers to packed vector width');
    like($constant_hdl, qr/\bOUT_LANES\s+:\s+out\s+std_logic_vector\(4\s+downto\s+0\)/s, 'list-like aggregate constant output lowers to packed vector width');
    like($constant_hdl, qr/\bOUT_FRAME\s+<=\s+"10101";/s, 'record-like aggregate constant assignment lowers to VHDL bits');
    like($constant_hdl, qr/\bOUT_LANES\s+<=\s+"10101";/s, 'list-like aggregate constant assignment lowers to VHDL bits');
    unlike($constant_hdl, qr/\btypedef\b|\bstruct\b|\bmodule\b|\balways_(?:ff|comb)\b|\brecord\b|\barray\b/s, 'aggregate constant VHDL output stays in the packed-vector scaffold');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $concat_output_path, repo_file('t/corpus/direct_rhs_concat_target_autogrowth.fsm')],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for aggregate concat packed-vector fixture')
        or diag($combined_output);
    ok(-e $concat_output_path, 'CLI writes aggregate concat VHDL output file');

    my $cli_hdl = read_file($concat_output_path);
    like($cli_hdl, qr/\bNESTED\s+:\s+out\s+std_logic_vector\(6\s+downto\s+0\);/s, 'CLI aggregate concat output includes packed nested port');
    like($cli_hdl, qr/\bOUT\s+<=\s+\(FLAG\s+&\s+DATA\);/s, 'CLI aggregate concat output includes packed assignment');
    unlike($cli_hdl, qr/\btypedef\b|\bstruct\b|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI aggregate concat VHDL output does not leak SystemVerilog syntax');

    my ($constant_success, $constant_error_message, $constant_full_buf, $constant_stdout_buf, $constant_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $constant_output_path, repo_file('t/corpus/direct_aggregate_constant_target_autogrowth.fsm')],
    );

    my $constant_combined_output = join('', @{ $constant_stdout_buf || [] }, @{ $constant_stderr_buf || [] }, ($constant_error_message || ''));
    ok($constant_success, 'CLI accepts direct --language vhdl for aggregate constant packed-vector fixture')
        or diag($constant_combined_output);
    ok(-e $constant_output_path, 'CLI writes aggregate constant VHDL output file');

    my $constant_cli_hdl = read_file($constant_output_path);
    like($constant_cli_hdl, qr/\bOUT_FRAME\s+:\s+out\s+std_logic_vector\(4\s+downto\s+0\);/s, 'CLI aggregate constant output includes packed record-like port');
    like($constant_cli_hdl, qr/\bOUT_LANES\s+<=\s+"10101";/s, 'CLI aggregate constant output includes packed bits assignment');
    unlike($constant_cli_hdl, qr/\btypedef\b|\bstruct\b|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI aggregate constant VHDL output does not leak SystemVerilog syntax');
};

subtest 'direct VHDL scaffold lowers vector output decimal literal assignments' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_output_decimal_literal.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_output_decimal_literal.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_output_decimal_literal
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_vector_output_decimal_literal\s+is\b/s, 'vector output decimal fixture emits direct VHDL entity');
    like($hdl, qr/\bOUT\s+:\s+out\s+std_logic_vector\(7\s+downto\s+0\);?/s, 'vector output decimal fixture lowers output port to std_logic_vector');
    like($hdl, qr/\bsignal\s+OUT_next\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'vector output decimal fixture declares vector next signal');
    like($hdl, qr/\bOUT_next\s+<=\s+std_logic_vector\(to_unsigned\(165,\s+8\)\);/s, 'vector output decimal literal lowers through target-width to_unsigned');
    like($hdl, qr/\bOUT\s+<=\s+"00000000";/s, 'vector output decimal fixture keeps vector reset literal');
    unlike($hdl, qr/\bOUT_next\s+<=\s+165;/s, 'vector output decimal fixture does not emit a raw integer-to-vector assignment');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b/s, 'vector output decimal VHDL output does not leak SystemVerilog structural syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for vector output decimal literal fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes vector output decimal literal VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bOUT_next\s+<=\s+std_logic_vector\(to_unsigned\(165,\s+8\)\);/s, 'CLI vector output decimal VHDL output includes typed literal assignment');
    unlike($cli_hdl, qr/\bOUT_next\s+<=\s+165;|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI vector output decimal VHDL output avoids raw integer assignment and SystemVerilog syntax');
};

subtest 'direct VHDL scaffold lowers vector output negative decimal literal assignments' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_output_negative_decimal_literal.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_vector_output_negative_decimal_literal.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_vector_output_negative_decimal_literal
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_vector_output_negative_decimal_literal\s+is\b/s, 'vector output negative decimal fixture emits direct VHDL entity');
    like($hdl, qr/\bOUT\s+:\s+out\s+std_logic_vector\(7\s+downto\s+0\);?/s, 'vector output negative decimal fixture lowers output port to std_logic_vector');
    like($hdl, qr/\bsignal\s+OUT_next\s+:\s+std_logic_vector\(7\s+downto\s+0\);/s, 'vector output negative decimal fixture declares vector next signal');
    like($hdl, qr/\bOUT_next\s+<=\s+std_logic_vector\(to_signed\(-1,\s+8\)\);/s, 'vector output negative decimal literal lowers through target-width signed conversion');
    unlike($hdl, qr/\bOUT_next\s+<=\s+-1;|to_unsigned\(-1,\s+8\)/s, 'vector output negative decimal fixture avoids raw integer assignments and unsigned casts');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b/s, 'vector output negative decimal VHDL output does not leak SystemVerilog structural syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for vector output negative decimal literal fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes vector output negative decimal literal VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bOUT_next\s+<=\s+std_logic_vector\(to_signed\(-1,\s+8\)\);/s, 'CLI vector output negative decimal VHDL output includes typed literal assignment');
    unlike($cli_hdl, qr/\bOUT_next\s+<=\s+-1;|to_unsigned\(-1,\s+8\)|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI vector output negative decimal VHDL output avoids raw integer assignment, unsigned casts, and SystemVerilog syntax');
};

subtest 'direct VHDL scaffold lowers signed vector output decimal literal assignments' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_vector_output_decimal_literal.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_vector_output_decimal_literal.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_vector_output_decimal_literal
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_signed_vector_output_decimal_literal\s+is\b/s, 'signed vector output decimal fixture emits direct VHDL entity');
    like($hdl, qr/\bOUT\s+:\s+out\s+signed\(7\s+downto\s+0\);?/s, 'signed vector output decimal fixture lowers output port to signed');
    like($hdl, qr/\bsignal\s+OUT_next\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed vector output decimal fixture declares signed next signal');
    like($hdl, qr/\bOUT_next\s+<=\s+to_signed\(5,\s+8\);/s, 'signed vector output decimal literal lowers through target-width to_signed');
    unlike($hdl, qr/\bOUT_next\s+<=\s+5;|to_unsigned\(5,\s+8\)/s, 'signed vector output decimal fixture avoids raw integer assignments and unsigned casts');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b/s, 'signed vector output decimal VHDL output does not leak SystemVerilog structural syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector output decimal literal fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector output decimal literal VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bOUT_next\s+<=\s+to_signed\(5,\s+8\);/s, 'CLI signed vector output decimal VHDL output includes typed literal assignment');
    unlike($cli_hdl, qr/\bOUT_next\s+<=\s+5;|to_unsigned\(5,\s+8\)|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI signed vector output decimal VHDL output avoids raw integer assignment, unsigned casts, and SystemVerilog syntax');
};

subtest 'direct VHDL scaffold lowers signed vector output negative decimal literal assignments' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_vector_output_negative_decimal_literal.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_vector_output_negative_decimal_literal.vhd');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_vector_output_negative_decimal_literal
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

    my $hdl = generate_vhdl($fsm_path);
    like($hdl, qr/\bentity\s+direct_vhdl_signed_vector_output_negative_decimal_literal\s+is\b/s, 'signed vector output negative decimal fixture emits direct VHDL entity');
    like($hdl, qr/\bOUT\s+:\s+out\s+signed\(7\s+downto\s+0\);?/s, 'signed vector output negative decimal fixture lowers output port to signed');
    like($hdl, qr/\bsignal\s+OUT_next\s+:\s+signed\(7\s+downto\s+0\);/s, 'signed vector output negative decimal fixture declares signed next signal');
    like($hdl, qr/\bOUT_next\s+<=\s+to_signed\(-1,\s+8\);/s, 'signed vector output negative decimal literal lowers through target-width to_signed');
    unlike($hdl, qr/\bOUT_next\s+<=\s+-1;|to_unsigned\(-1,\s+8\)/s, 'signed vector output negative decimal fixture avoids raw integer assignments and unsigned casts');
    unlike($hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b/s, 'signed vector output negative decimal VHDL output does not leak SystemVerilog structural syntax');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $fsm_path],
    );

    my $combined_output = join('', @{ $stdout_buf || [] }, @{ $stderr_buf || [] }, ($error_message || ''));
    ok($success, 'CLI accepts direct --language vhdl for signed vector output negative decimal literal fixture')
        or diag($combined_output);
    ok(-e $output_path, 'CLI writes signed vector output negative decimal literal VHDL output file');

    my $cli_hdl = read_file($output_path);
    like($cli_hdl, qr/\bOUT_next\s+<=\s+to_signed\(-1,\s+8\);/s, 'CLI signed vector output negative decimal VHDL output includes typed literal assignment');
    unlike($cli_hdl, qr/\bOUT_next\s+<=\s+-1;|to_unsigned\(-1,\s+8\)|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI signed vector output negative decimal VHDL output avoids raw integer assignment, unsigned casts, and SystemVerilog syntax');
};

subtest 'direct VHDL scaffold lowers scalar output decimal literal assignments' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $scalar_fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_output_decimal_literal.fsm');
    my $scalar_output_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_output_decimal_literal.vhd');
    my $signed_scalar_fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_scalar_output_decimal_literal.fsm');
    my $signed_scalar_output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_scalar_output_decimal_literal.vhd');

    write_file(
        $scalar_fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_output_decimal_literal
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
        $signed_scalar_fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_scalar_output_decimal_literal
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

    my $scalar_hdl = generate_vhdl($scalar_fsm_path);
    like($scalar_hdl, qr/\bentity\s+direct_vhdl_scalar_output_decimal_literal\s+is\b/s, 'scalar output decimal fixture emits direct VHDL entity');
    like($scalar_hdl, qr/\bFLAG\s+:\s+out\s+std_logic;?/s, 'scalar output decimal fixture lowers output port to std_logic');
    like($scalar_hdl, qr/\bsignal\s+FLAG_next\s+:\s+std_logic;/s, 'scalar output decimal fixture declares scalar next signal');
    like($scalar_hdl, qr/\bFLAG_next\s+<=\s+'0';/s, 'even scalar output decimal literal lowers to std_logic zero');
    unlike($scalar_hdl, qr/\bFLAG_next\s+<=\s+2;|to_unsigned\(2,\s+1\)|to_signed\(2,\s+1\)/s, 'scalar output decimal fixture avoids raw integer assignments and vector casts');
    unlike($scalar_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b/s, 'scalar output decimal VHDL output does not leak SystemVerilog structural syntax');

    my $signed_scalar_hdl = generate_vhdl($signed_scalar_fsm_path);
    like($signed_scalar_hdl, qr/\bentity\s+direct_vhdl_signed_scalar_output_decimal_literal\s+is\b/s, 'signed scalar output decimal fixture emits direct VHDL entity');
    like($signed_scalar_hdl, qr/\bFLAG\s+:\s+out\s+std_logic;?/s, 'signed scalar output decimal fixture lowers one-bit signed output port to std_logic');
    like($signed_scalar_hdl, qr/\bsignal\s+FLAG_next\s+:\s+std_logic;/s, 'signed scalar output decimal fixture declares scalar next signal');
    like($signed_scalar_hdl, qr/\bFLAG_next\s+<=\s+'1';/s, 'odd signed scalar output decimal literal lowers to std_logic one');
    unlike($signed_scalar_hdl, qr/\bFLAG_next\s+<=\s+3;|to_unsigned\(3,\s+1\)|to_signed\(3,\s+1\)/s, 'signed scalar output decimal fixture avoids raw integer assignments and vector casts');
    unlike($signed_scalar_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b/s, 'signed scalar output decimal VHDL output does not leak SystemVerilog structural syntax');

    my ($scalar_success, $scalar_error_message, $scalar_full_buf, $scalar_stdout_buf, $scalar_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $scalar_output_path, $scalar_fsm_path],
    );

    my $scalar_combined_output = join('', @{ $scalar_stdout_buf || [] }, @{ $scalar_stderr_buf || [] }, ($scalar_error_message || ''));
    ok($scalar_success, 'CLI accepts direct --language vhdl for scalar output decimal literal fixture')
        or diag($scalar_combined_output);
    ok(-e $scalar_output_path, 'CLI writes scalar output decimal literal VHDL output file');

    my $scalar_cli_hdl = read_file($scalar_output_path);
    like($scalar_cli_hdl, qr/\bFLAG_next\s+<=\s+'0';/s, 'CLI scalar output decimal VHDL output includes std_logic low-bit assignment');
    unlike($scalar_cli_hdl, qr/\bFLAG_next\s+<=\s+2;|to_unsigned\(2,\s+1\)|to_signed\(2,\s+1\)|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI scalar output decimal VHDL output avoids raw integer assignment, vector casts, and SystemVerilog syntax');

    my ($signed_success, $signed_error_message, $signed_full_buf, $signed_stdout_buf, $signed_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $signed_scalar_output_path, $signed_scalar_fsm_path],
    );

    my $signed_combined_output = join('', @{ $signed_stdout_buf || [] }, @{ $signed_stderr_buf || [] }, ($signed_error_message || ''));
    ok($signed_success, 'CLI accepts direct --language vhdl for signed scalar output decimal literal fixture')
        or diag($signed_combined_output);
    ok(-e $signed_scalar_output_path, 'CLI writes signed scalar output decimal literal VHDL output file');

    my $signed_cli_hdl = read_file($signed_scalar_output_path);
    like($signed_cli_hdl, qr/\bFLAG_next\s+<=\s+'1';/s, 'CLI signed scalar output decimal VHDL output includes std_logic low-bit assignment');
    unlike($signed_cli_hdl, qr/\bFLAG_next\s+<=\s+3;|to_unsigned\(3,\s+1\)|to_signed\(3,\s+1\)|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI signed scalar output decimal VHDL output avoids raw integer assignment, vector casts, and SystemVerilog syntax');
};

subtest 'direct VHDL scaffold lowers scalar output negative decimal literal assignments' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $scalar_fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_output_negative_decimal_literal.fsm');
    my $scalar_output_path = File::Spec->catfile($tempdir, 'direct_vhdl_scalar_output_negative_decimal_literal.vhd');
    my $signed_scalar_fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_scalar_output_negative_decimal_literal.fsm');
    my $signed_scalar_output_path = File::Spec->catfile($tempdir, 'direct_vhdl_signed_scalar_output_negative_decimal_literal.vhd');

    write_file(
        $scalar_fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_scalar_output_negative_decimal_literal
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
        $signed_scalar_fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_signed_scalar_output_negative_decimal_literal
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

    my $scalar_hdl = generate_vhdl($scalar_fsm_path);
    like($scalar_hdl, qr/\bentity\s+direct_vhdl_scalar_output_negative_decimal_literal\s+is\b/s, 'scalar output negative decimal fixture emits direct VHDL entity');
    like($scalar_hdl, qr/\bFLAG\s+:\s+out\s+std_logic;?/s, 'scalar output negative decimal fixture lowers output port to std_logic');
    like($scalar_hdl, qr/\bsignal\s+FLAG_next\s+:\s+std_logic;/s, 'scalar output negative decimal fixture declares scalar next signal');
    like($scalar_hdl, qr/\bFLAG_next\s+<=\s+'1';/s, 'odd scalar output negative decimal literal lowers to std_logic one');
    unlike($scalar_hdl, qr/\bFLAG_next\s+<=\s+-1;|to_unsigned\(-1,\s+1\)|to_signed\(-1,\s+1\)/s, 'scalar output negative decimal fixture avoids raw integer assignments and vector casts');
    unlike($scalar_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b/s, 'scalar output negative decimal VHDL output does not leak SystemVerilog structural syntax');

    my $signed_scalar_hdl = generate_vhdl($signed_scalar_fsm_path);
    like($signed_scalar_hdl, qr/\bentity\s+direct_vhdl_signed_scalar_output_negative_decimal_literal\s+is\b/s, 'signed scalar output negative decimal fixture emits direct VHDL entity');
    like($signed_scalar_hdl, qr/\bFLAG\s+:\s+out\s+std_logic;?/s, 'signed scalar output negative decimal fixture lowers one-bit signed output port to std_logic');
    like($signed_scalar_hdl, qr/\bsignal\s+FLAG_next\s+:\s+std_logic;/s, 'signed scalar output negative decimal fixture declares scalar next signal');
    like($signed_scalar_hdl, qr/\bFLAG_next\s+<=\s+'0';/s, 'even signed scalar output negative decimal literal lowers to std_logic zero');
    unlike($signed_scalar_hdl, qr/\bFLAG_next\s+<=\s+-2;|to_unsigned\(-2,\s+1\)|to_signed\(-2,\s+1\)/s, 'signed scalar output negative decimal fixture avoids raw integer assignments and vector casts');
    unlike($signed_scalar_hdl, qr/\bmodule\b|\balways_(?:ff|comb)\b/s, 'signed scalar output negative decimal VHDL output does not leak SystemVerilog structural syntax');

    my ($scalar_success, $scalar_error_message, $scalar_full_buf, $scalar_stdout_buf, $scalar_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $scalar_output_path, $scalar_fsm_path],
    );

    my $scalar_combined_output = join('', @{ $scalar_stdout_buf || [] }, @{ $scalar_stderr_buf || [] }, ($scalar_error_message || ''));
    ok($scalar_success, 'CLI accepts direct --language vhdl for scalar output negative decimal literal fixture')
        or diag($scalar_combined_output);
    ok(-e $scalar_output_path, 'CLI writes scalar output negative decimal literal VHDL output file');

    my $scalar_cli_hdl = read_file($scalar_output_path);
    like($scalar_cli_hdl, qr/\bFLAG_next\s+<=\s+'1';/s, 'CLI scalar output negative decimal VHDL output includes std_logic low-bit assignment');
    unlike($scalar_cli_hdl, qr/\bFLAG_next\s+<=\s+-1;|to_unsigned\(-1,\s+1\)|to_signed\(-1,\s+1\)|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI scalar output negative decimal VHDL output avoids raw integer assignment, vector casts, and SystemVerilog syntax');

    my ($signed_success, $signed_error_message, $signed_full_buf, $signed_stdout_buf, $signed_stderr_buf) = run(
        command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $signed_scalar_output_path, $signed_scalar_fsm_path],
    );

    my $signed_combined_output = join('', @{ $signed_stdout_buf || [] }, @{ $signed_stderr_buf || [] }, ($signed_error_message || ''));
    ok($signed_success, 'CLI accepts direct --language vhdl for signed scalar output negative decimal literal fixture')
        or diag($signed_combined_output);
    ok(-e $signed_scalar_output_path, 'CLI writes signed scalar output negative decimal literal VHDL output file');

    my $signed_cli_hdl = read_file($signed_scalar_output_path);
    like($signed_cli_hdl, qr/\bFLAG_next\s+<=\s+'0';/s, 'CLI signed scalar output negative decimal VHDL output includes std_logic low-bit assignment');
    unlike($signed_cli_hdl, qr/\bFLAG_next\s+<=\s+-2;|to_unsigned\(-2,\s+1\)|to_signed\(-2,\s+1\)|\bmodule\b|\balways_(?:ff|comb)\b/s, 'CLI signed scalar output negative decimal VHDL output avoids raw integer assignment, vector casts, and SystemVerilog syntax');
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
