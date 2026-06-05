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

sub capture_exception {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };

    return '' if $ok;
    return $@ || 'unknown error';
}
