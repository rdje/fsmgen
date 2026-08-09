#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::AST::Node;
use FSM::CoreAST;
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
    (CNT 3)
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
    my $generated_enable_logical = FSM::AST::BinaryOp->new(
        '&&',
        FSM::AST::SignalRef->new('idle_en'),
        FSM::AST::SignalRef->new('setup_en'),
    );
    my $arithmetic = FSM::AST::BinaryOp->new(
        '+',
        FSM::AST::SignalRef->new('BUS1'),
        FSM::AST::SignalRef->new('BUS2'),
    );
    my $modulo_over_product = FSM::AST::BinaryOp->new(
        '%',
        FSM::AST::SignalRef->new('BUS1'),
        FSM::AST::BinaryOp->new(
            '*',
            FSM::AST::SignalRef->new('BUS2'),
            FSM::AST::SignalRef->new('BUS1'),
        ),
    );
    my $subtract_nested_subtract = FSM::AST::BinaryOp->new(
        '-',
        FSM::AST::SignalRef->new('BUS1'),
        FSM::AST::BinaryOp->new(
            '-',
            FSM::AST::SignalRef->new('BUS2'),
            FSM::AST::SignalRef->new('BUS1'),
        ),
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
        $support->ast_to_systemverilog($generated_enable_logical),
        'idle_en & setup_en',
        'AST support renders generated enable signals through bitwise operators too',
    );
    is(
        $support->ast_to_systemverilog($arithmetic),
        'BUS1 + BUS2',
        'AST support renders arithmetic expressions with direct binary operator emission',
    );
    is(
        $support->ast_to_systemverilog($modulo_over_product),
        'BUS1 % (BUS2 * BUS1)',
        'AST support preserves right-nested same-precedence arithmetic grouping',
    );
    is(
        $support->ast_to_systemverilog($subtract_nested_subtract),
        'BUS1 - (BUS2 - BUS1)',
        'AST support preserves non-associative right-nested arithmetic grouping',
    );
    is(
        $support->ast_to_systemverilog($negated),
        '!A',
        'AST support collapses negated 1-bit truthiness comparisons to direct negation',
    );

    my $truthy_nonzero = FSM::AST::BinaryOp->new(
        '!=',
        FSM::AST::SignalRef->new('BUS1'),
        FSM::AST::Literal->new('0'),
    );
    my $truthy_zero = FSM::AST::BinaryOp->new(
        '==',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::Literal->new('0'),
    );
    my $truthy_one = FSM::AST::BinaryOp->new(
        '==',
        FSM::AST::SignalRef->new('A'),
        FSM::AST::Literal->new('1'),
    );

    is(
        $support->ast_to_systemverilog($truthy_nonzero),
        '(|BUS1)',
        'AST support lowers multibit nonzero comparisons to reduction truthiness',
    );
    is(
        $support->ast_to_systemverilog($truthy_zero),
        '!A',
        'AST support collapses 1-bit equals-zero comparisons to direct negation',
    );
    is(
        $support->ast_to_systemverilog($truthy_one),
        'A',
        'AST support collapses 1-bit equals-one comparisons to the bare signal',
    );

    $prepared_backend->{intermediate_signals}{sum_expr} = {
        width => 3,
        expression => 'BUS1[2:0] + BUS2[2:0]',
        source => 'test_width_metadata',
    };
    $prepared_backend->{intermediate_signals}{flag_expr} = {
        width => 1,
        expression => 'A & B',
        source => 'test_width_metadata',
    };
    $prepared_backend->{intermediate_signals}{unresolved_expr} = {
        width => undef,
        width_source => 'unresolved_factorization_ast',
        expression => 'CNT + CNT',
        source => 'test_unresolved_width_metadata',
    };
    my $sum_expr_ref = sub { FSM::HDL::IntermediateSignalRef->new(signal_name => 'sum_expr') };
    my $flag_expr_ref = sub { FSM::HDL::IntermediateSignalRef->new(signal_name => 'flag_expr') };
    my $unresolved_expr_ref = sub { FSM::HDL::IntermediateSignalRef->new(signal_name => 'unresolved_expr') };

    is(
        $support->ast_to_systemverilog(
            FSM::AST::BinaryOp->new('==', $sum_expr_ref->(), FSM::AST::Literal->new("3'd0")),
        ),
        '(~|sum_expr)',
        'AST support renders multi-bit intermediate equals-zero as reduction zero',
    );
    is(
        $support->ast_to_systemverilog(
            FSM::AST::BinaryOp->new('==', $sum_expr_ref->(), FSM::AST::Literal->new("3'd1")),
        ),
        "sum_expr == 3'd1",
        'AST support preserves multi-bit intermediate equals-one as explicit equality',
    );
    is(
        $support->ast_to_systemverilog(
            FSM::AST::BinaryOp->new('==', $flag_expr_ref->(), FSM::AST::Literal->new("1'b0")),
        ),
        '!flag_expr',
        'AST support still collapses one-bit intermediate equals-zero to direct negation',
    );
    is(
        $support->ast_to_systemverilog(
            FSM::AST::BinaryOp->new('==', $unresolved_expr_ref->(), FSM::AST::Literal->new("3'd0")),
        ),
        '(~|unresolved_expr)',
        'AST support fails closed to reduction zero when an intermediate width is unresolved',
    );
    is(
        $support->ast_to_systemverilog(
            FSM::AST::BinaryOp->new('==', $unresolved_expr_ref->(), FSM::AST::Literal->new("3'd1")),
        ),
        "unresolved_expr == 3'd1",
        'AST support preserves equals-one when an intermediate width is unresolved',
    );

    my $a_ref = sub { FSM::AST::SignalRef->new('A') };
    my $b_ref = sub { FSM::AST::SignalRef->new('B') };
    my $bus1_ref = sub { FSM::AST::SignalRef->new('BUS1') };
    my $bus2_ref = sub { FSM::AST::SignalRef->new('BUS2') };
    my $one = sub { FSM::AST::Literal->new('1') };
    my $zero = sub { FSM::AST::Literal->new('0') };
    my $not_b = sub { FSM::AST::UnaryOp->new('!', $b_ref->()) };
    my %vector_signals = map {
        $_ => FSM::CoreAST::Signal->new(name => $_, width => 8)
    } qw(BUS1 BUS2);
    my $bus1_core_ref = sub { FSM::CoreAST::SignalRef->new($vector_signals{BUS1}) };
    my $bus2_core_ref = sub { FSM::CoreAST::SignalRef->new($vector_signals{BUS2}) };
    my $bitnot_bus1 = sub { FSM::AST::UnaryOp->new('~', $bus1_core_ref->()) };
    my $bitnot_bus2 = sub { FSM::AST::UnaryOp->new('~', $bus2_core_ref->()) };

    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('&', $a_ref->(), $one->())),
        'A',
        'AST support simplifies boolean identity A & 1 to A before rendering',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('|', $a_ref->(), $zero->())),
        'A',
        'AST support simplifies boolean identity A | 0 to A before rendering',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('&', $a_ref->(), $zero->())),
        "1'b0",
        'AST support simplifies boolean annihilator A & 0 to false before rendering',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('|', $a_ref->(), FSM::AST::UnaryOp->new('!', $a_ref->()))),
        "1'b1",
        'AST support simplifies boolean complement A | !A to true before rendering',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::UnaryOp->new('!', FSM::AST::UnaryOp->new('!', $a_ref->()))),
        'A',
        'AST support simplifies double negation before rendering',
    );
    is(
        $support->ast_to_systemverilog(
            FSM::AST::BinaryOp->new(
                '|',
                $a_ref->(),
                FSM::AST::BinaryOp->new('&', $a_ref->(), $b_ref->()),
            ),
        ),
        'A',
        'AST support simplifies absorption A | (A & B) to A before rendering',
    );
    is(
        $support->ast_to_systemverilog(
            FSM::AST::BinaryOp->new(
                '|',
                FSM::AST::BinaryOp->new('&', $a_ref->(), $b_ref->()),
                FSM::AST::BinaryOp->new('&', $a_ref->(), $not_b->()),
            ),
        ),
        'A',
        'AST support simplifies consensus (A & B) | (A & !B) to A before rendering',
    );
    is(
        $support->ast_to_systemverilog(
            FSM::AST::UnaryOp->new(
                '!',
                FSM::AST::BinaryOp->new('&', $a_ref->(), $not_b->()),
            ),
        ),
        '!A | B',
        'AST support applies shorter De Morgan form after RHS AST simplification',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('&', $bus1_ref->(), FSM::AST::Literal->new("1'b1"))),
        "BUS1 & 1'b1",
        'AST support preserves vector-nonidentity BUS1 & 1 when width-safe simplification is not proven',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('&', $bus1_core_ref->(), FSM::AST::Literal->new("8'b11111111"))),
        'BUS1',
        'AST support simplifies vector identity BUS1 & 8-bit all-ones mask to BUS1',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('|', $bus1_core_ref->(), FSM::AST::Literal->new("8'b00000000"))),
        'BUS1',
        'AST support simplifies vector identity BUS1 | 8-bit zero mask to BUS1',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('&', $bus1_core_ref->(), FSM::AST::Literal->new("1'b0"))),
        "8'b0",
        'AST support simplifies vector annihilator BUS1 & 1-bit zero mask to an 8-bit zero constant',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('|', $bus1_core_ref->(), FSM::AST::Literal->new("8'b11111111"))),
        "8'b11111111",
        'AST support simplifies vector annihilator BUS1 | 8-bit all-ones mask to an 8-bit all-ones constant',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('^', $bus1_core_ref->(), FSM::AST::Literal->new("8'b00000000"))),
        'BUS1',
        'AST support simplifies vector XOR zero identity to BUS1',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('^', $bus1_core_ref->(), FSM::AST::Literal->new("8'b11111111"))),
        '~(BUS1)',
        'AST support simplifies vector XOR all-ones mask to bitwise complement',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('^', $bus1_core_ref->(), $bus1_core_ref->())),
        "8'b0",
        'AST support simplifies vector self-XOR to a same-width zero constant',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::UnaryOp->new('~', FSM::AST::UnaryOp->new('~', $bus1_core_ref->()))),
        'BUS1',
        'AST support simplifies vector double bitwise negation before rendering',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('&', $bus1_core_ref->(), $bitnot_bus1->())),
        "8'b0",
        'AST support simplifies vector complement BUS1 & ~BUS1 to a same-width zero constant',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('|', $bus1_core_ref->(), $bitnot_bus1->())),
        "8'b11111111",
        'AST support simplifies vector complement BUS1 | ~BUS1 to a same-width all-ones constant',
    );
    is(
        $support->ast_to_systemverilog(
            FSM::AST::BinaryOp->new(
                '|',
                $bus1_core_ref->(),
                FSM::AST::BinaryOp->new('&', $bus1_core_ref->(), $bus2_core_ref->()),
            ),
        ),
        'BUS1',
        'AST support simplifies vector absorption BUS1 | (BUS1 & BUS2) to BUS1',
    );
    is(
        $support->ast_to_systemverilog(
            FSM::AST::BinaryOp->new(
                '|',
                FSM::AST::BinaryOp->new('&', $bus1_core_ref->(), $bus2_core_ref->()),
                FSM::AST::BinaryOp->new('&', $bus1_core_ref->(), $bitnot_bus2->()),
            ),
        ),
        'BUS1',
        'AST support simplifies vector consensus (BUS1 & BUS2) | (BUS1 & ~BUS2) to BUS1',
    );
    is(
        $support->ast_to_systemverilog(FSM::AST::BinaryOp->new('&', $bus1_core_ref->(), FSM::AST::Literal->new("16'hffff"))),
        "BUS1 & 16'hFFFF",
        'AST support preserves vector identity masks that would change expression width',
    );

    my $cnt_signal = FSM::CoreAST::Signal->new(name => 'CNT', width => 3);
    my $cnt_slice_ne_two = FSM::CoreAST::BinaryOp->new(
        '!=',
        FSM::CoreAST::SignalRef->new($cnt_signal, slice => [2, 1]),
        FSM::CoreAST::Literal->new('2', width => 2, radix => 'decimal'),
    );
    my $cnt_slice_nonzero = FSM::CoreAST::BinaryOp->new(
        '!=',
        FSM::CoreAST::SignalRef->new($cnt_signal, slice => [2, 1]),
        FSM::CoreAST::Literal->new('0', width => 2, radix => 'decimal'),
    );
    my $cnt_single_bit_slice_and = FSM::CoreAST::BinaryOp->new(
        '&&',
        FSM::CoreAST::SignalRef->new($cnt_signal, slice => [0, 0]),
        FSM::AST::SignalRef->new('A'),
    );

    is(
        $support->ast_to_systemverilog($cnt_slice_ne_two),
        "CNT[2:1] != 2'd2",
        'AST support preserves CoreAST signal slices in non-truthiness comparisons',
    );
    is(
        $support->ast_to_systemverilog($cnt_slice_nonzero),
        '(|CNT[2:1])',
        'AST support preserves CoreAST signal slices in multibit truthiness lowering',
    );
    is(
        $support->ast_to_systemverilog($cnt_single_bit_slice_and),
        'CNT[0:0] & A',
        'AST support treats one-bit CoreAST slices as bitwise logical operands',
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

subtest 'CoreAST direct SystemVerilog rendering preserves same-precedence right grouping' => sub {
    my %signals = map {
        $_ => FSM::CoreAST::Signal->new(name => $_, width => 8)
    } qw(BUS1 BUS2);
    my $ref = sub {
        my ($name) = @_;
        return FSM::CoreAST::SignalRef->new($signals{$name});
    };

    my $modulo_over_product = FSM::CoreAST::BinaryOp->new(
        '%',
        $ref->('BUS1'),
        FSM::CoreAST::BinaryOp->new(
            '*',
            $ref->('BUS2'),
            $ref->('BUS1'),
        ),
    );
    my $subtract_nested_subtract = FSM::CoreAST::BinaryOp->new(
        '-',
        $ref->('BUS1'),
        FSM::CoreAST::BinaryOp->new(
            '-',
            $ref->('BUS2'),
            $ref->('BUS1'),
        ),
    );

    is(
        $modulo_over_product->to_systemverilog,
        'BUS1 % (BUS2 * BUS1)',
        'CoreAST SV rendering preserves right-nested modulo/product grouping',
    );
    is(
        $subtract_nested_subtract->to_systemverilog,
        'BUS1 - (BUS2 - BUS1)',
        'CoreAST SV rendering preserves right-nested non-associative grouping',
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
