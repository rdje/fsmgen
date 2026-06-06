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

subtest 'direct VHDL scaffold keeps broader arithmetic expression parity fail-closed' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_vhdl_multiply_deferred.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_vhdl_multiply_deferred
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (A 8)
    (B 8)
    (PRODUCT 8)
  )
  (idle
    (= (PRODUCT (* A B)))
  )
)
FSM
    );

    my $error = capture_exception(sub {
        generate_vhdl($fsm_path);
    });

    like($error, qr/arithmetic expression 'A \* B' is outside the direct VHDL scaffold/s, 'multiplication remains outside the direct VHDL scaffold boundary');

    my $corpus_error = capture_exception(sub {
        generate_vhdl('t/corpus/arithmetic_xor_operator_variants.fsm');
    });

    unlike($corpus_error, qr/arithmetic expression 'a \+ b \+ c \+ d'/s, 'arithmetic corpus no longer fails on the same-width addition chain');
    like($corpus_error, qr/arithmetic expression 'a - b - c - d' is outside the direct VHDL scaffold/s, 'subtraction chains remain outside the direct VHDL scaffold boundary');
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
