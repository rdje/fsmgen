use strict;
use warnings;
use lib 'perl';
use Test::More;
use FSM::CoreAST;
use FSM::AST::Node;
use FSM::ExpressionNamer;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport;
use FSM::Synthesis::EnableGraph::ASTSupport;

my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
my $builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(signal_manager => $manager);
my $namer = FSM::ExpressionNamer->new;
my $context = {expr_namer => $namer};
my $intermediate = FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->new(
    flattened_dt => $context);
my $enable = FSM::Synthesis::EnableGraph::ASTSupport->new(flattened_dt => $context);

sub core_signal {
    my ($name, $width) = @_;
    return FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $name, width => $width));
}
sub core_unary { return FSM::CoreAST::UnaryOp->new(operator => $_[0], operand => $_[1]); }

subtest 'real width consumers preserve scalar reduction results over wide operands' => sub {
    for my $width (1, 8, 37) {
        my $operand = core_signal("bus$width", $width);
        for my $operator ('^', '&', '|') {
            my $ast = core_unary($operator, $operand);
            is($builder->infer_exact_expression_width($ast), 1, "$operator/$width exact builder width");
            is($namer->infer_ast_width($ast), 1, "$operator/$width Core AST naming width");
            is($intermediate->infer_width_from_intermediate_ast($ast), 1, "$operator/$width direct intermediate width");
            is($enable->_expression_width($ast), 1, "$operator/$width enable-graph width");
            my $concat = FSM::CoreAST::Concatenation->new($ast,
                FSM::CoreAST::Literal->new('0', width => 3, radix => 'binary'));
            is($builder->infer_exact_expression_width($concat), 4, "$operator/$width nested concat is four bits");
            is($namer->infer_ast_width($concat), 4, "$operator/$width nested named concat agrees");
            my $comparison = FSM::CoreAST::BinaryOp->new('==', $ast,
                FSM::CoreAST::Literal->new('1', width => 1, radix => 'binary'));
            is($builder->infer_exact_expression_width($comparison), 1, "$operator/$width comparison remains scalar");
            is($namer->infer_ast_width($comparison), 1, "$operator/$width named comparison remains scalar");
            is($operand->signal->width, $width, "$operator/$width operand stays unchanged");
        }
    }
};

subtest 'runtime and substituted ASTs retain the same result width' => sub {
    my $literal = FSM::AST::Literal->new("8'hA5");
    for my $operator ('^', '&', '|') {
        my $runtime = FSM::AST::UnaryOp->new($operator, $literal);
        is($namer->infer_ast_width($runtime), 1, "$operator runtime naming does not borrow literal width");
        is($intermediate->infer_width_from_intermediate_ast($runtime), 1, "$operator runtime intermediate is scalar");
        is($enable->_expression_width($runtime), 1, "$operator runtime enable width is scalar");
        my $substituted = FSM::HDL::SubstitutedUnaryOp->new(operator => $operator, operand => $literal);
        is($intermediate->infer_width_from_intermediate_ast($substituted), 1, "$operator substituted intermediate is scalar");
        is($enable->_expression_width($substituted), 1, "$operator substituted enable width is scalar");
    }
};

subtest 'all operators have distinct readable named intermediates' => sub {
    for my $model ('core', 'runtime') {
        my $names = FSM::ExpressionNamer->new;
        my @actual;
        for my $operator ('^', '&', '|') {
            my $node = $model eq 'core'
                ? core_unary($operator, core_signal('payload', 16))
                : FSM::AST::UnaryOp->new($operator, FSM::AST::Literal->new("16'hA55A"));
            my $name = $names->name_ast_expression($node);
            push @actual, $name;
            like($name, qr/\Areduce_(?:xor|and|or)_/, "$model/$operator readable reduction name");
            is($names->get_signal_definitions->{$name}{width}, 1, "$model/$operator stored intermediate width");
        }
        my %unique = map { $_ => 1 } @actual;
        is(scalar(keys %unique), 3, "$model reductions do not collide with each other");
        is_deeply([sort grep { /\Areduce_/ } keys %{$names->get_signal_definitions}],
            [sort @actual], "$model retains every reduction definition beside ordinary constants");
    }
};

subtest 'destination width cannot resize the reduction operand' => sub {
    for my $operator ('^', '&', '|') {
        my %names = ('^' => 'bit_xor', '&' => 'bit_and', '|' => 'bit_or');
        my $signal = $manager->register_signal($names{$operator}, width => 1);
        my $node = core_unary($operator, FSM::CoreAST::SignalRef->new($signal));
        $builder->propagate_width_to_expression($node, 12);
        is($node->operand->signal->width, 1, "$operator keeps authored operand width");
        is($manager->get_signal($names{$operator})->width, 1, "$operator cannot alter the signal registry");
    }
    my $ordinary = core_unary('~', core_signal('ordinary', 1));
    $builder->propagate_width_to_expression($ordinary, 12);
    is($ordinary->operand->signal->width, 12, 'ordinary width propagation keeps its existing behavior');
};

subtest 'binary vector and other unary width contracts remain unchanged' => sub {
    my $wide = core_signal('wide', 16);
    my $other = core_signal('other', 8);
    for my $operator ('^', '&', '|') {
        my $binary = FSM::CoreAST::BinaryOp->new($operator, $wide, $other);
        is($builder->infer_exact_expression_width($binary), 16, "$operator binary exact width remains vector");
        is($namer->infer_ast_width($binary), 16, "$operator binary named width remains vector");
        is($enable->_expression_width($binary), 16, "$operator binary enable width remains vector");
    }
    is($builder->infer_exact_expression_width(core_unary('!', $wide)), 1, 'logical negation remains scalar');
    is($namer->infer_ast_width(core_unary('!', $wide)), 1, 'logical naming remains scalar');
    is($builder->infer_exact_expression_width(core_unary('~', $wide)), 16, 'bitwise complement remains vector');
    is($namer->infer_ast_width(core_unary('~', $wide)), 16, 'bitwise complement naming inference remains vector');
    $manager->register_signal('bus', width => 8, width_declared => 1);
    for my $operator ('^', '&', '|') {
        my $accepted = eval { $builder->parse_expression([$operator, 'bus']); 1 };
        ok(!$accepted, "$operator unary source admission remains closed in this prerequisite");
        like($@, qr/requires at least 2 operands/, "$operator retains the source arity boundary");
    }
};

done_testing();
