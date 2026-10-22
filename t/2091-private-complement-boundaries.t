#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::CoreAST;
use FSM::AST::Node;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;
use FSM::Pipeline::SourceFrontend;

my $work = tempdir(CLEANUP => 1);
my $path = "$work/declared.fsm";
open my $fh, '>', $path or die $!;
print {$fh} <<'FSM';
(?fsm:complement_contract
  (+system (clock clk) (sreset rst_n))
  (+size (A 1) (W 8) (Y 1) (Z 8))
  (idle (= (Y A)) (= (Z W))))
FSM
close $fh or die $!;
my $raw = FSM::Pipeline::SourceFrontend->parse_fsm_file(fsm_file => $path, debug_level => 0);
my $module = FSM::Pipeline::SourceFrontend->create_fsm_module(raw_ast => $raw, debug_level => 0);
my $ctx = FSM::HDL::FlattenedDT->new(debug => 0);
$ctx->{orchestrator}->reset_generation_state;
$ctx->{enable_graph_signal_support}->set_fsm_module_reference($module);
$ctx->{orchestrator}->flatten_all_decision_trees($module);
$ctx->{enable_graph_enable_support}->generate_enable_conditions($module);
$ctx->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences;
my $owner = $ctx->{enable_graph_ast_support};
my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => $ctx);

for my $model (qw(core runtime substituted)) {
    subtest "$model width and executed rendering boundaries" => sub {
        for my $case ([A => 1], [W => 8], [missing => undef]) {
            my ($name, $width) = @$case;
            my $operand = $model eq 'runtime'
                ? FSM::AST::SignalRef->new($name)
                : FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(
                    name => $name, width => defined($width) ? $width : 'UNRESOLVED_WIDTH'));
            my $complement = unary($model, '~', $operand);
            is($owner->_expression_width($complement), $width, "$name retains declared width");
            is(0 + $owner->_operand_is_single_bit($complement),
                defined($width) && $width == 1 ? 1 : 0, "$name scalar status requires known width one");
            is(render($complement), "~($name)", "$name complement rendering preserves operand");
            is(render(unary($model, '!', $complement)),
                defined($width) && $width == 1 ? "!(~($name))" : "(~|~($name))",
                "$name logical rendering follows complement width");
            for my $logical ('!', 'not') {
                is(0 + $owner->_operand_is_single_bit(unary($model, $logical, $operand)),
                    1, "$name/$logical remains scalar");
            }
            for my $reduction ('^', '&', '|') {
                is(0 + $owner->_operand_is_single_bit(unary($model, $reduction, $operand)),
                    1, "$name/$reduction remains scalar");
            }
            for my $unknown ('unsupported', '-') {
                is(0 + $owner->_operand_is_single_bit(unary($model, $unknown, $operand)),
                    0, "$name/$unknown cannot borrow operand width");
            }
            # Both logical operator selection and truthiness rendering consume
            # this classifier independently of unary negation emission.
            is($owner->_choose_operator_symbol('&&', $complement, $complement),
                defined($width) && $width == 1 ? '&' : '&&', "$name logical pair selection");
            is($owner->_render_truthiness_value($complement, render($complement)),
                defined($width) && $width == 1 ? "~($name)" : "(|~($name))",
                "$name nonzero truthiness selection");
        }
    };
}

subtest 'direct VHDL refuses residual complement in assignments and conditions' => sub {
    for my $expression ('~(A)', '!(~(A))', '~(W)', 'A == ~(A)', '(~(A)) & A') {
        for my $condition (0, 1) {
            my $statement = $condition
                ? "always_comb begin\nif ($expression) begin\nY = 1'b1;\nend\nend"
                : "assign Y = $expression;";
            my $sv = "module complement_profile (\ninput wire A,\ninput wire [7:0] W,\noutput wire Y\n);\n$statement\nendmodule\n";
            my $vhdl = eval { $backend->convert_systemverilog_to_vhdl($sv) };
            my $error = $@;
            ok(!defined($vhdl), "$expression condition=$condition returns no artifact");
            like($error, qr/bitwise complement expression .* outside the direct VHDL scaffold/s,
                "$expression condition=$condition has explicit profile refusal");
        }
    }
};

done_testing();

sub unary {
    my ($model, $operator, $operand) = @_;
    return FSM::AST::UnaryOp->new($operator, $operand) if $model eq 'runtime';
    return FSM::CoreAST::UnaryOp->new(operator => $operator, operand => $operand) if $model eq 'core';
    return FSM::HDL::SubstitutedUnaryOp->new(operator => $operator, operand => $operand);
}

sub render { $owner->ast_to_systemverilog($_[0]) }
