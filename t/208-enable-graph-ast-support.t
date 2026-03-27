#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;

subtest 'enable-graph AST support rebuilds AST rendering and operator classification from a prepared backend context' => sub {
    my $fsm_module = parse_fsm_module(
        'enable_graph_ast_support_contract',
        <<'FSM'
(?fsm:enable_graph_ast_support_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
    (BUS1 8)
    (BUS2 8)
    (OUT1 1)
    (OUT2 1)
  )
  (idle
    (<(| A B)
      (OUT1 <= 1)
    )
    (<(| A B)
      (OUT2 <= 0)
    )
  )
)
FSM
    );

    my $prepared_backend = prepare_flattened_backend($fsm_module);
    my $support = $prepared_backend->{enable_graph_ast_support};

    my $one_bit_logical = FSM::AST::BinaryOp->new(
        '||',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::SignalRef->new('B'),
    );
    my $multi_bit_logical = FSM::AST::BinaryOp->new(
        '||',
        FSM::AST::SignalRef->new('BUS1'),
        FSM::AST::SignalRef->new('BUS2'),
    );
    my $arithmetic = FSM::AST::BinaryOp->new(
        '+',
        FSM::AST::SignalRef->new('BUS1'),
        FSM::AST::SignalRef->new('BUS2'),
    );
    my $negated = FSM::AST::UnaryOp->new(
        '!',
        FSM::AST::BinaryOp->new(
            '==',
            FSM::AST::SignalRef->new('A'),
            FSM::AST::Literal->new('1'),
        ),
    );

    is(
        $support->ast_to_systemverilog($one_bit_logical),
        'A | B',
        'AST support renders 1-bit logical operators through bitwise SystemVerilog symbols',
    );
    is(
        $support->ast_to_systemverilog($multi_bit_logical),
        'BUS1 || BUS2',
        'AST support keeps multi-bit logical operators as logical SystemVerilog operators',
    );
    is(
        $support->ast_to_systemverilog($arithmetic),
        'BUS1 + BUS2',
        'AST support renders arithmetic expressions with direct binary operator emission',
    );
    is(
        $support->ast_to_systemverilog($negated),
        '!((A == 1))',
        'AST support keeps negated comparison rendering stable',
    );

    ok(
        $support->is_logical_operation($one_bit_logical),
        'AST support classifies logical binary operations',
    );
    ok(
        !$support->is_arithmetic_operation($one_bit_logical),
        'AST support does not misclassify logical binary operations as arithmetic',
    );
    ok(
        $support->is_arithmetic_operation($arithmetic),
        'AST support classifies arithmetic binary operations',
    );
    ok(
        $support->ast_contains_factorizable_operators($negated),
        'AST support treats unary-expression trees as factorizable',
    );
    is(
        $support->should_factor_logical_operation($one_bit_logical) ? 1 : 0,
        (($prepared_backend->{binary_logical_op_counts}{$one_bit_logical->to_systemverilog} || 0) > 1) ? 1 : 0,
        'AST support delegates logical factorization policy to the live frequency table',
    );
};

done_testing();

sub parse_fsm_module {
    my ($basename, $fsm_text) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$basename.fsm");

    write_file($fsm_path, $fsm_text);
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    return FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
}

sub prepare_flattened_backend {
    my ($fsm_module) = @_;
    my $hdl_generator = FSM::HDL::FlattenedDT->new(debug => 0);
    $hdl_generator->{orchestrator}->reset_generation_state();
    $hdl_generator->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
    $hdl_generator->{orchestrator}->flatten_all_decision_trees($fsm_module);
    $hdl_generator->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    $hdl_generator->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    return $hdl_generator;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
