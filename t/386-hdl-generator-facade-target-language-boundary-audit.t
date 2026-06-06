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

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
